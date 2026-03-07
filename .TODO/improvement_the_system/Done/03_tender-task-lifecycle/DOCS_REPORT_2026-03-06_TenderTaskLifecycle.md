# Documentation Review Report: Tender Task Lifecycle Implementation

**Review Date:** 2026-03-06  
**Reviewer:** @SlineDocs  
**Scope:** Tender Task Lifecycle Implementation Documentation  
**Plan Reference:** `.cursor/plans/tender_task_lifecycle_-_critic_reviewed_8fa6fa0b.plan.md` (not found - using available plans)

---

## Executive Summary

The Tender Task Lifecycle implementation is **well-documented overall** with comprehensive coverage in DEVELOPER_GUIDE.md, good code documentation, and supporting artifacts. However, several issues were identified ranging from LOW to HIGH severity.

**Overall Rating:** 8.5/10 - Good documentation with minor gaps

---

## Findings Summary

| Severity | Count | Categories |
|----------|-------|------------|
| HIGH | 2 | Missing changelog entry, contract/implementation mismatch |
| MED | 3 | Incomplete references, missing doc comments |
| LOW | 4 | Minor formatting, TODOs in code, typos |

---

## Detailed Findings

### 🔴 HIGH Severity

#### 1. Missing Changelog Entry in Sline_Log.md
**Location:** `Sline_everything/Sline_Log.md`  
**Finding:** No dedicated entry for Tender Task Lifecycle implementation exists in the master log. The log jumps from "Role Switching Flow" (2026-03-06) to older entries without documenting the Tender Task Lifecycle completion.  
**Impact:** Historical traceability compromised; future developers cannot find implementation details.  
**Fix:** Add new section after line 65 following the established template:

```markdown
---

## 🟢 Tender Task Lifecycle — Optimistic Concurrency, Auto-Expiry, Audit Logging

**Date:** 2026-03-06  
**Plan:** `.TODO/PLAN_TaskRequestBidFlow_CRITIC_2026-03-06.md`

### ✅ Implemented

- **Database Layer:**
  - `accept_task_request` RPC v2 — Price validation, idempotency, audit logging
  - `cleanup_expired_awards()` function — Auto-expiry with 1-hour grace period
  - `idx_task_requests_awarded_unpaid` — Optimized cron query index
  - `idx_one_accepted_per_task` — Enforces single accepted offer per task
  - pg_cron job `cleanup-expired-awards` — Runs every 10 minutes
  - `system_config` entries — `tender_payment_timeout_hours` (48h default)

- **Application Layer:**
  - `TaskRequestsService.accept()` — Price mismatch exception handling
  - `PriceMismatchException` — Typed exception with expected/actual prices
  - `OfferAlreadyAcceptedException` — Idempotency protection
  - `AwardExpirationMonitor` — Live countdown timer with urgency levels
  - `TaskRequestsViewModel.award()` — Two-step award+pay flow

- **Test Infrastructure:**
  - `test/fixtures/tender_tasks.dart` — Complete fixture set
  - `test/unit/tender/` — Unit tests for service, viewmodel, monitor

- **Migration:** `supabase/migrations/20260306_tender_guardrails.sql`

### 📊 Impact

- **Security:** Optimistic concurrency prevents race condition attacks
- **UX:** Clear payment deadlines with live countdown
- **Reliability:** Auto-expiry prevents stuck tasks
- **Observability:** Full audit trail in admin_logs

### 🔗 References

- Contract: `.TODO/CONTRACT_accept_task_request_v2.md`
- Smoke Test: `.TODO/SMOKE_TEST_TENDER.md`
- Rollback Triggers: `.TODO/ROLLBACK_TRIGGERS.md`
- Model Consolidation: `.TODO/improvement_the_system/ImplementReady/04_task-request-bid-flow/MODEL_CONSOLIDATION_PLAN.md`
```

---

#### 2. Contract vs Implementation Mismatch
**Location:** `.TODO/CONTRACT_accept_task_request_v2.md` vs `lib/features/tasks/services/task_service.dart`  
**Finding:** The contract documents `accept_task_request` RPC with `p_expected_price_cents` parameter, but the TaskService implementation uses `award_task_offer` RPC for the two-step flow. The contract does not document `award_task_offer` or `pay_awarded_offer` RPCs.  
**Evidence:**
- Contract (line 143): References `accept_task_request` RPC
- TaskService (line 739): Uses `award_task_offer` RPC
- TaskService (line 787): Uses `pay_awarded_offer` RPC

