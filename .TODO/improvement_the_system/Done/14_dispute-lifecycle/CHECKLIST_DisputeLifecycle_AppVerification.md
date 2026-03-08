# Dispute Lifecycle — App verification checklist & change summary

**Date:** 2026-03-08  
**Scope:** What was added, removed, modified, and how to check it in the app.

---

## Quick summary (what & why)

| What | Why |
|------|-----|
| **Approve/Review disabled when a dispute is open** | So clients cannot release escrow while a dispute is active. |
| **Single “has open dispute?” check** | All detail screens use `SafetyViewModel` → `DisputeService` (no duplicate logic). |
| **Booking uses booking id for dispute check** | Handles missing `task_id` safely; same behaviour for every booking. |
| **Disputed banner on work item details** | When you open a disputed item (e.g. from “Submit Evidence”), you see why Approve is blocked. |
| **Better logging** | Entity ids and event names in logs so support can trace disputes and errors. |
| **Docs and diagram updated** | SUPABASE_SETUP, DEVELOPER_GUIDE, STRUCTURE, MVP_ROADMAP, Sline_Log, diagram 14 match the implementation. |

---

## What was ADDED

- **DisputeService**
  - `hasOpenDisputeForDirectOffer(offerId)` — check open dispute for a direct offer.
  - `hasOpenDisputeForBooking(bookingId)` — check open dispute for a booking (via its task).
- **SafetyViewModel**
  - `hasOpenDisputeForDirectOffer(offerId)` and `hasOpenDisputeForBooking(bookingId)` — exposed to UI.
- **Booking details screen**
  - `_ApproveWithDisputeGuard` — “Approve & Release Funds” is disabled when there is an open dispute for that booking (uses `hasOpenDisputeForBooking(booking.id)`).
- **Work item details screen**
  - `_ReviewWithDisputeGuard` — “Review” button disabled when there is an open dispute for that task/booking/direct offer.
  - `_buildDisputedBanner` — info banner when the work item is disputed: *“This work has an open dispute. Submit evidence from the dispute flow (coming soon).”*
- **Direct offer details screen**
  - `_ApproveWithDisputeGuard` — “Approve & release payment” disabled when there is an open dispute for that direct offer.
- **Logger**
  - `AppLogger.e(..., json: ...)` — optional `json` parameter for error logs (entity ids, event names).
- **Logging**
  - Submit success: `event_name: 'safety_dispute_submitted'`, `task_id`.
  - Submit failure (VM): `event_name: 'safety_dispute_submit_failed'`, `task_id`.
  - Has-open-dispute errors: `task_id` / `direct_offer_id` / `booking_id` in the error log.

---

## What was REMOVED

- **Booking details**
  - The special case where “Approve & Release” was always enabled when `booking.taskId` was null/empty. Now the guard always runs via `hasOpenDisputeForBooking(booking.id)` (service returns false when no task_id, so button can still be enabled when there is no dispute).

---

## What was MODIFIED

- **DisputeService**
  - `hasOpenDisputeForTask` — error log now includes `task_id` in `json`.
  - `hasOpenDisputeForDirectOffer` — error log now includes `direct_offer_id` in `json`.
  - `hasOpenDisputeForBooking` — error log now includes `booking_id` in `json`.
  - Submit success log — added `event_name: 'safety_dispute_submitted'`.
- **SafetyViewModel**
  - `submitDispute` catch — log now includes `event_name: 'safety_dispute_submit_failed'` and `task_id`.
- **Booking details**
  - Guard now calls `hasOpenDisputeForBooking(booking.id)` instead of `hasOpenDisputeForTask(booking.taskId)` so behaviour is consistent and null `task_id` is handled in the service.
- **Docs**
  - SUPABASE_SETUP (§1 enums, §5.24–5.26 disputes/messages/evidence, §6.4 view, §17 changelog).
  - DEVELOPER_GUIDE (§5.3 dispute lifecycle and guard).
  - STRUCTURE (test path, migrations), MVP_ROADMAP (dispute row), Sline_Log (new entry), diagram 14 (enum, triggers, RLS).

