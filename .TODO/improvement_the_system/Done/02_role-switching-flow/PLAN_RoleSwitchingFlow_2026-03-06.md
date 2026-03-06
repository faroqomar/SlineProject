# 📌 Plan: Role Switching Flow Hardening

## 1) Goal

- **Goal:** Harden the role switching feature to be atomic, secure, and free from state pollution. Replace the naive `UPDATE profiles SET active_role` with an atomic RPC that syncs to JWT custom claims, enforces explicit state teardown, and validates RLS policies.
- **Why:** The current implementation is vulnerable to race conditions (double taps, multi-device), lacks explicit state teardown (risking data leakage across personas), and relies on expensive RLS joins. JWT custom claims provide performance and security benefits.
- **Result:** A production-grade role switch flow with atomic guarantees, proper session refresh, explicit ViewModel teardown, and hardened RLS enforcement.

## 2) Scope

### In-Scope

- Atomic role switching via `switch_active_role` RPC with `expected_old_role` guard
- Supabase Auth Hooks to sync `active_role` to JWT `app_metadata` claims
- Session refresh (`supabase.auth.refreshSession()`) as a hard blocker
- Explicit state teardown contract: `ChatViewModel`, `DashboardViewModel`, `TaskViewModel`, `HomeViewModel`
- RLS policy audit and hardening for role-specific actions
- Observability: `AppLogger` events for role switch lifecycle
- Migration path for existing profiles (backfill JWT claims on login)

### Out-of-Scope

- New UI designs (reuse existing Profile Settings toggle)
- New tables or major schema changes (additive-only to `profiles.active_role`)
- Push notifications for role changes
- Admin/moderation features for forced role changes
- Historical role tracking/audit log table (out of MVP scope)

## 3) Evidence & Findings (From Scan)

### Existing

| Component | Location | Status |
|-----------|----------|--------|
| `changeRole()` naive implementation | `lib/features/profile/data/profile_repository.dart:104-112` | ✅ Exists, needs replacement |
| `changeRole()` ViewModel wrapper | `lib/features/profile/viewmodels/profile_view_model.dart:502-507` | ✅ Exists, needs enhancement |
| `DashboardViewModel.setRole()` | `lib/features/dashboard/viewmodels/dashboard_view_model.dart:251-290` | ✅ Exists, needs teardown hooks |
| `ChatViewModel` with subscriptions | `lib/features/chat/viewmodels/chat_view_model.dart:30-416` | ✅ Needs `disconnectChannels()` method |
| `ProfileModel.activeRole` | `lib/features/profile/models/profile_model.dart:7,39` | ✅ Exists |
| Old state diagram | `Sline_everything/AppDigram/All_Diagrams/02_role-switching-flow.md` | ⚠️ Needs replacement with sequence diagram |
| Holistic report with findings | `.TODO/improvement_the_system/ImplementReady/02_role-switching-flow/00_HOLISTIC_REPORT.md` | ✅ Comprehensive analysis available |
| Final sequence diagram (reference) | `.TODO/improvement_the_system/ImplementReady/02_role-switching-flow/06_DIAGRAM_FINAL.md` | ✅ Target architecture defined |

### Missing

| Component | Required For | Owner |
|-----------|--------------|-------|
| `switch_active_role` RPC | Atomic role switching with race condition guard | @Supabase_Ops |
| Supabase Auth Hook for JWT claims | Performance-optimized RLS (avoid profiles joins) | @Supabase_Ops |
| `ChatViewModel.disconnectChannels()` | Teardown contract - cancel realtime subscriptions | @Architect |
| `DashboardViewModel.resetAllCaches()` | Teardown contract - clear work items, bookings, inbox | @Architect |
| `TaskViewModel.clearCache()` | Teardown contract - clear task lists | @Architect |
| `HomeViewModel.clearCache()` | Teardown contract - clear home feed | @Architect |
| `ProfileRepository.switchRole()` (new method) | Call RPC instead of naive UPDATE | @Architect |
| Session refresh integration | Ensure JWT claims are fresh before UI unlock | @Architect |
| RLS policy updates | Enforce `active_role` checks on `task_requests`, `availability_slots` | @Supabase_Ops |

