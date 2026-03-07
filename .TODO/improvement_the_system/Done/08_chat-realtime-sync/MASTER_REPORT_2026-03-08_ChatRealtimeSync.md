# Master Report — Chat Realtime Sync (Orchestrator Pipeline)

**Date:** 2026-03-08  
**Scope:** Chat Realtime Sync (08_chat-realtime-sync)  
**Plan:** `.TODO/PLAN_ChatRealtimeSync_2026-03-07_PlanCritic.md`  
**Execution:** `.TODO/EXECUTION_LOG_ChatRealtimeSync_2026-03-07.md`  
**Pipeline:** Architect → Observability → SlineDocs → CodeGuard

---

## A) Executive Summary

| Item | Result |
|------|--------|
| **What was reviewed** | Full Chat Realtime Sync implementation: lib/features/chat/ (view, viewmodels, services, models, merger), tests, migrations (20260307219900, 20260307220000, 20260307220100), contract, RLS matrix, verification doc, and related Sline_everything docs. |
| **Overall risk level** | **LOW** — No BLOCKERs; MVVM and RLS aligned; optional refactors and doc/observability improvements only. |
| **Final decision** | **Ready** — CodeGuard APPROVED ✅. Pipeline not blocked. |

---

## B) Consolidated Findings (Deduplicated)

Grouped by category; each with Severity, Owner agent, Path/object, and Fix recommendation.

### Security

| # | Severity | Owner | Path / object | Fix |
|---|----------|--------|----------------|------|
| 1 | LOW | Observability | `lib/features/chat/models/conversation_model.dart` (lines 94, 113) | Remove or redact PII in debug logs: `rawLastMessage` (may contain message content), `other_user_name` / `other_user_avatar`. Use “other_user present” or hash; never log message body. |

- RLS and contract are aligned; no RLS BLOCKER. Manual RLS verification (Check 1–4 in `.TODO/08_RLS_verification_chat.md`) required before release.

### Data Integrity

| # | Severity | Owner | Path / object | Fix |
|---|----------|--------|----------------|------|
| 1 | LOW | Architect | `lib/features/chat/viewmodels/chat_view_model.dart` — `subscribeToActiveConversation()` | Optional: at start of subscribe, clear or reset `_lastMessages` when `cid != activeConversation?.id` so a future entry point (e.g. deep link) cannot mix two conversations. Low priority while only entry is _openChat. |

- Merger accumulation and stream error handling are correct; no duplicate messages on reconnect when used as today.

### Architecture / MVVM

| # | Severity | Owner | Path / object | Fix |
|---|----------|--------|----------------|------|
| 1 | — | — | All chat view code | No finding. MVVM boundary PASS: no Supabase in view; View → ViewModel → Repository → Service. |
| 2 | LOW | Architect | Migration ordering | Document that 20260307219900 is the single source for presence table + publication + app_config; 20260307220000 and 20260307220100 are redundant/legacy for clarity. |

### Performance

| # | Severity | Owner | Path / object | Fix |
|---|----------|--------|----------------|------|
| 1 | MED | CodeGuard / Architect | `chat_view_model.dart` — `refreshOfferStatusesForCurrentMessages()` | Called on every message stream emission. Debounce (e.g. 500 ms) or run only when merged list contains offer messages and has changed. |
| 2 | LOW | CodeGuard / Architect | `chat_view_model.dart` — `markReceiptsForActive()` | Called on every emission (and twice on subscribe). Consider: mark delivered/seen once on open and when new messages from other party arrive. |

### Observability

| # | Severity | Owner | Path / object | Fix |
|---|----------|--------|----------------|------|
| 1 | MED | Observability | Chat feature logs | Adopt stable event taxonomy (e.g. `chat_presence_upsert`, `chat_mark_delivered`, `chat_messages_subscription_error`); add `event_name` and `conversation_id` (and `feature: chat`) where missing. |
| 2 | MED | Observability | `chat_view_model.dart` — “Error marking receipts” | Add `conversation_id` and `operation` (delivered|seen) to receipt failure log for traceability. |
| 3 | HIGH (PII) | Observability | `conversation_model.dart` | Remove or redact logs that expose `rawLastMessage` (content) and `other_user_name` / `other_user_avatar`. |
| 4 | LOW | Observability | Chat logs | Use consistent tags (e.g. `Chat`, `ChatVM`) for all chat-related logs; optional `correlation_id` in a later pass. |

### Docs / Reference Integrity

