// Schema ref: profiles table in SUPABASE_SETUP.md
import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/features/profile/models/profile_model.dart';

/// Full valid JSON fixture matching Supabase `profiles` table columns.
Map<String, dynamic> _fullJson() {
  return <String, dynamic>{
    'id': 'profile-uuid-001',
    'full_name': 'Omar Khalid',
    'email': 'omar@example.com',
    'avatar_url': 'avatars/profile-uuid-001/pic.jpg',
    'bio': 'Flutter developer based in Baghdad',
    'active_role': 'freelancer',
    'skills': <dynamic>['flutter', 'dart', 'supabase'],
    'seller_level': 'level_2',
    'account_status': 'active',
    'moderation_reason': null,
    'restriction_scope': null,
    'force_logout_after': '2026-08-15T09:30:00Z',
    'created_at': '2025-01-10T14:00:00Z',
  };
}

/// Minimal JSON -- only the required fields (`id`, `created_at`).
Map<String, dynamic> _minimalJson() {
  return <String, dynamic>{
    'id': 'profile-uuid-002',
    'created_at': '2025-03-20T08:00:00Z',
  };
}

void main() {
  group('ProfileModel.fromJson', () {
    test('parses all fields from valid JSON', () {
      final profile = ProfileModel.fromJson(_fullJson());

      expect(profile.id, 'profile-uuid-001');
      expect(profile.fullName, 'Omar Khalid');
      expect(profile.email, 'omar@example.com');
      expect(profile.avatarUrl, 'avatars/profile-uuid-001/pic.jpg');
      expect(profile.bio, 'Flutter developer based in Baghdad');
      expect(profile.activeRole, 'freelancer');
      expect(profile.skills, ['flutter', 'dart', 'supabase']);
      expect(profile.sellerLevel, 'level_2');
      expect(profile.accountStatus, 'active');
      expect(profile.moderationReason, isNull);
      expect(profile.restrictionScope, isNull);
      expect(profile.forceLogoutAfterUtc, DateTime.utc(2026, 8, 15, 9, 30, 0));
      expect(profile.createdAt, DateTime.utc(2025, 1, 10, 14, 0, 0));
    });

    test('default values applied when fields missing', () {
      final profile = ProfileModel.fromJson(_minimalJson());

      expect(profile.activeRole, 'client');
      expect(profile.accountStatus, 'active');
      expect(profile.skills, isEmpty);
    });

    test('nullable fields handle null gracefully', () {
      final profile = ProfileModel.fromJson(<String, dynamic>{
        'id': 'profile-uuid-003',
        'full_name': null,
        'email': null,
        'avatar_url': null,
        'bio': null,
        'active_role': null,
        'skills': null,
        'seller_level': null,
        'account_status': null,
        'moderation_reason': null,
        'restriction_scope': null,
        'force_logout_after': null,
        'created_at': '2025-05-01T00:00:00Z',
      });

      expect(profile.fullName, isNull);
      expect(profile.email, isNull);
      expect(profile.avatarUrl, isNull);
      expect(profile.bio, isNull);
      expect(profile.sellerLevel, isNull);
      expect(profile.moderationReason, isNull);
      expect(profile.restrictionScope, isNull);
      expect(profile.forceLogoutAfterUtc, isNull);
      // Defaults kick in for active_role, account_status, skills
      expect(profile.activeRole, 'client');
      expect(profile.accountStatus, 'active');
      expect(profile.skills, isEmpty);
    });

    test('missing optional fields default correctly without crash', () {
      final profile = ProfileModel.fromJson(_minimalJson());

      expect(profile.fullName, isNull);
      expect(profile.email, isNull);
      expect(profile.avatarUrl, isNull);
      expect(profile.bio, isNull);
      expect(profile.sellerLevel, isNull);
      expect(profile.moderationReason, isNull);
      expect(profile.restrictionScope, isNull);
      expect(profile.forceLogoutAfterUtc, isNull);
    });

    test('createdAt is parsed as UTC', () {
      final profile = ProfileModel.fromJson(_fullJson());

      expect(profile.createdAt.isUtc, isTrue);
    });

    test('forceLogoutAfterUtc is parsed as UTC', () {
      final profile = ProfileModel.fromJson(_fullJson());

      expect(profile.forceLogoutAfterUtc, isNotNull);
      expect(profile.forceLogoutAfterUtc!.isUtc, isTrue);
    });

    test('forceLogoutAfterUtc from offset timestamp is still UTC', () {
      final profile = ProfileModel.fromJson(<String, dynamic>{
        ..._fullJson(),
        'force_logout_after': '2026-08-15T12:30:00+03:00',
      });

      expect(profile.forceLogoutAfterUtc!.isUtc, isTrue);
      expect(profile.forceLogoutAfterUtc, DateTime.utc(2026, 8, 15, 9, 30, 0));
    });

    test('createdAt from offset timestamp is converted to UTC', () {
      final profile = ProfileModel.fromJson(<String, dynamic>{
        ..._fullJson(),
        'created_at': '2025-01-10T17:00:00+03:00',
      });

      expect(profile.createdAt.isUtc, isTrue);
      expect(profile.createdAt, DateTime.utc(2025, 1, 10, 14, 0, 0));
    });
  });

  group('ProfileModel.toJson', () {
    test('serializes all fields with snake_case keys matching DB columns', () {
      final json = ProfileModel.fromJson(_fullJson()).toJson();

      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('full_name'), isTrue);
      expect(json.containsKey('email'), isTrue);
      expect(json.containsKey('avatar_url'), isTrue);
      expect(json.containsKey('bio'), isTrue);
      expect(json.containsKey('active_role'), isTrue);
      expect(json.containsKey('skills'), isTrue);
      expect(json.containsKey('seller_level'), isTrue);
      expect(json.containsKey('account_status'), isTrue);
      expect(json.containsKey('moderation_reason'), isTrue);
      expect(json.containsKey('restriction_scope'), isTrue);
      expect(json.containsKey('force_logout_after'), isTrue);
      expect(json.containsKey('created_at'), isTrue);
    });

    test('round-trip fromJson -> toJson preserves values', () {
      final original = _fullJson();
      final profile = ProfileModel.fromJson(original);
      final json = profile.toJson();

      expect(json['id'], original['id']);
      expect(json['full_name'], original['full_name']);
      expect(json['email'], original['email']);
      expect(json['avatar_url'], original['avatar_url']);
      expect(json['bio'], original['bio']);
      expect(json['active_role'], original['active_role']);
      expect(json['skills'], original['skills']);
      expect(json['seller_level'], original['seller_level']);
      expect(json['account_status'], original['account_status']);
      expect(json['moderation_reason'], original['moderation_reason']);
      expect(json['restriction_scope'], original['restriction_scope']);
      // DateTime fields serialized as ISO 8601 strings
      expect(
        DateTime.parse(json['created_at'] as String).toUtc(),
        DateTime.utc(2025, 1, 10, 14, 0, 0),
      );
      expect(
        DateTime.parse(json['force_logout_after'] as String).toUtc(),
        DateTime.utc(2026, 8, 15, 9, 30, 0),
      );
    });

    test(
      'round-trip fromJson -> toJson -> fromJson produces identical model',
      () {
        final profile1 = ProfileModel.fromJson(_fullJson());
        final json = profile1.toJson();
        final profile2 = ProfileModel.fromJson(json);

        expect(profile2.id, profile1.id);
        expect(profile2.fullName, profile1.fullName);
        expect(profile2.email, profile1.email);
        expect(profile2.activeRole, profile1.activeRole);
        expect(profile2.skills, profile1.skills);
        expect(profile2.createdAt, profile1.createdAt);
        expect(profile2.forceLogoutAfterUtc, profile1.forceLogoutAfterUtc);
      },
    );

    test('toJson does not contain camelCase keys', () {
      final json = ProfileModel.fromJson(_fullJson()).toJson();

      expect(json.containsKey('fullName'), isFalse);
      expect(json.containsKey('avatarUrl'), isFalse);
      expect(json.containsKey('activeRole'), isFalse);
      expect(json.containsKey('sellerLevel'), isFalse);
      expect(json.containsKey('accountStatus'), isFalse);
      expect(json.containsKey('moderationReason'), isFalse);
      expect(json.containsKey('restrictionScope'), isFalse);
      expect(json.containsKey('forceLogoutAfterUtc'), isFalse);
      expect(json.containsKey('createdAt'), isFalse);
    });
  });

  group('ProfileModel.copyWith', () {
    test('creates a new instance with updated fields', () {
      final original = ProfileModel.fromJson(_fullJson());
      final updated = original.copyWith(
        fullName: 'New Name',
        bio: 'Updated bio',
      );

      // Updated fields
      expect(updated.fullName, 'New Name');
      expect(updated.bio, 'Updated bio');
      // Unchanged fields
      expect(updated.id, original.id);
      expect(updated.email, original.email);
      expect(updated.activeRole, original.activeRole);
      expect(updated.skills, original.skills);
      expect(updated.createdAt, original.createdAt);
      expect(updated.sellerLevel, original.sellerLevel);
      expect(updated.accountStatus, original.accountStatus);
    });

    test('copyWith with no arguments returns equivalent instance', () {
      final original = ProfileModel.fromJson(_fullJson());
      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.fullName, original.fullName);
      expect(copy.email, original.email);
      expect(copy.bio, original.bio);
      expect(copy.activeRole, original.activeRole);
      expect(copy.skills, original.skills);
      expect(copy.sellerLevel, original.sellerLevel);
      expect(copy.accountStatus, original.accountStatus);
      expect(copy.moderationReason, original.moderationReason);
      expect(copy.restrictionScope, original.restrictionScope);
      expect(copy.forceLogoutAfterUtc, original.forceLogoutAfterUtc);
      expect(copy.createdAt, original.createdAt);
    });

    test('copyWith updates skills list', () {
      final original = ProfileModel.fromJson(_fullJson());
      final updated = original.copyWith(skills: ['go', 'python']);

      expect(updated.skills, ['go', 'python']);
      expect(original.skills, ['flutter', 'dart', 'supabase']);
    });

    test('copyWith updates accountStatus and moderationReason', () {
      final original = ProfileModel.fromJson(_fullJson());
      final updated = original.copyWith(
        accountStatus: 'suspended',
        moderationReason: 'Policy violation',
        restrictionScope: 'full',
      );

      expect(updated.accountStatus, 'suspended');
      expect(updated.moderationReason, 'Policy violation');
      expect(updated.restrictionScope, 'full');
    });

    test('copyWith updates forceLogoutAfterUtc', () {
      final original = ProfileModel.fromJson(_fullJson());
      final newDate = DateTime.utc(2027, 1, 1);
      final updated = original.copyWith(forceLogoutAfterUtc: newDate);

      expect(updated.forceLogoutAfterUtc, newDate);
      expect(updated.forceLogoutAfterUtc!.isUtc, isTrue);
    });

    test('copyWith preserves immutable id, email, activeRole, createdAt', () {
      final original = ProfileModel.fromJson(_fullJson());
      final updated = original.copyWith(fullName: 'Changed');

      expect(updated.id, original.id);
      expect(updated.email, original.email);
      expect(updated.activeRole, original.activeRole);
      expect(updated.createdAt, original.createdAt);
    });
  });
}
