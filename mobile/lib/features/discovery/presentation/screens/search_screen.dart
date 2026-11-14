import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../domain/destination_summary.dart';
import '../../domain/lgu.dart';
import '../../domain/taxonomy.dart';
import '../discovery_providers.dart';
import '../widgets/destination_artwork.dart';
import '../widgets/destination_compact_tile.dart';
import '../widgets/lgu_cluster_sheet.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _searchController;
  final ScrollController _scrollController = ScrollController();
  bool _hasText = false;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    final query = ref.read(searchFilterProvider).query;
    _searchController = TextEditingController(text: query);
    _hasText = query.isNotEmpty;
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 360) {
      unawaited(_loadMore());
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore) {
      return;
    }

    final page = ref.read(filteredDestinationsProvider).value;
    if (page == null || !page.hasNextPage) {
      return;
    }

    setState(() => _loadingMore = true);

    try {
      await ref.read(filteredDestinationsProvider.notifier).loadMore();
    } on Exception catch (error) {
      if (mounted) {
        _showMessage(_errorMessage(error));
      }
    } finally {
      if (mounted) {
        setState(() => _loadingMore = false);
      }
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(filteredDestinationsProvider);

    try {
      await ref.read(filteredDestinationsProvider.future);
    } on Exception {
      // The inline result state reports the failure.
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _clearQuery() {
    _searchController.clear();
    setState(() => _hasText = false);
    ref.read(searchFilterProvider.notifier).clearQuery();
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() => _hasText = false);
    ref.read(searchFilterProvider.notifier).reset();
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();
  }

  Future<void> _openCategoryPicker(
    DestinationTaxonomy taxonomy,
    String? selectedCode,
  ) async {
    FocusScope.of(context).unfocus();

    final selected = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return _CategoryPickerSheet(
          taxonomy: taxonomy,
          selectedCode: selectedCode,
        );
      },
    );

    if (selected == null || !mounted) {
      return;
    }

    ref
        .read(searchFilterProvider.notifier)
        .setCategoryCode(selected.isEmpty ? null : selected);
    HapticFeedback.lightImpact();
  }

  void _openLguPicker(LguDirectory directory) {
    FocusScope.of(context).unfocus();

    showLguClusterSheet(
      context: context,
      directory: directory,
      onSelected: (lgu) {
        ref.read(searchFilterProvider.notifier).setLguCode(lgu.lguCode);
        HapticFeedback.lightImpact();
      },
    );
  }

  void _openDestination(DestinationSummary destination) {
    HapticFeedback.lightImpact();
    context.push(
      '${AppRoutes.destinationDetail}/${destination.slug}',
      extra: destination,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(searchFilterProvider);
    final directory = ref.watch(lgusProvider).value;
    final taxonomy = ref.watch(taxonomyProvider).value;
    final results = ref.watch(filteredDestinationsProvider);
    final selectedLgu = directory?.lguByCode(filter.lguCode);
    final selectedCategory = taxonomy?.categoryByCode(filter.categoryCode);

    ref.listen(searchFilterProvider, (previous, next) {
      if (previous != next && _scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.warmSand, Color(0xFFF0DFC9)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SEARCH THE CATALOG',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.terracotta,
                                fontSize: 9,
                                letterSpacing: 1.1,
                              ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          'Find the right place.',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          directory == null
                              ? 'Verified places across every circuit.'
                              : 'Search ${directory.totalLgus} LGUs, '
                                    '${taxonomy?.categories.length ?? 6} '
                                    'categories, and local flavor.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(height: 1.45),
                        ),
                        const SizedBox(height: 18),
                        _SearchField(
                          controller: _searchController,
                          hasText: _hasText,
                          onChanged: (value) {
                            ref
                                .read(searchFilterProvider.notifier)
                                .setQuery(value);
                            final hasText = value.isNotEmpty;
                            if (hasText != _hasText) {
                              setState(() => _hasText = hasText);
                            }
                          },
                          onClear: _clearQuery,
                          onSubmitted: (_) => FocusScope.of(context).unfocus(),
                        ),
                        const SizedBox(height: 14),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              _FilterPill(
                                icon: CupertinoIcons.sparkles,
                                label: 'Hidden gems',
                                selected: filter.popularityTier == 'hidden_gem',
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  ref
                                      .read(searchFilterProvider.notifier)
                                      .toggleHiddenGems();
                                },
                              ),
                              const SizedBox(width: 8),
                              _FilterPill(
                                icon: CupertinoIcons.ticket,
                                label: 'Free entry',
                                selected: filter.isFree == true,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  ref
                                      .read(searchFilterProvider.notifier)
                                      .toggleFreeEntry();
                                },
                              ),
                              const SizedBox(width: 8),
                              _FilterPill(
                                icon: CupertinoIcons.square_grid_2x2,
                                label: selectedCategory?.name ?? 'Category',
                                selected: filter.categoryCode != null,
                                onTap: taxonomy == null
                                    ? () => _showMessage(
                                        'Categories are still loading.',
                                      )
                                    : () => _openCategoryPicker(
                                        taxonomy,
                                        filter.categoryCode,
                                      ),
                              ),
                              const SizedBox(width: 8),
                              _FilterPill(
                                icon: CupertinoIcons.location,
                                label: selectedLgu?.name ?? 'LGU',
                                selected: filter.lguCode != null,
                                onTap: directory == null
                                    ? () => _showMessage(
                                        'The LGU directory is still loading.',
                                      )
                                    : () => _openLguPicker(directory),
                              ),
                              if (filter.activeFilterCount > 0) ...[
                                const SizedBox(width: 8),
                                _FilterPill(
                                  icon: CupertinoIcons.xmark,
                                  label: 'Reset',
                                  selected: false,
                                  onTap: _resetFilters,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                results.value == null
                                    ? 'Searching verified places…'
                                    : '${results.value!.total} verified '
                                          '${results.value!.total == 1 ? 'place' : 'places'}',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: AppColors.mutedForest,
                                      fontFeatures:
                                          AppTypography.tabularFigures,
                                    ),
                              ),
                            ),
                            if (filter.activeFilterCount > 0)
                              Text(
                                '${filter.activeFilterCount} active '
                                '${filter.activeFilterCount == 1 ? 'filter' : 'filters'}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(fontSize: 10),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: results.when(
                      loading: () => const _SearchLoading(),
                      error: (error, stackTrace) => _SearchError(
                        message: _errorMessage(error),
                        onRetry: () =>
                            ref.invalidate(filteredDestinationsProvider),
                      ),
                      data: (page) => _ResultList(
                        page: page,
                        scrollController: _scrollController,
                        loadingMore: _loadingMore,
                        emptyTitle: filter.hasActiveFilters
                            ? 'No places match this trail.'
                            : 'No places are available yet.',
                        emptyMessage: filter.hasActiveFilters
                            ? 'Try a broader search or clear a filter to see '
                                  'more of the north.'
                            : 'Refresh once the destination catalog is '
                                  'available.',
                        onReset: filter.hasActiveFilters ? _resetFilters : null,
                        onRefresh: _refresh,
                        onLoadMore: _loadMore,
                        onDestinationTap: _openDestination,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hasText,
    required this.onChanged,
    required this.onClear,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool hasText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      autocorrect: false,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: 'Beaches, heritage, empanada, Pagudpud…',
        prefixIcon: const Icon(
          CupertinoIcons.search,
          size: 19,
          color: AppColors.mutedForest,
        ),
        suffixIcon: hasText
            ? IconButton(
                tooltip: 'Clear search',
                onPressed: onClear,
                icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 18),
              )
            : null,
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: selected ? AppColors.deepForest : AppColors.ivorySand,
      shape: ContinuousRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(999)),
        side: BorderSide(
          color: selected ? AppColors.deepForest : AppColors.hairline,
          width: 0.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(999)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: selected ? AppColors.ivorySand : AppColors.deepForest,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  color: selected ? AppColors.ivorySand : AppColors.deepForest,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultList extends StatelessWidget {
  const _ResultList({
    required this.page,
    required this.scrollController,
    required this.loadingMore,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.onReset,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onDestinationTap,
  });

  final DestinationPage page;
  final ScrollController scrollController;
  final bool loadingMore;
  final String emptyTitle;
  final String emptyMessage;
  final VoidCallback? onReset;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoadMore;
  final ValueChanged<DestinationSummary> onDestinationTap;

  @override
  Widget build(BuildContext context) {
    if (page.items.isEmpty) {
      return RefreshIndicator(
        color: AppColors.terracotta,
        backgroundColor: AppColors.ivorySand,
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 36, 20, 120),
          children: [
            _EmptyState(
              title: emptyTitle,
              message: emptyMessage,
              onReset: onReset,
            ),
          ],
        ),
      );
    }

    final footerCount = page.hasNextPage ? 1 : 0;

    return RefreshIndicator(
      color: AppColors.terracotta,
      backgroundColor: AppColors.ivorySand,
      onRefresh: onRefresh,
      child: ListView.separated(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
        itemCount: page.items.length + footerCount,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index >= page.items.length) {
            return _LoadMoreFooter(
              loading: loadingMore,
              onTap: () {
                HapticFeedback.lightImpact();
                onLoadMore();
              },
            );
          }

          final destination = page.items[index];

          return DestinationCompactTile(
            destination: destination,
            onTap: () => onDestinationTap(destination),
          );
        },
      ),
    );
  }
}

