import 'package:yomou/features/novels/domain/entities/novel_search_order.dart';
import 'package:yomou/features/novels/domain/entities/novel_search_target.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';

class NovelSearchRequest {
  const NovelSearchRequest({
    required this.site,
    this.query = '',
    this.target = NovelSearchTarget.all,
    this.genreCode,
    this.original,
    this.order = NovelSearchOrder.newest,
    this.page = 1,
    this.pageSize = 20,
  });

  static const Object _unset = Object();

  final NovelSite site;
  final String query;
  final NovelSearchTarget target;
  final int? genreCode;
  final String? original;
  final NovelSearchOrder order;
  final int page;
  final int pageSize;

  String get normalizedQuery => query.trim();
  bool get hasQuery => normalizedQuery.isNotEmpty;

  Map<String, String> toQueryParameters() {
    return <String, String>{
      if (hasQuery) 'q': normalizedQuery,
      'target': target.queryValue,
      if (genreCode != null) 'genre': '$genreCode',
      if (original case final original? when original.trim().isNotEmpty)
        'original': original.trim(),
      'order': order.queryValue,
    };
  }

  NovelSearchRequest copyWith({
    NovelSite? site,
    String? query,
    NovelSearchTarget? target,
    Object? genreCode = _unset,
    Object? original = _unset,
    NovelSearchOrder? order,
    int? page,
    int? pageSize,
  }) {
    return NovelSearchRequest(
      site: site ?? this.site,
      query: query ?? this.query,
      target: target ?? this.target,
      genreCode: identical(genreCode, _unset)
          ? this.genreCode
          : genreCode as int?,
      original: identical(original, _unset)
          ? this.original
          : original as String?,
      order: order ?? this.order,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NovelSearchRequest &&
            site == other.site &&
            normalizedQuery == other.normalizedQuery &&
            target == other.target &&
            genreCode == other.genreCode &&
            original == other.original &&
            order == other.order &&
            page == other.page &&
            pageSize == other.pageSize;
  }

  @override
  int get hashCode => Object.hash(
    site,
    normalizedQuery,
    target,
    genreCode,
    original,
    order,
    page,
    pageSize,
  );
}
