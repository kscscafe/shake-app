import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/env.dart';
import '../services/ad_helper.dart';

/// AdMob 標準バナー（320x50）。
/// 画面ごとに異なる Unit ID を使うため、[slot] を渡して識別する。
/// 読み込み完了するまでは枠だけ確保しつつ何も描画しない（CLS 抑止）。
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key, required this.slot});

  final AdSlot slot;

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (!Env.adsEnabled) return;
    _ad = BannerAd(
      adUnitId: AdHelper.adUnitId(widget.slot),
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Env.adsEnabled) return const SizedBox.shrink();
    return SizedBox(
      height: AdSize.banner.height.toDouble(),
      child: (_loaded && _ad != null)
          ? AdWidget(ad: _ad!)
          : const SizedBox.shrink(),
    );
  }
}
