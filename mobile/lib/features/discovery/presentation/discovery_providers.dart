import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../data/destination_repository.dart';
import '../domain/destination_detail.dart';
import '../domain/destination_filter.dart';
import '../domain/destination_summary.dart';
import '../domain/lgu.dart';
import '../domain/taxonomy.dart';

final destinationRepositoryProvider = Provider<DestinationRepository>((ref) {
  return DestinationRepository(ref.watch(dioProvider));
});

final lgusProvider = FutureProvider<LguDirectory>((ref) {
  return ref.watch(destinationRepositoryProvider).fetchLgus();
});

final taxonomyProvider = FutureProvider<DestinationTaxonomy>((ref) {
  return ref.watch(destinationRepositoryProvider).fetchTaxonomy();
});

final destinationDetailProvider =
    FutureProvider.family<DestinationDetail, String>((ref, slug) {
  return ref.watch(destinationRepositoryProvider).fetchDestinationDetail(slug);
});

class ExploreFeed {
  const ExploreFeed({
    required this.iconicHighlights,
    required this.hiddenGems,
    required this.culinaryStops,
    required this.lguDirectory,
  });

  final List<DestinationSummary> iconicHighlights;
  final List<DestinationSummary> hiddenGems;
  final List<DestinationSummary> culinaryStops;
  final LguDirectory lguDirectory;
}

final exploreFeedProvider = FutureProvider<ExploreFeed>((ref) async {
  final repository = ref.watch(destinationRepositoryProvider);
  final directoryFuture = ref.watch(lgusProvider.future);

  final responses = await Future.wait([
    repository.fetchDestinations(
      const DestinationFilter(popularityTier: 'iconic_hub', limit: 100),
    ),
    repository.fetchDestinations(
      const DestinationFilter(popularityTier: 'hidden_gem', limit: 100),
    ),
    repository.fetchDestinations(
      const DestinationFilter(categoryCode: 'food_culinary', limit: 100),
    ),
  ]);

  final directory = await directoryFuture;

  return ExploreFeed(
    iconicHighlights: responses[0].items,
    hiddenGems: responses[1].items,
    culinaryStops: responses[2].items,
    lguDirectory: directory,
  );
});

final searchFilterProvider =
    NotifierProvider<SearchFilterNotifier, DestinationFilter>(
      SearchFilterNotifier.new,
    );

class SearchFilterNotifier extends Notifier<DestinationFilter> {
  Timer? _queryDebounce;

  @override
  DestinationFilter build() {
    ref.onDispose(() => _queryDebounce?.cancel());
    return const DestinationFilter();
  }

  void setQuery(String value) {
    _queryDebounce?.cancel();
    final query = value.trim();

    if (query.isEmpty) {
      state = state.copyWith(query: '', page: 1);
      return;
    }

    _queryDebounce = Timer(const Duration(milliseconds: 300), () {
      state = state.copyWith(query: query, page: 1);
    });
  }

  void clearQuery() {
    _queryDebounce?.cancel();
    state = state.copyWith(query: '', page: 1);
  }

  void setPopularityTier(String? tier) {
    state = state.copyWith(popularityTier: tier, page: 1);
  }

  void toggleHiddenGems() {
    setPopularityTier(
      state.popularityTier == 'hidden_gem' ? null : 'hidden_gem',
    );
  }

  void toggleFreeEntry() {
    state = state.copyWith(isFree: state.isFree == true ? null : true, page: 1);
  }

  void setCategoryCode(String? code) {
    state = state.copyWith(categoryCode: code, page: 1);
  }

  void setLguCode(String? code) {
    state = state.copyWith(lguCode: code, page: 1);
  }

  void setCluster(String? code) {
    state = state.copyWith(cluster: code, page: 1);
  }

  void reset() {
    _queryDebounce?.cancel();
    state = const DestinationFilter();
  }
}

final filteredDestinationsProvider =
    AsyncNotifierProvider<FilteredDestinationsNotifier, DestinationPage>(
      FilteredDestinationsNotifier.new,
    );

class FilteredDestinationsNotifier extends AsyncNotifier<DestinationPage> {
  @override
  Future<DestinationPage> build() {
    final filter = ref.watch(searchFilterProvider);
    return ref.watch(destinationRepositoryProvider).fetchDestinations(filter);
  }

  Future<void> loadMore() async {
    final current = state.value;

    if (current == null || !current.hasNextPage) {
      return;
    }

    final filter = ref.read(searchFilterProvider);
    final nextPage = await ref
        .read(destinationRepositoryProvider)
        .fetchDestinations(filter.copyWith(page: current.page + 1));

    state = AsyncData(
      current.copyWith(
        items: [...current.items, ...nextPage.items],
        total: nextPage.total,
        page: nextPage.page,
        limit: nextPage.limit,
        totalPages: nextPage.totalPages,
      ),
    );
  }
}
