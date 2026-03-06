# 00_HOLISTIC_REPORT: Role Switching Flow Audit

**Skills Selected:**

- **Evidence-First Reading:** Used to verify how `active_role` is handled in `ProfileRepository` and Supabase RPCs.
- **State Machine & Lifecycle:** Used to analyze the teardown and setup of Flutter app state when a persona switch occurs.
- **Threat Modeling (Security):** Used to identify bypass attacks where UI rules aren't enforced by DB constraints, specifically around atomic state.
- **RLS & Privilege Boundaries:** Used to evaluate how `active_role` is enforced at the database level and optimize the source of truth (JWT claims).
- **Diagram Crafting (Mermaid):** Used to redesign the diagram into a sequence flow accurately reflecting client-server interactions and synchronization.

**Why these skills fit:** Role switching is fundamentally a state machine transition that impacts authorization (RLS) and app lifecycle (UI streams). Evidence-first reading ensures all claims are backed by actual code (`ProfileRepository.changeRole`) or DB schema (`search_profiles`).

**Skills Intentionally Not Used:**

- _DB-First Financial Modeling:_ Not relevant to raw privilege swapping.
- _Idempotency & Concurrency:_ While concurrency matters for the atomic toggle, role switching is a singular user preference update, making state lifecycle and RLS boundaries the primary concern.

---

## A) What This Diagram Is

- **Description:** The diagram describes how a single authenticated user flips their active persona between "Client" and "Freelancer" within the SLine platform.
- **System Boundaries & Assumptions:** It assumes a single `profiles` table row per user, with an `active_role` column that dictates their current UI feed and available actions. It assumes the UI and DB remain in perfect sync and that state is properly torn down.

## B) Why It Exists

- **Problem Solved:** Allows a unified account system instead of forcing users to create two separate accounts for buying and selling services.
- **Risks Prevented:** Prevents UI clutter by hiding irrelevant features (e.g., hiding the "Post a job" button when in Freelancer mode), and restricts backend actions via RLS.

## C) Where It Lives in the Product

- **App Entry Points:** Profile Settings Screen -> "Switch to Freelancer" or "Switch to Client" toggle.
- **Service/Logic touchpoints:** `lib/features/profile/data/profile_repository.dart` -> `changeRole()`. ViewModels handling teardown (`TaskViewModel`, `InboxViewModel`, `DashboardViewModel`).
- **DB/RPC Dependencies:** `profiles.active_role` column. `auth.jwt() -> 'app_metadata' ->> 'active_role'`. `switch_active_role` RPC logic.

## D) Current Diagram Evaluation (Score)

- **Score AFTER System Critic Feedback:** 9/10
- **What's good:** It clearly illustrates the high-level intent, failure modes, session sync, and exact teardown contract.
- **What was missing previously:** It omitted the client-side state teardown (canceling Supabase realtime streams, clearing local provider caches), atomic RPC guards, and exact RLS matrices.
- **What was unsafe previously:** It portrayed the switch as instantaneous and flawless via a naive DB `update`, ignoring race conditions (multi-device) and state pollution (leaking client data to freelancer view).

## E) Extracted Invariants & Contracts

1. **Source of Truth Enforcement:** `auth.jwt() -> 'app_metadata' ->> 'active_role'` MUST be the definitive source of truth for RLS policies to prevent expensive and slow `profiles` table joins on every write/read.
2. **Atomic Role Switching:** Role changes MUST use an atomic RPC (`rpc('switch_active_role', { expected_old_role, new_role })`) to prevent race conditions resulting from double-taps or multi-device desynchronization.
3. **Session Refresh Check:** The client MUST await `supabase.auth.refreshSession()` on success to guarantee the new JWT claims are loaded before unlocking the UI.
4. **Hard Teardown Contract:** `TaskViewModel.clearCache()`, `InboxViewModel.disconnectChannels()`, and `DashboardViewModel.resetCounters()` MUST be triggered immediately upon a successful role switch before the new view is rendered.

## F) Failure Modes & Attack Scenarios

1. **State Pollution via Stream Retention**
   - _What happens now:_ If the user switches to Freelancer, but previous `TaskViewModel` streams aren't disposed, they might still receive underlying client updates in memory.
   - _Production Expectation:_ Switching role forces a hard reset of all scoped providers via the Teardown Contract.
   - _Missing Guardrails:_ Explicit `reset()` or stream `.cancel()` bounds in the ViewModels on role switch.
   - _Validation:_ Unit tests ensuring `disconnectChannels()` or `clearCache()` is called when `ProfileRepository.changeRole` resolves.
2. **API Bypass / Unauthorized Writes**
   - _What happens now:_ The UI blocks a Client from seeing task proposals, but a malicious user sending a direct Supabase REST call to `task_requests` might bypass this if standard RLS doesn't enforce `active_role`.
   - _Production Expectation:_ All RLS policies for persona-specific actions must explicitly check the JWT claim.
   - _Missing Guardrails:_ Strict `active_role` verification in all relevant RLS INSERT/UPDATE policies mapping (`task_requests`, `tasks`, `availability_slots`).
   - _Validation:_ DB-level pgTAP testing performing authorized and unauthorized inserts with mocked JWTs.
