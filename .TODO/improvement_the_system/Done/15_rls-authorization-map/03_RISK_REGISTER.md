# 03_RISK_REGISTER

## R1: PII Leakage (Critical)

- **Status**: CURRENT
- **Evidence**: View `public.users` exposes `auth.users` to `anon`.
- **Impact**: Attacker can scrape the entire user database (emails, names).
- **Mitigation**: Drop `public.users`. Enforce self-only `SELECT` on `profiles`.

## R2: RLS Bypass via Views (High)

- **Status**: CURRENT
- **Evidence**: `tasks_mvp` uses `SECURITY DEFINER`.
- **Impact**: Any user can see all tasks regardless of status or ownership.
- **Mitigation**: Change to `SECURITY INVOKER`.

## R3: Privilege Escalation (Medium)

- **Status**: CURRENT
- **Evidence**: `public` role has `UPDATE` permission on `bookings`.
- **Impact**: Potentially allows unauthenticated actors to trigger status transitions if they guess a UUID.
- **Mitigation**: Transition to `authenticated` role-only for all DML.

## R4: Improper Ledger Access (High)

- **Status**: IMPROVED
- **Evidence**: `ledger_lines` policy grants `ALL` to `service_role`.
- **Guard**: Apps only use `authenticated` role which has restrictive SELECT-only or ALL-denied logic.
- **Residual Risk**: A compromised Service Key would allow total financial control.

## R5: Shadow Deletions (Medium)

- **Status**: CURRENT
- **Evidence**: `profiles` has a `DELETE` policy for `public`.
- **Impact**: Potential for unauthenticated user deletion if `uid` check is weak or misconfigured.
- **Mitigation**: Restrict `DELETE` to `authenticated` and verify `uid` matching.
