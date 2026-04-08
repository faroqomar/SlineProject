# Plan: Agent-Side CI & Repository Safeguards Implementation

**Plan Version:** 2.0 (Post-Critique)
**Date:** 2026-04-06
**Created By:** @SlinePlanner, reviewed by @PlanCritic
**Session Log:** `docs/LOG/SESSION_PLAN_Agent_CI_RepoSafeguards_2026-04-06.md`
**Parent Plan:** `.TODO/PLAN_GitHub_CI_RepoSafeguards_2026-04-04.md`
**Manual Counterpart:** `.TODO/Future_Plans/MANUAL_GitHub_Setup_Checklist.md`
**Critique:** `.TODO/PLAN_CRITIQUE_2026-04-06_Agent_CI_RepoSafeguards.md`

---

## 1) Goal

- **Goal:** Implement all agent-side (in-repository) CI workflows, developer tooling, and documentation files from the GitHub/CI/Repo Safeguards master plan.
- **Why:** The core CI pipeline (lint, 7 architecture guard checks, 1229 tests, 40% coverage floor, APK+web build) is solid, but the surrounding infrastructure is missing: secret scanning, dependency review, PR templates, CODEOWNERS, contributor docs, Edge Function env documentation, and pre-commit secret guards. This creates risk for a financial marketplace app.
- **Result:** 12 new files created + 3 existing files updated. Every PR is automatically validated for secret leaks and dependency vulnerabilities. Developers have structured PR/issue templates, code ownership routing, and local secret-detection hooks. Documentation drift is fixed.

---

## 2) Scope

### In-Scope (Agent-Implementable Only)

| ID | Item | File | Action |
|----|------|------|--------|
| A1 | Secret check script | `scripts/check-secrets.sh` | CREATE |
| A2 | Enhanced pre-commit hook | `.githooks/pre-commit` | UPDATE |
| A3 | Secret scanning workflow | `.github/workflows/secret-scan.yml` | CREATE |
| A4 | PR template | `.github/pull_request_template.md` | CREATE |
| A5 | Dependency review workflow | `.github/workflows/dependency-review.yml` | CREATE |
| A6 | Dependabot configuration | `.github/dependabot.yml` | CREATE |
| A7 | CODEOWNERS | `.github/CODEOWNERS` | CREATE |
| A8 | CI workflow enhancements | `.github/workflows/ci.yml` | UPDATE |
| A9 | SECURITY.md | `SECURITY.md` | CREATE |
| A10 | Edge Function env docs | `supabase/functions/.env.example` | CREATE |
| A11 | Bug report issue template | `.github/ISSUE_TEMPLATE/bug_report.yml` | CREATE |
| A12 | Feature request issue template | `.github/ISSUE_TEMPLATE/feature_request.yml` | CREATE |
| A13 | CONTRIBUTING.md | `CONTRIBUTING.md` | CREATE |
| A14 | MVP_ROADMAP drift fix | `Sline_everything/MVP_ROADMAP.md` | UPDATE |
| A15 | ARCHITECTURE_ANALYSIS date fix | `Sline_everything/ARCHITECTURE_ANALYSIS.md` | UPDATE |

### Out-of-Scope

- Manual GitHub configuration (branch protection, secret scanning toggle, Dependabot alerts, labels) — see `MANUAL_GitHub_Setup_Checklist.md`
- iOS build job (requires macOS runner)
- Release/deploy workflow (no release process yet)
- Flutter code changes, schema changes, or test writing
- Custom Dart lint rules (`custom_lint` package — future)

---

## 3) Evidence & Findings (From Scan)

### Existing

| Asset | Status | Line Count | Notes |
|-------|--------|------------|-------|
| `.github/workflows/ci.yml` | Active | 175 lines | 4 jobs: lint, arch guard (7 checks), test (40% floor), build |
| `.github/PULL_REQUEST_TEMPLATE/migration.md` | Active | 43 lines | 7-section migration checklist |
| `.githooks/pre-commit` | Active | 21 lines | format + analyze only |
| `MIGRATION_REVIEW_CHECKLIST.md` | Active | root | 7-point checklist, referenced in PR template migration.md |
| `analysis_options.yaml` | Active | ~46 lines | `very_good_analysis` + 5 SLine rules, 21 disabled |
| `CLAUDE.md` | Active | root | Architecture rules, CI description, conventions |
| Test suite | Active | ~1229 tests | 150 test files, 40% coverage floor, 0 failures |

### Missing (To Be Created By This Plan)

| Asset | Risk | Notes |
|-------|------|-------|
| `scripts/` directory | MEDIUM | No reusable CI/local scripts exist |
| Secret scanning (CI or hook) | HIGH | No detection of accidentally committed secrets |
| `.github/pull_request_template.md` | MEDIUM | No general PR template (only migration-specific exists) |
| `.github/ISSUE_TEMPLATE/` directory | LOW | No structured issue templates |
| `.github/CODEOWNERS` | MEDIUM | No automatic reviewer assignment |
| `.github/dependabot.yml` | MEDIUM | No automated dependency updates |
| `.github/workflows/secret-scan.yml` | HIGH | No secret leak detection in CI |
| `.github/workflows/dependency-review.yml` | MEDIUM | No vulnerability scanning on PRs |
| `SECURITY.md` | MEDIUM | No responsible disclosure process |
| `CONTRIBUTING.md` | LOW | CLAUDE.md covers conventions but not contributor-facing |
| `supabase/functions/.env.example` | MEDIUM | 18 env vars undocumented |
| `workflow_dispatch` trigger on CI | LOW | Cannot manually trigger CI |
| Build artifact uploads | LOW | Cannot download build outputs from CI |

### Must NOT Duplicate

- Coverage floor logic (already in `ci.yml` lines 131-149)
- Architecture guard checks (already in `ci.yml` lines 36-100)
- Pre-commit format + analyze (already in `.githooks/pre-commit` lines 3-19)
- Migration review checklist content (already at `MIGRATION_REVIEW_CHECKLIST.md` — PR template must REFERENCE, not copy)

### Conflicts / Risks

