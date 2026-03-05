# Decision: Direct-DM authorization rule (Favorites)

**Date**: 2026-03-01  
**Plan**: PLAN_FavoritesFix_2026-03-01.md  
**Status**: Locked for this fix

## Canonical rule

**Direct client-initiated DMs remain favorites-gated.**

- A client may create (or get) a direct conversation with a freelancer (non–task-linked) only if that freelancer is in the client’s favorites.
- This is enforced at the database layer (e.g. `conversations_insert_client_only` policy and any related trigger/function), not only in the app.
- No change to this rule in the scope of the Favorites Fix. If product later wants non–favorites-gated DMs, that will be a separate product/security change with its own approval and implementation.

## Implications

- App and docs must align with this rule: “Direct DM requires favorite.”
- Reconcile trigger/function comments and docs (e.g. SUPABASE_SETUP.md, DEVELOPER_GUIDE Favorites) to state this rule; do not state that “favorites were removed for DMs.”
- QA and release verification must confirm that direct DM insert without a matching favorite row is denied (policy/trigger behavior).

## References

- Live Supabase: `conversations_insert_client_only` (favorites-gated).
- Plan: PLAN_FavoritesFix_2026-03-01.md, PLAN_CRITIC_FavoritesFix_2026-03-01.md.
