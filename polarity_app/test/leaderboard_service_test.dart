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

  test('submitScore routes easy scores to easy leaderboard IDs', () async {
    final client = _FakeGamesClient();
    final service = LeaderboardService(
      client: client,
      androidLeaderboardHardId: 'android_hard',
      androidLeaderboardEasyId: 'android_easy',
      iosLeaderboardHardId: 'ios_hard',
      iosLeaderboardEasyId: 'ios_easy',
    );

    await service.submitScore(42, easyMode: true);

    expect(client.signInCalls, 1);
    expect(client.submits.length, 1);
    expect(client.submits.first.androidLeaderboardID, 'android_easy');
    expect(client.submits.first.iOSLeaderboardID, 'ios_easy');
    expect(client.submits.first.value, 42);
  });

  test('queues highest pending score and flushes after sign-in recovers', () async {
    final client = _FakeGamesClient()..failSignIn = true;
    final service = LeaderboardService(
      client: client,
      androidLeaderboardHardId: 'android_hard',
      androidLeaderboardEasyId: 'android_easy',
      iosLeaderboardHardId: 'ios_hard',
      iosLeaderboardEasyId: 'ios_easy',
    );

    await service.submitScore(10, easyMode: false);
    await service.submitScore(50, easyMode: false);
    await service.submitScore(20, easyMode: false);
    expect(client.submits, isEmpty);

    client.failSignIn = false;
    await service.init();

    expect(client.submits.length, 1);
    expect(client.submits.first.androidLeaderboardID, 'android_hard');
    expect(client.submits.first.value, 50);
  });

  test('showLeaderboard opens board for selected mode', () async {
    final client = _FakeGamesClient()..signedIn = true;
    final service = LeaderboardService(
      client: client,
      androidLeaderboardHardId: 'android_hard',
      androidLeaderboardEasyId: 'android_easy',
      iosLeaderboardHardId: 'ios_hard',
      iosLeaderboardEasyId: 'ios_easy',
    );

    await service.showLeaderboard(easyMode: false);
    await service.showLeaderboard(easyMode: true);

    expect(client.shows.length, 2);
    expect(client.shows[0].androidLeaderboardID, 'android_hard');
    expect(client.shows[1].androidLeaderboardID, 'android_easy');
  });
}