### Conflicts / Risks (docs vs code vs live DB drift, naming mismatches, security/migration risks)

1. **Drift Risk:** The existing `changeRole()` uses direct `UPDATE` while the holistic report specifies an RPC. Direct update must be deprecated, not modified in-place, to avoid breaking existing flow during migration window.
2. **JWT Claim Sync Risk:** If `refreshSession()` fails after DB update, user has new role in DB but old JWT claim. UI must detect this and either retry or revert.
3. **RLS Policy Risk:** Changing RLS to use JWT claims instead of `profiles` joins is a significant change. Must validate all existing queries still work.
4. **Multi-Device Race:** Two devices switching role simultaneously could create inconsistent state. `expected_old_role` guard mitigates this.

## 4) System Impact Map

- **UI:** Profile Settings screen (`profile_view.dart`) - minimal changes, enhance error handling
- **MVVM/App Logic:**
  - `ProfileRepository` - add new `switchRole()` method, deprecate `changeRole()`
  - `ProfileViewModel` - enhance `changeRole()` to call teardown contract, session refresh
  - `ChatViewModel` - add `disconnectChannels()`, `clearCache()` methods
  - `DashboardViewModel` - add `resetAllCaches()` method
  - `TaskViewModel` - add `clearCache()` method
  - `HomeViewModel` - add `clearCache()` method
- **Database:**
  - New RPC: `switch_active_role(expected_old_role, new_role)`
  - New trigger/hook: Sync `active_role` to `auth.users.app_metadata`
  - RLS policy updates: `task_requests`, `availability_slots`, `tasks` (if needed)
- **RLS/Security:** Move from `profiles.active_role` joins to `auth.jwt()->'app_metadata'->>'active_role'`
- **Realtime/Notifications:** Chat subscriptions must be explicitly canceled on role switch
- **Storage:** No impact
- **Observability:** Add `AppLogger` events: `role_switch_started`, `role_switch_success`, `role_switch_failed`, `role_switch_teardown_begin`, `role_switch_teardown_complete`
- **Compatibility & Migration:**
  - Existing `changeRole()` stays functional during migration
  - JWT claims backfilled on next login/session refresh
  - 2-week compatibility window before removing naive `changeRole()`
- **Contracts:**
  - RPC signature: `switch_active_role(p_expected_old_role text, p_new_role text)`
  - Returns: `{ success: boolean, new_role: text, error?: text }`

---

# ✅ Execution Phases (Checklist)

## Phase 0: Preconditions & Gates

> Primary: @Sentinel

### 0.1 Spec Lock

- [ ] (@Sentinel) Acceptance criteria defined:
  - Role switch completes within 3 seconds (including session refresh)
  - No data leakage between personas (verified by UI integration test)
  - Race condition blocked (verified by pgTAP test with concurrent RPC calls)
  - RLS policies enforce role restrictions (verified by negative tests)
- [ ] (@Architect) Confirm all affected modules:
  - `lib/features/profile/*`
  - `lib/features/dashboard/*`
  - `lib/features/chat/*`
  - `lib/features/tasks/*`
  - `lib/features/home/*`
- **Verify (@Sentinel):** done-conditions + rollback triggers documented

### 0.2 Threat Model (Security-sensitive: role bypass, state pollution)

- [ ] (@ThreatModeler) Create `.TODO/THREAT_MODEL_role_switching_2026-03-06.md` with:
  - Bypass scenarios: Direct API calls with wrong role JWT
  - State pollution scenarios: Chat messages from previous role visible
  - Race condition scenarios: Double-tap, multi-device simultaneous switch
  - Negative test cases for each scenario
- **Verify (@Sentinel):** testable and included in Phase 4

### 0.3 Contracts

- [ ] (@APIContract) Create `.TODO/CONTRACT_role_switching_2026-03-06.md` with:
  - RPC signature: `switch_active_role(p_expected_old_role text, p_new_role text)`
  - Return type: JSON object with `success`, `new_role`, optional `error`
  - Error codes: `stale_state`, `invalid_role`, `session_error`
  - Flutter ↔ DB mapping: RPC → Repository → ViewModel → UI
