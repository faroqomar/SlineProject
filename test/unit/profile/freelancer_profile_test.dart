/// Unit tests for public profile display mapping.
///
/// These tests protect role-sensitive profile presentation so client profiles
/// cannot accidentally expose freelancer booking actions or impossible stats.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/features/portfolio/models/portfolio_item.dart';
import 'package:sline_app/features/profile/models/freelancer_profile.dart';
import 'package:sline_app/features/profile/models/profile_model.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';

void main() {
  group('FreelancerProfile.fromModel', () {
    test('keeps client profiles out of freelancer hiring state', () {
      final profile = FreelancerProfile.fromModel(
        profile: _profile(activeRole: 'client', skills: const ['Design']),
        portfolio: const <PortfolioItem>[],
      );

      expect(profile.role, 'client');
      expect(profile.title, 'Client');
      expect(profile.isFreelancer, isFalse);
      expect(profile.jobSuccess, '-');
      expect(profile.jobsCompleted, 0);
    });

    test('uses completed history for freelancer proof metrics', () {
      final profile = FreelancerProfile.fromModel(
        profile: _profile(activeRole: 'freelancer', skills: const ['Design']),
        portfolio: const <PortfolioItem>[],
        history: [
          _task(),
          _task(id: 'task-2'),
        ],
      );

      expect(profile.role, 'freelancer');
      expect(profile.title, 'Design');
      expect(profile.isFreelancer, isTrue);
      expect(profile.jobSuccess, '100%');
      expect(profile.jobsCompleted, 2);
    });

    test('ignores non-completed history for freelancer proof metrics', () {
      final profile = FreelancerProfile.fromModel(
        profile: _profile(activeRole: 'freelancer', skills: const ['Design']),
        portfolio: const <PortfolioItem>[],
        history: [
          _task(id: 't1'),
          _task(id: 't2', status: TaskStatus.canceled),
          _task(id: 't3', status: TaskStatus.inProgress),
        ],
      );

      expect(profile.role, 'freelancer');
      expect(profile.title, 'Design');
      expect(profile.isFreelancer, isTrue);
      expect(profile.jobSuccess, '100%');
      expect(profile.jobsCompleted, 1);
    });
  });
}

ProfileModel _profile({
  required String activeRole,
  List<String> skills = const [],
}) {
  return ProfileModel(
    id: 'profile-1',
    fullName: 'Test User',
    email: 'test@example.com',
    activeRole: activeRole,
    skills: skills,
    createdAt: DateTime.utc(2026),
  );
}

Task _task({String id = 'task-1', TaskStatus status = TaskStatus.completed}) {
  return Task(
    id: id,
    title: 'Completed work',
    description: 'Done',
    budget: 100,
    userId: 'client-1',
    status: status,
    createdAt: DateTime.utc(2026),
  );
}
