# 07_SYSTEM_CRITIC_VERDICT

## A) Verdict

_(Note: Notion MCP is unavailable in the current execution context, so the original `02_role-switching-flow.md` diagram was used as the OLD source)._

### OLD System Diagram Score: 2/10

**Evidence-based Reasons:**

1. **Lacks State Teardown (Evidence: Diagram entirely omits local cache/stream clearing).** Switching roles without clearing local view models leaks data across personas in memory.
2. **Missing RLS Enforcement Matrix (Evidence: Diagram stops at UI toggle).** Assumes DB constraints inherently know the active role without specifying _how_ this is evaluated on writes.
3. **No Failure Modes Covered (Evidence: Diagram only shows success paths).** Network failures during the DB update leave the UI in an inconsistent state.
4. **Race Condition Vulnerability (Evidence: Diagram shows a simple `App action: Switch`).** Lacks atomic guarantees if a user rapidly toggles or uses multiple devices.

### NEW System Artifacts Score: 7/10

**Evidence-based Reasons:**

1. **Identified Data Leakage (Evidence: `03_RISK_REGISTER` calls out State Pollution via Stream Retention).** Adds necessary focus on front-end teardown.
2. **Identified Unauthorized Writes (Evidence: `00_HOLISTIC_REPORT` section F2).** Recognizes the need for RLS enforcement beyond the UI.
3. **Introduced Sequence Diagram (Evidence: `06_DIAGRAM_FINAL`).** Correctly models the asynchronous nature and visualizes the database wait and session refresh.
4. **Indecisive on Source of Truth (Evidence: `00_HOLISTIC_REPORT` suggests "Audit all RLS... Or, move active_role into custom JWT claims").** Fails to make a firm architectural decision for production scale.
5. **Missing Atomic Switch Guards (Evidence: `06_DIAGRAM_FINAL` uses a naive `update profiles set active_role='freelancer'`).** Susceptible to race conditions (e.g., clicking twice, multi-device sync issues).

**Explicit FIXES in NEW vs OLD:**

- Added a teardown/reload contract step.
- Added explicit failure mode branching (SnackBars).
- Acknowledged `refreshSession()` requirement.
- Transitioned from a naive State diagram to a concrete Sequence diagram modeling the full client-server lifecycle.

---

## B) Critical Gaps in NEW Architecture

1. **Decision + Enforcement Plan for Source of Truth:** The plan is indecisive between `profiles` DB joins and JWT claims. **Decision enforced:** JWT Custom Claims using Supabase Auth Hooks (`app_metadata.active_role`). `profiles.active_role` is updated via RPC, which syncs to auth metadata, and RLS reads `auth.jwt() ->> 'active_role'`. This avoids N+1 queries during RLS evaluation.
2. **Atomic Switch Guard:** The `update profiles` query is prone to race conditions if executed concurrently. It must be replaced by a transactional RPC that asserts the expected previous state (`rpc('switch_active_role', { expected_old_role: 'client', new_role: 'freelancer' })`).
3. **Session Refresh Requirement:** It is mentioned but not strictly tied as a hard blocker. The UI _must_ await the token refresh before executing the ViewModel teardown/reload. If the token fails to refresh, the app must revert the local state or log out.
4. **Teardown Contract Exactness:** "Trigger State Teardown" is too vague. It must explicitly clear: `TaskViewModel.reset()`, `InboxViewModel.disconnectChannels()`, `DashboardViewModel.clearCounters()`.
5. **RLS Matrix:** The report loosely says "freelancer tables". It must explicitly list: `task_requests` (insert/update requires `freelancer`), `availability_slots` (requires `freelancer`), `tasks` (insert requires `client`).

---

## C) Minimal Necessary Improvements

1. **Change:** Replace naive `update profiles` with `rpc('switch_active_role', { expected_old_role, new_role })`.
   - **Why it matters:** Prevents race conditions and lost updates from multi-device toggling or double clicks.
   - **How to verify:** pgTAP test trying to switch from `freelancer` to `freelancer` using `expected_old_role='client'`, which must fail.
2. **Change:** Mandate JWT Custom Claims (`auth.jwt() -> 'app_metadata' ->> 'active_role'`) as the RLS source of truth.
   - **Why it matters:** Drastically improves database performance by removing slow joins from high-frequency RLS policies.
   - **How to verify:** Integration test asserting RLS policies pass/fail using mocked JWT tokens with/without the correct claim.
3. **Change:** Detail the teardown contract explicitly in the diagram and report.
   - **Why it matters:** Developers need to know exactly which Providers/ViewModels to clear to prevent data contamination.
   - **How to verify:** Unit test asserting `mockInboxViewModel.disconnectChannels()` is called when `changeRole` succeeds.
4. **Change:** Update the Sequence Diagram to include the RPC, the atomic guard, and the explicit provider teardowns.

**(Note: These improvements have been applied to `00_HOLISTIC_REPORT.md` and `06_DIAGRAM_FINAL.md`).**
