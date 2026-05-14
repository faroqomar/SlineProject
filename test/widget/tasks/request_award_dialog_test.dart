/// Widget tests for showAwardDialog (request_award_dialog.dart).
///
/// showAwardDialog displays an AlertDialog with budget comparison, delivery
/// days, payment deadline info, "What happens next" steps, and Cancel/Award
/// buttons. The dialog is a top-level function that receives its dependencies
/// as parameters rather than reading from context (except the nested
/// showPriceMismatchDialog helper).
///
/// T-numbers: T270 -- T280.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/features/tasks/models/task_request_model.dart';
import 'package:sline_app/features/tasks/view/widgets/requests/request_award_dialog.dart';
import 'package:sline_app/features/tasks/viewmodels/task_requests_view_model.dart';

import '../../test_support/pump_app.dart';

// ---------------------------------------------------------------------------
// File-local mocks
// ---------------------------------------------------------------------------
class _MockTaskRequestsViewModel extends Mock
    with ChangeNotifier
    implements TaskRequestsViewModel {}

// ---------------------------------------------------------------------------
// Shared constants and helpers
// ---------------------------------------------------------------------------
const _kTaskId = 'task-200';

TaskRequest _makeRequest({
  String id = 'req-1',
  String bidderId = 'bidder-1',
  int price = 50000,
  int days = 7,
  String? bidderName = 'Ahmed K.',
  OfferStatus status = OfferStatus.pending,
  PaymentStatus paymentStatus = PaymentStatus.unpaid,
  DateTime? createdAt,
  String? taskTitle,
}) {
  return TaskRequest(
    id: id,
    taskId: _kTaskId,
    bidderId: bidderId,
    price: price,
    days: days,
    status: status,
    paymentStatus: paymentStatus,
    createdAt: createdAt ?? DateTime.now().subtract(const Duration(hours: 1)),
    bidderName: bidderName,
    taskTitle: taskTitle,
  );
}

