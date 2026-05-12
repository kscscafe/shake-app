import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/env.dart';
import 'ad_helper.dart';

/// インタースティシャル広告のロード・表示を担うマネージャ。
///
/// 使い方：
/// 1. 画面 initState などで [load] を呼んでプリロード開始（5秒タイムアウト付き）
/// 2. 表示したいタイミングで [showIfAvailable] を呼ぶ
///   - ロード成功時：広告を表示してダイアログが閉じるまで待機
///   - 失敗・未ロード時：何もせず即座に戻る（フェイルオープン）
class InterstitialAdManager {
  InterstitialAdManager({AdSlot slot = AdSlot.measureInterstitial})
      : _slot = slot;

  static const _tag = '[Interstitial]';

  final AdSlot _slot;
  InterstitialAd? _ad;
  Future<void>? _loading;
  bool _disposed = false;

  /// プリロード。すでにロード済み or ロード中なら同じ Future を返す。
  Future<void> load() {
    if (!Env.adsEnabled) {
      debugPrint('$_tag load() skipped: ads disabled by Env.adsEnabled=false');
      return Future.value();
    }
    if (_disposed) {
      debugPrint('$_tag load() skipped: disposed');
      return Future.value();
    }
    if (_ad != null) {
      debugPrint('$_tag load() skipped: already loaded');
      return Future.value();
    }
    if (_loading != null) {
      debugPrint('$_tag load() reusing in-flight load future');
      return _loading!;
    }
    return _loading = _doLoad();
  }

  Future<void> _doLoad() {
    final unitId = AdHelper.adUnitId(_slot);
    final start = DateTime.now();
    debugPrint('$_tag load() start unitId=$unitId slot=$_slot');

    final completer = Completer<void>();
    InterstitialAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          final elapsed = DateTime.now().difference(start).inMilliseconds;
          debugPrint('$_tag onAdLoaded in ${elapsed}ms responseInfo='
              '${ad.responseInfo?.responseId ?? "(null)"}');
          if (_disposed) {
            debugPrint('$_tag disposing freshly loaded ad: manager disposed');
            ad.dispose();
          } else {
            _ad = ad;
          }
          if (!completer.isCompleted) completer.complete();
        },
        onAdFailedToLoad: (error) {
          final elapsed = DateTime.now().difference(start).inMilliseconds;
          debugPrint('$_tag onAdFailedToLoad in ${elapsed}ms code=${error.code} '
              'domain=${error.domain} message="${error.message}"');
          _ad = null;
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );

    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        final elapsed = DateTime.now().difference(start).inMilliseconds;
        debugPrint('$_tag load() timed out after ${elapsed}ms (5s cap)');
      },
    ).whenComplete(() => _loading = null);
  }

  /// ロード済みなら表示し、ダイアログが閉じるまで await する。
  /// 未ロード or エラーの場合は即 return（呼び出し側の遷移を妨げない）。
  Future<void> showIfAvailable() async {
    if (!Env.adsEnabled) {
      debugPrint(
          '$_tag showIfAvailable() skipped: ads disabled by Env.adsEnabled=false');
      return;
    }
    debugPrint('$_tag showIfAvailable() called: '
        'hasAd=${_ad != null} disposed=$_disposed loadingInFlight=${_loading != null}');

    if (_disposed) {
      debugPrint('$_tag showIfAvailable() skipped: disposed');
      return;
    }
    final ad = _ad;
    _ad = null;
    if (ad == null) {
      debugPrint('$_tag showIfAvailable() skipped: ad not loaded yet');
      return;
    }

    final completer = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (a) {
        debugPrint('$_tag onAdShowedFullScreenContent');
      },
      onAdImpression: (a) {
        debugPrint('$_tag onAdImpression');
      },
      onAdClicked: (a) {
        debugPrint('$_tag onAdClicked');
      },
      onAdDismissedFullScreenContent: (a) {
        debugPrint('$_tag onAdDismissedFullScreenContent');
        a.dispose();
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (a, error) {
        debugPrint('$_tag onAdFailedToShowFullScreenContent code=${error.code} '
            'domain=${error.domain} message="${error.message}"');
        a.dispose();
        if (!completer.isCompleted) completer.complete();
      },
    );

    debugPrint('$_tag calling ad.show()');
    try {
      await ad.show();
      debugPrint('$_tag ad.show() returned, awaiting dismiss callback');
    } catch (e, st) {
      debugPrint('$_tag ad.show() threw: $e\n$st');
      if (!completer.isCompleted) completer.complete();
    }
    return completer.future;
  }

  void dispose() {
    debugPrint('$_tag dispose() called: hadAd=${_ad != null}');
    _disposed = true;
    _ad?.dispose();
    _ad = null;
  }
}