class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter({required this.loading, required this.onTap});

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              )
            : TextButton.icon(
                onPressed: onTap,
                icon: const Icon(CupertinoIcons.chevron_down, size: 14),
                label: const Text('Load more places'),
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.message, this.onReset});

  final String title;
  final String message;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(26),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const ShapeDecoration(
              color: AppColors.skyBlueWash,
              shape: ContinuousRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
            ),
            child: const Icon(
              CupertinoIcons.search,
              size: 26,
              color: AppColors.deepForest,
            ),
          ),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: textTheme.titleLarge),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(height: 1.5),
          ),
          if (onReset != null) ...[
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onReset,
              child: const Text('Clear filters'),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchLoading extends StatelessWidget {
  const _SearchLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 120),
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) =>
          const LoadingSkeleton(height: 124, borderRadius: 24),
    );
  }
}

class _SearchError extends StatelessWidget {
  const _SearchError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
      children: [
        AppCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_circle,
                size: 28,
                color: AppColors.terracotta,
              ),
              const SizedBox(height: 14),
              Text('Search is out of reach.', style: textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(message, style: textTheme.bodySmall?.copyWith(height: 1.5)),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(CupertinoIcons.arrow_clockwise, size: 16),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryPickerSheet extends StatelessWidget {
  const _CategoryPickerSheet({
    required this.taxonomy,
    required this.selectedCode,
  });

  final DestinationTaxonomy taxonomy;
  final String? selectedCode;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.72,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 6, 22, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Filter by category', style: textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  'Choose the kind of place you want to find.',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 22),
              children: [
                _CategoryOption(
                  label: 'All categories',
                  description: 'Show every verified kind of place.',
                  icon: CupertinoIcons.compass,
                  selected: selectedCode == null,
                  onTap: () => Navigator.of(context).pop(''),
                ),
                for (final category in taxonomy.categories)
                  _CategoryOption(
                    label: category.name,
                    description: category.description,
                    categoryCode: category.categoryCode,
                    selected: selectedCode == category.categoryCode,
                    onTap: () =>
                        Navigator.of(context).pop(category.categoryCode),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryOption extends StatelessWidget {
  const _CategoryOption({
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
    this.categoryCode,
    this.icon,
  });

  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;
  final String? categoryCode;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style = destinationStyleFor(categoryCode ?? '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        color: selected ? AppColors.warmSand : AppColors.ivorySand,
        borderColor: selected ? AppColors.terracotta : AppColors.hairline,
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: ShapeDecoration(
                gradient: style.gradient,
                shape: const ContinuousRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
              ),
              child: Icon(
                icon ?? style.icon,
                size: 19,
                color: AppColors.ivorySand,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      color: selected
                          ? AppColors.deepForest
                          : AppColors.deepForest,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 10.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              selected
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.circle,
              size: 19,
              color: selected ? AppColors.terracotta : AppColors.hairline,
            ),
          ],
        ),
      ),
    );
  }
}

String _errorMessage(Object error) {
  if (error is ApiException) {
    return error.message;
  }

  return 'Check your connection and try searching again.';
}
