import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../discovery/domain/lgu.dart';
import '../../discovery/presentation/discovery_providers.dart';
import '../domain/trip_plan_models.dart';
import 'planner_providers.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  late final TextEditingController _promptController;

  static const _quickPrompts = [
    '2-day coastal & heritage trip near Pagudpud under ₱2,500 with waterfalls',
    '1-day Laoag and Paoay heritage + empanada food crawl by motorcycle',
    'Relaxed eastern highland eco-farm & falls trip in Adams and Solsona',
  ];

  static const _sceneryOptions = [
    ('coastal', 'Coastal'),
    ('highland', 'Highland'),
    ('heritage_urban', 'Heritage'),
    ('rural_agro', 'Rural'),
  ];

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController(
      text: ref.read(plannerProvider).prompt,
    );
    Future.microtask(() {
      if (mounted) {
        ref.read(plannerProvider.notifier).loadSavedItineraries();
      }
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(plannerProvider);
    final lguDir = ref.watch(lgusProvider).value;
    final taxonomy = ref.watch(taxonomyProvider).value;
    final textTheme = Theme.of(context).textTheme;
    final originLabel = _resolveOriginName(state, lguDir);

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
          child: Stack(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 175),
                    children: [
                      Text(
                        'AI CO-PILOT',
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.terracotta,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('Plan your north.', style: textTheme.displayMedium),
                      const SizedBox(height: 16),

                      // 1. GPS & Manual Starting Town Bar
                      _OriginContextCard(
                        originLabel: originLabel,
                        usingGps: state.usingGps,
                        onUseGps: () {
                          HapticFeedback.lightImpact();
                          ref.read(plannerProvider.notifier).acquireGpsLocation();
                        },
                        onPickTown: lguDir == null
                            ? null
                            : () => _openOriginPicker(context, lguDir),
                      ),
                      if (state.savedItineraries.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _SavedPlansCard(
                          plans: state.savedItineraries,
                          onOpen: (id) async {
                            HapticFeedback.lightImpact();
                            final ok = await ref
                                .read(plannerProvider.notifier)
                                .openSavedItinerary(id);
                            if (ok && context.mounted) {
                              context.push(AppRoutes.itinerary);
                            }
                          },
                          onDelete: (id) {
                            HapticFeedback.lightImpact();
                            ref
                                .read(plannerProvider.notifier)
                                .deleteSavedItinerary(id);
                          },
                        ),
                      ],
                      const SizedBox(height: 14),

                      // 2. Natural-Language Prompt Card
                      AppCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Describe your trip',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _promptController,
                              maxLines: 3,
                              minLines: 2,
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                hintText:
                                    'e.g., 2-day coastal & heritage trip near Pagudpud under ₱2,500',
                                filled: true,
                                fillColor: AppColors.warmSand.withValues(alpha: 0.6),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: AppColors.hairline,
                                    width: 0.5,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: AppColors.hairline,
                                    width: 0.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                for (final sample in _quickPrompts)
                                  ActionChip(
                                    label: Text(
                                      sample,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.labelSmall?.copyWith(
                                        color: AppColors.deepForest,
                                      ),
                                    ),
                                    backgroundColor: AppColors.skyBlueWash,
                                    side: BorderSide.none,
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      _promptController.text = sample;
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: state.isParsingIntent
                                    ? null
                                    : () {
                                        HapticFeedback.lightImpact();
                                        ref
                                            .read(plannerProvider.notifier)
                                            .interpretPrompt(
                                              _promptController.text,
                                            );
                                      },
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.deepForest,
                                  foregroundColor: AppColors.ivorySand,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: const ContinuousRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(18),
                                    ),
                                  ),
                                ),
                                icon: state.isParsingIntent
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.ivorySand,
                                        ),
                                      )
                                    : const Icon(CupertinoIcons.sparkles, size: 16),
                                label: Text(
                                  state.isParsingIntent
                                      ? 'Extracting...'
                                      : 'Extract trip details',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 3. Structured Preference Controls & Confirmation Card
                      _PreferencesControlsCard(
                        prefs: state.preferences,
                        awaitingConfirmation: state.awaitingConfirmation,
                        categories: taxonomy?.categories ?? const [],
                        sceneryOptions: _sceneryOptions,
                        onUpdate: (updated) {
                          ref
                              .read(plannerProvider.notifier)
                              .updatePreferences(updated);
                        },
                        onFindPlaces: state.isLoadingRecommendations
                            ? null
                            : () {
                                HapticFeedback.lightImpact();
                                ref
                                    .read(plannerProvider.notifier)
                                    .findMatchingPlaces();
                              },
                        isLoading: state.isLoadingRecommendations,
                      ),

                      if (state.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        AppCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              const Icon(
                                CupertinoIcons.exclamationmark_circle_fill,
                                color: AppColors.terracotta,
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
                      ],

                      if (state.isLoadingRecommendations) ...[
                        const SizedBox(height: 18),
                        const LoadingSkeleton(height: 150, borderRadius: 24),
                      ] else if (state.recommendations != null) ...[
                        const SizedBox(height: 20),
                        _RecommendationsSection(
                          response: state.recommendations!,
                          lockedIds: state.preferences.lockedDestinationIds,
                          onToggleStop: (id) {
                            HapticFeedback.lightImpact();
                            ref
                                .read(plannerProvider.notifier)
                                .toggleLockedDestination(id);
                          },
                          onApplyRelaxation: (patch) {
                            HapticFeedback.lightImpact();
                            var next = state.preferences;
                            if (patch['budgetAmount'] is num) {
                              next = next.copyWith(
                                budgetAmount:
                                    (patch['budgetAmount'] as num).toDouble(),
                              );
                            }
                            if (patch.containsKey('preferredLgus')) {
                              next = next.copyWith(
                                preferredLgus: const [],
                                preferredClusters: const [],
                              );
                            }
                            if (patch['startTime'] is String &&
                                patch['endTime'] is String) {
                              next = next.copyWith(
                                startTime: patch['startTime'] as String,
                                endTime: patch['endTime'] as String,
                                availableHoursPerDay: 10,
                              );
                            }
                            ref
                                .read(plannerProvider.notifier)
                                .updatePreferences(next);
                            ref
                                .read(plannerProvider.notifier)
                                .findMatchingPlaces();
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Sticky Frosted Bottom CTA bar above floating tab dock
              Positioned(
                left: 16,
                right: 16,
                bottom: 94,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 728),
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: ShapeDecoration(
                            color: AppColors.ivorySand.withValues(alpha: 0.88),
                            shape: const ContinuousRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(22)),
                              side: BorderSide(
                                color: AppColors.hairline,
                                width: 0.5,
                              ),
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
                                      '${state.preferences.availableDays}d · ₱${(state.preferences.budgetAmount ?? 0).round()}',
                                      style: textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontFeatures: AppTypography.tabularFigures,
                                      ),
                                    ),
                                    Text(
                                      state.preferences.lockedDestinationIds.isEmpty
                                          ? 'Auto-select feasible stops'
                                          : '${state.preferences.lockedDestinationIds.length} stops selected',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: AppColors.mutedForest,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              FilledButton.icon(
                                onPressed: state.isGeneratingItinerary
                                    ? null
                                    : () async {
                                        HapticFeedback.lightImpact();
                                        final ok = await ref
                                            .read(plannerProvider.notifier)
                                            .buildItinerary();
                                        if (ok && context.mounted) {
                                          context.push(AppRoutes.itinerary);
                                        }
                                      },
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.terracotta,
                                  foregroundColor: AppColors.ivorySand,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 12,
                                  ),
                                  shape: const ContinuousRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(16),
                                    ),
                                  ),
                                ),
                                icon: state.isGeneratingItinerary
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.ivorySand,
                                        ),
                                      )
                                    : const Icon(CupertinoIcons.map_fill, size: 15),
                                label: const Text('Build itinerary'),
                              ),
                            ],
                          ),
                        ),
                      ),
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

  String _resolveOriginName(PlannerState state, LguDirectory? directory) {
    if (state.usingGps) return 'Current GPS location';
    final lgu = directory?.lguByCode(state.preferences.originLguCode);
    return lgu?.name ?? 'Laoag City';
  }

  Future<void> _openOriginPicker(
    BuildContext context,
    LguDirectory directory,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.ivorySand,
      shape: const ContinuousRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final lgus = directory.clusters.expand((c) => c.lgus).toList();
        return SafeArea(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: lgus.length,
            itemBuilder: (context, index) {
              final lgu = lgus[index];
              return ListTile(
                leading: const Icon(
                  CupertinoIcons.map_pin,
                  color: AppColors.deepForest,
                ),
                title: Text(lgu.name),
                subtitle: Text(lgu.typeLabel),
                onTap: () {
                  ref.read(plannerProvider.notifier).setOriginLgu(lgu.lguCode);
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _OriginContextCard extends StatelessWidget {
  const _OriginContextCard({
    required this.originLabel,
    required this.usingGps,
    required this.onUseGps,
    this.onPickTown,
  });

  final String originLabel;
  final bool usingGps;
  final VoidCallback onUseGps;
  final VoidCallback? onPickTown;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            usingGps ? CupertinoIcons.location_fill : CupertinoIcons.map_pin_ellipse,
            size: 18,
            color: AppColors.terracotta,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Starting from $originLabel',
              style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: onUseGps,
            child: const Text('Use GPS'),
          ),
          if (onPickTown != null)
            TextButton(
              onPressed: onPickTown,
              child: const Text('Change town'),
            ),
        ],
      ),
    );
  }
}

