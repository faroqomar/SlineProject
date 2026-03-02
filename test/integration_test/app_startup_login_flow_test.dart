import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/app/main_navigation_screen.dart';
import 'package:sline_app/features/auth/view/login_screen.dart';

import 'support/helpers.dart';
import 'support/preflight.dart';
import 'support/t61_t70_env.dart';

void main() {
  ensureIntegrationBinding();

  group('App Startup/Login Flow T64-T65', () {
    testWidgets(
      'T64 Cold start unauthenticated lands on login',
      (tester) async {
        const tag = 'T64';
        await launchAppForIntegration(tester, tag: tag, resetAuth: true);

        await pumpUntilFound(
          tester,
          find.byKey(LoginScreen.emailFieldKey),
          tag: tag,
          timeout: const Duration(seconds: 15),
          reason: 'Expected login screen after auth reset cold start.',
        );

        expect(find.byKey(LoginScreen.passwordFieldKey), findsOneWidget);
        expect(find.byKey(LoginScreen.signInButtonKey), findsOneWidget);
        expect(find.byKey(MainNavigationScreen.createTaskFabKey), findsNothing);
      },
      skip: T61T70Preflight.t64() != null,
    );

    testWidgets(
      'T65 Login happy path lands on main navigation',
      (tester) async {
        const tag = 'T65';
        await launchAppForIntegration(tester, tag: tag, resetAuth: true);
        await loginViaUi(
          tester,
          tag: tag,
          email: T61T70Env.loginEmail,
          password: T61T70Env.loginPassword,
        );

        await pumpUntilFound(
          tester,
          find.byKey(MainNavigationScreen.createTaskFabKey),
          tag: tag,
          timeout: const Duration(seconds: 20),
          reason: 'Main navigation FAB did not appear after successful login.',
        );

        expect(
          find.byKey(MainNavigationScreen.createTaskFabKey),
          findsOneWidget,
        );
      },
      skip: T61T70Preflight.t65() != null,
    );
  });
}
