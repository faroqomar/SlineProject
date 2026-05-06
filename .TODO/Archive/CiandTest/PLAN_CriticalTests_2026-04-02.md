# Plan: Phase C — Critical Tests

> **Revision:** v2 — Rewritten after @PlanCritic audit (2026-04-02)

---

# @PlanCritic Audit Report

## A) Assumptions + Decision Needed (Blocking)

### Assumptions

1. **Team size = 1 developer** executing via Claude Code agents.
2. **No real Supabase instance** needed — all tests are pure unit tests with mocks.
3. **Flutter SDK 3.8.1** — same as CI.
4. **mocktail** is the mocking library (not mockito).
5. **Baseline: 400 tests pass, 0 analyze issues** — from Phase B completion.
6. **`fakeAsync` from `package:fake_async`** is available (Flutter test dependency).

### Decision Needed (Blocking)

#### Decision 1: WalletVM and ChatVM Mock Strategy

**What:** WalletViewModel and ChatViewModel create internal services in their constructors from `SupabaseClient`. You cannot inject mock services directly — only a mock client.

**Options:**
1. **Mock at SupabaseClient level** — pass `MockSupabaseClient`, configure `.from()`, `.rpc()`, `.auth` chains. Pro: zero production changes. Con: brittle, verbose; leaks service internals; hard to verify which service method was called.
2. **Refactor constructors to accept optional services** — add `{WalletRepository? repo, AccountGuardService? accountGuardService}` to WalletVM; add `{ChatRepository? repo, AccountGuardService? accountGuardService, DirectOffersService? directOffersService}` to ChatVM. Pro: clean DI, matches BookingVM/DashboardVM pattern. Con: production code change (but additive-only — existing callers unaffected).
3. **Hybrid** — mock at client level for Wallet, refactor for Chat (3 nested services).

**Recommended:** Option 2. BookingVM and DashboardVM already use this pattern. The change is additive (optional params with defaults). Client-level mocking for ChatVM's 3 nested services would produce 100+ lines of mock config per test.

**Impact on plan:** Adds a dedicated Phase 1 for constructor refactoring BEFORE VM tests.

#### Decision 2: DashboardVM Auto-Loads on Construction

**What:** DashboardVM calls `_loadCachedRole()`, `_syncRoleFromBackend()`, and `_loadOverviewData()` in its constructor. All mocks must be pre-configured BEFORE construction.

**Options:**
1. **Pre-configure all mocks with defaults in setUp** — verbose but works.
2. **Add a `DashboardViewModel.lazy()` constructor** that skips auto-loading — production code change.

**Recommended:** Option 1. DashboardVM already has good DI. Pre-configuring defaults is the established pattern (booking_view_model_test.dart does this).

**Impact on plan:** Adds explicit "default mock configuration" step to Dashboard test setup.

---

## B) Gate Status

### Gate 0: Test Infrastructure Gate — FAIL

**Reasons:**
- Original plan had no dedicated phase for constructor refactoring (WalletVM, ChatVM)
- No step to create shared mock classes used by multiple test files
- No step to verify `RoleSwitchCoordinator().clearForTesting()` works
- No `fakeAsync` strategy for ChatVM's 500ms debounce timer

**Fix:** Add Phase 1 (Test Infrastructure) with constructor refactoring, shared mock creation, singleton reset verification, and timer testing strategy.

### Gate 1: Data / Contracts Gate — PASS

- DTO tests cover field mapping, null defaults, enum fallback, type coercion
- No schema changes needed

### Gate 2: Security / RLS Gate — PASS (N/A)

- Phase C is test-only — no security surface changes

### Gate 3: Backend / Supabase Gate — PASS (N/A)

- No backend changes

### Gate 4: UI / Integration Gate — PASS (N/A)

- No UI changes

### Gate 5: Release / QA Gate — FAIL

**Reasons:**
- No step to verify constructor refactoring doesn't break existing tests/providers
- No baseline verification gate between refactoring and new test writing
- No explicit ordering: refactor -> verify baseline -> write new tests

**Fix:** Add baseline verification gate after constructor refactoring.

---

## C) Critical Gaps (Must-Fix)

### Gap 1: No Constructor Refactoring Phase

**Gap:** WalletVM and ChatVM cannot be meaningfully unit-tested without injecting mock services.
**Why it will break:** Client-level mocking for ChatVM's 3 nested services = 100+ lines of brittle mock config per test.
**Fix:** Add Phase 1: refactor constructors to accept optional service params. Verify baseline passes after.
**Owner:** @Architect
**Acceptance check:** Constructors accept optional services. All 400 existing tests pass. Analyze clean.

### Gap 2: RoleSwitchCoordinator Singleton Pollution

**Gap:** ChatVM and DashboardVM register with `RoleSwitchCoordinator()` (static singleton) in constructors.
**Why it will break:** Tests creating multiple VMs without cleanup accumulate stale references. Subsequent tests fail non-deterministically.
**Fix:** Add `RoleSwitchCoordinator().clearForTesting()` to `tearDown` in every Chat/Dashboard test group. Method exists at line 139-143.
**Owner:** @Architect
**Acceptance check:** Each test group has tearDown with `vm.dispose()` + `RoleSwitchCoordinator().clearForTesting()`.

### Gap 3: ChatVM teardownForRoleSwitch Calls Supabase.instance

**Gap:** `teardownForRoleSwitch()` at line 119 calls `Supabase.instance.client.removeAllChannels()`.
**Why it will break:** In tests, Supabase.instance may not be initialized. The code has a try-catch for both Exception and Error — it won't crash but will log warnings.
**Fix:** After constructor refactor, verify teardown doesn't crash in tests. Warning logs are acceptable (already caught). Document as known noise.
**Owner:** @Architect
**Acceptance check:** teardownForRoleSwitch() does not crash in tests.

### Gap 4: DashboardVM Auto-Loads in Constructor

**Gap:** All mocks must be pre-configured BEFORE DashboardVM construction.
**Why it will break:** Any unconfigured mock → `MissingStubError` from mocktail during construction.
**Fix:** Add explicit default stub list in setUp: `fetchUserRole()`, `fetchWorkItems()`, `fetchActivityFeed()`, `fetchCounters()`, cache methods.
**Owner:** @Architect
**Acceptance check:** VM constructs without `MissingStubError`.

### Gap 5: No Shared Mock File

**Gap:** `MockAccountGuardService` needed by 3 test files. `MockDirectOffersService` needed by 2.
**Why it will break:** Won't crash, but creates maintenance burden — duplicate mock definitions.
**Fix:** Create `test/helpers/mock_services.dart` for mocks used by 2+ test files. Update `helpers.dart` barrel.
**Owner:** @Architect
**Acceptance check:** Shared mock file exists, imported by WalletVM/ChatVM/DashboardVM tests.

---

## D) Invariants & Success Criteria (Non-Negotiable)

| # | Invariant | How to Enforce | How to Verify |
|---|-----------|---------------|---------------|
| 1 | No test calls `Supabase.instance` directly | Code review; grep | `grep -rn 'Supabase\.instance' test/unit/` returns 0 matches (excluding helpers) |
| 2 | No test depends on network | All service calls mocked | Tests pass in CI (no network) |
| 3 | Every test file follows naming convention | `*_test.dart` suffix | `flutter test` discovers all |
| 4 | Constructor refactoring is backwards-compatible | Optional params with defaults | `main.dart` compiles unchanged |
| 5 | No existing test weakened | No `expect` removals, no `skip` additions | Diff review shows only additions |
| 6 | `flutter analyze` stays clean | Run in QA phase | Exit code 0 |
| 7 | RoleSwitchCoordinator cleaned between tests | `clearForTesting()` in tearDown | No cross-test pollution |
| 8 | Contract nullability matches DB nullability | DTO tests verify null handling | Each model test has "missing fields" case |

