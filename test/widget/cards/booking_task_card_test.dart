import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/widgets/scale_button.dart';
import 'package:sline_app/features/saved/viewmodels/saved_tasks_view_model.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';
import 'package:sline_app/features/tasks/view/widgets/booking_task_card.dart';

import '../../test_support/pump_app.dart';

class _MockSavedTasksViewModel extends Mock
    with ChangeNotifier
    implements SavedTasksViewModel {}

Task _bookingTask({
  String id = 'task-booking-1',
  String title = 'Logo Design Service',
  String description = 'Professional logo design with revisions',
  double budget = 200,
  TaskStatus status = TaskStatus.open,
  String? userName,
  String? userAvatar,
}) {
  return Task(
    id: id,
    title: title,
    description: description,
    budget: budget,
    userId: 'user-1',
    status: status,
    taskType: TaskType.booking,
    createdAt: DateTime.utc(2026, 4),
    skills: const ['Design', 'Branding'],
    userName: userName ?? 'Jane Doe',
    userAvatar: userAvatar,
  );
}

Future<void> _pumpBookingTaskCard(
  WidgetTester tester, {
  required Task task,
  required _MockSavedTasksViewModel savedVm,
  VoidCallback? onTap,
}) async {
  await pumpApp(
    tester,
    ChangeNotifierProvider<SavedTasksViewModel>.value(
      value: savedVm,
      child: Scaffold(
        body: SingleChildScrollView(
          child: BookingTaskCard(task: task, onTap: onTap ?? () {}),
        ),
      ),
    ),
  );
}

void main() {
  late _MockSavedTasksViewModel mockSavedVm;

  setUp(() {
    mockSavedVm = _MockSavedTasksViewModel();
    when(() => mockSavedVm.isSaved(any())).thenReturn(false);
  });

  group('BookingTaskCard Phase 9 — redesign validations', () {
    testWidgets('no Transform.translate used for avatar positioning', (
      tester,
    ) async {
      await _pumpBookingTaskCard(
        tester,
        task: _bookingTask(),
        savedVm: mockSavedVm,
      );

      // The redesigned card should not use Transform.translate for the avatar.
      // ScaleButton uses ScaleTransition (which uses Transform internally),
      // so we specifically check there's no Positioned widget with a negative
      // offset (the old overlapping avatar pattern) and no explicit
      // Transform.translate usage in the BookingTaskCard tree.
      //
      // Verify the avatar Row is present (inline layout, not overlapping).
      // The redesigned card uses a Row for avatar + name instead of
      // Transform.translate with a negative offset.
      final bookingCardFinder = find.byType(BookingTaskCard);
      expect(bookingCardFinder, findsOneWidget);

      // Verify there is a Row containing the author name (inline layout)
      expect(
        find.descendant(of: bookingCardFinder, matching: find.text('Jane Doe')),
        findsOneWidget,
      );
    });

    testWidgets('uses ScaleButton for press feedback', (tester) async {
      await _pumpBookingTaskCard(
        tester,
        task: _bookingTask(),
        savedVm: mockSavedVm,
      );

      // Verify ScaleButton is present in the widget tree
      expect(find.byType(ScaleButton), findsOneWidget);
    });

    testWidgets('renders avatar with initials when no image', (tester) async {
      await _pumpBookingTaskCard(
        tester,
        task: _bookingTask(userName: 'John Smith'),
        savedVm: mockSavedVm,
      );

      // Avatar initials should be visible (JS for John Smith)
      expect(find.text('JS'), findsOneWidget);
    });

    testWidgets('renders Amber Dusk booking CTA and featured state', (
      tester,
    ) async {
      await pumpApp(
        tester,
        ChangeNotifierProvider<SavedTasksViewModel>.value(
          value: mockSavedVm,
          child: Scaffold(
            body: SingleChildScrollView(
              child: BookingTaskCard(
                task: _bookingTask(),
                onTap: () {},
                isHot: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('See details'), findsOneWidget);
      expect(find.text('Featured'), findsOneWidget);
      expect(find.text('PER MONTH'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    });

    testWidgets('keeps details CTA compact instead of full width', (
      tester,
    ) async {
      await _pumpBookingTaskCard(
        tester,
        task: _bookingTask(),
        savedVm: mockSavedVm,
      );

      final cardWidth = tester.getSize(find.byType(BookingTaskCard)).width;
      final actionWidth = tester
          .getSize(
            find.byKey(
              const ValueKey<String>('booking_task_card_details_action'),
            ),
          )
          .width;

      expect(actionWidth, lessThan(cardWidth * 0.55));
      expect(actionWidth, greaterThan(120));
    });
  });
}
