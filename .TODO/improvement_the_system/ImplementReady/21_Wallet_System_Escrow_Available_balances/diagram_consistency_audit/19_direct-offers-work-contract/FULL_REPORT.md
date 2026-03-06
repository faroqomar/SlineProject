# FULL REPORT: 19 Direct Offers Work Contract

## 0) Skill Selection

- **Skills selected**: Evidence-First Reading, State Machine & Lifecycle, DB-First Financial Modeling, Threat Modeling (Security), Diagram Crafting.
- **Why these fit**: Direct Offers bypass normal Booking state machines. Modeling this requires strict observation of the DB triggers (`fn_direct_offer_guard`) and the exact Ledger transitions used for escrow vs non-escrow jobs.
- **Skills not used**: Repo Mapping.

## 1) Folder Identity

- **Folder name + path**: `.TODO/improvement_the_system/19_direct-offers-work-contract`
- **What system/feature it describes**: How users agree to work via Chat directly (without public tasks or availability slots).
- **Entities involved**: `direct_offers` (table), `fn_direct_offer_guard` (DB Trigger), `process_payment_event_ledger`.

## 2) Human Explanation

A Freelancer messages a Client and proposes a price/timeline. The `direct_offers` row is created as `sent`. The Client accepts it. Crucially, work _cannot_ begin until the Client places money in Escrow (`payment_status='held'`), shifting the offer to `active`. The Freelancer delivers the work. The Client releases funds via the standard Ledger service, finalizing the offer as `completed` and paying the Freelancer.

## 3) Symbol Legend

- **Rectangles**: Client Actions vs Freelancer Actions.
- **Solid Arrows**: State Transitions intercepted by the Postgres Guard.
- **Dashed Logic**: Financial Ledger calls driving the state.

## 4) Extracted Contracts & Invariants

1. **Initial State**: Offers strictly begin with `status='sent'` and `payment_status='unpaid'`.
2. **Escrow Lock**: Status CANNOT transition to `active` unless `payment_status` shifts to `held`.
3. **Delivery Authority**: Only the user mapping to `freelancer_id` can mark the offer `delivered`.
4. **Completion Lock**: Completion strictly hinges on the Ledger marking `payment_status='released'`.

## 5) Conflict Scan Results

### 5.1 Naming Drift

- **Conflict**: Broad usages of "approve delivery" implying usage of `rpc_approve_delivery`.
- **Resolution**: `direct_offers` are structurally distinct from `tasks`. Payment release MUST target the generic Ledger RPC wrapper.

### 5.2 Logic Drift

- **Conflict**: The legacy diagram hallucinated a flow where Delivery automatically bypassed the escrow.
- **Resolution**: Strictly map the `fn_direct_offer_guard` lines of SQL which require the 3-step Sent -> Held -> Completed dance.

### 5.3 Data Model Drift

- None detected within the schema itself, but app UI often mismanaged the intermediate 'accepted-but-unpaid' state.

## 6) Security & Failure Modes (Adversarial)

- **Work Before Pay**: Freelancer updates status to `active` without the Client paying.
  - _Mitigation_: The DB guard instantly aborts the transaction because `payment_status != 'held'`.
- **Self-Delivery Spoofing**: Client updates offer to `delivered` to force a refund state.
  - _Mitigation_: Guard explicitly checks `auth.uid() == freelancer_id` for delivery transitions.

## 7) UI Mapping

### 7.1 Mobile App UI

- **Screens**: Chat Thread (Rendered as an interactive bubble), "My Work" Unified View.
- **States**: Rendering distinct "Pay to Start" buttons vs "Awaiting Delivery" based on combination of `status` & `payment_status`.
- **Guardrails**: Adding timeouts to auto-cancel `sent` offers after 7 days to clear chat noise.

### 7.2 Admin Dashboard UI

- **Pages**: Direct Dispute Center.
- **Metrics**: Volume of un-actioned offers.

### 7.3 Implementation Hooks

- `DirectOffersService.createOffer()` -> Raw DB interaction.

## 8) Diagram Verdict + Best Diagram Type

- **Score now**: 9/10 (Post-fixes)
- **Best Diagram Type**: Sequence Diagram heavily focused on the DB Guard interactions breaking specific adversarial operations.

## 9) Upgrade Plan

- **Phase 0: Observability**: Ensure `source_id` properly maps these distinct IDs into unified dashboard lists.
- **Phase 1: Contracts**: Enforce client-side UI explicitly handles the `accepted` vs `active` visual split to encourage clients to pay Escrow.
- **Phase 2: Hardening**: Run unit tests on `fn_direct_offer_guard` against every permutation of illegal state skips.
- **Phase 3: Cleanup**: Build DB cron or Edge Function to garbage-collect stale `sent` offers.

## 10) Risks

### 10.1 Risks if current version kept

- **UI Abandonment**: Freelancers confused why work is accepted but they haven't been paid.

### 10.2 Risks introduced by fixes

- **Ledger Incompatibility**: If Ledger events aren't distinctly tagged for `direct_offers`, reconciliation fails. _Mitigation_: Strict ENUM typing for entity source types.

## 11) Test Plan (High-value)

- **Security**: As a standard user, attempt to update an unpaid `direct_offers` row `status='active'` -> Assert Guard fails.
- **Integration**: Accept -> Pay -> Deliver -> Release (Verify ledger marks lines successfully).

## 12) Production Checklist

- [ ] Guard `fn_direct_offer_guard` verified in active PG instance.
- [ ] Unified Work View includes a union branch for `direct_offers` data.
- [ ] RLS policies restricted purely to Sender & Receiver.
