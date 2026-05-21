import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/features/auth/viewmodels/auth_session_view_model.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';
import 'package:sline_app/features/tasks/models/task_request_model.dart';
import 'package:sline_app/features/tasks/services/task_requests_service.dart';
import 'package:sline_app/features/tasks/services/task_service.dart';
import 'package:sline_app/features/tasks/view/widgets/requests/submit_request_sheet.dart';
import 'package:sline_app/features/tasks/viewmodels/task_requests_view_model.dart';

import '../../test_support/pump_app.dart';

// ---------------------------------------------------------------------------
// File-local mocks
// ---------------------------------------------------------------------------
class _MockTaskService extends Mock implements TaskService {}

class _MockTaskRequestsService extends Mock implements TaskRequestsService {}

class _MockAuthSessionViewModel extends Mock
    with ChangeNotifier
    implements AuthSessionViewModel {}

class _MockTaskRequestsViewModel extends Mock
    with ChangeNotifier
    implements TaskRequestsViewModel {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _kTaskId = 'task-1';
const _kBudget = '5000';

Task _openTask({String userId = 'other-user'}) {
  return Task(
    id: _kTaskId,
    title: 'Test Task',
    description: 'A test task description',
    budget: 5000,
    userId: userId,
    status: TaskStatus.open,
    createdAt: DateTime.utc(2026, 3),
  );
}

TaskRequest _existingBid({
  int price = 300000,
  int days = 5,
  String? note = 'Old cover letter',
}) {
  return TaskRequest(
    id: 'req-existing',
    taskId: _kTaskId,
    bidderId: 'user-1',
    price: price,
    days: days,
    note: note,
    status: OfferStatus.pending,
    createdAt: DateTime.utc(2026, 3),
  );
}

/// Pumps a Scaffold host that triggers [showSubmitRequestSheet] via a button.
Future<void> _pumpHost(
  WidgetTester tester, {
  required _MockTaskService taskService,
  required _MockTaskRequestsService requestsService,
  required _MockAuthSessionViewModel authVm,
  required _MockTaskRequestsViewModel controller,
  OnBidReplacedCallback? onReplaced,
}) async {
  await pumpApp(
    tester,
    MultiProvider(
      providers: [
        Provider<TaskService>.value(value: taskService),
        Provider<TaskRequestsService>.value(value: requestsService),
        ChangeNotifierProvider<AuthSessionViewModel>.value(value: authVm),
        ChangeNotifierProvider<TaskRequestsViewModel>.value(value: controller),
      ],
      child: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const Key('trigger_btn'),
                onPressed: () => showSubmitRequestSheet(
                  context,
                  taskId: _kTaskId,
                  controller: controller,
                  budget: _kBudget,
                  onReplaced: onReplaced,
                ),
                child: const Text('Open Sheet'),
              ),
            ),
          );
        },
      ),
    ),
  );
}

/// Configures service stubs for the "new bid" happy path.
void _stubNewBidHappyPath({
  required _MockTaskService taskService,
  required _MockTaskRequestsService requestsService,
  required _MockAuthSessionViewModel authVm,
  required _MockTaskRequestsViewModel controller,
}) {
  when(() => authVm.currentUserId).thenReturn('user-1');
  when(
    () => taskService.getTaskById(_kTaskId),
  ).thenAnswer((_) async => _openTask());
  when(
    () => controller.checkBidReplaceability(),
  ).thenAnswer((_) async => BidReplaceabilityResult.noExistingBid());
  when(
    () => controller.submitOfferUI(
      taskId: any(named: 'taskId'),
      price: any(named: 'price'),
      days: any(named: 'days'),
      note: any(named: 'note'),
    ),
  ).thenAnswer((_) async => true);
  when(() => controller.errorMessage).thenReturn(null);
}

