import 'package:shared_preferences/shared_preferences.dart';
import 'package:polarity/core/security/score_guard.dart';

enum DailyMissionProgress {
  inProgress,
  completedNow,
  failedNow,
  alreadyResolved,
}

class StorageService {
  static const _highScoreKey = 'hs_v1';
  static const _adsEnabledKey = 'ads_enabled';
  static const _isDarkThemeKey = 'is_dark_theme';
  static const _hapticsEnabledKey = 'haptics_enabled';
  static const _audioEnabledKey = 'audio_enabled';
  static const _firstLaunchKey = 'first_launch';
  static const _easyModeKey = 'easy_mode';
  static const _eliteUnlockedKey = 'elite_unlocked';
  static const _milestoneTierKey = 'milestone_tier';
  static const _streakCountKey = 'streak_count';
  static const _lastPlayDateKey = 'last_play_date';
  static const _highScoreModeKey = 'hs_mode';
  static const _leaderboardBestTotalKey = 'lb_best_total';
  static const _leaderboardBestEasyKey = 'lb_best_easy';
  static const _leaderboardBestHardKey = 'lb_best_hard';
  static const _leaderboardPreferredViewKey = 'lb_pref_view';
  static const _retentionDayKey = 'retention_day';
  static const _dailyChallengeTargetKey = 'daily_challenge_target';
  static const _dailyChallengeCompletedDayKey =
      'daily_challenge_completed_day';
  static const _dailyMissionDayKey = 'daily_mission_day';
  static const _dailyMissionGoalKey = 'daily_mission_goal';
  static const _dailyMissionRunsKey = 'daily_mission_runs';
  static const _dailyMissionCompletedDayKey = 'daily_mission_completed_day';
  static const _dailyMissionFailedDayKey = 'daily_mission_failed_day';
  static const _reviveTokensKey = 'revive_tokens';
  static const _themeRotationsKey = 'theme_rotations';
  static const _rememberThemeAcrossLaunchesKey =
      'remember_theme_across_launches';
  static const _activeThemeTierKey = 'active_theme_tier';
  static const _activeThemeVarKey = 'active_theme_var';
  static const _activeThemeScoreKey = 'active_theme_score';

  static const int _maxReviveTokens = 1;
  static const int _dailyMissionPassLimit = 5;

  late SharedPreferences _prefs;

  String _dateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _todayString() => _dateString(DateTime.now());

