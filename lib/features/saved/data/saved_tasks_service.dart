// SavedTasksService - CRUD for the `saved_tasks` table (bookmarking tasks).
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';
import '../models/saved_task_model.dart';

class SavedTasksService {
  final SupabaseClient _client;

  SavedTasksService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

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
    final res = await _client
        .from('saved_tasks')
        .select('task:tasks(*)')
        .eq('user_id', uid)
        .order('created_at', ascending: false);

    // Each row has shape: { task: { ...task fields... } }
    return (res as List)
        .map((row) => Task.fromJson(row['task'] as Map<String, dynamic>))
        .toList();
  }
}
