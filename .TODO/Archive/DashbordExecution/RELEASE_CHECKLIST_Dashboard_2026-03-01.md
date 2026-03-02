# Dashboard Remediation – Release Checklist

**Plan**: Dashboard Full Remediation v2  
**Date**: 2026-03-01

Definition of done per slice; merge blockers; rollback points.

## Slices (Branch Names)

1. `codex/dashboard-remediation-01-test-infra` – Test infra, fixtures, preflight, selectors.
2. `codex/dashboard-remediation-02-db-security` – Live scan (or verified export), finance boundary, transition RPCs, tender contract, profile summary, RLS.
3. `codex/dashboard-remediation-03-app-layer` – Repos, coordinator, ViewModel split, wallet/cache/services ownership, AppLogger.
4. `codex/dashboard-remediation-04-ui-qa-docs` – UI wiring, widget moves, dead code removal, tests, manual scenarios, docs.

## Merge Blockers (All Slices)

- [ ] `flutter analyze` clean.
- [ ] No `print()` in new/changed code; AppLogger used.
- [ ] MVVM: no UI → Supabase.
- [ ] Review checklist completed for the slice.

## Slice 1 DoD

- [ ] TEST_INFRA and FIXTURES docs exist.
- [ ] dashboard_env.dart and dashboard_preflight.dart exist and are used by dashboard integration tests.
- [ ] Selector/key map documented (or placeholder); no regression in existing tests.

## Slice 2 DoD

- [ ] LIVE_SCAN artifact or verified SQL export exists (or slice explicitly excludes DB-sensitive work).
- [ ] Finance boundary: non-admin cannot read finance views.
- [ ] Transition RPCs exist and are used; tender payment state machine aligned.
- [ ] Migration and reconciliation artifacts exist; verify queries run.

## Slice 3 DoD

- [ ] TenderPaymentCoordinator + TenderPaymentViewModel; single payment path.
- [ ] LedgerService treats `{ok:false}` as terminal (already true; verify).
- [ ] Dashboard ViewModel split (or facade) and ownership explicit; cache/services/wallet ownership decided and implemented.
- [ ] AppLogger instrumentation per OBSERVABILITY doc.

## Slice 4 DoD

- [ ] Shell/tabs use bounded owners; lazy-load by tab.
- [ ] Booking/offer/wallet widgets moved to owning features; status presentation shared.
- [ ] Tender payment UI bound to VM; dead Manage files removed.
- [ ] Unit/widget/integration tests added/updated; manual scenarios run; docs synced.

## Rollback Points

- Slice 1: revert test infra only.
- Slice 2: rollback migrations only; re-enable kill-switch if contract unresolved.
- Slice 3: keep facade; revert coordinator/VM if regressions.
- Slice 4: disable award/pay entry points if UI/QA fails; keep widget wrappers if needed.

## Kill-Switch Activation

- If live DB proof unavailable: block Phase 1.1+ or disable award/pay in UI.
- If finance leak remains: disable finance reads in app and revoke grants first.
- If payment state drift found: disable award/pay; run reconciliation forward-fix.

## Evidence Attachment

- Failure artifacts in `integration_test/artifacts/`; attach to execution log or PR.
- Release sign-off only with code, DB evidence (where applicable), tests, and docs aligned.