/// Configures service stubs for the "replace bid" path.
void _stubReplaceBidPath({
  required _MockTaskService taskService,
  required _MockTaskRequestsService requestsService,
  required _MockAuthSessionViewModel authVm,
  required _MockTaskRequestsViewModel controller,
  TaskRequest? existingBid,
}) {
  final bid = existingBid ?? _existingBid();
  when(() => authVm.currentUserId).thenReturn('user-1');
  when(
    () => taskService.getTaskById(_kTaskId),
  ).thenAnswer((_) async => _openTask());
  when(
    () => controller.checkBidReplaceability(),
  ).thenAnswer((_) async => BidReplaceabilityResult.canReplace(bid));
  when(
    () => requestsService.replaceOffer(
      taskId: any(named: 'taskId'),
      price: any(named: 'price'),
      days: any(named: 'days'),
      note: any(named: 'note'),
    ),
  ).thenAnswer(
    (_) async => TaskRequest(
      id: 'req-new',
      taskId: _kTaskId,
      bidderId: 'user-1',
      price: 400000,
      days: 3,
      note: 'New note',
      status: OfferStatus.pending,
      createdAt: DateTime.utc(2026, 3, 2),
    ),
  );
  when(() => controller.loadForTask(any())).thenAnswer((_) async {});
  when(() => controller.errorMessage).thenReturn(null);
}

/// Opens the sheet by tapping the trigger button and letting animations settle.
Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('trigger_btn')));
  await tester.pumpAndSettle();
}

