import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polarity/features/game/engine/game_engine.dart';
import 'package:polarity/services/audio_service.dart';
import 'package:polarity/services/haptic_service.dart';
import 'package:polarity/services/storage_service.dart';
import 'package:polarity/services/ad_service.dart';
import 'package:polarity/services/iap_service.dart';
import 'package:polarity/services/connectivity_service.dart';
import 'package:polarity/services/leaderboard_service.dart';
import 'package:polarity/services/review_service.dart';
import 'package:polarity/services/share_service.dart';

// --- Singleton service providers ---

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService();
});

final hapticServiceProvider = Provider<HapticService>((ref) {
  return HapticService();
});

final adServiceProvider = Provider<AdService>((ref) {
  return AdService();
});

final iapServiceProvider = Provider<IapService>((ref) {
  return IapService();
});

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final leaderboardServiceProvider = Provider<LeaderboardService>((ref) {
  return LeaderboardService();
});

final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService();
});

final shareServiceProvider = Provider<ShareService>((ref) {
  return ShareService();
});

// --- Game engine provider ---

final gameEngineProvider = Provider<GameEngine>((ref) {
  return GameEngine();
});

// --- Settings state providers ---

final isDarkThemeProvider = StateProvider<bool>((ref) {
  return ref.read(storageServiceProvider).isDarkTheme;
});

final hapticsEnabledProvider = StateProvider<bool>((ref) {
  return ref.read(storageServiceProvider).hapticsEnabled;
});

final audioEnabledProvider = StateProvider<bool>((ref) {
  return ref.read(storageServiceProvider).audioEnabled;
});

final adsEnabledProvider = StateProvider<bool>((ref) {
  return ref.read(storageServiceProvider).adsEnabled;
});

final easyModeProvider = StateProvider<bool>((ref) {
  return ref.read(storageServiceProvider).easyMode;
});

final rememberThemeAcrossLaunchesProvider = StateProvider<bool>((ref) {
  return ref.read(storageServiceProvider).rememberThemeAcrossLaunches;
});

final eliteUnlockedProvider = StateProvider<bool>((ref) {
  return ref.read(storageServiceProvider).isEliteUnlocked;
});

final milestoneTierProvider = StateProvider<int>((ref) {
  return ref.read(storageServiceProvider).milestoneTier;
});

// V6: Reactive rewarded ad readiness — death screen watches this
final rewardedAdReadyProvider = StateProvider<bool>((ref) => false);
