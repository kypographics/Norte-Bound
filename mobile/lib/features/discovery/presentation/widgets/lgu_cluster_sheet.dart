import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/lgu.dart';

Future<void> showLguClusterSheet({
  required BuildContext context,
  required LguDirectory directory,
  required ValueChanged<Lgu> onSelected,
  String? initialCluster,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.deepForest.withValues(alpha: 0.42),
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.82,
        minChildSize: 0.55,
        maxChildSize: 0.94,
        builder: (context, scrollController) {
          return LguClusterSheet(
            directory: directory,
            initialCluster: initialCluster,
            onSelected: (lgu) {
              Navigator.of(sheetContext).pop();
              onSelected(lgu);
            },
          );
        },
      );
    },
  );
}

class LguClusterSheet extends StatelessWidget {
  const LguClusterSheet({
    super.key,
    required this.directory,
    required this.onSelected,
    this.initialCluster,
  });

  final LguDirectory directory;
  final ValueChanged<Lgu> onSelected;
  final String? initialCluster;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final clusters = directory.orderedClusters;
    final initialIndex = _initialIndex(clusters, initialCluster);

    return DecoratedBox(
      decoration: const ShapeDecoration(
        color: AppColors.ivorySand,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          side: BorderSide(color: AppColors.hairline, width: 0.5),
        ),
      ),
      child: DefaultTabController(
        length: clusters.isEmpty ? 1 : clusters.length,
        initialIndex: initialIndex,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: const ShapeDecoration(
                color: AppColors.hairline,
                shape: StadiumBorder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 14, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const ShapeDecoration(
                      color: AppColors.skyBlueWash,
                      shape: ContinuousRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    ),
                    child: const Icon(
                      CupertinoIcons.map,
                      color: AppColors.deepForest,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Browse by LGU', style: textTheme.headlineSmall),
                        const SizedBox(height: 4),
                        Text(
                          '${directory.totalLgus} municipalities and cities '
                          'across ${clusters.length} tourism circuits.',
                          style: textTheme.bodySmall?.copyWith(height: 1.45),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close LGU browser',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(CupertinoIcons.xmark, size: 18),
                  ),
                ],
              ),
            ),
            if (clusters.isEmpty)
              const Expanded(child: _EmptyClusterState())
            else ...[
              Align(
                alignment: Alignment.centerLeft,
                child: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  dividerColor: Colors.transparent,
                  indicatorColor: AppColors.terracotta,
                  indicatorWeight: 2.5,
                  labelColor: AppColors.deepForest,
                  unselectedLabelColor: AppColors.mutedForest,
                  labelStyle: textTheme.labelLarge,
                  unselectedLabelStyle: textTheme.labelMedium,
                  tabs: [
                    for (final cluster in clusters)
                      Tab(
                        height: 42,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(cluster.label),
                            const SizedBox(width: 6),
                            Text(
                              '${cluster.total}',
                              style: textTheme.labelSmall?.copyWith(
                                color: AppColors.mutedForest,
                                fontFeatures: AppTypography.tabularFigures,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: TabBarView(
                  children: [
                    for (final cluster in clusters)
                      ListView.separated(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                        itemCount: cluster.lgus.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 9),
                        itemBuilder: (context, index) {
                          final lgu = cluster.lgus[index];

                          return _LguTile(
                            lgu: lgu,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              onSelected(lgu);
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  int _initialIndex(List<LguCluster> clusters, String? code) {
    if (code == null) {
      return 0;
    }

    final index = clusters.indexWhere((cluster) => cluster.cluster == code);
    return index < 0 ? 0 : index;
  }
}

class _LguTile extends StatelessWidget {
  const _LguTile({required this.lgu, required this.onTap});

  final Lgu lgu;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: const ShapeDecoration(
              color: AppColors.warmSand,
              shape: ContinuousRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
            ),
            child: Text(
              lgu.name.characters.first.toUpperCase(),
              style: textTheme.titleMedium,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        lgu.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall,
                      ),
                    ),
                    if (lgu.isMajorHub) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: const ShapeDecoration(
                          color: AppColors.terracottaWash,
                          shape: StadiumBorder(),
                        ),
                        child: Text(
                          'HUB',
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.terracotta,
                            fontSize: 8,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${lgu.typeLabel} · ${lgu.clusterLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            CupertinoIcons.chevron_right,
            size: 14,
            color: AppColors.mutedForest,
          ),
        ],
      ),
    );
  }
}

class _EmptyClusterState extends StatelessWidget {
  const _EmptyClusterState();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.location_slash,
              size: 34,
              color: AppColors.mutedForest,
            ),
            const SizedBox(height: 12),
            Text('No LGUs available.', style: textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Refresh discovery once the destination directory is available.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
