# 📌 Plan: Chat Realtime Sync (08_chat-realtime-sync)

## 1) Goal

- **Goal:** Implement production-grade chat realtime sync: presence (typing indicators), delivery/read receipts, RLS and triggers for `messages` and `conversation_presence`, deduplication via `ChatRealtimeMerger`, and reduced N+1 load on conversation stream.
- **Why:** Current state has missing RLS/triggers and presence table in migrations, presence UI is TODO/hardcoded false, receipt propagation is partial, and `subscribeToConversations` re-fetches full relationship graphs on every stream event.
- **Result:** Secure, observable, resilient realtime chat with single/double tick UX and typing indicators; docs and live DB aligned.

---

## 2) Scope

### In-Scope

- Additive DB: `conversation_presence` table (if missing in live DB), RLS for `messages` and `conversation_presence`, realtime publication for both.
- Presence: Flutter presence upsert/subscribe, 15s TTL handling (client-side or DB trigger), typing indicator in list and chat header.
- Receipts: Ensure `mark_delivered` / `mark_seen` RPCs and stream updates propagate to sender UI (double grey / double blue).
- Dedupe: Use `ChatRealtimeMerger` inside `subscribeToMessages` (or equivalent merge strategy) so reconnects do not duplicate messages.
- Performance: Reduce `subscribeToConversations` load (client-side merge or narrower re-fetch; no full JOIN on every heartbeat).
- Observability: Connection/presence logging and optional correlation (per `.TODO/.../08_chat-realtime-sync` improvement plan).
- Tests: RLS isolation, presence TTL, stream merge; manual E2E for receipts and connection recovery.
- Documentation: DEVELOPER_GUIDE Chat section, SUPABASE_SETUP, STRUCTURE/MVP_ROADMAP if surface changes.

### Out-of-Scope

- Changing message or conversation table schema (additive only).
- New notification types beyond existing message notifications.
- Multi-device read sync beyond single conversation `mark_seen` semantics already in RPCs.

---

## 3) Evidence & Findings (From Scan)

### Existing

- **Docs:** `Sline_everything/SUPABASE_SETUP.md` documents `messages` and `conversation_presence` schema, RLS policy names (e.g. `messages_select`, `messages_insert`, `conversation_presence` policies), and `expire_typing_presence` trigger. Realtime enabled on `messages` per doc. `Sline_everything/DEVELOPER_GUIDE/Chat Feature.md` describes chat flow, MessageService, ChatRepository, ChatViewModel; no presence or receipt lifecycle.
- **Code:** `lib/features/chat/services/message_service.dart` — `markDelivered`/`markSeen` RPCs (lines ~284, ~294), `subscribeToMessages` (stream by `conversation_id`, map to `Message`, sort by `created_at`; no `ChatRealtimeMerger`). `subscribeToConversations` (lines ~447–498): `asyncMap` re-fetches full conversations with `profiles`, `tasks`, `last_message` for all convo IDs on every stream emission. `lib/features/chat/services/chat_realtime_merger.dart` — `ChatRealtimeMerger.merge` exists; not used in `subscribeToMessages`. `lib/features/chat/view/widgets/conversation_list_tile.dart:40` — TODO, `isOnline = false` hardcoded. `lib/features/chat/data/chat_repository.dart` — delegates streams to MessageService. `lib/features/chat/viewmodels/chat_view_model.dart` — uses `subscribeToConversations(user.id)` and `subscribeToMessages(activeConversation!.id)`.
- **Migrations:** No `CREATE TABLE conversation_presence` and no `CREATE POLICY` for `messages` or `conversation_presence` in `supabase/migrations/` (grep returned no matches). Archive migrations reference `messages` (inserts, notify trigger). Doc claims RLS ✅ but migrations do not contain the policies.

### Missing

