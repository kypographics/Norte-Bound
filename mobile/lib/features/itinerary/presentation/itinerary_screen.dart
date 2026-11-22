import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../discovery/presentation/widgets/destination_artwork.dart';
import '../../preferences/domain/trip_plan_models.dart';
import '../../preferences/presentation/planner_providers.dart';

class ItineraryScreen extends ConsumerStatefulWidget {
  const ItineraryScreen({super.key});

  @override
  ConsumerState<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends ConsumerState<ItineraryScreen> {
  int _selectedDayIndex = 0;
  _WeatherSnapshot? _weather;
  String? _weatherKey;

  void _syncWeather(ItineraryDayPlan? day) {
    if (day == null || day.stops.isEmpty) return;
    final first = day.stops.firstWhere(
      (s) => s.latitude != null && s.longitude != null,
      orElse: () => day.stops.first,
    );
    if (first.latitude == null || first.longitude == null) return;
    final key =
        '${day.dayNumber}:${first.latitude!.toStringAsFixed(2)},${first.longitude!.toStringAsFixed(2)}';
    if (key == _weatherKey) return;
    _weatherKey = key;
    unawaited(
      _fetchOpenMeteoWeather(
        first.lguName,
        first.latitude!,
        first.longitude!,
        key,
      ),
    );
  }

  Future<void> _fetchOpenMeteoWeather(
    String areaName,
    double lat,
    double lon,
    String requestKey,
  ) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 4),
      ),
    );
    try {
      final res = await dio.get<Map<String, dynamic>>(
        'https://api.open-meteo.com/v1/forecast',
        queryParameters: {
          'latitude': lat,
          'longitude': lon,
          'current': 'temperature_2m,precipitation,wind_speed_10m',
          'daily': 'precipitation_probability_max',
          'forecast_days': 1,
        },
      );
      if (!mounted || _weatherKey != requestKey) return;
      final current = res.data?['current'];
      final daily = res.data?['daily'];
      if (current is Map<String, dynamic>) {
        final probs = daily is Map<String, dynamic>
            ? daily['precipitation_probability_max']
            : null;
        final rainProb = probs is List && probs.isNotEmpty && probs.first is num
            ? (probs.first as num).round()
            : 0;
        setState(() {
          _weather = _WeatherSnapshot(
            areaName: areaName,
            tempC: (current['temperature_2m'] as num?)?.toDouble() ?? 29,
            windKmh: (current['wind_speed_10m'] as num?)?.toDouble() ?? 12,
            precipMm: (current['precipitation'] as num?)?.toDouble() ?? 0,
            rainProbabilityPct: rainProb,
          );
        });
      }
    } catch (_) {
      // Non-blocking when offline or inside widget tests
    } finally {
      dio.close(force: true);
    }
  }

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
                  Text(
                    'No itinerary generated yet',
                    style: textTheme.headlineSmall,
                  ),
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
    _syncWeather(activeDay);
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
            onPressed: () => _handleSavePlan(itinerary),
            icon: Icon(
              itinerary.savedId != null
                  ? CupertinoIcons.bookmark_fill
                  : CupertinoIcons.bookmark,
              size: 16,
            ),
            label: Text(itinerary.savedId != null ? 'Saved' : 'Save'),
          ),
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
                  Text(
                    'Live schedule updates detected',
                    style: textTheme.titleSmall,
                  ),
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

          if (state.errorMessage != null) ...[
            AppCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.exclamationmark_circle_fill,
                    color: AppColors.danger,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.deepForest,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 2. Deterministic PHP Expense Breakdown
          _ExpenseBreakdownCard(expense: expense),
          if (_weather != null) ...[
            const SizedBox(height: 12),
            _WeatherAdvisoryCard(
              weather: _weather!,
              onSwapIndoor: () {
                HapticFeedback.lightImpact();
                ref
                    .read(plannerProvider.notifier)
                    .buildItinerary(
                      overridePreferences: state.preferences.copyWith(
                        categories: const [
                          'heritage_cultural',
                          'artisan_craft_experience',
                          'food_culinary',
                        ],
                      ),
                    );
              },
            ),
          ],
          const SizedBox(height: 14),

          // Action Row: Start route / Adjust / Save / Check live changes / Food / Share
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: itinerary.days.isEmpty
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        ref
                            .read(plannerProvider.notifier)
                            .startRouteNavigation(
                              dayIndex: _selectedDayIndex.clamp(
                                0,
                                itinerary.days.length - 1,
                              ),
                            );
                        context.push(AppRoutes.itineraryMap);
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.deepForest,
                  foregroundColor: AppColors.ivorySand,
                ),
                icon: const Icon(CupertinoIcons.location_north_fill, size: 15),
                label: const Text('Start route'),
              ),
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
                onPressed: () => _handleSavePlan(itinerary),
                icon: Icon(
                  itinerary.savedId != null
                      ? CupertinoIcons.bookmark_fill
                      : CupertinoIcons.bookmark,
                  size: 15,
                ),
                label: Text(itinerary.savedId != null ? 'Saved' : 'Save plan'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref
                      .read(plannerProvider.notifier)
                      .autoRouteNearestToFurthest(dayIndex: _selectedDayIndex);
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Route ordered from nearest to furthest.',
                        ),
                        backgroundColor: AppColors.deepForest,
                      ),
                    );
                },
                icon: const Icon(CupertinoIcons.compass, size: 15),
                label: const Text('Nearest → Furthest'),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    _openNearbyFoodSheet(context, state.preferences),
                icon: const Icon(Icons.local_cafe_outlined, size: 15),
                label: const Text('Add food/coffee'),
              ),
              OutlinedButton.icon(
                onPressed: () => _openShareSplitSheet(
                  context,
                  itinerary,
                  state.preferences.groupSize,
                ),
                icon: const Icon(CupertinoIcons.share, size: 15),
                label: const Text('Share / Split'),
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
            for (var idx = 0; idx < activeDay.stops.length; idx += 1) ...[
              Builder(
                builder: (context) {
                  final stop = activeDay.stops[idx];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (stop.travelTimeFromPrevMinutes > 0)
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 18,
                            bottom: 6,
                            top: 2,
                          ),
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
                                      fontFeatures:
                                          AppTypography.tabularFigures,
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
                                Builder(
                                  builder: (context) {
                                    final isLocked = state
                                        .preferences
                                        .lockedDestinationIds
                                        .contains(stop.destinationId);
                                    return IconButton(
                                      tooltip: isLocked
                                          ? 'Unlock stop'
                                          : 'Lock stop',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        ref
                                            .read(plannerProvider.notifier)
                                            .toggleLockedDestination(
                                              stop.destinationId,
                                              name: stop.name,
                                            );
                                      },
                                      icon: Icon(
                                        isLocked
                                            ? CupertinoIcons.lock_fill
                                            : CupertinoIcons.lock_open,
                                        size: 16,
                                        color: isLocked
                                            ? AppColors.terracotta
                                            : AppColors.mutedForest,
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  tooltip: 'Move earlier',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: idx > 0
                                      ? () {
                                          HapticFeedback.lightImpact();
                                          ref
                                              .read(plannerProvider.notifier)
                                              .moveStopInDay(
                                                _selectedDayIndex.clamp(
                                                  0,
                                                  itinerary.days.length - 1,
                                                ),
                                                idx,
                                                idx - 1,
                                              );
                                        }
                                      : null,
                                  icon: const Icon(
                                    CupertinoIcons.chevron_up,
                                    size: 16,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Move later',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: idx < activeDay.stops.length - 1
                                      ? () {
                                          HapticFeedback.lightImpact();
                                          ref
                                              .read(plannerProvider.notifier)
                                              .moveStopInDay(
                                                _selectedDayIndex.clamp(
                                                  0,
                                                  itinerary.days.length - 1,
                                                ),
                                                idx,
                                                idx + 1,
                                              );
                                        }
                                      : null,
                                  icon: const Icon(
                                    CupertinoIcons.chevron_down,
                                    size: 16,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Swap stop',
                                  visualDensity: VisualDensity.compact,
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
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 68,
                                  height: 68,
                                  child: DestinationArtwork(
                                    categoryCode: stop.categoryCode,
                                    slug: stop.slug,
                                    name: stop.name,
                                    imageUrl: stop.imageUrl,
                                    borderRadius: 16,
                                    iconSize: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      InkWell(
                                        onTap: () => context.push(
                                          '${AppRoutes.destinationDetail}/${stop.slug}',
                                        ),
                                        child: Text(
                                          stop.name,
                                          style: textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${stop.lguName} · ${stop.operatingWindowLabel} · Entry ₱${stop.entryCostPhp.round()}${stop.estimatedMealCostPhp > 0 ? ' · Meal ₱${stop.estimatedMealCostPhp.round()}' : ''}',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: AppColors.mutedForest,
                                          fontFeatures:
                                              AppTypography.tabularFigures,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          if (state.preferences.transportMode == 'publicCommute') ...[
            const SizedBox(height: 6),
            const _CommuterGuideCard(),
          ],
          const SizedBox(height: 10),
          _EmergencyOfflineCard(isCachedOffline: itinerary.savedId != null),
        ],
      ),
    );
  }

  Future<void> _handleSavePlan(GeneratedItinerary itinerary) async {
    HapticFeedback.lightImpact();
    final ok = await ref
        .read(plannerProvider.notifier)
        .saveActiveItinerary(
          '${itinerary.originName} ${itinerary.totalDays}-Day Plan',
        );
    if (!mounted) return;
    final router = GoRouter.maybeOf(context);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    if (ok) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Itinerary saved to your account.'),
          backgroundColor: AppColors.deepForest,
          action: SnackBarAction(
            label: 'View saved',
            textColor: AppColors.skyBlue,
            onPressed: () => router?.go(AppRoutes.planner),
          ),
        ),
      );
    } else {
      final err =
          ref.read(plannerProvider).errorMessage ?? 'Could not save itinerary.';
      messenger.showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.danger),
      );
    }
  }

  static String _budgetLevelFor(num amount) {
    if (amount <= 1800) return 'budget';
    if (amount <= 4500) return 'moderate';
    return 'flexible';
  }

  Future<void> _openAdjustSheet(
    BuildContext context,
    TripPreferenceInput current,
  ) async {
    var hours = current.availableHoursPerDay;
    var budget = current.budgetAmount ?? 2500;
    var budgetScope = current.budgetScope;
    var budgetLevel = current.budgetLevel;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.ivorySand,
      shape: const ContinuousRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Adjust remaining trip constraints',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
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
                    const SizedBox(height: 6),
                    Text(
                      'Budget scope',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final (val, label) in const [
                          ('perPerson', 'Per person'),
                          ('totalGroup', 'Total group'),
                        ])
                          ChoiceChip(
                            label: Text(label),
                            selected: budgetScope == val,
                            selectedColor: AppColors.skyBlueWash,
                            onSelected: (_) =>
                                setModalState(() => budgetScope = val),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Budget: ₱${budget.round()} (${budgetScope == 'totalGroup' ? 'Total group' : 'Per person'})',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        for (final preset in const [1000, 2500, 5000, 10000])
                          ChoiceChip(
                            label: Text(
                              '₱${(preset ~/ 1000)},${(preset % 1000).toString().padLeft(3, '0')}',
                              style: const TextStyle(
                                fontFeatures: AppTypography.tabularFigures,
                              ),
                            ),
                            selected: budget.round() == preset,
                            selectedColor: AppColors.skyBlueWash,
                            onSelected: (_) => setModalState(() {
                              budget = preset.toDouble();
                              budgetLevel = _budgetLevelFor(preset);
                            }),
                          ),
                      ],
                    ),
                    Slider(
                      value: budget.clamp(500, 15000).toDouble(),
                      min: 500,
                      max: 15000,
                      divisions: 29,
                      activeColor: AppColors.terracotta,
                      onChanged: (v) => setModalState(() {
                        budget = v.roundToDouble();
                        budgetLevel = _budgetLevelFor(budget);
                      }),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ref
                              .read(plannerProvider.notifier)
                              .buildItinerary(
                                overridePreferences: current.copyWith(
                                  availableHoursPerDay: hours,
                                  budgetAmount: budget,
                                  budgetScope: budgetScope,
                                  budgetLevel: budgetLevel,
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
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openNearbyFoodSheet(
    BuildContext context,
    TripPreferenceInput current,
  ) async {
    HapticFeedback.lightImpact();
    final foodFuture = ref
        .read(plannerRepositoryProvider)
        .fetchRecommendations(
          current.copyWith(
            categories: const ['food_culinary'],
            preferredScenery: const [],
          ),
        );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.ivorySand,
      shape: const ContinuousRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * 0.6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                  child: Text(
                    'Add nearby lunch or coffee',
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                ),
                Expanded(
                  child: FutureBuilder(
                    future: foodFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final items = snapshot.data?.items ?? const [];
                      if (items.isEmpty) {
                        return const Center(
                          child: Text(
                            'No nearby dining stops fit your current budget.',
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final food = items[i];
                          return ListTile(
                            title: Text(food.name),
                            subtitle: Text(
                              '${food.lguName} · ${food.estimatedTravelMinutes} mins · ${food.entryLabel}',
                            ),
                            trailing: const Icon(
                              CupertinoIcons.plus_circle_fill,
                            ),
                            onTap: () {
                              Navigator.pop(sheetContext);
                              final updatedLocked = {
                                ...current.lockedDestinationIds,
                                food.id,
                              }.toList();
                              ref
                                  .read(plannerProvider.notifier)
                                  .buildItinerary(
                                    overridePreferences: current.copyWith(
                                      lockedDestinationIds: updatedLocked,
                                    ),
                                  );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openShareSplitSheet(
    BuildContext context,
    GeneratedItinerary itinerary,
    int groupSize,
  ) async {
    HapticFeedback.lightImpact();
    final pax = math.max(1, groupSize);
    final totalPhp = itinerary.expenseBreakdown.totalEstimatedCost;
    final perPersonPhp = totalPhp / pax;
    final lines = <String>[
      'NORTE BOUND · ${itinerary.totalDays}-Day Itinerary from ${itinerary.originName}',
      'Total Est.: ₱${totalPhp.round()} · Per person ($pax pax): ₱${perPersonPhp.round()}',
      for (final day in itinerary.days) ...[
        'Day ${day.dayNumber}:',
        for (final stop in day.stops)
          '  ${stop.startTime}-${stop.endTime} ${stop.name} (${stop.lguName})',
      ],
    ];
    final summaryText = lines.join('\n');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.ivorySand,
      shape: const ContinuousRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        final textTheme = Theme.of(sheetContext).textTheme;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Share & Group Split', style: textTheme.headlineSmall),
                const SizedBox(height: 10),
                AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ExpenseStat(
                          label: 'GROUP TOTAL',
                          value: '₱${totalPhp.round()}',
                        ),
                      ),
                      Expanded(
                        child: _ExpenseStat(
                          label: 'PER PERSON ($pax PAX)',
                          value: '₱${perPersonPhp.round()}',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  summaryText,
                  maxLines: 7,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedForest,
                    fontFeatures: AppTypography.tabularFigures,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: summaryText));
                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(this.context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Itinerary & split copied to clipboard.',
                              ),
                              backgroundColor: AppColors.deepForest,
                            ),
                          );
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.deepForest,
                      foregroundColor: AppColors.ivorySand,
                    ),
                    icon: const Icon(CupertinoIcons.doc_on_clipboard, size: 16),
                    label: const Text('Copy summary'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WeatherSnapshot {
  const _WeatherSnapshot({
    required this.areaName,
    required this.tempC,
    required this.windKmh,
    required this.precipMm,
    required this.rainProbabilityPct,
  });

  final String areaName;
  final double tempC;
  final double windKmh;
  final double precipMm;
  final int rainProbabilityPct;

  bool get isRainRisk => rainProbabilityPct >= 50 || precipMm > 0.2;
}

class _WeatherAdvisoryCard extends StatelessWidget {
  const _WeatherAdvisoryCard({
    required this.weather,
    required this.onSwapIndoor,
  });

  final _WeatherSnapshot weather;
  final VoidCallback onSwapIndoor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.all(14),
      color: weather.isRainRisk
          ? AppColors.terracottaWash
          : AppColors.ivorySand,
      child: Row(
        children: [
          Icon(
            weather.isRainRisk
                ? CupertinoIcons.cloud_rain_fill
                : CupertinoIcons.sun_max_fill,
            size: 20,
            color: weather.isRainRisk
                ? AppColors.terracotta
                : AppColors.deepForest,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${weather.areaName} weather · ${weather.tempC.round()}°C',
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: AppTypography.tabularFigures,
                  ),
                ),
                Text(
                  'Rain risk ${weather.rainProbabilityPct}% · Wind ${weather.windKmh.round()} km/h',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedForest,
                    fontFeatures: AppTypography.tabularFigures,
                  ),
                ),
              ],
            ),
          ),
          if (weather.isRainRisk)
            TextButton(
              onPressed: onSwapIndoor,
              child: const Text('Swap indoor'),
            ),
        ],
      ),
    );
  }
}

class _CommuterGuideCard extends StatelessWidget {
  const _CommuterGuideCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.bus,
                size: 17,
                color: AppColors.terracotta,
              ),
              const SizedBox(width: 8),
              Text(
                'Ilocos Norte Commuter Guide',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Manila–Laoag terminals: Partas, GV Florida, Farinas Transit (Laoag Bypass / Town Proper).\n'
            '• North coast (Bacarra → Pasuquin → Burgos → Bangui → Pagudpud): ride Laoag–Pagudpud minibus/modern jeep (₱40–₱130).\n'
            '• Kapurpurawan / Adams trailheads: hire station tricycles (₱150–₱350 roundtrip) or habal-habal from Pancian.',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.mutedForest,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyOfflineCard extends StatelessWidget {
  const _EmergencyOfflineCard({required this.isCachedOffline});

  final bool isCachedOffline;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            CupertinoIcons.phone_circle_fill,
            size: 20,
            color: AppColors.deepForest,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCachedOffline
                      ? 'Offline Trip Pack Ready · Emergency Contacts'
                      : 'Emergency Contacts (Save plan for offline use)',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Emergency: 911 · Ilocos Norte PDRRMO: (077) 772-1211 · DOT Region I: (072) 888-2098',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedForest,
                    fontFeatures: AppTypography.tabularFigures,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.terracotta,
              ),
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
