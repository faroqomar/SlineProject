/// Shared cache for signed URLs to prevent redundant Supabase storage calls.
///
/// Why this exists: Generating signed URLs requires a network call to Supabase.
/// Caching them prevents excessive API calls when the same image is displayed
/// multiple times (e.g., in lists, when scrolling back, or on widget rebuilds).
///
/// Cache Strategy:
/// - URLs are cached for 90 minutes (signed URLs valid for 2 hours)
/// - Early expiry (90 min vs 2 hr) ensures URLs are refreshed before they expire
/// - Cache is in-memory only (cleared on app restart)
library;

/// Cache entry holding the signed URL and its expiration time.
class SignedUrlCacheEntry {
  final String url;
  final DateTime expiry;

  SignedUrlCacheEntry({required this.url, required this.expiry});

  /// Check if this cache entry is still valid
  bool get isValid => DateTime.now().isBefore(expiry);
}

/// Global cache for signed URLs across the app.
///
/// Usage:
/// ```dart
/// final cached = SignedUrlCache.get(storagePath);
/// if (cached != null) {
///   return cached; // Use cached URL
/// }
/// final signedUrl = await generateSignedUrl(storagePath);
/// SignedUrlCache.set(storagePath, signedUrl);
/// ```
class SignedUrlCache {
  SignedUrlCache._(); // Prevent instantiation

  static final Map<String, SignedUrlCacheEntry> _cache = {};

  /// Default cache duration (90 minutes to allow refresh before 2hr expiry)
  static const Duration defaultCacheDuration = Duration(minutes: 90);

  /// Get a cached URL if it exists and is still valid
  static String? get(String storagePath) {
    final entry = _cache[storagePath];
    if (entry != null && entry.isValid) {
      return entry.url;
    }
    // Remove expired entry
    if (entry != null) {
      _cache.remove(storagePath);
    }
    return null;
  }

  /// Cache a signed URL for the given storage path
  static void set(
    String storagePath,
    String signedUrl, {
    Duration? duration,
  }) {
    _cache[storagePath] = SignedUrlCacheEntry(
      url: signedUrl,
      expiry: DateTime.now().add(duration ?? defaultCacheDuration),
    );
  }

  /// Clear all cached URLs (e.g., on logout)
  static void clear() {
    _cache.clear();
  }

  /// Remove a specific cached URL
  static void remove(String storagePath) {
    _cache.remove(storagePath);
  }

  /// Get current cache size (for debugging)
  static int get size => _cache.length;
}

