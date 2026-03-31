# Audit Notes - Hardened Payment Linking System

**Skills applied**: Evidence-First Reading, DB-First Financial Modeling.

## 1. Context & Baseline

- **Input Diagram**: [24_hardened_paymentLinking_system.md](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/AppDigram/All_Diagrams/24_hardened_paymentLinking_system.md)
- **Reference Diagram**: [19_direct-offers-work-contract.md](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/AppDigram/All_Diagrams/19_direct-offers-work-contract.md)
- **Source of Truth**: [SUPABASE_SETUP.md](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/SUPABASE_SETUP.md)

## 2. Evidence Registry

### E1: Non-existent Hardened Tables

- **Observation**: `payment_intents`, `payment_events`, and `orphan_payments` mentioned in Diag 24 are MISSING from `SUPABASE_SETUP.md`.
- **Evidence**: `grep` search for these terms in `SUPABASE_SETUP.md` returned 0 results.
- **Status**: PROPOSED DESIGN (not implemented).

### E2: Existing Ledger Infrastructure

- **Observation**: A robust double-entry system exists (v2.16).
- **Evidence**: `SUPABASE_SETUP.md` §5.20-5.22 defines `accounts`, `journal_entries`, `ledger_lines`.
- **Orchestration**: `process_payment_event_ledger` is the actual RPC used for escrow and releases ([SUPABASE_SETUP.md:L1430](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/SUPABASE_SETUP.md#L1430)).

### E3: Payment Flow in Status Guards

- **Observation**: Lifecycle guards for `bookings` and `direct_offers` anticipate payment.
- **Evidence**:
  - `direct_offers` check ([SUPABASE_SETUP.md:L691](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/SUPABASE_SETUP.md#L691)): `fn_direct_offer_guard` enforces `accepted` -> `active` requires payment.
  - `bookings` check ([SUPABASE_SETUP.md:L1311](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/SUPABASE_SETUP.md#L1311)): `pending` -> `paid_request_pending`.

## 3. System Boundaries

- The current system handles **logic** (status guards) and **ledgering** (double-entry).
- The missing piece is the **Intent/Gateway Linking** layer which prevents "random" webhook hits from being processed without a pre-registered server-side contract.

## 4. Initial Critique

- Diag 24 is highly defensive (Good).
- Mismatch between `WAL: RPC process_payment_event` (Diag 24) and `process_payment_event_ledger` (Live Code).
- The "Signature" in metadata is the "Golden Thread" that binds the gateway to our intent.
