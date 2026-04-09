import 'package:in_app_review/in_app_review.dart';

class ReviewService {
  final InAppReview _review = InAppReview.instance;
  bool _hasRequestedThisSession = false;

  Future<void> requestReviewIfEligible() async {
    if (_hasRequestedThisSession) return;
    try {
      if (await _review.isAvailable()) {
        _hasRequestedThisSession = true;
        await _review.requestReview();
      }
    } catch (_) {}
  }
}
