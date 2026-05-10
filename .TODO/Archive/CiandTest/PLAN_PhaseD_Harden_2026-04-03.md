# Plan: Phase D — Harden (v2 — @PlanCritic Rewrite)

**Session Log:** `docs/LOG/SESSION_PLAN_PhaseD_Harden_2026-04-03.md`
**Critic Pass:** 2026-04-03
**Previous Version:** v1 (820 lines, 9 phases). This is the corrected version.

---

# @PlanCritic Audit Report

## A) Assumptions + Decision Needed (Blocking)

### Assumptions

1. **Sentry is the chosen crash reporting provider.** No alternative (Crashlytics, Datadog) has been discussed. Sentry chosen because the existing `CrashReportingService` interface maps 1:1 to Sentry's API.
2. `**sentry_flutter ^8.0.0`** is compatible with the project's SDK constraint (`sdk: ^3.8.1`). Verified: sentry_flutter 8.x requires Flutter 3.3+ and Dart 3.0+, which is satisfied.
3. **pgTAP extension may not be available** on the Supabase project. The plan includes a fallback (plain SQL assertion queries).
4. **Current coverage is 30.6%** (6133/20059 lines from lcov.info). The original plan assumed ~70%. This drastically changes the threshold strategy.
5. `**showSubmitRequestSheet` is called from exactly 1 file** (`requests_list_screen.dart`, 3 call sites). Decomposition impact is contained.
6. **12 Edge Functions** import `corsHeaders` from `_shared/bookin_payment.ts`. CORS change has broad blast radius.
7. **DashboardViewModel tests** fully mock dependencies via constructor DI. The delegate pattern will work IF the public API proxy layer is preserved exactly.
8. `**submit_request_sheet.dart` is a top-level function**, not a widget class. It cannot use `ChangeNotifierProvider` in the normal way — the VM would need to be created locally within the function body or passed from the caller.
9. **ChatVM `removeAllChannels()` is routed through `ChatRepository`**, not direct `Supabase.instance` in the VM. This is a pre-existing A6-adjacent issue but NOT directly `Supabase.instance` in a viewmodel method body. Out-of-scope for Phase D.

### Decision Needed (Blocking)

#### DN-1: Coverage Threshold Value

- **What:** Current coverage is 30.6%. The original plan said "70% threshold." Setting 70% would fail CI immediately.
- **Options:**
  1. Set threshold at 28% (current minus 2% — regression floor only).
  2. Set threshold at 35% (aspirational bump, achievable with Phase D new tests).
  3. Skip threshold enforcement entirely in Phase D; add in Phase E when coverage improves.
- **Recommended:** Option 1 (28% floor). **Why:** The purpose of coverage enforcement is to prevent regression, not to chase a target. Setting 70% is fantasy at 30.6%. A 28% floor prevents backsliding while being immediately achievable. Raise to 35% after Phase D tests land, then incrementally.
- **Plan impact:** Phase 7.4 threshold value changes from 70% to 28%.

#### DN-2: SubmitRequestViewModel Provider Strategy

- **What:** `showSubmitRequestSheet` is a top-level async function, not a widget. It cannot wrap itself in `ChangeNotifierProvider`. How does the new `SubmitRequestViewModel` get provided?
- **Options:**
  1. Create the VM locally inside the function body (`final vm = SubmitRequestViewModel(...)`) and pass it to child widgets manually (no Provider).
  2. Register `SubmitRequestViewModel` globally in `main.dart` as a `ChangeNotifierProvider`.
  3. Wrap the `showModalBottomSheet` content in a scoped `ChangeNotifierProvider`.
- **Recommended:** Option 3 (scoped provider). **Why:** The VM is short-lived (sheet lifecycle only). Global registration wastes memory. Local creation without Provider prevents `Consumer`/`context.watch` reactivity. Scoped provider inside the sheet builder gives both lifecycle management and reactivity.
- **Plan impact:** Phase 3.4 rewritten to use scoped provider pattern inside `showModalBottomSheet` builder.

#### DN-3: BookingService Provider Promotion

- **What:** `BookingService` is currently instantiated inline in `DashboardViewModel` constructor: `BookingService((repository ?? DashboardRepository()).client)`. If extracted into a delegate, the delegate needs a `BookingService` — but there's no `BookingService` in the provider tree.
- **Options:**
  1. Promote `BookingService` to a global `Provider<BookingService>` in `main.dart` before decomposition.
  2. Keep `BookingService` creation inside `DashboardViewModel` and pass it to delegates during construction.
  3. Give each delegate its own `BookingService` instance.
- **Recommended:** Option 2 (pass from VM to delegate). **Why:** Promoting to global provider is a larger change that affects all BookingService consumers. The VM already creates the instance — just pass it to delegates in the constructor. This is the minimal-change path.
- **Plan impact:** Phase 2.2–2.4 delegate constructors receive pre-built services from the parent VM, not from Provider tree.

---

## B) Gate Status

### Gate 0: Test Infrastructure Gate — ✅ PASS

- 98 test files, 706 tests passing, shared mock file with 8 mocks.
- `test/helpers/mock_services.dart` covers Dashboard, Wallet, Chat, Booking, Task, DirectOffers services.
- **Needed:** 1 new mock (`MockTaskRequestsService`) for inbox delegate tests. Minor addition, not blocking.

### Gate 1: Data / Contracts Gate — ✅ PASS

- No schema changes in Phase D. All work is refactoring existing code or adding tests/docs.
- No DTO contract changes. Delegate extraction preserves existing model consumption.
- No migration work (D6 is a checklist document, not a migration).

### Gate 2: Security / RLS Gate — ✅ PASS (conditional)

- D7 (CORS) and D8 (paymentId validation) are security-hardening items.
- pgTAP tests (D5) validate RPC security behavior.
- **Condition:** CORS change must include `localhost` patterns for development. Plan addresses this.

### Gate 3: Backend / Supabase Gate — ✅ PASS

- Edge Function changes (D7, D8) have `Skill: supabase-migration` tags.
- pgTAP tests (D5) have `Skill: supabase-migration` tags.
- No schema/migration work. Migration checklist (D6) is documentation only.
- Session log initialized at `docs/LOG/SESSION_PLAN_PhaseD_Harden_2026-04-03.md`.

### Gate 4: UI / Integration Gate — ✅ PASS (after fixes)

- Original plan had UI decomposition (Phases 3–4) with `@Pixel` ownership and Skill tags.
- **Fix applied:** Added explicit sub-phase for verifying no visual regression (screenshot comparison or manual check step).
- **Fix applied:** Added missing step for `submit_request_sheet` scoped provider wiring pattern.

### Gate 5: Release / QA Gate — ✅ PASS

- Full QA phase (Phase 8) with non-regression, architecture compliance, line counts, edge function verification, build verification.
- Rollback plan with decision tree.
- Documentation sync phase (Phase 9).

---

## C) Critical Gaps (Must-Fix)

### Gap 1: Coverage Threshold Delusion

- **Gap:** Plan says "70% threshold." Current coverage is 30.6%.
- **Why it will break:** CI would reject every merge immediately after enforcement. Zero productivity until coverage doubles.
- **Fix:** Set threshold at 28% (regression floor). Document plan to raise incrementally.
- **Owner:** Infra / @Architect
- **Acceptance check:** CI passes at current coverage level AND fails when a test file is deleted.

### Gap 2: submit_request_sheet Provider Pattern Undefined

- **Gap:** Plan says "instantiate SubmitRequestViewModel via ChangeNotifierProvider" but `showSubmitRequestSheet` is a top-level function, not a widget.
- **Why it will break:** Executor would try to wrap a function in a Provider and hit a dead end. The function's BuildContext comes from the calling screen, not from a widget tree the sheet controls.
- **Fix:** Use scoped `ChangeNotifierProvider` inside the `showModalBottomSheet` builder callback. The VM is created in the builder, scoped to the sheet's widget subtree.
- **Owner:** Frontend / @Architect
- **Acceptance check:** `SubmitRequestViewModel` is accessible via `context.read` inside the sheet. Sheet lifecycle disposes the VM.

### Gap 3: BookingService Not in Provider Tree

- **Gap:** Delegates need `BookingService` but it's instantiated inline in `DashboardViewModel` constructor, not in `main.dart` provider tree.
- **Why it will break:** Delegate constructor expects a `BookingService` parameter. If the plan assumes it comes from `context.read<BookingService>()`, it won't exist.
- **Fix:** DashboardViewModel creates `BookingService` as before, then passes it to delegates during construction. No provider tree change needed.
- **Owner:** Frontend / @Architect
- **Acceptance check:** Delegates receive services from parent VM. No new Provider registrations for services.

### Gap 4: 12 Edge Functions Affected by CORS Change

- **Gap:** Original plan says "verify all Edge Functions that import corsHeaders still work" but doesn't enumerate them. There are 12 functions affected.
- **Why it will break:** If `corsHeaders` becomes a function (to check Origin header dynamically), the call signature changes. Every consumer must be updated.
- **Fix:** Keep `corsHeaders` as a static object but add a `getCorsHeaders(req: Request)` function alongside it. Migrate consumers incrementally. OR make the function backward-compatible by defaulting to first allowed origin when no request is provided.
- **Owner:** Backend / @Supabase_Ops
- **Acceptance check:** All 12 Edge Functions deploy without errors. OPTIONS preflight returns correct headers for allowed origins.

### Gap 5: DashboardVM Delegate Dispose Safety

- **Gap:** Plan creates delegates but doesn't address dispose lifecycle. Current VM uses `_isDisposed` flag and `_abortIfDisposed()` checks in async methods.
- **Why it will break:** If delegates hold async operations and the parent VM disposes, delegates could call `notifyListeners()` on a disposed parent.
- **Fix:** Each delegate receives a `bool Function() isDisposed` callback from the parent VM. Delegates check this before calling `onChanged()`. Add explicit step in Phase 2.2–2.4.
- **Owner:** Frontend / @Architect
- **Acceptance check:** Calling `dispose()` on the parent VM prevents all delegate callbacks from firing.

### Gap 6: Architecture Guard Check 3 Insufficient

- **Gap:** CI guard Check 3 excludes `Supabase.instance.client.auth.` patterns. The A6 violations in `notification_view_model.dart` use exactly `Supabase.instance.client.auth.onAuthStateChange` and `Supabase.instance.client.auth.currentUser` — which are EXCLUDED by the guard.
- **Why it will break:** After fixing A6, the guard still wouldn't catch regressions because the exclusion pattern allows exactly the pattern we're fixing.
- **Fix:** After A6 fixes land (Phase 7.1–7.2), tighten Check 3 by removing the `grep -v 'Supabase\.instance\.client\.auth\.'` exclusion. All legitimate auth access should now go through DI parameters.
- **Owner:** Infra / @Architect
- **Acceptance check:** Reintroducing `Supabase.instance.client.auth.currentUser` in a viewmodel causes CI to fail.

### Gap 7: Missing MockTaskRequestsService

- **Gap:** Inbox delegate tests need `MockTaskRequestsService` but it doesn't exist in `test/helpers/mock_services.dart`.
- **Why it will break:** Delegate test files won't compile without the mock.
- **Fix:** Add `MockTaskRequestsService` to `test/helpers/mock_services.dart` as part of Phase 2.7 setup.
- **Owner:** Frontend / @Sentinel
- **Acceptance check:** Mock exists. Inbox delegate tests compile and pass.

---

## D) Invariants & Success Criteria (Non-Negotiable)


