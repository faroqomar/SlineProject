# Profile Summary Minimum Contract

**Plan**: Dashboard Full Remediation v2  
**Date**: 2026-03-01

## Requirement

- Dashboard (and profile preview) need only **full_name** and **avatar_url** for counterparty display.
- RPC rpc_get_profile_summaries must not return more fields than required unless another audited caller needs them.

## Options

- **In-place shrink**: Alter RPC to return only id, full_name, avatar_url (and any other field proven required by caller scan). Risk: hidden callers may break.
- **Versioned/additive**: Add new RPC (e.g. rpc_get_profile_summaries_v2) with minimal shape; migrate dashboard and profile to it; deprecate old RPC after compatibility window.

## Client

- Dashboard and ProfileSummaryService consume only the minimal set; do not rely on bio, active_role, skills, created_at, seller_level unless documented as required.

## Verification

- Caller scan: rg rpc_get_profile_summaries or get_profile_summaries in lib; list consumers and required fields.
- After change: function definition returns only approved columns; dashboard and profile tests pass.
