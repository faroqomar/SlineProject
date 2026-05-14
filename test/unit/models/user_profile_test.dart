// Schema ref: profiles table in SUPABASE_SETUP.md
import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/models/user_profile.dart';

/// Full valid JSON fixture matching Supabase `profiles` table columns.
Map<String, dynamic> _fullJson() {
  return <String, dynamic>{
    'id': 'user-uuid-001',
    'full_name': 'Ali Hassan',
    'email': 'ali@example.com',
    'avatar_url': 'avatars/user-uuid-001/1700000000.jpg',
    'account_status': 'active',
    'moderation_reason': null,
    'restriction_scope': null,
    'force_logout_after': '2026-06-01T12:00:00Z',
  };
}

/// Minimal JSON -- only the required `id` field.
Map<String, dynamic> _minimalJson() {
  return <String, dynamic>{'id': 'user-uuid-002'};
}

void main() {
  group('UserProfile.fromMap', () {
    test('parses all fields from valid JSON', () {
      final profile = UserProfile.fromMap(_fullJson());

      expect(profile.id, 'user-uuid-001');
      expect(profile.fullName, 'Ali Hassan');
      expect(profile.email, 'ali@example.com');
      expect(profile.avatarUrl, 'avatars/user-uuid-001/1700000000.jpg');
      expect(profile.accountStatus, 'active');
      expect(profile.moderationReason, isNull);
      expect(profile.restrictionScope, isNull);
      expect(profile.forceLogoutAfterUtc, DateTime.utc(2026, 6, 1, 12));
    });

    test('all nullable fields handle null gracefully', () {
      final profile = UserProfile.fromMap(<String, dynamic>{
        'id': 'user-uuid-003',
        'full_name': null,
        'email': null,
        'avatar_url': null,
        'account_status': null,
        'moderation_reason': null,
        'restriction_scope': null,
        'force_logout_after': null,
      });

      expect(profile.id, 'user-uuid-003');
      expect(profile.fullName, isNull);
      expect(profile.email, isNull);
      expect(profile.avatarUrl, isNull);
      expect(profile.accountStatus, isNull);
      expect(profile.moderationReason, isNull);
      expect(profile.restrictionScope, isNull);
      expect(profile.forceLogoutAfterUtc, isNull);
    });

    test('missing optional fields default to null without crash', () {
      final profile = UserProfile.fromMap(_minimalJson());

      expect(profile.id, 'user-uuid-002');
      expect(profile.fullName, isNull);
      expect(profile.email, isNull);
      expect(profile.avatarUrl, isNull);
      expect(profile.accountStatus, isNull);
      expect(profile.moderationReason, isNull);
      expect(profile.restrictionScope, isNull);
      expect(profile.forceLogoutAfterUtc, isNull);
    });

    test('forceLogoutAfterUtc is parsed as UTC', () {
      final profile = UserProfile.fromMap(_fullJson());

      expect(profile.forceLogoutAfterUtc, isNotNull);
      expect(profile.forceLogoutAfterUtc!.isUtc, isTrue);
    });

    test('forceLogoutAfterUtc parsed from non-Z timestamp is still UTC', () {
      final profile = UserProfile.fromMap(<String, dynamic>{
        ..._fullJson(),
        'force_logout_after': '2026-06-01T15:00:00+03:00',
      });

      expect(profile.forceLogoutAfterUtc, isNotNull);
      expect(profile.forceLogoutAfterUtc!.isUtc, isTrue);
      expect(profile.forceLogoutAfterUtc, DateTime.utc(2026, 6, 1, 12));
    });

    test('account_status with moderation fields parses correctly', () {
      final profile = UserProfile.fromMap(<String, dynamic>{
        'id': 'user-uuid-004',
        'account_status': 'suspended',
        'moderation_reason': 'Terms violation',
        'restriction_scope': 'full',
      });

      expect(profile.accountStatus, 'suspended');
      expect(profile.moderationReason, 'Terms violation');
      expect(profile.restrictionScope, 'full');
    });
  });

  group('UserProfile.toMap', () {
    test('serializes all fields with snake_case keys matching DB columns', () {
      final map = UserProfile.fromMap(_fullJson()).toMap();

      expect(map.containsKey('id'), isTrue);
      expect(map.containsKey('full_name'), isTrue);
      expect(map.containsKey('email'), isTrue);
      expect(map.containsKey('avatar_url'), isTrue);
      expect(map.containsKey('account_status'), isTrue);
      expect(map.containsKey('moderation_reason'), isTrue);
      expect(map.containsKey('restriction_scope'), isTrue);
      expect(map.containsKey('force_logout_after'), isTrue);
    });

    test('round-trip fromMap -> toMap preserves values', () {
      final original = _fullJson();
      final profile = UserProfile.fromMap(original);
      final map = profile.toMap();

      expect(map['id'], original['id']);
      expect(map['full_name'], original['full_name']);
      expect(map['email'], original['email']);
      expect(map['avatar_url'], original['avatar_url']);
      expect(map['account_status'], original['account_status']);
      expect(map['moderation_reason'], original['moderation_reason']);
      expect(map['restriction_scope'], original['restriction_scope']);
      // force_logout_after becomes ISO 8601 string
      expect(map['force_logout_after'], isA<String>());
      expect(
        DateTime.parse(map['force_logout_after'] as String).toUtc(),
        DateTime.utc(2026, 6, 1, 12),
      );
    });

    test('toMap serializes null fields as null', () {
      final map = UserProfile.fromMap(_minimalJson()).toMap();

      expect(map['full_name'], isNull);
      expect(map['email'], isNull);
      expect(map['avatar_url'], isNull);
      expect(map['account_status'], isNull);
      expect(map['moderation_reason'], isNull);
      expect(map['restriction_scope'], isNull);
      expect(map['force_logout_after'], isNull);
    });

    test('toMap does not contain camelCase keys', () {
      final map = UserProfile.fromMap(_fullJson()).toMap();

      expect(map.containsKey('fullName'), isFalse);
      expect(map.containsKey('avatarUrl'), isFalse);
      expect(map.containsKey('accountStatus'), isFalse);
      expect(map.containsKey('moderationReason'), isFalse);
      expect(map.containsKey('restrictionScope'), isFalse);
      expect(map.containsKey('forceLogoutAfterUtc'), isFalse);
    });
  });
}
