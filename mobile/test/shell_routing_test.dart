import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norte_bound/app.dart';
import 'package:norte_bound/features/auth/domain/models/user.dart';
import 'package:norte_bound/features/auth/presentation/auth_providers.dart';
import 'package:norte_bound/features/discovery/presentation/discovery_providers.dart';

import 'support/fake_auth_notifier.dart';
import 'support/fake_discovery.dart';

Widget _app(User user) {
  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith(() => FixedAuthNotifier(user)),
      exploreFeedProvider.overrideWith((ref) async => fakeExploreFeed),
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

  testWidgets('admin user mobile shell exposes the four traveler destinations without in-app admin tab', (tester) async {
    await tester.pumpWidget(_app(testAdmin));
    await tester.pumpAndSettle();

    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('AI Co-Pilot'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Curator'), findsNothing);
  });
}
