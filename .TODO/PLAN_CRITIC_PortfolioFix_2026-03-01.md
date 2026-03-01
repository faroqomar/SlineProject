## A) Assumptions + Decision Needed (Blocking)

### Assumptions

- The target feature is the current portfolio surface spanning `lib/features/portfolio/**` plus the direct profile/public-profile dependencies already audited in `.TODO/protfolio.TODO.md:1-354`.
- The live Supabase project scanned on 2026-03-01 is the same project contract the app currently targets.
- Existing test infrastructure is the baseline to extend, not replace: widget tests use `test/test_support/pump_app.dart:5-18`, and integration preflight patterns already exist in `integration_test/support/preflight.dart:5-57`.
- The active runtime owner-manage entry point is `ManagePortfolioScreen`, not `PortfolioScreen`. File References: `lib/features/profile/view/settings_screen.dart:85-99`, `lib/features/profile/view/manage_portfolio_screen.dart:18-422`.
- Fixes must preserve MVVM boundaries and keep authorization in RLS/server-side storage policies; client checks remain UX only. File References: `Sline_everything/DEVELOPER_GUIDE.md:53-65`, `lib/main.dart:176-187`.

### Decision Needed (Blocking)

1. Missing decision: canonical persisted image contract.
- Options:
  - Keep writing mixed `image_url` values and normalize in UI only.
  - Standardize on public URL in `image_url`.
  - Introduce additive `image_path` as canonical persisted field and keep `image_url` as compatibility-read only.
- Recommended: introduce additive `image_path` as canonical persisted field and keep `image_url` as compatibility-read only.
- Why: current repo code already writes two incompatible meanings into `image_url`, and live rows are mixed and partially malformed. File References: `lib/features/portfolio/services/portfolio_service.dart:67-79`, `lib/features/profile/data/profile_repository.dart:145-162`, `.TODO/protfolio.TODO.md:109-128`.
- Plan impact:
  - If mixed `image_url` remains canonical: drift stays permanent and delete/render bugs remain likely.
  - If public URL remains canonical: cleanup and future bucket privacy changes stay fragile.
  - If `image_path` becomes canonical: migration scope grows, but the contract becomes testable and future-safe.

2. Missing decision: canonical portfolio write owner in app code.
- Options:
  - Keep profile-owned CRUD as the active write path.
  - Keep standalone `portfolio` feature path as the write owner.
  - Merge writes into `lib/features/portfolio/**` and make profile/public-profile consumers only.
- Recommended: merge writes into `lib/features/portfolio/**` and make profile/public-profile consumers only.
- Why: duplicate write paths are the central source of drift already visible in upload, delete, render, and paging behavior. File References: `lib/features/portfolio/services/portfolio_service.dart:12-149`, `lib/features/profile/data/profile_repository.dart:109-162`, `.TODO/protfolio.TODO.md:129-156`.
- Plan impact:
  - If profile path stays canonical: the declared feature boundary remains false.
  - If standalone path stays canonical without consumer migration: active settings/profile screens remain duplicated.
  - If writes converge under `lib/features/portfolio/**`: architecture and behavior can be enforced in one place.

3. Missing decision: fate of `PortfolioScreen`.
- Options:
  - Keep it fully supported as another owner-manage entry point.
  - Keep it temporarily as a read-only compatibility surface if still reachable.
  - Remove it immediately.
- Recommended: keep it temporarily as a read-only compatibility surface until route usage is re-verified, then deprecate if unused.
- Why: no verified caller was found, but immediate deletion would still be assumption-driven. File References: `lib/features/portfolio/view/portfolio_screen.dart:13-243`, `.TODO/protfolio.TODO.md:146-156`.
- Plan impact:
  - If kept as full owner-manage: duplicate UX continues.
  - If kept read-only: non-owner authz risk is closed without assuming route removal.
  - If removed immediately: route/import breakage becomes a real risk.

4. Missing decision: delivery slicing.
- Options:
  - One PR for DB, app, UI, tests, and docs.
  - Two PRs: DB/security first, app/UI/tests/docs second.
  - Three PRs: test/contract artifacts, DB/security, app/UI/tests/docs.
