import 'dart:convert';

import 'package:http/http.dart' as http;

class GeoLocation {
  const GeoLocation({required this.countryCode, required this.countryName});
  final String countryCode;
  final String countryName;
}

/// IP アドレスから国コード/国名を取得するサービス。
/// 失敗時は "XX / Unknown" にフォールバックする。
class GeoService {
  GeoService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const GeoLocation _fallback = GeoLocation(
    countryCode: 'XX',
    countryName: 'Unknown',
  );

  Future<GeoLocation> fetchCountry() async {
    try {
      final res = await _client
          .get(Uri.parse(
              'http://ip-api.com/json/?fields=status,country,countryCode'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return _fallback;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (json['status'] != 'success') return _fallback;
      final code = (json['countryCode'] as String?)?.toUpperCase();
      final name = json['country'] as String?;
      if (code == null || code.length != 2 || name == null) return _fallback;
      return GeoLocation(countryCode: code, countryName: name);
    } catch (_) {
      return _fallback;
    }
  }
}
