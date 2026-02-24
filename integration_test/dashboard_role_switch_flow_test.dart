import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/widgets/custom_bottom_nav_bar.dart';
import 'package:sline_app/features/dashboard/view/dashboard_screen.dart';

import 'support/helpers.dart';
import 'support/preflight.dart';
import 'support/t61_t70_env.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'T70 Dashboard role switch persists and refreshes data without crash',
    (tester) async {
      const tag = 'T70';
      final freelancerCue = T61T70Env.t70RoleCueFreelancer.trim().isNotEmpty
          ? T61T70Env.t70RoleCueFreelancer.trim()
          : 'Ready to pick up some work?';
      final clientCue = T61T70Env.t70RoleCueClient.trim().isNotEmpty
          ? T61T70Env.t70RoleCueClient.trim()
          : "Let's get your projects moving.";

      await launchAppForIntegration(tester, tag: tag, resetAuth: true);
      await loginViaUi(
        tester,
        tag: tag,
        email: T61T70Env.loginEmail,
        password: T61T70Env.loginPassword,
      );

      await tapByKey(tester, CustomBottomNavBar.dashboardNavKey, tag: tag);
      await pumpUntilFound(
        tester,
        find.byKey(DashboardScreen.settingsButtonKey),
        tag: tag,
        timeout: const Duration(seconds: 20),
      );
      await pumpUntilAnyFound(
        tester,
        [find.text(clientCue), find.text(freelancerCue)],
        tag: tag,
        timeout: const Duration(seconds: 20),
        reason: 'Dashboard overview role cue never became visible.',
      );

      // Switch to Client role
      await tapByKey(tester, DashboardScreen.settingsButtonKey, tag: tag);
      await pumpUntilFound(
        tester,
        find.byKey(DashboardScreen.clientRoleButtonKey),
        tag: tag,
      );
      await tapByKey(tester, DashboardScreen.clientRoleButtonKey, tag: tag);
      await tester.tap(find.text('Close'));
      await tester.pump();

      await pumpUntilFound(
        tester,
        find.text(clientCue),
        tag: tag,
        timeout: const Duration(seconds: 20),
        reason: 'Client role cue not shown after role switch.',
      );

      // Same-session persistence: leave dashboard and re-enter.
      await tapByKey(tester, CustomBottomNavBar.homeNavKey, tag: tag);
      await pumpUntilFound(
        tester,
        find.byKey(CustomBottomNavBar.homeNavKey),
        tag: tag,
        timeout: const Duration(seconds: 8),
      );
      await tapByKey(tester, CustomBottomNavBar.dashboardNavKey, tag: tag);

      await pumpUntilFound(
        tester,
        find.text(clientCue),
        tag: tag,
        timeout: const Duration(seconds: 20),
        reason: 'Client role did not persist after same-session re-entry.',
      );
      expect(find.byKey(DashboardScreen.settingsButtonKey), findsOneWidget);

      // Switch back to Freelancer to prove multi-role toggling still works.
      await tapByKey(tester, DashboardScreen.settingsButtonKey, tag: tag);
      await pumpUntilFound(
        tester,
        find.byKey(DashboardScreen.freelancerRoleButtonKey),
        tag: tag,
      );
      await tapByKey(tester, DashboardScreen.freelancerRoleButtonKey, tag: tag);
      await tester.tap(find.text('Close'));
      await tester.pump();

      await pumpUntilFound(
        tester,
        find.text(freelancerCue),
        tag: tag,
        timeout: const Duration(seconds: 20),
        reason: 'Freelancer role cue not restored after switching back.',
      );
    },
    skip: T61T70Preflight.t70() != null,
  );
}
