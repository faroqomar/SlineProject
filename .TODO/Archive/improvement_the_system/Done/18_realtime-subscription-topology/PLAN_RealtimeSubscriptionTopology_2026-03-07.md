# Plan: Realtime Subscription Topology (18) — Plan Critic Revision

**Source:** `.TODO/PLAN_RealtimeSubscriptionTopology_2026-03-07.md` (original)  
**Workflow:** @PlanCritic (`.agents/workflows/plan_critic.md`)  
**Date:** 2026-03-07

---

## A) Assumptions + Decision Needed (Blocking)

### Assumptions (inferred)

- Live DB publication currently includes `messages`; may or may not include `notifications` (docs conflict). Plan does not add or remove tables from publication.
- `Conversation` model is immutable (final fields). Merge = replace list entry with new `Conversation` instance with updated last_message_* from `Message`, not mutate in place.
- Single developer or small team; no separate QA automation harness for realtime. Manual E2E + log inspection are the primary verification.
- No feature flag required; rollback = revert commit or disable call to `subscribeToUserConversations()`.
- Branch strategy: single PR for service + repository + viewmodel + docs; no long-lived feature branch specified.

### Decision Needed (Blocking)

| Decision | Options | Recommended | Plan impact |
|----------|---------|-------------|-------------|
| **New conversation ID not in list:** when message arrives for unknown `conversation_id`, how to hydrate? | (1) Call `fetchConversations()` once; (2) Fetch single conversation by ID via new repo method; (3) Ignore and rely on next pull-to-refresh | **Option 2**: Add `getConversationById(conversationId)` (or reuse existing getter if any), fetch one row with relations, append to list and sort. Avoids full refetch and keeps UX instant. | Plan must add explicit step: implement single-conversation fetch and call it from ViewModel when conversation_id not in list. |
| **Publication check shows `conversations` in result** | (1) Block plan until removal migration is added; (2) Add Phase 1.5: migration to remove conversations from publication, then proceed | **Option 1**: Block. Plan assumes conversations is NOT in publication. If it is, add a separate plan/migration to remove it first, then execute this plan. | Phase 1 Gate: if conversations in publication → STOP and document; do not proceed to Phase 2 until resolved. |

---

## B) Gate Status (Pass/Fail)

| Gate | Status | Reason | What to add/fix to pass |
|------|--------|--------|--------------------------|
| **1) Data/Contracts** | ❌ FAIL | Merge logic underspecified: Conversation is immutable; “update” must be “replace with new instance”. No explicit contract for “new conversation” hydration path. | Add step: ViewModel merge builds new `Conversation` instances (copy existing + lastMessage/lastMessageTime/lastMessageSenderId from Message). Add step: single-conversation fetch when conversation_id not in list. Confirm Message fields used in merge (conversationId, content, created_at, sender_id) in contract. |
| **2) Security** | ✅ PASS | RLS unchanged; messages stream filtered by receiver_id; messages_select already enforces participant. | None. |
| **3) Backend/API** | ⚠️ CONDITIONAL | Pass only after live publication check. If conversations is in publication, gate fails. | Run `SELECT * FROM pg_publication_tables WHERE pubname='supabase_realtime';` before Phase 2. If conversations appears → fail gate and block. |
| **4) UI/Integration** | ❌ FAIL | No explicit loading/error state for “new conversation” fetch; rapid re-subscribe (e.g. role switch) could double-fetch. | Add: loading guard so only one fetchConversations or getConversationById runs at a time for “new convo” path; ensure empty/error state for Inbox still works when stream has no events yet. |
| **5) Release/QA** | ❌ FAIL | No automated test; no written E2E script; no flake/retry policy; “check logs” is vague. | Add: written manual E2E script (steps + expected result); add acceptance check that no `SELECT ... conversations ... IN` appears in logs during test; document where to look (AppLogger tag / pg_stat_statements). |

---

## C) Critical Gaps (Must-Fix)

