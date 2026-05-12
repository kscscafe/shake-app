/// 加速度（m/s²）→ 震度（日本）/ MMI（海外）の変換ロジック。
///
/// 仕様書「3. 計測仕様」のテーブルをそのまま実装する。
/// ランキングでは加速度の生値で並べ、表示時にここで国別フォーマットへ変換する。
library;

enum IntensityScale { jma, mmi }

class Intensity {
  const Intensity({required this.scale, required this.label});

  final IntensityScale scale;

  /// 画面に表示するラベル。日本: "5弱"、海外: "Ⅵ" など。
  final String label;
}

class IntensityConverter {
  IntensityConverter._();

  /// [countryCode] が 'JP' なら震度、それ以外は MMI に換算する。
  static Intensity fromAcceleration({
    required double acceleration,
    required String countryCode,
  }) {
    if (countryCode.toUpperCase() == 'JP') {
      return Intensity(
        scale: IntensityScale.jma,
        label: _jmaLabel(acceleration),
      );
    }
    return Intensity(
      scale: IntensityScale.mmi,
      label: _mmiLabel(acceleration),
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