---

## E) Risk Register

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|------|-------|------------|--------|--------------|-------------|-----------|----------|
| Constructor refactor breaks provider setup in `main.dart` | Phase 1 | LOW | HIGH | All providers | `flutter analyze` + `flutter test` | Optional params with same defaults | Revert, fall back to client-level mocking |
| ChatVM test flakes from 500ms debounce timer | Phase 5 | MEDIUM | LOW | Single test | Non-deterministic failures | Use `fakeAsync` | `skip:` with TODO |
| DashboardVM test flakes from async init | Phase 6 | MEDIUM | MEDIUM | Dashboard suite | `MissingStubError` in setUp | Pre-configure ALL stubs | Add init guard |
| Singleton leaks between tests | Phase 5, 6 | HIGH | HIGH | Chat + Dashboard suites | Random CI failures | `clearForTesting()` in tearDown | `setUpAll` reset |
| Mock setup too verbose for ChatVM | Phase 5 | MEDIUM | MEDIUM | Dev productivity | 500+ line test file | Constructor refactor (Gap 1) | Accept verbose mocks |

---

## F) Pre-Mortem

1. **This fails when** the executor skips constructor refactoring and tries client-level mocking for WalletVM — produces brittle chains that break on any query change.
2. **This fails when** `RoleSwitchCoordinator().clearForTesting()` is forgotten in tearDown and Chat+Dashboard tests pollute each other.
3. **This fails when** DashboardVM tests don't pre-configure ALL stubs before construction, causing `MissingStubError`.
4. **This fails when** "core slices only" is treated as "test every method" — test file balloons to 1000+ lines.
5. **This fails when** ChatVM's `teardownForRoleSwitch()` warning log is mistaken for a real error and hours are wasted debugging.
6. **This fails when** DTO tests use `{'taskId': ...}` instead of `{'task_id': ...}` — test passes but doesn't match real DB.
7. **This fails when** extending existing model tests accidentally modifies an `expect` assertion, breaking the baseline.
8. **This fails when** `fakeAsync` is not used for ChatVM's debounce timer and tests become timing-dependent.
9. **This fails when** shared mock file isn't added to `helpers.dart` barrel export and imports fail.
10. **This fails when** only individual test files are run during dev but the full suite is never run, missing singleton pollution.

---

## G) Plan Fixes

### Fix 1: Add Phase 1 — Test Infrastructure

**Goal:** Make WalletVM/ChatVM testable. Create shared mocks. Verify baseline.
**Why:** Current constructors create services internally.
**How:** Add optional service params. Create mock file. Run full suite.
**Output:** Modified constructors. `test/helpers/mock_services.dart`. Green baseline.
**Stop condition:** 400 tests pass. Analyze clean. Constructors accept optional services.

### Fix 2: Add Baseline Verification Gate

**Goal:** Ensure refactoring didn't break anything before new tests.
**Why:** Regressions from refactoring would corrupt all subsequent work.
**How:** `flutter test` + `flutter analyze` + `dart format` after refactoring.
**Output:** Green CI locally.
**Stop condition:** 400 pass, 0 issues, format clean.

### Fix 3: Singleton Cleanup in Test Template

**Goal:** Prevent singleton pollution.
**Why:** ChatVM/DashboardVM register with static singleton on construction.
**How:** `tearDown(() { vm.dispose(); RoleSwitchCoordinator().clearForTesting(); })`.
**Output:** Cleanup in every Chat/Dashboard tearDown.
**Stop condition:** No cross-test failures.

### Fix 4: Default Mock Configuration for DashboardVM

**Goal:** Prevent MissingStubError from auto-loading constructor.
**Why:** DashboardVM calls 3 load methods in constructor.
**How:** setUp configures 6+ default stubs before VM construction.
**Output:** setUp block with complete default mocks.
**Stop condition:** VM constructs without error.

### Fix 5: fakeAsync for ChatVM Timer Tests

**Goal:** Deterministic debounce timer testing.
**Why:** 500ms debounce on offer status refresh.
**How:** Wrap timer tests in `fakeAsync`.
**Output:** Timer tests are deterministic.
**Stop condition:** Pass on repeated runs.

### Fix 6: Schema Reference in DTO Tests

**Goal:** Ensure test JSON matches actual DB column names.
**Why:** Test using wrong column names passes but doesn't reflect reality.
**How:** Each DTO test has schema reference comment. All JSON uses snake_case.
**Output:** Schema ref comments in each test file.
**Stop condition:** All fromJson fixtures use snake_case matching DB.

---

# Corrected Plan (Execution-Ready)

## 1) Goal

- **Goal:** Cover dangerous untested zones with unit tests (ViewModels) and DTO parsing tests for business-critical paths: auth, wallet, chat, dashboard, payment, and data-layer contracts.
- **Why:** Phases A/B locked gates and exposed bugs. Phase C adds regression coverage for the riskiest code before hardening (Phase D). Financial, auth, and communication code without tests is a liability.
- **Result:** 5 ViewModel test suites + 7 new model test files + 4 model test extensions. All pass in CI. No network dependency.

---

## 2) Scope

### In-Scope

- **C1:** `AuthSessionViewModel` unit tests
- **C2:** `WalletViewModel` unit tests (requires constructor refactor)
- **C3:** `TenderPaymentViewModel` unit tests
- **C4:** `ChatViewModel` unit tests (requires constructor refactor)
- **C5:** `DashboardViewModel` unit tests — core slices only
- **C6:** DTO parsing / model mapping tests
- **Infra:** Constructor refactoring for WalletVM/ChatVM. Shared mock file. Singleton cleanup strategy.

### Out-of-Scope

- Widget tests, integration tests, golden files
- Tests requiring real Supabase
- God-file decomposition, crash reporting (Phase D)
- SearchVM, SavedTasksVM, remaining P2 ViewModels
- pgTAP tests, coverage threshold enforcement (Phase D)
- `very_good_analysis` migration (Phase E)

---

## 3) Evidence & Findings (From Scan)

### Existing

- **87 test files** (56 unit, 21 widget, 10 integration). **9 of 26 VMs tested** (35%).
- **Test infra:** mocktail mocks (`MockSupabaseClient`, `MockGoTrueClient`, `MockUser`, `MockSession`), fixtures, helpers, `supabase_test_helper.dart`.
- **RoleSwitchCoordinator has `clearForTesting()`** (line 139-143).
- **DashboardVM has excellent DI** — all 5 deps injectable.
- **TenderPaymentVM has perfect DI** — coordinator injected.
- **AuthSessionVM has good DI** — both deps injectable.
- **BookingVM pattern is the template** — accepts `repo`, `chatRepository`, `paymentService` in constructor.

### Missing

- **WalletVM/ChatVM lack service-level DI** — only accept `SupabaseClient?`.
- **No shared mock file** for cross-test mocks.
- **No `fakeAsync` usage** in current test suite.
- **7 critical models untested.** 4 existing model tests lack edge cases.

### Must NOT Duplicate

- Existing model tests (T23-T33) — extend only.
- Existing service tests — VM tests complement.
- `auth_repository_test.dart` — VM test builds on top.

### Conflicts / Risks

- **Constructor refactoring** must not break `main.dart` (all params optional with defaults).
- **RoleSwitchCoordinator singleton** persists across tests — must clear in tearDown.
- **ChatVM.teardownForRoleSwitch()** calls `Supabase.instance.client.removeAllChannels()` — caught by try-catch.
- **DashboardVM auto-loads in constructor** — all mocks must be pre-configured.
- **ChatVM 500ms debounce timer** — needs `fakeAsync` for deterministic tests.

---

## 4) System Impact Map

