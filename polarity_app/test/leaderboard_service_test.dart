import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polarity/services/leaderboard_service.dart';

class _SubmitAttempt {
  final String androidLeaderboardID;
  final String iOSLeaderboardID;
  final int value;

  const _SubmitAttempt({
    required this.androidLeaderboardID,
    required this.iOSLeaderboardID,
    required this.value,
  });
}

class _ShowAttempt {
  final String androidLeaderboardID;
  final String iOSLeaderboardID;

  const _ShowAttempt({
    required this.androidLeaderboardID,
    required this.iOSLeaderboardID,
  });
}

class _FakeGamesClient implements GamesPlatformClient {
  bool signedIn = false;
  bool failSignIn = false;
  bool failSubmit = false;
  bool failShow = false;

  int signInCalls = 0;
  final List<_SubmitAttempt> submits = <_SubmitAttempt>[];
  final List<_ShowAttempt> shows = <_ShowAttempt>[];

  @override
  Future<bool> isSignedIn() async => signedIn;

  @override
  Future<String?> signIn() async {
    signInCalls++;
    if (failSignIn) return 'sign_in_failed';
    signedIn = true;
    return null;
  }

  @override
  Future<String?> submitScore({
    required String androidLeaderboardID,
    required String iOSLeaderboardID,
    required int value,
  }) async {
    if (failSubmit) return 'submit_failed';
    submits.add(
      _SubmitAttempt(
        androidLeaderboardID: androidLeaderboardID,
        iOSLeaderboardID: iOSLeaderboardID,
        value: value,
      ),
    );
    return null;
  }

  @override
  Future<String?> showLeaderboards({
    required String androidLeaderboardID,
    required String iOSLeaderboardID,
  }) async {
    if (failShow) return 'show_failed';
    shows.add(
      _ShowAttempt(
        androidLeaderboardID: androidLeaderboardID,
        iOSLeaderboardID: iOSLeaderboardID,
      ),
    );
    return null;
  }
}

void main() {
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('submitModeScore routes easy scores to easy leaderboard IDs', () async {
    final client = _FakeGamesClient();
    final service = LeaderboardService(
      client: client,
      androidLeaderboardTotalId: 'android_total',
      androidLeaderboardHardId: 'android_hard',
      androidLeaderboardEasyId: 'android_easy',
      iosLeaderboardTotalId: 'ios_total',
      iosLeaderboardHardId: 'ios_hard',
      iosLeaderboardEasyId: 'ios_easy',
    );

    await service.submitModeScore(42, easyMode: true);

    expect(client.signInCalls, 1);
    expect(client.submits.length, 1);
    expect(client.submits.first.androidLeaderboardID, 'android_easy');
    expect(client.submits.first.iOSLeaderboardID, 'ios_easy');
    expect(client.submits.first.value, 42);
  });

  test('submitTotalScore routes score to total leaderboard IDs', () async {
    final client = _FakeGamesClient();
    final service = LeaderboardService(
      client: client,
      androidLeaderboardTotalId: 'android_total',
      androidLeaderboardHardId: 'android_hard',
      androidLeaderboardEasyId: 'android_easy',
      iosLeaderboardTotalId: 'ios_total',
      iosLeaderboardHardId: 'ios_hard',
      iosLeaderboardEasyId: 'ios_easy',
    );

    await service.submitTotalScore(73);

    expect(client.submits.length, 1);
    expect(client.submits.first.androidLeaderboardID, 'android_total');
    expect(client.submits.first.iOSLeaderboardID, 'ios_total');
    expect(client.submits.first.value, 73);
  });

  test('queues highest pending scores and flushes after sign-in recovers', () async {
    final client = _FakeGamesClient()..failSignIn = true;
    final service = LeaderboardService(
      client: client,
      androidLeaderboardTotalId: 'android_total',
      androidLeaderboardHardId: 'android_hard',
      androidLeaderboardEasyId: 'android_easy',
      iosLeaderboardTotalId: 'ios_total',
      iosLeaderboardHardId: 'ios_hard',
      iosLeaderboardEasyId: 'ios_easy',
    );

    await service.submitModeScore(10, easyMode: false);
    await service.submitModeScore(50, easyMode: false);
    await service.submitModeScore(20, easyMode: false);
    await service.submitTotalScore(88);
    await service.submitTotalScore(64);
    expect(client.submits, isEmpty);

    client.failSignIn = false;
    await service.init();

    expect(client.submits.length, 2);
    expect(client.submits[0].androidLeaderboardID, 'android_total');
    expect(client.submits[0].value, 88);
    expect(client.submits[1].androidLeaderboardID, 'android_hard');
    expect(client.submits[1].value, 50);
  });

  test('showLeaderboard opens board selected by user', () async {
    final client = _FakeGamesClient()..signedIn = true;
    final service = LeaderboardService(
      client: client,
      androidLeaderboardTotalId: 'android_total',
      androidLeaderboardHardId: 'android_hard',
      androidLeaderboardEasyId: 'android_easy',
      iosLeaderboardTotalId: 'ios_total',
      iosLeaderboardHardId: 'ios_hard',
      iosLeaderboardEasyId: 'ios_easy',
    );

    await service.showLeaderboard(view: LeaderboardView.total);
    await service.showLeaderboard(view: LeaderboardView.hard);
    await service.showLeaderboard(view: LeaderboardView.easy);

    expect(client.shows.length, 3);
    expect(client.shows[0].androidLeaderboardID, 'android_total');
    expect(client.shows[1].androidLeaderboardID, 'android_hard');
    expect(client.shows[2].androidLeaderboardID, 'android_easy');
  });

  test('blocks mode submit when board IDs overlap', () async {
    final client = _FakeGamesClient();
    final service = LeaderboardService(
      client: client,
      androidLeaderboardTotalId: 'android_total',
      androidLeaderboardHardId: 'android_shared',
      androidLeaderboardEasyId: 'android_shared',
      iosLeaderboardTotalId: 'ios_total',
      iosLeaderboardHardId: 'ios_shared',
      iosLeaderboardEasyId: 'ios_shared',
    );

    await service.submitModeScore(77, easyMode: true);
    await service.submitModeScore(81, easyMode: false);

    expect(client.submits, isEmpty);
  });

  test('blocks total submit and show when total ID overlaps a mode ID', () async {
    final client = _FakeGamesClient()..signedIn = true;
    final service = LeaderboardService(
      client: client,
      androidLeaderboardTotalId: 'android_same_as_hard',
      androidLeaderboardHardId: 'android_same_as_hard',
      androidLeaderboardEasyId: 'android_easy',
      iosLeaderboardTotalId: 'ios_same_as_hard',
      iosLeaderboardHardId: 'ios_same_as_hard',
      iosLeaderboardEasyId: 'ios_easy',
    );

    await service.submitTotalScore(99);
    final shown = await service.showLeaderboard(view: LeaderboardView.total);

    expect(client.submits, isEmpty);
    expect(client.shows, isEmpty);
    expect(shown, isFalse);
  });
}
