import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/widgets/scale_button.dart';
import 'package:sline_app/features/saved/viewmodels/saved_tasks_view_model.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';
import 'package:sline_app/features/tasks/view/widgets/task_card.dart';

import '../../test_support/pump_app.dart';

class _MockSavedTasksViewModel extends Mock
    with ChangeNotifier
    implements SavedTasksViewModel {}

Task _testTask({
  String id = 'task-1',
  String title = 'Build a Website',
  String description = 'Full-stack web development project',
  double budget = 500,
  TaskStatus status = TaskStatus.open,
  TaskType taskType = TaskType.tender,
}) {
  return Task(
    id: id,
    title: title,
    description: description,
    budget: budget,
    userId: 'user-1',
    status: status,
    taskType: taskType,
    createdAt: DateTime.utc(2026, 4),
    skills: const ['Flutter', 'Dart'],
  );
}

void main() {
  group('TaskCard Phase 9 — redesign validations', () {
    testWidgets('renders without 120px header section', (tester) async {
      final task = _testTask();

      await pumpApp(
        tester,
        Scaffold(
          body: TaskCard(task: task, onTap: () {}, useLegacyLayout: true),
        ),
      );

      // The redesigned card should not have a Container with height: 120
      // (the old image header). Find all SizedBox and Container widgets and
      // verify none have height == 120.
      final containerFinder = find.byType(Container);
      final containers = tester.widgetList<Container>(containerFinder);
      final has120Height = containers.any((c) {
        final constraints = c.constraints;
        if (constraints != null && constraints.maxHeight == 120) return true;
        // Also check BoxDecoration height via SizedBox parent
        return false;
      });
      expect(has120Height, isFalse);
    });

    testWidgets('uses ScaleButton for press feedback', (tester) async {
      final task = _testTask();

      await pumpApp(
        tester,
        Scaffold(
          body: TaskCard(task: task, onTap: () {}, useLegacyLayout: true),
        ),
      );

      // Verify ScaleButton is present in the widget tree
      expect(find.byType(ScaleButton), findsOneWidget);
    });

    testWidgets('displays title and status badge', (tester) async {
      final task = _testTask(title: 'Design a Logo');

      await pumpApp(
        tester,
        Scaffold(
          body: TaskCard(task: task, onTap: () {}, useLegacyLayout: true),
        ),
      );

      // Title should be rendered
      expect(find.text('Design a Logo'), findsOneWidget);

      // Tender badge should be rendered
      expect(find.text('TENDER'), findsOneWidget);
    });
  });

  group('TaskCard Phase 3 — Amber Dusk tender card', () {
    late _MockSavedTasksViewModel savedVm;

    setUp(() {
      savedVm = _MockSavedTasksViewModel();
      when(() => savedVm.isSaved(any())).thenReturn(false);
    });

    testWidgets('renders quiet tender hierarchy and preserves tap callback', (
      tester,
    ) async {
      var tapped = false;
      final task = _testTask(
        title: 'Landing page for clothing brand',
        description: 'Creative landing page for a new clothes line',
      );

      await pumpApp(
        tester,
        ChangeNotifierProvider<SavedTasksViewModel>.value(
          value: savedVm,
          child: Scaffold(
            body: SingleChildScrollView(
              child: TaskCard(
                task: task,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Landing page for clothing brand'), findsOneWidget);
      expect(find.text('TASK'), findsOneWidget);
      expect(find.text('Make offer'), findsOneWidget);

      await tester.tap(find.byType(ScaleButton).first);
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}
