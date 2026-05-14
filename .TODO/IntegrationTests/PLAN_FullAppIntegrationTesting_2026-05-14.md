# Source-of-Truth Plan: Full-App Test Coverage

Date: 2026-05-14
Status: Rechecked and expanded for full test-pyramid coverage
Critique gate: `.TODO/PLAN_CRITIQUE_FullAppIntegrationTesting_2026-05-14.md`
Session log: `docs/LOG/SESSION_PLAN_FullAppIntegrationTesting_2026-05-14.md`

This is the source-of-truth plan for building SLine's full app test program. It covers Unit tests, Widget tests, Golden tests, Integration tests, backend/RLS checks, SQL/RPC checks, static architecture checks, and manual release gates where automation is unsafe.

## Goal

Build a complete, organized, repeatable testing system for the whole SLine app: auth, account state, role switching, discovery, search, profile, favorites, tender creation, proposals, booking, payments, chat, notifications, dashboard, wallet, work management, direct offers, deep links, storage-backed media, safety surfaces, and Supabase/RLS boundaries.

The output is a tracked testing system, not a loose set of test files. Every app surface must connect to a test ID, test layer, fixture requirement, selector map, golden target where visual stability matters, run command, artifact location, status label, and benefit.

## Non-Negotiable Rules

1. Use the current app-driven `integration_test` approach with `WidgetTester` for end-to-end app flows.
2. Reuse `test/integration_test/support/helpers.dart` before adding new harness code.
3. Keep tests under `test/integration_test/` unless a file is explicitly a root device test already living under `integration_test/`.
4. Do not add Supabase calls, navigation shortcuts, or business logic to Views for test convenience.
5. Do not mutate production data.
6. Do not commit secrets, shared passwords, card details, or raw payment gateway metadata.
7. Every skipped or blocked test must have a matrix row and a blocker reason.
8. Every external-payment test must use either a safe automated lane or a manual release lane.
9. Every phase must update the coverage ledger, matrix, fixtures, selectors, golden matrix, and runbook if it changes their scope.
10. Golden tests are required for stable visual contracts, but they do not replace Widget or Integration tests.

## Current Dependency Baseline

Already present in `pubspec.yaml`:

- `flutter_test`
- `integration_test`
- `mocktail`
- `postgrest`
- app dependencies used by tests through the app, including `supabase_flutter`, `shared_preferences`, `uuid`, `webview_flutter`, `app_links`, `cached_network_image`, and `sentry_flutter`

Do not add packages at the start of this plan. Add a package only when a concrete test failure proves the current stack cannot cover the target cleanly.

## Explicit Test Package Map

This is the package/source-of-truth map for what each test layer should use.

| Test layer | Use now | Add only if needed | Command to add | Notes |
| --- | --- | --- | --- | --- |
| Unit tests | `flutter_test`, `mocktail` | `fake_async` | `flutter pub add --dev fake_async` | Use for ViewModels, services, models, mappers, guards, retry logic, cache logic, payment state, and error mapping. Add `fake_async` only if timer/Future/Stream behavior needs deterministic virtual time. |
| Widget tests | `flutter_test`, `mocktail` | `network_image_mock`, `image_picker_platform_interface`, `webview_flutter_platform_interface` | `flutter pub add --dev network_image_mock image_picker_platform_interface webview_flutter_platform_interface` | Use for screens, shared widgets, forms, cards, modals, sheets, loading/empty/error states, and role-specific states. Add image/picker/webview helpers only when those widgets cannot be tested cleanly with the current stack. |
| Golden tests | Flutter built-in golden assertions from `flutter_test` | `golden_toolkit` preferred if compatible; `golden_test` only after package review | `flutter pub add --dev golden_toolkit` or `flutter pub add --dev golden_test` | Use for stable visual contracts across primary screens, shared components, payment/chat/dashboard cards, modal/sheet layouts, theme states, sizes, and critical locales. Do not add both golden helpers. Start with built-in `matchesGoldenFile`, then add one helper only if multi-device/theme/locale maintenance becomes painful. |
| Integration tests | `integration_test`, `flutter_test`, current `test/integration_test/support/helpers.dart` | none by default | Already present | Use for real app flows across Provider state, routing, Supabase fixtures, storage, realtime, payment recovery, dashboard reflection, and deep links. Do not add a separate mobile-driver framework unless a concrete native-device limitation appears. |
| RLS/backend/client-policy tests | `flutter_test`, `postgrest`, app `supabase_flutter` dependency | none by default | Already present | Use for authenticated client-style policy checks, RLS boundary assertions, and service/RPC behavior. SQL-level tests stay in `supabase/tests/` and use Supabase/Postgres tooling, not a Dart package. |
| Static/architecture/coverage checks | `very_good_analysis`, Flutter analyzer, existing architecture guard, `flutter test --coverage` | `lcov`/`genhtml` as local tooling if readable HTML reports are needed | not a Dart dependency | Use to enforce MVVM boundaries, formatting, linting, coverage floors, forbidden imports, AppLogger usage, and generated coverage reports. |
| Artifact/helper tests | `flutter_test`, Dart `io` where safe | `file` | `flutter pub add --dev file` | Add only if artifact writer tests need an in-memory filesystem instead of writing to disk. |
| Test logging and failure diagnostics | existing `AppLogger`, `flutter_test`, integration helper wrappers | none by default | Already present | Reuse `AppLogger` with a lightweight test sink/recorder if needed. Dump buffered logs and step labels only when a test fails. |
| Manual release/device checks | no package | none by default | not applicable | Use runbook-driven checks for external QiCard, push delivery, real-device quirks, and anything unsafe for CI automation. |

Issue-driven package additions:

| Issue encountered | Package to consider | Why |
| --- | --- | --- |
| Golden tests become repetitive across themes, locales, and devices | `golden_toolkit` or `golden_test` | Adds structure on top of Flutter's built-in golden APIs for multi-device/theme/locale snapshots |
| Helper-level retry/timer tests need deterministic virtual time outside normal widget pumping | `fake_async` | Lets helper tests control timers without waiting in real time |
| Signed-image or network-image widget fallback tests fail because network loading is disabled in the test environment | `network_image_mock` | Allows non-device widget coverage for image fallback behavior |
| Artifact writer needs in-memory filesystem tests instead of writing to disk | `file` | Supports filesystem abstraction for helper unit tests |
| Attachment picker seams need non-device widget testing | `image_picker_platform_interface` | Allows platform-channel behavior to be mocked in widget-level tests |
| Payment WebView behavior needs widget-level platform mocking separate from full manual payment verification | `webview_flutter_platform_interface` | Allows WebView controller/platform behavior to be faked for non-external payment tests |

## Test Logging Strategy

Purpose: make failed automated tests easier to debug by exposing meaningful app logs and test-step labels while keeping production logging clean.

### Principles

1. Reuse the existing `AppLogger` architecture.
   - Production code keeps calling `AppLogger.d/i/w/e/api`.
   - Do not create a parallel logger for tests.
   - Do not add a logging package unless the existing static logger cannot be safely captured.

2. Add the smallest test-friendly seam if needed.
   - Preferred implementation: add an optional static test sink/writer hook inside `AppLogger` with production default behavior still using `debugPrint`.
   - Tests can attach a `TestLogSink` or `TestLogRecorder` that buffers formatted `AppLogger` lines in memory.
   - The sink must be reset in `tearDown` so tests cannot leak logger state into each other.
   - If changing `AppLogger` is not needed, capture logs through test helper wrappers around existing output instead.

