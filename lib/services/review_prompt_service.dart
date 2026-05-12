import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 計測完了の累計回数を SharedPreferences に保存し、しきい値到達で
/// In-App Review ダイアログを 1 度だけ要求する。
///
/// iOS / Android ともにシステム側で年あたりの表示回数に上限があるため、
/// アプリ側からは「3 回計測したユーザーに 1 度だけ要求」というポリシー。
class ReviewPromptService {
  ReviewPromptService._();

  static const _kShakeCountKey = 'shake_completed_count';
  static const _kReviewPromptedKey = 'review_prompted_v1';

  /// 何回目の計測完了で初めて要求するか。
  static const _promptThreshold = 3;

  /// 計測完了 1 回ぶんをカウントし、しきい値到達 & 未要求ならレビューを要求する。
  static Future<void> incrementAndMaybePrompt() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_kShakeCountKey) ?? 0) + 1;
    await prefs.setInt(_kShakeCountKey, count);

    if (count < _promptThreshold) return;
    if (prefs.getBool(_kReviewPromptedKey) ?? false) return;

    final review = InAppReview.instance;
    if (await review.isAvailable()) {
      await review.requestReview();
      await prefs.setBool(_kReviewPromptedKey, true);
    }
  }
}
