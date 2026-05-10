# Plan: GitHub / CI / Repository Safeguards — Full Implementation

**Plan Version:** 1.0
**Date:** 2026-04-04
**Created By:** @Planner + Senior Engineering Audit
**Session Log:** `docs/LOG/SESSION_PLAN_GitHub_CI_RepoSafeguards_2026-04-04.md`

---

## 1) Goal

- **Goal:** Bring the SLine repository to production-grade CI/CD maturity with all missing safeguards, workflows, templates, and developer tooling.
- **Why:** The core CI pipeline (lint, architecture guard, test + coverage floor, build) is solid, but the surrounding infrastructure — secret scanning, dependency review, PR process, branch protection, release workflow, platform completeness — is missing entirely. This creates risk for a financial marketplace app.
- **Result:** A repo where every PR is automatically validated for code quality, architecture compliance, coverage regression, dependency vulnerabilities, and secret leaks — with structured review processes and documented manual GitHub configuration.

---

## 2) Scope

### In-Scope

| ID | Item | Owner |
|----|------|-------|
| G1 | Enhanced CI workflow (`ci.yml` improvements) | Agent |
| G2 | Secret scanning workflow | Agent |
| G3 | Dependency review workflow | Agent |
| G4 | Dependabot configuration | Agent |
| G5 | PR template with migration/payment/architecture checklists | Agent |
| G6 | Bug report issue template | Agent |
| G7 | Feature request issue template | Agent |
| G8 | CODEOWNERS file | Agent |
| G9 | Enhanced pre-commit hook (secret detection + env file guard) | Agent |
| G10 | SECURITY.md | Agent |
| G11 | CONTRIBUTING.md | Agent |
| G12 | Edge Function env documentation (`supabase/functions/.env.example`) | Agent |
| G13 | Scripts directory (`scripts/check-secrets.sh`) | Agent |
| G14 | Documentation drift fixes (MVP_ROADMAP, ARCHITECTURE_ANALYSIS) | Agent |
| G15 | GitHub branch protection setup guide | Agent (document) + Manual (configure) |
| G16 | Manual GitHub configuration steps | Manual only |

### Out-of-Scope

- iOS build job (requires macOS runner — higher CI cost, defer to Phase 3)
- Release/deploy workflow (no release process established yet — defer)
- pgTAP database tests (in-scope for Phase D, not this plan)
- Code changes (god-file decomposition, architecture fixes — separate Phase D work)
- Sentry/crash reporting (Phase D item D1, already complete)
- Custom Dart lint rules (requires `custom_lint` package — future work)
- Golden/snapshot widget tests (future testing phase)
- Integration test CI job (tests exist but require device/emulator — future)

---

## 3) Evidence & Findings (From Scan)

### Existing

| Asset | Status | Notes |
|-------|--------|-------|
| `.github/workflows/ci.yml` | Active, 4 jobs | lint + arch guard (7 checks) + test (40% floor) + build |
| `.githooks/pre-commit` | Active | format + analyze |
| `analysis_options.yaml` | 36 rules, strong-mode | Comprehensive |
| Architecture guard | 7 hard-fail checks | Zero current violations |
| Coverage floor | 40% threshold | Live in CI, `if: always()` |
| CORS headers | Fixed | `ALLOWED_ORIGIN` env var, defaults to `https://sline.app` |
| Secret management | Clean | No hardcoded secrets in Edge Functions |
| Supabase config | Hardcoded URL + anon key | Safe (public by design, RLS-protected) |
| `MIGRATION_REVIEW_CHECKLIST.md` | Exists in root | 7-section checklist for migration PRs |
| Documentation | 13+ docs, all current | Comprehensive, internally consistent |

### Missing

| Asset | Risk Level | Notes |
|-------|-----------|-------|
| PR template | MEDIUM | No structured review process |
| Issue templates | LOW | No structured bug/feature reports |
| CODEOWNERS | MEDIUM | No automatic reviewer assignment |
| Dependabot | MEDIUM | No automated dependency updates |
| Secret scanning | HIGH | No detection of accidentally committed secrets |
| Dependency review | MEDIUM | No vulnerability scanning on PRs |
| SECURITY.md | MEDIUM | No responsible disclosure process |
| CONTRIBUTING.md | LOW | Development standards in CLAUDE.md but not contributor-facing |
| `.env.example` | MEDIUM | 12+ Edge Function env vars undocumented |
| `dart_test.yaml` | LOW | Default test runner config (acceptable) |
| `scripts/` directory | LOW | No reusable CI/local scripts |
| `workflow_dispatch` trigger | LOW | Cannot manually trigger CI |

### Must NOT Duplicate

- Coverage floor logic (already in `ci.yml` lines 119-135)
- Architecture guard checks (already in `ci.yml` lines 32-88)
- Pre-commit format + analyze (already in `.githooks/pre-commit`)
- Migration review checklist (already at `MIGRATION_REVIEW_CHECKLIST.md`)
- CORS fix (already done — env-based `ALLOWED_ORIGIN`)

