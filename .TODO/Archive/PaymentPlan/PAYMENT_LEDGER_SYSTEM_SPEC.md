# PAYMENT_LEDGER_SYSTEM_SPEC.md

## 1. Inventory (Current State)

### Existing Wallet Tables & Views

- `wallet_transactions`: Single-sided ledger table storing individual transaction events (type, amount). Types include deposit, escrow_hold, escrow_release, payment_in, refund, withdrawal.
- `wallet_balances`: A PostgreSQL View that aggregates the single-sided transactions by user to compute `available_balance` and `held_balance`.

### Existing RPCs

- `process_payment_event`: Main trigger handling transitions (e.g., escrow, release, refund). It manages both updating entity statuses (booking, task_request) and inserting rows into `wallet_transactions`.
- `process_expired_requests`: Automated cron RPC that refunds pending tasks that expire unanswered.

### Current Booking / Task Payment Flow Triggers in Code

- `BookingService.bookSlot`: Simulates immediate payment and triggers `process_payment_event` with `escrow`.
- `BookingService.approveAndRelease`: Calls `process_payment_event` with `release`.
- `BookingService.declineBooking`: Calls `process_payment_event` with `refund`.

### Current Dashboard Metrics Sources

- Dashboard metrics derive primarily from **counts of entities** (WorkItems) and their states.
- E.g., `needsReview`, `pendingPayment`, `activeWork` are calculated by checking `WorkItem.statusUiBucket`.
- Gross financial values (GMV, Revenue) are absent or implied by counting active jobs instead of aggregating ledger entries.

---

## 2. Compliance Gaps vs. Global Standards

- [ ] **Missing Double-Entry Primitives**: The system acts as a standard single-ledger wallet. It lacks Journal Entries mapping atomic movements (Credits & Debits) balancing across distinct Accounts.
- [ ] **Missing Append-Only Enforcement**: Although guarded by RLS, `wallet_transactions` structurally lacks hard database triggers (e.g., `RAISE EXCEPTION`) preventing accidental updates or deletes to history by the `service_role`.
- [ ] **Missing Idempotency & Concurrency Protection**: RPCs currently execute without a strict idempotency key (`idempotency_key` column is absent). Double-invocations on slow networks risk double charges or double releases over the same entity unless row locks (`FOR UPDATE`) strictly guard concurrent state reads.
- [ ] **Missing Audit Trail (Action → Journal ID)**: System transitions do not generate an immutable audit manifest binding the exact application event (client clicked 'Decline') to the resultant financial journal.
- [ ] **Client-Side Anti-Patterns**: `DashboardRepository` calculates metrics by iterating over object arrays in memory locally, instead of pulling aggregated system-level SQL sums. Total system cash vs total user escrow isn't verified.

---

## 3. Proposed Target Architecture

### Chart of Accounts

| Account Type  | System Name               | Direction                          | Description                                                                                                        |
| :------------ | :------------------------ | :--------------------------------- | :----------------------------------------------------------------------------------------------------------------- |
| **Asset**     | `platform_cash`           | Debit increases / Credit decreases | Real liquid fiat residing in Stripe or corporate bank accounts.                                                    |
| **Liability** | `platform_escrow`         | Credit increases / Debit decreases | Funds held by the platform on behalf of the transaction participants, pending resolution (release/refund/dispute). |
| **Liability** | `user_available`          | Credit increases / Debit decreases | Funds owed to the user and available for withdrawal/spend within the platform.                                     |
| **Liability** | `user_pending_withdrawal` | Credit increases / Debit decreases | Locked funds pending payout.                                                                                       |
| **Revenue**   | `platform_revenue`        | Credit increases / Debit decreases | SLine's realized commission/revenue on completed work.                                                             |

_Note: `user_available` strictly refers to `user_available:{user_id}` (where `owner_id = user_id`)._

### Event Catalog & Double-Entry Journal Lines (Balanced)

_All journals must balance: SUM(DEBIT amounts) == SUM(CREDIT amounts)._

| Event                | Status Condition                                        | Debit Account                 | Credit Account                                              |
| :------------------- | :------------------------------------------------------ | :---------------------------- | :---------------------------------------------------------- |
| **Deposit**          | N/A                                                     | `platform_cash` (Asset)       | `user_available` (Liability)                                |
| **Escrow Hold**      | Booking created (`unpaid` ➞ `held`)                     | `user_available` (Liability)  | `platform_escrow` (Liability)                               |
| **Release_With_Fee** | Delivery approved (`held` ➞ `released`)                 | `platform_escrow` (Liability) | `user_available` (Liability) + `platform_revenue` (Revenue) |
| **Refund**           | Booking declined/User Won Dispute (`held` ➞ `refunded`) | `platform_escrow` (Liability) | `user_available` (Liability)                                |
| **Withdrawal**       | N/A                                                     | `user_available` (Liability)  | `platform_cash` (Asset)                                     |