- **Verify (@Sentinel):** contract matches schema + shapes

### 0.4 Migration Plan

- [ ] (@DataMigration) Create `.TODO/MIGRATION_role_switching_2026-03-06.md` with:
  - Introduce: New RPC, Auth Hook, new Repository method
  - Backfill: JWT claims populated on next login/refresh
  - Enforce: RLS policies updated to use JWT claims (2-week window)
  - Compatibility: Keep `changeRole()` functional during window
  - Rollback: Revert to profiles-based RLS if issues arise
- **Verify (@Sentinel):** measurable compatibility window (14 days from deploy)

### 0.5 Feature Flag (Low-risk, but monitor rollout)

- [ ] (@Architect) Add `RoleSwitchCoordinator` class that can route to old or new implementation
- **Verify (@Sentinel):** rollback path documented (revert to `changeRole()` if RPC fails)

---

## Phase 1: Database & Security

> Primary: @Supabase_Ops

### 1.0 Live Supabase Confirmation (MANDATORY)

- [ ] (@Supabase_Ops) Re-scan via MCP for touched objects:
  - Confirm `profiles` table has `active_role` column
  - Confirm `auth.users` structure (for app_metadata updates)
  - Check existing RLS policies on `task_requests`, `availability_slots`, `tasks`
- [ ] (@Supabase_Ops) Confirm no naming conflicts with existing functions/triggers
- **Verify (@Sentinel):** drift + safe approach recorded

### 1.1 Schema (Additive-only)

- [ ] (@Supabase_Ops) Create migration file:
```sql
-- Migration: 20260306_switch_active_role_rpc

-- 1. Create RPC for atomic role switching
CREATE OR REPLACE FUNCTION switch_active_role(
  p_expected_old_role TEXT,
  p_new_role TEXT
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_current_role TEXT;
  v_user_id UUID;
BEGIN
  v_user_id := auth.uid();
  
  -- Get current role from profiles
  SELECT active_role INTO v_current_role
  FROM profiles
  WHERE id = v_user_id;
  
  -- Atomic guard: expected_old_role must match
  IF v_current_role IS DISTINCT FROM p_expected_old_role THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'stale_state',
      'message', 'Role was already changed or mismatch detected'
    );
  END IF;
  
  -- Validate new_role
  IF p_new_role NOT IN ('client', 'freelancer') THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'invalid_role',
      'message', 'Invalid role specified'
    );
  END IF;
  
  -- Update profiles
  UPDATE profiles
  SET active_role = p_new_role,
      updated_at = NOW()
  WHERE id = v_user_id;
  
  -- Update auth metadata (this requires Auth Hook or manual sync)
  -- Note: Auth Hook will handle JWT claim sync
  
  RETURN jsonb_build_object(
    'success', true,
    'new_role', p_new_role
  );
END;
$$;

-- 2. Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION switch_active_role(TEXT, TEXT) TO authenticated;

-- 3. Create helper to sync role to JWT claims (called by Auth Hook or manually)
CREATE OR REPLACE FUNCTION sync_role_to_jwt_claims()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Update auth.users app_metadata with current role
  -- This is a simplified version; actual implementation may use Auth Hook
  UPDATE auth.users
  SET raw_app_meta_data = COALESCE(raw_app_meta_data, '{}'::jsonb) || 
                          jsonb_build_object('active_role', NEW.active_role)
  WHERE id = NEW.id;
  
  RETURN NEW;
END;
$$;

-- 4. Create trigger to auto-sync on profile update
DROP TRIGGER IF EXISTS trg_sync_role_to_jwt ON profiles;
CREATE TRIGGER trg_sync_role_to_jwt
  AFTER UPDATE OF active_role ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION sync_role_to_jwt_claims();
```
- **Verify (@Sentinel):** migration is additive (no drops), indexes preserved

### 1.2 RLS Hardening

