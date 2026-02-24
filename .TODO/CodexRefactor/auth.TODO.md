# auth — PHASE 1 Audit Report + Fix Plan

Date: 2026-02-23  
Scope: `lib/features/auth/**` + direct integration/dependencies used by auth flows (`lib/main.dart`, `lib/core/services/logger_service.dart`, `lib/core/services/supabase_config.dart`, documented `profiles` RLS notes in `Sline_everything/SUPABASE_SETUP.md`)

## Overview (what feature does, boundaries, dependencies)

- Feature purpose: user login, signup, password reset, logout/session state handling.
- In-scope auth files:
  - `lib/features/auth/data/auth_repository.dart`
  - `lib/features/auth/viewmodels/auth_view_model.dart`
  - `lib/features/auth/view/login_screen.dart`
  - `lib/features/auth/view/signup_screen.dart`
  - `lib/features/auth/view/forgot_password_screen.dart`
- Direct integration points:
  - `lib/main.dart` (global `AuthViewModel` provider + session-expiry callback wiring)
  - `lib/core/services/logger_service.dart` (logging + crash reporting path)
  - `lib/core/services/supabase_config.dart` (client auth config / anon key)
  - `Sline_everything/SUPABASE_SETUP.md` (documented `profiles` RLS policies)
- Data dependencies touched by auth code:
  - Supabase Auth (`signUp`, `signInWithPassword`, `resetPasswordForEmail`, `signOut`)
  - `public.profiles` table (`insert`, `select().eq('id', user.id).single()`)
- Static analysis result:
  - `flutter analyze lib/features/auth lib/main.dart` -> `No issues found!` (semantic risks remain; analyzer did not catch them)

## Findings

### Security (highest priority)

- [High] PII leakage in auth logs and crash reporting path.
  - `lib/features/auth/viewmodels/auth_view_model.dart:135` logs `profile['full_name']` after login.
  - `lib/features/auth/viewmodels/auth_view_model.dart:141`, `:169`, `:188`, `:206` interpolate raw auth errors into log messages (`'... failed: $e'`).
  - `lib/core/services/logger_service.dart:176`-`181` forwards logger errors/messages to `CrashReportingService`.
  - `lib/core/services/logger_service.dart:127`-`139` masks tokens only in JSON payloads, not arbitrary error/message strings.
  - Impact: auth error payloads and profile names may be exposed in debug logs and forwarded telemetry.

- [Medium] RLS/auth flow mismatch risk in signup when email confirmation is enabled.
  - `lib/features/auth/data/auth_repository.dart:21`-`25` attempts immediate sign-in if `response.session == null`.
  - `lib/features/auth/data/auth_repository.dart:27`-`34` requires an authenticated session (`currentUser`) before inserting `profiles`.
  - Documented `profiles` insert policies require `auth.uid() = id` (`Sline_everything/SUPABASE_SETUP.md:783`-`785`).
  - Impact: on projects requiring email confirmation, the client may create an auth user but fail profile creation due missing authenticated session; onboarding becomes inconsistent.

- [Medium] Hardcoded password reset redirect URL is environment-specific.
  - `lib/features/auth/data/auth_repository.dart:57`-`60`
  - Impact: reset links can fail on web/dev/staging or if deep-link allowlist changes, causing broken recovery flow. (Not a secret issue, but auth security/usability risk.)

- [Info] No client service-role key usage observed in auth scope.
  - `lib/core/services/supabase_config.dart:6`-`10`, `:17`-`28` documents and uses anon key only.

- [Info] No direct RPC / `SECURITY DEFINER` object usage in auth feature code.
  - Auth code accesses Supabase Auth + `profiles` table only (`lib/features/auth/data/auth_repository.dart:30`, `:79`-`83`).
  - Backend docs contain global `SECURITY DEFINER` warnings, but none are directly invoked by auth feature code in this scope.

### Data Integrity

- [Critical] Non-transactional signup can leave orphaned auth users or missing profile rows.
  - `lib/features/auth/data/auth_repository.dart:16`-`34` performs auth signup, optional sign-in, then separate `profiles` insert.
  - Impact: if `profiles` insert fails (RLS, network, duplicate row, transient DB error), the auth account may still exist. User state becomes partially created.