### Status Gating Matrix

| Event         | Booking/Task Status Requirements                                                                                               | Entity Payment Target Status |
| :------------ | :----------------------------------------------------------------------------------------------------------------------------- | :--------------------------- |
| `escrow_hold` | Status must be `pending`. Booking Payment Status must be `unpaid`.                                                             | ➞ `held`                     |
| `release`     | Status must be `delivered`. Booking Payment Status must be `held`.                                                             | ➞ `released`                 |
| `refund`      | Status must be `declined`, `canceled`, `expired_unanswered`, or `refunded` via dispute. Booking Payment Status must be `held`. | ➞ `refunded`                 |

### Actor Requirements

- `escrow_hold`: actor = client
- `release`: actor = client
- `refund`: actor = provider OR system (timeouts) OR dispute resolution authority
- `withdrawal_request` / `withdrawal_complete`: actor = provider OR system (webhook)

---

## 4. Migration Plan

- [ ] **Phase 0: Definitions Freeze**
  - Lock in the Chart of Accounts and Event definitions outlined above.
  - Ensure everyone aligns on SLine Revenue structure.

- [ ] **Phase 1: DB Objects & Constrains**
  - Create tables: `accounts`, `journal_entries` (containing `idempotency_key`), and `ledger_lines`.
  - Balance enforcement MUST be guaranteed via RPC validation before commit, and/or trigger on journal finalize.
  - Implement trigger to block Updates/Deletes on both ledger tables to enforce strict append-only compliance.

- [ ] **Phase 2: RPC Rewrite Strategy**
  - Refactor `process_payment_event` to take `idempotency_key`.
  - Modify interior logic to sequentially write double-entry `ledger_lines` rather than single `wallet_transactions` rows.
  - Add `FOR UPDATE` serializable row locks on the `bookings`/`tasks` records before mutating them.

- [ ] **Phase 3: View Emulation (Stable Flutter Interfaces)**
  - Re-create the `wallet_balances` view mapping `SUM(credit) - SUM(debit)` from the `user_available` account mapped to `available_balance`.
  - Ensure `WalletViewModel` and `WalletService` continue functioning transparently.

- [ ] **Phase 4: Dashboard Financial Views (Single Source of Truth)**
  - Create robust analytical SQL views pointing strictly to `platform_revenue` and `platform_escrow` for dashboard values.
  - Switch `DashboardRepository` locally computed counters to fetch aggregated ledger metrics straight from the DB.

- [ ] **Data Backfill Strategy**
  - Run a one-off PL/pgSQL migration script converting historical successful `wallet_transactions` records into `journal_entries` with two balancing `ledger_lines`. Assign a system "legacy" idempotency key.

## 5. Refinements (Required for Production-Grade Compliance)

- **Journals must balance:** SUM(DEBIT) == SUM(CREDIT) per `journal_entry_id`.
- **`user_available` must be a per-user account:** `user_available:{user_id}` with `owner_id` and `currency`.
- **`platform_escrow` description:** held on behalf of participants pending resolution.
- **Idempotency:**
  - `journal_entries.idempotency_key` must be globally UNIQUE.
  - _(Optional)_ UNIQUE(`related_entity_type`, `related_entity_id`, `event_type`) for event replay prevention.
- **Append-only enforcement:**
  - No UPDATE/DELETE allowed for any role (including `service_role`).
  - Corrections are performed via compensating (reversal) journals.
- **Payment processing protocol (single DB transaction):**
  - Lock entity row, validate gates, check idempotency, write balanced journal+lines, update entity statuses, write audit log, commit.
- **Dashboard split:**
  - Operational counters from work tables.
  - Financial numbers strictly from ledger views (`platform_revenue`, `platform_escrow`, `platform_cash`).
- **Backfill rules:** must map each legacy `wallet_transactions.type` to a balanced journal with metadata linking to the legacy id.
- **Add currency:** to accounts/journals to avoid future breaking migrations.

---

## 6. Data Model Requirements (Target)

### 6.1 accounts

- `id` (uuid)
- `account_code` (text, unique)
  - Examples: `platform_cash`, `platform_escrow`, `platform_revenue`, `user_available:{user_id}`
- `account_type` (enum): `asset` | `liability` | `revenue` | `expense` | `equity`
- `owner_id` (uuid, nullable)
  - `null` for the platform, `user_id` for personal accounts.
- `currency` (text)
- `created_at`

### 6.2 journal_entries

- `id`
- `event_type` (text/enum)
- `related_entity_type`
- `related_entity_id`
- `idempotency_key` (text, unique)
- `created_by`
- `created_at`
- `meta` (jsonb)

