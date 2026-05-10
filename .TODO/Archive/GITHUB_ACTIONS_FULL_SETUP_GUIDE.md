# GitHub Settings — Complete Production Setup Guide for SLine

**App:** SLine (Flutter freelance marketplace with QiCard payments, Supabase backend, Sentry crash reporting)
**Repo Owner:** @faroqomar
**Date:** 2026-04-07

---

## FULL INVENTORY: Every Secret, Variable, and Config SLine Uses

Before configuring anything, here is EVERY secret and configuration value in the entire SLine codebase:

### A) Flutter App — Compile-Time Flags (`--dart-define`)

These are injected at build time via `flutter run --dart-define=KEY=VALUE` or `flutter build apk --dart-define=KEY=VALUE`.

| Variable | Type | File | Default | What It Does |
|----------|------|------|---------|-------------|
| `SENTRY_DSN` | String | `lib/main.dart:94` | `""` (disabled) | Sentry crash reporting endpoint. Empty = Sentry off. |
| `SENTRY_ENV` | String | `lib/main.dart:97` | `"development"` | Sentry environment tag (development/staging/production) |
| `USE_QICARD_PAYMENT` | bool | `lib/main.dart:78` | `true` | `true` = real QiCard payments, `false` = demo/mock payments |
| `QICARD_FINISH_URL` | String | `lib/core/config/payment_runtime_config.dart:3` | `"https://sline.app/?payment_return=1"` | URL QiCard redirects to after payment completes |
| `APP_VERSION` | String | `lib/core/providers/system_config_view_model.dart:39` | `"1.0.0"` | Used for forced-update checks against remote config |
| `VERBOSE_DEBUG_CRASH_REPORTING` | bool | `lib/core/services/crash_reporting_service.dart:3` | `false` | Extra console logging for crash service debugging |

### B) Supabase Edge Functions — Server-Side Secrets (`Deno.env.get`)

These live in Supabase's secret store (not GitHub). Listed here for completeness.

| Variable | File(s) | Required | Sensitivity |
|----------|---------|----------|-------------|
| `SUPABASE_URL` | `_shared/bookin_payment.ts` | Yes (auto-injected hosted) | Public |
| `SUPABASE_ANON_KEY` | `_shared/bookin_payment.ts` | Yes (auto-injected hosted) | Public |
| `SUPABASE_SERVICE_ROLE_KEY` | `_shared/bookin_payment.ts` | Yes (auto-injected hosted) | **SECRET** |
| `QICARD_API_BASE_URL` | `_shared/bookin_payment.ts` | Yes | Public |
| `QICARD_TERMINAL_ID` | `_shared/bookin_payment.ts` | Yes | **SECRET** |
| `QICARD_USERNAME` | `_shared/bookin_payment.ts` | Yes | **SECRET** |
| `QICARD_PASSWORD` | `_shared/bookin_payment.ts` | Yes | **SECRET** |
| `QICARD_RSA_PUBLIC_KEY_PEM` | `finalize_payment_webhook`, `qicard_webhook_handler` | Yes | **SECRET** |
| `QICARD_FINISH_URL` | `_shared/bookin_payment.ts` | Yes | Public |
| `QICARD_PROVIDER_NAME` | `_shared/bookin_payment.ts` | Yes | Public |
| `QICARD_NOTIFICATION_URL` | `_shared/bookin_payment.ts` | Yes | Public |
| `QICARD_ALLOW_UNSIGNED_LOCAL_DEV` | `qicard_webhook_handler` | No (default: false) | Public |
| `FCM_SERVER_KEY` | `push-notify/index.ts` | Yes | **SECRET** |
| `CRON_SECRET` | `process-push-queue/index.ts` | Yes | **SECRET** |
| `PUSH_NOTIFY_SECRET` | `push-notify/index.ts` | Yes | **SECRET** |
| `ALLOWED_ORIGIN` | `_shared/bookin_payment.ts` | Yes | Public |
| `ENVIRONMENT` | `qicard_webhook_handler` | No (default: production) | Public |
| `BOOKING_PAYMENT_EXPIRY_MINUTES` | `_shared/bookin_payment.ts` | No (default: 30) | Public |

### C) Hardcoded in Client Code (Intentionally Public)

