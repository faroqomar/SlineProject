# 📌 Plan: Auth Fix & Contract Reconcile

## 1) Goal

- Goal: make Auth signup, login, password recovery, and session handling correct against the current live Supabase state, with server-authoritative profile bootstrap and strict MVVM boundaries.
- Why: current auth behavior still depends on client-side `public.profiles` creation, valid sign-in can fail when the profile row is missing, password recovery is only half-implemented in Flutter, and the app currently instantiates more than one auth session listener. References: `lib/features/auth/data/auth_repository.dart:9-38`, `lib/features/auth/data/auth_repository.dart:75-83`, `lib/features/auth/viewmodels/auth_view_model.dart:45-89`, `lib/main.dart:139-199`, `lib/features/auth/view/login_screen.dart:83-85`, `lib/features/auth/view/signup_screen.dart:86-88`, `lib/features/auth/view/forgot_password_screen.dart:57-59`.
- Result: new users get `public.profiles` rows from the server path, existing missing-profile users recover safely during rollout, password reset completes in-app, auth state is handled by one global session owner, and the release is gated by live DB verification plus deterministic tests.

## 2) Scope

### In-Scope

- Auth feature runtime and direct dependencies:
  - `lib/features/auth/data/auth_repository.dart`
  - `lib/features/auth/viewmodels/auth_view_model.dart`
  - `lib/features/auth/view/login_screen.dart`
  - `lib/features/auth/view/signup_screen.dart`
  - `lib/features/auth/view/forgot_password_screen.dart`
  - `lib/main.dart`
  - `lib/app/main_navigation_screen.dart`
  - `lib/core/models/user_profile.dart`
  - `lib/core/services/supabase_config.dart`
  - `lib/core/services/logger_service.dart`
  - `lib/core/services/crash_reporting_service.dart`
  - `lib/core/utils/error_mapper.dart`
  - `lib/features/profile/data/profile_repository.dart`
- Auth automated test surface:
  - `test/unit/auth/`
  - `test/widget/auth/`
  - `integration_test/app_startup_login_flow_test.dart`
  - new auth integration coverage for recovery and session expiry
- Platform deep-link files used by auth recovery:
  - `android/app/src/main/AndroidManifest.xml`
  - `ios/Runner/Info.plist`
- Live Supabase objects directly touched by auth:
  - `auth.users`
  - `auth.sessions`
  - `public.profiles`
  - `public.rpc_get_profile_summaries(uuid[])`
  - `public.search_profiles(...)`
  - `storage.objects` policies for `avatars` as indirect profile contract context

### Out-of-Scope

- Post-login dashboard, task, booking, chat, or wallet behavior.
- New OAuth/social login implementation.
- Broad profile-feature cleanup outside the auth correctness contract.
- New edge functions; live scan shows only payment-related edge functions and no auth-specific function surface.
- Schema removal/renames for `public.profiles.email`; this plan only decouples auth correctness from that column.

## 3) Evidence & Findings (From Scan)

### Existing

- `AuthRepository.signUp()` currently signs up, then conditionally signs in, then inserts into `public.profiles` from the client. Reference: `lib/features/auth/data/auth_repository.dart:9-38`.
- `AuthRepository.getCurrentUserProfile()` reads `public.profiles` with `.single()`, which makes login success depend on the row existing immediately. Reference: `lib/features/auth/data/auth_repository.dart:75-83`.
- `AuthViewModel` subscribes to `Supabase.instance.client.auth.onAuthStateChange`, but screen files also instantiate local `AuthViewModel()` providers. References: `lib/features/auth/viewmodels/auth_view_model.dart:45-49`, `lib/features/auth/view/login_screen.dart:83-85`, `lib/features/auth/view/signup_screen.dart:86-88`, `lib/features/auth/view/forgot_password_screen.dart:57-59`.
- The root app already owns a global auth provider and session-expired callback path. Reference: `lib/main.dart:139-199`, `lib/main.dart:271-288`.
- Password reset initiation already uses the app deep-link scheme `io.supabase.sline://login-callback`. References: `lib/features/auth/data/auth_repository.dart:55-60`, `android/app/src/main/AndroidManifest.xml:34-40`, `ios/Runner/Info.plist:56-68`.
- `ProfileRepository` duplicates reset-password initiation, which creates contract drift risk. Reference: `lib/features/profile/data/profile_repository.dart:107-109`.
- A shared `ErrorMapper` already exists, but auth code does not use it. References: `lib/core/utils/error_mapper.dart:1-145`, `lib/features/auth/viewmodels/auth_view_model.dart:220-248`.
- Existing auth tests only cover login basics and startup/login happy path. References: `test/unit/auth/auth_view_model_test.dart:14-131`, `test/widget/auth/login_screen_test.dart:74-179`, `integration_test/app_startup_login_flow_test.dart:9-62`.
- Live Supabase scan found:
  - `auth.users = 6`
  - `public.profiles = 4`
  - `auth_users_missing_profile = 2`
  - `orphan_profiles = 0`
  - no non-internal trigger on `auth.users` or `public.profiles`
  - duplicate `INSERT` policies on `public.profiles`
  - `public.profiles` uses `active_role`, not `role`
  - safe summary RPCs already exist: `public.rpc_get_profile_summaries(uuid[])`, `public.search_profiles(...)`

