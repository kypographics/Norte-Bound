import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norte_bound/core/theme/app_theme.dart';
import 'package:norte_bound/features/auth/presentation/login_screen.dart';
import 'package:norte_bound/features/auth/presentation/register_screen.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(theme: AppTheme.light, home: child),
  );
}

Future<void> _tapButton(WidgetTester tester, String label) async {
  final button = find.widgetWithText(FilledButton, label);
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('login validates required credentials', (tester) async {
    await tester.pumpWidget(_wrap(const LoginScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back.'), findsOneWidget);

    await _tapButton(tester, 'Sign In');

    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
  });

  testWidgets('registration validates fields and exposes role choices', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const RegisterScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Create your account.'), findsOneWidget);
    expect(find.text('Traveler'), findsOneWidget);
    expect(find.text('Curator'), findsOneWidget);

    await _tapButton(tester, 'Create Account');

    expect(find.text('Enter your full name.'), findsOneWidget);
    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(find.text('Create a password.'), findsOneWidget);
  });

  testWidgets('registration rejects malformed input', (tester) async {
    await tester.pumpWidget(_wrap(const RegisterScreen()));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'A');
    await tester.enterText(fields.at(1), 'not-an-email');
    await tester.enterText(fields.at(2), 'short');
    await _tapButton(tester, 'Create Account');

    expect(find.text('Use at least 2 characters.'), findsOneWidget);
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Use at least 8 characters.'), findsOneWidget);
  });
}