3. **Race Conditions / Double Taps**
   - _What happens now:_ A rapid double tap sends two concurrent `update profiles` requests.
   - _Production Expectation:_ The `switch_active_role` RPC atomically blocks the second request since `expected_old_role` no longer matches the current state.

## G) Production-Grade Improvement Plan

- **Phase 0: Observability & logs**
  - _Change:_ Wrap `ProfileRepository.changeRole` with `AppLogger` events (`role_switch_started`, `role_switch_success`, `role_switch_failed`).
  - _Why:_ To trace users who flip roles rapidly (potential abuse) or encounter network failures.
  - _Test:_ Monitor logs for `role_switch_*` events.
- **Phase 1: JWT Claims & Atomic RPC**
  - _Change:_ Implement `switch_active_role` RPC and use Supabase Auth Hooks to populate `app_metadata.active_role` in the JWT.
  - _Why:_ Atomic safety and drastic RLS performance improvements without joins.
  - _Test:_ Execute RPC with mismatched expected role (must fail).
- **Phase 2: Core contracts/invariants enforcement**
  - _Change:_ Implement flutter-side explicit state teardown (`InboxViewModel.disconnectChannels()`, etc.). Enforce `supabase.auth.refreshSession()`.
  - _Why:_ Prevents a freelancer from seeing their client-side inbox chats mixed with freelancer inquiries.
  - _Test:_ Automated UI integration test checking that Inbox is empty/reloaded after a switch.
- **Phase 3: Hardening the RLS Matrix**
  - _Change:_ Audit `SUPABASE_SETUP.md` RLS policies.
    - `tasks` (INSERT requires `client`)
    - `task_requests` (INSERT/UPDATE requires `freelancer`)
    - `availability_slots` (INSERT/UPDATE requires `freelancer`)
  - _Why:_ Secures the platform against backend direct-API abuse bypassing the UI.
  - _Test:_ Attempt an unauthorized insert using a raw Supabase client with a 'client' JWT.

## H) Best Diagram Recommendation

- **Best Type:** **Sequence Diagram**
- **Why:** A simple state diagram fails to capture the asynchronous nature of the database update, the atomic locks (`expected_old_role`), the `refreshSession` requirement, and the explicit teardown of local application state. A sequence diagram perfectly maps the exact order of operations needed to do this safely.

## I) Final Improved Diagram (Mermaid)

_(See `06_DIAGRAM_FINAL.md` for the rendering)_

## J) Risk Register

### J1) Risks if we keep the current system

- **Data Leakage (State Pollution) [Severity: High, Likelihood: Medium]**
  - _Evidence:_ The old flow implies UI simply flips the DB value without explicitly calling out stream lifecycle limits.
- **Server Overload via RLS Joins [Severity: Medium, Likelihood: High]**
  - _Evidence:_ Relying on `profiles` joins for every table row queried by active role causes severe database CPU overhead.
- **Bypass UI Logic [Severity: Critical, Likelihood: Low]**
  - _Evidence:_ Core tables might lack strict `active_role` RLS checks, relying too heavily on UI hiding.

### J2) Risks introduced by improvements

- **JWT Custom Claim Sync Delay [Severity: Low, Likelihood: Medium]**
  - _Risk:_ A token refresh is required post-DB update, causing a momentary desync if the network drops before refresh succeeds.
  - _Mitigation:_ Await `supabase.auth.refreshSession()` before resolving the UI state switch; if it fails, throw an error and revert local UI.
- **Complexity in Teardown [Severity: Medium, Likelihood: Medium]**
  - _Risk:_ Unsubscribing from all active realtime channels might cause stutter or missed events.
  - _Mitigation:_ Implement explicit methods (`clearCache`, `disconnectChannels`) on specific ViewModels rather than indiscriminately wiping the entire app memory tree.

## K) Verification Checklist (Production Readiness)

- [ ] **Unit Tests (View Models):** Test that calling `switchRole` explicitly calls `TaskViewModel.clearCache()` and `InboxViewModel.disconnectChannels()`.
- [ ] **Integration Tests (UI):** Render Profile view, switch role, wait for session refresh, verify Dashboard resets entirely and fetches new persona data.
- [ ] **Atomic DB Checks:** pgTAP tests attempting concurrent RPC calls to `switch_active_role` must correctly block one via `expected_old_role`.
- [ ] **RLS Checks (DB):** pgTAP tests asserting that a 'client' role JWT cannot write to `task_requests` or `availability_slots`.
- [ ] **Audit Logs:** Monitor `AppLogger` output to capture all role transitions.

## L) Final Verdict

- **Score AFTER fixes:** 9/10
- **Blockers to production:** Implementing the `switch_active_role` RPC with `expected_old_role` lock, Supabase Auth Hooks for JWT custom claims, and explicit Flutter state teardowns.
- **Ship criteria:** All Verification Checklist items pass, specifically the UI integration test proving no data crossover, and the pgTAP DB security tests verifying the JWT-based RLS action matrix.