### Conflicts / Risks

| Conflict | Source A | Source B | Resolution |
|----------|---------|---------|------------|
| Coverage target | MVP_ROADMAP.md says "70%" | CI currently enforces 40% floor | CI wins. Update roadmap. |
| ARCHITECTURE_ANALYSIS date | Header says "March 7, 2024" | Content is from 2026 | Typo. Fix to 2026. |
| APK build mode | CI builds `--debug` | Production needs `--release` | Change to release in Phase 2 |
| Check 3 exclusions | Current grep-v chain | Known A6 pattern passes | Tighten after A6 fixes land (Phase D item D11) |

---

## 4) System Impact Map

- **UI:** None
- **MVVM / App Logic:** None
- **Database:** None
- **RLS / Security:** Secret scanning prevents credential leaks
- **RPC / Edge Functions:** `.env.example` documents required vars
- **Storage:** None
- **Realtime / Notifications:** None
- **Observability:** None
- **Compatibility & Migration:** PR template includes migration checklist
- **Contracts:** None
- **Developer Workflow:** PR template, issue templates, CODEOWNERS, enhanced hooks, scripts
- **CI/CD Pipeline:** Secret scan, dependency review, dependabot, workflow improvements
- **Documentation:** SECURITY.md, CONTRIBUTING.md, doc drift fixes
- **GitHub Configuration:** Branch protection, required checks, secret scanning settings

---

## 5) Agent Map

- Phase 0: @Planner, @Sentinel (preconditions)
- Phase 1: @CodeGuard, @Sentinel (CI workflow enhancements)
- Phase 2: @CodeGuard, @Sentinel (new CI workflows)
- Phase 3: @Architect, @Sentinel (developer workflow files)
- Phase 4: @DocsKeeper, @Sentinel (documentation)
- Phase 5: @Planner (manual configuration guide)
- Phase 6: @Sentinel (verification)

---

## Phase 0: Preconditions & Gates

**Primary Agent(s):** @Planner, @Sentinel

### 0.1 Spec Lock

- [ ] (@Sentinel) Acceptance criteria:
  - All new workflow files pass `actionlint` syntax (or equivalent manual review)
  - All new repo files follow project conventions (English, no emoji unless requested)
  - Pre-commit hook enhancements do not break existing developer workflow
  - No existing CI checks are weakened or removed
  - All manual steps are documented with exact click paths
- [ ] (@Planner) Non-regression list:
  - `flutter test` must still pass (706+ tests)
  - `flutter analyze` must still pass (0 issues)
  - Architecture guard (7 checks) must still pass
  - Coverage floor (40%) must still be enforced
  - Pre-commit hook (format + analyze) must still work
- **GATE CHECK:** Scope, acceptance, and non-regression defined.

---

## Phase 1: CI Workflow Enhancements (@CodeGuard)

**Primary Agent(s):** @CodeGuard, @Sentinel
**Goal:** Improve the existing `ci.yml` with missing capabilities
**Why:** Current workflow lacks manual trigger, and APK builds in debug mode
**Result:** Enhanced CI with `workflow_dispatch` and consistent build modes

### 1.1 Add workflow_dispatch Trigger

**File:** `.github/workflows/ci.yml`

- [ ] (@CodeGuard) Add `workflow_dispatch: {}` to the `on:` block
- [ ] (@Sentinel) Verify existing triggers (push, pull_request) are unchanged

### 1.2 Fix APK Build Mode

**File:** `.github/workflows/ci.yml`

- [ ] (@CodeGuard) Change `flutter build apk --debug` to `flutter build apk --debug` (KEEP as debug)
  - **Reasoning:** Release APK requires signing keys (keystore) which are not in CI. Debug is correct for CI compilation validation. Web release works because web doesn't need signing.
  - **Future:** When signing is set up, add a separate release build job
- [ ] (@Sentinel) Verify build matrix still works

### 1.3 Add Build Artifact Upload

**File:** `.github/workflows/ci.yml`

- [ ] (@CodeGuard) Add `actions/upload-artifact@v4` step after build
- [ ] (@CodeGuard) Upload APK and web build outputs
- [ ] (@Sentinel) Verify artifacts are accessible in GitHub Actions UI

**GATE CHECK:** CI workflow enhanced without breaking existing checks.

---

## Phase 2: New CI Workflows (@CodeGuard)

**Primary Agent(s):** @CodeGuard, @Sentinel
**Goal:** Add secret scanning and dependency review as separate workflows
**Why:** Missing safeguards for a financial marketplace app
**Result:** Automated detection of leaked secrets and vulnerable dependencies

### 2.1 Secret Scanning Workflow

**File:** `.github/workflows/secret-scan.yml` (NEW)

- [ ] (@CodeGuard) Create workflow triggered on `push` (all branches) and `pull_request`
- [ ] (@CodeGuard) Use `trufflesecurity/trufflehog@v3` with `--only-verified` flag
- [ ] (@CodeGuard) Configure to scan git history on PR, current commit on push
- [ ] (@Sentinel) Verify workflow blocks merge on verified secret detection
- [ ] (@Sentinel) Verify Supabase anon key (public, intentional) does not trigger false positive

