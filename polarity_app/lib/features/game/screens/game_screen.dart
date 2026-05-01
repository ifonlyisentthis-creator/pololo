import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polarity/features/game/engine/game_engine.dart';
import 'package:polarity/features/game/painters/game_painter.dart';
import 'package:polarity/features/death/screens/death_screen.dart';
import 'package:polarity/core/constants.dart';
import 'package:polarity/providers/providers.dart';
import 'package:polarity/services/audio_service.dart';
import 'package:polarity/services/haptic_service.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late Ticker _ticker;
  Duration _lastTime = Duration.zero;
  double _accumulator = 0;
  late GameEngine _engine;
  late GamePainter _gamePainter;
  late AudioService _audio;
  late HapticService _haptics;
  int _lastScore = -1;
  int _lastPhase = -1;
  bool _deathFlowStarted = false;
  bool _deathScreenVisible = false;
  bool _pauseDialogVisible = false;
  bool _pauseDialogActionInProgress = false;
  int _lastTutorialBucket = -1;
  bool _cachedPainterIsDark = true;
  bool _lastTutorialInteracted = false;

  // Easter egg: Fisher-Yates shuffled deck for no-repeat messages
  final Random _easterEggRng = Random();
  late List<int> _easterEggDeck = _buildEasterEggDeck();
  int _easterEggCursor = 0;

  List<int> _buildEasterEggDeck() {
    final deck = List<int>.generate(
      GameConstants.easterEggDeathMessages.length, (i) => i,
    );
    deck.shuffle(_easterEggRng);
    return deck;
  }

  String _getEasterEggMessage() {
    if (_easterEggCursor >= _easterEggDeck.length) {
      final lastShown = _easterEggDeck.last;
      _easterEggDeck = _buildEasterEggDeck();
      if (_easterEggDeck.first == lastShown && _easterEggDeck.length > 1) {
        final swapIdx = 1 + _easterEggRng.nextInt(_easterEggDeck.length - 1);
        _easterEggDeck[0] = _easterEggDeck[swapIdx];
        _easterEggDeck[swapIdx] = lastShown;
      }
      _easterEggCursor = 0;
    }
    return GameConstants.easterEggDeathMessages[_easterEggDeck[_easterEggCursor++]];
  }

  // Fixed-step simulation gives stable physics and smoother pacing under load.
  static const double _fixedTimeStep = 1.0 / 120.0;
  static const double _maxFrameDelta = 0.1;
  static const int _maxSubSteps = 8;

  // Repaint notifier — triggers only the CustomPaint, not the entire widget tree
  final _repaintNotifier = _GameRepaintNotifier();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _engine = ref.read(gameEngineProvider);
    _audio = ref.read(audioServiceProvider);
    _haptics = ref.read(hapticServiceProvider);
    _cachedPainterIsDark = ref.read(isDarkThemeProvider);
    _engine.useWhiteSurfaceThemeInversion = !_cachedPainterIsDark;
    _gamePainter = GamePainter(
      engine: _engine,
      isDarkTheme: _cachedPainterIsDark,
      repaint: _repaintNotifier,
    );

    _ticker = createTicker(_onTick);
    _ticker.start();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      _engine.init(size.width, size.height);

      final storage = ref.read(storageServiceProvider);
      final shouldTutor = storage.isFirstLaunch || storage.getHighScore() < 5;
      _engine.configureTutorial(shouldTutor);
      if (storage.isFirstLaunch) storage.setFirstLaunchDone();

      // V2: Load elite status + tier from storage
      _engine.eliteUnlocked = ref.read(eliteUnlockedProvider);
      _engine.currentTier = storage.milestoneTier;
      _engine.previousTier = _engine.currentTier;

      _engine.startGame();

      // Start active-playtime clock for interstitial ad pacing
      ref.read(adServiceProvider).resumePlayClock();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Auto-pause when app goes to background
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      // V5: Also pause during countdown (not just playing)
      if ((_engine.state == GameState.playing ||
              _engine.state == GameState.countdown) &&
          !_pauseDialogVisible) {
        _engine.pause();
        _showPauseDialog();
      }
    }
  }

  void _onTick(Duration elapsed) {
    if (_lastTime == Duration.zero) {
      _lastTime = elapsed;
      return;
    }
    var dt = (elapsed - _lastTime).inMicroseconds / 1000000.0;
    _lastTime = elapsed;
    if (dt <= 0) return;
    if (dt > _maxFrameDelta) dt = _maxFrameDelta;

    _accumulator += dt;
    int subSteps = 0;
    while (_accumulator >= _fixedTimeStep && subSteps < _maxSubSteps) {
      _engine.update(_fixedTimeStep);
      _accumulator -= _fixedTimeStep;
      subSteps++;
    }
    if (subSteps == _maxSubSteps) {
      // Drop excess backlog to avoid catch-up spirals after long frame stalls.
      _accumulator = 0;
    }

    bool rebuildHud = false;

    // Notify only the CustomPaint to repaint — avoids rebuilding the entire widget tree
    _repaintNotifier.notify();

    if (_engine.score != _lastScore) {
      _lastScore = _engine.score;
      _onScoreChanged();
      rebuildHud = true;
    }

    if (_engine.currentPhase != _lastPhase) {
      if (_lastPhase >= 0) _onPhaseChanged();
      _lastPhase = _engine.currentPhase;
      rebuildHud = true;
    }

    if (_engine.state == GameState.dead && !_deathFlowStarted) {
      _deathFlowStarted = true;
      _onDeath();
    }

    // Tutorial interaction changed — rebuild to swap tutorial text
    if (_engine.tutorialHasInteracted != _lastTutorialInteracted) {
      _lastTutorialInteracted = _engine.tutorialHasInteracted;
      rebuildHud = true;
    }

    // Shield event polling
    if (_engine.shieldJustBroke) {
      _engine.shieldJustBroke = false;
      _audio.play('shield_break');
      _haptics.mediumImpact();
    }
    if (_engine.shieldJustPickedUp) {
      _engine.shieldJustPickedUp = false;
      _audio.play('shield_pickup');
      _haptics.lightTap();
    }

    // V2: Elite unlock event
    if (_engine.eliteJustUnlocked) {
      _engine.eliteJustUnlocked = false;
      _audio.play('elite_unlock');
      _haptics.heavyImpact();
      // Persist
      ref.read(eliteUnlockedProvider.notifier).state = true;
      ref.read(storageServiceProvider).setEliteUnlocked(true);
    }

    // V2: High score matched heartbeat
    if (_engine.highScoreJustMatched) {
      _engine.highScoreJustMatched = false;
      _haptics.heavyImpact();
    }

    // V3: Theme activation event
    if (_engine.themeJustActivated) {
      _engine.themeJustActivated = false;
      _audio.play('phase'); // reuse phase sound for now
      _haptics.mediumImpact();
      // Persist rotation indices + active theme for app restart
      final storage = ref.read(storageServiceProvider);
      storage.setThemeRotationsJson(_engine.serializeThemeRotations());
      final at = _engine.activeTheme;
      final rememberTheme = ref.read(rememberThemeAcrossLaunchesProvider);
      if (rememberTheme && at != null) {
        storage.setActiveTheme(at.tier, at.variation, _engine.score);
      } else {
        storage.clearActiveTheme();
      }
    }

    // V4: Troll activation event
    if (_engine.trollSystem.trollJustActivated) {
      _engine.trollSystem.trollJustActivated = false;
      _haptics.lightTap();
    }

    // V4: Troll ended event
    if (_engine.trollSystem.trollJustEnded) {
      _engine.trollSystem.trollJustEnded = false;
    }

    // Rebuild HUD for tutorial fade (only when opacity bucket changes, not every frame)
    if (_engine.showTutorial && mounted) {
      final opBucket = (_engine.tutorialOpacity * 10).round();
      if (opBucket != _lastTutorialBucket) {
        _lastTutorialBucket = opBucket;
        rebuildHud = true;
      }
    }

    if (rebuildHud && mounted) {
      setState(() {});
    }
  }

  void _onScoreChanged() {
    _audio.play('score');
    _haptics.lightTap();
  }

  void _onPhaseChanged() {
    _audio.play('phase');
    _haptics.phaseVibrate();
  }

  void _onDeath() {
    if (mounted) setState(() {});
    _audio.play('death');
    _haptics.heavyImpact();

    // Pause active-playtime clock — death screen / ads don't count
    ref.read(adServiceProvider).pausePlayClock();

    final storage = ref.read(storageServiceProvider);

    if (_engine.isNewHighScore) {
      storage.setHighScore(_engine.highScore);
      if (_engine.shouldRequestReview) {
        ref.read(reviewServiceProvider).requestReviewIfEligible();
      }
    }

    final modeBest = storage.leaderboardBestScore;
    if (_engine.score > modeBest) {
      storage.setLeaderboardBestScore(_engine.score);
      ref
          .read(leaderboardServiceProvider)
          .submitScore(_engine.score);
    }

    // V2: Persist tier if upgraded — Bug fix 3: consume immediately
    final tierUp = _engine.tierJustUnlocked;
    _engine.tierJustUnlocked = false;
    if (tierUp) {
      final storage = ref.read(storageServiceProvider);
      storage.setMilestoneTier(_engine.currentTier);
      ref.read(milestoneTierProvider.notifier).state = _engine.currentTier;
      _audio.play('tier_up');
    }

    final adService = ref.read(adServiceProvider);
    final connectivity = ref.read(connectivityServiceProvider);
    final adsEnabled = ref.read(adsEnabledProvider);
    if (adsEnabled && connectivity.isOnline) {
      adService.recordDeathAndShowIfEligible(
        onAdOpened: () {
          _ticker.muted = true;
        },
        onAdClosed: () {
          if (mounted) {
            _lastTime = Duration.zero;
            _accumulator = 0;
            if (!_deathScreenVisible) {
              _ticker.muted = false;
            }
          }
        },
      );
    }

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      _showDeathScreen(tierUp: tierUp);
    });
  }

  void _showDeathScreen({bool tierUp = false}) {
    _deathScreenVisible = true;
    // Death screen is opaque; pause hidden route updates until user restarts/revives.
    _ticker.muted = true;
    final deathMessage = _engine.getDeathMessage();
    final isPraise = _engine.lastMessageWasPraise;

    // Easter egg override: cheesy self-blame messages
    final easterEggActive = ref.read(easterEggActiveProvider);
    final String finalMessage;
    final bool finalIsPraise;
    if (easterEggActive) {
      // Stay active for entire session — only reset on app restart.
      // easterEggConsumed blocks re-trigger from menu tap.
      ref.read(easterEggConsumedProvider.notifier).state = true;
      finalMessage = _getEasterEggMessage();
      finalIsPraise = true;
    } else {
      finalMessage = deathMessage;
      finalIsPraise = isPraise;
    }

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (context, animation1, animation2) => DeathScreen(
          score: _engine.score,
          highScore: _engine.highScore,
          isNewHighScore: _engine.isNewHighScore,
          deathMessage: finalMessage,
          isPraise: finalIsPraise,
          hasRevivedThisRun: _engine.hasRevivedThisRun,
          onRestart: _restart,
          onRevive: _revive,
          isSessionBest: _engine.isSessionBest && !_engine.isNewHighScore,
          tierJustUnlocked: tierUp,
          currentTier: _engine.currentTier,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _restart() {
    Navigator.of(context).pop();
    _deathFlowStarted = false;
    _deathScreenVisible = false;
    _ticker.muted = false;
    _lastScore = -1;
    _lastPhase = -1;

    final storage = ref.read(storageServiceProvider);
    final shouldTutor = storage.getHighScore() < 5;
    _engine.configureTutorial(shouldTutor);

    _engine.startGame();
    _lastTime = Duration.zero;
    _accumulator = 0;
    if (mounted) setState(() {});

    // Resume active-playtime clock for new game
    ref.read(adServiceProvider).resumePlayClock();
  }

  void _revive() {
    Navigator.of(context).pop();
    _deathFlowStarted = false;
    _deathScreenVisible = false;
    _ticker.muted = false;
    _audio.play('revive');
    _engine.revive();
    _lastTime = Duration.zero;
    _accumulator = 0;
    if (mounted) setState(() {});

    // Resume active-playtime clock after revive
    ref.read(adServiceProvider).resumePlayClock();
  }

  @override
  void dispose() {
    ref.read(adServiceProvider).pausePlayClock();
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _repaintNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkThemeProvider);
    _engine.useWhiteSurfaceThemeInversion = !isDark;
    if (_cachedPainterIsDark != isDark) {
      _cachedPainterIsDark = isDark;
      _gamePainter = GamePainter(
        engine: _engine,
        isDarkTheme: isDark,
        repaint: _repaintNotifier,
      );
    }
    final inverted = _engine.isPhase5Inverted;
    final effectiveBg = inverted
        ? Colors.white
        : (isDark ? Colors.black : Colors.white);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (_engine.state == GameState.playing) {
            _engine.pause();
            _showPauseDialog();
          } else if (_engine.state == GameState.paused) {
            // Already paused — do nothing, dialog is already shown
          } else if (_engine.state == GameState.countdown) {
            // During revive countdown — ignore back button
          } else {
            // On menu/dead state, allow going back
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: effectiveBg,
        body: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) {
            _engine.isTouching = true;
            _audio.play('tap');
            _haptics.lightTap();
          },
          onPointerUp: (_) => _engine.isTouching = false,
          onPointerCancel: (_) => _engine.isTouching = false,
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              children: [
                // Game canvas — driven by _repaintNotifier, NOT setState
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _gamePainter,
                      isComplex: true,
                      willChange: true,
                      size: Size.infinite,
                    ),
                  ),
                ),
                // HUD overlay — only rebuilds on setState (score/phase changes)
                Positioned.fill(
                  child: RepaintBoundary(child: _buildHUD(isDark)),
                ),
                // Debug invincibility button (debug builds only)
                if (kDebugMode)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        _engine.debugInvincible = !_engine.debugInvincible;
                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _engine.debugInvincible
                              ? Colors.green.withValues(alpha: 0.7)
                              : Colors.red.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _engine.debugInvincible ? 'GOD' : 'DBG',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHUD(bool isDark) {
    final inverted = _engine.isPhase5Inverted;
    final fgColor = inverted
        ? Colors.black
        : (isDark ? Colors.white : Colors.black);
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return IgnorePointer(
      child: Column(
        children: [
          SizedBox(height: topPad + 16),

          // Score
          SizedBox(
            width: double.infinity,
            child: Text(
              '${_engine.score}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 56,
                fontWeight: FontWeight.w100,
                color: fgColor,
                letterSpacing: 0,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: Text(
              'BEST: ${_engine.highScore}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: FontWeight.w300,
                color: fgColor.withValues(alpha: 0.35),
                letterSpacing: 3,
              ),
            ),
          ),

          const Spacer(),

          // Tutorial: full instructions before first tap
          if (_engine.showTutorial && _engine.state == GameState.playing && !_engine.tutorialHasInteracted)
            Opacity(
              opacity: _engine.tutorialOpacity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'TAP TO START',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: fgColor.withValues(alpha: 0.6),
                        letterSpacing: 6,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _tutorialPoint('HOLD', 'PULL RIGHT', fgColor),
                        const SizedBox(width: 32),
                        _tutorialPoint('RELEASE', 'PULL LEFT', fgColor),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: fgColor.withValues(alpha: 0.15),
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'AVOID WALLS & OBSTACLES',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.w300,
                          color: fgColor.withValues(alpha: 0.35),
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Tutorial: controls hint after tap, fades at score 5
          if (_engine.showTutorial && _engine.state == GameState.playing && _engine.tutorialHasInteracted)
            Opacity(
              opacity: _engine.tutorialOpacity,
              child: Text(
                'HOLD \u2192 RIGHT    RELEASE \u2192 LEFT',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  color: fgColor.withValues(alpha: 0.3),
                  letterSpacing: 2,
                ),
              ),
            ),

          const Spacer(),
          SizedBox(height: bottomPad + 16),
        ],
      ),
    );
  }

  Widget _tutorialPoint(String action, String result, Color fgColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          action,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: fgColor.withValues(alpha: 0.5),
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          result,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            fontWeight: FontWeight.w300,
            color: fgColor.withValues(alpha: 0.3),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  void _showPauseDialog() {
    if (!mounted || _pauseDialogVisible) return;
    _pauseDialogVisible = true;
    _pauseDialogActionInProgress = false;

    // Pause menu overlays the game; freeze simulation/repaint until resume.
    _ticker.muted = true;
    final isDark = ref.read(isDarkThemeProvider);
    final bgColor = isDark ? Colors.black : Colors.white;
    final fgColor = isDark ? Colors.white : Colors.black;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: bgColor.withValues(alpha: 0.85),
      builder: (ctx) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            _resumeFromPauseDialog(ctx);
          }
        },
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'PAUSED',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 36,
                  fontWeight: FontWeight.w100,
                  color: fgColor,
                  letterSpacing: 8,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 40),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _resumeFromPauseDialog(ctx),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: fgColor.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'RESUME',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      color: fgColor,
                      letterSpacing: 4,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _quitFromPauseDialog(ctx),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  child: Text(
                    'QUIT',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      color: fgColor.withValues(alpha: 0.4),
                      letterSpacing: 4,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      _pauseDialogVisible = false;
      _pauseDialogActionInProgress = false;
    });
  }

  void _resumeFromPauseDialog(BuildContext ctx) {
    if (_pauseDialogActionInProgress) return;
    _pauseDialogActionInProgress = true;

    Navigator.of(ctx).pop();
    _engine.resume();
    _ticker.muted = false;
    _lastTime = Duration.zero;
    _accumulator = 0;
  }

  void _quitFromPauseDialog(BuildContext ctx) {
    if (_pauseDialogActionInProgress) return;
    _pauseDialogActionInProgress = true;

    _ticker.muted = false;
    Navigator.of(ctx).pop();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

/// Lightweight ChangeNotifier that signals the CustomPainter to repaint
/// without triggering a widget tree rebuild.
class _GameRepaintNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}