- [High] Login success can be incorrectly reported as failure if profile read fails.
  - `lib/features/auth/viewmodels/auth_view_model.dart:132`-`143` treats `getCurrentUserProfile()` failure as login failure after successful `signIn`.
  - `lib/features/auth/data/auth_repository.dart:75`-`85` uses `.single()` which throws on 0 or >1 rows.
  - Impact: user may be authenticated server-side but UI shows login failure and blocks navigation; can produce confusing session/UI divergence.

- [Medium] `profiles.email` duplication can drift from Supabase Auth email.
  - `lib/features/auth/data/auth_repository.dart:30`-`34` inserts `email` into `profiles`.
  - `lib/features/profile/data/profile_repository.dart:51`-`53` updates auth email separately.
  - Impact: if no synchronized update path/trigger exists, `auth.users.email` and `profiles.email` may diverge.

- [Medium] Signup UX flow does not model “confirmation email sent” as a valid outcome.
  - `lib/features/auth/viewmodels/auth_view_model.dart:152`-`173` returns only `bool`.
  - `lib/features/auth/view/signup_screen.dart:66`-`74` navigates to main screen on any `true`.
  - Impact: no explicit handling for “account created, confirmation required” vs “signed in immediately”.

### Architecture

- [High] MVVM boundary violation: `AuthViewModel` directly depends on Supabase SDK for auth state stream.
  - `lib/features/auth/viewmodels/auth_view_model.dart:15`, `:51`-`85`
  - Expected direction (per architecture guard): `View -> ViewModel -> Service/Repository -> Supabase`.
  - Impact: ViewModel mixes state orchestration with SDK subscription concerns and becomes harder to isolate in tests.

- [High] Duplicate `AuthViewModel` instances create redundant auth listeners and fragmented auth state.
  - Global provider: `lib/main.dart:103`
  - Local providers:
    - `lib/features/auth/view/login_screen.dart:68`-`70`
    - `lib/features/auth/view/signup_screen.dart:86`-`88`
    - `lib/features/auth/view/forgot_password_screen.dart:57`-`59`
  - `AuthViewModel` constructor always subscribes to `onAuthStateChange` (`lib/features/auth/viewmodels/auth_view_model.dart:44`-`47`, `:51`-`85`)
  - Impact: multiple listeners for one auth stream, inconsistent `onSessionExpired` callback ownership, avoidable rebuild/event duplication.

- [Medium] `AuthViewModel` has multiple responsibilities (session listener, action state, error mapping).
  - `lib/features/auth/viewmodels/auth_view_model.dart` (single file/class handles session lifecycle + all auth actions + error mapping)
  - Impact: changes in one auth flow increase regression risk for others; harder unit testing granularity.

- [Info] No obvious feature-internal cyclic import pattern found.
  - Import scan shows straightforward `view -> viewmodel -> data` references within auth feature.

### Code Quality

- [High] Error mapping logic is brittle and order-dependent; can misclassify errors.
  - `lib/features/auth/viewmodels/auth_view_model.dart:217`-`245`
  - `errorString.contains('password')` (`:231`-`234`) is too broad and runs before some more-specific cases.
  - `errorString.contains('email')` (`:235`-`238`) is also overly broad.
  - Impact: incorrect messages shown to users, harder troubleshooting.

- [Medium] Placeholder social login UI is interactive but no-op.
  - `lib/features/auth/view/login_screen.dart:248`-`258`, `:296`-`318` (`onTap: () {}`)
  - `lib/features/auth/view/signup_screen.dart:298`-`308`, `:348`-`370` (`onTap: () {}`)
  - Impact: dead-end UX; users can tap controls that do nothing.

- [Medium] Unused `AuthViewModel` API members (dead code candidates).
  - `lib/features/auth/viewmodels/auth_view_model.dart:102`-`104` (`currentUserId`, `currentUserEmail`, `isAuthenticated`)
  - `lib/features/auth/viewmodels/auth_view_model.dart:116`-`119` (`clearError()`)
  - Repo-wide usage scan found no references.

- [Low] Redundant `mounted` checks in reset flow.
  - `lib/features/auth/view/forgot_password_screen.dart:34`, `:37`, `:46`
  - Impact: noise; no behavioral issue.

