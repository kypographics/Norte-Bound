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
import '../../../auth/presentation/auth_providers.dart';
import '../../domain/destination_summary.dart';
import '../../domain/lgu.dart';
import '../discovery_providers.dart';
import '../widgets/destination_compact_tile.dart';
import '../widgets/destination_hero_card.dart';
import '../widgets/lgu_cluster_sheet.dart';

class DiscoveryScreen extends ConsumerWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(exploreFeedProvider);
    final user = ref.watch(authNotifierProvider).value;
    final firstName = _firstName(user?.fullName);

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
              child: RefreshIndicator(
                color: AppColors.terracotta,
                backgroundColor: AppColors.ivorySand,
                onRefresh: () => _refresh(ref),
                child: ListView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                  children: [
                    _DiscoveryHeader(
                      firstName: firstName,
                      onAvatarTap: () => context.go(AppRoutes.profile),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      'Find your\nnorth.',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Verified places, quiet detours, and local flavor across '
                      'Ilocos Norte.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.mutedForest,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _SearchTrigger(onTap: () => context.go(AppRoutes.search)),
                    const SizedBox(height: 28),
                    ...feed.when(
                      loading: () => const [_DiscoveryLoading()],
                      error: (error, stackTrace) => [
                        _DiscoveryError(
                          message: _errorMessage(error),
                          onRetry: () {
                            ref.invalidate(lgusProvider);
                            ref.invalidate(exploreFeedProvider);
                          },
                        ),
                      ],
                      data: (feed) => _feedSections(context, ref, feed),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _feedSections(
    BuildContext context,
    WidgetRef ref,
    ExploreFeed feed,
  ) {
    final directory = feed.lguDirectory;
    final clusters = directory.orderedClusters;

    return [
      const _FestivalsAndAdvisoriesStrip(),
      const SizedBox(height: 24),
      _SectionHeader(
        eyebrow: 'TOURISM CIRCUITS',
        title: 'Explore by circuit',
        actionLabel: 'All LGUs',
        onAction: () => _openLguBrowser(context, ref, directory),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 76,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: clusters.length,
          separatorBuilder: (context, index) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final cluster = clusters[index];

            return _CircuitCard(
              cluster: cluster,
              onTap: () => _openLguBrowser(
                context,
                ref,
                directory,
                initialCluster: cluster.cluster,
              ),
            );
          },
        ),
      ),
      if (feed.hiddenGems.isNotEmpty) ...[
        const SizedBox(height: 32),
        _SectionHeader(
          eyebrow: 'QUIET CORNERS',
          title: 'Hidden gems',
          actionLabel: 'See all',
          onAction: () {
            ref.read(searchFilterProvider.notifier).reset();
            ref.read(searchFilterProvider.notifier).toggleHiddenGems();
            context.go(AppRoutes.search);
          },
        ),
        const SizedBox(height: 6),
        Text(
          'Less-traveled places worth the detour.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 248,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: feed.hiddenGems.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final destination = feed.hiddenGems[index];

              return DestinationHeroCard(
                destination: destination,
                onTap: () => _openDestination(context, destination),
              );
            },
          ),
        ),
      ],
      if (feed.iconicHighlights.isNotEmpty) ...[
        const SizedBox(height: 32),
        _SectionHeader(
          eyebrow: 'SIGNATURE STOPS',
          title: 'Iconic landmarks',
          actionLabel: 'See all',
          onAction: () {
            ref.read(searchFilterProvider.notifier).reset();
            ref
                .read(searchFilterProvider.notifier)
                .setPopularityTier('iconic_hub');
            context.go(AppRoutes.search);
          },
        ),
        const SizedBox(height: 6),
        Text(
          'The places that define a first trip north.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 248,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: feed.iconicHighlights.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final destination = feed.iconicHighlights[index];

              return DestinationHeroCard(
                destination: destination,
                onTap: () => _openDestination(context, destination),
              );
            },
          ),
        ),
      ],
      const SizedBox(height: 32),
      _LguDirectoryCard(
        directory: directory,
        onBrowse: () => _openLguBrowser(context, ref, directory),
      ),
      if (feed.culinaryStops.isNotEmpty) ...[
        const SizedBox(height: 32),
        _SectionHeader(
          eyebrow: 'LOCAL FLAVOR',
          title: 'Taste the north',
          actionLabel: 'See all',
          onAction: () {
            ref.read(searchFilterProvider.notifier).reset();
            ref
                .read(searchFilterProvider.notifier)
                .setCategoryCode('food_culinary');
            context.go(AppRoutes.search);
          },
        ),
        const SizedBox(height: 6),
        Text(
          'Empanada, bagnet, miki, and the stops locals return to.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 126,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: feed.culinaryStops.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final destination = feed.culinaryStops[index];

              return DestinationCompactTile(
                destination: destination,
                width: 312,
                onTap: () => _openDestination(context, destination),
              );
            },
          ),
        ),
      ],
      const SizedBox(height: 28),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            CupertinoIcons.checkmark_shield,
            size: 16,
            color: AppColors.mutedForest,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Every place, fee, and operating detail is grounded in verified '
              'local records.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w500, height: 1.45),
            ),
          ),
        ],
      ),
    ];
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(lgusProvider);
    ref.invalidate(taxonomyProvider);
    ref.invalidate(exploreFeedProvider);

    try {
      await ref.read(exploreFeedProvider.future);
    } on Exception {
      // The inline error state reports the failure.
    }
  }

  void _openLguBrowser(
    BuildContext context,
    WidgetRef ref,
    LguDirectory directory, {
    String? initialCluster,
  }) {
    showLguClusterSheet(
      context: context,
      directory: directory,
      initialCluster: initialCluster,
      onSelected: (lgu) {
        final filters = ref.read(searchFilterProvider.notifier);
        filters.reset();
        filters.setLguCode(lgu.lguCode);
        HapticFeedback.lightImpact();
        context.go(AppRoutes.search);
      },
    );
  }

  void _openDestination(BuildContext context, DestinationSummary destination) {
    context.push(
      '${AppRoutes.destinationDetail}/${destination.slug}',
      extra: destination,
    );
  }
}

