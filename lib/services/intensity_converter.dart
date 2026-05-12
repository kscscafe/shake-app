/// 加速度（m/s²）→ 震度（日本）/ MMI（海外）の変換ロジック。
///
/// 仕様書「3. 計測仕様」のテーブルをそのまま実装する。
/// ランキングでは加速度の生値で並べ、表示時にここで国別フォーマットへ変換する。
/// 表示は常に MMI を主スケールとし、JP の場合は震度を併記する。
library;

enum IntensityScale { jma, mmi }

class Intensity {
  const Intensity({
    required this.scale,
    required this.mmiLabel,
    this.jmaLabel,
  });

  /// 計測者の所属国による分類。JP のみ jma、それ以外は mmi。
  final IntensityScale scale;

  /// 主表示用の MMI ラベル（"Ⅵ" など）。常に値あり。
  final String mmiLabel;

  /// JP の場合のみ非 null。震度ラベル（"5弱" など）。
  final String? jmaLabel;

  /// 後方互換: 旧 API。常に MMI ラベルを返す。
  String get label => mmiLabel;
}

class IntensityConverter {
  IntensityConverter._();

  /// [countryCode] が 'JP' なら MMI と震度の両方を、それ以外は MMI のみを返す。
  static Intensity fromAcceleration({
    required double acceleration,
    required String countryCode,
  }) {
    final mmi = _mmiLabel(acceleration);
    if (countryCode.toUpperCase() == 'JP') {
      return Intensity(
        scale: IntensityScale.jma,
        mmiLabel: mmi,
        jmaLabel: _jmaLabel(acceleration),
      );
    }
    return Intensity(
      scale: IntensityScale.mmi,
      mmiLabel: mmi,
    );
  }

  static String _jmaLabel(double a) {
    if (a >= 60.0) return '7';
    if (a >= 40.0) return '6強';
    if (a >= 25.0) return '6弱';
    if (a >= 14.0) return '5強';
    if (a >= 8.0) return '5弱';
    if (a >= 2.5) return '4';
    if (a >= 0.8) return '3';
    if (a >= 0.25) return '2';
    if (a >= 0.08) return '1';
    return '0';
  }

  static String _mmiLabel(double a) {
    if (a >= 40.0) return 'Ⅸ+';
    if (a >= 12.0) return 'Ⅷ';
    if (a >= 6.3) return 'Ⅶ';
    if (a >= 2.5) return 'Ⅵ';
    if (a >= 0.8) return 'Ⅴ';
    if (a >= 0.25) return 'Ⅳ';
    if (a >= 0.08) return 'Ⅱ–Ⅲ';
    return 'Ⅰ';
  }
}