### Missing

- No server-authoritative bootstrap function/trigger for new `auth.users` rows.
- No temporary self-heal path for already-broken `auth.users` rows missing `public.profiles`.
- No in-app password-reset completion screen.
- No explicit handling for `AuthChangeEvent.passwordRecovery` in the auth state flow.
- No auth-specific test-infrastructure artifact for selectors, fixtures, env injection, artifact capture, or flake policy.
- No documented state machine for signed-in, signed-out, session-expired, recovery, and missing-profile states.

### Must NOT Duplicate

- Do not keep two auth session listeners after refactor.
- Do not keep two password-reset initiation contracts across auth and profile repositories.
- Do not add a second auth-specific profile DTO when `lib/core/models/user_profile.dart` already exists.
- Do not create a client-side privileged path or any service-role usage in Flutter.
- Do not create a second long-lived compatibility path after rollout; `rpc_ensure_self_profile()` must be temporary and explicitly removable.

### Conflicts / Risks (docs vs code vs live DB drift, naming mismatches, security/migration risks)

- Docs still describe client profile insertion after signup. Reference: `Sline_everything/DEVELOPER_GUIDE.md:1407-1414`.
- Docs still refer to `role`, while live `public.profiles` uses `active_role`. Reference: `Sline_everything/DEVELOPER_GUIDE.md:1376-1385`.
- Docs show stale setup counts that do not match live DB reality. Reference: `Sline_everything/SUPABASE_SETUP.md:22`.
- Live DB already contains two auth users without profile rows, so rollout cannot assume a clean baseline.
- Duplicate `INSERT` policies on `public.profiles` indicate policy drift and require verified cleanup instead of blind deletion.
- Password recovery deep links are configured at the platform layer, but Flutter does not yet complete the recovery flow.
- The critique baseline for this rewrite is recorded in `.TODO/PLAN_CRITIC_AuthFix_2026-03-01.md`.

## 4) System Impact Map

- UI:
  - update `lib/features/auth/view/login_screen.dart`
  - update `lib/features/auth/view/signup_screen.dart`
  - update `lib/features/auth/view/forgot_password_screen.dart`
  - add `lib/features/auth/view/reset_password_update_screen.dart`
  - add stable keys/selectors for auth inputs, buttons, and terminal states
- MVVM/App Logic:
  - split session ownership from screen form state
  - introduce `lib/features/auth/viewmodels/auth_session_view_model.dart`
  - introduce `lib/features/auth/viewmodels/auth_form_view_model.dart`
  - update provider wiring in `lib/main.dart`
- Database:
  - add server-side profile bootstrap function + trigger
  - add temporary self-heal RPC for rollout
  - backfill current missing profile rows
  - reconcile duplicate `INSERT` policies after verification
- RLS/Security:
  - keep `public.profiles` base-table access self-only
  - ensure cross-user access continues only through summary RPCs
  - remove client-side `public.profiles` bootstrap writes from final state
- Realtime/Notifications (if any):
  - no auth-specific realtime changes planned; live publication remains `messages` and `notifications`
- Storage:
  - no bucket changes planned; `profiles.avatar_url` remains an indirect profile contract
- Observability (if any):
  - auth event taxonomy
  - privacy-safe auth logging
  - crash-report identity set/clear hooks tied to the global session owner
- Compatibility & Migration:
  - additive-first DB rollout
  - temporary compatibility window for existing missing-profile users
  - three-slice rollout with explicit stop/go gates
- Contracts:
  - signup metadata contract for `full_name`
  - typed self-profile contract via `UserProfile`
  - self-heal RPC contract
  - password recovery callback contract
  - auth event/state machine contract

---

# ✅ Execution Phases (Checklist)

## Phase 0: Preconditions & Gates

> Primary: @Sentinel

- Goal: lock the design, test prerequisites, contracts, migration order, and slice boundaries before runtime changes begin.
- Why: the current failure modes come from ambiguous ownership and incomplete rollout planning, not just missing code.
- How: create the missing planning artifacts, freeze the critical decisions, and define stop conditions for each delivery slice.
- Result: the implementation path is unambiguous and reviewable.

### 0.0 Test Infrastructure Gate