3. Print logs mainly on failure.
   - Passing tests should stay quiet.
   - On failure, the helper dumps:
     - test ID and test name
     - current step label
     - completed step labels
     - buffered `AppLogger` lines
     - integration fixture IDs and backend target if available
     - failure screenshot/artifact path if available

4. Use step labels for integration flows.
   - Integration helpers should expose a small `step('label', () async { ... })` wrapper.
   - Step labels should be human-readable and specific, for example `IT08 payment: tap checkout`, `IT09 chat: wait for recipient message`, or `IT03 auth: submit invalid password`.
   - A failed integration test should identify the exact last step without requiring a full log scan.

5. Keep assertions focused on behavior.
   - Unit tests assert return values, state transitions, error mapping, and service outcomes.
   - Widget tests assert visible widgets, state rendering, SnackBars, dialogs, and navigation effects.
   - Integration tests assert visible UI, app state, backend effects, and route outcomes.
   - Do not assert on log messages except for narrow tests of the test sink/recorder itself.

6. Test SnackBars and toasts through the UI.
   - If a flow shows a SnackBar, toast, dialog, banner, or inline error, assert it with `find.text`, `find.byKey`, or visible widget state.
   - Logs may explain why a SnackBar appeared, but they are not the source of truth for the user-visible behavior.

7. Protect secrets and payment data.
   - Keep `AppLogger` token masking.
   - Test log dumps must redact passwords, auth tokens, card/CVV data, payment gateway raw metadata, signed URLs, and private fixture values.
   - Manual payment artifacts follow the same redaction policy.

### Planned Logging Helpers

- `test/helpers/test_log_recorder.dart`
  - Buffers `AppLogger` output for Unit and Widget tests.
  - Provides `dumpOnFailure` behavior.
  - Resets `AppLogger.currentLevel` and any test sink in `tearDown`.

- `test/integration_test/support/logged_test.dart`
  - Provides `loggedTestWidgets(testId, description, body)` and `step(label, body)` wrappers.
  - Captures current step and completed steps.
  - Dumps buffered logs only when the test body throws.

- `test/integration_test/support/artifacts.dart`
  - Includes log dump metadata in the same artifact folder as screenshots and failure notes.

### Logging Test Coverage

- `UT01.LOG.1`: test recorder buffers `AppLogger` output without printing during success.
- `UT01.LOG.2`: test recorder dumps buffered logs when a wrapped test fails.
- `UT01.LOG.3`: test recorder redacts secrets and payment-like fields.
- `WT01.LOG.1`: SnackBar/toast assertions are made through visible UI, not log text.
- `IT01.LOG.1`: integration step wrapper reports the last active step on failure.
- `IT01.LOG.2`: integration artifact metadata includes test ID, step labels, backend target, and fixture IDs.

### Gate

Phase 1 is not complete until failed-test diagnostics include meaningful app logs and step labels without noisy output from passing tests.

## Full Test Pyramid Contract

Every feature phase must close coverage at the right layer. A phase is not complete because one integration flow passes.

| Layer | What it proves | Required locations | Required for full-app completion |
| --- | --- | --- | --- |
| Unit tests | Pure logic, models, mappers, services, ViewModels, guards, error mapping, cache/retry/payment state machines | `test/unit/`, `test/features/`, `test/core/`, `test/helpers/` | Every ViewModel, service, mapper, payment/realtime helper, auth guard, and critical model touched by the app surface |
| Widget tests | A screen/component renders states and handles local interactions with mocked ViewModels/services | `test/widget/`, `test/core/widgets/`, feature-specific widget test folders | Every primary screen, shared component, form, card, modal, sheet, empty/loading/error state, and role-specific state |
| Golden tests | Stable visual contracts for screens/components across supported states, themes, sizes, and critical locales | `test/golden/`, `test/golden/<feature>/`, `test/golden/core/`, `test/golden/screens/` | Every primary screen shell, high-risk shared component, payment/chat/dashboard card, modal/sheet, and redesigned visual surface |
| Integration tests | Real app flows across screens, Provider state, Supabase fixtures, routing, realtime, storage, and payment recovery | `test/integration_test/`, legacy `integration_test/` only when explicitly migrated or quarantined | Every critical user journey from login to marketplace action to post-action dashboard/chat/wallet state |
| RLS/SQL/RPC tests | Backend authorization, database invariants, RPC transitions, storage policies, and payment lifecycle safety | `test/rls/`, `supabase/tests/`, targeted `test/integration_test/security/` | Every protected table/object and every money/workflow-changing RPC |
| Static and architecture checks | MVVM boundaries, linting, formatting, forbidden imports, logging, token usage, and query boundaries | `.github/workflows/ci.yml`, architecture guard scripts, `flutter analyze`, `dart format` | Every PR and every full test-program closure |
| Manual release checks | External payment gateway, real device quirks, push notification delivery, and flows unsafe for CI automation | `.TODO/RUNBOOK_FullAppIntegration_2026-05-14.md`, `test/integration_test/manual_release/`, artifact notes | Every external dependency that cannot be reliably or safely automated |

## Coverage Ledger Rules

The test program must maintain one row per app surface or backend contract in `.TODO/TEST_COVERAGE_LEDGER_FullApp_2026-05-14.md`.

Required columns:

- Surface or contract
- Source file(s)
- Unit test path/status
- Widget test path/status
- Golden test path/status
- Integration test path/status
- RLS/SQL/RPC test path/status
- Manual release check path/status
- Fixture ID(s)
- Last command run
- Artifact path
- Blocker or gap

Any row with a missing required layer must be marked `BLOCKED`, `NOT_APPLICABLE_WITH_REASON`, or `DONE`. Empty cells are not allowed.

## Test ID Prefixes

Use these prefixes in the coverage ledger and matrices:

- `UT`: Unit test
- `WT`: Widget test
- `GT`: Golden test
- `IT`: Integration test
- `RLS`: RLS/backend/client-policy test
- `SQL`: SQL/RPC/database invariant test
- `MAN`: Manual release or real-device check
- `COV`: Coverage ledger, matrix, docs, or reporting validation

The detailed phase sections below list the main scenario coverage. For each scenario, execution must add or verify the matching `UT`, `WT`, `GT`, `IT`, `RLS`/`SQL`, and `MAN` rows required by the Phase Coverage Summary. A phase is not complete when only the `IT` rows pass.

## Blocking Decisions Before Implementation

Record these in `.TODO/RUNBOOK_FullAppIntegration_2026-05-14.md` before writing broad feature tests.

1. Backend target
   - Preferred: dedicated non-production Supabase project.
   - Alternative: local Supabase after Docker and seed scripts are confirmed.
   - Required evidence: `IT_STAGING_CONFIRMED=true` for staging or successful `supabase status` for local.

2. Fixture policy
   - Required: namespaced fixture users and rows with cleanup rules.
   - Required actors: client, freelancer, unrelated authenticated user, signed-out state.

3. Payment policy
   - Automated lane: demo payment or seeded callback/recovery.
   - Manual lane: controlled QiCard simulator/manual pass with redacted screenshots.
   - CI must not depend on entering external card details.

4. Device matrix
   - Minimum execution matrix: iOS simulator plus Android emulator smoke.
   - Web smoke only for flows that the app supports reliably on web.
   - Each test ID must state supported devices and blocked devices.