| Conflict | Source A | Source B | Resolution |
|----------|---------|---------|------------|
| Coverage target in MVP_ROADMAP | MVP_ROADMAP says "70% target" | CI enforces 40% floor | Fix roadmap to say "40% floor" |
| ARCHITECTURE_ANALYSIS date | Header says "March 7, 2024" | Content is from 2026 | Fix to "2026-03-07" |
| Arch guard count in MVP_ROADMAP | Line 92 says "6 MVVM checks" | CI has 7 checks (Check 7 added Phase E) | Fix to "7" |
| TruffleHog false positive | Supabase anon key in `supabase_config.dart` | TruffleHog `--only-verified` flag | Flag filters unverified; anon key is public by design |
| CODEOWNERS effectiveness | File can be created in repo | Only works when branch protection requires code owner review | Note dependency on manual step B1 |
| Edge Function env vars | Parent plan lists 14 vars | Scan found 18 unique `Deno.env.get()` calls | Use scan result (18 vars) |

---

## 4) System Impact Map

- **UI:** None
- **MVVM / App Logic:** None
- **Database:** None
- **RLS / Security:** Secret scanning prevents credential leaks; SECURITY.md documents disclosure process
- **RPC / Edge Functions:** `.env.example` documents 18 required env vars
- **Storage:** None
- **Realtime / Notifications:** None
- **Observability:** None
- **Compatibility & Migration:** PR template references migration checklist
- **Contracts:** None
- **Developer Workflow:** PR template, issue templates, CODEOWNERS, enhanced hooks, scripts
- **CI/CD Pipeline:** Secret scan workflow, dependency review workflow, Dependabot config, CI enhancements
- **Documentation:** SECURITY.md, CONTRIBUTING.md, .env.example, MVP_ROADMAP drift fix, ARCHITECTURE_ANALYSIS date fix

---

## 5) Agent Map

- Phase 0: @SlinePlanner, @Sentinel (preconditions & gates)
- Phase 1: @CodeGuard, @Sentinel (secret scanning infrastructure)
- Phase 2: @CodeGuard, @Sentinel (CI workflow enhancements)
- Phase 3: @Architect, @Sentinel (developer workflow files)
- Phase 4: @SlineDocs, @Sentinel (documentation & drift fixes)
- Phase 5: @Sentinel (verification & non-regression)

---

## Phase 0: Preconditions & Gates

**Primary Agent(s):** @SlinePlanner, @Sentinel

### 0.1 Spec Lock

**Primary Agent(s):** @SlinePlanner, @Sentinel
**Goal:** Lock acceptance criteria and non-regression expectations
**Why:** Any regression in CI blocks all development
**How:** Define measurable acceptance and non-regression checks
**Result:** Clear pass/fail criteria for every phase

- [ ] (@Sentinel) Define acceptance criteria:
  - All new YAML workflow files are syntactically valid
  - All new repo files follow project conventions (English, no hardcoded secrets)
  - Pre-commit hook enhancements do not break existing developer workflow (format + analyze preserved)
  - No existing CI checks are weakened, removed, or renamed
  - All manual configuration dependencies are documented
  - Secret patterns must NOT match Supabase anon key (it is public by design)
- [ ] (@SlinePlanner) Define non-regression list:
  - `flutter test` must still pass (~1229 tests, 0 failures)
  - `flutter analyze` must still pass (0 issues)
  - `dart format --set-exit-if-changed .` must pass
  - Architecture guard (7 checks) must still pass with 0 violations
  - Coverage floor (40%) must still be enforced
  - Pre-commit hook (format + analyze) must still work unchanged
  - `.github/PULL_REQUEST_TEMPLATE/migration.md` must remain intact
- [ ] (@SlinePlanner) **[ADDED — Critique Fix 4] Blocking Input: GitHub username** — Ask the developer for their exact GitHub username. Required for CODEOWNERS. Do NOT use a placeholder.
- [ ] (@SlinePlanner) **[ADDED — Critique Fix 4] Blocking Input: Security contact email** — Ask the developer for the email to use in SECURITY.md. Do NOT use a placeholder.
- [ ] (@CodeGuard) **[ADDED — Critique Fix 5] TruffleHog version freshness check** — Run `gh api repos/trufflesecurity/trufflehog/releases/latest --jq .tag_name` and record the current release tag. If newer than `v3.88.0`, use the newer version in Phase 1.3.
- **GATE CHECK:** Scope, acceptance criteria, non-regression list, blocking inputs, and version checks are complete.

---

## Phase 1: Secret Scanning Infrastructure (@CodeGuard)

**Primary Agent(s):** @CodeGuard, @Sentinel
**Goal:** Create the secret detection script, update the pre-commit hook, and add the CI secret scanning workflow
**Why:** No secret scanning exists anywhere — one mistake away from permanent credential exposure in a payment app
**How:** Build the reusable script first, then wire it into the hook, then add CI workflow as automated safety net
**Result:** Three-layer secret defense: local script, pre-commit hook, CI workflow

### 1.1 Create Secret Check Script

**Primary Agent(s):** @CodeGuard, @Sentinel
**Goal:** Create a reusable shell script for secret pattern detection
**Why:** Shared between pre-commit hook and manual developer checks; single source of truth for patterns
**How:** Write a shell script that scans text input for dangerous patterns
**Result:** Executable script at `scripts/check-secrets.sh`

- [ ] (@CodeGuard) Create directory `scripts/` if it does not exist
- [ ] (@CodeGuard) Create `scripts/check-secrets.sh` with the following behavior:
  - Accept input via stdin or file arguments
  - Scan for patterns: `sk_live_`, `sk_test_`, `service_role`, `SUPABASE_SERVICE_ROLE_KEY\s*=\s*ey`, `password\s*[:=]\s*['"][^\s]{8,}`, `-----BEGIN.*PRIVATE KEY-----`, `ghp_[A-Za-z0-9_]{36}`, `gho_[A-Za-z0-9_]{36}`
  - Exclude `.md` files from scan (docs may reference pattern names)
  - Exit 0 if clean, exit 1 if secrets detected, print offending lines to stderr
- [ ] (@CodeGuard) Make script executable: `chmod +x scripts/check-secrets.sh`
- [ ] (@Sentinel) Verify script can run standalone: `echo "sk_live_test123" | bash scripts/check-secrets.sh` returns exit 1
- [ ] (@Sentinel) Verify script does NOT flag Supabase anon key pattern (anon keys start with `eyJ`, but are public)
- [ ] (@Sentinel) Verify script does NOT flag `.md` files that mention pattern names in documentation
- **GATE CHECK:** Script is executable, detects real patterns, rejects false positives on anon keys and docs.

