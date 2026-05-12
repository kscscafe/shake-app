import 'dart:io' show Platform;

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';

/// App Tracking Transparency (iOS 14+) の許可ダイアログ表示を担う。
///
/// Apple のガイドラインに沿うため：
/// - iOS 以外では何もしない
/// - すでに確定済み（authorized / denied / restricted）なら再要求しない
/// - notDetermined のときのみ、UI が描画されたあとに少し待ってから表示
///
/// MobileAds.instance.initialize() は **このサービスの完了後** に呼ぶこと。
/// ATT が確定する前に AdMob を初期化すると、最初の広告リクエストで IDFA が
/// 利用できず「審査時にダイアログが出ない」というレビュー指摘の原因になる。
class TrackingConsentService {
  static const _tag = '[ATT]';

  /// ダイアログ要求が必要なら表示し、確定したステータスを返す。
  /// iOS 以外では [TrackingStatus.notSupported] を返す。
  static Future<TrackingStatus> requestIfNeeded() async {
    if (!Platform.isIOS) {
      debugPrint('$_tag skipped: not iOS');
      return TrackingStatus.notSupported;
    }

    final current = await AppTrackingTransparency.trackingAuthorizationStatus;
    debugPrint('$_tag current status: $current');

    if (current != TrackingStatus.notDetermined) {
      // すでに確定済み（過去に応答済 / iOS 13 以下 / restricted）
      return current;
    }

    // Apple 推奨：UI が active になった直後に呼ぶ。
    // Flutter で main() 直後に呼ぶと SwiftUI / UIKit のウィンドウが
    // まだ key window でない瞬間があり、ダイアログが silently に
    // スキップされるケースが報告されているため 200ms 待つ。
    await Future<void>.delayed(const Duration(milliseconds: 200));

    debugPrint('$_tag requesting authorization...');
    final result =
        await AppTrackingTransparency.requestTrackingAuthorization();
    debugPrint('$_tag result: $result');
    return result;
  }
}
