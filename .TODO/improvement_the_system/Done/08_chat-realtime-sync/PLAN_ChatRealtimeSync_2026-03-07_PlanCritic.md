# PlanCritic — Chat Realtime Sync (08_chat-realtime-sync) — Audited & Corrected Plan

**Source plan:** `.TODO/PLAN_ChatRealtimeSync_2026-03-07.md`  
**Workflow:** `@.agents/workflows/plan_critic.md`  
**Date:** 2026-03-07

---

## A) Assumptions + Decision Needed (Blocking)

### Assumptions (inferred)

- Single Flutter codebase; no separate backend. Supabase is the only backend.
- “Live Supabase” = project’s linked Supabase project (staging or prod); scan is manual/MCP.
- Realtime subscription lifecycle: subscriptions are cancelled when ChatViewModel is disposed or screen is popped (existing pattern).
- Throttle for presence: minimum 5s between upserts per conversation (as in patch plan).
- 15s TTL: if DB trigger is not implemented, client ignores `is_typing == true` when `now() - updated_at > 15s`.
- Test runner: `flutter test`; no separate Supabase test runner specified — RLS verification is manual SQL or later automation.
- No deadline; “production-grade” means correctness and security first.

### Decision Needed (Blocking)

| # | What decision is missing | Options | Recommended choice | What changes in plan |
|---|---------------------------|----------|--------------------|----------------------|
| 1 | **subscribeToConversations optimization strategy** | (A) Client-side merge: keep stream of raw convo rows, merge with cached profiles/tasks in memory. (B) Lighter re-fetch: on stream event, fetch only changed convo IDs with same JOIN. (C) Defer: leave as-is, only add presence + receipts. | (A) Client-side merge. | Phase 2.2: add explicit steps for conversation cache (by id), merge function, and stream shape unchanged. If (B): add step to compute diff of convo IDs and fetch only those. If (C): remove performance acceptance criterion. |
| 2 | **15s presence expiry enforcement** | (A) DB trigger/pg_cron that deletes/updates stale presence. (B) Client-only: UI and ViewModel ignore presence older than 15s. | (B) Client-only for first ship; add (A) in a follow-up migration if needed. | Phase 1.3: document “client-side 15s TTL only”; no DB trigger in initial migration. Phase 3.1: explicit step “ignore is_typing when updated_at older than 15s”. |
| 3 | **Feature flag for presence/receipt UI** | (A) No flag; ship always on. (B) App-level flag (e.g. app_config or remote config) to hide presence + receipt ticks. | (B) Flag to disable presence and receipt UI. | Phase 0.5: make feature flag mandatory; Phase 2.3 / 3.1: read flag before showing typing/ticks; Rollback: set flag to disable. |

---

## B) Gate Status (Pass / Fail)