| #   | Invariant                                                   | How to Enforce                                       | How to Verify                                                             |
| --- | ----------------------------------------------------------- | ---------------------------------------------------- | ------------------------------------------------------------------------- |
| 1   | No View calls Supabase directly                             | Architecture guard Check 1                           | `grep -rn 'Supabase\.instance' lib/features/*/view/` returns empty        |
| 2   | No ViewModel imports View layer                             | Architecture guard Check 2                           | `grep -rn "import.*\/view\/" lib/features/*/viewmodels/` returns empty    |
| 3   | No ViewModel accesses Supabase.instance outside DI defaults | Architecture guard Check 3 (tightened after Phase 7) | Grep returns only constructor `??` patterns                               |
| 4   | AppLogger used instead of print()                           | `avoid_print` lint rule                              | `flutter analyze` reports 0 issues                                        |
| 5   | All existing tests pass after each phase                    | `flutter test`                                       | 706+ tests pass, 0 failures                                               |
| 6   | No hardcoded secrets (Sentry DSN, API keys)                 | Code review + grep                                   | `grep -rn 'https://.*@.*sentry' lib/` returns empty                       |
| 7   | Delegate decomposition preserves public API                 | Test compatibility                                   | All 20 DashboardVM tests pass unchanged                                   |
| 8   | Edge Function CORS doesn't reflect arbitrary origins        | Security review                                      | `curl -H "Origin: https://evil.com"` returns allowed origin, not evil.com |
| 9   | Coverage can only go up, never down                         | CI threshold enforcement                             | Removing a test file fails CI                                             |
| 10  | Contract nullability matches DB nullability                 | Model tests (Phase C)                                | Existing 144 DTO tests pass                                               |


---

## E) Risk Register


| Risk                                                 | Where      | Probability | Impact   | Blast radius             | Early signal                                                    | Prevention                                             | Fallback                                              |
| ---------------------------------------------------- | ---------- | ----------- | -------- | ------------------------ | --------------------------------------------------------------- | ------------------------------------------------------ | ----------------------------------------------------- |
| Delegate extraction breaks DashboardVM tests         | Phase 2    | Medium      | High     | 20 unit + 2 widget tests | Test failures after 2.5                                         | Run tests after EACH sub-phase, not just at end        | Forward-fix delegate wiring; never revert to monolith |
| CORS change breaks Edge Functions in production      | Phase 5    | Low         | Critical | All payment flows        | 4xx errors on preflight OPTIONS                                 | Test with curl before deploy; include localhost in dev | Revert to `*` immediately                             |
| Sentry SDK conflicts with existing deps              | Phase 1    | Low         | Medium   | Build failure            | `flutter pub get` fails                                         | Check compatibility before adding                      | Use Firebase Crashlytics instead                      |
| submit_request_sheet scoped Provider doesn't dispose | Phase 3    | Medium      | Low      | Memory leak              | ViewModel stays alive after sheet closes                        | Use `ChangeNotifierProvider` (auto-disposes)           | Manual dispose in `WillPopScope`                      |
| pgTAP not available on Supabase project              | Phase 6    | Medium      | Low      | No SQL tests             | Extension query returns empty                                   | Check availability first (6.1)                         | Write plain SQL assertion scripts                     |
| Coverage threshold blocks legitimate PR              | Phase 7    | Low         | Medium   | Team velocity            | CI fails on PR with no test changes                             | Set threshold conservatively (28%)                     | Raise threshold gradually, not all at once            |
| Parallel agent file corruption (Phase C precedent)   | Phases 2–4 | Low         | High     | Source file overwritten  | `flutter analyze` explodes with errors                          | Run `flutter analyze` after EACH agent completes       | Restore from git; re-run single agent                 |
| Architecture guard exclusion still allows A6 pattern | Phase 7    | High        | Medium   | Regressions reintroduced | New VM accesses Supabase.instance.client.auth without detection | Tighten Check 3 AFTER A6 fixes land                    | Manual code review on PRs                             |


---

## F) Pre-Mortem

1. **This fails when** the executor sets coverage threshold at 70% without measuring first, CI rejects every merge, and someone force-pushes to bypass.
2. **This fails when** the DashboardVM delegate extraction changes a public getter signature that widget tests depend on, causing a cascade of 20+ test failures that take hours to debug.
3. **This fails when** CORS is tightened but `http://localhost:54321` (Supabase local) is not in the allowlist, breaking all local Edge Function calls.
4. **This fails when** `showSubmitRequestSheet` is wrapped in `ChangeNotifierProvider` at the wrong level (outside `showModalBottomSheet`), and the VM's context is the calling screen — not the sheet — causing `Provider.of` to fail.
5. **This fails when** pgTAP tests are written but can't be run because `pgtap` extension isn't enabled, and nobody checks until Phase 8 QA.
6. **This fails when** a delegate's async method completes after `DashboardViewModel.dispose()`, calls the `onChanged` callback, which calls `notifyListeners()` on a disposed ChangeNotifier, triggering a Flutter assertion error.
7. **This fails when** Sentry initialization wraps `runZonedGuarded` instead of being wrapped BY it, breaking the existing error boundary chain and swallowing zone errors.
8. **This fails when** the architecture guard Check 3 exclusion `grep -v 'Supabase\.instance\.client\.auth\.'` isn't removed after A6 fixes, and a future developer reintroduces the exact same violation undetected.
9. **This fails when** 12 Edge Functions import `corsHeaders` as a static object but the CORS fix changes it to a function — every import site breaks simultaneously.
10. **This fails when** parallel background agents overwrite each other's files during decomposition work (Phase C precedent: `wallet_view_model_test.dart` corruption).

---

## G) Plan Fixes (Concrete Additions / Expansions)

### Fix G1: Add Coverage Measurement Step Before Threshold Decision

- **Goal:** Know the actual coverage before setting a threshold.
- **Why:** Original plan assumed ~70%. Reality is 30.6%. Blind threshold setting blocks all merges.
- **How:** Add explicit `flutter test --coverage` + calculate step in Phase 7.4. Use measured value minus 2% as floor.
- **Output artifact:** Coverage percentage documented in session log.
- **Stop condition:** Threshold is set and CI passes at current coverage.

### Fix G2: Add Scoped Provider Pattern for SubmitRequestViewModel

- **Goal:** Define how SubmitRequestViewModel is provided in a top-level function context.
- **Why:** `showSubmitRequestSheet` is not a widget. Standard ChangeNotifierProvider wrapping doesn't apply.
- **How:** Create the VM inside the `showModalBottomSheet` builder, wrap sheet content in `ChangeNotifierProvider.value(value: vm, child: SheetContent())`.
- **Output artifact:** Working sheet with scoped ViewModel.
- **Stop condition:** `context.read<SubmitRequestViewModel>()` works inside the sheet. VM is disposed when sheet closes.

### Fix G3: Add Delegate Dispose Safety Pattern

- **Goal:** Prevent delegates from calling back into a disposed parent VM.
- **Why:** Async delegate methods can complete after parent disposes.
- **How:** Each delegate receives `bool Function() isDisposed` from parent. All callbacks check this before invoking `onChanged`.
- **Output artifact:** Delegates with dispose-safety. No Flutter assertion errors on rapid dispose.
- **Stop condition:** Test: create VM, call async delegate method, immediately dispose VM. No assertion error.

### Fix G4: Add CORS Backward Compatibility Strategy

- **Goal:** Change `corsHeaders` without breaking 12 Edge Functions simultaneously.
- **Why:** Changing a static export to a function breaks all consumers at once.
- **How:** Add new `getCorsHeaders(req: Request)` function. Keep old `corsHeaders` export as default. Migrate consumers to new function one at a time.
- **Output artifact:** Both `corsHeaders` (static) and `getCorsHeaders(req)` (dynamic) exported. Old export deprecated.
- **Stop condition:** All 12 functions use `getCorsHeaders(req)`. Old static export removed.

### Fix G5: Add Missing MockTaskRequestsService

- **Goal:** Enable inbox delegate testing.
- **Why:** Mock doesn't exist in shared helpers.
- **How:** Add `class MockTaskRequestsService extends Mock implements TaskRequestsService {}` to `test/helpers/mock_services.dart`.
- **Output artifact:** Updated mock file with 9 mocks (was 8).
- **Stop condition:** Inbox delegate tests compile.

### Fix G6: Tighten Architecture Guard Check 3 After A6 Fixes

- **Goal:** Prevent A6 regression after fixing notification and saved VMs.
- **Why:** Current guard exclusion `grep -v 'Supabase\.instance\.client\.auth\.'` allows the exact pattern we're fixing.
- **How:** Remove that exclusion from Check 3 AFTER both VMs are refactored. All legitimate auth access now goes through DI.
- **Output artifact:** Updated `ci.yml` with tighter Check 3.
- **Stop condition:** Adding `Supabase.instance.client.auth.currentUser` to a viewmodel causes CI failure.

### Fix G7: Add Per-Sub-Phase Test Gate for DashboardVM Decomposition

- **Goal:** Catch delegate wiring issues immediately, not at end of Phase 2.
- **Why:** Phase C post-mortem identified "file corruption during parallel agent execution." DashboardVM has 20 dependent tests.
- **How:** Add `flutter test test/unit/dashboard/` gate check after EACH sub-phase (2.2, 2.3, 2.4, 2.5) — not just at 2.6.
- **Output artifact:** Test results logged per sub-phase.
- **Stop condition:** Any sub-phase test failure blocks next sub-phase.

---

# H) Corrected Plan (Execution-Ready, Gate-Based)

---

## 1) Goal

- **Goal:** Harden the SLine codebase for production readiness — crash observability, god-file decomposition, Edge Function security, coverage gating, pgTAP tests, migration discipline, and A6 architecture violation fixes.
- **Why:** Phases A–C locked the gates, exposed bugs, and covered critical paths (706 tests, 30.6% line coverage). Phase D fills the remaining safety gaps: invisible production errors (Sentry), oversized files hiding untested logic (3 god files), Edge Function CORS exposure, and missing SQL-level validation. Without Phase D, the codebase has blind spots after deploy.
- **Result:** Production crash reporting active. Top 3 god files decomposed. Edge Functions CORS-hardened. Coverage regression floor enforced. pgTAP tests validate critical RPCs. Migration review checklist adopted. A6 violations resolved. Architecture guard tightened.

---

## 2) Scope

### In-Scope


| ID  | Item                                                      | Audit Ref         |
| --- | --------------------------------------------------------- | ----------------- |
| D1  | Implement Sentry crash reporting (replace NoOp)           | Audit §1 #6, §4.6 |
| D2  | Decompose `dashboard_view_model.dart` (1149 lines)        | Audit §4.7        |
| D3  | Decompose `submit_request_sheet.dart` (916 lines)         | Audit §4.7        |
| D4  | Decompose `requests_list_screen.dart` (1172 lines)        | Audit §4.7        |
| D5  | Add pgTAP tests for critical RPCs                         | Audit §4.5 S4     |
| D6  | Add migration review checklist                            | Audit §4.8        |
| D7  | Tighten CORS on Edge Functions                            | Audit §4.5 S1     |
| D8  | Add `paymentId` regex validation in webhook handler       | Audit §4.5 S2     |
| D9  | Set up coverage regression floor (~28%) in CI             | Audit §4.4        |
| D10 | Fix architecture violations A6 (Supabase.instance in VMs) | Audit §4.3 A6     |
| D11 | Tighten architecture guard Check 3 after A6 fixes         | Critic finding G6 |


### Out-of-Scope

- `very_good_analysis` migration (Phase E)
- Localization / `.arb` files (Phase E)
- Full god-file decomposition (only top 3 tackled here)
- Sealed class `AppFailure` error system (Phase E)
- DeepLinkService route registry refactor (Phase E)
- 85% coverage target (Phase E)
- Remaining god files below 900 lines
- `QICARD_ALLOW_UNSIGNED_LOCAL_DEV` CI enforcement (Phase E)
- ChatVM `removeAllChannels()` routing through repo (pre-existing, not direct Supabase.instance in VM)

