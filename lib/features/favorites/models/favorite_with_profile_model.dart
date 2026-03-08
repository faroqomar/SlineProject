import 'package:sline_app/core/services/logger_service.dart';

/// Favorite row joined with optional freelancer profile (CONTRACT_FavoritesJoin).
/// Uses root [freelancer_id] when joined profile is null to avoid crash.
class FavoriteWithProfile {
  final String id;
  final String freelancerId;
  final String? freelancerName;
  final String? freelancerAvatar;
  final DateTime createdAt;

  FavoriteWithProfile({
    required this.id,
    required this.freelancerId,
    required this.createdAt,
    this.freelancerName,
    this.freelancerAvatar,
  });

  /// Parses from Supabase joined response. Root row must have id, freelancer_id, created_at.
  /// When [freelancer] relation is null, uses root freelancer_id and logs.
  factory FavoriteWithProfile.fromMap(Map<String, dynamic> map) {
    final freelancer = map['freelancer'] as Map<String, dynamic>?;
    final rootFreelancerId = map['freelancer_id'];
    final String freelancerId;
    final String? freelancerName;
    final String? freelancerAvatar;

    if (freelancer != null) {
      freelancerId =
          freelancer['id'] as String? ?? rootFreelancerId?.toString() ?? '';
      freelancerName = freelancer['full_name'] as String?;
      freelancerAvatar = freelancer['avatar_url'] as String?;
    } else {
      freelancerId = rootFreelancerId is String
          ? rootFreelancerId
          : rootFreelancerId?.toString() ?? '';
      freelancerName = null;
      freelancerAvatar = null;
      if (freelancerId.isNotEmpty) {
        AppLogger.w(
          'Joined freelancer profile missing; using root freelancer_id',
          tag: 'Favorites',
        );
      }
    }

    final id = map['id'] as String? ?? '';
    final createdAtStr = map['created_at'] as String?;
    final createdAt = createdAtStr != null
        ? DateTime.parse(createdAtStr)
        : DateTime.now().toUtc();

    return FavoriteWithProfile(
      id: id,
      freelancerId: freelancerId,
      freelancerName: freelancerName,
      freelancerAvatar: freelancerAvatar,
      createdAt: createdAt,
    );
  }
}