### 2.2 Dependency Review Workflow

**File:** `.github/workflows/dependency-review.yml` (NEW)

- [ ] (@CodeGuard) Create workflow triggered on `pull_request` to `main`
- [ ] (@CodeGuard) Use `actions/dependency-review-action@v4`
- [ ] (@CodeGuard) Configure to fail on `high` and `critical` severity vulnerabilities
- [ ] (@CodeGuard) Allow `moderate` and `low` as warnings (not blocking)
- [ ] (@Sentinel) Verify workflow integrates with GitHub's dependency graph

### 2.3 Dependabot Configuration

**File:** `.github/dependabot.yml` (NEW)

- [ ] (@CodeGuard) Configure pub ecosystem updates (weekly, Mondays)
- [ ] (@CodeGuard) Configure github-actions ecosystem updates (weekly)
- [ ] (@CodeGuard) Set PR limit to 5 per ecosystem to avoid PR flood
- [ ] (@CodeGuard) Add labels for automated PRs (`dependencies`, `automated`)
- [ ] (@Sentinel) Verify dependabot config syntax

**GATE CHECK:** All new workflows created, syntactically valid, and have clear merge-blocking behavior.

---

## Phase 3: Developer Workflow Files (@Architect)

**Primary Agent(s):** @Architect, @Sentinel
**Goal:** Add PR template, issue templates, CODEOWNERS, enhanced hooks, scripts
**Why:** Structured review process and local safeguards for a team repo
**Result:** Every PR has a checklist, every code area has an owner, every commit is secret-scanned locally

### 3.1 PR Template

**File:** `.github/pull_request_template.md` (NEW)

- [ ] (@Architect) Create PR template with sections:
  - What changed (brief description)
  - Why (motivation / ticket link)
  - General checklist (tests, analyze, architecture)
  - Payment/wallet/booking checklist (conditional)
  - Migration checklist (conditional, reference `MIGRATION_REVIEW_CHECKLIST.md`)
  - Supabase/Edge Function checklist (conditional)
- [ ] (@Sentinel) Verify template references the existing migration checklist rather than duplicating it
- [ ] (@Sentinel) Verify template is concise — developers will skip it if too long

### 3.2 Issue Templates

**File:** `.github/ISSUE_TEMPLATE/bug_report.yml` (NEW)

- [ ] (@Architect) Create YAML-based bug report template with:
  - Description, reproduction steps, expected vs actual, environment, screenshots
- [ ] (@Sentinel) Verify template uses YAML format (not markdown) for structured fields

**File:** `.github/ISSUE_TEMPLATE/feature_request.yml` (NEW)

- [ ] (@Architect) Create YAML-based feature request template with:
  - Problem description, proposed solution, alternatives considered, context
- [ ] (@Sentinel) Verify template is useful, not bureaucratic

### 3.3 CODEOWNERS

**File:** `.github/CODEOWNERS` (NEW)

- [ ] (@Architect) Create CODEOWNERS with ownership rules:
  - `*` → default owner (project lead)
  - `lib/features/wallet/` → wallet owner
  - `lib/features/booking/` → booking owner
  - `supabase/` → backend owner
  - `.github/` → CI owner
  - `lib/core/` → core infrastructure owner
- [ ] (@Sentinel) Verify CODEOWNERS syntax is valid
- [ ] (@Sentinel) Note: CODEOWNERS only works when branch protection requires code owner review (manual config step)

### 3.4 Enhanced Pre-Commit Hook

**File:** `.githooks/pre-commit` (UPDATE)

- [ ] (@CodeGuard) Add secret pattern detection before format check:
  - Scan staged diff for `sk_live`, `sk_test`, `service_role`, `password\s*[:=]\s*['"][^\s]+`
  - Exclude `.md` files from secret scan (docs may reference patterns)
- [ ] (@CodeGuard) Add env file staging guard:
  - Block commit if `.env`, `secrets.json`, or `credentials.json` are staged
- [ ] (@Sentinel) Verify existing format + analyze checks are preserved unchanged
- [ ] (@Sentinel) Verify hook does not slow down normal commits significantly (< 2s overhead)

### 3.5 Scripts Directory

**File:** `scripts/check-secrets.sh` (NEW)

- [ ] (@CodeGuard) Create reusable secret scanning script used by both pre-commit and CI
- [ ] (@CodeGuard) Make executable (`chmod +x`)
- [ ] (@Sentinel) Verify script can run standalone for manual checks

**GATE CHECK:** All developer workflow files created, CODEOWNERS valid, hook tested locally.

---

## Phase 4: Documentation (@DocsKeeper)

**Primary Agent(s):** @DocsKeeper, @Sentinel
**Goal:** Add missing repo docs and fix documentation drift
**Why:** Financial app needs SECURITY.md, contributors need onboarding docs, stale docs create confusion
**Result:** Repo has responsible disclosure process, contributor guide, and accurate documentation