### 6.3 ledger_lines

- `id`
- `journal_entry_id`
- `account_id`
- `direction` (DEBIT/CREDIT)
- `amount` (numeric > 0)
- `currency` (must match journal currency)
- `created_at`

---

## 7. Financial Event Catalog (Expanded, Global-Grade)

### 7.1 Core Events (MVP)

- `deposit`
- `escrow_hold`
- `release_with_fee`
- `refund`
- `withdrawal_complete`

### 7.2 Reserved Events (Phase Later)

- `withdrawal_request` (locks funds)
- `withdrawal_failed` (reverts lock)
- `dispute_opened` (freeze)
- `dispute_resolved_release`
- `dispute_resolved_refund`
- `partial_refund`
- `manual_adjustment` (admin-only with strict audit)

---

## 8. Rules & Constraints (Compliance Core)

### 8.1 Atomicity

Each payment event MUST be processed in a single DB transaction:

1. Entity row lock
2. Validate gates
3. Idempotency check
4. Balanced journal write + lines
5. Entity status update
6. Audit log write
7. Commit

### 8.2 Concurrency / Locking

- RPC must lock the related entity row (`bookings` / `task_requests`) **before** reading/updating status.
- The system must prevent two concurrent events from passing gates.

### 8.3 Idempotency

- `journal_entries.idempotency_key` is globally UNIQUE.
- Optional secondary guard: UNIQUE(`related_entity_type`, `related_entity_id`, `event_type`)

### 8.4 Immutability

- No UPDATE/DELETE on ledger tables for any role.
- Corrections must use compensating journals (reversals).

### 8.5 Currency Integrity

- All lines in a journal must share the same currency.
- Accounts must be currency-scoped (or at minimum validated).

### 8.6 Fee Policy Integrity

- Fee calculation must be deterministic and stored in `meta` (`fee_rate`, `fee_amount`, `gross`, `net`).
- Fee is only recognized on release/complete (not on hold).

---

## 9. Dashboard Financial Definitions & Sources (Binding)

### 9.1 Operational Metrics (Work tables)

- `activeWork`, `pending`, `done`, `inboxOffers`, etc.
- **Source:** Work items / status buckets.

### 9.2 Financial Metrics (Ledger only)

- **GMV:** Sum of `escrow_hold` gross amounts within period.
- **Revenue:** Sum of credits to `platform_revenue` within period.
- **Escrow Outstanding:** Current balance of `platform_escrow`.
- **Total Deposits:** Sum of debits to `platform_cash` from `deposit`.
- **Total Withdrawals:** Sum of `withdrawal_complete` gross amounts within period (equivalent to SUM of CREDIT amounts on `platform_cash` for that event).
- **Refunds Total:** Sum of `refund` amounts within period.
- **Take Rate:** Revenue / GMV.
- **Refund Rate:** Refunds Total / GMV.

### 9.3 Source Objects

All financial metrics MUST be computed from:

- `vw_financial_metrics_realtime`
- `vw_financial_metrics_period(period_start, period_end)` OR daily snapshot view/table later.

---

## 10. Balance Computation Rules (Binding)

### 10.1 Per-account balance

- **Asset accounts:** balance = SUM(DEBIT) - SUM(CREDIT)
- **Liability/Revenue accounts:** balance = SUM(CREDIT) - SUM(DEBIT)

### 10.2 Wallet balance mapping

- `available_balance(user)` = balance(`user_available:{user_id}`) (liability semantics)
- `escrow_outstanding` = balance(`platform_escrow`) (liability semantics)
- `liquidity` = balance(`platform_cash`) (asset semantics)

### 10.3 Negative balances policy

- The system MUST prevent any user liability account from going negative (insufficient funds).
- Any negative state is a critical invariant violation and must be blocked at RPC gate level.

---

## 11. Withdrawal Lifecycle (Global Standard)

### 11.1 States

A withdrawal must be represented by an entity record (e.g., `withdrawal_requests`) with:

- `requested` → `processing` → (`completed` | `failed` | `canceled`)

### 11.2 Ledger events

- `withdrawal_request` (locks funds):
  - Debit `user_available:{user}` (Liability ↓)
  - Credit `user_pending_withdrawal:{user}` (Liability ↑)
- `withdrawal_complete` (payout executed):
  - Debit `user_pending_withdrawal:{user}` (Liability ↓)
  - Credit `platform_cash` (Asset ↓)
- `withdrawal_failed` (unlock funds):
  - Debit `user_pending_withdrawal:{user}` (Liability ↓)
  - Credit `user_available:{user}` (Liability ↑)

### 11.3 Why this is mandatory

- Prevents double-spend (user requests payout while still spending available balance).
- Makes async payment gateways safe and auditable.

---

