# Plan Critique: Agent-Side CI & Repository Safeguards Implementation

**Plan Under Audit:** `.TODO/PLAN_Agent_CI_RepoSafeguards_2026-04-06.md`
**Auditor:** @PlanCritic
**Date:** 2026-04-06
**Verdict:** ❌ FAIL (2 critical gaps, 3 medium gaps — corrected plan below)

---

## A) Assumptions + Decision Needed (Blocking)

### Assumptions

1. **Solo developer repo**: CODEOWNERS points all paths to the same GitHub username. Acceptable for now.
2. **TruffleHog v3.88.0 is a valid tag**: Tag format is correct; exact version may need update at execution time. Non-blocking.
3. **No signing keys in CI**: APK stays `--debug`. Correct.
4. **`.env.example` is not gitignored**: Verified — `.gitignore` blocks `.env`, `.env.local`, `.env.*.local` but NOT `.env.example`. Correct.
5. **CODEOWNERS at `.github/CODEOWNERS`**: Valid location (GitHub checks `.github/`, root, and `docs/` in order). Correct.
6. **PR template coexistence**: `.github/pull_request_template.md` (default) + `.github/PULL_REQUEST_TEMPLATE/migration.md` (selectable alternative) coexist correctly on GitHub. Verified.
7. **Secret scan on all branches is intentional**: Plan explicitly triggers on all branch pushes, not just `main`. Acceptable for a payment app — catch secrets everywhere.

### Decision Needed (Blocking)

#### DN-1: `dependency-review-action` Does NOT Support Pub Ecosystem

- **What decision is missing:** The plan creates `.github/workflows/dependency-review.yml` using `actions/dependency-review-action@v4`, but this action does NOT support the `pub` (Dart/Flutter) package ecosystem. It supports npm, pip, Maven, and GitHub Actions only.
- **Options:**
  1. **Keep the workflow anyway** — it will still block PRs that add vulnerable GitHub Actions dependencies. Pub deps are covered by Dependabot alerts (manual step B4). The workflow won't fail — it just won't scan pub deps.
  2. **Replace with `google/osv-scanner-action`** — OSV Scanner supports pub/Dart and would actually scan Flutter dependencies.
  3. **Remove the workflow entirely** — rely solely on Dependabot alerts for pub vulnerability detection.
- **Recommended choice:** Option 1 (keep it). The workflow still provides value for GitHub Actions dependencies and will NOT produce false failures. Dependabot alerts (manual step B4) handle pub vulnerabilities. Add a comment in the YAML explaining the limitation.
- **What changes in the plan:** Add a YAML comment `# Note: does not scan pub deps — Dependabot alerts cover pub vulnerabilities` and add a step in Phase 5 to verify the workflow doesn't produce misleading results.

#### DN-2: CODEOWNERS GitHub Username

- **What decision is missing:** The plan uses `@<project-lead-github-username>` as a placeholder. Executor needs the actual GitHub username.
- **Options:**
  1. Ask the developer for their GitHub username before execution.
  2. Use `@erosDevv` if that's the known GitHub handle (inferred from repo context).
- **Recommended choice:** Option 1 — ask the developer. Wrong username = CODEOWNERS silently fails.
- **What changes in the plan:** Add an explicit "blocking input" step at Phase 0 to collect the GitHub username.

---

## B) Gate Status

| # | Gate | Status | Reason | Fix |
|---|------|--------|--------|-----|
| 1 | Data / Contracts Gate | ✅ PASS | No data model or contract changes. Env vars are documentation-only. | — |
| 2 | Security / RLS Gate | ✅ PASS | Secret scanning adds defense. SECURITY.md adds disclosure. No RLS changes. `.env.example` uses placeholders only. | — |
| 3 | Backend / Supabase Gate | ✅ PASS | No schema, RLS, RPC, or migration changes. `.env.example` is documentation. No diagram needed (no flow changes). Session log exists. | — |
| 4 | UI / Integration Gate | ✅ PASS | No UI changes. | — |
| 5 | Release / QA Gate | ❌ FAIL | (1) `dependency-review-action` doesn't support pub — plan doesn't acknowledge this, creating false confidence. (2) No YAML validation step during execution (plan only validates "at the end" in Phase 5, but invalid YAML should fail fast). (3) Pre-commit hook testing lacks a negative test for `.env.example` (must NOT be blocked). | (1) Add limitation comment + Dependabot coverage note. (2) Add per-phase YAML validation immediately after file creation. (3) Add `.env.example` negative test to hook verification. |

