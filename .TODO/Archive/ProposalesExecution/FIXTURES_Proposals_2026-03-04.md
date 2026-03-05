# Fixtures: Proposals 2026-03-04

**Purpose**: Deterministic data requirements for proposal unit/widget/integration tests.

## Accounts (roles)

| Fixture | Role | Use |
|---------|------|-----|
| Client owner | `profiles.active_role = 'client'`, owns tasks | Award, pay, reject, resume payment |
| Freelancer | `profiles.active_role = 'freelancer'` | Submit, replace proposal; view pending-payment |
| Unrelated authenticated | Different profile, any role | Negative: no access to others’ proposals |

## Tender / proposal states

| Fixture | Description | Use |
|---------|-------------|-----|
| Open tender, no proposals | One task (tender), status open, 0 task_requests | Submit first proposal |
| Tender with pending proposal | One task, one task_request status pending | Replace, owner review |
| Awarded-unpaid proposal | task_request awarded, task not yet paid | Resume payment, finalize |
| Replace flow | One task, one existing proposal (same bidder) | Replace path |
| Rejected proposal | task_request rejected | Negative UI / no actions |

## Cleanup / reset steps

- After integration tests that create data: delete or mark test task_requests/tasks by test tag or timestamp; or use dedicated test project and truncate.
- Auth: `resetAuthSessionForIntegration(tag: ...)` before login as different role when switching actor.

## Env / secrets

- Do not commit Supabase anon key or service role; use env (e.g. `SUPABASE_URL`, `SUPABASE_ANON_KEY`) or CI secrets.
- Document in repo (e.g. TEST_INFRA or README) that integration tests require configured Supabase project.
