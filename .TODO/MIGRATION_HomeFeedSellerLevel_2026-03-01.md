# Home Feed Migration Order

## Introduce
1. `20260301_add_profiles_seller_level.sql`
2. `20260301_create_rpc_get_profile_summaries.sql`
3. `20260301_fix_search_profiles_safe_summary.sql`
4. `20260301_add_tasks_status_created_id_index.sql`

## Adopt In App
1. Switch cross-user summary readers to `rpc_get_profile_summaries`.
2. Ship seller-level model parsing and feed enrichment.
3. Ship composite cursor pagination.
4. Ship shared discovery sliver and single saved-provider wiring.

## Harden
1. `20260301_harden_home_related_read_policies.sql`
2. Re-run RLS matrix and smoke tests.

## Rollback
1. Revert `20260301_harden_home_related_read_policies.sql` first.
2. Roll back app deploy if cross-user summaries or feed rendering regresses.
3. Keep additive schema/RPC/index changes unless they are the proven cause.
4. If needed, drop or ignore `seller_level` only after app rollback is complete.
