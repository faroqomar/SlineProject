# @PlanCritic — Plan Auditor, Risk Predictor & Execution Gatekeeper

## A) Assumptions + Decision Needed (Blocking)

- **Assumption:** The payment gateway provides an HMAC signature in the webhook payload that can be validated against a server-side secret.
- **Assumption:** The `create_payment_intent` Edge Function will recalculate the `gross_amount` from the database entity (booking/task/offer) and _not_ trust any `amount` parameter sent by the client.
- **Decision Needed (Blocking): Webhook Secret Management**
  - _Missing:_ How the edge function securely accesses the gateway webhook secret.
  - _Options:_ (1) Hardcoded in edge function (Unsafe), (2) Supabase Vault, (3) Supabase Edge Function Environment Variables.
  - _Recommended:_ (3) Supabase Edge Function Environment Variables (`supabase secrets set`).
  - _Impact:_ The plan must include a step for DevOps/Supabase_Ops to set this secret before deployment.
- **Decision Needed (Blocking): Client-side Completion Signal**
  - _Missing:_ How does the client app know the webhook succeeded if they are waiting on a loading screen?
  - _Options:_ (1) `payment_intents` realtime subscription, (2) manual polling, (3) deep-link redirect from gateway.
  - _Recommended:_ (1) Supabase Realtime subscription on the `payment_intents` row.
  - _Impact:_ Phase 2 must explicitly wire a realtime listener for the intent status transition.

---

## B) Gate Status (Pass/Fail)

1.  **Data/Contracts Gate: ❌ FAIL**
    - _Reason:_ The schema for `payment_intents` and `payment_events` lacks explicit exact column definitions and idempotency constraints in the plan.
    - _Fix:_ Add explicit DDL generation step defining `gateway_intent_id` as UNIQUE and `signature` columns.
2.  **Security Gate: ❌ FAIL**
    - _Reason:_ Plan doesn't explicitly restrict client write access to `payment_intents`.
    - _Fix:_ Add explicit step ensuring RLS on `payment_intents` is `SELECT` only for the `payer_id`, and `INSERT/UPDATE` is restricted to service-role (Edge Functions) only.
3.  **Backend/API Gate: ❌ FAIL**
    - _Reason:_ Missing the server-side price calculation step. If the Edge Function trusts the client's requested price, users can spoof payment logic.
    - _Fix:_ `create_payment_intent` MUST SELECT the entity from the DB to determine the price and fee rate securely.
4.  **UI/Integration Gate: ❌ FAIL**
    - _Reason:_ The UI flow for waiting on the webhook relies on vague "loading states".
    - _Fix:_ Explicitly define a realtime listener in the ViewModel that pushes the user to a Success screen _only_ when `payment_intents.status == 'succeeded'`.
5.  **Release/QA Gate: ✅ PASS**
    - _Reason:_ E2E functional QA and ThreatModeler negative checks are included.

---

## C) Critical Gaps (Must-Fix)

- **Gap:** Trusting client amount.
  - **Why it breaks:** Client intercepts API call, sends `gross_amount = 1`, gateway charges 1, webhook validates 1 == 1, entity is marked paid.
  - **Fix:** Edge function `create_payment_intent` ignores client amount, queries DB for `booking.price` or `task.budget`, and computes the gross server-side.
  - **Owner:** @Supabase_Ops (RPC/Edge logic).
- **Gap:** Realtime Sync for Payment Success.
  - **Why it breaks:** User sits on endless spinner if gateway deep-link fails or webhook takes 5 seconds.
  - **Fix:** `CheckoutViewModel` subscribes to `payment_intents` table changes where `id = current_intent_id`.
  - **Owner:** @Architect.

---

## D) Invariants & Success Criteria (Non-Negotiable)

