import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norte_bound/core/theme/app_theme.dart';
import 'package:norte_bound/features/auth/presentation/auth_providers.dart';
import 'package:norte_bound/features/discovery/presentation/discovery_providers.dart';
import 'package:norte_bound/features/itinerary/presentation/itinerary_screen.dart';
import 'package:norte_bound/features/map/presentation/itinerary_map_screen.dart';
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
  Future<int> saveItinerary({
    required String title,
    required GeneratedItinerary itinerary,
    required TripPreferenceInput preferences,
  }) async => 42;

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
    tester.view.physicalSize = const Size(900, 1700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
    expect(
      find.text(
        'No saved itinerary plans yet. Build an itinerary and tap "Save plan" to keep it here.',
      ),
      findsOneWidget,
    );

    await tester.enterText(
      find.byType(TextField),
      '2-day coastal trip near Pagudpud under 2500',
    );
    await tester.ensureVisible(find.text('Extract trip details'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Extract trip details'));
    await tester.pumpAndSettle();

    expect(find.text('Confirm extracted trip details'), findsOneWidget);
    expect(find.text('REVIEW BEFORE SCORING'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Budget options'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Per person'), findsOneWidget);
    expect(find.text('Total group'), findsOneWidget);
    expect(find.text('Budget'), findsOneWidget);
    expect(find.text('Moderate'), findsOneWidget);
    expect(find.text('Flexible'), findsOneWidget);
    await tester.tap(find.text('Total group'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('₱5,000'));
    await tester.pumpAndSettle();
    expect(find.text('2d · ₱5000 total'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Find matching places'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -240));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Find matching places'));
    await tester.pumpAndSettle();

    expect(find.text('Overnight stay (Day 2+ base)'), findsOneWidget);
    expect(find.text('Find matching places (2)'), findsOneWidget);

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

    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Save plan'), findsOneWidget);
    await tester.tap(find.text('Save plan'));
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsNWidgets(2));
    expect(find.text('Itinerary saved to your account.'), findsOneWidget);
    expect(find.text('View saved'), findsOneWidget);

    await tester.tap(find.text('Adjust plan'));
    await tester.pumpAndSettle();
    expect(find.text('Per person'), findsOneWidget);
    expect(find.text('Total group'), findsOneWidget);
    expect(find.text('₱5,000'), findsOneWidget);

    Navigator.pop(tester.element(find.text('Recalculate plan')));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Lock stop'), findsOneWidget);
    await tester.tap(find.text('Share / Split'));
    await tester.pumpAndSettle();
    expect(find.text('Share & Group Split'), findsOneWidget);
    expect(find.text('Copy summary'), findsOneWidget);
  });

  testWidgets('planner renders removable chips for draft stops added by name', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(
          () => FixedAuthNotifier(testTourist),
        ),
        lgusProvider.overrideWith((ref) async => fakeLguDirectory),
        taxonomyProvider.overrideWith((ref) async => fakeTaxonomy),
        plannerRepositoryProvider.overrideWithValue(_FakePlannerRepository()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authNotifierProvider.future);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const PlannerScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    container
        .read(plannerProvider.notifier)
        .addDestinationToDraft(7, name: 'Anuplig Falls');
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Included stops'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Included stops'), findsOneWidget);
    expect(find.text('Anuplig Falls'), findsOneWidget);

    await tester.ensureVisible(find.widgetWithText(InputChip, 'Anuplig Falls'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(InputChip, 'Anuplig Falls'),
        matching: find.byType(Icon),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Included stops'), findsNothing);
    expect(container.read(plannerProvider).preferences.lockedDestinationIds, isEmpty);
  });

  testWidgets('autoRouteNearestToFurthest and ItineraryMapScreen adjust route nearest to furthest', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(
          () => FixedAuthNotifier(testTourist),
        ),
        plannerRepositoryProvider.overrideWithValue(_TwoStopFakeRepo()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(plannerProvider.notifier).buildItinerary();
    final before = container.read(plannerProvider).itinerary!.days.first.stops;
    expect(before.map((s) => s.name), ['Far Falls', 'Near Pottery']);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ItineraryMapScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nearest → Furthest'), findsOneWidget);
    expect(find.text('Far Falls'), findsOneWidget);
    expect(find.text('Near Pottery'), findsOneWidget);

    await tester.tap(find.text('Nearest → Furthest'));
    await tester.pumpAndSettle();

    final afterAuto = container.read(plannerProvider).itinerary!.days.first.stops;
    expect(afterAuto.map((s) => s.name), ['Near Pottery', 'Far Falls']);

    container.read(plannerProvider.notifier).moveStopInDay(0, 0, 1);
    final afterManual = container.read(plannerProvider).itinerary!.days.first.stops;
    expect(afterManual.map((s) => s.name), ['Far Falls', 'Near Pottery']);
  });

  testWidgets('Start route switches to navigation HUD showing next destination, distance, ETA, and traffic', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(
          () => FixedAuthNotifier(testTourist),
        ),
        plannerRepositoryProvider.overrideWithValue(_TwoStopFakeRepo()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(plannerProvider.notifier).buildItinerary();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ItineraryMapScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Start route'), findsOneWidget);
    await tester.tap(find.text('Start route'));
    await tester.pumpAndSettle();

    expect(find.text('NEXT DESTINATION · STOP 1 OF 2'), findsOneWidget);
    expect(find.text('64.5 km'), findsOneWidget);
    expect(find.text('ETA'), findsOneWidget);
    expect(find.text('TRAFFIC'), findsOneWidget);
    expect(find.text('Light traffic'), findsOneWidget);

    await tester.tap(find.text('Arrived · Next stop'));
    await tester.pumpAndSettle();

    expect(find.text('NEXT DESTINATION · STOP 2 OF 2'), findsOneWidget);
    expect(find.text('Finish route'), findsOneWidget);

    await tester.tap(find.text('Finish route'));
    await tester.pumpAndSettle();
    expect(container.read(plannerProvider).isNavigating, isFalse);
  });

  testWidgets('planner origin picker supports locations across the Philippines', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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

    await tester.tap(find.text('Change origin'));
    await tester.pumpAndSettle();

    expect(find.text('ACROSS THE PHILIPPINES'), findsOneWidget);
    expect(find.text('Metro Manila'), findsOneWidget);

    await tester.tap(find.text('Metro Manila'));
    await tester.pumpAndSettle();

    expect(find.text('Starting from Metro Manila'), findsOneWidget);
  });
}