---

## App verification checklist

Use this on a real device or simulator to confirm behaviour.

### Prerequisites

- [ ] You can open **Booking details** for a delivered booking (as client).
- [ ] You can open **Work item details** (task or booking) in “delivered” state (as client).
- [ ] You can open **Direct offer details** for a delivered direct offer (as client).
- [ ] You have (or can create) **one open dispute** linked to a task, and optionally one linked to a direct offer.

---

### 1. Booking details — Approve & Release

- [ ] Open a **delivered** booking where there is **no** dispute.  
  **Expected:** “Approve & Release Funds” shows “Checking…” briefly, then is **enabled**.
- [ ] Open a **delivered** booking where there **is** an open dispute for that booking’s task.  
  **Expected:** “Approve & Release Funds” shows “Checking…” briefly, then is **disabled** (greyed out).
- [ ] Submit a new dispute from the same booking details (Report Issue → submit dispute).  
  **Expected:** After submit, the Approve button is **disabled** (refresh or re-open if needed).

---

### 2. Work item details (task) — Review

- [ ] Open work item details for a **delivered task** with **no** dispute.  
  **Expected:** “Review” shows “Checking…” briefly, then is **enabled**.
- [ ] Open work item details for a **delivered task** that **has** an open dispute.  
  **Expected:** “Review” shows “Checking…” briefly, then is **disabled**.
- [ ] On the same disputed task, scroll the overview.  
  **Expected:** You see the **disputed banner**: *“This work has an open dispute. Submit evidence from the dispute flow (coming soon).”*

---

### 3. Work item details (booking) — Review

- [ ] Open work item details for a **delivered booking** with **no** dispute.  
  **Expected:** “Review” is **enabled** after “Checking…”.
- [ ] Open work item details for a **delivered booking** that **has** an open dispute.  
  **Expected:** “Review” is **disabled** after “Checking…”, and the disputed banner is visible.

---

### 4. Direct offer details — Approve & release payment

- [ ] Open direct offer details for a **delivered** direct offer with **no** dispute.  
  **Expected:** “Approve & release payment” shows “Checking…” then is **enabled**.
- [ ] Open direct offer details for a **delivered** direct offer that **has** an open dispute.  
  **Expected:** “Approve & release payment” shows “Checking…” then is **disabled**.

---

### 5. Dashboard — Submit Evidence

- [ ] From the dashboard, open a work item that shows **“Submit Evidence”** (disputed).  
  **Expected:** You land on work item details; the **disputed banner** is shown and “Review” is **disabled**.

---

### 6. Submit dispute (sanity check)

- [ ] From booking details, open “Report Issue” and submit a dispute with a reason.  
  **Expected:** Dispute is created; no crash; Approve & Release is (or becomes) **disabled** for that booking.

---

### 7. Logs (optional)

- [ ] In debug, submit a dispute and check logs: `event_name: safety_dispute_submitted`, `task_id` present.
- [ ] In debug, trigger a dispute-check error (e.g. disconnect) and check logs: error log includes `task_id` or `booking_id` or `direct_offer_id` and (for VM) `event_name: safety_dispute_submit_failed`.

---

## If something fails

- **Button stays enabled with a dispute:** Confirm the dispute is for the same task/booking/direct offer and status is `open` or `active`. Check RLS and that the app user is the client for that work.
- **Button stays on “Checking…”:** Check network and Supabase; dispute check uses `.limit(1).maybeSingle()` and should return quickly.
- **No disputed banner:** Banner only shows when `unified_status == disputed` (from `vw_unified_work_items`). Ensure the view and dispute row are correct.

---

## References

- Plan: `.TODO/PLAN_DisputeLifecycle_2026-03-08.md`
- Execution log: `.TODO/EXECUTION_LOG_DisputeLifecycle_2026-03-08.md`
- Master report: `.TODO/MASTER_REPORT_2026-03-08_DisputeLifecycle.md`
