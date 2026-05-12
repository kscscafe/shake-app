import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import '../services/analytics_service.dart';
import '../services/geo_service.dart';
import '../services/interstitial_ad_manager.dart';
import '../services/ranking_service.dart';
import '../services/shake_sensor_service.dart';
import 'result_screen.dart';

enum _Phase { countdown, measuring, finalizing, error }

/// 体勢整えカウントダウン (10s) → 計測 (10s) → スコア送信 → 結果画面の流れ。
class MeasureScreen extends StatefulWidget {
  const MeasureScreen({super.key, required this.nickname});
  final String nickname;

  @override
  State<MeasureScreen> createState() => _MeasureScreenState();
}

class _MeasureScreenState extends State<MeasureScreen> {
  static const _countdownSeconds = 10;
  static const _measureDuration = Duration(seconds: 10);
  static const _topSeconds = 5;

  _Phase _phase = _Phase.countdown;
  int _countdown = _countdownSeconds;
  Timer? _ticker;
  String? _errorMessage;
  final InterstitialAdManager _interstitial = InterstitialAdManager();
  final ShakeSensorService _sensor = ShakeSensorService();

  // amplitude 制御は Android 一部端末のみサポート。iOS / 非対応端末では
  // HapticFeedback で代替するため、起動時に判定してキャッシュする。
  bool _hasAmplitudeControl = false;

  @override
  void initState() {
    super.initState();
    // 計測 + Supabase ラウンドトリップ中に間に合うよう早めにプリロード。
    _interstitial.load();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        _hasAmplitudeControl =
            (await Vibration.hasAmplitudeControl()) == true;
      }
    } catch (_) {
      _hasAmplitudeControl = false;
    }
    if (!mounted) return;
    _runCountdown();
  }

  void _runCountdown() {
    _ticker?.cancel();
    _vibrateForTick(_countdown); // 表示開始の '10' でも振動
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _countdown -= 1);
      if (_countdown > 0) {
        _vibrateForTick(_countdown);
      } else {
        _vibrateForGo();
        t.cancel();
        _beginMeasuring();
      }
    });
  }

  /// カウントダウン中の段階的バイブ。
  /// 10〜6: 弱, 5〜2: 中, 1: 強。
  void _vibrateForTick(int t) {
    final int amplitude;
    final int durationMs;
    if (t >= 6) {
      amplitude = 64;
      durationMs = 80;
      HapticFeedback.lightImpact();
    } else if (t >= 2) {
      amplitude = 128;
      durationMs = 120;
      HapticFeedback.mediumImpact();
    } else {
      amplitude = 200;
      durationMs = 180;
      HapticFeedback.heavyImpact();
    }
    if (_hasAmplitudeControl) {
      Vibration.vibrate(duration: durationMs, amplitude: amplitude);
    }
  }

  /// 計測開始（GO）の最強バイブ。
  void _vibrateForGo() {
    HapticFeedback.heavyImpact();
    Future.delayed(
        const Duration(milliseconds: 100), HapticFeedback.heavyImpact);
    if (_hasAmplitudeControl) {
      Vibration.vibrate(duration: 350, amplitude: 255);
    }
  }

  /// 計測終了の合図。カウントダウンとは違うパターン。
  void _vibrateForFinish() {
    if (_hasAmplitudeControl) {
      Vibration.vibrate(
        pattern: [0, 100, 80, 100, 80, 250],
        intensities: [0, 200, 0, 200, 0, 255],
      );
    } else {
      HapticFeedback.heavyImpact();
      Future.delayed(
          const Duration(milliseconds: 120), HapticFeedback.heavyImpact);
      Future.delayed(
          const Duration(milliseconds: 240), HapticFeedback.heavyImpact);
    }
  }

  Future<void> _beginMeasuring() async {
    if (!mounted) return;
    setState(() => _phase = _Phase.measuring);
    try {
      final acceleration = await _sensor.measure(
        duration: _measureDuration,
        topSeconds: _topSeconds,
      );
      if (!mounted) return;
      _vibrateForFinish();
      await _finalize(acceleration);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _errorMessage = '計測に失敗しました: $e';
      });
    }
  }

  Future<void> _finalize(double acceleration) async {
    setState(() => _phase = _Phase.finalizing);
    try {
      final geo = await GeoService().fetchCountry();
      final res = await RankingService().submitScore(
        nickname: widget.nickname,
        acceleration: acceleration,
        countryCode: geo.countryCode,
        countryName: geo.countryName,
      );
      unawaited(AnalyticsService.instance.shakeCompleted(
        nickname: widget.nickname,
        acceleration: acceleration,
        countryCode: geo.countryCode,
        worldRank: res.worldRank,
        countryRank: res.countryRank,
      ));

      // ロード済みならインタースティシャルを表示してから結果画面へ。
      // 未ロード/失敗時はスルー（フェイルオープン）。
      await _interstitial.showIfAvailable();
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            nickname: widget.nickname,
            acceleration: acceleration,
            countryCode: geo.countryCode,
            countryName: geo.countryName,
            worldRank: res.worldRank,
            countryRank: res.countryRank,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _errorMessage = 'スコア登録に失敗しました: $e';
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _sensor.dispose();
    _interstitial.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: Center(child: _buildBody())),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case _Phase.countdown:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'GET READY',
              style: TextStyle(
                color: Colors.amberAccent,
                fontSize: 18,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _countdown > 0 ? '$_countdown' : 'GO',
              style: const TextStyle(
                color: Colors.amberAccent,
                fontSize: 220,
                fontWeight: FontWeight.w900,
                shadows: [Shadow(color: Colors.orange, blurRadius: 40)],
              ),
            ),
          ],
        );
      case _Phase.measuring:
        return const Text(
          'NOW SHAKE!!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF16A34A),
            fontSize: 56,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            shadows: [Shadow(color: Color(0xFF15803D), blurRadius: 32)],
          ),
        );
      case _Phase.finalizing:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(color: Colors.amberAccent),
            SizedBox(height: 24),
            Text('SUBMITTING...',
                style: TextStyle(color: Colors.white70, letterSpacing: 4)),
          ],
        );
      case _Phase.error:
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  color: Color(0xFF16A34A), size: 64),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'エラーが発生しました',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('戻る'),
              ),
            ],
          ),
        );
    }
  }
}