- **UI:** None
- **MVVM / App Logic:** Additive constructor changes to WalletVM and ChatVM (optional params with defaults). Zero behavior change.
- **Database:** None
- **RLS / Security:** None
- **RPC / Edge Functions:** None
- **Storage:** None
- **Realtime / Notifications:** Tests mock realtime — no production impact
- **Observability:** None
- **Compatibility & Migration:** Constructor changes backwards-compatible
- **Contracts:** DTO tests lock current model contracts

---

## 5) Agent Map

| Phase | Owner(s) | Focus |
|-------|----------|-------|
| 0 | `@SlinePlanner`, `@Sentinel` | Preconditions |
| 1 | `@Architect`, `@Sentinel` | Test infrastructure & constructor refactoring |
| 2 | `@Architect`, `@Sentinel` | AuthSessionViewModel tests |
| 3 | `@Architect`, `@Sentinel` | WalletViewModel tests |
| 4 | `@Architect`, `@Sentinel` | TenderPaymentViewModel tests |
| 5 | `@Architect`, `@Sentinel` | ChatViewModel tests |
| 6 | `@Architect`, `@Sentinel` | DashboardViewModel tests |
| 7 | `@Architect`, `@APIContract`, `@Sentinel` | DTO / model mapping tests |
| 8 | `@Sentinel`, `@CodeGuard` | Final QA & CI verification |
| 9 | `@SlineDocs` | Documentation sync |

---

## Phase 0: Preconditions & Gates

**Primary Agent(s):** `@SlinePlanner`, `@Sentinel`

**Goal:** Lock scope, acceptance criteria, verify readiness.
**Why:** Prevent ambiguous "done" criteria.
**How:** Define measurable criteria, confirm file locations, verify existing helpers.
**Result:** Unambiguous definition of done.

### 0.1 Spec Lock

**Primary Agent(s):** `@Sentinel`, `@Architect`

- [ ] (`@Sentinel`) Define acceptance criteria:
  - All 5 new ViewModel test suites pass (`flutter test` exit 0)
  - All new DTO tests pass
  - No existing tests broken (400 baseline preserved)
  - No test depends on network or real Supabase
  - Each VM test covers: construction, happy path, error states, loading transitions, dispose/cleanup
  - Each DTO test covers: happy path fromJson, null defaults, unknown enum fallback, round-trip where toJson exists
  - `flutter analyze` remains clean
  - CI pipeline passes
- [ ] (`@Architect`) Confirm new test file locations:
  - `test/unit/auth/auth_session_view_model_test.dart` (NEW)
  - `test/unit/wallet/wallet_view_model_test.dart` (NEW)
  - `test/unit/tasks/tender_payment_view_model_test.dart` (NEW)
  - `test/unit/chat/chat_view_model_test.dart` (NEW)
  - `test/unit/dashboard/dashboard_view_model_test.dart` (NEW)
  - `test/unit/models/user_profile_test.dart` (NEW)
  - `test/unit/models/profile_model_test.dart` (NEW)
  - `test/unit/models/conversation_model_test.dart` (NEW)
  - `test/unit/models/chat_offer_payload_test.dart` (NEW)
  - `test/unit/models/wallet_balance_model_test.dart` (NEW)
  - `test/unit/models/wallet_activity_model_test.dart` (NEW)
  - `test/unit/models/direct_offer_model_test.dart` (NEW)
  - `test/helpers/mock_services.dart` (NEW)
  - Extend: 4 existing model test files
- [ ] (`@SlineDocs`) Confirm authoritative docs:
  - `.TODO/AUDIT_Quality_Architecture_2026-04-01.md` — Phase C definition
  - `Sline_everything/SUPABASE_SETUP.md` — table schemas for DTO column name validation
- **GATE CHECK:** Scope, acceptance, files, and docs explicit.

### 0.2 Test Infrastructure Assessment

**Primary Agent(s):** `@Architect`, `@Sentinel`

- [ ] (`@Architect`) Verify existing mock helpers sufficient:
  - `test/helpers/mock_supabase.dart` — MockSupabaseClient, MockGoTrueClient, MockUser, MockSession
  - `test/helpers/mock_supabase_rpc.dart` — RPC mocking
  - `test/fixtures/` — profiles, booking, chat, tender fixtures
  - `test/supabase_test_helper.dart` — ensureSupabaseTestEnvironment()
- [ ] (`@Architect`) Confirm `RoleSwitchCoordinator().clearForTesting()` exists (line 139-143).
- [ ] (`@Architect`) List NEW mocks needed:
  - **Shared (`test/helpers/mock_services.dart`):** MockWalletRepository, MockAccountGuardService, MockChatRepository, MockDirectOffersService, MockDashboardRepository, MockDashboardCacheService, MockBookingService, MockTaskService
  - **Colocated:** MockAuthRepository, MockTenderPaymentCoordinator
- [ ] (`@Sentinel`) Confirm no infrastructure gap blocks Phase C.
- **GATE CHECK:** Mocks identified. Infrastructure ready or has creation plan.

---

## Phase 1: Test Infrastructure & Constructor Refactoring

**Primary Agent(s):** `@Architect`, `@Sentinel`

**Goal:** Make WalletVM/ChatVM testable via service injection. Create shared mocks. Verify baseline.
**Why:** WalletVM creates WalletRepository + AccountGuardService internally. ChatVM creates ChatRepository + AccountGuardService + DirectOffersService internally. Cannot inject mocks without constructor changes. BookingVM and DashboardVM already use the injectable pattern.
**How:** Add optional service parameters. Create shared mock file. Run full suite.
**Result:** Refactored constructors. Shared mock file. Green baseline.

### 1.1 Refactor WalletViewModel Constructor

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Read current constructor (lines 10-18 of `wallet_view_model.dart`).
- [ ] (`@Architect`) Refactor to accept optional `WalletRepository? repo` and `AccountGuardService? accountGuardService`:
  ```dart
  WalletViewModel({
    WalletRepository? repo,
    AccountGuardService? accountGuardService,
    SupabaseClient? client,
  }) : _repo = repo ?? WalletRepository(client ?? Supabase.instance.client),
       _accountGuardService = accountGuardService ?? AccountGuardService(client: client ?? Supabase.instance.client);
  ```
- [ ] (`@Architect`) Verify `lib/main.dart` — existing `WalletViewModel()` calls compile unchanged.
- [ ] (`@Architect`) Grep for other `WalletViewModel(` constructors — verify none pass arguments.
- [ ] (`@Sentinel`) Run `flutter analyze` — must be clean.
- **GATE CHECK:** WalletVM constructor accepts optional services. No compilation errors.

### 1.2 Refactor ChatViewModel Constructor

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Read current constructor (lines 34-48 of `chat_view_model.dart`).
- [ ] (`@Architect`) Refactor to accept optional `ChatRepository? repo`, `AccountGuardService? accountGuardService`, `DirectOffersService? directOffersService`:
  ```dart
  ChatViewModel({
    ChatRepository? repo,
    AccountGuardService? accountGuardService,
    DirectOffersService? directOffersService,
    SupabaseClient? client,
  }) {
    _repo = repo ?? ChatRepository(client ?? Supabase.instance.client);
    _accountGuardService = accountGuardService ?? AccountGuardService(client: client ?? Supabase.instance.client);
    _directOffersService = directOffersService ?? DirectOffersService(client ?? Supabase.instance.client);
    RoleSwitchCoordinator().register(this);
  }
  ```
- [ ] (`@Architect`) Change `late final` to `late` for `_repo`, `_accountGuardService`, `_directOffersService` (conditional assignment in body).
- [ ] (`@Architect`) Verify `lib/main.dart` — existing `ChatViewModel()` calls compile unchanged.
- [ ] (`@Architect`) Grep for other `ChatViewModel(` constructors — verify none pass arguments.
- [ ] (`@Sentinel`) Run `flutter analyze` — must be clean.
- **GATE CHECK:** ChatVM constructor accepts optional services. No compilation errors.

