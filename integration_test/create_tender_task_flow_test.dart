import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/app/main_navigation_screen.dart';
import 'package:sline_app/core/widgets/custom_bottom_nav_bar.dart';
import 'package:sline_app/features/home/view/home_screen.dart';
import 'package:sline_app/features/tasks/view/create_task_screen.dart';

import 'support/helpers.dart';
import 'support/preflight.dart';
import 'support/t61_t70_env.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'T66 Create tender task flow form submit appears in task/order surfaces',
    (tester) async {
      const tag = 'T66';
      final marker = uniqueMarker(tag, 'tender');

      T61T70Preflight.log(
        tag,
        'Using default surfaces: Tenders list + TaskDetailsScreen',
      );

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
      );

      await tapByKey(tester, MainNavigationScreen.createTaskFabKey, tag: tag);
      await pumpUntilFound(
        tester,
        find.byKey(CreateTaskScreen.primaryActionButtonKey),
        tag: tag,
        timeout: const Duration(seconds: 12),
        reason: 'CreateTaskScreen did not open from main-nav FAB.',
      );

      // Step 1: Tender type selected (default), move next.
      await tapByKey(tester, CreateTaskScreen.tenderTypeCardKey, tag: tag);
      await tapByKey(tester, CreateTaskScreen.primaryActionButtonKey, tag: tag);

      // Step 2: Fill title/description and continue.
      final titleField = find.byType(TextFormField).at(0);
      final descField = find.byType(TextFormField).at(1);
      final tagsField = find.byType(TextFormField).at(2);
      await pumpUntilFound(tester, titleField, tag: tag);
      await tester.enterText(titleField, marker);
      await tester.pump();
      await tester.enterText(
        descField,
        'Automated integration tender created by $tag',
      );
      await tester.pump();
      if (exists(tagsField)) {
        await tester.enterText(tagsField, 'test, integration');
        await tester.pump();
      }
      await tapByKey(tester, CreateTaskScreen.primaryActionButtonKey, tag: tag);

      // Step 3: Submit (budget/deadline are optional in current code path).
      await tapByKey(tester, CreateTaskScreen.primaryActionButtonKey, tag: tag);
      await pumpUntilFound(
        tester,
        find.byKey(MainNavigationScreen.createTaskFabKey),
        tag: tag,
        timeout: const Duration(seconds: 25),
        reason: 'CreateTaskScreen did not close after submit.',
      );

      // Refresh home/filter providers so the new task shows in discovery lists.
      await refreshHomeFeedViaProviders(tester, tag: tag);

      // Narrow to the unique marker in shared filter state from Home.
      await tapByKey(tester, CustomBottomNavBar.homeNavKey, tag: tag);
      await pumpUntilFound(
        tester,
        find.byKey(HomeScreen.searchFieldKey),
        tag: tag,
      );
      await tester.enterText(find.byKey(HomeScreen.searchFieldKey), marker);
      await tester.pump();
      await pumpFor(tester, duration: const Duration(seconds: 1));

      // Surface 1: Tenders list
      await tapByKey(tester, CustomBottomNavBar.tendersNavKey, tag: tag);
      await pumpUntilFound(
        tester,
        find.text(marker),
        tag: tag,
        timeout: const Duration(seconds: 15),
        reason:
            'Created tender marker not visible in Tenders list surface after refresh.',
      );
      expect(find.text(marker), findsAtLeastNWidgets(1));

      // Surface 2: Task details
      await tester.tap(find.text(marker).first);
      await tester.pump();
      await pumpUntilAnyFound(
        tester,
        [find.text('Job Details'), find.text('Booking Details')],
        tag: tag,
        timeout: const Duration(seconds: 12),
        reason: 'Task details screen did not open from Tenders list item tap.',
      );
      expect(find.text(marker), findsAtLeastNWidgets(1));
      expect(find.text('Job Details'), findsOneWidget);
    },
    skip: T61T70Preflight.t66() != null,
  );
}