5. Existing-test treatment
   - `integration_test/chat_creation_test.dart` must be migrated, quarantined, or blocked because it contains hardcoded placeholder Supabase config.
   - `test/integration_test/favorites_cross_feature_flow_test.dart` must be implemented or explicitly blocked.
   - `test/integration_test/proposals/proposal_flows_placeholder_test.dart` must be implemented or explicitly blocked.

## Provided Test Credentials Handling

The user provided two seeded test accounts and one payment test card for test execution. Do not write raw passwords, full card numbers, CVV values, or full expiration values into tracked repo files.

Local setup note:

- Raw test values for this machine may live in `.env.test.local`.
- `.env.test.local` is ignored by the repo's existing `.gitignore` rule `.env.*.local`.
- Tracked docs, matrices, logs, screenshots, and artifacts must keep using aliases/redacted values.

### Test Accounts

Use these aliases in fixtures, matrices, and runbooks:

| Alias | Email | Secret handling | Primary use |
| --- | --- | --- | --- |
| `IT_ACCOUNT_1` | `1test@test.com` | Password provided by user; store only in local shell env or ignored `.env.test.local` | Client/account-one flows, auth smoke, owner-side assertions |
| `IT_ACCOUNT_2` | `2test@test.com` | Password provided by user; store only in local shell env or ignored `.env.test.local` | Freelancer/account-two flows, cross-account visibility, proposals/chat/realtime |

Recommended local-only variables:

```bash
export IT_ACCOUNT_1_EMAIL='1test@test.com'
export IT_ACCOUNT_1_PASSWORD='<provided-out-of-band>'
export IT_ACCOUNT_2_EMAIL='2test@test.com'
export IT_ACCOUNT_2_PASSWORD='<provided-out-of-band>'
```

Compatibility with existing tests:

- Existing single-login tests may continue using `IT_LOGIN_EMAIL` and `IT_LOGIN_PASSWORD`.
- Cross-account tests should use `IT_ACCOUNT_1_EMAIL`, `IT_ACCOUNT_1_PASSWORD`, `IT_ACCOUNT_2_EMAIL`, and `IT_ACCOUNT_2_PASSWORD`.
- If an existing helper only accepts `IT_LOGIN_EMAIL` / `IT_LOGIN_PASSWORD`, the run command can map account one into those values.

### Payment Test Card

Use a manual-payment alias instead of raw card values:

| Alias | Redacted identity | Secret handling | Primary use |
| --- | --- | --- | --- |
| `IT_QICARD_TEST_CARD` | card ending `8582` | Full PAN, CVV, and expiration were provided by the user; store only in local shell env or ignored `.env.test.local` | Manual QiCard simulator/release lane only |

Recommended local-only variables:

```bash
export IT_QICARD_PAN='<provided-out-of-band>'
export IT_QICARD_CVV='<provided-out-of-band>'
export IT_QICARD_EXPIRY='<provided-out-of-band>'
```

Rules:

- Do not commit raw card values.
- Do not print raw card values in logs, failure dumps, screenshots, or artifacts.
- Use the label `IT_QICARD_TEST_CARD ending 8582` in matrices and reports.
- Automated CI should use demo/seeded callback/payment recovery lanes. Full external-card entry stays manual unless a safe gateway test seam exists.

## Required Tracking Artifacts

Create these before broad test implementation:

1. `.TODO/TEST_COVERAGE_LEDGER_FullApp_2026-05-14.md`
   - One row per app surface/backend contract with Unit, Widget, Golden, Integration, RLS/SQL/RPC, Manual, fixture, command, artifact, and blocker columns.

2. `.TODO/INTEGRATION_TEST_MATRIX_FullApp_2026-05-14.md`
   - Test ID, suite, flow, role, device, route/screen, backend objects, fixture IDs, command, artifact path, status, blocker, owner, last run.

3. `.TODO/UNIT_WIDGET_TEST_MATRIX_FullApp_2026-05-14.md`
   - Unit/widget test ID, source file, mocked dependency, state covered, command, status, and blocker.

4. `.TODO/GOLDEN_TEST_MATRIX_FullApp_2026-05-14.md`
   - Golden target, state, theme, size/device, locale, fixture/stub, image path, update command, approval status, and blocker.

5. `.TODO/FIXTURES_FullAppIntegration_2026-05-14.md`
   - Fixture ID, actor, table/object, seed source, cleanup rule, related tests, required dart-defines, safety note.

6. `.TODO/SELECTORS_FullAppIntegration_2026-05-14.md`
   - Current keys, dynamic keys, stale TODO conflicts, missing keys, selector additions required.

7. `.TODO/ENV_FullAppIntegration_2026-05-14.md`
   - `IT_STAGING_CONFIRMED`, account aliases, local-only credential variable names, fixture IDs, payment-card alias, payment flags, device IDs, local/staging choice.

8. `.TODO/RLS_MATRIX_FullAppIntegration_2026-05-14.md`
   - Owner, participant, unrelated authenticated user, and signed-out access for each protected object.

9. `.TODO/ARTIFACT_POLICY_FullAppIntegration_2026-05-14.md`
   - Artifact path, naming, retention, redaction, failure screenshot policy, log policy.

10. `.TODO/RUNBOOK_FullAppIntegration_2026-05-14.md`
   - Local run commands, staging run commands, CI groups, manual payment runbook, cleanup commands.

11. `docs/diagrams/FullAppTestCoverageTopology.md`
   - Test topology for Unit, Widget, Golden, Integration, RLS/SQL/RPC, app helpers, fixtures, Supabase, payment lane, realtime lane, artifacts, and CI.

12. `test/integration_test/artifacts/README.md`
   - Explains generated integration artifacts, failure log dumps, step labels, and redaction rules.

13. `test/golden/README.md`
   - Explains golden update, review, approval, font/image stabilization, and artifact rules.

## Phase Coverage Summary

This table is the recheck gate for full-app coverage. Each phase still has detailed test summaries below, but completion requires the relevant layers here.

