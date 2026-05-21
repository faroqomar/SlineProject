import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/features/dashboard/view/dashboard_screen.dart';
import 'package:sline_app/features/dashboard/viewmodels/dashboard_view_model.dart';

import '../../test_support/pump_app.dart';

class _MockDashboardViewModel extends Mock
    with ChangeNotifier
    implements DashboardViewModel {}

List<Widget> _stubTabViews() {
  return const [
    Center(key: ValueKey('dashboard_tab_body_0'), child: Text('Overview Body')),
    Center(key: ValueKey('dashboard_tab_body_1'), child: Text('Bookings Body')),
    Center(key: ValueKey('dashboard_tab_body_2'), child: Text('Work Body')),
    Center(key: ValueKey('dashboard_tab_body_3'), child: Text('Wallet Body')),
    Center(key: ValueKey('dashboard_tab_body_4'), child: Text('Inbox Body')),
  ];
}

Future<void> _pumpDashboardScreen(
  WidgetTester tester,
  _MockDashboardViewModel vm,
) async {
  when(() => vm.currentTab).thenReturn(DashboardTab.overview);
  when(() => vm.currentRole).thenReturn(UserRole.freelancer);
  when(() => vm.setRole(UserRole.client)).thenAnswer((_) async {});
  when(() => vm.setRole(UserRole.freelancer)).thenAnswer((_) async {});

  await pumpApp(
    tester,
    ChangeNotifierProvider<DashboardViewModel>.value(
      value: vm,
      child: DashboardScreen(tabViews: _stubTabViews()),
    ),
  );
}

void main() {
  group('DashboardScreen T56-T58', () {
    testWidgets('T56 shows 5 tabs Overview Bookings Work Wallet Inbox', (
      tester,
    ) async {
      final vm = _MockDashboardViewModel();

      await _pumpDashboardScreen(tester, vm);

      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Bookings'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
      expect(find.text('Wallet'), findsOneWidget);
      expect(find.text('Inbox'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('dashboard_tab_body_0')),
        findsOneWidget,
      );
      expect(find.byType(TabBar), findsNothing);
      final activeTabContainers = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .where((widget) {
            final decoration = widget.decoration;
            return decoration is BoxDecoration &&
                decoration.gradient == AmberDuskMaterial.activeWashGradient;
          })
          .length;
      expect(activeTabContainers, 1);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, AmberDuskTokens.colors.background);
      expect(find.byType(AmberDuskBackground), findsOneWidget);
    });

    testWidgets('T57 tab tap calls setTab(index)', (tester) async {
      final vm = _MockDashboardViewModel();

      await _pumpDashboardScreen(tester, vm);

      await tester.tap(find.text('Work'));
      await tester.pump();

      verify(() => vm.setTab(2)).called(1);
    });

    testWidgets('T58 role switch ignores active role taps', (tester) async {
      final vm = _MockDashboardViewModel();

      await _pumpDashboardScreen(tester, vm);

      // Tap settings button to open the bottom sheet (Phase 7: migrated
      // from AlertDialog to showModalBottomSheet).
      await tester.tap(find.byKey(DashboardScreen.settingsButtonKey));
      // pumpAndSettle waits for bottom sheet slide-up animation to finish
      await tester.pumpAndSettle();

      // Role buttons are now inside the bottom sheet — find by key
      await tester.tap(find.byKey(DashboardScreen.clientRoleButtonKey));
      await tester.pump();
      await tester.tap(find.byKey(DashboardScreen.freelancerRoleButtonKey));
      await tester.pump();

      verify(() => vm.setRole(UserRole.client)).called(1);
      verifyNever(() => vm.setRole(UserRole.freelancer));
    });
  });
}
