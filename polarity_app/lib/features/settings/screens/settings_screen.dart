import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:polarity/core/constants.dart';
import 'package:polarity/providers/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkThemeProvider);
    final hapticsOn = ref.watch(hapticsEnabledProvider);
    final audioOn = ref.watch(audioEnabledProvider);
    final adsOn = ref.watch(adsEnabledProvider);
    final rememberTheme = ref.watch(rememberThemeAcrossLaunchesProvider);
    final bgColor = isDark ? Colors.black : Colors.white;
    final fgColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // Header (fixed, never scrolls)
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      ref.read(audioServiceProvider).play('menu');
                      Navigator.of(context).pop();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: fgColor.withValues(alpha: 0.6),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'SETTINGS',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 22,
                      fontWeight: FontWeight.w200,
                      color: fgColor,
                      letterSpacing: 6,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Scrollable content — prevents overflow on small screens
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // Theme toggle
                      _SettingsTile(
                        label: 'THEME',
                        description: isDark ? 'PITCH BLACK' : 'PURE WHITE',
                        value: isDark,
                        fgColor: fgColor,
                        onChanged: (val) {
                          ref.read(isDarkThemeProvider.notifier).state = val;
                          ref.read(storageServiceProvider).setDarkTheme(val);
                          ref.read(hapticServiceProvider).selectionClick();
                        },
                      ),

                      _divider(fgColor),

                      // Haptics toggle
                      _SettingsTile(
                        label: 'HAPTICS',
                        description: hapticsOn ? 'ON' : 'OFF',
                        value: hapticsOn,
                        fgColor: fgColor,
                        onChanged: (val) {
                          ref.read(hapticsEnabledProvider.notifier).state = val;
                          ref
                              .read(storageServiceProvider)
                              .setHapticsEnabled(val);
                          ref.read(hapticServiceProvider).enabled = val;
                          if (val) {
                            ref.read(hapticServiceProvider).selectionClick();
                          }
                        },
                      ),

                      _divider(fgColor),

                      // Audio toggle
                      _SettingsTile(
                        label: 'AUDIO',
                        description: audioOn ? 'ON' : 'OFF',
                        value: audioOn,
                        fgColor: fgColor,
                        onChanged: (val) {
                          ref.read(audioEnabledProvider.notifier).state = val;
                          ref.read(storageServiceProvider).setAudioEnabled(val);
                          ref.read(audioServiceProvider).enabled = val;
                          ref.read(hapticServiceProvider).selectionClick();
                        },
                      ),

                      _divider(fgColor),

                      // Difficulty toggle
                      _SettingsTile(
                        label: 'DIFFICULTY',
                        description:
                            ref.watch(easyModeProvider) ? 'EASY' : 'HARD',
                        value: ref.watch(easyModeProvider),
                        fgColor: fgColor,
                        onChanged: (val) {
                          ref.read(easyModeProvider.notifier).state = val;
                          ref.read(storageServiceProvider).setEasyMode(val);
                          ref.read(gameEngineProvider).easyMode = val;
                          ref.read(hapticServiceProvider).selectionClick();
                        },
                      ),

                      _divider(fgColor),

                      // Remember active theme across app relaunch
                      _SettingsTile(
                        label: 'REMEMBER THEME',
                        description: rememberTheme
                            ? 'ON (REOPEN KEEP)'
                            : 'OFF (SESSION ONLY)',
                        value: rememberTheme,
                        fgColor: fgColor,
                        onChanged: (val) {
                          ref
                              .read(rememberThemeAcrossLaunchesProvider.notifier)
                              .state = val;
                          final storage = ref.read(storageServiceProvider);
                          storage.setRememberThemeAcrossLaunches(val);
                          if (!val) {
                            storage.clearActiveTheme();
                          }
                          ref.read(hapticServiceProvider).selectionClick();
                        },
                      ),

                      _divider(fgColor),

                      // Remove Ads / Premium
                      if (adsOn) ...[
                        GestureDetector(
                          onTap: () async {
                            ref.read(hapticServiceProvider).selectionClick();
                            final iap = ref.read(iapServiceProvider);
                            // Just launch the purchase flow.
                            // Actual ad-disable happens via the IAP purchase
                            // stream listener (in main.dart) only after payment
                            // is confirmed by the store.
                            await iap.buyRemoveAds();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'REMOVE ADS',
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w300,
                                          color: fgColor,
                                          letterSpacing: 3,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '\$${GameConstants.iapPrice.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w300,
                                          color:
                                              fgColor.withValues(alpha: 0.4),
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.shopping_cart_outlined,
                                  color: fgColor.withValues(alpha: 0.4),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        _divider(fgColor),
                      ],

                      // Restore Purchases
                      GestureDetector(
                        onTap: () async {
                          ref.read(hapticServiceProvider).selectionClick();
                          await ref.read(iapServiceProvider).restorePurchases();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'RESTORE PURCHASES',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                              color: fgColor,
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Privacy Policy
                      Center(
                        child: GestureDetector(
                          onTap: () async {
                            ref.read(hapticServiceProvider).selectionClick();
                            final uri =
                                Uri.parse(GameConstants.privacyPolicyUrl);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'Privacy Policy',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                fontWeight: FontWeight.w300,
                                color: fgColor.withValues(alpha: 0.3),
                                letterSpacing: 1,
                                decoration: TextDecoration.underline,
                                decorationColor:
                                    fgColor.withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider(Color fgColor) {
    return Container(
      height: 1,
      color: fgColor.withValues(alpha: 0.06),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String label;
  final String description;
  final bool value;
  final Color fgColor;
  final ValueChanged<bool> onChanged;

  const _SettingsTile({
    required this.label,
    required this.description,
    required this.value,
    required this.fgColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    color: fgColor,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    color: fgColor.withValues(alpha: 0.35),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          // Custom minimal toggle
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: value
                      ? fgColor.withValues(alpha: 0.5)
                      : fgColor.withValues(alpha: 0.15),
                ),
                color: value
                    ? fgColor.withValues(alpha: 0.1)
                    : Colors.transparent,
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment:
                    value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.all(3),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: value
                        ? fgColor.withValues(alpha: 0.8)
                        : fgColor.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