| Gap | Why it will break | Fix | Owner | Acceptance |
|-----|-------------------|-----|--------|------------|
| **Merge semantics ambiguous** | Code assumes mutable “update”; `Conversation` is immutable. Wrong implementation will not compile or will not update UI. | State explicitly: for each message, find conversation by id; create new `Conversation(..., lastMessage: message.content, lastMessageTime: message.createdAt, lastMessageSenderId: message.senderId, ...)`; replace in list; sort; notify. | @Architect | Merge step in plan and code uses new instance, not mutation. |
| **New conversation ID not in list** | Plan says “fetchConversations or fetch that conversation” but no method exists for single fetch; full fetchConversations on every new chat could cause spinner/N+1 on open. | Add repository method `getConversationById(conversationId)` (or equivalent) returning one Conversation with relations; ViewModel calls it when message.conversationId not in list; append result, sort, notify. | @Architect | Single-conversation fetch exists and is used in subscribe handler. |
| **Subscription type rename** | `_convoSub` currently `StreamSubscription<List<Map>>`; new stream is `List<Message>`. Type change and handler signature must be consistent. | Change to `StreamSubscription<List<Message>>? _inboxMsgSub` (or keep name); cancel in dispose; same re-subscribe cancel pattern. | @Architect | Compiles; no leftover Map parsing in handler. |
| **No written E2E script** | “Manual E2E” with no script leads to inconsistent verification and missed steps. | Add to plan: “Manual E2E script” artifact: numbered steps (e.g. 1. Login A, 2. Login B, 3. B sends message to A, 4. A on Inbox sees update without refresh) and expected result; add “Check logs for absence of conversations IN query”. | @Sentinel | Document exists; QA runs it before release gate. |
| **Double fetch on “new convo”** | If two messages for same new conversation arrive in quick succession, ViewModel might call getConversationById twice. | Guard: track “pending fetch” for conversation IDs or debounce; only one in-flight fetch per conversation_id. | @Architect | At most one fetch per new conversation_id until in list. |
| **Live publication not confirmed before code change** | If conversations is in publication, removing only the client stream leaves DB still broadcasting; later re-adding client code could reintroduce N+1. | Phase 1 gate: run publication query; record result; if conversations in list, block and add removal to plan or separate change. | @Supabase_Ops | Publication result documented; plan does not proceed if conversations present. |

---

## D) Invariants & Success Criteria (Non-Negotiable)

| Invariant | How to enforce | How to verify |
|-----------|----------------|----------------|
| **Inbox realtime uses only the messages stream (receiver_id=userId), never conversations stream** | Delete `subscribeToConversations`; no `.from('conversations').stream(...)` in chat service. | Grep codebase for `conversations` + `stream`; must be empty. |
| **No REST/select inside realtime stream handlers for conversation list updates** | No `.select()`, `.in_('id', ...)` or asyncMap over stream in message_service inbox path. | Code review; no asyncMap in subscribeToInboxMessages. |
| **supabase_realtime publication does not include conversations** | No migration adding conversations; if present in DB, separate removal. | `SELECT * FROM pg_publication_tables WHERE pubname='supabase_realtime';` → conversations not in result. |
| **RLS messages_select applies to realtime payloads** | Supabase applies RLS to realtime; filter receiver_id=userId narrows at client. | Existing RLS policy; no change. |
| **Single source of truth for conversation list on Inbox** | ViewModel holds one `conversations` list; initial load via fetchConversations; updates only via message stream merge or single-conversation fetch. | No duplicate lists; one notifyListeners after merge/fetch. |

---

## E) Risk Register

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|------|-------|-------------|--------|--------------|-------------|------------|----------|
| Live DB has conversations in publication | Phase 1 | Low | High | Feature / DB load | Publication query result | Run query first; block if present | Add migration to remove conversations from publication; re-run plan |
| Merge logic creates wrong Conversation (missing required fields) | ViewModel | Med | Med | Feature (wrong preview/order) | Wrong text or order in Inbox | Use copy-with or explicit constructor; unit test merge helper | Manual check; fix constructor |
| Double fetch for new conversation | ViewModel | Med | Low | Local (extra request) | Logs show two getConversationById for same id | Guard: one in-flight fetch per conversation_id | Debounce or set of “fetching” ids |
| Re-subscribe without cancel (e.g. role switch) leaves two listeners | ChatViewModel | Low | Med | App-wide (double updates) | Duplicate UI updates or leaks | Cancel previous _inboxMsgSub before subscribe; dispose cancels | Role switch coordinator already teardown; verify cancel in dispose |
| Documentation still says “conversations in publication” | Docs | Med | Med | Team (wrong mental model) | Doc review | Update diagram + DEVELOPER_GUIDE + SUPABASE_SETUP in same PR | Doc sync step in plan; verify in release gate |
| Someone re-adds conversations stream later | Future code | Med | High | App/DB | Grep in codebase | Delete path; document invariant; comment in code | N/A |
| E2E not run / false pass | QA | Med | High | Feature | No written script; ad-hoc testing | Written E2E script; checklist in release gate | Require sign-off on script before merge |

