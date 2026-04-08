import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/features/auth/view/signup_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;

import '../../supabase_test_helper.dart';
import '../../test_support/pump_app.dart';

void main() {
  setUpAll(() async {
    ensureSupabaseTestEnvironment();
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      anonKey: 'test-anon-key',
      debug: false,
      localStorage: supabaseTestLocalStorage,
      pkceAsyncStorage: supabaseTestPkceStorage,
    );
  });

  group('SignupScreen Phase 9 — password strength & validation', () {
    testWidgets('password strength label updates from Weak to Strong', (
      tester,
    ) async {
      await pumpApp(tester, const SignupScreen());

      // Let stagger animation complete
      await tester.pump(const Duration(milliseconds: 600));

      // Type a weak password (only length < 8, no uppercase, no digit, no special)
      await tester.enterText(find.byKey(SignupScreen.passwordFieldKey), 'A');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // A single uppercase char: strength = 0.25 (has uppercase only) => Weak
      expect(find.text('Weak'), findsOneWidget);

      // Now type a strong password (length >= 8, uppercase, digit, special)
      await tester.enterText(
        find.byKey(SignupScreen.passwordFieldKey),
        'Abcd1234!',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // All four criteria met => strength = 1.0 => Strong
      expect(find.text('Strong'), findsOneWidget);
    });

    testWidgets('confirm password mismatch shows red cancel icon', (
      tester,
    ) async {
      await pumpApp(tester, const SignupScreen());

      // Let stagger animation complete
      await tester.pump(const Duration(milliseconds: 600));

      // Type a different confirm password first
      await tester.enterText(
        find.byKey(SignupScreen.confirmPasswordFieldKey),
        'DifferentPassword',
      );
      await tester.pump();

      // Now type a password — this triggers _onPasswordChanged which calls
      // setState, causing a rebuild that re-evaluates _buildConfirmSuffix
      // with the confirm controller's current text.
      await tester.enterText(
        find.byKey(SignupScreen.passwordFieldKey),
        'Abcd1234!',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // The cancel icon (red) should be present for mismatch
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets(
      'stagger animation completes and all fields visible after 600ms',
      (tester) async {
        await pumpApp(tester, const SignupScreen());

        // Advance past the stagger animation (500ms emphasis + margin)
        await tester.pump(const Duration(milliseconds: 600));

        // All form elements should be visible
        expect(find.text('Create Account'), findsAtLeastNWidgets(1));
        expect(find.byKey(SignupScreen.nameFieldKey), findsOneWidget);
        expect(find.byKey(SignupScreen.emailFieldKey), findsOneWidget);
        expect(find.byKey(SignupScreen.passwordFieldKey), findsOneWidget);
        expect(
          find.byKey(SignupScreen.confirmPasswordFieldKey),
          findsOneWidget,
        );
        expect(find.byKey(SignupScreen.signUpButtonKey), findsOneWidget);
      },
    );

    testWidgets('inline error shown on empty submit via Form validation', (
      tester,
    ) async {
      // Use a larger surface size so the button is not clipped off-screen
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpApp(tester, const SignupScreen());

      // Let stagger animation complete
      await tester.pump(const Duration(milliseconds: 600));

      // Scroll the button into view before tapping
      await tester.ensureVisible(find.byKey(SignupScreen.signUpButtonKey));
      await tester.pumpAndSettle();

      // Tap Create Account with all fields empty
      await tester.tap(find.byKey(SignupScreen.signUpButtonKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Form validators should show inline errors below fields
      expect(find.text('Please enter your name'), findsOneWidget);
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter a password'), findsOneWidget);
      expect(find.text('Please confirm your password'), findsOneWidget);
    });
  });
}