### 1.3 Create Shared Mock File

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Create `test/helpers/mock_services.dart`:
  ```dart
  import 'package:mocktail/mocktail.dart';
  // imports for each service/repo

  class MockWalletRepository extends Mock implements WalletRepository {}
  class MockAccountGuardService extends Mock implements AccountGuardService {}
  class MockChatRepository extends Mock implements ChatRepository {}
  class MockDirectOffersService extends Mock implements DirectOffersService {}
  class MockDashboardRepository extends Mock implements DashboardRepository {}
  class MockDashboardCacheService extends Mock implements DashboardCacheService {}
  class MockBookingService extends Mock implements BookingService {}
  class MockTaskService extends Mock implements TaskService {}
  ```
- [ ] (`@Architect`) Update `test/helpers/helpers.dart` barrel to export `mock_services.dart`.
- [ ] (`@Sentinel`) Run `flutter analyze` — must compile.
- **GATE CHECK:** Shared mock file exists and compiles.

### 1.4 Baseline Verification

**Primary Agent(s):** `@Sentinel`

- [ ] (`@Sentinel`) Run `flutter test` — all 400 existing tests must pass.
- [ ] (`@Sentinel`) Run `flutter analyze` — 0 issues.
- [ ] (`@Sentinel`) Run `dart format --set-exit-if-changed .` — clean.
- [ ] (`@Sentinel`) Verify `main.dart` provider registrations compile unchanged.
- **GATE CHECK:** Baseline green. Refactoring caused zero regressions. Safe to write new tests.

---

## Phase 2: AuthSessionViewModel Tests (C1)

**Primary Agent(s):** `@Architect`, `@Sentinel`

**Goal:** Cover login/logout/session lifecycle — broken auth = entire app inaccessible.
**Why:** Zero tests exist. Session management is foundation of entire app.
**How:** Mock AuthRepository + Stream<AuthState>. Test construction, auth events, profile loading, logout, errors, dispose.
**Result:** `test/unit/auth/auth_session_view_model_test.dart`.

### 2.1 Mock Setup

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Create `_MockAuthRepository extends Mock implements AuthRepository` in test file.
- [ ] (`@Architect`) Create `StreamController<AuthState>` for simulating auth state changes.
- [ ] (`@Architect`) Create fixture data: valid UserProfile, AuthState events (signedIn, signedOut, tokenRefreshed, passwordRecovery).
- [ ] (`@Architect`) Pre-configure `authRepo.getCurrentUserProfileWithRetry()` BEFORE VM construction (called in constructor).
- [ ] (`@Architect`) Add tearDown: `viewModel.dispose()`.
- [ ] (`@Sentinel`) Verify setUp completes without error.
- **GATE CHECK:** Mocks ready, VM constructs.

### 2.2 Construction & Initial State Tests

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Test: VM constructs without error.
- [ ] (`@Architect`) Test: `error` initially null.
- [ ] (`@Architect`) Test: `isAuthenticated` correct based on auth stream state.
- [ ] (`@Architect`) Test: `currentUserId` null when no user signed in.
- [ ] (`@Architect`) Test: `currentUserProfile` null before profile loads.
- [ ] (`@Sentinel`) Verify pass.
- **GATE CHECK:** Construction tests green.

### 2.3 Auth State Stream Tests

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Test: `signedIn` → `isAuthenticated` true.
- [ ] (`@Architect`) Test: `signedIn` → `currentUserId` returns user ID.
- [ ] (`@Architect`) Test: `signedIn` triggers profile load (verify repo called).
- [ ] (`@Architect`) Test: `signedOut` → `isAuthenticated` false, profile cleared.
- [ ] (`@Architect`) Test: `tokenRefreshed` → session updated, no profile reload.
- [ ] (`@Architect`) Test: `passwordRecovery` → flag set.
- [ ] (`@Sentinel`) Verify pass.
- **GATE CHECK:** Auth stream covered.

### 2.4 Profile Loading Tests

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Test: Successful load sets `currentUserProfile`, clears loading.
- [ ] (`@Architect`) Test: Load failure sets `error`, triggers `logout()`.
- [ ] (`@Architect`) Test: Uses retry method (`getCurrentUserProfileWithRetry`).
- [ ] (`@Sentinel`) Verify pass.
- **GATE CHECK:** Profile loading covered.

### 2.5 Logout Tests

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Test: `logout()` calls `authRepo.signOut()`.
- [ ] (`@Architect`) Test: `logout()` clears `currentUserProfile`.
- [ ] (`@Architect`) Test: `logout()` handles signOut failure gracefully.
- [ ] (`@Sentinel`) Verify pass.
- **GATE CHECK:** Logout covered.

### 2.6 Error & Session Expiry Tests

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Test: `clearError()` sets error null, notifies listeners.
- [ ] (`@Architect`) Test: `onSessionExpired` consumes flag (true once, then false).
- [ ] (`@Architect`) Test: `onPasswordRecovery` consumes flag.
- [ ] (`@Sentinel`) Verify pass.
- **GATE CHECK:** Error handling covered.

### 2.7 Dispose Tests

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Test: `dispose()` cancels auth stream subscription.
- [ ] (`@Architect`) Test: No crash if auth stream emits after dispose.
- [ ] (`@Sentinel`) Run `flutter test test/unit/auth/auth_session_view_model_test.dart` — all pass.
- **GATE CHECK:** All AuthSessionVM tests pass.

---

## Phase 3: WalletViewModel Tests (C2)

**Primary Agent(s):** `@Architect`, `@Sentinel`

**Goal:** Cover financial data — wrong balance = user trust destroyed.
**Why:** Zero VM tests. Financial code is liability.
**How:** Inject MockWalletRepository + MockAccountGuardService (enabled by Phase 1). Test balance, pagination, withdrawal, dedup, errors.
**Result:** `test/unit/wallet/wallet_view_model_test.dart`.

### 3.1 Mock Setup

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Import shared mocks from `test/helpers/mock_services.dart`.
- [ ] (`@Architect`) Create fixtures: WalletBalanceModel (zero, positive, held), WalletActivityModel list.
- [ ] (`@Architect`) Configure defaults: `repo.getWalletBalance()` → zero, `repo.getActivity()` → [].
- [ ] (`@Architect`) Construct: `WalletViewModel(repo: mockRepo, accountGuardService: mockGuard)`.
- [ ] (`@Architect`) Add tearDown: `viewModel.dispose()`.
- [ ] (`@Sentinel`) Verify setUp clean.
- **GATE CHECK:** Mocks ready, VM constructs.

### 3.2 Balance Loading Tests

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Test: `loadWallet()` fetches balance, sets `balance` field.
- [ ] (`@Architect`) Test: `loadWallet()` fetches activities, populates list.
- [ ] (`@Architect`) Test: `isLoading` true during load, false after.
- [ ] (`@Architect`) Test: `error` null on success.
- [ ] (`@Architect`) Test: `_hasLoadedWallet` flag set.
- [ ] (`@Sentinel`) Verify pass.
- **GATE CHECK:** Balance loading covered.

### 3.3 Deduplication Tests

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Test: Two concurrent `ensureLoaded()` calls → only one `loadWallet()` (verify called(1)).
- [ ] (`@Architect`) Test: `ensureLoaded(forceRefresh: true)` bypasses dedup.
- [ ] (`@Architect`) Test: `_loadingFuture` null after completion.
- [ ] (`@Sentinel`) Verify pass.
- **GATE CHECK:** Dedup verified.