- Migration that creates `conversation_presence` and adds RLS for `messages` and `conversation_presence`.
- Migration or verified state: `ALTER PUBLICATION supabase_realtime ADD TABLE messages` and `conversation_presence` (doc says realtime on messages; publication add not found in migrations).
- Trigger `expire_typing_presence` (doc claims 15s expiry; not in migrations). Optional: client-side 15s TTL only if DB trigger deferred.
- Presence service or MessageService methods: `upsertPresence`, subscribe to `conversation_presence` for active conversation/list.
- Conversation model fields: `otherUserTyping` / `isOnline` (or equivalent) fed from presence.
- Use of `ChatRealtimeMerger` in the messages stream path.
- RLS check matrix file in `.TODO/` for chat tables.

### Conflicts / Risks (docs vs code vs live DB drift, naming mismatches, security/migration risks)

- **Drift:** SUPABASE_SETUP.md describes RLS and `conversation_presence` as existing; migrations do not. Live DB may already have some objects applied out-of-band — **mandatory:** re-scan live Supabase (tables, policies, publication, triggers) before applying new migration and record findings.
- **Risk:** If RLS is absent on `messages`, any authenticated user could read/write messages outside their conversations until patch is applied.
- **Risk:** N+1 in `subscribeToConversations` can cause high latency under load; fix is in-scope but must not change stream shape contract for ViewModel.
- **Risk:** Presence write storm if clients upsert too frequently; throttle (e.g. max 1 update per 5s) and 15s TTL must be enforced (DB or client).

---

## 4) System Impact Map

- **UI:** Conversation list tile shows real typing/online from presence; chat screen shows typing indicator; message list shows sent/delivered/read ticks. Loading/empty/error states unchanged.
- **MVVM/App Logic:** MessageService gains presence upsert + optional presence stream; subscribeToMessages uses merger for dedupe; subscribeToConversations optimized (merge or reduced re-fetch). ChatViewModel may hold presence state and wire to Conversation model/UI. No direct Supabase in View.
- **Database:** Additive migration: `conversation_presence` table (if missing), RLS on `messages` and `conversation_presence`, realtime publication, optional `expire_typing_presence` trigger.
- **RLS/Security:** Participant-only SELECT/INSERT (and UPDATE where needed) for messages; participant-only SELECT and self-only INSERT/UPDATE for presence. RLS matrix in `.TODO/`.
- **Realtime/Notifications:** Realtime on `messages` and `conversation_presence`; existing message notification triggers unchanged.
- **Storage:** No change (chat-attachments already private with path-based access).
- **Observability:** Logging for presence/receipts/connection where agreed (see Phase 2.4); no PII in logs.
- **Compatibility & Migration:** Additive only; no drop/rename. Old app versions ignore presence; receipt columns already exist.
- **Contracts:** Flutter message/presence shapes must match DB; optional `.TODO/` contract file if RPC/stream payloads change.

---

# ✅ Execution Phases (Checklist)

## Phase 0: Preconditions & Gates

> Primary: @Sentinel

### 0.1 Spec Lock

- [ ] (@Sentinel) Acceptance + non-regression list (measurable): RLS blocks non-participant access; presence appears in UI within 15s TTL; receipts show double grey then double blue; no duplicate messages on reconnect; conversation list does not re-fetch full JOIN on every tick.
- [ ] (@Architect) Confirm modules/entry points: `lib/features/chat/` (MessageService, ChatRepository, ChatViewModel, conversation_list_tile, chat screen).
- **Verify (@Sentinel):** done-conditions + rollback triggers documented.

### 0.2 Threat Model (If sensitive/high-risk)

- [ ] (@ThreatModeler) Threat model + security requirements + negative checks (in `.TODO/` or 08_chat-realtime-sync folder): presence spoofing (RLS auth.uid() = user_id + participant), message injection (participant-only insert), cross-conversation read.
- **Verify (@Sentinel):** testable and included in Phase 4.

### 0.3 Contracts (If payloads change)

- [ ] (@APIContract) If RPC/stream payloads or new table shapes are formalized, contract file(s) in `.TODO/` (DB/RPC ↔ Flutter).
- **Verify (@Sentinel):** contract matches schema + shapes.

### 0.4 Migration Plan (If schema/data changes)