## 12. Reconciliation & External Payment Mapping

### 12.1 External references (stored in `journal_entries.meta`)

For any event that touches real money (`deposit`, `withdrawal_complete`):

- `psp_provider`: e.g., Stripe
- `psp_event_id`: webhook event id
- `psp_charge_id` / `psp_payment_intent_id` (for deposits)
- `psp_payout_id` / `psp_transfer_id` (for withdrawals)
- `psp_status`
- `psp_timestamp`

### 12.2 Reconciliation rule

- `platform_cash` must be reconcilable to PSP reported balance.
- Any mismatch must be explainable by pending deposits/withdrawals in lifecycle states.

### 12.3 Idempotency alignment

- Webhook ingestion MUST use a deterministic `idempotency_key` derived from `psp_event_id` to prevent duplicates.

---

## 13. Entity Coverage

The `related_entity_type` parameter is restricted to specific system actions:

- `booking` | `task_request` | `withdrawal_request` | `admin_adjustment`

Each type triggers a strict subset of financial events defined in the catalog above.

---

## 14. Views & Interfaces Contract (Flutter + Dashboard Binding)

### 14.1 Wallet Balance View (User)

**Name:** `vw_wallet_balances_user`
**Purpose:** Returns exactly two fixed numbers for the Wallet screen.
**Returns (per user):**

- `user_id`
- `currency`
- `available_balance`
- `held_balance` (defined here as `platform_escrow` linked to this user as a client)
- `pending_withdrawal_balance` (optional)
- `updated_at` (optional)

**Rules:**

- MUST be derived from ledger only.
- MUST return 0 (not null) for new users.

### 14.2 Wallet Activity View (User)

**Name:** `vw_wallet_activity_user`
**Returns:**

- `journal_id`
- `created_at`
- `event_type`
- `amount_gross`
- `amount_net` (nullable; mainly for `release_with_fee`)
- `fee_amount` (nullable)
- `currency`
- `related_entity_type`
- `related_entity_id`
- `counterparty_user_id` (nullable)
- `status` (derived if needed: completed/processing/etc.)

**Rules:**

- Derived from `journal_entries` + `ledger_lines` (never from old `wallet_transactions`).

### 14.3 Financial Metrics Realtime View (System)

**Name:** `vw_financial_metrics_realtime`
**Returns:**

- `currency`
- `escrow_outstanding`
- `platform_cash_balance`
- `lifetime_gmv`
- `lifetime_revenue`
- `lifetime_refunds`
- `lifetime_withdrawals`
- `updated_at`

### 14.4 Financial Metrics Period View (System)

**Name:** `vw_financial_metrics_period(period_start, period_end)`
**Returns:**

- `currency`
- `gmv`
- `revenue`
- `refunds`
- `withdrawals`
- `take_rate`
- `refund_rate`

**Rule:**

- "period" metrics MUST be computed from event types + account credits/debits as defined in Section 9.

### 14.5 Operational Metrics View (Optional)

**Name:** `vw_operational_metrics_period`

- Counts from work tables only (active/done/pending/inbox).

---

## 15. Execution Plan (Phased TODO, No Code)

### Phase A — DB Preparation

- Create `accounts`, `journal_entries`, `ledger_lines`.
- Create `audit_logs` (if not present).
- **Triggers:** append-only block update/delete.
- **Constraints:** positive amounts, currency match.
- (Balance validation strategy defined via RPC or trigger).
- **Result:** Ledger ready for writes.

### Phase B — Ledger Engine RPC (Core)

- Refactor `process_payment_event` → write journals/lines.
- **Add:**
  - `idempotency_key` required.
  - Entity locking + gates.
  - Negative balance guard.
  - Fee computation stored in meta.
- Add webhook ingestion endpoints (even as stubs).
- **Result:** All money movements become ledger-native.

### Phase C — Compatibility Layer

- Replace `wallet_balances` with new view `vw_wallet_balances_user`.
- Provide `vw_wallet_activity_user`.
- Keep Flutter interfaces stable (`WalletViewModel` reads same fields).
- **Result:** Frontend continues working with minimal changes.

### Phase D — Dashboard Integration

- Add `vw_financial_metrics_realtime`.
- Add `vw_financial_metrics_period`.
- Update `DashboardRepository`:
  - Keep operational counters local or via operational view.
  - Financial counters must come from ledger views.
- **Result:** Dashboard becomes legally consistent with ledger.

### Phase E — Backfill & Cutover

- Backfill `wallet_transactions` → `journal_entries` + `ledger_lines` (tag meta legacy).
- Verify balances match old system for a sample set.
- Verify escrow outstanding matches expected.
- Freeze old writes to `wallet_transactions` (read-only legacy).
- **Result:** Clean migration with historical continuity.