### 4.1 SECURITY.md

**File:** `SECURITY.md` (NEW)

- [ ] (@DocsKeeper) Create with sections:
  - Responsible disclosure process (email contact)
  - Security architecture overview (RLS, auth, payment security)
  - What to report (vulnerabilities, data exposure, auth bypass)
  - What NOT to report (known public data like anon key)
  - Response timeline expectations
- [ ] (@Sentinel) Verify no internal secrets or infrastructure details are exposed

### 4.2 CONTRIBUTING.md

**File:** `CONTRIBUTING.md` (NEW)

- [ ] (@DocsKeeper) Create with sections:
  - Getting started (Flutter setup, `git config core.hooksPath .githooks`)
  - Architecture overview (MVVM, reference CLAUDE.md)
  - PR process (reference PR template)
  - Commit conventions (conventional commits optional, reference existing style)
  - Testing requirements (run tests, maintain coverage floor)
  - Code style (reference analysis_options.yaml)
  - Migration process (reference `MIGRATION_REVIEW_CHECKLIST.md`)
- [ ] (@Sentinel) Verify doc is concise and references existing docs rather than duplicating

### 4.3 Edge Function Environment Documentation

**File:** `supabase/functions/.env.example` (NEW)

- [ ] (@DocsKeeper) Document all required Edge Function environment variables:
  - `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`
  - `QICARD_API_BASE_URL`, `QICARD_TERMINAL_ID`, `QICARD_USERNAME`, `QICARD_PASSWORD`
  - `QICARD_RSA_PUBLIC_KEY_PEM`, `QICARD_FINISH_URL`
  - `QICARD_ALLOW_UNSIGNED_LOCAL_DEV`
  - `FCM_SERVER_KEY`, `CRON_SECRET`, `PUSH_NOTIFY_SECRET`
  - `ALLOWED_ORIGIN`
- [ ] (@DocsKeeper) Add comments explaining each variable's purpose
- [ ] (@DocsKeeper) Mark which are required vs optional
- [ ] (@Sentinel) Verify NO actual secrets are in the example file (only placeholders)

### 4.4 Documentation Drift Fixes

**File:** `Sline_everything/MVP_ROADMAP.md` (UPDATE)

- [ ] (@DocsKeeper) Update Section 9 "Current Focus":
  - Change "coverage enforcement (70% target)" to "coverage enforcement (40% regression floor)"
  - Add Phase D progress notes (D1-D3 complete, D4-D11 queued)
- [ ] (@Sentinel) Verify no other sections need updates

**File:** `Sline_everything/ARCHITECTURE_ANALYSIS.md` (UPDATE)

- [ ] (@DocsKeeper) Fix header date from "March 7, 2024" to "2026-03-07 (with embedded notes through 2026-04-03)"
- [ ] (@Sentinel) Verify content accuracy is unchanged

**GATE CHECK:** All docs created, drift fixed, no secrets exposed.

---

## Phase 5: Manual Configuration Guide (@Planner)

**Primary Agent(s):** @Planner
**Goal:** Document every manual step the developer must perform outside the repository
**Why:** Branch protection, required checks, secret scanning settings, and environments cannot be configured via code
**Result:** A clear checklist of manual GitHub configuration steps

This phase produces documentation only. The actual manual steps are performed by the developer.

### 5.1 Document Manual GitHub Configuration

This is documented in the plan itself (see Section B below) and will be referenced in `CONTRIBUTING.md`.

**GATE CHECK:** All manual steps documented with exact click paths.

---

## Phase 6: Verification (@Sentinel)

**Primary Agent(s):** @Sentinel
**Goal:** Verify all changes work together without breaking existing CI
**Why:** Any regression in the CI pipeline blocks the entire team
**Result:** Confirmed non-regression and new safeguards working

### 6.1 Non-Regression Verification

- [ ] (@Sentinel) Run `flutter test` — all 706+ tests pass
- [ ] (@Sentinel) Run `flutter analyze` — 0 issues
- [ ] (@Sentinel) Run `dart format --set-exit-if-changed .` — passes
- [ ] (@Sentinel) Verify `.githooks/pre-commit` works with new secret detection
- [ ] (@Sentinel) Verify all YAML files are syntactically valid

### 6.2 New File Verification

- [ ] (@Sentinel) Verify all new files are tracked by git
- [ ] (@Sentinel) Verify no files conflict with `.gitignore`
- [ ] (@Sentinel) Verify CODEOWNERS syntax with `gh api repos/{owner}/{repo}/codeowners/errors` (after push)

**GATE CHECK:** Full non-regression verified. All new safeguards in place.

---

## SECTION A — Agent-Implementable Items (In-Repository)

### A1. CI Workflow Enhancements

**File:** `.github/workflows/ci.yml`
**Action:** UPDATE
**Changes:**
1. Add `workflow_dispatch: {}` to `on:` block
2. Add `actions/upload-artifact@v4` after each build step
**Priority:** P1
**Why:** Manual trigger enables debugging; artifacts enable inspection of builds
**Order:** 1st