### 1.2 Update Pre-Commit Hook

**Primary Agent(s):** @CodeGuard, @Sentinel
**Goal:** Add secret detection and env file guard to the pre-commit hook
**Why:** Last line of defense before secrets enter git history
**How:** Prepend new checks before existing format + analyze steps; preserve existing behavior exactly
**Result:** Enhanced hook with 4 checks: env file guard, secret scan, format, analyze

**File:** `.githooks/pre-commit` (UPDATE — currently 21 lines)

- [ ] (@CodeGuard) Add env file staging guard as the FIRST check:
  - Scan `git diff --cached --name-only` for `.env`, `.env.*`, `secrets.json`, `credentials.json`
  - **[EXPANDED — Critique Fix 3] CRITICAL: Exclude `.env.example`** — pattern must match `.env` exactly and `.env.*` variants but NOT `.env.example`. Use grep with negative lookahead or explicit exclusion: `grep -E '(^|/)\.env$|(^|/)\.env\.[^e]|(^|/)\.env\.e[^x]|(^|/)secrets\.json|(^|/)credentials\.json'` or equivalent logic that skips `.env.example`.
  - If blocked files found: print warning, list files, exit 1
- [ ] (@CodeGuard) Add secret pattern scan as the SECOND check:
  - Run `git diff --cached --diff-filter=ACM` through `scripts/check-secrets.sh`
  - If secrets detected: print warning with file names and line numbers, exit 1
- [ ] (@CodeGuard) Preserve existing format check (lines 3-9) UNCHANGED as the THIRD check
- [ ] (@CodeGuard) Preserve existing analyze check (lines 11-19) UNCHANGED as the FOURTH check
- [ ] (@Sentinel) Verify existing format + analyze behavior is IDENTICAL to before (run a test commit)
- [ ] (@Sentinel) Verify hook overhead is < 2 seconds for a normal commit (secret scan + env guard only)
- [ ] (@Sentinel) Verify hook blocks a commit containing `sk_live_testkey123` in a `.dart` file
- [ ] (@Sentinel) Verify hook allows a commit with only clean `.dart` changes
- [ ] (@Sentinel) **[ADDED — Critique Fix 3] Verify hook ALLOWS staging `.env.example`** — create a test `.env.example`, stage it, run hook, confirm it passes. Critical because Phase 4.2 creates `supabase/functions/.env.example` which must be committable.
- [ ] (@Sentinel) **[ADDED — Critique Fix 3] Verify hook BLOCKS `.env.local`** — confirm env guard catches `.env.local` but not `.env.example`.
- **GATE CHECK:** Hook has 4 checks in order (env guard, secret scan, format, analyze). `.env.example` passes. `.env` and `.env.local` blocked. Existing behavior unchanged.

### 1.3 Create Secret Scanning CI Workflow

**Primary Agent(s):** @CodeGuard, @Sentinel
**Goal:** Add TruffleHog v3 secret scanning as a CI workflow
**Why:** Automated safety net — catches secrets that slip past local hooks
**How:** Create a new workflow file using `trufflesecurity/trufflehog` GitHub Action
**Result:** New workflow at `.github/workflows/secret-scan.yml`

- [ ] (@CodeGuard) Create `.github/workflows/secret-scan.yml` with:
  - Name: `Secret Scan`
  - Triggers: `push` (all branches) and `pull_request`
  - Permissions: `contents: read`
  - Job name: `trufflehog` with display name `TruffleHog Secret Scan`
  - Steps: checkout with `fetch-depth: 0` + TruffleHog action (use version from Phase 0 freshness check, default `v3.88.0`) with `extra_args: --only-verified`
  - **[ADDED — Critique Fix 6] Concurrency block:** `concurrency: { group: secret-scan-${{ github.ref }}, cancel-in-progress: true }` — prevents duplicate runs on rapid pushes
