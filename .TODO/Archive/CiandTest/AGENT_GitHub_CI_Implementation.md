# Agent Implementation Checklist — GitHub CI & Repo Safeguards

**What:** Everything the agent creates or updates in the repository.
**Plan Reference:** `.TODO/PLAN_GitHub_CI_RepoSafeguards_2026-04-04.md`
**Session Log:** `docs/LOG/SESSION_PLAN_GitHub_CI_RepoSafeguards_2026-04-04.md`

---

## Phase 1 — P0 Critical (Do First)

### 1. Create `scripts/check-secrets.sh` (NEW)

- [ ] Create reusable shell script that scans staged diffs for secret patterns
- [ ] Patterns to detect: `sk_live`, `sk_test`, `service_role`, `password\s*[:=]\s*['"][^\s]+`
- [ ] Exclude `.md` files from scan (docs may reference patterns)
- [ ] Make executable (`chmod +x`)
- [ ] Must work standalone for manual developer checks
- **Owner:** @CodeGuard
- **Why:** Dependency for pre-commit hook update AND CI secret scanning

---

### 2. Update `.githooks/pre-commit` (UPDATE)

Current file has: format check + analyze check (22 lines).

- [ ] Add secret pattern detection BEFORE the existing format check
  - Call `scripts/check-secrets.sh` on staged files
  - Block commit if secrets detected
- [ ] Add env file staging guard
  - Block commit if `.env`, `secrets.json`, or `credentials.json` are staged
- [ ] Preserve existing format + analyze checks UNCHANGED
- [ ] Total overhead must be < 2 seconds on normal commits
- **Owner:** @CodeGuard
- **Why:** Last line of defense before secrets enter git history

---

### 3. Create `.github/workflows/secret-scan.yml` (NEW)

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
      - uses: trufflesecurity/trufflehog@v3.88.0
        with:
          extra_args: --only-verified
