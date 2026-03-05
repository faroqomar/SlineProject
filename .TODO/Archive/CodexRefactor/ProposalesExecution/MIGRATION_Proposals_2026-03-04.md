# Migration Plan: Proposals 2026-03-04

**Purpose**: Additive-first, provenance-safe DB changes.

## Sequencing

1. **Introduce**: Apply new migrations (secure RPC, profile contract, atomic finalize) on staging first.
2. **Backfill**: Only if deadline/resume strategy requires new column; backfill from existing timestamps where possible.
3. **Enforce**: After app callers use new contract; no drops in first rollout.
4. **Cleanup**: Defer until compatibility window closes (later release).

## Reserved migration slots

| Slot | Purpose |
|------|---------|
| `supabase/migrations/20260304060000_secure_proposal_rpc_contract.sql` | Patch award_task_offer, pay_awarded_offer, cancel_awarded_offer, get_client_awarded_unpaid_offers, get_freelancer_awarded_unpaid_offers to bind auth to auth.uid(). |
| `supabase/migrations/20260304061000_proposal_profile_summary_contract.sql` | Minimum-field proposal profile RPC or narrow existing RPC. |
| `supabase/migrations/20260304062000_finalize_awarded_offer_payment.sql` | Atomic finalize RPC for non-QiCard (ledger + task_request/task update). |
| Optional | Deadline/resume column or view only if Phase 1 live scan proves necessary. |

## Compatibility

- Keep existing RPC signatures as wrappers until Flutter is switched; then deprecate. No drop of columns or functions in first rollout.
- Forward-only reconcile rules: see DB_PROVENANCE_Proposals_2026-03-04.md.
