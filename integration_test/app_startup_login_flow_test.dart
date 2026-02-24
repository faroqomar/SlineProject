import 'package:flutter_test/flutter_test.dart';

import 'support/helpers.dart';
import 'support/preflight.dart';

void main() {
  ensureIntegrationBinding();

  group('App Startup/Login Flow T64-T65', () {
    testWidgets(
      'T64 Cold start unauthenticated lands on login',
      (tester) async {
        T61T70Preflight.log(
          'T64',
          'Preflight satisfied. Implement cold-start reset + login selector assertions.',
        );
        await launchAppForIntegration(tester, tag: 'T64');
        throw UnimplementedError(
          'T64 implementation requires locked emulator/reset strategy.',
        );
      },
      skip: T61T70Preflight.t64() != null,
    );

    testWidgets(
      'T65 Login happy path lands on main navigation',
      (tester) async {
        T61T70Preflight.log(
          'T65',
          'Preflight satisfied. Implement login submission + main-nav assertions.',
        );
        await launchAppForIntegration(tester, tag: 'T65');
        throw UnimplementedError(
          'T65 implementation requires staging credentials/selectors.',
        );
      },
      skip: T61T70Preflight.t65() != null,
    );
  });
}
