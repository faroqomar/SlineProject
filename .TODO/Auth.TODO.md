# Auth — Feature Audit (Phase 1) + Verified Fix Plan

## 0) Overview
- What this feature does: Auth handles login, signup, password reset initiation, logout state, and auth-session event listening via `AuthRepository` + `AuthViewModel` + auth screens. File References: `lib/features/auth/data/auth_repository.dart:6-96`, `lib/features/auth/viewmodels/auth_view_model.dart:19-249`, `lib/features/auth/view/login_screen.dart:18-337`, `lib/features/auth/view/signup_screen.dart:17-371`, `lib/features/auth/view/forgot_password_screen.dart:11-172`.
- Boundaries (in scope): Auth feature files, app auth route/provider wiring, Supabase bootstrap/logger behavior used by auth, password-reset deep-link platform registration, and shared `profiles` table interactions relevant to auth bootstrap/reset consistency. File References: `lib/main.dart:122-235`, `lib/core/services/supabase_config.dart:15-30`, `lib/core/services/logger_service.dart:40-182`, `android/app/src/main/AndroidManifest.xml:34-40`, `ios/Runner/Info.plist:56-68`, `lib/features/profile/data/profile_repository.dart:51-68`.
- Boundaries (out of scope): Post-login feature behavior inside main navigation tabs is not audited here. File References: `lib/app/main_navigation_screen.dart:20-49`.
- Entry points (screens/routes/calls): App boot selects login vs main nav from current Supabase user and registers `/login` + `/signup` routes; auth screens trigger view-model login/register/reset. File References: `lib/main.dart:198-235`, `lib/features/auth/view/login_screen.dart:49-77`, `lib/features/auth/view/signup_screen.dart:41-80`, `lib/features/auth/view/forgot_password_screen.dart:28-51`.

## 1) Feature Map (Current Repo State)
- Primary feature files (with references)
  - Repository: `lib/features/auth/data/auth_repository.dart:6-96`
  - ViewModel (session + form state combined): `lib/features/auth/viewmodels/auth_view_model.dart:19-249`
  - Login UI: `lib/features/auth/view/login_screen.dart:18-337`
  - Signup UI: `lib/features/auth/view/signup_screen.dart:17-371`
  - Forgot password UI: `lib/features/auth/view/forgot_password_screen.dart:11-172`
- Direct dependencies (with references)
  - Global auth provider and auth route wiring: `lib/main.dart:122-235`
  - Post-login target screen (`MainNavigationScreen`): `lib/app/main_navigation_screen.dart:20-30`
  - Supabase client initialization (URL + anon key): `lib/core/services/supabase_config.dart:15-30`
  - Logging + masking + crash-report forwarding used by auth errors/info: `lib/core/services/logger_service.dart:40-182`
  - Crash reporting default implementation (debug no-op printer): `lib/core/services/crash_reporting_service.dart:45-80`
  - Android deep-link scheme registration for Supabase callback: `android/app/src/main/AndroidManifest.xml:34-40`
  - iOS deep-link scheme registration for Supabase callback: `ios/Runner/Info.plist:56-68`
  - Shared `profiles` table / duplicate reset API path in Profile repository (relevant to auth table consistency): `lib/features/profile/data/profile_repository.dart:51-68`
  - Current auth tests (unit/widget/integration coverage baseline): `test/unit/auth/auth_view_model_test.dart:14-131`, `test/widget/auth/login_screen_test.dart:74-179`, `integration_test/app_startup_login_flow_test.dart:9-62`
- Supabase touchpoints (tables/RPC/storage/realtime) (with references to code or SQL docs)
  - Supabase Auth methods: `signUp`, `signInWithPassword`, `resetPasswordForEmail`, `signOut`, `currentUser` in `lib/features/auth/data/auth_repository.dart:16-25`, `lib/features/auth/data/auth_repository.dart:46-53`, `lib/features/auth/data/auth_repository.dart:55-71`, `lib/features/auth/data/auth_repository.dart:73-86`
  - `profiles` table read/write from auth flow: `lib/features/auth/data/auth_repository.dart:30-34`, `lib/features/auth/data/auth_repository.dart:79-83`
  - Auth state stream (`onAuthStateChange`) in ViewModel: `lib/features/auth/viewmodels/auth_view_model.dart:21-23`, `lib/features/auth/viewmodels/auth_view_model.dart:45-55`
  - RPCs/storage/realtime channels in auth feature: UNVERIFIED (absence-based) — no `rpc(` / `storage.from(` / channel calls found in `lib/features/auth/**` during scan; missing dedicated auth SQL docs under `supabase/migrations/` for confirmation of server-side touchpoints.
  - RLS/policies for `profiles`: UNVERIFIED — missing versioned SQL/policy files for `profiles` in current repo scan (`supabase/migrations/*profiles*.sql` not present).

