# Audit Notes: 11_availability-overlap-guard

## Skills Applied

- **Threat Modeling (Security):** To evaluate what a malicious provider or client might do to bypass schedule limits.
- **Invariants & Contracts:** To rigorously define the overlap block DB trigger (`trg_no_overlap_slots`) rules.
- **Production Migration Planning:** Because the Flutter code is completely missing, ensuring the path to production is documented.
- **Diagram Crafting (Mermaid):** Refactoring the flow from just an error condition diagram into a complete sequence.

_Skills intentionally not used:_ State Machine & Lifecycle (booking state is covered elsewhere; availability just uses `is_blocked` true/false), DB-First Financial Modeling (payment and ledgers are downstream from slot availability).

## Evidence Collected

1. Code `lib/` grep: `availability_slots` is only parsed in `booking_model.dart`. NO insert UI or Service exists.
2. DB grep `SUPABASE_SETUP.md`:
   - `availability_slots` table uses primary key `id`.
   - `slots_write_owner` RLS ensures only the `auth.uid() = provider_id` can create/update.
   - Trigger `trg_no_overlap_slots` calling `fn_reject_overlapping_slots()` prevents any overlap via `tstzrange` checks.
