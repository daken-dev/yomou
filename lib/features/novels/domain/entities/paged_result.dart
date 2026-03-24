class PagedResult<T> {
  PagedResult({
    required List<T> items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  }) : items = List<T>.unmodifiable(items);

  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;

  bool get hasMore => (page * pageSize) < totalCount;
  int get nextPage => page + 1;
}