class _SavedPlansCard extends StatelessWidget {
  const _SavedPlansCard({
    required this.plans,
    required this.onOpen,
    required this.onDelete,
  });

  final List<SavedItinerarySummary> plans;
  final ValueChanged<int> onOpen;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saved plans',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          for (final plan in plans)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(
                CupertinoIcons.bookmark_fill,
                size: 18,
                color: AppColors.terracotta,
              ),
              title: Text(
                plan.title,
                style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${plan.totalDays}d · ${plan.stopCount} stops · ₱${plan.totalEstimatedCost.round()}',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedForest,
                  fontFeatures: AppTypography.tabularFigures,
                ),
              ),
              trailing: IconButton(
                tooltip: 'Delete saved plan',
                onPressed: () => onDelete(plan.id),
                icon: const Icon(CupertinoIcons.trash, size: 17),
              ),
              onTap: () => onOpen(plan.id),
            ),
        ],
      ),
    );
  }
}

class _PreferencesControlsCard extends StatelessWidget {
  const _PreferencesControlsCard({
    required this.prefs,
    required this.awaitingConfirmation,
    required this.categories,
    required this.sceneryOptions,
    required this.onUpdate,
    required this.onFindPlaces,
    required this.isLoading,
  });

  final TripPreferenceInput prefs;
  final bool awaitingConfirmation;
  final List<dynamic> categories;
  final List<(String, String)> sceneryOptions;
  final ValueChanged<TripPreferenceInput> onUpdate;
  final VoidCallback? onFindPlaces;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  awaitingConfirmation
                      ? 'Confirm extracted trip details'
                      : 'Trip constraints',
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (awaitingConfirmation)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: const ShapeDecoration(
                    color: AppColors.skyBlueWash,
                    shape: StadiumBorder(),
                  ),
                  child: Text(
                    'REVIEW BEFORE SCORING',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.deepForest,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Days & Group steppers
          Row(
            children: [
              Expanded(
                child: _StepperTile(
                  label: 'Days',
                  value: '${prefs.availableDays}',
                  onMinus: prefs.availableDays > 1
                      ? () => onUpdate(
                            prefs.copyWith(availableDays: prefs.availableDays - 1),
                          )
                      : null,
                  onPlus: prefs.availableDays < 7
                      ? () => onUpdate(
                            prefs.copyWith(availableDays: prefs.availableDays + 1),
                          )
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StepperTile(
                  label: 'Travelers',
                  value: '${prefs.groupSize}',
                  onMinus: prefs.groupSize > 1
                      ? () => onUpdate(prefs.copyWith(groupSize: prefs.groupSize - 1))
                      : null,
                  onPlus: prefs.groupSize < 20
                      ? () => onUpdate(prefs.copyWith(groupSize: prefs.groupSize + 1))
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Budget Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Budget (${prefs.budgetScope == 'totalGroup' ? 'Total group' : 'Per person'})', style: textTheme.bodySmall),
              Text(
                '₱${(prefs.budgetAmount ?? 2500).round()}',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: AppTypography.tabularFigures,
                ),
              ),
            ],
          ),
          Slider(
            value: (prefs.budgetAmount ?? 2500).clamp(300, 15000),
            min: 300,
            max: 15000,
            divisions: 29,
            activeColor: AppColors.terracotta,
            onChanged: (v) => onUpdate(prefs.copyWith(budgetAmount: v.roundToDouble())),
          ),

          // Scenery chips
          Text('Scenery', style: textTheme.labelMedium),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final (code, label) in sceneryOptions)
                FilterChip(
                  label: Text(label),
                  selected: prefs.preferredScenery.contains(code),
                  selectedColor: AppColors.skyBlueWash,
                  checkmarkColor: AppColors.deepForest,
                  onSelected: (selected) {
                    final next = [...prefs.preferredScenery];
                    if (selected) {
                      next.add(code);
                    } else {
                      next.remove(code);
                    }
                    onUpdate(prefs.copyWith(preferredScenery: next));
                  },
                ),
            ],
          ),