---

## C) Critical Gaps (Must-Fix)

### Gap 1: `dependency-review-action` Pub Blindness

- **Gap:** Plan assumes `actions/dependency-review-action@v4` scans pub dependencies. It does not.
- **Why it will break:** Creates false confidence — team believes pub deps are scanned on PRs, but they aren't. A high-severity pub vulnerability passes undetected.
- **Fix:** Add a YAML comment documenting the limitation. Add a note in the PR template that pub vulnerabilities are covered by Dependabot alerts, not the PR check. Add a future-work item to evaluate `google/osv-scanner-action` for pub support.
- **Owner:** @CodeGuard
- **Acceptance check:** YAML file contains limitation comment. CONTRIBUTING.md or PR template references Dependabot for pub dependency security.

### Gap 2: YAML Validation Deferred to Phase 5

- **Gap:** Plan creates 5 YAML files across Phases 1-3 but only validates them in Phase 5. If a YAML syntax error exists, all subsequent work on top of it is wasted.
- **Why it will break:** Executor creates `secret-scan.yml` with a YAML error in Phase 1, builds the hook and PR template in Phases 2-3, then discovers the error in Phase 5. Rework cascade.
- **Fix:** Each sub-phase that creates a YAML file must include an immediate validation step: `python3 -c "import yaml; yaml.safe_load(open('file.yml'))"` or equivalent `yq` check.
- **Owner:** @Sentinel
- **Acceptance check:** Every YAML-creating sub-phase has an inline validation step before its GATE CHECK.

### Gap 3: Pre-Commit Hook — Missing `.env.example` Negative Test

- **Gap:** Hook env guard blocks `.env`, `.env.*`, but must NOT block `.env.example`. Plan mentions "Do NOT block `.env.example`" but has no explicit test for this.
- **Why it will break:** A regex like `\.env\.` or `\.env$` could accidentally match `.env.example`. Without an explicit negative test, this regresses silently. The `.env.example` file created in Phase 4.2 would then be uncommittable.
- **Fix:** Add to Phase 1.2 verification: "(@Sentinel) Verify hook ALLOWS staging and committing `supabase/functions/.env.example`"
- **Owner:** @Sentinel
- **Acceptance check:** A commit containing only `.env.example` changes passes the pre-commit hook.

---

## D) Invariants & Success Criteria (Non-Negotiable)

| # | Invariant | How to Enforce | How to Verify |
|---|-----------|---------------|---------------|
| I1 | Existing CI checks must not be weakened or renamed | Diff `ci.yml` before/after — only additive changes | `git diff .github/workflows/ci.yml` shows only additions |
| I2 | Pre-commit hook must preserve format + analyze behavior | Existing lines 3-19 must appear unchanged in updated hook | `diff` old vs new hook, lines 3-19 identical |
| I3 | No actual secrets in any committed file | Grep all new files for secret patterns | Run `scripts/check-secrets.sh` against all new files |
| I4 | `.env.example` must be committable | `.gitignore` must not match `.env.example` | `git add supabase/functions/.env.example` succeeds |
| I5 | CI job display names must match branch protection expectations | Names in YAML `name:` fields match the manual checklist | Cross-reference YAML names with `MANUAL_GitHub_Setup_Checklist.md` |
| I6 | PR template must reference, not duplicate, migration checklist | PR template contains a link/reference, not a copy of the 7-point checklist | Verify `MIGRATION_REVIEW_CHECKLIST.md` is mentioned by name, not inlined |
| I7 | `flutter test` must still pass after all changes | Run test suite | 0 failures |
| I8 | `flutter analyze` must still pass after all changes | Run analyzer | 0 issues |

---

## E) Risk Register

