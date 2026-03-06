# Gaps and Fixes: 12_unified-work-view

## [GAP-01] Missing Direct Offers

- **Evidence**: `SUPABASE_SETUP.md:L669` shows `direct_offers` table. `vw_unified_work_items` SQL only has 3 branches (Tasks, Bookings, Awarded Tasks).
- **Risk**: Direct offers won't show up in the "My Work" feed, making them invisible to users after acceptance.
- **Fix**: Add a 4th `UNION ALL` branch for `direct_offers`. Map `status` (active, delivered, completed) to `unified_status`.

## [GAP-02] Disputed State missing from View

- **Evidence**: `lib/core/app_enums.dart:L83` has `UnifiedWorkStatus.disputed`. View logic doesn't join with `disputes` table or check for dispute status.
- **Risk**: A disputed work item will show as "Active" or "Delivered" misleadingly.
- **Fix**: Add a check in all branches to detect if a related record exists in the `disputes` table (filtered by entity_id and entity_type). Override `unified_status` to 'disputed' if found.

## [GAP-03] Service-Layer Fallback Mapper

- **Evidence**: `work_management_service.dart:L45` and `unified_work_item_fallback_mapper.dart`.
- **Reason**: The view likely fails RLS or has a logical hole regarding awarded tasks before they become "in_progress".
- **Risk**: Fragmentation of business logic. If the mapper and the SQL drift, the app shows different data on different screens.
- **Fix**: Harden `Branch 3` of the view to include all awarded-but-unpaid tasks and ensure RLS policies on the view (or `SECURITY_INVOKER` setting) allow the freelancer to see them. Remove the fallback mapper in Flutter.

## [GAP-04] RLS Privilege Boundaries

- **Evidence**: UNION views in Supabase can be tricky.
- **Risk**: If the view is `SECURITY DEFINER` (the default if not specified in some versions/snippets), it might bypass RLS unless carefully coded.
- **Fix**: Ensure the view is created with `SECURITY_INVOKER` (Postgres 15+) or explicitly wrap with a row-level filter function.

## [GAP-05] Ambiguous Source Status

- **Evidence**: `UnifiedWorkItemModel` takes `source_status` but the mapping in the SQL `CASE` statement is hardcoded.
- **Risk**: If a new status is added to `booking_status_enum` or `task_status`, the view will return the raw value instead of a mapped unified value.
- **Fix**: Use a dedicated mapping function in SQL to ensure consistency.
