import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/storage/traveler_local_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../domain/destination_detail.dart';
import '../../domain/destination_summary.dart';
import '../../../preferences/presentation/planner_providers.dart';
import '../discovery_providers.dart';
import '../widgets/destination_artwork.dart';

class DestinationDetailScreen extends ConsumerWidget {
  const DestinationDetailScreen({
    super.key,
    required this.slug,
    this.destination,
  });

  final String slug;
  final DestinationSummary? destination;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(destinationDetailProvider(slug));
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.warmSand,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.warmSand, Color(0xFFF0DFC9)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Floating App Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Row(
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
                      'VERIFIED DESTINATION',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.terracotta,
                        fontSize: 9,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Builder(
                      builder: (context) {
                        final id = detailAsync.value?.id ?? destination?.id;
                        final slugVal =
                            detailAsync.value?.slug ?? destination?.slug ?? slug;
                        final nameVal =
                            detailAsync.value?.name ?? destination?.name ?? slug;
                        final lguVal =
                            detailAsync.value?.lguName ??
                            destination?.lguName ??
                            'Ilocos Norte';
                        final catVal =
                            detailAsync.value?.categoryCode ??
                            destination?.categoryCode ??
                            'natural_attraction';
                        final imgVal =
                            detailAsync.value?.imageUrl ?? destination?.imageUrl;
                        final isFav = id != null &&
                            ref.watch(
                              travelerLocalStoreProvider.select(
                                (s) => s.isFavorite(id),
                              ),
                            );
                        return _CircleButton(
                          icon: isFav
                              ? CupertinoIcons.heart_fill
                              : CupertinoIcons.heart,
                          tooltip: isFav
                              ? 'Remove from favorites'
                              : 'Save to favorites',
                          onTap: id == null || id <= 0
                              ? () {}
                              : () {
                                  HapticFeedback.lightImpact();
                                  ref
                                      .read(travelerLocalStoreProvider.notifier)
                                      .toggleFavorite(
                                        FavoriteDestination(
                                          id: id,
                                          slug: slugVal,
                                          name: nameVal,
                                          lguName: lguVal,
                                          categoryCode: catVal,
                                          imageUrl: imgVal,
                                        ),
                                      );
                                },
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Body content
              Expanded(
                child: detailAsync.when(
                  data: (detail) => _DestinationDetailBody(detail: detail),
                  loading: () => destination != null
                      ? _DestinationDetailBodyFromSummary(summary: destination!)
                      : const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: LoadingSkeleton(
                              height: 300,
                              borderRadius: 24,
                            ),
                          ),
                        ),
                  error: (error, stack) => destination != null
                      ? _DestinationDetailBodyFromSummary(summary: destination!)
                      : Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: AppCard(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    CupertinoIcons.exclamationmark_triangle,
                                    size: 36,
                                    color: AppColors.terracotta,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Could not load full profile',
                                    style: textTheme.headlineSmall,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    error.toString(),
                                    style: textTheme.bodySmall?.copyWith(
                                      color: AppColors.mutedForest,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton(
                                    onPressed: () => ref.refresh(
                                      destinationDetailProvider(slug),
                                    ),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                ),
              ),

              // Sticky Frosted Bottom Action Bar
              ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    decoration: BoxDecoration(
                      color: AppColors.ivorySand.withValues(alpha: 0.84),
                      border: const Border(
                        top: BorderSide(color: AppColors.hairline, width: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'ENTRY ESTIMATE',
                                style: textTheme.labelSmall?.copyWith(
                                  color: AppColors.mutedForest,
                                  fontSize: 8.5,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                detailAsync.value?.priceLabel ??
                                    destination?.priceLabel ??
                                    'Verified rates',
                                style: textTheme.titleMedium?.copyWith(
                                  fontFeatures: AppTypography.tabularFigures,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        FilledButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            final router = GoRouter.maybeOf(context);
                            final messenger = ScaffoldMessenger.of(context);
                            final resolvedId =
                                detailAsync.value?.id ?? destination?.id;
                            final name =
                                detailAsync.value?.name ??
                                destination?.name ??
                                slug;
                            if (resolvedId != null && resolvedId > 0) {
                              ref
                                  .read(plannerProvider.notifier)
                                  .addDestinationToDraft(
                                    resolvedId,
                                    name: name,
                                  );
                            }
                            messenger
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Added $name to active itinerary draft!',
                                  ),
                                  action: SnackBarAction(
                                    label: 'Plan',
                                    textColor: AppColors.skyBlue,
                                    onPressed: () =>
                                        router?.go(AppRoutes.planner),
                                  ),
                                  backgroundColor: AppColors.deepForest,
                                ),
                              );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.terracotta,
                            foregroundColor: AppColors.ivorySand,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 14,
                            ),
                            shape: const ContinuousRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(20),
                              ),
                            ),
                          ),
                          icon: const Icon(CupertinoIcons.plus_circle_fill, size: 16),
                          label: const Text('Add to Itinerary'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DestinationDetailBody extends StatelessWidget {
  const _DestinationDetailBody({required this.detail});

  final DestinationDetail detail;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final opStatus = detail.operationalStatusAt(now);
    final todayDayIndex = now.weekday % 7;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
      children: [
        SizedBox(
          height: 260,
          child: DestinationArtwork(
            categoryCode: detail.categoryCode,
            slug: detail.slug,
            name: detail.name,
            imageUrl: detail.imageUrl,
            borderRadius: 24,
            iconSize: 68,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MetaPill(
              icon: CupertinoIcons.map_pin_ellipse,
              label: detail.lguName.toUpperCase(),
              isSkyBlue: true,
            ),
            _MetaPill(
              icon: CupertinoIcons.tag_fill,
              label: detail.categoryName.toUpperCase(),
              isSkyBlue: true,
            ),
            _MetaPill(
              icon: detail.isHiddenGem
                  ? CupertinoIcons.sparkles
                  : CupertinoIcons.star_fill,
              label: detail.popularityLabel.toUpperCase(),
              isTerracotta: detail.isHiddenGem,
              isSkyBlue: !detail.isHiddenGem,
            ),
            _MetaPill(
              icon: CupertinoIcons.checkmark_shield_fill,
              label: detail.verification.statusLabel.toUpperCase(),
              isSkyBlue: true,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(detail.name, style: textTheme.displaySmall),
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
                '${detail.address.isNotEmpty ? detail.address : detail.lguName} · ${detail.tourismCluster.replaceAll('_', ' ')}',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedForest,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Verification & Source Attribution Card (Zero Hallucination)
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.shield_lefthalf_fill,
                    size: 18,
                    color: AppColors.deepForest,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Verified Source Attribution',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _MetaPill(
                    icon: detail.verification.isVerified
                        ? CupertinoIcons.checkmark_seal_fill
                        : CupertinoIcons.clock_fill,
                    label: detail.verification.statusLabel.toUpperCase(),
                    isSkyBlue: detail.verification.isVerified,
                    isTerracotta: !detail.verification.isVerified,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ProvenanceRow(
                label: 'Verification Status',
                value: detail.verification.statusLabel,
              ),
              const SizedBox(height: 6),
              _ProvenanceRow(
                label: 'Source Name',
                value: detail.verification.sourceName ?? 'Municipal Tourism Office',
              ),
              const SizedBox(height: 6),
              _ProvenanceRow(
                label: 'Source Type',
                value: detail.verification.sourceTypeLabel,
              ),
              const SizedBox(height: 6),
              _ProvenanceRow(
                label: 'Last Verified',
                value: detail.verification.lastVerifiedDate ?? 'Recently verified',
                tabular: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Itemized Financial Breakdown Card
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.money_dollar_circle,
                    size: 18,
                    color: AppColors.terracotta,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Itemized Financial Breakdown',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    detail.pricing.currency,
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.mutedForest,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _FinancialLineItem(
                label: 'Adult Entrance Fee',
                value: detail.pricing.adultEntryLabel,
              ),
              _FinancialLineItem(
                label: 'Student / Senior Concession',
                value: detail.pricing.concessionEntryLabel,
              ),
              _FinancialLineItem(
                label: 'Mandatory Activity / Guide Fee',
                value: detail.pricing.mandatoryActivityLabel,
              ),
              _FinancialLineItem(
                label: 'Parking Fee',
                value: detail.pricing.parkingLabel,
              ),
              _FinancialLineItem(
                label: 'Estimated Meal Range',
                value: detail.pricing.mealRangeLabel,
                showDivider: false,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.warmSand.withValues(alpha: 0.65),
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  border: Border.all(color: AppColors.hairline, width: 0.5),
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.car_detailed,
                      size: 14,
                      color: AppColors.deepForest,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        detail.highwayAccessible
                            ? 'Highway accessible · ${detail.roadConditionLabel}'
                            : 'Local feeder road · ${detail.roadConditionLabel}',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.deepForest,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // About & Historical Background
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Overview', style: textTheme.titleSmall),
              const SizedBox(height: 10),
              Text(
                detail.description,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedForest,
                  height: 1.6,
                ),
              ),
              if (detail.historicalBackground != null &&
                  detail.historicalBackground!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Historical & Cultural Significance', style: textTheme.titleSmall),
                const SizedBox(height: 10),
                Text(
                  detail.historicalBackground!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedForest,
                    height: 1.6,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 7-Day Operating Schedule Card
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(CupertinoIcons.clock, size: 18, color: AppColors.terracotta),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('7-Day Operating Schedule', style: textTheme.titleSmall),
                        const SizedBox(height: 2),
                        Text(
                          detail.verification.isVerified
                              ? opStatus.detailText
                              : 'Schedule awaits field check',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.mutedForest,
                            fontFeatures: AppTypography.tabularFigures,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _MetaPill(
                    icon: !detail.verification.isVerified
                        ? CupertinoIcons.clock_fill
                        : opStatus.isOpen
                            ? CupertinoIcons.checkmark_circle_fill
                            : CupertinoIcons.moon_zzz_fill,
                    label: !detail.verification.isVerified
                        ? 'FIELD CHECK PENDING'
                        : opStatus.label.toUpperCase(),
                    isSkyBlue: detail.verification.isVerified && opStatus.isOpen,
                    isTerracotta: !detail.verification.isVerified || !opStatus.isOpen,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (detail.operatingHours.isEmpty)
                Text('Standard hours apply.', style: textTheme.bodySmall)
              else
                ...detail.operatingHours.map((h) {
                  final isToday = h.dayOfWeek == todayDayIndex;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    margin: const EdgeInsets.symmetric(vertical: 1),
                    decoration: isToday
                        ? BoxDecoration(
                            color: AppColors.skyBlueWash,
                            borderRadius: const BorderRadius.all(Radius.circular(10)),
                          )
                        : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isToday
                              ? '${h.dayName ?? 'Day ${h.dayOfWeek}'} (Today)'
                              : (h.dayName ?? 'Day ${h.dayOfWeek}'),
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
                            color: AppColors.deepForest,
                          ),
                        ),
                        Text(
                          h.temporarilyClosed
                              ? 'Temporarily Closed'
                              : h.is24Hours
                                  ? '24 Hours'
                                  : '${h.openingTime ?? ''} – ${h.closingTime ?? ''}',
                          style: textTheme.bodySmall?.copyWith(
                            color: h.temporarilyClosed
                                ? AppColors.terracotta
                                : isToday
                                    ? AppColors.deepForest
                                    : AppColors.mutedForest,
                            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                            fontFeatures: AppTypography.tabularFigures,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),

        if (detail.tags.isNotEmpty) ...[
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in detail.tags)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: const ShapeDecoration(
                    color: AppColors.skyBlueWash,
                    shape: StadiumBorder(),
                  ),
                  child: Text(
                    tag.name,
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.deepForest,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _DestinationDetailBodyFromSummary extends StatelessWidget {
  const _DestinationDetailBodyFromSummary({required this.summary});

  final DestinationSummary summary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
      children: [
        SizedBox(
          height: 260,
          child: DestinationArtwork(
            categoryCode: summary.categoryCode,
            slug: summary.slug,
            name: summary.name,
            imageUrl: summary.imageUrl,
            borderRadius: 24,
            iconSize: 68,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _MetaPill(
              icon: CupertinoIcons.checkmark_shield_fill,
              label: summary.verificationStatus.toUpperCase(),
              isSkyBlue: true,
            ),
            const SizedBox(width: 8),
            _MetaPill(
              icon: CupertinoIcons.compass,
              label: summary.clusterLabel.toUpperCase(),
              isSkyBlue: true,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(summary.name, style: textTheme.displaySmall),
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
                '${summary.lguName} · ${summary.categoryName}',
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
                  value: summary.priceLabel,
                ),
              ),
              Container(width: 0.5, height: 36, color: AppColors.hairline),
              Expanded(
                child: _DetailStat(
                  label: 'ACCESS',
                  value: summary.highwayAccessible ? 'Highway' : 'Local road',
                ),
              ),
              Container(width: 0.5, height: 36, color: AppColors.hairline),
              Expanded(
                child: _DetailStat(
                  label: 'CLUSTER',
                  value: summary.clusterLabel,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('About this place', style: textTheme.headlineSmall),
        const SizedBox(height: 10),
        Text(
          summary.description,
          style: textTheme.bodyLarge?.copyWith(
            color: AppColors.mutedForest,
            height: 1.62,
          ),
        ),
      ],
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
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, size: 18),
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    this.isSkyBlue = false,
    this.isTerracotta = false,
  });

  final IconData icon;
  final String label;
  final bool isSkyBlue;
  final bool isTerracotta;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: ShapeDecoration(
        color: isTerracotta ? AppColors.terracotta.withValues(alpha: 0.15) : AppColors.skyBlueWash,
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: isTerracotta ? AppColors.terracotta : AppColors.deepForest,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: isTerracotta ? AppColors.terracotta : AppColors.deepForest,
              fontSize: 9,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w700,
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

class _ProvenanceRow extends StatelessWidget {
  const _ProvenanceRow({
    required this.label,
    required this.value,
    this.tabular = false,
  });

  final String label;
  final String value;
  final bool tabular;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 122,
          child: Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.mutedForest,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.deepForest,
              fontWeight: FontWeight.w600,
              fontFeatures: tabular ? AppTypography.tabularFigures : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _FinancialLineItem extends StatelessWidget {
  const _FinancialLineItem({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedForest,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                value,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.deepForest,
                  fontWeight: FontWeight.w700,
                  fontFeatures: AppTypography.tabularFigures,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 0.5, color: AppColors.hairline),
      ],
    );
  }
}