---

## 3) Evidence & Findings

### Measured

- **Coverage:** 30.6% (6133/20059 lines). Source: `coverage/lcov.info` from last `flutter test --coverage` run.
- **DashboardVM:** 1149 lines. 1 `Supabase.instance` occurrence in constructor DI default (line 53). 20 unit tests, 2 widget test files depend on it.
- **submit_request_sheet:** 916 lines. Top-level function (not widget). 3 call sites in 1 file. No existing tests for its business logic.
- **requests_list_screen:** 1172 lines. `ExpiredBidFilter` enum defined inline (lines 20–44). Uses `TaskRequestsViewModel` from provider.
- **Edge Functions:** 12 functions import `corsHeaders` from `_shared/bookin_payment.ts`.
- **Architecture guard Check 3:** Excludes `Supabase.instance.client.auth.` patterns — would NOT catch A6 regressions.
- **Mocks:** 8 in `test/helpers/mock_services.dart`. Missing: `MockTaskRequestsService`.

### Must NOT Duplicate

- Existing `AppLogger` logging — Sentry uses breadcrumbs, does NOT replace AppLogger.
- Existing `ErrorMapper` — Sentry captures raw exceptions; user-facing messages stay in ErrorMapper.
- Existing `DashboardRepository` — decomposition extracts VM logic, not repo queries.
- Existing test helpers — extend mocks, don't duplicate.

### Conflicts / Risks

- **DashboardVM decomposition:** Highest-risk item. 20 tests + 2 widget test files depend on current API. Strategy: delegate pattern preserving ALL public signatures.
- **submit_request_sheet:** Function-based, not widget. VM provision via scoped `ChangeNotifierProvider` inside `showModalBottomSheet` builder (DN-2 decision).
- **CORS change:** 12 functions affected. Strategy: add `getCorsHeaders(req)` alongside static `corsHeaders`, migrate incrementally (G4 fix).
- **Coverage enforcement:** Reality is 30.6%, not 70%. Strategy: 28% regression floor (DN-1 decision).
- **Delegate dispose safety:** Async methods can outlive parent VM. Strategy: `isDisposed` callback (G3 fix).

---

## 4) System Impact Map

- **UI:** D3, D4 — view-layer files split into smaller widgets. No visual changes. Scoped provider for SubmitRequestVM.
- **MVVM / App Logic:** D2 (DashboardVM delegates), D10 (A6 fixes) — ViewModel refactoring. Public API preserved.
- **Database:** D5 — read-only pgTAP tests. No schema changes.
- **RLS / Security:** D5 (pgTAP validates RPC behavior), D7/D8 (Edge Function hardening).
- **RPC / Edge Functions:** D7 (CORS), D8 (paymentId). All 12 functions affected by CORS. 1 function affected by paymentId.
- **Storage:** No impact.
- **Realtime / Notifications:** No impact.
- **Observability:** D1 (Sentry) — all error boundaries get crash reporting.
- **CI/CD:** D9 (coverage floor), D11 (guard tightening).
- **Contracts:** No contract changes. All decompositions preserve existing interfaces.

---

## 5) Agent Map


| Phase | Agents                                         |
| ----- | ---------------------------------------------- |
| 0     | `@Planner`, `@Sentinel`                   |
| 1     | `@Observability`, `@Architect`, `@Sentinel`    |
| 2     | `@Architect`, `@Sentinel`                      |
| 3     | `@Architect`, `@Pixel`, `@Sentinel`            |
| 4     | `@Architect`, `@Pixel`, `@Sentinel`            |
| 5     | `@Supabase_Ops`, `@ThreatModeler`, `@Sentinel` |
| 6     | `@Supabase_Ops`, `@Sentinel`                   |
| 7     | `@Architect`, `@Sentinel`                      |
| 8     | `@Sentinel`, `@CodeGuard`, `@ThreatModeler`    |
| 9     | `@DocsKeeper`                                   |


---

## Phase 0: Preconditions & Gates

**Primary Agent(s):** `@Planner`, `@Sentinel`

### Goal

Lock scope, acceptance criteria, and non-regression baseline before any implementation.

### Why

Phases B and C both discovered regressions and file corruption during execution. Explicit baselines prevent silent breakage.

### How

Run all verification commands. Record exact numbers. Define acceptance criteria.

### Result

Locked baseline. Explicit acceptance criteria. Rollback expectations.

### 0.1 Spec Lock

**Primary Agent(s):** `@Sentinel`

- (`@Sentinel`) Record acceptance criteria:
  1. `CrashReportingService.instance` is `SentryCrashReportingService` in release builds (when `SENTRY_DSN` is set).
  2. `dashboard_view_model.dart` < 400 lines. 3 delegate classes exist and are tested.
  3. `submit_request_sheet.dart` < 500 lines. Business logic in a tested ViewModel.
  4. `requests_list_screen.dart` < 500 lines. Filter logic in a tested ViewModel.
  5. `notification_view_model.dart` — no `Supabase.instance` outside DI constructor defaults.
  6. `saved_tasks_view_model.dart` — no `Supabase.instance` outside DI constructor defaults.
  7. Edge Function CORS restricted to allowlist (`sline.app` + `localhost`).
  8. `paymentId` regex validation active in webhook handler.
  9. CI coverage regression floor enforced (blocks merge below 28%).
  10. pgTAP tests exist for 3 critical RPCs (or plain SQL alternative if pgTAP unavailable).
  11. `MIGRATION_REVIEW_CHECKLIST.md` exists and is referenced in `CLAUDE.md`.
  12. All 706+ existing tests pass. `flutter analyze`: 0 issues.
  13. Architecture guard: all 6 checks pass. Check 3 tightened (no `auth` exclusion).
  14. Both build targets compile (`apk --debug`, `web --release`).
  15. Documentation synced: STRUCTURE.md, DEVELOPER_GUIDE.md, CLAUDE.md updated.
- (`@Architect`) Confirm touched modules: `lib/core/services/`, `lib/features/dashboard/viewmodels/`, `lib/features/tasks/view/widgets/requests/`, `lib/features/tasks/viewmodels/`, `lib/features/notifications/viewmodels/`, `lib/features/saved/viewmodels/`, `supabase/functions/`, `.github/workflows/ci.yml`, `test/helpers/mock_services.dart`.
- (`@DocsKeeper`) Confirm authoritative docs: Audit file, DEVELOPER_GUIDE, STRUCTURE, SUPABASE_SETUP.
- **GATE CHECK:** Scope, criteria, and doc references are explicit.

### 0.2 Non-Regression Baseline

**Primary Agent(s):** `@Sentinel`

- (`@Sentinel`) Run `flutter test` — record exact counts: X passed, Y skipped, 0 failures.
- (`@Sentinel`) Run `flutter analyze` — record: 0 issues.
- (`@Sentinel`) Run `dart format --set-exit-if-changed .` — record: 0 changes.
- (`@Sentinel`) Run architecture guard checks (all 6 grep commands from `ci.yml`) — record: all pass.
- (`@Sentinel`) Run `flutter test --coverage` and calculate coverage: record `DA` total and hit counts.
- (`@Sentinel`) Run `flutter build apk --debug` and `flutter build web --release` — record: both succeed.
- (`@Sentinel`) Record DashboardVM test count: `flutter test test/unit/dashboard/dashboard_view_model_test.dart` — record exact count.
- (`@Sentinel`) Write all baseline metrics to session log.
- **GATE CHECK:** Baseline metrics locked. All numbers recorded. Implementation may begin.

---

## Phase 1: Crash Reporting — Sentry Integration (D1)

**Primary Agent(s):** `@Observability`, `@Architect`, `@Sentinel`

### Goal

Replace `NoOpCrashReportingService` with Sentry so production errors are captured and triaged.

### Why

Audit §1 #6: CrashReportingService is NoOp. Production errors invisible. This is the #1 observability gap.

### How

Add `sentry_flutter`, implement `SentryCrashReportingService`, wire into `main.dart` error boundaries, integrate with `AuthSessionViewModel`.

### Result

Fatal and non-fatal errors reported to Sentry. User ID attached. Breadcrumbs forwarded. App works with and without DSN.

### 1.1 Add Sentry Dependency

**Primary Agent(s):** `@Observability`

- (`@Observability`) Add `sentry_flutter: ^8.0.0` to `pubspec.yaml` under `dependencies`.
- (`@Observability`) Run `flutter pub get`. Verify no dependency conflicts.
- (`@Observability`) Run `flutter analyze` — 0 issues.
- (`@Sentinel`) Confirm `pubspec.lock` updated correctly. No forced downgrades on other packages.
- **GATE CHECK:** `flutter pub get` succeeds. `flutter analyze`: 0 issues. No dependency conflicts.

### 1.2 Implement SentryCrashReportingService

**Primary Agent(s):** `@Observability`, `@Architect`

- (`@Observability`) Create `lib/core/services/sentry_crash_reporting_service.dart`.
- (`@Observability`) Implement `CrashReportingService` interface:
  - `recordError()` → `Sentry.captureException(exception, stackTrace: stack)` with `hint` containing `fatal` flag.
  - `log()` → `Sentry.addBreadcrumb(Breadcrumb(message: message))`.
  - `setUserIdentifier()` → `Sentry.configureScope((scope) => scope.setUser(SentryUser(id: identifier)))`.
  - `setCustomKey()` → `Sentry.configureScope((scope) => scope.setTag(key, value.toString()))`.
- (`@Observability`) Import only `package:sentry_flutter/sentry_flutter.dart` and `package:flutter/foundation.dart`. No other imports.
- (`@Architect`) Verify: does NOT import `material.dart`, `widgets.dart`, or any view-layer code.
- (`@Architect`) Verify: does NOT duplicate `AppLogger` calls. Sentry captures exceptions; AppLogger handles dev console output.
- (`@Sentinel`) Verify: class can be instantiated in tests without a live Sentry DSN. Add a simple construction test.
- (`@Sentinel`) Run `flutter analyze` — 0 issues.
- **GATE CHECK:** Class compiles. No MVVM violations. Testable without DSN.

### 1.3 Wire Sentry into main.dart Error Boundaries

**Primary Agent(s):** `@Observability`, `@Architect`

- (`@Observability`) Read `lib/main.dart` lines 80–160 to understand current error boundary structure.
- (`@Observability`) Modify `main()` function:
  - **CRITICAL ORDER:** `SentryFlutter.init()` wraps the existing `runZonedGuarded`. Sentry must be the outermost wrapper.
  - Inside `SentryFlutter.init()` options callback:
    - `options.dsn = const String.fromEnvironment('SENTRY_DSN')` (empty string = disabled).
    - `options.environment = const String.fromEnvironment('SENTRY_ENV', defaultValue: 'development')`.
    - `options.tracesSampleRate = 0.2`.
    - `options.beforeSend = (event, {hint}) => event` (placeholder for future PII scrubbing).
  - Inside `SentryFlutter.init()` app runner callback: preserve existing `runZonedGuarded` + `runApp()` exactly as-is.