1.  **Invariant:** Single source of truth for payment transitions.
    - _Enforce:_ Client cannot `UPDATE bookings SET payment_status = 'held'`. Only `process_payment_event_ledger` RPC can do this, and only the Webhook Edge Function can call that RPC with the correct context.
    - _Verify:_ RLS policy on bookings/tasks denies UPDATE to `payment_status`.
2.  **Invariant:** Payment intents are immutable once gateway session is created.
    - _Enforce:_ DB Trigger blocks UPDATE to `gross_amount` or `fee_rate_locked` on `payment_intents`.
3.  **Invariant:** Webhook signatures must match.
    - _Enforce:_ Edge function crypto crypto.subtle.verify or equivalent HMAC payload check.

---

## E) Risk Register (Predict Problems)

| Risk                 | Where             | Probability | Impact | Blast radius   | Early signal                           | Prevention                                     | Fallback                             |
| :------------------- | :---------------- | :---------- | :----- | :------------- | :------------------------------------- | :--------------------------------------------- | :----------------------------------- |
| Webhook delayed/lost | Gateway ↔ Webhook | Med         | High   | Local          | Intent stuck in `gateway_created` > 1h | Reliable gateway choice                        | Escalate/Reconcile script            |
| App crashes mid-pay  | Client App        | High        | Low    | Local          | User reopens app                       | Webhook completes payload asynchronously       | User sees updated status upon reopen |
| Price mismatch       | Webhook Edge      | Low         | High   | Financial Loss | `orphan_payments` alerts               | Server calculates price during intent creation | Nullify payment, manual review       |

---

## F) Pre-Mortem (How this fails in real life)

- This fails when a user creates an intent, minimizes the app to pay, the webhook fires successfully, but when the user returns, the app UI doesn't know to refresh and shows "Payment Failed."
- This fails when a malicious user sends `gross: 10` to the edge function instead of `1000` and the edge function blindly signs it.
- This fails when DevOps forgets to set the gateway secret in the Supabase Edge Function environment, causing all webhooks to fail signature validation and land in `orphan_payments`.

---

# H) Corrected Plan (Execution-Ready, Gate-Based)

# 📌 Plan: Hardened Wallet & Gateway System Integration

## 1) Goal

- **Goal:** Implement the "Unified Golden Path" for the Wallet System and Hardened Payment Gateway.
- **Why:** To resolve payment ambiguity, protect against gateway webhook failures during app crashes, and deliver the final Wallet UI / Admin Finance dashboards.
- **Result:** A production-ready financial ledger connected to a tamper-proof payment intent system (no direct client gateway access) visualized in the Wallet Tab.

## 2) Scope

### In-Scope

- `payment_intents`, `payment_events`, `orphan_payments` DDL & RLS.
- Edge Webhooks (`create_payment_intent`, `finalize_payment_webhook`).
- Flutter Wallet Tab & Checkout logic.
- Admin aggregated views.

### Out-of-Scope

- Withdrawals feature.

## 3) System Impact Map

- **UI:** Flutter Wallet Tab, Refactored Checkout Screen.
- **MVVM:** `PaymentService`, `CheckoutViewModel` with strict realtime listeners.
- **Database:** 3 new tables, 3 new views.
- **RLS/Security:** Strict Service-Role boundaries for webhooks.
- **Observability:** `orphan_payments` telemetry.

---

# ✅ Execution Phases (Checklist)

## Phase 0: Test Infra & Preconditions

> Primary: @Sentinel

- [ ] (@Sentinel) Define acceptance test criteria.
- [ ] (@APIContract) Contract file for Edge Functions (defining inputs, strictly omitting `amount` from client inputs).
- [ ] (@Supabase_Ops) Set Webhook HMAC secret in Supabase Edge environments (`supabase secrets set GATEWAY_WEBHOOK_SECRET=xyz`).
- **GATE CHECK:** Secrets set? Contracts defined? **PASS/FAIL**

## Phase 1: Database, Contracts & Security

> Primary: @Supabase_Ops