- [ ] (@Supabase_Ops) Audit and update RLS policies to use JWT claims:

```sql
-- Example: task_requests INSERT (only freelancers can submit proposals)
-- Old (slow - requires join):
-- CREATE POLICY task_requests_insert_freelancer ON task_requests
--   FOR INSERT WITH CHECK (
--     freelancer_id = auth.uid() AND
--     (SELECT active_role FROM profiles WHERE id = auth.uid()) = 'freelancer'
--   );

-- New (fast - uses JWT claim):
CREATE POLICY task_requests_insert_freelancer ON task_requests
  FOR INSERT WITH CHECK (
    freelancer_id = auth.uid() AND
    auth.jwt()->'app_metadata'->>'active_role' = 'freelancer'
  );

-- Similar updates for:
-- - availability_slots (insert/update requires freelancer)
-- - tasks (insert may require client, depending on business rules)
```

- [ ] (@Supabase_Ops) Create RLS matrix file `.TODO/RLS_MATRIX_role_switching_2026-03-06.md`
- **Verify (@Sentinel):** negative tests fail (client cannot insert task_request), positive tests pass

### 1.3 Auth Hook for JWT Claims (if Supabase supports)

- [ ] (@Supabase_Ops) Configure Auth Hook to sync `profiles.active_role` to `auth.users.app_metadata`
- If Auth Hooks not available, use trigger-based approach with `sync_role_to_jwt_claims()`
- **Verify (@Sentinel):** JWT token contains `active_role` claim after profile update

### 1.4 Migration Execution

- [ ] (@DataMigration) Run migration in order:
  1. Create RPC function
  2. Create sync trigger
  3. Add new RLS policies (WITH CHECK using JWT claims)
  4. (2-week window) Remove old policies that use joins
- **Verify (@Sentinel):** all queries pass, no performance regression

---

## Phase 2: App Layer (MVVM)

> Primary: @Architect

### 2.1 Models & Contract Compliance

- [ ] (@Architect) Create `RoleSwitchResult` model:
```dart
// lib/features/profile/models/role_switch_result.dart
class RoleSwitchResult {
  final bool success;
  final String? newRole;
  final String? errorCode;
  final String? message;
  
  RoleSwitchResult({
    required this.success,
    this.newRole,
    this.errorCode,
    this.message,
  });
  
  factory RoleSwitchResult.fromJson(Map<String, dynamic> json) {
    return RoleSwitchResult(
      success: json['success'] as bool,
      newRole: json['new_role'] as String?,
      errorCode: json['error'] as String?,
      message: json['message'] as String?,
    );
  }
}
```
- **Verify (@Sentinel):** types/nullability match contract

### 2.2 Services/Repositories

- [ ] (@Architect) Add new method to `ProfileRepository`:
```dart
// lib/features/profile/data/profile_repository.dart

/// Atomically switches user role with race condition protection.
/// This is the NEW implementation that replaces changeRole().
Future<RoleSwitchResult> switchRole({
  required String expectedOldRole,
  required String newRole,
}) async {
  AppLogger.i(
    'role_switch_started',
    tag: 'ProfileRepo',
    json: {'from': expectedOldRole, 'to': newRole},
  );
  
  try {
    final response = await _client.rpc(
      'switch_active_role',
      params: {
        'p_expected_old_role': expectedOldRole,
        'p_new_role': newRole,
      },
    );
    
    final result = RoleSwitchResult.fromJson(response as Map<String, dynamic>);
    
    if (result.success) {
      AppLogger.i(
        'role_switch_rpc_success',
        tag: 'ProfileRepo',
        json: {'new_role': result.newRole},
      );
    } else {
      AppLogger.w(
        'role_switch_rpc_failed',
        tag: 'ProfileRepo',
        json: {'error': result.errorCode, 'message': result.message},
      );
    }
    
    return result;
  } catch (e, st) {
    AppLogger.e(
      'role_switch_exception',
      tag: 'ProfileRepo',
      error: e,
      stackTrace: st,
    );
    return RoleSwitchResult(
      success: false,
      errorCode: 'exception',
      message: e.toString(),
    );
  }
}

/// Legacy method - mark as deprecated
@Deprecated('Use switchRole() for atomic role switching with race protection')
Future<void> changeRole({
  required String userId,
  required String newRole,
}) async {
  // ... existing implementation stays for compatibility
}
```
- **Verify (@Sentinel):** RLS-safe, no UI→Supabase calls