| Phase | Unit coverage | Widget coverage | Golden coverage | Integration coverage | Backend/RLS/SQL coverage | Manual/static coverage |
| --- | --- | --- | --- | --- | --- | --- |
| Phase 0 | Coverage-ledger validators and matrix parsing helpers | Matrix/readme rendering checks if docs helpers are added | Not applicable with reason: no app UI | Existing-test classification only | Backend target decision recorded | Plan gate, docs gate, source inventory |
| Phase 1 | Harness helpers, metadata builders, artifact naming, preflight result mapping, test log recorder | Minimal harness smoke around launch states and UI-visible SnackBar/toast assertions | Not applicable with reason: no product UI | Startup smoke through shared harness with logged step labels | Backend/preflight confirmation | Artifact policy, failure capture proof, failure-only log dump |
| Phase 2 | Fixture builders, cleanup filters, RLS result mappers | Fixture/preflight status widgets if any are app-visible | Not applicable with reason: backend contract phase | Fixture login/preflight smoke | RLS/SQL/RPC matrix and seed checks | Non-production target proof |
| Phase 3 | Auth ViewModels, validators, auth services, error mapping, session guards | Login, signup, forgot/reset screens in loading/error/success states | Auth screens and form states at supported sizes/themes | Login, logout, signup route sanity, password recovery | Auth/RLS session boundary checks | Account-state runbook |
| Phase 4 | NavigationProvider, theme provider, role-switch logic, settings actions | Shell, bottom nav, settings sheet, role switch controls | Main shell, bottom nav, settings/role sheet | Shell navigation, role switching, logout/settings paths | Role permission smoke if backend state changes | Architecture guard and route inventory |
| Phase 5 | Home/search/favorites/profile ViewModels, filters, mappers, favorite service | Discovery cards, search states, favorites list/card, profile/portfolio states | Home feed, search results, favorite card/list, public profile, portfolio sections | Feed, search, category, favorite, profile, saved flows | Favorites/profile/storage read boundaries | VisualQA feed visibility recheck |
| Phase 6 | Create-task ViewModel/service, validators, package/attachment guards | Create task, task detail, package/direct booking entry, attachment states | Create-task form, task detail, package card, attachment/error states | Create tender, task detail, direct booking entry, attachment smoke | Task insert/read/update policy and storage path checks | Cleanup proof for created rows |
| Phase 7 | Proposal/task-request services, award/reject/replace state machines | Proposal sheets/cards, request tile states, award/reject dialogs | Proposal state cards, request tile, award/reject/payment entry surfaces | Submit, replace, reject, award, retry-payment entry | Proposal/task-request RLS and award RPC checks | Placeholder elimination proof |
| Phase 8 | Payment services, PaymentPendingStore, wallet services, booking state mappers | Booking details, payment return, wallet/history, dashboard payment widgets | Booking card/detail, payment return states, wallet card/history, dashboard booking state | Booking lifecycle, payment recovery, wallet/dashboard reflection | Payment/booking/wallet RLS, RPC, callback invariants | Manual QiCard release lane |
| Phase 9 | Chat services, direct-offer services, notification/deep-link mappers, retry logic | Chat list/screen, message bubbles, direct-offer sheets, notification modal | Chat conversation, message bubble states, direct-offer card/sheet, notification modal | Realtime chat, direct offer, notification tap, deep-link fallback | Chat/direct-offer/notification RLS | Push/external notification manual notes |
| Phase 10 | Dashboard/work/order ViewModels and summary calculators | Dashboard tabs, work tabs/details, management/order states, next actions | Dashboard overview/cards, work item/detail, management list, next actions | Dashboard/work/order navigation and post-action state | Work/booking/task visibility policy checks | Operational release checklist |
| Phase 11 | Signed media services, cache wrappers, error mapper, safety services/ViewModels | SignedAvatar/Image, media fallbacks, safety/report/block screens, error states | Media placeholders, error states, safety surfaces, shared widgets | Media rendering, fallback paths, safety submission smoke | Storage bucket policy and safety/RLS boundaries | Cache/performance and redaction checks |
| Phase 12 | Authorization guards, policy client helpers, RPC invariant helpers | User-safe denial/error surfaces | Not applicable unless denial UI is visual-critical | Negative app flows for protected surfaces | Full RLS/SQL/RPC/storage negative matrix | Security review and architecture guard |
| Phase 13 | CI grouping scripts/helpers, coverage parser, flake classifier | Report/status widgets if any are generated | Golden CI update/review workflow smoke | Smoke/backend/full group execution | Backend-gated group fail-closed behavior | CI workflow, coverage threshold, artifact report |
| Phase 14 | Coverage-ledger consistency helpers if scripted | Docs/runbook validation widgets only if rendered | Golden manifest completeness check | Matrix vs test-file reconciliation | RLS/doc consistency check | Docs, diagrams, handoff, session log |

## Phase 0: Test Program Contract

### Purpose

Turn the plan into a controlled test program before any broad app-flow work begins.

### Tests To Implement

- `COV00.1`: full coverage ledger creation and validation checklist.
- `COV00.2`: Unit/Widget/Golden/Integration/RLS coverage status for every app surface.
- `COV00.3`: fixture manifest completeness checklist.
- `COV00.4`: selector inventory scan from current Dart code.
- `COV00.5`: existing Unit, Widget, Integration, and backend test classification.
- `COV00.6`: Golden target matrix creation and approval policy.
- `COV00.7`: backend/payment/device decision recording.

### Locations

- `.TODO/TEST_COVERAGE_LEDGER_FullApp_2026-05-14.md`
- `.TODO/INTEGRATION_TEST_MATRIX_FullApp_2026-05-14.md`
- `.TODO/UNIT_WIDGET_TEST_MATRIX_FullApp_2026-05-14.md`
- `.TODO/GOLDEN_TEST_MATRIX_FullApp_2026-05-14.md`
- `.TODO/FIXTURES_FullAppIntegration_2026-05-14.md`
- `.TODO/SELECTORS_FullAppIntegration_2026-05-14.md`
- `.TODO/ENV_FullAppIntegration_2026-05-14.md`
- `.TODO/RUNBOOK_FullAppIntegration_2026-05-14.md`

### Benefits

- Prevents broad tests from being written against unknown backend state.
- Forces stale archived TODO data to be reconciled with current code.
- Gives every later Unit, Widget, Golden, Integration, RLS/SQL/RPC, and Manual test an owner, command, fixture source, artifact path, and status.

### Package Notes

No package additions.

### Gate

Do not enter Phase 1 until all required tracking artifacts exist and every known app surface has a coverage-ledger row.

## Phase 1: Harness, Preflight, and Failure Artifacts

### Purpose

Make tests deterministic, debuggable, and safe to rerun.

### Tests To Implement

- `IT01.1`: app launcher reaches either login screen or authenticated shell.
- `IT01.2`: clean-session launch resets auth state when required.
- `IT01.3`: preflight blocks missing staging/local confirmation.
- `IT01.4`: preflight blocks missing actor credentials.
- `IT01.5`: failure artifact capture writes screenshot/log metadata.
- `IT01.6`: helper waits fail with clear reason rather than hanging.
- `UT01.LOG.1`: test log recorder buffers `AppLogger` output and stays quiet on success.
- `UT01.LOG.2`: test log recorder dumps logs only when a wrapped test fails.
- `UT01.LOG.3`: test log recorder redacts secret/payment-like values.
- `IT01.LOG.1`: integration step wrapper reports the active step on failure.
- `IT01.LOG.2`: integration artifact metadata includes test ID, step labels, backend target, fixture IDs, and log dump path.

### Locations

- `lib/core/services/logger_service.dart` only if a minimal optional test sink hook is needed.
- `test/helpers/test_log_recorder.dart`
- `test/integration_test/support/helpers.dart`
- `test/integration_test/support/preflight.dart`
- `test/integration_test/support/logged_test.dart`
- `test/integration_test/support/artifacts.dart`
- `test/integration_test/support/test_metadata.dart`
- `test/integration_test/artifacts/README.md`
- `test/integration_test/app_startup_login_flow_test.dart`

### Benefits

- Makes every later phase easier to debug.
- Reduces flake from blind waits.
- Gives repeatable artifact evidence for failures.
- Keeps passing test output quiet while making failed tests show useful `AppLogger` context and exact step labels.
- Preserves behavior-focused assertions by testing SnackBars, toasts, dialogs, banners, and inline errors through visible UI.

### Package Notes

No package additions by default. Reuse `AppLogger`, `flutter_test`, and helper wrappers. If artifact-writer tests need an in-memory filesystem, add `file`.

### Gate

At least one startup smoke test must run through the shared launcher, preflight, logged step wrapper, and artifact policy. A deliberately failing local-only diagnostic check must prove that buffered app logs and step labels are printed only on failure.