| Risk | Where | Probability | Impact | Blast Radius | Early Signal | Prevention | Fallback |
|------|-------|-------------|--------|--------------|-------------|-----------|----------|
| TruffleHog flags Supabase anon key | Phase 1.3 | LOW | MEDIUM | CI blocked | First workflow run fails | `--only-verified` flag filters unverified patterns | Add `.trufflehog.yaml` allowlist if needed |
| Pre-commit hook too slow | Phase 1.2 | LOW | MEDIUM | Developer friction | Developers bypass hook with `--no-verify` | Secret scan only on staged diff (not full repo) | Make secret scan optional via env var `SKIP_SECRET_SCAN=1` |
| CODEOWNERS wrong username | Phase 3.3 | MEDIUM | LOW | Silent failure (no review requests) | No auto-review-request on first PR | Ask developer for username before execution | Verify with `gh api repos/{owner}/{repo}/codeowners/errors` after push |
| `dependency-review-action` false confidence | Phase 2.1 | HIGH | MEDIUM | Team believes pub deps are scanned | Never — silent non-coverage | Document limitation in YAML comment | Dependabot alerts cover pub deps |
| TruffleHog version pinned too old | Phase 1.3 | MEDIUM | LOW | Misses new secret patterns | New secret types slip through | Check latest release at execution time | Update version tag |
| Dependabot PR flood | Phase 2.2 | LOW | LOW | PR noise | More than 5 PRs in first week | PR limits (5 pub, 3 actions) | Reduce limits or pause Dependabot |
| YAML syntax error in workflow | Phase 1-3 | MEDIUM | HIGH | Workflow fails on first run | First CI run after push | Inline YAML validation after creation | Fix syntax, re-push |
| `.env.example` blocked by gitignore | Phase 4.2 | LOW | MEDIUM | File uncommittable | `git add` fails | Verified: `.gitignore` does NOT block `.env.example` | Add explicit negation `!.env.example` to `.gitignore` |

---

## F) Pre-Mortem (How This Fails In Real Life)

1. **This fails when** the executor creates `secret-scan.yml` with a typo in the `extra_args` field and discovers it only after all 12 files are created, requiring a debugging session to find which YAML file is broken.

2. **This fails when** the pre-commit hook env guard uses a regex that matches `.env.example`, making the `.env.example` file created in Phase 4 uncommittable. The executor doesn't discover this until Phase 4.2.

3. **This fails when** the developer sees `Dependency Vulnerability Check: PASS` on every PR and assumes pub dependencies are scanned, when they aren't. A high-severity pub vulnerability ships to production.

4. **This fails when** CODEOWNERS uses a placeholder `@<project-lead-github-username>` instead of a real GitHub username, and the executor commits it literally. GitHub silently ignores invalid CODEOWNERS entries — no error, no review requests, no warning.

5. **This fails when** the developer enables branch protection with "Require review from Code Owners" before CODEOWNERS is pushed, and then cannot merge any PR because there are no valid code owners to approve.

6. **This fails when** TruffleHog flags a "verified" secret that is actually the Supabase anon key (which is embedded in the Flutter app and is public by design), and the CI blocks all PRs until someone adds an allowlist.

7. **This fails when** the developer creates the GitHub labels with slightly different names than what `dependabot.yml` references (e.g., `dependency` instead of `dependencies`), and Dependabot PRs silently have no labels.

8. **This fails when** the executor adds `workflow_dispatch` to `ci.yml` but accidentally changes the indentation of existing `on:` block triggers, breaking push/PR triggers for the main CI.

---

## G) Plan Fixes (Concrete Additions / Expansions)

### Fix 1: Add DN-1 Resolution — `dependency-review-action` Limitation

- **Goal:** Acknowledge and document that `dependency-review-action` does not scan pub dependencies
- **Why:** Prevents false confidence in dependency security
- **How:** Add YAML comment in workflow file + note in CONTRIBUTING.md
- **Output artifact:** Updated `.github/workflows/dependency-review.yml` with limitation comment
- **Stop condition:** YAML comment exists, CONTRIBUTING.md mentions Dependabot for pub deps

### Fix 2: Add Inline YAML Validation After Each YAML File Creation