### 3.4 Pagination Tests

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Test: `loadMore()` appends (not replaces) activities.
- [ ] (`@Architect`) Test: `loadMore()` updates cursor.
- [ ] (`@Architect`) Test: `hasMore` false when < 20 items returned.
- [ ] (`@Architect`) Test: `loadMore()` no-op when `hasMore` false.
- [ ] (`@Architect`) Test: `loadMore()` no-op when loading.
- [ ] (`@Sentinel`) Verify pass.
- **GATE CHECK:** Pagination verified.

### 3.5 Withdrawal Tests

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Test: Checks `accountGuardService.canPerformSensitiveAction()` first.
- [ ] (`@Architect`) Test: Guard blocks → false, sets error.
- [ ] (`@Architect`) Test: Success → calls repo, refreshes, returns true.
- [ ] (`@Architect`) Test: `isWithdrawing` flag transitions.
- [ ] (`@Architect`) Test: Failure sets user-friendly error.
- [ ] (`@Architect`) Test: `FormatException` produces distinct message.
- [ ] (`@Sentinel`) Verify pass.
- **GATE CHECK:** Withdrawal covered.

### 3.6 Error & Summary Tests

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Test: `loadWallet()` failure sets error + isLoading false.
- [ ] (`@Architect`) Test: `clearError()` resets.
- [ ] (`@Architect`) Test: `summary` getter valid with zero balance.
- [ ] (`@Sentinel`) Run `flutter test test/unit/wallet/wallet_view_model_test.dart` — all pass.
- **GATE CHECK:** All WalletVM tests pass.

---

## Phase 4: TenderPaymentViewModel Tests (C3)

**Primary Agent(s):** `@Architect`, `@Sentinel`

**Goal:** Cover payment flow — payment = money, zero tolerance.
**Why:** `booking_request_flow_test.dart` is skipped. TenderPaymentVM covers coordinator logic without live gateway.
**How:** Mock TenderPaymentCoordinator. Test submit, recovery, expiry, error mapping.
**Result:** `test/unit/tasks/tender_payment_view_model_test.dart`.

### 4.1 Mock Setup

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Create `_MockTenderPaymentCoordinator` in test file.
- [ ] (`@Architect`) Create fixtures: requestId, taskTitle, freelancerName, amount, paymentDeadline (future + past).
- [ ] (`@Architect`) Add tearDown: `viewModel.dispose()`.
- [ ] (`@Sentinel`) Verify compiles.
- **GATE CHECK:** Mocks ready.

### 4.2 Construction & Getter Tests

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Test: Constructs with required params.
- [ ] (`@Architect`) Test: Initial state — `isProcessing` false, `errorMessage` null, `success` false, `pendingFormUrl` null.
- [ ] (`@Architect`) Test: Getters return constructor values.
- [ ] (`@Architect`) Test: `isExpired` false when deadline future, true when past.
- [ ] (`@Architect`) Test: `timeRemaining` correct Duration.
- [ ] (`@Sentinel`) Verify pass.
- **GATE CHECK:** Construction covered.

### 4.3 Submit Happy Path

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Test: `submit()` sets `isProcessing` true during execution.
- [ ] (`@Architect`) Test: Success sets `success` true.
- [ ] (`@Architect`) Test: Calls coordinator with correct params.
- [ ] (`@Architect`) Test: `isProcessing` false after success.
- [ ] (`@Sentinel`) Verify pass.
- **GATE CHECK:** Happy path covered.

### 4.4 WebView Redirect Tests

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Test: Coordinator returns pendingFormUrl → VM sets url + requestId.
- [ ] (`@Architect`) Test: `hasPendingWebPayment` true.
- [ ] (`@Architect`) Test: `clearPendingWebPayment()` clears state.
- [ ] (`@Sentinel`) Verify pass.
- **GATE CHECK:** WebView flow covered.

### 4.5 Recovery Tests

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Test: `completeRecovery()` calls coordinator with correct IDs.
- [ ] (`@Architect`) Test: Success sets `success` true, clears pending.
- [ ] (`@Architect`) Test: Failure sets `errorMessage`.
- [ ] (`@Sentinel`) Verify pass.
- **GATE CHECK:** Recovery covered.

### 4.6 Error Mapping Tests

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Test: `INVALID_STATE` → user-friendly message.
- [ ] (`@Architect`) Test: `PAYMENT_NOT_SUCCESS` → correct message.
- [ ] (`@Architect`) Test: `PAYMENT_DEADLINE_EXPIRED` → correct message.
- [ ] (`@Architect`) Test: `FORBIDDEN` → correct message.
- [ ] (`@Architect`) Test: `TASK_REQUEST_NOT_FOUND` → correct message.
- [ ] (`@Architect`) Test: Unknown exception → fallback message.
- [ ] (`@Architect`) Test: `isProcessing` false after any error.
- [ ] (`@Sentinel`) Run full test file — all pass.
- **GATE CHECK:** All TenderPaymentVM tests pass.

---

## Phase 5: ChatViewModel Tests (C4)

**Primary Agent(s):** `@Architect`, `@Sentinel`

**Goal:** Cover core communication logic — highest daily usage.
**Why:** 767 lines, zero VM tests. Most-used feature.
**How:** Inject mocks via refactored constructor. Use `fakeAsync` for timer. Focus on core ops.
**Result:** `test/unit/chat/chat_view_model_test.dart`.

### 5.1 Mock Setup & Singleton Management

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Import shared mocks: MockChatRepository, MockDirectOffersService, MockAccountGuardService.
- [ ] (`@Architect`) Create fixtures using `chat_fixtures.dart`.
- [ ] (`@Architect`) Configure default mocks:
  - `chatRepo.fetchConversations()` → `[]`
  - `chatRepo.fetchMessages(any())` → `[]`
  - `chatRepo.subscribeToMessages(any())` → `Stream.empty()`
  - `chatRepo.subscribeToAllInboxMessages()` → `Stream.empty()`
  - `chatRepo.subscribeToPresence(any(), any())` → `Stream.empty()`
- [ ] (`@Architect`) Construct: `ChatViewModel(repo: mockRepo, accountGuardService: mockGuard, directOffersService: mockOffers)`.
- [ ] (`@Architect`) **CRITICAL tearDown:**
  ```dart
  tearDown(() {
    viewModel.dispose();
    RoleSwitchCoordinator().clearForTesting();
  });
  ```
- [ ] (`@Sentinel`) Verify setUp completes. Verify tearDown clears singleton.
- **GATE CHECK:** Mocks ready, VM constructs, singleton handled.

### 5.2 Conversation CRUD Tests

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Test: `fetchConversations()` populates list.
- [ ] (`@Architect`) Test: `fetchConversations()` sets `isLoadingConversations`.
- [ ] (`@Architect`) Test: `fetchConversations()` error sets state, doesn't crash.
- [ ] (`@Architect`) Test: `createOrGetConversation()` returns existing.
- [ ] (`@Architect`) Test: `createOrGetConversation()` creates new via repo.
- [ ] (`@Architect`) Test: `createOrGetConversation()` sets `isCreatingConversation`.
- [ ] (`@Architect`) Test: `createOrGetConversation()` maps errors via `_mapConversationError()`.
- [ ] (`@Architect`) Test: `deleteConversation()` removes from list, calls repo.
- [ ] (`@Sentinel`) Verify pass.
- **GATE CHECK:** Conversation CRUD covered.

### 5.3 Message Tests

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Test: `fetchMessages()` populates `currentMessages`.
- [ ] (`@Architect`) Test: `fetchMessages()` sets `isLoadingMessages`.
- [ ] (`@Architect`) Test: `sendMessage()` calls repo.
- [ ] (`@Architect`) Test: `sendMessage()` sets `isSending`.
- [ ] (`@Architect`) Test: `sendMessage()` error sets state.
- [ ] (`@Sentinel`) Verify pass.
- **GATE CHECK:** Messages covered.

