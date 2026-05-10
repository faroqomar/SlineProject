# Docs Report — Chat Realtime Sync (08_chat-realtime-sync)

**Feature:** 08_chat-realtime-sync (Chat Realtime Sync)  
**Plan:** `.TODO/PLAN_ChatRealtimeSync_2026-03-07_PlanCritic.md`  
**Execution:** `.TODO/EXECUTION_LOG_ChatRealtimeSync_2026-03-07.md`  
**Date:** 2026-03-08  
**Author:** DocsKeeper (Orchestrator pipeline)

---

## 1. Scope and Evidence (Files Scanned)

### 1.1 Sline_everything (Chat-related)

| File | Purpose |
|------|--------|
| `Sline_everything/DEVELOPER_GUIDE/Chat Feature.md` | Chat feature reference (presence, receipts, realtime, file inventory) |
| `Sline_everything/SUPABASE_SETUP.md` | Schema, RLS, triggers, realtime, app_config |
| `Sline_everything/STRUCTURE.md` | File tree; chat feature and recent updates |
| `Sline_everything/MVP_ROADMAP.md` | Feature status (Realtime chat row) |
| `Sline_everything/Sline_Log.md` | Version timeline and release entries |
| `Sline_everything/DEVELOPER_GUIDE.md` | System map; links to Chat Feature |
| `Sline_everything/AppDigram/All_Diagrams/08_chat-realtime-sync.md` | Sequence diagram (presence + messages) |
| `Sline_everything/AppDigram/All_Diagrams/18_realtime-subscription-topology.md` | Inbox/conversation list realtime topology |

### 1.2 .TODO (Plans, execution, contract, RLS)

| File | Purpose |
|------|--------|
| `.TODO/PLAN_ChatRealtimeSync_2026-03-07_PlanCritic.md` | Audited plan (phases 0–5, gates, decisions) |
| `.TODO/EXECUTION_LOG_ChatRealtimeSync_2026-03-07.md` | Phase 0–3 done; Phase 4–5 pointers |
| `.TODO/08_chat_realtime_contract.md` | DB ↔ Flutter contract (messages, conversation_presence, RPCs) |
| `.TODO/08_chat_acceptance.md` | Acceptance and non-regression criteria |
| `.TODO/08_RLS_verification_chat.md` | RLS verification procedure (Checks 1–4) |
| `.TODO/RLS_Matrix_Chat_2026-03-07.md` | RLS matrix (messages + conversation_presence policies) |
| `.TODO/08_live_db_state_20260307.md` | Live DB state snapshot and migration strategy |

### 1.3 Migrations (verified present)

| Migration | Purpose |
|-----------|--------|
| `supabase/migrations/20260307219900_chat_presence_and_rls_full.sql` | conversation_presence table (IF NOT EXISTS), RLS, realtime ADD TABLE, app_config `chat_presence_receipts_enabled` |
| `supabase/migrations/20260307220000_chat_realtime_presence_publication.sql` | ADD TABLE conversation_presence to supabase_realtime |
| `supabase/migrations/20260307220100_chat_presence_receipts_flag.sql` | app_config insert for `chat_presence_receipts_enabled` (ON CONFLICT DO NOTHING) |

---

## 2. Documentation Delta (Updated vs Still Required)

### 2.1 Already updated (aligned with feature)

- **Chat Feature.md**
  - §2.6 `conversation_presence`: columns, RLS summary, realtime, feature flag.
  - §2.7 Receipt lifecycle: `delivered_at`/`seen_at`, RPCs, UI ticks, merge strategy.
  - §2.8 Realtime: active chat (subscribeToMessages, subscribeToPresence), Inbox (subscribeToInboxMessages), reference to diagram 18.
  - File inventory includes `chat_realtime_merger.dart`; no separate line for `chat_realtime_merger_test.dart` (test lives under `test/`).