          if (categories.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Categories', style: textTheme.labelMedium),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final cat in categories)
                  FilterChip(
                    label: Text(cat.name as String),
                    selected: prefs.categories.contains(cat.categoryCode),
                    selectedColor: AppColors.skyBlueWash,
                    checkmarkColor: AppColors.deepForest,
                    onSelected: (selected) {
                      final next = [...prefs.categories];
                      final code = cat.categoryCode as String;
                      if (selected) {
                        next.add(code);
                      } else {
                        next.remove(code);
                      }
                      onUpdate(prefs.copyWith(categories: next));
                    },
                  ),
              ],
            ),
          ],

          const SizedBox(height: 12),
          // Transport mode segmented chips
          Text('Transport mode', style: textTheme.labelMedium),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (final (val, label) in const [
                ('motorcycle', 'Motorcycle'),
                ('privateCar', 'Private car'),
                ('publicCommute', 'Public commute'),
              ])
                ChoiceChip(
                  label: Text(label),
                  selected: prefs.transportMode == val,
                  selectedColor: AppColors.skyBlueWash,
                  onSelected: (_) => onUpdate(prefs.copyWith(transportMode: val)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onFindPlaces,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.deepForest,
                side: const BorderSide(color: AppColors.deepForest),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: const ContinuousRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(18)),
                ),
              ),
              icon: isLoading
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(CupertinoIcons.compass, size: 16),
              label: const Text('Find matching places'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperTile extends StatelessWidget {
  const _StepperTile({
    required this.label,
    required this.value,
    this.onMinus,
    this.onPlus,
  });

  final String label;
  final String value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.warmSand.withValues(alpha: 0.6),
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        border: Border.all(color: AppColors.hairline, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: textTheme.labelSmall?.copyWith(color: AppColors.mutedForest)),
                Text(
                  value,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: AppTypography.tabularFigures,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onMinus,
            icon: const Icon(CupertinoIcons.minus_circle, size: 18),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onPlus,
            icon: const Icon(CupertinoIcons.plus_circle, size: 18),
          ),
        ],
      ),
    );
  }
}