void main() {
  late _MockTaskService taskService;
  late _MockTaskRequestsService requestsService;
  late _MockAuthSessionViewModel authVm;
  late _MockTaskRequestsViewModel controller;

  setUpAll(() {
    registerFallbackValue(_openTask());
    registerFallbackValue(_existingBid());
  });

  setUp(() {
    taskService = _MockTaskService();
    requestsService = _MockTaskRequestsService();
    authVm = _MockAuthSessionViewModel();
    controller = _MockTaskRequestsViewModel();
  });

  // =========================================================================
  // New Bid Mode
  // =========================================================================
  group('SubmitRequestSheet — new bid mode', () {
    testWidgets('T120: sheet opens when trigger button is tapped', (
      tester,
    ) async {
      _stubNewBidHappyPath(
        taskService: taskService,
        requestsService: requestsService,
        authVm: authVm,
        controller: controller,
      );

      await _pumpHost(
        tester,
        taskService: taskService,
        requestsService: requestsService,
        authVm: authVm,
        controller: controller,
      );

      await _openSheet(tester);

      expect(find.byKey(const Key('submit_proposal_sheet')), findsOneWidget);
    });

    testWidgets('T121: renders Submit Proposal header for new bid', (
      tester,
    ) async {
      _stubNewBidHappyPath(
        taskService: taskService,
        requestsService: requestsService,
        authVm: authVm,
        controller: controller,
      );

      await _pumpHost(
        tester,
        taskService: taskService,
        requestsService: requestsService,
        authVm: authVm,
        controller: controller,
      );

      await _openSheet(tester);

      expect(find.text('Submit Proposal'), findsWidgets);
    });

    testWidgets('T122: renders bid amount field', (tester) async {
      _stubNewBidHappyPath(
        taskService: taskService,
        requestsService: requestsService,
        authVm: authVm,
        controller: controller,
      );

      await _pumpHost(
        tester,
        taskService: taskService,
        requestsService: requestsService,
        authVm: authVm,
        controller: controller,
      );

      await _openSheet(tester);

      expect(find.text('Amount (IQD)'), findsOneWidget);
      // The IQD amount field uses the same payments icon as the live sheet.
      expect(find.byIcon(Icons.payments_outlined), findsWidgets);
    });

    testWidgets('T123: renders delivery days field', (tester) async {
      _stubNewBidHappyPath(
        taskService: taskService,
        requestsService: requestsService,
        authVm: authVm,
        controller: controller,
      );

      await _pumpHost(
        tester,
        taskService: taskService,
        requestsService: requestsService,
        authVm: authVm,
        controller: controller,
      );

      await _openSheet(tester);

      expect(find.text('Delivery (Days)'), findsOneWidget);
      expect(find.text('e.g. 7'), findsOneWidget);
    });

    testWidgets('T124: renders cover letter field', (tester) async {
      _stubNewBidHappyPath(
        taskService: taskService,
        requestsService: requestsService,
        authVm: authVm,
        controller: controller,
      );

      await _pumpHost(
        tester,
        taskService: taskService,
        requestsService: requestsService,
        authVm: authVm,
        controller: controller,
      );

      await _openSheet(tester);

      expect(find.text('Cover Letter'), findsOneWidget);
      expect(
        find.text('Explain why you are the best fit for this job...'),
        findsOneWidget,
      );
    });

    testWidgets('T125: renders upload placeholder text', (tester) async {
      _stubNewBidHappyPath(
        taskService: taskService,
        requestsService: requestsService,
        authVm: authVm,
        controller: controller,
      );

      await _pumpHost(
        tester,
        taskService: taskService,
        requestsService: requestsService,
        authVm: authVm,
        controller: controller,
      );

      await _openSheet(tester);

      expect(find.text('Upload Files (Coming Soon)'), findsOneWidget);
      expect(find.byIcon(Icons.upload_file), findsOneWidget);
    });

    testWidgets('T126: renders submit button with Submit Proposal text', (
      tester,
    ) async {
      _stubNewBidHappyPath(
        taskService: taskService,
        requestsService: requestsService,
        authVm: authVm,
        controller: controller,
      );

      await _pumpHost(
        tester,
        taskService: taskService,
        requestsService: requestsService,
        authVm: authVm,
        controller: controller,
      );

      await _openSheet(tester);

      // 'Submit Proposal' appears both in header and button
      final submitTexts = find.text('Submit Proposal');
      expect(submitTexts, findsWidgets);
    });

    testWidgets('T127: empty price shows validation error on submit', (
      tester,
    ) async {
      _stubNewBidHappyPath(
        taskService: taskService,
        requestsService: requestsService,
        authVm: authVm,
        controller: controller,
      );

      await _pumpHost(
        tester,
        taskService: taskService,
        requestsService: requestsService,
        authVm: authVm,
        controller: controller,
      );

      await _openSheet(tester);

      // Enter days but leave price empty
      final daysFields = find.byType(TextFormField);
      // Fields: price (0), days (1), cover letter (2)
      await tester.enterText(daysFields.at(1), '7');
      await tester.pump();

      // Tap the submit button (the InkWell inside AppButton)
      // Find the text 'Submit Proposal' that is inside the bottom button area
      final submitButtons = find.text('Submit Proposal');
      await tester.tap(submitButtons.last);
      await tester.pumpAndSettle();

      expect(find.text('Enter a price greater than 0'), findsWidgets);
    });

    testWidgets('T127a: zero price shows friendly validation error', (
      tester,
    ) async {
      _stubNewBidHappyPath(
        taskService: taskService,
        requestsService: requestsService,
        authVm: authVm,
        controller: controller,
      );

      await _pumpHost(
        tester,
        taskService: taskService,
        requestsService: requestsService,
        authVm: authVm,
        controller: controller,
      );

      await _openSheet(tester);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '0');
      await tester.enterText(fields.at(1), '7');
      await tester.pump();

      await tester.tap(find.text('Submit Proposal').last);
      await tester.pumpAndSettle();

      expect(find.text('Enter a price greater than 0'), findsWidgets);
    });

    testWidgets('T128: empty days shows validation error on submit', (
      tester,
    ) async {
      _stubNewBidHappyPath(
        taskService: taskService,
        requestsService: requestsService,
        authVm: authVm,
        controller: controller,
      );

      await _pumpHost(
        tester,
        taskService: taskService,
        requestsService: requestsService,
        authVm: authVm,
        controller: controller,
      );

      await _openSheet(tester);

      // Enter price but leave days empty
      final formFields = find.byType(TextFormField);
      await tester.enterText(formFields.at(0), '100');
      await tester.pump();

      final submitButtons = find.text('Submit Proposal');
      await tester.tap(submitButtons.last);
      await tester.pumpAndSettle();

      expect(find.text('Invalid'), findsWidgets);
    });

    testWidgets('T129: valid form triggers submission', (tester) async {
      _stubNewBidHappyPath(
        taskService: taskService,
        requestsService: requestsService,
        authVm: authVm,
        controller: controller,
      );

      await _pumpHost(
        tester,
        taskService: taskService,
        requestsService: requestsService,
        authVm: authVm,
        controller: controller,
      );

      await _openSheet(tester);

      final formFields = find.byType(TextFormField);
      await tester.enterText(formFields.at(0), '100');
      await tester.enterText(formFields.at(1), '7');
      await tester.pump();

      final submitButtons = find.text('Submit Proposal');
      await tester.tap(submitButtons.last);
      await tester.pumpAndSettle();

      verify(
        () => controller.submitOfferUI(
          taskId: _kTaskId,
          price: 100.0,
          days: 7,
        ),
      ).called(1);
    });

    testWidgets('T138: cover letter accepts multi-line text', (tester) async {
      _stubNewBidHappyPath(
        taskService: taskService,
        requestsService: requestsService,
        authVm: authVm,
        controller: controller,
      );

      await _pumpHost(
        tester,
        taskService: taskService,
        requestsService: requestsService,
        authVm: authVm,
        controller: controller,
      );

      await _openSheet(tester);

      final formFields = find.byType(TextFormField);
      // The cover letter is the third TextFormField (index 2)
      const multilineText = 'Line one\nLine two\nLine three';
      await tester.enterText(formFields.at(2), multilineText);
      await tester.pump();

      expect(find.text(multilineText), findsOneWidget);
    });
  });

  // =========================================================================
  // Guard validation failure
  // =========================================================================
  group('SubmitRequestSheet — guard validation', () {
    testWidgets('T130: guard validation failure shows snackbar error', (
      tester,
    ) async {
      when(() => authVm.currentUserId).thenReturn('user-1');
      // Task is closed, so validateTask returns false
      when(() => taskService.getTaskById(_kTaskId)).thenAnswer(
        (_) async => Task(
          id: _kTaskId,
          title: 'Closed Task',
          description: 'desc',
          budget: 5000,
          userId: 'other-user',
          status: TaskStatus.closed,
          createdAt: DateTime.utc(2026, 3),
        ),
      );

      await _pumpHost(
        tester,
        taskService: taskService,
        requestsService: requestsService,
        authVm: authVm,
        controller: controller,
      );

      await tester.tap(find.byKey(const Key('trigger_btn')));
      await tester.pumpAndSettle();

      // The sheet should NOT open; instead a SnackBar with the error appears
      expect(find.byKey(const Key('submit_proposal_sheet')), findsNothing);
      expect(
        find.text('This task is no longer accepting offers.'),
        findsOneWidget,
      );
    });
  });

  // =========================================================================
  // Replace Bid Mode
  // =========================================================================
  group('SubmitRequestSheet — replace bid mode', () {
    testWidgets('T131: replace mode shows Replace Your Bid header', (
      tester,
    ) async {
      _stubReplaceBidPath(
        taskService: taskService,
        requestsService: requestsService,
        authVm: authVm,
        controller: controller,
      );

      await _pumpHost(
        tester,
        taskService: taskService,
        requestsService: requestsService,
        authVm: authVm,
        controller: controller,
      );

      await _openSheet(tester);

      expect(find.text('Replace Your Bid'), findsOneWidget);
    });

    testWidgets('T132: replace mode shows REPLACE badge with swap icon', (
      tester,
    ) async {
      _stubReplaceBidPath(
        taskService: taskService,
        requestsService: requestsService,
        authVm: authVm,
        controller: controller,
      );

      await _pumpHost(
        tester,
        taskService: taskService,
        requestsService: requestsService,
        authVm: authVm,
        controller: controller,
      );

      await _openSheet(tester);

      expect(find.text('REPLACE'), findsOneWidget);
      expect(find.byIcon(Icons.swap_horiz), findsOneWidget);
    });

    testWidgets('T133: replace mode shows existing bid summary', (
      tester,
    ) async {
      _stubReplaceBidPath(
        taskService: taskService,
        requestsService: requestsService,
        authVm: authVm,
        controller: controller,
        existingBid: _existingBid(),
      );

      await _pumpHost(
        tester,
        taskService: taskService,
        requestsService: requestsService,
        authVm: authVm,
        controller: controller,
      );

      await _openSheet(tester);

      expect(find.text('Current Bid (will be archived)'), findsOneWidget);
      // price 300000 formatted as 300K IQD
      expect(find.text('300K IQD'), findsOneWidget);
      expect(find.text('5 days'), findsOneWidget);
    });

    testWidgets('T134: replace mode button says Replace Bid', (tester) async {
      _stubReplaceBidPath(
        taskService: taskService,
        requestsService: requestsService,
        authVm: authVm,
        controller: controller,
      );

      await _pumpHost(
        tester,
        taskService: taskService,
        requestsService: requestsService,
        authVm: authVm,
        controller: controller,
      );

      await _openSheet(tester);

      expect(find.text('Replace Bid'), findsOneWidget);
    });

    testWidgets('T135: replace bid opens confirmation dialog', (tester) async {
      _stubReplaceBidPath(
        taskService: taskService,
        requestsService: requestsService,
        authVm: authVm,
        controller: controller,
        existingBid: _existingBid(),
      );

      await _pumpHost(
        tester,
        taskService: taskService,
        requestsService: requestsService,
        authVm: authVm,
        controller: controller,
      );

      await _openSheet(tester);

      // Fill in new bid values
      final formFields = find.byType(TextFormField);
      await tester.enterText(formFields.at(0), '4000');
      await tester.enterText(formFields.at(1), '3');
      await tester.pump();

      // Tap 'Replace Bid' button
      await tester.tap(find.text('Replace Bid'));
      await tester.pumpAndSettle();

      // Confirmation dialog should appear
      expect(find.text('Replace your bid?'), findsOneWidget);
    });

    testWidgets('T136: confirmation dialog shows comparison', (tester) async {
      _stubReplaceBidPath(
        taskService: taskService,
        requestsService: requestsService,
        authVm: authVm,
        controller: controller,
        existingBid: _existingBid(),
      );

      await _pumpHost(
        tester,
        taskService: taskService,
        requestsService: requestsService,
        authVm: authVm,
        controller: controller,
      );

      await _openSheet(tester);

      final formFields = find.byType(TextFormField);
      await tester.enterText(formFields.at(0), '4000');
      await tester.enterText(formFields.at(1), '3');
      await tester.pump();

      await tester.tap(find.text('Replace Bid'));
      await tester.pumpAndSettle();

      // The dialog shows CURRENT BID and NEW BID sections
      expect(find.text('CURRENT BID'), findsOneWidget);
      expect(find.text('NEW BID'), findsOneWidget);

      // Existing bid: 300000 IQD => 300K IQD, 5 days
      expect(find.text('300K IQD'), findsWidgets);
      expect(find.text('5 days'), findsWidgets);

      // New bid: 4000 IQD => 4K IQD, 3 days
      expect(find.text('4K IQD'), findsWidgets);
      expect(find.text('3 days'), findsWidgets);
    });

    testWidgets('T137: cancel in confirmation does not replace', (
      tester,
    ) async {
      _stubReplaceBidPath(
        taskService: taskService,
        requestsService: requestsService,
        authVm: authVm,
        controller: controller,
        existingBid: _existingBid(),
      );

      await _pumpHost(
        tester,
        taskService: taskService,
        requestsService: requestsService,
        authVm: authVm,
        controller: controller,
      );

      await _openSheet(tester);

      final formFields = find.byType(TextFormField);
      await tester.enterText(formFields.at(0), '4000');
      await tester.enterText(formFields.at(1), '3');
      await tester.pump();

      await tester.tap(find.text('Replace Bid'));
      await tester.pumpAndSettle();

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // replaceOffer should NOT have been called
      verifyNever(
        () => requestsService.replaceOffer(
          taskId: any(named: 'taskId'),
          price: any(named: 'price'),
          days: any(named: 'days'),
          note: any(named: 'note'),
        ),
      );
    });
  });
}