- **SUPABASE_SETUP.md**
  - Table list (§1): `conversation_presence` present.
  - §5.7 `conversation_presence`: table description and columns.
  - §7.12 `conversation_presence` policies: `presence_select_participant`, `presence_upsert_self`, `presence_update_self`.
  - Messages RLS (§7): `messages_update_by_receiver` documented (receiver_id = uid for seen_at).
  - ERD (§1): `conversation_presence (conversation_id, user_id)` under conversations.
- **Sline_Log.md**
  - Realtime topology entry (Diagram 18) mentions “conversation_presence for typing” and Chat Feature §2.6.

### 2.2 Still needs updating (prioritized)

| # | Doc | What’s missing or wrong |
|---|-----|-------------------------|
| 1 | **SUPABASE_SETUP.md** §12 Realtime | Publication list says only `messages` and `notifications`. **conversation_presence** was added to `supabase_realtime` by migrations 20260307219900 / 20260307220000. Doc must list all three tables and state that `conversations` must NOT be added (per 20260307230000). |
| 2 | **SUPABASE_SETUP.md** §5.8 app_config | Only `enable_direct_conversation_rpc` is listed. **chat_presence_receipts_enabled** is added by 20260307219900 and 20260307220100; must be documented (purpose: enable/disable typing indicator and receipt ticks; values `'true'`/`'false'`). |
| 3 | **SUPABASE_SETUP.md** §5.7 conversation_presence + §8 triggers | Note claims “Presence records are automatically expired after 15 seconds by `expire_typing_presence` trigger.” Trigger is **not** in any migration; plan/execution use **client-only 15s TTL**. Table §8 lists `trg_expire_presence` / `expire_typing_presence()` — **trigger does not exist** in repo migrations. Either remove trigger mention and note “client-side 15s TTL only” or add a follow-up migration and then align doc. |
| 4 | **Sline_Log.md** | No dedicated **version entry** for “Chat Realtime Sync (08)” with: plan path (PlanCritic), execution log path, contract, RLS matrix, verification doc, migration names, and Phase 5 “docs to update” pointer. |
| 5 | **MVP_ROADMAP.md** | No explicit row for “Chat Realtime Sync” or “08_chat-realtime-sync”. “Realtime chat” is ✅ but does not mention presence, receipts, feature flag, or merger. Add/update a row for 08 with status and short blurb (e.g. presence, receipts, `chat_presence_receipts_enabled`, ChatRealtimeMerger). |
| 6 | **STRUCTURE.md** | “Recent Structure-Sensitive Updates” could add one line for Chat Realtime Sync: e.g. presence/receipts, `chat_realtime_merger_test.dart`, feature flag, 15s TTL (optional). |

---

## 3. Reference Integrity (Broken refs, outdated statements, paths)

### 3.1 Broken or incorrect references

| Location | Issue | Evidence |
|----------|--------|----------|
| **SUPABASE_SETUP.md** §5.7 Note | States presence is expired by `expire_typing_presence` trigger. | No migration in `supabase/migrations` defines this trigger; plan/execution use client-only 15s TTL. |
| **SUPABASE_SETUP.md** §8 (Triggers) | Lists `trg_expire_presence` / `expire_typing_presence()`. | `grep` in `supabase/migrations` for `expire_typing` / `trg_expire_presence`: 0 results. |
| **SUPABASE_SETUP.md** §12 Realtime | “Only `messages` and `notifications` are in the realtime publication.” | Migrations add **conversation_presence** to `supabase_realtime`; statement is outdated. |
| **08_chat_realtime_contract.md** §2 conversation_presence | `user_id` described as “FK auth.users (PK part)”. | Migration 20260307219900 and live DB state: `user_id uuid NOT NULL REFERENCES public.profiles(id)`. Contract should say FK to **profiles(id)** for consistency. |

### 3.2 Paths and names verified (exist and match)

