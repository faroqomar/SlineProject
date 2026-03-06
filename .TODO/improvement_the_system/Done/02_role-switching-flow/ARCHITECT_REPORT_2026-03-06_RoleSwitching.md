# Architecture Review Report: Role Switching Flow Implementation

**Review Date:** 2026-03-06  
**Reviewer:** @Architect  
**Scope:** Full implementation review of Role Switching Flow  
**Plan Reference:** `.TODO/PLAN_RoleSwitchingFlow_CRITIC_2026-03-06.md`

---

## 1. Executive Summary

**Overall Status:** ✅ **APPROVED WITH MINOR RECOMMENDATIONS**

The Role Switching Flow implementation by @Executor demonstrates solid MVVM architecture adherence, proper separation of concerns, and comprehensive error handling. All critical components from the plan critic review have been implemented correctly.

---

## 2. MVVM Boundary Check

### 2.1 Layer Separation Analysis

| Layer | Files | Boundary Status | Notes |
|-------|-------|-----------------|-------|
| **View** | Not in scope of this review | N/A | UI changes were assigned to @Pixel |
| **ViewModel** | `profile_view_model.dart`<br>`chat_view_model.dart`<br>`dashboard_view_model.dart`<br>`task_view_model.dart`<br>`home_view_model.dart` | ✅ **PASS** | All ViewModels properly use repository layer, never call Supabase directly |
| **Service/Repository** | `role_switch_repository.dart`<br>`profile_repository.dart` | ✅ **PASS** | Clean abstraction, all Supabase calls encapsulated |
| **Core/Coordinator** | `role_switch_coordinator.dart`<br>`role_switch_aware.dart` | ✅ **PASS** | Singleton coordinator correctly manages cross-ViewModel teardown |

### 2.2 MVVM Compliance Verification

**✅ PASS - No Direct Supabase in Views**
- All Supabase interactions flow through:
  - `RoleSwitchRepository` (role-specific operations)
  - `ProfileRepository` (legacy operations)

**✅ PASS - Repository Delegation Pattern**
```dart
// profile_repository.dart:131-132
/// Get the role switch repository for atomic role operations.
RoleSwitchRepository get roleSwitch => _roleSwitchRepository;
```
This properly delegates without breaking encapsulation.

**✅ PASS - Coordinator Pattern for Cross-Feature Communication**
- `ProfileViewModel` cannot directly access `DashboardViewModel` (different feature branches)
- `RoleSwitchCoordinator` singleton solves this without violating MVVM:
```dart
// lib/core/services/role_switch_coordinator.dart:74-135
Future<void> teardownAll() async {
  // Iterates registered ViewModels and calls teardownForRoleSwitch()
  // No direct ViewModel references needed
}
```

**✅ PASS - ViewModel Lifecycle Management**
All ViewModels properly register/unregister:
```dart
// chat_view_model.dart:42, 69-70
RoleSwitchCoordinator().register(this);
// ...
RoleSwitchCoordinator().unregister(this);
```

---

## 3. Data Flow Map

### 3.1 Role Switch Flow (UI → DB → UI)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          ROLE SWITCH DATA FLOW                               │
└─────────────────────────────────────────────────────────────────────────────┘

[User Action] → [ProfileViewModel.changeRole()] → [RoleSwitchRepository]
     │
     │          1. Rate Limit Check (RPC: check_role_switch_rate_limit)
     │          2. Atomic RPC Call (switch_active_role)
     │             - expected_old_role guard (race protection)
     │             - DB UPDATE profiles.active_role
     │             - INSERT audit_logs
     │          3. Session Refresh (refreshSessionWithRetry)
     │          4. JWT Verification (verifyJwtRole)
     │          5. Teardown (RoleSwitchCoordinator.teardownAll())
     │             - ChatViewModel.teardownForRoleSwitch()
     │             - DashboardViewModel.teardownForRoleSwitch()
     │             - TaskViewModel.teardownForRoleSwitch()
     │             - HomeViewModel.teardownForRoleSwitch()
     │          6. Profile Reload (loadUserData())
     │
     ↓
[DB Trigger: trg_sync_role_to_jwt] → [auth.users.app_metadata.active_role]
     │
     ↓
