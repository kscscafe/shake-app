import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/env.dart';
import 'screens/home_screen.dart';
import 'services/analytics_service.dart';
import 'services/tracking_consent_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase / Supabase は ATT に依存しないので先に初期化。
  await Firebase.initializeApp();
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabasePublishableKey,
  );

  // NOTE: MobileAds.instance.initialize() は ATT の確定後に呼ぶ必要があるため
  //   ここでは呼ばない。ShakeApp.initState の post-frame コールバックで実行する。

  runApp(const ShakeApp());
}

class ShakeApp extends StatefulWidget {
  const ShakeApp({super.key});

  @override
  State<ShakeApp> createState() => _ShakeAppState();
}

class _ShakeAppState extends State<ShakeApp> with WidgetsBindingObserver {
  bool _attRequested = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 最初のフレームが描画され UI が key window として有効になってから ATT 要求。
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapTracking());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_attRequested) {
      _bootstrapTracking();
    }
  }

  Future<void> _bootstrapTracking() async {
    if (_attRequested) return;
    _attRequested = true;

    // 1) ATT ダイアログ（iOS 14+ かつ未決定時のみ実際に表示される）
    await TrackingConsentService.requestIfNeeded();

    // 2) AdMob 初期化（ATT 確定後のため、IDFA 取得可否が正しく反映される）
    await MobileAds.instance.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SHAKE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF16A34A),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      navigatorObservers: [AnalyticsService.instance.navigatorObserver],
    );
  }
}
