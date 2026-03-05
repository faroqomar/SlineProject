# Done Criteria: Proposals 2026-03-04

**Purpose**: Definition of done for the proposal remediation.

## Acceptance (all must be true)

1. **RPC auth**: Proposal RPCs (award, pay, cancel, get_client_awarded_unpaid_offers, get_freelancer_awarded_unpaid_offers) bind authorization to `auth.uid()`; spoofed actor IDs do not change outcomes.
2. **No client role mutation**: Submit flow does not update `profiles.active_role`; role mismatch surfaces as explicit error.
3. **Atomic finalize**: Non-QiCard finalize is one server path; no client path where ledger success outlives proposal/task state failure.
4. **RLS-safe reads**: Owner/freelancer proposal reads use chosen profile contract; no forbidden direct `profiles` join.
5. **Resume payload**: All payment resume launchers use same typed payload; real task title and server-derived deadline shown.
6. **Feature boundary**: Active proposal runtime under `lib/features/proposals`; no duplicate active path; stub modal removed or tombstoned.
7. **Tests**: Test infra, unit/widget/integration/manual/SQL evidence pass; release checklist satisfied.
8. **Docs**: Docs match code and verified DB reality.

## Stop conditions

- Phase 1: Do not apply migrations to production until live scan and RLS verification pass.
- Phase 2/3: Do not remove compatibility exports until all launchers use proposal_payment_route and new models.
