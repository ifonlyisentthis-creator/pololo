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

/// Play Games Services / Game Center wrapper for leaderboards.
///
/// Guarantees:
/// - Auto sign-in attempts before show/submit.
/// - Score retry queue while auth is unavailable.
class LeaderboardService {
  LeaderboardService({
    GamesPlatformClient? client,
    String? androidLeaderboardId,
    String? iosLeaderboardId,
  })  : _client = client ?? GamesServicesClient(),
        _androidId = androidLeaderboardId ?? GameConstants.androidLeaderboardId,
        _iosId = iosLeaderboardId ?? GameConstants.iosLeaderboardId;

  final GamesPlatformClient _client;
  final String _androidId;
  final String _iosId;

  bool _signedIn = false;
  bool _signInDeclined = false;
  Future<bool>? _signInFuture;
  DateTime? _lastSignInAttempt;

  int _pendingScore = 0;

  static const Duration _signInTimeout = Duration(seconds: 12);
  static const Duration _operationTimeout = Duration(seconds: 15);

  bool get isSignedIn => _signedIn;

  bool get _isSupportedPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  bool get _isConfigured {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _androidId.isNotEmpty && !_androidId.contains('placeholder');
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _iosId.isNotEmpty && !_iosId.contains('placeholder');
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

  Future<void> submitScore(int score) async {
    if (score <= 0 || !_isSupportedPlatform) return;
    if (!_isConfigured) return;

    if (score > _pendingScore) _pendingScore = score;

    final signedIn = await _ensureSignedIn();
    if (!signedIn) return;

    await _flushPendingScores();
  }

  Future<bool> showLeaderboard() async {
    if (!_isSupportedPlatform) return false;

    final signedIn = await _ensureSignedIn(forceRetry: true);
    if (!signedIn) return false;

    await _flushPendingScores();

    try {
      final result = await _client
          .showLeaderboards(
            androidLeaderboardID: _isConfigured ? _androidId : '',
            iOSLeaderboardID: _isConfigured ? _iosId : '',
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

  /// Auto sign-in: attempts once silently. If user cancels or it fails,
  /// won't retry for [_signInCooldown] unless [forceRetry] is true
  /// (used when user explicitly taps the leaderboard button).
  Future<bool> _ensureSignedIn({bool forceRetry = false}) async {
    if (_signedIn) return true;
    if (!_isSupportedPlatform) return false;

    // Don't spam sign-in — only retry when user explicitly taps leaderboard
    if (!forceRetry && _signInDeclined) return false;
    if (!forceRetry && _lastSignInAttempt != null) return false;

    final inFlight = _signInFuture;
    if (inFlight != null) return inFlight;

    final signInFuture = _signInInternal();
    _signInFuture = signInFuture;
    final result = await signInFuture;
    _signInFuture = null;
    return result;
  }

  Future<bool> _signInInternal() async {
    _lastSignInAttempt = DateTime.now();
    try {
      final alreadySignedIn = await _client
          .isSignedIn()
          .timeout(_signInTimeout, onTimeout: () => false);
      if (alreadySignedIn) {
        _signedIn = true;
        _signInDeclined = false;
        return true;
      }

      final signInResult = await _client
          .signIn()
          .timeout(_signInTimeout, onTimeout: () => 'timeout');
      if (signInResult != null) {
        // signIn returned non-null = error or user cancelled
        _signedIn = false;
        _signInDeclined = true;
        return false;
      }

      final signedInNow = await _client
          .isSignedIn()
          .timeout(_signInTimeout, onTimeout: () => false);
      _signedIn = signedInNow;
      _signInDeclined = !signedInNow;
      return signedInNow;
    } catch (_) {
      _signedIn = false;
      _signInDeclined = true;
      return false;
    }
  }

  Future<void> _flushPendingScores() async {
    if (!_signedIn) return;

    final pending = _pendingScore;
    if (pending > 0) {
      final ok = await _submitScoreNow(pending);
      if (ok && _pendingScore == pending) {
        _pendingScore = 0;
      }
    }
  }

  Future<bool> _submitScoreNow(int score) async {
    if (!_isConfigured) return false;

    try {
      final result = await _client
          .submitScore(
            androidLeaderboardID: _androidId,
            iOSLeaderboardID: _iosId,
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
