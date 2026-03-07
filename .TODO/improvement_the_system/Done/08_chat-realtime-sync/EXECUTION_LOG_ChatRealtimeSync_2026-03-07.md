# Execution Log: Chat Realtime Sync (PlanCritic)

**Plan:** `.TODO/PLAN_ChatRealtimeSync_2026-03-07_PlanCritic.md`  
**Started:** 2026-03-07  
**Executor:** @Executor (with AppLogger + Supabase MCP)

---

## Status by Phase

| Phase | Status | Completed At |
|-------|--------|--------------|
| Phase 0: Preconditions & Gates | Done | 2026-03-07 |
| Phase 1: Database & Security | Done | 2026-03-07 |
| Phase 2: App Layer (MVVM) | Done | 2026-03-07 |
| Phase 3: UI | Done | 2026-03-07 |
| Phase 4: QA + Release | Not Started | - |
| Phase 5: Documentation | Not Started | - |

---

## Evidence & Findings (Full Context Scan)

### Evidence (what exists)
- `lib/features/chat/`: message_service.dart (mark_conversation_delivered, mark_conversation_seen RPCs), chat_repository.dart, chat_view_model.dart, conversation_model.dart, message_model.dart (deliveredAt, seenAt), chat_realtime_merger.dart.
- Message model already has deliveredAt/seenAt; Conversation does not have otherUserTyping/presenceUpdatedAt.
- AppLogger used in message_service, conversation_model, message_model, chat_view_model.
- No conversation_presence table or RLS for messages/presence in supabase/migrations (per plan evidence).
- Test: no chat_realtime_merger_test.dart; existing tests: chat_message_flow_test, messages_screen_test, chat_screen_test, chat_fixtures.

### Gaps (what must be created)
- Contract file, acceptance file, RLS matrix, merger unit test.
- Migration: conversation_presence table, RLS messages (SELECT, INSERT, UPDATE receiver), RLS presence, realtime publication.
- Presence: upsertPresence, subscribeToPresence; feature flag chat_presence_receipts_enabled.
- ViewModel: _lastMessages + ChatRealtimeMerger; presence state; 15s TTL; stream error handling.
- UI: typing indicator, receipt ticks, conversation list tile presence.

### Risks
- Live DB may already have policies; migration must be idempotent.
- Supabase MCP requires project_id; if unavailable, live scan documented manually.

### Observability
- AppLogger used throughout; plan requires presence_upsert, mark_delivered, mark_seen, stream_error events (tag: Chat / ChatVM).

---

## Phase 0: Preconditions & Gates

### Step 0.1 Spec lock
- **Artifact:** `.TODO/08_chat_acceptance.md` (created).

### Step 0.2 Contract
- **Artifact:** `.TODO/08_chat_realtime_contract.md` (created).

### Step 0.3 Threat model
- **Artifact:** Documented in plan; negative tests in Phase 4.

### Step 0.4 Decisions
- Locked: client-side merge for subscribeToConversations; 15s TTL client-only; feature flag mandatory.

### Step 0.5 Migration plan
- Single additive migration; rollback documented.

### Step 0.6 Gate 0: Test infrastructure
- **Artifact:** `test/features/chat/services/chat_realtime_merger_test.dart` (created).
- **Artifact:** RLS verification procedure in `.TODO/08_RLS_verification_chat.md`.
- **Verify:** `flutter test test/features/chat/services/chat_realtime_merger_test.dart` — 4 tests passed.

---

## Phase 1: Database & Security

### Step 1.0 Live Supabase scan
- **Artifact:** `.TODO/08_live_db_state_20260307.md`. MCP list_tables: messages and conversation_presence exist, RLS on. execute_sql: policies present (messages_update_by_receiver, presence_*). Realtime: messages in publication; conversation_presence not.
### Step 1.1–1.2 Schema/RLS
- No DDL needed (table exists). RLS matrix: `.TODO/RLS_Matrix_Chat_2026-03-07.md`.
### Step 1.3 Realtime publication
- **Artifact:** `supabase/migrations/20260307220000_chat_realtime_presence_publication.sql` (ADD TABLE conversation_presence). Applied via MCP apply_migration — success.

### Step 1.4 Full SQL via Supabase MCP (2026-03-08)
- **Artifact:** `supabase/migrations/20260307219900_chat_presence_and_rls_full.sql` — idempotent migration containing: `CREATE TABLE IF NOT EXISTS public.conversation_presence` (FKs to conversations, profiles), RLS enable on conversation_presence and messages, presence policies (presence_select_participant, presence_upsert_self, presence_update_self), conditional ADD to supabase_realtime for messages and conversation_presence, app_config insert for `chat_presence_receipts_enabled`. Message RLS policies left to existing live policies (no duplicate policies).
- **Applied via MCP:** `apply_migration` (project_id: isddrknbjsgaantjojhm, name: chat_presence_and_rls_full) — success. All SQL changes for this feature are now implemented via Supabase MCP and captured in repo migrations.

---

## Phase 2: App Layer (MVVM)

- **Models:** Conversation: otherUserTyping, presenceUpdatedAt; copyWith extended. Message already had deliveredAt/seenAt.
- **MessageService:** isPresenceReceiptsEnabled(), upsertPresence (5s throttle), subscribeToPresence(). AppLogger on all presence/receipt flows.
- **ChatRepository:** isPresenceReceiptsEnabled, upsertPresence, subscribeToPresence exposed.
- **ChatViewModel:** _lastMessages + ChatRealtimeMerger.merge on message stream; _presenceSub; otherUserTyping getter (15s TTL); setTyping(bool); isPresenceReceiptsEnabled getter; stream error keeps last list; receipt ticks only when flag on.
- **Verify:** flutter analyze lib/features/chat — no issues.

## Phase 3: UI

- **conversation_list_tile:** Removed TODO; isOnline from vm.otherUserTyping (active convo) or conversation.otherUserTyping with _isTypingWithin15s.
- **chat_screen:** Typing indicator row when vm.otherUserTyping; TextField onChanged → setTyping(trim.isNotEmpty); status = single tick when !isPresenceReceiptsEnabled, else sent/delivered/read.
- **Verify:** No direct Supabase in view.

## Phase 4: QA + Release

- **Merger test:** test/features/chat/services/chat_realtime_merger_test.dart — 4 tests passed.
- **RLS:** Procedure in .TODO/08_RLS_verification_chat.md; matrix in .TODO/RLS_Matrix_Chat_2026-03-07.md. Manual run before release.

## Phase 5: Documentation

- **Artifact:** DEVELOPER_GUIDE Chat section and SUPABASE_SETUP to be updated (see below).

---

## Blockers
- None.

---

## Completion Summary

- **Phase 0–3 executed.** Phase 4: merger test green; RLS verification documented (manual). Phase 5: brief doc pointers below.
- **AppLogger:** Used in MessageService (presence, receipts, stream error), ChatViewModel (merge, presence, stream_error), Conversation.fromJson (existing).
- **Supabase MCP:** list_tables, execute_sql (policies, publication), apply_migration (realtime + flag; then full migration 20260307219900_chat_presence_and_rls_full) — all SQL for chat presence/RLS/realtime applied via MCP.
- **Feature flag:** app_config key `chat_presence_receipts_enabled` (default true). Set to 'false' to disable presence and receipt ticks.
- **Docs to update:** Sline_everything/DEVELOPER_GUIDE/Chat Feature.md — add presence table, presence service, receipt lifecycle, realtime merge, feature flag, 15s TTL. SUPABASE_SETUP — conversation_presence in realtime publication, app_config key.
