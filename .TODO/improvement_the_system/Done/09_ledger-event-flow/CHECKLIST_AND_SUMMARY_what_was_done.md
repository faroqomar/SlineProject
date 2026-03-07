# Ledger Event Flow — What Was Done & How to Check

**Scope:** 09_ledger-event-flow (plan, execution, orchestrator review, report fixes)  
**Date:** 2026-03-07

---

## Quick summary

| What | Why |
|------|-----|
| **Added** a small forensics helper and wired it into the ledger service | So every ledger call sends `session_id` + `request_id` in `p_meta` and logs, for audit and support (single source of truth). |
| **Added** `request_id` in log lines (start / success / error) | So you can match a log line to the DB journal entry when debugging or handling disputes. |
| **Added** Sline_Log and MVP_ROADMAP entries | So the change is documented and visible in project docs. |
| **Modified** only the wallet ledger path (no UI, no new screens) | All behavior is in the app layer that talks to the ledger RPC; no schema or RLS changes. |

---

## What was ADDED

- **`lib/core/utils/ledger_forensics.dart`**  
  - New file.  
  - Class `LedgerForensics` with `build(sessionId:, includeRequestId:)` that returns a map `{ session_id?, request_id? }`.  
  - **Why:** Single place that builds forensics for all ledger calls; contract says `p_meta` must include at least `session_id`, and we added optional `request_id` for correlation.

- **Sline_Log.md**  
  - New entry at the top: “Ledger Event Flow — Forensics, Contract, Tests, Runbook (2026-03-07)”.  
  - **Why:** Document the feature and point to plan, contract, runbook, and master report.

- **MVP_ROADMAP.md**  
  - Updated the “Wallet and ledger views” row to mention ledger event flow (forensics, contract, tests, runbook) and link to the 09 folder and contract.  
  - **Why:** Keep roadmap in sync with what’s implemented.

- **Master report (MASTER_REPORT_2026-03-07_LedgerEventFlow.md)**  
  - New “Fixes applied” section; regression checklist checkboxes and next actions updated.  
  - **Why:** Record what was fixed after the orchestrator review and what’s verified.

---

## What was MODIFIED

- **`lib/features/wallet/services/ledger_service.dart`**  
  - **Import:** `ledger_forensics.dart`.  
  - **Constructor:** Optional second parameter `LedgerForensics?` (defaults to `LedgerForensics()` so existing call sites stay valid).  
  - **`_mergeForensics(meta)`:** Uses `_forensics.build(sessionId: auth.currentUser?.id, includeRequestId: true)`, then merges that map into `meta` (caller keys win; we only fill missing `session_id` / `request_id`). So `p_meta` now always has `request_id` and `session_id` when the user is logged in.  
  - **Logging:** Every log line in `submitPaymentEvent` (start, success, RPC error, PostgrestException, catch-all) appends ` request_id:$requestId` when present.  
  - **Why:** Implement the contract (forensics in `p_meta`) and add correlation id in logs without changing RPC or DB.

- **`Sline_everything/Sline_Log.md`**  
  - One new section (see “What was ADDED” above).

- **`Sline_everything/MVP_ROADMAP.md`**  
  - One row text change (see “What was ADDED” above).

- **`.TODO/MASTER_REPORT_2026-03-07_LedgerEventFlow.md`**  
  - “Fixes applied” + checklist + next actions (see “What was ADDED” above).

---

## What was REMOVED

- **Nothing.** No code or docs were removed; only additions and the modifications above.

---

## Checklist — How to verify in the app/codebase

Use this to confirm behavior and that nothing else was changed.

### Code

- [ ] **New util**  
  - Open `lib/core/utils/ledger_forensics.dart`.  
  - Confirm: class `LedgerForensics`, method `build(sessionId:, includeRequestId:)` returning a map with optional `session_id` and `request_id`.

- [ ] **LedgerService uses forensics**  
  - Open `lib/features/wallet/services/ledger_service.dart`.  
  - Confirm: import `ledger_forensics.dart`; constructor has optional `LedgerForensics?`; `_mergeForensics` uses `_forensics.build(...)` and merges into `meta`; no direct assignment of `session_id` only (old logic replaced by the util).

- [ ] **Logs include request_id**  
  - In `ledger_service.dart`, search for `request_id`.  
  - Confirm: the same `requestId` variable is used in the “Submitting Ledger Event”, “Ledger event succeeded”, “Ledger RPC returned ok: false”, “Ledger RPC Failed”, and “Unexpected Ledger Error” log lines (each appends ` request_id:$requestId` when non-null).

- [ ] **No other app code changed**  
  - No new or modified UI screens.  
  - No changes to booking, task, wallet, or direct-offer **screens**; only the **service** that calls the ledger RPC was modified (and the new core util).  
  - All existing `LedgerService(_client)` call sites still work (optional second parameter).

### Docs

- [ ] **Sline_Log**  
  - Open `Sline_everything/Sline_Log.md`.  
  - Confirm: first content section is “Ledger Event Flow — Forensics, Contract, Tests, Runbook (2026-03-07)” with refs to plan, contract, runbook, master report.

- [ ] **MVP_ROADMAP**  
  - Open `Sline_everything/MVP_ROADMAP.md`, find “Wallet and ledger views”.  
  - Confirm: row mentions ledger event flow, forensics, contract, tests, runbook, and 09 folder/contract link.

### Running checks

- [ ] **Analyzer**  
  - Run: `flutter analyze lib/features/wallet/ lib/core/utils/ledger_forensics.dart`  
  - Expect: no issues.

- [ ] **Tests**  
  - Run: `flutter test test/unit/wallet/ test/rls/ledger_rls_test.dart`  
  - Expect: all tests pass (e.g. 6).

### In the real app (when you have backend)

- [ ] **Ledger still works**  
  - Trigger a flow that calls the ledger (e.g. pay booking, approve delivery, tender pay).  
  - Expect: same success/error behavior as before; no new errors.

- [ ] **Forensics in DB (optional)**  
  - After a successful ledger event, in DB check `journal_entries.meta` for that journal entry.  
  - Expect: `session_id` and `request_id` present when the user was logged in.

- [ ] **Logs (optional)**  
  - Reproduce a ledger call and check app logs.  
  - Expect: “Submitting Ledger Event … request_id:…” and “Ledger event succeeded … request_id:…” (or the error line with `request_id`) so you can correlate with the DB.

---

## One-line recap

**Added** a forensics util and `request_id` in `p_meta` and logs; **modified** only `LedgerService` and the docs above; **removed** nothing — so ledger events are auditable and easier to trace without changing UI or DB.
