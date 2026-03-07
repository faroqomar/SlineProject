# FULL REPORT: 06 Direct Chat Offer Flow

## 0) Skill Selection

- **Skills selected**: DB-First Financial Modeling, State Machine & Lifecycle, Observability.
- **Why these fit**: Direct offers circumvent the open marketplace to strike a deal within DMs. Ensuring `direct_offers` ties into the exact same `process_payment_event_ledger` as public tasks is vital.
- **Skills not used**: Repo Mapping.

## 1) Folder Identity

- **Folder name + path**: `.TODO/improvement_the_system/ImplementReady/06_direct-chat-offer-flow`
- **What system/feature it describes**: Freelancers sending a custom-priced work contract directly into an existing chat thread with a client, leading to an escrow payment.
- **Entities involved**: `direct_offers` (table), chat UI, `process_payment_event_ledger`.

## 2) Human Explanation

A Freelancer negotiates with a Client in DMs. The Freelancer proposes an offer. A `direct_offers` row is created with `status = 'sent'` and `payment_status = 'unpaid'`. The Client accepts the offer by paying via the QiCard gateway. The `gateway_escrow` event updates the `payment_status` to `'held'` and `status` to `'active'`. The Freelancer delivers the work, setting `status = 'delivered'`, and logs a `review_expires_at` date. The Client approves or the 3-day clock expires, triggering `release_with_fee` and marking the offer `'completed'`.

## 3) Symbol Legend

- **Circles**: Offer States (`sent`, `canceled`, `rejected`, `active`).
- **Solid Arrows**: Explicit user actions (Accept, Pay, Deliver).
- **Dashed Arrows**: Asynchronous UI rendering / Cron Timeout (`review_expires_at`).
- **Brackets [GAP]**: Missing or hazardous paths in legacy implementations.

## 4) Extracted Contracts & Invariants

1. **Initial Creation Contract**: A freelancer must be the one initiating the offer. It defaults to `sent` and `unpaid`.
2. **Escrow Funding Liability**: An offer ONLY transitions to `active` via a valid ledger event (`escrow_hold`).

## 5) Conflict Scan Results

### 5.1 Naming Drift

- **Conflict**: The UI / Legacy diagrams used `pending`.
- **Resolution**: Deprecated `pending`. The database strictly uses `sent` for unaccepted offers.

### 5.2 Logic Drift

- **Conflict**: Missing a path for the Freelancer to cancel a sent offer before the client pays.
- **Resolution**: Implementation requires a `canceled_unpaid` branch.

### 5.3 Data Model Drift

- **Conflict**: DB lacked `delivered_at` and `review_expires_at` missing in original design, causing permanent escrow locks.
- **Resolution**: Direct Offers must have a 3-day timeout cron exactly like Tender tasks.

## 6) Security & Failure Modes (Adversarial)

- **Permanent Escrow Trap**: Freelancer delivers, Client deletes app. Funds stuck forever.
  - _Mitigation_: The `review_expires_at` field and `fn_check_expired_reviews` cron job auto-approve.
- **Active Cancellation Ghost**: Client wants a refund on an `active` offer but the UI doesn't have a button.
  - _Mitigation_: Extend the disputes system to accept `direct_offer_id`.

## 7) UI Mapping

### 7.1 Mobile App UI

- **Screens**: Chat Messages Stream, Pay Now Gateway.
- **States**: Rendering a "Custom Offer Card" inline with chat messages based on state (Sent, Accepted, Delivered, Complete).
- **Guardrails**: Hide the "Pay Now" button if `payment_status` is already `held`.

### 7.2 Admin Dashboard UI

- **Pages**: Direct Offers feed.
- **Metrics**: Total volume of private vs public hires.
- **Drilldowns**: Map the direct offer UUID to `journal_entries`.

### 7.3 Implementation Hooks

- `DirectOffersService.sendOffer()`.
- Payment Service -> Ledger `gateway_escrow`.
- `DirectOffersService.markDelivered()`.

## 8) Diagram Verdict + Best Diagram Type

- **Score now**: 9/10
- **Best Diagram Type**: State Diagram (Composite State) connecting UX status to Financial Payment Status.

## 9) Upgrade Plan

- **Phase 0: Nomenclature**: Replace all traces of `pending` with `sent` in UI code.
- **Phase 1: DB Migrations**: Add `delivered_at` and `review_expires_at` to `direct_offers`.
- **Phase 2: Cron Setup**: Modify `fn_check_expired_reviews` to act on `direct_offers` as well as tasks.
- **Phase 3: Disputes**: Ensure support can cleanly `refund` an active direct offer.

## 10) Risks

### 10.1 Risks if current version kept

- **Stuck Funds**: The lack of an auto-expiry for direct offers guarantees locked escrows.

### 10.2 Risks introduced by fixes

- **Timeout Abuse**: Freelancers could send an empty text file delivery and wait 3 days to steal the escrow. _Mitigation_: Strong push notifications to the Client.

## 11) Test Plan (High-value)

- **Integration**: Send offer -> Pay -> Deliver -> Wait 3 Days (simulated) -> Assert payment `released`.
- **Security**: Client attempts to call `markDelivered` (Must fail via RLS).

## 12) Production Checklist

- [ ] `review_expires_at` included in Direct Offers schema.
- [ ] Diagram explicitly states `active_held` to align UI logic with DB state.
- [ ] Dispute pathway configured for private offers.
