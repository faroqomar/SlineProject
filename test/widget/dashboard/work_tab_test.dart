import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/deep_link_service.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/features/dashboard/models/dashboard_counters.dart';
import 'package:sline_app/features/dashboard/models/work_item.dart';
import 'package:sline_app/features/dashboard/view/tabs/work_tab.dart';
import 'package:sline_app/features/dashboard/view/widgets/work_item_card.dart';
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
    String id, {
    String? conversationId,
  }) async => null;
}

WorkItem _buildWorkItem({
  required String id,
  required String title,
  required bool canReview,
  String statusRaw = 'delivered',
  String statusUiBucket = 'Active',
}) {
  return WorkItem(
    id: id,
    type: WorkItemType.booking,
    title: title,
    counterpartyId: 'counterparty-$id',
    counterpartyName: 'Counterparty',
    counterpartyAvatar: '',
    counterpartyRole: 'Client',
    statusRaw: statusRaw,
    statusUiBucket: statusUiBucket,
    createdAt: DateTime.utc(2026, 3, 1, 10),
    lastUpdate: DateTime.utc(2026, 3, 1, 11),
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
      'waiting-on-client items render inside the single Active list',
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
        expect(find.text('In Progress (1)'), findsNothing);
        // Phase 7 REDESIGN: review banner text updated for clarity
        expect(find.text('Waiting for client review'), findsOneWidget);
        expect(find.text('Delivered booking'), findsOneWidget);
      },
    );

    testWidgets('client-reviewable items keep review urgency inside the card', (
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

      expect(find.text('Needs Your Review (1)'), findsNothing);
      expect(find.text('In Progress (1)'), findsNothing);
      // Phase 7 REDESIGN: review banner text updated for clarity
      expect(find.text('Delivery ready for your review'), findsOneWidget);
      expect(find.text('Waiting for client review'), findsNothing);
    });

    testWidgets('refunded work uses done treatment and full progress', (
      tester,
    ) async {
      final vm = _MockDashboardViewModel();
      final refundedItem = _buildWorkItem(
        id: 'refunded-work',
        title: 'Refunded booking',
        canReview: false,
        statusRaw: 'refunded',
        statusUiBucket: 'Done',
      );

      when(() => vm.activeWork).thenReturn(const []);
      when(() => vm.deliveredWork).thenReturn(const []);
      when(() => vm.completedWork).thenReturn([refundedItem]);
      when(() => vm.cancelledWork).thenReturn(const []);

      await _pumpWorkTab(tester, vm);
      await tester.tap(find.text('Done 1'));
      await tester.pumpAndSettle();

      final refundedCard = find.ancestor(
        of: find.text('REFUNDED'),
        matching: find.byType(WorkItemCard),
      );
      expect(refundedCard, findsOneWidget);

      final progress = tester.widget<LinearProgressIndicator>(
        find.descendant(
          of: refundedCard,
          matching: find.byType(LinearProgressIndicator),
        ),
      );
      final status = tester.widget<Text>(
        find.descendant(of: refundedCard, matching: find.text('REFUNDED')),
      );

      expect(progress.value, 1);
      expect(status.style?.color, AmberDuskTokens.colors.text);
    });

    testWidgets('public work cards hide explicit unsafe titles', (
      tester,
    ) async {
      final vm = _MockDashboardViewModel();
      final unsafeItem = _buildWorkItem(
        id: 'unsafe-title',
        title: 'suck my cock',
        canReview: false,
      );

      when(() => vm.activeWork).thenReturn([unsafeItem]);
      when(() => vm.deliveredWork).thenReturn(const []);
      when(() => vm.completedWork).thenReturn(const []);
      when(() => vm.cancelledWork).thenReturn(const []);

      await _pumpWorkTab(tester, vm);

      expect(find.text('suck my cock'), findsNothing);
      expect(find.text('Content under review'), findsOneWidget);
    });
  });
}
