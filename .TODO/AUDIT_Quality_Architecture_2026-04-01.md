# SLine Project Quality & Architecture Audit

**Date:** 2026-04-01
**Scope:** Full codebase + Supabase + CI + Architecture + Testing
**Overall Health Score:** 68/100

---

## Table of Contents

1. [Release Blockers](#1-release-blockers)
2. [Important But Not Immediate Blockers](#2-important-but-not-immediate-blockers)
3. [Execution Plan (Phased)](#3-execution-plan-phased)
4. [Detailed Findings](#4-detailed-findings)
   - 4.1 [CI/CD (Missing)](#41-cicd-missing)
   - 4.2 [Lint & Static Analysis](#42-lint--static-analysis)
   - 4.3 [Architecture Violations](#43-architecture-violations)
   - 4.4 [Testing Gaps](#44-testing-gaps)
   - 4.5 [Supabase & Security](#45-supabase--security)
   - 4.6 [Error Handling & Logging](#46-error-handling--logging)
   - 4.7 [Code Quality & Smells](#47-code-quality--smells)
   - 4.8 [Migration Review Discipline (Missing)](#48-migration-review-discipline-missing)
   - 4.9 [DTO / Mapper Contract Checks (Missing)](#49-dto--mapper-contract-checks-missing)
   - 4.10 [Feature-Level Health Map](#410-feature-level-health-map)
5. [CI/CD Pipeline Design](#5-cicd-pipeline-design)
6. [Proposed Lint Upgrades](#6-proposed-lint-upgrades)
7. [File References](#7-file-references)

---

## 1. Release Blockers

These MUST be resolved before any serious launch:

| # | Issue | Why It Blocks |
|---|-------|---------------|
| 1 | **No CI/CD pipeline** | Any merge can ship broken code. With booking/wallet/payments/roles, one bad merge = production incident. |
| 2 | **48 unawaited futures** | App shows success to user but operation silently failed. Data loss risk. Includes `main.dart:435,445` initialization races. |
| 3 | **258 bare `catch (e)` blocks** | Swallows `TypeError`, `RangeError`, `StateError` — real bugs get hidden behind "Something went wrong". Critical paths (wallet, payment, booking) must surface real errors. |
| 4 | **Auth/Wallet/Payment missing tests** | `AuthSessionViewModel`, `WalletViewModel`, `TenderPaymentViewModel` have zero unit tests. Financial + auth code without tests = blind deployment. |
| 5 | **Direct MVVM violations in critical flows** | `submit_request_sheet.dart:36` calls `Supabase.instance` directly from UI. `ProfileViewModel` holds `TextEditingController`. These break testability and set bad precedent. |
| 6 | **CrashReportingService is NoOp** | Production errors are invisible. No Sentry, no Crashlytics. You're flying blind after deploy. |

---

## 2. Important But Not Immediate Blockers

These matter but won't cause a production incident tomorrow:

| Issue | Category |
|-------|----------|
| `very_good_analysis` migration | debt |
| Full god-file decomposition (all 25+ files) | debt |
| Localization complete setup (Arabic/Kurdish `.arb` files) | strategic |
| 85% coverage target | nice-to-have |
| DeepLinkService route registry refactor | cleanup |
| `prefer_single_quotes` / `prefer_const_constructors` lint fixes | debt |

---

## 3. Execution Plan (Phased)

> Philosophy: Lock the gates first. Then expose the bugs. Then fix the house.

### Phase A: Gates Before Cleanup (Week 1)

Lock down the codebase so no new damage gets in.

| # | Task | Effort | Details |
|---|------|--------|---------|
| A1 | Add CI pipeline (`.github/workflows/ci.yml`) | 2h | analyze + test + build gates. See [Section 5](#5-cicd-pipeline-design). |
| A2 | Add architecture guard in CI | 1h | Grep-based checks for MVVM violations. Blocks PRs that add new violations. |
| A3 | Add pre-commit hook | 30m | `dart format` + `flutter analyze` locally before push. |
| A4 | Enable coverage generation (no enforcement yet) | 30m | `flutter test --coverage` in CI. See the number. Don't gate on it yet. |

### Phase B: Bug Exposure (Week 2)

Fix the patterns that hide real bugs.

| # | Task | Effort | Details |
|---|------|--------|---------|
| B1 | Fix 48 `unawaited_futures` | 4h | Review each. Add `await`, or wrap in `unawaited()` from `dart:async` for intentional fire-and-forget. |
| B2 | Fix bare `catch` in critical paths first | 1 day | Change `catch (e)` to `on Exception catch (e)` in: wallet, payment, booking, auth ViewModels/services. Let `Error` subclasses propagate. |
| B3 | Fix remaining bare `catch` blocks | 1 day | Same pattern across all other ViewModels and services. |
| B4 | Remove `Supabase.instance` from `submit_request_sheet.dart` | 30m | Pass `userId` from ViewModel or inject via Provider. |
| B5 | Move TextEditingControllers out of `ProfileViewModel` | 2h | ViewModel exposes `updateProfile(String name, String email, String bio)`. View owns controllers. |
| B6 | Remove ChatScreen import + Navigator.push from `user_profile_view_model.dart` | 1h | Use callback or navigation service. |
| B7 | Remove Repository imports from 3 view files | 1h | `create_task_screen.dart:11`, `public_profile_screen.dart:11`, `requests_list_screen.dart:12` — route through ViewModel. |

### Phase C: Critical Tests (Week 3-4)

Cover the dangerous zones. Not chasing percentage — covering risk.

| # | What to Test | Why It's Critical | Effort |
|---|-------------|-------------------|--------|
| C1 | `AuthSessionViewModel` | Controls login/logout/session. Broken = entire app inaccessible. | 1 day |
| C2 | `WalletViewModel` | Financial data. Wrong balance = user trust destroyed. | 1 day |
| C3 | Payment / booking integration (un-skip `booking_request_flow_test.dart`) | Payment flow is currently untested end-to-end. | 1 day |
| C4 | `ChatViewModel` | Core communication. Highest daily usage feature. | 1-2 days |
| C5 | `DashboardViewModel` — core slices only | 1149 lines. Don't test everything. Test: role switch, refresh, work items loading, error states. | 2 days |
| C6 | DTO parsing / model mapping tests (see [4.9](#49-dto--mapper-contract-checks-missing)) | Data layer bugs are invisible from UI but cause cascading failures. | 2 days |

### Phase D: Harden (Month 2)

Now that gates are up and critical paths are covered:

| # | Task | Effort |
|---|------|--------|
| D1 | Implement Sentry or Firebase Crashlytics (replace NoOp) | 1 day |
| D2 | Decompose `dashboard_view_model.dart` (1149 lines) | 2 days |
| D3 | Decompose `submit_request_sheet.dart` (919 lines) | 1 day |
| D4 | Decompose `requests_list_screen.dart` (1164 lines) | 1 day |
| D5 | Add pgTAP tests for critical RPCs | 2 days |
| D6 | Add migration review checklist (see [4.8](#48-migration-review-discipline-missing)) | 1h |
| D7 | Tighten CORS on Edge Functions | 15m |
| D8 | Add `paymentId` regex validation in webhook handler | 30m |
| D9 | Set up coverage enforcement (70% threshold) | 1h |

### Phase E: Polish (Month 3+)

| Task |
|------|
| Replace `flutter_lints` with `very_good_analysis` (test on separate branch first, measure "explosion" size) |
| Run `dart fix --apply` for auto-fixable issues (~138 issues) |
| Reduce null assertions (`!`) — introduce state sealed classes for ViewModels |
| Localization setup (`l10n.yaml` + `.arb` files) |
| DeepLinkService route registry refactor |
| Remaining god-file decomposition |
| 85% coverage target |

---

## 4. Detailed Findings

### 4.1 CI/CD (Missing)

**Status:** No CI pipeline exists. Zero automation.

- No `.github/workflows/`
- No Codemagic, Bitrise, Fastlane
- Only a bare `netlify.toml` for web deploys (no test/lint steps)

**Risk:** Every push to main can ship broken code. With booking, wallet, payments, roles, and admin — one unchecked merge can cascade.

**Fix:** See [Section 5](#5-cicd-pipeline-design) for full pipeline design.

---

### 4.2 Lint & Static Analysis

**Current setup:** `flutter_lints` v5.0.0 with 34 rules (18 original + 16 added).

**`flutter analyze` output: 456 info issues, 0 warnings, 0 errors.**

| Rule | Count | Severity | Action |
|------|-------|----------|--------|
| `avoid_catches_without_on_clauses` | 258 | CRITICAL | Fix: `on Exception catch (e)` — critical paths first |
| `prefer_const_constructors` | 89 | LOW | Auto-fix: `dart fix --apply` |
| `unawaited_futures` | 48 | CRITICAL | Manual review each one |
| `prefer_single_quotes` | 35 | LOW | Auto-fix: `dart fix --apply` |
| `prefer_const_literals_to_create_immutables` | 14 | LOW | Auto-fix: `dart fix --apply` |
| `prefer_final_locals` | 10 | LOW | Quick manual fix |
| `unnecessary_await_in_return` | 2 | LOW | Quick manual fix |

**Risk classification:**
- `unawaited_futures` = **release blocker** (silent data loss)
- `avoid_catches_without_on_clauses` = **high risk** (hides real bugs)
- `prefer_single_quotes` / `prefer_const_*` = **debt** (cosmetic, auto-fixable)

**Lint ignore directives:** Only 18 across entire codebase. All justified (`deprecated_member_use_from_same_package` in proposal migration code). Clean.

**~~Missing rules:~~ DONE (2026-04-01)** — 16 new rules added. See [Section 6](#6-proposed-lint-upgrades). Only +12 new issues from the new rules. Safety rules caught zero violations (code was already clean).

**`very_good_analysis` migration:** Good idea but do it on a separate branch first. Measure the "explosion" — it enables 100+ rules. Incremental adoption is safer than big-bang.

---

### 4.3 Architecture Violations

| ID | Violation | Severity | File | Fix |
|----|-----------|----------|------|-----|
| A1 | View calls `Supabase.instance` directly | **CRITICAL** | `submit_request_sheet.dart:36` | Pass userId from ViewModel/Provider |
| A2 | ViewModel holds `TextEditingController` + `GlobalKey<FormState>` | **HIGH** | `profile_view_model.dart:36-39` | Move controllers to View. VM exposes data methods. |
| A3 | ViewModel imports View (`ChatScreen`) | **HIGH** | `user_profile_view_model.dart:7` | Use callback or navigation service |
| A4 | ViewModel does `Navigator.push` | **HIGH** | `user_profile_view_model.dart:61-92` | Navigation belongs in View layer |
| A5 | View imports Repository directly (3 files) | **MEDIUM** | `create_task_screen.dart:11`, `public_profile_screen.dart:11`, `requests_list_screen.dart:12` | Route through ViewModel |
| A6 | ViewModel accesses `Supabase.instance` directly | **MEDIUM** | `notification_view_model.dart:55-56`, `saved_tasks_view_model.dart:108-112` | Use injected auth service |
| A7 | Core service imports feature Views | **MEDIUM** | `deep_link_service.dart` (6 feature screen imports) | Refactor to route registry pattern |
| A8 | Business logic in View (filtering, price calc) | **MEDIUM** | `requests_list_screen.dart:100-110`, `submit_request_sheet.dart:149-328` | Move logic to ViewModel |

**Enforcement:** Architecture guard in CI (grep-based). See [Section 5](#5-cicd-pipeline-design).

---

### 4.4 Testing Gaps

**Current state:** 86 test files. 9 of 26 ViewModels tested (35%).

**Strong areas:**
- RLS security tests (8 files) — well-designed
- Model serialization tests — good coverage
- Bid lifecycle integration test — comprehensive (5 flow scenarios)
- Test infrastructure (mock helpers, fixtures, pump_app) — solid

**Critical gaps (ordered by business risk, not coverage percentage):**

| Priority | ViewModel / Area | Risk If Untested |
|----------|-----------------|------------------|
| **P0** | `AuthSessionViewModel` | Login/logout broken = app unusable |
| **P0** | `WalletViewModel` | Wrong balances = user trust destroyed |
| **P0** | Payment integration (currently skipped) | Payment flow = money. Zero tolerance. |
| **P0** | `ChatViewModel` | Core communication. Highest daily usage. |
| **P1** | `DashboardViewModel` (core slices) | Main screen. 1149 lines of untested logic. Test role switch, refresh, error states. |
| **P1** | `TenderPaymentViewModel` | Payment code without tests is a liability |
| **P1** | `DirectOfferDetailsViewModel` | Offer acceptance logic must be correct |
| **P1** | `WorkItemDetailsViewModel` | Delivery/revision state machine |
| **P2** | `SearchViewModel` | Debounce/cancel logic |
| **P2** | `SavedTasksViewModel` | Auth subscription cleanup |
| **P2** | Remaining ViewModels | Lower business risk |

**Coverage targets:**
- Target 70% line coverage but **don't make it a numbers game**.
- Cover dangerous zones (wallet, auth, booking, payment, role switching, dashboard critical logic) first.
- Writing tests on trivial files to bump percentage is waste.

**Missing infrastructure:**
- No code coverage tooling configured
- No `flutter_test_config.dart`
- No golden file testing
- 1 skipped test (`booking_request_flow_test.dart`), 1 placeholder (`proposal_flows_placeholder_test.dart`)

---

### 4.5 Supabase & Security

**Overall rating: 8.5/10 — Strong.**

**What's excellent:**
- Append-only ledger (`journal_entries` + `ledger_lines`) — correct double-entry design
- Idempotency keys on all financial operations — prevents double-charging
- RLS on ALL tables, including `admin_logs` (service_role only)
- `SECURITY_INVOKER` on views — prevents privilege escalation
- Webhook RSA SHA256 signature verification
- Amount/currency verification on payment intents
- Orphan payment recording for investigation
- Rate limiting on role switches (3/minute)
- Private storage buckets with signed URLs (60s TTL)
- Service role key only in Deno env, never in client code

**Issues to address:**

| ID | Issue | Risk | Fix |
|----|-------|------|-----|
| S1 | CORS `Access-Control-Allow-Origin: *` on Edge Functions | LOW | Restrict to `https://sline.app` in `_shared/bookin_payment.ts:25-29` |
| S2 | `.or()` filter with string interpolation in webhook handler | LOW | Add regex validation: `/^[a-zA-Z0-9\-_]+$/` for `paymentId` in `qicard_webhook_handler/index.ts:243` |
| S3 | `QICARD_ALLOW_UNSIGNED_LOCAL_DEV` flag | LOW | Add CI check to ensure never `true` in production |
| S4 | No pgTAP tests for RPCs | MEDIUM | Add tests for `process_gateway_escrow_booking`, `accept_task_request`, `switch_active_role` |

**Recommended pgTAP tests:**
- Double escrow hold is idempotent (same key = no error)
- Amount mismatch is rejected
- Role switch rate limit enforced (4th switch within 1 minute fails)
- `accept_task_request` prevents double-acceptance

---

### 4.6 Error Handling & Logging

**What's good:**
- `ErrorMapper` (246 lines) — comprehensive mapping for Postgrest, Auth, Storage, Network errors
- `AppLogger` with token masking (`access_token`, `refresh_token` auto-masked), feature tagging, stack trace capture
- Three-layer global error boundary: `runZonedGuarded` + `FlutterError.onError` + `PlatformDispatcher.onError`
- `CrashReportingService` interface ready for swap-in (currently NoOp)
- Flutter error filters for known non-actionable platform errors
- Technical message filtering prevents SQL/table names from leaking to UI
- `avoid_print` lint rule enforced — only `AppLogger` calls `debugPrint` (intentional)

**What needs work:**

| Issue | Impact | Fix |
|-------|--------|-----|
| `CrashReportingService` is NoOp | Production errors invisible | Implement Sentry or Firebase Crashlytics |
| No retry logic for transient network failures | User gets error on first timeout | Add exponential backoff utility |
| ViewModel error is `String? error` | View can't react differently to auth vs network vs validation errors | Consider `AppFailure` sealed class (Phase D/E) |
| 258 bare catch blocks | Real bugs hidden | `on Exception catch (e)` |

**Proposed typed error system (future improvement, not blocker):**

```dart
sealed class AppFailure {
  final String userMessage;
  final String? debugMessage;
  const AppFailure(this.userMessage, {this.debugMessage});
}

class NetworkFailure extends AppFailure { ... }
class AuthFailure extends AppFailure { final bool sessionExpired; ... }
class ValidationFailure extends AppFailure { final Map<String, String> fieldErrors; ... }
class BusinessFailure extends AppFailure { final String code; ... } // e.g. 'BOOKING_ALREADY_EXISTS'
```

---

### 4.7 Code Quality & Smells

**God files (>800 lines):**

| File | Lines | Decomposition Priority |
|------|-------|----------------------|
| `requests_list_screen.dart` | 1164 | HIGH — complex filtering + pagination + bid comparison in view |
| `dashboard_view_model.dart` | 1149 | HIGH — extract `DashboardWorkVM`, `DashboardInboxVM`, `DashboardActivityVM` |
| `work_item_details_screen.dart` | 1095 | MEDIUM |
| `wallet_shared_body.dart` | 1003 | MEDIUM |
| `task_service.dart` | 960 | MEDIUM |
| `create_task_screen.dart` | 943 | MEDIUM |
| `submit_request_sheet.dart` | 919 | HIGH — business logic mixed with UI |
| `task_requests_service.dart` | 856 | LOW |
| `task_requests_view_model.dart` | 845 | LOW |
| `payment_checkout_screen.dart` | 831 | MEDIUM |
| `booking_view_model.dart` | 820 | LOW |
| `qicard_payment_service.dart` | 811 | LOW |

**Start with these 3 (they have logic-in-view issues, not just length):**
1. `dashboard_view_model.dart` — too many responsibilities
2. `submit_request_sheet.dart` — bid comparison logic belongs in ViewModel
3. `requests_list_screen.dart` — filter logic belongs in ViewModel

**Do NOT decompose all 25+ files at once.** That's a refactor swamp.

**Null safety concerns:**
- 80+ null assertion operators (`!`) across codebase
- High-risk locations: `work_item_details_screen.dart` (`vm.workItem!`, `vm.booking!`), `direct_offer_details_screen.dart`, `message_service.dart`
- Future fix: Introduce sealed state classes (`Loading | Loaded | Error`) to eliminate assertions

**Other code smells:**
- 14 TODO/FIXME comments (acceptable — concentrated in profile/settings unimplemented features)
- `DeepLinkService` imports 6 feature screens — core/feature coupling
- No localization despite `intl`/`flutter_localizations` in pubspec
- `dependency_overrides: sign_in_with_apple: ^7.0.1` — version incompatibility unresolved

---

### 4.8 Migration Review Discipline (Missing)

**Problem:** With Supabase and frequent migrations, there's no formal review process for database changes.

**What's needed:**

Every migration PR should include answers to:

1. **Naming:** Does the migration file name follow `YYYYMMDD_description.sql` convention?
2. **Rollback:** What's the rollback plan? Is there a down migration? What happens if this migration fails halfway?
3. **Data safety:** What existing data could break? Are there rows that violate the new constraint?
4. **RLS impact:** Does this change affect any RLS policies? Will existing authenticated queries still work?
5. **RPC contract:** If an RPC signature changes, which client code calls it? Is the client updated in the same PR?
6. **Idempotency:** Can this migration be re-run safely? (`CREATE OR REPLACE`, `IF NOT EXISTS`, etc.)
7. **Performance:** Does this add an index? Does the new query hit an existing index?

**Suggested:** Add a `MIGRATION_REVIEW_CHECKLIST.md` to the project root or `.TODO/` that teams reference on every migration PR.

---

### 4.9 DTO / Mapper Contract Checks (Missing)

**Problem:** The project is heavily data-driven (Supabase → JSON → Dart models). Many bugs originate in this layer, not in UI.

**What's needed:**

Tests that verify:

| Check | Example | Why |
|-------|---------|-----|
| **DTO parsing** | `BookingModel.fromJson(rawJson)` doesn't throw on valid DB row | One renamed column = crash |
| **DB row → model mapping** | `TaskModel.fromJson(row)` correctly maps all fields | Supabase returns snake_case, model expects camelCase |
| **Nullability contract** | `fromJson` handles null `deadline` gracefully when column is nullable | New nullable column = existing model breaks |
| **Enum mapping** | `BookingStatus.fromString('in_progress')` maps correctly | New enum value added in DB but not in Dart = crash |
| **Backward compatibility** | Model handles row with missing optional field (added in newer migration) | Old rows don't have the field |
| **Default values** | `TaskModel.fromJson({...missing_field...})` uses correct default | Missing defaults = null assertion crash |

**Current model tests exist** (8 files in `test/unit/models/`) but focus mainly on `fromJson`/`toMap` happy paths. Need:
- Tests with partial JSON (simulating old DB rows)
- Tests with null values for each nullable field
- Tests with unknown enum values
- Tests verifying field name mapping matches actual Supabase column names

---

### 4.10 Feature-Level Health Map

Each feature module should be thought of as having its own health profile:

| Feature | Tests | Architecture | Lint | Critical Logic | Overall |
|---------|-------|-------------|------|---------------|---------|
| **auth** | Minimal (1 repo test, no VM test) | Clean | OK | Session management untested | **RED** |
| **wallet** | Partial (service test, no VM test) | Clean | OK | Financial operations untested | **RED** |
| **booking** | Good (VM + widget + model tests) | Clean | OK | Integration test skipped | **YELLOW** |
| **payment** | Partial (demo service, config tests) | Clean | OK | Production flow gaps | **YELLOW** |
| **tasks** | Good (VM + service + model + integration) | View has Supabase access (A1) | OK | Bid lifecycle well tested | **YELLOW** |
| **chat** | Partial (service + widget, no VM test) | Clean | OK | Core feature untested | **YELLOW** |
| **dashboard** | Widget tests only, no VM test | Clean | OK | 1149-line VM untested | **RED** |
| **profile** | Good (VM + widget tests) | VM has controllers (A2) | OK | Architecture violation | **YELLOW** |
| **work** | Contract test only | Clean | OK | Delivery state machine untested | **YELLOW** |
| **notifications** | VM test exists | VM accesses Supabase directly (A6) | OK | — | **GREEN** |
| **proposals** | Model tests, placeholder integration | Clean | OK | Placeholder test = no real coverage | **YELLOW** |
| **direct_offers** | Service test only | Clean | OK | Offer acceptance untested | **YELLOW** |
| **search** | No tests | Clean | OK | Debounce logic untested | **RED** |
| **saved** | No tests | VM accesses Supabase directly (A6) | OK | Auth subscription untested | **RED** |

**Interpretation:**
- **RED** = has critical untested logic or architecture violations in sensitive areas
- **YELLOW** = partially covered, known gaps exist
- **GREEN** = acceptable for current stage

---

## 5. CI/CD Pipeline Design

### GitHub Actions: `.github/workflows/ci.yml`

```yaml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  analyze:
    name: Lint & Analyze
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.8.1'
          cache: true
      - run: flutter pub get
      - run: dart format --set-exit-if-changed .
      - run: flutter analyze --fatal-infos

  architecture-guard:
    name: Architecture Guard
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Check MVVM boundaries
        run: |
          FAIL=0

          echo "--- Checking for Supabase.instance in views ---"
          if grep -rn "Supabase\.instance" lib/features/*/view/ lib/features/*/view/**/* 2>/dev/null; then
            echo "FAIL: Direct Supabase access found in view layer"
            FAIL=1
          fi

          echo "--- Checking for material.dart in viewmodels ---"
          if grep -rn "package:flutter/material.dart" lib/features/*/viewmodels/ 2>/dev/null; then
            echo "FAIL: material.dart imported in viewmodel layer"
            FAIL=1
          fi

          echo "--- Checking for view imports in viewmodels ---"
          if grep -rn "import.*\/view\/" lib/features/*/viewmodels/ 2>/dev/null; then
            echo "FAIL: view layer imported in viewmodel"
            FAIL=1
          fi

          if [ $FAIL -eq 1 ]; then
            echo "Architecture violations detected. Fix before merging."
            exit 1
          fi
          echo "All architecture checks passed."

  test:
    name: Unit & Widget Tests
    runs-on: ubuntu-latest
    needs: analyze
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.8.1'
          cache: true
      - run: flutter pub get
      - run: flutter test --coverage
      - name: Report coverage
        run: |
          if command -v lcov &> /dev/null; then
            COVERAGE=$(lcov --summary coverage/lcov.info 2>&1 | grep "lines" | grep -oP '\d+\.\d+')
            echo "Line coverage: $COVERAGE%"
          else
            echo "lcov not available, skipping coverage summary"
          fi

  build:
    name: Build Validation
    runs-on: ubuntu-latest
    needs: [analyze, test]
    strategy:
      matrix:
        target: [apk, web]
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.8.1'
          cache: true
      - run: flutter pub get
      - run: flutter build ${{ matrix.target }} --release
```

### Pre-commit Hook: `.githooks/pre-commit`

```bash
#!/bin/sh
set -e
echo "Running format check..."
dart format --set-exit-if-changed .
echo "Running analyze..."
flutter analyze --fatal-infos
echo "Pre-commit checks passed."
```

Enable: `git config core.hooksPath .githooks`

---

## 6. Proposed Lint Upgrades

### ~~Add these rules to `analysis_options.yaml`:~~ DONE (2026-04-01)

> **Applied.** 16 new rules added to `analysis_options.yaml`. Impact: +12 new issues only (10 `prefer_final_locals`, 2 `unnecessary_await_in_return`). Safety rules (`cancel_subscriptions`, `close_sinks`, `throw_in_finally`, etc.) caught zero new violations — existing code already follows those patterns. Total: 456 info issues, 0 warnings, 0 errors.

Rules added:

| Category | Rules |
|----------|-------|
| Safety | `cancel_subscriptions`, `close_sinks`, `no_duplicate_case_values`, `throw_in_finally`, `unnecessary_statements`, `literal_only_boolean_expressions`, `no_adjacent_strings_in_list` |
| Code Quality | `prefer_final_locals`, `avoid_void_async`, `prefer_if_null_operators`, `prefer_null_aware_operators`, `prefer_collection_literals`, `unnecessary_await_in_return`, `use_super_parameters`, `depend_on_referenced_packages`, `sort_child_properties_last` |

### `very_good_analysis` migration path:

1. Create branch: `feat/very-good-analysis`
2. Replace `flutter_lints` with `very_good_analysis: ^7.0.0` in pubspec
3. Run `flutter analyze` — count new issues
4. If < 200 new issues: migrate gradually with `// ignore_for_file:` on worst files
5. If > 200: stay on `flutter_lints` + manual rules above, revisit in 3 months

---

## 7. File References

### Violations requiring immediate fixes:

```
lib/features/tasks/view/widgets/requests/submit_request_sheet.dart:36       # A1: Supabase in view
lib/features/profile/viewmodels/profile_view_model.dart:36-39               # A2: Controllers in VM
lib/features/profile/viewmodels/user_profile_view_model.dart:7              # A3: View import in VM
lib/features/profile/viewmodels/user_profile_view_model.dart:61-92          # A4: Navigator in VM
lib/features/tasks/view/create_task_screen.dart:11                          # A5: Repo in view
lib/features/profile/view/public_profile_screen.dart:11                     # A5: Repo in view
lib/features/tasks/view/widgets/requests/requests_list_screen.dart:12       # A5: Repo in view
lib/features/notifications/viewmodels/notification_view_model.dart:55-56    # A6: Supabase in VM
lib/features/saved/viewmodels/saved_tasks_view_model.dart:108-112           # A6: Supabase in VM
lib/core/services/deep_link_service.dart                                    # A7: Core imports features
```

### God files (decompose starting with top 3):

```
lib/features/dashboard/viewmodels/dashboard_view_model.dart                 # 1149 lines — decompose first
lib/features/tasks/view/widgets/requests/submit_request_sheet.dart          #  919 lines — decompose second
lib/features/tasks/view/widgets/requests/requests_list_screen.dart          # 1164 lines — decompose third
```

### Edge function security fixes:

```
supabase/functions/_shared/bookin_payment.ts:25-29                          # S1: CORS wildcard
supabase/functions/qicard_webhook_handler/index.ts:243                      # S2: Filter interpolation
```

### Strong areas (no changes needed):

```
lib/core/utils/error_mapper.dart                                            # Comprehensive error mapping
lib/core/services/logger_service.dart                                       # Good structured logging
lib/core/services/crash_reporting_service.dart                              # Interface ready, needs impl
lib/core/utils/flutter_error_filters.dart                                   # Platform error suppression
test/rls/                                                                   # 8 RLS security tests
test/unit/models/                                                           # 8 model serialization tests
supabase/functions/qicard_webhook_handler/index.ts                          # Payment hardening excellent
```
