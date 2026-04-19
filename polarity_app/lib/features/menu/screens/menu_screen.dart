import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polarity/features/game/screens/game_screen.dart';
import 'package:polarity/features/settings/screens/settings_screen.dart';
import 'package:polarity/core/constants.dart';
import 'package:polarity/providers/providers.dart';

// Easter egg tap reaction pools (by tap number)
const _easterEggReactions = <int, List<String>>{
  1: ['hmm 🤔', 'wait 👀', '👀', '🤔'],
  2: ['ooh whats this 🤔', 'hmm interesting 👀', 'curious 🧐', 'wait wait 👀'],
  3: ['ur onto something 🧐', 'keep tapping 👀', 'u found something 🤔', 'getting warmer 🧐'],
  4: ['not far now 🤔', 'few more 👀', 'keep going 🧐', 'almost found it 👀'],
  5: ['just a lil more 🤔', 'patience 🧐', 'so persistent 👀', 'dedicated 🤔'],
  6: ['ONE MORE 👀', 'this is it 🤔', 'final tap 🧐', 'LAST ONE 👀'],
};

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  double _titleOpacity = 0;
  double _buttonsOpacity = 0;
  bool _navActionInProgress = false;

  // Easter egg tap tracking
  int _easterEggTaps = 0;
  bool _easterEggDone = false;
  final _easterEggRng = Random();
  String? _reactionText;

  // Repaint notifier drives ONLY the background painter, no widget rebuild
  final _bgNotifier = _MenuBgNotifier();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _ticker.start();

    // Reset easter egg on fresh menu screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(easterEggActiveProvider.notifier).state = false;
    });

    // Staggered fade-in
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _titleOpacity = 1);
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _buttonsOpacity = 1);
    });
  }

  void _onTick(Duration elapsed) {
    _bgNotifier.phase = elapsed.inMicroseconds / 1000000.0;
    _bgNotifier.notify();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _bgNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkThemeProvider);
    final bgColor = isDark ? Colors.black : Colors.white;
    final fgColor = isDark ? Colors.white : Colors.black;
    final storage = ref.read(storageServiceProvider);
    final highScore = storage.getHighScore();
    final currentTier = ref.watch(milestoneTierProvider);
    final streak = storage.streakCount;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Animated background — driven by _bgNotifier, NOT setState
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _MenuBackgroundPainter(
                    notifier: _bgNotifier,
                    color: fgColor,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),

            // Main content (only rebuilds on theme/opacity changes)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  // Title
                  AnimatedOpacity(
                    opacity: _titleOpacity,
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOut,
                    child: Column(
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _onEasterEggTap,
                          child: Text(
                            'POLARITY',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 42,
                              fontWeight: FontWeight.w100,
                              color: fgColor,
                              letterSpacing: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 60,
                          height: 1,
                          color: fgColor.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 12),
                        // Easter egg reaction (inline, below divider)
                        AnimatedOpacity(
                          opacity: _reactionText != null ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: SizedBox(
                            height: 28,
                            child: Text(
                              _reactionText ?? '',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: fgColor.withValues(alpha: 0.6),
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (highScore > 0)
                          Text(
                            'BEST: $highScore',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              fontWeight: FontWeight.w300,
                              color: fgColor.withValues(alpha: 0.35),
                              letterSpacing: 4,
                            ),
                          ),
                        if (currentTier > 0) ...[
                          const SizedBox(height: 6),
                          Text(
                            '◆ ${GameConstants.tierNames[currentTier]}',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: GameConstants.tierColors[currentTier],
                              letterSpacing: 3,
                            ),
                          ),
                        ],
                        if (streak >= 2) ...[
                          const SizedBox(height: 8),
                          Text(
                            '🔥 $streak-DAY STREAK',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.w300,
                              color: fgColor.withValues(alpha: 0.3),
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Play button
                  AnimatedOpacity(
                    opacity: _buttonsOpacity,
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOut,
                    child: Column(
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _startGame,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 56,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: fgColor.withValues(alpha: 0.4),
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'PLAY',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 18,
                                fontWeight: FontWeight.w300,
                                color: fgColor,
                                letterSpacing: 8,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Bottom row: Leaderboard, Settings
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _IconButton(
                              icon: Icons.emoji_events_outlined,
                              color: fgColor,
                              onTap: () async {
                                if (_navActionInProgress) return;
                                _navActionInProgress = true;
                                ref.read(audioServiceProvider).play('menu');
                                ref
                                    .read(hapticServiceProvider)
                                    .selectionClick();
                                await ref
                                    .read(leaderboardServiceProvider)
                                    .showLeaderboard();
                                if (mounted) {
                                  _navActionInProgress = false;
                                }
                              },
                            ),
                            const SizedBox(width: 32),
                            _IconButton(
                              icon: Icons.tune_outlined,
                              color: fgColor,
                              onTap: () async {
                                if (_navActionInProgress) return;
                                _navActionInProgress = true;
                                ref.read(audioServiceProvider).play('menu');
                                ref
                                    .read(hapticServiceProvider)
                                    .selectionClick();
                                await Navigator.of(context).push(
                                  PageRouteBuilder(
                                    opaque: true,
                                    pageBuilder: (ctx, a1, a2) =>
                                        const SettingsScreen(),
                                    transitionsBuilder:
                                        (ctx, animation, a2, child) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      );
                                    },
                                    transitionDuration:
                                        const Duration(milliseconds: 250),
                                  ),
                                );
                                if (mounted) {
                                  _navActionInProgress = false;
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onEasterEggTap() {
    if (_easterEggDone) return;

    _easterEggTaps++;
    ref.read(hapticServiceProvider).selectionClick();

    String reaction;
    if (_easterEggTaps >= 7) {
      reaction = 'ilysm';
      _easterEggDone = true;
      ref.read(easterEggActiveProvider.notifier).state = true;
    } else {
      final pool = _easterEggReactions[_easterEggTaps] ?? _easterEggReactions[6]!;
      reaction = pool[_easterEggRng.nextInt(pool.length)];
    }

    _showReaction(reaction);
  }

  void _showReaction(String text) {
    setState(() => _reactionText = text);

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted && _reactionText == text) {
        setState(() => _reactionText = null);
      }
    });
  }

  void _startGame() {
    if (_navActionInProgress) return;
    _navActionInProgress = true;

    ref.read(audioServiceProvider).play('menu');
    ref.read(hapticServiceProvider).mediumImpact();
    Navigator.of(context)
        .push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (ctx, a1, a2) => const GameScreen(),
        transitionsBuilder: (ctx, animation, a2, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    )
        .then((_) {
      if (mounted) {
        _navActionInProgress = false;
      }
    });
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, color: color.withValues(alpha: 0.6), size: 22),
      ),
    );
  }
}

/// Lightweight notifier that drives the background painter repaint
/// without triggering any widget tree rebuilds.
class _MenuBgNotifier extends ChangeNotifier {
  double phase = 0;
  void notify() => notifyListeners();
}

class _MenuBackgroundPainter extends CustomPainter {
  final _MenuBgNotifier notifier;
  final Color color;

  // Reusable Paint objects — mutated in-place per frame (zero allocation)
  final Paint _circlePaint = Paint();
  final Paint _gridPaint = Paint();

  _MenuBackgroundPainter({required this.notifier, required this.color})
      : super(repaint: notifier);

  @override
  void paint(Canvas canvas, Size size) {
    final phase = notifier.phase;
    _circlePaint
      ..color = color.withValues(alpha: 0.03)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;

    for (int i = 0; i < 8; i++) {
      final radius = 40.0 + i * 50 + sin(phase * 0.3 + i * 0.5) * 10;
      canvas.drawCircle(Offset(cx, cy), radius, _circlePaint);
    }

    _gridPaint
      ..color = color.withValues(alpha: 0.015)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.fill;

    const spacing = 50.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), _gridPaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), _gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MenuBackgroundPainter oldDelegate) =>
      oldDelegate.color != color;
}