- [ ] (@DataMigration) Single additive migration: create `conversation_presence` if not exists, RLS for `messages` and `conversation_presence`, publication, optional trigger. No backfill (presence is ephemeral). Rollback: drop new policies and table if needed; document forward-fix.
- **Verify (@Sentinel):** measurable compatibility (existing app continues to work; new features opt-in by deployment).

### 0.5 Feature Flag/Rollout (If risky)

- [ ] (@Architect) Optional: feature flag for presence/receipt UI to disable if issues arise.
- **Verify (@Sentinel):** rollback path documented.

---

## Phase 1: Database & Security

> Primary: @Supabase_Ops

### 1.0 Live Supabase Confirmation (MANDATORY)

- [ ] (@Supabase_Ops) Re-scan via Supabase MCP or dashboard: list tables (`messages`, `conversation_presence`), list RLS policies on these tables, list publication `supabase_realtime` tables, list triggers on `messages` and `conversation_presence`.
- [ ] (@Supabase_Ops) Record in plan or `.TODO/`: what exists vs what docs say; avoid drops/renames; additive-only migration.
- **Verify (@Sentinel):** drift + safe approach recorded.

### 1.1 Schema (Additive-first)

- [ ] (@Supabase_Ops) DDL: `CREATE TABLE IF NOT EXISTS public.conversation_presence (conversation_id uuid REFERENCES conversations(id) ON DELETE CASCADE, user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE, is_typing boolean DEFAULT false, updated_at timestamptz DEFAULT now(), PRIMARY KEY (conversation_id, user_id))`.
- [ ] (@Supabase_Ops) Ensure `messages` has required columns (`delivered_at`, `seen_at`); no table drop/rename.
- [ ] (@Supabase_Ops) Indexes: presence lookup by conversation_id if needed; align to RLS filters.
- **Verify (@Sentinel):** no leaks/breaks, naming consistent with SUPABASE_SETUP.md.

### 1.2 RLS

- [ ] (@Supabase_Ops) Policies for `messages`: participant-only SELECT; INSERT with sender_id = auth.uid() and participant check; UPDATE for receiver (e.g. delivered_at/seen_at) per existing RPC semantics.
- [ ] (@Supabase_Ops) Policies for `conversation_presence`: SELECT participant-only; INSERT/UPDATE with auth.uid() = user_id and participant.
- [ ] (@Supabase_Ops) RLS check matrix file in `.TODO/` (e.g. `RLS_Matrix_Chat_YYYY-MM-DD.md`) with positive/negative cases.
- **Verify (@Sentinel):** negative fails, positive passes (manual or test).

### 1.3 Triggers/RPC (If needed)

- [ ] (@Supabase_Ops) Optional: `expire_typing_presence` (e.g. pg_cron or trigger that deletes/updates presence where updated_at < now() - interval '15 seconds'). If deferred, plan documents client-side 15s TTL only.
- [ ] (@Supabase_Ops) Confirm `mark_delivered` / `mark_seen` RPCs exist and update `messages`; no change unless contract requires.
- **Verify (@Sentinel):** state rules enforced.

### 1.4 Realtime Publication

- [ ] (@Supabase_Ops) `ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;` (if not already). `ALTER PUBLICATION supabase_realtime ADD TABLE public.conversation_presence;`
- **Verify (@Sentinel):** subscriptions receive inserts/updates.

### 1.5 Migration Execution

- [ ] (@DataMigration) Apply migration in non-prod first; then prod per project process.
- **Verify (@Sentinel):** verify queries and RLS tests pass.

---

## Phase 2: App Layer (MVVM)

> Primary: @Architect

### 2.1 Models & Contract Compliance

- [ ] (@Architect) Conversation model: add optional `otherUserTyping` / `isOnline` (or equivalent) for list/header; parse from presence or repository layer.
- [ ] (@Architect) Message model: already has `delivered_at`/`seen_at`; ensure mapping and nullability match DB.
- **Verify (@Sentinel):** types/nullability match contract/DB.

