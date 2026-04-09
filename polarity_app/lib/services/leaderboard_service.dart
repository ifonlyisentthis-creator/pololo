import 'package:games_services/games_services.dart';

/// Play Games Services / Game Center wrapper for leaderboards.
class LeaderboardService {
  bool _signedIn = false;

  bool get isSignedIn => _signedIn;

  Future<void> init() async {
    try {
      await GamesServices.signIn();
      _signedIn = true;
    } catch (_) {
      _signedIn = false;
    }
  }

  Future<void> submitScore(int score) async {
    if (!_signedIn) return;
    try {
      await GamesServices.submitScore(
        score: Score(
          // Replace with your actual leaderboard ID from Play Console / App Store Connect
          androidLeaderboardID: 'CgkI_placeholder_leaderboard',
          iOSLeaderboardID: 'polarity_leaderboard',
          value: score,
        ),
      );
    } catch (_) {}
  }

  Future<void> showLeaderboard() async {
    if (!_signedIn) {
      try {
        await GamesServices.signIn();
        _signedIn = true;
      } catch (_) {
        return;
      }
    }
    try {
      await GamesServices.showLeaderboards(
        // Replace with your actual leaderboard ID
        androidLeaderboardID: 'CgkI_placeholder_leaderboard',
        iOSLeaderboardID: 'polarity_leaderboard',
      );
    } catch (_) {}
  }
}