/// Pumps a Scaffold with a button that opens showAwardDialog on tap.
/// This allows us to test the dialog in a real overlay context.
Future<void> _pumpDialogLauncher(
  WidgetTester tester, {
  required TaskRequest request,
  required _MockTaskRequestsViewModel vm,
  String? budget,
}) async {
  await pumpApp(
    tester,
    ChangeNotifierProvider<TaskRequestsViewModel>.value(
      value: vm,
      child: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            key: const Key('open_dialog_btn'),
            onPressed: () => showAwardDialog(
              context: context,
              request: request,
              vm: vm,
              budget: budget,
              onAwardingChanged: ({required isAwarding}) {},
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
}

/// Taps the launcher button and pumps to let the dialog appear.
Future<void> _openDialog(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('open_dialog_btn')));
  await tester.pumpAndSettle();
}

void main() {
  late _MockTaskRequestsViewModel mockVm;

  setUp(() {
    mockVm = _MockTaskRequestsViewModel();
  });

  group('showAwardDialog', () {
    // -----------------------------------------------------------------------
    // T270: dialog renders when triggered
    // -----------------------------------------------------------------------
    testWidgets('T270: dialog renders when triggered', (tester) async {
      final request = _makeRequest();
      await _pumpDialogLauncher(tester, request: request, vm: mockVm);
      await _openDialog(tester);

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // T271: shows freelancer name in title
    // -----------------------------------------------------------------------
    testWidgets('T271: shows freelancer name in title', (tester) async {
      final request = _makeRequest(bidderName: 'Sara M.');
      await _pumpDialogLauncher(tester, request: request, vm: mockVm);
      await _openDialog(tester);

      expect(find.textContaining('Sara M.'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // T272: shows bid price
    // -----------------------------------------------------------------------
    testWidgets('T272: shows bid price', (tester) async {
      // 50000 -> "50K IQD" per PriceFormatter
      final request = _makeRequest(price: 50000);
      await _pumpDialogLauncher(tester, request: request, vm: mockVm);
      await _openDialog(tester);

      expect(find.text('50K IQD'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // T273: shows delivery days
    // -----------------------------------------------------------------------
    testWidgets('T273: shows delivery days', (tester) async {
      final request = _makeRequest(days: 10);
      await _pumpDialogLauncher(tester, request: request, vm: mockVm);
      await _openDialog(tester);

      expect(find.textContaining('10 days'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // T274: shows budget comparison
    // -----------------------------------------------------------------------
    testWidgets('T274: shows budget comparison', (tester) async {
      final request = _makeRequest(price: 50000);
      await _pumpDialogLauncher(
        tester,
        request: request,
        vm: mockVm,
        budget: '60000',
      );
      await _openDialog(tester);

      expect(find.text('Price Comparison'), findsOneWidget);
      expect(find.text('Your Budget:'), findsOneWidget);
      expect(find.text('Bid Price:'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // T275: "Award Freelancer" button exists
    // -----------------------------------------------------------------------
    testWidgets('T275: "Award Freelancer" button exists', (tester) async {
      final request = _makeRequest();
      await _pumpDialogLauncher(tester, request: request, vm: mockVm);
      await _openDialog(tester);

      expect(find.text('Award Freelancer'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // T276: "Cancel" button dismisses dialog
    // -----------------------------------------------------------------------
    testWidgets('T276: "Cancel" button dismisses dialog', (tester) async {
      final request = _makeRequest();
      await _pumpDialogLauncher(tester, request: request, vm: mockVm);
      await _openDialog(tester);

      // Verify dialog is open
      expect(find.byType(AlertDialog), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.byType(AlertDialog), findsNothing);
    });

    // -----------------------------------------------------------------------
    // T277: under-budget shows green indicator
    // -----------------------------------------------------------------------
    testWidgets('T277: under-budget shows green indicator', (tester) async {
      // Bid price 50000, budget 60000 -> under budget
      final request = _makeRequest(price: 50000);
      await _pumpDialogLauncher(
        tester,
        request: request,
        vm: mockVm,
        budget: '60000',
      );
      await _openDialog(tester);

      // Should show "Under budget by X" message
      expect(find.textContaining('Under budget'), findsOneWidget);
      // Green trending_down icon
      expect(find.byIcon(Icons.trending_down), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // T278: over-budget shows red indicator
    // -----------------------------------------------------------------------
    testWidgets('T278: over-budget shows red indicator', (tester) async {
      // Bid price 80000, budget 60000 -> over budget
      final request = _makeRequest(price: 80000);
      await _pumpDialogLauncher(
        tester,
        request: request,
        vm: mockVm,
        budget: '60000',
      );
      await _openDialog(tester);

      // Should show "Over budget by X" message
      expect(find.textContaining('Over budget'), findsOneWidget);
      // Red trending_up icon
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // T279: shows payment deadline info
    // -----------------------------------------------------------------------
    testWidgets('T279: shows payment deadline info', (tester) async {
      final request = _makeRequest();
      await _pumpDialogLauncher(tester, request: request, vm: mockVm);
      await _openDialog(tester);

      expect(find.text('Payment Required Within 24 Hours'), findsOneWidget);
      expect(
        find.textContaining('After awarding, you have until'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Work starts only after payment is confirmed.'),
        findsOneWidget,
      );
    });

    // -----------------------------------------------------------------------
    // T280: shows "What happens next" steps
    // -----------------------------------------------------------------------
    testWidgets('T280: shows "What happens next" steps', (tester) async {
      final request = _makeRequest();
      await _pumpDialogLauncher(tester, request: request, vm: mockVm);
      await _openDialog(tester);

      expect(find.text('What happens next:'), findsOneWidget);
      expect(find.text('Award the bid'), findsOneWidget);
      expect(find.text('Complete payment'), findsOneWidget);
      expect(find.text('Work begins'), findsOneWidget);

      // Step descriptions
      expect(find.text('Now'), findsOneWidget);
      expect(find.text('Within 24 hours'), findsOneWidget);
      expect(find.text('After payment confirmed'), findsOneWidget);
    });
  });
}
