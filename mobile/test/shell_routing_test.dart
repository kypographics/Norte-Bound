import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norte_bound/app.dart';
import 'package:norte_bound/core/router/app_router.dart';
import 'package:norte_bound/core/router/app_routes.dart';
import 'package:norte_bound/features/auth/domain/models/user.dart';
import 'package:norte_bound/features/auth/presentation/auth_providers.dart';

import 'support/fake_auth_notifier.dart';

Widget _app(User user) {
  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith(() => FixedAuthNotifier(user)),
    ],
    child: const NorteBoundApp(),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('tourist shell exposes the four traveler destinations', (
    tester,
  ) async {
    await tester.pumpWidget(_app(testTourist));
    await tester.pumpAndSettle();

    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('AI Co-Pilot'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Curator'), findsNothing);
  });

  testWidgets('admin shell exposes the curator destination', (tester) async {
    await tester.pumpWidget(_app(testAdmin));
    await tester.pumpAndSettle();

    expect(find.text('Curator'), findsOneWidget);
  });

  testWidgets('tourists are redirected away from the curator route', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(() => FixedAuthNotifier(testTourist)),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const NorteBoundApp(),
      ),
    );
    await tester.pumpAndSettle();

    container.read(appRouterProvider).go(AppRoutes.admin);
    await tester.pumpAndSettle();

    expect(find.text('Find your\nnorth.'), findsOneWidget);
    expect(find.text('Curator studio.'), findsNothing);
  });

  testWidgets('admins can open the curator destination', (tester) async {
    final container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(() => FixedAuthNotifier(testAdmin)),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const NorteBoundApp(),
      ),
    );
    await tester.pumpAndSettle();

    container.read(appRouterProvider).go(AppRoutes.admin);
    await tester.pumpAndSettle();

    expect(find.text('Curator studio.'), findsOneWidget);
    expect(
      find.text(
        'Manage destination records, verification status, and verified '
        'metadata across all 22 LGUs of Ilocos Norte.',
      ),
      findsOneWidget,
    );
  });
}