- **Goal:** Catch syntax errors immediately, not at Phase 5
- **Why:** Prevents rework cascade from deferred validation
- **How:** After each YAML file is created, run `python3 -c "import yaml; yaml.safe_load(open('path'))"` or `cat path | python3 -c "import sys,yaml;yaml.safe_load(sys.stdin)"`
- **Output artifact:** Validation step in each YAML-creating sub-phase
- **Stop condition:** Every YAML-creating sub-phase has inline validation before GATE CHECK

### Fix 3: Add `.env.example` Negative Test to Pre-Commit Hook Verification

- **Goal:** Ensure hook does NOT block `.env.example` files
- **Why:** `.env.example` is intentionally committed; blocking it breaks Phase 4.2
- **How:** Add explicit Sentinel verification: stage `.env.example`, run hook, confirm it passes
- **Output artifact:** Verification step in Phase 1.2
- **Stop condition:** `.env.example` commits pass the hook

### Fix 4: Add Blocking Input Step for CODEOWNERS Username

- **Goal:** Collect the actual GitHub username before CODEOWNERS is created
- **Why:** Placeholder usernames cause silent CODEOWNERS failure
- **How:** Add a step in Phase 0 or Phase 3.3 to ask the developer for their GitHub username
- **Output artifact:** Step in Phase 0 with "Decision Needed" marker
- **Stop condition:** Real GitHub username is used in CODEOWNERS

### Fix 5: Add TruffleHog Version Freshness Check

- **Goal:** Use a current TruffleHog version at execution time
- **Why:** Pinned `v3.88.0` may be outdated by execution time
- **How:** Add a step to check `gh api repos/trufflesecurity/trufflehog/releases/latest` and update the pinned version if needed
- **Output artifact:** Step in Phase 1.3
- **Stop condition:** Pinned version is within 2 minor versions of latest

### Fix 6: Add Concurrency Block to New Workflows

- **Goal:** Prevent duplicate secret-scan and dependency-review runs
- **Why:** Main `ci.yml` has `concurrency: { group: ci-${{ github.ref }}, cancel-in-progress: true }` but new workflows don't. Multiple pushes in quick succession will stack up redundant runs.
- **How:** Add `concurrency` block to `secret-scan.yml` and `dependency-review.yml`
- **Output artifact:** Updated workflow YAML
- **Stop condition:** Both new workflows have concurrency blocks

### Fix 7: Add `if: always()` to Artifact Upload

- **Goal:** Upload build artifacts even when the build step fails
- **Why:** Failed builds are often the ones developers need to inspect. Without `if: always()`, artifacts are only uploaded on success — useless for debugging.
- **How:** Add `if: always()` to the upload-artifact step
- **Output artifact:** Updated `ci.yml`
- **Stop condition:** Artifact upload runs regardless of build success/failure

---

## H) Corrected Plan (Execution-Ready, Gate-Based)

The corrected plan is written as an update to the original. Changes are marked with `[ADDED]`, `[CHANGED]`, or `[EXPANDED]`.

---

# Corrected Plan: Agent-Side CI & Repository Safeguards Implementation

**Plan Version:** 2.0 (Post-Critique)
**Date:** 2026-04-06
**Created By:** @SlinePlanner, reviewed by @PlanCritic
**Session Log:** `docs/LOG/SESSION_PLAN_Agent_CI_RepoSafeguards_2026-04-06.md`

---

## Phase 0: Preconditions & Gates

**Primary Agent(s):** @SlinePlanner, @Sentinel

### 0.1 Spec Lock

**Primary Agent(s):** @SlinePlanner, @Sentinel
**Goal:** Lock acceptance criteria, non-regression list, and blocking inputs
**Why:** Any regression in CI blocks all development; missing inputs block execution
**How:** Define measurable checks and collect required inputs
**Result:** Clear pass/fail criteria + all blocking inputs resolved

