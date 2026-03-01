> Historical Status: Superseded on 2026-03-01. Do not treat this file as the current runtime contract for the dashboard/orders surface.

> Current authoritative references:
> - `.TODO/DOCS_SYNC_2026-03-01_Orders_Dashboard_Decommission.md`
> - `.TODO/DOCS_REFERENCE_FIX_2026-03-01_Orders_Dashboard_Decommission.md`
> - `Sline_everything/DEVELOPER_GUIDE.md`
> - `Sline_everything/DEVELOPER_GUIDE/Orders Feature.md`
> - `lib/features/orders/README.md`

# Threat Model — Orders — 2026-03-01

## Abuse Cases
- Cross-owner offer acceptance using mismatched owner fields.
- Cross-owner offer rejection using mismatched owner fields.
- Cross-owner task deletion under mixed `user_id` / `client_id` / `owner_id` policies.
- Unknown offer status rendered as actionable pending.
- Raw PostgREST/RPC errors leaked into snackbars.
- Notification spam caused by broad authenticated insert policy.

## Required Controls
- Orders reads use owner-compatible filtering, but privileged decisions use server-side RPC owner checks.
- Unknown offer statuses are non-actionable.
- User-facing errors are mapped and sanitized.
- Offer decision actions are single-flight in UI.
- Client app does not widen notification behavior beyond existing offer-decision notifications.

## Verification Targets
- Non-owner cannot accept or reject another user’s offer.
- Non-owner cannot delete another user’s task.
- Unknown offer state renders without `Accept` / `Reject` controls.
- Failed delete/chat/offer actions never expose raw DB text.
