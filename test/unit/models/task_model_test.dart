import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';

Map<String, dynamic> _taskJson({Map<String, dynamic>? overrides}) {
  final base = <String, dynamic>{
    'id': 'task-1',
    'title': 'Book a photographer',
    'description': 'Need photos for event',
    'budget': 250,
    'user_id': 'user-1',
    'status': 'open',
    'task_type': 'booking',
    'created_at': '2026-02-24T10:00:00Z',
    'skills': ['photo', 'editing'],
    'category': 'Flat Category',
    'profiles': <String, dynamic>{
      'full_name': 'Nested Profile Name',
      'avatar_url': 'nested-avatar.png',
    },
    'user_name': 'Flat Name',
    'user_avatar': 'flat-avatar.png',
    'categories': <String, dynamic>{'name': 'Nested Category'},
    'image_paths': ['tasks/path1.jpg'],
    'offers': 3,
  };
  if (overrides != null) {
    base.addAll(overrides);
  }
  return base;
}

void main() {
  group('Task model T23-T25', () {
    test(
      'T23 Task.fromJson parses booking type and joined profile/category fields',
      () {
        final task = Task.fromJson(
          _taskJson(
            overrides: {
              'profiles': <String, dynamic>{
                'full_name': 'Joined Winner',
                'avatar_url': 'joined-avatar.png',
              },
              'user_name': 'Flat Loser',
              'user_avatar': 'flat-loser.png',
              'categories': <String, dynamic>{'name': 'Joined Category'},
              'category': 'Flat Category Fallback',
            },
          ),
        );

        expect(task.taskType, TaskType.booking);
        expect(task.userName, 'Joined Winner');
        expect(task.userAvatar, 'joined-avatar.png');
        expect(task.categoryName, 'Joined Category');
      },
    );

    test('T24 Task.fromJson maps owner and runtime statuses safely', () {
      final task = Task.fromJson(
        _taskJson(
          overrides: {
            'owner_id': 'owner-77',
            'user_id': 'legacy-user',
            'status': 'in_progress',
          },
        ),
      );

      expect(task.id, 'task-1');
      expect(task.userId, 'owner-77');
      expect(task.status, TaskStatus.inProgress);
    });

    test('T24b Task.fromJson unknown status defaults to TaskStatus.draft', () {
      final task = Task.fromJson(
        _taskJson(overrides: {'status': 'legacy_unknown_status'}),
      );

      expect(task.status, TaskStatus.draft);
    });

    test(
      'T25 Task.toJson(includeSystemFields: false) excludes id and created_at',
      () {
        final task = Task(
          id: 'task-system-id',
          title: 'Task title',
          description: 'Task description',
          budget: 150.0,
          userId: 'user-1',
          status: TaskStatus.assigned,
          taskType: TaskType.booking,
          createdAt: DateTime.utc(2026, 2, 24, 10),
          category: 'Design',
        );

        final json = task.toJson(includeSystemFields: false);

        expect(json.containsKey('id'), isFalse);
        expect(json.containsKey('created_at'), isFalse);
        expect(json['title'], 'Task title');
        expect(json['user_id'], 'user-1');
        expect(json['status'], 'assigned');
        expect(json['task_type'], 'booking');
        expect(json['category'], 'Design');
      },
    );

    test(
      'T25b Task.toJson serializes TaskStatus.inProgress as in_progress',
      () {
        final task = Task(
          id: 'task-progress',
          title: 'Task title',
          description: 'Task description',
          budget: 150.0,
          userId: 'user-1',
          status: TaskStatus.inProgress,
          createdAt: DateTime.utc(2026, 2, 24, 10),
        );

        final json = task.toJson();

        expect(json['status'], 'in_progress');
      },
    );
  });
}