## 2) Evidence Index (Ground Truth)
| FindingID | Claim | File Reference (path + line range) | Risk | Notes |
|---|---|---|---|---|
| SEC-01 | Auth writes/reads `profiles`, but repo lacks versioned `profiles` RLS/policy SQL to verify authz source-of-truth | `lib/features/auth/data/auth_repository.dart:30-34`, `lib/features/auth/data/auth_repository.dart:79-83`; UNVERIFIED missing `supabase/migrations/*profiles*.sql` | High | RLS verification is blocked locally |
| SEC-02 | Password reset uses hardcoded custom redirect URI; Auth VM does not show password recovery event handling in switch | `lib/features/auth/data/auth_repository.dart:55-62`, `lib/features/auth/viewmodels/auth_view_model.dart:54-89` | High | Android/iOS schemes exist (`android/app/src/main/AndroidManifest.xml:34-40`, `ios/Runner/Info.plist:56-68`) |
| SEC-03 | Auth logs masked emails for signup/login/reset/signout flows | `lib/features/auth/data/auth_repository.dart:15-16`, `lib/features/auth/data/auth_repository.dart:45-46`, `lib/features/auth/data/auth_repository.dart:56-61`, `lib/features/auth/data/auth_repository.dart:65-70` | Low | Logger prints only in debug (`lib/core/services/logger_service.dart:82-91`) |
| SEC-04 | Duplicate password-reset API path exists; Profile repository reset path omits `redirectTo` used by Auth | `lib/features/auth/data/auth_repository.dart:55-62`, `lib/features/profile/data/profile_repository.dart:66-68` | Medium | Can produce divergent reset UX/callback behavior |
| DI-01 | Signup is multi-step (`auth.signUp` -> optional signIn -> `profiles.insert`) with no transaction/rollback | `lib/features/auth/data/auth_repository.dart:16-34` | Critical | Orphaned auth user or partial signup state possible |
| DI-02 | Login success depends on profile fetch success and `.single()`; any profile issue causes login failure path | `lib/features/auth/viewmodels/auth_view_model.dart:131-149`, `lib/features/auth/data/auth_repository.dart:75-86` | High | Valid auth session can be reported as failed |
| DI-03 | Signup auto-signs-in when `response.session == null`, making behavior environment/config dependent | `lib/features/auth/data/auth_repository.dart:21-25` | High | Email-confirmation settings can change flow semantics |
| DI-04 | Auth duplicates `email` into `profiles`; Profile repo updates auth email only | `lib/features/auth/data/auth_repository.dart:30-34`, `lib/features/profile/data/profile_repository.dart:51-53` | Medium | `auth.users.email` and `profiles.email` drift risk |
| ARC-01 | Global `AuthViewModel` provider exists and auth screens create local `AuthViewModel` providers too | `lib/main.dart:122-126`, `lib/features/auth/view/login_screen.dart:83-85`, `lib/features/auth/view/signup_screen.dart:86-88`, `lib/features/auth/view/forgot_password_screen.dart:57-59` | High | Split state + duplicated lifecycle |
| ARC-02 | Every `AuthViewModel` subscribes to `auth.onAuthStateChange` in constructor | `lib/features/auth/viewmodels/auth_view_model.dart:45-55` | High | Duplicate listeners when multiple providers exist |
| ARC-03 | Session-expiry callback is invoked only from stream `onError`, not in `signedOut` branch | `lib/features/auth/viewmodels/auth_view_model.dart:58-62`, `lib/features/auth/viewmodels/auth_view_model.dart:74-87`, `lib/main.dart:203-215` | High | Real sign-out/session expiry may not redirect |
| ARC-04 | ViewModel directly imports Supabase SDK and binds to `Supabase.instance.client.auth.onAuthStateChange` | `lib/features/auth/viewmodels/auth_view_model.dart:15`, `lib/features/auth/viewmodels/auth_view_model.dart:45-49` | Medium | Weakens MVVM/DI boundary |
| CQ-01 | Error mapping uses broad substring matching for `"password"` / `"email"` | `lib/features/auth/viewmodels/auth_view_model.dart:220-248` | Medium | Misclassification of unrelated errors |
| CQ-02 | Non-English inline comment in auth repository | `lib/features/auth/data/auth_repository.dart:21` | Low | Codebase consistency/maintainability issue |
| CQ-03 | `ForgotPasswordScreen` repeats redundant `mounted` checks after prior guard | `lib/features/auth/view/forgot_password_screen.dart:34-50` | Low | Noise and harder control-flow review |
| CQ-04 | Auth profile API returns untyped `Map<String, dynamic>?` | `lib/features/auth/data/auth_repository.dart:75-86` | Low | Weak typing across auth/profile boundary |
| PER-01 | `SignupScreen` wraps most of the UI in one `Consumer<AuthViewModel>` | `lib/features/auth/view/signup_screen.dart:111-338` | Medium | Broad rebuild scope on loading/error changes |
| PER-02 | Login always fetches profile after sign-in, but result is only used for logging | `lib/features/auth/viewmodels/auth_view_model.dart:135-139` | Medium | Extra query on every login |
| PER-03 | `_setLoading` / `_setError` always call `notifyListeners()` without equality checks | `lib/features/auth/viewmodels/auth_view_model.dart:109-117` | Low | Avoidable rebuilds, amplified by duplicate listeners |
| TST-01 | Existing tests cover login screen, auth VM basics, and startup/login happy path only | `test/unit/auth/auth_view_model_test.dart:14-131`, `test/widget/auth/login_screen_test.dart:74-179`, `integration_test/app_startup_login_flow_test.dart:9-62` | Medium | Critical flows (signup/reset/session expiry) not evidenced here |