### 2.2 Services/Repositories

- [ ] (@Architect) MessageService: add `upsertPresence(conversationId, userId, isTyping)` calling `from('conversation_presence').upsert(...)` with throttle (e.g. 5s min interval per conversation).
- [ ] (@Architect) MessageService: add stream or one-off fetch for `conversation_presence` for active conversation (and optionally for list) so ViewModel can drive typing/online.
- [ ] (@Architect) MessageService `subscribeToMessages`: feed stream through `ChatRealtimeMerger.merge` (accumulate state per conversation, merge new rows, dedupe by id, sort by created_at) so reconnects do not duplicate.
- [ ] (@Architect) MessageService `subscribeToConversations`: replace full asyncMap re-fetch with client-side merge of stream rows + cached profiles/tasks, OR reduce re-fetch to only changed convo IDs / lighter select; preserve stream shape `List<Map<String, dynamic>>` for ViewModel.
- [ ] (@Architect) ChatRepository: expose presence upsert and presence stream/fetch if not already via MessageService.
- **Verify (@Sentinel):** RLS-safe, no UI→Supabase calls; no N+1 in hot path.

### 2.3 ViewModels

- [ ] (@Architect) ChatViewModel: hold presence state (typing/online) for active conversation and optionally for list; call presence upsert on typing start/stop with throttle; subscribe to presence updates when conversation is active.
- [ ] (@Architect) ChatViewModel: ensure message list state is updated from merged stream (delivered_at/seen_at) so UI can show ticks.
- **Verify (@Sentinel):** recoverable state + correct transitions; single source of truth.

### 2.4 Observability (If needed)

- [ ] (@Observability) Event list + correlation strategy (in `.TODO/` or 08 folder): e.g. presence upsert, mark_delivered, mark_seen, stream errors.
- [ ] (@Architect) Instrument services/viewmodels (not UI); no sensitive content in logs.
- **Verify (@Sentinel):** no PII, consistent correlation.

---

## Phase 3: UI (After logic)

> Primary: @Pixel

### 3.1 Wiring

- [ ] (@Pixel) conversation_list_tile: remove TODO; bind `isOnline`/typing to Conversation model or ViewModel presence state (from presence service).
- [ ] (@Pixel) Chat screen header: show "Typing..." when other participant typing (from ViewModel); hide after 15s if no update (client TTL if DB trigger not used).
- [ ] (@Pixel) Message bubbles: show single tick (sent), double grey (delivered), double blue (read) from message `delivered_at`/`seen_at` and stream updates.
- [ ] (@Pixel) Loading/empty/error states for messages and conversation list unchanged or improved.
- **Verify (@Sentinel):** stable UX on slow/empty data; no direct Supabase in widgets.

### 3.2 Polish (Optional)

- [ ] (@Pixel) Micro-interactions for typing indicator (low-risk only).
- **Verify (@Sentinel):** no perf regression.

---

## Phase 4: QA + Security (MANDATORY)

> Primary: @Sentinel

### 4.1 Contract + Migration Checks

- [ ] (@Sentinel) Shapes/types match contract or DB; migration verify queries (if any) pass.
- **Verify (@Sentinel):** no mismatch.

### 4.2 Security + Abuse Tests

- [ ] (@Sentinel) Execute ThreatModeler negative checks: non-participant cannot SELECT/INSERT messages; cannot upsert presence for other user or non-participant conversation.
- [ ] (@Sentinel) RLS leak audit: attempt cross-conversation read in SQL or via client.
- **Verify (@Sentinel):** unauthorized access impossible.

### 4.3 Functional QA

- [ ] (@Sentinel) Manual E2E: send message → other device delivers → other device opens chat → sender sees double grey then double blue.
- [ ] (@Sentinel) Manual E2E: typing indicator appears and disappears within 15s.
- [ ] (@Sentinel) Manual E2E: airplane mode on → send → airplane off → reconnect; no duplicate messages.
- [ ] (@Sentinel) Stream merge unit test: `ChatRealtimeMerger` dedupes and sorts (test file e.g. `test/features/chat/services/chat_realtime_merger_test.dart`).
- **Verify (@Sentinel):** no crashes, consistent behavior.