## Phase 2: Backend Target, Fixtures, Seeds, Cleanup, and RLS Matrix

### Purpose

Guarantee every stateful test has known actors, known rows, cleanup rules, and RLS expectations.

### Tests To Implement

- `IT02.1`: backend target confirmation test.
- `IT02.2`: seeded client login fixture is valid.
- `IT02.3`: seeded freelancer login fixture is valid.
- `IT02.4`: unrelated authenticated actor fixture is valid.
- `IT02.5`: fixture cleanup dry-run lists only namespaced rows.
- `IT02.6`: RLS matrix smoke for profiles, tasks, task requests, bookings, chats, favorites, wallet, notifications, and storage paths.
- `IT02.7`: `IT_ACCOUNT_1` and `IT_ACCOUNT_2` aliases are mapped to the provided test emails without exposing passwords in tracked files.

### Locations

- `.TODO/FIXTURES_FullAppIntegration_2026-05-14.md`
- `.TODO/RLS_MATRIX_FullAppIntegration_2026-05-14.md`
- `test/integration_test/support/full_app_env.dart`
- `test/integration_test/support/fixture_preflight.dart`
- `test/integration_test/security/rls_matrix_test.dart`
- `supabase/tests/` if SQL-level assertions are added

### Benefits

- Removes dependency on personal/manual staging data.
- Protects production data.
- Connects UI behavior to Supabase policy guarantees.
- Establishes the two provided test accounts as named actors for cross-account tests without committing their shared password.

### Package Notes

No package additions by default. `postgrest` is already present for client-style policy checks.

### Gate

No stateful UI test may run until its fixture IDs and cleanup rules are listed.
Account-password values must be loaded from local env or ignored `.env.test.local`, never from tracked docs.

## Phase 3: Startup, Auth, Signup, Password Recovery, and Session State

### Purpose

Lock down the entry path and account/session lifecycle.

### Tests To Implement

- `IT03.1`: cold start reaches login for signed-out user.
- `IT03.2`: seeded user login succeeds.
- `IT03.3`: invalid login shows user-safe error and remains on login.
- `IT03.4`: logout clears session and returns to login.
- `IT03.5`: session restore reaches main shell.
- `IT03.6`: signup form validates name, email, password, and confirm password.
- `IT03.7`: signup route does not navigate to unrelated task/job detail.
- `IT03.8`: forgot-password validation and success state.
- `IT03.9`: reset-password update validation and success state where safe.
- `IT03.10`: deleted/invalid user session teardown does not crash notification or auth services.

### Locations

- `test/integration_test/auth/auth_startup_flow_test.dart`
- `test/integration_test/auth/auth_signup_flow_test.dart`
- `test/integration_test/auth/password_recovery_flow_test.dart`
- `test/integration_test/app_startup_login_flow_test.dart`
- `lib/features/auth/view/login_screen.dart`
- `lib/features/auth/view/signup_screen.dart`
- `lib/features/auth/view/forgot_password_screen.dart`
- `lib/features/auth/view/reset_password_update_screen.dart`

### Benefits

- Prevents users from getting stuck before entering the app.
- Catches route regressions like signup opening the wrong surface.
- Confirms auth errors are mapped to user-safe messages.

### Package Notes

No package additions.

### Gate

Auth keys in old TODO files must be replaced with current keys from the app code.

## Phase 4: App Shell, Navigation, Role Switching, Settings, and Theme State

### Purpose

Verify that the primary app shell can navigate the full product without losing state.

### Tests To Implement

- `IT04.1`: main shell renders after login.
- `IT04.2`: bottom navigation reaches Home, Search/Discovery, Create, Messages, and Dashboard surfaces.
- `IT04.3`: create-task FAB opens the correct route/sheet.
- `IT04.4`: client-to-freelancer role switch works.
- `IT04.5`: freelancer-to-client role switch works.
- `IT04.6`: settings screen or sheet opens and closes.
- `IT04.7`: logout from settings returns to login.
- `IT04.8`: theme or dark-mode row toggles safely if enabled.
- `IT04.9`: support/safety/settings dialogs render and dismiss.
- `IT04.10`: hidden routes and modal-sheet launchers from the UI inventory are reachable where intended.

### Locations

- `test/integration_test/shell/main_shell_navigation_test.dart`
- `test/integration_test/shell/role_switch_settings_test.dart`
- `test/integration_test/dashboard_role_switch_flow_test.dart`
- `lib/app/main_navigation_screen.dart`
- `lib/core/widgets/custom_bottom_nav_bar.dart`
- `lib/features/dashboard/view/dashboard_screen.dart`

### Benefits

- Catches broken navigation early.
- Proves role-sensitive UI can be tested without shortcuts.
- Creates reusable navigation helpers for later phases.

### Package Notes

No package additions.

### Gate

Every route touched here must be listed in the matrix with supported device targets.

## Phase 5: Home, Discovery, Search, Categories, Favorites, Profile, Portfolio, and Saved Surfaces

### Purpose

Cover browsing and relationship-building flows across client and freelancer roles.

### Tests To Implement

- `IT05.1`: Home feed loads seeded records.
- `IT05.2`: pull-to-refresh or provider refresh updates the feed.
- `IT05.3`: newly created tender becomes visible to the creator if expected.
- `IT05.4`: newly created tender becomes visible to another account if expected.
- `IT05.5`: search returns seeded task/freelancer results.
- `IT05.6`: category filter opens filtered results.
- `IT05.7`: public profile opens from discovery.
- `IT05.8`: profile summary and portfolio render seeded data.
- `IT05.9`: favorite freelancer add/remove works.
- `IT05.10`: favorite card opens profile.
- `IT05.11`: favorite card starts chat when fixture allows it.
- `IT05.12`: saved/empty/error states render correctly.

### Locations

- `test/integration_test/discovery/home_discovery_flow_test.dart`
- `test/integration_test/discovery/search_category_flow_test.dart`
- `test/integration_test/profile/public_profile_portfolio_flow_test.dart`
- `test/integration_test/favorites/favorites_cross_feature_flow_test.dart`
- `test/integration_test/favorites_cross_feature_flow_test.dart`
- `lib/features/home/view/`
- `lib/features/search/view/`
- `lib/features/categories/view/`
- `lib/features/profile/view/`
- `lib/features/favorites/view/`
- `lib/features/saved/view/`

### Benefits

- Covers high-traffic browsing paths.
- Replaces the current favorites placeholder with real coverage.
- Converts known VisualQA feed visibility issues into executable tests.

### Package Notes

No package additions by default. If non-device image fallback tests are needed for profile/portfolio images, add `network_image_mock`.

### Gate

Favorites fixture rows and public-profile fixture rows must be listed before implementation.

## Phase 6: Task Creation, Service Packages, Direct Booking Entry, and Attachments

### Purpose

Verify task creation and provider package entry points before proposals and bookings depend on them.

### Tests To Implement

- `IT06.1`: create tender validation for missing title, description, category, budget, and deadline.
- `IT06.2`: create tender success with namespaced marker.
- `IT06.3`: created tender detail route opens.
- `IT06.4`: package/service creation path validates tier, price, and description where present.
- `IT06.5`: direct booking entry opens from provider/package context.
- `IT06.6`: task image attachment path works with safe test media if enabled.
- `IT06.7`: attachment cancel/error state is safe.
- `IT06.8`: create-task flow does not hardcode colors, direct Supabase, or business logic in Views.

