/// Unit tests for [UserProfileViewModel].
///
/// Run: `flutter test test/unit/profile/user_profile_view_model_test.dart`
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sline_app/features/chat/models/conversation_model.dart';
import 'package:sline_app/features/portfolio/models/portfolio_item.dart';
import 'package:sline_app/features/profile/models/profile_model.dart';
import 'package:sline_app/features/profile/viewmodels/user_profile_view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/mock_services.dart';

class _MockUser extends Mock implements User {}

void main() {
  late MockProfileRepository mockProfileRepo;
  late MockMessageService mockMessageService;
  late _MockUser mockUser;

  final testProfileModel = ProfileModel(
    id: 'target-user',
    fullName: 'Alice Smith',
    avatarUrl: 'avatars/alice.png',
    bio: 'Designer and developer.',
    activeRole: 'freelancer',
    skills: const ['Design', 'Flutter'],
    createdAt: DateTime.utc(2026, 1, 15),
  );

  final testPortfolioItems = [
    PortfolioItem(
      id: 'p-1',
      ownerId: 'target-user',
      title: 'Project Alpha',
      description: 'A cool project',
      createdAt: DateTime.utc(2026, 2),
    ),
    PortfolioItem(
      id: 'p-2',
      ownerId: 'target-user',
      title: 'Project Beta',
      createdAt: DateTime.utc(2026, 3),
    ),
  ];

  final testConversation = Conversation(
    id: 'conv-1',
    user1Id: 'current-user',
    user2Id: 'target-user',
    createdAt: DateTime.utc(2026, 3, 10),
  );

  setUp(() {
    mockProfileRepo = MockProfileRepository();
    mockMessageService = MockMessageService();
    mockUser = _MockUser();
  });

  /// Helper to build VM with standard wiring.
  UserProfileViewModel buildVm({String userId = 'target-user'}) {
    return UserProfileViewModel(
      userId: userId,
      profileRepo: mockProfileRepo,
      messageService: mockMessageService,
    );
  }

  /// Stub the happy-path load chain.
  void stubHappyLoad() {
    when(
      () => mockProfileRepo.fetchProfile('target-user'),
    ).thenAnswer((_) async => testProfileModel);
    when(
      () => mockProfileRepo.getPortfolioItems('target-user'),
    ).thenAnswer((_) async => testPortfolioItems);
  }

  group('UserProfileViewModel', () {
    test('initial state: isLoading true, no profile, no error', () {
      final vm = buildVm();

      expect(vm.isLoading, isTrue);
      expect(vm.profile, isNull);
      expect(vm.error, isNull);
      expect(vm.portfolio, isEmpty);
    });

    test('load happy path fetches profile and portfolio', () async {
      stubHappyLoad();

      final vm = buildVm();
      await vm.load();

      expect(vm.isLoading, isFalse);
      expect(vm.error, isNull);
      expect(vm.profile, isNotNull);
      expect(vm.profile!.id, 'target-user');
      expect(vm.profile!.fullName, 'Alice Smith');
      expect(vm.portfolio.length, 2);
      verify(() => mockProfileRepo.fetchProfile('target-user')).called(1);
      verify(() => mockProfileRepo.getPortfolioItems('target-user')).called(1);
    });

    test('load error sets error state', () async {
      when(
        () => mockProfileRepo.fetchProfile('target-user'),
      ).thenThrow(Exception('DB down'));

      final vm = buildVm();
      await vm.load();

      expect(vm.isLoading, isFalse);
      expect(vm.error, 'Failed to load profile. Please try again.');
      expect(vm.profile, isNull);
    });

    test(
      'load: portfolio failure is non-critical (profile still loads)',
      () async {
        when(
          () => mockProfileRepo.fetchProfile('target-user'),
        ).thenAnswer((_) async => testProfileModel);
        when(
          () => mockProfileRepo.getPortfolioItems('target-user'),
        ).thenThrow(Exception('RLS denied'));

        final vm = buildVm();
        await vm.load();

        expect(vm.profile, isNotNull);
        expect(vm.portfolio, isEmpty);
        expect(vm.error, isNull);
      },
    );

    test('getOrCreateConversation happy path', () async {
      when(() => mockUser.id).thenReturn('current-user');
      when(() => mockProfileRepo.currentUser).thenReturn(mockUser);
      when(
        () => mockMessageService.createOrGetConversation(
          user1Id: 'current-user',
          user2Id: 'target-user',
        ),
      ).thenAnswer((_) async => testConversation);

      final vm = buildVm();
      final result = await vm.getOrCreateConversation();

      expect(result, isNotNull);
      expect(result!.id, 'conv-1');
      verify(
        () => mockMessageService.createOrGetConversation(
          user1Id: 'current-user',
          user2Id: 'target-user',
        ),
      ).called(1);
    });

    test(
      'getOrCreateConversation returns null when not authenticated',
      () async {
        when(() => mockProfileRepo.currentUser).thenReturn(null);

        final vm = buildVm();
        final result = await vm.getOrCreateConversation();

        expect(result, isNull);
        verifyNever(
          () => mockMessageService.createOrGetConversation(
            user1Id: any(named: 'user1Id'),
            user2Id: any(named: 'user2Id'),
          ),
        );
      },
    );

    test('getOrCreateConversation returns null for same user', () async {
      when(() => mockUser.id).thenReturn('target-user');
      when(() => mockProfileRepo.currentUser).thenReturn(mockUser);

      final vm = buildVm();
      final result = await vm.getOrCreateConversation();

      expect(result, isNull);
      verifyNever(
        () => mockMessageService.createOrGetConversation(
          user1Id: any(named: 'user1Id'),
          user2Id: any(named: 'user2Id'),
        ),
      );
    });

    test('portfolio getter returns loaded portfolio items', () async {
      stubHappyLoad();

      final vm = buildVm();
      await vm.load();

      expect(vm.portfolio.length, 2);
      expect(vm.portfolio[0].title, 'Project Alpha');
      expect(vm.portfolio[1].title, 'Project Beta');
    });

    test('isLoading flag management across load lifecycle', () async {
      final completer = Completer<ProfileModel>();
      when(
        () => mockProfileRepo.fetchProfile('target-user'),
      ).thenAnswer((_) => completer.future);

      final vm = buildVm();
      // isLoading starts true by default from constructor
      expect(vm.isLoading, isTrue);

      final future = vm.load();
      // Still loading during fetch
      expect(vm.isLoading, isTrue);

      when(
        () => mockProfileRepo.getPortfolioItems('target-user'),
      ).thenAnswer((_) async => <PortfolioItem>[]);
      completer.complete(testProfileModel);
      await future;

      expect(vm.isLoading, isFalse);
    });

    test('retry calls load again', () async {
      stubHappyLoad();

      final vm = buildVm();
      await vm.load();
      verify(() => mockProfileRepo.fetchProfile('target-user')).called(1);

      // retry() calls load() internally (fire-and-forget)
      vm.retry();
      // Allow the microtask to complete
      await Future<void>.delayed(Duration.zero);
      verify(() => mockProfileRepo.fetchProfile('target-user')).called(1);
    });

    test('currentUserId getter returns repo current user id', () {
      when(() => mockUser.id).thenReturn('my-id');
      when(() => mockProfileRepo.currentUser).thenReturn(mockUser);

      final vm = buildVm();
      expect(vm.currentUserId, 'my-id');
    });
  });
}
