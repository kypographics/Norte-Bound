import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norte_bound/core/theme/app_theme.dart';
import 'package:norte_bound/features/auth/domain/models/user.dart';
import 'package:norte_bound/features/auth/presentation/auth_providers.dart';
import 'package:norte_bound/features/auth/presentation/profile_screen.dart';
import 'package:norte_bound/features/discovery/presentation/discovery_providers.dart';
import 'package:norte_bound/features/preferences/data/planner_repository.dart';
import 'package:norte_bound/features/preferences/domain/trip_plan_models.dart';
import 'package:norte_bound/features/preferences/presentation/planner_providers.dart';

import '../../support/fake_auth_notifier.dart';
import '../../support/fake_discovery.dart';

class _FakeProfilePlannerRepository extends PlannerRepository {
  _FakeProfilePlannerRepository() : super(Dio());

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
}

Widget _wrap(User user) {
  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith(() => FixedAuthNotifier(user)),
      lgusProvider.overrideWith((ref) async => fakeLguDirectory),
      plannerRepositoryProvider.overrideWithValue(
        _FakeProfilePlannerRepository(),
      ),
    ],
    child: MaterialApp(theme: AppTheme.light, home: const ProfileScreen()),
  );
}

Future<void> _pumpProfile(WidgetTester tester, User user) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(_wrap(user));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('profile renders identity and saved travel defaults', (
    tester,
  ) async {
    await _pumpProfile(tester, testTourist);

    expect(find.text('Your profile.'), findsOneWidget);
    expect(find.text('Maria Santos'), findsOneWidget);
    expect(find.text('traveler@example.com'), findsOneWidget);
    expect(find.text('TOURIST'), findsOneWidget);
    expect(find.text('Saved plans'), findsOneWidget);
    expect(find.text('Laoag City 2-Day Plan'), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('22-LGU Stamp Passport'), findsOneWidget);
    expect(find.text('0 / 22 LGUs explored'), findsOneWidget);
    await tester.ensureVisible(find.text('Travel baseline'));
    await tester.pumpAndSettle();
    expect(find.text('Travel baseline'), findsOneWidget);
    expect(find.text('Private car'), findsOneWidget);
    expect(find.text('Total group'), findsOneWidget);
    expect(find.text('Relaxed'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    await tester.ensureVisible(find.text('Sign Out'));
    await tester.pumpAndSettle();
    expect(find.text('Change password'), findsOneWidget);
    expect(find.text('Sign Out'), findsOneWidget);
  });

  testWidgets('profile can remove a saved itinerary plan', (tester) async {
    await _pumpProfile(tester, testTourist);

    expect(find.text('Laoag City 2-Day Plan'), findsOneWidget);
    await tester.tap(find.byTooltip('Delete saved plan'));
    await tester.pumpAndSettle();

    expect(find.text('Laoag City 2-Day Plan'), findsNothing);
    expect(
      find.text(
        'No saved plans yet. Build an itinerary and tap "Save plan" to keep it here.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('profile group size stepper updates locally', (tester) async {
    await _pumpProfile(tester, testTourist);

    await tester.ensureVisible(find.byTooltip('Increase group size'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Increase group size'));
    await tester.pumpAndSettle();

    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('profile opens the name editor sheet', (tester) async {
    await _pumpProfile(tester, testTourist);

    await tester.tap(find.byTooltip('Edit name'));
    await tester.pumpAndSettle();

    expect(find.text('Edit name'), findsOneWidget);
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
  });

  testWidgets('profile confirms sign out before clearing the session', (
    tester,
  ) async {
    await _pumpProfile(tester, testTourist);

    await tester.ensureVisible(find.text('End this session on this device.'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('End this session on this device.'));
    await tester.pumpAndSettle();

    expect(find.text('Sign out?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Sign out?'), findsNothing);
    expect(find.text('Maria Santos'), findsOneWidget);
  });

  testWidgets('admin profile renders the curator role', (tester) async {
    await _pumpProfile(tester, testAdmin);

    expect(find.text('CURATOR ADMIN'), findsOneWidget);
    expect(find.text('Curator Console'), findsOneWidget);
    expect(find.text('TOURIST'), findsNothing);
  });
}
