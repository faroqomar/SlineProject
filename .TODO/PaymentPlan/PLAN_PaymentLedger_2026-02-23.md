# 📌 Plan: Payment Ledger Implementation (3-Phase Execution — Ultra Detailed & Hardened)

## 0) Definitions (Fixed - must be agreed upon before any work)

### 0.1 Entities involved in money (Entity Coverage)

No other entities allowed.

- booking
- task_request
- withdrawal_request (will be prepared even if for later)
- admin_adjustment (reserved)

### 0.2 Accounts (Chart of Accounts)

Platform accounts (owner_id = NULL)

- platform_cash
- platform_escrow
- platform_revenue
- platform_test_float

Per-user accounts (owner_id = auth.users.id)

- user_available:{user_id}
- user_pending_withdrawal:{user_id}

### 0.3 Event Types (Minimum required)

Internal payment events (NOW)

- escrow_hold
- release_with_fee
- refund
- withdrawal_request

Deferred events (LATER)

- deposit
- withdrawal_complete
- withdrawal_failed

System/Admin events (Reserved)

- admin_credit
- admin_adjustment
- reversal

### 0.4 Invariants (Non-negotiable rules)

- Append-only: NO UPDATE / NO DELETE on ledger tables for any role
- Balanced Journal: SUM(DEBIT) == SUM(CREDIT) for each journal_entry_id
- Idempotency: journal_entries.idempotency_key UNIQUE
- Locking: Any financial event related to booking/task_request must perform SELECT ... FOR UPDATE on row
- No negative: user_available:{user} must not fall below 0
- Dashboard financial = views only (not calculating from app)

---

## Phase 1 — Build the Payment System (Ledger Core Only)

### 1.1 Goal

Build the "Payment Heart" inside Supabase/Postgres only:

- tables + constraints + triggers
- RPC engine
- views contract
- without any wiring to the application (Flutter) and without Gateway

### 1.2 Deliverables — Detailed Detail

#### 1.2.1 DB Tables (Exact Names + Columns)

**A) accounts**
Columns

- id (uuid, PK)
- account_code (text, UNIQUE)
- account_type (text or enum): asset | liability | revenue | expense | equity
- owner_id (uuid, nullable) = auth.users.id
- currency (text) = "IQD" (Fixed MVP)
- created_at (timestamptz)

Indexes

- idx_accounts_owner_id

**B) journal_entries**
Columns

- id (uuid, PK)
- event_type (text) — must be one from event catalog
- related_entity_type (text) — must be one from entity coverage
- related_entity_id (uuid, nullable for platform events)
- idempotency_key (text, UNIQUE)
- status (text): posted | voided (Default: posted)
- created_by (uuid) actor user id (auth.uid for Flutter, or NULL for system)
- currency (text) "IQD"
- meta (jsonb) — details (fee, gateway ids, reversals, etc.)
- created_at (timestamptz)

Indexes

- idx_journal_entries_entity on (related_entity_type, related_entity_id)
- idx_journal_entries_event_type
- idx_journal_entries_status
- idx_journal_entries_created_at

**C) ledger_lines**
Columns

- id (uuid, PK)
- journal_entry_id (uuid, FK → journal_entries.id)
- account_id (uuid, FK → accounts.id)
- direction (text): DEBIT | CREDIT
- amount (numeric, > 0)
- currency (text) "IQD"
- created_at (timestamptz)

Indexes

- idx_ledger_lines_journal_entry_id
- idx_ledger_lines_account_id
- idx_ledger_lines_created_at

**D) audit_logs**
Columns

- id (uuid, PK)
- actor_user_id (uuid)
- action (text)
- related_entity_type (text, nullable)
- related_entity_id (uuid, nullable)
- journal_entry_id (uuid, FK → journal_entries.id)
- meta (jsonb) (optional, without sensitive information)
- created_at (timestamptz)

Indexes

- idx_audit_logs_actor_user_id
- idx_audit_logs_journal_entry_id
- idx_audit_logs_created_at

**E) withdrawal_requests (built now but unused)**
Columns

- id (uuid, PK)
- user_id (uuid = auth.users.id)
- status (text): requested | processing | completed | failed | canceled
- amount (numeric > 0)
- currency (text) "IQD"
- created_at (timestamptz)

---

#### 1.2.2 Triggers (Append-only + Hard Protections)

Trigger Names (Fixed)