- [Low] Non-English inline code comment in auth repository.
  - `lib/features/auth/data/auth_repository.dart:21`
  - Impact: consistency/readability issue for English-only team conventions (not a UI-string violation).

- [Low] Navigation style inconsistency across auth screens (`named routes` vs `MaterialPageRoute` vs `pop`).
  - `lib/features/auth/view/login_screen.dart:52`-`55`, `:195`-`201`, `:273`
  - `lib/features/auth/view/signup_screen.dart:70`-`73`, `:323`
  - `lib/features/auth/view/forgot_password_screen.dart:44`, `:66`

### Performance

- [High] Multiple `AuthViewModel` instances multiply Supabase auth stream subscriptions.
  - Same evidence as architecture finding:
  - `lib/main.dart:103` + local providers in auth screens + auto-subscribe in `AuthViewModel` constructor.
  - Impact: duplicate event processing and harder-to-debug navigation/session side effects.

- [Medium] `SignupScreen` rebuild scope is too broad.
  - `lib/features/auth/view/signup_screen.dart:111`-`338` wraps almost the entire form column in `Consumer<AuthViewModel>`.
  - Impact: full form rebuild on loading/error state changes instead of rebuilding only action/status widgets.

- [Medium] Redundant network call on login just for logging.
  - `lib/features/auth/viewmodels/auth_view_model.dart:132`-`136` fetches profile immediately and logs `full_name`.
  - Impact: extra `profiles` round-trip on every login; also increases failure surface.

- [Low] `notifyListeners()` is called even when values do not change.
  - `lib/features/auth/viewmodels/auth_view_model.dart:106`-`114`, `:116`-`119`
  - Impact: unnecessary rebuilds (small individually, repeated across flows).

### Testing gaps

- [High] No auth feature tests found in `test/` (no files matched `auth|login|signup|forgot|session`).

- [High] Missing unit tests for critical auth state/error behavior:
  - `AuthViewModel` login/register/reset/logout success/error paths
  - session-expiry callback queue behavior (`onSessionExpired` pending event path)
  - error mapping classification (`_mapAuthError`)

- [High] Missing integration/widget tests for onboarding edge cases:
  - signup when email confirmation is enabled (no immediate session)
  - login when `profiles` row is missing or duplicate
  - password reset success/failure messaging and return navigation

- [Medium] Missing regression test for duplicate auth listeners / session redirect behavior.
  - Global + local `AuthViewModel` providers can cause duplicate auth event listeners today.

## Dead/Unused code candidates (with file paths)

- `lib/features/auth/viewmodels/auth_view_model.dart:102`-`104`
  - Unused getters: `currentUserId`, `currentUserEmail`, `isAuthenticated` (no repo usages found).
- `lib/features/auth/viewmodels/auth_view_model.dart:116`-`119`
  - `clearError()` appears unused (no repo usages found).
- `lib/features/auth/view/login_screen.dart:296`-`318`
  - `_buildSocialButton()` renders tappable placeholders with no-op action (`onTap: () {}`).
- `lib/features/auth/view/signup_screen.dart:348`-`370`
  - `_buildSocialButton()` duplicate no-op placeholder implementation.

## Duplicate code candidates (with file paths)

- Social auth button widget duplicated:
  - `lib/features/auth/view/login_screen.dart:296`-`318`
  - `lib/features/auth/view/signup_screen.dart:348`-`370`

- Repeated auth screen shell/layout patterns (gradient background, brand header, field labels, spacing):
  - `lib/features/auth/view/login_screen.dart`
  - `lib/features/auth/view/signup_screen.dart`
  - `lib/features/auth/view/forgot_password_screen.dart`

- Repeated local auth provider creation (and listener creation side effect):
  - `lib/features/auth/view/login_screen.dart:68`-`70`
  - `lib/features/auth/view/signup_screen.dart:86`-`88`
  - `lib/features/auth/view/forgot_password_screen.dart:57`-`59`

- Duplicate sign-out data-access logic across features:
  - `lib/features/auth/data/auth_repository.dart:64`-`71`
  - `lib/features/profile/data/profile_repository.dart:55`-`57`

