import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/features/favorites/models/favorite_with_profile_model.dart';

void main() {
  group('FavoriteWithProfile.fromMap', () {
    test('parses full joined row', () {
      final map = <String, dynamic>{
        'id': 'fav-1',
        'freelancer_id': 'freelancer-1',
        'created_at': '2026-03-01T12:00:00Z',
        'freelancer': <String, dynamic>{
          'id': 'freelancer-1',
          'full_name': 'Jane Doe',
          'avatar_url': 'https://example.com/avatar.png',
        },
      };
      final f = FavoriteWithProfile.fromMap(map);
      expect(f.id, 'fav-1');
      expect(f.freelancerId, 'freelancer-1');
      expect(f.freelancerName, 'Jane Doe');
      expect(f.freelancerAvatar, 'https://example.com/avatar.png');
      expect(f.createdAt.toUtc().toIso8601String(), contains('2026-03-01'));
    });

    test('null join uses root freelancer_id and does not throw', () {
      final map = <String, dynamic>{
        'id': 'fav-2',
        'freelancer_id': 'freelancer-2',
        'created_at': '2026-03-01T14:00:00Z',
        'freelancer': null,
      };
      final f = FavoriteWithProfile.fromMap(map);
      expect(f.id, 'fav-2');
      expect(f.freelancerId, 'freelancer-2');
      expect(f.freelancerName, null);
      expect(f.freelancerAvatar, null);
      expect(f.createdAt.toUtc().toIso8601String(), contains('2026-03-01'));
    });

    test('missing freelancer_id on root uses empty string when join null', () {
      final map = <String, dynamic>{
        'id': 'fav-3',
        'created_at': '2026-03-01T16:00:00Z',
        'freelancer': null,
      };
      final f = FavoriteWithProfile.fromMap(map);
      expect(f.freelancerId, '');
      expect(f.freelancerName, null);
    });
  });
}