### 4.4 Observability Validation (If included)

- [ ] (@Sentinel) Required logs/events exist and are useful; privacy redaction enforced.
- **Verify (@Sentinel):** actionable telemetry without leaks.

---

## Phase 5: Documentation Sync (MANDATORY)

> Primary: @DocsKeeper

- [ ] (@DocsKeeper) Update `Sline_everything/DEVELOPER_GUIDE/Chat Feature.md`: presence table, presence service, receipt lifecycle, realtime merge strategy.
- [ ] (@DocsKeeper) Update `Sline_everything/SUPABASE_SETUP.md` if migration adds objects not yet documented; align realtime publication and RLS sections with actual migration.
- [ ] (@DocsKeeper) Update `Sline_everything/STRUCTURE.md` or `MVP_ROADMAP.md` if chat surface or status changes.
- **Verify (@Sentinel):** docs match code + live DB reality.

---

## 7) Acceptance Criteria (MANDATORY)

- RLS: Non-participant cannot read or insert messages; cannot upsert presence for others or non-participant conversations.
- Presence: Typing indicator appears in list/header and disappears within 15s without activity.
- Receipts: Sender sees single tick → double grey (delivered) → double blue (read) after receiver delivers and opens chat.
- Dedupe: After disconnect/reconnect, message list shows exactly one copy of each message.
- Performance: Conversation list stream does not trigger full JOIN re-fetch on every realtime tick (reduced or merged).
- Compatibility: Existing clients without presence/receipt UI continue to work; no breaking change to message/conversation APIs.
- Observability: Agreed events logged without PII.

---

## 8) Rollback Plan

- **DB:** If migration causes issues: drop only new policies and `conversation_presence` table if safe; do not drop `messages` RLS if it was missing (prefer fix-forward with correct policies). Document in migration comment.
- **App:** Revert MessageService/ChatViewModel/UI changes; optional feature flag to disable presence and receipt UI.
- **Emergency:** Disable realtime for `conversation_presence` via publication if presence causes load; clients fall back to no typing indicator.

---

## 9) References (From Scan)

- `.TODO/improvement_the_system/ImplementReady/08_chat-realtime-sync/00_DECISION.md`
- `.TODO/improvement_the_system/ImplementReady/08_chat-realtime-sync/00_HOLISTIC_REPORT.md`
- `.TODO/improvement_the_system/ImplementReady/08_chat-realtime-sync/01_EVIDENCE.md`
- `.TODO/improvement_the_system/ImplementReady/08_chat-realtime-sync/02_PATCH_PLAN.md`
- `.TODO/improvement_the_system/ImplementReady/08_chat-realtime-sync/02_GAPS_AND_FIXES.md`
- `.TODO/improvement_the_system/ImplementReady/08_chat-realtime-sync/03_RISK_REGISTER.md`
- `.TODO/improvement_the_system/ImplementReady/08_chat-realtime-sync/04_TEST_PLAN.md`
- `Sline_everything/DEVELOPER_GUIDE.md`
- `Sline_everything/DEVELOPER_GUIDE/Chat Feature.md`
- `Sline_everything/SUPABASE_SETUP.md` (sections 5.6, 5.7, 7.x messages/conversation_presence, realtime)
- `Sline_everything/STRUCTURE.md`
- `Sline_everything/MVP_ROADMAP.md`
- `Sline_everything/ARCHITECTURE_ANALYSIS.md`
- `Sline_everything/CODE_REVIEW.md`
- `lib/features/chat/services/message_service.dart`
- `lib/features/chat/services/chat_realtime_merger.dart`
- `lib/features/chat/view/widgets/conversation_list_tile.dart`
- `lib/features/chat/data/chat_repository.dart`
- `lib/features/chat/viewmodels/chat_view_model.dart`
- Live Supabase scan (MCP or dashboard): to be performed in Phase 1.0 and results recorded.
