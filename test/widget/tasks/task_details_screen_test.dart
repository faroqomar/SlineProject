// Widget tests for TaskDetailsScreen.
//
// Type A screen: StatefulWidget that reads TaskViewModel, ChatViewModel,
// AccountGuardService, and SafetyViewModel from context.
// Tests inject file-local mocks via Provider ancestors.
//
// Supabase.initialize is called in setUpAll to prevent assertion errors from
// OrderManagementSection (rendered when currentUserId is non-null), which
// internally creates WorkLogService -> Supabase.instance.client.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/account_guard_service.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/app_card_container.dart';
import 'package:sline_app/features/chat/viewmodels/chat_view_model.dart';
import 'package:sline_app/features/safety/viewmodels/safety_view_model.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';
import 'package:sline_app/features/tasks/view/task_details_screen.dart';
import 'package:sline_app/features/tasks/viewmodels/task_view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../supabase_test_helper.dart';
import '../../test_support/pump_app.dart';

// ---------------------------------------------------------------------------
// File-local mocks
// ---------------------------------------------------------------------------
class _MockTaskViewModel extends Mock
    with ChangeNotifier
    implements TaskViewModel {}

class _MockChatViewModel extends Mock
    with ChangeNotifier
    implements ChatViewModel {}

class _MockAccountGuardService extends Mock implements AccountGuardService {}

class _MockSafetyViewModel extends Mock
    with ChangeNotifier
    implements SafetyViewModel {}

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------
const _kOwnerId = 'owner-1';
const _kFreelancerId = 'freelancer-1';

// ---------------------------------------------------------------------------
// Factory helpers
// ---------------------------------------------------------------------------

/// Creates a Task with sensible defaults for tender-type tasks.
Task _task({
  String id = 'task-1',
  String title = 'Build a Website',
  String description = 'Full-stack web development project',
  double budget = 500,
  String userId = _kOwnerId,
  TaskStatus status = TaskStatus.open,
  TaskType taskType = TaskType.tender,
  DateTime? createdAt,
  DateTime? deadline,
  String? categoryName,
  String? userName,
  List<String> imagePaths = const [],
  Map<String, dynamic>? packages,
  int offers = 0,
}) {
  return Task(
    id: id,
    title: title,
    description: description,
    budget: budget,
    userId: userId,
    status: status,
    taskType: taskType,
    createdAt: createdAt ?? DateTime.utc(2026, 4, 1),
    deadline: deadline,
    categoryName: categoryName,
    userName: userName,
    imagePaths: imagePaths,
    packages: packages,
    offers: offers,
  );
}

/// Creates a booking-type Task with package data.
Task _bookingTask({
  String id = 'task-booking-1',
  String title = 'Logo Design Service',
  String description = 'Professional logo design with revisions',
  double budget = 200,
  String userId = _kOwnerId,
  TaskStatus status = TaskStatus.open,
  int offers = 0,
}) {
  return _task(
    id: id,
    title: title,
    description: description,
    budget: budget,
    userId: userId,
    status: status,
    taskType: TaskType.booking,
    offers: offers,
    packages: <String, dynamic>{
      'Basic': <String, dynamic>{
        'price': 100,
        'delivery': 3,
        'revisions': 1,
        'description': 'Basic logo package',
      },
      'Standard': <String, dynamic>{
        'price': 200,
        'delivery': 5,
        'revisions': 3,
        'description': 'Standard logo package',
      },
      'Premium': <String, dynamic>{
        'price': 500,
        'delivery': 7,
        'revisions': 'Unlimited',
        'description': 'Premium logo package',
      },
    },
  );
}

