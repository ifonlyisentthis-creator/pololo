import 'dart:typed_data';
import 'dart:io';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class ShareService {
  /// Share score with an image captured from the provided [controller].
  /// The controller must be wrapping a Screenshot widget in the UI.
  Future<void> shareScoreWithScreenshot({
    required ScreenshotController controller,
    required int score,
    required int highScore,
    required String roast,
  }) async {
    try {
      final Uint8List? imageBytes = await controller.capture(
        delay: const Duration(milliseconds: 50),
      );
      if (imageBytes == null) {
        await _shareTextOnly(score: score, highScore: highScore, roast: roast);
        return;
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/polarity_score.png');
      await file.writeAsBytes(imageBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'POLARITY | Score: $score | Best: $highScore\n$roast\nCan you beat me? 🎮',
      );
    } catch (_) {
      await _shareTextOnly(score: score, highScore: highScore, roast: roast);
    }
  }

  /// Fallback: text-only share (always works)
  Future<void> _shareTextOnly({
    required int score,
    required int highScore,
    required String roast,
  }) async {
    try {
      await Share.share(
        'POLARITY | Score: $score | Best: $highScore\n$roast\nCan you beat me? 🎮',
      );
    } catch (_) {}
  }
}
