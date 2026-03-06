# FULL REPORT: 05 Booking Lifecycle

## 0) Skill Selection

- **Skills selected**: Invariants & Contracts, State Machine & Lifecycle, DB-First Financial Modeling, RLS & Privilege Boundaries.
- **Why these fit**: Bookings reserve time blocks directly and bypass the tender bidding process. This requires intense timeline conflict validations (Invariants) and escrow transitions directly out of the booking gate.
- **Skills not used**: Repo Mapping.

## 1) Folder Identity

- **Folder name + path**: `.TODO/improvement_the_system/ImplementReady/05_booking-lifecycle`
- **What system/feature it describes**: A client directly books a freelancer for a specific time slot using their pre-defined portfolio/service rate.
- **Entities involved**: `bookings`, `availability_slots`, `process_payment_event_ledger`.

## 2) Human Explanation

A Client browses a Freelancer's profile and selects an open `availability_slot`. The Client creates a `booking` and is immediately pushed to pay. The slot is temporarily locked (`is_blocked = true`). Once the Client pays, the ledger `gateway_escrow` triggers. The booking status becomes `confirmed` (in_progress work). The Freelancer delivers the service. The Client approves, releasing the funds via `release_with_fee`. If the Client doesn't pay in a short window, the booking expires, the slot unlocks, and the booking is voided.

## 3) Symbol Legend

- **Circles**: Blocked/Unblocked states of the Time Slot.
- **Rectangles**: Booking Entity states (`pending`, `confirmed`, `completed`).
- **Solid Arrows**: User progression.
- **Dashed Arrows**: Cron job auto-unblocking unpaid slots.

## 4) Extracted Contracts & Invariants

1. **Slot Mutex:** Two confirmed bookings CANNOT occupy the same availability slot.
2. **Immediate Escrow Path:** A booking skips `assigned` and `open` bids. It goes `pending_payment` -> `confirmed` (which maps functionally to `in_progress`).

## 5) Conflict Scan Results

### 5.1 Naming Drift

- **Conflict**: The booking entity uses `status = 'confirmed'`, while tender tasks use `status = 'in_progress'`.
- **Resolution**: Map `confirmed` to represent funded escrow in bookings.

### 5.2 Logic Drift

- **Conflict**: Freelancers used to manually "Accept" bookings.
- **Resolution**: Sline bookings are instant-book if the slot is open. If manual approval is needed, it must happen _before_ payment. Current flow: Payment first implies Instant-Book.

### 5.3 Data Model Drift

- None detected in modern schema; references accurate `bookings` table.

## 6) Security & Failure Modes (Adversarial)

- **Slot Squatting (DoS)**: A malicious client creates 50 bookings but never pays, locking up the freelancer's calendar.
  - _Mitigation_: A fast Cron Job (e.g., 15 minutes) that auto-deletes unpaid bookings and flips `is_blocked = false` on the slots.
- **Double Booking Race**: Two clients book the same slot milliseconds apart.
  - _Mitigation_: Database UNIQUE constraints or `is_blocked = false` WHERE clauses on the INSERT.

## 7) UI Mapping

### 7.1 Mobile App UI

- **Screens**: Freelancer Calendar, Checkout Page, Booking Details.
- **States**: Selecting Slot, Payment Loading, Confirmed Appointment.
- **Guardrails**: Polling for slot availability live before showing Checkout.

### 7.2 Admin Dashboard UI

- **Pages**: Global Bookings feed.
- **Metrics**: Dropout rate (Bookings created vs Paid).
- **Drilldowns**: Map booking IDs to generated `ledger_lines`.

### 7.3 Implementation Hooks

- `BookingService.createBooking()` -> Maps directly to QiCard checkout gateway.
- `payment_webhook` -> `process_payment_event_ledger` marks it `confirmed`.

## 8) Diagram Verdict + Best Diagram Type

- **Score now**: 9/10
- **Best Diagram Type**: Sequence Diagram mixed with State states.

## 9) Upgrade Plan

- **Phase 0: Observability**: Track the drop-off rate of unpaid bookings.
- **Phase 1: Contracts**: Enforce the 15-minute unpaid `pending` expiry cron. Protect slots.
- **Phase 2: Hardening**: Ensure slot UNIQUE constraints reject overlapping times exactly.

## 10) Risks

### 10.1 Risks if current version kept

- **Slot Squatting**: Calendar destroyed by troll accounts locking slots.

### 10.2 Risks introduced by fixes

- **Payment Delay Cancellation**: If QiCard takes 16 minutes to verify, but the Cron deletes it at 15 minutes, funds arrive but the booking is dead.
  - _Mitigation_: Implement robust Orphan Payment linking.

## 11) Test Plan (High-value)

- **Integration**: Start booking, wait 15 min, assert slot is unblocked.
- **Concurrency**: Fire two booking requests for the same slot ID simultaneously; assert one fails.

## 12) Production Checklist

- [ ] 15-minute slot unlock cron job active.
- [ ] `process_payment_event_ledger` handles `booking_id` successfully.
