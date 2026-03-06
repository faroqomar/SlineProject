# Gaps and Fixes for Booking Lifecycle

## Skills Selected

- **Evidence-First Reading**: To read the diagram and app code to verify the current state
- **State Machine & Lifecycle**: To analyze the booking state transitions.
- **Idempotency & Concurrency**: To evaluate race conditions like double bookings on the same slot.
- **DB-First Financial Modeling**: To analyze the payment transition logic and escrow.
- **Diagram Crafting (Mermaid)**: To output the final optimized diagram.

## 1. Identified Gaps in Current Diagram

1. **Missing Dispute/Escalation Path**
   - **Evidence**: `lib/core/app_enums.dart` defines `UnifiedWorkStatus.disputed` and `Sline_everything/SUPABASE_SETUP.md` defines a `disputes` table, but the booking lifecycle jumps straight from `delivered` to `canceled` without a dispute or mediation state.
2. **Missing `no_show` Status**
   - **Evidence**: `lib/core/app_enums.dart` has `noShow` in the `BookingStatus` enum, but it's completely missing from the diagram. A "no show" is a critical failure mode for scheduled bookings.
3. **Ambiguous Cancellation Rules**
   - **Evidence**: The diagram says `active --> canceled: Canceled (Either / Refunds rules apply)`. This hides the complexity of who canceled, when, and how much is refunded (full vs partial).
4. **Missing Timeout/Auto-Complete for Delivery**
   - **Evidence**: `Sline_everything/SUPABASE_SETUP.md` (tasks table) has `review_expires_at` which dictates auto-approval. Currently, the diagram only shows `delivered --> completed: Client Approves`, ignoring the cron job that auto-approves if the client ignores the delivery.
5. **No Slot Overlap Prevention Visibility**
   - **Evidence**: `Sline_everything/SUPABASE_SETUP.md` mentions `fn_reject_overlapping_slots` trigger. While not a state itself, it acts as a transition guard that will reject the `paid_request_pending` -> `active` or `pending` -> `paid_request_pending` transition if the slot is no longer available.

## 2. Proposed Fixes & Invariants

- **Invariant 1 (Escrow Lock)**: A booking must never reach `active` without successful payment escrow (`payment_status = 'held'`).
- **Invariant 2 (Slot Lock)**: A state transition to `active` must fail if `fn_reject_overlapping_slots` detects concurrent slot consumption.
- **Fix 1**: Add `disputed` state from `delivered` or `active`.
- **Fix 2**: Add `no_show` terminal state from `active` (e.g., Client reports provider didn't show up).
- **Fix 3**: Add `expired_review` transition from `delivered` to `completed` driven by cron, utilizing the `review_expires_at` timestamp.
