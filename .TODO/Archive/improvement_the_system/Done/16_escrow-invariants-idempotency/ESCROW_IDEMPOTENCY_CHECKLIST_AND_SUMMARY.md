# Escrow Idempotency — Checklist & Summary

**Plan:** Escrow Invariants & Idempotency (16_escrow-invariants-idempotency)  
**Date:** 2026-03-07

---

## What was done and why

**Problem:** Approving delivery used a server-generated idempotency key that included `now()`, so every retry got a different key. The “idempotency” never kicked in: a retry after a network drop could release escrow twice.

**Goal:** Make escrow release **truly idempotent**: same key on retry, so the DB rejects the second attempt and the user sees success without double-paying.

**What we did:**

1. **Backend (Supabase)**  
   - **Stable key:** Key is now `entity_id + status + payment_status` (no time). Same entity + state ⇒ same key ⇒ second call hits UNIQUE and returns “already done.”  
   - **FOR UPDATE:** We lock the booking row before generating the key and calling the ledger, so two concurrent approvals don’t race.  
   - **Index cleanup:** Removed the duplicate unique index on `journal_entries.idempotency_key` (one constraint is enough).

2. **App (Flutter)**  
   - **Logging:** Every approve-delivery step is logged (request, success, error) with tags so you can trace and debug.  
   - **Correlation ID:** Each approval gets a single id (`apv_<entityId>_<timestamp>`) from the ViewModel and passed to the service; both log it so one request can be followed across layers.  
   - **Double-tap guard:** The Approve button in the review-delivery modal is one-shot: first tap runs the action, further taps are ignored until the request finishes (on error we allow retry).

3. **Docs & runbook**  
   - Diagram 16 and SUPABASE_SETUP describe the new key and FOR UPDATE.  
   - DEVELOPER_GUIDE states that approve delivery is idempotent under retry.  
   - Sline_Log has an entry for this change.  
   - RUNBOOK explains how to run T1/T2/T4 (idempotency, concurrency, bypass) in SQL.

---

## Add / Remove / Modify (short)

| Area | Added | Removed | Modified |
|------|--------|---------|----------|
| **DB** | — | Duplicate index `idx_journal_entries_idempotency` | `rpc_approve_delivery`: booking branch now uses FOR UPDATE + stable key (no `now()`) |
| **Service** | Optional `correlationId` on `approveDelivery`; logs at request start and success with tag + correlationId | — | Comment that flow is idempotent; error log now has tag |
| **ViewModel** | Generation of `correlationId` and passing it to the service; log with correlationId | — | Added tag to existing error log |
| **Modal** | `_hasApproved` one-shot guard; AppLogger (tap, success, error, “already in progress”) | — | Approve handler: guard + logging + reset guard on error |
| **Docs** | CONTRACT (key formula), RUNBOOK (T1/T2/T4), execution log, Sline_Log entry, DEVELOPER_GUIDE bullet (idempotent approve) | — | Diagram 16 (FOR UPDATE + stable key), SUPABASE_SETUP §9.5 |
| **Repo** | Migration file `20260307000001_escrow_idempotency_stable_key.sql` | — | — |

**Nothing was removed from the app’s behavior:** same RPC, same params, same UI flow. Only backend logic (key + lock), logging, and one-shot button behavior were added or updated.

---

## Checklist — What to check in the actual app

Use this on a real device or simulator to confirm the implementation.

### Before you start

- [ ] App builds: `flutter run` (or your usual run command).
- [ ] You are logged in as a **client** who has a work item in **delivered** state with **payment held** (booking) or a delivered **task** (no payment).

---

### 1. Approve delivery (happy path)

- [ ] Open **Work** (or dashboard) and select a **delivered** work item (booking or task).
- [ ] Tap **Approve** (or “Review delivery” then “Approve”).
- [ ] Loading state appears (e.g. spinner on the button).
- [ ] Modal closes and the work item shows as **completed** (and for booking, balance updated if you have a wallet view).
- [ ] In logs (Xcode/Android Studio/terminal), you see lines with tags **WorkManagement**, **WorkItemDetails**, **ReviewDelivery** and a **correlationId** like `apv_<uuid>_<number>` on request and success.

---

### 2. Double-tap / “already in progress”

- [ ] Open another delivered work item (or the same if you can reset it).
- [ ] Tap **Approve** and **immediately tap again** one or more times.
- [ ] Only **one** request should run (one loading, one success); no duplicate RPCs.
- [ ] In logs, after the first tap you may see a **ReviewDelivery** “Approve already in progress or done” (debug) if the second tap is processed before the first finishes.

---

### 3. Retry after “failure” (idempotency)

- [ ] Use a **delivered + held** booking where you can trigger a “failed” response then retry (e.g. turn off network after first tap, then turn it back on and tap again; or use a test that mocks failure).
- [ ] First attempt may fail (e.g. network error); user sees error.
- [ ] Retry **Approve** (e.g. tap again or reopen modal and approve).
- [ ] Second attempt succeeds and the work is completed **once** (no double release).
- [ ] In DB (Supabase SQL or RUNBOOK T1): for that booking, `journal_entries` has **one** row with `event_type = 'release_with_fee'` (not two).

*If you can’t simulate network failure, running T1 from the RUNBOOK in Supabase (call RPC twice for the same entity) is enough to prove idempotency.*

---

### 4. Request revision (no regression)

- [ ] Open a delivered work item.
- [ ] Choose **Request changes** / “Request revision” and enter a reason; submit.
- [ ] Request is sent and modal closes; no crash and no wrong approval.

---

### 5. Logging and correlation

- [ ] Perform one **Approve** from the app.
- [ ] In logs, find one **correlationId** value (e.g. `apv_<id>_<timestamp>`).
- [ ] The **same** correlationId appears in both **WorkItemDetails** and **WorkManagement** logs for that approval.

---

### 6. Backend (if you have DB access)

- [ ] In Supabase SQL editor, run:  
  `SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname = 'rpc_approve_delivery';`  
  Function body should contain **`for update`** and **`v_status || ':' || v_payment_status`** in the digest, and **no `now()`** in the key.
- [ ] Run:  
  `SELECT indexname FROM pg_indexes WHERE tablename = 'journal_entries';`  
  There should be **no** `idx_journal_entries_idempotency` (duplicate removed).

---

## Quick reference

| What | Where |
|------|--------|
| Service approval + logging | `lib/features/work/services/work_management_service.dart` — `approveDelivery` |
| ViewModel + correlationId | `lib/features/work/viewmodels/work_item_details_view_model.dart` — `approveDelivery` |
| Modal one-shot + logs | `lib/features/work/view/widgets/review_delivery_modal.dart` — `_handleApprove`, `_hasApproved` |
| Migration (key + FOR UPDATE + index drop) | `supabase/migrations/20260307000001_escrow_idempotency_stable_key.sql` |
| How to run T1/T2/T4 | `.TODO/.../16_escrow-invariants-idempotency/RUNBOOK_EscrowIdempotency_T1_T2.md` |

---

**Done when:** All checklist items that apply to your environment are checked and match the behavior above.
