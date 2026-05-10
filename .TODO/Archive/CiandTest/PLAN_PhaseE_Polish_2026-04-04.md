# Plan: Phase E — Polish, Test Coverage Expansion, & Code Quality Hardening (v2 — @PlanCritic Rewrite)

> **v2 changelog:** @PlanCritic audit found 7 critical gaps, 2 data mismatches, and 4 ordering risks in v1. See [Change Report (Section I)](#i-change-report) at the end for full diff.

---

## @PlanCritic Audit Report

### A) Assumptions + Decision Needed (Blocking)

**Assumptions (inferred, safe defaults):**
- A1: `very_good_analysis ^7.0.0` is compatible with Dart ^3.8.1 and Flutter ^3.8.1 (verified: yes).
- A2: Existing 774 tests do NOT depend on localization delegates in widget test `MaterialApp` wrappers (verified: no localization configured in tests).
- A3: `booking_view_model.dart` at 820 lines is decomposable (verified: ~280 lines extractable via payment coordinator + pagination handler).
- A4: DeepLinkService is already registered in `main.dart:275` as `Provider(create: (_) => DeepLinkService())` — no fresh wiring needed.
- A5: `WorkItemDetailsViewModel` exists at `lib/features/work/viewmodels/work_item_details_view_model.dart` (verified: confirmed).
- A6: Test infrastructure (`test/helpers/mock_services.dart` with 9 mocks, `mock_supabase.dart`, etc.) is sufficient for Phase 8 expansion.

**Decision Needed (Blocking):**

**DN-1: ViewModel count — plan says 32, actual is 27.**
- Options:
  1. Accept 27 as the real count — adjust all "32/32" targets to "27/27" and recount tested/untested.
  2. Include `SystemConfigViewModel` (in `lib/core/`) + dashboard delegates + monitors → inflated count.
- **Recommended:** Option 1. Only count files matching `*_view_model.dart` under `lib/features/` plus `lib/core/providers/`. The 5-VM discrepancy likely comes from counting delegates (DashboardWorkDelegate, DashboardInboxDelegate, DashboardBookingDelegate) and monitors (AwardExpirationMonitor) as VMs. They are NOT ViewModels — they are delegates/helpers.
- **Impact on plan:** Phase 8 test target drops from 15 → 10 untested VMs. Phase 9 coverage targets are slightly easier to reach.

**DN-2: Should architecture guard be expanded to catch `core/ → features/` imports?**
- Options:
  1. Add Check 7 to CI: `grep -rn "import.*features/" lib/core/` (catches DeepLinkService violation and future regressions).
  2. Defer until Phase 10 completes (DeepLinkService refactor will fix the current violation).
- **Recommended:** Option 1 — add the guard in Phase 1 (alongside APK fix), but mark it warning-only until Phase 10 completes the DeepLinkService refactor, then graduate to hard failure.
- **Impact on plan:** New sub-phase in Phase 1. Guard catches future violations immediately.

**DN-3: Should sealed `ViewState<T>` migration also update existing tested VMs (WalletVM, ChatVM, DashboardVM)?**
- Options:
  1. Migrate only 3 untested/lightly-tested VMs (DirectOfferDetails, BookingVM, WorkItemDetails) — lower risk.
  2. Also migrate tested VMs — higher churn, breaks existing test assertions.
- **Recommended:** Option 1. Seal only 3 VMs in Phase E. If ergonomic (Phase 5.5 decision gate), plan remaining VMs for Phase F. Migrating tested VMs risks breaking 150+ existing tests.
- **Impact on plan:** No change (v1 already planned Option 1, but this makes it explicit).

---

### B) Gate Status

| Gate | Status | Reason | Fix |
|------|--------|--------|-----|
| **Gate 0: Test Infrastructure** | ✅ PASS | `mock_services.dart` has 9 mocks, extensible pattern. `mock_supabase.dart` provides client stubs. `supabase_test_helper.dart` handles init. Phase 4 DI normalization planned before tests. | — |
| **Gate 1: Data / Contracts** | ✅ PASS | No schema changes. Sealed `ViewState<T>` is a new internal contract but does not affect DB/RPC shapes. | — |
| **Gate 2: Security / RLS** | ✅ PASS | No RLS changes. No new privileged actions. DeepLinkService refactor is navigation-only. | — |
| **Gate 3: Backend / Supabase** | ✅ PASS | No backend changes in Phase E scope. | — |
| **Gate 4: UI / Integration** | ❌ FAIL | (1) View decomposition phases lack `audit` skill step. (2) `work_item_details_screen` plan says "if VM exists" — now confirmed it exists, plan must be deterministic. (3) Localization wiring may break widget tests that use bare `MaterialApp`. | Add `Skill: audit` to every view decomposition sub-phase. Remove "if VM exists" conditional. Add localization test helper step. |
| **Gate 5: Release / QA** | ❌ FAIL | (1) No step to verify architecture guard Check 7 (core→features). (2) VM count is wrong (32 vs 27). (3) Phase 3 `dart fix --apply` is redundant if Phase 2 already ran it — no explicit skip-if-done gate. (4) No mock expansion step before Phase 8 test writing. | Fix VM count. Add mock expansion sub-phase. Add skip condition for Phase 3. Add CI guard expansion. |

---

### C) Critical Gaps (Must-Fix)

**Gap 1: ViewModel count is wrong (32 → 27)**
- **Why it will break:** Phase 8 test targets are inflated. Executor will waste time looking for 5 non-existent VMs. AC-6 says "32/32" but correct target is 27/27.
- **Fix:** Recount. Actual untested VMs: ~10 (not 15). Update all references.
- **Owner:** @Sentinel
- **Acceptance check:** `find lib/features -name "*_view_model.dart" | wc -l` matches plan count.

**Gap 2: No CI guard for core→features imports**
- **Why it will break:** DeepLinkService currently violates core→features boundary. After Phase 10 refactor, nothing prevents NEW violations from slipping in.
- **Fix:** Add Check 7 to CI architecture guard: `grep -rn "import.*features/" lib/core/`. Warning-only until Phase 10 completes.
- **Owner:** @Architect
- **Acceptance check:** CI job includes the check. DeepLinkService appears as expected warning. After Phase 10: warning count drops to 0, guard graduates to hard failure.

**Gap 3: Phase 5.4 "if VM exists" is ambiguous**
- **Why it will break:** Executor doesn't know which branch to take. WorkItemDetailsViewModel IS confirmed to exist.
- **Fix:** Remove conditional. Plan deterministically: "Migrate WorkItemDetailsViewModel to sealed state."
- **Owner:** @Architect
- **Acceptance check:** Step has no "if" language.

**Gap 4: No mock expansion step before Phase 8**
- **Why it will break:** Phase 8 tests need mocks for services not yet in `mock_services.dart` (SearchService, SavedTasksService, CategoriesRepository, PortfolioRepository, ProfileRepository, SafetyService/ReportService/DisputeService, ServicesRepository, AuthRepository/AccountGuardService [partially exists]). Writing tests without pre-creating mocks = each test file reinvents mocks = duplication + inconsistency.
- **Fix:** Add Phase 8.0 sub-phase: "Expand shared mock infrastructure" — create all missing mock classes in `mock_services.dart` before any test writing begins.
- **Owner:** @Sentinel
- **Acceptance check:** `mock_services.dart` contains mock classes for all services/repositories used by untested VMs.

**Gap 5: View decomposition phases lack `Skill: audit` final step**
- **Why it will break:** Planner §4.1 UI Phase Rules mandate a final `audit` step in every UI phase. Phases 7.1–7.4 have `arrange` and `harden` but no `audit`.
- **Fix:** Add `(@Pixel | Skill: audit)` as the final step in each view decomposition sub-phase.
- **Owner:** @Pixel
- **Acceptance check:** Every Phase 7 sub-phase ends with an audit step.

**Gap 6: Localization may break existing widget tests**
- **Why it will break:** Phase 11 wires `localizationsDelegates` into `MaterialApp`. Any widget test that constructs `MaterialApp()` without delegates will render `AppLocalizations.of(context)` as null if the proof-of-concept strings are in shared widgets. Tests that use `pumpWidget(MaterialApp(home: SomeScreen()))` without delegates will crash.
- **Fix:** Add Phase 11.3: "Create test localization helper" — a `testApp()` wrapper that includes delegates. Update any affected test files.
- **Owner:** @Sentinel
- **Acceptance check:** All tests pass after localization wiring. Test helper exists.

**Gap 7: Phase 3 is potentially redundant**
- **Why it will break:** Phase 2.2 already runs `dart fix --apply`. Phase 3 repeats the same command. Executor may waste time or get confused.
- **Fix:** Merge Phase 3 into Phase 2.2 as a sub-step. Add explicit skip condition: "If Phase 2 already achieved 0 remaining dart fixes, mark Phase 3 as SKIPPED."
- **Owner:** @Architect
- **Acceptance check:** No redundant phase exists.

---

### D) Invariants & Success Criteria (Non-Negotiable)

| # | Invariant | How to Enforce | How to Verify |
|---|-----------|---------------|---------------|
| I-1 | No View calls Supabase directly | CI architecture guard Check 1 | `grep -rn "Supabase\.instance" lib/features/*/view/` returns 0 |
| I-2 | No ViewModel calls Supabase directly (outside DI defaults) | CI architecture guard Check 3 | CI job passes |
| I-3 | No core/ service imports feature/ screens | CI architecture guard Check 7 (NEW) | `grep -rn "import.*features/.*screen" lib/core/` returns 0 (after Phase 10) |
| I-4 | All VMs have injectable constructors | Phase 4 DI normalization | Each VM constructor accepts optional service parameters |
| I-5 | Sealed ViewState does not break existing tests | Run full suite after each VM migration | `flutter test` passes after each Phase 5 sub-phase |
| I-6 | God file decomposition does not change behavior | Tests pass before and after extraction | `flutter test` passes after each Phase 6/7 sub-phase |
| I-7 | DeepLinkService handles all 10 entity types after refactor | Unit tests for each route | 10 route handler tests pass |
| I-8 | Localization does not crash views without delegates | Test helper wraps MaterialApp with delegates | Widget tests use `testApp()` wrapper |
| I-9 | Coverage floor is evidence-based, not aspirational | Measure after tests, set floor at measured-2% | `flutter test --coverage` percentage > CI threshold |
| I-10 | AppLogger used, never print() | Lint rule `avoid_print` | `flutter analyze` returns 0 |

---

### E) Risk Register

| Risk | Where | Probability | Impact | Blast Radius | Early Signal | Prevention | Fallback |
|------|-------|------------|--------|--------------|-------------|-----------|----------|
| `very_good_analysis` produces >500 issues | Phase 2 | Medium | High | All code | `flutter analyze` count | Decision gate at 300/500 | Revert to flutter_lints + manual rules |
| Sealed ViewState is too verbose for Flutter views | Phase 5 | Medium | Medium | 3 VMs + views | Code review of first migration | Start with simplest VM | Stop at 1 VM, defer pattern |
| booking_view_model extraction breaks payment flow | Phase 6.4 | Low | High | Payment-critical path | Existing BookingVM tests fail | Run tests after each extraction | Revert extraction, keep at 820 |
| DeepLinkService refactor breaks push notification routing | Phase 10 | Medium | High | All deep links | Manual test of each entity type | Preserve all 10 entity types in registry | Revert to switch/case pattern |
| Localization delegates break widget tests | Phase 11 | Medium | Medium | All widget tests | First `flutter test` after wiring | Create test helper before wiring | Remove delegates from shared screens |
| Coverage floor set too high, blocks future PRs | Phase 9 | Low | Medium | CI pipeline | PRs start failing | Set floor at measured-2% | Lower floor immediately |
| God file targets are infeasible (§1.2) | Phase 6/7 | Medium | Low | Per-file | Extraction map shows <100 lines extractable | Feasibility analysis before extraction | Document exception, keep current size |
| Mock expansion in Phase 8.0 misses a service | Phase 8 | Low | Low | One test file | Test file can't construct VM | Add mock on-demand | — |

---

### F) Pre-Mortem (How This Fails In Real Life)

- **This fails when** `very_good_analysis` produces 700 new issues and the executor spends 2 days fixing lints instead of writing tests, burning Phase E time budget.
- **This fails when** sealed `ViewState<T>` requires 50+ lines of pattern-matching boilerplate per view, making the pattern rejected at the Phase 5.5 decision gate after already migrating 3 VMs.
- **This fails when** `booking_view_model.dart` extraction map reveals only 80 lines extractable (not 280), and the 820→740 result still fails AC-4's <800 target with a false sense of failure.
- **This fails when** Phase 10 DeepLinkService refactor changes navigation timing, and a race condition causes push notification deep links to navigate before the target screen's VM has loaded data.
- **This fails when** the executor writes 10 VM test files with 8 tests each (80 total), but coverage only reaches 38% because ViewModel tests don't cover service/repository/view code, and the 50% floor is unreachable without additional test types.
- **This fails when** localization `AppLocalizations.of(context)!` null-asserts in a screen that's rendered in 15 widget tests, and all 15 tests crash because the test harness doesn't include localization delegates.
- **This fails when** Phase 4 DI normalization changes a VM constructor signature, breaking a `Provider<ViewModel>` registration in `main.dart` that the executor doesn't notice until runtime.
- **This fails when** the APK Kotlin fix requires `compileSdk 35` but `sentry_flutter` or another plugin requires `compileSdk 34`, creating a version conflict with no clean resolution.
- **This fails when** `dart fix --apply` auto-adds `const` to a widget constructor that has a side-effect initializer, and the behavioral change is invisible until a user reports a bug in production.

---

### G) Plan Fixes (Concrete Additions / Expansions)

**Fix 1: Correct VM count globally (32→27)**
- Goal: Eliminate data mismatch
- Why: Wrong count cascades into wrong test targets, wrong coverage math, wrong acceptance criteria
- How: Replace "32" with "27" in all plan text. Recount untested: 27 total − 17 tested = 10 untested
- Output artifact: Updated AC-6 text
- Stop condition: `find lib/features -name "*_view_model.dart" | wc -l` matches plan count

**Fix 2: Add CI architecture guard Check 7 (core→features)**
- Goal: Prevent future core→features boundary violations
- Why: Current guard has blind spot. DeepLinkService violation would slip past CI today.
- How: Add grep check to architecture-guard job in ci.yml. Warning-only initially. Graduate after Phase 10.
- Output artifact: Updated `.github/workflows/ci.yml`
- Stop condition: Check 7 appears in CI output. Known DeepLinkService warnings are expected.

**Fix 3: Remove Phase 5.4 "if VM exists" conditional**
- Goal: Make plan deterministic
- Why: VM exists (confirmed). Conditional creates executor confusion.
- How: Replace with direct migration steps for WorkItemDetailsViewModel.
- Output artifact: Updated Phase 5.4 text
- Stop condition: No "if" language in Phase 5.4.

**Fix 4: Add Phase 8.0 — Mock Infrastructure Expansion**
- Goal: Prepare shared mocks before test writing
- Why: 10 untested VMs need mocks for ~12 services/repositories not yet in mock_services.dart
- How: Read each untested VM's constructor. Add mock class to mock_services.dart for every injected dependency.
- Output artifact: Expanded `test/helpers/mock_services.dart`
- Stop condition: Every service/repository dependency of every untested VM has a mock in the shared file.

**Fix 5: Add `Skill: audit` to all Phase 7 sub-phases**
- Goal: Comply with Planner §4.1 UI Phase Rules
- Why: Mandatory rule. Plan is incomplete without it.
- How: Add `(@Pixel | Skill: audit)` as final checklist item in 7.1–7.4.
- Output artifact: Updated Phase 7 steps
- Stop condition: Every Phase 7 sub-phase ends with an audit step.

**Fix 6: Add Phase 11.3 — Test Localization Helper**
- Goal: Prevent localization from breaking widget tests
- Why: `AppLocalizations.of(context)!` will null-crash in tests without delegates
- How: Create `testApp()` wrapper in test helpers. Update affected test files.
- Output artifact: New test helper function. Updated test files.
- Stop condition: All tests pass after localization wiring.

**Fix 7: Merge Phase 3 into Phase 2**
- Goal: Eliminate redundant phase
- Why: Phase 2.2 already runs `dart fix --apply`. Phase 3 repeats it.
- How: Make `dart fix --apply` + verification the final sub-step of Phase 2. Remove standalone Phase 3.
- Output artifact: Updated Phase 2. Renumbered subsequent phases.
- Stop condition: No redundant dart-fix phase exists.

**Fix 8: Add Phase 1 sub-phase for CI guard expansion**
- Goal: Catch core→features violations early
- Why: Without this guard, Phase 10 could finish but future violations slip in
- How: Add grep check to ci.yml in Phase 1 (alongside APK fix). Warning-only.
- Output artifact: Updated ci.yml with Check 7
- Stop condition: CI includes Check 7. Warning-only until Phase 10 graduates it.

---

## H) Corrected Plan (Execution-Ready, Gate-Based, v2)

---

# Plan: Phase E — Polish, Test Coverage Expansion, & Code Quality Hardening

## 1) Goal

- **Goal:** Elevate the SLine codebase from "hardened MVP" (Phase D baseline: 774 tests, 30.6% coverage, 0 analyze issues) to "release-candidate quality" by fixing the APK build, upgrading lint strictness, normalizing ViewModel DI, introducing sealed error states, decomposing remaining god files, expanding test coverage to all ViewModels, refactoring DeepLinkService, and laying localization groundwork.
- **Why:** Phases A–D locked the gates, exposed bugs, covered critical paths, and hardened infrastructure. Phase E addresses the remaining debt: 9 god files, 10 untested ViewModels, low coverage floor, string-based error states, loose lint rules, hard-coded deep link routing, and missing localization infrastructure. These gaps block confident release and sustainable velocity.
- **Result:** Coverage floor raised to 45%+, all god files under 800 lines (or documented feasibility exception per §1.2), `very_good_analysis` adopted (or documented deferral), sealed error states in 3 critical VMs, DeepLinkService decoupled from features, localization infrastructure ready for `.arb` content, APK build green, CI guard expanded, and all gates passing.

## 2) Scope

### In-Scope

- E1: Fix APK build (sentry_flutter Kotlin/Gradle mismatch)
- E2: Expand CI architecture guard (Check 7: core→features boundary)
- E3: Migrate to `very_good_analysis` lint package (includes `dart fix --apply`)
- E4: Normalize ViewModel DI (8 partially-injectable VMs)
- E5: Introduce sealed `ViewState<T>` state classes (3 critical VMs)
- E6: Decompose remaining 9 god files (5 logic-layer + 4 view-layer)
- E7: Expand shared mock infrastructure + write tests for 10 untested ViewModels
- E8: Raise coverage floor to 45%+
- E9: Refactor DeepLinkService to route registry pattern
- E10: Localization infrastructure setup (`l10n.yaml` + `.arb` scaffold + test helper)
- E11: Documentation sync

### Out-of-Scope

- Full Arabic/Kurdish translation content (Phase F — translator needed)
- 85% coverage target (Phase F — requires widget/integration test expansion)
- Sealed ViewState migration of already-tested VMs (Phase F — after ergonomics proven)
- Admin Orphan Queue / Payment Trace features
- HMAC in create edge & webhook signature verification
- Golden file testing setup
- Retry/exponential backoff utility

## 3) Evidence & Findings (From Scan)

### Existing

- **774 tests**, all passing, 0 analyze issues
- **28% coverage floor** enforced in CI (measured baseline: 30.6%)
- **17/27 ViewModels tested** (63%) — corrected from v1's 17/32
- **6 architecture guard checks** all pass (hard failure)
- **Sentry crash reporting** live (10 tests)
- **Phase D decompositions complete:** DashboardVM (1149→537), SubmitRequestSheet (916→737), RequestsListScreen (1172→604)
- **DI patterns established:** Most VMs use optional constructor injection with `Supabase.instance` fallback
- **Localization dependencies present** in pubspec: `intl ^0.20.2`, `flutter_localizations`
- **Pre-commit hooks** active: format + analyze
- **Test infrastructure solid:** `mock_services.dart` (9 mocks), `mock_supabase.dart`, `supabase_test_helper.dart`, `role_switch_helpers.dart`
- **WorkItemDetailsViewModel confirmed** at `lib/features/work/viewmodels/work_item_details_view_model.dart`
- **DeepLinkService already registered** in `main.dart:275` as `Provider(create: (_) => DeepLinkService())`

### Missing

- **9 god files** still >800 lines (total: ~8,177 lines of oversized files)
- **10 untested ViewModels**: DirectOfferDetailsVM, SearchVM, SavedTasksVM, CategoriesVM, PortfolioVM, PublicProfileVM, UserProfileVM, SafetyVM, MyServicesVM, WorkItemDetailsVM
- **No `l10n.yaml`**, no `.arb` files, no locale configuration
- **DeepLinkService** imports 7 feature screens + 5 feature services/models directly — core/feature boundary violation (A7)
- **No CI guard for core→features imports** — architecture guard blind spot
- **No sealed state classes** — all VMs use `String? error` + `bool _isLoading`
- **No `very_good_analysis`** — still on `flutter_lints` (34 rules vs 100+)
- **APK build broken** — Kotlin version mismatch from sentry_flutter native deps
- **`Doc/DIGRAM/` directory** does not exist
- **Shared mock file missing** mocks for: SearchService, SavedTasksService, CategoriesRepository, PortfolioRepository, ProfileRepository, ReportService, DisputeService, ServicesRepository

### Must NOT Duplicate

- Phase D delegate patterns (DashboardWorkDelegate, DashboardInboxDelegate, DashboardBookingDelegate)
- Phase C test infrastructure (mock_services.dart, test helpers)
- Phase B architecture fixes (all A1–A6 violations already fixed)
- Existing RLS test suite (8 files)
- Existing mock classes in mock_services.dart (9 mocks — extend, don't recreate)

### Conflicts / Risks

- **R1:** `very_good_analysis` may produce 200+ new lint issues — requires branch-first assessment before merge
- **R2:** Sealed state classes in VMs will change ViewModel API surface — views consuming `vm.error` and `vm.isLoading` must be updated
- **R3:** DeepLinkService refactor touches navigation — must not break push notification deep links or activity log deep links
- **R4:** APK Kotlin fix may require updating `settings.gradle.kts` and `build.gradle.kts` — affects Android build chain
- **R5:** God file decomposition in view layer requires careful widget extraction to avoid breaking layout/state
- **R6:** SavedTasksVM has constructor auto-loading (`_initAuthListener`) — tests need mock pre-configuration before construction
- **R7:** 8 of 10 untested VMs are "partially injectable" — constructor refactoring required before test writing
- **R8:** Localization delegates in `MaterialApp` will break widget tests that use bare `MaterialApp()` wrappers
- **R9:** `booking_view_model.dart` at 820 lines is borderline — extraction map may reveal only ~280 lines extractable (feasible but tight)

## 4) System Impact Map

- **UI:** Sealed state classes change how views consume VM state; widget extractions from god files; localization wrapping with `AppLocalizations`
- **MVVM / App Logic:** Sealed `ViewState` classes replace `String? error` + `bool isLoading` in 3 VMs; ViewModel constructor DI normalization; delegate extraction from god VMs/services
- **Database:** No schema changes
- **RLS / Security:** No policy changes
- **RPC / Edge Functions:** No changes
- **Storage:** No changes
- **Realtime / Notifications:** DeepLinkService refactor must preserve notification deep link routing
- **Observability:** No changes (Sentry already integrated)
- **Compatibility & Migration:** `very_good_analysis` changes lint rules; sealed states change VM API for 3 VMs; Kotlin/Gradle version bump
- **Contracts:** Sealed `ViewState<T>` replaces `isLoading + error + data` contract pattern in 3 VMs
- **CI/CD:** Architecture guard expanded with Check 7; coverage floor raised; APK build restored

## 5) Agent Map

- **Phase 0:** `@Planner`, `@Sentinel`
- **Phase 1:** `@Architect`, `@Sentinel` (APK fix + CI guard expansion)
- **Phase 2:** `@Architect`, `@Sentinel` (lint migration + auto-fixes)
- **Phase 3:** `@Architect`, `@Sentinel` (VM DI normalization)
- **Phase 4:** `@Architect`, `@Sentinel` (sealed state classes)
- **Phase 5:** `@Architect`, `@Sentinel` (god file decomposition — logic layer)
- **Phase 6:** `@Pixel`, `@Architect`, `@Sentinel` (god file decomposition — views)
- **Phase 7:** `@Sentinel`, `@Architect` (mock expansion + VM test expansion)
- **Phase 8:** `@Sentinel`, `@Architect` (coverage push)
- **Phase 9:** `@Architect`, `@Sentinel` (DeepLinkService refactor)
- **Phase 10:** `@Architect`, `@Pixel`, `@Sentinel` (localization infrastructure)
- **Phase 11:** `@Sentinel`, `@CodeGuard` (final QA)
- **Phase 12:** `@DocsKeeper` (documentation sync)

---

## Phase 0: Preconditions & Gates

**Primary Agent(s):** `@Planner`, `@Sentinel`
**Goal:** Lock acceptance criteria and confirm baseline state before execution begins.
**Why:** Phase E is large (12 execution phases); clear boundaries prevent scope creep and ensure measurable progress.
**How:** Define pass/fail criteria, verify baseline numbers, confirm session log.
**Result:** Acceptance criteria locked, baseline snapshot verified, session log ready.

### 0.1 Spec Lock

**Primary Agent(s):** `@Sentinel`, `@Architect`
**Goal:** Define measurable acceptance criteria for every Phase E deliverable.
**Why:** Without measurable criteria, "done" is subjective and disputes arise at Phase 11 QA.
**How:** List each criterion with its verification command.
**Result:** AC table with exact commands.

- [ ] (`@Sentinel`) Verify baseline state by running:
  - `flutter test` — confirm 774 tests pass.
  - `flutter analyze` — confirm 0 issues.
  - `flutter build web --release` — confirm web build succeeds.
  - `flutter build apk --debug` — confirm APK build FAILS (expected, Phase D known issue).
  - Architecture guard in CI — confirm 6 checks pass.
  - Coverage floor — confirm 28% threshold in ci.yml.
- [ ] (`@Sentinel`) Lock acceptance criteria (ALL must pass for Phase E completion):
  - **AC-1:** `flutter build apk --debug` exits 0.
  - **AC-2:** `analysis_options.yaml` includes `very_good_analysis` (or documented deferral decision with rationale in session log).
  - **AC-3:** `dart fix --dry-run` reports 0 remaining auto-fixable issues.
  - **AC-4:** All 9 god files under 800 lines (or documented feasibility exception per §1.2 with extraction map evidence).
  - **AC-5:** 3+ ViewModels use sealed `ViewState<T>` pattern.
  - **AC-6:** 27/27 ViewModels have corresponding test files with at least 5 tests each.
  - **AC-7:** CI coverage floor raised to 45%+ (or measured-2%, whichever is higher).
  - **AC-8:** `grep -c "import.*features.*screen" lib/core/services/deep_link_service.dart` returns 0.
  - **AC-9:** `l10n.yaml` exists, `flutter gen-l10n` succeeds, 1+ `.arb` file with 10+ key stubs.
  - **AC-10:** All `Sline_everything/` docs updated to reflect Phase E changes.
  - **AC-11:** 0 analyze issues, all tests pass, all CI gates green (including Check 7 warning-only or hard-fail).
- [ ] (`@Architect`) Confirm the touched modules and file list:
  - 9 god files (5 logic + 4 view)
  - 10 untested VMs (DI normalization + tests)
  - `lib/core/services/deep_link_service.dart` (refactor)
  - `lib/l10n/` (new directory)
  - `lib/core/models/view_state.dart` + `app_failure.dart` (new files)
  - `analysis_options.yaml` + `pubspec.yaml` (lint migration)
  - `android/settings.gradle.kts` + `android/app/build.gradle.kts` (APK fix)
  - `.github/workflows/ci.yml` (guard expansion + coverage floor)
  - `test/helpers/mock_services.dart` (mock expansion)
- [ ] (`@DocsKeeper`) Confirm authoritative docs: `AUDIT_Quality_Architecture_2026-04-01.md`, `DEVELOPER_GUIDE.md`, `STRUCTURE.md`, `ARCHITECTURE_ANALYSIS.md`.
- **GATE CHECK:** All acceptance criteria are measurable with exact commands. Baseline snapshot matches expected values. Touched file list is explicit.

### 0.2 Session Log Confirmation

**Primary Agent(s):** `@Sentinel`
**Goal:** Confirm session log is initialized and path is correct.
**Why:** Session log tracks execution events. Must exist before Phase 1.
**How:** Verify file exists and header is correct.
**Result:** Session log ready for executor.

- **Session Log Path:** `docs/LOG/SESSION_PLAN_PhaseE_Polish_2026-04-04.md`
- [ ] (`@Sentinel`) Confirm session log file exists and header is populated with plan reference.
- [ ] (`@Sentinel`) Confirm `[PLAN CREATED]` section includes scope, phase count, and risk areas.
- **GATE CHECK:** Session log is initialized and ready.

---

## Phase 1: Fix APK Build + CI Guard Expansion (Blockers)

**Primary Agent(s):** `@Architect`, `@Sentinel`
**Goal:** Restore green APK build and expand CI architecture guard to catch core→features boundary violations.
**Why:** Broken APK build blocks release and reduces CI confidence (Phase D deferred this). Missing CI guard allows future core→features violations to slip in undetected.
**How:** Update Kotlin/Gradle versions for APK. Add Check 7 to architecture guard (warning-only).
**Result:** APK and web builds both succeed. CI has 7 architecture checks.

### 1.1 Diagnose APK Build Failure

**Primary Agent(s):** `@Architect`
**Goal:** Identify exact Kotlin/Gradle version requirements.
**Why:** Can't fix what you don't understand. Multiple version variables interact (Kotlin, Gradle plugin, compileSdk, AGP).
**How:** Run build, read error, check plugin requirements.
**Result:** Root cause identified with exact target versions.

- [ ] (`@Architect`) Run `flutter build apk --debug 2>&1 | tail -50` and capture the exact error message.
- [ ] (`@Architect`) Read `android/settings.gradle.kts` — note current Kotlin version and Gradle plugin version.
- [ ] (`@Architect`) Read `android/app/build.gradle.kts` — note current `compileSdk`, `minSdk`, `targetSdk`.
- [ ] (`@Architect`) Check sentry_flutter's pub.dev page or CHANGELOG for minimum Kotlin version, minimum Gradle version, and minimum compileSdk.
- [ ] (`@Architect`) Check if any other plugins (e.g., `image_picker`, `webview_flutter`) have conflicting version requirements.
- [ ] (`@Sentinel`) Document root cause and target versions in session log.
- **GATE CHECK:** Root cause is identified. Target Kotlin version, Gradle plugin version, and compileSdk are documented. No conflicting plugin requirements.

### 1.2 Apply APK Build Fix

**Primary Agent(s):** `@Architect`, `@Sentinel`
**Goal:** Update Android build config to satisfy all plugin requirements.
**Why:** Broken build is a release blocker.
**How:** Update version numbers in Gradle config files.
**Result:** Both platform builds succeed.

- [ ] (`@Architect`) Update Kotlin version in `android/settings.gradle.kts` to target version.
- [ ] (`@Architect`) Update Gradle plugin version in `android/settings.gradle.kts` if required.
- [ ] (`@Architect`) Update `compileSdk` in `android/app/build.gradle.kts` if required.
- [ ] (`@Architect`) Update `targetSdk` in `android/app/build.gradle.kts` if required (must match or follow compileSdk).
- [ ] (`@Architect`) Run `flutter clean && flutter pub get`.
- [ ] (`@Architect`) Run `flutter build apk --debug` — must succeed.
- [ ] (`@Architect`) Run `flutter build web --release` — must still succeed (no regression).
- [ ] (`@Sentinel`) Run `flutter test` — all 774 tests must pass.
- [ ] (`@Sentinel`) Run `flutter analyze` — 0 issues.
- **GATE CHECK:** APK build succeeds. Web build succeeds. All tests pass. Analyze clean.

### 1.3 Expand CI Architecture Guard (Check 7: Core→Features)

**Primary Agent(s):** `@Architect`, `@Sentinel`
**Goal:** Add CI check to detect `lib/core/` importing `lib/features/` code.
**Why:** DeepLinkService currently violates this boundary (7+ feature screen imports, 5+ feature service imports). Without a guard, new violations will slip in after Phase 9 fixes the current one.
**How:** Add grep check to ci.yml architecture-guard job. Warning-only initially (DeepLinkService is a known violation). Graduate to hard failure after Phase 9.
**Result:** CI reports core→features imports. Known violations documented.

- [ ] (`@Architect`) Add Check 7 to `.github/workflows/ci.yml` architecture-guard job:
  ```bash
  echo "--- Check 7: core/ importing features/ (warning-only) ---"
  CORE_FEATURE_IMPORTS=$(grep -rn "import.*features/" lib/core/ 2>/dev/null | wc -l)
  if [ "$CORE_FEATURE_IMPORTS" -gt 0 ]; then
    echo "WARNING: $CORE_FEATURE_IMPORTS core->features imports found (known: DeepLinkService)"
    grep -rn "import.*features/" lib/core/ 2>/dev/null
    echo "Will become hard failure after DeepLinkService refactor (Phase E9)"
  fi
  ```
- [ ] (`@Architect`) Add comment in ci.yml: `# TODO: Graduate Check 7 to hard failure after Phase E9 DeepLinkService refactor`.
- [ ] (`@Sentinel`) Run architecture guard locally — confirm Check 7 reports known DeepLinkService violations as warnings.
- [ ] (`@Sentinel`) Confirm Checks 1–6 still pass (no regression).
- **GATE CHECK:** Check 7 exists in CI. Known violations are reported as warnings. Checks 1–6 unaffected.

---

## Phase 2: Lint Migration — `very_good_analysis` + Auto-Fixes

**Primary Agent(s):** `@Architect`, `@Sentinel`
**Goal:** Replace `flutter_lints` with `very_good_analysis` for stricter code quality enforcement, and apply all auto-fixable issues.
**Why:** `flutter_lints` has ~34 rules; `very_good_analysis` enables 100+. Stricter linting catches bugs earlier. Audit recommended branch-first strategy. `dart fix --apply` is the first remediation step after lint migration and should not be a separate phase.
**How:** Swap lint package, measure issue count, decide via decision gate, fix issues, run `dart fix --apply`.
**Result:** `very_good_analysis` active (or documented deferral) with 0 issues and 0 remaining auto-fixes.

### 2.1 Lint Package Swap + Issue Assessment

**Primary Agent(s):** `@Architect`, `@Sentinel`
**Goal:** Measure the impact of `very_good_analysis` before committing to migration.
**Why:** Unbounded lint issue count could derail Phase E timeline. Decision gate prevents this.
**How:** Swap package, run analyze, count issues.
**Result:** Issue count recorded. Decision gate evaluated.

- [ ] (`@Architect`) Update `pubspec.yaml`: replace `flutter_lints: ^5.0.0` with `very_good_analysis: ^7.0.0` in `dev_dependencies`.
- [ ] (`@Architect`) Update `analysis_options.yaml`: change `include: package:flutter_lints/flutter.yaml` to `include: package:very_good_analysis/analysis_options.yaml`.
- [ ] (`@Architect`) Review existing custom rules in `analysis_options.yaml`. Remove any that are already included in `very_good_analysis`. Keep any custom rules not covered.
- [ ] (`@Architect`) Run `flutter pub get` to resolve dependencies.
- [ ] (`@Architect`) Run `flutter analyze 2>&1 | tail -5` and record the total issue count.
- [ ] (`@Sentinel`) **Decision gate evaluation:**
  - **< 300 new issues:** PROCEED. Fix incrementally in Phase 2.2.
  - **300–500 new issues:** PROCEED WITH IGNORES. Add `// ignore_for_file:` for the noisiest 2–3 rules on legacy files. Create `.TODO/LINT_DEBT_PhaseE.md` tracking artifact listing every ignored rule + file.
  - **> 500 new issues:** REVERT. Restore `flutter_lints`. Add 5–10 individual rules from `very_good_analysis` to custom rules. Document deferral decision in session log. Mark AC-2 as DEFERRED.
- [ ] (`@Sentinel`) Document decision and issue count in session log.
- **GATE CHECK:** Issue count is recorded. Decision is made and documented. If REVERT: `flutter_lints` is restored and analyze passes 0.

### 2.2 Fix Lint Issues + Apply Auto-Fixes (If Proceeding)

**Primary Agent(s):** `@Architect`, `@Sentinel`
**Goal:** Reach 0 analyze issues under the new lint package.
**Why:** Lint issues left unresolved block CI and obscure real problems.
**How:** Run `dart fix --apply` first (auto-fixes), then manually fix remaining issues by priority.
**Result:** `flutter analyze` reports 0 issues. `dart fix --dry-run` reports 0 remaining.

- [ ] (`@Architect`) Run `dart fix --dry-run` to preview auto-fixable issues.
- [ ] (`@Architect`) Run `dart fix --apply` to apply all auto-fixes.
- [ ] (`@Architect`) Run `flutter analyze` — record remaining issue count after auto-fixes.
- [ ] (`@Architect`) Manually fix remaining issues, prioritizing:
  1. **Safety-category rules** first (potential bugs: missing returns, unchecked casts, unused results).
  2. **Style-category rules** second (consistency: naming, ordering).
  3. **Preference-category rules** last (cosmetic: const, final, single quotes).
- [ ] (`@Architect`) For rules that produce excessive false positives in test files, add targeted `// ignore_for_file:` in specific test files only — document each exception in session log.
- [ ] (`@Architect`) Run `dart fix --dry-run` — confirm 0 remaining auto-fixable issues.
- [ ] (`@Sentinel`) Run `flutter analyze` — must report 0 issues.
- [ ] (`@Sentinel`) Run `flutter test` — all tests must pass (lint fixes must not change behavior).
- [ ] (`@Sentinel`) Review diff — confirm no behavioral changes (only syntactic improvements). Spot-check any `const` additions to widget constructors.
- **GATE CHECK:** `very_good_analysis` active. 0 analyze issues. 0 remaining dart fixes. All tests pass. No behavioral changes.

---

## Phase 3: ViewModel DI Normalization (Infrastructure for Testing)

**Primary Agent(s):** `@Architect`, `@Sentinel`
**Goal:** Ensure all 10 untested ViewModels have fully injectable constructors so tests can be written without `Supabase.instance` initialization.
**Why:** 8 of 10 untested VMs are "partially injectable" with hard-coded `Supabase.instance` fallbacks. Tests will crash with `MissingPluginException` without DI refactoring. Phase C taught us this must happen BEFORE test writing (WalletVM + ChatVM required emergency refactoring).
**How:** Add optional constructor parameters for all dependencies. Use lazy getters for Supabase fallbacks. Keep backward-compatible defaults.
**Result:** All 27 ViewModels have "fully injectable" constructors. No production behavior changes. No provider registration changes in main.dart.

### 3.1 Refactor VMs with Supabase.instance Fallbacks (4 VMs)

**Primary Agent(s):** `@Architect`, `@Sentinel`
**Goal:** Remove hard-coded `Supabase.instance` from VM constructors and bodies.
**Why:** These 4 VMs directly reference `Supabase.instance`, which crashes in test environments.
**How:** Change to lazy getter pattern: `late final _client = client ?? Supabase.instance.client`.
**Result:** 4 VMs can be constructed in tests without Supabase initialization.

- [ ] (`@Architect`) **SavedTasksViewModel** (`lib/features/saved/viewmodels/saved_tasks_view_model.dart`):
  - Change `Supabase.instance.client` fallback to lazy getter.
  - Document constructor auto-loading: `_initAuthListener()` runs in constructor, calls `load()` on login.
  - Ensure mock stubs for auth stream + load must be configured BEFORE construction.
- [ ] (`@Architect`) **CategoriesViewModel** (`lib/features/categories/viewmodels/categories_view_model.dart`):
  - Change `CategoriesRepository(Supabase.instance.client)` fallback to injectable `CategoriesRepository?` parameter with lazy default.
- [ ] (`@Architect`) **PortfolioViewModel** (`lib/features/portfolio/viewmodels/portfolio_view_model.dart`):
  - Change `Supabase.instance` fallback to injectable `PortfolioRepository?` parameter with lazy default.
- [ ] (`@Architect`) **PublicProfileViewModel** (`lib/features/profile/viewmodels/public_profile_view_model.dart`):
  - Change `Supabase.instance` fallback to injectable `ProfileRepository?` parameter with lazy default.
- [ ] (`@Sentinel`) After EACH VM refactor: run `flutter analyze` — 0 issues.
- [ ] (`@Sentinel`) After ALL 4: run `flutter test` — all 774 tests pass (backward compatibility).
- **GATE CHECK:** 4 VMs refactored. No `Supabase.instance` in constructor bodies. All existing tests pass.

### 3.2 Refactor VMs with Hard-Coded Service Instantiation (4 VMs)

**Primary Agent(s):** `@Architect`, `@Sentinel`
**Goal:** Remove hard-coded service/repository construction from VM constructors.
**Why:** These VMs create service instances internally (e.g., `SearchService()`) making it impossible to inject mocks.
**How:** Change to optional injectable parameter with lazy default.
**Result:** 4 more VMs are fully injectable.

- [ ] (`@Architect`) **SearchViewModel** (`lib/features/search/viewmodels/search_view_model.dart`):
  - Change `SearchService? service` constructor to use lazy getter for default.
- [ ] (`@Architect`) **SafetyViewModel** (`lib/features/safety/viewmodels/safety_view_model.dart`):
  - Change `ReportService?` and `DisputeService?` fallbacks to lazy getters.
- [ ] (`@Architect`) **MyServicesViewModel** (`lib/features/services/viewmodels/my_services_view_model.dart`):
  - Change `ServicesRepository()` fallback to injectable parameter.
- [ ] (`@Architect`) **AuthFormViewModel** (`lib/features/auth/viewmodels/auth_form_view_model.dart`):
  - Change `_buildDefaultGuardService()` Supabase fallback to injectable `AccountGuardService?` parameter.
- [ ] (`@Sentinel`) After EACH: run `flutter analyze` — 0 issues.
- [ ] (`@Sentinel`) After ALL 4: run `flutter test` — all tests pass.
- **GATE CHECK:** 4 more VMs refactored. All 8 partially-injectable VMs are now fully injectable. All tests pass.

### 3.3 Verify Already-Injectable ViewModels (2 VMs)

**Primary Agent(s):** `@Architect`, `@Sentinel`
**Goal:** Confirm the 2 remaining untested VMs need no DI changes.
**Why:** DirectOfferDetailsVM and WorkItemDetailsVM were identified as "fully injectable" — verify this before test writing.
**How:** Read constructors, confirm all deps are required or optional injectable params.
**Result:** DI pattern documented for all 10 untested VMs.

- [ ] (`@Architect`) Confirm **DirectOfferDetailsViewModel** constructor: all dependencies via required named parameters, no fallbacks. Document: "fully injectable."
- [ ] (`@Architect`) Confirm **WorkItemDetailsViewModel** constructor: check for any hard-coded dependencies or auto-loading behavior. Document DI pattern.
- [ ] (`@Sentinel`) Create DI verification summary in session log listing all 10 untested VMs and their DI status (all should be "fully injectable" by this point).
- **GATE CHECK:** All 10 untested VMs have documented, confirmed "fully injectable" constructors.

---

## Phase 4: Sealed State Classes (3 Critical VMs)

**Primary Agent(s):** `@Architect`, `@Sentinel`
**Goal:** Replace `String? error` + `bool _isLoading` pattern with typed `ViewState<T>` sealed class in the 3 highest-risk ViewModels.
**Why:** String error states prevent views from reacting differently to auth vs network vs validation failures. Null assertions on data (`vm.workItem!`) crash when state is loading/error. Sealed states make illegal states unrepresentable.
**How:** Define shared `ViewState<T>` sealed class. Migrate 3 VMs (DirectOfferDetails, Booking, WorkItemDetails). Update consuming views. Evaluate ergonomics.
**Result:** 3 VMs use type-safe state. Views use pattern matching. Decision gate determines future rollout.

### 4.1 Define Sealed State Infrastructure

**Primary Agent(s):** `@Architect`, `@Sentinel`
**Goal:** Create the shared `ViewState<T>` and `AppFailure` types.
**Why:** Infrastructure must exist before any VM migration.
**How:** Create new files in `lib/core/models/`. Write unit tests.
**Result:** Infrastructure compiled, tested, importable.

- [ ] (`@Architect`) Create `lib/core/models/view_state.dart`:
  ```dart
  sealed class ViewState<T> {
    const ViewState();
  }
  class ViewInitial<T> extends ViewState<T> { const ViewInitial(); }
  class ViewLoading<T> extends ViewState<T> { const ViewLoading(); }
  class ViewLoaded<T> extends ViewState<T> { final T data; const ViewLoaded(this.data); }
  class ViewFailed<T> extends ViewState<T> { final AppFailure failure; const ViewFailed(this.failure); }
  ```
- [ ] (`@Architect`) Create `lib/core/models/app_failure.dart`:
  ```dart
  sealed class AppFailure {
    final String userMessage;
    final String? debugMessage;
    const AppFailure(this.userMessage, {this.debugMessage});
  }
  class NetworkFailure extends AppFailure { ... }
  class AuthFailure extends AppFailure { final bool sessionExpired; ... }
  class ValidationFailure extends AppFailure { final Map<String, String> fieldErrors; ... }
  class BusinessFailure extends AppFailure { final String code; ... }
  ```
- [ ] (`@Sentinel`) Write unit tests for `ViewState<T>`: construction, type checking via `is`, exhaustive switch, equality if applicable. Minimum 8 tests.
- [ ] (`@Sentinel`) Write unit tests for `AppFailure` subclasses: construction, field access, type hierarchy. Minimum 6 tests.
- [ ] (`@Sentinel`) Run `flutter analyze` — 0 issues.
- [ ] (`@Sentinel`) Run `flutter test` — all tests pass (including new ones).
- **GATE CHECK:** `view_state.dart` and `app_failure.dart` exist, compile, and have passing tests.

### 4.2 Migrate DirectOfferDetailsViewModel (Simplest Consumer)

**Primary Agent(s):** `@Architect`, `@Sentinel`
**Goal:** Replace `_isLoading` + `_error` + `_offer` fields with `ViewState<DirectOffer>`.
**Why:** DirectOfferDetailsVM is fully injectable and has the simplest state shape — ideal first migration to validate the pattern.
**How:** Replace fields, update getters, update consuming view to use `switch (vm.state)`.
**Result:** DirectOfferDetailsVM uses sealed state. View compiles and renders.

- [ ] (`@Architect`) Read `lib/features/direct_offers/viewmodels/direct_offer_details_view_model.dart` — identify `_isLoading`, `_error`, and data fields.
- [ ] (`@Architect`) Replace with `ViewState<DirectOffer> _state = const ViewInitial()`.
- [ ] (`@Architect`) Update all methods that set `_isLoading = true` / `_error = ...` to use `_state = ViewLoading()` / `_state = ViewFailed(...)`.
- [ ] (`@Architect`) Update getters to expose `ViewState<DirectOffer> get state => _state`.
- [ ] (`@Architect`) Read `lib/features/direct_offers/view/direct_offer_details_screen.dart`.
- [ ] (`@Architect`) Update view to use `switch (vm.state)` pattern matching with explicit cases for Initial, Loading, Loaded, Failed.
- [ ] (`@Sentinel`) Run `flutter analyze` — 0 issues.
- [ ] (`@Sentinel`) Run `flutter test` — all existing tests pass.
- [ ] (`@Sentinel`) Note: how many lines of view code changed? Is the switch pattern readable or verbose? Record in session log.
- **GATE CHECK:** DirectOfferDetailsVM uses ViewState. View compiles. Tests pass. Ergonomics noted.

### 4.3 Migrate BookingViewModel

**Primary Agent(s):** `@Architect`, `@Sentinel`
**Goal:** Replace `_isLoading` + `_error` + booking data fields with `ViewState` usage.
**Why:** BookingVM has existing tests (Phase C) — validates that sealed state migration doesn't break tested VMs.
**How:** Replace fields, update getters, update consuming views, update existing tests.
**Result:** BookingVM uses sealed state. All existing BookingVM tests adapted and passing.

- [ ] (`@Architect`) Read `lib/features/booking/viewmodels/booking_view_model.dart` — identify all `_isLoading`, `_error`, and data fields. Note: BookingVM may have multiple data fields (booking list, current booking, etc.) — may need multiple ViewState fields or a composite data class.
- [ ] (`@Architect`) Decide: single `ViewState<BookingData>` with composite data class, or multiple `ViewState` fields for different operations. Document decision.
- [ ] (`@Architect`) Apply sealed state migration.
- [ ] (`@Architect`) Update all consuming views to use pattern matching.
- [ ] (`@Architect`) Update existing BookingVM tests to assert on `ViewState` instead of `isLoading` + `error`.
- [ ] (`@Sentinel`) Run `flutter test` — all BookingVM tests pass with updated assertions.
- [ ] (`@Sentinel`) Run `flutter analyze` — 0 issues.
- [ ] (`@Sentinel`) Note: how many test assertions changed? Record in session log.
- **GATE CHECK:** BookingVM uses sealed state. All existing tests adapted. View compiles.

### 4.4 Migrate WorkItemDetailsViewModel

**Primary Agent(s):** `@Architect`, `@Sentinel`
**Goal:** Migrate WorkItemDetailsVM to sealed state, eliminating the 32 null assertions in its consuming view.
**Why:** `work_item_details_screen.dart` has 32 `!` operators (21x `workItem!`, 3x `booking!`, etc.). Sealed state with a `Loaded` case that provides non-null data eliminates these crash points.
**How:** Replace fields with ViewState. Update view to use pattern matching with non-null data access in Loaded case.
**Result:** WorkItemDetailsVM uses sealed state. Null assertions in view reduced to <10.

- [ ] (`@Architect`) Read `lib/features/work/viewmodels/work_item_details_view_model.dart` — identify all nullable data fields and error/loading flags.
- [ ] (`@Architect`) Design composite data class if multiple fields need to be non-null together (e.g., `WorkItemData(workItem, booking, ...)`).
- [ ] (`@Architect`) Apply sealed state migration.
- [ ] (`@Architect`) Read `lib/features/work/view/work_item_details_screen.dart` — replace `vm.workItem!` patterns with sealed state pattern matching.
- [ ] (`@Architect`) Count remaining `!` operators — target: <10 (down from 32).
- [ ] (`@Sentinel`) Run `flutter analyze` — 0 issues.
- [ ] (`@Sentinel`) Run `flutter test` — all tests pass.
- [ ] (`@Sentinel`) Document null assertion count reduction in session log.
- **GATE CHECK:** WorkItemDetailsVM uses sealed state. Null assertions reduced by 75%+. Tests pass.

### 4.5 Sealed State Rollout Decision Gate

**Primary Agent(s):** `@Sentinel`
**Goal:** Decide whether to continue sealed state migration to remaining VMs in Phase F.
**Why:** The pattern needs real-world validation before committing to a full codebase migration.
**How:** Evaluate 3 completed migrations for ergonomics, churn, and test impact.
**Result:** Decision documented with evidence. Phase F scope adjusted accordingly.

- [ ] (`@Sentinel`) Collect metrics from 4.2–4.4:
  - Total view lines changed across 3 migrations.
  - Total test assertions changed.
  - Average switch/case boilerplate per view.
  - Any gotchas or pain points encountered.
- [ ] (`@Sentinel`) Decision gate:
  - **If ergonomic** (< 30 lines of boilerplate per view, tests adapted cleanly): Recommend Phase F migrates remaining VMs.
  - **If mixed** (30–60 lines boilerplate, some test friction): Recommend Phase F migrates only VMs with >3 null assertions.
  - **If verbose/painful** (>60 lines boilerplate, significant test rewrites): Stop at 3 VMs. Reconsider approach (e.g., simpler sealed class, or keep `isLoading` pattern for simple VMs).
- [ ] (`@Sentinel`) Document decision and evidence in session log.
- **GATE CHECK:** Decision is documented with quantitative evidence. Phase F scope is clear.

---

## Phase 5: God File Decomposition — ViewModels & Services (Logic Layer)

**Primary Agent(s):** `@Architect`, `@Sentinel`
**Goal:** Decompose the 5 god files that are ViewModels or Services to under 800 lines each (or document feasibility exception).
**Why:** Large files are hard to test, review, and maintain. Logic-layer decomposition must happen before view-layer (Phase 6) because views depend on logic-layer contracts.
**How:** For EACH file: read → extraction map → line-count feasibility (§1.2) → extract delegates/sub-services → verify tests pass → verify line count.
**Result:** 5 logic-layer god files under 800 lines (or documented exceptions). All tests pass.

### 5.1 Decompose `task_service.dart` (960 lines)

**Primary Agent(s):** `@Architect`, `@Sentinel`
**Goal:** Split TaskService into focused sub-services.
**Why:** 960 lines of mixed CRUD, query, filter, and orchestration logic — largest service file.
**How:** Identify method groups. Extract task image handling, task status queries, or pagination helpers into separate service files.
**Result:** TaskService under 800 lines.

- [ ] (`@Architect`) Read `lib/features/tasks/services/task_service.dart` completely. Note method count, dependency list, shared state.
- [ ] (`@Architect`) Create extraction map:
  - List each method group with approximate line counts.
  - Identify shared state that prevents extraction (e.g., cached SupabaseClient).
  - Estimate extractable lines vs must-stay lines.
- [ ] (`@Architect`) Set realistic target per §1.2: `current_lines - extractable_lines + 10% buffer`.
- [ ] (`@Architect`) Extract identified delegate(s) to new file(s) under `lib/features/tasks/services/`.
- [ ] (`@Architect`) Update imports in all files that reference TaskService methods that moved.
- [ ] (`@Architect`) Verify parent service correctly delegates to new file(s).
- [ ] (`@Sentinel`) Run `flutter test` — all existing task tests must pass.
- [ ] (`@Sentinel`) Run `flutter analyze` — 0 issues.
- [ ] (`@Sentinel`) Measure `task_service.dart` line count — must be under 800 (or document §1.2 exception if must-stay lines exceed 700).
- **GATE CHECK:** TaskService decomposed. Tests pass. Analyze clean. Line count verified.

### 5.2 Decompose `task_requests_view_model.dart` (853 lines)

**Primary Agent(s):** `@Architect`, `@Sentinel`
**Goal:** Extract filter logic, pagination state, or bid comparison into delegates.
**Why:** 853 lines mixing pagination, filtering, bid management, and status tracking.
**How:** Follow Phase D delegate pattern (similar to RequestsFilterViewModel extraction).
**Result:** Under 800 lines.

- [ ] (`@Architect`) Read `lib/features/tasks/viewmodels/task_requests_view_model.dart` completely.
- [ ] (`@Architect`) Create extraction map with line-count feasibility analysis (§1.2).
- [ ] (`@Architect`) Extract delegate(s) to new file(s) under `lib/features/tasks/viewmodels/`.
- [ ] (`@Architect`) Verify parent VM correctly delegates.
- [ ] (`@Sentinel`) Run `flutter test` — existing task_requests tests pass.
- [ ] (`@Sentinel`) Run `flutter analyze` — 0 issues.
- [ ] (`@Sentinel`) Verify under 800 lines (or document §1.2 exception).
- **GATE CHECK:** Decomposed. Tests pass. Analyze clean.

### 5.3 Decompose `task_requests_service.dart` (856 lines)

**Primary Agent(s):** `@Architect`, `@Sentinel`
**Goal:** Extract query/filter methods or status management into sub-services.
**Why:** 856 lines of service logic.
**How:** Identify method groupings, extract focused sub-service.
**Result:** Under 800 lines.

- [ ] (`@Architect`) Read `lib/features/tasks/services/task_requests_service.dart` completely.
- [ ] (`@Architect`) Create extraction map with feasibility analysis (§1.2).
- [ ] (`@Architect`) Extract sub-service(s).
- [ ] (`@Architect`) Update imports in consuming VMs.
- [ ] (`@Sentinel`) Run `flutter test` — pass.
- [ ] (`@Sentinel`) Run `flutter analyze` — 0 issues.
- [ ] (`@Sentinel`) Verify under 800 lines (or document §1.2 exception).
- **GATE CHECK:** Decomposed. Tests pass.

### 5.4 Decompose `booking_view_model.dart` (820 lines)

**Primary Agent(s):** `@Architect`, `@Sentinel`
**Goal:** Extract payment coordination or pagination into delegates.
**Why:** 820 lines. Borderline but payment-adjacent code deserves isolation. Extraction map shows ~280 lines extractable (payment coordinator ~150L, pagination handler ~80L, lifecycle ~50L).
**How:** Extract BookingPaymentCoordinator delegate first (cleanest extraction). Evaluate further extraction if needed.
**Result:** Under 800 lines (target: ~540 with full extraction).

- [ ] (`@Architect`) Read `lib/features/booking/viewmodels/booking_view_model.dart` completely.
- [ ] (`@Architect`) Create extraction map with feasibility analysis (§1.2). Confirm ~280 lines are extractable.
- [ ] (`@Architect`) Extract `BookingPaymentCoordinator` delegate — payment-related methods.
- [ ] (`@Architect`) If target not met, extract pagination handler.
- [ ] (`@Architect`) Wire delegates in BookingVM constructor with DI support.
- [ ] (`@Sentinel`) Run `flutter test` — all BookingVM tests pass (note: tests may reference sealed state from Phase 4.3).
- [ ] (`@Sentinel`) Run `flutter analyze` — 0 issues.
- [ ] (`@Sentinel`) Verify under 800 lines.
- **GATE CHECK:** Decomposed. Tests pass. Payment code isolated.

### 5.5 Decompose `qicard_payment_service.dart` (811 lines)

**Primary Agent(s):** `@Architect`, `@Sentinel`
**Goal:** Extract webhook handling, payment creation, or refund logic into focused sub-services.
**Why:** 811 lines of payment-critical code. Isolation improves auditability and testability.
**How:** Extract by payment operation type (create vs webhook vs refund).
**Result:** Under 800 lines.

- [ ] (`@Architect`) Read `lib/core/services/qicard_payment_service.dart` completely.
- [ ] (`@Architect`) Create extraction map with feasibility analysis (§1.2).
- [ ] (`@Architect`) Extract sub-service(s) to `lib/core/services/`.
- [ ] (`@Architect`) Update imports in consuming code.
- [ ] (`@Sentinel`) Run `flutter test` — pass.
- [ ] (`@Sentinel`) Run `flutter analyze` — 0 issues.
- [ ] (`@Sentinel`) Verify under 800 lines (or document §1.2 exception).
- **GATE CHECK:** All 5 logic-layer god files addressed. Tests pass. Analyze clean.

---

## Phase 6: God File Decomposition — Views (UI Layer)

**Primary Agent(s):** `@Pixel`, `@Architect`, `@Sentinel`
**Goal:** Decompose the 4 god files that are Views/Widgets to under 800 lines each.
**Why:** Large view files mix layout, interaction logic, and widget trees. Extraction improves reusability, testability, and maintainability.
**How:** Extract sub-widgets, section builders, or dialog components. Follow Phase D's `requests_list_screen` extraction pattern (1172→604).
**Result:** 4 view god files under 800 lines each.

### 6.1 Decompose `work_item_details_screen.dart` (1099 lines)

**Primary Agent(s):** `@Pixel`, `@Architect`, `@Sentinel`
**Goal:** Extract status section, timeline section, action buttons, and detail sections into sub-widgets.
**Why:** 1099 lines — largest view file. Contains 32 null assertions (some reduced by Phase 4.4 sealed state migration). Highest decomposition priority.
**How:** Extract focused widgets to `lib/features/work/view/widgets/`. Leverage sealed state from Phase 4.4 in extracted widgets.
**Result:** Under 800 lines. Null assertions minimal.

- [ ] (`@Pixel | Skill: arrange`) Read entire file. Identify widget sections: header/status, timeline, action buttons, booking details, deliverables, review section.
- [ ] (`@Architect`) Create extraction map with line-count feasibility analysis (§1.2).
- [ ] (`@Pixel | Skill: arrange`) Extract section widgets to `lib/features/work/view/widgets/`:
  - `work_item_status_header.dart`
  - `work_item_timeline.dart`
  - `work_item_action_buttons.dart`
  - (additional widgets as identified in extraction map)
- [ ] (`@Pixel | Skill: harden`) Ensure extracted widgets receive data from sealed `ViewState` — no `!` operators needed in `Loaded` case.
- [ ] (`@Sentinel`) Run `flutter analyze` — 0 issues.
- [ ] (`@Sentinel`) Verify file under 800 lines.
- [ ] (`@Sentinel`) Count remaining `!` operators — must be < 5.
- [ ] (`@Pixel | Skill: audit`) Final visual audit: confirm layout, spacing, and state rendering match pre-extraction behavior.
- **GATE CHECK:** Decomposed. Null assertions minimal. Audit complete. Analyze clean.

### 6.2 Decompose `wallet_shared_body.dart` (1003 lines)

**Primary Agent(s):** `@Pixel`, `@Sentinel`
**Goal:** Extract wallet sections into sub-widgets.
**Why:** 1003 lines. Shared widget used in multiple contexts.
**How:** Extract balance card, transaction list, withdrawal form.
**Result:** Under 800 lines.

- [ ] (`@Pixel | Skill: arrange`) Read entire file. Identify sections: balance display, transaction list, withdrawal form, filters.
- [ ] (`@Architect`) Create extraction map with feasibility analysis (§1.2).
- [ ] (`@Pixel | Skill: arrange`) Extract section widgets to `lib/features/wallet/view/widgets/`.
- [ ] (`@Sentinel`) Run `flutter test` — existing wallet tests pass.
- [ ] (`@Sentinel`) Run `flutter analyze` — 0 issues.
- [ ] (`@Sentinel`) Verify under 800 lines.
- [ ] (`@Pixel | Skill: audit`) Final visual audit of wallet screens.
- **GATE CHECK:** Decomposed. Tests pass. Audit complete.

### 6.3 Decompose `create_task_screen.dart` (944 lines)

**Primary Agent(s):** `@Pixel`, `@Architect`, `@Sentinel`
**Goal:** Extract form sections, image picker, and category selector.
**Why:** 944 lines. Form-heavy screen with mixed concerns.
**How:** Extract form field groups as widgets.
**Result:** Under 800 lines.

- [ ] (`@Pixel | Skill: arrange`) Read entire file. Identify form sections: title/description, category picker, budget/deadline, image picker, submit section.
- [ ] (`@Architect`) Create extraction map with feasibility analysis (§1.2).
- [ ] (`@Pixel | Skill: arrange`) Extract form section widgets to `lib/features/tasks/view/widgets/`.
- [ ] (`@Sentinel`) Run `flutter analyze` — 0 issues.
- [ ] (`@Sentinel`) Verify under 800 lines.
- [ ] (`@Pixel | Skill: audit`) Final visual audit of create task screen.
- **GATE CHECK:** Decomposed. Audit complete. Analyze clean.

### 6.4 Decompose `payment_checkout_screen.dart` (831 lines)

**Primary Agent(s):** `@Pixel`, `@Architect`, `@Sentinel`
**Goal:** Extract payment summary, WebView section, and confirmation dialogs.
**Why:** 831 lines. Payment-adjacent UI deserves clear boundaries.
**How:** Extract focused widgets.
**Result:** Under 800 lines.

- [ ] (`@Pixel | Skill: arrange`) Read entire file. Identify sections: payment summary, WebView container, status indicators, confirmation dialogs.
- [ ] (`@Architect`) Create extraction map with feasibility analysis (§1.2).
- [ ] (`@Pixel | Skill: arrange`) Extract section widgets to `lib/features/booking/view/widgets/` (or `lib/features/payment/view/widgets/` depending on file location).
- [ ] (`@Sentinel`) Run `flutter analyze` — 0 issues.
- [ ] (`@Sentinel`) Verify under 800 lines.
- [ ] (`@Pixel | Skill: audit`) Final visual audit of checkout screen.
- **GATE CHECK:** All 4 view-layer god files decomposed. Audits complete. Analyze clean.

---

## Phase 7: Mock Expansion + ViewModel Test Expansion

**Primary Agent(s):** `@Sentinel`, `@Architect`
**Goal:** Expand shared mock infrastructure, then write test files for all 10 untested ViewModels.
**Why:** 63% VM test coverage (17/27) is insufficient. Untested VMs include search (debounce), saved (auth subscription), direct offers (acceptance), portfolio, categories, safety (report/dispute), and work item details. Mock expansion must happen BEFORE test writing to prevent mock duplication.
**How:** First expand mocks, then write tests following Phase C patterns.
**Result:** 27/27 ViewModels have test files. Minimum 8 tests per VM (~100+ new tests).

### 7.0 Expand Shared Mock Infrastructure

**Primary Agent(s):** `@Sentinel`, `@Architect`
**Goal:** Add mock classes for all services/repositories used by the 10 untested VMs.
**Why:** Without shared mocks, each test file will re-create mock classes — duplication, inconsistency, maintenance burden. Phase C established the `mock_services.dart` pattern; Phase 7 must extend it.
**How:** Read each untested VM's constructor. Add missing mock classes to `test/helpers/mock_services.dart`.
**Result:** Shared mock file contains mocks for ALL service/repository dependencies of all 27 VMs.

- [ ] (`@Sentinel`) Read each of the 10 untested VM constructors. List every injected dependency.
- [ ] (`@Sentinel`) Cross-reference against existing mocks in `test/helpers/mock_services.dart` (currently: MockWalletRepository, MockAccountGuardService, MockChatRepository, MockDirectOffersService, MockDashboardRepository, MockDashboardCacheService, MockBookingService, MockTaskService, MockTaskRequestsService).
- [ ] (`@Architect`) Add missing mock classes to `test/helpers/mock_services.dart`:
  - `MockSearchService` (for SearchVM)
  - `MockSavedTasksService` or relevant service (for SavedTasksVM)
  - `MockCategoriesRepository` (for CategoriesVM)
  - `MockPortfolioRepository` (for PortfolioVM)
  - `MockProfileRepository` (for PublicProfileVM, UserProfileVM)
  - `MockReportService` (for SafetyVM)
  - `MockDisputeService` (for SafetyVM)
  - `MockServicesRepository` (for MyServicesVM)
  - `MockAuthRepository` (for AuthFormVM, if not already covered)
  - `MockMessageService` (for UserProfileVM, if not already covered)
  - Any other dependencies found in constructor scans.
- [ ] (`@Sentinel`) Run `flutter analyze` — 0 issues.
- [ ] (`@Sentinel`) Run `flutter test` — all tests pass (mocks are additive, no breakage).
- **GATE CHECK:** `mock_services.dart` contains mock classes for every service/repository dependency. No test file needs to define its own mock class.

### 7.1 Priority 1: Business-Critical VMs

**Primary Agent(s):** `@Sentinel`
**Goal:** Test the 3 untested VMs with highest business risk.
**Why:** DirectOfferDetails handles offer acceptance (money flow), Search handles the primary discovery UX, SavedTasks handles persistent user state.
**How:** Write test files following Phase C pattern. Each file: setUp with mocks, tearDown cleanup, happy path, error path, edge cases.
**Result:** 3 VM test files with ~35 total tests.

- [ ] (`@Sentinel`) **DirectOfferDetailsViewModel test file** (`test/unit/direct_offers/direct_offer_details_view_model_test.dart`):
  - setUp: create mock services, construct VM.
  - Tests: offer loading (happy + error), acceptance, rejection, payment trigger, sealed state transitions (ViewInitial → ViewLoading → ViewLoaded, ViewFailed).
  - Minimum 12 tests.
- [ ] (`@Sentinel`) **SearchViewModel test file** (`test/unit/search/search_view_model_test.dart`):
  - setUp: create mock SearchService, construct VM.
  - Tests: debounce behavior (query change triggers delayed search), tab switching, query clearing, pagination (load more), empty results, error handling.
  - Minimum 12 tests.
- [ ] (`@Sentinel`) **SavedTasksViewModel test file** (`test/unit/saved/saved_tasks_view_model_test.dart`):
  - **CRITICAL:** Pre-configure ALL mock stubs BEFORE VM construction (constructor auto-loads via `_initAuthListener`).
  - setUp: create mock service + mock auth stream, configure stubs, THEN construct VM.
  - tearDown: dispose VM, clean up streams.
  - Tests: auth listener init, load on login, load on logout (clear), save toggle, unsave toggle, error handling, pagination.
  - Minimum 12 tests.
- [ ] (`@Sentinel`) Run `flutter test` after each new test file — all must pass.
- **GATE CHECK:** 3 business-critical VM test files created with ~35 tests. All pass.

### 7.2 Priority 2: User-Facing VMs

**Primary Agent(s):** `@Sentinel`
**Goal:** Test 4 user-facing VMs.
**Why:** These VMs back screens users interact with daily — profile views, auth forms, portfolio.
**How:** Write test files.
**Result:** 4 VM test files with ~32 total tests.

- [ ] (`@Sentinel`) **AuthFormViewModel test file** (`test/unit/auth/auth_form_view_model_test.dart`):
  - Tests: form submission (email/password), validation errors, network error mapping, account guard check, loading state.
  - Minimum 10 tests.
- [ ] (`@Sentinel`) **UserProfileViewModel test file** (`test/unit/profile/user_profile_view_model_test.dart`):
  - Tests: profile loading, portfolio fetch, message initiation, error states.
  - Minimum 8 tests.
- [ ] (`@Sentinel`) **PublicProfileViewModel test file** (`test/unit/profile/public_profile_view_model_test.dart`):
  - Tests: public profile loading, error states, empty portfolio.
  - Minimum 6 tests.
- [ ] (`@Sentinel`) **PortfolioViewModel test file** (`test/unit/portfolio/portfolio_view_model_test.dart`):
  - Tests: portfolio loading, image upload coordination, delete, error handling.
  - Minimum 8 tests.
- [ ] (`@Sentinel`) Run `flutter test` — all pass.
- **GATE CHECK:** 4 user-facing VM test files. All pass.

### 7.3 Priority 3: Supporting VMs

**Primary Agent(s):** `@Sentinel`
**Goal:** Test remaining 3 untested VMs.
**Why:** Complete VM test coverage. These VMs back secondary screens but still contain testable business logic.
**How:** Write test files.
**Result:** 3 VM test files with ~22 total tests.

- [ ] (`@Sentinel`) **CategoriesViewModel test file** (`test/unit/categories/categories_view_model_test.dart`):
  - Tests: category loading, caching behavior, error states.
  - Minimum 6 tests.
- [ ] (`@Sentinel`) **SafetyViewModel test file** (`test/unit/safety/safety_view_model_test.dart`):
  - Tests: report submission, dispute listing, dispute detail loading, error handling.
  - Minimum 8 tests.
- [ ] (`@Sentinel`) **MyServicesViewModel test file** (`test/unit/services/my_services_view_model_test.dart`):
  - Tests: service listing, create, update, delete, error handling.
  - Minimum 8 tests.
- [ ] (`@Sentinel`) **WorkItemDetailsViewModel test file** (`test/unit/work/work_item_details_view_model_test.dart`):
  - Tests: work item loading (sealed state), booking loading, status transitions, action methods, error handling.
  - Minimum 10 tests.
- [ ] (`@Sentinel`) Run `flutter test` — all pass.
- **GATE CHECK:** All 27 VMs have test files. All tests pass. Run `find test -name "*_view_model_test.dart" | wc -l` — must be ≥ 27.

---

## Phase 8: Coverage Floor Push

**Primary Agent(s):** `@Sentinel`, `@Architect`
**Goal:** Raise CI coverage floor from 28% to 45%+ (or measured-2%, whichever is higher).
**Why:** 28% was a Phase D regression floor. Phase E tests should push actual coverage significantly higher. The new floor must be evidence-based, not aspirational.
**How:** Measure after Phase 7, add targeted tests if needed, raise floor.
**Result:** Coverage floor raised. CI green with new threshold.

### 8.1 Measure Coverage and Set Floor

**Primary Agent(s):** `@Sentinel`, `@Architect`
**Goal:** Determine the actual coverage after Phase 7 tests and set an appropriate floor.
**Why:** Setting the floor without measuring leads to either too-low (useless) or too-high (blocking) thresholds. Phase D lesson: set floor at measured-2%.
**How:** Run coverage, analyze results, decide floor.
**Result:** Evidence-based coverage floor.

- [ ] (`@Sentinel`) Run `flutter test --coverage`.
- [ ] (`@Sentinel`) Parse `coverage/lcov.info` — report total line coverage percentage.
- [ ] (`@Sentinel`) **If coverage ≥ 47%**: Set floor to 45%.
- [ ] (`@Sentinel`) **If coverage 40–46%**: Set floor to measured-2%.
- [ ] (`@Sentinel`) **If coverage 35–39%**: Identify 5 high-value uncovered service/repository files. Write targeted tests (aim for +5% coverage). Then set floor to measured-2%.
- [ ] (`@Sentinel`) **If coverage < 35%**: Identify 10 high-value uncovered files. Write targeted tests. Set floor to measured-2%. Document in session log why 45% was not achievable (likely: services/views have low coverage, VM tests alone insufficient).
- **GATE CHECK:** Coverage measured. Floor decision is evidence-based.

### 8.2 Update CI Configuration

**Primary Agent(s):** `@Architect`, `@Sentinel`
**Goal:** Apply new coverage floor to CI.
**Why:** Floor without CI enforcement is meaningless.
**How:** Update threshold in ci.yml.
**Result:** CI green with new floor.

- [ ] (`@Architect`) Update coverage threshold in `.github/workflows/ci.yml` from `28` to new floor value.
- [ ] (`@Sentinel`) Run `flutter test --coverage` locally — confirm coverage meets threshold.
- [ ] (`@Sentinel`) Run `flutter analyze` — 0 issues (sanity check).
- **GATE CHECK:** CI threshold updated. Coverage passes locally.

---

## Phase 9: DeepLinkService Refactor

**Primary Agent(s):** `@Architect`, `@Sentinel`
**Goal:** Refactor DeepLinkService from hard-coded feature screen imports to a route registry pattern. Graduate CI Check 7 to hard failure.
**Why:** Core service importing 7 feature screens + 5 feature services violates core/feature boundary (architecture violation A7). After refactoring, Check 7 prevents future violations.
**How:** Define `DeepLinkRegistry`. Features register handlers. DeepLinkService dispatches via registry.
**Result:** DeepLinkService has 0 feature imports. CI Check 7 is hard failure.

### 9.1 Design Route Registry

**Primary Agent(s):** `@Architect`, `@Sentinel`
**Goal:** Design the registry interface before implementation.
**Why:** Poor interface design leads to refactor-of-the-refactor. Get the API right first.
**How:** Define types, registration pattern, dispatch pattern. Confirm all 10 entity types are covered.
**Result:** Interface design documented and approved.

- [ ] (`@Architect`) Design `DeepLinkHandler` typedef:
  ```dart
  typedef DeepLinkHandler = Future<void> Function(BuildContext context, String entityId, Map<String, dynamic>? metadata);
  ```
- [ ] (`@Architect`) Design `DeepLinkRegistry` class:
  - `void register(String entityType, DeepLinkHandler handler)` — features call this at startup.
  - `Future<void> handle(BuildContext context, String entityType, String entityId, {Map<String, dynamic>? metadata})` — DeepLinkService calls this.
  - `bool canHandle(String entityType)` — check if handler exists.
- [ ] (`@Sentinel`) Verify design covers all 10 entity types: `task`, `offer`, `booking`, `conversation`, `message`, `direct_offer`, `directoffer`, `profile`, `user`, `work_item`.
- [ ] (`@Sentinel`) Verify design handles: notification deep links, activity log deep links, URL-based deep links.
- **GATE CHECK:** Interface design covers all routes. No entity type is dropped.

### 9.2 Implement Registry + Migrate Handlers

**Primary Agent(s):** `@Architect`, `@Sentinel`
**Goal:** Create registry, move handlers to feature modules, update DeepLinkService.
**Why:** Implementation must preserve all existing behavior while removing feature imports from core.
**How:** Create registry file, create per-feature registration files, refactor DeepLinkService, wire in main.dart.
**Result:** 0 feature imports in DeepLinkService.

- [ ] (`@Architect`) Create `lib/core/services/deep_link_registry.dart` with `DeepLinkRegistry` class.
- [ ] (`@Architect`) Create feature-side registration files:
  - `lib/features/tasks/services/task_deep_link_handler.dart`
  - `lib/features/booking/services/booking_deep_link_handler.dart`
  - `lib/features/chat/services/chat_deep_link_handler.dart`
  - `lib/features/direct_offers/services/direct_offer_deep_link_handler.dart`
  - `lib/features/work/services/work_deep_link_handler.dart`
  - `lib/features/profile/services/profile_deep_link_handler.dart`
- [ ] (`@Architect`) Move entity-specific navigation logic from DeepLinkService switch/case into each handler.
- [ ] (`@Architect`) Refactor `DeepLinkService` to:
  - Accept `DeepLinkRegistry` via constructor (DI).
  - Dispatch to registry instead of switch/case.
  - Remove ALL feature screen imports.
  - Remove ALL feature service imports (TaskService, BookingService, MessageService).
- [ ] (`@Architect`) Update DeepLinkService registration in `main.dart:275` to inject registry.
- [ ] (`@Architect`) Wire feature registrations in `main.dart` or via a `registerDeepLinkHandlers()` initialization function.
- [ ] (`@Sentinel`) Verify: `grep -c "import.*features/" lib/core/services/deep_link_service.dart` returns 0.
- [ ] (`@Sentinel`) Verify: `grep -c "import.*features/" lib/core/services/deep_link_registry.dart` returns 0.
- [ ] (`@Sentinel`) Run `flutter analyze` — 0 issues.
- [ ] (`@Sentinel`) Run `flutter test` — all tests pass.
- **GATE CHECK:** 0 feature imports in core/services/deep_link_service.dart. Tests pass.

### 9.3 Write Deep Link Tests + Graduate CI Check 7

**Primary Agent(s):** `@Sentinel`, `@Architect`
**Goal:** Test all 10 routes and make CI Check 7 a hard failure.
**Why:** Untested refactor is unverified refactor. CI guard must prevent regressions.
**How:** Write unit tests for registry. Graduate Check 7.
**Result:** 10 route tests pass. Check 7 is hard failure.

- [ ] (`@Sentinel`) Write `test/unit/core/deep_link_registry_test.dart`:
  - Test registration of each entity type.
  - Test dispatch to correct handler.
  - Test unknown entity type handling (graceful fallback).
  - Minimum 12 tests.
- [ ] (`@Architect`) Update CI Check 7 in `.github/workflows/ci.yml`:
  - Remove `echo "WARNING"` → change to `echo "FAIL"` + `FAIL=1`.
  - Remove TODO comment about Phase E9.
- [ ] (`@Sentinel`) Run CI locally — all 7 checks pass (including Check 7 as hard failure).
- [ ] (`@Sentinel`) Run `flutter test` — all tests pass including new deep link tests.
- **GATE CHECK:** 10 route tests pass. CI Check 7 is hard failure with 0 violations.

---

## Phase 10: Localization Infrastructure

**Primary Agent(s):** `@Architect`, `@Pixel`, `@Sentinel`
**Goal:** Set up localization infrastructure so `.arb` content can be added incrementally. Create test helper to prevent localization from breaking widget tests.
**Why:** App needs Arabic and Kurdish support. Infrastructure must exist before translators can contribute. Widget tests must not break when localization is wired in.
**How:** Create `l10n.yaml`, scaffold `.arb`, wire `MaterialApp`, create test helper, proof-of-concept on 1 screen.
**Result:** Localization compiles and runs. Test helper exists. Proof-of-concept renders.

### 10.1 Create Localization Config

**Primary Agent(s):** `@Architect`, `@Sentinel`
**Goal:** Create localization configuration files.
**Why:** Flutter requires `l10n.yaml` and `.arb` files for code generation.
**How:** Create config and template files.
**Result:** `flutter gen-l10n` succeeds.

- [ ] (`@Architect`) Create `lib/l10n/` directory.
- [ ] (`@Architect`) Create `l10n.yaml`:
  ```yaml
  arb-dir: lib/l10n
  template-arb-file: app_en.arb
  output-localization-file: app_localizations.dart
  output-class: AppLocalizations
  ```
- [ ] (`@Architect`) Create `lib/l10n/app_en.arb` with 15+ high-frequency string stubs:
  - Navigation: home, search, dashboard, profile, settings, notifications, wallet
  - Actions: login, logout, submit, cancel, save, delete, confirm
  - States: loading, error, empty, retry, noResults
  - Errors: networkError, sessionExpired, unknownError
- [ ] (`@Architect`) Add `generate: true` to `pubspec.yaml` under `flutter:` section if not already present.
- [ ] (`@Sentinel`) Run `flutter gen-l10n` — must succeed without errors.
- [ ] (`@Sentinel`) Verify generated `app_localizations.dart` file exists.
- **GATE CHECK:** Localization files generate. `.arb` has 15+ stubs.

### 10.2 Wire Localization into App

**Primary Agent(s):** `@Architect`, `@Pixel`, `@Sentinel`
**Goal:** Connect localization delegates to `MaterialApp`.
**Why:** Delegates must be wired for `AppLocalizations.of(context)` to work.
**How:** Update `main.dart` MaterialApp config. Replace 3–5 strings on 1 screen as proof of concept.
**Result:** English strings render via localization. App runs normally.

- [ ] (`@Architect`) Update `MaterialApp` in `main.dart`:
  - Add `localizationsDelegates: AppLocalizations.localizationsDelegates`
  - Add `supportedLocales: AppLocalizations.supportedLocales`
  - Add `locale: const Locale('en')` as default
- [ ] (`@Pixel | Skill: arrange`) Replace 3–5 hardcoded strings in one high-frequency screen (e.g., dashboard tab labels or home screen titles) with `AppLocalizations.of(context)!.keyName`.
- [ ] (`@Sentinel`) Run app — confirm English strings render correctly.
- [ ] (`@Sentinel`) Run `flutter analyze` — 0 issues.
- **GATE CHECK:** Localization wired. Proof-of-concept strings render in English.

### 10.3 Create Test Localization Helper

**Primary Agent(s):** `@Sentinel`, `@Architect`
**Goal:** Prevent localization from breaking existing widget tests.
**Why:** Widget tests that use `MaterialApp()` without delegates will crash if any rendered widget calls `AppLocalizations.of(context)!`. A shared test helper ensures all widget tests include delegates.
**How:** Create `testApp()` wrapper function. Update any broken tests.
**Result:** All tests pass with localization wired.

- [ ] (`@Architect`) Create or update `test/helpers/test_app.dart`:
  ```dart
  Widget testApp({required Widget home}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: home,
    );
  }
  ```
- [ ] (`@Sentinel`) Run `flutter test` — identify any tests that fail due to localization.
- [ ] (`@Sentinel`) Update failing tests to use `testApp()` wrapper.
- [ ] (`@Sentinel`) Run `flutter test` — ALL tests pass.
- **GATE CHECK:** All tests pass. Test helper exists. No localization-related test failures.

---

## Phase 11: Final QA & Security Review (MANDATORY)

**Primary Agent(s):** `@Sentinel`, `@CodeGuard`
**Goal:** Verify all Phase E deliverables meet acceptance criteria.
**Why:** Phase E touches lint rules, state management patterns, file structure, navigation, build config, and localization. Comprehensive verification prevents regressions.
**How:** Run all gates, verify all AC items, check architecture guard, run full test suite.
**Result:** All 11 acceptance criteria evaluated.

### 11.1 Full Gate Check

**Primary Agent(s):** `@Sentinel`, `@CodeGuard`
**Goal:** Run every automated gate and security review.
**Why:** Final verification before documentation phase.
**How:** Execute all verification commands.
**Result:** All gates green.

- [ ] (`@Sentinel`) Run `flutter analyze` — 0 issues.
- [ ] (`@Sentinel`) Run `flutter test --coverage` — all tests pass, coverage meets floor.
- [ ] (`@Sentinel`) Run `flutter build apk --debug` — succeeds.
- [ ] (`@Sentinel`) Run `flutter build web --release` — succeeds.
- [ ] (`@Sentinel`) Run architecture guard locally — all 7 checks pass (Check 7 hard failure, 0 violations).
- [ ] (`@Sentinel`) Run `dart fix --dry-run` — 0 remaining.
- [ ] (`@CodeGuard`) Review all new files for:
  - Security: no hardcoded keys, no Supabase.instance in views, no direct DB access in VMs.
  - Performance: no N+1 queries in new/refactored services, no unbounded lists in extracted delegates.
  - Compatibility: no breaking changes to provider registrations in main.dart.
  - DI: all new mocks use `mockito` or manual mocks consistently.
- **GATE CHECK:** All automated gates pass. Code review clean.

### 11.2 Acceptance Criteria Verification

**Primary Agent(s):** `@Sentinel`
**Goal:** Evaluate every AC item with evidence.
**Why:** Acceptance criteria are the definition of done. No AC = not done.
**How:** Run verification command for each AC. Record PASS/FAIL/DEFERRED with evidence.
**Result:** AC evaluation table in session log.

- [ ] (`@Sentinel`) **AC-1:** `flutter build apk --debug` exits 0 — PASS/FAIL
- [ ] (`@Sentinel`) **AC-2:** `head -5 analysis_options.yaml` shows `very_good_analysis` — PASS/FAIL/DEFERRED (if deferred: session log has rationale)
- [ ] (`@Sentinel`) **AC-3:** `dart fix --dry-run` reports 0 — PASS/FAIL
- [ ] (`@Sentinel`) **AC-4:** `wc -l` on all 9 god files shows <800 — PASS/FAIL (list any §1.2 exceptions with extraction map evidence)
- [ ] (`@Sentinel`) **AC-5:** 3+ VMs use `ViewState<T>` — PASS/FAIL (list migrated VMs)
- [ ] (`@Sentinel`) **AC-6:** `find test -name "*_view_model_test.dart" | wc -l` ≥ count of VMs — PASS/FAIL
- [ ] (`@Sentinel`) **AC-7:** CI coverage threshold is 45%+ (or measured-2%) — PASS/FAIL
- [ ] (`@Sentinel`) **AC-8:** `grep -c "import.*features.*screen" lib/core/services/deep_link_service.dart` returns 0 — PASS/FAIL
- [ ] (`@Sentinel`) **AC-9:** `test -f l10n.yaml && flutter gen-l10n` succeeds — PASS/FAIL
- [ ] (`@Sentinel`) **AC-10:** Docs diff reviewed — PASS/FAIL
- [ ] (`@Sentinel`) **AC-11:** `flutter analyze` = 0, `flutter test` = all pass, CI green — PASS/FAIL
- **GATE CHECK:** All AC items evaluated with evidence. Results in session log.

---

## Phase 12: Documentation Sync (MANDATORY)

**Primary Agent(s):** `@DocsKeeper`
**Goal:** Update all documentation to reflect Phase E changes.
**Why:** Docs must match code reality. Phase E changes lint config, file structure, state patterns, localization, deep link architecture, CI config, and coverage thresholds.
**How:** Update each affected doc file. Write sync artifact.
**Result:** All docs aligned. Sync artifact created.

### 12.1 Update Core Docs

**Primary Agent(s):** `@DocsKeeper`
**Goal:** Update Sline_everything docs.
**Why:** Developers reference these docs. Stale docs cause wrong implementations.
**How:** Update each doc with Phase E changes.
**Result:** All docs match code reality.

- [ ] (`@DocsKeeper`) Update `Sline_everything/DEVELOPER_GUIDE.md`:
  - New lint package (`very_good_analysis` or continued `flutter_lints` + rationale)
  - Sealed `ViewState<T>` pattern documentation with example usage
  - Localization setup: `l10n.yaml`, `.arb` workflow, `flutter gen-l10n` command
  - `DeepLinkRegistry` pattern documentation
  - Test helper (`testApp()`) documentation
- [ ] (`@DocsKeeper`) Update `Sline_everything/STRUCTURE.md`:
  - New files from god-file decomposition (all delegates, sub-services, widgets)
  - `lib/l10n/` directory
  - `lib/core/models/view_state.dart` and `app_failure.dart`
  - `lib/core/services/deep_link_registry.dart`
  - Feature-side deep link handler files
- [ ] (`@DocsKeeper`) Update `Sline_everything/ARCHITECTURE_ANALYSIS.md`:
  - Sealed state class architecture decision + evidence from Phase 4.5 decision gate
  - DeepLinkService decoupling decision + registry pattern rationale
  - CI guard expansion (Check 7)
- [ ] (`@DocsKeeper`) Update `CLAUDE.md`:
  - Lint package reference
  - Sealed state pattern reference
  - Localization commands (`flutter gen-l10n`)
  - Updated coverage floor value
  - Updated test count
  - Architecture guard: 7 checks (Check 7 description)
- **GATE CHECK:** All docs updated. No stale references.

### 12.2 Write Phase E Docs Sync Artifact

**Primary Agent(s):** `@DocsKeeper`
**Goal:** Create tracking artifact for doc changes.
**Why:** Artifact pattern established in Phases A–D. Provides audit trail.
**How:** Write summary file.
**Result:** Sync artifact exists.

- [ ] (`@DocsKeeper`) Write `.TODO/DOCS_SYNC_2026-04-04_PhaseE.md` documenting:
  - Which docs were updated
  - What changed in each doc
  - Cross-references to plan and session log
- **GATE CHECK:** Docs sync artifact exists and is complete.

### 12.3 Update Audit File

**Primary Agent(s):** `@DocsKeeper`
**Goal:** Update the master audit file to reflect Phase E completion.
**Why:** Audit file is the single source of truth for project health. Must reflect current state.
**How:** Update Phase E section, Feature-Level Health Map, test count, coverage, god file status.
**Result:** Audit file current.

- [ ] (`@DocsKeeper`) Update `.TODO/AUDIT_Quality_Architecture_2026-04-01.md`:
  - Mark Phase E tasks as DONE with details and dates.
  - Update Feature-Level Health Map — all features should be GREEN or YELLOW (no RED).
  - Update test count (774 + new tests).
  - Update coverage percentage and floor.
  - Update god file status (all under 800 or documented exceptions).
  - Update architecture guard status (7 checks).
- **GATE CHECK:** Audit file reflects Phase E completion accurately.

---

## 7) Acceptance Criteria (MANDATORY)

| # | Criterion | Measurable Check |
|---|-----------|-----------------|
| AC-1 | APK build green | `flutter build apk --debug` exits 0 |
| AC-2 | `very_good_analysis` active | `analysis_options.yaml` includes `very_good_analysis` (or documented deferral with decision gate evidence) |
| AC-3 | Auto-fixes applied | `dart fix --dry-run` reports 0 |
| AC-4 | No god files | `wc -l` on all 9 targets shows <800 (or documented §1.2 feasibility exception with extraction map) |
| AC-5 | Sealed state in critical VMs | 3+ VMs use `ViewState<T>` pattern |
| AC-6 | All VMs tested | 27/27 ViewModel files have corresponding test files with ≥5 tests each |
| AC-7 | Coverage floor raised | CI threshold set to 45%+ (or measured-2%, whichever is higher) |
| AC-8 | DeepLinkService decoupled | `grep -c "import.*features/" lib/core/services/deep_link_service.dart` returns 0 |
| AC-9 | Localization ready | `l10n.yaml` exists, `flutter gen-l10n` succeeds, 1+ `.arb` file with 15+ key stubs |
| AC-10 | Docs aligned | All `Sline_everything/` docs + `CLAUDE.md` updated |
| AC-11 | CI fully green | 0 analyze, all tests pass, 7 arch checks pass, coverage floor met, both builds succeed |

## 8) Rollback Plan

| Change | Rollback Strategy | Risk |
|--------|-------------------|------|
| `very_good_analysis` migration | Revert `pubspec.yaml` + `analysis_options.yaml` to `flutter_lints`. Clean. | None |
| Sealed `ViewState<T>` classes | Revert VM + View changes via git. Infrastructure files can stay unused. | Forward-fix preferred — once views are updated, reverting is messy |
| God file decompositions | Revert file splits via git. Extracted files are additive. | Forward-fix preferred — reverting multi-file extractions is error-prone |
| DeepLinkService refactor | Revert to switch/case pattern via git. Registry files can stay unused. | Medium — must restore all feature imports |
| Localization infrastructure | Remove `l10n.yaml`, `lib/l10n/`, revert `main.dart` locale config. | Low |
| APK build fix | Revert Kotlin/Gradle versions. Web build unaffected. | Low |
| Coverage floor increase | Revert CI threshold in ci.yml. | None |
| VM DI normalization | All changes are additive (optional params). Revert unnecessary. | None |
| CI Check 7 | Remove grep check from ci.yml. | None |

**Forward-fix preferred for:** God file decompositions, sealed state classes, DeepLinkService refactor. All other changes are cleanly revertible.

## 9) References (From Scan)

### Docs Scanned
- `.TODO/AUDIT_Quality_Architecture_2026-04-01.md` — master audit, Phase E task list
- `Sline_everything/MVP_ROADMAP.md` — Phase E definition
- `Sline_everything/DEVELOPER_GUIDE.md` — architecture patterns
- `Sline_everything/STRUCTURE.md` — file organization
- `docs/LOG/SESSION_PLAN_PhaseD_Harden_2026-04-03.md` — Phase D results and known issues

### Code Paths Scanned
- All 27 ViewModel files under `lib/features/*/viewmodels/` + `lib/core/providers/`
- 9 god files (line counts verified)
- `lib/core/services/deep_link_service.dart` (7 feature screen imports + 5 feature service imports confirmed)
- `analysis_options.yaml` (current lint config: flutter_lints, 34 rules)
- `.github/workflows/ci.yml` (6 architecture checks, 28% coverage floor)
- `pubspec.yaml` (Dart ^3.8.1, flutter_lints ^5.0.0, intl, flutter_localizations)
- `test/helpers/mock_services.dart` (9 existing mock classes)
- `test/helpers/` directory (6 helper files: mock_services, mock_supabase, mock_supabase_rpc, role_switch_helpers, ledger_rpc_invoker, supabase_test_helper)
- 10 untested VMs scanned for DI patterns (2 fully injectable, 8 partially injectable)
- `main.dart` DeepLinkService registration at line 275

### Database Objects Confirmed
- No schema changes planned in Phase E

### Related `.TODO/` Artifacts
- `.TODO/AUDIT_Quality_Architecture_2026-04-01.md`
- `.TODO/Archive/PLAN_PhaseD_Harden_2026-04-03.md`

### Session Log
- `docs/LOG/SESSION_PLAN_PhaseE_Polish_2026-04-04.md`

---

## I) Change Report

### 1. Original Issues Summary (v1 → v2)

7 critical gaps, 2 data mismatches, 4 ordering/redundancy issues found.

### 2. Added Steps

| # | What Was Added | Why |
|---|---------------|-----|
| 1 | Phase 1.3: CI architecture guard Check 7 (core→features) | v1 had no guard for this boundary. DeepLinkService violation would go undetected by CI after Phase 10 refactor. |
| 2 | Phase 7.0: Mock infrastructure expansion sub-phase | v1 jumped straight to test writing. Without shared mocks, each test file would re-create mock classes. |
| 3 | Phase 10.3: Test localization helper | v1 wired localization but didn't address widget test breakage from `AppLocalizations.of(context)!` null crash. |
| 4 | `Skill: audit` step in all Phase 6 (formerly 7) sub-phases | v1 view decomposition phases lacked mandatory audit step per Planner §4.1. |
| 5 | Phase 9.3: Graduate CI Check 7 to hard failure | v1 had no step to graduate the warning-only guard after DeepLinkService refactor completed. |
| 6 | `.arb` stubs increased from 10 to 15 | v1's 10 stubs were thin. 15 covers navigation, actions, states, and errors for realistic proof of concept. |

### 3. Removed Steps

| # | What Was Removed | Why |
|---|-----------------|-----|
| 1 | Standalone Phase 3 (dart fix --apply) | Redundant with Phase 2.2 which already runs `dart fix --apply`. Merged into Phase 2. |
| 2 | Phase 5.4 "if VM exists" conditional | WorkItemDetailsVM confirmed to exist. Conditional language removed. Plan is now deterministic. |

### 4. Reordered Steps

| From | To | Reason |
|------|-----|--------|
| Phase 3 (dart fix) was separate | Merged into Phase 2.2 | Eliminate redundancy — `dart fix` is the first remediation step of lint migration, not a separate phase |
| Phases 4–13 renumbered | Phases 3–12 | Cascading renumber after Phase 3 merge |

### 5. Expanded Steps

| Step | What Changed |
|------|-------------|
| Phase 0.1 Spec Lock | Added explicit verification commands for each baseline check. Listed all touched files. |
| Phase 3 (DI normalization, was 4) | Split into 3.1 (Supabase fallback VMs), 3.2 (hard-coded service VMs), 3.3 (verify injectable VMs). Clearer separation by DI pattern type. |
| Phase 4 (sealed state, was 5) | Phase 4.4 is now deterministic (WorkItemDetailsVM exists). Added composite data class design step for BookingVM. |
| Phase 7 (tests, was 8) | Added 7.0 mock expansion. Added WorkItemDetailsVM to Priority 3 tests. Fixed VM count (27 not 32, 10 untested not 15). |
| Phase 8 (coverage, was 9) | Changed target from hard 50% to "45%+ or measured-2%". Added explicit tiered decision logic. |
| Phase 9 (DeepLink, was 10) | Added 9.3 sub-phase for tests + CI guard graduation. Expanded 9.2 with specific handler file names. |
| Phase 10 (localization, was 11) | Added 10.3 test helper sub-phase. |

### 6. Why

The v1 plan was structurally sound but had:
- **Data errors:** 32 VMs (actual: 27) cascading into wrong test targets and coverage math.
- **Missing infrastructure steps:** Mock expansion and test localization helper were absent, guaranteeing test-phase failures.
- **CI blind spot:** No guard for core→features imports meant the DeepLinkService refactor could succeed but future violations would go undetected.
- **Redundancy:** Standalone `dart fix` phase was a no-op after lint migration phase already ran it.
- **Ambiguity:** "if VM exists" conditional in Phase 5.4 was resolvable at plan time (VM exists).
- **Missing mandatory skill:** View decomposition phases lacked `Skill: audit` per Planner §4.1.

### 7. Residual Risks

- `very_good_analysis` issue count is unknown until Phase 2.1 — may trigger deferral.
- Sealed `ViewState<T>` ergonomics are unknown until Phase 4.2 — decision gate at 4.5.
- `booking_view_model.dart` at 820 lines is borderline — extraction map may reveal less than expected.
- Coverage target of 45% depends on VM tests providing sufficient line coverage — services/views may remain uncovered.
- DeepLinkService refactor changes navigation timing — deep link race conditions possible.

END.
