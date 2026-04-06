import 'package:sline_app/features/profile/models/profile_model.dart';

/// DTO for displaying a user's public profile.
/// Explicitly excludes private fields like email, phone, metadata, settings.
class PublicProfile {
  final String id;
  final String fullName;
  final String? avatarUrl;
  final String? bio;
  final String role;
  final List<String> skills;
  final DateTime createdAt;

  const PublicProfile({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.bio,
    required this.role,
    this.skills = const [],
    required this.createdAt,
  });

  /// Factory to create PublicProfile safely from the full ProfileModel.
  /// This ensures we never accidentally pass a full model to the UI.
  factory PublicProfile.fromModel(ProfileModel model) {
    return PublicProfile(
      id: model.id,
      fullName: model.fullName ?? 'Unknown User',
      avatarUrl: model.avatarUrl,
      bio: model.bio,
      role: model.activeRole,
      skills: model.skills,
      createdAt: model.createdAt,
    );
  }
}