| # | Severity | Owner | Path / object | Fix |
|---|----------|--------|----------------|------|
| 1 | HIGH | SlineDocs | `Sline_everything/SUPABASE_SETUP.md` §5.7, §8 | Remove or correct reference to `expire_typing_presence` trigger and `trg_expire_presence` — **trigger does not exist** in migrations; document **client-only 15s TTL**. |
| 2 | MED | SlineDocs | `Sline_everything/SUPABASE_SETUP.md` §12 Realtime | Add **conversation_presence** to publication list (with messages, notifications); state that conversations must NOT be added. |
| 3 | MED | SlineDocs | `Sline_everything/SUPABASE_SETUP.md` §5.8 app_config | Document **chat_presence_receipts_enabled** (purpose: typing + receipt ticks; values `'true'`/`'false'`). |
| 4 | MED | SlineDocs | `.TODO/08_chat_realtime_contract.md` | Fix `user_id` FK: state **profiles(id)** (migration and live DB use profiles, not auth.users). |
| 5 | LOW | SlineDocs | `Sline_everything/Sline_Log.md` | Add version entry for Chat Realtime Sync: plan, execution log, contract, RLS matrix, verification doc, migration names. |
| 6 | LOW | SlineDocs | `Sline_everything/MVP_ROADMAP.md` | Add/update row for 08_chat-realtime-sync (presence, receipts, feature flag, ChatRealtimeMerger). |
| 7 | LOW | SlineDocs | `Sline_everything/STRUCTURE.md` | Optional: one line in “Recent Structure-Sensitive Updates” for Chat Realtime Sync. |

### Migration / Backend

| # | Severity | Owner | Path / object | Fix |
|---|----------|--------|----------------|------|
| 1 | MED | CodeGuard / Supabase_Ops | `supabase/migrations/20260307220000_chat_realtime_presence_publication.sql` | Not idempotent: ADD TABLE without IF NOT EXISTS. Migration 20260307219900 already adds conversation_presence to publication. Make 20260307220000 idempotent (same DO $$ IF NOT EXISTS pattern) or deprecate in favor of 19900-only path. |

---

## C) Fix Plan (Ordered, Step-by-Step)

| Step | Owner | Action | Verification |
|------|--------|--------|----------------|
| 1 | @SlineDocs | Update SUPABASE_SETUP: remove expire_typing_presence trigger refs; document client-only 15s TTL; add conversation_presence to §12; add app_config §5.8 chat_presence_receipts_enabled. | Grep confirms no “expire_typing_presence” in SUPABASE_SETUP; §12 lists messages, notifications, conversation_presence. |
| 2 | @SlineDocs | Fix 08_chat_realtime_contract.md: user_id FK to profiles(id). | Contract text matches migration. |
| 3 | @Observability | Remove/redact PII in conversation_model.dart (rawLastMessage, other_user name/avatar). Add conversation_id + operation to “Error marking receipts” in chat_view_model. | No message content or identifiable name/avatar in logs; receipt failure log has conversation_id and operation. |
| 4 | @Supabase_Ops or @DataMigration | Make migration 20260307220000 idempotent (IF NOT EXISTS for ADD TABLE conversation_presence) OR document that 19900 is canonical and 20000 is legacy. | New deploy runs migrations without “already in publication” error. |
| 5 | @Architect | (Optional) Debounce refreshOfferStatusesForCurrentMessages; optionally reduce markReceiptsForActive frequency. | No behavioral regression; same tests pass. |
| 6 | @SlineDocs | Sline_Log version entry for Chat Realtime Sync; MVP_ROADMAP row for 08; optional STRUCTURE note. | Refs to plan, execution, contract, migrations are traceable. |
| 7 | @CodeGuard | Re-run review after Steps 1–4 (or 1–6) if desired. | No new BLOCKERs. |

---

## D) Regression Checklist

- **Critical flows:** (1) Open chat → messages load and merge; (2) Receive new message via realtime → list updates, no duplicates; (3) Typing indicator shows/hides within 15s; (4) Mark delivered/seen → ticks update when flag on; (5) Feature flag false → no typing, single tick only; (6) Stream error → last list restored, no crash.
- **How to test quickly:** `flutter analyze lib/features/chat/`; `flutter test test/features/chat/services/chat_realtime_merger_test.dart`; manual: open two clients, type, wait 15s, check ticks and presence; run RLS checks 1–4 from `.TODO/08_RLS_verification_chat.md`.

---

## E) Rollback Notes

| Area | Rollback |
|------|----------|
| **Feature** | Set `app_config.chat_presence_receipts_enabled` to `'false'` to disable typing and receipt ticks without code deploy. |
| **Realtime** | Removing conversation_presence from supabase_realtime stops presence events; messages stream unchanged. |
| **Migrations** | No rollback migration run; schema is additive. If needed, document manual steps (e.g. DROP POLICY, remove from publication) in a separate rollback runbook. |
| **Code** | Revert chat viewmodel/service/repository and merger changes; keep migrations if DB is already updated (idempotent). |

---

## F) Next Actions

1. **Before release:** Run RLS verification (Check 1–4 in `.TODO/08_RLS_verification_chat.md`) and record outcome.
2. **Docs:** Execute Fix Plan Steps 1, 2, 6 (SlineDocs) so SUPABASE_SETUP and contract are accurate and Chat Realtime Sync is traceable in Sline_Log/MVP_ROADMAP.
3. **Observability:** Execute Step 3 (PII redaction + receipt failure context); optionally adopt event taxonomy (Step 3 and Observability report §4).
4. **Migration:** Execute Step 4 (20260307220000 idempotent or deprecated) to avoid deploy risk.
5. **Performance (optional):** Step 5 — debounce offer refresh and tune receipt calls when convenient.
6. **CodeGuard:** Optionally re-run after doc and migration fixes (Step 7).

---

**Pipeline status:** Complete. No BLOCKER; final decision **Ready**.
