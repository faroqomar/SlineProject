> Historical Status: Superseded on 2026-03-01. Do not treat this file as the current runtime contract for the dashboard/orders surface.

> Current authoritative references:
> - `.TODO/DOCS_SYNC_2026-03-01_Orders_Dashboard_Decommission.md`
> - `.TODO/DOCS_REFERENCE_FIX_2026-03-01_Orders_Dashboard_Decommission.md`
> - `Sline_everything/DEVELOPER_GUIDE.md`
> - `Sline_everything/DEVELOPER_GUIDE/Orders Feature.md`
> - `lib/features/orders/README.md`

# Docs Report — orders

- Date: 2026-03-01
- Scope: `orders`
- Plan Reference: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_OrdersFix_2026-03-01.md`
- Workflow: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.agents/workflows/orchestrator.md`

## Evidence
- The main developer guide now documents owner-compatible orders reads and the dedicated orders flow.
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/DEVELOPER_GUIDE.md:73-78`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/DEVELOPER_GUIDE.md:1489-1500`
- The feature-specific orders guide now matches the dedicated Orders tab, error states, and unknown-offer handling.
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/DEVELOPER_GUIDE/Orders Feature.md:3-24`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/DEVELOPER_GUIDE/Orders Feature.md:38-62`
- `replace_task_request(...) -> void` is documented correctly now.
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/SUPABASE_SETUP.md:1464-1471`

## Reference Integrity Scan
- No broken file references were found in the updated orders developer guide sections.
- The current docs point at existing files:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/view/orders_dashboard_screen.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/view/widgets/offer_list_sheet.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/viewmodels/orders_view_model.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/services/orders_service.dart`

## Documentation Deltas Still Required
- HIGH: `SUPABASE_SETUP.md` still documents overloaded `accept_task_request` and `reject_task_request` signatures as parallel valid surfaces, but it does not define one canonical client contract or deprecation path.
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/SUPABASE_SETUP.md:1395-1418`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/SUPABASE_SETUP.md:1456-1462`
- MEDIUM: the docs still do not document the live `notifications_insert_any` policy risk or the intended least-privilege path for offer-decision notifications.
  - No explicit policy discussion found in:
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/DEVELOPER_GUIDE.md`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/DEVELOPER_GUIDE/Orders Feature.md`
    - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/SUPABASE_SETUP.md:1395-1476`
- MEDIUM: the docs describe the app contract, but not the compatibility window between `owner_id`, `user_id`, and `client_id` at the database policy layer.
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/DEVELOPER_GUIDE.md:73-78`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/DEVELOPER_GUIDE/Orders Feature.md:15-24`

## Required Doc Updates
- Add a canonical accept/reject RPC section to `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/SUPABASE_SETUP.md`.
- Add a compatibility note for the mixed owner columns and the migration target.
- Add a least-privilege note for notification writes in the orders/offers path.

## Verdict
- Docs status: PASS for repo code references and current UI behavior.
- Docs status: NOT COMPLETE for backend contract governance. The overloaded RPC documentation and notification policy documentation are still behind live risk.
