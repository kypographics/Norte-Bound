import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norte_bound/app.dart';
import 'package:norte_bound/features/auth/domain/models/user.dart';
import 'package:norte_bound/features/auth/presentation/auth_providers.dart';

class _AuthenticatedAuthNotifier extends AuthNotifier {
  @override
  Future<User?> build() async {
    return const User(
      id: 1,
      email: 'traveler@example.com',
      fullName: 'Maria Santos',
      role: UserRole.tourist,
    );
  }
}

class _SignedOutAuthNotifier extends AuthNotifier {
  @override
  Future<User?> build() async => null;
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('authenticated app renders the discovery foundation', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_AuthenticatedAuthNotifier.new),
        ],
        child: const NorteBoundApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NORTE BOUND'), findsOneWidget);
    expect(find.text('Find your\nnorth.'), findsOneWidget);
    expect(find.text('CONTEXT-AWARE PLANNING'), findsOneWidget);
  });

  testWidgets('unauthenticated app renders the login screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_SignedOutAuthNotifier.new),
        ],
        child: const NorteBoundApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome back.'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
