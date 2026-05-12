import 'package:firebase_analytics/firebase_analytics.dart';

/// Firebase Analytics のイベント送信を一元管理する。
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _fa = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get navigatorObserver =>
      FirebaseAnalyticsObserver(analytics: _fa);

  /// 振りの計測完了。スコア（加速度）・順位・国コードを一緒に送る。
  Future<void> shakeCompleted({
    required String nickname,
    required double acceleration,
    required String countryCode,
    required int worldRank,
    required int countryRank,
  }) {
    return _fa.logEvent(
      name: 'shake_completed',
      parameters: {
        'nickname': nickname,
        'acceleration': acceleration,
        'country_code': countryCode,
        'world_rank': worldRank,
        'country_rank': countryRank,
      },
    );
  }

  /// ランキング画面が開かれた。
  Future<void> rankingViewed() {
    return _fa.logEvent(name: 'ranking_viewed');
  }

  /// 結果画面で「もう一度」をタップ。
  Future<void> tryAgain() {
    return _fa.logEvent(name: 'try_again');
  }
}
