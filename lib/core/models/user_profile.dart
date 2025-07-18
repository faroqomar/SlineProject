/// Represents a user profile stored in Supabase `profiles` table.
class UserProfile {
  final String id;          // UUID from auth.users
  final String? fullName;   // User's display name
  final String? email;      // Email copied from auth.users
  final String? avatarUrl;  // Profile picture (optional)

  UserProfile({
    required this.id,
    this.fullName,
    this.email,
    this.avatarUrl,
  });

  /// Converts a Supabase row into a UserProfile object.
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      fullName: map['full_name'] as String?,
      email: map['email'] as String?,
      avatarUrl: map['avatar_url'] as String?,
    );
  }

  /// Converts the object to a map for insert/update.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'avatar_url': avatarUrl,
    };
  }
}