### A2. Secret Scanning Workflow

**File:** `.github/workflows/secret-scan.yml`
**Action:** CREATE
**Content:**
```yaml
name: Secret Scan
on:
  push:
  pull_request:
permissions:
  contents: read
jobs:
  trufflehog:
    name: TruffleHog Secret Scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: trufflesecurity/trufflehog@v3.88.0  # Pin to stable release
        with:
          extra_args: --only-verified
```
**Priority:** P0
**Why:** No secret scanning = one mistake away from permanent credential exposure
**Order:** 2nd

### A3. Dependency Review Workflow

**File:** `.github/workflows/dependency-review.yml`
**Action:** CREATE
**Content:**
```yaml
name: Dependency Review
on:
  pull_request:
    branches: [main]
permissions:
  contents: read
jobs:
  review:
    name: Dependency Vulnerability Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/dependency-review-action@v4
        with:
          fail-on-severity: high
          allow-licenses: MIT, BSD-2-Clause, BSD-3-Clause, Apache-2.0, ISC, Zlib
```
**Priority:** P1
**Why:** Supply chain risk is real for apps with payment flows
**Order:** 3rd

### A4. Dependabot Configuration

**File:** `.github/dependabot.yml`
**Action:** CREATE
**Content:**
```yaml
version: 2
updates:
  - package-ecosystem: "pub"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
    open-pull-requests-limit: 5
    labels:
      - "dependencies"
      - "automated"
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
    open-pull-requests-limit: 3
    labels:
      - "ci"
      - "automated"
```
**Priority:** P1
**Why:** Stale dependencies accumulate vulnerabilities silently
**Order:** 4th

### A5. PR Template

**File:** `.github/pull_request_template.md`
**Action:** CREATE
**Priority:** P0
**Why:** Immediate improvement to review quality and safety for every PR
**Order:** 5th

### A6. Issue Templates

**Files:**
- `.github/ISSUE_TEMPLATE/bug_report.yml` — CREATE
- `.github/ISSUE_TEMPLATE/feature_request.yml` — CREATE
**Priority:** P2
**Why:** Structured reports help prioritize work but are not safety-critical
**Order:** 6th

### A7. CODEOWNERS

**File:** `.github/CODEOWNERS`
**Action:** CREATE
**Priority:** P1
**Why:** Ensures critical paths (payment, auth, Supabase) get reviewed by domain experts
**Order:** 7th

### A8. Enhanced Pre-Commit Hook

**File:** `.githooks/pre-commit`
**Action:** UPDATE
**Changes:** Add secret pattern detection and env file guard before existing format + analyze checks
**Priority:** P0
**Why:** Last line of defense before secrets enter git history
**Order:** 8th

### A9. Secret Check Script

**File:** `scripts/check-secrets.sh`
**Action:** CREATE
**Priority:** P1
**Why:** Reusable by pre-commit hook and manual developer checks
**Order:** 9th (created before hook update references it)

### A10. SECURITY.md

**File:** `SECURITY.md`
**Action:** CREATE
**Priority:** P1
**Why:** Financial marketplace needs responsible disclosure process
**Order:** 10th

### A11. CONTRIBUTING.md

**File:** `CONTRIBUTING.md`
**Action:** CREATE
**Priority:** P2
**Why:** Useful but not safety-critical; CLAUDE.md covers most conventions
**Order:** 11th

### A12. Edge Function .env.example

**File:** `supabase/functions/.env.example`
**Action:** CREATE
**Priority:** P1
**Why:** 14 env vars undocumented; onboarding friction and deployment risk
**Order:** 12th

### A13. Documentation Drift Fixes

**Files:**
- `Sline_everything/MVP_ROADMAP.md` — UPDATE (coverage threshold, Phase D progress)
- `Sline_everything/ARCHITECTURE_ANALYSIS.md` — UPDATE (fix date typo)
**Priority:** P2
**Why:** Stale docs cause confusion but are not blocking
**Order:** 13th

---

## SECTION B — Manual Configuration (Developer Must Do)

### B1. GitHub Branch Protection Rules

**Platform:** GitHub → Repository → Settings → Branches → Branch protection rules
**Branch:** `main`

**Required Actions:**
1. Click "Add branch protection rule"
2. Branch name pattern: `main`
3. Enable: **Require a pull request before merging**
   - Required approving reviews: `1`
   - Dismiss stale pull request approvals when new commits are pushed: YES
   - Require review from Code Owners: YES (after CODEOWNERS is pushed)
4. Enable: **Require status checks to pass before merging**
   - Required checks (add these exact names):
     - `Lint & Analyze`
     - `Architecture Guard`
     - `Unit & Widget Tests`
     - `Build (apk)`
     - `Build (web)`
     - `TruffleHog Secret Scan` (after secret-scan.yml is pushed)
     - `Dependency Vulnerability Check` (after dependency-review.yml is pushed)
   - Require branches to be up to date before merging: YES
