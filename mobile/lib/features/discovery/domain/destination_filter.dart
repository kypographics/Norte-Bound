const Object _unset = Object();

class DestinationFilter {
  const DestinationFilter({
    this.query = '',
    this.lguCode,
    this.cluster,
    this.categoryCode,
    this.popularityTier,
    this.isFree,
    this.page = 1,
    this.limit = 20,
  });

  final String query;
  final String? lguCode;
  final String? cluster;
  final String? categoryCode;
  final String? popularityTier;
  final bool? isFree;
  final int page;
  final int limit;

  bool get hasActiveFilters =>
      query.trim().isNotEmpty ||
      lguCode != null ||
      cluster != null ||
      categoryCode != null ||
      popularityTier != null ||
      isFree != null;

  int get activeFilterCount {
    var count = 0;

    if (query.trim().isNotEmpty) count++;
    if (lguCode != null) count++;
    if (cluster != null) count++;
    if (categoryCode != null) count++;
    if (popularityTier != null) count++;
    if (isFree != null) count++;

    return count;
  }

  DestinationFilter copyWith({
    String? query,
    Object? lguCode = _unset,
    Object? cluster = _unset,
    Object? categoryCode = _unset,
    Object? popularityTier = _unset,
    Object? isFree = _unset,
    int? page,
    int? limit,
  }) {
    return DestinationFilter(
      query: query ?? this.query,
      lguCode: identical(lguCode, _unset) ? this.lguCode : lguCode as String?,
      cluster: identical(cluster, _unset) ? this.cluster : cluster as String?,
      categoryCode: identical(categoryCode, _unset)
          ? this.categoryCode
          : categoryCode as String?,
      popularityTier: identical(popularityTier, _unset)
          ? this.popularityTier
          : popularityTier as String?,
      isFree: identical(isFree, _unset) ? this.isFree : isFree as bool?,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    final trimmedQuery = query.trim();

    return {
      if (trimmedQuery.isNotEmpty) 'q': trimmedQuery,
      if (lguCode != null) 'lgu_code': lguCode,
      if (cluster != null) 'cluster': cluster,
      if (categoryCode != null) 'category_code': categoryCode,
      if (popularityTier != null) 'popularity_tier': popularityTier,
      if (isFree != null) 'is_free': isFree,
      'page': page,
      'limit': limit,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is DestinationFilter &&
        other.query == query &&
        other.lguCode == lguCode &&
        other.cluster == cluster &&
        other.categoryCode == categoryCode &&
        other.popularityTier == popularityTier &&
        other.isFree == isFree &&
        other.page == page &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(
    query,
    lguCode,
    cluster,
    categoryCode,
    popularityTier,
    isFree,
    page,
    limit,
  );
}
