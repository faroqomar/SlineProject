# Patch Plan: Availability & Overlap Guard

## 1. Minimal SQL Changes

### A. Implement Overlap Guard (Postgres constraints)

Adding the GiST `EXCLUDE` constraint directly to `availability_slots` is safer and faster than a PL/pgSQL trigger.

```sql
-- Requires btree_gist extension
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- Prevents ANY two rows for the SAME provider from having overlapping starts_at/ends_at
ALTER TABLE public.availability_slots
ADD CONSTRAINT no_overlapping_slots
EXCLUDE USING gist (
  provider_id WITH =,
  tstzrange(starts_at, ends_at, '[)') WITH &&
);
```

### B. Patch `rpc_create_booking_draft_validated`

The current booking RPC leaves slots as `is_blocked = false`. We must atomically claim the slot.

```sql
-- Inside rpc_create_booking_draft_validated
-- After INSERT INTO public.bookings (...) RETURNING * INTO v_booking;

  UPDATE public.availability_slots
  SET is_blocked = true
  WHERE id = p_slot_id;

-- RETURN v_booking;
```

## 2. Minimal Flutter implementation (MVVM)

- `lib/features/availability/services/availability_service.dart`
  ```dart
  // Expected contract
  class AvailabilityService {
    Future<void> createSlot(DateTime startsAt, DateTime endsAt) async {
       // Must convert to UTC ISO8601
       await supabase.from('availability_slots').insert({
         'starts_at': startsAt.toUtc().toIso8601String(),
         'ends_at': endsAt.toUtc().toIso8601String(),
       });
    }
  }
  ```
- `lib/features/availability/viewmodels/availability_viewmodel.dart`
  - Handles UI state, triggers `AvailabilityService`.
  - Maps `PostgrestException` code `23P01` (exclusion violation) to `You already have a slot during this time period.`
- `lib/features/availability/view/availability_manager_screen.dart`
  - Presents a calendar/time picker explicitly bounded to 1-hour increments.

## 3. Updated Mermaid Diagram (Reflective of true patched system)

```mermaid
sequenceDiagram
    participant P as Provider (App)
    participant S as AvailabilityService (Flutter)
    participant DB as Supabase PostgreSQL
    participant C as Client (App)

    %% Provider creates an availability slot
    P->>S: createSlot(starts_at, ends_at)
    S->>S: Convert to UTC ISO8601
    S->>DB: INSERT INTO availability_slots

    Note over DB: Check: starts_at < ends_at
    Note over DB: Constraint: btree_gist EXCLUDE (no overlaps)

    alt Overlap detected (GiST tstzrange)
        DB-->>S: RAISE EXCEPTION 'exclusion_violation'
        S-->>P: Error: "You already have a slot at this time."
    else Clean slot
        DB->>DB: Commit INSERT
        DB-->>S: Success (slot_id)
        S-->>P: UI Update: Slot added
    end

    %% Client later books the slot
    C->>DB: rpc_create_booking_draft_validated (slot_id)
    Note over DB: Row check: IF slot is_blocked RAISE EXCEPTION
    DB->>DB: INSERT INTO bookings
    DB->>DB: UPDATE availability_slots SET is_blocked=true
    DB-->>C: Booking Created Response
```
