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

        final json = task.toJson();

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

  group('Task model extended coverage', () {
    test('Minimal JSON (only required fields) — no crash', () {
      final json = <String, dynamic>{
        'id': 'task-min',
        'title': 'Minimal',
        'description': 'Desc',
        'budget': 50,
        'user_id': 'u-1',
        'status': 'open',
        'created_at': '2026-04-01T00:00:00Z',
      };
      final task = Task.fromJson(json);

      expect(task.id, 'task-min');
      expect(task.title, 'Minimal');
      expect(task.budget, 50.0);
      expect(task.userId, 'u-1');
      expect(task.status, TaskStatus.open);
      expect(task.taskType, TaskType.tender); // default
      expect(task.skills, isEmpty);
      expect(task.categoryId, isNull);
      expect(task.category, isNull);
      expect(task.categoryName, isNull);
      expect(task.userName, isNull);
      expect(task.userAvatar, isNull);
      expect(task.authorSellerLevel, isNull);
      expect(task.assignedFreelancerId, isNull);
      expect(task.imagePaths, isEmpty);
      expect(task.packages, isNull);
      expect(task.offers, 0);
      expect(task.deadline, isNull);
    });

    test('Each TaskStatus round-trips through serialization', () {
      // Expected DB strings for each TaskStatus
      final expectedDbStrings = <TaskStatus, String>{
        TaskStatus.open: 'open',
        TaskStatus.assigned: 'assigned',
        TaskStatus.inProgress: 'in_progress',
        TaskStatus.completed: 'completed',
        TaskStatus.closed: 'closed',
        TaskStatus.canceled: 'canceled',
        TaskStatus.draft: 'draft',
      };

      for (final entry in expectedDbStrings.entries) {
        final task = Task(
          id: 'rt-${entry.key.name}',
          title: 'RT',
          description: 'Round trip',
          budget: 10,
          userId: 'u-1',
          status: entry.key,
          createdAt: DateTime.utc(2026, 4),
        );

        final json = task.toJson(includeSystemFields: true);
        expect(
          json['status'],
          entry.value,
          reason: '${entry.key} should serialize to ${entry.value}',
        );

        final restored = Task.fromJson(json);
        expect(
          restored.status,
          entry.key,
          reason: '${entry.key} should round-trip',
        );
      }
    });

    test(
      "Both 'in_progress' and 'inProgress' map to TaskStatus.inProgress",
      () {
        final fromSnake = Task.fromJson(
          _taskJson(overrides: {'status': 'in_progress'}),
        );
        expect(fromSnake.status, TaskStatus.inProgress);

        final fromCamel = Task.fromJson(
          _taskJson(overrides: {'status': 'inProgress'}),
        );
        expect(fromCamel.status, TaskStatus.inProgress);
      },
    );

    test('owner_id vs user_id fallback (prefers owner_id)', () {
      // Case 1: owner_id present — wins over user_id
      final withOwner = Task.fromJson(
        _taskJson(
          overrides: {'owner_id': 'owner-wins', 'user_id': 'user-loses'},
        ),
      );
      expect(withOwner.userId, 'owner-wins');

      // Case 2: owner_id absent, client_id absent — falls back to user_id
      final withoutOwner = Task.fromJson(
        _taskJson(overrides: {'user_id': 'user-fallback'}),
      );
      expect(withoutOwner.userId, 'user-fallback');

      // Case 3: owner_id absent, client_id present — uses client_id before user_id
      final withClient = Task.fromJson(<String, dynamic>{
        ..._taskJson(),
        'owner_id': null,
        'client_id': 'client-middle',
        'user_id': 'user-last',
      });
      expect(withClient.userId, 'client-middle');
    });
  });
}