- [ ] (@Sentinel) Create `.TODO/TEST_INFRA_AuthFix_2026-03-01.md` covering:
  - unit/widget/integration scope mapping
  - shared harness usage
  - env/secrets injection method
  - timeout budgets
  - retry/flake policy
  - failure artifact path and naming
- [ ] (@Pixel) Define stable selector/key names for:
  - login email field
  - login password field
  - login submit
  - signup full-name field
  - signup email field
  - signup password field
  - signup submit
  - forgot-password email field
  - forgot-password submit
  - reset-password new password field
  - reset-password confirm password field
  - reset-password submit
  - auth loading/error/success terminal states
- [ ] (@Sentinel) Create `.TODO/FIXTURES_AuthFix_2026-03-01.md` with:
  - seeded valid user contract
  - duplicate-email user contract
  - recovery-flow account contract
  - expired-session test strategy
  - fail-fast preflight checks
- [ ] (@Sentinel) Map each planned auth behavior to the correct test type before implementation starts.
- **Verify (@Sentinel):** no auth test is allowed to proceed without stable selectors, documented fixtures, and bounded waits.

### 0.1 Spec Lock

- [ ] (@Architect) Lock the canonical bootstrap authority as: `auth.users` trigger plus temporary authenticated self-heal RPC during rollout.
- [ ] (@APIContract) Lock `full_name` delivery through auth signup metadata; no final client write to `public.profiles` is allowed.
- [ ] (@Pixel) Lock password recovery completion as an in-app reset-password update screen.
- [ ] (@Architect) Lock the final app ownership model:
  - one global `AuthSessionViewModel`
  - screen-scoped `AuthFormViewModel`
  - no screen-scoped auth session listeners
- [ ] (@Sentinel) Create `.TODO/ACCEPTANCE_AuthFix_2026-03-01.md` with measurable done-conditions and release blockers.
- **Verify (@Sentinel):** bootstrap, recovery, and state-ownership decisions are fixed and no longer optional.

### 0.2 Threat Model (If sensitive/high-risk)

- [ ] (@ThreatModeler) Create `.TODO/THREAT_MODEL_AuthFix_2026-03-01.md` for:
  - orphan signup/profile state
  - missing-profile login drift
  - cross-user `public.profiles` access
  - deep-link recovery misuse
  - duplicate session listeners
  - PII leakage in logs/crash reports
- [ ] (@Sentinel) Convert each threat into a concrete negative test or live verify query.
- **Verify (@Sentinel):** every security risk has an enforcement and verification path before Phase 1 starts.

### 0.3 Contracts (If payloads change)

- [ ] (@APIContract) Create `.TODO/CONTRACT_AuthFix_2026-03-01.md` covering:
  - signup request metadata
  - typed self-profile read shape
  - self-heal RPC input/output and removal conditions
  - password recovery callback contract
  - session event -> app action contract
- [ ] (@Architect) Create `.TODO/STATE_MACHINE_AuthFix_2026-03-01.md` covering:
  - signed-in with profile present
  - signed-in with profile missing
  - signed-out
  - session-expired
  - signup pending/failed/succeeded
  - forgot-password pending/failed/succeeded
  - password-recovery callback -> reset screen
  - reset-password pending/failed/succeeded
- [ ] (@Sentinel) Block implementation if any auth event still has more than one possible route/action outcome.
- **Verify (@Sentinel):** contracts are explicit enough to drive DB work, repository changes, UI states, and tests.

### 0.4 Migration Plan (If schema/data changes)

- [ ] (@DataMigration) Create `.TODO/MIGRATION_PLAN_AuthFix_2026-03-01.md` with introduce/backfill/enforce order for:
  - `public.handle_new_user()`
  - trigger creation on `auth.users`
  - temporary `public.rpc_ensure_self_profile()`
  - missing-profile backfill
  - duplicate `INSERT` policy cleanup
  - compatibility-window exit
- [ ] (@Supabase_Ops) Define the exact verify queries for:
  - auth user count
  - profile count
  - `auth_users_missing_profile`
  - `orphan_profiles`
  - trigger presence
  - duplicate policy count
- [ ] (@Sentinel) Define rollback triggers for each execution slice.
- **Verify (@Sentinel):** migration order is additive-first, measurable, and rollback-safe.

### 0.5 Feature Flag/Rollout (If risky)

- [ ] (@Architect) Lock three delivery slices with independent review and rollback points:
  - Slice 1: test infra + contracts + app tolerance seams + stable keys
  - Slice 2: DB bootstrap migration + self-heal RPC + backfill + verify queries
  - Slice 3: final app refactor + reset completion UI + tests + docs sync + removal of transitional client bootstrap path
- [ ] (@Sentinel) Create `.TODO/RELEASE_CHECKLIST_AuthFix_2026-03-01.md` with definition of done per slice.
- [ ] (@SlineDocs) Identify which docs change in each slice so docs drift does not persist until the end.
- **Verify (@Sentinel):** rollout sequencing is explicit and no large unreviewable auth batch remains.

