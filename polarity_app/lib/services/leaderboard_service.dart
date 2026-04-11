import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:games_services/games_services.dart';
import 'package:polarity/core/constants.dart';

enum LeaderboardView {
  total,
  hard,
  easy,
}

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
    String? androidLeaderboardTotalId,
    String? iosLeaderboardTotalId,
    String? androidLeaderboardHardId,
    String? androidLeaderboardEasyId,
    String? iosLeaderboardHardId,
    String? iosLeaderboardEasyId,
  })  : _client = client ?? GamesServicesClient(),
        _totalIds = _LeaderboardIds(
          androidId:
              androidLeaderboardTotalId ?? GameConstants.androidLeaderboardTotalId,
          iosId: iosLeaderboardTotalId ?? GameConstants.iosLeaderboardTotalId,
        ),
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
  final _LeaderboardIds _totalIds;
  final _LeaderboardIds _hardIds;
  final _LeaderboardIds _easyIds;

  bool _signedIn = false;
  Future<bool>? _signInFuture;

  int _pendingTotalScore = 0;
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

  _LeaderboardIds _idsForView(LeaderboardView view) {
    switch (view) {
      case LeaderboardView.total:
        return _totalIds;
      case LeaderboardView.hard:
        return _hardIds;
      case LeaderboardView.easy:
        return _easyIds;
    }
  }

  String _platformId(_LeaderboardIds ids) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return ids.androidId;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return ids.iosId;
    }
    return '';
  }

  bool _isIdConfigured(String id) =>
      id.isNotEmpty && !id.contains('placeholder');

  bool _isViewUnambiguous(LeaderboardView view) {
    if (!_isSupportedPlatform) return false;

    final targetId = _platformId(_idsForView(view));
    if (!_isIdConfigured(targetId)) return false;

    for (final other in LeaderboardView.values) {
      if (other == view) continue;
      final otherId = _platformId(_idsForView(other));
      if (_isIdConfigured(otherId) && otherId == targetId) {
        // Overlapping board IDs are ambiguous; fail closed to avoid score bleed.
        return false;
      }
    }

    return true;
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

  Future<void> submitScore(int score, {required bool easyMode}) {
    return submitModeScore(score, easyMode: easyMode);
  }

  Future<void> submitModeScore(int score, {required bool easyMode}) async {
    if (score <= 0 || !_isSupportedPlatform) return;

    final view = easyMode ? LeaderboardView.easy : LeaderboardView.hard;
    if (!_isViewUnambiguous(view)) {
      return;
    }

    _queuePendingScore(score, view: view);

    final signedIn = await _ensureSignedIn();
    if (!signedIn) return;

    await _flushPendingScores();
  }

  Future<void> submitTotalScore(int score) async {
    if (score <= 0 || !_isSupportedPlatform) return;

    if (!_isViewUnambiguous(LeaderboardView.total)) {
      return;
    }

    _queuePendingScore(score, view: LeaderboardView.total);

    final signedIn = await _ensureSignedIn();
    if (!signedIn) return;

    await _flushPendingScores();
  }

  Future<bool> showLeaderboard({required LeaderboardView view}) async {
    if (!_isSupportedPlatform) return false;

    if (!_isViewUnambiguous(view)) {
      return false;
    }

    final ids = _idsForView(view);

    final signedIn = await _ensureSignedIn();
    if (!signedIn) return false;

    await _flushPendingScores();

    try {
      final result = await _client
          .showLeaderboards(
            androidLeaderboardID: ids.androidId,
            iOSLeaderboardID: ids.iosId,
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

  void _queuePendingScore(int score, {required LeaderboardView view}) {
    switch (view) {
      case LeaderboardView.total:
        if (score > _pendingTotalScore) _pendingTotalScore = score;
        break;
      case LeaderboardView.easy:
        if (score > _pendingEasyScore) _pendingEasyScore = score;
        break;
      case LeaderboardView.hard:
        if (score > _pendingHardScore) _pendingHardScore = score;
        break;
    }
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

    final pendingTotal = _pendingTotalScore;
    if (pendingTotal > 0) {
      final ok = await _submitScoreNow(
        pendingTotal,
        view: LeaderboardView.total,
      );
      if (ok && _pendingTotalScore == pendingTotal) {
        _pendingTotalScore = 0;
      }
    }

    final pendingHard = _pendingHardScore;
    if (pendingHard > 0) {
      final ok = await _submitScoreNow(
        pendingHard,
        view: LeaderboardView.hard,
      );
      if (ok && _pendingHardScore == pendingHard) {
        _pendingHardScore = 0;
      }
    }

    final pendingEasy = _pendingEasyScore;
    if (pendingEasy > 0) {
      final ok = await _submitScoreNow(
        pendingEasy,
        view: LeaderboardView.easy,
      );
      if (ok && _pendingEasyScore == pendingEasy) {
        _pendingEasyScore = 0;
      }
    }
  }

  Future<bool> _submitScoreNow(int score, {required LeaderboardView view}) async {
    final ids = _idsForView(view);
    if (!_isViewUnambiguous(view)) return false;

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
