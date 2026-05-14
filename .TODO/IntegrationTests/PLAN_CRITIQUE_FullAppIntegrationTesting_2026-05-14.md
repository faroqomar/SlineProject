# PlanCritic Gate: Full-App Integration Testing

Date: 2026-05-14
Reviewed plan: `.TODO/PLAN_FullAppIntegrationTesting_2026-05-14.md` pre-critique draft
Corrected plan: `.TODO/PLAN_FullAppIntegrationTesting_2026-05-14.md`
Gate owner: one local PlanCritic pass, no spawned subagents

## A) Assumptions + Decision Needed (Blocking)

Assumptions:

- SLine must keep strict MVVM boundaries while adding tests.
- The suite should use `test/integration_test/` as the canonical app-driven integration-test root unless a file is explicitly an external driver test.
- Existing archived TODOs are evidence, not current truth. Their selector paths and artifact paths must be validated against current code.
- Full QiCard gateway automation is unsafe for CI unless a dedicated mock/seam exists.
- The current local Supabase environment is not proven available because local Supabase status previously depended on Docker being available.

Blocking decisions:

1. Backend target: choose dedicated staging/non-production Supabase or local Supabase with Docker and seeds confirmed.
2. Fixture mutation policy: choose namespaced fixtures and cleanup rules before writing stateful tests.
3. Payment strategy: choose automated demo/seeded callback lane plus manual QiCard release lane.
4. Device matrix: choose minimum devices for full-app proof and CI smoke.
5. Existing test treatment: repair, quarantine, or block current placeholder/skipped/hardcoded integration tests before expanding coverage.

## B) Gate Status

Gate 0: Test Infrastructure
Status: FAIL

- The draft planned artifacts but did not require them before execution.
- Existing placeholders and hardcoded test files were named but not made a hard gate.
- Artifact paths conflicted across prior TODOs and were not normalized.
- Preflight strategy existed but was not centralized enough for full-app use.

Gate 1: Data and Contracts
Status: FAIL

- Backend target and fixture ownership were not decided.
- Stale auth/favorites/proposals/dashboard TODOs were not reconciled against current selectors and helper files.
- The plan did not require a fixture manifest before stateful test work.

Gate 2: Security and RLS
Status: PARTIAL FAIL

- The draft mentioned RLS but did not require an actor/object matrix before tests.
- It did not tie every negative authorization check to a user-facing integration flow.
- Supabase client behavior vs service-role/admin behavior was not separated tightly enough.

Gate 3: Backend and Supabase
Status: FAIL

- The plan did not block on local/staging Supabase confirmation.
- It did not require diagram/doc updates if testing revealed process drift.
- Payment, callback, realtime, and storage fixtures were too broad and not fixture-ID driven.

Gate 4: UI and Integration
Status: FAIL

- The draft was broad enough to sound complete but not decomposed enough per route, state, actor, and device.
- It did not convert VisualQA known issues into explicit regression targets.
- It did not fully reconcile stale selectors from archived TODOs.

Gate 5: Release and QA
Status: FAIL

- CI grouping was useful but not strict enough to keep manual payment tests out of normal CI.
- Reporting labels from the VisualQA guide were not adopted as the standard.
- Existing skipped tests could still give false confidence.

## C) Critical Gaps

1. No hard source-of-truth artifact gate before execution.
2. No backend target decision.
3. No payment automation/manual split.
4. No fixture manifest as a prerequisite.
5. No current selector inventory before test writing.
6. Existing hardcoded/skipped/placeholder tests could stay broken while new plans claim coverage.
7. Stale TODO conflicts were not elevated to plan corrections.
8. VisualQA regressions were not explicit test cases.
9. Artifact path and naming policy were inconsistent.
10. RLS checks were not tied to actors and UI flows.
11. Device coverage was underspecified.
12. Docs/diagram closure was present but not strict enough.

## D) Invariants & Success Criteria

Invariants:

- Views never call Supabase.
- ViewModels do not gain test-only Supabase shortcuts.
- RLS remains enforced by Supabase policies and RPCs.
- Payment lifecycle rules stay backend-enforced.
- Stored media references remain paths, not signed URLs.
- Production data and secrets are never used.
- Logs use `AppLogger`.
- Tests use bounded waits.
- Fixture cleanup is namespaced and explicit.

Success criteria:

1. Required matrix, fixture, selector, env, RLS, artifact, runbook, and topology files exist.
2. Existing placeholder/skipped/hardcoded tests are repaired or clearly quarantined.
3. Core app smoke runs against the approved backend target.
4. High-risk flows have automated tests or a manual release lane.
5. RLS negative checks cover owner, participant, unrelated authenticated, and signed-out actors.
6. CI has smoke, backend-gated, nightly/full, and manual-release groups.
7. Docs and diagrams reflect actual implementation.

## E) Risk Register

| Risk | Severity | Mitigation |
| --- | --- | --- |
| Tests mutate production/shared data | Critical | Non-production backend gate plus namespaced fixtures |
| QiCard flow is falsely automated | Critical | Automated seeded/demo lane plus manual release lane |
| Realtime tests flap | High | Seeded conversations, bounded waits, actor-specific assertions |
| Stale TODO selectors drive broken tests | High | Regenerate selector inventory from current code |
| Skipped tests hide missing coverage | High | Matrix every skip with blocker ID |
| CI is too slow or brittle | Medium | Split smoke/backend/nightly/manual groups |
| Docs drift | Medium | DocsKeeper closure phase |
| Payment metadata leaks into artifacts | High | Redaction policy and manual evidence rules |

## F) Pre-Mortem

The likely failure mode is that broad integration tests are written against whatever staging data happens to exist, then CI becomes flaky and the team disables the suite. The second likely failure mode is claiming payment coverage because a WebView opened, while the post-return booking/dashboard state still fails. The third likely failure mode is stale archived selector maps causing tests to fail or pass for irrelevant reasons.

The corrected plan prevents this by making backend target, fixtures, selectors, artifacts, payment lane, and existing-test repair mandatory before broad authoring starts.

## G) Plan Fixes

1. Rewrote the source plan as a gated execution system.
2. Added blocking decisions and hard stop conditions.
3. Added required artifacts for matrix, fixtures, selectors, env, RLS, artifacts, runbook, and topology.
4. Normalized canonical test root and artifact path.
5. Added stale TODO conflict handling.
6. Added VisualQA known issues as regression targets.
7. Split payment into automated and manual lanes.
8. Added explicit RLS matrix requirements.
9. Added CI grouping and release-reporting rules.
10. Added topology diagram and docs closure.

## H) Corrected Plan

The corrected source-of-truth plan is persisted at:

- `.TODO/PLAN_FullAppIntegrationTesting_2026-05-14.md`

Execution must follow the rewritten file and must not use the pre-critique draft.

## I) Change Report

Changed:

- Converted the plan from a broad implementation roadmap into a gated source-of-truth plan.
- Added blocking decisions and hard stop conditions.
- Added required artifacts for matrix, fixtures, selectors, env, RLS, artifacts, runbook, and topology.
- Added exact existing-test repair targets.
- Added stale TODO conflict notes.
- Added payment-lane separation.
- Added device and CI grouping expectations.

Preserved:

- Full-app integration-test goal.
- Flutter `integration_test` direction.
- Planner/PlanCritic workflow.
- SLine MVVM, Supabase, RLS, and documentation constraints.
