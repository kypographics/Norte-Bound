import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../preferences/domain/trip_plan_models.dart';
import '../../preferences/presentation/planner_providers.dart';

class ItineraryScreen extends ConsumerStatefulWidget {
  const ItineraryScreen({super.key});

  @override
  ConsumerState<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends ConsumerState<ItineraryScreen> {
  int _selectedDayIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(plannerProvider);
    final itinerary = state.itinerary;
    final textTheme = Theme.of(context).textTheme;

    if (itinerary == null) {
      return Scaffold(
        backgroundColor: AppColors.warmSand,
        appBar: AppBar(title: const Text('Itinerary')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AppCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('No itinerary generated yet', style: textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.go(AppRoutes.planner),
                    child: const Text('Go to AI Co-Pilot'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final activeDay = itinerary.days.isNotEmpty
        ? itinerary.days[_selectedDayIndex.clamp(0, itinerary.days.length - 1)]
        : null;
    final report = itinerary.feasibilityReport;
    final expense = itinerary.expenseBreakdown;

    return Scaffold(
      backgroundColor: AppColors.warmSand,
      appBar: AppBar(
        backgroundColor: AppColors.warmSand,
        elevation: 0,
        title: Text('${itinerary.totalDays}-Day Itinerary'),
        actions: [
          TextButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push(AppRoutes.itineraryMap);
            },
            icon: const Icon(CupertinoIcons.map_pin_ellipse, size: 16),
            label: const Text('Open map'),
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          // 1. 5-Condition Feasibility Banner
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      report.isFeasible
                          ? CupertinoIcons.checkmark_seal_fill
                          : CupertinoIcons.exclamationmark_triangle_fill,
                      color: report.isFeasible
                          ? AppColors.deepForest
                          : AppColors.terracotta,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        report.isFeasible
                            ? 'Feasible plan · ${report.passedCount} of 5 checks passed'
                            : 'Constraint conflict · ${report.passedCount} of 5 checks passed',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: const ShapeDecoration(
                        color: AppColors.skyBlueWash,
                        shape: StadiumBorder(),
                      ),
                      child: Text(
                        '${itinerary.recalculationTimeMs} ms',
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.deepForest,
                          fontFeatures: AppTypography.tabularFigures,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (report.violatedConstraints.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  for (final v in report.violatedConstraints)
                    Text(
                      v,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.terracotta,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
                const SizedBox(height: 10),
                Text(
                  '${itinerary.lesserKnownCount} of ${itinerary.totalStops} stops are community or lesser-known (${(itinerary.lesserKnownRatio * 100).round()}%) · ${itinerary.totalDistanceKm} km total',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedForest,
                    fontFeatures: AppTypography.tabularFigures,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (state.detectedChanges.isNotEmpty) ...[
            AppCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Live schedule updates detected', style: textTheme.titleSmall),
                  const SizedBox(height: 6),
                  for (final c in state.detectedChanges)
                    Text(
                      '• $c',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.terracotta,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 2. Deterministic PHP Expense Breakdown
          _ExpenseBreakdownCard(expense: expense),
          const SizedBox(height: 14),

          // Action Row: Adjust / Save / Check live changes
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => _openAdjustSheet(context, state.preferences),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.terracotta,
                  foregroundColor: AppColors.ivorySand,
                ),
                icon: const Icon(CupertinoIcons.slider_horizontal_3, size: 15),
                label: const Text('Adjust plan'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.read(plannerProvider.notifier).checkLiveChanges();
                },
                icon: const Icon(CupertinoIcons.refresh, size: 15),
                label: const Text('Check live changes'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  await ref.read(plannerProvider.notifier).saveActiveItinerary(
                        '${itinerary.originName} ${itinerary.totalDays}-Day Plan',
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Itinerary saved to your account.'),
                        backgroundColor: AppColors.deepForest,
                      ),
                    );
                  }
                },
                icon: const Icon(CupertinoIcons.bookmark_fill, size: 15),
                label: Text(itinerary.savedId != null ? 'Saved' : 'Save plan'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Day switcher tabs
          if (itinerary.days.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Wrap(
                spacing: 8,
                children: [
                  for (var i = 0; i < itinerary.days.length; i += 1)
                    ChoiceChip(
                      label: Text('Day ${itinerary.days[i].dayNumber}'),
                      selected: _selectedDayIndex == i,
                      selectedColor: AppColors.skyBlueWash,
                      onSelected: (_) => setState(() => _selectedDayIndex = i),
                    ),
                ],
              ),
            ),

          if (activeDay != null)
            for (final stop in activeDay.stops) ...[
              if (stop.travelTimeFromPrevMinutes > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 18, bottom: 6, top: 2),
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.arrow_down,
                        size: 13,
                        color: AppColors.mutedForest,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${stop.distanceFromPrevKm} km · ${stop.travelTimeFromPrevMinutes} mins · ₱${stop.legTransportCostPhp.round()} ride est.',
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.mutedForest,
                          fontFeatures: AppTypography.tabularFigures,
                        ),
                      ),
                    ],
                  ),
                ),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: const ShapeDecoration(
                            color: AppColors.skyBlueWash,
                            shape: StadiumBorder(),
                          ),
                          child: Text(
                            '${stop.startTime} – ${stop.endTime}',
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.deepForest,
                              fontWeight: FontWeight.w700,
                              fontFeatures: AppTypography.tabularFigures,
                            ),
                          ),
                        ),
                        if (stop.mealWindow != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: ShapeDecoration(
                              color: AppColors.terracottaWash,
                              shape: const StadiumBorder(),
                            ),
                            child: Text(
                              stop.mealWindow!.toUpperCase(),
                              style: textTheme.labelSmall?.copyWith(
                                color: AppColors.terracotta,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        IconButton(
                          tooltip: 'Swap stop',
                          onPressed: state.isGeneratingItinerary
                              ? null
                              : () {
                                  HapticFeedback.lightImpact();
                                  ref
                                      .read(plannerProvider.notifier)
                                      .excludeStopAndRecalculate(
                                        stop.destinationId,
                                      );
                                },
                          icon: const Icon(
                            CupertinoIcons.arrow_2_squarepath,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => context.push(
                        '${AppRoutes.destinationDetail}/${stop.slug}',
                      ),
                      child: Text(
                        stop.name,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${stop.lguName} · ${stop.operatingWindowLabel} · Entry ₱${stop.entryCostPhp.round()}${stop.estimatedMealCostPhp > 0 ? ' · Meal ₱${stop.estimatedMealCostPhp.round()}' : ''}',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedForest,
                        fontFeatures: AppTypography.tabularFigures,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  Future<void> _openAdjustSheet(
    BuildContext context,
    TripPreferenceInput current,
  ) async {
    var hours = current.availableHoursPerDay;
    var budget = current.budgetAmount ?? 2500;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.ivorySand,
      shape: const ContinuousRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Adjust remaining trip constraints',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 14),
                  Text(
                    'Daily hours: ${hours.round()} hrs',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Slider(
                    value: hours.clamp(2, 14),
                    min: 2,
                    max: 14,
                    divisions: 12,
                    activeColor: AppColors.terracotta,
                    onChanged: (v) => setModalState(() => hours = v),
                  ),
                  Text(
                    'Budget: ₱${budget.round()}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Slider(
                    value: budget.clamp(300, 15000),
                    min: 300,
                    max: 15000,
                    divisions: 29,
                    activeColor: AppColors.terracotta,
                    onChanged: (v) => setModalState(() => budget = v),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ref.read(plannerProvider.notifier).buildItinerary(
                              overridePreferences: current.copyWith(
                                availableHoursPerDay: hours,
                                budgetAmount: budget,
                              ),
                            );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.terracotta,
                        foregroundColor: AppColors.ivorySand,
                      ),
                      child: const Text('Recalculate plan'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ExpenseBreakdownCard extends StatelessWidget {
  const _ExpenseBreakdownCard({required this.expense});

  final ItineraryExpenseBreakdown expense;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final budget = expense.budgetAmount ?? expense.totalEstimatedCost;
    final ratio = budget > 0
        ? (expense.totalEstimatedCost / budget).clamp(0.0, 1.0)
        : 1.0;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Estimated budget usage', style: textTheme.titleSmall),
              Text(
                expense.budgetAmount != null
                    ? '₱${expense.totalEstimatedCost.round()} of ₱${expense.budgetAmount!.round()}'
                    : '₱${expense.totalEstimatedCost.round()}',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: AppTypography.tabularFigures,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: AppColors.warmSand,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.terracotta),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ExpenseStat(
                  label: 'ENTRANCE',
                  value:
                      '₱${(expense.entranceAndActivityCost + expense.parkingCost).round()}',
                ),
              ),
              Expanded(
                child: _ExpenseStat(
                  label: 'MEALS',
                  value: '₱${expense.mealsCost.round()}',
                ),
              ),
              Expanded(
                child: _ExpenseStat(
                  label: 'TRANSPORT',
                  value: '₱${expense.transportCost.round()}',
                ),
              ),
              Expanded(
                child: _ExpenseStat(
                  label: 'REMAINING',
                  value: expense.remainingBudget != null
                      ? '₱${expense.remainingBudget!.round()}'
                      : 'N/A',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpenseStat extends StatelessWidget {
  const _ExpenseStat({required this.label, required this.value});

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
            fontSize: 8.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontFeatures: AppTypography.tabularFigures,
          ),
        ),
      ],
    );
  }
}