**Impact:** Contract documentation is outdated and doesn't match the actual implementation pattern.  
**Fix:** Update CONTRACT_accept_task_request_v2.md to:
1. Document the `award_task_offer` RPC (parameters: `p_request_id`, `p_expected_price_cents`)
2. Document the `pay_awarded_offer` RPC (parameters: `p_request_id`)
3. Clarify that `accept_task_request` is the legacy one-step flow
4. Add deprecation notice for one-step flow

---

### 🟡 MEDIUM Severity

#### 3. Missing Documentation References
**Location:** `Sline_everything/DEVELOPER_GUIDE.md` (Tender Task Lifecycle section)  
**Finding:** Several referenced files are not cross-linked properly:
- Line 2509 references `.TODO/CONTRACT_accept_task_request_v2.md` but this should be updated to also reference the two-step contract
- Missing reference to `MODEL_CONSOLIDATION_PLAN.md`
- Missing reference to `ROLLBACK_TRIGGERS.md`

**Fix:** Add to DEVELOPER_GUIDE.md line 2509 area:
```markdown
## 7. Contracts & Plans

- **Two-Step Award Contract:** `.TODO/CONTRACT_accept_task_request_v2.md` (award → pay flow)
- **Model Consolidation:** `.TODO/improvement_the_system/ImplementReady/04_task-request-bid-flow/MODEL_CONSOLIDATION_PLAN.md`
- **Rollback Procedures:** `.TODO/ROLLBACK_TRIGGERS.md`
- **Smoke Test Script:** `.TODO/SMOKE_TEST_TENDER.md`
```

---

