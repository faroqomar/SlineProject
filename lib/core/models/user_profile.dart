/// What: Data model representing a user's profile row from Supabase `profiles`.
/// Why: Provides a typed structure to map database rows to the app domain and back.
/// Represents a user profile stored in Supabase `profiles` table.
/// Note: avatarUrl is a storage path; generate a signed URL at render time.
class UserProfile {
  final String id; // UUID from auth.users
  final String? fullName; // User's display name
  final String? email; // Email copied from auth.users
  /// Stores the **private storage path** in Supabase Storage, not a public URL.
  /// Example: `avatars/{uid}/{timestamp}.jpg`.
  /// UI must call `AvatarService.createSignedUrl(avatarUrl!)` to display the image.
  final String? avatarUrl; // Profile picture (optional)
  final String? accountStatus;
  final String? moderationReason;
  final String? restrictionScope;
  final DateTime? forceLogoutAfterUtc;

  UserProfile({
    required this.id,
    this.fullName,
    this.email,
    this.avatarUrl,
    this.accountStatus,
    this.moderationReason,
    this.restrictionScope,
    this.forceLogoutAfterUtc,
  });

  /// Converts a Supabase row into a UserProfile object.
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      fullName: map['full_name'] as String?,
      email: map['email'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      accountStatus: map['account_status'] as String?,
      moderationReason: map['moderation_reason'] as String?,
      restrictionScope: map['restriction_scope'] as String?,
      forceLogoutAfterUtc: map['force_logout_after'] != null
          ? DateTime.tryParse(map['force_logout_after'].toString())?.toUtc()
          : null,
    );
  }

  /// Converts the object to a map for insert/update.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'avatar_url': avatarUrl,
      'account_status': accountStatus,
      'moderation_reason': moderationReason,
      'restriction_scope': restrictionScope,
      'force_logout_after': forceLogoutAfterUtc?.toIso8601String(),
    };
  }
}