### GATE CHECK

- [ ] (@Sentinel) All Phase 0 artifacts exist and the five decisions above are locked.
- [ ] (@Sentinel) Test Infrastructure Gate is PASS before database or UI execution begins.

## Phase 1: Database & Security (If applicable)

> Primary: @Supabase_Ops

- Goal: make `public.profiles` bootstrap server-authoritative and safe for both new and existing users.
- Why: live data already proves the client bootstrap path is not reliable.
- How: introduce server-side bootstrap, add a temporary self-heal path, backfill missing rows, then reconcile policies after verification.
- Result: the database becomes the source of truth for profile existence and auth no longer relies on client writes for correctness.

### 1.0 Live Supabase Confirmation (MANDATORY)

- [ ] (@Supabase_Ops) Re-scan the live project immediately before migration work for:
  - `auth.users`
  - `auth.sessions`
  - `public.profiles`
  - `pg_policies`
  - `pg_trigger`
  - `pg_indexes`
  - `pg_publication_tables`
- [ ] (@Supabase_Ops) Save the baseline to `.TODO/LIVE_DB_BASELINE_AuthFix_2026-03-01.md`.
- [ ] (@Sentinel) Block migration work if live drift increased from the scan already captured in this plan.
- **Verify (@Sentinel):** migration work starts from a verified live baseline, not stale assumptions.

### 1.1 Schema (Additive-first)

- [ ] (@Supabase_Ops) Create `supabase/migrations/20260301_auth_profile_bootstrap.sql` with:
  - `public.handle_new_user()` as `SECURITY DEFINER`
  - fixed `search_path`
  - `auth.on_auth_user_created` trigger
  - temporary `public.rpc_ensure_self_profile()` as `SECURITY DEFINER`
- [ ] (@APIContract) Ensure bootstrap logic reads `full_name` from auth metadata and writes a consistent `public.profiles` row using live field names, including `active_role` instead of doc-stale `role`.
- [ ] (@DataMigration) Keep Phase 1 additive-only; do not drop or rename `profiles.email` in this plan.
- **Verify (@Sentinel):** server bootstrap objects exist and match the locked contract without destructive schema change.

### 1.2 RLS

- [ ] (@Supabase_Ops) Preserve self-only base-table `public.profiles` access:
  - SELECT `auth.uid() = id`
  - INSERT `auth.uid() = id`
  - UPDATE `auth.uid() = id`
  - DELETE `auth.uid() = id`
- [ ] (@Supabase_Ops) Create `.TODO/RLS_MATRIX_AuthFix_2026-03-01.md` with allowed/forbidden checks for:
  - self read
  - self insert
  - self update
  - self delete
  - cross-user denial
  - cross-user summary access only through existing safe RPCs
- [ ] (@ThreatModeler) Ensure `rpc_ensure_self_profile()` can only create or return the authenticated caller’s own profile row.
- [ ] (@Supabase_Ops) Delay duplicate `INSERT` policy cleanup until after trigger and backfill verification succeed.
- **Verify (@Sentinel):** least-privilege access stays intact and the compatibility RPC cannot become a broader write surface.

### 1.3 Triggers/RPC (If needed)

- [ ] (@Supabase_Ops) Implement `rpc_ensure_self_profile()` as an idempotent rollout-only compatibility RPC.
- [ ] (@APIContract) Lock the RPC result shape to the typed self-profile contract so the app can treat it as recovery, not as a general admin primitive.
- [ ] (@ThreatModeler) Explicitly reject any client service-role usage, admin-only client action, or edge-function detour for auth bootstrap.
- [ ] (@DataMigration) Define the removal condition for `rpc_ensure_self_profile()` as: `auth_users_missing_profile = 0` and no recovery-path hits during the compatibility observation window.
- **Verify (@Sentinel):** compatibility support is bounded, self-only, and removable.

### 1.4 Migration Execution (If needed)

- [ ] (@DataMigration) Execute introduce/backfill/enforce in this order:
  - deploy trigger/function/RPC
  - backfill missing profile rows
  - re-run verify queries
  - observe compatibility-window results
  - clean up duplicate `INSERT` policy only after evidence is green
- [ ] (@Supabase_Ops) Record outputs in `.TODO/EXECUTION_LOG_PLAN_AuthFix_2026-03-01.md`.
- [ ] (@Sentinel) Block Phase 2 finalization and Slice 3 until verify outputs prove:
  - `auth_users_missing_profile = 0`
  - `orphan_profiles = 0`
  - expected trigger exists
  - duplicate policy count is reduced to the canonical target
- **Verify (@Sentinel):** live DB is consistent before the app removes any transitional bootstrap behavior.

