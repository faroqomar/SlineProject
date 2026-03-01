import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sline_app/features/profile/data/profile_repository.dart';
import 'package:sline_app/features/profile/models/profile_model.dart';
import 'package:sline_app/features/profile/viewmodels/profile_view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

class _MockUser extends Mock implements User {}

void main() {
  group('ProfileViewModel.loadHeaderProfile', () {
    late _MockProfileRepository repository;
    late _MockUser user;
    late ProfileViewModel viewModel;

    setUp(() {
      repository = _MockProfileRepository();
      user = _MockUser();
      viewModel = ProfileViewModel(repository: repository);

      when(() => user.id).thenReturn('user-1');
      when(() => user.email).thenReturn('user@example.com');
      when(() => repository.currentUser).thenReturn(user);
      when(() => repository.fetchProfileSummary('user-1')).thenAnswer(
        (_) async => ProfileModel(
          id: 'user-1',
          fullName: 'Ada Lovelace',
          avatarUrl: 'avatars/user-1/avatar.png',
          bio: 'Builds systems.',
          activeRole: 'freelancer',
          skills: const ['Flutter'],
          sellerLevel: 'level_2',
          createdAt: DateTime.utc(2026, 3, 1),
        ),
      );
      when(
        () => repository.getAvatarPath('user-1'),
      ).thenAnswer((_) async => 'user-1/avatar.png');
      when(
        () => repository.createSignedAvatarUrl('user-1/avatar.png'),
      ).thenAnswer((_) async => 'https://signed/avatar.png');
      when(
        () => repository.getPortfolioItems(any()),
      ).thenAnswer((_) async => <Map<String, dynamic>>[]);
    });

    test('loads header-safe data without fetching portfolio', () async {
      await viewModel.loadHeaderProfile();

      expect(viewModel.fullName, 'Ada Lovelace');
      expect(viewModel.avatarUrl, 'https://signed/avatar.png');
      expect(viewModel.skills, <String>['Flutter']);
      verify(() => repository.fetchProfileSummary('user-1')).called(1);
      verify(() => repository.getAvatarPath('user-1')).called(1);
      verifyNever(() => repository.getPortfolioItems(any()));
    });
  });
}