| Reference | Status |
|-----------|--------|
| `lib/features/chat/data/chat_repository.dart` | Exists |
| `lib/features/chat/services/message_service.dart` | Exists |
| `lib/features/chat/services/chat_realtime_merger.dart` | Exists |
| `lib/features/chat/viewmodels/chat_view_model.dart` | Exists |
| `lib/features/chat/models/conversation_model.dart` | Exists |
| `lib/features/chat/models/message_model.dart` | Exists |
| `lib/features/chat/view/chat_screen.dart` | Exists |
| `lib/features/chat/view/widgets/conversation_list_tile.dart` | Exists |
| `test/features/chat/services/chat_realtime_merger_test.dart` | Exists (execution log) |
| `Sline_everything/AppDigram/All_Diagrams/18_realtime-subscription-topology.md` | Exists |
| `Sline_everything/AppDigram/All_Diagrams/08_chat-realtime-sync.md` | Exists |
| Migration `20260307219900_chat_presence_and_rls_full.sql` | Exists |
| Migration `20260307220000_chat_realtime_presence_publication.sql` | Exists |
| Migration `20260307220100_chat_presence_receipts_flag.sql` | Exists |
| Migration `20260307230000_realtime_topology_no_conversations.sql` | Referenced in SUPABASE_SETUP; exists in repo |
| RLS policy names: `presence_select_participant`, `presence_upsert_self`, `presence_update_self` | Match migration and RLS_Matrix_Chat |
| RLS policy: `messages_update_by_receiver` | Documented in SUPABASE_SETUP and RLS matrix |

### 3.3 Outdated or ambiguous statements

- **Diagram 08** (`08_chat-realtime-sync.md`): `last_verified: "2026-03-05"`; implementation completed 2026-03-07. Optional: set to 2026-03-07 and add feature flag / 15s TTL in description if desired.
- **Chat Feature.md** §7 “Realtime”: “Subscribe to `messages` and `conversations` streams” — implementation uses **messages** and **conversation_presence** for active chat; **conversations** is intentionally not in realtime (see diagram 18). Wording could be tightened to “messages and conversation_presence” for active chat and “messages (receiver_id)” for Inbox.

---

## 4. Summary

### 4.1 Broken references (to fix in docs)

1. **SUPABASE_SETUP.md**: Remove or correct `expire_typing_presence` trigger (§5.7 note and §8 trigger list); document client-only 15s TTL.
2. **SUPABASE_SETUP.md**: Realtime §12 — add `conversation_presence` to publication list; keep “do not add conversations”.
3. **08_chat_realtime_contract.md**: Fix `user_id` FK to **profiles(id)** (or note “profiles.id in migration; auth.users in contract” if intentional).

### 4.2 Required doc updates (prioritized)

1. **SUPABASE_SETUP.md**: Realtime publication (add conversation_presence); app_config (`chat_presence_receipts_enabled`); conversation_presence TTL and trigger (client-only 15s; remove non-existent trigger).
2. **Sline_Log.md**: Add version entry for Chat Realtime Sync with plan, execution log, contract, RLS matrix, verification doc, migrations.
3. **MVP_ROADMAP.md**: Add or update row for 08_chat-realtime-sync (presence, receipts, feature flag).
4. **08_chat_realtime_contract.md**: Correct user_id FK reference.
5. **STRUCTURE.md** (optional): One-line note in “Recent Structure-Sensitive Updates” for Chat Realtime Sync.
6. **Diagram 08** (optional): Refresh last_verified and mention feature flag / 15s TTL.

### 4.3 Evidence summary

- **Plans/execution:** PlanCritic plan and execution log read; Phase 0–3 done, Phase 4 (QA) and Phase 5 (docs) partially done.
- **Contracts/RLS:** Contract, acceptance, RLS matrix, RLS verification, and live DB state files present and consistent except contract user_id FK.
- **Migrations:** Three chat presence/realtime migrations present; no trigger for presence expiry in migrations.
- **Core docs:** Chat Feature.md is up to date for presence/receipts/realtime; SUPABASE_SETUP has gaps and one incorrect trigger reference; Sline_Log and MVP_ROADMAP lack a dedicated 08 entry.

---

**Report only.** No doc edits were performed in this step.