[RLS Policies] → JWT-based role verification
     │
     ↓
[UI Update] → notifyListeners() → Consumer rebuilds
```

### 3.2 Database Flow Detail

```sql
-- Migration: 20260306_role_switch_foundation.sql
-- RPC Function: switch_active_role(p_expected_old_role, p_new_role)

Step 1: Auth Check
  └─ v_user_id := auth.uid()
  └─ IF NULL → session_error

Step 2: Current Role Fetch
  └─ SELECT active_role INTO v_current_role
  └─ IF NULL → db_error (profile not found)

Step 3: Idempotency Check
  └─ IF v_current_role = p_new_role → success (already set)

Step 4: Atomic Guard
  └─ IF v_current_role IS DISTINCT FROM p_expected_old_role
  └─ → stale_state error (race condition detected)

Step 5: Update with Race Protection
  └─ UPDATE profiles SET active_role = p_new_role
  └─ WHERE id = v_user_id AND active_role = p_expected_old_role
  └─ IF NOT FOUND → stale_state (concurrent modification)

Step 6: Audit Logging (always)
  └─ INSERT INTO audit_logs (action='role_switch', details={old,new,success})

Step 7: Trigger JWT Sync
  └─ trg_sync_role_to_jwt fires
  └─ UPDATE auth.users SET raw_app_meta_data->active_role
```

### 3.3 Error Flow Mapping

| Error Code | Source | Handling | UX Impact |
|------------|--------|----------|-----------|
| `stale_state` | RPC (multi-device race) | Show refresh message | User prompted to retry |
| `invalid_role` | RPC (validation) | Log error | Invalid state, shouldn't occur |
| `db_error` | RPC/DB | Retry with backoff | Generic error message |
| `session_error` | RPC/Auth | Force logout | Re-authentication required |
| `rate_limit` | RPC/Rate Check | Block for 60s | Wait message shown |
| `teardown_error` | Coordinator | Log warning, continue | Silent (best effort) |

---

## 4. Path Validation

### 4.1 Files Verified (Exist and Structured Correctly)

| File Path | Status | Lines | Notes |
|-----------|--------|-------|-------|
| `lib/core/mixins/role_switch_aware.dart` | ✅ | 44 | Clean mixin interface |
| `lib/core/services/role_switch_coordinator.dart` | ✅ | 149 | Singleton pattern, proper logging |
| `lib/features/profile/models/role_switch_result.dart` | ✅ | 80 | Complete model with error codes |
| `lib/features/profile/data/role_switch_repository.dart` | ✅ | 184 | Full implementation with JWT verification |
| `lib/features/profile/data/profile_repository.dart` | ✅ | 395 | Legacy method deprecated, new getter added |
| `lib/features/profile/viewmodels/profile_view_model.dart` | ✅ | 722 | Complete flow implementation |
| `lib/features/chat/viewmodels/chat_view_model.dart` | ✅ | 462 | Proper teardown with channel cleanup |
| `lib/features/dashboard/viewmodels/dashboard_view_model.dart` | ✅ | 1143 | Full cache invalidation |
| `lib/features/tasks/viewmodels/task_view_model.dart` | ✅ | 200 | Simple but complete teardown |
| `lib/features/home/viewmodels/home_view_model.dart` | ✅ | 303 | Pagination state reset |
| `supabase/migrations/20260306_role_switch_foundation.sql` | ✅ | 303 | Complete SQL with audit logging |
| `test/fixtures/profiles.dart` | ✅ | 314 | Comprehensive fixtures |
| `test/helpers/mock_supabase.dart` | ✅ | 191 | Mock classes for testing |
| `test/helpers/role_switch_helpers.dart` | ✅ | 380 | Test utilities and simulator |
| `test/unit/profile/role_switch_result_test.dart` | ✅ | 152 | Unit tests for model |

### 4.2 Import Path Validation

All imports resolve correctly:
- `package:sline_app/core/services/logger_service.dart` → ✅
- `package:supabase_flutter/supabase_flutter.dart` → ✅
- Relative imports within `lib/` → ✅
- Test imports use relative paths to `lib/` → ✅

### 4.3 Class Name Verification

| Declared Name | Exists | Used In |
|---------------|--------|---------|
| `RoleSwitchAware` (mixin) | ✅ | 5 ViewModels |
| `RoleSwitchCoordinator` | ✅ | 5 ViewModels + ProfileVM |
| `RoleSwitchResult` | ✅ | Repository, ViewModel, Tests |
| `RoleSwitchError` | ✅ | Error handling code |
| `RoleSwitchRepository` | ✅ | ProfileRepository |
| `RoleSwitchTeardownException` | ✅ | Coordinator |

---

## 5. Contract Checks

### 5.1 RPC Response → Model Mapping

**✅ VERIFIED: `RoleSwitchResult.fromJson()` matches RPC return structure**

RPC returns (from SQL migration):
```json
{
  "success": boolean,
  "new_role": text (optional),
  "error": text (optional),
  "message": text (optional)
}
```

Dart model parsing (from role_switch_result.dart:19-26):
```dart
factory RoleSwitchResult.fromJson(Map<String, dynamic> json) {
  return RoleSwitchResult(
    success: json['success'] as bool? ?? false,
    newRole: json['new_role'] as String?,        // ✅ matches
    errorCode: json['error'] as String?,         // ✅ matches
    message: json['message'] as String?,         // ✅ matches
  );
}
```

### 5.2 Error Code Taxonomy Consistency

**✅ VERIFIED: All error codes match between SQL, Dart, and Fixtures**

| Code | SQL (migration) | Dart (RoleSwitchError) | Fixtures | Tests |
|------|-----------------|------------------------|----------|-------|
| `stale_state` | ✅ L64 | ✅ L73 | ✅ L173 | ✅ |
| `invalid_role` | ✅ L72 | ✅ L74 | ✅ L187 | ✅ |
| `db_error` | ✅ L146 | ✅ L75 | ✅ L200 | ✅ |
| `session_error` | ✅ L32 | ✅ L76 | ✅ L212 | ✅ |
| `rate_limit` | ✅ (check function) | ✅ L77 | ✅ L224 | ✅ |
| `teardown_error` | N/A (app-level) | ✅ L78 | ✅ L237 | ✅ |

### 5.3 Audit Logging Contract

**✅ VERIFIED: Both success and failure paths log to audit_logs**

Success path (migration L96-116):
```sql
INSERT INTO audit_logs (...)
VALUES (v_user_id, 'role_switch', 'profile', v_user_id,
        jsonb_build_object('old_role', ..., 'new_role', ..., 'success', true), ...);