## 3) Findings
### 3.1 Security (Highest Priority)
- `SEC-01` File Reference: `lib/features/auth/data/auth_repository.dart:30-34`, `lib/features/auth/data/auth_repository.dart:79-83`; UNVERIFIED missing `supabase/migrations/*profiles*.sql`. Impact: Auth writes/reads `profiles` but the repo does not provide versioned `profiles` RLS/policy SQL, so authorization cannot be verified from source. Exploit/Failure scenario: A permissive or missing `profiles` policy could allow over-read/over-write, or a restrictive policy could break signup/login profile bootstrap in production.
- `SEC-02` File Reference: `lib/features/auth/data/auth_repository.dart:55-62`, `lib/features/auth/viewmodels/auth_view_model.dart:54-89`, `android/app/src/main/AndroidManifest.xml:34-40`, `ios/Runner/Info.plist:56-68`. Impact: Password reset initiation uses a custom redirect and platform schemes are registered, but the auth ViewModel event switch shows no password-recovery-specific handling path. Exploit/Failure scenario: User taps reset link and returns to app, but no explicit recovery completion handling exists in the auth flow, causing account recovery denial or confusing UX loops.
- `SEC-03` File Reference: `lib/features/auth/data/auth_repository.dart:15-16`, `lib/features/auth/data/auth_repository.dart:45-46`, `lib/features/auth/data/auth_repository.dart:56-61`, `lib/features/auth/data/auth_repository.dart:65-70`, `lib/core/services/logger_service.dart:82-91`. Impact: Masked email addresses are logged during auth operations; this is reduced by debug-only logging but still PII in developer logs. Exploit/Failure scenario: Shared QA devices or CI/dev logs leak partially identifiable email data.
- `SEC-04` File Reference: `lib/features/auth/data/auth_repository.dart:55-62`, `lib/features/profile/data/profile_repository.dart:66-68`. Impact: Password reset can be triggered via two code paths with different redirect behavior (`redirectTo` in auth, none in profile repo), creating inconsistent callback destinations. Exploit/Failure scenario: Reset initiated from one screen returns to web/default flow while another returns to app, breaking recovery consistency and increasing support risk.

### 3.2 Data Integrity
- `DI-01` File Reference: `lib/features/auth/data/auth_repository.dart:16-34`. Impact: Signup performs auth user creation and `profiles` insert as separate operations with no transaction or compensation. Failure scenario: Auth user is created, `profiles.insert` fails (RLS/network/constraint), and subsequent login or signup attempts fail or behave inconsistently due to missing profile row.
- `DI-02` File Reference: `lib/features/auth/viewmodels/auth_view_model.dart:131-149`, `lib/features/auth/data/auth_repository.dart:75-86`. Impact: `AuthViewModel.login()` treats profile fetch failure as login failure, and the repository uses `.single()` which throws on missing/duplicate rows. Failure scenario: Credentials are valid and session exists, but a missing/duplicate profile row causes a false “login failed” path and blocks navigation.
- `DI-03` File Reference: `lib/features/auth/data/auth_repository.dart:21-25`. Impact: Signup behavior changes based on whether Supabase returns an immediate session; the code force-attempts password sign-in when session is null. Failure scenario: Environment with email confirmation enabled/disabled behaves differently, causing unexpected auto-login or extra failures after signup.
- `DI-04` File Reference: `lib/features/auth/data/auth_repository.dart:30-34`, `lib/features/profile/data/profile_repository.dart:51-53`. Impact: Email is stored in both auth and `profiles`, but profile flow updates auth email only. Failure scenario: UI reads stale `profiles.email` while auth session uses updated `auth.users.email`, causing user-visible mismatch and potential business-rule errors.

