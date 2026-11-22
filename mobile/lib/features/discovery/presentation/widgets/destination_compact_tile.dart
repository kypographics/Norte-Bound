import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/destination_summary.dart';
import 'destination_artwork.dart';

class DestinationCompactTile extends StatelessWidget {
  const DestinationCompactTile({
    super.key,
    required this.destination,
    this.onTap,
    this.width,
  });

  final DestinationSummary destination;
  final VoidCallback? onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tile = AppCard(
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            height: 100,
            child: DestinationArtwork(
              categoryCode: destination.categoryCode,
              slug: destination.slug,
              name: destination.name,
              imageUrl: destination.imageUrl,
              borderRadius: 18,
              iconSize: 32,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: SizedBox(
              height: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          destination.categoryName.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.mutedForest,
                            fontSize: 9,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ),
                      if (destination.isHiddenGem)
                        const Icon(
                          CupertinoIcons.sparkles,
                          size: 13,
                          color: AppColors.terracotta,
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    destination.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(height: 1.25),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.location,
                        size: 11,
                        color: AppColors.mutedForest,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          '${destination.lguName} · ${destination.clusterLabel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          destination.priceLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.deepForest,
                            fontFeatures: AppTypography.tabularFigures,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (destination.tags.isNotEmpty)
                        Flexible(
                          child: Text(
                            destination.tags.first.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.terracotta,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: AppColors.mutedForest,
            ),
          ),
        ],
      ),
    );

    if (width == null) {
      return tile;
    }

    return SizedBox(width: width, child: tile);
  }
}