- (`@Observability`) After Sentry init succeeds, set `CrashReportingService.instance = SentryCrashReportingService()`.
- (`@Observability`) In `FlutterError.onError` handler, AFTER existing `AppLogger.e()` call, add:
`CrashReportingService.instance.recordError(details.exception, details.stack, fatal: true)`.
- (`@Observability`) In `PlatformDispatcher.instance.onError` handler, AFTER existing `AppLogger.e()` call, add:
`CrashReportingService.instance.recordError(error, stack, fatal: true)`.
- (`@Observability`) In `runZonedGuarded` error handler, AFTER existing `AppLogger.e()` call, add:
`CrashReportingService.instance.recordError(error, stack, fatal: false)`.
- (`@Architect`) Verify: DSN is NOT hardcoded. Must be `String.fromEnvironment`.
- (`@Architect`) Verify: When `SENTRY_DSN` is empty, `SentryFlutter.init()` silently disables. Confirm by reading Sentry docs or testing.
- (`@Sentinel`) Run `flutter test` — all 706+ tests pass (Sentry should not interfere with tests when DSN is empty).
- (`@Sentinel`) Run `flutter analyze` — 0 issues.
- **GATE CHECK:** App starts with AND without `SENTRY_DSN`. Tests pass. No hardcoded secrets. Error boundary chain preserved.

### 1.4 Auth Session Integration

**Primary Agent(s):** `@Observability`

- (`@Observability`) Read `lib/features/auth/viewmodels/auth_session_view_model.dart`. Find the login success path and logout path.
- (`@Observability`) After successful login (where user ID is available), add:
`CrashReportingService.instance.setUserIdentifier(userId)`.
- (`@Observability`) On logout (before session clear), add:
`CrashReportingService.instance.setUserIdentifier('')`.
- (`@Observability`) Confirm: NO PII sent to Sentry. Only the anonymized Supabase user UUID. No email, name, phone.
- (`@Sentinel`) Run `flutter test test/unit/viewmodels/auth_session_view_model_test.dart` — all 32 tests pass.
- (`@Sentinel`) Run `flutter test` — full suite passes.
- **GATE CHECK:** User ID attached after login. Cleared after logout. No PII. Tests pass.

### 1.5 Sentry Documentation + Verification

**Primary Agent(s):** `@Sentinel`, `@DocsKeeper`

- (`@Sentinel`) Run `flutter test` — all 706+ tests pass.
- (`@Sentinel`) Run `flutter analyze` — 0 issues.
- (`@Sentinel`) Run `flutter build apk --debug` — compiles.
- (`@Sentinel`) Run `flutter build web --release` — compiles.
- (`@DocsKeeper`) Add to `CLAUDE.md` Build & Run section:
  ```
  flutter run --dart-define=SENTRY_DSN=<your_dsn>   # Enable crash reporting
  flutter run --dart-define=SENTRY_ENV=production    # Set environment
  ```
- **GATE CHECK:** Sentry complete. Both builds compile. Tests pass. DSN documented in CLAUDE.md.

---

## Phase 2: DashboardViewModel Decomposition (D2)

**Primary Agent(s):** `@Architect`, `@Sentinel`

### Goal

Decompose `dashboard_view_model.dart` (1149 lines) into 3 focused delegate classes while preserving the existing public API and all 20+ tests.

### Why

Audit §4.7: "too many responsibilities." The VM handles overview, bookings, inbox, work items, activity feed, role switching, and offer/booking actions in one file.

### How

Extract internal method groups into delegate classes. Parent VM composes delegates, proxies all public getters/methods. Delegates receive services from parent (not from Provider tree). Delegates use `isDisposed` callback for dispose safety.

### Result

`dashboard_view_model.dart` < 400 lines. 3 delegates in `lib/features/dashboard/viewmodels/`. All existing 20+ unit tests and 2 widget test files pass unchanged. 15+ new delegate tests added.

### 2.1 Identify Extraction Targets + Add Missing Mock

**Primary Agent(s):** `@Architect`, `@Sentinel`

- (`@Architect`) Read `dashboard_view_model.dart` fully (1149 lines).
- (`@Architect`) Produce extraction map:
  - **DashboardWorkDelegate** — `_fetchWorkItems()`, `_calculateNextActions()`, `_calculateActiveUpNext/InProgress/InReview()`, work caches, `performPrimaryAction()`, `withdrawOffer()`, `releaseOfferWithFee()`, `refundOffer()`, `cancelAwardedOffer()`. ~300 lines.
  - **DashboardInboxDelegate** — `_loadInboxData()`, `_fetchInboxInternal()`, `inboxGroupedByTask`, `awardOffer()`, `acceptOffer()`, `rejectOffer()`, `payAwardedOffer()`. ~250 lines.
  - **DashboardBookingDelegate** — `_loadBookingsData()`, `_fetchBookingsInternal()`, `setBookingFilter()`, `updateBookingStatus()`, `acceptBooking()`, `declineBooking()`, `cancelBooking()`, `_fetchPendingItemsInternal()`. ~200 lines.
- (`@Architect`) Document what STAYS in the parent VM: constructor, dispose, `teardownForRoleSwitch()`, `setRole()`, `_syncRoleFromBackend()`, `_loadCachedRole()`, `setTab()`, `_loadData()` orchestration, `_loadOverviewData()`, role/tab/loading state, `_safeNotify()`, `_abortIfDisposed()`.
- (`@Sentinel`) Add `MockTaskRequestsService` to `test/helpers/mock_services.dart` (needed for inbox delegate tests).
- (`@Sentinel`) Verify the extraction map covers all methods >10 lines. No orphans.
- **GATE CHECK:** Map documented. Mock added. No orphan methods.

### 2.2 Create DashboardWorkDelegate

**Primary Agent(s):** `@Architect`

- (`@Architect`) Create `lib/features/dashboard/viewmodels/dashboard_work_delegate.dart`.
- (`@Architect`) Constructor parameters: `DashboardRepository repo`, `TaskService taskService`, `BookingService bookingService`, `DirectOffersService directOffersService`, `VoidCallback onChanged`, `bool Function() isDisposed`.
- (`@Architect`) Move work item state: `_workItems`, `_nextActionsCache`, `_activeWorkCache`, `_deliveredWorkCache`, `_completedWorkCache`, `_cancelledWorkCache`.
- (`@Architect`) Move work methods: `fetchWorkItems()`, all `_calculate*()` methods, `performPrimaryAction()`, `withdrawOffer()`, `releaseOfferWithFee()`, `refundOffer()`, `cancelAwardedOffer()`.
- (`@Architect`) Add `invalidateCaches()` method for parent to call during role switch teardown.
- (`@Architect`) Add `clear()` method: resets `_workItems = []`, invalidates caches.
- (`@Architect`) Every async method checks `if (isDisposed()) return;` before calling `onChanged()`.
- (`@Architect`) Import ONLY `foundation.dart` (not `material.dart`). No view imports.
- (`@Sentinel`) Run `flutter analyze` — 0 issues.
- (`@Sentinel`) Run `flutter test test/unit/dashboard/dashboard_view_model_test.dart` — verify tests still compile (they test parent VM, not delegate directly yet).
- **GATE CHECK:** Delegate compiles. Analyze clean. Existing tests compile.

### 2.3 Create DashboardInboxDelegate

**Primary Agent(s):** `@Architect`

- (`@Architect`) Create `lib/features/dashboard/viewmodels/dashboard_inbox_delegate.dart`.
- (`@Architect`) Constructor parameters: `DashboardRepository repo`, `TaskService taskService`, `VoidCallback onChanged`, `bool Function() isDisposed`.
- (`@Architect`) Move inbox state: `_inboxOffers`, `_inboxLoaded`.
- (`@Architect`) Move inbox methods: `loadInboxData()`, `fetchInboxInternal()`, `inboxGroupedByTask` getter, `awardOffer()`, `acceptOffer()`, `rejectOffer()`, `payAwardedOffer()`.
- (`@Architect`) Add `clear()` method: resets state.
- (`@Architect`) Every async method checks `if (isDisposed()) return;` before calling `onChanged()`.
- (`@Architect`) Import ONLY `foundation.dart`. No view imports.
- (`@Sentinel`) Run `flutter analyze` — 0 issues.
- (`@Sentinel`) Run `flutter test test/unit/dashboard/dashboard_view_model_test.dart` — tests still compile.
- **GATE CHECK:** Delegate compiles. Analyze clean. Existing tests compile.

### 2.4 Create DashboardBookingDelegate

**Primary Agent(s):** `@Architect`

- (`@Architect`) Create `lib/features/dashboard/viewmodels/dashboard_booking_delegate.dart`.
- (`@Architect`) Constructor parameters: `BookingService bookingService`, `DashboardRepository repo`, `DirectOffersService directOffersService`, `VoidCallback onChanged`, `bool Function() isDisposed`.
- (`@Architect`) Move booking state: `_bookings`, `_bookingsLoaded`, `_pendingRequests`, `_pendingPaymentTenders`.
- (`@Architect`) Move booking methods: `loadBookingsData()`, `fetchBookingsInternal()`, `fetchPendingItemsInternal()`, `setBookingFilter()`, `updateBookingStatus()`, `acceptBooking()`, `declineBooking()`, `cancelBooking()`.
- (`@Architect`) Add `clear()` method.
- (`@Architect`) Every async method checks `if (isDisposed()) return;` before calling `onChanged()`.
- (`@Architect`) Import ONLY `foundation.dart`. No view imports.
- (`@Sentinel`) Run `flutter analyze` — 0 issues.
- (`@Sentinel`) Run `flutter test test/unit/dashboard/dashboard_view_model_test.dart` — tests still compile.
- **GATE CHECK:** Delegate compiles. Analyze clean. Existing tests compile.

### 2.5 Refactor DashboardViewModel to Compose Delegates

**Primary Agent(s):** `@Architect`

- (`@Architect`) In `DashboardViewModel` constructor, create delegate instances:
  - `_workDelegate = DashboardWorkDelegate(repo: _repository, taskService: _taskService, bookingService: _bookingService, directOffersService: _directOffersService, onChanged: _safeNotify, isDisposed: () => _isDisposed)`.
  - `_inboxDelegate = DashboardInboxDelegate(repo: _repository, taskService: _taskService, onChanged: _safeNotify, isDisposed: () => _isDisposed)`.
  - `_bookingDelegate = DashboardBookingDelegate(bookingService: _bookingService, repo: _repository, directOffersService: _directOffersService, onChanged: _safeNotify, isDisposed: () => _isDisposed)`.
- (`@Architect`) Replace ALL extracted method bodies with delegate forwarding calls:
  - `List<WorkItem> get workItems => _workDelegate.workItems;`
  - `List<WorkItem> get nextActions => _workDelegate.nextActions;`
  - `Future<void> withdrawOffer(String id) => _workDelegate.withdrawOffer(id);`
  - (... and so on for EVERY extracted public getter and method)
- (`@Architect`) Keep in parent VM (NOT delegated):
  - Constructor, `dispose()`, `teardownForRoleSwitch()`, `setRole()`, `_syncRoleFromBackend()`, `_loadCachedRole()`, `setTab()`, `_loadData()` orchestration, `_loadOverviewData()`, `refresh()`, role/tab/loading/disposed state, `_safeNotify()`, `_abortIfDisposed()`, `userName`, `currentUserId`.
- (`@Architect`) In `teardownForRoleSwitch()`, call `_workDelegate.clear()`, `_inboxDelegate.clear()`, `_bookingDelegate.clear()`.
- (`@Architect`) In `_loadData()`, call delegate fetch methods instead of removed internal methods.
- (`@Architect`) Verify line count < 400.
- (`@Sentinel`) Run `flutter analyze` — 0 issues.
- (`@Sentinel`) Run `flutter test test/unit/dashboard/dashboard_view_model_test.dart` — ALL existing tests pass.
- (`@Sentinel`) Run `flutter test test/widget/dashboard/` — widget tests pass.
- (`@Sentinel`) Run `flutter test` — full suite passes.
- **GATE CHECK:** Parent VM < 400 lines. ALL existing tests pass unchanged. Public API identical.