| Gate | Status | Reason | What to add/fix to pass |
|------|--------|--------|--------------------------|
| **Data/Contracts Gate** | ❌ FAIL | (1) RPC contract for `mark_delivered` / `mark_seen` (params, return shape) not written. (2) Presence row shape (conversation_id, user_id, is_typing, updated_at) not in a single contract file. (3) Live DB state unknown until scan. | Add contract file (or section in plan): RPC names, params, return; presence table columns and realtime payload. Make Phase 1.0 output a written “Live DB state” artifact. |
| **Security Gate** | ❌ FAIL | (1) Exact RLS expressions for messages UPDATE (who can set delivered_at/seen_at) not specified. (2) RLS matrix is “in .TODO/” but not a gate prerequisite for Phase 1.2. (3) No automated RLS test (allowed + forbidden) required. | Define UPDATE policy: receiver_id = auth.uid() for delivered_at/seen_at. Require RLS matrix file before Phase 1.2 sign-off. Add step: at least 2 RLS tests (e.g. SQL or integration) — one allowed, one forbidden. |
| **Backend/API Gate** | ❌ FAIL | (1) subscribeToMessages with ChatRealtimeMerger: stream emits full snapshot; merger needs “existing” state — accumulation strategy (per-conversation state in ViewModel vs inside service) not defined. (2) Error handling on stream: on error, emit empty list vs retry vs reconnect not specified. | Add step: define where accumulation lives (ViewModel holds last list, service merges incoming rows with caller-provided existing). Add step: on stream error, log + emit last known list (or empty) and optionally trigger reconnect. |
| **UI/Integration Gate** | ⚠️ PARTIAL | (1) Loading/empty/error for message list and conversation list not explicitly specified (“unchanged or improved”). (2) Offline/connection-lost UX: show “Waiting for connection” or only stale state — not decided. | Add explicit acceptance: message list and conversation list have defined loading, empty, and error states. Add decision or default: on connection lost, show last state + optional banner “Reconnecting…”. |
| **Release/QA Gate** | ❌ FAIL | (1) No test infrastructure gate: no mention of test harness, fixtures, or RLS test runner. (2) E2E is manual only; no timeout/retry policy. (3) No flake/artifact policy. | Add Gate 0 (Test Infrastructure): list test dirs, merger test file, RLS test approach (manual SQL or script). Add E2E timeout (e.g. 60s per scenario) and “max 1 retry on timeout”; document failure artifact (screenshot/log path). |

**Gate 0: Test Infrastructure Gate** — ❌ FAIL  
- No shared test harness or fixture manifest for chat. Merger test is unit (no Supabase). RLS verification is ad-hoc.  
- **Fix:** Require before Phase 4: (1) `test/features/chat/services/chat_realtime_merger_test.dart` exists and runs with `flutter test`. (2) RLS verification method documented (e.g. “Run SQL as User A/B/C in dashboard” or “Add test/rls/ script”). (3) No new test that depends on live Supabase in default `flutter test` (or document env var for integration).

---

## C) Critical Gaps (Must-Fix)

| Gap | Why it will break | Fix (exact step(s)) | Owner | Acceptance check |
|-----|-------------------|---------------------|--------|-------------------|
| **RLS UPDATE policy for messages** | If only SELECT/INSERT are defined, receiver cannot set delivered_at/seen_at via RPC; receipts will never update. | Add in Phase 1.2: CREATE POLICY for UPDATE on messages WHERE receiver_id = auth.uid() (and participant check) for columns delivered_at, seen_at only (or document that RPC uses service role). | @Supabase_Ops | RPC mark_delivered/mark_seen succeeds for receiver; non-receiver UPDATE fails. |
| **Merger accumulation** | ChatRealtimeMerger.merge(existing, newRows, fromJson) requires “existing”. Current subscribeToMessages returns Stream\<List\<Message\>> with no accumulation; each emission is full snapshot. So either service accumulates internally (stateful) or ViewModel feeds previous list into merge — not specified. | Add step: ViewModel (or repository) keeps last List\<Message\> for active conversation; MessageService exposes a stream that emits raw rows (or list); ViewModel/repository merges with last list via ChatRealtimeMerger.merge and updates state. Document in plan: “accumulation in ViewModel; service returns stream of snapshots; merge in ViewModel before notifyListeners”. | @Architect | After reconnect, message list has no duplicates; order by created_at. |
| **Contract artifact** | Flutter and DB can drift (e.g. column rename); no single reference. | Add step in Phase 0.3: Create `.TODO/08_chat_realtime_contract.md` (or section in plan) with: messages columns used by app, conversation_presence columns, mark_delivered(mid uuid), mark_seen(cid uuid) signatures. | @APIContract / @Sentinel | Contract file exists; Phase 2.1/4.1 reference it. |
| **Feature flag** | If presence/receipts cause load or bugs, no way to disable without deploy. | Add Phase 0.5 (mandatory): Implement feature flag (e.g. app_config key or remote config) “chat_presence_receipts_enabled”. Phase 3.1: read flag; if false, hide typing and receipt ticks (single tick only). | @Architect | Flag false → no presence upsert, no receipt ticks; flag true → full UX. |
| **RLS verification tests** | Plan says “manual or test”; without automated checks, regressions can ship. | Add Phase 4.2 step: “At least 2 RLS checks: (1) Participant can SELECT/INSERT messages. (2) Non-participant cannot SELECT messages (expect 0 rows or 42501).” Implement via SQL run in Supabase (e.g. as different users) or documented manual procedure with expected outcomes. | @Sentinel | Documented procedure or script; both checks pass. |