- Recommended: three PRs.
- Why: this feature spans live DB contract, RLS/storage, app architecture, and multiple UI surfaces. One or two broad PRs are review-hostile and rollback-hostile.
- Plan impact:
  - One PR: fastest on paper, worst for rollback.
  - Two PRs: workable, but still mixes testability baseline with risky DB changes.
  - Three PRs: safest and easiest to gate.

5. Missing decision: automatic handling of malformed legacy rows.
- Options:
  - Best-effort auto-normalize every non-HTTP `image_url`.
  - Quarantine malformed rows for manual review while auto-normalizing only safe rows.
  - Ignore malformed rows and ship new code only.
- Recommended: quarantine malformed rows for manual review while auto-normalizing only safe rows.
- Why: live data already contains `blob:`-contaminated values that cannot be safely guessed into storage object paths. Live Supabase scan evidence referenced in `.TODO/protfolio.TODO.md:109-128`.
- Plan impact:
  - If all rows are auto-normalized: risk of data loss or wrong deletes is high.
  - If malformed rows are quarantined: migration gets longer but stays safe.
  - If malformed rows are ignored: UI parity and cleanup guarantees stay incomplete.

## B) Gate Status (Pass/Fail)

### Gate 0: Test Infrastructure Gate
- Status: ❌ FAIL
- Reason:
  - The old plan added multiple new unit/widget tests but did not create a dedicated test-infra gate.
  - Shared harnesses exist, but the portfolio plan never defined how to extend them for this feature. File References: `test/test_support/pump_app.dart:5-18`, `integration_test/support/preflight.dart:5-57`.
  - Only one item-level `Key` is evidenced in the active manage list; action controls, dialogs, public-profile cards, and standalone portfolio actions have no verified stable selectors. File References: `lib/features/profile/view/manage_portfolio_screen.dart:331-331`, `lib/features/profile/view/manage_portfolio_screen.dart:183-245`, `lib/features/profile/view/widgets/public_profile/public_profile_portfolio.dart:22-85`, `lib/features/portfolio/view/portfolio_screen.dart:91-190`.
- What to add/fix to pass:
  - Add a dedicated test-infra phase before contract and DB work.
  - Define selector/key map, fixture manifest, env/preflight contract, run commands, failure artifact path, and retry budget.

### Gate 1: Data/Contracts Gate
- Status: ❌ FAIL
- Reason:
  - The old plan identified the mixed image semantics but did not lock the canonical persisted contract as a hard precondition.
  - Public-profile still consumes a second portfolio DTO with synthetic fields instead of a shared contract. File References: `lib/features/profile/models/freelancer_profile.dart:109-127`, `lib/features/profile/view/widgets/public_profile/public_profile_portfolio.dart:97-166`.
  - The plan did not force a field-level compatibility matrix for legacy URL rows, path rows, and malformed rows.
- What to add/fix to pass:
  - Lock `image_path` as canonical persisted data with explicit compatibility rules.
  - Add a contract artifact for owner/manage/public portfolio DTOs.
  - Add a migration/read matrix for URL vs path vs malformed rows.

### Gate 2: Security Gate
- Status: ❌ FAIL
- Reason:
  - The old plan called out unauthorized mutation UX but left the fate of `PortfolioScreen` unresolved.
  - Repo migration coverage for portfolio RLS/storage policy remains unverified. File References: `.TODO/protfolio.TODO.md:95-103`, `Sline_everything/SUPABASE_SETUP.md:1133-1142`, `Sline_everything/SUPABASE_SETUP.md:1581-1588`.
  - Raw exception text is still surfaced in active portfolio flows today. File References: `lib/features/portfolio/view/sheets/add_portfolio_sheet.dart:49-54`, `lib/features/profile/viewmodels/profile_view_model.dart:267-273`.
- What to add/fix to pass:
  - Make non-owner mutation denial a release-blocking invariant.
  - Add live policy snapshot plus repo migration restoration if missing.
  - Add explicit error taxonomy and user-safe message contract.

