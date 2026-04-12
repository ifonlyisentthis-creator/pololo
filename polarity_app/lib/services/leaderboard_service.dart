import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:games_services/games_services.dart';
import 'package:polarity/core/constants.dart';

abstract class GamesPlatformClient {
  Future<String?> signIn();
  Future<bool> isSignedIn();
  Future<String?> submitScore({
    required String androidLeaderboardID,
    required String iOSLeaderboardID,
    required int value,
  });
  Future<String?> showLeaderboards({
    required String androidLeaderboardID,
    required String iOSLeaderboardID,
  });
}

class GamesServicesClient implements GamesPlatformClient {
  @override
  Future<String?> signIn() => GamesServices.signIn();

  @override
  Future<bool> isSignedIn() => GamesServices.isSignedIn;

  @override
  Future<String?> submitScore({
    required String androidLeaderboardID,
    required String iOSLeaderboardID,
    required int value,
  }) {
    return GamesServices.submitScore(
      score: Score(
        androidLeaderboardID: androidLeaderboardID,
        iOSLeaderboardID: iOSLeaderboardID,
        value: value,
      ),
    );
  }

  @override
  Future<String?> showLeaderboards({
    required String androidLeaderboardID,
    required String iOSLeaderboardID,
  }) {
    return GamesServices.showLeaderboards(
      androidLeaderboardID: androidLeaderboardID,
      iOSLeaderboardID: iOSLeaderboardID,
    );
  }
}

class _LeaderboardIds {
  final String androidId;
  final String iosId;

  const _LeaderboardIds({
    required this.androidId,
    required this.iosId,
  });
}

/// Play Games Services / Game Center wrapper for leaderboards.
///
/// Guarantees:
/// - Auto sign-in attempts before show/submit.
/// - Separate hard/easy leaderboard IDs.
/// - Score retry queue while auth is unavailable.
class LeaderboardService {
  LeaderboardService({
    GamesPlatformClient? client,
    String? androidLeaderboardHardId,
    String? androidLeaderboardEasyId,
    String? iosLeaderboardHardId,
    String? iosLeaderboardEasyId,
  })  : _client = client ?? GamesServicesClient(),
        _hardIds = _LeaderboardIds(
          androidId:
              androidLeaderboardHardId ?? GameConstants.androidLeaderboardHardId,
          iosId: iosLeaderboardHardId ?? GameConstants.iosLeaderboardHardId,
        ),
        _easyIds = _LeaderboardIds(
          androidId:
              androidLeaderboardEasyId ?? GameConstants.androidLeaderboardEasyId,
          iosId: iosLeaderboardEasyId ?? GameConstants.iosLeaderboardEasyId,
        );

  final GamesPlatformClient _client;
  final _LeaderboardIds _hardIds;
  final _LeaderboardIds _easyIds;

  bool _signedIn = false;
  Future<bool>? _signInFuture;

  int _pendingEasyScore = 0;
  int _pendingHardScore = 0;

  static const Duration _signInTimeout = Duration(seconds: 12);
  static const Duration _operationTimeout = Duration(seconds: 15);

  bool get isSignedIn => _signedIn;

  bool get _isSupportedPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  _LeaderboardIds _idsForMode(bool easyMode) {
    return easyMode ? _easyIds : _hardIds;
  }

  bool _isConfiguredForCurrentPlatform(_LeaderboardIds ids) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return ids.androidId.isNotEmpty && !ids.androidId.contains('placeholder');
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return ids.iosId.isNotEmpty && !ids.iosId.contains('placeholder');
    }
    return false;
  }

  Future<void> init() async {
    if (!_isSupportedPlatform) {
      _signedIn = false;
      return;
    }

    final signedIn = await _ensureSignedIn();
    if (!signedIn) return;
    await _flushPendingScores();
  }

  Future<void> submitScore(int score, {required bool easyMode}) async {
    if (score <= 0 || !_isSupportedPlatform) return;

    final ids = _idsForMode(easyMode);
    if (!_isConfiguredForCurrentPlatform(ids)) return;

    _queuePendingScore(score, easyMode: easyMode);

    final signedIn = await _ensureSignedIn();
    if (!signedIn) return;

    await _flushPendingScores();
  }

  Future<bool> showLeaderboard({required bool easyMode}) async {
    if (!_isSupportedPlatform) return false;

    final ids = _idsForMode(easyMode);
    final specificLeaderboardConfigured = _isConfiguredForCurrentPlatform(ids);

    final signedIn = await _ensureSignedIn();
    if (!signedIn) return false;

    await _flushPendingScores();

    try {
      final result = await _client
          .showLeaderboards(
            androidLeaderboardID: specificLeaderboardConfigured
                ? ids.androidId
                : '',
            iOSLeaderboardID: specificLeaderboardConfigured ? ids.iosId : '',
          )
          .timeout(
            _operationTimeout,
            onTimeout: () => 'timeout',
          );
      return result == null;
    } catch (_) {
      return false;
    }
  }

  void _queuePendingScore(int score, {required bool easyMode}) {
    if (easyMode) {
      if (score > _pendingEasyScore) _pendingEasyScore = score;
      return;
    }
    if (score > _pendingHardScore) _pendingHardScore = score;
  }

  Future<bool> _ensureSignedIn() async {
    if (!_isSupportedPlatform) {
      _signedIn = false;
      return false;
    }

    final inFlight = _signInFuture;
    if (inFlight != null) return inFlight;

    final signInFuture = _signInInternal();
    _signInFuture = signInFuture;
    final result = await signInFuture;
    _signInFuture = null;
    return result;
  }

  Future<bool> _signInInternal() async {
    try {
      final alreadySignedIn = await _client
          .isSignedIn()
          .timeout(_signInTimeout, onTimeout: () => false);
      if (alreadySignedIn) {
        _signedIn = true;
        return true;
      }

      final signInResult = await _client
          .signIn()
          .timeout(_signInTimeout, onTimeout: () => 'timeout');
      if (signInResult != null) {
        _signedIn = false;
        return false;
      }

      final signedInNow = await _client
          .isSignedIn()
          .timeout(_signInTimeout, onTimeout: () => false);
      _signedIn = signedInNow;
      return signedInNow;
    } catch (_) {
      _signedIn = false;
      return false;
    }
  }

  Future<void> _flushPendingScores() async {
    if (!_signedIn) return;

    final pendingHard = _pendingHardScore;
    if (pendingHard > 0) {
      final ok = await _submitScoreNow(pendingHard, easyMode: false);
      if (ok && _pendingHardScore == pendingHard) {
        _pendingHardScore = 0;
      }
    }

    final pendingEasy = _pendingEasyScore;
    if (pendingEasy > 0) {
      final ok = await _submitScoreNow(pendingEasy, easyMode: true);
      if (ok && _pendingEasyScore == pendingEasy) {
        _pendingEasyScore = 0;
      }
    }
  }

  Future<bool> _submitScoreNow(int score, {required bool easyMode}) async {
    final ids = _idsForMode(easyMode);
    if (!_isConfiguredForCurrentPlatform(ids)) return false;

    try {
      final result = await _client
          .submitScore(
            androidLeaderboardID: ids.androidId,
            iOSLeaderboardID: ids.iosId,
            value: score,
          )
          .timeout(
            _operationTimeout,
            onTimeout: () => 'timeout',
          );
      return result == null;
    } catch (_) {
      return false;
    }
  }
}
