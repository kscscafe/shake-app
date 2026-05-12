import 'package:flutter/material.dart';

import '../models/ranking_entry.dart';
import '../services/ad_helper.dart';
import '../services/analytics_service.dart';
import '../services/intensity_converter.dart';
import '../services/review_prompt_service.dart';
import '../services/screenshot_share_service.dart';
import '../widgets/banner_ad_widget.dart';
import 'home_screen.dart';
import 'ranking_screen.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.nickname,
    required this.acceleration,
    required this.countryCode,
    required this.countryName,
    required this.worldRank,
    required this.countryRank,
  });

  final String nickname;

  /// m/s²（生値）。表示時に震度 / MMI へ変換する。
  final double acceleration;
  final String countryCode;
  final String countryName;
  final int worldRank;
  final int countryRank;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final GlobalKey _shareKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // 結果画面が描画 → 操作可能になってから少し待ってレビュー要求。
    // 画面遷移と被るとシステム側で要求が無視されることがある。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        ReviewPromptService.incrementAndMaybePrompt();
      });
    });
  }

  String get _flag => RankingEntry(
        id: '',
        nickname: widget.nickname,
        acceleration: widget.acceleration,
        countryCode: widget.countryCode,
        countryName: widget.countryName,
        createdAt: DateTime.now(),
      ).flagEmoji;

  Intensity get _intensity => IntensityConverter.fromAcceleration(
        acceleration: widget.acceleration,
        countryCode: widget.countryCode,
      );

  String get _scaleHashtag =>
      _intensity.scale == IntensityScale.jma ? '#震度' : '#MMI';

  Future<void> _onShare() async {
    final intensity = _intensity;
    final ok = await ScreenshotShareService.shareWidget(
      boundaryKey: _shareKey,
      text:
          'I shook the world! ${intensity.label} '
          '(${widget.acceleration.toStringAsFixed(2)} m/s²) '
          '🌍 World #${widget.worldRank} #SHAKE #ShakeToTheWorld $_scaleHashtag',
      filenamePrefix: 'shake_result',
    );
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.black,
        content: Text('シェアに失敗しました', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final intensity = _intensity;
    final scaleLabel =
        intensity.scale == IntensityScale.jma ? '震度' : 'MMI';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RepaintBoundary(
                key: _shareKey,
                child: Container(
                  color: Colors.black,
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      const Text(
                        'YOUR SCORE',
                        style: TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 18,
                          letterSpacing: 8,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            widget.nickname,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Courier',
                              letterSpacing: 4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        scaleLabel,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 16,
                          letterSpacing: 6,
                        ),
                      ),
                      Text(
                        intensity.label,
                        style: const TextStyle(
                          color: Color(0xFF16A34A),
                          fontSize: 96,
                          fontWeight: FontWeight.w900,
                          shadows: [Shadow(color: Color(0xFF15803D), blurRadius: 32)],
                        ),
                      ),
                      Text(
                        '${widget.acceleration.toStringAsFixed(2)} m/s²',
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 22,
                          letterSpacing: 4,
                          fontFamily: 'Courier',
                        ),
                      ),
                      const SizedBox(height: 24),
                      _RankRow(
                        icon: '🌍',
                        label: 'WORLD',
                        rank: widget.worldRank,
                      ),
                      const SizedBox(height: 8),
                      _RankRow(
                        icon: _flag,
                        label: widget.countryName.toUpperCase(),
                        rank: widget.countryRank,
                      ),
                      const Spacer(),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text(
                          '#SHAKE #ShakeToTheWorld',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const RankingScreen(),
                ),
              ),
              icon: const Icon(Icons.emoji_events),
              label: const Text('VIEW RANKING'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.amberAccent,
                foregroundColor: Colors.black,
                minimumSize: const Size(220, 52),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _onShare,
              icon: const Icon(Icons.ios_share, color: Colors.white),
              label: const Text(
                'SHARE',
                style: TextStyle(color: Colors.white, letterSpacing: 4),
              ),
            ),
            TextButton(
              onPressed: () {
                AnalyticsService.instance.tryAgain();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (_) => false,
                );
              },
              child: const Text(
                'TRY AGAIN',
                style: TextStyle(color: Colors.white, letterSpacing: 4),
              ),
            ),
            const SizedBox(height: 8),
            const BannerAdWidget(slot: AdSlot.resultBanner),
          ],
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.icon,
    required this.label,
    required this.rank,
  });
  final String icon;
  final String label;
  final int rank;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(icon, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          '#$rank',
          style: const TextStyle(
            color: Colors.amberAccent,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
