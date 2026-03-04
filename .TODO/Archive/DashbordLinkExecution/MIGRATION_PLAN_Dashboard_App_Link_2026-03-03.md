# Data Migration Plan - Dashboard App Link (2026-03-03)

## Strategy
- Additive-first.
- No drops/renames in this rollout.
- Keep compatibility window for current app clients.

## DB Drift To Reconcile
- Local repo missing dashboard-link migrations present in docs/TODO bundle.
- Live DB missing `admin_approvals` and `admin_pii_access_logs`.
- `reports` and `system_config` RLS need app-safe read/write bridges.

## Ordered Steps

1. Introduce missing objects (additive)
- Add migration for `admin_approvals` and approval RPCs.
- Add migration for `admin_pii_access_logs`.
- Add/align `admin_update_system_config` and key seeds if drifted.

2. Add app-safe policy/RPC bridges
- Reports:
  - add authenticated INSERT policy (`reporter_user_id = auth.uid()`).
  - add own-row SELECT policy for reporter.
- System config:
  - expose read-only public keys through restricted RPC or SELECT policy.

3. Validate
- Run policy probes with authenticated and anonymous contexts.
- Verify no write access to admin tables for app clients.

## Rollback
- Prefer forward-fix.
- Emergency disable by removing newly-added permissive policies first.
