# FULL REPORT: 11 Availability Overlap Guard

## 0) Skill Selection

- **Skills selected**: Threat Modeling (Security), Invariants & Contracts, Production Migration Planning, Diagram Crafting.
- **Why these fit**: Directly analyzes a preventative database trigger (`trg_no_overlap_slots`). Production migration is key because the Flutter client completely lacked the screens to add these slots.
- **Skills not used**: State Machine & Lifecycle (slots are binary on/off).

## 1) Folder Identity

- **Folder name + path**: `.TODO/improvement_the_system/ImplementReady/11_availability-overlap-guard`
- **What system/feature it describes**: A PostgreSQL safety mechanism (`trg_no_overlap_slots`) that prevents a service provider from setting two working schedules that intersect in time.
- **Entities involved**: `availability_slots`, `trg_no_overlap_slots`, `bookings`.

## 2) Human Explanation

A Freelancer (Provider) attempts to define custom working hours via the app. The app attempts to `INSERT INTO availability_slots`. Postgres catches the row before commit using a `trg_no_overlap_slots` trigger. This trigger uses a GiST index on `tstzrange` to determine if the new `starts_at` and `ends_at` overlaps with any existing slot for that `provider_id`. If it does, Postgres aborts the transaction. If it's clean, the slot commits. Later, when a Client pays for a booking, the `bookings_insert` trigger marks that specific slot as `is_blocked = true`.

## 3) Symbol Legend

- **Rectangles**: Components interacting (Provider, Flutter, Postgres, Client).
- **Solid Arrows**: Insertion / booking commands.
- **Dotted Alt**: Overlap rejection handling vs Clean commit flow.

## 4) Extracted Contracts & Invariants

1. **Owner-Only Creation**: Only `auth.uid() = provider_id` can INSERT or UPDATE their slots.
2. **No Overlaps**: Strict check against `tstzrange(starts_at, ends_at, '[)')` overlapping for the same provider.
3. **Time Flow**: `starts_at` MUST be strictly `< ends_at`.

## 5) Conflict Scan Results

### 5.1 Naming Drift

- **Conflict**: None. `is_blocked` logic matches DB accurately.

### 5.2 Logic Drift

- **Conflict**: Finding slots for booking involves manually querying unblocked slots instead of an aggregate view.
- **Resolution**: Query `availability_slots` where `is_blocked = false` and `starts_at > now()`.

### 5.3 Data Model Drift

- **Conflict**: The Flutter codebase had 0% coverage for creating these slots.
- **Resolution**: An `AvailabilityService.dart` must be written from scratch.

## 6) Security & Failure Modes (Adversarial)

- **Bypassing the Block**: A user attempts to update an existing slot's end time to overlap another one.
  - _Mitigation_: The overlap trigger fires `BEFORE INSERT OR UPDATE`, covering modifications securely.
- **Double Booking Race**: Two clients book the same slot milliseconds apart.
  - _Mitigation_: `UNIQUE` constraints and serializable UI locking on the booking side.

## 7) UI Mapping

### 7.1 Mobile App UI

- **Screens**: "My Schedule" (Freelancer Settings), "Select Time" (Client Booking).
- **States**: Provider choosing intervals. Validating overlap local to UI before sending to speed UX.
- **Guardrails**: UI blocks overlapping time picker selections to prevent hitting the DB error.

### 7.2 Admin Dashboard UI

- **Pages**: Schedule Dispute Investigation.
- **Metrics**: Provider capacity utilization.
- **Drilldowns**: Read-only timeline view of slots for a given provider.

### 7.3 Implementation Hooks

- `AvailabilityService.createSlot(starts, ends)` -> Maps to raw insert.
- `BookingService` -> Implicitly marks slot `is_blocked = true` when payment confirms.

## 8) Diagram Verdict + Best Diagram Type

- **Score now**: 9/10
- **Best Diagram Type**: Sequence Diagram capturing the failure modes and the subsequent client-booking link.

## 9) Upgrade Plan

- **Phase 0: Observability**: Track `availability_slot_created` vs `availability_slot_blocked`.
- **Phase 1: Contracts**: Implement Flutter `AvailabilityService`. Map PostgreSQL Exceptions to clear UI messages ("You already have a slot at this time").
- **Phase 2: Hardening**: Ensure foreign keys from `bookings` to `availability_slots` use `RESTRICT` on delete, not `CASCADE`.
- **Phase 3: Scale**: Maintain GiST ranges and standard B-Tree on `provider_id`.

## 10) Risks

### 10.1 Risks if current version kept

- **100% Failure**: The app lacked the UI/Code to let freelancers actually input their schedule.

### 10.2 Risks introduced by fixes

- **Hard Delete Loss**: If a provider deletes a slot that has an active booking, it corrupts financial records. _Mitigation_: `RESTRICT` delete policy in SQL.

## 11) Test Plan (High-value)

- **Integration**: Attempt to insert two intersecting slots (`12:00-14:00` and `13:00-15:00`). Verify Postgres throws exception.
- **Unit (RLS)**: Attacker passes `provider_id` of someone else -> verify RLS denies.

## 12) Production Checklist

- [ ] `AvailabilityService` built in Flutter MVVM.
- [ ] Error mapping handles Postgres overlap exception gracefully.
- [ ] `RESTRICT` deletion rules applied.