### Locations

- `test/integration_test/tasks/create_tender_task_flow_test.dart`
- `test/integration_test/tasks/task_details_flow_test.dart`
- `test/integration_test/booking/direct_booking_entry_flow_test.dart`
- `test/integration_test/create_tender_task_flow_test.dart`
- `lib/features/tasks/view/create_task_screen.dart`
- `lib/features/tasks/view/task_details_screen.dart`
- `lib/features/booking/view/`
- `lib/features/services/view/`

### Benefits

- Proves the app can create and revisit core marketplace objects.
- Provides stable task fixtures for proposal and booking phases.
- Catches broken attachment paths without touching production storage.

### Package Notes

No package additions by default. If attachment picker behavior must be tested outside device integration, add `image_picker_platform_interface`.

### Gate

Created records must use test namespace markers and cleanup rules.

## Phase 7: Proposals, Task Requests, Award, Replacement, Rejection, and Payment Entry

### Purpose

Cover the tender lifecycle from freelancer proposal through client award and payment entry states.

### Tests To Implement

- `IT07.1`: open tender with no proposals.
- `IT07.2`: freelancer submits a proposal.
- `IT07.3`: duplicate proposal is blocked or routes to replacement.
- `IT07.4`: proposal replacement flow works.
- `IT07.5`: rejected proposal state renders correctly.
- `IT07.6`: pending proposal state renders correctly.
- `IT07.7`: awarded-unpaid proposal state renders correctly.
- `IT07.8`: client awards proposal.
- `IT07.9`: freelancer and client see correct role-specific actions.
- `IT07.10`: retry payment button appears only in valid states.
- `IT07.11`: proposal amount prefill/edit regression is covered.
- `IT07.12`: missing resume/payment record fallback is covered.

### Locations

- `test/integration_test/proposals/proposal_submit_replace_flow_test.dart`
- `test/integration_test/proposals/proposal_award_state_flow_test.dart`
- `test/integration_test/proposals/proposal_regression_test.dart`
- `test/integration_test/proposals/proposal_flows_placeholder_test.dart`
- `test/integration_test/task_requests/bid_lifecycle_test.dart`
- `lib/features/tasks/view/widgets/requests/`
- `lib/features/tasks/services/task_requests_service.dart`
- `lib/features/proposals/`

### Benefits

- Replaces placeholder proposal coverage with real role-based flows.
- Protects the core marketplace conversion path.
- Catches state mismatch between proposal, task request, award, and payment entry.

### Package Notes

No package additions.

### Gate

Do not mark this phase done while `proposal_flows_placeholder_test.dart` remains a placeholder.

## Phase 8: Booking, Checkout, Payment Return, Payment Recovery, Wallet, Refund, and Dashboard Payment State

### Purpose

Cover the financially sensitive lifecycle without making CI depend on external payment entry.

### Tests To Implement

- `IT08.1`: booking list loads seeded booking.
- `IT08.2`: booking detail opens and shows client/provider context.
- `IT08.3`: booking request accept/decline states render correctly.
- `IT08.4`: demo or seeded payment lane creates payable state.
- `IT08.5`: payment return route handles success.
- `IT08.6`: payment return route handles cancel/failure.
- `IT08.7`: pending payment recovery survives app restart.
- `IT08.8`: dashboard bookings reflect processed payment state.
- `IT08.9`: wallet balance/history reflect seeded payment records.
- `IT08.10`: refund/decline state is visible where fixtures allow it.
- `IT08.11`: gateway technical metadata is not shown as user-facing copy.
- `IT08.12`: manual external payment runbook captures redacted evidence.
- `MAN08.13`: manual QiCard test-card run uses `IT_QICARD_TEST_CARD ending 8582` from local env without storing PAN/CVV/expiration in tracked files or artifacts.

### Locations

- `test/integration_test/booking/booking_request_flow_test.dart`
- `test/integration_test/booking/booking_payment_recovery_flow_test.dart`
- `test/integration_test/booking/payment_return_flow_test.dart`
- `test/integration_test/wallet/wallet_payment_history_flow_test.dart`
- `test/integration_test/dashboard/dashboard_payment_state_flow_test.dart`
- `test/integration_test/booking_request_flow_test.dart`
- `lib/features/booking/view/`
- `lib/features/wallet/view/`
- `lib/features/dashboard/view/`
- `lib/core/services/payment_service.dart`
- `lib/core/services/payment_pending_store.dart`

### Benefits

- Tests the highest-risk business flow with safe automation boundaries.
- Converts payment recovery and dashboard booking regressions into explicit tests.
- Keeps CI stable while still preserving manual release proof for external gateway behavior.
- Allows repeatable manual payment checks with the provided test-card alias while preserving PCI-style redaction boundaries.

### Package Notes

No package additions by default. If WebView platform behavior must be mocked in non-device tests, add `webview_flutter_platform_interface`.

### Gate

External payment entry remains manual until a safe mock or seeded callback seam exists.
Full PAN, CVV, and expiration must never appear in committed files, logs, screenshots, or test artifacts.

## Phase 9: Chat, Realtime, Direct Offers, Notifications, and Deep Links

### Purpose

Verify asynchronous communication and route recovery across roles and contexts.

### Tests To Implement

- `IT09.1`: chat list opens seeded conversation.
- `IT09.2`: participant can open conversation.
- `IT09.3`: unrelated user is denied by RLS/security test.
- `IT09.4`: actor A sends a message.
- `IT09.5`: actor B receives or refreshes to see the message.
- `IT09.6`: failed send/retry state is visible.
- `IT09.7`: booking-context chat opens.
- `IT09.8`: task-context chat opens.
- `IT09.9`: direct offer creation opens from chat.
- `IT09.10`: direct offer accept/decline/payment/delivery states render with seeded fixtures.
- `IT09.11`: notification list renders seeded notification.
- `IT09.12`: notification tap deep-links to the target surface.
- `IT09.13`: invalid deep link shows safe fallback.
- `IT09.14`: deleted-user or unavailable-target notification does not crash.

### Locations

- `test/integration_test/chat/chat_message_flow_test.dart`
- `test/integration_test/chat/chat_realtime_two_actor_flow_test.dart`
- `test/integration_test/chat/chat_context_routes_flow_test.dart`
- `test/integration_test/direct_offers/direct_offer_flow_test.dart`
- `test/integration_test/notifications/notification_deeplink_flow_test.dart`
- `test/integration_test/chat_message_flow_test.dart`
- `test/integration_test/notification_deeplink_flow_test.dart`
- `integration_test/chat_creation_test.dart`
- `lib/features/chat/view/`
- `lib/features/direct_offers/view/`
- `lib/features/notifications/view/`
- `lib/core/services/deep_link_service.dart`

### Benefits

- Covers realtime behavior with deterministic actor fixtures.
- Repairs or quarantines the legacy root chat test with placeholder Supabase config.
- Tests user-facing deep-link recovery instead of only service-level logic.

### Package Notes

No package additions by default. If helper-level timer/retry tests need virtual time, add `fake_async`.

### Gate

Realtime waits must be bounded and every chat test must name participant, other participant, and unrelated actor behavior.

## Phase 10: Dashboard, Work, Orders, Management, Next Actions, and Operational Surfaces

### Purpose

Verify the app state after marketplace actions are complete or in progress.

### Tests To Implement