### Gate 3: Backend/API Gate
- Status: ❌ FAIL
- Reason:
  - The old plan did not force one canonical portfolio write owner before app-layer changes.
  - It identified pagination drift but did not bind a stable cursor contract to the DB/API layer first. File References: `lib/features/portfolio/services/portfolio_service.dart:20-48`.
  - Delete cleanup behavior is split across two repositories/services and no compatibility matrix was locked before migration work. File References: `lib/features/portfolio/services/portfolio_service.dart:116-148`, `lib/features/profile/data/profile_repository.dart:141-162`.
- What to add/fix to pass:
  - Lock `lib/features/portfolio/**` as the single write owner.
  - Add composite cursor contract and verification queries before refactor work.
  - Add deterministic delete semantics for canonical and legacy rows.

### Gate 4: UI/Integration Gate
- Status: ❌ FAIL
- Reason:
  - Public profile still renders placeholder-only portfolio cards instead of contract-backed portfolio content. File References: `lib/features/profile/view/widgets/public_profile/public_profile_portfolio.dart:97-166`.
  - The active manage dialog still performs async CRUD calls without local try/catch around save flows. File References: `lib/features/profile/view/manage_portfolio_screen.dart:188-209`.
  - `PortfolioScreen` still constructs its ViewModel from `SupabaseClient` in the view and exposes raw error text in body and delete snackbars. File References: `lib/features/portfolio/view/portfolio_screen.dart:76-79`, `lib/features/portfolio/view/portfolio_screen.dart:122-124`, `lib/features/portfolio/view/portfolio_screen.dart:173-180`.
- What to add/fix to pass:
  - Add a UI state matrix for manage/profile/public/standalone surfaces.
  - Replace raw error rendering with mapped English states.
  - Add stable action selectors and read-only mode behavior.

### Gate 5: Release/QA Gate
- Status: ❌ FAIL
- Reason:
  - The old plan had no PR slicing rule, no reviewer checklist, and no go/no-go gate.
  - It did not define flake thresholds, failure artifact paths, or fail-fast preflight requirements for any future integration coverage.
  - Docs sync existed, but there was no requirement that docs match the post-change live Supabase reality before release.
- What to add/fix to pass:
  - Add three-PR delivery slices with per-slice done criteria.
  - Add QA runbook, artifact conventions, and rerun policy.
  - Add final live-rescan and docs parity gate.

## C) Critical Gaps (Must-Fix)

### Gap 1
- Gap: No dedicated Test Infrastructure Gate.
- Why it will break: the plan schedules widget and integration work without defining selectors, fixtures, or failure artifacts. That produces brittle or skipped tests.
- Fix (exact step(s) to add / reorder):
  - Add Phase 0.0 Test Infrastructure Gate.
  - Create `.TODO/TEST_INFRA_Portfolio_2026-03-01.md`.
  - Create `.TODO/FIXTURES_Portfolio_2026-03-01.md`.
- Owner: Frontend
- Acceptance check: selector map, fixture manifest, run commands, timeout budget, and failure artifact path exist before any new portfolio test file is created.

### Gap 2
- Gap: Canonical image contract is unresolved.
- Why it will break: UI, delete cleanup, and migration logic will keep diverging if the persisted meaning of image data is not locked first.
- Fix (exact step(s) to add / reorder):
  - Add a blocking contract artifact before DB or app changes.
  - Choose canonical `image_path` plus compatibility-read rules for legacy `image_url`.
- Owner: Backend
- Acceptance check: one field is documented as canonical, one compatibility window is documented, and every renderer/delete path follows it.

### Gap 3
- Gap: Canonical portfolio write owner is unresolved.
- Why it will break: both `ProfileRepository` and `PortfolioRepository` can continue diverging after the first fix.
- Fix (exact step(s) to add / reorder):
  - Add a decision artifact choosing `lib/features/portfolio/**` as the only write owner.
  - Reorder the plan so consumer migration follows that decision.