### 2.3 ViewModels - Teardown Contract Implementation

#### 2.3.1 ChatViewModel Enhancements

- [ ] (@Architect) Add teardown methods to `ChatViewModel`:
```dart
// lib/features/chat/viewmodels/chat_view_model.dart

/// Disconnects all realtime channels. Called during role switch teardown.
void disconnectChannels() {
  AppLogger.i('chat_disconnect_channels', tag: 'ChatVM');
  _msgSub?.cancel();
  _msgSub = null;
  _convoSub?.cancel();
  _convoSub = null;
}

/// Clears all cached data. Called during role switch teardown.
void clearCache() {
  AppLogger.i('chat_clear_cache', tag: 'ChatVM');
  conversations.clear();
  currentMessages.clear();
  _offerStatusCache.clear();
  activeConversation = null;
  _notify();
}

/// Combined teardown for role switch.
Future<void> teardownForRoleSwitch() async {
  AppLogger.i('chat_teardown_role_switch', tag: 'ChatVM');
  disconnectChannels();
  clearCache();
}
```

#### 2.3.2 DashboardViewModel Enhancements

- [ ] (@Architect) Add teardown methods to `DashboardViewModel`:
```dart
// lib/features/dashboard/viewmodels/dashboard_view_model.dart

/// Resets all cached data and loaded flags. Called during role switch.
void resetAllCaches() {
  AppLogger.i('dashboard_reset_all_caches', tag: 'DashboardVM');
  
  // Clear work items and computed caches
  _workItems = [];
  _invalidateWorkCaches();
  
  // Clear activity and other data
  _activityFeed = [];
  _counters = const DashboardCounters();
  _myTasks = [];
  _bookings = [];
  _inboxOffers = [];
  _pendingRequests = [];
  _pendingPaymentTenders = [];
  
  // Reset lazy-load flags
  _bookingsLoaded = false;
  _inboxLoaded = false;
  
  _safeNotify();
}

/// Teardown contract for role switch.
Future<void> teardownForRoleSwitch() async {
  AppLogger.i('dashboard_teardown_role_switch', tag: 'DashboardVM');
  resetAllCaches();
}
```

#### 2.3.3 TaskViewModel Enhancements

- [ ] (@Architect) Add to `TaskViewModel`:
```dart
// lib/features/tasks/viewmodels/task_view_model.dart

/// Clears all cached task data. Called during role switch.
void clearCache() {
  AppLogger.i('task_clear_cache', tag: 'TaskVM');
  // Clear any cached task lists, filters, etc.
  // Implementation depends on current TaskViewModel state
  notifyListeners();
}

Future<void> teardownForRoleSwitch() async {
  AppLogger.i('task_teardown_role_switch', tag: 'TaskVM');
  clearCache();
}
```

#### 2.3.4 HomeViewModel Enhancements

- [ ] (@Architect) Add to `HomeViewModel`:
```dart
// lib/features/home/viewmodels/home_view_model.dart

/// Clears home feed cache. Called during role switch.
void clearCache() {
  AppLogger.i('home_clear_cache', tag: 'HomeVM');
  // Clear feed cache
  notifyListeners();
}

Future<void> teardownForRoleSwitch() async {
  AppLogger.i('home_teardown_role_switch', tag: 'HomeVM');
  clearCache();
}
```

### 2.4 ProfileViewModel - Enhanced Role Switch