class _DiscoveryHeader extends StatelessWidget {
  const _DiscoveryHeader({required this.firstName, required this.onAvatarTap});

  final String firstName;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: const ShapeDecoration(
            color: AppColors.deepForest,
            shape: ContinuousRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
          child: const Icon(
            CupertinoIcons.compass,
            color: AppColors.ivorySand,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NORTE BOUND',
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'ILOCOS NORTE · VERIFIED DISCOVERY',
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.mutedForest,
                  fontSize: 9,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Tooltip(
          message: 'Open profile',
          child: GestureDetector(
            onTap: onAvatarTap,
            child: Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: const ShapeDecoration(
                color: AppColors.ivorySand,
                shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                  side: BorderSide(color: AppColors.hairline, width: 0.5),
                ),
              ),
              child: Text(
                firstName.characters.first.toUpperCase(),
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.terracotta,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchTrigger extends StatelessWidget {
  const _SearchTrigger({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            const Icon(
              CupertinoIcons.search,
              size: 18,
              color: AppColors.mutedForest,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Search places, food, heritage…',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedForest,
                ),
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: const ShapeDecoration(
                color: AppColors.terracottaWash,
                shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              child: const Icon(
                CupertinoIcons.slider_horizontal_3,
                size: 16,
                color: AppColors.terracotta,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String eyebrow;
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.terracotta,
                  fontSize: 9,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 5),
              Text(title, style: textTheme.headlineSmall),
            ],
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(0, 34),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(actionLabel, style: textTheme.labelMedium),
        ),
      ],
    );
  }
}

class _CircuitCard extends StatelessWidget {
  const _CircuitCard({required this.cluster, required this.onTap});

  final LguCluster cluster;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final icon = switch (cluster.cluster) {
      TourismClusterInfo.northernCoast => CupertinoIcons.sun_max,
      TourismClusterInfo.centralUrbanHeritage => CupertinoIcons.building_2_fill,
      TourismClusterInfo.southernHeritageCoast => CupertinoIcons.compass,
      _ => CupertinoIcons.tree,
    };

    return SizedBox(
      width: 170,
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const ShapeDecoration(
                color: AppColors.skyBlueWash,
                shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(13)),
                ),
              ),
              child: Icon(icon, size: 18, color: AppColors.deepForest),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    cluster.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${cluster.total} LGUs',
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      fontFeatures: AppTypography.tabularFigures,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LguDirectoryCard extends StatelessWidget {
  const _LguDirectoryCard({required this.directory, required this.onBrowse});

  final LguDirectory directory;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cityCount = directory.lgus.where((lgu) => lgu.isCity).length;
    final municipalityCount = directory.totalLgus - cityCount;

    return AppCard(
      color: AppColors.deepForest,
      borderColor: AppColors.deepForest,
      padding: const EdgeInsets.all(20),
      onTap: onBrowse,
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -34,
            child: Icon(
              CupertinoIcons.map,
              size: 150,
              color: AppColors.ivorySand.withValues(alpha: 0.06),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: const ShapeDecoration(
                  color: AppColors.skyBlueWash,
                  shape: StadiumBorder(),
                ),
                child: Text(
                  'THE WHOLE PROVINCE',
                  style: textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${directory.totalLgus} LGUs.\nOne northern coast.',
                style: textTheme.headlineMedium?.copyWith(
                  color: AppColors.ivorySand,
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$municipalityCount municipalities and $cityCount cities, '
                'grouped into ${directory.clusters.length} tourism circuits.',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.warmSand.withValues(alpha: 0.72),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  for (final cluster in directory.orderedClusters) ...[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${cluster.total}',
                            style: textTheme.titleLarge?.copyWith(
                              color: AppColors.ivorySand,
                              fontFeatures: AppTypography.tabularFigures,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cluster.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.warmSand.withValues(alpha: 0.58),
                              fontSize: 8,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    'Browse the directory',
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.terracotta,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    CupertinoIcons.arrow_right,
                    size: 13,
                    color: AppColors.terracotta,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DiscoveryLoading extends StatelessWidget {
  const _DiscoveryLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LoadingSkeleton(width: 120, height: 12),
        const SizedBox(height: 12),
        SizedBox(
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) =>
                const LoadingSkeleton(width: 170, height: 76, borderRadius: 24),
          ),
        ),
        const SizedBox(height: 32),
        const LoadingSkeleton(width: 150, height: 24),
        const SizedBox(height: 14),
        SizedBox(
          height: 248,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 2,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) => const LoadingSkeleton(
              width: 292,
              height: 248,
              borderRadius: 24,
            ),
          ),
        ),
        const SizedBox(height: 32),
        const LoadingSkeleton(width: 150, height: 24),
        const SizedBox(height: 14),
        SizedBox(
          height: 248,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 2,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) => const LoadingSkeleton(
              width: 292,
              height: 248,
              borderRadius: 24,
            ),
          ),
        ),
      ],
    );
  }
}

class _DiscoveryError extends StatelessWidget {
  const _DiscoveryError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const ShapeDecoration(
              color: AppColors.terracottaWash,
              shape: ContinuousRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
            child: const Icon(
              CupertinoIcons.exclamationmark_circle,
              size: 22,
              color: AppColors.terracotta,
            ),
          ),
          const SizedBox(height: 16),
          Text('Discovery is out of reach.', style: textTheme.titleLarge),
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
    );
  }
}