- Owner: Backend
- Acceptance check: only one repository/service pair writes `portfolio_items` and `portfolio` storage.

### Gap 4
- Gap: Migration plan does not explicitly quarantine malformed live rows.
- Why it will break: best-effort normalization can map bad values to the wrong storage object path and cause data loss or failed cleanup.
- Fix (exact step(s) to add / reorder):
  - Add a quarantine/remediation branch in the migration artifact.
  - Add verify queries for migrated, legacy, and malformed row counts.
- Owner: Backend
- Acceptance check: malformed rows are enumerated and excluded from destructive assumptions.

### Gap 5
- Gap: No UI state matrix for manage/public/standalone portfolio flows.
- Why it will break: current code already conflates success, empty, and raw backend error states.
- Fix (exact step(s) to add / reorder):
  - Add `.TODO/UI_STATE_MATRIX_Portfolio_2026-03-01.md`.
  - Define loading, empty, recoverable error, read-only, legacy-image-fallback, and delete-partial-failure states.
- Owner: Frontend
- Acceptance check: each state has one expected render path and one test case.

### Gap 6
- Gap: Release slicing is missing.
- Why it will break: DB, architecture, UI, tests, and docs in one stream are hard to review and hard to roll back.
- Fix (exact step(s) to add / reorder):
  - Add three PR slices with per-PR gate criteria.
  - Add final go/no-go checklist after docs and live rescan.
- Owner: Product
- Acceptance check: each slice is independently reviewable and rollback-safe.

### Gap 7
- Gap: No explicit live verification artifact for RLS/storage and pagination correctness.
- Why it will break: docs and repo SQL are already behind live reality, and pagination fixes are easy to regress silently.
- Fix (exact step(s) to add / reorder):
  - Add `.TODO/RLS_CHECK_Portfolio_2026-03-01.md`.
  - Add migration verify queries and paging verify queries as release blockers.
- Owner: Backend
- Acceptance check: release requires both SQL/live-object evidence and app-level test evidence.

## D) Invariants & Success Criteria (Non-Negotiable)

1. Invariant: one canonical repository/service path owns all portfolio writes.
- How to enforce: move all CRUD/upload/delete writes under `lib/features/portfolio/**`; remove portfolio writes from `ProfileRepository`.
- How to verify: `rg -n "\.from\('portfolio_items'\)|storage\.from\('portfolio'\)" lib -g '*.dart'` shows one write owner after migration.

2. Invariant: canonical persisted portfolio image data is a storage path, not a public URL.
- How to enforce: additive `image_path` plus compatibility reads for legacy `image_url`.
- How to verify: live verify query shows new rows populate canonical path field and delete cleanup resolves from path.

3. Invariant: non-owner users cannot trigger mutation requests from UI, and RLS still blocks cross-user writes.
- How to enforce: read-only mode in app plus unchanged least-privilege RLS/storage policies.
- How to verify: widget/viewmodel tests and live forbidden-case SQL/PostgREST checks.

4. Invariant: pagination is exhaustive and stable across equal timestamps.
- How to enforce: server-filtered composite cursor (`created_at`, `id`) and aligned index/query shape.
- How to verify: unit tests and verify queries over >100 rows with identical timestamps.

5. Invariant: public profile, owner preview, manage, and standalone portfolio surfaces render the same domain contract.
- How to enforce: dedicated public DTO mapping from the canonical feature contract and shared image renderer.
- How to verify: widget tests and manual parity check across all four surfaces.

6. Invariant: deleting a portfolio item never silently leaves the system in an unknown state.
- How to enforce: deterministic DB delete + storage cleanup contract with controlled partial-failure handling.
- How to verify: delete tests for canonical rows, legacy URL rows, and malformed rows.

7. Invariant: raw backend exceptions are never shown directly to the user.
- How to enforce: error taxonomy and mapped English UI messages in viewmodels/services.
- How to verify: grep checks and widget tests for failure flows.

8. Invariant: test runs fail fast on missing prerequisites.
- How to enforce: fixture manifest, preflight contract, bounded waits, and artifact capture conventions.
- How to verify: QA runbook exists and preflight blocks missing env/seed data before long-running tests.