- [ ] (@Sentinel) Verify the job display name is exactly `TruffleHog Secret Scan` (this exact string is used when adding it as a required status check in GitHub branch protection)
- [ ] (@Sentinel) Verify `--only-verified` flag is present (prevents false positives from patterns that look like secrets but aren't active)
- [ ] (@Sentinel) Verify `fetch-depth: 0` is set (TruffleHog needs full git history for deep scans)
- [ ] (@Sentinel) Verify concurrency block is present
- [ ] (@Sentinel) Verify workflow does NOT duplicate any steps from `ci.yml`
- [ ] (@Sentinel) **[ADDED — Critique Fix 2] Inline YAML validation:** Run `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/secret-scan.yml'))"` — must pass. Do NOT proceed to Phase 2 if this fails.
- **GATE CHECK:** Workflow file created, YAML valid, concurrency set, job name matches branch protection expectation.

---

## Phase 2: CI Workflow Enhancements (@CodeGuard)

**Primary Agent(s):** @CodeGuard, @Sentinel
**Goal:** Add dependency review workflow, Dependabot config, and improve existing CI workflow
**Why:** Supply chain protection and CI convenience features
**How:** Create new workflow files and update existing `ci.yml`
**Result:** Dependency vulnerabilities caught on PRs, automated dependency updates, manual CI trigger, build artifacts downloadable

### 2.1 Create Dependency Review Workflow

**Primary Agent(s):** @CodeGuard, @Sentinel
**Goal:** Add automated dependency vulnerability scanning on PRs
**Why:** Supply chain risk is real for apps with payment flows
**How:** Create a new workflow using `actions/dependency-review-action`
**Result:** New workflow at `.github/workflows/dependency-review.yml`

- [ ] (@CodeGuard) Create `.github/workflows/dependency-review.yml` with:
  - Name: `Dependency Review`
  - Triggers: `pull_request` to `main` only
  - Permissions: `contents: read`
  - Job name: `review` with display name `Dependency Vulnerability Check`
  - Steps: checkout + `actions/dependency-review-action@v4` with `fail-on-severity: high` and `allow-licenses: MIT, BSD-2-Clause, BSD-3-Clause, Apache-2.0, ISC, Zlib`
  - **[ADDED — Critique Fix 6] Concurrency block:** `concurrency: { group: dep-review-${{ github.ref }}, cancel-in-progress: true }`
  - **[ADDED — Critique Fix 1] YAML comment at top of file:**
    ```
    # NOTE: dependency-review-action does not scan pub/Dart dependencies.
    # Pub dep vulnerabilities are covered by Dependabot alerts (GitHub Settings > Code Security).
    # This workflow scans GitHub Actions dependencies and license compliance.
    ```
- [ ] (@Sentinel) Verify job display name is exactly `Dependency Vulnerability Check` (used in branch protection)
- [ ] (@Sentinel) Verify `fail-on-severity: high` blocks only high/critical (moderate/low are warnings)
- [ ] (@Sentinel) Verify workflow ONLY triggers on `pull_request` (not push — dependency review is PR-scoped)
- [ ] (@Sentinel) Verify limitation comments are present in the YAML
- [ ] (@Sentinel) Verify concurrency block is present
- [ ] (@Sentinel) **[ADDED — Critique Fix 2] Inline YAML validation:** `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/dependency-review.yml'))"` — must pass.
- **GATE CHECK:** Workflow created, limitation documented, concurrency set, no false confidence in pub dep scanning.

### 2.2 Create Dependabot Configuration

**Primary Agent(s):** @CodeGuard, @Sentinel
**Goal:** Enable automated dependency update PRs
**Why:** Stale dependencies accumulate vulnerabilities silently
**How:** Create `dependabot.yml` config file
**Result:** Weekly automated PRs for pub and github-actions dependency updates

- [ ] (@CodeGuard) Create `.github/dependabot.yml` with:
  - `version: 2`
  - Pub ecosystem: weekly on Monday, 5 PR limit, labels `dependencies` + `automated`
  - GitHub Actions ecosystem: weekly on Monday, 3 PR limit, labels `ci` + `automated`
- [ ] (@Sentinel) Verify YAML syntax is valid
- [ ] (@Sentinel) **[ADDED — Critique Fix 2] Inline YAML validation:** `python3 -c "import yaml; yaml.safe_load(open('.github/dependabot.yml'))"` — must pass.
- [ ] (@Sentinel) Verify PR limits prevent flood (5 for pub, 3 for actions)
- [ ] (@Sentinel) Note: labels must be created manually on GitHub with EXACT names (`dependencies`, `automated`, `ci`) — see `MANUAL_GitHub_Setup_Checklist.md`
- [ ] (@Sentinel) Note: Dependabot alerts must be enabled manually in GitHub settings (documented in `MANUAL_GitHub_Setup_Checklist.md`)
- **GATE CHECK:** Config file valid, PR limits reasonable, manual dependencies documented.

### 2.3 Enhance Existing CI Workflow

**Primary Agent(s):** @CodeGuard, @Sentinel
**Goal:** Add `workflow_dispatch` trigger and build artifact uploads to existing `ci.yml`
**Why:** Manual trigger enables debugging failed pipelines; artifacts enable inspection of builds
**How:** Add trigger and upload steps to existing file without changing any existing logic
**Result:** Enhanced `ci.yml` with manual trigger and downloadable artifacts

**File:** `.github/workflows/ci.yml` (UPDATE — currently 175 lines)

- [ ] (@CodeGuard) Add `workflow_dispatch: {}` to the `on:` block (after `pull_request:` line)
- [ ] (@CodeGuard) Add `actions/upload-artifact@v4` step after each build step in the matrix job:
  - For APK: upload `build/app/outputs/flutter-apk/` with name `apk-debug` (verified: `flutter-apk/` directory exists in Flutter build output)
  - For web: upload `build/web/` with name `web-release`
  - Set `retention-days: 7` to limit storage
  - **[ADDED — Critique Fix 7] Add `if: always()` to both upload steps** — failed builds are the primary use case for artifact inspection
- [ ] (@Sentinel) Verify existing `on:` triggers (`push`, `pull_request`) are UNCHANGED
- [ ] (@Sentinel) Verify existing job names (`analyze`, `architecture-guard`, `test`, `build`) are UNCHANGED
- [ ] (@Sentinel) Verify coverage threshold value (`40`) is UNCHANGED
- [ ] (@Sentinel) Verify APK build mode (`--debug`) is UNCHANGED (release requires signing keys)
- [ ] (@Sentinel) Verify no existing steps are reordered, renamed, or removed
- [ ] (@Sentinel) **[ADDED] Diff check:** Run `git diff .github/workflows/ci.yml` and confirm ONLY additive changes (new lines, no modified existing lines except within the `on:` block)
- **GATE CHECK:** CI workflow enhanced without breaking any existing check. Artifacts upload even on failure. All existing job names preserved.

---

## Phase 3: Developer Workflow Files (@Architect)

**Primary Agent(s):** @Architect, @Sentinel
**Goal:** Add PR template, issue templates, and CODEOWNERS
**Why:** Structured review process and ownership routing for critical code paths
**How:** Create template and config files in `.github/`
**Result:** Every PR has a checklist, every code area has an owner, structured issue reporting

### 3.1 Create PR Template

**Primary Agent(s):** @Architect, @Sentinel
**Goal:** Create a general-purpose PR template with conditional checklists
**Why:** Immediate improvement to review quality and safety for every PR
**How:** Create markdown template at `.github/pull_request_template.md`
**Result:** All PRs show a structured checklist; migration/payment/Supabase sections are conditional

- [ ] (@Architect) Create `.github/pull_request_template.md` with sections:
  - **What changed** — brief description field
  - **Why** — motivation / ticket link field
  - **General checklist:**
    - [ ] Tests pass (`flutter test`)
    - [ ] Analysis clean (`flutter analyze`)
    - [ ] Architecture guard passes
    - [ ] No hardcoded colors (`Color(0xFF...)`) — use `AppColors.*`
    - [ ] No `print()` or `debugPrint()` — use `AppLogger`
    - [ ] No hardcoded secrets
  - **If payment/wallet/booking is touched:**
    - [ ] Edge cases tested (zero amount, negative, overflow)
    - [ ] RLS policies verified for owner/participant/other
    - [ ] No PII in logs
    - [ ] Escrow state transitions are server-side
  - **If migration files are included:**
    - [ ] See `MIGRATION_REVIEW_CHECKLIST.md` for full checklist
  - **If Supabase/Edge Functions are touched:**
    - [ ] CORS headers present (`ALLOWED_ORIGIN`)
    - [ ] Auth verification in place
    - [ ] No `service_role` key in client code
    - [ ] `.env.example` updated if new env vars added
- [ ] (@Sentinel) Verify template REFERENCES `MIGRATION_REVIEW_CHECKLIST.md` rather than duplicating its content
- [ ] (@Sentinel) Verify template does NOT conflict with existing `migration.md` in `PULL_REQUEST_TEMPLATE/`
- [ ] (@Sentinel) Verify template is concise (developers skip long templates — aim for < 40 lines)
- **GATE CHECK:** PR template created, references existing docs, does not duplicate.

### 3.2 Create Issue Templates

**Primary Agent(s):** @Architect, @Sentinel
**Goal:** Add structured bug report and feature request templates
**Why:** Structured reports help prioritize work and capture reproduction steps
**How:** Create YAML-based issue templates in `.github/ISSUE_TEMPLATE/`
**Result:** GitHub shows structured forms when creating issues

- [ ] (@Architect) Create `.github/ISSUE_TEMPLATE/` directory
- [ ] (@Architect) Create `.github/ISSUE_TEMPLATE/bug_report.yml` with fields:
  - `name: Bug Report`
  - `description: Report a bug or unexpected behavior`
  - Body fields: description (required), reproduction steps (required), expected vs actual (required), environment (dropdown: Android/iOS/Web), screenshots (optional)
- [ ] (@Architect) Create `.github/ISSUE_TEMPLATE/feature_request.yml` with fields:
  - `name: Feature Request`
  - `description: Suggest a new feature or improvement`
  - Body fields: problem description (required), proposed solution (required), alternatives considered (optional), additional context (optional)
- [ ] (@Sentinel) Verify both templates use YAML format (not markdown) for structured fields
- [ ] (@Sentinel) **[ADDED — Critique Fix 2] Inline YAML validation** for both templates:
  - `python3 -c "import yaml; yaml.safe_load(open('.github/ISSUE_TEMPLATE/bug_report.yml'))"`
  - `python3 -c "import yaml; yaml.safe_load(open('.github/ISSUE_TEMPLATE/feature_request.yml'))"`
- [ ] (@Sentinel) Verify templates are useful but not bureaucratic (< 10 fields each)
- [ ] (@Sentinel) Verify templates do NOT conflict with existing migration template in `PULL_REQUEST_TEMPLATE/`
- **GATE CHECK:** Issue templates created, YAML validated inline, structured but concise.

### 3.3 Create CODEOWNERS

**Primary Agent(s):** @Architect, @Sentinel
**Goal:** Define code ownership for critical paths
**Why:** Payment, auth, Supabase, and core infrastructure need domain expert review
**How:** Create CODEOWNERS file mapping directories to GitHub usernames
**Result:** GitHub auto-requests reviews from domain owners

- [ ] (@Architect) Create `.github/CODEOWNERS` using the **real GitHub username collected in Phase 0** (NOT a placeholder):
  - `*` -> `@<real-github-username>` (default owner for all files)
  - `lib/features/wallet/` -> `@<real-github-username>` (wallet/payment owner)
  - `lib/features/booking/` -> `@<real-github-username>` (booking owner)
  - `supabase/` -> `@<real-github-username>` (backend owner)
  - `.github/` -> `@<real-github-username>` (CI owner)
  - `lib/core/` -> `@<real-github-username>` (core infrastructure owner)
  - NOTE: All paths currently point to the same owner (solo developer). When team grows, split ownership.
- [ ] (@Sentinel) **[CHANGED — Critique Fix 4] Verify CODEOWNERS uses a REAL GitHub username, NOT a placeholder** like `<project-lead-github-username>`
- [ ] (@Sentinel) Verify CODEOWNERS syntax is valid (GitHub format: `path @owner`)
- [ ] (@Sentinel) Document that CODEOWNERS only works when branch protection "Require review from Code Owners" is enabled (manual step B1)
- **GATE CHECK:** CODEOWNERS created with real username, syntax valid, dependency on manual config documented.

---

## Phase 4: Documentation & Drift Fixes (@SlineDocs)

**Primary Agent(s):** @SlineDocs, @Sentinel
**Goal:** Create missing repo documentation and fix documentation drift
**Why:** Financial app needs SECURITY.md; 18 Edge Function env vars are undocumented; stale docs cause confusion
**How:** Create new documentation files and update stale sections
**Result:** Responsible disclosure process, contributor guide, env var documentation, accurate docs

### 4.1 Create SECURITY.md

**Primary Agent(s):** @SlineDocs, @Sentinel
**Goal:** Document responsible disclosure process
**Why:** Financial marketplace must have a security reporting channel
**How:** Create root-level SECURITY.md with clear reporting instructions
**Result:** Security researchers and users know how to report vulnerabilities

- [ ] (@SlineDocs) Create `SECURITY.md` using the **real security contact email collected in Phase 0** (NOT a placeholder):
  - **Reporting a Vulnerability** — use the real email from Phase 0 blocking input
  - **What to Report** — authentication bypass, data exposure, RLS circumvention, payment manipulation, unauthorized access
  - **What NOT to Report** — Supabase anon key (public by design, protected by RLS), known cosmetic issues
  - **Security Architecture** — brief: RLS on all tables, server-side payment processing, signed URLs for storage, auth-gated Edge Functions
  - **Response Timeline** — acknowledge within 48h, triage within 7 days
- [ ] (@Sentinel) Verify NO internal infrastructure details are exposed (no URLs, no IPs, no internal service names)
- [ ] (@Sentinel) Verify NO actual secrets or credentials appear in the file
- [ ] (@Sentinel) **[CHANGED — Critique Fix 4] Verify email contact is a REAL email, NOT a placeholder**
- **GATE CHECK:** SECURITY.md created with real contact email, no sensitive information exposed.

### 4.2 Create Edge Function Environment Documentation

**Primary Agent(s):** @SlineDocs, @Sentinel
**Goal:** Document all 18 Edge Function environment variables
**Why:** Undocumented env vars cause onboarding friction and deployment failures
**How:** Create `.env.example` with placeholder values and comments
**Result:** Developers know exactly which env vars to configure

**File:** `supabase/functions/.env.example` (NEW)

**Scan found these 18 unique `Deno.env.get()` calls across all Edge Functions:**

- [ ] (@SlineDocs) Create `supabase/functions/.env.example` with ALL 18 variables:
  - `# --- Supabase Core (auto-injected in hosted, manual in local) ---`
  - `SUPABASE_URL=https://your-project.supabase.co`
  - `SUPABASE_ANON_KEY=your-anon-key`
  - `SUPABASE_SERVICE_ROLE_KEY=your-service-role-key`
  - `# --- QiCard Payment Gateway (required for payment flows) ---`
  - `QICARD_API_BASE_URL=https://api.qicard.com`
  - `QICARD_TERMINAL_ID=your-terminal-id`
  - `QICARD_USERNAME=your-username`
  - `QICARD_PASSWORD=your-password`
  - `QICARD_RSA_PUBLIC_KEY_PEM=your-rsa-public-key-pem`
  - `QICARD_FINISH_URL=https://your-app.com/payment/finish`
  - `QICARD_PROVIDER_NAME=QiCard`
  - `QICARD_NOTIFICATION_URL=https://your-project.supabase.co/functions/v1/qicard_webhook_handler`
  - `QICARD_ALLOW_UNSIGNED_LOCAL_DEV=false`
  - `# --- Push Notifications (required for FCM push) ---`
  - `FCM_SERVER_KEY=your-fcm-server-key`
  - `# --- Cron & Security (required for scheduled functions) ---`
  - `CRON_SECRET=your-cron-secret`
  - `PUSH_NOTIFY_SECRET=your-push-notify-secret`
  - `# --- App Config ---`
  - `ALLOWED_ORIGIN=https://sline.app`
  - `ENVIRONMENT=production`
  - `BOOKING_PAYMENT_EXPIRY_MINUTES=30`
- [ ] (@SlineDocs) Add comments explaining each variable's purpose
- [ ] (@SlineDocs) Mark which are required vs optional (e.g., `QICARD_ALLOW_UNSIGNED_LOCAL_DEV` is optional, defaults to `false`)
- [ ] (@Sentinel) Verify NO actual secrets are in the file (only placeholder values like `your-*`)
- [ ] (@Sentinel) Verify all 18 env vars from the scan are included
- [ ] (@Sentinel) Verify `.env.example` is NOT in `.gitignore` (it must be committed)
- **GATE CHECK:** All 18 env vars documented with placeholders. No real secrets. File is committable.

### 4.3 Create CONTRIBUTING.md

**Primary Agent(s):** @SlineDocs, @Sentinel
**Goal:** Create contributor onboarding guide
**Why:** CLAUDE.md covers conventions but is not contributor-facing; new developers need a quick-start
**How:** Create root-level CONTRIBUTING.md that references existing docs
**Result:** Contributors can onboard quickly without reading all internal docs

- [ ] (@SlineDocs) Create `CONTRIBUTING.md` with sections:
  - **Getting Started** — Flutter 3.8.1+, `flutter pub get`, `git config core.hooksPath .githooks`
  - **Architecture** — MVVM, reference CLAUDE.md for details
  - **PR Process** — create feature branch, run `flutter test` + `flutter analyze`, submit PR (template auto-applied)
  - **Testing** — run `flutter test`, maintain 40% coverage floor, use `AppLogger` not `print()`
  - **Code Style** — reference `analysis_options.yaml`, `very_good_analysis` base
  - **Database Migrations** — reference `MIGRATION_REVIEW_CHECKLIST.md`
  - **Security** — reference `SECURITY.md`, never commit `.env` files
  - **[ADDED — Critique Fix 1] Dependency Security** — note that pub dependency vulnerabilities are monitored via GitHub Dependabot alerts. The `Dependency Vulnerability Check` CI workflow covers GitHub Actions dependencies and license compliance, NOT pub deps.
- [ ] (@Sentinel) Verify doc is concise (< 100 lines) and REFERENCES existing docs rather than duplicating
- [ ] (@Sentinel) Verify no internal secrets or infrastructure details are exposed
- [ ] (@Sentinel) Verify dependency security coverage description is accurate (Dependabot for pub, CI workflow for GH Actions)
- **GATE CHECK:** CONTRIBUTING.md created, concise, references canonical docs, dependency security accurately described.

### 4.4 Fix Documentation Drift — MVP_ROADMAP.md

**Primary Agent(s):** @SlineDocs, @Sentinel
**Goal:** Fix stale coverage and architecture guard numbers
**Why:** Stale docs cause confusion when planning future phases
**How:** Update specific lines with current values
**Result:** MVP_ROADMAP reflects current CI reality

**File:** `Sline_everything/MVP_ROADMAP.md` (UPDATE)

- [ ] (@SlineDocs) Line 92: Change "6 MVVM boundary checks" to "7 MVVM boundary checks" (Check 7 added in Phase E)
- [ ] (@SlineDocs) Section 9 "Current Focus": Change any reference to "coverage enforcement (70% target)" to "coverage enforcement (40% regression floor)"
- [ ] (@SlineDocs) Verify Phase E completion notes (line ~125-139) reflect current reality: 27/27 VMs tested, 982+ tests, 40% floor
- [ ] (@Sentinel) Verify no other stale numbers exist in the file
- [ ] (@Sentinel) Verify only drift-related content is changed (no unrelated edits)
- **GATE CHECK:** Coverage, test count, and architecture guard numbers match CI reality.

### 4.5 Fix Documentation Drift — ARCHITECTURE_ANALYSIS.md

**Primary Agent(s):** @SlineDocs, @Sentinel
**Goal:** Fix date typo
**Why:** Header says 2024 but content is from 2026
**How:** Change one line
**Result:** Accurate date

**File:** `Sline_everything/ARCHITECTURE_ANALYSIS.md` (UPDATE)

- [ ] (@SlineDocs) Line 3: Change "Date: March 7, 2024" to "Date: 2026-03-07 (with embedded notes through 2026-04-06)"
- [ ] (@Sentinel) Verify content accuracy is unchanged (only date line modified)
- **GATE CHECK:** Date typo fixed, content unchanged.

---

## Phase 5: Verification & Non-Regression (@Sentinel)

**Primary Agent(s):** @Sentinel
**Goal:** Verify all changes work together without breaking existing CI or developer workflow
**Why:** Any regression in the CI pipeline blocks all development
**How:** Run full verification suite and check all new files
**Result:** Confirmed non-regression and all new safeguards in place

### 5.1 Non-Regression Verification

**Primary Agent(s):** @Sentinel
**Goal:** Confirm existing CI checks still pass
**Why:** No existing check may be weakened
**How:** Run all existing validation commands
**Result:** All pass

- [ ] (@Sentinel) Run `flutter test` — all ~1229 tests pass, 0 failures
- [ ] (@Sentinel) Run `flutter analyze` — 0 issues
- [ ] (@Sentinel) Run `dart format --set-exit-if-changed .` — passes
- [ ] (@Sentinel) Verify `.githooks/pre-commit` works end-to-end:
  - Test with clean commit: passes all 4 checks
  - Test with `.env` file staged: blocked by env guard
  - Test with secret pattern in staged `.dart` file: blocked by secret scan
- [ ] (@Sentinel) Verify architecture guard logic in `ci.yml` is UNCHANGED (7 checks, same grep patterns)
- [ ] (@Sentinel) Verify coverage threshold in `ci.yml` is UNCHANGED (`THRESHOLD=40`)
- **GATE CHECK:** All existing checks pass. No regression.

### 5.2 New File Verification

**Primary Agent(s):** @Sentinel
**Goal:** Confirm all new files are valid and tracked
**Why:** Invalid YAML or untracked files break CI or are useless
**How:** Validate syntax and git tracking
**Result:** All new files valid and committed

- [ ] (@Sentinel) Verify all new YAML files are syntactically valid:
  - `.github/workflows/secret-scan.yml`
  - `.github/workflows/dependency-review.yml`
  - `.github/dependabot.yml`
  - `.github/ISSUE_TEMPLATE/bug_report.yml`
  - `.github/ISSUE_TEMPLATE/feature_request.yml`
- [ ] (@Sentinel) Verify all new files are tracked by git (`git status` shows no untracked new files)
- [ ] (@Sentinel) Verify no new files conflict with `.gitignore` entries
- [ ] (@Sentinel) Verify `scripts/check-secrets.sh` is executable (`ls -la scripts/check-secrets.sh` shows `x` permission)
- [ ] (@Sentinel) Verify `.env.example` is NOT blocked by `.gitignore` (`.gitignore` blocks `.env` and `.env.local` but NOT `.env.example`)
- [ ] (@Sentinel) Verify CODEOWNERS syntax: each line is `<path> @<username>` format
- **GATE CHECK:** All files valid, tracked, executable where needed, not blocked by gitignore.

### 5.3 Cross-Reference Verification

**Primary Agent(s):** @Sentinel
**Goal:** Confirm all cross-references between files are correct
**Why:** Broken references cause confusion
**How:** Check each reference link
**Result:** All references resolve

- [ ] (@Sentinel) Verify PR template references `MIGRATION_REVIEW_CHECKLIST.md` (file exists at root)
- [ ] (@Sentinel) Verify CONTRIBUTING.md references `CLAUDE.md` (exists), `SECURITY.md` (created this plan), `MIGRATION_REVIEW_CHECKLIST.md` (exists), `analysis_options.yaml` (exists)
- [ ] (@Sentinel) Verify pre-commit hook references `scripts/check-secrets.sh` (created this plan)
- [ ] (@Sentinel) Verify no circular or broken references
- **GATE CHECK:** All cross-references valid.

### 5.4 [ADDED — Critique Fix 1] Dependency Security Coverage Verification

**Primary Agent(s):** @Sentinel
**Goal:** Confirm the team understands what IS and IS NOT scanned for dependency vulnerabilities
**Why:** `dependency-review-action` does not scan pub deps — team must know Dependabot alerts are the real coverage for Flutter/Dart packages
**How:** Verify documentation accurately describes the coverage model
**Result:** No false confidence in dependency security

- [ ] (@Sentinel) Verify `dependency-review.yml` contains limitation comments at the top
- [ ] (@Sentinel) Verify CONTRIBUTING.md mentions Dependabot for pub dependency security
- [ ] (@Sentinel) Verify `MANUAL_GitHub_Setup_Checklist.md` step B4 (Enable Dependabot Alerts) is documented as required for pub dep coverage
- **GATE CHECK:** Dependency security coverage model is documented and accurate. No false confidence.

---

## 6) Acceptance Criteria (MANDATORY)

1. All 12 new files created and syntactically valid
2. All 3 existing files updated with targeted changes only
3. Every phase, sub-phase, and step has an explicit owning agent
4. No existing CI checks weakened, removed, or renamed
5. `flutter test` passes (~1229 tests, 0 failures)
6. `flutter analyze` passes (0 issues)
7. Architecture guard (7 checks) still passes
8. Coverage floor (40%) still enforced
9. Pre-commit hook still runs format + analyze, now also runs env guard + secret scan
10. Secret check script is standalone-runnable
11. No actual secrets committed in any file
12. All YAML workflows use exact job display names matching branch protection expectations
13. PR template references (not duplicates) existing migration checklist
14. `.env.example` covers all 18 Edge Function env vars found in scan
15. Documentation drift fixed (MVP_ROADMAP arch guard count, coverage floor; ARCHITECTURE_ANALYSIS date)

---

## 7) Rollback Plan

- **Workflow files** (secret-scan.yml, dependency-review.yml, dependabot.yml): Revert with `git revert` — no external state changed. GitHub will stop running workflows that don't exist.
- **CI workflow changes** (ci.yml — workflow_dispatch + artifacts): Revert with `git revert` — only additive changes, no logic modified.
- **Pre-commit hook** (.githooks/pre-commit): Revert with `git revert`. Developers may need `git config core.hooksPath .githooks` again if hook path was reset.
- **CODEOWNERS**: Delete the file. If branch protection requires code owner review, uncheck that setting first.
- **PR template** (pull_request_template.md): Delete the file. GitHub falls back to no template.
- **Issue templates** (bug_report.yml, feature_request.yml): Delete the files. GitHub falls back to blank issue form.
- **Scripts** (check-secrets.sh): Delete `scripts/` directory. Update pre-commit hook to remove the script reference.
- **Documentation** (SECURITY.md, CONTRIBUTING.md, .env.example): Delete the files — no external dependencies.
- **Doc drift fixes** (MVP_ROADMAP, ARCHITECTURE_ANALYSIS): Revert with `git revert` — content-only changes.

All changes are independently reversible with no cascading effects. No change requires a forward-fix — all can be cleanly reverted.

---

## 8) References (From Scan)

### Docs Scanned
- `CLAUDE.md` — architecture rules, CI description, conventions
- `Sline_everything/DEVELOPER_GUIDE.md` — v2.21.0, 7 MVVM checks, 33% floor, 982 tests, Phase F
- `Sline_everything/MVP_ROADMAP.md` — Phases B-E history, drift found (arch guard count, coverage floor)
- `Sline_everything/ARCHITECTURE_ANALYSIS.md` — date typo confirmed (line 3: "2024" should be "2026")
- `Sline_everything/STRUCTURE.md` — file organization, `.github/`, `.githooks/`, `docs/LOG/` references
- `MIGRATION_REVIEW_CHECKLIST.md` — 7-point checklist, mandatory for migration PRs
- `analysis_options.yaml` — `very_good_analysis` base, 5 SLine-specific rules, 21 disabled
- `.TODO/PLAN_GitHub_CI_RepoSafeguards_2026-04-04.md` — parent master plan
- `.TODO/Future_Plans/AGENT_GitHub_CI_Implementation.md` — agent implementation checklist
- `.TODO/Future_Plans/MANUAL_GitHub_Setup_Checklist.md` — manual GitHub config checklist

### Code Paths Scanned
- `.github/workflows/ci.yml` — 175 lines, 4 jobs, 7 arch guard checks, 40% coverage floor
- `.github/PULL_REQUEST_TEMPLATE/migration.md` — 43 lines, 7-section migration checklist
- `.githooks/pre-commit` — 21 lines, format + analyze only
- `scripts/` — does NOT exist (to be created)
- `supabase/functions/` — 14 function files across 12 directories + 1 shared module
- `supabase/functions/_shared/bookin_payment.ts` — 701 lines, 13 env vars
- All Edge Functions scanned for `Deno.env.get()` — 18 unique env vars found
- `.gitignore` — blocks `.env`, `.env.local` but NOT `.env.example`

### Confirmed Non-Existent (To Be Created)
- `.github/pull_request_template.md` (general template)
- `.github/ISSUE_TEMPLATE/` directory
- `.github/CODEOWNERS`
- `.github/dependabot.yml`
- `.github/workflows/secret-scan.yml`
- `.github/workflows/dependency-review.yml`
- `scripts/` directory
- `SECURITY.md`
- `CONTRIBUTING.md`
- `supabase/functions/.env.example`

---

## 9) Scan Evidence (Mandatory Appendix)

### File Line Counts (Files To Be Modified)

| File | Current Lines | Planned Change |
|------|---------------|----------------|
| `.github/workflows/ci.yml` | 175 | Add ~15 lines (workflow_dispatch + artifact upload) |
| `.githooks/pre-commit` | 21 | Add ~25 lines (env guard + secret scan before existing checks) |
| `Sline_everything/MVP_ROADMAP.md` | ~150+ | Update 2-3 specific lines (arch guard count, coverage floor) |
| `Sline_everything/ARCHITECTURE_ANALYSIS.md` | ~440+ | Update 1 line (date typo) |

### Edge Function Environment Variables (Full Scan)

| Variable | Source File(s) | Required |
|----------|---------------|----------|
| `SUPABASE_URL` | `_shared/bookin_payment.ts` | Yes (auto-injected hosted) |
| `SUPABASE_ANON_KEY` | `_shared/bookin_payment.ts` | Yes (auto-injected hosted) |
| `SUPABASE_SERVICE_ROLE_KEY` | `_shared/bookin_payment.ts` | Yes (auto-injected hosted) |
| `QICARD_API_BASE_URL` | `_shared/bookin_payment.ts` | Yes |
| `QICARD_TERMINAL_ID` | `_shared/bookin_payment.ts` | Yes |
| `QICARD_USERNAME` | `_shared/bookin_payment.ts` | Yes |
| `QICARD_PASSWORD` | `_shared/bookin_payment.ts` | Yes |
| `QICARD_RSA_PUBLIC_KEY_PEM` | `_shared/bookin_payment.ts` | Yes |
| `QICARD_FINISH_URL` | `_shared/bookin_payment.ts` | Yes |
| `QICARD_PROVIDER_NAME` | `_shared/bookin_payment.ts` | Yes |
| `QICARD_NOTIFICATION_URL` | `_shared/bookin_payment.ts` | Yes |
| `QICARD_ALLOW_UNSIGNED_LOCAL_DEV` | `_shared/bookin_payment.ts` | No (defaults to `false`) |
| `FCM_SERVER_KEY` | `push-notify/index.ts` | Yes |
| `CRON_SECRET` | `process-push-queue/index.ts` | Yes |
| `PUSH_NOTIFY_SECRET` | `push-notify/index.ts` | Yes |
| `ALLOWED_ORIGIN` | `_shared/bookin_payment.ts`, `finalize_payment_webhook/index.ts` | Yes |
| `ENVIRONMENT` | `_shared/bookin_payment.ts` | No (defaults to `production`) |
| `BOOKING_PAYMENT_EXPIRY_MINUTES` | `_shared/bookin_payment.ts` | No (defaults to `30`) |

### CI Job Display Names (Critical for Branch Protection)

| Workflow File | Job Key | Display Name (used in branch protection) |
|---------------|---------|------------------------------------------|
| `ci.yml` | `analyze` | `Lint & Analyze` |
| `ci.yml` | `architecture-guard` | `Architecture Guard` |
| `ci.yml` | `test` | `Unit & Widget Tests` |
| `ci.yml` | `build` | `Build (apk)` / `Build (web)` |
| `secret-scan.yml` | `trufflehog` | `TruffleHog Secret Scan` |
| `dependency-review.yml` | `review` | `Dependency Vulnerability Check` |

### Pre-Commit Hook Current State

```sh
#!/bin/sh
echo "Running format check..."
if ! dart format --set-exit-if-changed . ; then
  echo ""
  echo "FAILED: Formatting issues found."
  echo "Fix:    dart format ."
  exit 1
fi
echo ""
echo "Running analyze..."
if ! flutter analyze --no-fatal-infos ; then
  echo ""
  echo "FAILED: Analysis found warnings or errors."
  echo "Fix:    Review the issues above and fix them before committing."
  exit 1
fi
echo ""
echo "Pre-commit checks passed."
```

Existing checks (format + analyze) MUST be preserved as checks 3 and 4. New checks (env guard + secret scan) are prepended as checks 1 and 2.

---

END.
