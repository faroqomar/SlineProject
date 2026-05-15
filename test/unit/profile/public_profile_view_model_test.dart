/// Unit tests for [PublicProfileViewModel].
///
/// Run: `flutter test test/unit/profile/public_profile_view_model_test.dart`
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sline_app/features/portfolio/models/portfolio_item.dart';
import 'package:sline_app/features/profile/models/freelancer_profile.dart';
import 'package:sline_app/features/profile/viewmodels/public_profile_view_model.dart';

import '../../helpers/mock_services.dart';

void main() {
  late MockProfileRepository mockRepo;

  setUp(() {
    mockRepo = MockProfileRepository();
  });

  FreelancerProfile fakeProfile({String id = 'user-1'}) {
    return FreelancerProfile(
      id: id,
      initials: 'JD',
      name: 'Jane Doe',
      verified: true,
      role: 'freelancer',
      title: 'Flutter Developer',
      location: 'Remote',
      jobSuccess: '100%',
      jobsCompleted: 5,
      hourlyRate: r'$50',
      bio: 'Experienced developer.',
      skills: const ['Flutter', 'Dart'],
      portfolio: const <PortfolioItem>[],
      reviews: const <ReviewItem>[],
    );
  }

  group('PublicProfileViewModel', () {
    test('initial state: no profile, not loading, no error', () {
      final vm = PublicProfileViewModel(repository: mockRepo);

      expect(vm.profile, isNull);
      expect(vm.isLoading, isFalse);
      expect(vm.error, isNull);
    });

    test('loadProfile happy path fetches profile by userId', () async {
      final expected = fakeProfile();
      when(
        () => mockRepo.getPublicProfile('user-1'),
      ).thenAnswer((_) async => expected);

      final vm = PublicProfileViewModel(repository: mockRepo);
      await vm.loadProfile('user-1');

      expect(vm.profile, equals(expected));
      expect(vm.isLoading, isFalse);
      expect(vm.error, isNull);
      verify(() => mockRepo.getPublicProfile('user-1')).called(1);
    });

    test('loadProfile error sets error state', () async {
      when(
        () => mockRepo.getPublicProfile('bad-id'),
      ).thenThrow(Exception('Network error'));

      final vm = PublicProfileViewModel(repository: mockRepo);
      await vm.loadProfile('bad-id');

      expect(vm.profile, isNull);
      expect(vm.isLoading, isFalse);
      expect(vm.error, 'Failed to load profile');
    });

    test('loadProfile sets isLoading true during operation', () async {
      final completer = Completer<FreelancerProfile>();
      when(
        () => mockRepo.getPublicProfile('user-1'),
      ).thenAnswer((_) => completer.future);

      final vm = PublicProfileViewModel(repository: mockRepo);
      final future = vm.loadProfile('user-1');

      // While the future has not completed, isLoading should be true
      expect(vm.isLoading, isTrue);
      expect(vm.error, isNull);

      completer.complete(fakeProfile());
      await future;

      expect(vm.isLoading, isFalse);
    });

    test('profile getter returns loaded profile', () async {
      final expected = fakeProfile(id: 'user-42');
      when(
        () => mockRepo.getPublicProfile('user-42'),
      ).thenAnswer((_) async => expected);

      final vm = PublicProfileViewModel(repository: mockRepo);
      await vm.loadProfile('user-42');

      expect(vm.profile?.id, 'user-42');
      expect(vm.profile?.name, 'Jane Doe');
      expect(vm.profile?.skills, containsAll(['Flutter', 'Dart']));
    });

    test('loadProfile keeps profile null when repo throws', () async {
      when(
        () => mockRepo.getPublicProfile('missing'),
      ).thenThrow(Exception('Not found'));

      final vm = PublicProfileViewModel(repository: mockRepo);
      await vm.loadProfile('missing');

      expect(vm.profile, isNull);
      expect(vm.error, 'Failed to load profile');
      expect(vm.isLoading, isFalse);
    });

    test('multiple loads replace previous profile', () async {
      final first = fakeProfile();
      final second = fakeProfile(id: 'user-2');

      when(
        () => mockRepo.getPublicProfile('user-1'),
      ).thenAnswer((_) async => first);
      when(
        () => mockRepo.getPublicProfile('user-2'),
      ).thenAnswer((_) async => second);

      final vm = PublicProfileViewModel(repository: mockRepo);
      await vm.loadProfile('user-1');
      expect(vm.profile?.id, 'user-1');

      await vm.loadProfile('user-2');
      expect(vm.profile?.id, 'user-2');
    });

    test('error is cleared on successful reload', () async {
      when(
        () => mockRepo.getPublicProfile('user-1'),
      ).thenThrow(Exception('fail'));

      final vm = PublicProfileViewModel(repository: mockRepo);
      await vm.loadProfile('user-1');
      expect(vm.error, isNotNull);

      // Now succeed
      when(
        () => mockRepo.getPublicProfile('user-1'),
      ).thenAnswer((_) async => fakeProfile());

      await vm.loadProfile('user-1');
      expect(vm.error, isNull);
      expect(vm.profile, isNotNull);
    });

    test('notifyListeners fires on load start and finish', () async {
      when(
        () => mockRepo.getPublicProfile('user-1'),
      ).thenAnswer((_) async => fakeProfile());

      final vm = PublicProfileViewModel(repository: mockRepo);
      var notifyCount = 0;
      vm.addListener(() => notifyCount++);

      await vm.loadProfile('user-1');

      // Two notifications: start (isLoading=true) and finish (isLoading=false)
      expect(notifyCount, 2);
    });
  });
}
