# CodeGuard Review Report: Tender Task Lifecycle

**Date:** 2026-03-06  
**Scope:** Tender Task Lifecycle Implementation  
**Change Type:** HIGH (Payment flows, escrow, database migrations)  
**Areas:** MVVM / DB / RLS / Business Logic / UI  
**Files Reviewed:** 7 core files + migrations + tests

---

## Evidence Collected

### Commands Run
```bash
flutter analyze          # 83 issues found (see Analysis)
flutter pub outdated     # Dependencies checked
```

### Docs Scanned
- `Sline_everything/DEVELOPER_GUIDE.md` - Architecture patterns, MVVM conventions
- `Sline_everything/SUPABASE_SETUP.md` - RLS policies, triggers
- `.cursor/plans/tender_task_lifecycle_*.plan.md` - Plan reference (not found, reviewed code directly)

### Web Freshness Checks
- Supabase Flutter SDK: v1.10.25 used, v2.12.0 available (major version behind)
- Security advisories: CVE-2025-48757 noted - RLS enforcement critical
- No critical security patches required for current implementation

---

## Critical Issues (BLOCKERS)

### 1. CRITICAL: Test Fixture Naming Collision
**File:** `test/fixtures/fixtures.dart`
**Risk:** Tests will fail to compile due to ambiguous exports
**Evidence:**
```dart
// test/fixtures/fixtures.dart - Lines 21, 24
export 'profiles.dart';      // Defines testClientId
export 'chat_fixtures.dart'; // ALSO defines testClientId
export 'tender_tasks.dart';  // ALSO defines testClientId
```
**Fix:** Rename conflicting constants to be fixture-specific:
- `profiles.dart`: `testClientId` → `testProfileClientId`
- `chat_fixtures.dart`: `testClientId` → `testChatClientId`
- `tender_tasks.dart`: `testClientId` → `testTenderClientId`
**Owner:** Test infrastructure maintainer

### 2. CRITICAL: Missing Mock Helper for Unit Tests
**File:** `test/unit/tender/task_requests_service_test.dart`
**Risk:** Unit tests fail compilation - missing imports
**Evidence:**
```dart
// Line 10: URI doesn't exist
import 'package:sline_app/test/helpers/mock_supabase.dart';
```
**Fix:** Create `test/helpers/mock_supabase.dart` with MockSupabaseClient, MockGoTrueClient, MockUser, and createMockPostgrestException helper
**Owner:** Test author

### 3. CRITICAL: Type Mismatch in TaskRequest Model Test
**File:** `test/unit/tender/task_requests_view_model_test.dart`
**Risk:** Price field changed from double to int, tests use double
**Evidence:**
```dart
// Lines 36, 99, 115: price: 500.0 (double)
// Model expects int price
```
**Fix:** Update all test fixtures to use int prices: `price: 500` instead of `price: 500.0`
**Owner:** Test author

---

## Warnings (Should Fix)

### 1. HIGH: Unused Import in Production Code
**File:** `lib/features/tasks/view/widgets/dashboard_offer_card.dart`
**Line:** 2
**Issue:** `import 'package:provider/provider.dart';` is unused
**Fix:** Remove unused import

### 2. HIGH: Unnecessary Import in UI
**File:** `lib/features/tasks/view/widgets/requests/requests_list_screen.dart`
**Line:** 12
**Issue:** Duplicate import of TaskRequestsService (already exported from viewmodel)
**Fix:** Remove redundant import

### 3. MEDIUM: Unused Exception Variable
**File:** `lib/features/tasks/viewmodels/task_requests_view_model.dart`
**Line:** 253
**Issue:** `on OfferAlreadyAcceptedException catch (e)` - `e` is unused
**Fix:** Use `catch (_)` or remove variable name

### 4. MEDIUM: Unused Import in Test
**File:** `test/unit/tender/award_expiration_monitor_test.dart`
**Line:** 6
**Issue:** `import 'dart:async';` is unnecessary
**Fix:** Remove unused import

### 5. MEDIUM: Test Missing Type Imports
**File:** `test/unit/tender/task_requests_view_model_test.dart`
**Lines:** 38, 39, 101, 102, 117, 118
**Issue:** `OfferStatus` and `PaymentStatus` enums not imported
**Fix:** Add `import 'package:sline_app/core/app_enums.dart';`

### 6. LOW: Deprecated Model Usage (Expected)
**Files:** Multiple references to `ProposalModel`
**Issue:** ProposalModel is deprecated in favor of TaskRequest
**Note:** This is intentional per MODEL_CONSOLIDATION_PLAN.md - acceptable for now

---

## Passed Checks

### ✅ Security
- **RLS Policies:** All queries use authenticated client with RLS-enforced tables
- **SQL Injection:** Parameterized queries used throughout (no string concatenation)
- **Price Validation:** Optimistic concurrency with expectedPriceCents prevents race conditions
- **Authorization:** accept_task_request RPC verifies task ownership before accepting
- **Audit Logging:** admin_logs captures price mismatch attempts and successful accepts
- **No Service Role Key:** Client code only uses anon key - correct

