import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/destination_summary.dart';
import 'destination_artwork.dart';

class DestinationHeroCard extends StatelessWidget {
  const DestinationHeroCard({
    super.key,
    required this.destination,
    this.onTap,
    this.width = 292,
  });

  final DestinationSummary destination;
  final VoidCallback? onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final shape = const ContinuousRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(24)),
      side: BorderSide(color: AppColors.hairline, width: 0.5),
    );

    return SizedBox(
      width: width,
      height: 248,
      child: Material(
        color: AppColors.deepForest,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onTap!();
                },
          customBorder: shape,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DestinationArtwork(
                categoryCode: destination.categoryCode,
                borderRadius: 24,
                iconSize: 56,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.16, 0.58, 1],
                    colors: [
                      Color(0x1F092008),
                      Color(0x99092008),
                      Color(0xF2092008),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _GlassPill(
                              icon: CupertinoIcons.compass,
                              label: destination.categoryName.toUpperCase(),
                            ),
                          ),
                        ),
                        if (destination.isHiddenGem) ...[
                          const SizedBox(width: 6),
                          const _GlassPill(
                            icon: CupertinoIcons.sparkles,
                            label: 'HIDDEN GEM',
                            highlighted: true,
                          ),
                        ],
                      ],
                    ),
                    const Spacer(),
                    Text(
                      destination.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.headlineSmall?.copyWith(
                        color: AppColors.ivorySand,
                        height: 1.12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          CupertinoIcons.location,
                          size: 13,
                          color: AppColors.warmSand,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${destination.lguName} · ${destination.clusterLabel}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.warmSand.withValues(alpha: 0.82),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _GlassPill(
                          icon: CupertinoIcons.ticket,
                          label: destination.priceLabel,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            destination.tags.isEmpty
                                ? destination.entityType
                                : destination.tags.first.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.warmSand.withValues(alpha: 0.58),
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      constraints: const BoxConstraints(maxWidth: 156),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: ShapeDecoration(
        color: highlighted
            ? AppColors.skyBlueWash
            : AppColors.ivorySand.withValues(alpha: 0.12),
        shape: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(999)),
          side: BorderSide(color: Color(0x2EFAF4EC), width: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: highlighted ? AppColors.deepForest : AppColors.ivorySand,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(
                color: highlighted ? AppColors.deepForest : AppColors.ivorySand,
                fontSize: 9,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
