# LOUD

マイクで叫び声の音量を測定して世界ランキングに登録する Flutter アプリ。

- **Flutter**: iOS + Android
- **DB**: Supabase
- **音量計測**: `noise_meter`
- **広告**: Google Mobile Ads（AdMob バナー）
- **国判定**: ip-api.com（IP → 国コード/国名）

## 画面構成

1. **HOME** — ニックネーム入力（6文字 A-Z/0-9・iOS ピッカー風ドラムロール・ゲーセン風 UI）+ SCREAM ボタン
2. **MEASURE** — 3…2…1 → `NOW SCREAM!!`（3秒計測）→ 結果へ
3. **RANKING** — WORLD / COUNTRY タブ・国旗 + 国名表示

## セットアップ

### 1. Supabase

1. [Supabase Dashboard](https://app.supabase.com/) → 該当プロジェクトを開く
2. **SQL Editor** で `supabase/schema.sql` の内容をすべて実行
3. **Project Settings → API** から `Publishable key`（anon key）をコピー
4. `lib/config/env.dart` の `supabasePublishableKey` に貼り付け

```dart
// lib/config/env.dart
static const String supabasePublishableKey = 'eyJhbGciOiJI...'; // ← ここ
```

### 2. AdMob

開発中は Google 公式テスト ID（コード/Manifest/Info.plist にプリセット済み）が使われます。本番リリース時は以下を差し替えてください：

| 場所 | 内容 |
| --- | --- |
| `android/app/src/main/AndroidManifest.xml` | `com.google.android.gms.ads.APPLICATION_ID` の value を本番 App ID に |
| `ios/Runner/Info.plist` | `GADApplicationIdentifier` を本番 App ID に |
| `lib/config/env.dart` | `useAdMobTestIds = false` に |
| `lib/services/ad_helper.dart` | `_prod` 側のバナー Unit ID を埋める |

### 3. 実行

```bash
flutter pub get
flutter run            # 接続中の実機 or シミュレータで起動
```

> **Note**: noise_meter は実機マイクを使うため、iOS シミュレータではうまく動かない場合があります。実機推奨。

## ディレクトリ構成

```
lib/
├── main.dart                       # 起動・Supabase / AdMob 初期化
├── config/
│   └── env.dart                    # Supabase URL / Key、AdMob テストフラグ
├── models/
│   └── ranking_entry.dart          # ランキング1件のモデル + 国旗 emoji
├── services/
│   ├── ad_helper.dart              # AdMob Unit ID
│   ├── geo_service.dart            # IP→国コード/国名（ip-api.com）
│   └── ranking_service.dart        # Supabase への登録 / 取得 / 順位 RPC
├── screens/
│   ├── home_screen.dart            # ホーム
│   ├── measure_screen.dart         # 計測（カウントダウン → 3秒）
│   ├── result_screen.dart          # 結果
│   └── ranking_screen.dart         # ランキング
└── widgets/
    └── banner_ad_widget.dart       # 共通 AdMob バナー
supabase/
└── schema.sql                      # rankings テーブル + RLS + 順位 RPC
```

## パーミッション

| プラットフォーム | 設定 |
| --- | --- |
| iOS | `NSMicrophoneUsageDescription`, `NSUserTrackingUsageDescription`, `GADApplicationIdentifier` |
| Android | `RECORD_AUDIO`, `INTERNET`, `ACCESS_NETWORK_STATE`, `com.google.android.gms.ads.APPLICATION_ID` |

## ビルド要件

- Android `minSdk = 23`（AdMob のため引き上げ済み）
- iOS は標準のまま（実機テスト時はマイク権限ダイアログを確認）
# phriend