### 3.3 Architecture
- `ARC-01` File Reference: `lib/main.dart:122-126`, `lib/features/auth/view/login_screen.dart:83-85`, `lib/features/auth/view/signup_screen.dart:86-88`, `lib/features/auth/view/forgot_password_screen.dart:57-59`. Impact: The app owns a global `AuthViewModel`, but auth screens create separate local instances, splitting state ownership. Failure scenario: Session callbacks and UI state diverge across instances, causing inconsistent navigation/error behavior.
- `ARC-02` File Reference: `lib/features/auth/viewmodels/auth_view_model.dart:45-55`. Impact: Each `AuthViewModel` instance subscribes to `auth.onAuthStateChange` immediately in the constructor. Failure scenario: Opening auth screens creates duplicate auth listeners and duplicate event handling/logging.
- `ARC-03` File Reference: `lib/features/auth/viewmodels/auth_view_model.dart:58-62`, `lib/features/auth/viewmodels/auth_view_model.dart:74-87`, `lib/main.dart:203-215`. Impact: App-level session-expiry navigation callback is wired, but `AuthViewModel` only invokes it on stream error and not on `signedOut`. Failure scenario: User signs out or session expires via normal signed-out event, and app remains on protected UI instead of redirecting cleanly to `/login`.
- `ARC-04` File Reference: `lib/features/auth/viewmodels/auth_view_model.dart:15`, `lib/features/auth/viewmodels/auth_view_model.dart:45-49`. Impact: ViewModel directly depends on Supabase SDK singleton for auth state stream, reducing DI testability and MVVM boundary clarity. Failure scenario: Future auth backend changes or test doubles require invasive ViewModel edits.

### 3.4 Code Quality
- `CQ-01` File Reference: `lib/features/auth/viewmodels/auth_view_model.dart:220-248`. Impact: Substring-based error mapping classifies any message containing `"password"` or `"email"` into generic validation messages. Failure scenario: Rate-limit, password-recovery, or server policy errors are misreported, slowing diagnosis and misleading users.
- `CQ-02` File Reference: `lib/features/auth/data/auth_repository.dart:21`. Impact: A non-English inline comment breaks the repository’s otherwise English code/comment style. Failure scenario: Maintainers miss intent or skip reviewing a critical signup branch due to language inconsistency.
- `CQ-03` File Reference: `lib/features/auth/view/forgot_password_screen.dart:34-50`. Impact: Redundant `mounted` checks add noise and obscure the actual control flow. Failure scenario: Future edits add branches and developers misread guard coverage.
- `CQ-04` File Reference: `lib/features/auth/data/auth_repository.dart:75-86`, `lib/features/auth/viewmodels/auth_view_model.dart:136-139`. Impact: Profile reads use untyped `Map<String, dynamic>` and string-key access in ViewModel log code. Failure scenario: Schema/key rename compiles successfully but fails at runtime.

### 3.5 Performance
- `PER-01` File Reference: `lib/features/auth/view/signup_screen.dart:111-338`. Impact: Signup screen rebuilds the full form subtree on every auth state change (`isLoading`/`error`). Failure scenario: Repeated loading toggles cause unnecessary widget rebuilds and jank on lower-end devices.
- `PER-02` File Reference: `lib/features/auth/viewmodels/auth_view_model.dart:135-139`, `lib/features/auth/data/auth_repository.dart:79-83`. Impact: Login performs an extra `profiles` query and uses it only for logging `full_name`. Failure scenario: Login latency increases and fails more often due to extra network dependence.
- `PER-03` File Reference: `lib/features/auth/viewmodels/auth_view_model.dart:109-117`, `lib/features/auth/viewmodels/auth_view_model.dart:45-55`, `lib/main.dart:122-126`, `lib/features/auth/view/login_screen.dart:83-85`, `lib/features/auth/view/signup_screen.dart:86-88`, `lib/features/auth/view/forgot_password_screen.dart:57-59`. Impact: Unconditional `notifyListeners()` plus duplicate `AuthViewModel` instances amplify rebuild/event overhead. Failure scenario: Extra listener notifications trigger unnecessary UI work and duplicate auth-state reactions.

### 3.6 Testing Gaps
- `TST-01` File Reference: `test/unit/auth/auth_view_model_test.dart:14-131`, `test/widget/auth/login_screen_test.dart:74-179`, `integration_test/app_startup_login_flow_test.dart:9-62`. Impact: Existing tests validate login VM/login UI/basic startup only; signup, forgot-password, and session-expiry redirect paths are not covered in observed files. Failure scenario: Regressions in signup/reset/session handling ship without test failures.
- `TST-02` File Reference: UNVERIFIED (missing files) `test/widget/auth/signup_screen_test.dart`, `test/widget/auth/forgot_password_screen_test.dart`. Impact: Widget behavior for signup/reset validation, loading, and snackbar paths is not evidenced in current repo state. Failure scenario: UI regressions in form validation or navigation are undetected.
- `TST-03` File Reference: `lib/features/auth/data/auth_repository.dart:55-62`, `lib/features/auth/viewmodels/auth_view_model.dart:54-89`, `android/app/src/main/AndroidManifest.xml:34-40`, `ios/Runner/Info.plist:56-68`; UNVERIFIED (missing integration tests) `integration_test/*password*`, `integration_test/*session*expiry*`. Impact: Password recovery callback completion and signed-out/session-expiry redirect are high-risk paths without evidenced integration tests. Failure scenario: Production recovery/session handling breaks while happy-path login tests still pass.