- [ ] (@Sentinel) Define acceptance criteria (unchanged from v1)
- [ ] (@SlinePlanner) Define non-regression list (unchanged from v1)
- [ ] `[ADDED]` (@SlinePlanner) **Blocking Input: GitHub username** — Ask the developer for their exact GitHub username. This is required for CODEOWNERS. Do NOT use a placeholder.
- [ ] `[ADDED]` (@SlinePlanner) **Blocking Input: Security contact email** — Ask the developer for the email to use in SECURITY.md responsible disclosure section. Do NOT use a placeholder.
- [ ] `[ADDED]` (@CodeGuard) **Version freshness check** — Run `gh api repos/trufflesecurity/trufflehog/releases/latest --jq .tag_name` and record the current TruffleHog release tag. If newer than `v3.88.0`, use the newer version.
- **GATE CHECK:** Scope, acceptance, non-regression, blocking inputs, and version checks are complete.

---

## Phase 1: Secret Scanning Infrastructure (@CodeGuard)

**Primary Agent(s):** @CodeGuard, @Sentinel
**Goal:** Three-layer secret defense: local script, pre-commit hook, CI workflow
**Why:** No secret scanning exists — critical for a payment app
**How:** Build script first, wire into hook, add CI workflow
**Result:** Secrets caught locally (hook), caught in CI (TruffleHog), and manually checkable (script)

### 1.1 Create Secret Check Script

(Unchanged from v1 — already well-decomposed)

### 1.2 Update Pre-Commit Hook

**Primary Agent(s):** @CodeGuard, @Sentinel
**Goal:** Add secret detection and env file guard
**Why:** Last line of defense before secrets enter git history
**How:** Prepend new checks before existing format + analyze
**Result:** 4-check hook: env guard, secret scan, format, analyze

- [ ] (@CodeGuard) Add env file staging guard as FIRST check:
  - Scan `git diff --cached --name-only` for `.env`, `.env.*`, `secrets.json`, `credentials.json`
  - `[CHANGED]` **CRITICAL: Exclude `.env.example`** — pattern must match `.env` and `.env.*` but NOT `.env.example`. Use: match files where name is exactly `.env` OR matches `.env.` followed by anything OTHER than `example`.
  - If blocked files found: print warning, list files, exit 1
- [ ] (@CodeGuard) Add secret pattern scan as SECOND check (unchanged from v1)
- [ ] (@CodeGuard) Preserve existing format check UNCHANGED as THIRD check
- [ ] (@CodeGuard) Preserve existing analyze check UNCHANGED as FOURTH check
- [ ] (@Sentinel) Verify existing format + analyze behavior is IDENTICAL to before
- [ ] (@Sentinel) Verify hook overhead < 2 seconds
- [ ] (@Sentinel) Verify hook blocks `sk_live_testkey123` in staged `.dart` file
- [ ] (@Sentinel) Verify hook allows clean `.dart` changes
- [ ] `[ADDED]` (@Sentinel) **Verify hook ALLOWS staging `.env.example`** — create a test `.env.example` file, stage it, run hook, confirm it passes. This is critical because Phase 4.2 creates `supabase/functions/.env.example` which must be committable.
- [ ] `[ADDED]` (@Sentinel) **Verify hook BLOCKS `.env.local`** — confirm the env guard catches `.env.local` but not `.env.example`.
- **GATE CHECK:** Hook has 4 checks in order. `.env.example` passes. `.env` and `.env.local` blocked. Existing behavior unchanged.

### 1.3 Create Secret Scanning CI Workflow

**Primary Agent(s):** @CodeGuard, @Sentinel
**Goal:** TruffleHog v3 CI workflow
**Why:** Automated safety net for secrets that slip past hooks
**How:** Create workflow YAML
**Result:** `.github/workflows/secret-scan.yml`

- [ ] (@CodeGuard) Create `.github/workflows/secret-scan.yml` with:
  - Name: `Secret Scan`
  - Triggers: `push` (all branches) and `pull_request`
  - Permissions: `contents: read`
  - `[ADDED]` **Concurrency block:** `concurrency: { group: secret-scan-${{ github.ref }}, cancel-in-progress: true }` — prevents duplicate runs on rapid pushes
  - Job name: `trufflehog` with display name `TruffleHog Secret Scan`
  - Steps: checkout with `fetch-depth: 0` + TruffleHog action (use version from Phase 0 freshness check) with `extra_args: --only-verified`