### GATE CHECK

- [ ] (@Sentinel) Data/Contracts Gate: PASS
- [ ] (@Sentinel) Security Gate: PASS
- [ ] (@Sentinel) Live verify queries are archived in `.TODO/EXECUTION_LOG_PLAN_AuthFix_2026-03-01.md`.

## Phase 2: App Layer (MVVM)

> Primary: @Architect

- Goal: align Flutter auth logic with the server-authoritative contract and remove ambiguous state ownership.
- Why: even with a correct DB contract, the current app can still mis-handle missing profiles, session events, and recovery callbacks.
- How: keep one auth repository, split session state from form state, make self-profile handling typed and tolerant during rollout, then remove transitional behavior after DB verification.
- Result: auth logic becomes deterministic, MVVM-compliant, and release-safe.

### 2.1 Models & Contract Compliance

- [ ] (@Architect) Reuse `lib/core/models/user_profile.dart` for auth self-profile mapping; extend it only if the locked contract requires new fields.
- [ ] (@Architect) Replace raw self-profile `Map<String, dynamic>` handling with explicit typed mapping and selected columns.
- [ ] (@APIContract) Align auth code and docs to live `public.profiles` fields such as `active_role`.
- **Verify (@Sentinel):** self-profile reads are typed, explicit, and schema-aligned.

### 2.2 Services/Repositories

- [ ] (@Architect) Keep one `AuthRepository` as the auth data-access facade for this remediation; avoid unnecessary service-layer duplication.
- [ ] (@Architect) Slice 1 preparatory work:
  - send `full_name` in signup auth metadata
  - introduce tolerant self-profile fetch behavior for the compatibility window
  - centralize password-reset initiation in auth, not profile
- [ ] (@Architect) During the compatibility window, define the login/profile recovery order as:
  - sign in
  - try typed self-profile read
  - if missing and DB compatibility window is still active, call `rpc_ensure_self_profile()`
  - re-read typed self-profile
  - only fail after bounded recovery paths are exhausted
- [ ] (@Architect) Slice 3 finalization work:
  - remove client `public.profiles.insert(...)`
  - remove any transition-only fallback that is no longer needed after Phase 1 gates pass
  - route all reset-password initiation through the auth contract only
- [ ] (@Architect) Replace custom string-substring error mapping with the shared `ErrorMapper` plus auth-specific extensions only where required.
- **Verify (@Sentinel):** no direct client profile bootstrap write remains in the final slice and auth errors use one mapping contract.

### 2.3 ViewModels / State

- [ ] (@Architect) Introduce `lib/features/auth/viewmodels/auth_session_view_model.dart` for app-wide auth session ownership.
- [ ] (@Architect) Introduce `lib/features/auth/viewmodels/auth_form_view_model.dart` for login/signup/forgot/reset form state.
- [ ] (@Architect) Refactor or retire `lib/features/auth/viewmodels/auth_view_model.dart` so it no longer combines global listener ownership with screen form behavior.
- [ ] (@Architect) Handle auth events explicitly in the session owner:
  - signedIn
  - signedOut
  - tokenRefreshed
  - userUpdated
  - passwordRecovery
- [ ] (@Architect) Make `signedOut` and session-expired behavior route through one root callback path instead of per-screen listeners.
- [ ] (@Architect) Add explicit state for `authenticatedProfileRecovering` or equivalent so the app can distinguish “valid session, profile recovery in progress” from fatal login failure.
- **Verify (@Sentinel):** one global session owner exists and each auth event has one state transition path.

### 2.4 App Shell / Navigation / Deep Link

- [ ] (@Architect) Update `lib/main.dart` provider wiring to expose the new session owner globally and avoid screen-level session listeners.
- [ ] (@Architect) Add a dedicated reset-password route and wire the recovery callback to it.
- [ ] (@Architect) Keep post-login navigation rooted in session/app-shell decisions instead of direct screen pushes to `MainNavigationScreen` on local form success.
- [ ] (@Observability) Ensure crash-report user identity set/clear hooks follow the single global session owner.
- **Verify (@Sentinel):** auth routing is shell-driven, recovery-aware, and free of duplicate listener ownership.

### GATE CHECK

- [ ] (@Sentinel) Backend/API Gate: PASS
- [ ] (@Sentinel) Exactly one auth session listener remains app-wide.
- [ ] (@Sentinel) Grep for direct client `public.profiles.insert` in final auth code returns zero.

## Phase 3: UI (After logic)

> Primary: @Pixel

- Goal: align all auth screens with the corrected contract and state machine.
- Why: current screens still navigate directly, own listeners locally, and expose incomplete or misleading auth behaviors.
- How: rewire screens to form-only state, add the missing reset screen, tighten rebuild scope, and remove dead-end UI actions.
- Result: auth UI matches the backend contract and is testable with stable selectors.

