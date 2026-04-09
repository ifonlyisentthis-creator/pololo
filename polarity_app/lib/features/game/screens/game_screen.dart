import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polarity/features/game/engine/game_engine.dart';
import 'package:polarity/features/game/painters/game_painter.dart';
import 'package:polarity/features/death/screens/death_screen.dart';
import 'package:polarity/providers/providers.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late Ticker _ticker;
  Duration _lastTime = Duration.zero;
  late GameEngine _engine;
  int _lastScore = -1;
  int _lastPhase = -1;
  bool _deathScreenShown = false;
  int _lastTutorialBucket = -1;

  // Repaint notifier — triggers only the CustomPaint, not the entire widget tree
  final _repaintNotifier = _GameRepaintNotifier();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _engine = ref.read(gameEngineProvider);
    _ticker = createTicker(_onTick);
    _ticker.start();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      _engine.init(size.width, size.height);

      final storage = ref.read(storageServiceProvider);
      final shouldTutor = storage.isFirstLaunch || storage.getHighScore() < 3;
      _engine.configureTutorial(shouldTutor);
      if (storage.isFirstLaunch) storage.setFirstLaunchDone();

      // V2: Load elite status + tier from storage
      _engine.eliteUnlocked = ref.read(eliteUnlockedProvider);
      _engine.currentTier = storage.milestoneTier;
      _engine.previousTier = _engine.currentTier;

      _engine.startGame();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Auto-pause when app goes to background
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // V5: Also pause during countdown (not just playing)
      if (_engine.state == GameState.playing ||
          _engine.state == GameState.countdown) {
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
    final dt = (elapsed - _lastTime).inMicroseconds / 1000000.0;
    _lastTime = elapsed;

    _engine.update(dt);

    // Notify only the CustomPaint to repaint — avoids rebuilding the entire widget tree
    _repaintNotifier.notify();

    if (_engine.score != _lastScore) {
      _lastScore = _engine.score;
      _onScoreChanged();
    }

    if (_engine.currentPhase != _lastPhase) {
      if (_lastPhase >= 0) _onPhaseChanged();
      _lastPhase = _engine.currentPhase;
    }

    if (_engine.state == GameState.dead && !_deathScreenShown) {
      _deathScreenShown = true;
      _onDeath();
    }

    // Shield event polling
    if (_engine.shieldJustBroke) {
      _engine.shieldJustBroke = false;
      ref.read(audioServiceProvider).play('shield_break');
      ref.read(hapticServiceProvider).mediumImpact();
    }
    if (_engine.shieldJustPickedUp) {
      _engine.shieldJustPickedUp = false;
      ref.read(audioServiceProvider).play('shield_pickup');
      ref.read(hapticServiceProvider).lightTap();
    }

    // V2: Elite unlock event
    if (_engine.eliteJustUnlocked) {
      _engine.eliteJustUnlocked = false;
      ref.read(audioServiceProvider).play('elite_unlock');
      ref.read(hapticServiceProvider).heavyImpact();
      // Persist
      ref.read(eliteUnlockedProvider.notifier).state = true;
      ref.read(storageServiceProvider).setEliteUnlocked(true);
    }

    // V2: High score matched heartbeat
    if (_engine.highScoreJustMatched) {
      _engine.highScoreJustMatched = false;
      ref.read(hapticServiceProvider).heavyImpact();
    }

    // V3: Theme activation event
    if (_engine.themeJustActivated) {
      _engine.themeJustActivated = false;
      ref.read(audioServiceProvider).play('phase'); // reuse phase sound for now
      ref.read(hapticServiceProvider).mediumImpact();
      // Persist rotation indices + active theme for app restart
      final storage = ref.read(storageServiceProvider);
      storage.setThemeRotationsJson(_engine.serializeThemeRotations());
      final at = _engine.activeTheme;
      if (at != null) {
        storage.setActiveTheme(at.tier, at.variation, _engine.score);
      }
    }

    // V4: Troll activation event
    if (_engine.trollSystem.trollJustActivated) {
      _engine.trollSystem.trollJustActivated = false;
      ref.read(hapticServiceProvider).lightTap();
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
        setState(() {});
      }
    }
  }

  void _onScoreChanged() {
    // Trigger HUD rebuild for score text
    if (mounted) setState(() {});
    ref.read(audioServiceProvider).play('score');
    ref.read(hapticServiceProvider).lightTap();
  }

  void _onPhaseChanged() {
    if (mounted) setState(() {});
    ref.read(audioServiceProvider).play('phase');
    ref.read(hapticServiceProvider).phaseVibrate();
  }

  void _onDeath() {
    if (mounted) setState(() {});
    ref.read(audioServiceProvider).play('death');
    ref.read(hapticServiceProvider).heavyImpact();

    if (_engine.isNewHighScore) {
      final storage = ref.read(storageServiceProvider);
      storage.setHighScore(_engine.highScore);
      storage.setHighScoreMode(_engine.easyMode);
      ref.read(leaderboardServiceProvider).submitScore(_engine.highScore);
      if (_engine.shouldRequestReview) {
        ref.read(reviewServiceProvider).requestReviewIfEligible();
      }
    }

    // V2: Persist tier if upgraded — Bug fix 3: consume immediately
    final tierUp = _engine.tierJustUnlocked;
    _engine.tierJustUnlocked = false;
    if (tierUp) {
      final storage = ref.read(storageServiceProvider);
      storage.setMilestoneTier(_engine.currentTier);
      ref.read(milestoneTierProvider.notifier).state = _engine.currentTier;
      ref.read(audioServiceProvider).play('tier_up');
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
          if (mounted) _ticker.muted = false;
        },
      );
    }

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      _showDeathScreen(tierUp: tierUp);
    });
  }

  void _showDeathScreen({bool tierUp = false}) {
    final deathMessage = _engine.getDeathMessage();
    final isPraise = _engine.lastMessageWasPraise;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (context, animation1, animation2) => DeathScreen(
          score: _engine.score,
          highScore: _engine.highScore,
          isNewHighScore: _engine.isNewHighScore,
          deathMessage: deathMessage,
          isPraise: isPraise,
          hasRevivedThisRun: _engine.hasRevivedThisRun,
          onRestart: _restart,
          onRevive: _revive,
          isSessionBest: _engine.isSessionBest && !_engine.isNewHighScore,
          tierJustUnlocked: tierUp,
          currentTier: _engine.currentTier,
          easyMode: _engine.easyMode,
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
    _deathScreenShown = false;
    _lastScore = -1;
    _lastPhase = -1;

    final storage = ref.read(storageServiceProvider);
    final shouldTutor = storage.getHighScore() < 3;
    _engine.configureTutorial(shouldTutor);

    _engine.startGame();
    if (mounted) setState(() {});
  }

  void _revive() {
    Navigator.of(context).pop();
    _deathScreenShown = false;
    ref.read(audioServiceProvider).play('revive');
    _engine.revive();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _repaintNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkThemeProvider);
    final inverted = _engine.isPhase5Inverted;
    final effectiveBg =
        inverted ? Colors.white : (isDark ? Colors.black : Colors.white);

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
            ref.read(audioServiceProvider).play('tap');
            ref.read(hapticServiceProvider).lightTap();
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
                      painter: GamePainter(
                        engine: _engine,
                        isDarkTheme: isDark,
                        repaint: _repaintNotifier,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),
                // HUD overlay — only rebuilds on setState (score/phase changes)
                Positioned.fill(
                  child: RepaintBoundary(
                    child: _buildHUD(isDark),
                  ),
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
    final fgColor =
        inverted ? Colors.black : (isDark ? Colors.white : Colors.black);
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

          // Tutorial text
          if (_engine.showTutorial && _engine.state == GameState.playing)
            Opacity(
              opacity: _engine.tutorialOpacity,
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  'HOLD TO PULL RIGHT\nRELEASE TO PULL LEFT',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    color: fgColor.withValues(alpha: 0.25),
                    letterSpacing: 2,
                    height: 2.0,
                  ),
                ),
              ),
            ),

          const Spacer(),
          SizedBox(height: bottomPad + 16),
        ],
      ),
    );
  }

  void _showPauseDialog() {
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
            // Back button on pause dialog → resume the game
            Navigator.of(ctx).pop();
            _engine.resume();
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
                onTap: () {
                  Navigator.of(ctx).pop();
                  _engine.resume();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
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
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
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
            ],
          ),
        ),
      ),
    );
  }
}

/// Lightweight ChangeNotifier that signals the CustomPainter to repaint
/// without triggering a widget tree rebuild.
class _GameRepaintNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}