- [ ] (@Sentinel) Verify job display name is exactly `TruffleHog Secret Scan`
- [ ] (@Sentinel) Verify `--only-verified` and `fetch-depth: 0` are set
- [ ] (@Sentinel) Verify concurrency block exists
- [ ] `[ADDED]` (@Sentinel) **Inline YAML validation:** Run `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/secret-scan.yml'))"` — must pass. Do not proceed to Phase 2 if this fails.
- **GATE CHECK:** Workflow valid, concurrency set, job name matches branch protection.

---

## Phase 2: CI Workflow Enhancements (@CodeGuard)

**Primary Agent(s):** @CodeGuard, @Sentinel
**Goal:** Dependency review, Dependabot, CI improvements
**Why:** Supply chain protection + CI convenience
**How:** Create new files, update existing CI
**Result:** Dep vulnerabilities caught, automated updates, manual trigger, artifacts

### 2.1 Create Dependency Review Workflow

**Primary Agent(s):** @CodeGuard, @Sentinel
**Goal:** Automated dependency vulnerability scanning on PRs
**Why:** Supply chain protection
**How:** Create workflow YAML with documented limitations
**Result:** `.github/workflows/dependency-review.yml`

- [ ] (@CodeGuard) Create `.github/workflows/dependency-review.yml` with:
  - Name: `Dependency Review`
  - Triggers: `pull_request` to `main` only
  - Permissions: `contents: read`
  - `[ADDED]` **Concurrency block:** `concurrency: { group: dep-review-${{ github.ref }}, cancel-in-progress: true }`
  - Job name: `review` with display name `Dependency Vulnerability Check`
  - Steps: checkout + `actions/dependency-review-action@v4` with `fail-on-severity: high` and `allow-licenses: MIT, BSD-2-Clause, BSD-3-Clause, Apache-2.0, ISC, Zlib`
  - `[ADDED]` **YAML comment at top of file:** `# NOTE: dependency-review-action does not scan pub/Dart dependencies.`
  - `[ADDED]` **YAML comment:** `# Pub dep vulnerabilities are covered by Dependabot alerts (GitHub Settings > Code Security).`
  - `[ADDED]` **YAML comment:** `# This workflow scans GitHub Actions dependencies and license compliance.`
- [ ] (@Sentinel) Verify job display name is exactly `Dependency Vulnerability Check`
- [ ] (@Sentinel) Verify limitation comments are present in the YAML
- [ ] `[ADDED]` (@Sentinel) **Inline YAML validation:** `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/dependency-review.yml'))"` — must pass.
- **GATE CHECK:** Workflow valid, limitation documented, no false confidence.

### 2.2 Create Dependabot Configuration

(Unchanged from v1 — already correct. Pub IS supported by Dependabot.)

- [ ] `[ADDED]` (@Sentinel) **Inline YAML validation:** `python3 -c "import yaml; yaml.safe_load(open('.github/dependabot.yml'))"` — must pass.
- **GATE CHECK:** Config valid, PR limits set, manual dependencies documented.

### 2.3 Enhance Existing CI Workflow

**Primary Agent(s):** @CodeGuard, @Sentinel
**Goal:** Add `workflow_dispatch` + artifact uploads
**Why:** Manual trigger + downloadable builds
**How:** Additive changes to `ci.yml`
**Result:** Enhanced CI without breaking existing checks

- [ ] (@CodeGuard) Add `workflow_dispatch: {}` to `on:` block
- [ ] (@CodeGuard) Add `actions/upload-artifact@v4` after each build step:
  - APK: upload `build/app/outputs/flutter-apk/` with name `apk-debug` (verified: `flutter-apk/` directory exists alongside `apk/` in Flutter build output)
  - Web: upload `build/web/` with name `web-release`
  - `retention-days: 7`
  - `[ADDED]` Add `if: always()` to upload steps — failed builds are the ones developers need to inspect
- [ ] (@Sentinel) Verify existing triggers, job names, coverage threshold, build mode are ALL unchanged
- [ ] (@Sentinel) Verify no existing steps reordered, renamed, or removed
- [ ] `[ADDED]` (@Sentinel) **Diff check:** Run `git diff .github/workflows/ci.yml` and confirm ONLY additive changes (new lines, no modified lines except `on:` block)
- **GATE CHECK:** CI enhanced, existing behavior unchanged, artifacts upload even on failure.