5. Enable: **Do not allow bypassing the above settings**
6. Enable: **Restrict who can push to matching branches** (optional, for team repos)
7. Do NOT enable: Require signed commits (low priority, adds friction)
8. Do NOT enable: Require linear history (optional preference)

**Priority:** P0 — BLOCKING
**Why:** Without branch protection, anyone can push directly to main, bypassing all CI checks
**When:** Immediately after the agent pushes the new workflow files

### B2. GitHub Secret Scanning

**Platform:** GitHub → Repository → Settings → Code security and analysis

**Required Actions:**
1. Enable: **Secret scanning** (free for all repos since 2023)
2. Enable: **Push protection** (blocks pushes containing detected secrets)
3. Review: Custom secret patterns (optional — add Supabase service_role pattern if available)

**Priority:** P0 — BLOCKING
**Why:** GitHub's native secret scanning covers more patterns than TruffleHog alone
**When:** Immediately

### B3. GitHub Actions Permissions

**Platform:** GitHub → Repository → Settings → Actions → General

**Required Actions:**
1. Verify: Actions permissions = "Allow all actions and reusable workflows" (or at minimum allow `actions/*`, `subosito/*`, `trufflesecurity/*`)
2. Verify: Workflow permissions = "Read repository contents" (already set in YAML, but verify repo default)

**Priority:** P1
**Why:** New workflows need permission to run
**When:** Before pushing new workflow files

### B4. Enable Dependabot Alerts

**Platform:** GitHub → Repository → Settings → Code security and analysis

**Required Actions:**
1. Enable: **Dependabot alerts**
2. Enable: **Dependabot security updates**
3. Verify: **Dependency graph** is enabled

**Priority:** P1
**Why:** Dependabot config file alone doesn't enable vulnerability alerts
**When:** After pushing `dependabot.yml`

### B5. Required Status Checks Update (After New Workflows)

**Platform:** GitHub → Repository → Settings → Branches → main protection rule

**Required Actions:**
After the secret-scan and dependency-review workflows have run at least once on a PR:
1. Go to branch protection for `main`
2. Add these as required status checks:
   - `TruffleHog Secret Scan`
   - `Dependency Vulnerability Check`

**Priority:** P1
**Why:** New workflows must be added as required checks to actually block merges
**When:** After the first PR with new workflows passes CI

### B6. GitHub Environments (Future — Not Blocking)

**Platform:** GitHub → Repository → Settings → Environments

**Required Actions (when release workflow is implemented):**
1. Create `production` environment
2. Add required reviewers for production deployments
3. Add environment secrets (signing keys, deploy tokens)

**Priority:** P3 — NOT BLOCKING
**Why:** No release workflow yet; needed when one is created
**When:** When release workflow is implemented

### B7. Labels Setup

**Platform:** GitHub → Repository → Issues → Labels

**Required Actions:**
1. Create label: `dependencies` (color: `#0075ca`)
2. Create label: `automated` (color: `#e4e669`)
3. Create label: `ci` (color: `#d4c5f9`)
4. Create label: `security` (color: `#b60205`)
5. Create label: `payment` (color: `#d93f0b`)
6. Create label: `migration` (color: `#fbca04`)

**Priority:** P2
**Why:** Dependabot config references these labels; also useful for issue triage
**When:** Before or after pushing dependabot config

---

## 6) Merge Blockers Plan

### Immediate Merge Blockers (enforce now)

| Check | Status | Job Name |
|-------|--------|----------|
| `dart format --set-exit-if-changed .` | ACTIVE | `Lint & Analyze` |
| `flutter analyze --no-fatal-infos` | ACTIVE | `Lint & Analyze` |
| Architecture guard (6 checks) | ACTIVE | `Architecture Guard` |
| `flutter test` | ACTIVE | `Unit & Widget Tests` |
| Coverage floor (>= 28%) | ACTIVE | `Unit & Widget Tests` |
| Secret scanning | TO ADD | `TruffleHog Secret Scan` |
| Dependency vulnerability review | TO ADD | `Dependency Vulnerability Check` |
| APK build | ACTIVE | `Build (apk)` |
| Web build | ACTIVE | `Build (web)` |
| At least 1 PR review | MANUAL CONFIG | Branch protection |

### Later Merge Blockers (Phase 2-3)

| Check | When | Job Name |
|-------|------|----------|
| iOS build | When macOS runner budget approved | `Build (ios)` |
| Coverage floor increase to 35% | After Phase D tests land | Update `THRESHOLD` in ci.yml |
| Architecture guard Check 3 tightening | After A6 fixes land | Update grep pattern |
| Edge Function Deno lint | When edge function CI is built | `Edge Function Lint` |

---

## 7) Release Blockers Plan

Issues that must be resolved before any production release:

