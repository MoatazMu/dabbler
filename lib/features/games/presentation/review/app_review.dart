import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppReviewService {
  static const _lastPromptKey = 'last_review_prompt';
  static const _minIntervalDays = 30;

  static Future<void> maybePromptForReview({bool force = false}) async {
    final review = InAppReview.instance;
    final prefs = await SharedPreferences.getInstance();

    final now = DateTime.now();
    final lastPromptMs = prefs.getInt(_lastPromptKey);
    if (!force && lastPromptMs != null) {
      final lastPrompt = DateTime.fromMillisecondsSinceEpoch(lastPromptMs);
      if (now.difference(lastPrompt).inDays < _minIntervalDays) {
        return; // Too soon
      }
    }

    if (await review.isAvailable()) {
      await review.requestReview();
      await prefs.setInt(_lastPromptKey, now.millisecondsSinceEpoch);
    }
  }
}