- [ ] (@Architect) Update `ProfileViewModel.changeRole()`:
```dart
// lib/features/profile/viewmodels/profile_view_model.dart

/// Changes user role with atomic protection, session refresh, and teardown contract.
/// This replaces the simple changeRole() with production-grade implementation.
Future<bool> changeRole(
  String newRole, {
  required ChatViewModel chatViewModel,
  required DashboardViewModel dashboardViewModel,
  required TaskViewModel taskViewModel,
  required HomeViewModel homeViewModel,
}) async {
  final user = _repo.currentUser;
  if (user == null) return false;
  
  // Get current role for expected_old_role guard
  final currentRole = _profile?.activeRole ?? 'client';
  if (currentRole == newRole) return true; // Nothing to do
  
  _isLoadingUpdate = true;
  _profileError = null;
  notifyListeners();
  
  AppLogger.i(
    'role_switch_initiated',
    tag: 'ProfileVM',
    json: {'from': currentRole, 'to': newRole},
  );
  
  try {
    // 1. Block UI during switch
    
    // 2. Call atomic RPC
    final result = await _repo.switchRole(
      expectedOldRole: currentRole,
      newRole: newRole,
    );
    
    if (!result.success) {
      _profileError = _mapRoleSwitchError(result.errorCode, result.message);
      AppLogger.w(
        'role_switch_failed',
        tag: 'ProfileVM',
        json: {'error': result.errorCode},
      );
      _isLoadingUpdate = false;
      notifyListeners();
      return false;
    }
    
    // 3. Session refresh - HARD BLOCKER
    AppLogger.d('role_switch_refreshing_session', tag: 'ProfileVM');
    final refreshResult = await _refreshSessionWithRetry();
    if (!refreshResult) {
      _profileError = 'Session refresh failed. Please log in again.';
      AppLogger.e('role_switch_session_refresh_failed', tag: 'ProfileVM');
      _isLoadingUpdate = false;
      notifyListeners();
      return false;
    }
    
    // 4. Execute teardown contract
    AppLogger.i('role_switch_teardown_begin', tag: 'ProfileVM');
    await Future.wait([
      chatViewModel.teardownForRoleSwitch(),
      dashboardViewModel.teardownForRoleSwitch(),
      taskViewModel.teardownForRoleSwitch(),
      homeViewModel.teardownForRoleSwitch(),
    ]);
    AppLogger.i('role_switch_teardown_complete', tag: 'ProfileVM');
    
    // 5. Update local profile state
    _profile = _profile?.copyWith(activeRole: newRole);
    
    // 6. Reload profile to confirm
    await loadUserData();
    
    AppLogger.i('role_switch_success', tag: 'ProfileVM');
    _isLoadingUpdate = false;
    notifyListeners();
    return true;
    
  } catch (e, st) {
    AppLogger.e(
      'role_switch_exception',
      tag: 'ProfileVM',
      error: e,
      stackTrace: st,
    );
    _profileError = 'Failed to switch role. Please try again.';
    _isLoadingUpdate = false;
    notifyListeners();
    return false;
  }
}

Future<bool> _refreshSessionWithRetry({int maxRetries = 3}) async {
  for (var i = 0; i < maxRetries; i++) {
    try {
      await Supabase.instance.client.auth.refreshSession();
      return true;
    } catch (e) {
      AppLogger.w(
        'session_refresh_attempt_failed',
        tag: 'ProfileVM',
        json: {'attempt': i + 1},
      );
      if (i < maxRetries - 1) {
        await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
      }
    }
  }
  return false;
}

String _mapRoleSwitchError(String? errorCode, String? message) {
  switch (errorCode) {
    case 'stale_state':
      return 'Your role was already changed elsewhere. Please refresh.';
    case 'invalid_role':
      return 'Invalid role selected.';
    case 'session_error':
      return 'Session error. Please log in again.';
    default:
      return message ?? 'Failed to switch role. Please try again.';
  }
}
```

### 2.5 Observability

- [ ] (@Observability) Instrument the role switch flow:
  - `role_switch_started` - when user initiates switch
  - `role_switch_rpc_success/failed` - RPC result
  - `role_switch_session_refreshed` - after successful refresh
  - `role_switch_teardown_begin/complete` - teardown contract
  - `role_switch_success/failed` - final outcome
- **Verify (@Sentinel):** no sensitive data in logs, consistent correlation IDs

