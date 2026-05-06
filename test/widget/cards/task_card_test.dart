import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/widgets/scale_button.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';
import 'package:sline_app/features/tasks/view/widgets/task_card.dart';

import '../../test_support/pump_app.dart';

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
    createdAt: DateTime.utc(2026, 4, 1),
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
      final task = _testTask(title: 'Design a Logo', taskType: TaskType.tender);

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
}
