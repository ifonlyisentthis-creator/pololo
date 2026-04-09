import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot/screenshot.dart';
import 'package:polarity/core/constants.dart';
import 'package:polarity/providers/providers.dart';

class DeathScreen extends ConsumerStatefulWidget {
  final int score;
  final int highScore;
  final bool isNewHighScore;
  final String deathMessage;
  final bool isPraise;
  final bool isSessionBest;
  final bool tierJustUnlocked;
  final int currentTier;
  final bool easyMode;
  final bool hasRevivedThisRun;
  final VoidCallback onRestart;
  final VoidCallback onRevive;

  const DeathScreen({
    super.key,
    required this.score,
    required this.highScore,
    required this.isNewHighScore,
    required this.deathMessage,
    required this.isPraise,
    required this.isSessionBest,
    required this.tierJustUnlocked,
    required this.currentTier,
    required this.easyMode,
    required this.hasRevivedThisRun,
    required this.onRestart,
    required this.onRevive,
  });

  @override
  ConsumerState<DeathScreen> createState() => _DeathScreenState();
}

class _DeathScreenState extends ConsumerState<DeathScreen>
    with SingleTickerProviderStateMixin {
  double _opacity = 0;
  bool _actionInProgress = false;
  bool _reviveReady = false; // true after ad watched, waiting for user tap
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) setState(() => _opacity = 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkThemeProvider);
    final bgColor = isDark ? Colors.black : Colors.white;
    final fgColor = isDark ? Colors.white : Colors.black;
    final connectivity = ref.read(connectivityServiceProvider);
    final adsEnabled = ref.watch(adsEnabledProvider);
    final isPremium = !adsEnabled; // Paid to remove ads = premium
    final isRewardedReady = ref.watch(rewardedAdReadyProvider);

    final showReviveButton = !widget.hasRevivedThisRun &&
        (_reviveReady ||
            isPremium ||
            (adsEnabled && connectivity.isOnline && isRewardedReady));
    final isPremiumRevive = isPremium;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: bgColor,
        body: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          child: Container(
            color: bgColor,
            child: SafeArea(
              child: Screenshot(
                controller: _screenshotController,
                child: Container(
                  color: bgColor,
                  width: double.infinity,
                  height: double.infinity,
                  child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: constraints.maxHeight * 0.12),

                              // New High Score badge
                              if (widget.isNewHighScore) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFFFFD60A)
                                          .withValues(alpha: 0.6),
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'NEW BEST',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFFFFD60A),
                                      letterSpacing: 4,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Tier badge
                              if (widget.currentTier > 0) ...[
                                Text(
                                  '\u25C6 ${GameConstants.tierNames[widget.currentTier]}',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: widget.tierJustUnlocked ? 13 : 11,
                                    fontWeight: FontWeight.w500,
                                    color: GameConstants.tierColors[widget.currentTier],
                                    letterSpacing: 3,
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Score
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${widget.score}',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 80,
                                    fontWeight: FontWeight.w100,
                                    color: fgColor,
                                    letterSpacing: -2,
                                    height: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'BEST: ${widget.highScore}',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w300,
                                  color: fgColor.withValues(alpha: 0.35),
                                  letterSpacing: 4,
                                ),
                              ),

                              // Session best badge
                              if (widget.isSessionBest) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'SESSION BEST',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF30D158).withValues(alpha: 0.6),
                                    letterSpacing: 3,
                                  ),
                                ),
                              ],

                              const SizedBox(height: 32),

                              // Roast
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: widget.isPraise
                                        ? const Color(0xFF30D158).withValues(alpha: 0.15)
                                        : fgColor.withValues(alpha: 0.08),
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  widget.deathMessage,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w300,
                                    color: fgColor.withValues(alpha: 0.5),
                                    height: 1.5,
                                  ),
                                ),
                              ),

                              SizedBox(height: constraints.maxHeight * 0.08),

                              // Revive button
                              if (showReviveButton) ...[
                                GestureDetector(
                                  onTap: _onRevive,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color(0xFF30D158)
                                            .withValues(alpha: 0.5),
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _reviveReady
                                              ? Icons.play_arrow_rounded
                                              : Icons.play_circle_outline,
                                          color: const Color(0xFF30D158),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          _reviveReady
                                              ? 'CONTINUE'
                                              : (isPremiumRevive
                                                  ? 'REVIVE'
                                                  : 'WATCH AD TO REVIVE'),
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w400,
                                            color: Color(0xFF30D158),
                                            letterSpacing: 2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Restart button
                              GestureDetector(
                                onTap: () {
                                  if (_actionInProgress) return;
                                  _actionInProgress = true;
                                  ref.read(audioServiceProvider).play('menu');
                                  ref
                                      .read(hapticServiceProvider)
                                      .mediumImpact();
                                  widget.onRestart();
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: fgColor.withValues(alpha: 0.3),
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'RESTART',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w300,
                                      color: fgColor,
                                      letterSpacing: 6,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Bottom actions: Share, Menu
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _BottomAction(
                                    icon: Icons.share_outlined,
                                    label: 'SHARE',
                                    color: fgColor,
                                    onTap: _onShare,
                                  ),
                                  const SizedBox(width: 32),
                                  _BottomAction(
                                    icon: Icons.home_outlined,
                                    label: 'MENU',
                                    color: fgColor,
                                    onTap: () {
                                      ref
                                          .read(audioServiceProvider)
                                          .play('menu');
                                      // Pop back to menu (first route) without
                                      // showing intermediate screens
                                      Navigator.of(context)
                                          .popUntil((route) => route.isFirst);
                                    },
                                  ),
                                ],
                              ),

                              SizedBox(height: constraints.maxHeight * 0.08),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }

  void _onRevive() async {
    if (_actionInProgress) return;
    _actionInProgress = true;

    ref.read(audioServiceProvider).play('menu');
    ref.read(hapticServiceProvider).mediumImpact();

    // Already watched ad — user is pressing CONTINUE
    if (_reviveReady) {
      widget.onRevive();
      return;
    }

    final adsEnabled = ref.read(adsEnabledProvider);

    if (!adsEnabled) {
      // Premium user — free revive, no ad
      widget.onRevive();
      return;
    }

    // Free user — must watch ad, then wait for user to tap CONTINUE
    final adService = ref.read(adServiceProvider);
    final shown = await adService.showRewarded(
      onRewarded: () {
        // Ad completed — don't auto-revive, just unlock the CONTINUE button
        if (mounted) {
          setState(() {
            _reviveReady = true;
            _actionInProgress = false;
          });
        }
      },
      onDismissed: () {
        // Ad closed (early dismiss or after reward) — unlock button if no reward
        if (mounted && !_reviveReady) {
          setState(() {
            _actionInProgress = false;
          });
        }
      },
    );
    if (!shown && mounted) {
      _actionInProgress = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ad not available. Try again later.',
            style: TextStyle(fontFamily: 'monospace'),
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _onShare() async {
    ref.read(audioServiceProvider).play('menu');
    ref.read(hapticServiceProvider).selectionClick();

    final shareService = ref.read(shareServiceProvider);
    await shareService.shareScoreWithScreenshot(
      controller: _screenshotController,
      score: widget.score,
      highScore: widget.highScore,
      roast: widget.deathMessage,
    );
  }
}

class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BottomAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color.withValues(alpha: 0.5), size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              fontWeight: FontWeight.w300,
              color: color.withValues(alpha: 0.35),
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}
