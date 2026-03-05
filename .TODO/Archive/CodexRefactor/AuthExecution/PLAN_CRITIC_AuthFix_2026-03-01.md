## A) Assumptions + Decision Needed (Blocking)

### Assumptions

- The current target remains the `Auth` feature bounded to `lib/features/auth/**` and its direct dependencies already captured in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_AuthFix_2026-03-01.md`.
- The live Supabase project scanned is the same project used by `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/services/supabase_config.dart:15-29`.
- Auth fixes must preserve strict MVVM boundaries and keep privileged actions server-side or RLS-enforced only.
- Existing test harnesses under `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/test_support/` and `/Users/eros/Dev/Eros_Projects/Sline/sline_app/integration_test/support/` are the starting point, not something to replace.
- The corrected plan should stay additive-first for DB work because live drift already exists (`auth.users=6`, `public.profiles=4`, `auth_users_missing_profile=2`).

### Decision Needed (Blocking)

1. Missing decision: what is the canonical profile bootstrap authority.
- Options:
  - Keep client-side `public.profiles.insert(...)` and only patch error handling.
  - Move to `auth.users` trigger only.
  - Move to `auth.users` trigger plus temporary authenticated self-heal RPC during rollout.
- Recommended: `auth.users` trigger plus temporary authenticated self-heal RPC during rollout.
- Why: trigger-only is the right steady state, but live DB already has 2 auth users without profile rows, so rollout needs a compatibility path instead of assuming backfill completes before every login.
- What changes in the plan depending on the choice:
  - Client-side insert: smaller app patch, but the root integrity problem remains.
  - Trigger only: cleaner target, but higher rollout risk if missing-profile users log in before backfill or trigger activation is verified.
  - Trigger + self-heal RPC: more work, but safest migration path and easiest rollback.

2. Missing decision: how `full_name` reaches server-side profile bootstrap.
- Options:
  - Pass `full_name` in `signUp` auth metadata.
  - Create the profile with blank `full_name` and force later completion.
  - Keep client-side profile insert just for `full_name`.
- Recommended: pass `full_name` in auth metadata.
- Why: it preserves signup UX, avoids a second client write, and gives the trigger enough context to create the row deterministically.
- What changes in the plan depending on the choice:
  - Metadata: contract and migration work needed, but no second client write.
  - Blank name: simpler backend, worse UX and extra profile-completion logic.
  - Client insert: keeps the current partial-write risk.

3. Missing decision: password recovery completion UX.
- Options:
  - Open app on callback and force user into a dedicated reset-password update screen.
  - Return to login and rely on external/web flow.
  - Leave recovery initiation only and do not complete in-app.
- Recommended: dedicated in-app reset-password update screen.
- Why: current mobile deep-link schemes already exist, and stopping at initiation leaves recovery incomplete in the Flutter app.
- What changes in the plan depending on the choice:
  - In-app screen: requires route, state handling, and tests.
  - Login redirect only: lower implementation scope, but weaker UX and unclear mobile completion path.
  - No completion: release blocker remains.

4. Missing decision: delivery slicing.
- Options:
  - One PR for DB, app logic, UI, tests, and docs.
  - Two PRs: DB/security first, app/tests/docs second.
  - Three PRs: test/contract baseline, DB/security migration, app/UI/tests/docs.
- Recommended: three PRs.
- Why: auth changes cross live DB, migration safety, app session logic, and user-entry flows. One or two large slices increase rollback complexity.
- What changes in the plan depending on the choice:
  - One PR: faster on paper, highest rollback risk.
  - Two PRs: acceptable, but still mixes too much risk in the app phase.
  - Three PRs: safest review and rollback path.

5. Missing decision: canonical app contract for `profiles.email`.
- Options:
  - Keep writing and reading cached `profiles.email`.
  - Stop writing it for new rows but keep it for compatibility reads.
  - Remove it from auth contract immediately.
- Recommended: stop depending on it for auth correctness, but keep the column for compatibility in this plan.
- Why: immediate removal broadens scope into profile-wide contract cleanup; keeping it while decoupling auth correctness is the least risky path.
- What changes in the plan depending on the choice:
  - Keep as-is: drift risk remains.
  - Compatibility-only: safest transition.
  - Remove immediately: requires cross-feature profile cleanup not in current scope.

## B) Gate Status (Pass/Fail)

### Gate 0: Test Infrastructure Gate
- Status: ❌ FAIL
- Reason:
  - The current plan adds multiple new unit/widget/integration tests but does not define a shared auth-specific test bootstrap phase first.
  - There is no selector/key plan for signup, forgot-password, or future reset-password completion screens, while current tests only cover login selectors in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/auth/login_screen_test.dart:74-179`.
  - The current plan does not define fixture/env requirements for recovery/session-expiry integration runs beyond the existing login preflight harness in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/integration_test/app_startup_login_flow_test.dart:9-62`.
- What to add/fix to pass:
  - Add a dedicated test-infrastructure subphase before contract or migration work.
  - Add auth selector map, integration fixture manifest, env injection contract, failure artifact path, timeout budgets, and rerun policy.

### Gate 1: Data/Contracts Gate
- Status: ❌ FAIL
- Reason:
  - The plan leaves bootstrap strategy as “trigger and optional RPC” instead of locking a single rollout design.
  - The plan does not explicitly lock how `full_name` reaches the server bootstrap path.
  - The plan does not include a self-profile lifecycle/state contract for missing-profile login, recovery, and signed-out events.
- What to add/fix to pass:
  - Lock bootstrap source, compatibility RPC policy, and metadata contract in Phase 0.
  - Add an auth event/state matrix artifact.
  - Add a typed self-profile contract using `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/models/user_profile.dart:1-32`.

### Gate 2: Security Gate
- Status: ❌ FAIL
- Reason:
  - The plan identifies duplicate `profiles` INSERT policies but does not make policy reconciliation a release gate with explicit before/after counts.
  - Password recovery callback handling is still described as work to do, not a hard release blocker.
  - PII logging removal is planned but not enforced as a must-pass verification item before release.
- What to add/fix to pass:
  - Make password recovery completion and PII-safe logging non-negotiable release checks.
  - Add exact RLS verify queries and expected counts.
  - Add a privacy grep/redaction check to the QA gate.

### Gate 3: Backend/API Gate
- Status: ❌ FAIL
- Reason:
  - The plan does not explicitly sequence “tolerant app logic first” ahead of DB trigger enforcement.
  - It does not define the exact self-heal RPC contract or when it is allowed to be removed.
  - It does not lock auth metadata usage for signup before app-layer repository refactors.
- What to add/fix to pass:
  - Add phased rollout order with stop/go criteria between steps.
  - Add exact compatibility-window exit criteria.
  - Add explicit signup metadata contract work before repository implementation.

### Gate 4: UI/Integration Gate
- Status: ❌ FAIL
- Reason:
  - The plan calls for a reset screen but does not define a screen-state matrix for login/signup/forgot/reset flows.
  - It does not require stable keys for the new screens and critical actions.
  - It does not define expected UI behavior for “valid auth session, missing profile row” before navigation.
- What to add/fix to pass:
  - Add an auth UI state matrix artifact.
  - Add a selector/key contract for all critical auth widgets.
  - Add acceptance criteria for missing-profile recovery states.

### Gate 5: Release/QA Gate
- Status: ❌ FAIL
- Reason:
  - The current plan lacks explicit PR slicing, review gates, and per-slice definition of done.
  - It does not define a release go/no-go checklist tied to DB verify queries, auth flows, and docs sync.
  - It does not define bounded flake handling for the new integration tests.
- What to add/fix to pass:
  - Add three-PR delivery slices with gate checks.
  - Add final release checklist.
  - Add retry/flake policy and failure artifact capture.

## C) Critical Gaps (Must-Fix)

### Gap 1
- Gap: No test infrastructure gate precedes the new auth tests.
- Why it will break: new widget/integration tests will be written against unstable selectors and ad hoc env assumptions, then get skipped or flake.
- Fix (exact step(s) to add / reorder):
  - Add `Phase 0.0 Test Infrastructure Gate` before spec lock.
  - Create `.TODO/TEST_INFRA_AuthFix_2026-03-01.md`.
  - Define selector map, env contract, fixture manifest, timeout budget, failure artifact path, and rerun policy.
- Owner: Frontend
- Acceptance check: auth test infra artifact exists and every planned auth test references stable selectors and documented preflight requirements.

### Gap 2
- Gap: Bootstrap authority is still ambiguous.
- Why it will break: implementation can drift into half-trigger, half-client behavior and keep the orphan-profile problem alive.
- Fix (exact step(s) to add / reorder):
  - Add a blocking decision in Phase 0 choosing `auth.users` trigger + temporary self-heal RPC.
  - Rewrite Phase 1 and Phase 2 to match that decision only.
- Owner: Backend
- Acceptance check: plan contains one bootstrap strategy and one rollout-removal condition for the self-heal RPC.

### Gap 3
- Gap: No explicit auth state machine exists for login/signup/reset/session events.
- Why it will break: `signedOut`, `passwordRecovery`, and missing-profile login paths will be implemented inconsistently across app shell and screens.
- Fix (exact step(s) to add / reorder):
  - Add `.TODO/STATE_MACHINE_AuthFix_2026-03-01.md` before backend or UI work.
  - Define event -> ViewModel state -> route/action mapping.
- Owner: Frontend
- Acceptance check: every auth event path has exactly one documented app behavior and one test target.

### Gap 4
- Gap: The plan does not lock how `full_name` gets to server-side bootstrap.
- Why it will break: the trigger can create incomplete profiles or the app can silently reintroduce a second client write.
- Fix (exact step(s) to add / reorder):
  - Add metadata payload contract to Phase 0 contracts.
  - Add repository update step before DB trigger rollout.
- Owner: Backend
- Acceptance check: signup contract explicitly includes `full_name` metadata and no client `profiles.insert(...)` remains.

### Gap 5
- Gap: Password recovery completion is not treated as a release blocker.
- Why it will break: the app can still ship with only reset initiation implemented.
- Fix (exact step(s) to add / reorder):
  - Move reset completion requirements into acceptance gates and release checklist.
  - Add dedicated reset screen, route, and end-to-end test as mandatory work, not optional UI work.
- Owner: Frontend
- Acceptance check: recovery flow passes manual and integration verification before release.

### Gap 6
- Gap: Missing-profile rollout handling is underspecified.
- Why it will break: current live users without `profiles` rows can still hit login issues even after a trigger is added.
- Fix (exact step(s) to add / reorder):
  - Add a compatibility-window contract and exact exit criteria.
  - Add pre/post migration count queries and app fallback behavior during the window.
- Owner: Backend
- Acceptance check: rollout steps explicitly prove `auth_users_missing_profile = 0` before compatibility code removal.

### Gap 7
- Gap: Release slicing and review workflow are absent.
- Why it will break: DB, auth logic, UI, tests, and docs can land in one risky, hard-to-rollback batch.
- Fix (exact step(s) to add / reorder):
  - Add three PR slices and definition of done per slice.
  - Add gate check after each slice.
- Owner: Product
- Acceptance check: the corrected plan names the slices, owners, gate checks, and rollback points.

### Gap 8
- Gap: Observability/privacy validation is too soft.
- Why it will break: auth may stop failing functionally but still leak email fragments or give poor diagnostics in rollout.
- Fix (exact step(s) to add / reorder):
  - Add privacy grep/log audit to QA gate.
  - Add minimal auth event taxonomy and correlation strategy.
- Owner: Infra
- Acceptance check: failure logs are actionable and no raw email/token values appear in auth instrumentation.

## D) Invariants & Success Criteria (Non-Negotiable)

1. Invariant: `public.profiles` bootstrap is server-authoritative for new auth users.
- How to enforce: `auth.users` trigger/function with locked `search_path`; no client `profiles.insert(...)` in auth repository.
- How to verify: grep check for `from('profiles').insert` in auth code returns zero; DB trigger exists; signup creates profile row automatically.

2. Invariant: login success is not blocked by optional profile enrichment.
- How to enforce: sign-in success path separated from tolerant self-profile fetch/self-heal path.
- How to verify: unit/integration test where sign-in succeeds and profile read is missing/transiently failing still leads to recoverable app state.

3. Invariant: base-table `public.profiles` reads remain self-only.
- How to enforce: RLS policies restricted to `auth.uid() = id`; cross-user access only through safe-summary RPCs.
- How to verify: allowed/forbidden RLS checks on live DB.

4. Invariant: password reset is a complete flow, not just a request flow.
- How to enforce: dedicated reset-password completion screen and auth event handling for recovery callback.
- How to verify: end-to-end recovery test passes.

5. Invariant: only one auth session listener is active app-wide.
- How to enforce: global session ViewModel only; screens do not instantiate listener-owning auth VMs.
- How to verify: grep for `AuthViewModel()` or equivalent session-VM constructors in auth screens returns zero after refactor.

6. Invariant: auth logs and crash instrumentation do not contain raw email or token values.
- How to enforce: remove masked-email auth logs and add redaction verification.
- How to verify: grep/log review in QA gate.

7. Invariant: rollout is safe for users already missing `profiles` rows.
- How to enforce: backfill plus temporary self-heal RPC compatibility window.
- How to verify: live verify query reaches zero missing profiles before compatibility removal.

8. Invariant: docs reflect live schema and final auth contract in the same release slice.
- How to enforce: docs-sync phase is mandatory and blocks release.
- How to verify: updated `DEVELOPER_GUIDE.md`, `SUPABASE_SETUP.md`, `STRUCTURE.md`, and roadmap entries match code and DB reality.

## E) Risk Register (Predict Problems)

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|------|-------|------------|--------|--------------|-------------|-----------|----------|
| Trigger bootstrap writes wrong or incomplete profile fields | live `auth.users` -> `public.profiles` | Med | High | Feature | New signup creates profile with null/incorrect `full_name` | Lock auth metadata contract and test trigger on staging | Keep self-heal RPC active and patch trigger function quickly |
| Missing-profile users still fail login during rollout | login bootstrap path | High | High | Feature | Valid login returns error or stalls before navigation | Ship tolerant app logic before removing client assumptions | Keep compatibility self-heal path until counts hit zero |
| Password recovery callback opens app but does not reach update-password state | mobile deep-link flow | Med | High | Feature | Reset link opens login screen with no update form | Add explicit recovery state machine and route handling | Temporarily route users to a fallback recovery instruction screen |
| Duplicate session listeners remain after refactor | app shell + auth screens | High | Med | Feature | Duplicate logs/navigation callbacks on sign-out | Remove per-screen auth listener providers and grep for them in QA | Fallback to one root session VM and read-only local form VMs |
| PII logging survives refactor | auth repository / crash hooks | Med | Med | Security-breach | Logs still show masked or raw email fragments | Add privacy grep/log audit as release gate | Disable non-essential auth info logs until cleanup is complete |
| Duplicate INSERT policies are cleaned up incorrectly | live `pg_policies` on `public.profiles` | Med | High | Feature | Signup/profile insert starts failing with 42501 | Verify exact before/after policy counts and behavior | Restore removed policy via rollback SQL |
| New integration tests flake due to env/account drift | `integration_test/` auth flows | High | Med | Delivery | Tests skip late or fail intermittently on missing accounts | Add fixture manifest, preflight, timeout budgets, rerun policy | Fall back to manual gate while stabilizing harness |
| Docs remain stale on `role` vs `active_role` | `Sline_everything/DEVELOPER_GUIDE.md` | High | Low | Team workflow | Engineers reimplement wrong field names | Make docs-sync a blocking gate | Patch docs in same release slice before merge |

## F) Pre-Mortem (How this fails in real life)

- This fails when the trigger is added, but signup still sends no `full_name` metadata, so new users get blank profile names and the team silently reintroduces a client patch.
- This fails when login is “fixed” in code, but one of the two existing missing-profile users still cannot get through because the compatibility window was removed too early.
- This fails when the reset email opens the app correctly, but there is no reset-password update screen, so support thinks deep linking works while users still cannot recover accounts.
- This fails when the session listener split is implemented, but one auth screen still constructs its own listener-owning ViewModel and produces duplicate redirects.
- This fails when DB policy cleanup removes the wrong INSERT policy before trigger/backfill verification and new signup starts returning RLS errors.
- This fails when widget tests are added for signup/reset without stable keys and then become brittle enough that the release gate ignores them.
- This fails when docs still mention `role` while code and DB use `active_role`, causing follow-up fixes to target the wrong field.
- This fails when auth logs remain “masked but identifying,” and the rollout solves correctness while leaving a privacy issue behind.

## G) Plan Fixes (Concrete Additions / Expansions)

1. Goal: establish test infrastructure before feature changes.
- Why: new tests are planned across unit/widget/integration layers, but shared setup is missing.
- How: add `TEST_INFRA_AuthFix_2026-03-01.md` with selector map, fixture manifest, env contract, command docs, failure artifact path, flake thresholds, and timeout budgets.
- Output artifact: test harness/helper + fixture manifest.
- Stop condition: all planned auth tests reference stable selectors and documented env prerequisites.

2. Goal: lock the bootstrap strategy.
- Why: the current plan leaves trigger vs RPC as an open branch.
- How: choose `auth.users` trigger + temporary self-heal RPC and rewrite all downstream steps to follow that path only.
- Output artifact: contract decision note + migration plan.
- Stop condition: the corrected plan contains one canonical bootstrap design and one compatibility removal rule.

3. Goal: define the auth event/state machine.
- Why: signed-out, password recovery, and missing-profile login behavior are still underspecified.
- How: add `STATE_MACHINE_AuthFix_2026-03-01.md` for auth events, UI states, and navigation results.
- Output artifact: state machine doc.
- Stop condition: every auth event and failure mode has one route/action outcome.

4. Goal: define server-readable signup metadata.
- Why: server bootstrap needs `full_name` without a second client DB write.
- How: add metadata payload to the API contract and update repository tasks accordingly.
- Output artifact: contract doc + repository update task.
- Stop condition: signup contract explicitly carries `full_name` metadata.

5. Goal: turn recovery completion into a release requirement.
- Why: password reset initiation alone is not enough.
- How: move reset completion screen, route, and end-to-end test into mandatory work and release criteria.
- Output artifact: reset screen + integration test.
- Stop condition: recovery request and completion both pass verification.

6. Goal: make rollout safe for already-bad data.
- Why: 2 existing auth users are already missing profile rows.
- How: add exact rollout order, verify queries, compatibility window, and exit criteria.
- Output artifact: migration/rollout checklist.
- Stop condition: missing-profile count is zero before compatibility code removal.

7. Goal: make release reviewable.
- Why: auth changes span DB, app logic, UI, tests, and docs.
- How: add three PR slices with gate checks and definition of done.
- Output artifact: release checklist / PR plan.
- Stop condition: each slice can merge independently with a rollback point.

8. Goal: harden privacy and diagnostics together.
- Why: auth failures need actionable telemetry without PII leakage.
- How: add auth event taxonomy, correlation strategy, and privacy grep/log audit.
- Output artifact: observability note.
- Stop condition: QA confirms useful signals and no raw email/token leakage.

## H) Corrected Plan (Execution-Ready, Gate-Based)

### Phase 0: Test Infrastructure + Contract Lock
- Goal: eliminate ambiguity before touching DB or app logic.
- Why: the current plan is blocked by missing test infra, bootstrap design ambiguity, and incomplete auth event contracts.
- How:
  - Build auth test infra artifact.
  - Lock bootstrap strategy to `auth.users` trigger + temporary self-heal RPC.
  - Lock `full_name` metadata contract.
  - Create auth event/state machine for login/signup/reset/signed-out/recovery.
  - Define three PR slices and definition of done.
- Result: deterministic baseline and no foundational ambiguity.
- GATE CHECK: selector map, fixture manifest, bootstrap decision, metadata contract, state machine, and PR slicing are all documented.

### Phase 1: Data/Contracts + Security/RLS
- Goal: make `public.profiles` bootstrap and access rules server-authoritative and auditable.
- Why: live DB already has missing profiles and duplicate insert-policy drift.
- How:
  - Introduce trigger/function and optional temporary self-heal RPC.
  - Backfill missing profiles.
  - Verify counts and trigger existence.
  - Reconcile duplicate INSERT policy only after behavior verification.
  - Preserve self-only base-table profile access.
- Result: live DB is consistent and auth-safe.
- GATE CHECK: missing-profile count is zero or compatibility path is proven safe; policies and trigger behavior are verified.

### Phase 2: Backend/App Logic
- Goal: make auth correctness independent from profile drift and remove client bootstrap writes.
- Why: current login and signup still rely on fragile client-side assumptions.
- How:
  - Split session vs form ViewModels.
  - Rework repositories around the new bootstrap contract.
  - Replace raw map profile reads with typed mapping.
  - Centralize reset initiation.
  - Use explicit signed-out/session-expired handling.
- Result: single-source auth state and tolerant login/signup flows.
- GATE CHECK: no client `profiles.insert(...)`, no duplicate listener providers, typed self-profile path in place.

### Phase 3: UI Wiring + Recovery UX
- Goal: align screens to the new auth contracts and complete recovery UX.
- Why: current screens duplicate providers and do not cover recovery completion.
- How:
  - Rewire login/signup/forgot-password to form/session VMs only.
  - Add reset-password update screen and route.
  - Define/loading empty error stale states for auth screens.
  - Disable/remove no-op social buttons.
  - Add stable keys for all critical auth actions.
- Result: stable, testable, complete auth UX.
- GATE CHECK: screens compile against new VMs, recovery route works, and stable selectors exist.

### Phase 4: QA + Security + Observability
- Goal: prove correctness, privacy, and rollout safety before release.
- Why: auth is entry-critical and live drift already exists.
- How:
  - Run unit/widget/integration coverage.
  - Execute RLS allow/deny checks.
  - Verify privacy-safe logs.
  - Run manual E2E script.
  - Capture failure artifacts with bounded retries.
- Result: release-ready evidence.
- GATE CHECK: all critical tests pass, RLS checks pass, privacy audit passes, and no open blockers remain.

### Phase 5: Docs + Release
- Goal: ship one coherent auth contract across repo, docs, and live DB.
- Why: current docs and live reality already drift.
- How:
  - Sync docs for bootstrap, `active_role`, reset completion, and file layout.
  - Execute release checklist by PR slice.
  - Record rollback and live verify outputs.
- Result: operationally safe release.
- GATE CHECK: docs match code + DB, release checklist is complete, rollback artifacts exist.

## I) Change Report (Diff-Style)

1. Original issues summary
- The original Auth plan had strong evidence gathering but left core execution decisions open, especially bootstrap authority, recovery completion, rollout sequencing, and test infrastructure.
- It also planned tests without first defining selectors, fixtures, env contracts, or bounded retries.

2. Added steps (bullet list)
- Added Test Infrastructure Gate.
- Added bootstrap authority decision.
- Added `full_name` metadata decision.
- Added auth event/state machine artifact.
- Added missing-profile compatibility-window exit criteria.
- Added PR slicing and definition of done.
- Added privacy grep/log audit requirement.
- Added selector/key contract for new auth screens.

3. Removed steps (if any)
- Removed ambiguity around “optional” compatibility RPC by forcing a rollout decision.
- Removed implicit assumption that password reset initiation alone was acceptable.

4. Reordered steps (from → to)
- Test work moved from late QA phase → upfront test infrastructure gate.
- Contract/decision work moved from implied within later phases → explicit blocking items in Phase 0.
- Rollout/compatibility handling moved from general migration notes → explicit pre-implementation release design.

5. Expanded steps (what became more detailed)
- Migration work expanded to include exact compatibility-window logic.
- UI work expanded to include state matrix and stable selectors.
- Observability work expanded to include privacy validation.
- Release work expanded to include PR slicing and go/no-go checks.

6. Why (short, practical)
- The original plan was directionally correct but still execution-fragile. The corrected version removes foundational ambiguity and forces a safer order of operations.

7. Residual risks (what still remains risky even after fixes)
- Live DB drift can still surprise rollout timing if additional missing-profile edge cases appear.
- Password recovery on mobile can still fail if Supabase callback behavior differs across platforms or auth package updates.
- Integration-test stability will still depend on staging account hygiene even after preflight work.
