import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/models/work_item.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/dashboard/models/activity_log.dart';

/// Service for caching dashboard data to enable instant loading
///
/// Implements stale-while-revalidate pattern:
/// 1. Load from cache instantly (if valid)
/// 2. Fetch fresh data in background
/// 3. Update cache for next load
class DashboardCacheService {
  final SharedPreferences _prefs;

  DashboardCacheService(this._prefs);

  // Cache keys
  static const String _workItemsKeyPrefix = 'dashboard_work_items';
  static const String _activityFeedKey = 'dashboard_activity_feed';
  static const String _countersKey = 'dashboard_counters';
  static const String _timestampKey = 'dashboard_timestamp';

  // Cache validity duration
  static const Duration _cacheValidity = Duration(minutes: 5);

  /// Generate role-specific key for work items
  String _workItemsKey(UserRole role) => '${_workItemsKeyPrefix}_${role.name}';

  /// Cache work items for a specific role
  Future<void> cacheWorkItems(List<WorkItem> items, UserRole role) async {
    try {
      final key = _workItemsKey(role);
      final jsonList = items.map((item) => item.toJson()).toList();
      final jsonString = jsonEncode(jsonList);

      await _prefs.setString(key, jsonString);
      await _updateTimestamp();

      AppLogger.d('Cached ${items.length} work items for role: ${role.name}');
    } on Exception catch (e) {
      AppLogger.e('Failed to cache work items', error: e);
    }
  }

  /// Get cached work items for a specific role
  Future<List<WorkItem>?> getCachedWorkItems(UserRole role) async {
    try {
      if (!isCacheValid()) {
        AppLogger.d('Cache expired, returning null');
        return null;
      }

      final key = _workItemsKey(role);
      final jsonString = _prefs.getString(key);

      if (jsonString == null) {
        AppLogger.d('No cached work items for role: ${role.name}');
        return null;
      }

      final jsonList = jsonDecode(jsonString) as List;
      final items = jsonList
          .map((json) => WorkItem.fromJson(json as Map<String, dynamic>))
          .toList();

      AppLogger.d('Retrieved ${items.length} cached work items');
      return items;
    } on Exception catch (e) {
      AppLogger.e('Failed to retrieve cached work items', error: e);
      return null;
    }
  }

  /// Cache activity feed
  Future<void> cacheActivityFeed(List<ActivityLog> feed) async {
    try {
      final jsonList = feed.map((log) => log.toJson()).toList();
      final jsonString = jsonEncode(jsonList);

      await _prefs.setString(_activityFeedKey, jsonString);
      await _updateTimestamp();

      AppLogger.d('Cached ${feed.length} activity log items');
    } on Exception catch (e) {
      AppLogger.e('Failed to cache activity feed', error: e);
    }
  }

  /// Get cached activity feed
  Future<List<ActivityLog>?> getCachedActivityFeed() async {
    try {
      if (!isCacheValid()) {
        return null;
      }

      final jsonString = _prefs.getString(_activityFeedKey);
      if (jsonString == null) {
        return null;
      }

      final jsonList = jsonDecode(jsonString) as List;
      final feed = jsonList
          .map((json) => ActivityLog.fromJson(json as Map<String, dynamic>))
          .toList();

      AppLogger.d('Retrieved ${feed.length} cached activity items');
      return feed;
    } on Exception catch (e) {
      AppLogger.e('Failed to retrieve cached activity feed', error: e);
      return null;
    }
  }

  /// Cache counters (serialized as JSON)
  Future<void> cacheCounters(Map<String, int> counters) async {
    try {
      final jsonString = jsonEncode(counters);
      await _prefs.setString(_countersKey, jsonString);
      await _updateTimestamp();

      AppLogger.d('Cached counters: $counters');
    } on Exception catch (e) {
      AppLogger.e('Failed to cache counters', error: e);
    }
  }

  /// Get cached counters
  Future<Map<String, int>?> getCachedCounters() async {
    try {
      if (!isCacheValid()) {
        return null;
      }

      final jsonString = _prefs.getString(_countersKey);
      if (jsonString == null) {
        return null;
      }

      final Map<String, dynamic> json = jsonDecode(jsonString);
      final counters = json.map((key, value) => MapEntry(key, value as int));

      AppLogger.d('Retrieved cached counters');
      return counters;
    } on Exception catch (e) {
      AppLogger.e('Failed to retrieve cached counters', error: e);
      return null;
    }
  }

  /// Check if cache is still valid based on timestamp
  bool isCacheValid() {
    final timestampMs = _prefs.getInt(_timestampKey);
    if (timestampMs == null) {
      return false;
    }

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    final now = DateTime.now();
    final age = now.difference(cacheTime);

    final isValid = age < _cacheValidity;
    AppLogger.d('Cache age: ${age.inSeconds}s, valid: $isValid');
    return isValid;
  }

  /// Update cache timestamp
  Future<void> _updateTimestamp() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _prefs.setInt(_timestampKey, now);
  }

  /// Clear all dashboard cache
  Future<void> clearCache() async {
    try {
      await _prefs.remove(_workItemsKey(UserRole.client));
      await _prefs.remove(_workItemsKey(UserRole.freelancer));
      await _prefs.remove(_activityFeedKey);
      await _prefs.remove(_countersKey);
      await _prefs.remove(_timestampKey);

      AppLogger.i('Dashboard cache cleared');
    } on Exception catch (e) {
      AppLogger.e('Failed to clear cache', error: e);
    }
  }

  /// Get cache statistics (for debugging)
  Map<String, dynamic> getCacheStats() {
    final stats = {
      'valid': isCacheValid(),
      'timestamp': _prefs.getInt(_timestampKey),
      'has_client_items': _prefs.containsKey(_workItemsKey(UserRole.client)),
      'has_freelancer_items': _prefs.containsKey(
        _workItemsKey(UserRole.freelancer),
      ),
      'has_activity': _prefs.containsKey(_activityFeedKey),
      'has_counters': _prefs.containsKey(_countersKey),
    };

    AppLogger.d('Cache stats: $stats');
    return stats;
  }

  /// Caches the user's active role (no expiration)
  Future<void> cacheUserRole(UserRole role) async {
    try {
      final roleStr = role == UserRole.client ? 'client' : 'freelancer';
      await _prefs.setString('user_role', roleStr);
      AppLogger.d('Cached role: $roleStr');
    } on Exception catch (e) {
      AppLogger.e('Failed to cache role', error: e);
    }
  }

  /// Retrieves the cached user role
  Future<UserRole?> getCachedUserRole() async {
    try {
      final roleStr = _prefs.getString('user_role');
      if (roleStr == 'client') return UserRole.client;
      if (roleStr == 'freelancer') return UserRole.freelancer;
      return null; // Not cached
    } on Exception catch (e) {
      AppLogger.e('Failed to retrieve cached role', error: e);
      return null;
    }
  }
}
