import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:norte_bound/core/router/app_routes.dart';
import 'package:norte_bound/core/theme/app_theme.dart';
import 'package:norte_bound/features/discovery/domain/destination_detail.dart';
import 'package:norte_bound/features/discovery/domain/destination_summary.dart';
import 'package:norte_bound/features/discovery/presentation/discovery_providers.dart';
import 'package:norte_bound/features/discovery/presentation/screens/destination_detail_screen.dart';

void main() {
  DestinationDetail buildSampleDetail({String popularityTier = 'hidden_gem'}) {
    return DestinationDetail(
      id: 7,
      slug: 'anuplig-falls',
      name: 'Anuplig Falls',
      lguCode: 'adams',
      lguName: 'Adams',
      tourismCluster: 'northern_coast',
      categoryCode: 'natural_attraction',
      categoryName: 'Natural Attraction',
      description: 'A serene cascade nestled in the Adams rainforest.',
      historicalBackground:
          'Stewarded by the Adams community as an eco-heritage sanctuary.',
      address: 'Sitio Anuplig, Adams, Ilocos Norte',
      entityType: 'attraction',
      popularityTier: popularityTier,
      highwayAccessible: false,
      roadCondition: 'paved_feeder',
      verification: const DestinationVerificationInfo(
        status: 'verified',
        sourceName: 'Adams Municipal Tourism Office',
        sourceType: 'official_registry',
        lastVerifiedDate: '2026-10-15',
      ),
      pricing: const DestinationDetailPricing(
        isFree: false,
        entranceFeeAdult: 50,
        entranceFeeConcession: 35,
        mandatoryActivityFee: 150,
        estimatedMealMin: 120,
        estimatedMealMax: 280,
        parkingFee: 20,
      ),
      operatingHours: List.generate(
        7,
        (day) => DestinationOperatingHour(
          dayOfWeek: day,
          dayName: const [
            'Sunday',
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday',
          ][day],
          openingTime: '00:00',
          closingTime: '23:59',
          is24Hours: true,
          temporarilyClosed: false,
        ),
      ),
      tags: const [
        DestinationTagRef(slug: 'waterfall', name: 'Waterfall'),
        DestinationTagRef(slug: 'eco-trek', name: 'Eco Trek'),
      ],
    );
  }

  testWidgets('renders editorial pills, attribution, itemized pricing, schedule, and CTA', (
    tester,
  ) async {
    final detail = buildSampleDetail();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          destinationDetailProvider('anuplig-falls').overrideWith(
            (ref) async => detail,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const DestinationDetailScreen(slug: 'anuplig-falls'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Editorial header & pills
    expect(find.text('Anuplig Falls'), findsOneWidget);
    expect(find.text('ADAMS'), findsOneWidget);
    expect(find.text('NATURAL ATTRACTION'), findsOneWidget);
    expect(find.text('HIDDEN GEM'), findsOneWidget);

    // Verification & Source Attribution Card
    expect(find.text('Verified Source Attribution'), findsOneWidget);
    expect(find.text('Adams Municipal Tourism Office'), findsOneWidget);
    expect(find.text('Official Registry'), findsOneWidget);
    expect(find.text('2026-10-15'), findsOneWidget);

    // Itemized Financial Breakdown
    await tester.scrollUntilVisible(
      find.text('Itemized Financial Breakdown'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Itemized Financial Breakdown'), findsOneWidget);
    expect(find.text('Adult Entrance Fee'), findsOneWidget);
    expect(find.text('₱50'), findsOneWidget);
    expect(find.text('Student / Senior Concession'), findsOneWidget);
    expect(find.text('₱35'), findsOneWidget);
    expect(find.text('Mandatory Activity / Guide Fee'), findsOneWidget);
    expect(find.text('₱150'), findsOneWidget);
    expect(find.text('Parking Fee'), findsOneWidget);
    expect(find.text('₱20'), findsOneWidget);
    expect(find.text('Estimated Meal Range'), findsOneWidget);
    expect(find.text('₱120–280'), findsOneWidget);

    // Historical & Cultural Significance
    await tester.scrollUntilVisible(
      find.text('Historical & Cultural Significance'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Historical & Cultural Significance'), findsOneWidget);
    expect(
      find.text('Stewarded by the Adams community as an eco-heritage sanctuary.'),
      findsOneWidget,
    );

    // 7-Day Operating Schedule & Live Status
    await tester.scrollUntilVisible(
      find.text('7-Day Operating Schedule'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('7-Day Operating Schedule'), findsOneWidget);
    expect(find.text('OPEN NOW'), findsOneWidget);

    // Sticky Bottom Bar CTA
    expect(find.text('Add to Itinerary'), findsOneWidget);
    expect(find.text('₱50/pax'), findsOneWidget);

    await tester.tap(find.text('Add to Itinerary'));
    await tester.pump();
    expect(
      find.text('Added Anuplig Falls to active itinerary draft!'),
      findsOneWidget,
    );
  });

  testWidgets('renders Iconic Hub pill when popularityTier is iconic_hub', (
    tester,
  ) async {
    final detail = buildSampleDetail(popularityTier: 'iconic_hub');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          destinationDetailProvider('anuplig-falls').overrideWith(
            (ref) async => detail,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const DestinationDetailScreen(slug: 'anuplig-falls'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('ICONIC HUB'), findsOneWidget);
    expect(find.text('HIDDEN GEM'), findsNothing);
  });

  testWidgets('renders retry state when detail fails without summary fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          destinationDetailProvider('missing-stop').overrideWith(
            (ref) => Future<DestinationDetail>.error(
              Exception('Destination not found'),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const DestinationDetailScreen(slug: 'missing-stop'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Could not load full profile'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('Plan snackbar action navigates safely after detail screen pops', (
    tester,
  ) async {
    final detail = buildSampleDetail();
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => context.push('/detail'),
                child: const Text('Open detail'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/detail',
          builder: (context, state) =>
              const DestinationDetailScreen(slug: 'anuplig-falls'),
        ),
        GoRoute(
          path: AppRoutes.planner,
          builder: (context, state) =>
              const Scaffold(body: Text('Planner Target')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          destinationDetailProvider('anuplig-falls').overrideWith(
            (ref) async => detail,
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open detail'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add to Itinerary'));
    await tester.pump();
    expect(find.text('Plan'), findsOneWidget);

    await tester.tap(find.byTooltip('Back to discovery'));
    await tester.pumpAndSettle();
    expect(find.text('Open detail'), findsOneWidget);

    await tester.tap(find.text('Plan'));
    await tester.pumpAndSettle();
    expect(find.text('Planner Target'), findsOneWidget);
  });
}