## 4) Dead/Unused Code Candidates
- Candidate: Placeholder social login buttons are interactive UI elements with no behavior (`onTap: () {}`), so they function as dead placeholders. File References: `lib/features/auth/view/login_screen.dart:266-276`, `lib/features/auth/view/login_screen.dart:314-336`, `lib/features/auth/view/signup_screen.dart:298-309`, `lib/features/auth/view/signup_screen.dart:348-370`. Why unused: No auth action or service call is wired. How to confirm: `rg -n "_buildSocialButton|onTap: \\(\\) \\{\\}" lib/features/auth/view --glob '*.dart'`.
- Candidate: `AuthViewModel.currentUserEmail`, `AuthViewModel.isAuthenticated`, and `AuthViewModel.clearError()` appear unused in current repo scan. File References: `lib/features/auth/viewmodels/auth_view_model.dart:104-122`. Why unused: No call sites were found in observed code scan output. How to confirm: `rg -n "currentUserEmail\\b|isAuthenticated\\b|clearError\\(" lib --glob '*.dart'`.
- Candidate: Per-screen local `ChangeNotifierProvider(AuthViewModel())` instances may be removable after auth state ownership is centralized. File References: `lib/features/auth/view/login_screen.dart:83-85`, `lib/features/auth/view/signup_screen.dart:86-88`, `lib/features/auth/view/forgot_password_screen.dart:57-59`. Why unused (candidate after refactor): Duplicates global provider in `lib/main.dart:122-126`. How to confirm: migrate screens to injected/global form/session VMs, then run auth widget/integration tests.

## 5) Duplicate Code Candidates
- Duplicate: Social button row + `_buildSocialButton` helper in login and signup. File References: `lib/features/auth/view/login_screen.dart:266-276`, `lib/features/auth/view/login_screen.dart:314-336`, `lib/features/auth/view/signup_screen.dart:298-309`, `lib/features/auth/view/signup_screen.dart:348-370`. Proposed shared abstraction: `lib/features/auth/view/widgets/auth_social_buttons_row.dart`.
- Duplicate: Email validation strings/logic repeated across auth screens. File References: `lib/features/auth/view/login_screen.dart:174-179`, `lib/features/auth/view/signup_screen.dart:202-210`, `lib/features/auth/view/forgot_password_screen.dart:140-148`. Proposed shared abstraction: `lib/features/auth/view/utils/auth_validators.dart`.
- Duplicate: Auth visual shell (gradient container, centered scroll/form layout, branding blocks) repeated across screens. File References: `lib/features/auth/view/login_screen.dart:86-155`, `lib/features/auth/view/signup_screen.dart:89-162`, `lib/features/auth/view/forgot_password_screen.dart:69-123`. Proposed shared abstraction: `lib/features/auth/view/widgets/auth_gradient_scaffold.dart` + `lib/features/auth/view/widgets/auth_brand_header.dart`.
- Duplicate: Password reset initiation API exists in both auth and profile repositories with inconsistent redirect handling. File References: `lib/features/auth/data/auth_repository.dart:55-62`, `lib/features/profile/data/profile_repository.dart:66-68`. Proposed shared abstraction: `lib/features/auth/data/auth_password_reset_service.dart` or single repository method used by both features.
- Duplicate: Login/signup success snackbar + `MainNavigationScreen` navigation patterns are similar and route to the same target. File References: `lib/features/auth/view/login_screen.dart:59-76`, `lib/features/auth/view/signup_screen.dart:66-79`, `lib/app/main_navigation_screen.dart:20-30`. Proposed shared abstraction: route helper or auth navigation coordinator method.

## 6) Refactor Plan (Exact Paths)
- Split combined auth ViewModel responsibilities.
  - Create: `lib/features/auth/viewmodels/auth_session_view_model.dart`
  - Create: `lib/features/auth/viewmodels/auth_form_view_model.dart`
  - Keep temporary compatibility wrapper/export: `lib/features/auth/viewmodels/auth_view_model.dart`
  - Migration strategy: keep `AuthViewModel` delegating to new classes for one phase; update imports incrementally; remove wrapper after tests pass.
- Separate auth account IO from profile bootstrap IO.
  - Create: `lib/features/auth/data/auth_account_repository.dart`
  - Create: `lib/features/auth/data/auth_profile_repository.dart`
  - Keep temporary facade: `lib/features/auth/data/auth_repository.dart`
  - Migration strategy: move code first, re-export old API, then tighten call sites and delete facade later.
