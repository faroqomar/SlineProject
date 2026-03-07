import 'package:uuid/uuid.dart';

/// Single source for ledger p_meta forensics (CONTRACT_ledger_event_flow).
/// Callers merge the returned map into p_meta so journal_entries.meta has
/// session_id and optional request_id for dispute/audit and log correlation.
class LedgerForensics {
  LedgerForensics({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  /// Builds forensics map for p_meta: session_id (when provided) and
  /// optional request_id for per-call correlation in logs and DB.
  /// Does not log or expose PII.
  Map<String, dynamic> build({
    required String? sessionId,
    bool includeRequestId = true,
  }) {
    final map = <String, dynamic>{};
    if (sessionId != null && sessionId.isNotEmpty) {
      map['session_id'] = sessionId;
    }
    if (includeRequestId) {
      map['request_id'] = _uuid.v4();
    }
    return map;
  }
}