### 2.6 Add Delegate Unit Tests

**Primary Agent(s):** `@Sentinel`, `@Architect`

- (`@Sentinel`) Create `test/unit/dashboard/dashboard_work_delegate_test.dart`:
  - Test: work item fetch populates list and calls onChanged.
  - Test: cache invalidation clears cached work item lists.
  - Test: `performPrimaryAction()` dispatches correctly for each WorkItem type.
  - Test: `withdrawOffer()` calls service and refreshes.
  - Test: dispose safety — onChanged NOT called when isDisposed returns true.
  - Target: 7+ tests.
- (`@Sentinel`) Create `test/unit/dashboard/dashboard_inbox_delegate_test.dart`:
  - Test: inbox fetch populates list.
  - Test: `inboxGroupedByTask` groups correctly.
  - Test: `awardOffer()` calls service.
  - Test: `rejectOffer()` calls service.
  - Test: dispose safety.
  - Target: 5+ tests.
- (`@Sentinel`) Create `test/unit/dashboard/dashboard_booking_delegate_test.dart`:
  - Test: booking fetch populates list.
  - Test: `setBookingFilter()` filters correctly.
  - Test: `acceptBooking()` / `declineBooking()` call service.
  - Test: dispose safety.
  - Target: 5+ tests.
- (`@Sentinel`) Run `flutter test` — full suite passes. New tests included.
- (`@Sentinel`) Verify total test count increased by 15+.
- **GATE CHECK:** 15+ new delegate tests pass. Full suite green. Total test count documented.

---

## Phase 3: submit_request_sheet Decomposition (D3)

**Primary Agent(s):** `@Architect`, `@Pixel`, `@Sentinel`

### Goal

Decompose `submit_request_sheet.dart` (916 lines) by extracting business logic into `SubmitRequestViewModel` and splitting UI into focused widgets.

### Why

Audit §4.3 A8: Business logic (validation, price calc, bid comparison) in view layer. Untestable. MVVM violation.

### How

Create `SubmitRequestViewModel` for all business logic. Provide it via scoped `ChangeNotifierProvider` inside the `showModalBottomSheet` builder. Extract UI builders into widget files. Preserve function entry point.

### Result

`submit_request_sheet.dart` < 500 lines. Business logic tested in isolation. 10+ new tests.

### 3.1 Analyze Current Structure

**Primary Agent(s):** `@Architect`

- (`@Architect`) Read `submit_request_sheet.dart` fully (916 lines).
- (`@Architect`) Identify business logic blocks:
  - Task guard logic (lines 32–86): status check, ownership check, task fetch.
  - Bid replaceability detection (lines 93–128): `checkBidReplaceability()` call.
  - Price comparison / change calculation (inline in dialog builder).
  - Form validation (form key, field validators).
  - Submission logic (bid creation, replacement, error handling).
- (`@Architect`) Identify UI blocks:
  - TextEditingController creation (lines 88–91).
  - Form fields (price, days, note).
  - Summary row builders (change indicators, comparison display).
  - SnackBar display.
  - Modal bottom sheet layout.
- (`@Architect`) Document the extraction map: what goes to ViewModel, what stays as UI, what becomes extracted widgets.
- (`@Sentinel`) Verify map is complete — no logic unaccounted.
- **GATE CHECK:** Extraction map documented.

### 3.2 Create SubmitRequestViewModel

**Primary Agent(s):** `@Architect`

- (`@Architect`) Create `lib/features/tasks/viewmodels/submit_request_view_model.dart`.
- (`@Architect`) Constructor: `SubmitRequestViewModel({required TaskService taskService, required TaskRequestsService requestsService, required TaskRequestsViewModel requestsVM, required String taskId, required String? userId, required String budget})`.
- (`@Architect`) Move into VM:
  - Task guard logic: `Future<bool> validateTask()` — returns true if task is open and user is not owner. Sets `guardError` state on failure.
  - Bid replaceability: `Future<void> checkReplaceability()` — calls `requestsVM.checkBidReplaceability()`, stores result.
  - Price comparison: `Map<String, dynamic>? get priceComparison` — computes diff between existing bid and new values.
  - Submission: `Future<bool> submit({required String price, required String days, required String note})`.
  - Replace bid: `Future<bool> replaceBid({required String price, required String days, required String note})`.
- (`@Architect`) State fields: `isSubmitting`, `guardError`, `submitError`, `replaceabilityResult`, `existingBid`, `isReplace`.
- (`@Architect`) Import ONLY `foundation.dart`, service/model files. No `material.dart`, no widget imports.
- (`@Sentinel`) Confirm: no MVVM violations. No view imports.
- (`@Sentinel`) Run `flutter analyze` — 0 issues.
- **GATE CHECK:** ViewModel compiles. No MVVM violations.

### 3.3 Extract UI Widget Components

**Primary Agent(s):** `@Pixel`

- (`@Pixel | Skill: distill`) Extract summary row builders into `lib/features/tasks/view/widgets/requests/submit_request_summary.dart`. These are the comparison display widgets that show old vs. new bid values.
- (`@Pixel | Skill: distill`) Extract change indicator widgets into `lib/features/tasks/view/widgets/requests/submit_request_change_indicator.dart`. These are the color-coded increase/decrease indicators.
- (`@Pixel | Skill: arrange`) Each extracted widget is a `StatelessWidget` that receives data via constructor parameters (not via Provider).
- (`@Sentinel`) Verify no visual changes — extracted widgets render identically to inline builders.
- (`@Sentinel`) Run `flutter analyze` — 0 issues.
- **GATE CHECK:** Widgets compile. Visual parity.

### 3.4 Wire ViewModel into Sheet (Scoped Provider)

**Primary Agent(s):** `@Architect`, `@Pixel`

- (`@Architect`) Refactor `showSubmitRequestSheet()`:
  - Task guard logic moves to: `final vm = SubmitRequestViewModel(...)` → `await vm.validateTask()` → early return if invalid.
  - `showModalBottomSheet` builder wraps content in:
    ```dart
    ChangeNotifierProvider<SubmitRequestViewModel>.value(
      value: vm,
      child: _SubmitRequestSheetContent(...),
    )
    ```
  - `_SubmitRequestSheetContent` is a new `StatelessWidget` (or `StatefulWidget` for TextEditingControllers) that uses `context.watch<SubmitRequestViewModel>()`.
- (`@Pixel`) Replace inline logic calls with VM state reads: `vm.isSubmitting`, `vm.isReplace`, `vm.priceComparison`.
- (`@Pixel`) Replace inline submission calls with `vm.submit(price: ..., days: ..., note: ...)`.
- (`@Architect`) TextEditingControllers stay in the view layer (inside `_SubmitRequestSheetContent`). VM receives values as parameters to `submit()`.
- (`@Architect`) Verify `submit_request_sheet.dart` is under 500 lines.
- (`@Sentinel`) Run `flutter analyze` — 0 issues.
- (`@Sentinel`) Run `flutter test` — all pass.
- **GATE CHECK:** Sheet works. Line count < 500. Tests pass.

### 3.5 Add SubmitRequestViewModel Tests

**Primary Agent(s):** `@Sentinel`, `@Architect`

- (`@Sentinel`) Create `test/unit/viewmodels/submit_request_view_model_test.dart`.
- (`@Sentinel`) Test cases:
  - `validateTask()` returns false when task is not open.
  - `validateTask()` returns false when user is task owner.
  - `validateTask()` returns true for valid task.
  - `checkReplaceability()` detects existing bid.
  - `submit()` creates new bid successfully.
  - `submit()` sets `submitError` on failure.
  - `replaceBid()` archives old bid and creates new one.
  - `isSubmitting` is true during async operation.
  - `priceComparison` computes correct diff.
  - Error handling: network failure during submit.
- (`@Sentinel`) Target: 10+ tests.
- (`@Sentinel`) Run `flutter test` — full suite passes.
- **GATE CHECK:** 10+ new tests pass. Full suite green.

---

## Phase 4: requests_list_screen Decomposition (D4)

**Primary Agent(s):** `@Architect`, `@Pixel`, `@Sentinel`

### Goal

Decompose `requests_list_screen.dart` (1172 lines) by extracting filter/sort logic into a ViewModel and splitting UI into widget files.

### Why

Audit §4.3 A8: Filter logic, sort comparators, expired bid handling, and pagination state in view layer. Untestable.

### How

Create `RequestsFilterViewModel` for filter/sort/pagination logic. Extract modal builders and list items into widget files. Keep `ExpiredBidFilter` enum in a shared location.

### Result

`requests_list_screen.dart` < 500 lines. Filter logic tested. 10+ new tests.

### 4.1 Analyze Current Structure

**Primary Agent(s):** `@Architect`

- (`@Architect`) Read `requests_list_screen.dart` fully (1172 lines).
- (`@Architect`) Identify logic blocks:
  - `ExpiredBidFilter` enum + extension (lines 20–44) — move to model file.
  - Filter state management (`_filter` field, filter switching).
  - Sort comparators (bid sorting logic).
  - Expired bid detection and filtering.
  - Pagination state (`_hasMore`, `_isLoadingMore`, cursor management).
- (`@Architect`) Identify UI blocks:
  - List item builder (bid card rendering).
  - Modal builders (award confirmation, reject confirmation, share options).
  - Filter chip bar.
  - Pagination scroll listener.
- (`@Architect`) Read `task_requests_view_model.dart` (845 lines) to assess: extend it or create new VM?
  - **Decision criterion:** If TaskRequestsVM already has filter/sort methods → extend. If not → create `RequestsFilterViewModel`.
- (`@Architect`) Document extraction map with decision rationale.
- (`@Sentinel`) Verify map is complete.
- **GATE CHECK:** Extraction map documented with decision.

### 4.2 Create RequestsFilterViewModel (or Extend TaskRequestsVM)

**Primary Agent(s):** `@Architect`

- (`@Architect`) Based on 4.1 decision, create `lib/features/tasks/viewmodels/requests_filter_view_model.dart` (preferred) OR add methods to existing `task_requests_view_model.dart`.
- (`@Architect`) Move `ExpiredBidFilter` enum to `lib/features/tasks/models/expired_bid_filter.dart` (reusable).
- (`@Architect`) Move filter/sort logic: `currentFilter`, `setFilter()`, `sortOrder`, `setSortOrder()`, expired bid filtering.
- (`@Architect`) Move pagination logic: `hasMore`, `isLoadingMore`, `loadMore()`, cursor management.
- (`@Architect`) Expose: `filteredRequests` getter (applies filter + sort to raw items from `TaskRequestsViewModel`).
- (`@Architect`) Import ONLY `foundation.dart` and models. No view imports.
- (`@Sentinel`) Confirm no MVVM violations.
- (`@Sentinel`) Run `flutter analyze` — 0 issues.
- **GATE CHECK:** Filter VM compiles. No MVVM violations.

### 4.3 Extract UI Widget Components

**Primary Agent(s):** `@Pixel`

- (`@Pixel | Skill: distill`) Extract list item builder into `lib/features/tasks/view/widgets/requests/request_list_item.dart`. StatelessWidget receiving `TaskRequest` + callbacks.
- (`@Pixel | Skill: distill`) Extract modal builders into `lib/features/tasks/view/widgets/requests/request_action_modals.dart`. Contains award/reject/share bottom sheets as static methods or top-level functions.
- (`@Pixel | Skill: arrange`) Refactor main screen to compose extracted widgets.
- (`@Sentinel`) Verify no visual changes.
- (`@Sentinel`) Run `flutter analyze` — 0 issues.
- **GATE CHECK:** Widgets compile. Visual parity.