---

## F) Pre-Mortem (How this fails in real life)

- **This fails when** the executor “updates” Conversation in place and the app doesn’t compile or list doesn’t refresh, because Conversation is immutable.
- **This fails when** a new message arrives for a brand-new conversation and the ViewModel calls fetchConversations() every time, causing a full loading spinner and extra load.
- **This fails when** the live DB has conversations in the publication and we only change the app; later someone re-enables the client stream and N+1 returns.
- **This fails when** two messages for the same new conversation arrive in a burst and the ViewModel fires two getConversationById calls and the list flashes or duplicates.
- **This fails when** QA “tested it” but there’s no script, and production shows Inbox not updating for some users (e.g. wrong filter or missing notify).
- **This fails when** docs still say “conversations in realtime” and a future dev re-adds the stream.
- **This fails when** _convoSub type is not changed and the handler still expects List<Map>, causing runtime/parse errors.

---

## G) Plan Fixes (Concrete Additions / Expansions)

| Goal | Why | How | Output artifact | Stop condition |
|------|-----|-----|------------------|-----------------|
| **Explicit merge algorithm** | Avoid wrong implementation (mutable update). | Document: for each Message, find Conversation by id; if found, build new Conversation with same fields except lastMessage, lastMessageTime, lastMessageSenderId from Message; replace in list; sort by lastMessageTime desc; if not found, add to “new convo” handling. | Plan step + optional merge helper in ViewModel or private method | Code passes review; no in-place mutation of Conversation |
| **Single-conversation fetch** | Avoid full fetchConversations on every new chat. | Add ChatRepository.getConversationById(conversationId) (or getConversation with relations); MessageService implements via select one + same join as getUserConversations. ViewModel calls when message.conversationId !in list. | Repository + service method; ViewModel call in handler | New conversation appears in list after one fetch |
| **Guard against double fetch** | Prevent duplicate getConversationById for same new conversation. | In ViewModel, maintain Set<String> _fetchingConversationIds or single _pendingNewConversationId; before fetch check; after fetch remove and add to list. | ViewModel state + guard in handler | At most one fetch per new conversation_id |
| **Subscription type and name** | Avoid type mismatch and leftover Map logic. | Replace _convoSub with _inboxMsgSub type StreamSubscription<List<Message>>?; handler receives List<Message>; remove Conversation.fromJson from stream handler. | chat_view_model.dart | Compiles; no Map parsing in inbox handler |
| **Phase 1 gate: publication check** | Block if DB contradicts plan. | Before Phase 2: run publication query; write result to execution log or plan follow-up; if conversations in result, mark “BLOCKED” and add removal step or separate plan. | Execution log / PLAN follow-up note | Gate pass/fail recorded; no Phase 2 if blocked |
| **Written manual E2E script** | Repeatable verification. | Create .TODO/.../18_realtime-subscription-topology/MANUAL_E2E_INBOX_REALTIME.md (or under plan folder) with steps: login A, login B, B sends to A, A on Inbox, expect update without refresh; add “Verify logs: no SELECT conversations IN”. | Markdown script | QA can run script; release gate requires it run |
| **Loading/error for Inbox** | Avoid spinner storm or silent failure. | Ensure fetchConversations on initial load; when getConversationById fails, log and optionally show error state or leave list unchanged; no full refetch loop. | ViewModel + optional error state | Initial load and error path defined |

---

## H) Corrected Plan (Execution-Ready, Gate-Based)

### Phase 0: Preconditions & Decisions

- **Goal:** Lock scope and resolve blocking decisions.
- **Why:** Prevents rework from wrong “new conversation” path or wrong publication assumption.
- **How:** Confirm “new conversation” = getConversationById (add method); confirm publication check is blocking (conversations must not be in result).
- **Result:** Decisions documented; plan unblocked.

**Steps:**

1. (@Architect) Decide and document: new conversation hydration = getConversationById (single fetch). Reject full fetchConversations on every new message for new convo.
2. (@Supabase_Ops) Confirm: when publication query returns conversations, plan is blocked until removal is planned.
3. (@Sentinel) Acceptance criteria locked: Inbox updates without full refetch; no N+1; publication without conversations; docs updated; written E2E script run.