/// Pump the TaskDetailsScreen wrapped in required providers.
///
/// Sets [currentUserId] on the mock TaskViewModel to control owner vs
/// non-owner rendering. Defaults to [_kFreelancerId] (non-owner).
Future<void> _pumpScreen(
  WidgetTester tester, {
  required Task task,
  required _MockTaskViewModel taskVm,
  required _MockChatViewModel chatVm,
  required _MockAccountGuardService guardService,
  required _MockSafetyViewModel safetyVm,
  String? currentUserId = _kFreelancerId,
  bool showProposalsInitially = false,
}) async {
  when(() => taskVm.currentUserId).thenReturn(currentUserId);

  await pumpApp(
    tester,
    MultiProvider(
      providers: [
        ChangeNotifierProvider<TaskViewModel>.value(value: taskVm),
        ChangeNotifierProvider<ChatViewModel>.value(value: chatVm),
        Provider<AccountGuardService>.value(value: guardService),
        ChangeNotifierProvider<SafetyViewModel>.value(value: safetyVm),
      ],
      child: TaskDetailsScreen(
        task: task,
        showProposalsInitially: showProposalsInitially,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  late _MockTaskViewModel mockTaskVm;
  late _MockChatViewModel mockChatVm;
  late _MockAccountGuardService mockGuard;
  late _MockSafetyViewModel mockSafety;

  setUpAll(() async {
    ensureSupabaseTestEnvironment();
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      anonKey: 'test-anon-key',
      debug: false,
      authOptions: FlutterAuthClientOptions(
        localStorage: supabaseTestLocalStorage,
        pkceAsyncStorage: supabaseTestPkceStorage,
      ),
    );
  });

  setUp(() {
    mockTaskVm = _MockTaskViewModel();
    mockChatVm = _MockChatViewModel();
    mockGuard = _MockAccountGuardService();
    mockSafety = _MockSafetyViewModel();

    // Default stubs
    when(
      () => mockGuard.canPerformSensitiveAction(),
    ).thenAnswer((_) async => true);
    when(
      () => mockSafety.submitReport(
        entityType: any(named: 'entityType'),
        entityId: any(named: 'entityId'),
        reason: any(named: 'reason'),
      ),
    ).thenAnswer((_) async => true);
  });

  group('TaskDetailsScreen T230-T243', () {
    // ---- T230: Renders widget ------------------------------------------------

    testWidgets('T230 renders TaskDetailsScreen widget', (tester) async {
      await _pumpScreen(
        tester,
        task: _task(),
        taskVm: mockTaskVm,
        chatVm: mockChatVm,
        guardService: mockGuard,
        safetyVm: mockSafety,
        currentUserId: null,
      );
      await tester.pump();

      expect(find.byType(TaskDetailsScreen), findsOneWidget);
    });

    // ---- T231: Shows task title ----------------------------------------------

    testWidgets('T231 shows task title', (tester) async {
      await _pumpScreen(
        tester,
        task: _task(title: 'Design a Mobile App'),
        taskVm: mockTaskVm,
        chatVm: mockChatVm,
        guardService: mockGuard,
        safetyVm: mockSafety,
        currentUserId: null,
      );
      await tester.pump();

      expect(find.text('Design a Mobile App'), findsOneWidget);
    });

    // ---- T232: Shows task description ----------------------------------------

    testWidgets('T232 shows task description', (tester) async {
      await _pumpScreen(
        tester,
        task: _task(description: 'Create a cross-platform Flutter app'),
        taskVm: mockTaskVm,
        chatVm: mockChatVm,
        guardService: mockGuard,
        safetyVm: mockSafety,
        currentUserId: null,
      );
      await tester.pump();

      expect(find.text('Create a cross-platform Flutter app'), findsOneWidget);
    });

    // ---- T233: Shows task budget (via booking package price) -----------------

    testWidgets('T233 shows task budget in booking package price', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        task: _bookingTask(),
        taskVm: mockTaskVm,
        chatVm: mockChatVm,
        guardService: mockGuard,
        safetyVm: mockSafety,
        currentUserId: null,
      );
      await tester.pump();

      // The Basic package has price 100 displayed as "$100"
      expect(find.text(r'$100'), findsOneWidget);
    });

    // ---- T234: Shows author userName in author section -----------------------

    testWidgets('T234 shows author userName in author section', (tester) async {
      await _pumpScreen(
        tester,
        task: _task(userName: 'John Designer'),
        taskVm: mockTaskVm,
        chatVm: mockChatVm,
        guardService: mockGuard,
        safetyVm: mockSafety,
        currentUserId: null,
      );
      await tester.pump();

      expect(find.text('John Designer'), findsOneWidget);
      // Verified badge is always shown
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    // ---- T235: Shows Apply Now CTA for non-owner freelancer on tender -------

    testWidgets('T235 shows Apply Now button for non-owner freelancer', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        task: _task(userId: _kOwnerId),
        taskVm: mockTaskVm,
        chatVm: mockChatVm,
        guardService: mockGuard,
        safetyVm: mockSafety,
        currentUserId: _kFreelancerId,
      );
      await tester.pump();

      expect(find.text('Apply Now'), findsOneWidget);
    });

    // ---- T236: Hides bid CTA for task owner (shows Manage Task) -------------

    testWidgets('T236 shows Manage Task for owner instead of Apply Now', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        task: _task(userId: _kOwnerId),
        taskVm: mockTaskVm,
        chatVm: mockChatVm,
        guardService: mockGuard,
        safetyVm: mockSafety,
        currentUserId: _kOwnerId,
      );
      await tester.pump();

      expect(find.text('Manage Task'), findsOneWidget);
      expect(find.text('Apply Now'), findsNothing);
    });

    // ---- T237: Shows View Received Proposals for owner of tender ------------

    testWidgets('T237 shows View Received Proposals for owner of tender', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        task: _task(userId: _kOwnerId, offers: 5),
        taskVm: mockTaskVm,
        chatVm: mockChatVm,
        guardService: mockGuard,
        safetyVm: mockSafety,
        currentUserId: _kOwnerId,
      );
      await tester.pump();

      expect(find.text('View Received Proposals'), findsOneWidget);
    });

    // ---- T238: Renders correctly when deadline is present --------------------

    testWidgets('T238 renders correctly when deadline is present', (
      tester,
    ) async {
      final deadline = DateTime.utc(2026, 6, 15);
      await _pumpScreen(
        tester,
        task: _task(deadline: deadline),
        taskVm: mockTaskVm,
        chatVm: mockChatVm,
        guardService: mockGuard,
        safetyVm: mockSafety,
        currentUserId: null,
      );
      await tester.pump();

      expect(find.byType(TaskDetailsScreen), findsOneWidget);
    });

    // ---- T239: Manage Task button disabled for owner -------------------------

    testWidgets('T239 Manage Task button is disabled for owner', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        task: _task(userId: _kOwnerId, status: TaskStatus.open),
        taskVm: mockTaskVm,
        chatVm: mockChatVm,
        guardService: mockGuard,
        safetyVm: mockSafety,
        currentUserId: _kOwnerId,
      );
      await tester.pump();

      // _canTriggerPrimaryAction returns false for owner, so onPressed is null
      expect(find.text('Manage Task'), findsOneWidget);
      final appButton = tester.widget<AppButton>(
        find.byWidgetPredicate(
          (w) => w is AppButton && w.text == 'Manage Task',
        ),
      );
      expect(appButton.onPressed, isNull);
    });

    // ---- T240: Closed task bottom bar still renders -------------------------

    testWidgets(
      'T240 closed task shows Manage Task for owner, no chat bubble',
      (tester) async {
        await _pumpScreen(
          tester,
          task: _task(userId: _kOwnerId, status: TaskStatus.closed),
          taskVm: mockTaskVm,
          chatVm: mockChatVm,
          guardService: mockGuard,
          safetyVm: mockSafety,
          currentUserId: _kOwnerId,
        );
        await tester.pump();

        expect(find.text('Manage Task'), findsOneWidget);
        expect(find.byIcon(Icons.chat_bubble_outline), findsNothing);
      },
    );

    // ---- T241: No loading spinner for pre-fetched task ----------------------

    testWidgets('T241 no loading spinner for passed-in task', (tester) async {
      await _pumpScreen(
        tester,
        task: _task(),
        taskVm: mockTaskVm,
        chatVm: mockChatVm,
        guardService: mockGuard,
        safetyVm: mockSafety,
        currentUserId: null,
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(TaskDetailsScreen), findsOneWidget);
    });

    // ---- T242: Booking type shows package selector tabs ---------------------

    testWidgets('T242 booking type shows package selector tabs', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        task: _bookingTask(),
        taskVm: mockTaskVm,
        chatVm: mockChatVm,
        guardService: mockGuard,
        safetyVm: mockSafety,
        currentUserId: null,
      );
      await tester.pump();

      expect(find.text('Basic'), findsOneWidget);
      expect(find.text('Standard'), findsOneWidget);
      expect(find.text('Premium'), findsOneWidget);
    });

    // ---- T243: Tender type shows Apply Now button ---------------------------

    testWidgets('T243 tender type shows Apply Now, no package selector', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        task: _task(taskType: TaskType.tender),
        taskVm: mockTaskVm,
        chatVm: mockChatVm,
        guardService: mockGuard,
        safetyVm: mockSafety,
        currentUserId: _kFreelancerId,
      );
      await tester.pump();

      expect(find.text('Apply Now'), findsOneWidget);
      expect(find.text('Basic'), findsNothing);
      expect(find.text('Standard'), findsNothing);
      expect(find.text('Premium'), findsNothing);
    });

    // ---- Additional coverage ------------------------------------------------

    testWidgets('T244 header shows Job Details for tender task', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        task: _task(taskType: TaskType.tender),
        taskVm: mockTaskVm,
        chatVm: mockChatVm,
        guardService: mockGuard,
        safetyVm: mockSafety,
        currentUserId: null,
      );
      await tester.pump();

      expect(find.text('Job Details'), findsOneWidget);
    });

    testWidgets('T245 header shows Booking Details for booking task', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        task: _bookingTask(),
        taskVm: mockTaskVm,
        chatVm: mockChatVm,
        guardService: mockGuard,
        safetyVm: mockSafety,
        currentUserId: null,
      );
      await tester.pump();

      expect(find.text('Booking Details'), findsOneWidget);
    });

    testWidgets('T246 non-owner sees chat bubble icon', (tester) async {
      await _pumpScreen(
        tester,
        task: _task(userId: _kOwnerId),
        taskVm: mockTaskVm,
        chatVm: mockChatVm,
        guardService: mockGuard,
        safetyVm: mockSafety,
        currentUserId: _kFreelancerId,
      );
      await tester.pump();

      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    });

    testWidgets('T247 owner does not see chat bubble icon', (tester) async {
      await _pumpScreen(
        tester,
        task: _task(userId: _kOwnerId),
        taskVm: mockTaskVm,
        chatVm: mockChatVm,
        guardService: mockGuard,
        safetyVm: mockSafety,
        currentUserId: _kOwnerId,
      );
      await tester.pump();

      expect(find.byIcon(Icons.chat_bubble_outline), findsNothing);
    });

    testWidgets('T248 flag/report button is always visible', (tester) async {
      await _pumpScreen(
        tester,
        task: _task(),
        taskVm: mockTaskVm,
        chatVm: mockChatVm,
        guardService: mockGuard,
        safetyVm: mockSafety,
        currentUserId: _kFreelancerId,
      );
      await tester.pump();

      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
    });

    testWidgets('T249 AppCardContainer wraps header and bottom bar', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        task: _task(),
        taskVm: mockTaskVm,
        chatVm: mockChatVm,
        guardService: mockGuard,
        safetyVm: mockSafety,
        currentUserId: null,
      );
      await tester.pump();

      // Header AppCardContainer + bottom bar AppCardContainer = at least 2
      expect(find.byType(AppCardContainer), findsAtLeastNWidgets(2));
    });

    testWidgets('T250 back arrow icon is present in header', (tester) async {
      await _pumpScreen(
        tester,
        task: _task(),
        taskVm: mockTaskVm,
        chatVm: mockChatVm,
        guardService: mockGuard,
        safetyVm: mockSafety,
        currentUserId: null,
      );
      await tester.pump();

      expect(find.byIcon(Icons.arrow_back_ios), findsOneWidget);
    });

    testWidgets('T251 share icon is present in header', (tester) async {
      await _pumpScreen(
        tester,
        task: _task(),
        taskVm: mockTaskVm,
        chatVm: mockChatVm,
        guardService: mockGuard,
        safetyVm: mockSafety,
        currentUserId: null,
      );
      await tester.pump();

      expect(find.byIcon(Icons.share), findsOneWidget);
    });

    testWidgets('T252 View Profile text appears in author section', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        task: _task(userName: 'Alice'),
        taskVm: mockTaskVm,
        chatVm: mockChatVm,
        guardService: mockGuard,
        safetyVm: mockSafety,
        currentUserId: null,
      );
      await tester.pump();

      expect(find.text('View Profile'), findsOneWidget);
    });

    testWidgets('T253 unknown user fallback when userName is null', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        task: _task(userName: null),
        taskVm: mockTaskVm,
        chatVm: mockChatVm,
        guardService: mockGuard,
        safetyVm: mockSafety,
        currentUserId: null,
      );
      await tester.pump();

      expect(find.text('Unknown User'), findsOneWidget);
    });

    testWidgets('T254 booking non-open status shows Booking Unavailable', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        task: _bookingTask(status: TaskStatus.completed, userId: _kOwnerId),
        taskVm: mockTaskVm,
        chatVm: mockChatVm,
        guardService: mockGuard,
        safetyVm: mockSafety,
        currentUserId: _kFreelancerId,
      );
      await tester.pump();

      expect(find.text('Booking Unavailable'), findsOneWidget);
    });

    testWidgets('T255 booking open status shows Book Basic by default', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        task: _bookingTask(userId: _kOwnerId),
        taskVm: mockTaskVm,
        chatVm: mockChatVm,
        guardService: mockGuard,
        safetyVm: mockSafety,
        currentUserId: _kFreelancerId,
      );
      await tester.pump();

      expect(find.text('Book Basic'), findsOneWidget);
    });

    testWidgets('T256 package details show delivery days and revisions', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        task: _bookingTask(),
        taskVm: mockTaskVm,
        chatVm: mockChatVm,
        guardService: mockGuard,
        safetyVm: mockSafety,
        currentUserId: null,
      );
      await tester.pump();

      // Basic package: 3 Days delivery, 1 Revision (singular)
      expect(find.text('3 Days'), findsOneWidget);
      expect(find.text('1 Revision'), findsOneWidget);
    });

    testWidgets('T257 tapping Standard tier switches package details', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        task: _bookingTask(userId: _kOwnerId),
        taskVm: mockTaskVm,
        chatVm: mockChatVm,
        guardService: mockGuard,
        safetyVm: mockSafety,
        currentUserId: _kFreelancerId,
      );
      await tester.pump();

      // Initially shows Basic price
      expect(find.text(r'$100'), findsOneWidget);

      // Tap Standard tier
      await tester.tap(find.text('Standard'));
      await tester.pump();

      // Now shows Standard price and button text
      expect(find.text(r'$200'), findsOneWidget);
      expect(find.text('Book Standard'), findsOneWidget);
    });

    testWidgets('T258 proposals link hidden for non-owner on tender', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        task: _task(userId: _kOwnerId, offers: 3),
        taskVm: mockTaskVm,
        chatVm: mockChatVm,
        guardService: mockGuard,
        safetyVm: mockSafety,
        currentUserId: _kFreelancerId,
      );
      await tester.pump();

      expect(find.text('View Received Proposals'), findsNothing);
    });

    testWidgets('T259 flag button opens Report Task dialog', (tester) async {
      await _pumpScreen(
        tester,
        task: _task(),
        taskVm: mockTaskVm,
        chatVm: mockChatVm,
        guardService: mockGuard,
        safetyVm: mockSafety,
        currentUserId: _kFreelancerId,
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.flag_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Report Task'), findsOneWidget);
      expect(find.text('Describe the issue'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Submit'), findsOneWidget);
    });

    testWidgets('T260 booking package description shown in details card', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        task: _bookingTask(),
        taskVm: mockTaskVm,
        chatVm: mockChatVm,
        guardService: mockGuard,
        safetyVm: mockSafety,
        currentUserId: null,
      );
      await tester.pump();

      expect(find.text('Basic logo package'), findsOneWidget);
    });

    testWidgets('T261 BASIC tier badge shown in package details', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        task: _bookingTask(),
        taskVm: mockTaskVm,
        chatVm: mockChatVm,
        guardService: mockGuard,
        safetyVm: mockSafety,
        currentUserId: null,
      );
      await tester.pump();

      // _selectedPackageTier.toUpperCase() for the badge
      expect(find.text('BASIC'), findsOneWidget);
    });
  });
}
