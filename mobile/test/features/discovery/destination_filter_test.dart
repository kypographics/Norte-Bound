import 'package:flutter_test/flutter_test.dart';
import 'package:norte_bound/features/discovery/domain/destination_filter.dart';

void main() {
  test('serializes only active filters and pagination', () {
    const filter = DestinationFilter(
      query: '  empanada  ',
      lguCode: 'batac-city',
      categoryCode: 'food_culinary',
      popularityTier: 'hidden_gem',
      isFree: true,
      page: 2,
      limit: 40,
    );

    expect(filter.toQueryParameters(), {
      'q': 'empanada',
      'lgu_code': 'batac-city',
      'category_code': 'food_culinary',
      'popularity_tier': 'hidden_gem',
      'is_free': true,
      'page': 2,
      'limit': 40,
    });
  });

  test('copyWith clears nullable filters explicitly', () {
    const filter = DestinationFilter(
      lguCode: 'paoay',
      cluster: 'southern_heritage_coast',
      categoryCode: 'heritage_cultural',
      popularityTier: 'iconic_hub',
      isFree: true,
    );

    final cleared = filter.copyWith(
      lguCode: null,
      cluster: null,
      categoryCode: null,
      popularityTier: null,
      isFree: null,
    );

    expect(cleared.lguCode, isNull);
    expect(cleared.cluster, isNull);
    expect(cleared.categoryCode, isNull);
    expect(cleared.popularityTier, isNull);
    expect(cleared.isFree, isNull);
  });

  test('copyWith preserves nullable filters when omitted', () {
    const filter = DestinationFilter(
      lguCode: 'paoay',
      categoryCode: 'heritage_cultural',
      isFree: true,
    );

    final pageTwo = filter.copyWith(page: 2);

    expect(pageTwo.lguCode, 'paoay');
    expect(pageTwo.categoryCode, 'heritage_cultural');
    expect(pageTwo.isFree, true);
    expect(pageTwo.page, 2);
  });

  test('counts active filters without pagination', () {
    const filter = DestinationFilter(
      query: 'falls',
      lguCode: 'adams',
      categoryCode: 'natural_attraction',
      isFree: true,
      page: 3,
    );

    expect(filter.hasActiveFilters, isTrue);
    expect(filter.activeFilterCount, 4);
  });

  test('empty query does not count as an active filter', () {
    const filter = DestinationFilter(query: '   ');

    expect(filter.hasActiveFilters, isFalse);
    expect(filter.activeFilterCount, 0);
    expect(filter.toQueryParameters(), {'page': 1, 'limit': 20});
  });

  test('equality includes page and filter values', () {
    const base = DestinationFilter(lguCode: 'paoay');
    const same = DestinationFilter(lguCode: 'paoay');
    const nextPage = DestinationFilter(lguCode: 'paoay', page: 2);

    expect(base, same);
    expect(base.hashCode, same.hashCode);
    expect(base == nextPage, isFalse);
  });
}