- Extract duplicated auth UI shell/components.
  - Create: `lib/features/auth/view/widgets/auth_gradient_scaffold.dart`
  - Create: `lib/features/auth/view/widgets/auth_brand_header.dart`
  - Create: `lib/features/auth/view/widgets/auth_social_buttons_row.dart`
  - Create: `lib/features/auth/view/utils/auth_validators.dart`
  - Migration strategy: refactor login first, then signup, then forgot-password; keep UI strings unchanged (English).
- Add password recovery completion flow.
  - Create: `lib/features/auth/view/reset_password_update_screen.dart`
  - Create (optional route constants): `lib/features/auth/auth_routes.dart`
  - Edit app route wiring in `lib/main.dart`
  - Migration strategy: add route/screen before changing reset callbacks; verify deep-link callback on both Android/iOS.
- Centralize password reset initiation to avoid redirect drift.
  - Create: `lib/features/auth/data/auth_password_reset_service.dart` (or add to `auth_account_repository.dart`)
  - Edit callers in `lib/features/auth/viewmodels/auth_form_view_model.dart` and `lib/features/profile/data/profile_repository.dart`
  - Migration strategy: preserve old method signatures temporarily and deprecate duplicated profile repo method.

## 7) Fix Plan (Phases)
### Phase 1: Critical security & correctness
1. What to change: Make signup profile bootstrap safe and idempotent; remove brittle client-only `profiles.insert` dependency for account provisioning (prefer DB trigger/RPC guarded by RLS/SECURITY DEFINER server-side logic as appropriate).
   Exact file(s) to edit/create: `lib/features/auth/data/auth_repository.dart` (or new `lib/features/auth/data/auth_account_repository.dart` / `lib/features/auth/data/auth_profile_repository.dart`), UNVERIFIED new SQL migration file under `supabase/migrations/` for `profiles` provisioning/policies (missing in repo).
   Acceptance criteria: Signup does not leave unrecoverable partial accounts when profile write fails; repeated signup/retry produces deterministic outcome; `profiles` authz rules are versioned in repo SQL.
2. What to change: Decouple login success from profile fetch success and replace `.single()` hard-failure path for profile bootstrap with tolerant handling (`maybeSingle`, fallback, or deferred fetch).
   Exact file(s) to edit/create: `lib/features/auth/viewmodels/auth_view_model.dart`, `lib/features/auth/data/auth_repository.dart`.
   Acceptance criteria: Valid credentials return login success even when profile row is missing/duplicated; UI receives a recoverable state/message; no false negative login due only to profile read.
3. What to change: Add password recovery completion handling (Dart-side) and route/screen for setting a new password after Supabase callback.
   Exact file(s) to edit/create: `lib/features/auth/viewmodels/auth_view_model.dart` (or `auth_session_view_model.dart`), `lib/main.dart`, `lib/features/auth/view/reset_password_update_screen.dart`.
   Acceptance criteria: Reset email -> callback opens app -> user can set new password -> login succeeds with new password; auth event handling includes explicit recovery path.
4. What to change: Unify password reset redirect behavior across auth and profile flows.
   Exact file(s) to edit/create: `lib/features/auth/data/auth_repository.dart`, `lib/features/profile/data/profile_repository.dart`, new shared reset service/repository file (`lib/features/auth/data/auth_password_reset_service.dart` or `lib/features/auth/data/auth_account_repository.dart`).
   Acceptance criteria: All reset initiation paths use the same `redirectTo` policy and tested callback destination.
5. What to change: Fix session-expiry redirect to trigger on actual signed-out state, not only stream error.
   Exact file(s) to edit/create: `lib/features/auth/viewmodels/auth_view_model.dart`, `lib/main.dart`.
   Acceptance criteria: Signed-out/session-expired events navigate to `/login` and clear protected navigation stack reliably.

### Phase 2: Refactor/structure
1. What to change: Separate session listener state from form submission state; remove duplicate per-screen auth listeners/providers.
   Exact file(s) to edit/create: `lib/features/auth/viewmodels/auth_session_view_model.dart`, `lib/features/auth/viewmodels/auth_form_view_model.dart`, `lib/features/auth/viewmodels/auth_view_model.dart` (compat), `lib/main.dart`, `lib/features/auth/view/login_screen.dart`, `lib/features/auth/view/signup_screen.dart`, `lib/features/auth/view/forgot_password_screen.dart`.
   Acceptance criteria: Only one auth session listener is active app-wide; auth screens use injected/shared state without creating extra `AuthViewModel()` listeners.
2. What to change: Move Supabase stream binding behind repository/service interface to restore MVVM direction.
   Exact file(s) to edit/create: `lib/features/auth/data/auth_account_repository.dart` (or `lib/features/auth/data/auth_repository.dart`), `lib/features/auth/viewmodels/auth_session_view_model.dart`.
   Acceptance criteria: ViewModel no longer references `Supabase.instance` directly; auth stream is injectable/testable.
