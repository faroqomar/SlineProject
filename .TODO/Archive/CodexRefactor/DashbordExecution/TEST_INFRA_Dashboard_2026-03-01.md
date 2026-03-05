# Dashboard Test Infrastructure

**Plan**: Dashboard Full Remediation v2  
**Date**: 2026-03-01

## Scope

- **Unit**: dashboard facade/ownership, cache injection, tender payment coordinator, LedgerService `{ok:false}`, booking/task transition guards, wallet snapshot init, profile-summary parsing.
- **Widget**: overview wallet states, work item CTA, inbox award/pay, tender payment screen states, booking card actions.
- **Integration**: role switch persistence, award/pay happy path (or documented manual contract), kill-switch behavior.

## Shared Harness

- Widget: `test/test_support/pump_app.dart` (pumpApp with providers).
- Integration: `integration_test/support/preflight.dart`, `t61_t70_env.dart`; dashboard-specific: `dashboard_env.dart`, `dashboard_preflight.dart`.

## Env / Secrets Injection

- Use `--dart-define` for integration only. No secrets in repo.
- Contract: `IT_STAGING_CONFIRMED`, `IT_LOGIN_EMAIL`, `IT_LOGIN_PASSWORD` (staging); dashboard-specific: `IT_DASHBOARD_*` for funded wallet, task/request/booking IDs when needed (see FIXTURES).

## Timeout Budgets

- Unit/widget: no retries; default test timeout.
- Integration: locator wait ceiling **20s**; scenario ceiling **120s**.
- One rerun max after failure artifact capture.

## Retry / Flake Policy

- Unit/widget: **zero retries**.
- Integration: **one rerun** only after saving failure artifact to the documented path.

## Failure Artifact Path and Naming

- Directory: `integration_test/artifacts/` (create if missing).
- Naming: `dashboard_<test_id>_<iso_date>T<time>_<brief>.png` or `.txt` (e.g. screenshot, log excerpt).
- Document in RELEASE_CHECKLIST that evidence must be attached for any failed run before rerun.

## Per-Test-ID Matrix

- One behavior per dashboard test ID.
- No bundled multi-behavior tests without explicit approval.
- Map test ID → selector(s), fixture(s), preflight gate, timeout in FIXTURES.

## Selectors / Keys (Stable)

Defined in coordination with Pixel; used by widget and integration tests:

- Role switch: settings button, role options (freelancer/client).
- Overview: wallet ready/empty/error states.
- Bookings: accept / decline / cancel actions.
- Work: start / review / pay actions.
- Inbox: award / pay-now / reject / refund / withdraw.
- Tender payment: submit, loading, error, success.
- Kill-switch / read-only banners when payment is disabled.

(Exact key names to be set when UI is finalized; use semantic keys or `Key('dashboard_role_switch')`-style.)