---

## D) Invariants & Success Criteria (Non-Negotiable)

| Invariant | How to enforce | How to verify |
|-----------|----------------|----------------|
| Only conversation participants can read or insert messages. | RLS: SELECT/INSERT USING/WITH CHECK via conversation membership (user1_id/user2_id). | RLS test: non-participant SELECT returns 0 rows; INSERT fails with 42501. |
| Only the receiver can set delivered_at/seen_at on messages. | RLS: UPDATE allowed where receiver_id = auth.uid() (and participant); or RPC uses service role and RPC body checks receiver. | Call mark_delivered/mark_seen as receiver → success; as sender only → no change or denied. |
| Presence rows are only writable by the user themselves for conversations they are in. | RLS: INSERT/UPDATE WITH CHECK auth.uid() = user_id and conversation in (participant conversations). | RLS test: User C cannot INSERT presence for A-B conversation. |
| Message list has at most one row per message id (no duplicates after merge). | ChatRealtimeMerger.merge dedupes by id; accumulation in ViewModel. | Unit test: merge([m1], [m1_updated]) → one element; E2E: reconnect → no duplicate messages. |
| Typing indicator is not shown for presence older than 15s (when DB trigger not used). | ViewModel or UI: if now() - updated_at > 15s, treat is_typing as false. | Manual: stop typing, wait 16s, other client no longer sees “Typing…”. |
| UI never calls Supabase directly. | View uses only ViewModel; ViewModel uses Repository/Service. | Code review / grep: no Supabase.instance in lib/features/chat/view. |

---

## E) Risk Register

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|------|-------|-------------|--------|--------------|--------------|------------|----------|
| Live DB already has conflicting RLS | Phase 1.0 | Med | High | Feature | Migration fails or policies duplicate | Phase 1.0: scan and record; migration uses IF NOT EXISTS / do not create policy if exists | Document exact migration idempotency; have “policy exists” check or use unique names |
| Presence write storm | MessageService.upsertPresence | Med | Med | App-wide (DB load) | High write rate on conversation_presence | Throttle 5s per conversation; client debounce typing | Feature flag off; remove from realtime publication |
| Realtime stream error leaves UI stuck | subscribeToMessages handleError | Med | Med | Feature | User sees stale or empty list | On error: log, emit last known list, optionally trigger reconnect | User reopens chat to resubscribe |
| subscribeToConversations still heavy | Phase 2.2 | High | Med | Feature | Slow conversation list when many convos | Client-side merge; no full re-fetch on every tick | Accept temporary load; optimize in follow-up |
| RLS UPDATE missing | Phase 1.2 | Med | High | Feature | Receipts never turn blue | Explicit UPDATE policy for receiver, columns delivered_at/seen_at | Add policy in hotfix migration |
| Merger not used correctly | Phase 2.2 | Med | High | Feature | Duplicate messages on reconnect | Accumulate in ViewModel; merge each snapshot with previous list | Manual test before release |
| E2E flaky (network/timing) | Phase 4.3 | High | Low | Delivery | Intermittent CI/local failure | Timeout 60s per scenario; max 1 retry; document as manual if needed | Mark E2E as manual until stabilized |

---

## F) Pre-Mortem (How this fails in real life)