---

## Phase 3: UI (After logic)

> Primary: @Pixel

### 3.1 Wiring

- [ ] (@Pixel) Update Profile Settings UI to pass ViewModels:
```dart
// In profile_view.dart or wherever role switch is triggered

// Get ViewModels from context
final chatViewModel = context.read<ChatViewModel>();
final dashboardViewModel = context.read<DashboardViewModel>();
final taskViewModel = context.read<TaskViewModel>();
final homeViewModel = context.read<HomeViewModel>();

// Call enhanced changeRole
final success = await profileViewModel.changeRole(
  'freelancer', // or 'client'
  chatViewModel: chatViewModel,
  dashboardViewModel: dashboardViewModel,
  taskViewModel: taskViewModel,
  homeViewModel: homeViewModel,
);

if (success) {
  // Show success, maybe navigate to dashboard
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Switched to Freelancer mode')),
  );
} else {
  // Error already set in ViewModel, show error
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(profileViewModel.profileError ?? 'Switch failed')),
  );
}
```
- **Verify (@Sentinel):** UI uses ViewModels only, loading/empty/error states handled

### 3.2 Polish (Optional)

- [ ] (@Pixel) Add loading indicator during role switch (blocks UI)
- [ ] (@Pixel) Add transition animation between personas (fade or slide)
- **Verify (@Sentinel):** no perf regression

---

## Phase 4: QA + Security (MANDATORY)

> Primary: @Sentinel

### 4.1 Contract + Migration Checks

- [ ] (@Sentinel) Verify `RoleSwitchResult` matches contract
- [ ] (@Sentinel) Run migration verify queries (RPC exists, trigger exists)
- **Verify (@Sentinel):** no mismatch

### 4.2 Security + Abuse Tests

- [ ] (@Sentinel) Execute ThreatModeler negative checks:
  - Attempt role switch with wrong `expected_old_role` (must fail)
  - Attempt concurrent role switches (only one should succeed)
  - Attempt direct `UPDATE profiles` bypass (verify RPC is enforced path)
- [ ] (@Sentinel) RLS leak audit:
  - Client JWT attempting `INSERT INTO task_requests` (must fail)
  - Client JWT attempting `INSERT INTO availability_slots` (must fail)
  - Freelancer JWT attempting `INSERT INTO task_requests` (must succeed)
- [ ] (@Sentinel) Storage audit: N/A (no storage changes)
- **Verify (@Sentinel):** unauthorized access impossible

### 4.3 Functional QA

- [ ] (@Sentinel) Manual E2E script:
  1. Open Profile Settings as Client
  2. Tap "Switch to Freelancer"
  3. Verify loading indicator appears
  4. Verify success message
  5. Navigate to Dashboard - should show Freelancer data
  6. Navigate to Chat - should not show old Client conversations
  7. Switch back to Client
  8. Verify proper restoration
- [ ] (@Sentinel) Edge cases:
  - Network failure during RPC
  - Network failure during session refresh
  - App killed mid-switch, restart
  - Double-tap on switch button (RPC guard should block)
  - Multi-device simultaneous switch (RPC guard should block one)
- **Verify (@Sentinel):** no crashes, consistent behavior

### 4.4 Performance QA

- [ ] (@Sentinel) Measure role switch time:
  - Target: < 3 seconds total (RPC + session refresh + teardown)
  - RPC execution: < 500ms
  - Session refresh: < 1 second
  - Teardown: < 500ms
- **Verify (@Sentinel):** meets performance targets

---

## Phase 5: Documentation Sync (MANDATORY)

> Primary: @SlineDocs

- [ ] (@SlineDocs) Update `Sline_everything/AppDigram/All_Diagrams/02_role-switching-flow.md`:
  - Replace state diagram with sequence diagram (use `06_DIAGRAM_FINAL.md` as reference)
  - Document teardown contract
  - Document RPC atomic guard
  - Document session refresh requirement
- [ ] (@SlineDocs) Update `Sline_everything/DEVELOPER_GUIDE.md`:
  - Add Role Switching section
  - Document ViewModel teardown pattern
  - Reference new RPC and RLS approach