| Value | File | Why It's OK |
|-------|------|------------|
| Supabase URL | `lib/core/services/supabase_config.dart:17` | Project identifier, public by design |
| Supabase Anon Key | `lib/core/services/supabase_config.dart:20` | Public key, all access protected by RLS |

### D) Android Signing (Not Configured Yet)

| Item | Current State | File |
|------|--------------|------|
| Keystore file | Not created | Would be at `android/keystore.jks` (gitignored) |
| Keystore password | Not configured | Would be in `android/key.properties` (gitignored) |
| Key alias | Not configured | Same |
| Key password | Not configured | Same |
| Release signing config | Uses debug key | `android/app/build.gradle.kts:40` |

### E) iOS Signing

| Item | Current State | File |
|------|--------------|------|
| Development Team ID | `H6MMG5EFTB` (hardcoded) | `ios/Runner.xcodeproj/project.pbxproj` |
| Code Sign Style | Automatic (Xcode-managed) | Same |
| Provisioning Profile | None specified | Same |

### F) Integration Test Fixtures (`--dart-define`)

Used only when running integration tests manually, NOT in CI.

| Variable | File |
|----------|------|
| `IT_STAGING_CONFIRMED` | `test/integration_test/support/dashboard_env.dart` |
| `IT_LOGIN_EMAIL` | Same |
| `IT_LOGIN_PASSWORD` | Same |
| `IT_DASHBOARD_WALLET_MIN_BALANCE` | Same |
| `IT_DASHBOARD_TASK_ID` | Same |
| `IT_DASHBOARD_TASK_REQUEST_ID` | Same |
| `IT_DASHBOARD_BOOKING_ID` | Same |
| `SUPABASE_INTEGRATION` | `test/storage_rls_test.dart`, `test/rls/chat_creation_security_test.dart` |
| Plus 13 more in `t61_t70_env.dart` | `test/integration_test/support/t61_t70_env.dart` |

### G) Local `.env` File (Exists, Gitignored)

```
SENTRY_DSN=https://424cd5bf020864dda4...  (your Sentry DSN)
SENTRY_ENV=development
```

---

## SECTION 1: Settings -> Actions -> General

### 1.1 Actions Permissions

**Navigate to:** Settings -> Actions -> General

**Select:** "Allow all actions and reusable workflows"

Our 3 workflow files use these 6 external actions:

| Action | Version | Workflow | Purpose |
|--------|---------|----------|---------|
| `actions/checkout@v4` | v4 | All 3 | Clone repo code |
| `subosito/flutter-action@v2` | v2 | ci.yml | Install Flutter 3.38.9 + cache |
| `actions/setup-java@v4` | v4 | ci.yml | Install Java 17 for Android APK |
| `actions/upload-artifact@v4` | v4 | ci.yml | Save APK + web builds for download |
| `actions/dependency-review-action@v4` | v4 | dependency-review.yml | Check for vulnerable deps |
| `trufflesecurity/trufflehog@main` | main | secret-scan.yml | Scan git history for leaked secrets |

**Alternative (more restrictive):** Select "Allow select actions and reusable workflows" and add:
```
actions/*
subosito/flutter-action@*
trufflesecurity/trufflehog@*
```

### 1.2 Artifact and Log Retention

**Leave at:** 90 days (default)

Our `ci.yml` overrides artifacts to 7-day retention. Logs stay 90 days for debugging.

### 1.3 Fork Pull Request Workflows

**Select:** "Require approval for all outside collaborators"

Prevents forks from running your CI and consuming your free minutes (2,000 minutes/month on free tier).

### 1.4 Workflow Permissions

**Select:** "Read repository contents and packages permissions"

Our workflow YAML files each declare `permissions: contents: read`. This is least-privilege — workflows can read code but cannot push commits, create releases, or modify settings.

**Click Save.**

---

## SECTION 2: Settings -> Secrets and variables -> Actions

### 2.1 Secrets Tab — What to Add NOW

**Navigate to:** Settings -> Secrets and variables -> Actions -> Secrets tab

Add these **Repository secrets** (click "New repository secret" for each):

#### Secret 1: `SENTRY_DSN`
- **Value:** Your Sentry DSN URL (from Sentry dashboard -> Project -> Settings -> Client Keys)
- **Currently:** In your local `.env` file, value starts with `https://424cd5bf...`
- **Why:** When you add production builds to CI, this secret injects Sentry crash reporting. Without it, the CI builds have Sentry disabled (empty string default = off).
- **Used by:** Future production build workflow via `--dart-define=SENTRY_DSN=${{ secrets.SENTRY_DSN }}`