- **This fails when** the live DB already has RLS on `messages` with different names or logic, and the migration tries to CREATE POLICY and hits a conflict or duplicate — **fix:** Phase 1.0 scan and idempotent migration (drop if exists then create, or check before create).
- **This fails when** the receiver calls `mark_seen` but there is no RLS UPDATE policy for messages, so the RPC or client update fails and senders never see double blue — **fix:** explicit UPDATE policy in Phase 1.2.
- **This fails when** `subscribeToMessages` emits full snapshots and the ViewModel just assigns the new list; on reconnect the stream re-emits and duplicates appear because there’s no merge — **fix:** ViewModel keeps previous list and merges with ChatRealtimeMerger.
- **This fails when** presence is upserted on every keystroke and the DB or realtime channel is overwhelmed — **fix:** throttle 5s and client-side 15s TTL.
- **This fails when** a bug in presence or receipts causes complaints and there’s no way to turn them off without a new release — **fix:** feature flag to disable presence and receipt UI.
- **This fails when** RLS is verified only manually once and a later migration breaks it — **fix:** document two RLS checks (allowed + forbidden) and run them before release.
- **This fails when** E2E runs without timeout and hangs on slow network — **fix:** 60s timeout and retry policy.

---

## G) Plan Fixes (Concrete Additions / Expansions)

| Goal | Why | How | Output artifact | Stop condition |
|------|-----|-----|-----------------|----------------|
| Contract file | Avoid Flutter/DB drift; single reference. | Write `.TODO/08_chat_realtime_contract.md`: messages columns (id, conversation_id, sender_id, receiver_id, delivered_at, seen_at, created_at, …), conversation_presence columns, RPC signatures mark_delivered(p_message_id uuid), mark_seen(p_conversation_id uuid). | `.TODO/08_chat_realtime_contract.md` | File exists; Phase 2 and 4 reference it. |
| RLS UPDATE for messages | Receiver must be able to set delivered_at/seen_at. | In migration: CREATE POLICY messages_update_by_receiver ON messages FOR UPDATE USING (receiver_id = auth.uid() AND conversation in participant list) with CHECK (only delivered_at/seen_at if needed). Or document RPC uses service role and enforces receiver. | Migration SQL | Receiver can update; non-receiver cannot. |
| Merger accumulation in ViewModel | Dedupe and correct order without stateful service. | ChatViewModel (or repository) keeps _lastMessages for active conversation. When stream emits, call ChatRealtimeMerger.merge(_lastMessages, newRows, Message.fromJson), then set _lastMessages = result, notifyListeners(). Service can stay as stream of snapshots. | Code in ChatViewModel + MessageService | Reconnect E2E shows no duplicates. |
| Feature flag | Safe rollback of presence/receipt UI. | Add app_config or remote key `chat_presence_receipts_enabled`. In ChatViewModel, if false: do not call upsertPresence; do not show typing/ticks (show single tick only). In UI, hide typing indicator and receipt states when false. | Code + config | Flag false → no presence writes, no ticks; flag true → full UX. |
| RLS verification procedure | Regress RLS safely. | Document in `.TODO/` or test/rls: (1) As participant: SELECT messages for own conversation → rows. (2) As non-participant: SELECT messages for other conversation → 0 rows or 42501. Run in Supabase SQL or with two test users. | Doc or script | Two checks pass before release. |
| Stream error handling | Avoid stuck UI. | In subscribeToMessages (or ViewModel): on stream error, log, then emit last known list (or empty). Optionally set “reconnecting” state and resubscribe after delay. | Code | On simulated disconnect, UI shows last list or empty and does not crash. |
| Test infrastructure gate | No fake progress on tests. | Before Phase 4: Ensure merger unit test file exists and runs; RLS verification method documented; no flutter test depending on live Supabase unless gated by env. | Test file + doc | Gate 0 PASS. |
| 15s TTL client-side | Typing disappears when user stops. | In ViewModel/UI: when displaying presence, if DateTime.now().difference(updated_at) > 15s, treat is_typing as false. | Code | Manual: stop typing, 16s later other client sees no “Typing…”. |

---

## H) Corrected Plan (Execution-Ready, Gate-Based)

### Phase 0: Preconditions & Gates

