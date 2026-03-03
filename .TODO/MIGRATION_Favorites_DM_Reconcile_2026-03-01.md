# Migration / reconcile: Favorites & DM

**Date**: 2026-03-01  
**Plan**: PLAN_FavoritesFix_2026-03-01.md

## Decision tree

1. **Docs-only reconcile**  
   If the locked DM rule (direct DMs favorites-gated) matches current live policy and trigger behavior: update only docs and code comments so they state the rule. No SQL change.

2. **Forward migration only if behavior must change**  
   If product/security later decides to change the rule (e.g. allow DMs without favorites): introduce a new migration that alters policy/trigger; do not backfill or rewrite history.

3. **No retroactive fake migration**  
   Do **not** add a “historical” migration that pretends to create `public.favorites` or its policies only to match current DB. The table already exists live; we document provenance instead.

## Provenance note

- **`public.favorites`** exists in live Supabase (columns, RLS, indexes) but is **not** represented in this repo’s `supabase/migrations/` history. Any new migration that touches favorites must be forward-looking (e.g. new policy or index) and not a fake “initial create” for provenance.

## If SQL reconcile is required

- Limit to the minimal change (e.g. trigger/function comment or single policy) to align with DECISION_Favorites_DM.
- Run in staging first; store before/after verification queries in this file or execution log.
- Do not bundle unrelated cleanup (e.g. duplicate indexes) in this fix.
