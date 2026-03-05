# DB Provenance: Proposals 2026-03-04

**Purpose**: Operational gate when live Supabase MCP access is unavailable.

## Current status

- **Live Supabase scan**: ✅ Applied via Supabase MCP (plugin-supabase-supabase) on 2026-03-05.
- **Migrations applied**: `secure_proposal_rpc_contract` (version 20260305021934), `proposal_profile_summary_contract` (20260305021945), `finalize_awarded_offer_payment` (20260305021949). All three applied with `apply_migration`; verified via `list_migrations` and `execute_sql` (all 7 RPCs present: award_task_offer, pay_awarded_offer, cancel_awarded_offer, get_client_awarded_unpaid_offers, get_freelancer_awarded_unpaid_offers, get_proposal_bidder_summaries, finalize_awarded_offer_payment).
- **Allowed work**: App, test-prep, and **DB reconcile** are **unblocked** for proposals.
- **Release**: Per RELEASE_CHECKLIST_Proposals, release still requires manual E2E and SQL/RLS verification steps; live DB evidence for proposal RPCs is now satisfied.

## Forward-only reconcile rules

- All proposal-related migrations must be **additive-first** (no drops/renames in first rollout).
- Reserve migration slots: `20260304060000_secure_proposal_rpc_contract.sql`, `20260304061000_proposal_profile_summary_contract.sql`, `20260304062000_finalize_awarded_offer_payment.sql`.
- Compatibility wrappers (old RPC signatures or views) must remain until app callers are switched and verified.
- Document drift (repo migrations vs live DB) in Phase 1.0 drift report when MCP is available.