**GATE CHECK:** Decisions recorded; Phase 1 can start.

---

### Phase 1: Data/Contracts & Live DB

- **Goal:** Confirm contracts and live DB state; no schema change.
- **Why:** Prevents building on wrong publication or wrong merge contract.
- **How:** Run publication query; document Message fields for merge; document merge algorithm (new Conversation instance).
- **Result:** Publication result recorded; merge contract explicit.

**Steps:**

1. (@Supabase_Ops) Run `SELECT * FROM pg_publication_tables WHERE pubname = 'supabase_realtime';` (MCP execute_sql). Record result (table names). If `conversations` in result → STOP; document BLOCKED; plan removal of conversations from publication or separate change; do not proceed to Phase 2.
2. (@APIContract) Contract: subscribeToInboxMessages(userId) returns Stream<List<Message>>. Message must have conversationId, content, created_at, sender_id, receiver_id. ViewModel merge uses these to build/update Conversation display (new instance, no mutation).
3. (@Architect) Document merge algorithm: for each Message in event, find Conversation by id; if found → new Conversation(..., lastMessage: message.content, lastMessageTime: message.createdAt, lastMessageSenderId: message.senderId); replace in list; if not found → queue for getConversationById (with guard). Sort list by lastMessageTime descending. notifyListeners once.

**GATE CHECK:** Publication does not include conversations; contract and merge algorithm written. If gate fails (conversations in publication), stop.

---

### Phase 2: Backend/API (Service + Repository)

- **Goal:** Implement subscribeToInboxMessages; remove conversations stream; add getConversationById; no REST inside stream.
- **Why:** Correct topology and remove N+1.
- **How:** MessageService: remove subscribeToConversations; add subscribeToInboxMessages(userId) with .stream(primaryKey: ['id']).eq('receiver_id', userId).order('created_at'), map to List<Message>, handleError + AppLogger.w. ChatRepository: remove subscribeToConversations; add subscribeToInboxMessages; add getConversationById(conversationId) delegating to service. MessageService: add getConversationById (one row + same relations as getUserConversations).
- **Result:** Service and repository expose new stream and single-conversation fetch; old stream removed.

**Steps:**

1. (@Architect) message_service.dart: Delete subscribeToConversations. Add subscribeToInboxMessages(String userId): from('messages').stream(primaryKey: ['id']).eq('receiver_id', userId).order('created_at'), .map(rows → List<Message>), no asyncMap, no select. handleError with AppLogger.w on error.
2. (@Architect) message_service.dart: Add getConversationById(String conversationId) returning Future<Conversation?> (or throw if not found). Use same select shape as getUserConversations for one row.
3. (@Architect) chat_repository.dart: Remove subscribeToConversations. Add subscribeToInboxMessages(userId). Add getConversationById(conversationId).
4. (@Observability) Add AppLogger.w in subscribeToInboxMessages handleError when error suggests timeout/protocol/connection.

**GATE CHECK:** No .from('conversations').stream; no asyncMap/select in subscribeToInboxMessages; getConversationById exists and returns one Conversation.

---

### Phase 3: ViewModel (App Logic)

- **Goal:** Wire Inbox to message stream; merge into list; handle new conversation with single fetch and guard.
- **Why:** Single source of truth; no N+1; correct UX.
- **How:** Replace subscribeToUserConversations implementation: subscribe to subscribeToInboxMessages(user.id); on List<Message>, apply merge (new Conversation instances, replace, sort); for conversation_id not in list, call getConversationById with guard (Set of fetching ids or single pending); append, sort, notify. Cancel previous subscription on re-subscribe and in dispose.
- **Result:** Inbox updates from message stream; new conversations appear after one fetch; no double fetch.

**Steps:**

1. (@Architect) chat_view_model.dart: Change subscription type to StreamSubscription<List<Message>>? _inboxMsgSub. In subscribeToUserConversations cancel _inboxMsgSub; set _inboxMsgSub = _repo.subscribeToInboxMessages(user.id).listen(...).
2. (@Architect) Handler: for each message, find conversation by message.conversationId in conversations. If found: build new Conversation with updated lastMessage, lastMessageTime, lastMessageSenderId; replace in list. If not found and conversationId not in _fetchingConversationIds: add to _fetchingConversationIds; call _repo.getConversationById(message.conversationId); on result append to conversations, remove id from _fetchingConversationIds, sort, _notify(). On error remove id from _fetchingConversationIds, log.
3. (@Architect) After processing all messages: sort conversations by lastMessageTime desc; _notify(). Ensure _mounted check before _notify.
4. (@Architect) dispose: _inboxMsgSub?.cancel(); _inboxMsgSub = null. UnsubscribeFromUserConversations cancels _inboxMsgSub.