### 3.1 Login Screen

- [ ] (@Pixel) Remove screen-scoped auth session provider ownership from `lib/features/auth/view/login_screen.dart`.
- [ ] (@Pixel) Route success through the global session state instead of direct push to `MainNavigationScreen`.
- [ ] (@Pixel) Narrow rebuild scope so the entire screen is not rebuilt for unrelated form state changes.
- [ ] (@Pixel) Add stable keys and explicit states for loading, invalid credentials, missing-profile recovery, and fatal error.
- **Verify (@Sentinel):** login UI is form-only and shell navigation owns success transitions.

### 3.2 Signup Screen

- [ ] (@Pixel) Remove screen-scoped auth session provider ownership from `lib/features/auth/view/signup_screen.dart`.
- [ ] (@Pixel) Keep `full_name` collection but wire it to signup metadata, not client profile insertion.
- [ ] (@Pixel) Replace direct navigation to `MainNavigationScreen` with session-driven flow.
- [ ] (@Pixel) Reduce overly broad `Consumer` rebuild scope around the form.
- [ ] (@Pixel) Remove or clearly disable no-op social-login buttons so the screen does not advertise dead actions.
- **Verify (@Sentinel):** signup UI reflects the server bootstrap contract and no longer depends on direct profile writes.

### 3.3 Forgot Password Screen

- [ ] (@Pixel) Remove screen-scoped auth session provider ownership from `lib/features/auth/view/forgot_password_screen.dart`.
- [ ] (@Pixel) Keep English-only UX copy and define terminal states for request pending, request success, invalid email, and delivery failure.
- [ ] (@Pixel) Add explicit guidance that the user must continue from the reset email link into the app recovery flow.
- **Verify (@Sentinel):** forgot-password UI only initiates reset and clearly hands off to the recovery callback flow.

### 3.4 Reset Password Update Screen

- [ ] (@Pixel) Add `lib/features/auth/view/reset_password_update_screen.dart`.
- [ ] (@Pixel) Include:
  - new password field
  - confirm password field
  - submit action
  - loading state
  - validation state
  - success state
  - expired/invalid recovery-session state
- [ ] (@Architect) Wire the screen to the locked `passwordRecovery` session event and auth repository update-password contract.
- **Verify (@Sentinel):** password recovery is complete in-app and testable end to end.

### 3.5 UX/State Hardening

- [ ] (@Pixel) Ensure all auth UI strings remain English only.
- [ ] (@Pixel) Prevent double submit on all auth forms.
- [ ] (@Pixel) Provide deterministic empty/loading/error/success states per the state machine.
- [ ] (@Pixel) Ensure any recovery or session-expiry interruption lands in a defined state instead of silent fallback.
- **Verify (@Sentinel):** UI/Integration Gate is PASS before Phase 4 begins.

### GATE CHECK

- [ ] (@Sentinel) UI/Integration Gate: PASS
- [ ] (@Sentinel) All planned auth screens expose stable keys/selectors and deterministic terminal states.

## Phase 4: QA + Security (MANDATORY)

> Primary: @Sentinel

- Goal: prove correctness, security, privacy, and rollout safety before release.
- Why: auth changes are cross-layer and cannot rely on ad hoc manual checks.
- How: run static analysis, layer-appropriate automated tests, live RLS verification, privacy audits, and a formal go/no-go checklist.
- Result: the final auth release is backed by evidence, not assumptions.

### 4.1 Static + Unit

- [ ] (@Sentinel) Run `flutter analyze` and resolve auth-related findings before release.
- [ ] (@Sentinel) Add/update unit tests for:
  - signup metadata submission
  - login success with existing profile
  - login success with missing profile recovered through compatibility path
  - login failure after bounded recovery attempts
  - password recovery event handling
  - signed-out/session-expired handling
  - shared error-mapper usage
- [ ] (@Sentinel) Require one behavior per test ID and no bundled assertions disguised as one test.
- **Verify (@Sentinel):** auth logic regressions are covered with deterministic unit tests.

### 4.2 Widget

- [ ] (@Sentinel) Add/update widget tests for:
  - login screen states
  - signup screen states
  - forgot-password screen states
  - reset-password update screen states
  - no-op social button removal/disablement behavior
  - stable key presence for automation-critical widgets
- [ ] (@Pixel) Use the selector map from `.TODO/TEST_INFRA_AuthFix_2026-03-01.md`; no ad hoc widget finders for critical paths.
- **Verify (@Sentinel):** auth UI states are covered by stable, non-brittle widget tests.

### 4.3 Integration/E2E

