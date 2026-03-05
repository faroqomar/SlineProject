# Dashboard Fixtures and Preconditions

**Plan**: Dashboard Full Remediation v2  
**Date**: 2026-03-01

## Seeded Accounts

- **Client**: staging account with login (IT_LOGIN_EMAIL / IT_LOGIN_PASSWORD or dedicated IT_DASHBOARD_CLIENT_*).
- **Freelancer**: staging account for provider flows (accept/decline, work items).
- Use existing T61T70Env pattern; extend with IT_DASHBOARD_* if needed for dashboard-only scenarios.

## Funded Wallet (Payment Happy Path)

- Precondition: user has sufficient balance for escrow hold.
- Fixture: either seeded balance in staging or use a test wallet ID / amount from env (IT_DASHBOARD_WALLET_MIN_BALANCE or skip test when not set).
- Fail-fast: if payment integration requires real QiCard flow, preflight blocks and test is skipped with reason.

## Insufficient Funds / Expired Payment

- **Insufficient funds**: stub or staging state where balance < required hold; expect LedgerService to return ok:false with ERR_INSUFFICIENT_FUNDS; UI must not advance to pay_awarded_offer.
- **Expired payment**: task_request or booking past payment deadline; expect rejection and no state advance.
- Fixtures: documented staging rows or unit test mocks; integration may be manual with postconditions.

## Task / Request / Booking IDs

- For integration or manual scripts: document required IDs (task_id, task_request_id, booking_id) when tests depend on seeded data.
- Source: staging DB or --dart-define (IT_DASHBOARD_TASK_ID, etc.); preflight checks presence and skips if missing.

## Fail-Fast Reset / Cleanup

- No destructive cleanup in shared staging; tests must not mutate critical production data.
- Reset: tests assume clean state or idempotent behavior; if a test creates data, it should use unique identifiers (e.g. task title with timestamp).
- Cleanup rules: document in RELEASE_CHECKLIST; no automated drop/truncate of shared tables.