**GATE CHECK:** No Conversation.fromJson from stream; merge uses new Conversation; at most one getConversationById per new conversation_id; dispose cancels.

---

### Phase 4: UI (Wiring + States)

- **Goal:** Inbox screen works with new stream; loading/empty/error preserved.
- **Why:** Stable UX.
- **How:** MessagesScreen still calls subscribeToUserConversations(); initial load still fetchConversations. Ensure empty and error states still work when stream has no events or fetch fails.
- **Result:** No regression; Inbox updates in realtime.

**Steps:**

1. (@Pixel) MessagesScreen: no change to call site. Confirm initial load (fetchConversations) and loading state unchanged. Confirm empty state when conversations.isEmpty and not loading.
2. (@Pixel) If getConversationById fails, ViewModel does not clear list; optional: set error message for Inbox or log only. No spinner storm.

**GATE CHECK:** Inbox shows list; new message updates list without full reload; no duplicate spinners.

---

### Phase 5: QA + Security + Release

- **Goal:** Verify behavior, security, and release readiness.
- **Why:** No false ship.
- **How:** Written E2E script; run script; check logs for no N+1; RLS check; doc review.
- **Result:** All gates pass; release allowed.

**Steps:**

1. (@Sentinel) Write manual E2E script: steps (login A, B, B sends to A, A on Inbox), expected (conversation moves to top, preview updates, no full refresh). Add: “Check AppLogger/logs: no SELECT ... conversations ... IN”. Save under .TODO/.../18.../ or plan folder.
2. (@Sentinel) Run publication query again; confirm conversations not in result.
3. (@Sentinel) Run manual E2E; confirm Inbox updates; confirm no N+1 in logs (or pg_stat_statements).
4. (@Sentinel) RLS: confirm messages_select applies; no test change required if existing coverage; else add note for future RLS test.
5. (@Sentinel) Regression: Chat screen message stream and notification stream still work (smoke).

**GATE CHECK:** E2E script exists and was run; no N+1 observed; publication correct; regression passed.

---

### Phase 6: Documentation Sync

- **Goal:** Docs match code and DB.
- **Why:** Prevent re-adding conversations stream and wrong mental model.
- **How:** Update diagram 18, SUPABASE_SETUP, Chat Feature, DEVELOPER_GUIDE/STRUCTURE as needed; optional Sline_Log.
- **Result:** Diagram and docs state: Inbox from messages (receiver_id); conversations NOT in publication.

**Steps:**

1. (@DocsKeeper) 18_realtime-subscription-topology.md: Remove “conversations in publication”; diagram Inbox from messages stream receiver_id=eq.{auth.uid}; Evidence table fixed; status/verification updated.
2. (@DocsKeeper) SUPABASE_SETUP.md Realtime: only messages and notifications in publication; do NOT add conversations; align snippet with Phase 1 result.
3. (@DocsKeeper) Chat Feature.md: Inbox realtime = subscribeToInboxMessages(userId); merge in ChatViewModel; no conversations stream.
4. (@DocsKeeper) DEVELOPER_GUIDE.md / STRUCTURE.md: minimal reference to topology; point to diagram and Chat Feature.
5. (@DocsKeeper) Optional: Sline_Log.md entry for realtime topology fix.

**GATE CHECK:** No doc claims “conversations in realtime”; diagram shows messages-driven Inbox.

---

## I) Change Report (Diff-Style)

### 1) Original issues summary

- Merge logic said “update” but Conversation is immutable (would break implementation).
- “Fetch that conversation” was vague; no getConversationById; risk of full fetchConversations on every new chat.
- No blocking gate if live DB has conversations in publication.
- No written E2E script; verification underspecified.
- Subscription type and handler (List<Message> vs List<Map>) not explicitly aligned; risk of leftover Map parsing.
- No guard against double fetch for same new conversation_id.
- Phase order and gate checks not strict (data/contracts before backend, backend before UI, QA before release).