```

- [ ] Create file with above content
- [ ] Verify Supabase anon key (public, intentional) does NOT trigger false positive
- [ ] Job name must be exactly `TruffleHog Secret Scan` (used in branch protection)
- **Owner:** @CodeGuard
- **Why:** Automated secret leak detection on every push/PR

---

### 4. Create `.github/pull_request_template.md` (NEW)

- [ ] Create PR template with sections:
  - **What changed** (brief description)
  - **Why** (motivation / ticket link)
  - **General checklist:**
    - [ ] Tests pass (`flutter test`)
    - [ ] Analysis clean (`flutter analyze`)
    - [ ] Architecture guard passes
    - [ ] No hardcoded colors, strings, or secrets
  - **Payment/wallet/booking checklist** (conditional):
    - [ ] Edge cases tested (zero amount, negative, overflow)
    - [ ] RLS policies verified
    - [ ] No PII in logs
  - **Migration checklist** (conditional):
    - [ ] See `MIGRATION_REVIEW_CHECKLIST.md` (reference, NOT duplicate)
  - **Supabase/Edge Function checklist** (conditional):
    - [ ] CORS headers present
    - [ ] Auth verification in place
    - [ ] No service_role key in client code
- [ ] Keep template concise (developers skip long templates)
- [ ] Reference existing `MIGRATION_REVIEW_CHECKLIST.md` rather than duplicating
- **Owner:** @Architect
- **Why:** Immediate review quality improvement for every PR

---

## Phase 2 — P1 Important (Do Second)

### 5. Create `.github/workflows/dependency-review.yml` (NEW)

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

- [ ] Create file with above content
- [ ] Fails on `high` and `critical` severity (moderate/low are warnings)
- [ ] Job name must be exactly `Dependency Vulnerability Check`
- **Owner:** @CodeGuard
- **Why:** Supply chain protection for a payment app

---

### 6. Create `.github/dependabot.yml` (NEW)

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

- [ ] Create file with above content
- [ ] 5 PR limit for pub, 3 for github-actions (avoid PR flood)
- **Owner:** @CodeGuard
- **Why:** Stale dependencies accumulate vulnerabilities silently

---

### 7. Create `.github/CODEOWNERS` (NEW)

- [ ] Create with ownership rules:
  - `*` -> default owner (project lead GitHub username)
  - `lib/features/wallet/` -> wallet owner
  - `lib/features/booking/` -> booking owner
  - `supabase/` -> backend owner
  - `.github/` -> CI owner
  - `lib/core/` -> core infrastructure owner
- [ ] Verify syntax is valid
- [ ] Note: Only effective when branch protection requires code owner review (manual step)
- **Owner:** @Architect
- **Why:** Critical paths (payment, auth, Supabase) get reviewed by domain experts

---

### 8. Update `.github/workflows/ci.yml` (UPDATE)

- [ ] Add `workflow_dispatch: {}` to the `on:` block (enables manual trigger)
- [ ] Add `actions/upload-artifact@v4` step after each build step:
  - Upload APK build output
  - Upload web build output
- [ ] Do NOT change existing triggers (push, pull_request)
- [ ] Do NOT change existing jobs or checks
- [ ] Keep APK as `--debug` (release requires signing keys not in CI)
- **Owner:** @CodeGuard
- **Why:** Manual trigger enables debugging; artifacts enable build inspection

---

### 9. Create `SECURITY.md` (NEW)

- [ ] Create with sections:
  - Responsible disclosure process (email contact)
  - Security architecture overview (RLS, auth, payment security)
  - What to report (vulnerabilities, data exposure, auth bypass)
  - What NOT to report (Supabase anon key is public by design)
  - Response timeline expectations
- [ ] NO internal secrets or infrastructure details exposed
- **Owner:** @DocsKeeper
- **Why:** Financial marketplace needs responsible disclosure process

---

### 10. Create `supabase/functions/.env.example` (NEW)

- [ ] Document all required Edge Function environment variables:
  - `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`
  - `QICARD_API_BASE_URL`, `QICARD_TERMINAL_ID`, `QICARD_USERNAME`, `QICARD_PASSWORD`
  - `QICARD_RSA_PUBLIC_KEY_PEM`, `QICARD_FINISH_URL`
  - `QICARD_ALLOW_UNSIGNED_LOCAL_DEV`
  - `FCM_SERVER_KEY`, `CRON_SECRET`, `PUSH_NOTIFY_SECRET`
  - `ALLOWED_ORIGIN`
- [ ] Add comments explaining each variable's purpose
- [ ] Mark which are required vs optional
- [ ] Use placeholder values only (e.g., `your-key-here`) — NO actual secrets
- **Owner:** @DocsKeeper
- **Why:** 14 env vars undocumented; onboarding friction and deployment risk

---

## Phase 3 — P2 Nice-to-Have (Do Third)

### 11. Create `.github/ISSUE_TEMPLATE/bug_report.yml` (NEW)

- [ ] YAML-based template with:
  - Description, reproduction steps, expected vs actual, environment, screenshots
- **Owner:** @Architect

---

### 12. Create `.github/ISSUE_TEMPLATE/feature_request.yml` (NEW)

- [ ] YAML-based template with:
  - Problem description, proposed solution, alternatives considered, context
- **Owner:** @Architect

---

### 13. Create `CONTRIBUTING.md` (NEW)

- [ ] Sections:
  - Getting started (Flutter setup, `git config core.hooksPath .githooks`)
  - Architecture overview (MVVM, reference CLAUDE.md)
  - PR process (reference PR template)
  - Testing requirements (run tests, maintain 40% coverage floor)
  - Code style (reference `analysis_options.yaml`)
  - Migration process (reference `MIGRATION_REVIEW_CHECKLIST.md`)
- [ ] Keep concise — reference existing docs, don't duplicate
- **Owner:** @DocsKeeper

---

### 14. Fix `Sline_everything/MVP_ROADMAP.md` (UPDATE)

- [ ] Section 9 "Current Focus": change "coverage enforcement (70% target)" to "coverage enforcement (40% regression floor)"
- [ ] Add Phase D progress notes
- **Owner:** @DocsKeeper

---

### 15. Fix `Sline_everything/ARCHITECTURE_ANALYSIS.md` (UPDATE)

- [ ] Fix header date from "March 7, 2024" to "2026-03-07"
- **Owner:** @DocsKeeper

---

## Verification Phase (After All Files Created)

- [ ] `flutter test` — all tests pass
- [ ] `flutter analyze` — 0 issues
- [ ] `dart format --set-exit-if-changed .` — passes
- [ ] `.githooks/pre-commit` works with new secret detection
- [ ] All new YAML files are syntactically valid
- [ ] All new files are tracked by git (not in `.gitignore`)
- [ ] No actual secrets in any file

---

## Summary

| Action | Count |
|--------|-------|
| New files to create | 12 |
| Existing files to update | 3 |
| Total file operations | 15 |
| Estimated phases | 3 (P0 -> P1 -> P2) |
