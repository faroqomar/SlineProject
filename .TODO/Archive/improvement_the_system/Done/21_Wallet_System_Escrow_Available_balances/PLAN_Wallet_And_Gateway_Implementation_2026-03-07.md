# 📌 Plan: Wallet UI & Hardened Gateway Implementation

## 1) Goal

- **Goal:** Implement the "Unified Golden Path" for the Wallet System and Hardened Payment Gateway according to the Diagram Consistency Audit (Diagrams 21-24 and Master Report).
- **Why:** To resolve payment ambiguity, protect against gateway webhook failures during app crashes, and deliver the final Wallet UI / Admin Finance dashboards.
- **Result:** A production-ready, append-only, idempotent financial ledger connected to a tamper-proof payment intent system (no direct client gateway access) and fully visualized in the Flutter Wallet Tab and Admin Finance Views.

## 2) Scope

### In-Scope

- Creating the Hardened Payment Linking tables (`payment_intents`, `payment_events`, `orphan_payments`).
- Implementing the Server/Edge Webhook handlers (`create_payment_intent`, `finalize_payment_webhook`).
- Wiring the Flutter Wallet Tab to `vw_wallet_balances_user` and `vw_wallet_activity_user`.
- Building Admin Finance Views (`vw_admin_finance_metrics`, `vw_admin_booking_finance`, `vw_admin_escrow_open`).
- Wiring flutter app "Pay" buttons to the `create_payment_intent` server logic instead of client-side gateway calls.

### Out-of-Scope

- Implementing the complete Withdrawals feature (gateways for paying out freelancers), which remains scheduled for a future phase.
- Modifying identity, task, or booking core state machines beyond their integration with payments.

## 3) Evidence & Findings (From Scan)

### Existing

- `process_payment_event_ledger` RPC exists.
- `rpc_approve_delivery` RPC exists.
- `platform_settings` table exists.
- `availability_slots` exists.
- User views `vw_wallet_balances_user` and `vw_wallet_activity_user` exist.

### Missing

- Tables: `payment_intents`, `payment_events`, `orphan_payments`.
- Edge Functions / RPCs: `create_payment_intent`, `finalize_payment_webhook`.
- Admin Finance Views: `vw_admin_finance_metrics`, `vw_admin_booking_finance`, `vw_admin_escrow_open`.
- Strict UI wiring ensuring the Flutter app _never_ initiates a gateway session directly.

### Conflicts / Risks

- **Admin vs Config Risk:** Older code may still reference `system_config` for fees. All new code MUST use `platform_settings.fee_rate_default_bps` per Diagram 22.
- **Client Finalization Risk:** Ensuring the existing UI completely drops any optimistic "payment success" state changes in favor of waiting for the webhook to finalize.

## 4) System Impact Map

- **UI:** Flutter Wallet Tab (Freelancer/Client), Payment Checkout Screens (replace direct gateway with server intent).
- **MVVM/App Logic:** Services must call new Edge Functions for intents. ViewModels must handle pending/webhook polling states.
- **Database:** New payment linking tables and Admin aggregation views.
- **RLS/Security:** `payment_events` and `payment_intents` must be strictly secured.
- **Realtime/Notifications:** Webhook success should trigger a realtime payload to the app to unlock the UI.
- **Storage:** No impact.
- **Observability:** `orphan_payments` acts as the primary telemetry for broken payments.
- **Compatibility & Migration:** Existing in-flight payments must be handled or flushed before the strict intent system is enforced.
- **Contracts:** Flutter ↔ Server Webhook Contract (Diagram 24).

---

# ✅ Execution Phases (Checklist)

## Phase 0: Preconditions & Gates

> Primary: @Sentinel

### 0.1 Spec Lock

- [ ] (@Sentinel) Acceptance + non-regression list (measurable)
- [ ] (@Architect) Confirm Flutter modules/entry points for checkout replacement.
- **Verify (@Sentinel):** done-conditions + rollback triggers defined.

### 0.2 Threat Model (If sensitive/high-risk)

- [ ] (@ThreatModeler) Threat model + security requirements + negative checks for webhook spoofing.
- **Verify (@Sentinel):** Webhook HMAC signature validation is testable.

### 0.3 Contracts

- [ ] (@APIContract) Contract file for `create_payment_intent` Edge Function payload.
- **Verify (@Sentinel):** contract matches schema + shapes.

### 0.4 Feature Flag/Rollout

- [ ] (@Architect) Toggle strategy for the new payment gateway switch.
- **Verify (@Sentinel):** rollback path documented.

---

## Phase 1: Database & Security

> Primary: @Supabase_Ops

### 1.0 Live Supabase Confirmation (MANDATORY)