### 5.4 Offer Action Tests (Core Only)

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Test: `createDirectOffer()` calls service.
- [ ] (`@Architect`) Test: `acceptOffer()` calls service, triggers refresh.
- [ ] (`@Architect`) Test: Offer action failure sets error.
- [ ] (`@Architect`) Note: Do NOT test every variant (reject, cancel, markDelivered, complete). Same pattern. Test one success + one failure.
- [ ] (`@Sentinel`) Verify pass.
- **GATE CHECK:** Offer core covered.

### 5.5 Realtime Subscription Lifecycle

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Test: `subscribeToActiveConversation()` calls repo.
- [ ] (`@Architect`) Test: `unsubscribeFromConversation()` cancels.
- [ ] (`@Architect`) Test: `subscribeToUserConversations()` calls repo.
- [ ] (`@Architect`) Test: `unsubscribeFromUserConversations()` cancels.
- [ ] (`@Architect`) Test: Double subscribe cancels first before re-subscribing.
- [ ] (`@Sentinel`) Verify pass.
- **GATE CHECK:** Realtime lifecycle covered.

### 5.6 Role Switch Teardown Tests

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Test: `teardownForRoleSwitch()` clears conversations.
- [ ] (`@Architect`) Test: Clears currentMessages.
- [ ] (`@Architect`) Test: Resets activeConversation to null.
- [ ] (`@Architect`) Test: Resets loading flags.
- [ ] (`@Architect`) Test: Does not crash (Supabase.instance try-catch handles it).
- [ ] (`@Sentinel`) Verify pass.
- **GATE CHECK:** Role switch teardown verified.

### 5.7 Error Mapping & Dispose Tests

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Test: `_mapConversationError()` maps at least 3 representative errors to user-friendly strings.
- [ ] (`@Architect`) Test: `dispose()` sets `_mounted` false, cancels subscriptions.
- [ ] (`@Architect`) Test: `_notify()` does NOT call `notifyListeners()` after `_mounted` false.
- [ ] (`@Sentinel`) Run full test file — all pass.
- **GATE CHECK:** All ChatVM tests pass.

### 5.8 Timer / Debounce Tests (If Applicable)

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Identify if any test in 5.2-5.7 is affected by 500ms debounce.
- [ ] (`@Architect`) If yes: wrap in `fakeAsync`, use `async.elapse(Duration(milliseconds: 500))`.
- [ ] (`@Architect`) If no: skip this sub-phase, note "timer not exercised — debounce is implementation detail."
- [ ] (`@Sentinel`) Verify no timing flakes.
- **GATE CHECK:** Timer deterministic or scoped out.

---

## Phase 6: DashboardViewModel Tests (C5)

**Primary Agent(s):** `@Architect`, `@Sentinel`

**Goal:** Cover core slices — role switch, refresh, tab loading, dispose safety.
**Why:** 1149 lines, untested, main screen. Don't test everything — test dangerous core.
**How:** Inject all 5 mocks. Pre-configure defaults for auto-loading constructor. Focus on core.
**Result:** `test/unit/dashboard/dashboard_view_model_test.dart`.

### 6.1 Mock Setup & Default Configuration

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Import shared mocks.
- [ ] (`@Architect`) **CRITICAL: Configure ALL default stubs BEFORE VM construction:**
  ```dart
  setUp(() {
    mockRepo = MockDashboardRepository();
    mockCache = MockDashboardCacheService();
    mockTaskService = MockTaskService();
    mockBookingService = MockBookingService();
    mockOffersService = MockDirectOffersService();

    when(() => mockRepo.fetchUserRole()).thenAnswer((_) async => UserRole.freelancer);
    when(() => mockRepo.fetchWorkItems(any())).thenAnswer((_) async => []);
    when(() => mockRepo.fetchActivityFeed()).thenAnswer((_) async => []);
    when(() => mockRepo.fetchCounters(workItems: any(named: 'workItems'), inboxOffers: any(named: 'inboxOffers')))
        .thenAnswer((_) async => const DashboardCounters());
    when(() => mockRepo.updateUserRole(any())).thenAnswer((_) async {});
    when(() => mockCache.getCachedRole()).thenReturn(null);
    when(() => mockCache.cacheRole(any())).thenAnswer((_) async {});
    when(() => mockCache.getCachedOverview()).thenReturn(null);
    when(() => mockCache.cacheOverview(any())).thenAnswer((_) async {});

    viewModel = DashboardViewModel(
      repository: mockRepo, cacheService: mockCache,
      taskService: mockTaskService, bookingService: mockBookingService,
      directOffersService: mockOffersService,
    );
  });
  ```
- [ ] (`@Architect`) **CRITICAL tearDown:**
  ```dart
  tearDown(() {
    viewModel.dispose();
    RoleSwitchCoordinator().clearForTesting();
  });
  ```
- [ ] (`@Sentinel`) Verify VM constructs without MissingStubError.
- **GATE CHECK:** Mocks complete, VM constructs.

### 6.2 Construction & Role Loading Tests

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Test: VM constructs without error.
- [ ] (`@Architect`) Test: Default role is `UserRole.freelancer`.
- [ ] (`@Architect`) Test: Default tab is `DashboardTab.overview`.
- [ ] (`@Architect`) Test: Construction calls `fetchUserRole()` (verify called).
- [ ] (`@Architect`) Test: Cache returns role → currentRole set immediately.
- [ ] (`@Architect`) Test: Backend returns different role → currentRole updates.
- [ ] (`@Sentinel`) Verify pass.
- **GATE CHECK:** Construction + role loading covered.

### 6.3 Role Switch Tests

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Test: `setRole(UserRole.client)` calls `repository.updateUserRole()`.
- [ ] (`@Architect`) Test: Role switch triggers data refresh (verify fetch calls).
- [ ] (`@Architect`) Test: Role switch clears work items + activity feed.
- [ ] (`@Architect`) Test: Role switch resets lazy-load flags.
- [ ] (`@Sentinel`) Verify pass.
- **GATE CHECK:** Role switching covered.

### 6.4 Data Loading & Refresh Tests

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Test: `refresh()` calls repo for work items, activity, counters.
- [ ] (`@Architect`) Test: Refresh failure sets error state.
- [ ] (`@Architect`) Test: Work items populated after success.
- [ ] (`@Sentinel`) Verify pass.
- **GATE CHECK:** Refresh covered.

### 6.5 Tab Lazy-Loading Tests

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Test: Overview loads on init (verify in construction calls).
- [ ] (`@Architect`) Test: Bookings NOT loaded until `setTab(DashboardTab.bookings)`.
- [ ] (`@Architect`) Test: First Bookings switch triggers load (verify service called).
- [ ] (`@Architect`) Test: Subsequent Bookings switches don't re-fetch (called once).
- [ ] (`@Architect`) Test: Inbox lazy-loads similarly.
- [ ] (`@Architect`) Test: `refresh()` resets lazy-load flags.
- [ ] (`@Sentinel`) Verify pass.
- **GATE CHECK:** Lazy-loading covered.

### 6.6 Dispose Safety Tests

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Test: `dispose()` sets `_isDisposed` (verified via _safeNotify behavior).
- [ ] (`@Architect`) Test: No crash if `refresh()` completes after dispose.
- [ ] (`@Architect`) Test: `_abortIfDisposed()` returns true after dispose.
- [ ] (`@Sentinel`) Run full test file — all pass.
- **GATE CHECK:** All DashboardVM tests pass.

---

## Phase 7: DTO Parsing / Model Mapping Tests (C6)

**Primary Agent(s):** `@Architect`, `@APIContract`, `@Sentinel`

**Goal:** Lock data-layer contracts — data bugs invisible from UI cause cascading failures.
**Why:** Models are contract between Supabase JSON and Dart. Renamed column or new enum = silent crash.
**How:** 7 new test files + 4 extensions. Each references SUPABASE_SETUP.md. Covers happy path, nulls, enums, coercion, round-trip.
**Result:** All critical models tested.

