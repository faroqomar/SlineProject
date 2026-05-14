# Session Log: PLAN_FullAppIntegrationTesting_2026-05-14
**Plan File:** .TODO/PLAN_FullAppIntegrationTesting_2026-05-14.md
**Date Started:** (filled by Executor when execution begins)
**Date Closed:** (filled when session ends)
**Executed By:** (filled by Executor)
**Final Status:** NOT STARTED

---

## Quick Summary
(To be written at session close by Executor)

---

## Agent Improvement Notes
(To be written at session close by Executor)

| Agent | Mistake Made | Rule to Add/Change |
|-------|-------------|-------------------|
| | | |

---

## Session Timeline
(Executor appends all events here as they happen)

### [PLAN CREATED]
- Plan: .TODO/PLAN_FullAppIntegrationTesting_2026-05-14.md
- Created by: @Planner
- Scope: Full SLine app test program covering Unit, Widget, Golden, Integration, RLS/SQL/RPC, static architecture, manual release, app boot, auth, shell, discovery, profile, tasks, tenders, bookings, payments, chat, direct offers, dashboard, work, wallet, notifications, deep links, storage, CI, artifacts, and docs.
- PRISM-equivalent phase in SLine roadmap: QA foundation / release hardening
- Estimated phases in plan: 10
- High-risk areas identified in planning:
  - Local Supabase was not inspectable because Docker is not running.
  - Existing fixture-gated integration tests are skipped when staging values are missing.
  - QiCard/payment tests require sanitized callback expectations and protected internal artifacts.
  - Realtime/chat/notification tests need bounded waits and failure artifacts.
  - `integration_test/chat_creation_test.dart` contains placeholder local anon-key setup.
- Known potential problem areas:
  - Fixture drift.
  - Missing selectors.
  - Payment gateway flake.
  - Realtime timing.
  - RLS policy drift from docs.
  - Long CI runtime.

---

### Notes from Planner to Executor
- Start with the matrix, fixture manifest, selector map, and Supabase reality gate. Do not write broad feature tests before those exist.
- Reuse `test/integration_test/support/helpers.dart`; do not create a second full-app harness.
- Do not add Flutter Driver unless a later profiling phase explicitly needs legacy `flutter drive`.
- Keep all test data non-production and fixture-scoped.
- Any test seam must preserve production defaults and MVVM boundaries.
- Keep skipped tests explicit: every skip needs a matrix row with the missing fixture/env value.

### [PLANCRITIC GATE COMPLETE]
- Gate: `.cursor/Agents/PlanCritic.md`
- Critique artifact: `.TODO/PLAN_CRITIQUE_FullAppIntegrationTesting_2026-05-14.md`
- Corrected source-of-truth plan: `.TODO/PLAN_FullAppIntegrationTesting_2026-05-14.md`
- Evidence read: related TODO artifacts for Auth, Favorites, Dashboard, Proposals, Work, Chat, and the latest VisualQA execution guide.
- Result: the pre-critique draft failed the source-of-truth gate. The rewritten plan now blocks execution until backend target, fixture policy, payment lane, device matrix, and existing placeholder/skipped integration-test treatment are resolved.

### [PLAN REWRITTEN BY PHASE]
- Request: rewrite the plan with a new section for each phase, omit separate visual-baseline and alternate mobile-driver test categories, and provide tests, locations, benefits, and package notes per phase.
- Updated plan: `.TODO/PLAN_FullAppIntegrationTesting_2026-05-14.md`
- Result: the plan now has phases 0-14, each with purpose, tests to implement, locations, benefits, package notes, and a gate.
- Dependency policy: keep the existing `integration_test` + `flutter_test` + SLine helper harness by default. Add packages only when a concrete failure proves the current stack is insufficient.

### [FULL TEST PYRAMID RECHECK]
- Request: recheck the plan so full completion covers Unit tests, Widget tests, Golden tests, Integration tests, and related backend/static/manual gates.
- Updated plan: `.TODO/PLAN_FullAppIntegrationTesting_2026-05-14.md`
- Result: added the Full Test Pyramid Contract, Coverage Ledger Rules, Phase Coverage Summary, Unit/Widget/Golden tracking artifacts, golden command patterns, and a broader Definition of Done.
- Dependency policy: use Flutter's built-in golden support first; consider `golden_toolkit` or `golden_test` only if multi-device/theme/locale golden maintenance becomes too heavy for the built-in API.

### [EXPLICIT PACKAGE MAP ADDED]
- Request: make package mentions obvious for Unit tests, Widget tests, Golden tests, Integration tests, and related layers.
- Updated plan: `.TODO/PLAN_FullAppIntegrationTesting_2026-05-14.md`
- Result: added `Explicit Test Package Map` with use-now packages, conditional add packages, and add commands for each test layer.

### [FINAL PLAN AUDIT]
- Request: last check for everything.
- Updated plan: `.TODO/PLAN_FullAppIntegrationTesting_2026-05-14.md`
- Result: added test ID prefixes for `UT`, `WT`, `GT`, `IT`, `RLS`, `SQL`, `MAN`, and `COV`; clarified that detailed phase scenarios must create matching coverage rows across all required test layers, not only integration rows.

### [TEST LOGGING STRATEGY ADDED]
- Request: add a lightweight test logging strategy that reuses `AppLogger`, prints useful diagnostics mostly on failure, keeps assertions focused on visible UI/state, and avoids unnecessary logging packages.
- Updated plan: `.TODO/PLAN_FullAppIntegrationTesting_2026-05-14.md`
- Result: added `Test Logging Strategy`, Phase 1 logging coverage, failure-only log dump rules, integration step-label requirements, and Definition of Done checks for quiet passing output plus useful failed-test diagnostics.

### [TEST CREDENTIAL ALIASES ADDED]
- Request: add provided test accounts and payment test card information for testing.
- Updated plan: `.TODO/PLAN_FullAppIntegrationTesting_2026-05-14.md`
- Result: added local-only credential handling with `IT_ACCOUNT_1`, `IT_ACCOUNT_2`, and `IT_QICARD_TEST_CARD ending 8582` aliases. Raw passwords, full card number, CVV, and expiration were intentionally not written to tracked docs.

### [LOCAL TEST ENV FILE ADDED]
- Request: user confirmed the raw test values can be added for the test environment.
- Local-only file: `.env.test.local`
- Result: added the raw test account and payment-card values to `.env.test.local`, which is ignored by `.gitignore`; tracked docs continue to use aliases/redacted values.