3. What to change: Extract shared auth UI shell/widgets and validators to remove duplication.
   Exact file(s) to edit/create: `lib/features/auth/view/widgets/auth_gradient_scaffold.dart`, `lib/features/auth/view/widgets/auth_brand_header.dart`, `lib/features/auth/view/widgets/auth_social_buttons_row.dart`, `lib/features/auth/view/utils/auth_validators.dart`, plus edits to auth screens.
   Acceptance criteria: Login/signup/forgot screens share the same extracted components; strings remain English-only.

### Phase 3: Tests
1. What to change: Add unit tests for signup/profile-bootstrap and login/profile-fetch edge cases.
   Exact file(s) to edit/create: `test/unit/auth/auth_repository_test.dart` (new), `test/unit/auth/auth_view_model_test.dart`.
   Acceptance criteria: Tests cover profile insert failure, missing/duplicate profile row, signed-out callback path, and error mapping edge cases.
2. What to change: Add widget tests for signup and forgot-password screens.
   Exact file(s) to edit/create: `test/widget/auth/signup_screen_test.dart`, `test/widget/auth/forgot_password_screen_test.dart`.
   Acceptance criteria: Validation, loading state, success/failure snackbar, and navigation behavior are covered.
3. What to change: Add integration tests for password recovery callback completion and session-expiry redirect.
   Exact file(s) to edit/create: `integration_test/auth_password_recovery_flow_test.dart`, `integration_test/auth_session_expiry_redirect_test.dart`.
   Acceptance criteria: End-to-end flows pass on configured test environment and fail on regression.
4. What to change: Add Supabase/RLS contract validation for `profiles` auth policies (repo-stored SQL and/or scripted checks).
   Exact file(s) to edit/create: UNVERIFIED new SQL/policy files under `supabase/migrations/`; optional validation docs `supabase/README_auth_rls_checks.md`.
   Acceptance criteria: `profiles` RLS rules are versioned and auditable from repo; auth flow policy expectations are documented.

### Phase 4: Polish/perf
1. What to change: Reduce `SignupScreen` rebuild scope and avoid extra notifications when state value is unchanged.
   Exact file(s) to edit/create: `lib/features/auth/view/signup_screen.dart`, `lib/features/auth/viewmodels/auth_view_model.dart` (or `auth_form_view_model.dart`).
   Acceptance criteria: Only action/error subtrees rebuild on auth state changes; no functional regression in signup UX.
2. What to change: Remove login profile fetch if only used for logging, or narrow query to required field with tolerant handling.
   Exact file(s) to edit/create: `lib/features/auth/viewmodels/auth_view_model.dart`, `lib/features/auth/data/auth_repository.dart`.
   Acceptance criteria: Login path has one fewer network dependency or explicit minimal/tolerant fetch behavior.
3. What to change: Replace placeholder social buttons with disabled UI state or actual implementation flag.
   Exact file(s) to edit/create: `lib/features/auth/view/login_screen.dart`, `lib/features/auth/view/signup_screen.dart`, optional shared `lib/features/auth/view/widgets/auth_social_buttons_row.dart`.
   Acceptance criteria: Users are not presented with tappable no-op auth controls.
4. What to change: Tighten error mapping to typed/auth-specific cases instead of broad substring matching.
   Exact file(s) to edit/create: `lib/features/auth/viewmodels/auth_view_model.dart` (or `auth_form_view_model.dart`).
   Acceptance criteria: Distinct auth failures map to accurate user messages; rate-limit/recovery/policy errors are not mislabeled as weak-password/invalid-email.

## 8) Verification Checklist
### Commands
- `flutter analyze`
- `flutter test test/unit/auth/auth_view_model_test.dart`
- `flutter test test/unit/auth/auth_repository_test.dart`
- `flutter test test/widget/auth/login_screen_test.dart`
- `flutter test test/widget/auth/signup_screen_test.dart`
- `flutter test test/widget/auth/forgot_password_screen_test.dart`
- `flutter test integration_test/app_startup_login_flow_test.dart`
- `flutter test integration_test/auth_password_recovery_flow_test.dart`
- `flutter test integration_test/auth_session_expiry_redirect_test.dart`
- `rg -n "create: \\(_\\) => AuthViewModel\\(" lib/main.dart lib/features/auth/view --glob '*.dart'`
- `rg -n "AuthChangeEvent\\.signedOut|passwordRecovery" lib/features/auth lib/main.dart --glob '*.dart'`
- `rg -n "resetPasswordForEmail\\(" lib/features/auth lib/features/profile --glob '*.dart'`
- `rg -n "\\.single\\(\\)|\\.maybeSingle\\(" lib/features/auth --glob '*.dart'`
- `rg -n "onTap: \\(\\) \\{\\}" lib/features/auth/view --glob '*.dart'`