### 7.1 UserProfile

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Create `test/unit/models/user_profile_test.dart`. Add schema ref comment.
- [ ] (`@Architect`) Test: `fromMap()` parses all fields (snake_case keys).
- [ ] (`@Architect`) Test: Only `id` required — all others nullable.
- [ ] (`@Architect`) Test: `forceLogoutAfterUtc` is UTC.
- [ ] (`@Architect`) Test: `toMap()` round-trip + snake_case keys.
- [ ] (`@Sentinel`) Verify pass.
- **GATE CHECK:** UserProfile pass.

### 7.2 ProfileModel

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Create `test/unit/models/profile_model_test.dart`. Schema ref.
- [ ] (`@Architect`) Test: Parses all fields.
- [ ] (`@Architect`) Test: Defaults — activeRole='client', accountStatus='active', skills=[].
- [ ] (`@Architect`) Test: Partial JSON — no crash.
- [ ] (`@Architect`) Test: DateTimes are UTC.
- [ ] (`@Architect`) Test: `toJson()` snake_case. `copyWith()` works.
- [ ] (`@Sentinel`) Verify pass.
- **GATE CHECK:** ProfileModel pass.

### 7.3 Conversation (Highest Priority DTO)

**Primary Agent(s):** `@Architect`, `@APIContract`

- [ ] (`@Architect`) Create `test/unit/models/conversation_model_test.dart`. Schema ref.
- [ ] (`@APIContract`) Test: `last_message` as Map — extracts content, created_at, sender_id, seen_at.
- [ ] (`@APIContract`) Test: `last_message` as List — takes `.last`.
- [ ] (`@APIContract`) Test: `last_message` as empty List — all null.
- [ ] (`@APIContract`) Test: `last_message` as null — all null.
- [ ] (`@Architect`) Test: `taskTitle` prefers flat, falls back to nested `tasks['title']`.
- [ ] (`@Architect`) Test: `otherUserTyping` defaults false.
- [ ] (`@Architect`) Test: `presenceUpdatedAt` handles null.
- [ ] (`@Architect`) Test: `copyWith()` preserves presence fields.
- [ ] (`@Architect`) Test: `toJson()` correct structure.
- [ ] (`@Sentinel`) Verify pass.
- **GATE CHECK:** Conversation pass.

### 7.4 ChatOfferPayload

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Create `test/unit/models/chat_offer_payload_test.dart`. Schema ref.
- [ ] (`@Architect`) Test: Parses price, days, title, description, status.
- [ ] (`@Architect`) Test: `price` type coercion (int, num, String).
- [ ] (`@Architect`) Test: `days` prefers 'days' over legacy 'delivery'.
- [ ] (`@Architect`) Test: Both missing → days=0.
- [ ] (`@Architect`) Test: `status` defaults 'pending'.
- [ ] (`@Architect`) Test: `toMap()` writes 'days' not 'delivery'.
- [ ] (`@Sentinel`) Verify pass.
- **GATE CHECK:** ChatOfferPayload pass.

### 7.5 WalletBalanceModel

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Create `test/unit/models/wallet_balance_model_test.dart`. Schema ref.
- [ ] (`@Architect`) Test: Parses 3 fields. All default 0 when missing. `zero()` factory. Snake_case keys.
- [ ] (`@Sentinel`) Verify pass.
- **GATE CHECK:** WalletBalanceModel pass.

### 7.6 WalletActivityModel

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Create `test/unit/models/wallet_activity_model_test.dart`. Schema ref.
- [ ] (`@Architect`) Test: Parses 10 fields. Numeric defaults 0. Currency defaults 'IQD'. createdAtUtc is UTC. Nullable fields handle null. Snake_case keys.
- [ ] (`@Sentinel`) Verify pass.
- **GATE CHECK:** WalletActivityModel pass.

### 7.7 DirectOffer

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Create `test/unit/models/direct_offer_model_test.dart`. Schema ref.
- [ ] (`@Architect`) Test: Parses all 22 fields.
- [ ] (`@Architect`) Test: `price`/`days`/`feeRateAppliedBps` type coercion.
- [ ] (`@Architect`) Test: `status` defaults 'sent', `paymentStatus` defaults 'unpaid'.
- [ ] (`@Architect`) Test: 8 nullable DateTimes handle null.
- [ ] (`@Architect`) Test: Computed getters (isSent, isActive, isCompleted, etc.).
- [ ] (`@Architect`) Test: Snake_case keys.
- [ ] (`@Sentinel`) Verify pass.
- **GATE CHECK:** DirectOffer pass.

