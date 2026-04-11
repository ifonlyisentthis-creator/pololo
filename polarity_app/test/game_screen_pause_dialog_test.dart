import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polarity/features/game/engine/game_engine.dart';
import 'package:polarity/features/game/screens/game_screen.dart';
import 'package:polarity/providers/providers.dart';
import 'package:polarity/services/audio_service.dart';
import 'package:polarity/services/haptic_service.dart';
import 'package:polarity/services/storage_service.dart';

class _FakeStorageService extends StorageService {
  bool _firstLaunch = false;
  int _highScore = 50;
  bool _adsEnabled = true;
  bool _isDarkTheme = true;
  bool _hapticsEnabled = true;
  bool _audioEnabled = true;
  bool _easyMode = false;
  bool _eliteUnlocked = false;
  int _milestoneTier = 0;
  bool _rememberThemeAcrossLaunches = true;
  int _leaderboardBestEasyScore = 0;
  int _leaderboardBestHardScore = 0;

  @override
  int getHighScore() => _highScore;

  @override
  Future<void> setHighScore(int score) async {
    _highScore = score;
  }

  @override
  bool get adsEnabled => _adsEnabled;

  @override
  Future<void> setAdsEnabled(bool value) async {
    _adsEnabled = value;
  }

  @override
  bool get isDarkTheme => _isDarkTheme;

  @override
  Future<void> setDarkTheme(bool value) async {
    _isDarkTheme = value;
  }

  @override
  bool get hapticsEnabled => _hapticsEnabled;

  @override
  Future<void> setHapticsEnabled(bool value) async {
    _hapticsEnabled = value;
  }

  @override
  bool get audioEnabled => _audioEnabled;

  @override
  Future<void> setAudioEnabled(bool value) async {
    _audioEnabled = value;
  }

  @override
  bool get isFirstLaunch => _firstLaunch;

  @override
  Future<void> setFirstLaunchDone() async {
    _firstLaunch = false;
  }

  @override
  bool get easyMode => _easyMode;

  @override
  Future<void> setEasyMode(bool value) async {
    _easyMode = value;
  }

  @override
  bool get isEliteUnlocked => _eliteUnlocked;

  @override
  Future<void> setEliteUnlocked(bool value) async {
    _eliteUnlocked = value;
  }

  @override
  int get milestoneTier => _milestoneTier;

  @override
  Future<void> setMilestoneTier(int tier) async {
    _milestoneTier = tier;
  }

  @override
  bool get rememberThemeAcrossLaunches => _rememberThemeAcrossLaunches;

  @override
  Future<void> setRememberThemeAcrossLaunches(bool value) async {
    _rememberThemeAcrossLaunches = value;
  }

  @override
  Future<void> setHighScoreMode(bool easyMode) async {}

  @override
  int get leaderboardBestEasyScore => _leaderboardBestEasyScore;

  @override
  Future<void> setLeaderboardBestEasyScore(int score) async {
    _leaderboardBestEasyScore = score;
  }

  @override
  int get leaderboardBestHardScore => _leaderboardBestHardScore;

  @override
  Future<void> setLeaderboardBestHardScore(int score) async {
    _leaderboardBestHardScore = score;
  }

  @override
  Future<void> setThemeRotationsJson(String json) async {}

  @override
  Future<void> setActiveTheme(int tier, int variation, int score) async {}

  @override
  Future<void> clearActiveTheme() async {}
}

class _SilentAudioService extends AudioService {
  @override
  Future<void> play(String sfxName) async {}
}

class _SilentHapticService extends HapticService {
  @override
  Future<void> lightTap() async {}

  @override
  Future<void> mediumImpact() async {}

  @override
  Future<void> heavyImpact() async {}

  @override
  Future<void> selectionClick() async {}

  @override
  Future<void> phaseVibrate() async {}
}

void main() {
  testWidgets(
    'repeated background events do not stack pause dialogs',
    (tester) async {
      final engine = GameEngine();
      final storage = _FakeStorageService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gameEngineProvider.overrideWithValue(engine),
            storageServiceProvider.overrideWithValue(storage),
            audioServiceProvider.overrideWithValue(_SilentAudioService()),
            hapticServiceProvider.overrideWithValue(_SilentHapticService()),
          ],
          child: const MaterialApp(home: GameScreen()),
        ),
      );

      await tester.pump();
      await tester.pump();
      expect(engine.state, GameState.playing);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();
      expect(find.text('PAUSED'), findsOneWidget);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();
      expect(find.text('PAUSED'), findsOneWidget);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}