- trg_journal_entries_append_only
- trg_ledger_lines_append_only
- trg_accounts_append_only

Behavior

- Always prevents UPDATE/DELETE

Balance enforcement

- "Balance check inside RPC before commit" (Best for MVP)

---

#### 1.2.3 RPC Engine (Signature + Params + Errors)

Function name

- process_payment_event_ledger

Params (Exact & Final - No Actor Spoofing)

- p_event_type (text) — one of catalog
- p_related_entity_type (text)
- p_related_entity_id (uuid)
- p_idempotency_key (text) — mandatory
- p_amount_gross (numeric) — OPTIONAL (RPC SHOULD ALWAYS READ `amount` DIRECTLY FROM THE PARENT ENTITY `bookings.amount_gross` IF PRESENT, p_amount_gross is for comparison/fallback only).
- p_currency (text) default 'IQD'
- p_meta (jsonb) default '{}'

Actor user id inside RPC is extracted as follows (never sent):

- v_actor_user_id := auth.uid()

Standard Return Payload (Exact keys)

- ok (boolean)
- journal_entry_id (uuid)
- event_type (text)
- related_entity_type (text)
- related_entity_id (uuid)
- balances (json):
  - available_balance
  - held_balance
- error (json nullable):
  - code
  - message

Error Codes

- ERR_MISSING_IDEMPOTENCY_KEY
- ERR_IDEMPOTENCY_REPLAY
- ERR_GATE_NOT_ALLOWED
- ERR_INSUFFICIENT_FUNDS
- ERR_UNBALANCED_JOURNAL
- ERR_ENTITY_NOT_FOUND
- ERR_CURRENCY_MISMATCH
- ERR_AMOUNT_MISMATCH
- ERR_WITHDRAWAL_AMOUNT_INVALID

---

#### 1.2.4 Views Contract (Exact Names + Columns)

**A) vw_wallet_balances_user**
Input: depends on auth.uid() via security barrier / RLS
Columns

- user_id
- currency
- available_balance
- held_balance
- pending_withdrawal_balance (optional)
- updated_at (optional)

**B) vw_wallet_activity_user**
Columns

- journal_entry_id
- created_at
- event_type
- amount_gross
- amount_net (nullable)
- fee_amount (nullable)
- currency
- related_entity_type
- related_entity_id
- counterparty_user_id (nullable)
  - escrow_hold: counterparty = provider_id (if present) or null
  - release_with_fee: counterparty = client_id for the provider view, and provider_id for the client view
  - refund: counterparty = provider_id or system
- status (optional derived)

**C) vw_financial_metrics_realtime**
Columns

- currency
- escrow_outstanding
- platform_cash_balance
- lifetime_gmv
- lifetime_revenue
- lifetime_refunds
- updated_at

**D) vw_financial_metrics_period(period_start, period_end)**
Columns

- currency
- gmv
- revenue
- refunds
- take_rate
- refund_rate

---

#### 1.2.5 Payment Event Matrix (Mandatory Document)

File: PAYMENT_EVENT_MATRIX.md

Example (by names)

- escrow_hold:
  - debit: user_available:{client_id} amount=v_entity_amount_gross
  - credit: platform_escrow amount=v_entity_amount_gross
- release_with_fee:
  - debit: platform_escrow amount=v_entity_amount_gross
  - credit: user_available:{provider_id} amount=net
  - credit: platform_revenue amount=fee
- refund:
  - debit: platform_escrow amount=v_entity_amount_gross
  - credit: user_available:{client_id} amount=v_entity_amount_gross
- withdrawal_request (internal-only):
  - debit: user_available:{user_id} amount=v_request_amount
  - credit: user_pending_withdrawal:{user_id} amount=v_request_amount
  - entity: withdrawal_request (related_entity_type = withdrawal_request)
- admin_credit (testing only):
  - debit: platform_test_float amount=p_amount_gross
  - credit: user_available:{user_id} amount=p_amount_gross

---

### 1.3 Gate 100% (Phase 1) — Won't pass without these

DB Integrity