**Goal:** Lock spec, contracts, threat model, migration strategy, and feature flag so execution cannot proceed on wrong assumptions.  
**Why:** Prevents rework and security gaps.  
**How:** Produce artifacts and decisions; block Phase 1 until Gate 0 and Data/Contracts pass.

**Steps:**

0.1 **Spec lock (@Sentinel)**  
- Acceptance list: RLS blocks non-participant; presence in UI within 15s TTL; receipts double grey → double blue; no duplicate messages on reconnect; conversation list does not full re-fetch every tick.  
- Non-regression: existing chat send/receive and conversation list still work.  
- **Artifact:** Bullet list in plan or `.TODO/08_chat_acceptance.md`.

0.2 **Contract (@APIContract / @Sentinel)**  
- Create `.TODO/08_chat_realtime_contract.md`: `messages` columns used by app; `conversation_presence` columns; RPCs `mark_delivered(p_message_id uuid)`, `mark_seen(p_conversation_id uuid)`; realtime payload shapes.  
- **Artifact:** Contract file.

0.3 **Threat model (@ThreatModeler)**  
- Document: presence spoofing (RLS auth.uid() = user_id + participant); message injection (participant-only INSERT); cross-conversation read (RLS SELECT). Negative tests: User C cannot read A-B messages; cannot upsert presence for A-B.  
- **Artifact:** `.TODO/08_chat_realtime_sync` or plan section.

0.4 **Decisions (blocking)**  
- **subscribeToConversations:** Client-side merge (recommended): stream raw convo rows; cache profiles/tasks by id; merge in memory; emit same stream shape.  
- **15s TTL:** Client-only: ignore is_typing when updated_at older than 15s; no DB trigger in first migration.  
- **Feature flag:** Mandatory. Key: e.g. `chat_presence_receipts_enabled`. When false: no presence upsert, no typing/ticks (single tick only).

0.5 **Migration plan (@DataMigration)**  
- Single additive migration: CREATE TABLE conversation_presence (if not exists); RLS for messages (SELECT, INSERT, UPDATE for receiver); RLS for conversation_presence; ADD TABLE to supabase_realtime. No backfill. Rollback: drop new policies and conversation_presence; do not drop messages RLS (fix-forward if missing).

0.6 **Gate 0: Test infrastructure (@Sentinel)**  
- Ensure `test/features/chat/services/chat_realtime_merger_test.dart` exists and runs with `flutter test`.  
- Document RLS verification: 2 checks (participant allowed, non-participant forbidden).  
- **GATE CHECK:** Merger test passes; RLS verification method documented. **If FAIL:** block until done.

**Result:** Contract file, threat model, decisions, migration plan, test gate passed. No Phase 1 until Gate 0 and contract exist.

---

### Phase 1: Database & Security

**Goal:** Additive schema, RLS, and realtime so app can safely use presence and receipts.  
**Why:** Current migrations lack conversation_presence and possibly messages RLS.  
**How:** Scan live DB; then one migration; then verify.

**Steps:**

1.0 **Live Supabase scan (MANDATORY) (@Supabase_Ops)**  
- List tables: messages, conversation_presence. List RLS policies on both. List publication supabase_realtime. List triggers on both.  
- Record: “Live DB state” (what exists vs SUPABASE_SETUP.md). Plan migration to be idempotent (IF NOT EXISTS, avoid duplicate policy names).  
- **Artifact:** `.TODO/08_live_db_state_YYYYMMDD.md` or section in plan.  
- **GATE CHECK:** Data/Contracts — contract file exists; live state recorded. **If FAIL:** do not run migration.

1.1 **Schema (@Supabase_Ops)**  
- CREATE TABLE IF NOT EXISTS public.conversation_presence (conversation_id uuid REFERENCES conversations(id) ON DELETE CASCADE, user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE, is_typing boolean DEFAULT false, updated_at timestamptz DEFAULT now(), PRIMARY KEY (conversation_id, user_id)).  
- Verify messages has delivered_at, seen_at (add columns if missing, additive).  
- Index on conversation_presence(conversation_id) for lookups.  
- **Artifact:** Migration file.

