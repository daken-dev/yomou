import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yomou/core/network/dio_provider.dart';
import 'package:yomou/features/narou/data/models/narou_novel_record.dart';
import 'package:yomou/features/novels/domain/entities/novel_ranking_period.dart';
import 'package:yomou/features/novels/domain/entities/novel_search_order.dart';
import 'package:yomou/features/novels/domain/entities/novel_search_target.dart';
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
      queryParameters: _baseQueryParameters(
        order: _rankingOrderForPeriod(period),
        page: page,
        pageSize: pageSize,
      ),
    );

    return _parsePagedResponse(response.data, page: page, pageSize: pageSize);
  }

  Future<PagedResult<NarouNovelRecord>> fetchSearchPage({
    String? word,
    required NovelSearchTarget target,
    int? genreCode,
    required NovelSearchOrder order,
    required int page,
    required int pageSize,
  }) async {
    final queryParameters = _baseQueryParameters(
      order: _searchOrder(order),
      page: page,
      pageSize: pageSize,
    );
    final normalizedWord = word?.trim();

    if (normalizedWord != null && normalizedWord.isNotEmpty) {
      queryParameters['word'] = normalizedWord;
    }
    if (genreCode != null) {
      queryParameters['genre'] = genreCode;
    }
    switch (target) {
      case NovelSearchTarget.all:
        break;
      case NovelSearchTarget.title:
        queryParameters['title'] = 1;
      case NovelSearchTarget.story:
        queryParameters['ex'] = 1;
      case NovelSearchTarget.keyword:
        queryParameters['keyword'] = 1;
      case NovelSearchTarget.author:
        queryParameters['wname'] = 1;
    }

    final response = await _dio.get<List<dynamic>>(
      _endpoint,
      queryParameters: queryParameters,
    );

    return _parsePagedResponse(response.data, page: page, pageSize: pageSize);
  }

  Map<String, Object> _baseQueryParameters({
    required String order,
    required int page,
    required int pageSize,
  }) {
    return <String, Object>{
      'out': 'json',
      'of': 't-n-w-s-g-k-ga-l-ah-r-f-e-no',
      'order': order,
      'st': ((page - 1) * pageSize) + 1,
      'lim': pageSize,
    };
  }

  PagedResult<NarouNovelRecord> _parsePagedResponse(
    List<dynamic>? data, {
    required int page,
    required int pageSize,
  }) {
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

  String _rankingOrderForPeriod(NovelRankingPeriod period) {
    return switch (period) {
      NovelRankingPeriod.overall => 'hyoka',
      NovelRankingPeriod.daily => 'dailypoint',
      NovelRankingPeriod.weekly => 'weeklypoint',
      NovelRankingPeriod.monthly => 'monthlypoint',
      NovelRankingPeriod.quarterly => 'quarterpoint',
      NovelRankingPeriod.yearly => 'yearlypoint',
    };
  }

  String _searchOrder(NovelSearchOrder order) {
    return switch (order) {
      NovelSearchOrder.newest => 'new',
      NovelSearchOrder.overallPoint => 'hyoka',
      NovelSearchOrder.dailyPoint => 'dailypoint',
      NovelSearchOrder.weeklyPoint => 'weeklypoint',
      NovelSearchOrder.monthlyPoint => 'monthlypoint',
      NovelSearchOrder.quarterlyPoint => 'quarterpoint',
      NovelSearchOrder.yearlyPoint => 'yearlypoint',
    };
  }
}
