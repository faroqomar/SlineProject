/// Abstract interface for generating signed URLs from Supabase storage paths.
///
/// This interface allows core widgets ([SignedAvatar], [SignedImage]) to
/// resolve storage paths to signed URLs without importing feature-specific
/// services. Feature services ([AvatarService], [TaskImageService]) implement
/// this interface.
///
/// ## Architecture
///
/// ```text
/// core/widgets/signed_avatar.dart  ──uses──>  core/services/signed_url_generator.dart
///                                                        ^
/// features/profile/services/avatar_service.dart  ──implements──┘
/// ```
///
/// This breaks the dependency from core → features while preserving
/// the existing service functionality.
abstract class SignedUrlGenerator {
  /// Creates a time-limited signed URL for the given [storagePath].
  ///
  /// Returns `null` if the URL cannot be generated (e.g., network error,
  /// invalid path, expired session). Callers should handle null gracefully
  /// by showing a fallback UI (placeholder icon, initials, etc.).
  ///
  /// [expire] optionally overrides the default TTL for the signed URL.
  /// If not provided, the service implementation determines the default.
  Future<String?> createSignedUrl(String storagePath, {Duration? expire});
}
