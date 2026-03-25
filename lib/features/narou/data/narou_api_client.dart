import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yomou/core/network/dio_provider.dart';
import 'package:yomou/features/narou/data/models/narou_novel_record.dart';
import 'package:yomou/features/novels/domain/entities/novel_ranking_period.dart';
import 'package:yomou/features/novels/domain/entities/paged_result.dart';

final narouApiClientProvider = Provider<NarouApiClient>((ref) {
  return NarouApiClient(ref.watch(dioProvider));
});

class NarouApiClient {
  NarouApiClient(this._dio);

  static const String _endpoint = 'https://api.syosetu.com/novelapi/api/';

  final Dio _dio;

  Future<PagedResult<NarouNovelRecord>> fetchRankingPage({
    required NovelRankingPeriod period,
    required int page,
    required int pageSize,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      _endpoint,
      queryParameters: <String, Object>{
        'out': 'json',
        'of': 't-n-w-s-g-k-ga-l-ah-r-f-e-no',
        'order': _orderForPeriod(period),
        'st': ((page - 1) * pageSize) + 1,
        'lim': pageSize,
      },
    );

    final data = response.data;
    if (data == null || data.isEmpty) {
      throw const FormatException('Narou API returned an empty response.');
    }

    final metadata = data.first;
    if (metadata is! Map) {
      throw const FormatException('Narou API metadata was missing.');
    }

    final metadataMap = Map<String, dynamic>.from(metadata);
    final allCount = metadataMap['allcount'];
    if (allCount is! num) {
      throw const FormatException('Narou API allcount was missing.');
    }

    final items = data
        .skip(1)
        .map((item) {
          if (item is! Map) {
            throw const FormatException('Narou API item was malformed.');
          }

          return NarouNovelRecord.fromJson(Map<String, dynamic>.from(item));
        })
        .toList(growable: false);

    return PagedResult<NarouNovelRecord>(
      items: items,
      totalCount: allCount.toInt(),
      page: page,
      pageSize: pageSize,
    );
  }

  String _orderForPeriod(NovelRankingPeriod period) {
    return switch (period) {
      NovelRankingPeriod.overall => 'hyoka',
      NovelRankingPeriod.daily => 'dailypoint',
      NovelRankingPeriod.weekly => 'weeklypoint',
      NovelRankingPeriod.monthly => 'monthlypoint',
      NovelRankingPeriod.quarterly => 'quarterpoint',
      NovelRankingPeriod.yearly => 'yearlypoint',
    };
  }
}