---

## Phase 3: Developer Workflow Files (@Architect)

**Primary Agent(s):** @Architect, @Sentinel
**Goal:** PR template, issue templates, CODEOWNERS
**Why:** Structured review process + ownership routing
**How:** Create files in `.github/`
**Result:** Every PR has a checklist, code areas have owners

### 3.1 Create PR Template

(Unchanged from v1 — already well-decomposed)

### 3.2 Create Issue Templates

- [ ] (@Architect) Create `.github/ISSUE_TEMPLATE/` directory
- [ ] (@Architect) Create `bug_report.yml` (unchanged from v1)
- [ ] (@Architect) Create `feature_request.yml` (unchanged from v1)
- [ ] `[ADDED]` (@Sentinel) **Inline YAML validation** for both templates
- **GATE CHECK:** Templates valid, structured, concise.

### 3.3 Create CODEOWNERS

**Primary Agent(s):** @Architect, @Sentinel
**Goal:** Code ownership for critical paths
**Why:** Payment, auth, Supabase need domain expert review
**How:** Create CODEOWNERS with real GitHub username (from Phase 0)
**Result:** GitHub auto-requests reviews

- [ ] (@Architect) Create `.github/CODEOWNERS` with ownership rules using the **real GitHub username collected in Phase 0** (NOT a placeholder):
  - `*` -> `@<real-username>`
  - `lib/features/wallet/` -> `@<real-username>`
  - `lib/features/booking/` -> `@<real-username>`
  - `supabase/` -> `@<real-username>`
  - `.github/` -> `@<real-username>`
  - `lib/core/` -> `@<real-username>`
- [ ] (@Sentinel) Verify CODEOWNERS uses a real GitHub username, NOT a placeholder
- [ ] (@Sentinel) Verify syntax: each line is `<glob-pattern> @username`
- **GATE CHECK:** CODEOWNERS has real username, valid syntax.

---

## Phase 4: Documentation & Drift Fixes (@SlineDocs)

**Primary Agent(s):** @SlineDocs, @Sentinel

### 4.1 Create SECURITY.md

- [ ] (@SlineDocs) Create `SECURITY.md` using the **real security contact email collected in Phase 0** (NOT a placeholder)
- [ ] (remaining steps unchanged from v1)
- **GATE CHECK:** SECURITY.md has real email, no sensitive info exposed.

### 4.2 Create Edge Function Environment Documentation

(Unchanged from v1 — 18 vars, all verified by scan)

### 4.3 Create CONTRIBUTING.md

- [ ] (@SlineDocs) Create `CONTRIBUTING.md` with sections (unchanged from v1)
- [ ] `[ADDED]` (@SlineDocs) Add note in security section: "Pub dependency vulnerabilities are monitored via GitHub Dependabot alerts. The `Dependency Vulnerability Check` CI workflow covers GitHub Actions dependencies and license compliance."
- **GATE CHECK:** CONTRIBUTING.md concise, references canonical docs, dependency security accurately described.

### 4.4 Fix Documentation Drift — MVP_ROADMAP.md

(Unchanged from v1)

### 4.5 Fix Documentation Drift — ARCHITECTURE_ANALYSIS.md

(Unchanged from v1)

---

## Phase 5: Verification & Non-Regression (@Sentinel)

**Primary Agent(s):** @Sentinel

### 5.1 Non-Regression Verification

(Unchanged from v1)

### 5.2 New File Verification

(Unchanged from v1 — inline YAML validation already added per-phase, but Phase 5 does a final sweep)

### 5.3 Cross-Reference Verification

(Unchanged from v1)

### 5.4 `[ADDED]` Dependency Security Coverage Verification

**Primary Agent(s):** @Sentinel
**Goal:** Confirm the team understands what IS and IS NOT scanned
**Why:** `dependency-review-action` doesn't scan pub deps — team must know Dependabot alerts are the real coverage
**How:** Verify documentation accurately describes the coverage model
**Result:** No false confidence in dependency security

