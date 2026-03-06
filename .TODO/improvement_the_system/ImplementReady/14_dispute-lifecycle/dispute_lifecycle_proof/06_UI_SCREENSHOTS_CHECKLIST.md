# UI Screenshots Checklist: Dispute Lifecycle

> This checklist defines exact screenshots that a developer/tester must capture to prove the dispute UI is correctly wired to backend constraints.

---

## F1) App Screenshots — Client

| #   | Screen                                                | Expected Visible Elements                                                                                          | Backend State Required                                                 | Query/RPC to Prove                                         |
| --- | ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------- | ---------------------------------------------------------- |
| C1  | **Booking Details BEFORE dispute** (status=delivered) | "Report Issue" link (red text), "Approve & Release Funds" button (active)                                          | `bookings.status='delivered'`, `payment_status='held'`                 | `SELECT status, payment_status FROM bookings WHERE id = ?` |
| C2  | **"Report Issue" dialog**                             | AlertDialog: title "Report Issue", TextField "Describe the problem…", Cancel + Submit buttons                      | Same as C1                                                             | N/A (UI-only)                                              |
| C3  | **After dispute submitted** (status=open)             | SnackBar "Dispute submitted.", "Approve & Release Funds" button should be **disabled** (⚠️ currently NOT disabled) | `disputes.status='open'` for this task                                 | `SELECT status FROM disputes WHERE task_id = ?`            |
| C4  | **Dashboard Work Tab (disputed)**                     | Item in "Active" bucket with `statusRaw='disputed'`, primary action "Submit Evidence"                              | `vw_unified_work_items.unified_status='disputed'`                      | `SELECT * FROM vw_unified_work_items WHERE ...`            |
| C5  | **Evidence upload UI**                                | ⚠️ NOT YET BUILT — screenshot should show "coming soon" or error                                                   | N/A                                                                    | N/A                                                        |
| C6  | **Dispute ACTIVE**                                    | Status badge change from "Open" to "Active" (admin-driven)                                                         | `disputes.status='active'`                                             | `SELECT status FROM disputes WHERE id = ?`                 |
| C7  | **Dispute RESOLVED (refund)**                         | Final outcome text, wallet balance increased                                                                       | `disputes.status='resolved'`, `disputes.resolution='refund'`           | `SELECT * FROM vw_wallet_balances_user`                    |
| C8  | **Dispute RESOLVED (release)**                        | Final outcome text, earnings released to freelancer                                                                | `disputes.status='resolved'`, `disputes.resolution='release_with_fee'` | `process_payment_event_ledger(...)` result                 |
| C9  | **Dispute CANCELED**                                  | (⚠️ Not implemented — withdrawal flow)                                                                             | `disputes.status='canceled'`                                           | N/A                                                        |

---

## F2) App Screenshots — Freelancer

| #   | Screen                                   | Expected Visible Elements                     | Backend State Required                                    | Query/RPC to Prove                              |
| --- | ---------------------------------------- | --------------------------------------------- | --------------------------------------------------------- | ----------------------------------------------- |
| F1  | **Notification that dispute started**    | ⚠️ NOT YET BUILT                              | `disputes.status='open'`, `defendant_id = freelancer_uid` | `SELECT * FROM disputes WHERE defendant_id = ?` |
| F2  | **Dispute thread screen**                | ⚠️ NOT YET BUILT                              | `dispute_messages` rows                                   | N/A                                             |
| F3  | **Evidence view + upload**               | ⚠️ NOT YET BUILT                              | `dispute_evidence` rows                                   | N/A                                             |
| F4  | **Task/Booking "locked due to dispute"** | "Mark Delivered" disabled, lock badge visible | ⚠️ NOT YET BUILT — no lock logic                          | N/A                                             |
| F5  | **Resolved outcome — earnings impact**   | ⚠️ NOT YET BUILT                              | `disputes.resolution` + ledger                            | N/A                                             |

---

## F3) Admin Dashboard Screenshots

| #   | Screen                         | Expected Visible Elements                      | Backend State Required                   | Query/RPC to Prove                                               |
| --- | ------------------------------ | ---------------------------------------------- | ---------------------------------------- | ---------------------------------------------------------------- |
| A1  | **Disputes list (filters)**    | ⚠️ NO ADMIN UI IN REPO                         | All `disputes` rows                      | `SELECT * FROM disputes ORDER BY created_at DESC`                |
| A2  | **Dispute detail page**        | Parties, timestamps, status timeline, evidence | Single dispute row + messages + evidence | JOIN across 3 tables                                             |
| A3  | **Admin resolve modal**        | Resolve / Refund / Release confirmation        | `disputes.status='active'`               | Admin RPC (not yet created)                                      |
| A4  | **Money story / ledger trace** | Journal entries, ledger lines for this entity  | `journal_entries` + `ledger_lines`       | `SELECT * FROM journal_entries WHERE related_entity_id = ?`      |
| A5  | **Audit log entry**            | Actor, action, timestamp, resolution detail    | `audit_logs` row                         | `SELECT * FROM audit_logs WHERE related_entity_type = 'dispute'` |

---

## Summary

| Section            | Screenshottable Now           | Requires Build First                         |
| ------------------ | ----------------------------- | -------------------------------------------- |
| Client (C1-C4)     | ✅ C1, C2 can be captured now | C3-C9 require dispute state logic / UI build |
| Freelancer (F1-F5) | ❌ None                       | All require new UI                           |
| Admin (A1-A5)      | ❌ None                       | Requires admin dashboard                     |
