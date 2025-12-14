// SLine App Widget Tests
//
// These tests verify core functionality of the SLine freelance marketplace app.
// The app requires Supabase initialization which is mocked for tests.

import 'package:flutter_test/flutter_test.dart';

import 'package:sline_app/core/models/user_profile.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';

void main() {
  group('UserProfile Model', () {
    test('fromMap creates valid UserProfile', () {
      final map = {
        'id': 'user-123',
        'full_name': 'John Doe',
        'email': 'john@example.com',
        'avatar_url': 'avatars/user-123/profile.jpg',
      };

      final profile = UserProfile.fromMap(map);

      expect(profile.id, 'user-123');
      expect(profile.fullName, 'John Doe');
      expect(profile.email, 'john@example.com');
      expect(profile.avatarUrl, 'avatars/user-123/profile.jpg');
    });

    test('toMap converts UserProfile to map', () {
      final profile = UserProfile(
        id: 'user-456',
        fullName: 'Jane Doe',
        email: 'jane@example.com',
      );

      final map = profile.toMap();

      expect(map['id'], 'user-456');
      expect(map['full_name'], 'Jane Doe');
      expect(map['email'], 'jane@example.com');
      expect(map['avatar_url'], isNull);
    });
  });

  group('Task Model', () {
    test('fromJson parses task correctly', () {
      final json = {
        'id': 'task-123',
        'title': 'Build Flutter App',
        'description': 'Create a mobile app',
        'budget': 500.0,
        'user_id': 'user-123',
        'status': 'open',
        'task_type': 'tender',
        'created_at': '2024-01-15T10:00:00Z',
        'skills': ['Flutter', 'Dart'],
        'category': 'Development',
      };

      final task = Task.fromJson(json);

      expect(task.id, 'task-123');
      expect(task.title, 'Build Flutter App');
      expect(task.description, 'Create a mobile app');
      expect(task.budget, 500.0);
      expect(task.userId, 'user-123');
      expect(task.status, TaskStatus.open);
      expect(task.taskType, TaskType.tender);
      expect(task.isTender, true);
      expect(task.isBooking, false);
      expect(task.skills, contains('Flutter'));
    });

    test('task type correctly identifies booking tasks', () {
      final json = {
        'id': 'task-456',
        'title': 'Consultation Service',
        'description': 'Book a session',
        'budget': 200.0,
        'user_id': 'user-123',
        'status': 'open',
        'task_type': 'booking',
        'created_at': '2024-01-15T10:00:00Z',
      };

      final task = Task.fromJson(json);

      expect(task.taskType, TaskType.booking);
      expect(task.isTender, false);
      expect(task.isBooking, true);
    });

    test('copyWith creates modified task', () {
      final original = Task(
        id: 'task-789',
        title: 'Original Title',
        description: 'Original description',
        budget: 100.0,
        userId: 'user-123',
        status: TaskStatus.open,
        createdAt: DateTime(2024, 1, 15),
      );

      final modified = original.copyWith(
        title: 'Updated Title',
        budget: 150.0,
        status: TaskStatus.assigned,
      );

      expect(modified.id, 'task-789');
      expect(modified.title, 'Updated Title');
      expect(modified.description, 'Original description');
      expect(modified.budget, 150.0);
      expect(modified.status, TaskStatus.assigned);
    });
  });

  group('TaskStatus Enum', () {
    test('all status values are accessible', () {
      expect(TaskStatus.values, contains(TaskStatus.open));
      expect(TaskStatus.values, contains(TaskStatus.assigned));
      expect(TaskStatus.values, contains(TaskStatus.closed));
      expect(TaskStatus.values, contains(TaskStatus.inProgress));
    });
  });

  group('TaskType Enum', () {
    test('all task types are accessible', () {
      expect(TaskType.values, contains(TaskType.tender));
      expect(TaskType.values, contains(TaskType.booking));
    });
  });
}