| Blocker | Status | Severity | Notes |
|---------|--------|----------|-------|
| Branch protection on `main` | NOT CONFIGURED | CRITICAL | Manual step B1 |
| Secret scanning enabled | NOT CONFIGURED | CRITICAL | Manual step B2 |
| All CI checks as required status checks | PARTIAL | HIGH | Manual step B5 |
| `qicard_payment_service.dart` untested (811 LOC) | NOT DONE | HIGH | Phase D / future test phase |
| `booking_service.dart` untested | NOT DONE | HIGH | Future test phase |
| No iOS build validation | NOT DONE | MEDIUM | Phase 3 |
| Webhook replay protection | NOT DONE | MEDIUM | Future security hardening |
| Webhook payload PII logging | NOT DONE | LOW | Code fix in Edge Functions |
| SECURITY.md exists | NOT DONE | MEDIUM | Phase 4 of this plan |

---

## 8) Recommended File Additions / Changes

### New Files (14)

| File | Type | Phase |
|------|------|-------|
| `.github/workflows/secret-scan.yml` | CI workflow | 2 |
| `.github/workflows/dependency-review.yml` | CI workflow | 2 |
| `.github/dependabot.yml` | Config | 2 |
| `.github/pull_request_template.md` | Template | 3 |
| `.github/ISSUE_TEMPLATE/bug_report.yml` | Template | 3 |
| `.github/ISSUE_TEMPLATE/feature_request.yml` | Template | 3 |
| `.github/CODEOWNERS` | Config | 3 |
| `scripts/check-secrets.sh` | Script | 3 |
| `SECURITY.md` | Documentation | 4 |
| `CONTRIBUTING.md` | Documentation | 4 |
| `supabase/functions/.env.example` | Documentation | 4 |
| `.TODO/PLAN_GitHub_CI_RepoSafeguards_2026-04-04.md` | Plan | 0 |
| `docs/LOG/SESSION_PLAN_GitHub_CI_RepoSafeguards_2026-04-04.md` | Log | 0 |

### Updated Files (4)

| File | Change | Phase |
|------|--------|-------|
| `.github/workflows/ci.yml` | Add workflow_dispatch + artifact upload | 1 |
| `.githooks/pre-commit` | Add secret detection + env guard | 3 |
| `Sline_everything/MVP_ROADMAP.md` | Fix coverage threshold + Phase D progress | 4 |
| `Sline_everything/ARCHITECTURE_ANALYSIS.md` | Fix date typo | 4 |

### Deleted Files

None.

---

## 9) Implementation Roadmap

### Phase 1: Immediate (Day 1)

| # | Task | Impact | Effort | Owner | Why Now |
|---|------|--------|--------|-------|---------|
| 1 | Create `scripts/check-secrets.sh` | HIGH | LOW | Agent | Dependency for hook + CI |
| 2 | Update `.githooks/pre-commit` with secret detection | HIGH | LOW | Agent | Every commit without this is a risk |
| 3 | Create `.github/workflows/secret-scan.yml` | HIGH | LOW | Agent | Automated safety net |
| 4 | Create `.github/workflows/dependency-review.yml` | HIGH | LOW | Agent | Supply chain protection |
| 5 | Create `.github/pull_request_template.md` | MEDIUM | LOW | Agent | Immediate review quality boost |
| 6 | Configure branch protection on `main` | CRITICAL | LOW | Manual | Core merge safety |
| 7 | Enable GitHub secret scanning + push protection | CRITICAL | LOW | Manual | Native secret protection |

### Phase 2: Short Term (Day 2-3)

| # | Task | Impact | Effort | Owner | Why Now |
|---|------|--------|--------|-------|---------|
| 8 | Create `.github/dependabot.yml` | MEDIUM | LOW | Agent | Automated dependency freshness |
| 9 | Create `.github/CODEOWNERS` | MEDIUM | LOW | Agent | Review routing |
| 10 | Update `ci.yml` (workflow_dispatch + artifacts) | LOW | LOW | Agent | CI convenience |
| 11 | Create `SECURITY.md` | MEDIUM | LOW | Agent | Responsible disclosure |
| 12 | Create `supabase/functions/.env.example` | MEDIUM | LOW | Agent | Onboarding + documentation |
| 13 | Enable Dependabot alerts in GitHub settings | MEDIUM | LOW | Manual | Complement config file |
| 14 | Add new workflows as required status checks | HIGH | LOW | Manual | New checks must block |
| 15 | Create GitHub labels | LOW | LOW | Manual | Dependabot references them |

### Phase 3: Advanced (Week 2+)

| # | Task | Impact | Effort | Owner | Why Now |
|---|------|--------|--------|-------|---------|
| 16 | Create issue templates (bug + feature) | LOW | LOW | Agent | Structured reporting |
| 17 | Create `CONTRIBUTING.md` | LOW | LOW | Agent | Onboarding |
| 18 | Fix doc drift (MVP_ROADMAP, ARCHITECTURE_ANALYSIS) | LOW | LOW | Agent | Accuracy |
| 19 | iOS build job (macos runner) | HIGH | MEDIUM | Agent + Manual | Platform coverage |
| 20 | Raise coverage floor to 35% | MEDIUM | LOW | Agent | After Phase D tests |
| 21 | Release workflow (tag-based) | MEDIUM | HIGH | Agent + Manual | When release process exists |
| 22 | Edge Function Deno lint workflow | MEDIUM | MEDIUM | Agent | TypeScript quality |
| 23 | Custom Dart lint rules (replace grep) | MEDIUM | HIGH | Agent | Replace brittle arch guard |

