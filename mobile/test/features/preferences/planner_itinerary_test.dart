import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norte_bound/core/theme/app_theme.dart';
import 'package:norte_bound/features/auth/presentation/auth_providers.dart';
import 'package:norte_bound/features/discovery/presentation/discovery_providers.dart';
import 'package:norte_bound/features/itinerary/presentation/itinerary_screen.dart';
import 'package:norte_bound/features/preferences/data/planner_repository.dart';
import 'package:norte_bound/features/preferences/domain/trip_plan_models.dart';
import 'package:norte_bound/features/preferences/presentation/planner_providers.dart';
import 'package:norte_bound/features/preferences/presentation/planner_screen.dart';

import '../../support/fake_auth_notifier.dart';
import '../../support/fake_discovery.dart';

class _FakePlannerRepository extends PlannerRepository {
  _FakePlannerRepository() : super(Dio());

  @override
  Future<List<SavedItinerarySummary>> fetchSavedItineraries() async {
    return const [
      SavedItinerarySummary(
        id: 1,
        title: 'Laoag City 2-Day Plan',
        totalDays: 2,
        totalEstimatedCost: 1450,
        stopCount: 6,
      ),
    ];
  }

  @override
  Future<void> deleteSavedItinerary(int itineraryId) async {}

  @override
  Future<ParsedIntentResult> parseIntent({
    required String prompt,
    String? originLguCode,
    double? latitude,
    double? longitude,
  }) async {
    return const ParsedIntentResult(
      source: 'deterministic-rule-parser',
      originLguCode: 'laoag-city',
      requiresUserConfirmation: true,
      extractedPreferences: TripPreferenceInput(
        categories: ['natural_attraction'],
        preferredScenery: ['coastal'],
        preferredLgus: ['pagudpud', 'adams'],
        budgetAmount: 2500,
        availableDays: 2,
      ),
    );
  }

  @override
  Future<RecommendationResponse> fetchRecommendations(
    TripPreferenceInput input,
  ) async {
    return const RecommendationResponse(
      originName: 'Laoag City',
      totalMatches: 2,
      dispersalSummary: DispersalSummary(
        lesserKnownCount: 1,
        totalCount: 2,
        lesserKnownRatio: 0.5,
        meetsThirtyPercentTarget: true,
      ),
      relaxationSuggestions: [],
      items: [
        RecommendedStop(
          id: 7,
          slug: 'anuplig-falls',
          name: 'Anuplig Falls',
          lguCode: 'adams',
          lguName: 'Adams',
          tourismCluster: 'northern_coast',
          categoryCode: 'natural_attraction',
          categoryName: 'Natural Attraction',
          popularityTier: 'hidden_gem',
          isCommunityBased: true,
          isLesserKnown: true,
          recommendedDurationMinutes: 90,
          matchPercentage: 92,
          distanceKm: 64.5,
          estimatedTravelMinutes: 72,
          entryFeePhp: 50,
          isFree: false,
          explanationReasons: ['Matches Natural Attraction', 'Community spot in Adams'],
        ),
        RecommendedStop(
          id: 1,
          slug: 'pagudpud-saud-white-beach',
          name: 'Saud White Beach',
          lguCode: 'pagudpud',
          lguName: 'Pagudpud',
          tourismCluster: 'northern_coast',
          categoryCode: 'natural_attraction',
          categoryName: 'Natural Attraction',
          popularityTier: 'iconic_hub',
          isCommunityBased: false,
          isLesserKnown: false,
          recommendedDurationMinutes: 150,
          matchPercentage: 84,
          distanceKm: 58.2,
          estimatedTravelMinutes: 65,
          entryFeePhp: 0,
          isFree: true,
          explanationReasons: ['Open 24 hours', 'Free entry'],
        ),
      ],
    );
  }

