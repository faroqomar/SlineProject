// SavedTaskModel
// Represents a bookmark entry for a task by a specific user.
import 'package:logger/logger.dart';

final _savedModelLogger = Logger();

class SavedTaskModel {
  /// Primary key id in `saved_tasks`.
  final String id;

  /// The owner who saved the task (auth.uid()).
  final String userId;

  /// The saved task id.
  final String taskId;

  /// When the bookmark was created.
  final DateTime createdAt;

  SavedTaskModel({
    required this.id,
    required this.userId,
    required this.taskId,
    required this.createdAt,
  });

  /// Build from PostgREST map.
  factory SavedTaskModel.fromMap(Map<String, dynamic> map) {
    try {
      return SavedTaskModel(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        taskId: map['task_id'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
    } catch (e, st) {
      _savedModelLogger.e('Failed to parse SavedTaskModel.fromMap', error: e, stackTrace: st);
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'task_id': taskId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