### 4.4 Wire and Verify

**Primary Agent(s):** `@Architect`, `@Sentinel`

- (`@Architect`) Refactor `requests_list_screen.dart` to use the filter ViewModel.
- (`@Architect`) If new VM created: provide via scoped `ChangeNotifierProvider` in screen's `build()`.
- (`@Architect`) Verify `requests_list_screen.dart` < 500 lines.
- (`@Sentinel`) Run `flutter analyze` — 0 issues.
- (`@Sentinel`) Run `flutter test` — all pass.
- **GATE CHECK:** Screen works. Line count < 500. Tests pass.

### 4.5 Add Filter ViewModel Tests

**Primary Agent(s):** `@Sentinel`, `@Architect`

- (`@Sentinel`) Create tests for the filter/sort ViewModel.
- (`@Sentinel`) Test cases:
  - `setFilter(hideExpired)` excludes expired bids.
  - `setFilter(showAll)` includes all bids.
  - `setFilter(showOnlyExpired)` includes only expired bids.
  - Sort by price ascending/descending.
  - Sort by date ascending/descending.
  - Pagination: `loadMore()` appends items.
  - Pagination: `hasMore` is false when last page reached.
  - Combined filter + sort produces correct ordering.
  - Empty list edge case.
  - Filter change resets pagination cursor.
- (`@Sentinel`) Target: 10+ tests.
- (`@Sentinel`) Run `flutter test` — full suite passes.
- **GATE CHECK:** 10+ new tests pass. Full suite green.

---

## Phase 5: Edge Function Security Hardening (D7, D8)

**Primary Agent(s):** `@Supabase_Ops`, `@ThreatModeler`, `@Sentinel`

### Goal

Tighten CORS on all Edge Functions. Add paymentId input validation on webhook handler.

### Why

Audit §4.5 S1: CORS `*` on all 12 Edge Functions. S2: paymentId lacks format validation before use in `.or()` query.

### How

Add `getCorsHeaders(req)` function with origin allowlist. Migrate all 12 functions. Add regex validation for paymentId.

### Result

CORS restricted to allowlist. paymentId validated. All 12 functions updated.

### 5.1 Add getCorsHeaders Function (Backward Compatible)

**Primary Agent(s):** `@Supabase_Ops`, `@ThreatModeler`

- (`@Supabase_Ops | Skill: supabase-migration`) Read `supabase/functions/_shared/bookin_payment.ts`.
- (`@Supabase_Ops | Skill: supabase-migration`) Add new function alongside existing export:
  ```typescript
  const ALLOWED_ORIGINS = (Deno.env.get("ALLOWED_ORIGINS") || "https://sline.app").split(",");

  export function getCorsHeaders(req: Request): Record<string, string> {
    const origin = req.headers.get("Origin") || "";
    const allowed = ALLOWED_ORIGINS.find(o =>
      origin === o || (o.startsWith("http://localhost") && origin.startsWith("http://localhost"))
    );
    return {
      "Access-Control-Allow-Origin": allowed || ALLOWED_ORIGINS[0],
      "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-signature",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
    };
  }
  ```
- (`@Supabase_Ops | Skill: supabase-migration`) Keep old `corsHeaders` export temporarily (backward compatible). Add `/** @deprecated Use getCorsHeaders(req) instead */` comment.
- (`@ThreatModeler`) Verify: function does NOT reflect arbitrary origins. If origin doesn't match, returns first allowed origin.
- (`@ThreatModeler`) Verify: `http://localhost` pattern matching doesn't accidentally allow `http://localhost.evil.com`.
- **GATE CHECK:** New function exported. Old export still works. No breaking changes yet.

### 5.2 Migrate All 12 Edge Functions to getCorsHeaders

**Primary Agent(s):** `@Supabase_Ops`

- (`@Supabase_Ops | Skill: supabase-migration`) List all 12 files that import from `_shared/bookin_payment.ts`:
  1. `booking_decline_refund/index.ts`
  2. `create_payment_intent/index.ts`
  3. `finalize_payment_webhook/index.ts`
  4. `process-push-queue/index.ts`
  5. `push-notify/index.ts`
  6. `qicard_payment_create/index.ts`
  7. `qicard_payment_create_direct_offer/index.ts`
  8. `qicard_payment_create_tender/index.ts`
  9. `qicard_payment_recovery/index.ts`
  10. `qicard_payment_recovery_direct_offer/index.ts`
  11. `qicard_payment_recovery_tender/index.ts`
  12. `qicard_webhook_handler/index.ts`
- (`@Supabase_Ops | Skill: supabase-migration`) For each file:
  - Replace `corsHeaders` import with `getCorsHeaders` import.
  - Replace `corsHeaders` usage in `new Response(...)` with `getCorsHeaders(req)`.
  - Ensure the `req` parameter is available where CORS headers are used (it should be — these are Deno serve handlers).
- (`@Supabase_Ops | Skill: supabase-migration`) Remove deprecated `corsHeaders` static export from `_shared/bookin_payment.ts`.
- (`@Sentinel`) Verify all 12 functions compile (no TypeScript errors).
- **GATE CHECK:** All 12 functions use `getCorsHeaders(req)`. Static `corsHeaders` removed.

### 5.3 Add paymentId Regex Validation

**Primary Agent(s):** `@Supabase_Ops`, `@ThreatModeler`

- (`@Supabase_Ops | Skill: supabase-migration`) Read `supabase/functions/qicard_webhook_handler/index.ts` around line 243.
- (`@Supabase_Ops | Skill: supabase-migration`) Add validation BEFORE the `.or()` query:
  ```typescript
  const PAYMENT_ID_REGEX = /^[a-zA-Z0-9\-_]{1,128}$/;
  if (!PAYMENT_ID_REGEX.test(paymentId)) {
    console.warn(`[webhook] Invalid paymentId format: ${paymentId.substring(0, 20)}`);
    return new Response(JSON.stringify({ error: "Invalid payment ID format" }), {
      status: 400, headers: { ...getCorsHeaders(req), "Content-Type": "application/json" }
    });
  }
  ```
- (`@Supabase_Ops | Skill: supabase-migration`) Also validate `intentId` with the same regex if it's used in the same `.or()` query.
- (`@ThreatModeler`) Verify regex covers all valid QiCard payment ID formats. Check a few existing `payment_intents.id` values for pattern.
- (`@ThreatModeler`) Verify: rejection logs the attempt but does NOT log the full malicious input (truncate to 20 chars).
- (`@Sentinel`) Verify valid payment webhooks still process correctly.
- **GATE CHECK:** Validation in place. Valid IDs pass. Invalid IDs return 400.

### 5.4 CORS Verification

**Primary Agent(s):** `@ThreatModeler`, `@Sentinel`

- (`@ThreatModeler`) Verify test cases:
  - `Origin: https://sline.app` → `Access-Control-Allow-Origin: https://sline.app`
  - `Origin: http://localhost:3000` → `Access-Control-Allow-Origin: http://localhost:3000`
  - `Origin: https://evil.com` → `Access-Control-Allow-Origin: https://sline.app` (first allowed, NOT reflecting evil.com)
  - No `Origin` header → `Access-Control-Allow-Origin: https://sline.app` (first allowed)
  - `Origin: http://localhost.evil.com` → `Access-Control-Allow-Origin: https://sline.app` (NOT matching localhost pattern)
- (`@Sentinel`) Verify all 12 functions have no remaining `corsHeaders` references (only `getCorsHeaders`).
- **GATE CHECK:** CORS hardened. All test cases pass.

---

## Phase 6: pgTAP Tests for Critical RPCs (D5)

**Primary Agent(s):** `@Supabase_Ops`, `@Sentinel`

### Goal

Add SQL-level tests for 3 critical RPCs.

### Why

Audit §4.5 S4: No pgTAP tests. Critical state transitions validated only by integration tests.

### How

Check pgTAP availability. If available, write pgTAP tests. If not, write plain SQL assertion scripts. Document execution.

### Result

SQL tests exist for 3 RPCs. Execution documented.

### 6.1 Verify pgTAP Availability + Create Directory

**Primary Agent(s):** `@Supabase_Ops`

- (`@Supabase_Ops | Skill: supabase-migration`) Check pgTAP: `SELECT * FROM pg_available_extensions WHERE name = 'pgtap';`
- (`@Supabase_Ops | Skill: supabase-migration`) If available: `CREATE EXTENSION IF NOT EXISTS pgtap;`
- (`@Supabase_Ops | Skill: supabase-migration`) If NOT available: document this. Use plain SQL assertion pattern instead:
  ```sql
  -- Assert: double acceptance fails
  DO $$ BEGIN
    PERFORM accept_task_request(...); -- first call
    BEGIN
      PERFORM accept_task_request(...); -- second call should fail
      RAISE EXCEPTION 'Expected error not raised';
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'PASS: double acceptance correctly prevented';
    END;
  END $$;
  ```
- (`@Supabase_Ops | Skill: supabase-migration`) Create `supabase/tests/` directory.
- **GATE CHECK:** pgTAP status confirmed. Directory created. Approach decided.

### 6.2 Test: accept_task_request Prevents Double-Acceptance

**Primary Agent(s):** `@Supabase_Ops`

- (`@Supabase_Ops | Skill: supabase-migration`) Read `accept_task_request` RPC definition from migrations.
- (`@Supabase_Ops | Skill: supabase-migration`) Write `supabase/tests/accept_task_request_test.sql`:
  - Setup: create test users, task, two requests (using service_role for setup).
  - Test 1: Accept first request → succeeds (status changes to 'accepted').
  - Test 2: Accept second request on same task → fails (double-acceptance prevented).
  - Test 3: Accept request on non-existent task → fails gracefully.
  - Teardown: delete test data.
- (`@Sentinel`) Verify test exercises actual RPC, not mocked logic.
- **GATE CHECK:** Test file exists. Logic correct.

### 6.3 Test: process_gateway_escrow_booking Idempotency

**Primary Agent(s):** `@Supabase_Ops`

- (`@Supabase_Ops | Skill: supabase-migration`) Read `process_gateway_escrow_booking` RPC definition.
- (`@Supabase_Ops | Skill: supabase-migration`) Write `supabase/tests/escrow_idempotency_test.sql`:
  - Test 1: First escrow hold with idempotency key → succeeds.
  - Test 2: Same key again → no error, no duplicate ledger entry.
  - Test 3: Different amount with same key → fails.
- (`@Sentinel`) Verify idempotency behavior matches audit expectations.
- **GATE CHECK:** Test file exists. Logic correct.

### 6.4 Test: switch_active_role Rate Limit

**Primary Agent(s):** `@Supabase_Ops`

- (`@Supabase_Ops | Skill: supabase-migration`) Read `switch_active_role` RPC definition.
- (`@Supabase_Ops | Skill: supabase-migration`) Write `supabase/tests/role_switch_rate_limit_test.sql`:
  - Test 1: 3 switches within 1 minute → all succeed.
  - Test 2: 4th switch within 1 minute → fails (rate limit).
  - Test 3: Switch after cooldown → succeeds.
- (`@Sentinel`) Verify rate limit matches documented 3/minute.
- **GATE CHECK:** Test file exists. Logic correct.

### 6.5 Document Test Runner

**Primary Agent(s):** `@Supabase_Ops`, `@DocsKeeper`

- (`@Supabase_Ops`) Add to `CLAUDE.md` Build & Run section:
  ```
  # Run pgTAP / SQL assertion tests (requires Supabase CLI + local DB)
  supabase db test                    # If pgTAP available
  psql $DATABASE_URL -f supabase/tests/<test_file>.sql  # Manual execution
  ```