- [ ] (@SlineDocs) Update `Sline_everything/SUPABASE_SETUP.md`:
  - Document `switch_active_role` RPC
  - Document Auth Hook/trigger for JWT claims
  - Document updated RLS policies
- **Verify (@Sentinel):** docs match code + live DB reality

---

## 7) Acceptance Criteria (MANDATORY)

| Criterion | Target | Verification |
|-----------|--------|--------------|
| **Correctness** | Role switch completes atomically with race protection | pgTAP test: concurrent RPC calls, only one succeeds |
| **Correctness** | No data leakage between personas | UI integration test: Inbox empty after switch |
| **Security** | RLS enforces role restrictions | pgTAP negative test: client JWT cannot insert task_request |
| **Security** | Race conditions blocked | pgTAP test: mismatched expected_old_role fails |
| **UX Stability** | Role switch completes in < 3 seconds | Performance test: measure RPC + refresh + teardown |
| **UX Stability** | Clear error messages for all failure modes | Manual QA: verify each error scenario |
| **Performance** | RLS queries use JWT claims (no joins) | EXPLAIN ANALYZE: no Seq Scan on profiles for RLS |
| **Compatibility** | 14-day migration window, old method still works | Deploy old + new side-by-side, verify both work |
| **Observability** | All role switches logged with correlation ID | Log audit: verify events present, no PII |

## 8) Rollback Plan

### DB Rollback

```sql
-- If RPC approach causes issues, revert to direct UPDATE:
-- 1. Disable RPC (don't delete, just revoke grants)
REVOKE EXECUTE ON FUNCTION switch_active_role(TEXT, TEXT) FROM authenticated;

-- 2. Revert RLS policies to use profiles joins
-- (Keep JWT policies as fallback, prioritize join-based)
-- Re-apply old policies from backup

-- 3. Remove Auth Hook trigger if causing issues
DROP TRIGGER IF EXISTS trg_sync_role_to_jwt ON profiles;
```

### App Rollback

1. Feature flag: Route `ProfileViewModel.changeRole()` to use legacy `ProfileRepository.changeRole()` instead of `switchRole()`
2. If issues detected:
   - Set feature flag to `useLegacyRoleSwitch = true`
   - Hotfix release with flag enabled
   - Investigate root cause
   - Re-enable new flow when fixed

### Emergency Disable

- Add remote config flag `enable_atomic_role_switch`
- If critical issues in production, set to `false` to force legacy path
- All users immediately revert to old behavior on next app start

## 9) References (From Scan)

### Documentation
- `Sline_everything/AppDigram/All_Diagrams/02_role-switching-flow.md` - Current (state diagram, to be replaced)
- `.TODO/improvement_the_system/ImplementReady/02_role-switching-flow/00_HOLISTIC_REPORT.md` - Comprehensive analysis
- `.TODO/improvement_the_system/ImplementReady/02_role-switching-flow/06_DIAGRAM_FINAL.md` - Target sequence diagram
- `.TODO/improvement_the_system/ImplementReady/02_role-switching-flow/07_SYSTEM_CRITIC_VERDICT.md` - Critical gaps identified
- `Sline_everything/DEVELOPER_GUIDE.md` - MVVM patterns
- `Sline_everything/SUPABASE_SETUP.md` - RLS patterns

### Code
- `lib/features/profile/data/profile_repository.dart` - Current naive implementation
- `lib/features/profile/viewmodels/profile_view_model.dart` - ViewModel to enhance
- `lib/features/chat/viewmodels/chat_view_model.dart` - Needs teardown methods
- `lib/features/dashboard/viewmodels/dashboard_view_model.dart` - Needs teardown methods
- `lib/features/tasks/viewmodels/task_view_model.dart` - Needs teardown methods
- `lib/features/home/viewmodels/home_view_model.dart` - Needs teardown methods

### Supabase (Live - via MCP)
- `profiles` table with `active_role` column
- `auth.users` table for JWT claims
- `task_requests`, `availability_slots` tables for RLS hardening