class _TwoStopFakeRepo extends _FakePlannerRepository {
  @override
  Future<GeneratedItinerary> generateItinerary(TripPreferenceInput input) async {
    return const GeneratedItinerary(
      originName: 'Laoag City',
      originLatitude: 18.1978,
      originLongitude: 120.5936,
      totalDays: 1,
      totalStops: 2,
      totalDistanceKm: 95,
      totalTravelMinutes: 90,
      totalVisitMinutes: 120,
      recalculationTimeMs: 12,
      lesserKnownCount: 1,
      lesserKnownRatio: 0.5,
      expenseBreakdown: ItineraryExpenseBreakdown(
        entranceAndActivityCost: 50,
        parkingCost: 0,
        mealsCost: 0,
        transportCost: 300,
        totalEstimatedCost: 350,
        budgetAmount: 2500,
        remainingBudget: 2150,
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
          endTime: '12:00',
          stops: [
            ItineraryStopItem(
              sequenceOrder: 1,
              destinationId: 7,
              slug: 'far-falls',
              name: 'Far Falls',
              lguCode: 'adams',
              lguName: 'Adams',
              categoryCode: 'natural_attraction',
              categoryName: 'Natural Attraction',
              popularityTier: 'hidden_gem',
              isCommunityBased: true,
              isLesserKnown: true,
              startTime: '09:10',
              endTime: '10:10',
              estimatedDurationMinutes: 60,
              travelTimeFromPrevMinutes: 70,
              distanceFromPrevKm: 64.5,
              legTransportCostPhp: 225,
              entryCostPhp: 50,
              estimatedMealCostPhp: 0,
              operatingWindowLabel: 'Open 24 hours',
              isOpenCompliant: true,
              latitude: 18.46,
              longitude: 120.90,
            ),
            ItineraryStopItem(
              sequenceOrder: 2,
              destinationId: 28,
              slug: 'near-pottery',
              name: 'Near Pottery',
              lguCode: 'san-nicolas',
              lguName: 'San Nicolas',
              categoryCode: 'artisan_craft_experience',
              categoryName: 'Artisan & Craft',
              popularityTier: 'hidden_gem',
              isCommunityBased: true,
              isLesserKnown: true,
              startTime: '10:40',
              endTime: '11:40',
              estimatedDurationMinutes: 60,
              travelTimeFromPrevMinutes: 30,
              distanceFromPrevKm: 30.5,
              legTransportCostPhp: 75,
              entryCostPhp: 0,
              estimatedMealCostPhp: 0,
              operatingWindowLabel: 'Open 08:00–17:00',
              isOpenCompliant: true,
              latitude: 18.21,
              longitude: 120.60,
            ),
          ],
        ),
      ],
    );
  }
}
