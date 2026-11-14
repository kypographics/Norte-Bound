import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norte_bound/app.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('app renders the discovery foundation', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: NorteBoundApp()));
    await tester.pumpAndSettle();

    expect(find.text('NORTE BOUND'), findsOneWidget);
    expect(find.text('Find your\nnorth.'), findsOneWidget);
    expect(find.text('CONTEXT-AWARE PLANNING'), findsOneWidget);
  });
}
