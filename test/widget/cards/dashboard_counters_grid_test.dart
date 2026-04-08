import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/features/dashboard/models/dashboard_counters.dart';
import 'package:sline_app/features/dashboard/view/widgets/dashboard_counters_grid.dart';
import 'package:sline_app/features/dashboard/viewmodels/dashboard_view_model.dart';

import '../../test_support/pump_app.dart';

class _MockDashboardViewModel extends Mock
    with ChangeNotifier
    implements DashboardViewModel {}

void main() {
  late _MockDashboardViewModel mockDashVm;

  setUp(() {
    mockDashVm = _MockDashboardViewModel();
    when(() => mockDashVm.currentRole).thenReturn(UserRole.client);
    when(() => mockDashVm.isLoading).thenReturn(false);
    when(() => mockDashVm.counters).thenReturn(
      const DashboardCounters(
        activeWork: 5,
        needsReview: 3,
        pendingPayment: 2,
        completed: 10,
      ),
    );
  });

  group('DashboardCountersGrid Phase 9 — animated counters', () {
    testWidgets('displays correct count values after animation settles', (
      tester,
    ) async {
      await pumpApp(
        tester,
        ChangeNotifierProvider<DashboardViewModel>.value(
          value: mockDashVm,
          child: const Scaffold(body: DashboardCountersGrid()),
        ),
      );

      // Let the animated count-up finish (500ms emphasis + margin)
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 200));

      // Client role shows: Active Work, Needs Review, Pending Payment, Completed
      expect(find.text('5'), findsOneWidget); // activeWork
      expect(find.text('3'), findsOneWidget); // needsReview
      expect(find.text('2'), findsOneWidget); // pendingPayment
      expect(find.text('10'), findsOneWidget); // completed
    });

    testWidgets('animated count widget is present in widget tree', (
      tester,
    ) async {
      await pumpApp(
        tester,
        ChangeNotifierProvider<DashboardViewModel>.value(
          value: mockDashVm,
          child: const Scaffold(body: DashboardCountersGrid()),
        ),
      );

      // Pump a frame so the grid renders
      await tester.pump();

      // The _AnimatedCount widget renders AnimatedBuilder widgets.
      // Since _AnimatedCount is private, we verify AnimatedBuilder is present
      // in the counters grid. There should be 4 counters, each with an
      // AnimatedBuilder for the count-up animation.
      expect(find.byType(AnimatedBuilder), findsAtLeastNWidgets(4));
    });
  });
}