- (`@Supabase_Ops`) Add comment header in each test file: prerequisites, execution method, expected output.
- **GATE CHECK:** Execution documented.

---

## Phase 7: A6 Fixes + Coverage Floor + Migration Checklist + Guard Tightening (D6, D9, D10, D11)

**Primary Agent(s):** `@Architect`, `@Sentinel`

### Goal

Fix A6 architecture violations. Enforce coverage regression floor. Create migration checklist. Tighten architecture guard.

### Why

A6 violations prevent unit testing. Coverage without enforcement is theater. Migration discipline prevents schema accidents. Guard exclusion allows regressions.

### How

Refactor 2 VMs for full DI. Measure coverage and set floor. Create checklist document. Remove guard exclusion.

### Result

All VMs injectable. Coverage floor enforced. Checklist exists. Guard tightened.

### 7.1 Fix NotificationViewModel (A6)

**Primary Agent(s):** `@Architect`

- (`@Architect`) Read `lib/features/notifications/viewmodels/notification_view_model.dart` fully (192 lines).
- (`@Architect`) Constructor already has `Stream<AuthState>? authStateChanges` parameter. Add:
  - `SupabaseClient? client` parameter.
  - Store as `final SupabaseClient _client;`, defaulting to `client ?? Supabase.instance.client`.
- (`@Architect`) Replace line 55: `Supabase.instance.client.auth.onAuthStateChange` → `_client.auth.onAuthStateChange`.
- (`@Architect`) Replace line 56: `Supabase.instance.client.auth.currentUser` → `_client.auth.currentUser`.
- (`@Architect`) Replace line 147: `Supabase.instance.client.auth.currentUser` → `_client.auth.currentUser`.
- (`@Architect`) Verify: refactoring is additive. Existing callers passing no `client` argument still work via default.
- (`@Sentinel`) Run `flutter analyze` — 0 issues.
- (`@Sentinel`) Run `flutter test` — all pass.
- **GATE CHECK:** No `Supabase.instance` outside DI constructor default.

### 7.2 Fix SavedTasksViewModel (A6)

**Primary Agent(s):** `@Architect`

- (`@Architect`) Read `lib/features/saved/viewmodels/saved_tasks_view_model.dart` fully (152 lines).
- (`@Architect`) Add to constructor: `SupabaseClient? client` parameter.
- (`@Architect`) Store as `final SupabaseClient _client;`, defaulting to `client ?? Supabase.instance.client`.
- (`@Architect`) Replace line 108: `Supabase.instance.client.auth.currentUser` → `_client.auth.currentUser`.
- (`@Architect`) Replace line 112: `Supabase.instance.client.auth.onAuthStateChange` → `_client.auth.onAuthStateChange`.
- (`@Architect`) Verify: additive. Existing callers unaffected.
- (`@Sentinel`) Run `flutter analyze` — 0 issues.
- (`@Sentinel`) Run `flutter test` — all pass.
- **GATE CHECK:** No `Supabase.instance` outside DI constructor default.

### 7.3 Tighten Architecture Guard Check 3 (D11)

**Primary Agent(s):** `@Architect`, `@Sentinel`

- (`@Architect`) Edit `.github/workflows/ci.yml` line 56. Remove the exclusion: `grep -v 'Supabase\.instance\.client\.auth\.'`.
- (`@Architect`) The tightened Check 3 becomes:
  ```bash
  if grep -rn --include='*.dart' 'Supabase\.instance' lib/features/ | grep '/viewmodels/' | grep -v 'client ??' | grep -v '/// ' | grep -v 'Supabase\.instance\.client)' | grep -v 'Supabase\.instance\.client;' ; then
  ```
- (`@Sentinel`) Run the tightened guard locally. Verify it passes (A6 violations are now fixed).
- (`@Sentinel`) Verify: adding `Supabase.instance.client.auth.currentUser` back into a viewmodel would be caught.
- **GATE CHECK:** Guard tightened. Passes clean. Would catch regressions.

### 7.4 Add CI Coverage Regression Floor (D9)

**Primary Agent(s):** `@Architect`, `@Sentinel`

- (`@Sentinel`) Run `flutter test --coverage` locally.
- (`@Sentinel`) Calculate current coverage from `coverage/lcov.info`:
  ```bash
  TOTAL=$(grep -c '^DA:' coverage/lcov.info)
  HIT=$(grep '^DA:' coverage/lcov.info | grep -cv ',0$')
  PERCENT=$(awk "BEGIN { printf \"%.1f\", ($HIT / $TOTAL) * 100 }")
  ```
- (`@Sentinel`) Record measured percentage in session log. (Expected: ~30.6% based on prior measurement.)
- (`@Architect`) Set threshold: measured percentage minus 2 (rounded down). E.g., if 30.6% → threshold = 28%.
- (`@Architect`) Edit `.github/workflows/ci.yml` test job. After coverage report step, add:
  ```yaml
  - name: Enforce coverage floor
    if: always()
    run: |
      if [ -f coverage/lcov.info ]; then
        TOTAL=$(grep -c '^DA:' coverage/lcov.info || echo 0)
        HIT=$(grep '^DA:' coverage/lcov.info | grep -cv ',0$' || echo 0)
        if [ "$TOTAL" -gt 0 ]; then
          PERCENT=$(awk "BEGIN { printf \"%.1f\", ($HIT / $TOTAL) * 100 }")
          THRESHOLD=28
          PASS=$(awk "BEGIN { print ($PERCENT >= $THRESHOLD) ? 1 : 0 }")
          if [ "$PASS" -eq 0 ]; then
            echo "::error::Coverage ${PERCENT}% is below required ${THRESHOLD}%"
            exit 1
          fi
          echo "Coverage ${PERCENT}% meets threshold ${THRESHOLD}%"
        fi
      fi
  ```
- (`@Sentinel`) Verify: CI passes at current coverage level.
- (`@Architect`) Document threshold in `CLAUDE.md` CI/CD section: "Coverage floor: 28% (regression prevention). Raise incrementally."
- **GATE CHECK:** CI enforces coverage floor. Documented.

### 7.5 Create Migration Review Checklist (D6)

**Primary Agent(s):** `@DocsKeeper`

- (`@DocsKeeper`) Create `MIGRATION_REVIEW_CHECKLIST.md` in project root.
- (`@DocsKeeper`) Include 7 review questions from Audit §4.8:
  1. **Naming:** `YYYYMMDD_description.sql` convention?
  2. **Rollback:** Down migration or rollback plan?
  3. **Data safety:** Existing rows that violate new constraints?
  4. **RLS impact:** Policies affected? Authenticated queries still work?
  5. **RPC contract:** Signature changes? Client updated in same PR?
  6. **Idempotency:** Safe to re-run? (`CREATE OR REPLACE`, `IF NOT EXISTS`)
  7. **Performance:** New index? Query hits existing index?
- (`@DocsKeeper`) Add "How to use" section: reference in every PR with `supabase/migrations/` files.
- (`@DocsKeeper`) Add reference in `CLAUDE.md` Supabase Backend section.
- (`@Sentinel`) Confirm checklist covers all Audit §4.8 categories.
- **GATE CHECK:** Checklist exists. Referenced in CLAUDE.md.

---

## Phase 8: Full QA + Security Verification (MANDATORY)

**Primary Agent(s):** `@Sentinel`, `@CodeGuard`, `@ThreatModeler`

### Goal

Verify all Phase D changes meet acceptance criteria. No regressions. No security gaps.

### Why

Phase C post-mortem identified file corruption during parallel agent execution. Explicit verification prevents silent breakage.

### How

Run all verification commands. Check every acceptance criterion. Document results.

### Result

All 15 acceptance criteria verified. Results documented in session log.

### 8.1 Non-Regression Verification

**Primary Agent(s):** `@Sentinel`

- (`@Sentinel`) Run `flutter test` — record: X passed (must be 706 + new tests), Y skipped, 0 failures.
- (`@Sentinel`) Run `flutter analyze` — 0 issues.
- (`@Sentinel`) Run `dart format --set-exit-if-changed .` — 0 changes.
- (`@Sentinel`) Run all 6 architecture guard checks locally — all pass (including tightened Check 3).
- (`@Sentinel`) Verify total test count increased by 35+ over baseline.
- **GATE CHECK:** Full non-regression pass.

### 8.2 Architecture Compliance

**Primary Agent(s):** `@Sentinel`, `@CodeGuard`

- (`@Sentinel`) `grep -rn 'Supabase\.instance' lib/features/*/viewmodels/` — only DI constructor `??` defaults remain.
- (`@Sentinel`) `grep -rn 'TextEditingController' lib/features/*/viewmodels/` — zero results.
- (`@Sentinel`) `grep -rn 'Navigator\.' lib/features/*/viewmodels/` — zero results.
- (`@Sentinel`) `grep -rn "import.*\/view\/" lib/features/*/viewmodels/` — zero results.
- (`@CodeGuard`) Review all new files (delegates, ViewModels, widgets) for import cleanliness.
- (`@CodeGuard`) Verify new `SubmitRequestViewModel` and `RequestsFilterViewModel` have injectable constructors.
- **GATE CHECK:** Architecture boundaries enforced.

### 8.3 God File Line Counts

**Primary Agent(s):** `@Sentinel`

- (`@Sentinel`) `wc -l` on all three files:
  - `dashboard_view_model.dart` < 400 lines.
  - `submit_request_sheet.dart` < 500 lines.
  - `requests_list_screen.dart` < 500 lines.
- **GATE CHECK:** All three decomposed to target sizes.

### 8.4 Edge Function Verification

**Primary Agent(s):** `@ThreatModeler`, `@Sentinel`

- (`@ThreatModeler`) Verify: no remaining `corsHeaders` (static) references in any Edge Function. Only `getCorsHeaders(req)`.
- (`@ThreatModeler`) Verify: `"Access-Control-Allow-Origin": "*"` does not appear in any file under `supabase/functions/`.
- (`@ThreatModeler`) Verify: paymentId validation rejects empty string, `'; DROP TABLE`, >128 chars, special characters.
- (`@Sentinel`) Verify: valid paymentId format passes.
- **GATE CHECK:** Edge Functions hardened.

### 8.5 Build Verification

**Primary Agent(s):** `@Sentinel`

- (`@Sentinel`) `flutter build apk --debug` — succeeds.
- (`@Sentinel`) `flutter build web --release` — succeeds.
- **GATE CHECK:** Both targets compile.

### 8.6 Acceptance Criteria Checklist

**Primary Agent(s):** `@Sentinel`

- (`@Sentinel`) Check ALL 15 acceptance criteria from Phase 0.1 against actual state. Mark each PASS/FAIL.
- (`@Sentinel`) If any FAIL: document which phase is responsible and what fix is needed.
- (`@Sentinel`) Write results to session log.
- **GATE CHECK:** All 15 criteria PASS.

---

## Phase 9: Documentation Sync (MANDATORY)

**Primary Agent(s):** `@DocsKeeper`

### Goal

Sync all documentation with implementation reality.

### Why

Phase D creates new files, changes CI, adds Edge Function logic, adds test infrastructure. Docs must reflect this.

### How

Update STRUCTURE.md, DEVELOPER_GUIDE.md, CLAUDE.md, Audit file. Write doc sync file.

### Result

All docs current. Audit file updated with Phase D completion markers.

### 9.1 Update Structure Documentation

**Primary Agent(s):** `@DocsKeeper`