- [ ] (@Supabase_Ops) DDL: Create `payment_intents` (id, entity_type, entity_id, payer_id, receiver_id, gross, fee_rate_locked, signature, gateway_intent_id, status:enum, idempotency_key:unique).
- [ ] (@Supabase_Ops) DDL: Create `payment_events` (append-only) and `orphan_payments`.
- [ ] (@Supabase_Ops) DDL: Create Admin Views (`vw_admin_finance_metrics`, `vw_admin_booking_finance`, `vw_admin_escrow_open`).
- [ ] (@Supabase_Ops) RLS: `payment_intents` (SELECT for payer_id, no client INSERT/UPDATE). `payment_events` (Service Role only). `orphan_payments` (Admin/Service Role only).
- **GATE CHECK:** DDL applied? RLS blocks client writes? **PASS/FAIL**

## Phase 2: Backend APIs (Edge Functions)

> Primary: @Supabase_Ops / @Architect

- [ ] (@Supabase_Ops) Edge Function: `create_payment_intent`. MUST query DB to calculate `gross_amount` and lock `fee_rate_default_bps`. MUST generate gateway session and return `checkout_url`.
- [ ] (@Supabase_Ops) Edge Function: `finalize_payment_webhook`. MUST verify HMAC signature. MUST execute `process_payment_event_ledger` via Service Role. MUST insert mismatches into `orphan_payments`.
- **GATE CHECK:** Edge functions deployed? HMAC verification tested with fake payload? **PASS/FAIL**

## Phase 3: Application UI Wiring

> Primary: @Architect & @Pixel

- [ ] (@Architect) `CheckoutViewModel.createIntent()`: Calls Edge Function, stores `payment_intent_id`.
- [ ] (@Architect) `CheckoutViewModel` realtime subscription: Listens to `payment_intents` where `id = target`. Upon `status == 'succeeded'`, triggers flow navigation.
- [ ] (@Pixel) Build/Refine the Wallet Tab using `WalletViewModel` (querying `vw_wallet_balances_user`).
- [ ] (@Pixel) Update Checkout UI to handle webview/external browser launch and await realtime success state.
- **GATE CHECK:** UI relies on realtime DB status rather than deep-link success? **PASS/FAIL**

## Phase 4: Polish, QA & Release

> Primary: @Sentinel

- [ ] (@Sentinel) E2E Test: Attempt to modify cart price client-side (verify Edge Function ignores it).
- [ ] (@Sentinel) E2E Test: Simulate valid webhook using service role. Verify Wallet UI updates balance automatically.
- [ ] (@Sentinel) Check `orphan_payments` logs for unexpected errors during testing.
- [ ] (@DocsKeeper) Document the new Payment Intent flow in DEVELOPER_GUIDE.md.
- **GATE CHECK:** Functional logic completely circumvents client tampering? **PASS/FAIL**

---

# I) Change Report (Diff-Style)

### 1) Original Issues

- Trusted client amounts in intent creation.
- Lacked explicit UI realtime syncing mechanism for payment completion.
- Missing specific security (RLS) enforcement on the new tables.
- Webhook secret management wasn't explicitly stated.

### 2) Added Steps

- Added step to register `GATEWAY_WEBHOOK_SECRET` in Supabase environments.
- Added strict constraint that `create_payment_intent` edge function calculates price via DB query, not client payload.
- Added explicit Realtime Subscription requirement in `CheckoutViewModel`.
- Explicitly defined RLS policies required for `payment_intents`.

### 3) Expanded Steps

- Expanded Edge Function tasks.

### 4) Why

- Prevents client-side price spoofing, fixes infinite loading spinners, strictly locks down the tables from malicious direct-API writes.

### 5) Residual Risks

- The gateway's deep linking back into the app might fail on some Android devices, placing heavy reliance on the realtime subscription to unlock the UI. Ensure a manual "I have paid, check status" refresh button exists as a fallback.