## E) Risk Register (Predict Problems)

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|------|-------|------------|--------|--------------|-------------|-----------|----------|
| Mixed image semantics survive the refactor | `lib/features/portfolio/services/portfolio_service.dart`, `lib/features/profile/data/profile_repository.dart`, live `public.portfolio_items` | High | High | Feature | New rows still populate `image_url` inconsistently | Lock canonical `image_path` contract and compatibility matrix first | Keep compatibility reads and block enforcement |
| Malformed live rows get mapped to wrong storage paths | live `public.portfolio_items.image_url` | Med | High | Data-loss | Delete cleanup targets wrong object or renders broken images after migration | Quarantine malformed rows; no best-effort destructive normalization | Leave malformed rows legacy-readable and repair manually |
| Duplicate write paths reappear | `ProfileRepository` + `PortfolioRepository` | High | High | Feature | Repo grep still shows two write owners after refactor | One write-owner invariant and repo-level grep check | Freeze profile-side CRUD and ship read-only fallback |
| Non-owner mutation UX remains reachable | `PortfolioScreen`, `PortfolioViewModel` | Med | High | Security-breach | User can still open add/delete flows for another owner | Read-only mode and widget/viewmodel tests | Disable standalone screen actions entirely |
| Pagination fix still skips equal-timestamp rows | `PortfolioService` | Med | High | Feature | Missing or duplicated items around page boundaries | Composite cursor contract + dedicated tests | Temporary page-size cap plus admin/manual reconciliation |
| Public profile remains contract-divergent | `freelancer_profile.dart`, `public_profile_portfolio.dart` | Med | Med | Feature | Public cards still show synthetic category/color only | Replace placeholder DTO and renderer in same slice | Keep public portfolio read-only and document mismatch as blocker |
| Portfolio tests remain brittle | manage/public/standalone widgets | Med | Med | Delivery | Test failures depend on text/layout tweaks | Selector/key map and harness contract | Limit release gate to unit + manual only until seams land |
| Docs drift again from live DB | `Sline_everything/*` vs live Supabase | High | Med | App-wide | Docs say private/public semantics different from live scan | Final live rescan + docs parity gate | Mark docs block and do not close release checklist |

## F) Pre-Mortem (How this fails in real life)

- This fails when the app starts writing `image_path`, but one UI surface still reads raw `image_url` and shows broken images for newly created items.
- This fails when the migration assumes every non-HTTP value is a valid storage path and deletes or hides the wrong asset.
- This fails when `ManagePortfolioScreen` is migrated, but `ProfileRepository` still exposes old write methods that a future screen reuses.
- This fails when the team hides the add button in `PortfolioScreen` but leaves long-press delete reachable for non-owner views.
- This fails when the page cursor fix handles `created_at` but not `id`, and equal-timestamp items still disappear intermittently.
- This fails when public profile keeps its synthetic portfolio DTO and the owner/public surfaces continue disagreeing on what a portfolio item is.
- This fails when the release merges DB, app, and UI changes together and the rollback path is unclear after a storage cleanup bug appears.
- This fails when docs are updated from intent instead of from the final live rescan, and the next change reintroduces the same storage assumptions.

## G) Plan Fixes (Concrete Additions / Expansions)

1. Goal: make portfolio tests executable before feature refactor work.
- Why: the old plan added tests without defining deterministic setup.
- How: add `TEST_INFRA`, `FIXTURES`, selector map, run commands, timeout budget, and artifact path.
- Output artifact: `.TODO/TEST_INFRA_Portfolio_2026-03-01.md`
- Stop condition: portfolio test prerequisites are documented before any new test file is created.

2. Goal: lock the canonical image contract.
- Why: mixed `image_url` semantics are the highest structural risk.
- How: add a contract artifact choosing canonical `image_path`, compatibility read rules, and malformed-row handling.
- Output artifact: `.TODO/CONTRACT_Portfolio_2026-03-01.md`
- Stop condition: every code path and migration step references one canonical image rule.

