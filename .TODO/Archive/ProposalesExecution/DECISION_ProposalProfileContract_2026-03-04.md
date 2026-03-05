# Decision: Proposal Profile Contract 2026-03-04

**Status**: Locked.

## Chosen strategy

**Proposal-specific minimum-field RPC** (or narrow contract via existing RPC).

- Do **not** relax `profiles_select_self`.
- Do **not** keep direct `profiles` join in owner proposal list.
- Owner and freelancer proposal surfaces receive bidder identity via a **minimum-field** contract only (e.g. id, display_name, avatar_url or path). No bio, active_role, skills, seller_level in proposal context unless product explicitly requires.

## Implementation

- Implement in Phase 1: either new RPC (e.g. `get_proposal_bidder_summaries`) or narrow return shape of existing profile-summary RPC for proposal callers only. Document in CONTRACT_proposals_rpc_and_models.
