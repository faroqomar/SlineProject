# Risk Register: Realtime Subscription Topology

**Skills Applied**:

- Threat Modeling (Security)
- Idempotency & Concurrency
- Observability (Logs/Alerts/Admin Trace)
- Evidence-First Reading
- RLS & Privilege Boundaries

**Why**: To identify the operational and security risks of the current realtime implementation logic versus the intended architecture.

## 1. Risks if we keep the current system

| Risk                                        | Severity | Likelihood  | Impact                                                                                                                                                                          | Evidence                                                                                                                                              |
| ------------------------------------------- | -------- | ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Silent Realtime Failure (Conversations)** | HIGH     | HIGH (100%) | Users do not see new chats in their inbox until they pull-to-refresh.                                                                                                           | `SUPABASE_SETUP.md` (Realtime Enabled on: messages, notifications). `message_service.dart:340` subscribes to `conversations`.                         |
| **N+1 Query Bomb on Stream Updates**        | CRITICAL | HIGH        | Every time a conversation updates, the client triggers a bulk `select()` query for ALL conversations. At scale, this will collapse the DB under connection load.                | `message_service.dart:352`: `.asyncMap(...)` runs `await _client.from('conversations').select(...).in_('id', convoIds)` for the whole stream payload. |
| **Global RLS Evaluation (CPU Starvation)**  | HIGH     | HIGH        | Subscribing to `conversations` without client filters means Supabase Realtime pushes every single platform-wide conversation change through RLS for every connected client.     | `message_service.dart:340`: `.stream().order('created_at')` has no `.or()` or `.eq()` filter for user ownership.                                      |
| **Missing Message De-duplication**          | LOW      | MEDIUM      | If the socket reconnects during a burst of events, duplicate messages may flash in the UI before state settles, though `stream()` handles primary key deduplication internally. | Standard WebSocket limits.                                                                                                                            |

## 2. Risks introduced by improvements

| Risk                                                      | Severity | Minimization / Mitigation                                                                                     |
| --------------------------------------------------------- | -------- | ------------------------------------------------------------------------------------------------------------- |
| **Adding `conversations` to `supabase_realtime`**         | MEDIUM   | This directly exposes the table to WS. Mitigation: Ensure `conversations_select` RLS is airtight.             |
| **Changing from `.stream()` to `on('postgres_changes')`** | LOW      | Requires rewriting the UI state ingestion loop in `message_service.dart`. Mitigation: Use structured testing. |
