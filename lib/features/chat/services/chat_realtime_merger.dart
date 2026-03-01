import '../models/message_model.dart';

/// Merges realtime message snapshots with existing list: dedupe by id, sort by created_at.
/// Prevents loss of messages when stream emits full snapshot instead of single row.
class ChatRealtimeMerger {
  /// Returns merged list: existing + new rows, deduped by message id (new wins), sorted by created_at.
  static List<Message> merge(
    List<Message> existing,
    List<Map<String, dynamic>> newRows,
    Message Function(Map<String, dynamic>) fromJson,
  ) {
    final byId = <String, Message>{};
    for (final m in existing) {
      byId[m.id] = m;
    }
    for (final row in newRows) {
      try {
        final msg = fromJson(row);
        byId[msg.id] = msg;
      } catch (_) {
        // Skip unparseable row; do not log raw content
      }
    }
    final list = byId.values.toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }
}
