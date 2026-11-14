import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norte_bound/core/theme/app_theme.dart';
import 'package:norte_bound/features/discovery/domain/destination_filter.dart';
import 'package:norte_bound/features/discovery/domain/destination_summary.dart';
import 'package:norte_bound/features/discovery/presentation/discovery_providers.dart';
import 'package:norte_bound/features/discovery/presentation/screens/search_screen.dart';

import '../../support/fake_discovery.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('search renders verified results from the repository provider', (
    tester,
  ) async {
    final container = await _pumpSearch(tester, fakeDestinationPage);
    addTearDown(container.dispose);

    expect(find.text('Find the right place.'), findsOneWidget);
    expect(find.text('3 verified places'), findsOneWidget);
    expect(find.text('Kaangrian Falls'), findsOneWidget);
    expect(find.text('Paoay Church'), findsOneWidget);
    expect(find.text('Batac Riverside Empanada'), findsOneWidget);
  });

  testWidgets('search debounces queries and toggles filter state', (
    tester,
  ) async {
    final container = await _pumpSearch(tester, fakeDestinationPage);
    addTearDown(container.dispose);

    await tester.enterText(find.byType(TextField), 'paoay');
    await tester.pump(const Duration(milliseconds: 350));

    expect(container.read(searchFilterProvider).query, 'paoay');

    await tester.tap(find.text('Free entry'));
    await tester.pumpAndSettle();

    expect(container.read(searchFilterProvider).isFree, isTrue);
    expect(find.text('2 active filters'), findsOneWidget);
  });

  testWidgets('search category sheet applies a taxonomy filter', (
    tester,
  ) async {
    final container = await _pumpSearch(tester, fakeDestinationPage);
    addTearDown(container.dispose);

    await tester.tap(find.text('Category'));
    await tester.pumpAndSettle();

    expect(find.text('Filter by category'), findsOneWidget);
    expect(find.text('Food & Culinary'), findsOneWidget);

    await tester.tap(find.text('Food & Culinary'));
    await tester.pumpAndSettle();

    expect(container.read(searchFilterProvider).categoryCode, 'food_culinary');
  });

  testWidgets('search empty state clears active filters', (tester) async {
    final container = await _pumpSearch(tester, emptyDestinationPage);
    addTearDown(container.dispose);

    await tester.tap(find.text('Free entry'));
    await tester.pumpAndSettle();

    expect(find.text('No places match this trail.'), findsOneWidget);
    expect(find.text('Clear filters'), findsOneWidget);

    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();

    expect(container.read(searchFilterProvider), const DestinationFilter());
    expect(find.text('No places are available yet.'), findsOneWidget);
  });
}

Future<ProviderContainer> _pumpSearch(
  WidgetTester tester,
  DestinationPage page,
) async {
  tester.view.physicalSize = const Size(900, 1700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(
    overrides: [
      lgusProvider.overrideWith((ref) async => fakeLguDirectory),
      taxonomyProvider.overrideWith((ref) async => fakeTaxonomy),
      filteredDestinationsProvider.overrideWith(
        () => FakeFilteredDestinationsNotifier(page),
      ),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: AppTheme.light, home: const SearchScreen()),
    ),
  );
  await tester.pumpAndSettle();

  return container;
}
