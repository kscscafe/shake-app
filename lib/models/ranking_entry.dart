class RankingEntry {
  RankingEntry({
    required this.id,
    required this.nickname,
    required this.acceleration,
    required this.countryCode,
    required this.countryName,
    required this.createdAt,
  });

  final String id;
  final String nickname;

  /// スコア。加速度（m/s²）の生値。表示時に震度 / MMI に変換する。
  final double acceleration;
  final String countryCode;
  final String countryName;
  final DateTime createdAt;

  factory RankingEntry.fromMap(Map<String, dynamic> map) {
    // SHAKE 用テーブルでは id が bigint serial のため、
    // dynamic を toString() で受けて UUID/bigint どちらでも吸収する。
    return RankingEntry(
      id: map['id'].toString(),
      nickname: map['nickname'] as String,
      acceleration: (map['acceleration'] as num).toDouble(),
      countryCode: map['country_code'] as String,
      countryName: map['country_name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// "JP" → 🇯🇵 を生成する（regional indicator symbols）。
  String get flagEmoji {
    if (countryCode.length != 2) return '🏳';
    final code = countryCode.toUpperCase();
    final first = code.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final second = code.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(first) + String.fromCharCode(second);
  }
}
