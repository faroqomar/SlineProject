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
/// - Bounded size (1000 entries max) to prevent memory issues
/// - Error caching (30 seconds) to prevent retry storms on 403 errors
library;

import 'package:sline_app/core/config/storage_config.dart';

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
  static final Map<String, SignedUrlCacheEntry> _errorCache = {};

  /// Default cache duration (90 minutes to allow refresh before 2hr expiry)
  static const Duration defaultCacheDuration = Duration(minutes: 90);

  /// Error cache duration (30 seconds to prevent retry storms)
  static const Duration defaultErrorCacheDuration = Duration(seconds: 30);

  /// Maximum number of entries in the cache to prevent memory issues
  static const int maxCacheSize = 1000;

  /// Number of entries to evict when cache is full
  static const int evictionBatchSize = 100;

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
  static void set(String storagePath, String signedUrl, {Duration? duration}) {
    _cleanupIfNeeded();
    _cache[storagePath] = SignedUrlCacheEntry(
      url: signedUrl,
      expiry: DateTime.now().add(duration ?? SharedStorageConfig.cacheDuration),
    );
    // Remove from error cache if it was there
    _errorCache.remove(storagePath);
  }

  /// Cache an error for the given storage path (prevents retry storms)
  ///
  /// [storagePath] - The storage path that resulted in an error
  static void setError(String storagePath) {
    _cleanupIfNeeded();
    _errorCache[storagePath] = SignedUrlCacheEntry(
      url: '', // Empty URL indicates error
      expiry: DateTime.now().add(SharedStorageConfig.errorCacheDuration),
    );
  }

  /// Check if a storage path has a cached error
  ///
  /// Returns true if an error is cached and hasn't expired
  static bool hasError(String storagePath) {
    final entry = _errorCache[storagePath];
    if (entry != null && entry.isValid) {
      return true;
    }
    // Remove expired entry
    if (entry != null) {
      _errorCache.remove(storagePath);
    }
    return false;
  }

  /// Clear all cached URLs (e.g., on logout)
  static void clear() {
    _cache.clear();
    _errorCache.clear();
  }

  /// Remove a specific cached URL
  static void remove(String storagePath) {
    _cache.remove(storagePath);
    _errorCache.remove(storagePath);
  }

  /// Get current cache size (for debugging)
  static int get size => _cache.length;

  /// Get current error cache size (for debugging)
  static int get errorSize => _errorCache.length;

  /// Clean up old entries if cache is getting too large
  static void _cleanupIfNeeded() {
    final totalSize = _cache.length + _errorCache.length;
    if (totalSize > maxCacheSize) {
      // Sort by expiry (oldest first)
      final sorted = _cache.entries.toList()
        ..sort((a, b) => a.value.expiry.compareTo(b.value.expiry));

      // Remove oldest entries
      final toRemove = sorted.take(evictionBatchSize).map((e) => e.key);
      for (final key in toRemove) {
        _cache.remove(key);
        _errorCache.remove(key);
      }
    }
  }

  /// Clear only expired entries (useful for periodic cleanup)
  static void clearExpired() {
    final now = DateTime.now();
    _cache.removeWhere((_, entry) => now.isAfter(entry.expiry));
    _errorCache.removeWhere((_, entry) => now.isAfter(entry.expiry));
  }
}
