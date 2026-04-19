import 'package:shared_preferences/shared_preferences.dart';
import 'package:polarity/core/security/score_guard.dart';

class StorageService {
  static const _highScoreKey = 'hs_v1';
  static const _adsEnabledKey = 'ads_enabled';
  static const _isDarkThemeKey = 'is_dark_theme';
  static const _hapticsEnabledKey = 'haptics_enabled';
  static const _audioEnabledKey = 'audio_enabled';
  static const _firstLaunchKey = 'first_launch';
  static const _eliteUnlockedKey = 'elite_unlocked';
  static const _milestoneTierKey = 'milestone_tier';
  static const _streakCountKey = 'streak_count';
  static const _lastPlayDateKey = 'last_play_date';
  static const _leaderboardBestKey = 'lb_best_hard';
  static const _themeRotationsKey = 'theme_rotations';
  static const _rememberThemeAcrossLaunchesKey =
      'remember_theme_across_launches';
  static const _activeThemeTierKey = 'active_theme_tier';
  static const _activeThemeVarKey = 'active_theme_var';
  static const _activeThemeScoreKey = 'active_theme_score';

  late SharedPreferences _prefs;

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

    // --- Leaderboard local best (for deduped score submits) ---
    int get leaderboardBestScore => _prefs.getInt(_leaderboardBestKey) ?? 0;
    Future<void> setLeaderboardBestScore(int score) =>
      _prefs.setInt(_leaderboardBestKey, score);

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