- Attempt to UPDATE/DELETE on ledger_lines fails
- Attempt to insert unbalanced journal fails
- idempotency_key unique (second insert with the same key doesn't write a new journal)

Funds

- escrow_hold on balance less than required → ERR_INSUFFICIENT_FUNDS

Views

- new user returns available_balance=0 and held_balance=0 (not null)
- Only `posted` journals are aggregated in views.

Exit

- All results Verified on staging/branch

### 1.4 Rollback (Phase 1)

- staging: drop objects
- production: disable RPC + keep objects (without deletion)

---

## Phase 2 — System Integration (Tasks/Bookings First) then Gateway

### Phase 2A — Wire Tasks/Bookings (No Gateway Yet)

_(Note: This is the first phase that touches Flutter code. Phase 1 is DB/RPC only)._

#### 2A.1 Goal

Connect bookings + task_requests + wallet with the payment events only:

- escrow_hold
- release_with_fee
- refund
- wallet lock (withdrawal_request) via Withdrawal screen/service

#### 2A.2 Deliverables (Detail)

**2A.2.1 Flutter / App Calls (Exact variable names)**
Generate idempotency (CRITICAL: Must be deterministic, not random UUIDv4 to survive app crashes)

- variable: idempotencyKey
- type: String
- format: UUIDv5(NAMESPACE, `${booking_id}_${event_type}`)

RPC call payload keys (FINAL)

- p_event_type
- p_related_entity_type
- p_related_entity_id
- p_idempotency_key
- p_amount_gross
- p_currency
- p_meta

**2A.2.2 Actor + Gate Rules (in RPC)**
RPC must verify:

- actor = auth.uid()
- entity status + payment_status

Booking escrow_hold

- booking.status == "pending"
- booking.payment_status == "unpaid"
- actor role = client (owner of booking as client)

Booking release_with_fee

- booking.status == "delivered"
- booking.payment_status == "held"
- actor = client

Booking refund

- booking.payment_status == "held"
- status allowed by policy: declined | canceled | expired_unanswered | dispute_refund
- actor allowed: provider OR system OR dispute_authority (system only from backend cron/edge)

**2A.2.3 Ensure Safe Financial Math (RPC Source of Truth)**
Gross amounts must be read directly from the Database entity during the SELECT ... FOR UPDATE row lock so Flutter doesn't send fake amounts.

- `v_entity_amount_gross` = row.amount_gross.
- Compare with `p_amount_gross` from client, throw `ERR_AMOUNT_MISMATCH` if not equal.

**2A.2.4 Meta fields mandatory inside journal_entries.meta**
For release_with_fee

- fee_rate_bps
- fee_amount
- gross_amount

---

#### 2A.3 Gate 100% (Phase 2A)

**Testing Setup & Gates:**

- **Test Script Name**: `test_phase2a_integration.dart`
- **DB Scenarios:**
  - escrow_hold fails without sufficient balance (Expected: `ERR_INSUFFICIENT_FUNDS`)
  - release fails before delivered (Expected: `ERR_GATE_NOT_ALLOWED`)
  - refund fails without held (Expected: `ERR_GATE_NOT_ALLOWED`)
  - same idempotencyKey twice gives the same result.
- **Verification Query:** `SELECT * FROM audit_logs WHERE action IN ('payment.escrow_hold', 'payment.release_with_fee', 'payment.refund')`

**Gate UI (Mandatory)**

- **Every Booking Card and Task Card:**
  - Exact same state shows the exact same button (no variation between views).
  - No button appears in the wrong state.
- **Wallet Screen:**
  - No "Deposit" button at all.
  - "Request Withdrawal" creates a `withdrawal_request` and locks funds (available decreases, pending increases).
- **UI State Required Tests:**
  1. `pending` + `unpaid` → shows **Escrow** CTA
  2. `delivered` + `held` → shows **Release** CTA
  3. `declined` + `held` → shows **Refund** CTA
  4. `active` + `held` → **No Button** (only informative badge based on R.3)

#### 2A.4 Dashboard Financial Wiring

Ensure all Dashboard queries in (Phase 2A) depend entirely on `vw_financial_metrics_realtime` and `vw_financial_metrics_period`, and do not depend on counting from `tasks/bookings`.

#### 2A.5 Rollback (Phase 2A)

- revert app commit
- RPC remains but not invoked

---

### Phase 2B — Gateway Integration — DEFERRED [LATER - NOT MVP]

#### 2B.1 Goal

Make wallet become "actual":

- deposit enters real money
- withdrawal takes out real money (prepare it)

#### 2B.2 Deliverables (Edge Function + Secrets + Mapping)

**2B.2.1 Edge Function Names**

- function: qicard_webhook_handler

**2B.2.2 Env Vars (Exact names)**

- QICARD_TERMINAL_ID
- QICARD_BASIC_AUTH
- QICARD_RSA_PUBLIC_KEY_PEM
- QICARD_PROVIDER_NAME = "qicard"

**2B.2.3 Webhook Request Handling (Exact variables)**

- header: X-Signature → variable: signatureHeader
- body raw bytes → variable: rawBody
- parsed json → variable: payload
- psp_event_id → variable: pspEventId
- payment_id → variable: pspPaymentId
- request_id → variable: pspRequestId
- status → variable: pspStatus
- amount → variable: amount
- currency → variable: currency

Deterministic idempotency_key (Stable Mapping)

- variable: idempotencyKey
- value: `qicard:<payment_id>:<event_type>:<status>` (Prevents Collision if event_id is not unique across status)

**2B.2.4 journal_entries.meta required keys**

- psp_provider
- psp_event_id
- psp_payment_id
- psp_request_id
- psp_status
- psp_timestamp

#### 2B.3 Gate 100% (Phase 2B)

- Wrong signature → reject
- Same webhook twice → only writes once
- platform_cash is reconcilable (initial reconciliation)

#### 2B.4 Rollback (Phase 2B)

- Disable webhook endpoint
- Doesn't affect internal payments

---

## Phase 3 — Backfill/Cutover + Monitoring — DEFERRED [LATER - NOT MVP]

### 3.1 Deliverables (Detail)

**3.1.1 Backfill (Legacy to Ledger)**

- source: wallet_transactions
- target: journal_entries + ledger_lines
- meta keys:
  - legacy_source="wallet_transactions"
  - legacy_tx_id
  - legacy_type
  - timestamps

**3.1.2 Freeze legacy writes**

- trigger: trg_wallet_transactions_freeze
- behavior: block INSERT/UPDATE/DELETE

**3.1.3 Flutter Cutover**

- Wallet reads:
  - vw_wallet_balances_user
  - vw_wallet_activity_user
- Booking/Task writes:
  - process_payment_event_ledger only

**3.1.4 Monitoring (Event names)**

- audit action names:
  - payment.escrow_hold
  - payment.release_with_fee
  - payment.refund
  - gateway.deposit
  - gateway.withdrawal_complete
  - gateway.withdrawal_failed

### 3.2 Gate 100% (Phase 3)

- legacy wallet_balances == new vw_wallet_balances_user (sample 100)
- platform_escrow outstanding == total held obligations
- legacy writes blocked
- E2E sandbox (Payment-Only No Gateway): admin_credit → Escrow Hold → Release With Fee → Refund. Each step: balanced journal, audit log, correct statuses.

### 3.3 Rollback (Phase 3)

- disable freeze trigger
- revert app
- Any discrepancy is corrected with compensating journals only.

---

Clear Note
This plan is "extremely detailed" and includes all the strict addendums integrated below.

---

## ✅ ADDENDUM A — Naming Convention (Everything must be fixed)

### A.1 SQL Object Naming Rules

- **Tables:** `snake_case`
- **Views:** Starts with `vw_`
- **Functions/RPC:** `fn_` (optional) or clear name like `process_payment_event_ledger`
- **Triggers:** `trg_<table>_<purpose>`
- **Indexes:** `idx_<table>_<cols>`
- **Constraints:** `ck_`, `uq_`, `fk_`

---

## ✅ ADDENDUM B — Strict Enums (To prevent random text)

### B.1 Enums (Recommended)

**B.1.1 ledger_direction_enum**

- DEBIT
- CREDIT

**B.1.2 ledger_account_type_enum**

- asset
- liability
- revenue
- expense
- equity

**B.1.3 payment_event_type_enum**

Internal payment events (NOW)

- escrow_hold
- release_with_fee
- refund
- withdrawal_request

Deferred events (LATER)

- deposit
- withdrawal_complete
- withdrawal_failed

_(Rule: In MVP, RPC strictly rejects any event_type in: deposit, withdrawal_complete, withdrawal_failed)_

System/Reserved

- admin_credit
- admin_adjustment
- reversal

**B.1.4 related_entity_type_enum**

- booking
- task_request
- withdrawal_request
- admin_adjustment

---

## ✅ ADDENDUM C — Constraints & Indexes (With exact names)

### C.1 accounts constraints/indexes

**Constraints**

- `uq_accounts_account_code` UNIQUE(account_code)
- `ck_accounts_currency_iqd` CHECK(currency = 'IQD')
- `ck_accounts_owner_validity` CHECK(
  (owner*id IS NULL AND account_type IN ('asset', 'liability', 'revenue', 'expense', 'equity') AND account_code NOT LIKE 'user*%') OR
  (owner*id IS NOT NULL AND account_code LIKE 'user*%:%')
  )

**Indexes**

- `idx_accounts_owner_id` ON(owner_id)

### C.2 journal_entries constraints/indexes

**Constraints**

- `uq_journal_entries_idempotency_key` UNIQUE(idempotency_key)
- `ck_journal_entries_currency_iqd` CHECK(currency = 'IQD')
- `ck_journal_entries_entity_type_allowed` CHECK(related_entity_type in ('booking','task_request','withdrawal_request','admin_adjustment'))
- `ck_journal_entries_entity_null_pair` CHECK( (related_entity_type IS NULL AND related_entity_id IS NULL) OR (related_entity_type IS NOT NULL AND related_entity_id IS NOT NULL) )
- `ck_journal_entries_event_type_allowed` CHECK(event_type in ('escrow_hold','release_with_fee','refund','deposit','withdrawal_request','withdrawal_complete','withdrawal_failed','admin_credit','admin_adjustment','reversal'))
- `ck_journal_entries_status_allowed` CHECK(status IN ('posted', 'voided'))

**Indexes**

- `idx_journal_entries_entity` ON(related_entity_type, related_entity_id)
- `idx_journal_entries_event_type` ON(event_type)
- `idx_journal_entries_status` ON(status)
- `idx_journal_entries_created_at` ON(created_at)
- `uq_journal_entries_single_reversal` UNIQUE INDEX ON ((meta->>'reversal_of_journal_entry_id')) WHERE meta->>'reversal_of_journal_entry_id' IS NOT NULL

### C.3 ledger_lines constraints/indexes

**Constraints**

- `ck_ledger_lines_amount_positive` CHECK(amount > 0)
- `ck_ledger_lines_currency_iqd` CHECK(currency = 'IQD')
- `ck_ledger_lines_direction_allowed` CHECK(direction in ('DEBIT','CREDIT'))

**FKs**

- `fk_ledger_lines_journal_entry` (journal_entry_id → journal_entries.id)
- `fk_ledger_lines_account` (account_id → accounts.id)

**Indexes**

- `idx_ledger_lines_journal_entry_id` ON(journal_entry_id)
- `idx_ledger_lines_account_id` ON(account_id)
- `idx_ledger_lines_created_at` ON(created_at)

### C.4 audit_logs constraints/indexes

**FKs**

- `fk_audit_logs_journal_entry` (journal_entry_id → journal_entries.id)

**Indexes**

- `idx_audit_logs_actor_user_id` ON(actor_user_id)
- `idx_audit_logs_journal_entry_id` ON(journal_entry_id)
- `idx_audit_logs_created_at` ON(created_at)

---

## ✅ ADDENDUM D — Triggers (With exact names + on which tables)

### D.1 Append-only triggers (STRICT)

- `trg_journal_entries_append_only`: ON journal_entries BEFORE UPDATE OR DELETE → RAISE EXCEPTION
- `trg_ledger_lines_append_only`: ON ledger_lines BEFORE UPDATE OR DELETE → RAISE EXCEPTION
- `trg_accounts_append_only` (Optional): ON accounts BEFORE UPDATE OR DELETE → RAISE EXCEPTION

### D.2 Freeze legacy trigger (Phase 3)

- `trg_wallet_transactions_freeze`: ON wallet_transactions BEFORE INSERT OR UPDATE OR DELETE → RAISE EXCEPTION

---

## ✅ ADDENDUM E — Actor Model (With exact names + how to verify)

### E.1 Actor Types (Inside RPC)

- `v_actor_user_id` = auth.uid()
- `actor_role` (derived) one of:
  - client
  - provider
  - system (RPC invoked by service role/Edge Function/cron. Cannot be triggered by Flutter)
  - dispute_authority

### E.2 How to decide client/provider?

Booking must contain clear fields:

- `bookings.client_id`
- `bookings.provider_id` (nullable until acceptance)
- `bookings.status`
- `bookings.payment_status`

Task request also:

- `task_requests.client_id`
- `task_requests.provider_id`
- `task_requests.status`
- `task_requests.payment_status`

**RPC Gate Rule:**

- If `auth.uid() == bookings.client_id` → actor_role = client
- If `auth.uid() == bookings.provider_id` → actor_role = provider

**System Actor Logic & `created_by`:**

- For operations performed by the system (edge functions/cron) `auth.uid()` will be null or service request.
- `created_by` is recorded either as `auth.uid()` (for client/provider events initiated from Flutter) or left `NULL` for system events.
- Internally, written in audit `meta`: `{"created_by_type": "user" | "system", "created_by_source": "flutter" | "edge" | "cron"}`

---

## ✅ ADDENDUM F — Fee Policy (To avoid calculation discrepancies)

### F.1 Fee inputs

Inside `p_meta` or fixed config:

- `fee_rate_bps` (basis points) example 1000 = 10%

---

## ✅ ADDENDUM G — Views: "How they are calculated" (To avoid discrepancies)

### G.1 Balance semantics (Binding)

- **Asset:** balance = SUM(DEBIT) - SUM(CREDIT)
- **Liability/Revenue:** balance = SUM(CREDIT) - SUM(DEBIT)

### G.2 vw_wallet_balances_user computation

- `available_balance` = balance(account_code = user_available:{auth.uid()})
- `pending_withdrawal_balance` = balance(account_code = user_pending_withdrawal:{auth.uid()})
- `held_balance` = calculated only from events related to entity and with client_id = auth.uid() and excludes any escrow not belonging to them.
  - SUM of `escrow_hold` gross - SUM of `refund`/`release` gross for bookings/task_requests where `client_id = auth.uid()`.

---

## ✅ ADDENDUM H — RPC: ERROR CODES

### H.1 Error Messages (Exact)

- `ERR_MISSING_IDEMPOTENCY_KEY`: "Idempotency key is required."
- `ERR_IDEMPOTENCY_REPLAY`: (Internal handling to return existing journal_entry_id)
- `ERR_GATE_NOT_ALLOWED`: "Event not allowed for current status/payment_status/actor."
- `ERR_INSUFFICIENT_FUNDS`: "Insufficient available balance."
- `ERR_UNBALANCED_JOURNAL`: "Journal is not balanced."
- `ERR_CURRENCY_MISMATCH`: "Currency mismatch."
- `ERR_ENTITY_NOT_FOUND`: "Related entity not found."
- `ERR_AMOUNT_MISMATCH`: "Client amount does not match entity amount."

---

## ✅ ADDENDUM I — Given / When / Then Tests (Full Detail)

### I.1 escrow_hold — success

**Given**

- booking.status = pending
- booking.payment_status = unpaid
- booking.client_id = U1
- user_available(U1) = 100000
- booking.amount_gross = 25000 (v_entity_amount_gross)

**When**

- U1 calls RPC with:
  - p_event_type = escrow_hold
  - p_related_entity_type = booking
  - p_related_entity_id = booking_id
  - p_idempotency_key = K1

**Then**

- journal_entries inserted (event_type escrow_hold)
- ledger_lines inserted:
  - DEBIT user_available:U1 amount 25000
  - CREDIT platform_escrow amount 25000
- booking.payment_status becomes held
- audit_logs row created with action payment.escrow_hold

### I.2 escrow_hold — insufficient funds

**Given**

- user_available(U1) = 1000
- booking.amount_gross = 25000 (v_entity_amount_gross)

**When**

- call escrow_hold

**Then**

- RPC returns ERR_INSUFFICIENT_FUNDS
- no journal inserted
- no entity update

### I.3 escrow_hold — idempotency replay

**Given**

- K1 already processed for same action

**When**

- call again with same K1

**Then**

- returns ok=true + original journal_entry_id
- no new journal/lines

### I.4 release_with_fee — success

**Given**

- booking.status = delivered
- booking.payment_status = held
- booking.client_id = U1
- booking.provider_id = U2
- gross = 25000, fee_rate_bps=1000 → fee=2500 → net=22500

**When**

- U1 calls release_with_fee with K2

**Then**

- ledger_lines:
  - DEBIT platform_escrow 25000
  - CREDIT user_available:U2 22500
  - CREDIT platform_revenue 2500
- booking.payment_status = released
- booking.status = completed
- audit action payment.release_with_fee

### I.5 release_with_fee — gate fail (not delivered)

**Given**

- booking.status = active

**When**

- U1 calls release_with_fee

**Then**

- ERR_GATE_NOT_ALLOWED
- no journal written

### I.6 refund — success (provider/system)

**Given**

- booking.payment_status = held
- status allowed by policy: declined (or expired)
- client = U1

**When**

- provider U2 (or system) calls refund with K3

**Then**

- ledger_lines:
  - DEBIT platform_escrow gross
  - CREDIT user_available:U1 gross
- booking.payment_status = refunded
- status updated according to rule (declined/expired/etc.)
- audit action payment.refund

### I.7 refund — fail if payment_status != held

**Given**

- payment_status = unpaid OR released

**When**

- refund

**Then**

- ERR_GATE_NOT_ALLOWED

### I.8 Concurrency test (double click escrow_hold)

**Given**

- same booking_id, K4 and K5 two requests at the same moment

**When**

- call1 + call2 concurrently

**Then**

- one takes lock and executes
- the second waits, and after the first finishes:
  - either gate fails (payment_status became held)
  - or returns noop if same key
- result: only one journal entry written

---

## ✅ ADDENDUM J — RPC Signature Hardening (Anti-Spoof)

### J.1 Rule (Binding)

- The RPC MUST NOT accept `p_actor_user_id` from the client.
- The actor identity MUST be derived inside the RPC only:
  - `v_actor_user_id := auth.uid()`

### J.2 Updated RPC Params (Final)

- `p_event_type` (text)
- `p_related_entity_type` (text)
- `p_related_entity_id` (uuid)
- `p_idempotency_key` (text)
- `p_amount_gross` (numeric)
- `p_currency` (text, default 'IQD')
- `p_meta` (jsonb, default '{}')

### J.3 Client payload keys (Final)

Client is only allowed to send:

- `p_event_type`
- `p_related_entity_type`
- `p_related_entity_id`
- `p_idempotency_key`
- `p_amount_gross`
- `p_currency`
- `p_meta`

---

## ✅ ADDENDUM K — Correct Execution Order (Race-Safe)

### K.1 Entity-based events (booking/task_request)

For events that mutate an entity (escrow_hold, release_with_fee, refund):

1. `SELECT ... FOR UPDATE` the entity row
2. Validate gate (status/payment_status/actor role)
3. Idempotency check (key exists?)
4. Funds check (if required)
5. Write journal + lines
6. Audit log
7. Update entity
8. Commit

### K.2 Webhook-only events (deposit/withdrawal outcomes)

1. Idempotency check (key exists?)
2. Write journal + lines
3. Audit log
4. Commit

---

## ✅ ADDENDUM L — Entity Preconditions (Schema Requirements)

### L.1 bookings required columns (must exist before Phase 2A)

- `bookings.id`
- `bookings.client_id`
- `bookings.provider_id` (nullable allowed)
- `bookings.status`
- `bookings.payment_status`
- `bookings.amount_gross` OR an equivalent source for p_amount_gross

### L.2 task_requests required columns

- `task_requests.id`
- `task_requests.client_id`
- `task_requests.provider_id` (nullable allowed)
- `task_requests.status`
- `task_requests.payment_status`
- `task_requests.amount_gross` OR equivalent

If any column is missing, a migration MUST be executed before Phase 2A begins.

---

## ✅ ADDENDUM M — Fee Policy Finalization (IQD Rounding)

### M.1 Fee rounding rule (Binding, BPS strictly)

Because IQD has no fractional units in our MVP:

- `fee_amount` = floor((gross_amount \* fee_rate_bps) / 10000)
- `net_amount` = gross_amount - fee_amount

### M.2 Required meta on release_with_fee

Fee rate is stored in `p_meta.fee_rate_bps` sourced from server config/backend context, NEVER trusted from UI input.

- `fee_rate_bps`
- `fee_amount`
- `gross_amount`
- `net_amount`
- `rounding_policy = "floor"`
- `client_id`
- `provider_id`

---

## ✅ ADDENDUM N — Journal Status + Voiding (Ledger Hygiene)

### N.1 Add status to journal_entries

Add column:

- `status` (text): `posted` | `voided`
  Default: `posted`

### N.2 Rule

- Only `posted` journals are included in balances and metrics.
- `voided` journals remain immutable (append-only) and are excluded from calculations.

---

## ✅ ADDENDUM O — Reversal Protocol (Compensating Journals Only)

### O.1 Rule (Binding)

No mutation is allowed for historical records.
Any correction MUST be done via a new compensating journal.

### O.2 Required meta keys for reversals

For any reversal journal:

- `reversal_of_journal_entry_id` (uuid)
- `reversal_reason` (text)

### O.3 Allowed reversal event types

- `admin_adjustment`
- `reversal`

---

## ✅ ADDENDUM P — Performance Strategy for Held Balance

### P.1 MVP Approach

`held_balance` can be computed live from entity-linked events:

- SUM `escrow_hold` - SUM (`refund` + `release`) for entities where `client_id = auth.uid()`

### P.2 Scale Approach (Reserved)

If performance degrades:

- Introduce materialized view or daily snapshot table for held balance and financial metrics.
- Snapshots must still be derived ONLY from `posted` ledger tables entries.

---

## ✅ ADDENDUM Q — Test Funding (No-Gateway Bootstrap)

### Q.1 Add platform test account

Add platform account:

- `platform_test_float` (account_type = asset)

### Q.2 Add reserved event

Add reserved event type:

- `admin_credit`

### Q.3 Journal lines for admin_credit (testing only)

- DEBIT `platform_test_float` amount = X
- CREDIT `user_available:{user_id}` amount = X

### Q.4 Gate

- This event can be executed ONLY by system/service role (never from Flutter).

---

## ✅ ADDENDUM R — UI Wiring Contract (Mandatory)

### R.1 Screens that MUST exist (or be created)

- **Wallet Screen:**
  - shows `available_balance`, `held_balance`, `pending_withdrawal_balance`
  - activity list from `vw_wallet_activity_user`
- **Booking Details Screen:**
  - shows booking_id, client_id, provider_id (nullable), status, payment_status, amount_gross, currency
  - buttons: escrow/release/refund based on exact rules
- **Task Request Details Screen (or Work Item Details):**
  - shows task_request_id, task_id, client_id, provider_id, status, payment_status, amount_gross, currency
  - buttons: escrow/release/refund based on exact rules
- **(Optional) Withdrawal Request Screen:**
  - create withdrawal_request
  - list pending requests

### R.2 Repositories/Services MUST use views/RPC only

- **WalletService** reads:
  - `vw_wallet_balances_user`
  - `vw_wallet_activity_user`
- **BookingService / TaskService** calls:
  - `process_payment_event_ledger`
- **WithdrawalService** calls:
  - request_withdrawal (either same RPC with event_type=withdrawal_request or a dedicated RPC)

### R.3 "No missing state" rule

If UI doesn't know how to represent a specific state combination (e.g., payment_status=held but status=active), you must:

- Show a clear badge
- Add a simple explanatory text
- NEVER show an incorrect CTA

### R.4 Unified Work Item mapping (`vw_unified_payable_items`)

To avoid duplicating logic across Booking Cards and Task Request Cards, map both to a single Unified Payable Item view so Cards can use one DTO:

- `vw_unified_payable_items` should return:
  - entity_type (booking | task_request)
  - entity_id
  - client_id
  - provider_id
  - status
  - payment_status
  - amount_gross
  - currency

### R.5 UI Action Mapping (Strictly tied to conditions)

- **Escrow Hold (Client)**
  - shows only if: `status = pending`, `payment_status = unpaid`, `actor = client`
- **Release With Fee (Client)**
  - shows only if: `status = delivered`, `payment_status = held`, `actor = client`
- **Refund (Provider/System)**
  - shows only if: `payment_status = held`, status allowed by policy (declined/canceled/expired/dispute_refund), `actor = provider` (or system)

---

## ✅ ADDENDUM S — Unified CTA Resolver

To prevent divergence between `booking_card`, `dashboard_card`, and `task_card`, there must be a single unified function in the front-end that determines the buttons.

- **Function Signature Idea:** takes `(status, payment_status, actor_role, entity_type)`
- **Returns:** `allowed_actions[]` + `badge_text`
- **Rule:** Exact same state MUST ALWAYS return the exact same button array and badge.

---

## ✅ ADDENDUM T — No Deposit UI Rule

- **Rule:** It is strictly prohibited in the current MVP to show any of the following triggers/buttons anywhere in the UI or Navigation:
  - Deposit button
  - Add funds button
  - Top up button

---

## ✅ ADDENDUM U — Withdrawal UI (Lock Only)

- Inside the **Wallet Screen**:
  - `Request Withdrawal` strictly creates a `withdrawal_request` event, decreasing `available_balance` and increasing `pending_withdrawal_balance` (locking funds internally).
  - There is absolutely NO `complete` or `failed` manual UI anywhere in the app to represent external withdrawal transitions for the MVP.
  