#### 4. Incomplete File Header Documentation
**Location:** `lib/features/tasks/viewmodels/task_requests_view_model.dart`  
**Finding:** File lacks proper library documentation header. While the class has a doc comment (line 12), the file itself doesn't explain its purpose, responsibilities, or usage patterns.  
**Fix:** Add file header:
```dart
/// TaskRequestsViewModel — MVVM state holder for Task Requests (Offers)
///
/// Manages the lifecycle of task offers including:
/// - Listing offers for a task (with pagination)
/// - Submitting new offers
/// - Awarding offers with optimistic concurrency (price validation)
/// - Handling price mismatch errors
/// - Two-step award+pay flow coordination
///
/// This ViewModel implements the Tender Task Lifecycle guardrails:
/// - Price validation prevents race conditions
/// - Idempotency protection for double-click scenarios
/// - Error mapping for user-friendly messages
///
/// Usage:
/// ```dart
/// final vm = TaskRequestsViewModel(taskId: taskId, isOwner: true);
/// await vm.loadInitial();
/// try {
///   await vm.award(requestId, expectedPriceCents: priceCents);
/// } on PriceMismatchException catch (e) {
///   // Show price mismatch dialog
/// }
/// ```
///
/// See: [Tender Task Lifecycle documentation in DEVELOPER_GUIDE.md]
library;
```

---

#### 5. Test File References Non-Existent Helper
**Location:** `test/unit/tender/task_requests_service_test.dart` (line 10)  
**Finding:** Import references `'package:sline_app/test/helpers/mock_supabase.dart'` which does not exist at that path. The actual location is `test/helpers/mock_supabase.dart`.  
**Evidence:**
```dart
import 'package:sline_app/test/helpers/mock_supabase.dart';  // WRONG PATH
```
**Fix:** Change to:
```dart
import '../../../helpers/mock_supabase.dart';  // RELATIVE PATH
```

---

### 🟢 LOW Severity

#### 6. Typo in Contract File
**Location:** `.TODO/CONTRACT_accept_task_request_v2.md` (line 242)  
**Finding:** "doesn't" should be "does not" per project conventions (formal documentation).  
**Fix:** Change "doesn't" to "does not" for consistency with formal documentation style.

---

#### 7. Missing Sign-off Completion
**Location:** `.TODO/CONTRACT_accept_task_request_v2.md` (lines 243-245)  
**Finding:** Sign-off section has empty checkboxes with no dates or names.  
**Fix:** Either:
- Fill in actual sign-off information, OR
- Add note: "Pending final review - scheduled for 2026-03-07"

---

#### 8. Rollback Triggers Missing Test Path Reference
**Location:** `.TODO/ROLLBACK_TRIGGERS.md` (line 129)  
**Finding:** References `20260306_rollback_tender_guardrails.sql` migration that doesn't exist in the codebase.  
**Evidence:** Line 129: `See migration: 20260306_rollback_tender_guardrails.sql`  
**Fix:** Either create the rollback migration file OR update the reference to:
```markdown
-- Revert RPC to previous version (without expected_price param)
-- See migration: supabase/migrations/20260306_tender_guardrails.sql for reverse operations
```

---

#### 9. Smoke Test Has Empty Result Table
**Location:** `.TODO/SMOKE_TEST_TENDER.md` (lines 109-115)  
**Finding:** The Expected Results table has empty "Actual Result" and "Pass/Fail" columns. This is a template that should be filled during testing.  
**Recommendation:** Add note: "Fill this table during smoke test execution. See procedure in section 3."

---

## Documentation Completeness Assessment

### ✅ Well Documented Areas

| Area | Rating | Evidence |
|------|--------|----------|
| DEVELOPER_GUIDE.md Tender Section | 9/10 | Lines 2367-2511 cover all aspects comprehensively |
| SQL Migration | 10/10 | `20260306_tender_guardrails.sql` has extensive comments |
| Test Fixtures | 9/10 | `tender_tasks.dart` has complete documentation |
| AwardExpirationMonitor | 10/10 | Excellent doc comments and usage examples |
| Smoke Test Script | 8/10 | Clear step-by-step procedure |
| Rollback Triggers | 9/10 | Comprehensive monitoring queries |

### ⚠️ Documentation Gaps

| Area | Gap | Severity |
|------|-----|----------|
| Sline_Log.md | No Tender Task Lifecycle entry | HIGH |
| CONTRACT_accept_task_request_v2.md | Outdated (one-step only) | HIGH |
| TaskRequestsViewModel | Missing file header | MED |
| Model Consolidation Plan | Not referenced in DEVELOPER_GUIDE | MED |
| Test file | Wrong import path | MED |

---

## Reference Integrity Check

| Reference | Status | Location |
|-----------|--------|----------|
| `supabase/migrations/20260306_tender_guardrails.sql` | ✅ EXISTS | Migration file present |
| `test/fixtures/tender_tasks.dart` | ✅ EXISTS | Fixture file present |
| `lib/features/tasks/viewmodels/award_expiration_monitor.dart` | ✅ EXISTS | Monitor implementation present |
| `.TODO/CONTRACT_accept_task_request_v2.md` | ✅ EXISTS | Contract documented |
| `.TODO/SMOKE_TEST_TENDER.md` | ✅ EXISTS | Smoke test script present |
| `.TODO/ROLLBACK_TRIGGERS.md` | ✅ EXISTS | Rollback procedures present |
| `award_task_offer` RPC | ✅ IMPLEMENTED | Called in TaskService |
| `pay_awarded_offer` RPC | ✅ IMPLEMENTED | Called in TaskService |
| `20260306_rollback_tender_guardrails.sql` | ❌ MISSING | Referenced but doesn't exist |
| `test/helpers/mock_supabase.dart` | ❌ MISSING | Wrong path in test file |

---

## Recommendations

### Immediate Actions (Before Release)

1. **HIGH:** Add Tender Task Lifecycle entry to `Sline_Log.md`
2. **HIGH:** Update `CONTRACT_accept_task_request_v2.md` to document two-step flow
3. **MED:** Add file header to `task_requests_view_model.dart`
4. **MED:** Fix import path in `task_requests_service_test.dart`

### Follow-up Actions (Next Sprint)

5. Create `20260306_rollback_tender_guardrails.sql` rollback migration
6. Add Model Consolidation reference to DEVELOPER_GUIDE.md
7. Complete sign-off in contract file
8. Run and fill in SMOKE_TEST_TENDER.md results

---

## Verification Checklist

- [x] DEVELOPER_GUIDE.md Tender section reviewed
- [x] CONTRACT_accept_task_request_v2.md reviewed
- [x] SMOKE_TEST_TENDER.md reviewed
- [x] ROLLBACK_TRIGGERS.md reviewed
- [x] test/fixtures/tender_tasks.dart reviewed
- [x] lib/features/tasks/models/task_request_model.dart reviewed
- [x] lib/features/tasks/services/task_requests_service.dart reviewed
- [x] lib/features/tasks/viewmodels/task_requests_view_model.dart reviewed
- [x] lib/features/tasks/viewmodels/award_expiration_monitor.dart reviewed
- [x] supabase/migrations/20260306_tender_guardrails.sql reviewed
- [x] Sline_Log.md reviewed for changelog entries
- [x] MVP_ROADMAP.md reviewed for status accuracy
- [x] MODEL_CONSOLIDATION_PLAN.md reviewed

---

## Conclusion

The Tender Task Lifecycle implementation has **solid documentation foundation**. The main gaps are:
1. Missing changelog entry (traceability)
2. Outdated contract (accuracy)
3. Minor code documentation gaps

With the recommended fixes applied, the documentation will be **release-ready** and maintainable for future developers.

**Overall Status:** ✅ APPROVED with noted fixes required

---

*Report Generated: 2026-03-06*  
*Agent: @SlineDocs*  
*Review Duration: Comprehensive scan of 15+ files*
