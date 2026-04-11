import 'package:flutter_test/flutter_test.dart';
import 'package:polarity/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _dateString(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

void main() {
  test('refreshDailyRetention initializes challenge, mission, and daily token', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.init();

    storage.refreshDailyRetention();

    expect(storage.reviveTokens, 1);
    expect(storage.dailyChallengeTarget, greaterThan(0));
    expect(storage.dailyMissionRunsGoal, 5);
    expect(storage.dailyMissionRunsCount, 0);
    expect(storage.isDailyMissionFailed, isFalse);
  });

  test('refreshDailyRetention grants exactly one token on new day', () async {
    final previousDay = _dateString(DateTime.now().subtract(const Duration(days: 3)));
    SharedPreferences.setMockInitialValues({
      'retention_day': previousDay,
      'revive_tokens': 4,
    });
    final storage = StorageService();
    await storage.init();

    storage.refreshDailyRetention();

    expect(storage.reviveTokens, 1);
  });

  test('refreshDailyRetention is idempotent on same day reopen', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.init();

    storage.refreshDailyRetention();
    final firstTokens = storage.reviveTokens;

    // Simulate reopening app same day.
    storage.refreshDailyRetention();

    expect(storage.reviveTokens, firstTokens);
  });

  test('daily mission fails when passes are exhausted without target', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.init();

    storage.refreshDailyRetention();
    final goal = storage.dailyMissionRunsGoal;

    DailyMissionProgress last = DailyMissionProgress.inProgress;
    for (int i = 0; i < goal; i++) {
      last = storage.recordRunForDailyMission(score: 0);
    }

    expect(last, DailyMissionProgress.failedNow);
    expect(storage.isDailyMissionCompleted, isFalse);
    expect(storage.isDailyMissionFailed, isTrue);
    expect(storage.dailyMissionRunsCount, goal);
  });

  test('daily mission completes when target is hit within pass limit', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.init();

    storage.refreshDailyRetention();
    final target = storage.dailyChallengeTarget;

    final result = storage.recordRunForDailyMission(score: target);

    expect(result, DailyMissionProgress.completedNow);
    expect(storage.isDailyMissionCompleted, isTrue);
    expect(storage.isDailyMissionFailed, isFalse);
    expect(storage.dailyMissionRunsCount, 1);
  });
}
