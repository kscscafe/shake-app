/// 環境設定。Supabase / AdMob のキーをここで管理する。
class Env {
  static const String supabaseUrl =
      'https://hvcyxbvgwedbmkhvezst.supabase.co';

  /// Supabase ダッシュボード → Project Settings → API → anon key
  static const String supabasePublishableKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh2Y3l4YnZnd2VkYm1raHZlenN0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc1OTY5NzAsImV4cCI6MjA5MzE3Mjk3MH0.71GS8KK1PKPSUbayGP1lYP1hoWv7XKti6nWl-53gVmI';

  /// AdMob のテスト/本番 ID は [AdHelper] 側で切り替える。
  /// 本番リリース時は false。開発中は true にしてテスト広告に戻す。
  static const bool useAdMobTestIds = false;

  /// 広告（バナー / インタースティシャル）の表示・ロードを有効にするか。
  /// スクリーンショット撮影など、広告を一時的に隠したいときは false にする。
  /// リリース時は必ず true に戻すこと。
  static const bool adsEnabled = true;
}