- [ ] (@Supabase_Ops) Re-scan for touched objects during migration.
- **Verify (@Sentinel):** drift + safe approach recorded.

### 1.1 Schema (Additive-first)

- [ ] (@Supabase_Ops) DDL for `payment_intents`, `payment_events`, `orphan_payments`.
- [ ] (@Supabase_Ops) DDL for Admin Views (`vw_admin_finance_metrics`, etc.).
- [ ] (@Supabase_Ops) Indexes aligned to gateway lookup (`gateway_intent_id`).
- **Verify (@Sentinel):** no leaks/breaks, naming consistent.

### 1.2 RLS

- [ ] (@Supabase_Ops) Policies for new payment tables (Append-only for events, Service-Role only for webhooks).
- [ ] (@Supabase_Ops) RLS check matrix file.
- **Verify (@Sentinel):** negative fails, positive passes.

### 1.3 Triggers/RPC / Edge Functions

- [ ] (@Supabase_Ops) Create/deploy `finalize_payment_webhook` (Edge Function or secure RPC) to handle HMAC verification and atomic ledger writes.
- **Verify (@Sentinel):** state rules enforced, idempotency holds.

---

## Phase 2: App Layer (MVVM)

> Primary: @Architect

### 2.1 Models & Contract Compliance

- [ ] (@Architect) Update models/DTOs for Payment Intent responses.
- **Verify (@Sentinel):** types/nullability match contract.

### 2.2 Services/Repositories

- [ ] (@Architect) Update `PaymentService` to call `create_payment_intent` instead of building gateway sessions locally.
- [ ] (@Architect) Add polling/realtime listener for payment completion.
- **Verify (@Sentinel):** RLS-safe, no UI→Supabase calls.

### 2.3 ViewModels

- [ ] (@Architect) Update `CheckoutViewModel` to manage the server-side intent state.
- [ ] (@Architect) Connect `WalletViewModel` to the existing `vw_wallet_balances_user` view.
- **Verify (@Sentinel):** recoverable state + correct transitions.

---

## Phase 3: UI (After logic)

> Primary: @Pixel

### 3.1 Wiring

- [ ] (@Pixel) Build/Refine the Wallet Tab using `WalletViewModel` (displaying Held, Available).
- [ ] (@Pixel) Update Checkout UI to reflect Secure Intent generation loading states.
- **Verify (@Sentinel):** stable UX on slow/empty data.

### 3.2 Polish

- [ ] (@Pixel) Micro-interactions for Wallet balance updates (glassmorphism cards).
- **Verify (@Sentinel):** no perf regression.

---

## Phase 4: QA + Security (MANDATORY)

> Primary: @Sentinel

### 4.1 Contract + Migration Checks

- [ ] (@Sentinel) Run migration verify queries to ensure intents table exists.
- **Verify (@Sentinel):** no mismatch.

### 4.2 Security + Abuse Tests

- [ ] (@Sentinel) Execute ThreatModeler negative checks (attempt to fire fake webhook).
- [ ] (@Sentinel) RLS leak audit on `payment_intents`.
- **Verify (@Sentinel):** unauthorized access impossible.

### 4.3 Functional QA

- [ ] (@Sentinel) Manual E2E script: Book task -> Pay -> Webhook -> Escrow Hold -> Deliver -> Approve -> Wallet Balance Updates.
- **Verify (@Sentinel):** no crashes, consistent behavior.

---

## Phase 5: Documentation Sync (MANDATORY)

> Primary: @DocsKeeper

- [ ] (@DocsKeeper) Update `DEVELOPER_GUIDE` to formally declare the Hardened Payment Linking as the active system.
- **Verify (@Sentinel):** docs match code + live DB reality.

---

## 7) Acceptance Criteria (MANDATORY)

- **Correctness:** All client-side checkout buttons successfully request an intent from the server.
- **Security:** Gateway events are strictly verified via HMAC signature before updating the ledger.
- **UX Stability:** The Wallet Tab correctly renders `Available` and `Held` sums matching the ledger views without client-side math.
- **Observability:** Invalid gateway payloads successfully route to the `orphan_payments` quarantine table.

## 8) Rollback Plan

- **DB:** Safe to leave new tables; disable the new webhook edge function and revert the flutter app to the previous checkout service logic.
- **App:** Retain old `CheckoutService` behind a feature flag for immediate fallback if the intent system fails in production.

## 9) References (From Scan)

- `Sline_everything/AppDigram/All_Diagrams/24_hardened_paymentLinking_system.md`
- `Sline_everything/AppDigram/All_Diagrams/21_Wallet_System_Escrow_Available_balances.md`
- `@mcp:supabase-mcp-server:` verification confirmed missing tables (`payment_intents`, `payment_events`, `orphan_payments`).