class _RecommendationsSection extends StatelessWidget {
  const _RecommendationsSection({
    required this.response,
    required this.lockedIds,
    required this.onToggleStop,
    required this.onApplyRelaxation,
  });

  final RecommendationResponse response;
  final List<int> lockedIds;
  final ValueChanged<int> onToggleStop;
  final ValueChanged<Map<String, dynamic>> onApplyRelaxation;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final pct = (response.dispersalSummary.lesserKnownRatio * 100).round();

    if (response.items.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No verified matches found', style: textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(
              'Adjust one constraint below to widen matching places.',
              style: textTheme.bodySmall?.copyWith(color: AppColors.mutedForest),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final suggestion in response.relaxationSuggestions)
                  FilledButton(
                    onPressed: () => onApplyRelaxation(suggestion.patch),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.terracotta,
                      foregroundColor: AppColors.ivorySand,
                    ),
                    child: Text(suggestion.label),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Matching places (${response.items.length})',
          style: textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          '${response.dispersalSummary.lesserKnownCount} of ${response.dispersalSummary.totalCount} suggested stops are community or lesser-known places ($pct%).',
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.mutedForest,
            fontFeatures: AppTypography.tabularFigures,
          ),
        ),
        const SizedBox(height: 12),
        for (final stop in response.items) ...[
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: const ShapeDecoration(
                        color: AppColors.skyBlueWash,
                        shape: StadiumBorder(),
                      ),
                      child: Text(
                        '${stop.matchPercentage}% match',
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.deepForest,
                          fontWeight: FontWeight.w700,
                          fontFeatures: AppTypography.tabularFigures,
                        ),
                      ),
                    ),
                    if (stop.isLesserKnown) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: ShapeDecoration(
                          color: AppColors.terracottaWash,
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          'Hidden gem',
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.terracotta,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    IconButton(
                      tooltip: lockedIds.contains(stop.id)
                          ? 'Remove stop'
                          : 'Include stop',
                      onPressed: () => onToggleStop(stop.id),
                      icon: Icon(
                        lockedIds.contains(stop.id)
                            ? CupertinoIcons.checkmark_circle_fill
                            : CupertinoIcons.plus_circle,
                        color: lockedIds.contains(stop.id)
                            ? AppColors.terracotta
                            : AppColors.deepForest,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () => context.push('${AppRoutes.destinationDetail}/${stop.slug}'),
                  child: Text(
                    stop.name,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${stop.lguName} · ${stop.entryLabel} · ${stop.estimatedTravelMinutes} mins away · ~${stop.recommendedDurationMinutes} mins',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedForest,
                    fontFeatures: AppTypography.tabularFigures,
                  ),
                ),
                if (stop.explanationReasons.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final reason in stop.explanationReasons.take(2))
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warmSand.withValues(alpha: 0.7),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(10),
                            ),
                          ),
                          child: Text(
                            reason,
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.deepForest,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