#### Secret 2: `SENTRY_AUTH_TOKEN`
- **Value:** From Sentry dashboard -> Settings -> Auth Tokens -> Create New Token (scopes: `project:releases`, `org:read`)
- **Why:** Needed for uploading debug symbols and source maps to Sentry so crash reports show readable stack traces.
- **Used by:** Future Sentry release workflow

#### Secret 3: `SUPABASE_ACCESS_TOKEN`
- **Value:** From Supabase dashboard -> Account -> Access Tokens -> Generate New Token
- **Why:** If you ever add `supabase db push`, `supabase functions deploy`, or migration CI steps, this authenticates the Supabase CLI.
- **Used by:** Future Supabase deployment workflow

#### Secret 4: `KEYSTORE_BASE64`
- **Value:** Your Android signing keystore, base64-encoded
- **How to create:**
  1. Generate a keystore (if you haven't): `keytool -genkey -v -keystore sline-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias sline`
  2. Base64-encode it: `base64 -i sline-release.jks | pbcopy` (copies to clipboard on Mac)
  3. Paste the result as the secret value
- **Why:** Required for signed release APK builds in CI
- **Used by:** Future release build workflow

#### Secret 5: `KEYSTORE_PASSWORD`
- **Value:** The password you set when creating the keystore
- **Why:** Unlocks the keystore file during CI release builds

#### Secret 6: `KEY_ALIAS`
- **Value:** The key alias inside the keystore (e.g., `sline`)
- **Why:** Identifies which key to use for signing

#### Secret 7: `KEY_PASSWORD`
- **Value:** The password for the specific key (often same as keystore password)
- **Why:** Unlocks the specific signing key

#### Secret 8: `FCM_SERVER_KEY`
- **Value:** Your Firebase Cloud Messaging server key (from Firebase Console -> Project Settings -> Cloud Messaging -> Server Key)
- **Why:** If you ever deploy Edge Functions from CI, this secret is needed by `push-notify` and `process-push-queue` functions.
- **Used by:** Future Edge Function deployment

#### Secret 9: `QICARD_TERMINAL_ID`
- **Value:** Your QiCard payment terminal ID
- **Why:** Same as above — needed for Edge Function deployment from CI

#### Secret 10: `QICARD_USERNAME`
- **Value:** Your QiCard API username

#### Secret 11: `QICARD_PASSWORD`
- **Value:** Your QiCard API password

#### Secret 12: `QICARD_RSA_PUBLIC_KEY_PEM`
- **Value:** QiCard's RSA public key (PEM format) for webhook signature verification

#### Secret 13: `CRON_SECRET`
- **Value:** A strong random string you generate (e.g., `openssl rand -base64 32`)
- **Why:** Authenticates scheduled function calls

#### Secret 14: `PUSH_NOTIFY_SECRET`
- **Value:** A strong random string you generate
- **Why:** Authenticates internal push notification routes

#### Secret 15: `SUPABASE_SERVICE_ROLE_KEY`
- **Value:** From Supabase dashboard -> Settings -> API -> `service_role` key
- **Why:** Bypasses RLS for admin operations in Edge Functions. NEVER use in client code.

**IMPORTANT:** Secrets 4-15 are only needed when you set up production builds and Edge Function deployment in CI. You can add them now to have them ready, or add them later when you build those workflows. None of the current 3 workflows use them.

### 2.2 Variables Tab — What to Add NOW

**Navigate to:** Settings -> Secrets and variables -> Actions -> **Variables** tab

Add these **Repository variables** (click "New repository variable" for each):

| Variable Name | Value | Why |
|---------------|-------|-----|
| `FLUTTER_VERSION` | `3.38.9` | Single place to update Flutter version for CI |
| `JAVA_VERSION` | `17` | Java version for Android builds |
| `SENTRY_ENV` | `production` | Sentry environment tag for production builds |
| `APP_VERSION` | `1.0.0` | App version for forced-update checks |
| `QICARD_FINISH_URL` | `https://sline.app/?payment_return=1` | QiCard payment return URL |
| `QICARD_API_BASE_URL` | `https://uat-sandbox-3ds-api.qi.iq/api/v1` | QiCard API endpoint (change for production) |
| `QICARD_PROVIDER_NAME` | `QiCard` | Payment provider identifier |
| `ALLOWED_ORIGIN` | `https://sline.app` | CORS origin for Edge Functions |
| `SUPABASE_PROJECT_REF` | `isddrknbjsgaantjojhm` | Your Supabase project reference ID |

**Variables vs Secrets:**
- **Variables** = visible in logs, non-sensitive configuration (URLs, version numbers, feature flags)
- **Secrets** = masked in logs, sensitive credentials (passwords, API keys, tokens)

---

## SECTION 3: Settings -> Environments

**Navigate to:** Settings -> Environments

Create these environments for future deployment workflows:

### Environment 1: `staging`

1. Click "New environment" -> Name: `staging`
2. **No protection rules needed** (staging can deploy freely)
3. Add these **environment secrets** (click "Add secret"):
   - `SENTRY_ENV` = `staging`
   - `USE_QICARD_PAYMENT` = `false` (use demo payments in staging)
4. Add these **environment variables** (click "Add variable"):
   - `QICARD_API_BASE_URL` = `https://uat-sandbox-3ds-api.qi.iq/api/v1` (sandbox)
   - `ALLOWED_ORIGIN` = `https://staging.sline.app` (if you have a staging domain)

### Environment 2: `production`

1. Click "New environment" -> Name: `production`
2. **Protection rules:**
   - Check "Required reviewers" -> Add `faroqomar`
   - Check "Wait timer" -> Set to `5` minutes (gives you time to cancel a bad deploy)
3. Add these **environment secrets**:
   - `SENTRY_ENV` = `production`
   - `USE_QICARD_PAYMENT` = `true`
4. Add these **environment variables**:
   - `QICARD_API_BASE_URL` = `https://api.qi.iq/api/v1` (production endpoint — verify this with QiCard)
   - `ALLOWED_ORIGIN` = `https://sline.app`

---

## SECTION 4: Settings -> Code security and analysis

**Navigate to:** Settings -> Code security and analysis

### Enable everything in this order:

| # | Setting | Action | What It Does |
|---|---------|--------|-------------|
| 1 | **Dependency graph** | Verify **Enabled** (usually on by default) | Maps all your dependencies so GitHub knows what you use |
| 2 | **Dependabot alerts** | Click **Enable** | Alerts you when any dependency (pub or GitHub Actions) has a known vulnerability (CVE) |
| 3 | **Dependabot security updates** | Click **Enable** | Auto-creates PRs to fix vulnerable dependencies |
| 4 | **Secret scanning** | Click **Enable** | Scans your entire git history for accidentally committed secrets (API keys, passwords, tokens) |
| 5 | **Push protection** | Click **Enable** | BLOCKS pushes before they happen if they contain a detected secret. This is the most important one — prevents secrets from ever entering git history. |
| 6 | **Secret scanning validity checks** | Enable if available | Checks if detected secrets are still active/valid (not just pattern matches) |

### Custom Secret Patterns (Optional, Advanced)

If available under "Custom patterns", add these patterns specific to SLine:

| Pattern Name | Regex | Why |
|-------------|-------|-----|
| Supabase Service Role Key | `eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+` near `service_role` | Catches accidental service_role key commits (different from the safe anon key) |

---

## SECTION 5: Settings -> Branches (Branch Protection)

**Navigate to:** Settings -> Branches -> "Add branch protection rule"

### 5.1 Branch Name Pattern

**Enter:** `main`

### 5.2 Protect Matching Branches — Check These

| Setting | Value | Why |
|---------|-------|-----|
| **Require a pull request before merging** | Check | Nobody pushes directly to main |
| -> Required approving reviews | `1` | At least 1 person reviews |
| -> Dismiss stale pull request approvals when new commits are pushed | Check | New code needs fresh approval |
| -> Require review from Code Owners | Check | CODEOWNERS file routes reviews to the right person |
| **Require status checks to pass before merging** | Check | CI must pass before merge |
| -> Require branches to be up to date before merging | Check | Branch must be current with main |
| **Require conversation resolution before merging** | Check | All review comments must be resolved |
| **Do not allow bypassing the above settings** | Check | Even admins follow the rules |

### 5.3 Status Checks to Add

Search and select each one in the status checks search box:

**Add immediately (these exist now):**

| # | Status Check Name | What It Validates |
|---|-------------------|-------------------|
| 1 | `Lint & Analyze` | `dart format` correctness + `flutter analyze` (no warnings/errors) |
| 2 | `Architecture Guard` | 7 MVVM boundary checks: no Supabase in views, no Navigator in VMs, no view imports in VMs, no TextEditingController in VMs, no repo imports in views, core->features import limit |
| 3 | `Unit & Widget Tests` | 1195+ tests pass + 40% minimum code coverage floor |
| 4 | `Build (apk)` | Android APK compiles successfully (catches Kotlin/Gradle/native SDK issues) |
| 5 | `Build (web)` | Web build compiles (catches web-specific Dart issues) |

**Add AFTER first PR runs (they won't appear until the workflows have executed at least once):**

| # | Status Check Name | What It Validates |
|---|-------------------|-------------------|
| 6 | `TruffleHog Secret Scan` | No verified leaked secrets in git history or PR diff |
| 7 | `Dependency Vulnerability Check` | No high/critical CVEs in added dependencies |

### 5.4 Settings to Leave UNCHECKED

| Setting | Why Leave Off |
|---------|--------------|
| Require signed commits | Adds GPG key friction for solo dev, low value now |
| Require linear history | Merge commits are fine, squash optional |
| Allow force pushes | Never force push to main |
| Allow deletions | Never delete main |

Click **Create** (or **Save changes**).

---

## SECTION 6: Settings -> Pages

Not needed. SLine deploys via Supabase hosting, not GitHub Pages.

---

## SECTION 7: Settings -> Webhooks

Not needed now. In the future, add webhooks for:
- Slack notifications on PR merges
- CodeMagic or Fastlane build triggers
- Supabase deployment triggers

---

## SECTION 8: Settings -> Deploy Keys

Not needed. No external service needs read access to the repo.

---

## SECTION 9: Issues -> Labels

**Navigate to:** Your repo -> Issues tab -> Labels

Create these labels (click "New label" for each):

| # | Label Name | Color Code | Used By |
|---|-----------|-----------|---------|
| 1 | `dependencies` | `#0075ca` | Dependabot pub dependency PRs |
| 2 | `automated` | `#e4e669` | All Dependabot PRs |
| 3 | `ci` | `#d4c5f9` | Dependabot GitHub Actions PRs |
| 4 | `security` | `#b60205` | Security-related issues |
| 5 | `payment` | `#d93f0b` | Payment/wallet/escrow issues |
| 6 | `migration` | `#fbca04` | Database migration issues |
| 7 | `bug` | (default — should exist already) | Bug report template |
| 8 | `enhancement` | (default — should exist already) | Feature request template |

---

## SECTION 10: Notifications (Your Personal Settings)

**Navigate to:** github.com -> Click your avatar -> Settings -> Notifications

Ensure:
- **Participating** notifications are on (you'll get notified about your own PRs and reviews)
- **Dependabot alerts** notifications are on
- **Watching** the SLine repo

---

## MASTER EXECUTION CHECKLIST

Do these in order. Check each box as you complete it.

```
=== STEP 1: Actions Permissions ===
Settings -> Actions -> General
[ ] Actions permissions: "Allow all actions and reusable workflows"
[ ] Workflow permissions: "Read repository contents and packages permissions"
[ ] Fork PRs: "Require approval for all outside collaborators"
[ ] Click Save

=== STEP 2: Secrets ===
Settings -> Secrets and variables -> Actions -> Secrets tab
[ ] Add: SENTRY_DSN (from your Sentry project)
[ ] Add: SENTRY_AUTH_TOKEN (from Sentry Settings -> Auth Tokens)
[ ] Add: SUPABASE_ACCESS_TOKEN (from Supabase -> Account -> Access Tokens)
[ ] Add: KEYSTORE_BASE64 (base64-encoded keystore file)
[ ] Add: KEYSTORE_PASSWORD
[ ] Add: KEY_ALIAS
[ ] Add: KEY_PASSWORD
[ ] Add: FCM_SERVER_KEY (from Firebase Console)
[ ] Add: QICARD_TERMINAL_ID
[ ] Add: QICARD_USERNAME
[ ] Add: QICARD_PASSWORD
[ ] Add: QICARD_RSA_PUBLIC_KEY_PEM
[ ] Add: CRON_SECRET (generate: openssl rand -base64 32)
[ ] Add: PUSH_NOTIFY_SECRET (generate: openssl rand -base64 32)
[ ] Add: SUPABASE_SERVICE_ROLE_KEY (from Supabase -> Settings -> API)

=== STEP 3: Variables ===
Settings -> Secrets and variables -> Actions -> Variables tab
[ ] Add: FLUTTER_VERSION = 3.38.9
[ ] Add: JAVA_VERSION = 17
[ ] Add: SENTRY_ENV = production
[ ] Add: APP_VERSION = 1.0.0
[ ] Add: QICARD_FINISH_URL = https://sline.app/?payment_return=1
[ ] Add: QICARD_API_BASE_URL = https://uat-sandbox-3ds-api.qi.iq/api/v1
[ ] Add: QICARD_PROVIDER_NAME = QiCard
[ ] Add: ALLOWED_ORIGIN = https://sline.app
[ ] Add: SUPABASE_PROJECT_REF = isddrknbjsgaantjojhm

=== STEP 4: Environments ===
Settings -> Environments
[ ] Create: staging (no protection rules)
[ ] Create: production (required reviewer: faroqomar, wait timer: 5 min)

=== STEP 5: Code Security ===
Settings -> Code security and analysis
[ ] Enable: Dependency graph (verify on)
[ ] Enable: Dependabot alerts
[ ] Enable: Dependabot security updates
[ ] Enable: Secret scanning
[ ] Enable: Push protection
[ ] Enable: Secret scanning validity checks (if available)

=== STEP 6: Push Code & Open PR ===
[ ] git add all new files
[ ] git commit
[ ] git push origin Tests_AND_Ci
[ ] Open PR: Tests_AND_Ci -> main
[ ] Wait for all CI checks to pass

=== STEP 7: Branch Protection ===
Settings -> Branches -> Add branch protection rule
[ ] Branch pattern: main
[ ] Check: Require PR (1 review, dismiss stale, require code owners)
[ ] Check: Require status checks
[ ] Check: Require up-to-date branches
[ ] Check: Require conversation resolution
[ ] Add check: Lint & Analyze
[ ] Add check: Architecture Guard
[ ] Add check: Unit & Widget Tests
[ ] Add check: Build (apk)
[ ] Add check: Build (web)
[ ] Check: Do not allow bypassing
[ ] Click Create

=== STEP 8: After First PR Passes ===
Settings -> Branches -> Edit main rule
[ ] Add check: TruffleHog Secret Scan
[ ] Add check: Dependency Vulnerability Check
[ ] Click Save

=== STEP 9: Labels ===
Issues -> Labels
[ ] Create: dependencies (#0075ca)
[ ] Create: automated (#e4e669)
[ ] Create: ci (#d4c5f9)
[ ] Create: security (#b60205)
[ ] Create: payment (#d93f0b)
[ ] Create: migration (#fbca04)
[ ] Verify: bug exists
[ ] Verify: enhancement exists

=== STEP 10: Verify Everything Works ===
[ ] Push directly to main -> REJECTED (branch protection working)
[ ] Open a PR -> All 7 CI checks appear and run
[ ] Code security page -> Secret scanning = Enabled
[ ] Code security page -> Dependabot alerts = Enabled
[ ] Check Dependabot tab -> Shows dependency graph
```

---

## WHAT THESE SECRETS UNLOCK (Future Workflows)

None of the current 3 workflows use secrets. But having them ready enables these future workflows:

| Future Workflow | Secrets It Uses | What It Does |
|----------------|----------------|-------------|
| Release APK build | `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`, `SENTRY_DSN` | Builds a signed production APK with Sentry enabled |
| Sentry release | `SENTRY_AUTH_TOKEN`, `SENTRY_DSN` | Uploads debug symbols for readable crash reports |
| Edge Function deploy | `SUPABASE_ACCESS_TOKEN`, `FCM_SERVER_KEY`, `CRON_SECRET`, `PUSH_NOTIFY_SECRET`, all QiCard secrets, `SUPABASE_SERVICE_ROLE_KEY` | Deploys Edge Functions from CI with proper secrets |
| Database migration | `SUPABASE_ACCESS_TOKEN` | Runs `supabase db push` from CI |
| Integration tests | Test email/password, fixture IDs | Runs Supabase integration tests in CI |