### Manual Scenarios
- Cold start while logged out: app opens login screen and does not expose protected screens. File References: `lib/main.dart:228-235`, `integration_test/app_startup_login_flow_test.dart:13-33`.
- Login happy path: valid credentials navigate to `MainNavigationScreen`. File References: `lib/features/auth/view/login_screen.dart:49-77`, `lib/app/main_navigation_screen.dart:20-30`.
- Login with valid auth but missing profile row (simulate DB issue): app reports recoverable profile state, not false login failure. File References to fix path: `lib/features/auth/viewmodels/auth_view_model.dart:131-149`, `lib/features/auth/data/auth_repository.dart:75-86`.
- Signup under email-confirmation on/off configurations: flow remains deterministic and user-facing next step is correct. File References: `lib/features/auth/data/auth_repository.dart:16-25`, `lib/features/auth/view/signup_screen.dart:41-80`.
- Password reset: request reset, open callback link on Android/iOS, complete password update, then login with new password. File References: `lib/features/auth/data/auth_repository.dart:55-62`, `android/app/src/main/AndroidManifest.xml:34-40`, `ios/Runner/Info.plist:56-68`.
- Session expiry / sign-out on protected screen: app clears stack and returns to `/login`. File References: `lib/main.dart:203-215`, `lib/features/auth/viewmodels/auth_view_model.dart:58-89`.
- Auth screens: no tappable no-op social buttons remain. File References: `lib/features/auth/view/login_screen.dart:266-336`, `lib/features/auth/view/signup_screen.dart:298-370`.

### Supabase/RLS Contract Checks
- UNVERIFIED current repo state: `profiles` table schema and policies are not present as versioned SQL in `supabase/migrations/` (missing `profiles` SQL/policy files from repo scan).
- Required SQL/policies to exist (repo-stored and DB-applied):
  - `profiles` table definition (or documented ownership if managed elsewhere)
  - `ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;`
  - Policies for `SELECT`, `INSERT`, `UPDATE` enforcing `auth.uid() = id` (or stricter documented logic)
  - If server-side profile bootstrap is adopted: trigger/function SQL with clear security model (SECURITY DEFINER usage audited and minimal)
- How to validate (after SQL exists):
  - Confirm SQL file(s) in `supabase/migrations/` reference `public.profiles` and policy statements.
  - Run local/CI policy checks (scripted or SQL) that prove anon users cannot read/write other users’ profiles.
  - Verify signup and login behavior against the policy contract (no client-side service-role usage; anon key only via `lib/core/services/supabase_config.dart:19-28`).

## 9) Risks & Rollback Notes
- Risk: Changing signup provisioning (client insert vs server-side trigger/RPC) can break new-user creation if app and DB changes are deployed out of order. File References: `lib/features/auth/data/auth_repository.dart:16-34`; UNVERIFIED future SQL migration file under `supabase/migrations/`.
- Risk: Removing local auth providers before replacing them with a single session/form state strategy can break auth screen loading/error UX and tests. File References: `lib/main.dart:122-126`, `lib/features/auth/view/login_screen.dart:83-85`, `lib/features/auth/view/signup_screen.dart:86-88`, `lib/features/auth/view/forgot_password_screen.dart:57-59`.
- Risk: Session redirect fixes can create navigation loops if `signedOut` handling and manual navigation callbacks both fire without guard logic. File References: `lib/main.dart:203-215`, `lib/features/auth/viewmodels/auth_view_model.dart:58-89`.
- Risk: Password recovery changes depend on keeping Android/iOS URL schemes consistent with the redirect URI. File References: `lib/features/auth/data/auth_repository.dart:57-60`, `android/app/src/main/AndroidManifest.xml:34-40`, `ios/Runner/Info.plist:56-68`.
- Rollback steps:
  - Revert auth Dart changes in `lib/features/auth/**` and `lib/main.dart` together to restore previous provider/listener behavior. File References: `lib/features/auth/viewmodels/auth_view_model.dart:19-249`, `lib/features/auth/view/login_screen.dart:18-337`, `lib/features/auth/view/signup_screen.dart:17-371`, `lib/features/auth/view/forgot_password_screen.dart:11-172`, `lib/main.dart:122-235`.
  - If DB policy/trigger migrations are introduced, rollback must include a reverse migration for `profiles` policy/trigger changes. File Reference: UNVERIFIED future SQL migration path under `supabase/migrations/`.
  - Re-run auth verification commands/tests after rollback before release. File References: `test/unit/auth/auth_view_model_test.dart:14-131`, `test/widget/auth/login_screen_test.dart:74-179`, `integration_test/app_startup_login_flow_test.dart:9-62`.
