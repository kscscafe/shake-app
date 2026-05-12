import 'dart:io' show Platform;

import '../config/env.dart';

/// 広告枠の種別。画面ごとに別の Unit ID を使えるようにするためのキー。
enum AdSlot {
  /// 結果画面のバナー
  resultBanner,

  /// ランキング画面のバナー
  rankingBanner,

  /// 計測完了 → 結果画面の遷移時に表示するインタースティシャル
  measureInterstitial,
}

/// AdMob の Unit ID を返すヘルパ。
///
/// [Env.useAdMobTestIds] が true のときは Google 公式テスト ID を返す。
/// 本番 ID は AdMob 管理画面で発行したものをここに集約する。
/// iOS / Android はそれぞれ別の AdMob アプリとして登録されているため、
/// Platform 判定で別 ID を返している。
class AdHelper {
  static String adUnitId(AdSlot slot) {
    if (Env.useAdMobTestIds) {
      return _testId(slot);
    }
    return _prodId(slot);
  }

  static String _prodId(AdSlot slot) {
    if (Platform.isAndroid) {
      switch (slot) {
        case AdSlot.resultBanner:
          return 'ca-app-pub-7818121287671921/1813833631';
        case AdSlot.rankingBanner:
          return 'ca-app-pub-7818121287671921/3727792943';
        case AdSlot.measureInterstitial:
          return 'ca-app-pub-7818121287671921/7970064948';
      }
    }
    if (Platform.isIOS) {
      switch (slot) {
        case AdSlot.resultBanner:
          return 'ca-app-pub-7818121287671921/6353956282';
        case AdSlot.rankingBanner:
          return 'ca-app-pub-7818121287671921/1899480610';
        case AdSlot.measureInterstitial:
          return 'ca-app-pub-7818121287671921/9586398946';
      }
    }
    throw UnsupportedError('Unsupported platform for AdMob');
  }

  static String _testId(AdSlot slot) {
    final isAndroid = Platform.isAndroid;
    final isIOS = Platform.isIOS;
    if (!isAndroid && !isIOS) {
      throw UnsupportedError('Unsupported platform for AdMob');
    }
    switch (slot) {
      case AdSlot.resultBanner:
      case AdSlot.rankingBanner:
        return isAndroid
            ? 'ca-app-pub-3940256099942544/6300978111'
            : 'ca-app-pub-3940256099942544/2934735716';
      case AdSlot.measureInterstitial:
        return isAndroid
            ? 'ca-app-pub-3940256099942544/1033173712'
            : 'ca-app-pub-3940256099942544/4411468910';
    }
  }
}
