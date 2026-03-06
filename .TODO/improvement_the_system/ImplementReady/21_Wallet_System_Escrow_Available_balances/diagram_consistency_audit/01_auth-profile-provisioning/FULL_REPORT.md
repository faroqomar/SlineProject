# FULL REPORT: 01 Auth & Profile Provisioning

## 0) Skill Selection

- **Skills selected**: Evidence-First Reading, Threat Modeling (Security), State Machine & Lifecycle, Idempotency & Concurrency.
- **Why these fit**: Auth provisioning acts as the root state machine for the user. Reading evidence ensures we don't assume trigger behavior. Threat modeling uncovers race conditions (client vs DB trigger) and session restore bypasses.
- **Skills not used**: DB-First Financial Modeling (no money movement). Diagram Crafting (omitted as original is sufficient with minor textual updates).

## 1) Folder Identity

- **Folder name + path**: `.TODO/improvement_the_system/Done/01_auth-profile-provisioning`
- **What system/feature it describes**: User registration, login, session restore, and profile provisioning via DB trigger.
- **Entities involved**: `auth.users`, `public.profiles`, `AuthFormViewModel`, `ProfileRepository`, `AccountGuardService`.

## 2) Human Explanation

When a user registers via the app, `auth.users` receives a new row. Supabase executes an `AFTER INSERT` trigger to atomically create a `public.profiles` row with a default `client` role. The app receives the auth session and attempts to fetch this profile. If the fetch is faster than the trigger (race condition), the app must retry. If the profile is successfully fetched, the user enters the app.
On cold start (session restore) or login, the app checks the user's `account_status` via `AccountGuardService`. If banned or suspended, the user is forcefully signed out and blocked.

## 3) Symbol Legend

- **Circles**: Application States (e.g., Logged In, Banned).
- **Solid Arrows**: Synchronous API calls (e.g., `signInWithPassword`).
- **Dashed Arrows**: Asynchronous DB Triggers or fallbacks.
- **Diamonds**: Logical forks (Profile Exists vs Not Found).

## 4) Extracted Contracts & Invariants

1. **1:1 Identity Contract**: Every `auth.users` row must have one `public.profiles` row (Evidence: `fetchProfile` expects exactly one row).
2. **Account Guard Verification**: All session restores must pass `AccountGuardService` (Evidence: `AuthFormViewModel` intercepts logins to verify status).

## 5) Conflict Scan Results

### 5.1 Naming Drift

- **Conflict**: App code often says "User" when meaning "Profile".
- **Resolution**: Use `auth.users.id` strictly for authentication and `profiles.id` for business logic (even though they share the same UUID).

### 5.2 Logic Drift

- **Conflict**: Client aggressively queries `profiles` immediately after `signUp`.
- **Resolution**: App MUST implement a max-3-retry polling loop (500ms) to accommodate Postgres trigger lag.

### 5.3 Data Model Drift

- **Conflict**: A halted trigger leaves an orphaned `auth.users` row.
- **Resolution**: Implement a cron sweeper for auth rows > 15 mins old without corresponding profiles.

## 6) Security & Failure Modes (Adversarial)

- **Replay / Orphan Risk**: Malicious/failed signups brick the email. _Mitigation_: The 15-minute sweeper cron job cleans up orphaned `auth.users`.
- **Session Bypass**: Banned users keep valid JWTs. _Mitigation_: `AccountGuardService` MUST fire on all app boots (Session Restore).

## 7) UI Mapping

### 7.1 Mobile App UI

- **Screens**: Login, Register, Splash (Session Restore).
- **States**: Loading (spinner during DB trigger wait), Failed (SignOut fallback), Success (Dashboard route).
- **Guardrails**: Disable login button while polling for profile. Force redirect to Login if `AccountGuardService` returns banned.

### 7.2 Admin Dashboard UI

- **Pages**: User Management.
- **Metrics**: Count of active profiles, count of orphaned `auth.users` (swept metrics).
- **Drilldowns**: Ability to manually fire the orphan sweeper or view failed registration logs.

### 7.3 Implementation Hooks

- `AuthFormViewModel.signUp()` -> `ProfileRepository.pollFetchProfile(...)`.
- `main.dart` or `AuthService` -> `AccountGuardService.evaluateCurrentUser()`.

## 8) Diagram Verdict + Best Diagram Type

- **Score now**: 10/10 (based on upgraded flow).
- **Best Diagram Type**: Sequence Diagram (to show async polling and trigger interactions).

## 9) Upgrade Plan

- **Phase 0: Observability**: Log all failed profile fetches post-signup.
- **Phase 1: Contracts**: Enforce `AccountGuardService` on Session Restore.
- **Phase 2: Hardening**: Add the 3-retry loop + `signOut()` failure policy for Flutter.
- **Phase 3: Cleanup**: Implement `pg_cron` for orphaned auth rows.

## 10) Risks

### 10.1 Risks if current version kept

- **Severity High**: Random "Profile Not Found" crashes for new users due to trigger lag.

### 10.2 Risks introduced by fixes

- **Polling UX Delay**: Users might wait up to 1.5s on signup (Mitigation: Add "Setting up your account..." loading text).

## 11) Test Plan (High-value)

- **Integration**: Mock 1000ms delay on the trigger; assert Flutter UI polls, succeeds on try 3, and proceeds.
- **Security**: Ban a user in DB, reboot app with valid session, assert they are signed out.

## 12) Production Checklist

- [ ] Retry loop implemented in `AuthFormViewModel`.
- [ ] `AccountGuardService` wraps application root startup.
- [ ] Sub-15 minute orphan DB sweeper active.