1.2 **RLS (@Supabase_Ops)**  
- **messages:** SELECT participant-only (via conversation user1_id/user2_id). INSERT sender_id = auth.uid() and participant. **UPDATE** (critical): receiver_id = auth.uid() and participant, for columns delivered_at, seen_at (or document RPC uses service role and enforces).  
- **conversation_presence:** SELECT participant-only; INSERT/UPDATE auth.uid() = user_id and participant.  
- Create RLS matrix file `.TODO/RLS_Matrix_Chat_YYYY-MM-DD.md`: positive (participant SELECT/INSERT/UPDATE) and negative (non-participant SELECT/INSERT, other user presence INSERT).  
- **Artifact:** Migration SQL + RLS matrix file.

1.3 **Realtime publication (@Supabase_Ops)**  
- ALTER PUBLICATION supabase_realtime ADD TABLE public.messages; (if not already). ADD TABLE public.conversation_presence.  
- **Artifact:** Migration SQL.

1.4 **Migration execution (@DataMigration)**  
- Apply migration in non-prod first, then prod. Run verify queries.  
- **GATE CHECK:** Security — RLS matrix done; at least 2 RLS checks (allowed + forbidden) run and pass. **If FAIL:** fix policies and re-run.

**Result:** conversation_presence table exists; messages and conversation_presence have RLS; realtime includes both. RLS matrix and two checks passed.

---

### Phase 2: App Layer (MVVM)

**Goal:** Services and ViewModels support presence, receipts, merge, and optimized conversation stream without breaking View contract.  
**Why:** UI must not call Supabase; single source of truth in ViewModel.  
**How:** Add presence and merge; respect feature flag; keep stream shapes.

**Steps:**

2.1 **Models (@Architect)**  
- Conversation: add optional otherUserTyping (bool), presenceUpdatedAt (DateTime?) — from presence or repository. Message: ensure delivered_at, seen_at mapped; nullability matches contract.  
- **Artifact:** conversation_model.dart, message_model.dart.

2.2 **MessageService (@Architect)**  
- upsertPresence(conversationId, userId, isTyping): throttle 5s per conversation; from('conversation_presence').upsert(...).  
- subscribeToPresence(conversationId): stream from('conversation_presence').stream(...).eq('conversation_id', conversationId).  
- subscribeToMessages: keep returning Stream\<List\<Message\>>. Option A: emit raw rows and let ViewModel merge (see 2.4). Option B: service holds last list per conversation and merges internally — then document stateful contract. Recommended: emit snapshot; ViewModel merges (2.4).  
- subscribeToConversations: implement client-side merge: stream raw conversation rows; maintain in-memory cache of conversations by id (with profiles/tasks/last_message from initial fetch or first emission); on each emission, merge by id, refill cache only for new/changed ids with one batched fetch if needed; emit List\<Map\> unchanged shape. No full JOIN on every tick.  
- **Artifact:** message_service.dart.

2.3 **ChatRepository (@Architect)**  
- Expose upsertPresence, subscribeToPresence (or getPresenceStream), subscribeToMessages, subscribeToConversations.  
- **Artifact:** chat_repository.dart.

2.4 **ChatViewModel (@Architect)**  
- If feature flag false: do not call upsertPresence; do not subscribe to presence; message status = sent only (no ticks).  
- If feature flag true: hold _lastMessages for active conversation. On subscribeToMessages emission: merged = ChatRealtimeMerger.merge(_lastMessages, rows, Message.fromJson); _lastMessages = merged; notifyListeners().  
- Hold presence state (otherUserTyping, presenceUpdatedAt) for active conversation; subscribe to presence stream when conversation is active; when displaying, if now() - presenceUpdatedAt > 15s, treat otherUserTyping as false.  
- On typing start/stop: call upsertPresence (throttled).  
- On stream error (if observable): log; keep last list; optionally set reconnecting and resubscribe.  
- **Artifact:** chat_view_model.dart.