## Refactor plan (exact file moves/splits)

Scalpel-first: preserve routes/UI behavior while reducing risk in small steps.

1. Split `AuthViewModel` responsibilities
   - `lib/features/auth/viewmodels/auth_view_model.dart` -> split into:
   - `lib/features/auth/viewmodels/auth_session_view_model.dart`
     - Owns `onAuthStateChange`, session-expiry callback queue, auth session state.
   - `lib/features/auth/viewmodels/auth_actions_view_model.dart`
     - Owns login/register/reset/logout loading/error state.
   - `lib/features/auth/utils/auth_error_mapper.dart`
     - Centralized deterministic auth error mapping.
   - Transitional compatibility (optional, short-lived): keep `lib/features/auth/viewmodels/auth_view_model.dart` as façade wrapper delegating to the two new VMs until screens are migrated.

2. Split data responsibilities in auth repository layer
   - `lib/features/auth/data/auth_repository.dart` -> keep Supabase Auth SDK calls only (`signIn`, `signUp`, `resetPassword`, `signOut`)
   - Extract from `lib/features/auth/data/auth_repository.dart` -> `lib/features/auth/data/auth_profile_repository.dart`
     - `getCurrentUserProfile()`
     - `ensureCurrentUserProfile()` / profile bootstrap logic

3. Extract shared auth UI widgets
   - Extract duplicate social buttons from:
     - `lib/features/auth/view/login_screen.dart`
     - `lib/features/auth/view/signup_screen.dart`
   - New shared widgets:
     - `lib/features/auth/view/widgets/auth_social_login_row.dart`
     - `lib/features/auth/view/widgets/auth_social_button.dart`
   - Extract repeated brand/header shell into:
     - `lib/features/auth/view/widgets/auth_brand_header.dart`
     - `lib/features/auth/view/widgets/auth_gradient_shell.dart`

4. Provider ownership cleanup (integration refactor)
   - `lib/features/auth/view/login_screen.dart` / `signup_screen.dart` / `forgot_password_screen.dart`
     - remove local `ChangeNotifierProvider<AuthViewModel>` creation
   - use a single global auth/session VM from `lib/main.dart`
   - if screen-local form state is needed, use the new `AuthActionsViewModel` locally (no auth stream subscription inside it)

## Fix Plan (Phases)

### Phase 1: critical security & correctness

Scalpel changes only; no wide refactor yet.

1. Fix signup/profile bootstrap flow for email-confirmation projects
   - Stop forcing immediate sign-in when `response.session == null` in `AuthRepository.signUp()`.
   - Return a structured signup outcome (e.g., `signedIn`, `confirmationRequired`) instead of `bool`.
   - Move profile creation to an authenticated moment:
     - either first successful login (`ensureCurrentUserProfile` with idempotent create/upsert), or
     - server-side DB trigger/RPC (preferred if available and audited).
   - Keep RLS as source of truth; do not use service-role in client.

2. Prevent login false-negative after successful auth
   - Make profile fetch non-blocking/non-auth-fatal in login flow.
   - Distinguish auth failure from profile bootstrap/read failure in UI messages.
   - Handle missing profile row explicitly (`maybeSingle`/existence check + self-heal path).

3. Reduce auth PII leakage
   - Remove `full_name` logging on login.
   - Stop interpolating raw auth error strings into user-facing logs/crash events.
   - Prefer sanitized logging (`AppLogger.e('Login failed', error: sanitizedCode)`).

4. Verify password reset redirect configuration path
   - Externalize/reset by environment config (and validate allowed redirects in Supabase project settings).

### Phase 2: refactor/structure

1. Split auth session listener from auth form actions (`AuthSessionViewModel` vs `AuthActionsViewModel`).
2. Remove duplicate local `AuthViewModel` providers in auth screens.
3. Extract `AuthProfileRepository` from `AuthRepository`.
4. Extract shared auth UI widgets (social login row/button, auth shell/header).
5. Consolidate route/navigation behavior for auth screens (consistent route strategy).

### Phase 3: tests

1. Add unit tests for auth action VM/repository:
   - login/register/reset/logout success/failure mapping
   - signup confirmation-required outcome
   - missing profile self-heal behavior