- (`@DocsKeeper`) Update `Sline_everything/STRUCTURE.md`:
  - Add delegate files under `lib/features/dashboard/viewmodels/`.
  - Add `submit_request_view_model.dart` under `lib/features/tasks/viewmodels/`.
  - Add `requests_filter_view_model.dart` under `lib/features/tasks/viewmodels/` (or note extension of existing).
  - Add extracted widget files under `lib/features/tasks/view/widgets/requests/`.
  - Add `sentry_crash_reporting_service.dart` under `lib/core/services/`.
  - Add `supabase/tests/` directory with test files.
  - Add `MIGRATION_REVIEW_CHECKLIST.md` to project root listing.
  - Update test count: 706 → new total.
- **GATE CHECK:** STRUCTURE.md reflects all new files.

### 9.2 Update Developer Guide + CLAUDE.md

**Primary Agent(s):** `@DocsKeeper`

- (`@DocsKeeper`) Update `Sline_everything/DEVELOPER_GUIDE.md`:
  - Add Sentry crash reporting section.
  - Update crash reporting section (no longer NoOp).
  - Document delegate pattern for DashboardVM as architectural example.
- (`@DocsKeeper`) Update `CLAUDE.md`:
  - Build & Run: Add `--dart-define=SENTRY_DSN=<dsn>` for release builds.
  - Build & Run: Add pgTAP/SQL test runner commands.
  - CI/CD: Add coverage floor enforcement note (28% threshold).
  - CI/CD: Note tightened architecture guard Check 3.
  - Supabase: Reference `MIGRATION_REVIEW_CHECKLIST.md`.
- **GATE CHECK:** CLAUDE.md and DEVELOPER_GUIDE.md updated.

### 9.3 Update Audit File + Write Sync Doc

**Primary Agent(s):** `@DocsKeeper`

- (`@DocsKeeper`) Update `.TODO/AUDIT_Quality_Architecture_2026-04-01.md`:
  - Mark D1–D11 items as DONE with dates in Phase D section.
  - Update Feature-Level Health Map if applicable (search → still RED, saved → GREEN after A6 fix).
- (`@DocsKeeper`) Write `.TODO/DOCS_SYNC_2026-04-03_PhaseD.md` documenting all doc changes.
- (`@DocsKeeper`) Update session log with final status, timeline, and findings.
- **GATE CHECK:** Audit file updated. Sync doc written. Session log complete.

---

## Acceptance Criteria (MANDATORY — 15 Criteria)

1. `CrashReportingService.instance` is `SentryCrashReportingService` when `SENTRY_DSN` is set.
2. `dashboard_view_model.dart` < 400 lines with 3 tested delegate classes.
3. `submit_request_sheet.dart` < 500 lines with tested `SubmitRequestViewModel`.
4. `requests_list_screen.dart` < 500 lines with tested filter ViewModel.
5. `notification_view_model.dart` — no `Supabase.instance` outside DI constructor default.
6. `saved_tasks_view_model.dart` — no `Supabase.instance` outside DI constructor default.
7. Edge Function CORS restricted to allowlist (`sline.app` + `localhost`). No `*` anywhere.
8. `paymentId` regex validation active in webhook handler.
9. CI coverage regression floor enforced (28%).
10. pgTAP / SQL assertion tests exist for 3 critical RPCs.
11. `MIGRATION_REVIEW_CHECKLIST.md` exists and is referenced in `CLAUDE.md`.
12. All 706+ existing tests pass. 35+ new tests added. `flutter analyze`: 0 issues.
13. Architecture guard: all 6 checks pass. Check 3 tightened (no auth exclusion).
14. Both build targets compile (`apk --debug`, `web --release`).
15. Documentation synced: STRUCTURE.md, DEVELOPER_GUIDE.md, CLAUDE.md, Audit file updated.

---

## Rollback Plan

### Immediately Revertible

- **Sentry (Phase 1):** Remove `sentry_flutter` from pubspec, revert `main.dart`, delete `SentryCrashReportingService` file. Falls back to NoOp.
- **Edge Functions (Phase 5):** Revert `_shared/bookin_payment.ts` to static `corsHeaders`. Revert all 12 function files. Single-commit revert.
- **CI coverage (Phase 7.4):** Remove threshold step from `ci.yml`.
- **Guard tightening (Phase 7.3):** Re-add the exclusion line.
- **Migration checklist (Phase 7.5):** Delete the file.
- **pgTAP tests (Phase 6):** Delete `supabase/tests/`. No production impact.

### Forward-Fix Preferred

- **DashboardVM decomposition (Phase 2):** Fix delegate wiring, don't revert to monolith.
- **submit_request_sheet decomposition (Phase 3):** Fix scoped provider wiring.
- **requests_list_screen decomposition (Phase 4):** Fix filter VM integration.

### Additive-Only (Safe)

- **A6 refactoring (Phase 7.1–7.2):** Optional constructor parameters with defaults. Existing callers unaffected.
- **New test files:** Adding tests never breaks production.

### Rollback Decision Tree

1. Do existing 706 tests pass? → If NO, identify responsible phase, revert that phase only.
2. Does `flutter analyze` report issues? → If YES, fix in responsible phase.
3. Does app build? → If NO, check import errors from decomposition.
4. Multiple phases broken? → Revert in reverse: 7 → 6 → 5 → 4 → 3 → 2 → 1.

---

## References

### Docs Scanned

- `.TODO/AUDIT_Quality_Architecture_2026-04-01.md` — primary input
- `Sline_everything/DEVELOPER_GUIDE.md` — architecture patterns
- `Sline_everything/STRUCTURE.md` — file organization
- `Sline_everything/ARCHITECTURE_ANALYSIS.md` — design decisions
- `.TODO/MASTER_REPORT_2026-04-02_PhaseC.md` — Phase C results
- `docs/LOG/SYSTEM_EVOLUTION_REPORT_2026-04-02_v2.md` — improvement rules
- `.TODO/CodeFixes.md` — intentional non-fixes

### Code Paths Scanned

- `lib/core/services/crash_reporting_service.dart` — 86 lines, NoOp stub
- `lib/main.dart` — error boundaries (lines 80–160), provider registration (lines 160–240)
- `lib/features/dashboard/viewmodels/dashboard_view_model.dart` — 1149 lines, 1 Supabase.instance in DI default
- `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart` — 916 lines, top-level function, 3 callers
- `lib/features/tasks/view/widgets/requests/requests_list_screen.dart` — 1172 lines, inline ExpiredBidFilter enum
- `lib/features/tasks/viewmodels/task_requests_view_model.dart` — 845 lines, complex existing API
- `lib/features/notifications/viewmodels/notification_view_model.dart` — 192 lines, A6 at lines 55–56, 147
- `lib/features/saved/viewmodels/saved_tasks_view_model.dart` — 152 lines, A6 at lines 108, 112
- `lib/features/chat/viewmodels/chat_view_model.dart` — DI defaults only (lines 39, 42, 45), no A6 in method bodies
- `.github/workflows/ci.yml` — 145 lines, Check 3 exclusion at line 56
- `test/unit/dashboard/dashboard_view_model_test.dart` — 20 tests, fully mocked via DI
- `test/widget/dashboard/` — 2 widget test files reference DashboardViewModel
- `test/helpers/mock_services.dart` — 8 mocks
- `supabase/functions/_shared/bookin_payment.ts` — CORS `*` at line 26
- `supabase/functions/` — 12 functions import corsHeaders
- `coverage/lcov.info` — 20059 DA lines, 6133 hit = 30.6%

---

# I) Change Report (Diff-Style)

## 1. Original Issues Summary

The v1 plan was structurally sound (10 phases, gate checks, agent ownership) but had 7 critical gaps that would cause execution failures.

## 2. Added Steps


| #   | Added Step                                                | Phase    | Why                                                                      |
| --- | --------------------------------------------------------- | -------- | ------------------------------------------------------------------------ |
| 1   | Measure coverage BEFORE setting threshold                 | 7.4      | v1 assumed 70%; reality is 30.6%. Setting 70% blocks all merges.         |
| 2   | Scoped ChangeNotifierProvider pattern for SubmitRequestVM | 3.4      | v1 said "ChangeNotifierProvider" but sheet is a function, not widget.    |
| 3   | `isDisposed` callback on all delegates                    | 2.2–2.4  | v1 didn't address async delegate methods outliving parent VM.            |
| 4   | `getCorsHeaders(req)` backward-compatible migration       | 5.1      | v1 implied replacing static export — breaks 12 functions simultaneously. |
| 5   | Per-sub-phase test gate in DashboardVM decomposition      | 2.2–2.5  | v1 only tested at 2.6. Phase C post-mortem found file corruption risk.   |
| 6   | Architecture guard Check 3 tightening (D11)               | 7.3      | v1 didn't address guard exclusion allowing A6 regressions.               |
| 7   | Add MockTaskRequestsService                               | 2.1      | v1 didn't identify missing mock for inbox delegate tests.                |
| 8   | Enumerate all 12 Edge Functions in CORS migration         | 5.2      | v1 said "verify all" but didn't list them.                               |
| 9   | Phase 8.6 explicit acceptance criteria checklist          | 8.6      | v1 had QA but didn't verify each criterion individually.                 |
| 10  | CORS verification test cases (5 specific scenarios)       | 5.4      | v1 said "verify" but no specific test cases.                             |
| 11  | DN-1, DN-2, DN-3 blocking decisions documented            | Preamble | v1 assumed answers to 3 questions that needed explicit decisions.        |


## 3. Removed Steps

None removed. All v1 steps preserved.

## 4. Reordered Steps


| From                                 | To                               | Why                                                          |
| ------------------------------------ | -------------------------------- | ------------------------------------------------------------ |
| Phase 7.3 was "Optional Enhancement" | Phase 7.3 is now mandatory (D11) | Guard exclusion is a security regression risk, not optional. |


## 5. Expanded Steps


| Step          | v1 Size            | v2 Size                             | What Changed                                                                  |
| ------------- | ------------------ | ----------------------------------- | ----------------------------------------------------------------------------- |
| Phase 0.2     | 6 bullets          | 8 bullets + coverage measurement    | Added explicit coverage baseline recording                                    |
| Phase 2.2–2.4 | 5 bullets each     | 10+ bullets each                    | Added dispose safety, per-sub-phase test gates, explicit constructor patterns |
| Phase 3.4     | 4 bullets          | 6 bullets + scoped provider pattern | Complete rewrite with correct provider strategy                               |
| Phase 5.1–5.2 | 5 bullets combined | 12+ bullets across 3 sub-phases     | Split into backward-compatible add, 12-function migration, old export removal |
| Phase 7.4     | 5 bullets          | 10 bullets with shell script        | Replaced "70% threshold" with measured-value-minus-2% strategy                |


## 6. Why

The v1 plan would have failed at:

1. **CI coverage enforcement** — immediate merge block at 70% vs 30.6% reality.
2. **SubmitRequestVM wiring** — executor would be stuck trying to wrap a function in Provider.
3. **CORS migration** — 12 simultaneous function breaks from changing a static export.
4. **Delegate dispose** — Flutter assertion errors on rapid navigation/role-switch.
5. **Architecture guard regression** — A6 pattern re-introduced without detection.

## 7. Residual Risks

1. **pgTAP availability** — may not be enabled on Supabase project. Fallback (SQL assertions) is defined but less robust.
2. **Sentry SDK compatibility** — untested with this specific Flutter version until `flutter pub get` runs.
3. **DashboardVM decomposition** — still the highest-risk item despite added gates. 20+ tests dependent on exact API.
4. **Coverage floor at 28%** — very low. Only prevents regression, doesn't drive improvement. Phase E must raise incrementally.
5. **ChatVM `removeAllChannels` via repo** — pre-existing A6-adjacent issue, explicitly out-of-scope. Documented for Phase E.

END.