2.5 **Observability (@Observability)**  
- Event list: presence_upsert, mark_delivered, mark_seen, stream_error. Correlation: conversation_id or user_id (no PII in logs). Instrument in service/ViewModel only.  
- **Artifact:** `.TODO/` event list or doc.

**GATE CHECK:** Backend/API — merger used with accumulation; stream error handling defined; no UI→Supabase. **If FAIL:** fix accumulation/error handling.

**Result:** Presence and receipts supported; conversation stream optimized; feature flag and 15s TTL enforced; observability in place.

---

### Phase 3: UI

**Goal:** Typing indicator and receipt ticks visible; loading/empty/error explicit; no direct Supabase.  
**Why:** User sees production-grade chat UX.  
**How:** Bind ViewModel presence and message status; respect feature flag; 15s TTL in display.

**Steps:**

3.1 **Conversation list tile (@Pixel)**  
- Remove TODO. Bind isOnline / typing from Conversation model (ViewModel provides Conversation with otherUserTyping/presenceUpdatedAt). If feature flag false, show isOnline = false, no typing. If presenceUpdatedAt older than 15s, show typing = false.  
- **Artifact:** conversation_list_tile.dart.

3.2 **Chat screen header (@Pixel)**  
- Show “Typing…” when ViewModel.otherUserTyping == true and updated_at within 15s. Hide after 15s. Feature flag false → never show.  
- **Artifact:** chat screen (header).

3.3 **Message bubbles (@Pixel)**  
- Single tick: sent (no delivered_at). Double grey: delivered_at set. Double blue: seen_at set. Data from Message.deliveredAt/seenAt (stream updates). Feature flag false → single tick only.  
- **Artifact:** message bubble widget.

3.4 **Loading / empty / error (@Pixel)**  
- Message list: loading spinner while initial load; empty state text when no messages; error state with retry if stream/repository fails. Conversation list: same. Document or keep existing behavior.  
- **Artifact:** messages_screen.dart, chat_screen.dart (or existing widgets).

**GATE CHECK:** UI/Integration — loading/empty/error defined; feature flag and 15s TTL applied. **If FAIL:** add missing states.

**Result:** Typing and receipts visible when flag on; 15s TTL; no direct Supabase in view.

---

### Phase 4: QA + Release

**Goal:** Security, functional, and regression checks pass; release gate clear.  
**Why:** Prevent regressions and insecure releases.  
**How:** RLS checks, E2E script, merger unit test, docs.

**Steps:**

4.1 **Contract + migration (@Sentinel)**  
- Verify Flutter types match contract; migration verify queries pass.  
- **Artifact:** Sign-off.

4.2 **Security (@Sentinel)**  
- Run 2 RLS checks: (1) Participant SELECT/INSERT messages — success. (2) Non-participant SELECT messages — 0 rows or 42501. Document procedure; run before release.  
- Threat model negative cases: presence spoof, cross-conversation read — blocked.  
- **Artifact:** RLS matrix + run record.

4.3 **Functional QA (@Sentinel)**  
- Manual E2E: send → other device delivers → other opens chat → sender sees double grey then double blue.  
- Manual E2E: typing appears and disappears within 15s.  
- Manual E2E: airplane on → send → airplane off → reconnect → no duplicate messages.  
- Unit: ChatRealtimeMerger dedupes and sorts (test file).  
- Timeout: 60s per E2E scenario; max 1 retry on timeout. Document failure artifact (screenshot/log path).  
- **Artifact:** Test plan doc; merger test green.

4.4 **Observability (@Sentinel)**  
- Confirm required events logged; no PII.  
- **Artifact:** Sign-off.

**GATE CHECK:** Release/QA — RLS checks passed; merger test passed; E2E scenarios run; observability checked. **If FAIL:** fix and re-run.

**Result:** All gates passed; release allowed.

---