### ✅ Performance
- **No N+1 Queries:** TaskService uses batch profile fetching (2 queries total)
- **Indexed Queries:** Migration adds `idx_task_requests_awarded_unpaid` for cron job
- **Timer Efficiency:** AwardExpirationMonitor uses 1-minute intervals (not excessive)
- **Pagination:** Cursor-based pagination with created_at timestamps

### ✅ Architecture
- **MVVM Compliance:** Services encapsulate Supabase calls; UI uses ViewModels
- **State Management:** ChangeNotifier properly implemented with notifyListeners()
- **Error Handling:** AppLogger used consistently; no print() statements
- **Resource Disposal:** AwardExpirationMonitor properly cancels timers in dispose()

### ✅ Database Design
- **Atomic Operations:** accept_task_request RPC handles acceptance atomically
- **Idempotency:** Function returns 'already_accepted' on duplicate calls
- **Auto-Expiry:** cleanup_expired_awards() cron job runs every 10 minutes
- **Constraint:** Unique partial index prevents multiple accepted offers per task

### ✅ Business Logic
- **Two-Step Flow:** awardOffer() + payAwardedOffer() properly separated
- **Payment Deadline:** 48-hour window with countdown UI
- **Price Protection:** PriceMismatchException caught and handled in UI
- **Backward Compatibility:** Deprecated methods marked with @Deprecated

---

## Risk Notes

### Threat Model Highlights

#### T1: Double-Award Prevention
**Mitigation:** Unique partial index `idx_one_accepted_per_task` ensures only one accepted offer per task at DB level

#### T2: Price Race Condition
**Mitigation:** expectedPriceCents parameter with PRICE_MISMATCH error prevents accepting modified offers

#### T3: Work Without Escrow
**Mitigation:** Two-step flow separates award from payment; status stays 'accepted' + 'unpaid' until payment

#### T4: Payment Window Bypass
**Mitigation:** Cron job auto-expires unpaid awards after deadline + 1-hour grace period

#### T5: Authorization Bypass
**Mitigation:** RPC verifies task ownership via auth.uid() = task.owner_id check

### Regression Risks
- **TaskRequest Model Change:** Price field changed from double to int - verify all consumers
- **RPC Signature Change:** accept_task_request now has optional expected_price_cents parameter
- **Migration Dependencies:** Requires system_config table with tender_payment_timeout_hours

---

## Dependency Status

| Package | Current | Latest | Status |
|---------|---------|--------|--------|
| supabase_flutter | 1.10.25 | 2.12.0 | ⚠️ Major version behind |
| postgrest | 1.5.2 | 2.6.0 | ⚠️ Major version behind |
| gotrue | 1.12.6 | 2.18.0 | ⚠️ Major version behind |

### Recommended Upgrade Plan
- **Immediate:** None required for security
- **Short-term (1-2 sprints):** Plan supabase_flutter v2 migration (breaking changes in auth API)
- **Note:** Current version is stable; upgrade when bandwidth allows

---

## Pre-Existing Issues (Not Related to This Change)

The following issues exist in the codebase but are NOT introduced by Tender Task Lifecycle:

1. **TimeoutException undefined** - `lib/features/chat/services/message_service.dart`
2. **Conversation null safety** - Multiple files returning nullable Conversation
3. **Mock classes in tests** - Various test files have incomplete mocks
4. **Error mapper dead code** - `lib/core/utils/error_mapper.dart:60`

---

## Verification Commands

```bash
# Verify migration applies cleanly:
supabase db reset

# Run Tender-specific tests:
flutter test test/unit/tender/

# Verify no new lint errors in changed files:
flutter analyze lib/features/tasks/services/task_requests_service.dart
flutter analyze lib/features/tasks/services/task_service.dart
flutter analyze lib/features/tasks/viewmodels/award_expiration_monitor.dart
flutter analyze lib/features/tasks/viewmodels/task_requests_view_model.dart

# Verify tests compile:
flutter test --dry-run test/unit/tender/
```

---

## Final Decision

### BLOCKED ❌

The implementation cannot proceed to production until the following are fixed:

1. **test/fixtures/fixtures.dart** - Fix ambiguous testClientId exports (BLOCKER #1)
2. **test/unit/tender/task_requests_service_test.dart** - Create missing mock helpers (BLOCKER #2)
3. **test/unit/tender/task_requests_view_model_test.dart** - Fix type mismatches (BLOCKER #3)

### Next Actions

| Priority | Action | Owner | ETA |
|----------|--------|-------|-----|
| P0 | Fix test fixture naming collision | @SlineDocs or Test Lead | Immediate |
| P0 | Create mock_supabase.dart helpers | Test author | Immediate |
| P0 | Fix test type mismatches | Test author | Immediate |
| P1 | Remove unused imports (dashboard_offer_card, requests_list_screen) | Implementer | Same session |
| P1 | Fix unused exception variable | Implementer | Same session |
| P2 | Run full test suite verification | QA | Before merge |

---

## Post-Fix Verification

After fixes are applied, re-run:
```bash
flutter analyze --no-pub
flutter test test/unit/tender/
```

Expected result: 0 errors in production files, all tests pass.

---

**Reviewed by:** @CodeGuard  
**Review Hash:** Based on git status as of 2026-03-06  
**Report Location:** `.TODO/CODEGUARD_REVIEW_2026-03-06_TenderTaskLifecycle.md`