  DateTime? _tryParseDateString(String dateString) {
    final parts = dateString.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d, 12);
  }

  int _daySeed(String dayString) {
    final day = _tryParseDateString(dayString);
    if (day == null) return 0;
    return DateTime.utc(day.year, day.month, day.day).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- High Score (HMAC protected) ---
  int getHighScore() {
    final stored = _prefs.getString(_highScoreKey);
    if (stored == null) return 0;
    return ScoreGuard.decodeFromStorage(stored) ?? 0;
  }

  Future<void> setHighScore(int score) async {
    final encoded = ScoreGuard.encodeForStorage(score);
    await _prefs.setString(_highScoreKey, encoded);
  }

  // --- Ads ---
  bool get adsEnabled => _prefs.getBool(_adsEnabledKey) ?? true;
  Future<void> setAdsEnabled(bool value) =>
      _prefs.setBool(_adsEnabledKey, value);

  // --- Theme ---
  bool get isDarkTheme => _prefs.getBool(_isDarkThemeKey) ?? true;
  Future<void> setDarkTheme(bool value) =>
      _prefs.setBool(_isDarkThemeKey, value);

  // --- Haptics ---
  bool get hapticsEnabled => _prefs.getBool(_hapticsEnabledKey) ?? true;
  Future<void> setHapticsEnabled(bool value) =>
      _prefs.setBool(_hapticsEnabledKey, value);

  // --- Audio ---
  bool get audioEnabled => _prefs.getBool(_audioEnabledKey) ?? true;
  Future<void> setAudioEnabled(bool value) =>
      _prefs.setBool(_audioEnabledKey, value);

  // --- First Launch ---
  bool get isFirstLaunch => _prefs.getBool(_firstLaunchKey) ?? true;
  Future<void> setFirstLaunchDone() =>
      _prefs.setBool(_firstLaunchKey, false);

  // --- Easy Mode (walls don't kill) ---
  bool get easyMode => _prefs.getBool(_easyModeKey) ?? false;
  Future<void> setEasyMode(bool value) =>
      _prefs.setBool(_easyModeKey, value);

  // --- Elite Unlock (permanent cosmetic) ---
  bool get isEliteUnlocked => _prefs.getBool(_eliteUnlockedKey) ?? false;
  Future<void> setEliteUnlocked(bool value) =>
      _prefs.setBool(_eliteUnlockedKey, value);

  // --- Milestone Tier (0=none, 1=bronze, 2=silver, 3=gold, 4=diamond, 5=obsidian) ---
  int get milestoneTier => _prefs.getInt(_milestoneTierKey) ?? 0;
  Future<void> setMilestoneTier(int tier) =>
      _prefs.setInt(_milestoneTierKey, tier);

  // --- Day Streak ---
  int get streakCount => _prefs.getInt(_streakCountKey) ?? 0;
  Future<void> setStreakCount(int count) =>
      _prefs.setInt(_streakCountKey, count);

  String get lastPlayDate => _prefs.getString(_lastPlayDateKey) ?? '';
  Future<void> setLastPlayDate(String date) =>
      _prefs.setString(_lastPlayDateKey, date);

  // --- High Score Mode (which mode the high score was set in) ---
  bool get highScoreIsEasyMode => _prefs.getBool(_highScoreModeKey) ?? false;
  Future<void> setHighScoreMode(bool easyMode) =>
      _prefs.setBool(_highScoreModeKey, easyMode);

  // --- Leaderboard local bests (total + per-mode) ---
  int get leaderboardBestTotalScore =>
      _prefs.getInt(_leaderboardBestTotalKey) ?? getHighScore();
  Future<void> setLeaderboardBestTotalScore(int score) =>
      _prefs.setInt(_leaderboardBestTotalKey, score);

  int get leaderboardBestEasyScore =>
      _prefs.getInt(_leaderboardBestEasyKey) ?? 0;
  Future<void> setLeaderboardBestEasyScore(int score) =>
      _prefs.setInt(_leaderboardBestEasyKey, score);

  int get leaderboardBestHardScore =>
      _prefs.getInt(_leaderboardBestHardKey) ?? 0;
  Future<void> setLeaderboardBestHardScore(int score) =>
      _prefs.setInt(_leaderboardBestHardKey, score);

  // --- Leaderboard view preference (0=total, 1=hard, 2=easy) ---
  int get leaderboardPreferredView =>
      _prefs.getInt(_leaderboardPreferredViewKey) ?? 0;
  Future<void> setLeaderboardPreferredView(int value) =>
      _prefs.setInt(_leaderboardPreferredViewKey, value);

  // --- Retention: revive tokens ---
  int get reviveTokens => _prefs.getInt(_reviveTokensKey) ?? 0;

  void addReviveTokens(int amount) {
    if (amount <= 0) return;
    final next = reviveTokens + amount;
    final clamped = next > _maxReviveTokens ? _maxReviveTokens : next;
    _prefs.setInt(_reviveTokensKey, clamped);
  }

  bool consumeReviveToken() {
    final current = reviveTokens;
    if (current <= 0) return false;
    _prefs.setInt(_reviveTokensKey, current - 1);
    return true;
  }

  // --- Retention: daily challenge ---
  int get dailyChallengeTarget => _prefs.getInt(_dailyChallengeTargetKey) ?? 25;
  bool get isDailyChallengeCompleted =>
      (_prefs.getString(_dailyChallengeCompletedDayKey) ?? '') ==
      _todayString();

  void markDailyChallengeCompleted() {
    _prefs.setString(_dailyChallengeCompletedDayKey, _todayString());
  }

  // --- Retention: daily mission (hit target within limited passes) ---
  int get dailyMissionRunsGoal =>
      _prefs.getInt(_dailyMissionGoalKey) ?? _dailyMissionPassLimit;

  int get dailyMissionRunsCount {
    if ((_prefs.getString(_dailyMissionDayKey) ?? '') != _todayString()) {
      return 0;
    }
    return _prefs.getInt(_dailyMissionRunsKey) ?? 0;
  }

  bool get isDailyMissionCompleted =>
      (_prefs.getString(_dailyMissionCompletedDayKey) ?? '') ==
      _todayString();

  bool get isDailyMissionFailed =>
      (_prefs.getString(_dailyMissionFailedDayKey) ?? '') == _todayString();

  int get dailyMissionPassesRemaining {
    final remaining = dailyMissionRunsGoal - dailyMissionRunsCount;
    return remaining > 0 ? remaining : 0;
  }

  DailyMissionProgress recordRunForDailyMission({required int score}) {
    final today = _todayString();
    if ((_prefs.getString(_dailyMissionDayKey) ?? '') != today) {
      _prefs.setString(_dailyMissionDayKey, today);
      _prefs.setInt(_dailyMissionRunsKey, 0);
      _prefs.setInt(_dailyMissionGoalKey, _dailyMissionPassLimit);
    }

    if (isDailyMissionCompleted || isDailyMissionFailed) {
      return DailyMissionProgress.alreadyResolved;
    }

    final nextRuns = (_prefs.getInt(_dailyMissionRunsKey) ?? 0) + 1;
    _prefs.setInt(_dailyMissionRunsKey, nextRuns);

    if (score >= dailyChallengeTarget) {
      _prefs.setString(_dailyMissionCompletedDayKey, today);
      return DailyMissionProgress.completedNow;
    }

    if (nextRuns >= dailyMissionRunsGoal) {
      _prefs.setString(_dailyMissionFailedDayKey, today);
      return DailyMissionProgress.failedNow;
    }

    return DailyMissionProgress.inProgress;
  }

  /// Rolls daily retention state once per calendar day.
  ///
  /// Grants exactly 1 revive token daily (non-stacking).
  void refreshDailyRetention() {
    final today = _todayString();
    final previousDay = _prefs.getString(_retentionDayKey) ?? '';
    if (previousDay == today) return;

    _prefs.setInt(_reviveTokensKey, 1);

    final seed = _daySeed(today);
    final challengeTarget = 30 + (seed % 46); // 30..75
    final missionGoal = _dailyMissionPassLimit; // fixed pass limit

    _prefs.setString(_retentionDayKey, today);
    _prefs.setInt(_dailyChallengeTargetKey, challengeTarget);
    _prefs.setString(_dailyMissionDayKey, today);
    _prefs.setInt(_dailyMissionGoalKey, missionGoal);
    _prefs.setInt(_dailyMissionRunsKey, 0);
    _prefs.remove(_dailyMissionCompletedDayKey);
    _prefs.remove(_dailyMissionFailedDayKey);
    _prefs.remove(_dailyChallengeCompletedDayKey);
  }

  // --- Theme Rotation Indices ---
  String get themeRotationsJson => _prefs.getString(_themeRotationsKey) ?? '';
  Future<void> setThemeRotationsJson(String json) =>
      _prefs.setString(_themeRotationsKey, json);

  // --- Remember active theme across app relaunch ---
  bool get rememberThemeAcrossLaunches =>
      _prefs.getBool(_rememberThemeAcrossLaunchesKey) ?? true;
  Future<void> setRememberThemeAcrossLaunches(bool value) =>
      _prefs.setBool(_rememberThemeAcrossLaunchesKey, value);

  // --- Active Theme Persistence ---
  int get activeThemeTier => _prefs.getInt(_activeThemeTierKey) ?? 0;
  int get activeThemeVariation => _prefs.getInt(_activeThemeVarKey) ?? 0;
  int get activeThemeScore => _prefs.getInt(_activeThemeScoreKey) ?? 0;
  Future<void> setActiveTheme(int tier, int variation, int score) async {
    await _prefs.setInt(_activeThemeTierKey, tier);
    await _prefs.setInt(_activeThemeVarKey, variation);
    await _prefs.setInt(_activeThemeScoreKey, score);
  }
  Future<void> clearActiveTheme() async {
    await _prefs.setInt(_activeThemeTierKey, 0);
  }

  /// Call on each game start. Returns updated streak count.
  int updateStreak() {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final lastDate = lastPlayDate;

    if (lastDate == todayStr) {
      // Already played today
      return streakCount;
    }

    // Bug fix 7: Use noon-normalized dates for DST-safe day difference
    final todayNoon = DateTime(today.year, today.month, today.day, 12);
    int newStreak;
    if (lastDate.isNotEmpty) {
      final parts = lastDate.split('-');
      if (parts.length == 3) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final d = int.tryParse(parts[2]);
        if (y != null && m != null && d != null) {
          final lastNoon = DateTime(y, m, d, 12);
          final diff = todayNoon.difference(lastNoon).inDays;
          newStreak = (diff == 1) ? streakCount + 1 : 1;
        } else {
          newStreak = 1;
        }
      } else {
        newStreak = 1;
      }
    } else {
      newStreak = 1;
    }

    setLastPlayDate(todayStr);
    setStreakCount(newStreak);
    return newStreak;
  }
}
