import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:polarity/app.dart';
import 'package:polarity/core/security/score_guard.dart';
import 'package:polarity/features/game/visual/theme_registry.dart';
import 'package:polarity/providers/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode for optimal gameplay
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // True full screen for entire app — hide status bar and nav bar
  // Set immersive BEFORE any other initialization to minimize bar flash
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));

  // Initialize security
  ScoreGuard.initialize();

  // Keep screen awake
  WakelockPlus.enable();

  // Create Riverpod container and initialize services
  final container = ProviderContainer();

  // Initialize all services in parallel
  await Future.wait([
    container.read(storageServiceProvider).init(),
    container.read(audioServiceProvider).init(),
    container.read(hapticServiceProvider).init(),
    container.read(connectivityServiceProvider).init(),
  ]);

  final storage = container.read(storageServiceProvider);
  final adService = container.read(adServiceProvider);
  final iapService = container.read(iapServiceProvider);

  // Apply persisted ad setting before ad init to avoid loading ads for premium users.
  adService.adsEnabled = storage.adsEnabled;

  // Wire rewarded readiness callback before ad init to avoid missing first ready event.
  adService.onRewardedReadyChanged = (ready) {
    container.read(rewardedAdReadyProvider.notifier).state = ready;
  };
  container.read(rewardedAdReadyProvider.notifier).state =
      adService.isRewardedReady;

  // IAP callback must be wired before IAP init/restore to avoid missing early
  // restored purchase events and accidentally leaving ads enabled.
  iapService.onPurchaseUpdated = (isPremium) {
    if (isPremium) {
      adService.adsEnabled = false;
      storage.setAdsEnabled(false);
      // Sync Riverpod state so death screen hides revive button immediately.
      container.read(adsEnabledProvider.notifier).state = false;
    }
  };

  // Initialize monetization services (non-blocking, errors caught)
  adService.init().catchError((_) {});
  iapService.init().catchError((_) {});
  container.read(leaderboardServiceProvider).init().catchError((_) {});

  // Apply persisted settings to services
  container.read(audioServiceProvider).enabled = storage.audioEnabled;
  container.read(hapticServiceProvider).enabled = storage.hapticsEnabled;

  // Load high score and difficulty into engine
  final engine = container.read(gameEngineProvider);
  engine.highScore = storage.getHighScore();
  engine.easyMode = storage.easyMode;
  engine.eliteUnlocked = storage.isEliteUnlocked;
  engine.currentTier = storage.milestoneTier;
  engine.previousTier = engine.currentTier;
  engine.highScoreMode = storage.highScoreIsEasyMode;
  engine.deserializeThemeRotations(storage.themeRotationsJson);
  ScoreGuard.setHighScore(engine.highScore);

  // Restore active theme from storage (persists across app restart)
  final savedTier = storage.activeThemeTier;
  if (storage.rememberThemeAcrossLaunches && savedTier > 0) {
    engine.activeTheme = ThemeRegistry.restoreTheme(
      savedTier,
      storage.activeThemeVariation,
      storage.activeThemeScore,
      engine.themeRotationIndices,
    );
    engine.rebuildInvertedCache();
  }

  // Update day streak
  storage.updateStreak();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const PolarityApp(),
    ),
  );
}