3. Goal: lock the write-owner architecture.
- Why: duplicate write paths are the current root cause of drift.
- How: add a write-owner decision and consumer migration plan.
- Output artifact: `.TODO/ARCHITECT_Portfolio_WriteOwner_2026-03-01.md`
- Stop condition: only one repository/service pair is allowed to mutate portfolio data.

4. Goal: make live migration safe.
- Why: live rows are mixed and partially malformed.
- How: add introduce/backfill/quarantine/enforce stages plus verify queries.
- Output artifact: `.TODO/MIGRATION_Portfolio_2026-03-01.md`
- Stop condition: migrated, legacy, and malformed row counts are measurable and acceptable.

5. Goal: make UI behavior deterministic.
- Why: current manage/public/standalone screens differ materially in behavior and error handling.
- How: add a UI state matrix and stable selectors for critical actions.
- Output artifact: `.TODO/UI_STATE_MATRIX_Portfolio_2026-03-01.md`
- Stop condition: every important state has one defined render path and one test case.

6. Goal: make security verification non-optional.
- Why: repo SQL is behind live reality and UI guards are not sufficient.
- How: add RLS/storage matrix plus live verify checklist.
- Output artifact: `.TODO/RLS_CHECK_Portfolio_2026-03-01.md`
- Stop condition: release cannot pass without positive and negative policy evidence.

7. Goal: make rollout reviewable and rollback-safe.
- Why: this change spans DB, architecture, UI, tests, and docs.
- How: add three PR slices with per-slice done criteria and rollback notes.
- Output artifact: `.TODO/ROLLOUT_Portfolio_2026-03-01.md`
- Stop condition: each slice can be reviewed and rolled back independently.

## H) Corrected Plan (Execution-Ready, Gate-Based)

### Phase 0: Test Infrastructure Gate
- Goal: make portfolio verification deterministic before implementation.
- Why: later QA work will fail or be skipped without selectors, fixtures, and preflight rules.
- How:
  - Inventory existing harnesses in `test/test_support/pump_app.dart:5-18` and `integration_test/support/preflight.dart:5-57`.
  - Add selector/key map for manage dialog actions, delete confirmation, public cards, and standalone portfolio actions.
  - Add fixture manifest covering owner user, non-owner user, >100 portfolio rows, equal-timestamp rows, legacy URL row, path row, and malformed row.
  - Add run commands, timeout budgets, rerun policy, and failure artifact conventions.
- Result: test work becomes deterministic and reviewable.
- GATE CHECK:
  - Selector map exists.
  - Fixture manifest exists.
  - Preflight contract exists.
  - QA runbook exists.

### Phase 1: Data/Contracts
- Goal: lock the portfolio data contract before DB or app changes.
- Why: current production failures are contract drift failures.
- How:
  - Lock canonical `image_path` contract and compatibility rules.
  - Lock `lib/features/portfolio/**` as the write owner.
  - Lock public-profile DTO mapping and fate of `PortfolioScreen`.
  - Define malformed-row handling and pagination cursor contract.
- Result: one source of truth exists for persisted data and consumer DTOs.
- GATE CHECK:
  - Contract artifact exists.
  - Write-owner decision exists.
  - `PortfolioScreen` decision exists.
  - Pagination cursor contract exists.

### Phase 2: Database & Security
- Goal: reconcile live DB/RLS/storage to the locked contract.
- Why: app refactor is unsafe until DB and auth rules are explicit.
- How:
  - Rescan live `portfolio_items`, indexes, policies, and bucket `portfolio`.
  - Add additive schema for canonical image fielding.
  - Restore missing repo migrations if absent.
  - Add RLS/storage verify matrix and migration verify queries.
  - Introduce/backfill/quarantine/enforce with no destructive assumptions.
- Result: live DB becomes explicit, additive-safe, and testable.
- GATE CHECK:
  - Live rescan matches planned migration scope.
  - Canonical field exists.
  - Positive/negative RLS cases are documented.
  - Migration verify queries pass.