### 7.8 Extend BookingModel

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Extend `test/unit/models/booking_model_test.dart` (add new group, don't modify existing).
- [ ] (`@Architect`) Test: Minimal JSON. Unknown status → pending. paymentStatus null → unpaid. dueAtUtc fallback chain. Round-trip each BookingStatus. 'cancelled' British → canceled.
- [ ] (`@Sentinel`) Verify existing T26-T27 unbroken.
- **GATE CHECK:** BookingModel extended.

### 7.9 Extend Message

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Extend `test/unit/models/message_model_test.dart`.
- [ ] (`@Architect`) Test: All attachments null — no crash. toJson excludes nulls. attachmentSize coercion. Round-trip. Each MessageType round-trips.
- [ ] (`@Sentinel`) Verify existing T28-T30 unbroken.
- **GATE CHECK:** Message extended.

### 7.10 Extend Task

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Extend `test/unit/models/task_model_test.dart`.
- [ ] (`@Architect`) Test: Minimal JSON. Each TaskStatus round-trips. Both 'in_progress' and 'inProgress' map correctly. owner_id vs user_id fallback.
- [ ] (`@Sentinel`) Verify existing T23-T25 unbroken.
- **GATE CHECK:** Task extended.

### 7.11 Extend TaskRequest

**Primary Agent(s):** `@Architect`

- [ ] (`@Architect`) Extend `test/unit/models/task_request_model_test.dart`.
- [ ] (`@Architect`) Test: All optional fields missing — no crash. Each OfferStatus round-trips. Unknown → OfferStatus.unknown.
- [ ] (`@Sentinel`) Verify existing T31-T33 unbroken.
- **GATE CHECK:** TaskRequest extended.

### 7.12 Full DTO Verification

**Primary Agent(s):** `@Sentinel`

- [ ] (`@Sentinel`) Run `flutter test test/unit/models/` — all pass.
- [ ] (`@Sentinel`) Confirm no test ID collisions.
- [ ] (`@Sentinel`) Diff existing model tests — only additions.
- **GATE CHECK:** All DTO tests pass.

---

## Phase 8: Final QA & CI Verification (MANDATORY)

**Primary Agent(s):** `@Sentinel`, `@CodeGuard`

**Goal:** Verify everything works together. No regressions. CI-ready.
**Why:** Individual gates verify parts. This verifies the whole.
**How:** Full suite, analysis, format, coverage, regression diff.
**Result:** Green CI. Documented coverage improvement.

### 8.1 Full Test Suite

**Primary Agent(s):** `@Sentinel`

- [ ] (`@Sentinel`) Run `flutter test` — ALL pass.
- [ ] (`@Sentinel`) Record new total test count (> 400 + new).
- [ ] (`@Sentinel`) Confirm 0 new skips.
- [ ] (`@CodeGuard`) Grep test/ for `Supabase.instance` — only in helpers.
- **GATE CHECK:** Full suite green.

### 8.2 Static Analysis & Format

**Primary Agent(s):** `@Sentinel`

- [ ] (`@Sentinel`) Run `flutter analyze` — 0 issues.
- [ ] (`@Sentinel`) Run `dart format --set-exit-if-changed .` — clean.
- **GATE CHECK:** Clean.

### 8.3 Architecture Guard

**Primary Agent(s):** `@CodeGuard`

- [ ] (`@CodeGuard`) Verify constructor refactoring (Phase 1) introduced no architecture violations.
- [ ] (`@Sentinel`) Run CI checks locally: format + analyze + test --coverage.
- **GATE CHECK:** CI would pass.

### 8.4 Coverage Snapshot

**Primary Agent(s):** `@Sentinel`

- [ ] (`@Sentinel`) Generate `flutter test --coverage`.
- [ ] (`@Sentinel`) Record line coverage. Compare to baseline. Document delta.
- **GATE CHECK:** Coverage captured (no threshold — Phase D).

### 8.5 Regression Check

**Primary Agent(s):** `@Sentinel`

- [ ] (`@Sentinel`) Diff 4 extended model test files — only additions, no removals.
- [ ] (`@Sentinel`) Diff WalletVM + ChatVM constructors — only additive optional params.
- [ ] (`@Sentinel`) Confirm 400 baseline tests pass unchanged.
- **GATE CHECK:** No regressions.

---

## Phase 9: Documentation Sync (MANDATORY)

**Primary Agent(s):** `@SlineDocs`

**Goal:** Update audit doc, close session log, align CLAUDE.md.
**Why:** Documentation must reflect reality.
**How:** Mark Phase C done, close log, update counts.
**Result:** All docs aligned.

### 9.1 Audit Document Update

- [ ] (`@SlineDocs`) Update `.TODO/AUDIT_Quality_Architecture_2026-04-01.md`: Mark C1-C6 DONE. Update Section 4.4 + 4.10. Record test count.
- **GATE CHECK:** Audit doc reflects completion.

### 9.2 Session Log Close

- [ ] (`@SlineDocs`) Complete `docs/LOG/SESSION_PLAN_CriticalTests_2026-04-02.md`: dates, summary, agent notes, timeline.
- **GATE CHECK:** Session log closed.

### 9.3 CLAUDE.md Update

- [ ] (`@SlineDocs`) Note constructor injection pattern for WalletVM/ChatVM if noteworthy.
- **GATE CHECK:** CLAUDE.md aligned.

---

## Acceptance Criteria (MANDATORY)

1. All 5 new ViewModel test suites exist and pass
2. All 7 new model test files exist and pass
3. All 4 existing model test files extended and pass
4. Constructor refactoring (WalletVM, ChatVM) is additive-only, no behavior change
5. Shared mock file (`test/helpers/mock_services.dart`) exists and is used
6. Total test count > 400 baseline + new
7. `flutter test` exit 0
8. `flutter analyze` exit 0
9. `dart format --set-exit-if-changed .` exit 0
10. No test depends on network or real Supabase
11. `RoleSwitchCoordinator().clearForTesting()` in every Chat/Dashboard tearDown
12. No existing tests weakened or skipped

---

## Rollback Plan

- **Constructor refactoring (Phase 1):** Revert optional params. Fall back to client-level mocking.
- **New test files:** Delete. Zero production impact.
- **Extended test files:** `git checkout` originals.
- **Shared mock file:** Delete. Update barrel.
- **Flaky tests:** `skip:` with TODO, don't block suite.

---

## References

### Docs
- `.TODO/AUDIT_Quality_Architecture_2026-04-01.md`
- `.cursor/Agents/Sline_Planner.md`, `.cursor/Agents/Plan_Critic.md`
- `CLAUDE.md`, `Sline_everything/SUPABASE_SETUP.md`

### Code Paths
- `lib/features/auth/viewmodels/auth_session_view_model.dart` (165 lines)
- `lib/features/wallet/viewmodels/wallet_view_model.dart` (154 lines)
- `lib/features/tasks/viewmodels/tender_payment_view_model.dart` (204 lines)
- `lib/features/chat/viewmodels/chat_view_model.dart` (767 lines)
- `lib/features/dashboard/viewmodels/dashboard_view_model.dart` (1149 lines)
- `lib/core/services/role_switch_coordinator.dart` (lines 29-33: singleton; 139-143: clearForTesting)
- `lib/features/direct_offers/services/direct_offers_service.dart` (creates 3 internal services)
- All model files, all 87 existing test files, test helpers/fixtures

### Session Log
- `docs/LOG/SESSION_PLAN_CriticalTests_2026-04-02.md`

---

## I) Change Report (Diff-Style)

### 1. Original Issues

- No test infrastructure phase — jumped to VM tests
- No constructor refactoring for WalletVM/ChatVM (deferred as "try client mocking first")
- No shared mock file (recommended colocating most mocks)
- No baseline verification gate between infra changes and new tests
- No `RoleSwitchCoordinator().clearForTesting()` in tearDown templates
- No `fakeAsync` strategy for ChatVM debounce
- No default mock pre-configuration for DashboardVM auto-loading constructor
- Column name validation mentioned but not enforced in DTO steps

### 2. Added Steps

| Addition | Phase | Why |
|----------|-------|-----|
| Phase 1: Test Infrastructure (entire phase) | NEW | WalletVM/ChatVM untestable without injectable services |
| 1.1: WalletVM constructor refactor | NEW | Enable mock injection |
| 1.2: ChatVM constructor refactor | NEW | Enable mock injection |
| 1.3: Shared mock file | NEW | Prevent duplication across 3+ test files |
| 1.4: Baseline verification | NEW | Ensure refactor didn't break anything |
| Singleton cleanup in tearDown | 5.1, 6.1 | Prevent cross-test pollution |
| Default mock pre-config for DashboardVM | 6.1 | Prevent MissingStubError |
| Phase 5.8: Timer/debounce strategy | NEW | Deterministic ChatVM tests |
| Schema ref comments in DTO tests | 7.1-7.11 | Ensure correct column names |
| Phase 8.5: Regression diff check | NEW | Verify no existing tests weakened |
| Acceptance criteria #4, #5, #11 | NEW | Enforce infra decisions |

### 3. Removed Steps

| Removal | Why |
|---------|-----|
| Phase 0.3 "Contracts" | Merged into 0.2 and Phase 1 |
| Mock strategy discussion | Decided (Option 2). No discussion in execution plan. |

### 4. Reordered Steps

| From | To | Why |
|------|-----|-----|
| WalletVM (was Phase 2) | Phase 3 | After infrastructure |
| ChatVM (was Phase 4) | Phase 5 | After infrastructure |
| DashboardVM (was Phase 5) | Phase 6 | After Chat (establishes singleton cleanup) |
| DTO tests (was Phase 6) | Phase 7 | VM tests may inform DTO tests |

### 5. Expanded Steps

| Step | What Changed |
|------|-------------|
| Chat mock setup (5.1) | Added default stub list + singleton tearDown |
| Dashboard mock setup (6.1) | Added complete default stub code block |
| All DTO phases (7.1-7.11) | Added schema ref comment step |
| QA phase (8) | Split into 5 sub-phases; added regression diff |

### 6. Why

Original plan assumed client-level mocking would work for WalletVM/ChatVM. Code inspection revealed this requires 100+ lines of brittle mock config per test. The established project pattern (BookingVM, DashboardVM) is constructor DI. Additive refactoring is safe, backwards-compatible, and makes all 5 VM suites follow the same pattern.

### 7. Residual Risks

1. **ChatVM.teardownForRoleSwitch()** still calls `Supabase.instance.client.removeAllChannels()` directly. Try-catch handles it. Flag for Phase D.
2. **DashboardVM test file** may exceed 300 lines for "core slices." Split into multiple files if needed. Deferred to executor.
3. **No `fakeAsync` precedent** in codebase — may encounter unexpected interactions. Timer sub-phase (5.8) is explicitly optional.
