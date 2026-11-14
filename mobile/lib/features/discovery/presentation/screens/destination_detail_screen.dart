import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/destination_summary.dart';
import '../widgets/destination_artwork.dart';

class DestinationDetailScreen extends StatelessWidget {
  const DestinationDetailScreen({
    super.key,
    required this.slug,
    this.destination,
  });

  final String slug;
  final DestinationSummary? destination;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final place = destination;

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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                children: [
                  Row(
                    children: [
                      _CircleButton(
                        icon: CupertinoIcons.chevron_left,
                        tooltip: 'Back to discovery',
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go(AppRoutes.discovery);
                          }
                        },
                      ),
                      const Spacer(),
                      Text(
                        'DESTINATION',
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.terracotta,
                          fontSize: 9,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (place == null) ...[
                    AppCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Destination details',
                            style: textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This stop is saved as "$slug". Its full verified '
                            'profile opens in the next discovery phase.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.mutedForest,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 18),
                          FilledButton(
                            onPressed: () => context.go(AppRoutes.discovery),
                            child: const Text('Back to discovery'),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      height: 250,
                      child: DestinationArtwork(
                        categoryCode: place.categoryCode,
                        borderRadius: 24,
                        iconSize: 64,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _MetaPill(
                          icon: CupertinoIcons.checkmark_shield,
                          label: place.verificationStatus.toUpperCase(),
                        ),
                        const SizedBox(width: 7),
                        _MetaPill(
                          icon: CupertinoIcons.compass,
                          label: place.clusterLabel.toUpperCase(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(place.name, style: textTheme.displaySmall),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          CupertinoIcons.location,
                          size: 15,
                          color: AppColors.mutedForest,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            '${place.lguName} · ${place.categoryName}',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.mutedForest,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    AppCard(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Expanded(
                            child: _DetailStat(
                              label: 'ENTRY',
                              value: place.priceLabel,
                            ),
                          ),
                          Container(
                            width: 0.5,
                            height: 36,
                            color: AppColors.hairline,
                          ),
                          Expanded(
                            child: _DetailStat(
                              label: 'ACCESS',
                              value: place.highwayAccessible
                                  ? 'Highway'
                                  : 'Local road',
                            ),
                          ),
                          Container(
                            width: 0.5,
                            height: 36,
                            color: AppColors.hairline,
                          ),
                          Expanded(
                            child: _DetailStat(
                              label: 'CLUSTER',
                              value: place.clusterLabel,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('About this place', style: textTheme.headlineSmall),
                    const SizedBox(height: 10),
                    Text(
                      place.description,
                      style: textTheme.bodyLarge?.copyWith(
                        color: AppColors.mutedForest,
                        height: 1.62,
                      ),
                    ),
                    if (place.tags.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: [
                          for (final tag in place.tags)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: const ShapeDecoration(
                                color: AppColors.skyBlueWash,
                                shape: StadiumBorder(),
                              ),
                              child: Text(
                                tag.name,
                                style: textTheme.labelSmall?.copyWith(
                                  color: AppColors.deepForest,
                                  fontSize: 9,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    AppCard(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            CupertinoIcons.clock,
                            size: 18,
                            color: AppColors.terracotta,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Verified operating hours, a map, and route '
                              'actions arrive in the next destination phase.',
                              style: textTheme.bodySmall?.copyWith(height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.ivorySand,
        shape: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(15)),
          side: BorderSide(color: AppColors.hairline, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: const SizedBox(
            width: 42,
            height: 42,
            child: Icon(CupertinoIcons.chevron_left, size: 18),
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: const ShapeDecoration(
        color: AppColors.skyBlueWash,
        shape: StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.deepForest),
          const SizedBox(width: 5),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              fontSize: 9,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  const _DetailStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: AppColors.mutedForest,
            fontSize: 8,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.labelMedium?.copyWith(
            fontFeatures: AppTypography.tabularFigures,
          ),
        ),
      ],
    );
  }
}