- `IT10.1`: dashboard overview loads for client.
- `IT10.2`: dashboard overview loads for freelancer.
- `IT10.3`: dashboard wallet card reflects seeded balance.
- `IT10.4`: dashboard bookings list includes seeded booking/payment state.
- `IT10.5`: inbox tab renders sent and received states.
- `IT10.6`: work tab lists task work item.
- `IT10.7`: work tab lists booking work item.
- `IT10.8`: work detail opens.
- `IT10.9`: message-from-work detail opens chat.
- `IT10.10`: revision/change/extension/cancel-award surfaces render where fixtures allow them.
- `IT10.11`: management/order list empty/loading/error/success states render.
- `IT10.12`: next actions list shows correct seeded actions.

### Locations

- `test/integration_test/dashboard/dashboard_overview_flow_test.dart`
- `test/integration_test/dashboard/dashboard_role_switch_flow_test.dart`
- `test/integration_test/dashboard/dashboard_next_actions_flow_test.dart`
- `test/integration_test/work/work_item_flow_test.dart`
- `test/integration_test/management/management_orders_flow_test.dart`
- `test/integration_test/dashboard_role_switch_flow_test.dart`
- `lib/features/dashboard/view/`
- `lib/features/work/view/`
- `lib/features/management/view/`
- `lib/features/orders/`

### Benefits

- Verifies the operational surfaces users return to after actions.
- Converts old dashboard fixture TODOs into current executable coverage.
- Catches mismatches between payment state, booking state, and dashboard summaries.

### Package Notes

No package additions.

### Gate

Dashboard fixture IDs from older TODOs must be used, replaced, or explicitly marked stale.

## Phase 11: Storage, Media, Cache Behavior, Error Mapping, Safety, and Resilience

### Purpose

Cover support systems that commonly fail outside happy paths.

### Tests To Implement

- `IT11.1`: private avatar renders through signed path behavior.
- `IT11.2`: missing avatar shows safe placeholder.
- `IT11.3`: task image renders through stored path.
- `IT11.4`: missing task image shows safe placeholder.
- `IT11.5`: chat attachment renders or fails safely.
- `IT11.6`: portfolio public media renders.
- `IT11.7`: cached image or preference-backed state survives restart where implemented.
- `IT11.8`: RLS denied error maps to session/user-safe message.
- `IT11.9`: duplicate/foreign-key/check-constraint errors map safely.
- `IT11.10`: network failure state renders retry path.
- `IT11.11`: safety/report/block surfaces open and submit only when fixture-safe.
- `IT11.12`: Sentry/runtime error path does not expose secrets in UI.

### Locations

- `test/integration_test/media/storage_media_flow_test.dart`
- `test/integration_test/media/media_fallback_flow_test.dart`
- `test/integration_test/resilience/error_mapping_flow_test.dart`
- `test/integration_test/safety/safety_report_flow_test.dart`
- `lib/core/widgets/signed_avatar.dart`
- `lib/core/widgets/signed_image.dart`
- `lib/core/utils/error_mapper.dart`
- `lib/features/safety/`
- `lib/features/profile/view/`
- `lib/features/tasks/view/`
- `lib/features/chat/view/`

### Benefits

- Proves storage paths and signed rendering behavior are safe.
- Catches user-hostile technical error messages.
- Covers safety-critical flows without depending on real user data.

### Package Notes

No package additions by default. If image fallback widget tests cannot load network images in CI, add `network_image_mock`.

### Gate

Do not store signed URLs in fixtures or database rows.

## Phase 12: Security, RLS, Negative Authorization, and Abuse Boundaries

### Purpose

Prove protected records cannot be accessed or mutated by the wrong actor.

### Tests To Implement

- `IT12.1`: signed-out user cannot access protected shell.
- `IT12.2`: unrelated user cannot read private booking.
- `IT12.3`: unrelated user cannot read private chat.
- `IT12.4`: unrelated user cannot read wallet/payment records.
- `IT12.5`: unrelated user cannot read another user's favorites.
- `IT12.6`: client cannot perform freelancer-only proposal action.
- `IT12.7`: freelancer cannot perform client-only award/payment action.
- `IT12.8`: storage bucket access fails without valid policy/path.
- `IT12.9`: direct-offer participant boundaries hold.
- `IT12.10`: notification target cannot leak protected data to unrelated actor.

### Locations

- `test/integration_test/security/rls_auth_boundaries_test.dart`
- `test/integration_test/security/rls_chat_boundaries_test.dart`
- `test/integration_test/security/rls_booking_wallet_boundaries_test.dart`
- `test/integration_test/security/rls_storage_boundaries_test.dart`
- `test/rls/`
- `supabase/tests/`
- `Sline_everything/SUPABASE_SETUP.md`

### Benefits

- Catches the highest-impact backend authorization regressions.
- Links Supabase policies to user-visible app behavior.
- Prevents false confidence from UI-only tests.

### Package Notes

No package additions by default. `postgrest` is already present for direct client-style policy assertions.

### Gate

Every negative test must specify actor, object, expected denial, and related RLS policy/source doc.

## Phase 13: CI Grouping, Device Matrix, Flake Control, Performance Signals, and Reports

### Purpose

Make the suite usable in daily work and still deep enough for release confidence.

### Tests To Implement

- `IT13.1`: PR smoke group command runs auth, shell, and one seeded app flow.
- `IT13.2`: backend-gated group blocks cleanly without staging/local confirmation.
- `IT13.3`: nightly/full group includes all stable suites.
- `IT13.4`: manual release group records payment and multi-device checks without entering CI.
- `IT13.5`: artifact report summarizes pass/fail/blocked by test ID.
- `IT13.6`: flake retry policy captures first failure before rerun.
- `IT13.7`: longest-running tests are identified and grouped outside fast PR checks.
- `IT13.8`: Android emulator smoke runs selected auth, shell, tender, payment recovery, and chat tests.
- `IT13.9`: iOS simulator full path runs selected cross-role flows.
- `IT13.10`: web smoke runs only supported web-safe flows.
- `IT13.11`: Unit suite command covers `test/unit`, `test/features`, and `test/core`.
- `IT13.12`: Widget suite command covers `test/widget` and shared widget tests.
- `IT13.13`: Golden suite command covers `test/golden` and blocks unreviewed diffs.
- `IT13.14`: coverage parser records real line coverage without misreading `lcov.info`.

### Locations

- `.github/workflows/ci.yml`
- `test/unit/`
- `test/features/`
- `test/core/`
- `test/widget/`
- `test/golden/`
- `test/integration_test/smoke/`
- `test/integration_test/backend_gated/`
- `test/integration_test/manual_release/`
- `test/integration_test/artifacts/`
- `.TODO/TEST_COVERAGE_LEDGER_FullApp_2026-05-14.md`
- `.TODO/INTEGRATION_TEST_MATRIX_FullApp_2026-05-14.md`
- `.TODO/UNIT_WIDGET_TEST_MATRIX_FullApp_2026-05-14.md`
- `.TODO/GOLDEN_TEST_MATRIX_FullApp_2026-05-14.md`
- `.TODO/RUNBOOK_FullAppIntegration_2026-05-14.md`

### Benefits

- Keeps PR feedback fast.
- Keeps deep coverage available without making every push slow.
- Separates true failures from missing environment blockers.

### Package Notes

No package additions by default. Prefer Flutter's native test output and CI artifacts first.

