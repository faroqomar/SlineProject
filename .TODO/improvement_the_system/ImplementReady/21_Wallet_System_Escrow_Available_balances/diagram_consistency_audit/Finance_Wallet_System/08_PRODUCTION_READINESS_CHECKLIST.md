# 08 PRODUCTION READINESS CHECKLIST

Before any money or users hit the finalized unified system, execute this validation checklist.

## 🗄️ Database & Schema Constraints

- [ ] **Data Immutable Verification**: Ensure `ledger_lines`, `journal_entries`, and `payment_events` are strictly configured enforcing Append-Only restrictions via trigger hooks blocking DELETE/UPDATE.
- [ ] **Double-Entry Constraint Check**: Trigger on `journal_entries` guarantees that the sum of debit/credit columns within linked `ledger_lines` exactly equals zero (`balance == 0`).
- [ ] **Schema Unification**: Double-check `wallet_transactions` terminology is sunsetted to prevent dev confusion. All logs follow `journal_entries`/`ledger_lines` patterns.
- [ ] **Disputes FSM Protected**: Attempting to insert junk state like `dispute_status_enum = 'foo'` immediately produces a database execution exception (`22P02`).
- [ ] **No Overlap Schedules Tested**: Overlapping slots in `availability_slots` physically rejects via indexing.

## 🔒 Security & Idempotency Check

- [ ] **Approve Delivery Fix Verified**: Attempt to double-click/spam "Approve" UI in rapid succession. The Idempotency system must return the same matching transaction confirmation gracefully without deducting dual platform fees or over-crediting freelancer Available accounts.
- [ ] **Orphan Catch-All**: Purposely submit a mocked malformed/tampered webhook representing an accepted payment gateway checkout response to the system. Confirm the system traps it specifically into `orphan_payments` and alerts operations, instead of executing or dumping cleanly.
- [ ] **Direct Offers Secure Validation**: Ensure direct chat offers successfully utilize the `rpc_approve_delivery` function with matching ownership criteria enforced.
- [ ] **Rate Limiting Operational**: Attempting excessive successive state transitions triggers generic 429 warnings protecting the backend workload.
- [ ] **RLS Authorization**: Run the automated 26 tests (as per Diagram 15) confirming non-Participants immediately receive 403 on arbitrary data injection attempts.

## 📱 User Interfaces

- [ ] **Balance Splits Accuracy Check**: Verify that "Total Amount" on the user's dashboard matches exactly the derived mathematical summation presented in `vw_wallet_balances`.
- [ ] **Availability Calendar Validated**: Full E2E logic validates Provider blocking capabilities properly mapping collision errors correctly to user-friendly messages via UI exception mappings.
- [ ] **Consistent Checkout Pathway**: Verify Tenders, Bookings, and Direct Offers utilize identical internal server calls passing safely identical objects `payment_intent_ids`.

## ⚙️ Operations & SRE Observability

- [ ] **Notification Triggers Live**: Webhook updates and manual Admin overrides properly broadcast push notifications ensuring non-delayed alerting for Booking success, dispute resolutions, and delivery states.
- [ ] **Audit Logging Active**: Database functions trigger transparent trailing into `audit_logs` specifically for sensitive operations like `process_payment_event_ledger(refund)`.
- [ ] **Admin Dashboards Viewable**: Super-users can visibly inspect aggregate financial volumes and filter out trapped Escrow or stalled Mediation disputes cleanly via tracking views (e.g., `vw_admin_finance_metrics`).
