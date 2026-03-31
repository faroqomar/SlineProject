# CodeGuard Review Report: Chat Realtime Sync

**Date:** 2026-03-08  
**Scope:** Chat Realtime Sync (feature 08_chat-realtime-sync)  
**Plan:** `.TODO/PLAN_ChatRealtimeSync_2026-03-07_PlanCritic.md`  
**Execution:** `.TODO/EXECUTION_LOG_ChatRealtimeSync_2026-03-07.md`

---

## Scope

- **Change Type:** MEDIUM (realtime subscriptions, presence, receipts, RLS, migrations)
- **Areas:** UI, MVVM (viewmodels, services, repository), models, DB/RLS, Realtime, migrations
- **Files Reviewed:**
  - `lib/features/chat/view/chat_screen.dart`
  - `lib/features/chat/view/widgets/conversation_list_tile.dart`
  - `lib/features/chat/viewmodels/chat_view_model.dart`
  - `lib/features/chat/data/chat_repository.dart`
  - `lib/features/chat/services/message_service.dart`
  - `lib/features/chat/services/chat_realtime_merger.dart`
  - `lib/features/chat/models/conversation_model.dart`
  - `lib/features/chat/models/message_model.dart`
  - `test/features/chat/services/chat_realtime_merger_test.dart`
  - `supabase/migrations/20260307219900_chat_presence_and_rls_full.sql`
  - `supabase/migrations/20260307220000_chat_realtime_presence_publication.sql`
  - `supabase/migrations/20260307220100_chat_presence_receipts_flag.sql`
- **Docs Scanned:** `Sline_everything/DEVELOPER_GUIDE.md`, `Sline_everything/SUPABASE_SETUP.md`, `Sline_everything/CODE_REVIEW.md`, `.TODO/08_chat_realtime_contract.md`, `.TODO/RLS_Matrix_Chat_2026-03-07.md`, `.TODO/08_RLS_verification_chat.md`

---

## Evidence Collected

### Commands run

| Command | Result |
|--------|--------|
| `flutter analyze lib/features/chat/` | No issues found (exit 0) |
| `flutter test test/features/chat/services/chat_realtime_merger_test.dart` | 4 tests passed (exit 0) |
| `flutter pub outdated` | Run; no security advisories inferred for chat-related deps (supabase_flutter, etc.) |

### Docs scanned

- DEVELOPER_GUIDE.md (Chat feature ref, MVVM, no direct Supabase in view)
- SUPABASE_SETUP.md (conversation_presence, messages, realtime)
- CODE_REVIEW.md (guardrails, error handling)
- Contract: `.TODO/08_chat_realtime_contract.md` (messages, conversation_presence, RPCs, realtime)
- RLS matrix: `.TODO/RLS_Matrix_Chat_2026-03-07.md` (messages + presence policies)
- RLS verification: `.TODO/08_RLS_verification_chat.md` (Check 1–4 procedure)

### Web freshness checks

- Not performed for this review (no dependency upgrade in scope). `flutter pub outdated` shows supabase_flutter and other deps have newer versions; no change required for this feature merge.

---

## Critical Issues (BLOCKERS)

**None.**

---

## Warnings (Should Fix)

### 1) Migration order / idempotency — 20260307220000 [MED]

- **Finding:** `20260307220000_chat_realtime_presence_publication.sql` runs `ALTER PUBLICATION supabase_realtime ADD TABLE public.conversation_presence` with no guard. Migration `20260307219900_chat_presence_and_rls_full.sql` already adds `conversation_presence` to the publication inside a `DO $$ ... IF NOT EXISTS` block. If both run in order, the second ADD can fail on “table already in publication”.
- **Risk:** Deployment failure or inconsistent migration history when 19900 is applied before 20000.
- **Suggestion:** Prefer a single migration path (e.g. only 19900) or make 20000 idempotent (e.g. same IF NOT EXISTS pattern). Owner: @Supabase_Ops / @DataMigration.

### 2) refreshOfferStatusesForCurrentMessages on every message emission [MED]

- **Finding:** In `ChatViewModel.subscribeToActiveConversation()`, the message stream listener awaits `refreshOfferStatusesForCurrentMessages()` on every emission. That triggers a batch `getOffersByIds` for all offer messages in `currentMessages`. High realtime churn could cause many sequential calls.
- **Risk:** Latency or backlog under heavy message flow; minor performance concern.
- **Suggestion:** Debounce (e.g. 500 ms) or call only when the merged list actually contains offer messages and has changed. Owner: @Architect.

### 3) markReceiptsForActive call frequency [LOW]

- **Finding:** `markReceiptsForActive(delivered: true, seen: false)` is invoked unawaited on subscribe (twice) and inside the message stream listener on every emission. RPCs `mark_conversation_delivered` / `mark_conversation_seen` are conversation-scoped; repeated calls are idempotent but add load.
- **Risk:** Extra RPC traffic; acceptable for correctness.
- **Suggestion:** Consider marking delivered/seen once when opening the conversation and optionally when new messages from the other party arrive, rather than on every snapshot. Owner: @Architect.

---

## Passed Checks

