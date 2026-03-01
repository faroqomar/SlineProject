import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/deep_link_service.dart';
import 'package:sline_app/features/dashboard/models/dashboard_counters.dart';
import 'package:sline_app/features/dashboard/models/work_item.dart';
import 'package:sline_app/features/dashboard/view/tabs/work_tab.dart';
import 'package:sline_app/features/dashboard/viewmodels/dashboard_view_model.dart';

import '../../test_support/pump_app.dart';

class _MockDashboardViewModel extends Mock
    with ChangeNotifier
    implements DashboardViewModel {}

class _FakeWorkItem extends Fake implements WorkItem {}

class _FakeDeepLinkService extends Fake implements DeepLinkService {
  @override
  Future<dynamic> handleWorkItem(
    BuildContext context,
    String type,
    String id,
  ) async => null;
}

WorkItem _buildWorkItem({
  required String id,
  required String title,
  required bool canReview,
}) {
  return WorkItem(
    id: id,
    type: WorkItemType.booking,
    title: title,
    counterpartyId: 'counterparty-$id',
    counterpartyName: 'Counterparty',
    counterpartyAvatar: '',
    counterpartyRole: 'Client',
    statusRaw: 'delivered',
    statusUiBucket: 'Active',
    createdAt: DateTime.utc(2026, 3, 1, 10, 0),
    lastUpdate: DateTime.utc(2026, 3, 1, 11, 0),
    primaryActionType: canReview
        ? PrimaryActionType.reviewDelivery
        : PrimaryActionType.viewDetails,
    permissions: WorkItemPermissions(canReview: canReview),
    needsReview: true,
  );
}

Future<void> _pumpWorkTab(
  WidgetTester tester,
  _MockDashboardViewModel vm,
) async {
  when(() => vm.consumeWorkSubTabIndex()).thenReturn(null);
  when(() => vm.currentRole).thenReturn(UserRole.client);
  when(() => vm.counters).thenReturn(const DashboardCounters());
  when(() => vm.performPrimaryAction(any())).thenAnswer((_) async {});

  await pumpApp(
    tester,
    Provider<DeepLinkService>.value(
      value: _FakeDeepLinkService(),
      child: ChangeNotifierProvider<DashboardViewModel>.value(
        value: vm,
        child: const Scaffold(body: WorkTab()),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeWorkItem());
  });

  group('WorkTab review routing', () {
    testWidgets(
      'waiting-on-client items stay out of Needs Your Review section',
      (tester) async {
        final vm = _MockDashboardViewModel();
        final waitingItem = _buildWorkItem(
          id: 'waiting-review',
          title: 'Delivered booking',
          canReview: false,
        );

        when(() => vm.activeWork).thenReturn([waitingItem]);
        when(() => vm.deliveredWork).thenReturn(const []);
        when(() => vm.completedWork).thenReturn(const []);
        when(() => vm.cancelledWork).thenReturn(const []);

        await _pumpWorkTab(tester, vm);

        expect(find.text('Needs Your Review (1)'), findsNothing);
        expect(find.text('Awaiting Client Review'), findsOneWidget);
        expect(find.text('Delivered booking'), findsOneWidget);
      },
    );

    testWidgets('client-reviewable items show Needs Your Review section', (
      tester,
    ) async {
      final vm = _MockDashboardViewModel();
      final reviewItem = _buildWorkItem(
        id: 'needs-review',
        title: 'Delivered task',
        canReview: true,
      );

      when(() => vm.activeWork).thenReturn([reviewItem]);
      when(() => vm.deliveredWork).thenReturn([reviewItem]);
      when(() => vm.completedWork).thenReturn(const []);
      when(() => vm.cancelledWork).thenReturn(const []);

      await _pumpWorkTab(tester, vm);

      expect(find.text('Needs Your Review (1)'), findsOneWidget);
      expect(find.text('Needs Review'), findsOneWidget);
      expect(find.text('Awaiting Client Review'), findsNothing);
    });
  });
}