---

## 10) Final Missing Ideas / Blind Spots

### 10.1 APK Signing for CI

The APK build uses `--debug` because release builds require a signing keystore. When ready for production:
- Store keystore as GitHub Actions secret (base64-encoded)
- Add release build job with signing configuration
- Keep debug build as compilation check; add release build for artifact generation

### 10.2 Web Preview Deployments

When the team starts reviewing PRs with UI changes, consider adding:
- Vercel/Netlify/Firebase Hosting preview deploys on PRs
- Gives reviewers a live URL to test UI changes
- Low effort with existing web build; high review quality boost

### 10.3 Scheduled Security Audit

Consider a weekly scheduled workflow that:
- Runs `flutter pub outdated` and posts results
- Checks for new Dart security advisories
- Low priority but useful for proactive maintenance

### 10.4 Test Stability Tracking

The CI does not track flaky tests. If a test passes intermittently:
- Consider adding `--reporter=json` to `flutter test` and parsing for flaky patterns
- Or use `--retry` flag with failure reporting
- Low priority now (0 flaky tests reported) but valuable as test suite grows

### 10.5 Commit Message Linting

Currently no commit message convention is enforced. Options:
- Add `commitlint` (overkill for a small team)
- Add a CI check for conventional commit prefix (feat/fix/chore/refactor)
- Low priority — existing commit messages are already descriptive

### 10.6 PR Size Warning

Large PRs (>500 lines changed) are harder to review and more likely to introduce bugs. Consider:
- A CI step that warns (not blocks) on PRs > 500 lines
- Encourages smaller, focused PRs
- Low priority but improves review quality

### 10.7 License Compliance

No license checking is configured. The project uses MIT, BSD, and Apache dependencies (safe), but:
- `dependency-review-action` with `allow-licenses` covers this partially
- Full compliance audit is low priority for an internal app

### 10.8 Backup Strategy Documentation

No documentation exists for:
- Supabase database backup strategy
- Point-in-time recovery procedures
- Disaster recovery runbook
- This should exist before production but is outside CI scope

### 10.9 Monitoring and Alerting

Phase D adds Sentry crash reporting (D1, complete), but:
- No uptime monitoring documented
- No database performance alerting
- No Edge Function error rate alerting
- These are operational concerns, not CI, but should be on the roadmap

### 10.10 Pre-Push Hook

Currently only a pre-commit hook exists. Consider adding a pre-push hook that:
- Runs `flutter test` (catches test failures before push, not just at CI time)
- Optional because it's slow (~30s+ for full test suite)
- Could be a `scripts/pre-push-test.sh` that developers opt into

---

## 11) Rollback Plan

- **Workflow files:** Can be reverted with `git revert` — no external state changed
- **Pre-commit hook:** Can be reverted; developers may need `git config core.hooksPath .githooks` again
- **Branch protection:** Can be disabled in GitHub settings immediately
- **Dependabot:** Can be disabled by deleting config file or disabling in GitHub settings
- **CODEOWNERS:** Can be deleted; branch protection "require code owner review" should be unchecked first
- **Secret scanning:** Can be disabled in GitHub settings
- **Documentation files:** Can be reverted; no external dependencies

All changes in this plan are independently reversible with no cascading effects.

---

## 12) References (From Scan)

### Docs Scanned
- `CLAUDE.md` — architecture rules, CI description
- `Sline_everything/MVP_ROADMAP.md` — Phase D coverage threshold claim
- `Sline_everything/ARCHITECTURE_ANALYSIS.md` — date typo
- `Sline_everything/STRUCTURE.md` — file organization
- `Sline_everything/DEVELOPER_GUIDE.md` — feature documentation
- `Sline_everything/CODE_REVIEW.md` — guardrails
- `Sline_everything/Sline_Log.md` — phase history
- `.TODO/PLAN_PhaseD_Harden_2026-04-03.md` — Phase D overlap check
- `MIGRATION_REVIEW_CHECKLIST.md` — existing migration checklist

### Code Paths Scanned
- `.github/workflows/ci.yml` — complete read
- `.githooks/pre-commit` — complete read
- `analysis_options.yaml` — complete read
- `lib/core/services/supabase_config.dart` — credential check
- `supabase/functions/_shared/bookin_payment.ts` — CORS headers
- `supabase/functions/` — Edge Function inventory (12 functions)
- `supabase/migrations/` — 8 active + 131 archived
- `.gitignore` — coverage verification

### Confirmed Non-Existent
- `.github/pull_request_template.md`
- `.github/ISSUE_TEMPLATE/`
- `.github/CODEOWNERS`
- `.github/dependabot.yml`
- `SECURITY.md`
- `CONTRIBUTING.md`
- `CHANGELOG.md`
- `dart_test.yaml`
- `supabase/functions/.env.example`
- `scripts/`

---

END.