2. Add unit tests for auth session VM:
   - `onAuthStateChange` event handling
   - queued session-expiry callback path
3. Add widget tests:
   - login screen loading/error rendering
   - signup confirmation-required message (no premature navigation)
   - forgot password success/failure flow
4. Add integration smoke test for end-to-end auth happy path (mocked backend or staging env)

### Phase 4: polish/perf

1. Narrow `Consumer` scope in `SignupScreen` (button/status only).
2. Avoid unnecessary `notifyListeners()` when state is unchanged.
3. Remove or disable no-op social login buttons until implemented.
4. Improve field validation consistency (email/password validators shared and deterministic).
5. Add analytics/logging standards for auth without PII leakage.

## Verification steps (commands + manual scenarios)

### Commands

- Static analysis (feature + integration point)
  - `flutter analyze lib/features/auth lib/main.dart`
- Tests (after Phase 3)
  - `flutter test`
  - `flutter test test/features/auth/`
- Search checks (post-fix guardrails)
  - `rg -n "ChangeNotifierProvider\\(create: \\(_\\) => AuthViewModel\\(" lib/main.dart lib/features/auth --glob '*.dart'`
    - Expect exactly one global provider, or no screen-local `AuthViewModel` providers after refactor.
  - `rg -n "User profile loaded:" lib/features/auth --glob '*.dart'`
    - Expect no PII log line.
  - `rg -n "failed: \\$e" lib/features/auth --glob '*.dart'`
    - Expect no raw error interpolation in auth logs.
  - `rg -n "\\.from\\('profiles'\\)" lib/features/auth --glob '*.dart'`
    - Review remaining profile access points after repository split.
  - `rg -n "onAuthStateChange" lib/features/auth lib/main.dart --glob '*.dart'`
    - Verify single ownership of auth stream subscription.

### Manual scenarios

1. Signup (email confirmation ON)
   - Create account.
   - Expect: success/confirmation-needed message, no premature navigation to main screen.
   - Confirm email and log in.
   - Expect: profile row exists and app enters main flow.

2. Signup (email confirmation OFF)
   - Create account.
   - Expect: immediate authenticated flow and profile bootstrap succeeds.

3. Login with missing profile row (simulate in staging/dev DB)
   - Delete profile row for a test user (server/admin only), keep auth user.
   - Log in.
   - Expect: auth succeeds; app handles missing profile explicitly (self-heal or clear recovery error), not generic “invalid login”.

4. Password reset
   - Request reset email from `ForgotPasswordScreen`.
   - Open reset link on target platform (iOS/Android/web).
   - Expect: redirect lands in allowed app route and reset completes.

5. Session expiry
   - Invalidate token / expire session.
   - Expect: single redirect to `/login` with no duplicate navigation stack actions.

6. Screen navigation stress
   - Open/close login/signup/forgot screens repeatedly.
   - Expect: no duplicate session-expiry callbacks or repeated auth event side effects.

7. Offline / poor network
   - Disable network and retry login/reset/signup.
   - Expect: stable error messages, no stuck loading state.

8. English-only UI strings check
   - Review auth screens visually after fixes.
   - Expect: all user-visible strings remain English.

## Risks & rollback notes

- Risk: changing signup flow may alter onboarding behavior/metrics (especially email-confirmation projects).
  - Mitigation: release behind a small staged rollout or QA gate; verify both confirmation ON/OFF projects.

- Risk: profile bootstrap changes can conflict with existing backend trigger/RPC (if present in actual DB but not in repo docs).
  - Mitigation: verify current production DB behavior before introducing client-side `upsert`; make create path idempotent.

- Risk: removing local auth providers without splitting responsibilities can break form-local loading/error UX.
  - Mitigation: introduce `AuthActionsViewModel` before deleting local providers, or adapt screens to consume global VM carefully.

- Risk: sanitizing logs may reduce debugging detail.
  - Mitigation: log stable error codes/categories instead of raw payloads; keep detailed traces server-side only if scrubbed.

- Rollback strategy
  - Phase 1 changes should be split into small commits:
    - signup flow outcome fix
    - login/profile-fetch decoupling
    - logging sanitization
  - If regression occurs, revert the specific commit/phase rather than the full auth module.
