// SavedTasksService - CRUD for the `saved_tasks` table (bookmarking tasks).
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/profile/services/profile_summary_service.dart';
import 'package:sline_app/features/saved/models/saved_task_model.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SavedTasksService {
  final SupabaseClient _client;
  late final ProfileSummaryService _profileSummaryService;

  SavedTasksService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client {
    _profileSummaryService = ProfileSummaryService(_client);
  }

  String _requireUid() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      AppLogger.e('Not authenticated', tag: 'Saved');
      throw StateError('Not authenticated');
    }
    return uid;
  }

  /// List saved tasks for current user (newest first).
  Future<List<SavedTaskModel>> listMine() async {
    final uid = _requireUid();
    final res = await _client
        .from('saved_tasks')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false);
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(SavedTaskModel.fromMap)
        .toList();
  }

  /// Check if a task is saved by current user.
  Future<bool> isSaved(String taskId) async {
    final uid = _requireUid();
    final res = await _client
        .from('saved_tasks')
        .select('id')
        .eq('user_id', uid)
        .eq('task_id', taskId)
        .maybeSingle();
    return res != null;
  }

  /// Save a task.
  Future<void> add(String taskId) async {
    final uid = _requireUid();
    await _client.from('saved_tasks').insert({
      'user_id': uid,
      'task_id': taskId,
    });
  }

  /// Remove a saved task.
  Future<void> remove(String taskId) async {
    final uid = _requireUid();
    await _client
        .from('saved_tasks')
        .delete()
        .eq('user_id', uid)
        .eq('task_id', taskId);
  }

  /// Toggle saved state; returns the new state (true if saved after call).
  Future<bool> toggle(String taskId) async {
    final saved = await isSaved(taskId);
    if (saved) {
      await remove(taskId);
      return false;
    } else {
      try {
        await add(taskId);
      } on PostgrestException catch (e) {
        // If duplicate (23505), consider it already saved.
        if (e.code == '23505') return true;
        rethrow;
      }
      return true;
    }
  }

  /// List saved tasks joined with full task details (newest first).
  Future<List<Task>> listMineWithDetails() async {
    final uid = _requireUid();
    // 1. Fetch saved tasks with their task details
    final res = await _client
        .from('saved_tasks')
        .select('task:tasks(*)')
        .eq('user_id', uid)
        .order('created_at', ascending: false);

    final rows = res as List<dynamic>;
    if (rows.isEmpty) return [];

    // 2. Extract distinct user IDs from tasks to fetch profiles
    // tasks.user_id references auth.users which matches profiles.id
    final userIds = rows
        .map((r) => r['task']['user_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();

    // 3. Fetch profiles for these users
    final profileMap = await _profileSummaryService.fetchByIds(userIds);

    // 4. Merge profile data into Task objects
    return rows.map((row) {
      final taskJson = row['task'] as Map<String, dynamic>;
      final userId = taskJson['user_id'] as String?;

      // Look up profile data
      final profile = userId != null ? profileMap[userId] : null;

      // Create Task, injecting profile info if available
      // We use copyWith after creation or inject into json, but simpler to use copyWith
      // because Task.fromJson looks for specific nested 'profiles' structure or flat keys.
      // Let's manually override.
      var task = Task.fromJson(taskJson);

      if (profile != null) {
        task = task.copyWith(
          userName: profile['full_name'],
          userAvatar: profile['avatar_url'],
          authorSellerLevel: profile['seller_level'] as String?,
        );
      }
      return task;
    }).toList();
  }
}
