import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/widgets/skeleton_loader.dart';
import 'package:sline_app/features/dashboard/view/tabs/inbox_tab.dart';
import 'package:sline_app/features/dashboard/viewmodels/dashboard_view_model.dart';
import 'package:sline_app/features/tasks/models/task_request_model.dart';

import '../../test_support/pump_app.dart';

class _MockDashboardViewModel extends Mock
    with ChangeNotifier
    implements DashboardViewModel {}

Future<void> _pumpInboxTab(
  WidgetTester tester,
  _MockDashboardViewModel vm, {
  UserRole role = UserRole.client,
  bool isLoading = false,
  List<TaskRequest> offers = const <TaskRequest>[],
}) async {
  when(() => vm.currentRole).thenReturn(role);
  when(() => vm.isLoading).thenReturn(isLoading);
  when(() => vm.inboxOffers).thenReturn(offers);
  when(() => vm.refresh()).thenAnswer((_) async {});

  await pumpApp(
    tester,
    ChangeNotifierProvider<DashboardViewModel>.value(
      value: vm,
      child: const Scaffold(body: InboxTab()),
    ),
  );
}

TaskRequest _offer({
  String id = 'offer-1',
  OfferStatus status = OfferStatus.pending,
  PaymentStatus paymentStatus = PaymentStatus.unpaid,
}) {
  return TaskRequest(
    id: id,
    taskId: 'task-1',
    bidderId: 'freelancer-1',
    price: 450,
    days: 3,
    note: 'I can start tomorrow.',
    status: status,
    paymentStatus: paymentStatus,
    createdAt: DateTime.utc(2020),
    bidderName: 'Yara Ahmed',
    taskTitle: 'Landing page design',
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_offer());
  });

  group('InboxTab functionality', () {
    testWidgets('shows action queue header without disabled Sent control', (
      tester,
    ) async {
      final vm = _MockDashboardViewModel();

      await _pumpInboxTab(tester, vm);

      expect(find.text('Proposals requiring action'), findsOneWidget);
      expect(find.text('Received'), findsNothing);
      expect(find.text('Sent'), findsNothing);
      expect(find.text('No Proposals Yet'), findsOneWidget);
      expect(find.text('Open Messages'), findsOneWidget);
      verifyNever(vm.refresh);
      expect(
        find.text(
          'Sent inbox data needs a separate dashboard contract before this mode can become active.',
        ),
        findsNothing,
      );
    });

    testWidgets('renders loading skeleton for empty loading state', (
      tester,
    ) async {
      final vm = _MockDashboardViewModel();

      await _pumpInboxTab(tester, vm, isLoading: true);

      expect(find.byType(SkeletonLoader), findsWidgets);
    });

    testWidgets('renders received offer list and awards pending offer', (
      tester,
    ) async {
      final vm = _MockDashboardViewModel();
      final offer = _offer();
      when(
        () => vm.awardOffer(any()),
      ).thenAnswer((_) async => <String, dynamic>{'success': true});
      when(
        () => vm.setTab(any(), workSubTab: any(named: 'workSubTab')),
      ).thenReturn(null);

      await _pumpInboxTab(tester, vm, offers: [offer]);

      expect(find.text('Yara Ahmed'), findsOneWidget);
      expect(find.text('Landing page design'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Award'));
      await tester.pumpAndSettle();

      verify(() => vm.awardOffer(offer)).called(1);
      verify(vm.refresh).called(1);
      verify(
        () => vm.setTab(DashboardTab.activeWork.index, workSubTab: 0),
      ).called(1);
    });

    testWidgets('shows award failure snackbar', (tester) async {
      final vm = _MockDashboardViewModel();
      when(() => vm.awardOffer(any())).thenAnswer(
        (_) async => <String, dynamic>{
          'success': false,
          'error': 'Award failed',
        },
      );

      await _pumpInboxTab(tester, vm, offers: [_offer()]);

      await tester.tap(find.widgetWithText(FilledButton, 'Award'));
      await tester.pumpAndSettle();

      expect(find.text('Award failed'), findsOneWidget);
    });

    testWidgets('renders Pay Now for accepted unpaid client offers', (
      tester,
    ) async {
      final vm = _MockDashboardViewModel();

      await _pumpInboxTab(
        tester,
        vm,
        offers: [_offer(status: OfferStatus.accepted)],
      );

      expect(find.widgetWithText(FilledButton, 'Pay Now'), findsOneWidget);
    });

    testWidgets('provider can withdraw pending sent offer', (tester) async {
      final vm = _MockDashboardViewModel();
      final offer = _offer();
      when(() => vm.withdrawOffer(any())).thenAnswer((_) async {});

      await _pumpInboxTab(
        tester,
        vm,
        role: UserRole.freelancer,
        offers: [offer],
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'Withdraw'));
      await tester.pumpAndSettle();

      verify(() => vm.withdrawOffer(offer.id)).called(1);
    });
  });
}
