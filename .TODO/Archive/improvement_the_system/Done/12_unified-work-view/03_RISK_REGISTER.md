# Risk Register: 12_unified-work-view

## [RR-01] Information Leakage (RLS Bypass)

- **Severity**: High | **Likelihood**: Medium
- **Impact**: One freelancer might see another freelancer's work titles, prices, or status if the view doesn't correctly inherit/enforce RLS.
- **Evidence**: `vw_unified_work_items` is a UNION ALL view. Supabase views do not automatically inherit RLS from source tables unless `SECURITY_INVOKER` is set.
- **Mitigation**: Re-create the view with `WITH (security_invoker = true)`.

## [RR-02] UI Desync (Fallback Mapper Drift)

- **Severity**: Medium | **Likelihood**: High
- **Impact**: If `vw_unified_work_items` SQL logic changes but `unified_work_item_fallback_mapper.dart` is not updated, the user will see a "jump" in status or data when opening details vs viewing the dashboard.
- **Evidence**: `WorkManagementService.dart:L43` explicitly calls a fallback.
- **Mitigation**: Consolidate all logic into a single source of truth (the Postgres view) and remove the Dart mapper.

## [RR-03] Direct Offer "Ghosting"

- **Severity**: High | **Likelihood**: High
- **Impact**: Users accept direct offers in chat, but they don't appear in "Active Work". Users forget to pay or deliver.
- **Evidence**: `direct_offers` table exists in `SUPABASE_SETUP.md` but is missing from the diagram and the SQL view branches.
- **Mitigation**: Integrate `direct_offers` as a first-class citizen in the `vw_unified_work_items` view.

## [RR-04] Migration Risk (View Overwrite)

- **Severity**: Low | **Likelihood**: Medium
- **Impact**: Overwriting the view might break existing dashboard queries if column types shift (e.g., `budget` numeric vs `price` numeric).
- **Mitigation**: Use `CREATE OR REPLACE VIEW` and dual-verify all column types in the `UNION ALL` branches.

## [RR-05] Dispute Visibility

- **Severity**: Medium | **Likelihood**: Medium
- **Impact**: Freelancer thinks they are "Delivered" and waiting for payment, while the client has filed a dispute.
- **Evidence**: `disputes` table is not joined in the current SQL view.
- **Mitigation**: Add a LEFT JOIN to `disputes` in the view logic to override `unified_status`.