### 2) Added steps

- Phase 0: Explicit decisions (new convo = getConversationById; publication check blocks).
- Phase 1: Publication query as gate; contract and merge algorithm in writing.
- Phase 2: getConversationById in service + repository; AppLogger.w in stream error.
- Phase 3: _inboxMsgSub type; merge with new Conversation instances; _fetchingConversationIds (or equivalent) guard; cancel in dispose.
- Phase 5: Written manual E2E script artifact; run script; log check for N+1.
- Gate checks at end of each phase with explicit pass/fail and block condition.

### 3) Removed steps

- None; steps were refined and reordered, not dropped.

### 4) Reordered steps

- “Live Supabase confirmation” moved into Phase 1 as gate (must pass before Phase 2).
- Contract and merge algorithm moved to Phase 1 (before any code).
- Observability (AppLogger.w) kept in Phase 2 with stream implementation.
- QA (E2E script + run) moved into Phase 5 with explicit artifact and run requirement.
- Docs phase after QA so docs reflect final behavior.

### 5) Expanded steps

- Merge: from “update last_message_*” to “build new Conversation(..., lastMessage, lastMessageTime, lastMessageSenderId); replace in list”.
- New conversation: from “fetchConversations or fetch that conversation” to “getConversationById with guard; append; sort”.
- Subscription: from “keep _convoSub type” to “StreamSubscription<List<Message>>? _inboxMsgSub; cancel previous; no Map parsing”.
- Phase 1: from “record result” to “if conversations in result → STOP and document BLOCKED”.
- QA: from “Manual E2E” to “Write E2E script; run it; check logs for no N+1”.

### 6) Why (short)

- Immutable model and single-fetch + guard prevent wrong code and duplicate requests.
- Publication gate prevents building on wrong DB state.
- Written E2E and log check make verification repeatable and N+1 detectable.
- Gate-based order (data → backend → UI → QA → docs) avoids rework and ensures release readiness.

### 7) Residual risks

- No automated integration test for Inbox realtime; still depends on manual run of script.
- If getConversationById fails (e.g. RLS or network), new conversation may not appear until next full fetch or refresh; error handling is “log and optionally show”; could be improved later.
- Role switch / teardown: plan relies on existing coordinator; if more entry points call subscribeToUserConversations without cancel, duplicate listeners remain a possibility; code review and dispose discipline are the mitigation.

---

## References (Unchanged)

- `.TODO/improvement_the_system/ImplementReady/18_realtime-subscription-topology/` (all referenced docs)
- `Sline_everything/DEVELOPER_GUIDE.md`, `SUPABASE_SETUP.md`, `MVP_ROADMAP.md`, `STRUCTURE.md`, `AppDigram/All_Diagrams/18_realtime-subscription-topology.md`, `DEVELOPER_GUIDE/Chat Feature.md`
- `lib/features/chat/services/message_service.dart`, `lib/features/chat/data/chat_repository.dart`, `lib/features/chat/viewmodels/chat_view_model.dart`, `lib/features/chat/view/messages_screen.dart`, `lib/features/chat/models/conversation_model.dart`, `lib/features/chat/models/message_model.dart`

---

## Mandatory Critique Checklist (Summary)

| Check | Result | Note |
|-------|--------|------|
| 3.1 Scope & requirements | Goal measurable; non-goals stated; edge (new convo, rapid messages) addressed in plan fixes | |
| 3.2 Dependencies & ordering | Fixed: Phase 1 (data/contracts) before Phase 2 (backend); Phase 5 (QA) before Phase 6 (docs) | |
| 3.3 Data model & contracts | Fixed: merge contract and Message fields explicit; Conversation immutable | |
| 3.4 Security | Pass: RLS unchanged; no new bypass | |
| 3.5 Performance | Fixed: no asyncMap/select in stream; guard against double fetch | |
| 3.6 Error handling & observability | Fixed: AppLogger.w on stream error; getConversationById error path (log/optional state) | |
| 3.7 UX & state | Fixed: loading/empty preserved; guard prevents spinner storm for new convo | |
| 3.8 Testing & QA | Fixed: written E2E script; run before release gate; N+1 check in logs | |
| 3.9 Release & migration | Rollback and emergency disable documented; no DB migration | |
| 3.10 Developer workflow | Doc update in Phase 6; single PR assumed; review checklist = gate checks | |