### Phase 5: Documentation

**Goal:** Docs match code and DB.  
**Why:** Onboarding and future changes.  
**How:** Update Chat feature doc, SUPABASE_SETUP, STRUCTURE/MVP if needed.

**Steps:**

5.1 **(@SlineDocs)**  
- Update DEVELOPER_GUIDE/Chat Feature.md: presence table, presence service, receipt lifecycle, realtime merge strategy, feature flag, 15s TTL.  
- Update SUPABASE_SETUP.md: conversation_presence, messages RLS (including UPDATE), realtime publication.  
- Update STRUCTURE.md or MVP_ROADMAP.md if chat surface changed.  
- **Artifact:** Updated docs.

**Result:** Docs aligned with code and live DB.

---

## I) Change Report (Diff-Style)

### 1) Original issues summary

- RLS UPDATE for messages not specified (receiver could not set delivered_at/seen_at).  
- ChatRealtimeMerger accumulation strategy undefined (where “existing” lives).  
- subscribeToConversations optimization left as “client-side merge OR lighter re-fetch” (ambiguous).  
- 15s TTL: DB trigger vs client not decided.  
- Feature flag optional; no safe rollback.  
- No contract file; no RLS matrix as gate.  
- No Gate 0 (test infrastructure); no explicit RLS tests (2).  
- Stream error handling and loading/empty/error states vague.  
- E2E timeout/retry and artifact policy missing.

### 2) Added steps

- Create `.TODO/08_chat_realtime_contract.md` (Phase 0.2).  
- Mandatory feature flag and 15s client-side TTL decision (Phase 0.4).  
- Gate 0: Test infrastructure — merger test exists, RLS verification method documented (Phase 0.6).  
- RLS UPDATE policy for messages (Phase 1.2).  
- RLS matrix file required before Phase 1.2 sign-off (Phase 1.2).  
- Live DB state artifact (Phase 1.0).  
- ViewModel accumulation for ChatRealtimeMerger (Phase 2.4).  
- Explicit stream error handling (keep last list; optional reconnect) (Phase 2.4).  
- Two RLS checks (allowed + forbidden) before release (Phase 4.2).  
- E2E timeout 60s, max 1 retry, failure artifact (Phase 4.3).  
- Explicit loading/empty/error for message and conversation list (Phase 3.4).

### 3) Removed steps

- None; only made optional items mandatory (feature flag, contract, RLS matrix, RLS tests).

### 4) Reordered steps

- Contract creation moved earlier (Phase 0.2) so Phase 1 and 2 reference it.  
- Gate 0 before Phase 1 so test infra is not skipped.  
- RLS matrix and two checks required before Phase 1.2 sign-off and again in Phase 4.2.

### 5) Expanded steps

- Phase 1.2: Added exact RLS UPDATE for messages (receiver, delivered_at/seen_at).  
- Phase 2.2: subscribeToConversations specified as “client-side merge” with cache and no full JOIN per tick.  
- Phase 2.4: Accumulation in ViewModel with ChatRealtimeMerger.merge; feature flag and 15s TTL in ViewModel.  
- Phase 4.2: Two RLS checks with procedure.  
- Phase 4.3: Timeout and retry policy; failure artifact.

### 6) Why (short)

- UPDATE policy: required for receipts to work.  
- Accumulation: required for dedupe; ViewModel keeps single source of truth.  
- Contract + matrix: avoid drift and regressions.  
- Feature flag: safe rollback.  
- Gate 0 + RLS tests: no fake progress; security verified.  
- Timeout/retry/artifact: stable E2E and debuggability.

### 7) Residual risks

- Live DB may already have policies with different names; migration must be idempotent (recorded in 1.0).  
- E2E still manual; flakiness possible until automated and stabilized.  
- subscribeToConversations client-side merge adds in-memory cache complexity; must be tested under many conversations.

---

**End of PlanCritic output.** Use this document as the execution-ready plan; run phases in order and pass each GATE CHECK before proceeding.