String _firstName(String? fullName) {
  final trimmed = fullName?.trim() ?? '';
  if (trimmed.isEmpty) {
    return 'Traveler';
  }

  return trimmed.split(RegExp(r'\s+')).first;
}

String _errorMessage(Object error) {
  if (error is ApiException) {
    return error.message;
  }

  return 'Check your connection and try loading the destination directory '
      'again.';
}

class _FestivalsAndAdvisoriesStrip extends StatelessWidget {
  const _FestivalsAndAdvisoriesStrip();

  static const _events = [
    (
      'FEBRUARY · LAOAG',
      'Pamulinawen Festival',
      'City fiestas, cultural street parades & local craft fairs.',
      false,
    ),
    (
      'FEBRUARY · PROVINCE-WIDE',
      'Tan-ok ni Ilocano',
      'Festival of festivals gathering all 22 LGUs.',
      false,
    ),
    (
      'MARCH · PAOAY & PINILI',
      'Abel / Inabel Fair',
      'Handloom weaving markets and artisan showcases.',
      false,
    ),
    (
      'SEPTEMBER · PIDDIG',
      'Basi Festival',
      'Sugarcane wine harvest & highland heritage week.',
      false,
    ),
    (
      'DECEMBER · BATAC',
      'Empanada Festival',
      'Riverside culinary showcase & heritage walk.',
      false,
    ),
    (
      'TRAVEL ADVISORY',
      'Coast & Highland Check',
      'Watch Pagudpud winds and afternoon upland showers.',
      true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FESTIVALS & ADVISORIES',
          style: textTheme.labelSmall?.copyWith(
            color: AppColors.terracotta,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Seasonal highlights across Ilocos Norte',
          style: textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 102,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _events.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final (eyebrow, title, subtitle, isAdvisory) = _events[index];
              return SizedBox(
                width: 236,
                child: AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  color: isAdvisory
                      ? AppColors.terracottaWash
                      : AppColors.ivorySand,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eyebrow,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(
                          color: isAdvisory
                              ? AppColors.terracotta
                              : AppColors.mutedForest,
                          fontSize: 8.5,
                          letterSpacing: 0.7,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.mutedForest,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
