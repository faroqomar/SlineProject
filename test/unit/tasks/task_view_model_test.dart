import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/features/tasks/data/task_repository.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';
import 'package:sline_app/features/tasks/viewmodels/task_view_model.dart';

class _MockTaskRepository extends Mock implements TaskRepository {}

Task _task({
  required String id,
  required String title,
  TaskStatus status = TaskStatus.open,
}) {
  return Task(
    id: id,
    title: title,
    description: 'Description for $title',
    budget: 100,
    userId: 'user-1',
    status: status,
    createdAt: DateTime.utc(2026, 1, 1),
  );
}

void main() {
  group('TaskViewModel T10-T13', () {
    test('T10 setPickedImages enforces max 5 images', () {
      final viewModel = TaskViewModel(repo: _MockTaskRepository());
      final images = List<XFile>.generate(
        7,
        (index) => XFile('/tmp/task_image_${index + 1}.jpg'),
      );

      viewModel.setPickedImages(images);

      expect(viewModel.pickedImages.length, 5);
      expect(
        viewModel.pickedImages.map((image) => image.path).toList(),
        images.take(5).map((image) => image.path).toList(),
      );

      viewModel.dispose();
    });

    test('T11 removePickedImageAt ignores out-of-range index safely', () {
      final viewModel = TaskViewModel(repo: _MockTaskRepository());
      final images = <XFile>[
        XFile('/tmp/task_image_1.jpg'),
        XFile('/tmp/task_image_2.jpg'),
        XFile('/tmp/task_image_3.jpg'),
      ];
      viewModel.setPickedImages(images);
      final before = viewModel.pickedImages.map((e) => e.path).toList();

      expect(() => viewModel.removePickedImageAt(-1), returnsNormally);
      expect(() => viewModel.removePickedImageAt(99), returnsNormally);

      expect(viewModel.pickedImages.map((e) => e.path).toList(), before);
      viewModel.dispose();
    });

    test('T12 createTask prepends created task and resets loading', () async {
      final repo = _MockTaskRepository();
      final viewModel = TaskViewModel(repo: repo);
      final existing = <Task>[
        _task(id: 'existing-1', title: 'Existing 1'),
        _task(id: 'existing-2', title: 'Existing 2'),
      ];
      final draftInput = _task(id: 'draft', title: 'Draft Input');
      final created = _task(id: 'created-1', title: 'Created Task');

      when(() => repo.getTasks()).thenAnswer((_) async => existing);
      when(() => repo.createTask(draftInput)).thenAnswer((_) async => created);

      await viewModel.loadTasks();
      final result = await viewModel.createTask(draftInput);

      expect(result.id, created.id);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.tasks.map((t) => t.id).toList(), [
        'created-1',
        'existing-1',
        'existing-2',
      ]);
      verify(() => repo.getTasks()).called(1);
      verify(() => repo.createTask(draftInput)).called(1);
      viewModel.dispose();
    });

    test(
      'T13 updateTaskStatus updates local task status optimistically',
      () async {
        final repo = _MockTaskRepository();
        final viewModel = TaskViewModel(repo: repo);
        final seededTasks = <Task>[
          _task(id: 'task-a', title: 'Task A', status: TaskStatus.open),
          _task(id: 'task-b', title: 'Task B', status: TaskStatus.assigned),
        ];

        when(() => repo.getTasks()).thenAnswer((_) async => seededTasks);
        when(
          () => repo.updateTaskStatus('task-a', TaskStatus.completed),
        ).thenAnswer((_) async {});

        await viewModel.loadTasks();
        await viewModel.updateTaskStatus('task-a', TaskStatus.completed);

        final ids = viewModel.tasks.map((t) => t.id).toList();
        final statuses = {
          for (final task in viewModel.tasks) task.id: task.status,
        };

        expect(ids, ['task-a', 'task-b']);
        expect(statuses['task-a'], TaskStatus.completed);
        expect(statuses['task-b'], TaskStatus.assigned);
        verify(
          () => repo.updateTaskStatus('task-a', TaskStatus.completed),
        ).called(1);
        viewModel.dispose();
      },
    );
  });
}
