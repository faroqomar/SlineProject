# FULL REPORT: 24 Hardened Payment Linking System

## 0) Skill Selection

- **Skills selected**: Evidence-First Reading, Threat Modeling (Security), Invariants & Contracts, Idempotency & Concurrency, DB-First Financial Modeling, RLS & Privilege Boundaries, Diagram Crafting.
- **Why these fit**: This is the single choke point where external money turns into internal SLine data. If webhooks are spoofed, hackers get free services. If signatures don't match, legitimate payments are lost. Threat modeling the connection between Gateway and Ledger is critical.
- **Skills not used**: Repo Mapping (Focus is strictly architectural behavior).

## 1) Folder Identity

- **Folder name + path**: `.TODO/improvement_the_system/24_hardened_paymentLinking_system`
- **What system/feature it describes**: A Defensive Payment Orchestration Layer bridging QiCard (or any provider) with SLine's internal Ledger. It acts as an audit gate to ensure every incoming webhook maps explicitly to a requested intent.
- **Entities involved**: `payment_intents` (table), `payment_events`, `orphan_payments`, Webhooks, `process_payment_event_ledger`.

## 2) Human Explanation

Before sending a user to the Gateway, the SLine App asks its backend (BFF) for permission to checkout. The server locks the entity (Booking/Task), records exactly how much it expects (`payment_intents`), and signs the amount with an HMAC secret. The user pays on QiCard. QiCard sends a webhook successfully. SLine catches the webhook (`payment_events`), validates the amount against the saved intent, and applies it to the Ledger. If the amount is short or the signature missing, it's dumped into `orphan_payments` for manual review, and the system denies the service.

## 3) Symbol Legend

- **Rectangles**: Backend for Frontend (BFF), Payment Gateway, Ledger RPC.
- **Solid Arrows**: Execution paths.
- **Dashed Logic**: Quarantine and Webhook validation.

## 4) Extracted Contracts & Invariants

1. **Uniqueness**: Each `payment_intent` binds exactly 1 entity per attempt.
2. **Amount Match**: Webhook incoming payment `amount` MUST == `intent.expected_amount` perfectly.
3. **Ledger Link Requirement**: Every successful webhook must generate an idempotent call to `process_payment_event_ledger` referencing the intent UUID.
4. **Append-Only Audits**: `payment_events` must be immutable to satisfy third-party payment audits.

## 5) Conflict Scan Results

### 5.1 Naming Drift

- **Conflict**: Relying explicitly on `process_payment_event` without the `_ledger` designation.
- **Resolution**: Point strictly at the v2.16 `_ledger` compliant variant. Note that the DB schema logic enforces this.

### 5.2 Logic Drift

- **Conflict**: Clients generating URLs themselves.
- **Resolution**: Strict server-side intent creation. No client-generated IDs for payments allowed.

### 5.3 Data Model Drift

- None detected. `payment_intents`, `payment_events`, and `orphan_payments` tables mapped correctly for production deployment.

## 6) Security & Failure Modes (Adversarial)

- **Amount Tampering**: Attacker intercepts checkout redirect, changes amount to 50 IQD instead of 5,000,000.
  - _Mitigation_: Webhook validation catches the mismatch between `intent.expected` and `webhook.paid`. Event is binned into `orphan_payments`. Booking isn't fulfilled.
- **Webhook Replay (Double Process)**: Gateway network hiccups and sends the exact same "Success" webhook three times in two seconds.
  - _Mitigation_: The `payment_intents` table tracks status. If `succeeded` already, the second webhook is safely ignored.

## 7) UI Mapping

### 7.1 Mobile App UI

- **Screens**: Checkout Buttons for Tasks, Bookings, Direct Offers.
- **States**: Rendering blocking "Generating Secure Payment Link..." spinner.
- **Guardrails**: Redirect to Gateway WebView and poll local API for status loop.

### 7.2 Admin Dashboard UI

- **Pages**: Orphaned Payments View, Dispute Reconciliation.
- **Metrics**: Count of `orphan_payments` (high count = attack ongoing).
- **Drilldowns**: Ability to manually assign an orphan payment to a target intent if there was a known fractional gateway error.

### 7.3 Implementation Hooks

- `PaymentIntentService` (Edge/BFF). `WebhookHandler`.

## 8) Diagram Verdict + Best Diagram Type

- **Score now**: 10/10 (Post-fixes)
- **Best Diagram Type**: Sequence Diagram mixed with State Transitions mapping exactly to the backend gateway validation.

## 9) Upgrade Plan

- **Phase 0: Observability**: Configure Supabase alerts for frequent `orphan_payments` triggers.
- **Phase 1: Contracts**: Rollout schema definitions (`payment_intents`, `events`, `orphans`). Set RLS to allow only `service_role` (Edge Functions) to INSERT into these.
- **Phase 2: Hardening**: Add HMAC-SHA256 signature logic to the payment intent generator to assure URL parameters weren't modified on the wire.
- **Phase 3: Integration**: Update the Ledger RPC to explicitly map to the created `payment_intent_id`.

## 10) Risks

### 10.1 Risks if current version kept

- **Payer Spoofing**: Without Intents, SLine is reliant entirely on potentially mutable metadata returning from the external gateway, enabling massive fraud vectors.

### 10.2 Risks introduced by fixes

- **Legacy Migrations**: Existing active jobs without an Intent structure. _Mitigation_: Allow 1-time fallback overrides purely during the phased rollout block.

## 11) Test Plan (High-value)

- **Security Check**: Attempt to forge a webhook matching an existing pending intent but specifying half the required price -> Assert moves to `orphan_payments`.
- **Integrity**: Send 5 consecutive success webhooks for the same Intent -> Assert exactly 1 Ledger `journal_entry` is generated.

## 12) Production Checklist

- [ ] Validation amounts block discrepancies.
- [ ] RLS explicit lockdowns on financial tables.
- [ ] Webhooks utilize idempotency paths strictly.