- [ ] (@Sentinel) Verify `dependency-review.yml` contains limitation comments
- [ ] (@Sentinel) Verify CONTRIBUTING.md mentions Dependabot for pub dependency security
- [ ] (@Sentinel) Verify `MANUAL_GitHub_Setup_Checklist.md` step B4 (Enable Dependabot Alerts) is documented as required for pub dep coverage
- **GATE CHECK:** Dependency security coverage model is documented and accurate.

---

## I) Change Report (Diff-Style)

### 1. Original Issues Summary

The v1 plan was well-structured but had 2 critical factual errors, 3 missing defensive steps, and 2 missing execution quality improvements.

### 2. Added Steps

| # | Step | Phase | Why |
|---|------|-------|-----|
| 1 | Blocking Input: GitHub username | 0.1 | CODEOWNERS fails silently with placeholder usernames |
| 2 | Blocking Input: Security contact email | 0.1 | SECURITY.md needs a real email |
| 3 | TruffleHog version freshness check | 0.1 | Pinned version may be outdated |
| 4 | `.env.example` negative test for hook | 1.2 | Hook could accidentally block `.env.example` |
| 5 | `.env.local` positive test for hook | 1.2 | Ensures env guard catches `.env.local` |
| 6 | Concurrency blocks on new workflows | 1.3, 2.1 | Prevents duplicate runs on rapid pushes |
| 7 | Inline YAML validation (5 files) | 1.3, 2.1, 2.2, 3.2 | Fail fast on syntax errors |
| 8 | `dependency-review-action` limitation comments | 2.1 | Prevents false confidence in pub dep scanning |
| 9 | `if: always()` on artifact uploads | 2.3 | Failed builds need inspection too |
| 10 | `ci.yml` diff check | 2.3 | Verify only additive changes |
| 11 | Dependabot security coverage note in CONTRIBUTING.md | 4.3 | Accurate dependency security documentation |
| 12 | Phase 5.4 dependency security coverage verification | 5.4 | Verify no false confidence |

### 3. Removed Steps

None.

### 4. Reordered Steps

None — original ordering was correct (script -> hook -> CI -> deps -> templates -> docs -> verify).

### 5. Expanded Steps

| Step | What Changed |
|------|-------------|
| Phase 0.1 | Added 3 blocking input/version steps |
| Phase 1.2 (hook verification) | Added `.env.example` and `.env.local` test cases |
| Phase 1.2 (env guard) | Expanded regex requirement to explicitly exclude `.env.example` |
| Phase 2.1 (dep review) | Added limitation comments and concurrency |
| Phase 2.3 (ci.yml update) | Added `if: always()` and diff check |
| Phase 3.3 (CODEOWNERS) | Changed placeholder to real username requirement |
| Phase 4.1 (SECURITY.md) | Changed placeholder to real email requirement |
| Phase 5 (verification) | Added Phase 5.4 for dependency security coverage |

### 6. Why

- **DN-1 (dep-review pub blindness):** The original plan created false confidence. Team would believe pub deps are scanned when they aren't.
- **YAML validation deferred:** Original plan validated YAML only at Phase 5. Errors discovered late cause rework cascades.
- **`.env.example` test missing:** Without this, Phase 4.2 could produce an uncommittable file.
- **Placeholder inputs:** CODEOWNERS and SECURITY.md with placeholders are functionally broken. Better to block on real input.
- **Concurrency missing:** New workflows would stack up redundant runs on rapid pushes.
- **Artifact `if: always()`:** Failed builds are the primary debugging use case for artifacts.

### 7. Residual Risks

| Risk | Mitigation | Status |
|------|-----------|--------|
| TruffleHog false positive on Supabase anon key | `--only-verified` flag | MITIGATED (low residual risk) |
| `dependency-review-action` never supports pub | Dependabot alerts cover pub; action still useful for GH Actions deps | ACCEPTED |
| Developer forgets manual GitHub config steps | `MANUAL_GitHub_Setup_Checklist.md` exists | MITIGATED (depends on developer follow-through) |
| Dependabot label mismatch | Labels must be created with exact names | DOCUMENTED in manual checklist |
| Solo developer CODEOWNERS = no real code review enforcement | Expected for solo dev; re-evaluate when team grows | ACCEPTED |

---

END.
