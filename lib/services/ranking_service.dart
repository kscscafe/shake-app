import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ranking_entry.dart';

class SubmitResult {
  SubmitResult({required this.worldRank, required this.countryRank});
  final int worldRank;
  final int countryRank;
}

/// SHAKE のランキング操作。スコアは m/s²（加速度の生値）で保存し、
/// 表示側で震度 / MMI に換算する。
///
/// TODO: Supabase 側に SHAKE 用のテーブル `rankings` と RPC
///       `world_rank_for` / `country_rank_for`（パラメータ
///       `target_acceleration`, `target_country`）を新規作成すること。
class RankingService {
  RankingService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<SubmitResult> submitScore({
    required String nickname,
    required double acceleration,
    required String countryCode,
    required String countryName,
  }) async {
    await _client.from('rankings').insert({
      'nickname': nickname,
      'acceleration': acceleration,
      'country_code': countryCode,
      'country_name': countryName,
    });

    final worldRank = await _client.rpc(
      'world_rank_for',
      params: {'target_acceleration': acceleration},
    );
    final countryRank = await _client.rpc(
      'country_rank_for',
      params: {
        'target_acceleration': acceleration,
        'target_country': countryCode,
      },
    );

    return SubmitResult(
      worldRank: _asInt(worldRank),
      countryRank: _asInt(countryRank),
    );
  }

  /// Supabase の RPC は bigint を int で返すが、PostgREST 経由だと
  /// 単一スカラーが [{"<fn>": v}] や List で来ることもある。
  /// int / double / String / List / Map のどれでも int に解決する。
  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.parse(v);
    if (v is List && v.isNotEmpty) return _asInt(v.first);
    if (v is Map && v.isNotEmpty) return _asInt(v.values.first);
    throw FormatException('Cannot convert $v (${v.runtimeType}) to int');
  }

  Future<List<RankingEntry>> fetchWorldRanking({int limit = 100}) async {
    final res = await _client
        .from('rankings')
        .select()
        .order('acceleration', ascending: false)
        .limit(limit);
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(RankingEntry.fromMap)
        .toList();
  }

  Future<List<RankingEntry>> fetchCountryRanking({
    required String countryCode,
    int limit = 100,
  }) async {
    final res = await _client
        .from('rankings')
        .select()
        .eq('country_code', countryCode)
        .order('acceleration', ascending: false)
        .limit(limit);
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(RankingEntry.fromMap)
        .toList();
  }
}