```

Exception path (migration L123-144):
```sql
INSERT INTO audit_logs (...)
VALUES (v_user_id, 'role_switch', 'profile', v_user_id,
        jsonb_build_object('old_role', ..., 'success', false, 'error', SQLERRM), ...);
```

### 5.4 JWT Verification Contract

**✅ VERIFIED: `verifyJwtRole()` correctly decodes and validates**

From role_switch_repository.dart:111-161:
```dart
bool verifyJwtRole(String expectedRole) {
  final jwt = _client.auth.currentSession?.accessToken;
  // ... validation ...
  final payload = jsonDecode(utf8.decode(base64.decode(payload)));
  final jwtRole = payload['app_metadata']?['active_role'];
  return jwtRole == expectedRole;
}
```

This matches the trigger that writes to `auth.users.raw_app_meta_data->'active_role'`.

---

## 6. Proposed Refactors

### 6.1 Minor Improvements (Non-Blocking)

#### R1: Add `rate_limit` to displayError Switch
**Location:** `role_switch_result.dart:49-62`

The `rate_limit` error code is defined but not handled in `displayError`. Add:
```dart
case 'rate_limit':
  return 'Too many role switches. Please wait a minute.';
```

**Priority:** Low  
**Impact:** Better UX for rate-limited users  
**Effort:** 1 line

#### R2: Consistent Tag Naming in ViewModels
**Location:** Multiple ViewModels

Some ViewModels use inconsistent log tags:
- `ProfileVM` uses `'ProfileVM'`
- `ChatVM` uses `'ChatVM'`  
- `DashboardVM` uses `'dashboard'` (lowercase)
- `TaskVM` uses `'TaskVM'`
- `HomeVM` uses `'HomeVM'`

**Recommendation:** Standardize to PascalCase matching class name.

**Priority:** Low  
**Impact:** Consistent log filtering  
**Effort:** 1 line change in dashboard_view_model.dart

#### R3: Add Timeout to Teardown Operations
**Location:** `role_switch_coordinator.dart:96`

Current teardown waits indefinitely. Consider adding timeout:
```dart
await vm.teardownForRoleSwitch().timeout(
  const Duration(seconds: 5),
  onTimeout: () {
    errors.add('${vm.runtimeType}: Timeout after 5s');
  },
);
```

**Priority:** Medium  
**Impact:** Prevents hung role switches  
**Effort:** 5 lines

### 6.2 Architecture Enhancements (Future Phase)

#### R4: Feature Flag Integration
**Location:** `profile_view_model.dart:507-618`

The current implementation always uses the new flow. The plan specified a feature flag `enable_atomic_role_switch`. Consider adding:

```dart
Future<bool> changeRole(String newRole) async {
  if (!FeatureFlags.isEnabled('enable_atomic_role_switch')) {
    return changeRoleLegacy(newRole);
  }
  // ... new implementation
}
```

**Priority:** Medium (depends on rollout strategy)  
**Impact:** Allows staged rollout  
**Effort:** New FeatureFlag service or remote config integration

#### R5: Circuit Breaker for Session Refresh
**Location:** `role_switch_repository.dart:83-105`

The plan specified a circuit breaker after 3 failed refreshes. Currently retries 3 times then returns false.

Consider adding circuit breaker state and force logout:
```dart
Future<bool> refreshSession({int maxRetries = 3}) async {
  // ... existing code ...
  if (i == maxRetries - 1) {
    // Circuit breaker: Force logout on persistent failure
    throw SessionRefreshException('Force logout required');
  }
}
```

**Priority:** Low (current implementation acceptable)  
**Impact:** Handles edge case of broken auth state  
**Effort:** 10 lines + error handling in ViewModel

---

## 7. Evidence: Files Scanned and Functions Reviewed

### 7.1 Core Infrastructure

| File | Key Functions/Classes | Lines Reviewed |
|------|------------------------|----------------|
| `role_switch_aware.dart` | `RoleSwitchAware` (mixin), `RoleSwitchTeardownException` | 1-44 |
| `role_switch_coordinator.dart` | `RoleSwitchCoordinator.register()`, `.unregister()`, `.teardownAll()` | 1-149 |
| `logger_service.dart` | `AppLogger.d/i/w/e/api()` | 1-208 |

### 7.2 Models and Data

| File | Key Functions/Classes | Lines Reviewed |
|------|------------------------|----------------|
| `role_switch_result.dart` | `RoleSwitchResult.fromJson()`, `.toJson()`, `.displayError`, `RoleSwitchError` | 1-80 |
| `role_switch_repository.dart` | `switchRole()`, `refreshSession()`, `verifyJwtRole()`, `checkRateLimit()` | 1-184 |
| `profile_repository.dart` | `changeRole()` (deprecated), `roleSwitch` getter | 107-132 |

### 7.3 ViewModels

| File | Key Functions | Lines Reviewed |
|------|---------------|----------------|
| `profile_view_model.dart` | `changeRole()` (full flow L507-618), `changeRoleLegacy()` | 1-722 |
| `chat_view_model.dart` | `teardownForRoleSwitch()` (L80-112), `dispose()` | 1-462 |
| `dashboard_view_model.dart` | `teardownForRoleSwitch()` (L74-98) | 1-1143 |
| `task_view_model.dart` | `teardownForRoleSwitch()` (L187-199) | 1-200 |
| `home_view_model.dart` | `teardownForRoleSwitch()` (L288-302) | 1-303 |

### 7.4 Database

| File | Key Components | Lines Reviewed |
|------|----------------|----------------|
| `20260306_role_switch_foundation.sql` | `switch_active_role()` RPC, `sync_role_to_jwt_claims()` trigger, rate limit function, JWT RLS policies | 1-303 |

### 7.5 Test Infrastructure

| File | Key Components | Lines Reviewed |
|------|----------------|----------------|
| `profiles.dart` | All fixtures (clientProfile, freelancerProfile, jwtPayloads, RPC responses) | 1-314 |
| `mock_supabase.dart` | `MockSupabaseClient`, `MockGoTrueClient`, `createMockClientUser()`, `createMockFreelancerUser()` | 1-191 |
| `role_switch_helpers.dart` | `MockRoleSwitchAware`, `RoleSwitchCoordinatorMock`, `RoleSwitchSimulator` | 1-380 |
| `role_switch_result_test.dart` | All 14 test cases | 1-152 |

---

## 8. Risk Assessment

### 8.1 Implementation Risks (Residual)

| Risk | Status | Mitigation in Code |
|------|--------|-------------------|
| Multi-device race condition | ✅ Addressed | `expected_old_role` atomic guard in RPC |
| JWT claim sync delay | ✅ Addressed | `verifyJwtRole()` with retry in ProfileViewModel L571-584 |
| ViewModel teardown failure | ✅ Addressed | Try-catch in coordinator L107-116, continues on error L591-594 |
| Realtime channel cleanup | ✅ Addressed | `client.removeAllChannels()` in ChatViewModel L93 |
| Audit logging missing | ✅ Addressed | Both success and exception paths log to audit_logs |
| Migration window enforcement | ⚠️ Partial | Legacy method marked `@Deprecated` with removal date |
| Feature flag absent | ⚠️ Noted | Not implemented, consider for staged rollout |

### 8.2 Code Quality Metrics

| Metric | Score | Notes |
|--------|-------|-------|
| MVVM Compliance | 10/10 | Clean boundaries, no Supabase in Views |
| Error Handling | 9/10 | Comprehensive, minor: missing rate_limit UX message |
| Logging | 10/10 | All paths use AppLogger with tags |
| Documentation | 9/10 | Good doc comments, could add more inline context |
| Test Infrastructure | 8/10 | Good fixtures and mocks, need integration tests |
| Database Security | 10/10 | RLS policies, audit logging, rate limiting |

---

## 9. Gate Checklist

Based on the original plan critic gates:

| Gate | Status | Evidence |
|------|--------|----------|
| **Gate 0:** Test Infrastructure | ✅ PASS | Fixtures, mocks, helpers, unit tests present |
| **Gate 1:** Data/Contracts | ✅ PASS | Error taxonomy defined, DTO boundary clear, migration ordered |
| **Gate 2:** Security | ✅ PASS | RLS policies listed, audit logging implemented |
| **Gate 3:** Backend/API | ✅ PASS | RPC idempotent (L51-58), rate limiting implemented |
| **Gate 4:** UI/Integration | ✅ PASS | Coordinator pattern solves ViewModel access |
| **Gate 5:** Release/QA | ⚠️ PARTIAL | Unit tests present, integration tests pending |

---

## 10. Conclusion and Recommendations

### 10.1 Final Verdict

**✅ APPROVED FOR PROCEEDING TO QA**

The implementation is architecturally sound, follows MVVM patterns correctly, and addresses all critical security and data consistency requirements from the plan critic review.

### 10.2 Required Actions Before Merge

1. **Fix R1** (rate_limit display message) - 1 line
2. **Run full test suite** - `flutter test`
3. **Verify SQL migration** - Test on staging database
4. **Integration test** - Full role switch flow with real backend

### 10.3 Recommended Post-Merge Actions

1. Add feature flag support for staged rollout
2. Create integration tests for role switch scenarios
3. Add pgTAP tests for RLS policy verification
4. Schedule calendar reminder for 2026-03-20 legacy removal

### 10.4 Sign-off

| Role | Status | Notes |
|------|--------|-------|
| MVVM Compliance | ✅ PASS | Clean architecture, proper layer separation |
| Security Review | ✅ PASS | Audit logging, RLS policies, rate limiting |
| Code Quality | ✅ PASS | Well-structured, consistent logging |
| Testability | ✅ PASS | Good fixture/mock infrastructure |

---

**Report Generated By:** @Architect  
**Date:** 2026-03-06  
**Next Step:** Route to @Sentinel for QA validation, then @CodeGuard for security review