### Phase 3: Backend APIs and App Data Layer
- Goal: align repositories, services, and viewmodels to the locked contract.
- Why: current drift lives in duplicate data-layer ownership and mixed cleanup logic.
- How:
  - Consolidate CRUD/upload/delete under feature-owned repository/service.
  - Add deterministic legacy compatibility parsing and delete cleanup.
  - Replace timestamp-only pagination with stable composite cursor behavior.
  - Remove raw update maps and raw exception leakage.
  - Make `PortfolioViewModel` owner/read-only aware.
- Result: app data layer becomes deterministic, MVVM-safe, and compatibility-aware.
- GATE CHECK:
  - One write owner remains.
  - No raw update maps remain.
  - No UI-to-Supabase construction remains for portfolio.
  - Pagination and delete tests pass.

### Phase 4: UI Wiring and Integration
- Goal: converge all portfolio surfaces on the same contract and state model.
- Why: manage/profile/public/standalone surfaces currently disagree materially.
- How:
  - Wire `ManagePortfolioScreen`, owner preview, public profile, and standalone screen to shared contract outputs.
  - Add explicit loading/empty/error/read-only/fallback states.
  - Hide non-owner mutation affordances.
  - Replace placeholder-only public cards with contract-backed rendering.
- Result: every portfolio surface behaves consistently and safely.
- GATE CHECK:
  - Public and owner surfaces render the same domain data.
  - Non-owner UI cannot trigger mutation flows.
  - Stable keys/selectors exist for critical actions.
  - Raw exception text is gone from UI.

### Phase 5: Polish, QA, Release, and Docs
- Goal: prove the fix is safe to ship and prevent drift from returning.
- Why: this feature crosses DB, storage, architecture, UI, and docs.
- How:
  - Run unit/widget/integration/manual checks from the test-infra runbook.
  - Execute live SQL verification and staging/manual role-based checks.
  - Sync docs to final code plus live DB reality.
  - Ship via three PR slices with final go/no-go checklist.
- Result: release decision is evidence-based and rollback-safe.
- GATE CHECK:
  - Tests and verify queries pass.
  - Docs match live reality.
  - PR slices meet done criteria.
  - Rollback notes are current.

## I) Change Report (Diff-Style)

1. Original issues summary
- The old plan identified the right failure areas but left the highest-risk decisions unresolved.
- It had no true test-infrastructure gate.
- It did not lock the canonical image contract or the single write-owner architecture before downstream work.
- It had no PR slicing or final go/no-go release gate.

2. Added steps
- Test Infrastructure Gate
- selector/key map
- fixture manifest and preflight contract
- canonical image contract artifact
- write-owner decision artifact
- malformed-row quarantine/remediation branch
- UI state matrix
- RLS/storage verification artifact
- rollout/PR slicing artifact

3. Removed steps (if any)
- Removed the implicit assumption that test setup can wait until the final QA phase.
- Removed the implicit assumption that mixed `image_url` semantics can be normalized safely without a canonical field decision.

4. Reordered steps (from → to)
- Tests from late-phase implementation → upfront Test Infrastructure Gate.
- Canonical contract decisions from “Phase 0 checklist” → blocking Data/Contracts phase before DB changes.
- Docs sync from “final cleanup” → final release blocker after live rescan.

5. Expanded steps (what became more detailed)
- Migration work expanded into introduce/backfill/quarantine/enforce with verify queries.
- UI work expanded into state matrix plus stable selectors.
- Security work expanded into live RLS/storage verification plus repo migration restoration.
- Release work expanded into three PR slices and go/no-go criteria.

6. Why (short, practical)
- The old plan would create motion but not safety. These changes make the sequence executable under live mixed data, duplicated architecture, and RLS/storage constraints.

7. Residual risks (what still remains risky even after fixes)
- Malformed legacy rows may still require manual repair after automated backfill.
- If `PortfolioScreen` has an unknown runtime caller outside the scanned code paths, deprecation work may need one more compatibility pass.
- If live docs drift again after rollout, future contributors can reintroduce public-URL assumptions unless the final docs gate is enforced.