  @override
  Future<GeneratedItinerary> generateItinerary(TripPreferenceInput input) async {
    return const GeneratedItinerary(
      originName: 'Laoag City',
      originLatitude: 18.1978,
      originLongitude: 120.5936,
      totalDays: 1,
      totalStops: 2,
      totalDistanceKm: 64.5,
      totalTravelMinutes: 72,
      totalVisitMinutes: 150,
      recalculationTimeMs: 18,
      lesserKnownCount: 1,
      lesserKnownRatio: 0.5,
      expenseBreakdown: ItineraryExpenseBreakdown(
        entranceAndActivityCost: 50,
        parkingCost: 20,
        mealsCost: 220,
        transportCost: 225,
        totalEstimatedCost: 515,
        budgetAmount: 2500,
        remainingBudget: 1985,
      ),
      feasibilityReport: FeasibilityReport(
        isFeasible: true,
        timeBudgetCompliant: true,
        operatingHoursCompliant: true,
        financialBudgetCompliant: true,
        timeWindowCompliant: true,
        routesCalculable: true,
        violatedConstraints: [],
      ),
      days: [
        ItineraryDayPlan(
          dayNumber: 1,
          dayOfWeek: 1,
          startTime: '08:00',
          endTime: '13:30',
          stops: [
            ItineraryStopItem(
              sequenceOrder: 1,
              destinationId: 7,
              slug: 'anuplig-falls',
              name: 'Anuplig Falls',
              lguCode: 'adams',
              lguName: 'Adams',
              categoryCode: 'natural_attraction',
              categoryName: 'Natural Attraction',
              popularityTier: 'hidden_gem',
              isCommunityBased: true,
              isLesserKnown: true,
              startTime: '09:12',
              endTime: '10:42',
              estimatedDurationMinutes: 90,
              travelTimeFromPrevMinutes: 72,
              distanceFromPrevKm: 64.5,
              legTransportCostPhp: 225,
              entryCostPhp: 70,
              estimatedMealCostPhp: 0,
              operatingWindowLabel: 'Open 24 hours',
              isOpenCompliant: true,
              latitude: 18.46,
              longitude: 120.90,
            ),
          ],
        ),
      ],
    );
  }
}

void main() {
  testWidgets('planner extracts intent, confirms constraints, and renders explainable recommendations', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(
            () => FixedAuthNotifier(testTourist),
          ),
          lgusProvider.overrideWith((ref) async => fakeLguDirectory),
          taxonomyProvider.overrideWith((ref) async => fakeTaxonomy),
          plannerRepositoryProvider.overrideWithValue(_FakePlannerRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const PlannerScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Plan your north.'), findsOneWidget);
    expect(find.text('Starting from Laoag City'), findsOneWidget);
    expect(find.text('Saved plans'), findsOneWidget);
    expect(find.text('Laoag City 2-Day Plan'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete saved plan'));
    await tester.pumpAndSettle();
    expect(find.text('Laoag City 2-Day Plan'), findsNothing);

    await tester.enterText(
      find.byType(TextField),
      '2-day coastal trip near Pagudpud under 2500',
    );
    await tester.tap(find.text('Extract trip details'));
    await tester.pumpAndSettle();

    expect(find.text('Confirm extracted trip details'), findsOneWidget);
    expect(find.text('REVIEW BEFORE SCORING'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Find matching places'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -240));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Find matching places'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Anuplig Falls'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -180));
    await tester.pumpAndSettle();
    expect(find.text('Anuplig Falls'), findsOneWidget);
    expect(find.text('92% match'), findsOneWidget);
    expect(find.text('Hidden gem'), findsOneWidget);
    expect(
      find.text('1 of 2 suggested stops are community or lesser-known places (50%).'),
      findsOneWidget,
    );
  });

  testWidgets('itinerary screen renders 5-condition feasibility banner, expense breakdown, and timeline', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(
          () => FixedAuthNotifier(testTourist),
        ),
        plannerRepositoryProvider.overrideWithValue(_FakePlannerRepository()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(plannerProvider.notifier).buildItinerary();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ItineraryScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Feasible plan · 5 of 5 checks passed'), findsOneWidget);
    expect(find.text('18 ms'), findsOneWidget);
    expect(find.text('₱515 of ₱2500'), findsOneWidget);
    expect(find.text('Anuplig Falls'), findsOneWidget);
    expect(find.text('09:12 – 10:42'), findsOneWidget);
  });
}
