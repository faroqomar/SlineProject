/// Centralized storage configuration for signed URL TTLs and cache settings.
///
/// This class provides consistent TTL values across all storage buckets
/// and cache configuration to prevent redundant API calls.
///
/// TTL Strategy:
/// - Chat attachments: 1 hour (sensitive, shorter-lived)
/// - Avatars: 2 hours (discoverable, longer-lived)
/// - Task images: 2 hours (discoverable, longer-lived)
///
/// Cache Strategy:
/// - URLs cached for 90 minutes (refresh before 2hr expiry)
/// - Errors cached for 30 seconds (prevent retry storms)
/// - Max 1000 entries (prevent memory issues)
class SharedStorageConfig {
  // Private constructor to prevent instantiation
  SharedStorageConfig._();

  /// TTL for chat attachments in seconds (sensitive, shorter-lived)
  /// 3600 seconds = 1 hour
  static const int chatAttachmentTtlSeconds = 3600;

  /// TTL for avatars in seconds (discoverable, longer-lived)
  /// 7200 seconds = 2 hours
  static const int avatarTtlSeconds = 7200;

  /// TTL for task images in seconds (discoverable, longer-lived)
  /// 7200 seconds = 2 hours
  static const int taskImageTtlSeconds = 7200;

  /// Cache duration for successful signed URLs
  /// 90 minutes - refreshed 30 minutes before 2hr expiry
  static const Duration cacheDuration = Duration(minutes: 90);

  /// Cache duration for error states
  /// 30 seconds - prevents retry storms on 403 errors
  static const Duration errorCacheDuration = Duration(seconds: 30);

  /// Maximum number of entries in the cache
  /// Prevents unbounded memory growth
  static const int maxCacheSize = 1000;

  /// Number of entries to evict when cache is full
  static const int evictionBatchSize = 100;

  /// Returns the appropriate TTL for a given bucket
  ///
  /// [bucket] - The storage bucket name
  /// Returns TTL in seconds
  static int ttlForBucket(String bucket) {
    switch (bucket) {
      case 'chat-attachments':
        return chatAttachmentTtlSeconds;
      case 'avatars':
        return avatarTtlSeconds;
      case 'task-images':
        return taskImageTtlSeconds;
      default:
        // Default to 1 hour for unknown buckets
        return 3600;
    }
  }

  /// Returns the appropriate TTL as a Duration for a given bucket
  ///
  /// [bucket] - The storage bucket name
  static Duration ttlDurationForBucket(String bucket) {
    return Duration(seconds: ttlForBucket(bucket));
  }
}
