import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norte_bound/core/theme/app_theme.dart';
import 'package:norte_bound/features/auth/presentation/auth_providers.dart';
import 'package:norte_bound/features/discovery/presentation/discovery_providers.dart';
import 'package:norte_bound/features/discovery/presentation/screens/discovery_screen.dart';

import '../../support/fake_auth_notifier.dart';
import '../../support/fake_discovery.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets(
    'discovery renders circuit, gem, iconic, LGU, and food sections',
    (tester) async {
      await _pumpDiscovery(tester);

      expect(find.text('NORTE BOUND'), findsOneWidget);
      expect(find.text('Find your\nnorth.'), findsOneWidget);
      expect(find.text('Explore by circuit'), findsOneWidget);
      expect(find.text('Hidden gems'), findsOneWidget);
      expect(find.text('Kaangrian Falls'), findsOneWidget);
      expect(find.text('Iconic landmarks'), findsOneWidget);
      expect(find.text('Paoay Church'), findsOneWidget);
      expect(find.text('5 LGUs.\nOne northern coast.'), findsOneWidget);
      expect(find.text('Taste the north'), findsOneWidget);
      expect(find.text('Batac Riverside Empanada'), findsOneWidget);
    },
  );

  testWidgets('LGU directory card opens the cluster browser', (tester) async {
    await _pumpDiscovery(tester);

    await tester.scrollUntilVisible(
      find.text('Browse the directory'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Browse the directory'));
    await tester.pumpAndSettle();

    expect(find.text('Browse by LGU'), findsOneWidget);
    expect(find.text('Adams'), findsOneWidget);
    expect(find.text('Northern Coast'), findsWidgets);
  });
}

Future<void> _pumpDiscovery(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(() => FixedAuthNotifier(testTourist)),
        lgusProvider.overrideWith((ref) async => fakeLguDirectory),
        taxonomyProvider.overrideWith((ref) async => fakeTaxonomy),
        exploreFeedProvider.overrideWith((ref) async => fakeExploreFeed),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const DiscoveryScreen()),
    ),
  );
  await tester.pumpAndSettle();
}
