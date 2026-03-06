# FULL REPORT: 02 Role Switching Flow

## 0) Skill Selection

- **Skills selected**: Evidence-First Reading, State Machine & Lifecycle, Threat Modeling (Security), RLS & Privilege Boundaries, Diagram Crafting.
- **Why these fit**: Role switching is a state transition that dictates RLS access. Evidence-first reading verifies `active_role` behavior. Threat modeling stops users bypassing UI to hit APIs.
- **Skills not used**: DB-First Financial Modeling.

## 1) Folder Identity

- **Folder name + path**: `.TODO/improvement_the_system/Done/02_role-switching-flow`
- **What system/feature it describes**: Toggling between Client and Freelancer personas, rebuilding the UI and updating the session JWT.
- **Entities involved**: `auth.jwt()`, `switch_active_role` (RPC), `ProfileRepository`, `TaskViewModel`, `InboxViewModel`, `DashboardViewModel`.

## 2) Human Explanation

When a user clicks "Switch to Client/Freelancer", they aren't just changing a UI flag. The app calls an atomic RPC `switch_active_role` with an `expected_old_role` to prevent multi-device race conditions. Once the DB responds, the backend injects the new role into the `app_metadata` Custom Claim of their JWT via an Auth Hook. The client app is forced to await `refreshSession()`. Once the new token arrives, the app explicitly calls a "Teardown Contract" to cancel old realtime streams and clear caches (`TaskViewModel`, `InboxViewModel`) before reloading the Dashboard with the new permissions.

## 3) Symbol Legend

- **Circles**: App/Server states (Freelancer mode, Client mode).
- **Solid Arrows**: Synchronous RPC/Auth updates.
- **Dashed Arrows**: Asynchronous UI rendering / cleanup triggers.
- **Diamonds**: Logical checks (`expected_old_role == current_role`).

## 4) Extracted Contracts & Invariants

1. **Source of Truth Enforcement**: `auth.jwt() -> 'app_metadata' ->> 'active_role'` MUST be the definitive source of RLS. Do not join `profiles` for role checks.
2. **Hard Teardown Contract**: All scoped providers (`InboxViewModel.disconnectChannels()`) MUST be cleared on role switch before rendering the next view.

## 5) Conflict Scan Results

### 5.1 Naming Drift

- **Conflict**: Backend views refer to `freelancer_id` and `client_id`, while DB profiles only have `active_role`.
- **Resolution**: A single user UUID maps to `client_id` when acting as a client, and `freelancer_id` when acting as a freelancer.

### 5.2 Logic Drift

- **Conflict**: UI assumes changing a local bool instantly applies logic locks.
- **Resolution**: UI MUST wait for `switch_active_role` RPC and `refreshSession()` before granting access.

### 5.3 Data Model Drift

- **Conflict**: Old queries joined `profiles` to check `active_role`.
- **Resolution**: `switch_active_role` populated JWTs natively; replace all JOIN-based RLS with `auth.jwt() -> 'app_metadata'` reads.

## 6) Security & Failure Modes (Adversarial)

- **Race Condition / Double Taps**: User hits "Switch" twice. _Mitigation_: The `expected_old_role` parameter on the RPC rejects the atomic update.
- **API Bypass**: Client directly queries `task_requests` via Postman. _Mitigation_: RLS explicitly checks JWT claims to fail.

## 7) UI Mapping

### 7.1 Mobile App UI

- **Screens**: Settings Sidebar ("Switch Role" button).
- **States**: Loading (RPC + Session Refresh block), Rebuilding (Tearing down streams, recreating Home).
- **Guardrails**: Screen must freeze input during the 1-2s role switch window.

### 7.2 Admin Dashboard UI

- **Pages**: User profiles section.
- **Metrics**: Count of active clients vs freelancers.
- **Drilldowns**: Ability to force a user's role to a specific persona via Admin API if their account glitches.

### 7.3 Implementation Hooks

- `ProfileRepository.changeRole()` calls `switch_active_role` and `refreshSession`.
- ViewModels intercept success and execute `.clearCache()` and `.disconnectChannels()`.

## 8) Diagram Verdict + Best Diagram Type

- **Score now**: 9/10
- **Best Diagram Type**: Sequence Diagram (handles async RPC, token refresh, and teardown sequentially).

## 9) Upgrade Plan

- **Phase 0: Observability**: Wrap transition blocks with `AppLogger` ("role_switch_starting", "role_switch_success").
- **Phase 1: Contracts**: Enforce `auth.jwt()` lookups inside RLS policies for `tasks`, `task_requests`, `bookings`.
- **Phase 2: Hardening**: Implement the Flutter Teardown hooks in the ViewModels.
- **Phase 3: Database**: Deprecate join-based RLS.

## 10) Risks

### 10.1 Risks if current version kept

- **State Pollution**: High Risk. If `InboxViewModel` streams aren't canceled, clients will see freelance chats mixed into their inbox.

### 10.2 Risks introduced by fixes

- **UI Stutter/Delay**: Awaiting `refreshSession` can take ~400ms. _Mitigation_: Optimistic local loading states.

## 11) Test Plan (High-value)

- **Unit (RPC)**: Pass mismatched `expected_old_role`; verify Postgres Exception.
- **Integration**: Start as Client, open Home, Switch to Freelancer. Assert that previous Client lists are nullified.
- **Security (RLS)**: Authenticate as Client via cURL, attempt to `INSERT` into `task_requests`. Expect 403 Forbidden.

## 12) Production Checklist

- [ ] Supabase Auth Hook for JWT population deployed.
- [ ] `switch_active_role` RPC live.
- [ ] ViewModels contain `clearCache` routines hooked to the repository emit.