- **MVVM / No direct Supabase in view:** No `Supabase.instance` or `Supabase.instance.client` in `lib/features/chat/view/`. Chat screen and conversation list tile use `context.read<ChatViewModel>()` / `context.watch<ChatViewModel>()` and ViewModel APIs only.
- **Stream / subscription cleanup:** `ChatViewModel.dispose()` cancels `_msgSub`, `_inboxMsgSub`, `_presenceSub`. `teardownForRoleSwitch()` cancels the same and calls `client.removeAllChannels()`. `unsubscribeFromConversation()` cancels message and presence subscriptions. No leak from undisposed subscriptions.
- **Merger accumulation:** ViewModel keeps `_lastMessages`; on each `subscribeToMessages` emission it merges via `ChatRealtimeMerger.merge(_lastMessages, newRows, Message.fromJson)`, then assigns `_lastMessages = merged` and updates `currentMessages`. Plan requirement (accumulation in ViewModel, merge before notify) is met.
- **Stream error handling:** Message stream `onError` restores `currentMessages` from `_lastMessages` and calls `_notify()`. Service stream uses `handleError` and logs. No stuck empty UI without fallback.
- **15s TTL for typing:** ViewModel getter `otherUserTyping` returns false when `_presenceUpdatedAt` is null or older than 15s. `ConversationListTile._isTypingWithin15s` enforces 15s for list tile. Typing indicator in chat header uses `vm.otherUserTyping`. Plan requirement (client-side 15s TTL) is met.
- **Feature flag:** `isPresenceReceiptsEnabled` is read from `app_config` (key `chat_presence_receipts_enabled`), cached 1 minute in `MessageService`. When false, ViewModel does not call `upsertPresence` or subscribe to presence; UI shows single tick only and no “Typing…” (receipt/typing logic gated by `controller.isPresenceReceiptsEnabled` and `vm.otherUserTyping`).
- **Presence throttle:** `MessageService.upsertPresence` throttles to at most once per 5s per conversation via `_lastPresenceUpsertByConvo`. Plan requirement (5s throttle) is met.
- **RLS:** Migration 20260307219900 creates `conversation_presence` with RLS; policies `presence_select_participant`, `presence_upsert_self`, `presence_update_self` (participant-only SELECT, self-only INSERT/UPDATE). Messages RLS left to existing policies; `.TODO/RLS_Matrix_Chat_2026-03-07.md` documents `messages_update_by_receiver` for receipts. Contract and RLS matrix align with implementation.
- **Secrets / logging:** No hardcoded secrets or tokens. AppLogger used for presence, receipts, stream errors; no PII in log messages (conversation_id / user_id only where needed).
- **Receipt RPCs:** Repository exposes `markDelivered` / `markSeen` calling `mark_conversation_delivered` and `mark_conversation_seen`; contract and plan match.
- **Merger unit tests:** `chat_realtime_merger_test.dart` has 4 tests: empty + new rows sorted, dedupe by id (new wins), order by created_at, skip unparseable row. All pass. One test intentionally supplies a bad row; merger skips it and logs (expected).
- **Rebuild scope:** Chat screen uses `Consumer<ChatViewModel>` for message list and typing; `ListView.builder` used for messages, so only visible items build. No full-tree rebuild storm identified.
- **N+1:** Conversation list updates via inbox message stream; for new conversation ids, `getConversationById` is called once per new id and guarded by `_fetchingConversationIds`. Acceptable for “new convo from inbox” flow; no classic N+1 on a single list query.

---

## Risk Notes

- **Threat model:** Contract and RLS matrix state presence spoof and cross-conversation read are blocked (participant-only SELECT; INSERT/UPDATE only for self on presence). RLS verification procedure (`.TODO/08_RLS_verification_chat.md`) defines four checks (participant SELECT/INSERT messages, non-participant SELECT messages, receiver UPDATE receipts, non-participant presence INSERT). Manual run before release is required; no automated RLS tests in repo.
- **Regression:** Existing chat send/receive and conversation list behavior depends on same ViewModel and repository; realtime merge is additive. Risk of duplicate messages on reconnect is mitigated by merger + accumulation.
- **Migration 20260307220100:** Inserts `chat_presence_receipts_enabled` with ON CONFLICT DO NOTHING; idempotent. 20260307219900 also inserts the same key; duplicate run is safe.

---

## Dependency Status

- **Outdated:** `flutter pub outdated` shows several packages (e.g. supabase_flutter, app_links, file_picker) with newer versions. Not introduced by this feature.
- **Deprecated:** None identified for chat code paths.
- **Security advisories:** No specific advisory checked for supabase_flutter or realtime usage for this review.
- **Recommendation:** Schedule dependency upgrades (including supabase_flutter) in a dedicated pass; not a gate for this merge.

---

## Final Decision

**APPROVED**

No Critical or BLOCKER issues. Implementation matches the PlanCritic plan: ViewModel accumulation with ChatRealtimeMerger, stream error handling, 15s TTL, feature flag, presence throttle, RLS and contract documented, merger tests passing, no direct Supabase in view, and subscriptions cleaned up on dispose/teardown.

**Next actions:**

1. Address Warnings 1–3 when convenient (migration idempotency, debounce offer refresh, optional receipt call tuning).
2. Run RLS verification (Check 1–4 in `.TODO/08_RLS_verification_chat.md`) before release and record outcome.
3. Complete Phase 5 (documentation) if not already done: update DEVELOPER_GUIDE Chat section and SUPABASE_SETUP for presence table, feature flag, and realtime publication.
