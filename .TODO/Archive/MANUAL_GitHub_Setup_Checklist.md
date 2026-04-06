# Manual GitHub Setup Checklist

**What:** Everything YOU must do by hand on GitHub's web UI.
**When:** After the agent pushes the new workflow/config files to the repo.
**Plan Reference:** `.TODO/PLAN_GitHub_CI_RepoSafeguards_2026-04-04.md`

---

## Priority 0 — Do Immediately After Agent Push

### 1. Branch Protection on `main`

**Where:** GitHub -> Repository -> Settings -> Branches -> Add branch protection rule

| Setting | Value |
|---------|-------|
| Branch name pattern | `main` |
| Require a pull request before merging | YES |
| Required approving reviews | `1` |
| Dismiss stale pull request approvals when new commits are pushed | YES |
| Require review from Code Owners | YES (after CODEOWNERS file is pushed) |
| Require status checks to pass before merging | YES |
| Require branches to be up to date before merging | YES |
| Do not allow bypassing the above settings | YES |
| Require signed commits | NO (adds friction, low priority) |
| Require linear history | NO (optional preference) |

**Required status checks to add (type the exact names):**
- `Lint & Analyze`
- `Architecture Guard`
- `Unit & Widget Tests`
- `Build (apk)`
- `Build (web)`

> Note: `TruffleHog Secret Scan` and `Dependency Vulnerability Check` are added later (see step 5 below) because GitHub requires a workflow to run at least once before it appears in the status check list.

---

### 2. Enable Secret Scanning

**Where:** GitHub -> Repository -> Settings -> Code security and analysis

- [ ] Enable **Secret scanning**
- [ ] Enable **Push protection** (blocks pushes containing detected secrets)
- [ ] (Optional) Add custom secret pattern for Supabase `service_role` key if available

---

### 3. Verify Actions Permissions

**Where:** GitHub -> Repository -> Settings -> Actions -> General

- [ ] Confirm Actions permissions = "Allow all actions and reusable workflows"
  - Or at minimum allow: `actions/*`, `subosito/*`, `trufflesecurity/*`
- [ ] Confirm Workflow permissions = "Read repository contents" (already set in YAML, but verify the repo default matches)

---

## Priority 1 — Do After First PR With New Workflows

### 4. Enable Dependabot Alerts

**Where:** GitHub -> Repository -> Settings -> Code security and analysis

- [ ] Enable **Dependabot alerts**
- [ ] Enable **Dependabot security updates**
- [ ] Verify **Dependency graph** is enabled

> The `dependabot.yml` config file alone does NOT enable vulnerability alerts. This manual step is required.

---

### 5. Add New Workflow Checks as Required Status Checks

**Where:** GitHub -> Repository -> Settings -> Branches -> Edit `main` protection rule -> Status checks

**When:** After the first PR with the new workflows has run successfully (so the check names appear in GitHub's list).

- [ ] Add `TruffleHog Secret Scan` as required
- [ ] Add `Dependency Vulnerability Check` as required

---

## Priority 2 — Do When Convenient

### 6. Create Labels for Dependabot + Issue Triage

**Where:** GitHub -> Repository -> Issues -> Labels -> New label

| Label | Color | Purpose |
|-------|-------|---------|
| `dependencies` | `#0075ca` (blue) | Auto-applied by Dependabot to dependency PRs |
| `automated` | `#e4e669` (yellow) | Auto-applied by Dependabot |
| `ci` | `#d4c5f9` (purple) | For CI/infrastructure PRs |
| `security` | `#b60205` (red) | For security-related issues |
| `payment` | `#d93f0b` (orange) | For payment/wallet/escrow issues |
| `migration` | `#fbca04` (gold) | For database migration issues |

---

## Priority 3 — Future (Not Now)

### 7. GitHub Environments (When Release Workflow Exists)

**Where:** GitHub -> Repository -> Settings -> Environments

- [ ] Create `production` environment
- [ ] Add required reviewers for production deployments
- [ ] Add environment secrets (signing keys, deploy tokens)

> Skip this until a release/deploy workflow is implemented.

---

## Quick Reference: Execution Order

```
1. Agent pushes files to branch
2. YOU do: Branch protection (#1) + Secret scanning (#2) + Actions permissions (#3)
3. Open PR to main (triggers new workflows for the first time)
4. YOU do: Dependabot alerts (#4) + Labels (#6)
5. After PR merges and workflows have run: Add new checks as required (#5)
6. Environments (#7) — later, when release workflow exists
```

---

## Verification

After completing all steps, confirm:

- [ ] Direct push to `main` is blocked (test by trying to push — should be rejected)
- [ ] PR without CI passing cannot be merged
- [ ] Secret scanning is active (check Settings -> Code security)
- [ ] Dependabot alerts tab shows up in the Security section
- [ ] Labels exist in Issues -> Labels