- [ ] (@Sentinel) Extend integration coverage beyond `integration_test/app_startup_login_flow_test.dart` to include:
  - cold start with valid session and existing profile
  - cold start with valid session and missing profile during compatibility window
  - signup -> recovery-safe landing
  - forgot-password request flow
  - password recovery callback -> update password -> login with new password
  - session expiry -> shell-level redirect to login
- [ ] (@Sentinel) Enforce documented timeout budgets, rerun policy, and artifact capture.
- [ ] (@Sentinel) Fail fast on missing env/accounts instead of timing out late.
- **Verify (@Sentinel):** the critical auth flows pass end to end in a deterministic environment.

### 4.4 Live Supabase / RLS Contract Checks

- [ ] (@Supabase_Ops) Re-run the locked verify queries for:
  - `auth_users_missing_profile = 0`
  - `orphan_profiles = 0`
  - expected trigger present
  - expected duplicate policy cleanup result
- [ ] (@Supabase_Ops) Run allowed/forbidden RLS checks from `.TODO/RLS_MATRIX_AuthFix_2026-03-01.md`.
- [ ] (@ThreatModeler) Confirm no client code path performs privileged actions or bypasses RLS expectations.
- **Verify (@Sentinel):** live DB behavior matches the intended security contract.

### 4.5 Privacy / Observability

- [ ] (@Observability) Create `.TODO/OBSERVABILITY_AuthFix_2026-03-01.md` with auth event names, correlation strategy, and redaction rules.
- [ ] (@Sentinel) Run grep/log audits to confirm no raw email, token, or reset credential values are emitted in auth logs or crash metadata.
- [ ] (@Observability) Ensure auth failure logs stay actionable after redaction.
- **Verify (@Sentinel):** privacy-safe diagnostics are enforced and not left as a best-effort note.

### 4.6 Release Go / No-Go

- [ ] (@Sentinel) Require all slice definitions of done to pass before release.
- [ ] (@Sentinel) Block release if any of these remain false:
  - no direct client `public.profiles.insert(...)` in final auth code
  - one auth session listener app-wide
  - password recovery completes in-app
  - `auth_users_missing_profile = 0`
  - RLS checks pass
  - docs updated
- [ ] (@Sentinel) Record final command outputs and live verification summary in `.TODO/EXECUTION_LOG_PLAN_AuthFix_2026-03-01.md`.
- **Verify (@Sentinel):** Release/QA Gate is PASS.

### GATE CHECK

- [ ] (@Sentinel) Release/QA Gate: PASS
- [ ] (@Sentinel) All auth blockers in `.TODO/ACCEPTANCE_AuthFix_2026-03-01.md` are green.

## Phase 5: Documentation Sync (MANDATORY)

> Primary: @SlineDocs

- Goal: reconcile docs with the final auth contract, live schema, and testing/release workflow.
- Why: current docs still describe stale auth/profile behavior and field names.
- How: update the docs that encode developer reality and remove stale guidance in the same release stream.
- Result: docs match code and live DB behavior after rollout.

### 5.1 Developer / Setup Docs

- [ ] (@SlineDocs) Update `Sline_everything/DEVELOPER_GUIDE.md` to reflect:
  - server-authoritative profile bootstrap
  - signup metadata contract
  - password recovery completion flow
  - final auth state ownership
- [ ] (@SlineDocs) Update `Sline_everything/SUPABASE_SETUP.md` to reflect:
  - current live object list
  - actual auth/profile counts or remove stale fixed counts
  - canonical `public.profiles` policies
  - new trigger/RPC objects if retained during the release window
- [ ] (@SlineDocs) Update `Sline_everything/STRUCTURE.md` for new auth VM and screen files.
- **Verify (@Sentinel):** docs no longer describe client profile insertion or stale field names.

### 5.2 Architecture / Quality Docs

- [ ] (@SlineDocs) Update `Sline_everything/ARCHITECTURE_ANALYSIS.md` if the session/form VM split changes the documented MVVM boundary.
- [ ] (@SlineDocs) Update `Sline_everything/CODE_REVIEW.md` or related review checklist docs if auth release gates add new mandatory checks.
- [ ] (@SlineDocs) Update `Sline_everything/MVP_ROADMAP.md` only if the auth remediation changes milestone status or future auth scope.
- **Verify (@Sentinel):** docs reflect the implemented architecture and release criteria, not the pre-fix state.

### GATE CHECK

- [ ] (@Sentinel) Documentation Sync Gate: PASS
- [ ] (@Sentinel) Referenced docs match the final shipped contract and live DB reality.

## 7) Acceptance Criteria (MANDATORY)

