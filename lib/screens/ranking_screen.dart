import 'package:flutter/material.dart';

import '../models/ranking_entry.dart';
import '../services/ad_helper.dart';
import '../services/analytics_service.dart';
import '../services/geo_service.dart';
import '../services/intensity_converter.dart';
import '../services/ranking_service.dart';
import '../services/screenshot_share_service.dart';
import '../widgets/banner_ad_widget.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);
  late Future<List<RankingEntry>> _world;
  late Future<_CountryView> _country;
  final GlobalKey _shareKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _world = RankingService().fetchWorldRanking();
    _country = _loadCountry();
    AnalyticsService.instance.rankingViewed();
  }

  Future<_CountryView> _loadCountry() async {
    final geo = await GeoService().fetchCountry();
    final list = await RankingService().fetchCountryRanking(
      countryCode: geo.countryCode,
    );
    return _CountryView(geo: geo, entries: list);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _onShare() async {
    final ok = await ScreenshotShareService.shareWidget(
      boundaryKey: _shareKey,
      text:
          'Check out the SHAKE world ranking! 🏆 #SHAKE #ShakeToTheWorld',
      filenamePrefix: 'shake_ranking',
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.amberAccent,
        title: const Text(
          'RANKING',
          style: TextStyle(letterSpacing: 8, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.ios_share),
            onPressed: _onShare,
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Color(0xFF16A34A),
          labelColor: Colors.amberAccent,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'WORLD'),
            Tab(text: 'COUNTRY'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: RepaintBoundary(
              key: _shareKey,
              child: Container(
                color: Colors.black,
                child: TabBarView(
                  controller: _tab,
                  children: [
                    _WorldTab(future: _world),
                    _CountryTab(future: _country),
                  ],
                ),
              ),
            ),
          ),
          const BannerAdWidget(slot: AdSlot.rankingBanner),
        ],
      ),
    );
  }
}

class _CountryView {
  _CountryView({required this.geo, required this.entries});
  final GeoLocation geo;
  final List<RankingEntry> entries;
}

class _WorldTab extends StatelessWidget {
  const _WorldTab({required this.future});
  final Future<List<RankingEntry>> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RankingEntry>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF16A34A)),
          );
        }
        if (snap.hasError) {
          return _ErrorBox(message: snap.error.toString());
        }
        final list = snap.data ?? const <RankingEntry>[];
        if (list.isEmpty) {
          return const _EmptyBox();
        }
        return _RankingList(entries: list);
      },
    );
  }
}

class _CountryTab extends StatelessWidget {
  const _CountryTab({required this.future});
  final Future<_CountryView> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_CountryView>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF16A34A)),
          );
        }
        if (snap.hasError) {
          return _ErrorBox(message: snap.error.toString());
        }
        final view = snap.data;
        if (view == null || view.entries.isEmpty) {
          return const _EmptyBox();
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                view.geo.countryCode,
                style: const TextStyle(
                  color: Colors.amberAccent,
                  letterSpacing: 4,
                ),
              ),
            ),
            Expanded(child: _RankingList(entries: view.entries)),
          ],
        );
      },
    );
  }
}

class _RankingList extends StatelessWidget {
  const _RankingList({required this.entries});
  final List<RankingEntry> entries;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, __) =>
          const Divider(color: Colors.white12, height: 1),
      itemBuilder: (_, i) {
        final e = entries[i];
        final rank = i + 1;
        final color = switch (rank) {
          1 => Colors.amberAccent,
          2 => Colors.grey.shade300,
          3 => Colors.brown.shade300,
          _ => Colors.white,
        };
        final intensity = IntensityConverter.fromAcceleration(
          acceleration: e.acceleration,
          countryCode: e.countryCode,
        );
        return ListTile(
          leading: Text(
            e.flagEmoji,
            style: const TextStyle(fontSize: 28),
          ),
          title: Row(
            children: [
              Text(
                e.countryCode,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontFamily: 'Courier',
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                e.nickname,
                style: TextStyle(
                  color: color,
                  fontFamily: 'Courier',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          subtitle: Text(
            '${e.acceleration.toStringAsFixed(2)} m/s²',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 12,
              fontFamily: 'Courier',
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                intensity.label,
                style: const TextStyle(
                  color: Color(0xFF16A34A),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '#$rank',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'NO SCORES YET\nBE THE FIRST TO SHAKE',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white54,
          letterSpacing: 4,
          height: 1.6,
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          'Error\n$message',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF16A34A)),
        ),
      ),
    );
  }
}