### Gate

CI must not fail because a deliberately manual or backend-gated test was placed in the wrong group.

## Phase 14: Documentation, Diagrams, Release Handoff, and Long-Term Maintenance

### Purpose

Keep the test system understandable after the first implementation pass.

### Tests To Implement

- `IT14.1`: runbook has commands for local, staging, smoke, backend-gated, full, and manual release runs.
- `IT14.2`: test topology diagram matches implemented helper/filesystem layout.
- `IT14.3`: matrix has no orphan test files.
- `IT14.4`: every test file has a matrix row.
- `IT14.5`: every skipped test has a blocker.
- `IT14.6`: every fixture-dependent test has fixture manifest entries.
- `IT14.7`: every coverage-ledger row has Unit, Widget, Golden, Integration, RLS/SQL/RPC, and Manual status.
- `IT14.8`: golden matrix has approval status for every golden file.
- `IT14.9`: docs mention only implemented behavior.
- `IT14.10`: session log records commands, artifacts, blocked flows, and next actions.

### Locations

- `.TODO/RUNBOOK_FullAppIntegration_2026-05-14.md`
- `.TODO/TEST_COVERAGE_LEDGER_FullApp_2026-05-14.md`
- `.TODO/INTEGRATION_TEST_MATRIX_FullApp_2026-05-14.md`
- `.TODO/UNIT_WIDGET_TEST_MATRIX_FullApp_2026-05-14.md`
- `.TODO/GOLDEN_TEST_MATRIX_FullApp_2026-05-14.md`
- `.TODO/FIXTURES_FullAppIntegration_2026-05-14.md`
- `docs/diagrams/FullAppTestCoverageTopology.md`
- `test/golden/README.md`
- `docs/LOG/SESSION_PLAN_FullAppIntegrationTesting_2026-05-14.md`
- `Sline_everything/DEVELOPER_GUIDE.md`
- `Sline_everything/STRUCTURE.md`
- `Sline_everything/SUPABASE_SETUP.md`

### Benefits

- Makes the suite maintainable instead of one-off.
- Helps future agents and developers know exactly what to run.
- Prevents docs from claiming coverage that does not exist.

### Package Notes

No package additions.

### Gate

Docs close only after implemented tests, skipped tests, artifacts, and blockers are reconciled.

## Final Implementation Order

1. Phase 0
2. Phase 1
3. Phase 2
4. Phase 3 and Phase 4
5. Phase 5 and Phase 6
6. Phase 7
7. Phase 8
8. Phase 9
9. Phase 10 and Phase 11
10. Phase 12
11. Phase 13
12. Phase 14

## Command Patterns

Baseline:

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze --no-fatal-infos
flutter test
```

Unit suites:

```bash
flutter test test/unit test/features test/core
```

Widget suites:

```bash
flutter test test/widget test/core/widgets
```

Golden suites:

```bash
flutter test test/golden
flutter test test/golden --update-goldens
```

RLS/backend suites:

```bash
flutter test test/rls/
```

Account-one login mapping for existing single-login tests:

```bash
export IT_ACCOUNT_1_EMAIL='1test@test.com'
export IT_ACCOUNT_1_PASSWORD='<provided-out-of-band>'

flutter test test/integration_test/app_startup_login_flow_test.dart \
  --dart-define=IT_STAGING_CONFIRMED=true \
  --dart-define=IT_LOGIN_EMAIL="$IT_ACCOUNT_1_EMAIL" \
  --dart-define=IT_LOGIN_PASSWORD="$IT_ACCOUNT_1_PASSWORD"
```

Cross-account test pattern:

```bash
export IT_ACCOUNT_1_EMAIL='1test@test.com'
export IT_ACCOUNT_1_PASSWORD='<provided-out-of-band>'
export IT_ACCOUNT_2_EMAIL='2test@test.com'
export IT_ACCOUNT_2_PASSWORD='<provided-out-of-band>'

flutter test test/integration_test/<suite>/<file>_test.dart \
  --dart-define=IT_STAGING_CONFIRMED=true \
  --dart-define=IT_ACCOUNT_1_EMAIL="$IT_ACCOUNT_1_EMAIL" \
  --dart-define=IT_ACCOUNT_1_PASSWORD="$IT_ACCOUNT_1_PASSWORD" \
  --dart-define=IT_ACCOUNT_2_EMAIL="$IT_ACCOUNT_2_EMAIL" \
  --dart-define=IT_ACCOUNT_2_PASSWORD="$IT_ACCOUNT_2_PASSWORD"
```

Single integration suite:

```bash
flutter test test/integration_test/<suite>/<file>_test.dart \
  --dart-define=IT_STAGING_CONFIRMED=true \
  --dart-define=IT_LOGIN_EMAIL=<redacted> \
  --dart-define=IT_LOGIN_PASSWORD=<redacted>
```

Feature suite with fixture IDs:

```bash
flutter test test/integration_test/<suite>/<file>_test.dart \
  --dart-define=IT_STAGING_CONFIRMED=true \
  --dart-define=IT_LOGIN_EMAIL=<redacted> \
  --dart-define=IT_LOGIN_PASSWORD=<redacted> \
  --dart-define=<FEATURE_FIXTURE_ID>=<redacted>
```

Manual payment release lane:

```bash
export IT_QICARD_PAN='<provided-out-of-band>'
export IT_QICARD_CVV='<provided-out-of-band>'
export IT_QICARD_EXPIRY='<provided-out-of-band>'

flutter run -d <device_id> --dart-define=USE_QICARD_PAYMENT=true
```

## Definition Of Done

The full app test program is done when:

1. All phase artifacts exist and are current.
2. Existing placeholder/skipped/hardcoded integration tests are fixed, quarantined, or blocked with explicit matrix rows.
3. The coverage ledger has no empty required cells across Unit, Widget, Golden, Integration, RLS/SQL/RPC, and Manual layers.
4. Every primary ViewModel, service, model mapper, guard, and utility has Unit coverage or a recorded reason.
5. Every primary screen, shared component, modal, sheet, empty/loading/error state, and role-specific state has Widget coverage or a recorded reason.
6. Every stable primary screen shell, high-risk component, and redesigned visual surface has Golden coverage or a recorded reason.
7. Auth, shell, discovery, task creation, proposals, booking/payment, chat, dashboard/work, media, safety, and RLS integration suites are implemented or explicitly blocked by environment.
8. Backend/RLS/SQL/RPC suites cover protected records and money/workflow-changing transitions.
9. PR smoke tests run in a reasonable time.
10. Backend-gated tests fail closed when environment values are missing.
11. Manual payment release steps are documented and redaction-safe.
12. `flutter analyze --no-fatal-infos` passes after implementation.
13. Unit, Widget, Golden, Integration, and RLS test commands pass or report explicit environment blockers.
14. Failed-test diagnostics include buffered `AppLogger` lines and step labels, while passing tests remain quiet.
15. SnackBars, toasts, dialogs, banners, and inline errors are asserted through visible UI/state, not log text.
16. Provided test accounts are represented by aliases and local-only env variables, not committed passwords.
17. The provided payment test card is represented by `IT_QICARD_TEST_CARD ending 8582`; full PAN, CVV, and expiration remain local-only.
18. No production secrets, card data, or raw payment metadata are committed.
19. Docs, diagrams, coverage ledger, matrices, fixtures, selectors, golden manifests, and session log match the real implemented suite.