- [ ] New signups create `public.profiles` server-side through the locked bootstrap contract; auth correctness does not depend on final client profile insertion.
- [ ] Live verify queries prove `auth_users_missing_profile = 0` and `orphan_profiles = 0`.
- [ ] `public.handle_new_user()` and its `auth.users` trigger exist in the live project.
- [ ] Duplicate `INSERT` policy drift on `public.profiles` is reconciled to the canonical target defined in `.TODO/RLS_MATRIX_AuthFix_2026-03-01.md`.
- [ ] `lib/features/auth/**` contains no direct final-state `public.profiles.insert(...)` path for bootstrap correctness.
- [ ] Exactly one auth session listener remains app-wide; auth screens do not instantiate listener-owning auth view models.
- [ ] Signup sends `full_name` through auth metadata and no longer relies on a second client DB write.
- [ ] Login handles the compatibility-window missing-profile case deterministically and stops using the compatibility path after rollout exit conditions are met.
- [ ] Password recovery works end to end: request reset, open callback, update password, sign in with the new password.
- [ ] Reset-password initiation exists in one contract path only; duplicate repository APIs are removed or delegated to the single auth contract.
- [ ] Auth uses the shared `ErrorMapper` contract instead of fragmented substring parsing as the primary mapping strategy.
- [ ] All auth UI strings remain English only.
- [ ] `flutter analyze` passes for auth changes and all planned unit/widget/integration tests pass under the documented test infrastructure.
- [ ] Privacy verification proves no raw email, token, or reset credentials are emitted in auth logs or crash metadata.
- [ ] `Sline_everything/DEVELOPER_GUIDE.md`, `Sline_everything/SUPABASE_SETUP.md`, and `Sline_everything/STRUCTURE.md` match the final shipped auth contract.

## 8) Rollback Plan

- Slice 1 rollback:
  - revert selector/test-infra artifacts and app-prep seams if they regress existing login behavior
  - keep current production auth path intact while investigation continues
  - do not merge partial session-owner refactors without their gate checks
- Slice 2 rollback:
  - disable or revert the new trigger/RPC migration if signup or self-profile recovery regresses
  - restore the prior `public.profiles` policy set if policy cleanup causes write failures
  - keep backfilled profile rows; do not delete recovered user data as part of rollback
- Slice 3 rollback:
  - re-enable the bounded compatibility path if final client-bootstrap removal exposes remaining rollout gaps
  - revert reset-password completion UI if it causes navigation regressions, but do not ship without a working recovery path
  - revert session/form VM split if duplicate-listener or routing regressions appear, then re-stage behind the Phase 0 state machine
- General rollback triggers:
  - signup creates auth users without usable profile rows
  - login failure rate increases for valid users
  - password recovery callback fails to reach a usable reset state
  - RLS checks fail
  - privacy audit detects sensitive auth logging
- General rollback rule:
  - rollback stops at the smallest slice that restores correctness; do not perform destructive schema cleanup or data deletion as part of rollback.

## 9) References (From Scan)

- Workflow references:
  - `.agents/workflows/planner.md`
  - `.agents/workflows/plan_critic.md`
  - `.TODO/PLAN_CRITIC_AuthFix_2026-03-01.md`
- Docs scanned:
  - `Sline_everything/DEVELOPER_GUIDE.md:1361-1424`
  - `Sline_everything/SUPABASE_SETUP.md:22`
  - `Sline_everything/SUPABASE_SETUP.md:1005-1015`
  - `Sline_everything/MVP_ROADMAP.md`
  - `Sline_everything/ARCHITECTURE_ANALYSIS.md`
  - `Sline_everything/CODE_REVIEW.md`
  - `Sline_everything/STRUCTURE.md`
- Code scanned:
  - `lib/main.dart:139-199`
  - `lib/main.dart:218-299`
  - `lib/features/auth/data/auth_repository.dart:9-86`
  - `lib/features/auth/viewmodels/auth_view_model.dart:45-248`
  - `lib/features/auth/view/login_screen.dart:59-334`
  - `lib/features/auth/view/signup_screen.dart:66-368`
  - `lib/features/auth/view/forgot_password_screen.dart:28-132`
  - `lib/features/profile/data/profile_repository.dart:90-109`
  - `lib/core/models/user_profile.dart:1-32`
  - `lib/core/utils/error_mapper.dart:1-145`
  - `android/app/src/main/AndroidManifest.xml:34-40`
  - `ios/Runner/Info.plist:56-68`
- Tests scanned:
  - `test/unit/auth/auth_view_model_test.dart:14-131`
  - `test/widget/auth/login_screen_test.dart:74-179`
  - `integration_test/app_startup_login_flow_test.dart:9-62`
- Live Supabase scan references:
  - `public.profiles` columns, indexes, policies, and row counts
  - `auth.users` and `auth.sessions`
  - `pg_trigger` for `auth.users` and `public.profiles`
  - `pg_policies` for `public.profiles`
  - `pg_publication_tables`
  - `public.rpc_get_profile_summaries(uuid[])`
  - `public.search_profiles(...)`
  - storage buckets and policies for profile-adjacent assets
