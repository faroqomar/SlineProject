# 📌 Plan: Portfolio Feature Recovery

## 1) Goal

- Goal: eliminate duplicated portfolio write paths, close authorization UX gaps, fix pagination/data drift, normalize portfolio image persistence safely against the live Supabase state, and leave the feature with one MVVM-compliant runtime contract. File References: `.TODO/protfolio.TODO.md:75-354`, `lib/features/portfolio/services/portfolio_service.dart:20-149`, `lib/features/profile/data/profile_repository.dart:109-227`
- Why: the current repo has two portfolio CRUD stacks, two incompatible meanings of `image_url`, one active public-profile placeholder DTO, and one standalone screen that can expose mutation UI for non-owner views. File References: `lib/features/portfolio/view/portfolio_screen.dart:55-191`, `lib/features/portfolio/services/portfolio_service.dart:67-79`, `lib/features/profile/data/profile_repository.dart:145-162`, `lib/features/profile/models/freelancer_profile.dart:109-127`
- Result: one canonical portfolio contract, one write owner under `lib/features/portfolio/**`, additive-safe DB/storage reconciliation, deterministic rendering across manage/profile/public surfaces, and a release gate backed by live SQL verification plus app tests. File References: `Sline_everything/DEVELOPER_GUIDE.md:53-65`, `Sline_everything/CODE_REVIEW.md:371-374`, `.TODO/PLAN_CRITIC_PortfolioFix_2026-03-01.md:1-287`

## 2) Scope

### In-Scope

- Feature module `lib/features/portfolio/**`. File References: `.TODO/CodexRefactor/01_FEATURES_INDEX.md:768-789`, `lib/features/portfolio/view/portfolio_screen.dart:13-243`, `lib/features/portfolio/viewmodels/portfolio_view_model.dart:8-193`, `lib/features/portfolio/data/portfolio_repository.dart:8-68`, `lib/features/portfolio/services/portfolio_service.dart:12-149`
- Direct profile/public-profile dependencies that currently read, write, or render portfolio data. File References: `lib/features/profile/view/settings_screen.dart:85-99`, `lib/features/profile/view/manage_portfolio_screen.dart:18-422`, `lib/features/profile/view/profile_screen.dart:309-390`, `lib/features/profile/view/public_profile_screen.dart:61-68`, `lib/features/profile/view/public_profile_screen.dart:280-291`, `lib/features/profile/viewmodels/profile_view_model.dart:185-323`, `lib/features/profile/viewmodels/public_profile_view_model.dart:19-37`, `lib/features/profile/viewmodels/user_profile_view_model.dart:8-108`, `lib/features/profile/data/profile_repository.dart:109-227`, `lib/features/profile/models/freelancer_profile.dart:92-142`, `lib/features/profile/view/widgets/public_profile/public_profile_portfolio.dart:9-167`
- Shared portfolio rendering primitive `lib/core/widgets/signed_image.dart:25-201`.
- Live Supabase objects directly touched: `public.portfolio_items`, bucket `portfolio`, related `storage.objects` policies. File References: `Sline_everything/SUPABASE_SETUP.md:689-722`, `Sline_everything/SUPABASE_SETUP.md:1133-1142`, `Sline_everything/SUPABASE_SETUP.md:1575-1588`

### Out-of-Scope

- Bucket privacy redesign in the same remediation. The live bucket is public today, and changing privacy in this patch would add avoidable migration risk. File References: `Sline_everything/DEVELOPER_GUIDE.md:73-79`, `.TODO/protfolio.TODO.md:172-180`
- Realtime, Edge Functions, or new RPC work unless the final live rescan proves they are required. UNVERIFIED current usage. File Reference: `.TODO/protfolio.TODO.md:35-38`
- Non-portfolio profile/task/dashboard redesign beyond direct portfolio dependencies. File References: `lib/features/profile/data/profile_repository.dart:164-227`

## 3) Evidence & Findings (From Scan)

### Existing

- Active owner-manage flow is `SettingsScreen -> ManagePortfolioScreen`. File References: `lib/features/profile/view/settings_screen.dart:85-99`, `lib/features/profile/view/manage_portfolio_screen.dart:18-422`
- Public profile flow is `PublicProfileViewModel -> ProfileRepository.getPublicProfile() -> PublicProfilePortfolio`. File References: `lib/features/profile/view/public_profile_screen.dart:61-68`, `lib/features/profile/view/public_profile_screen.dart:280-291`, `lib/features/profile/viewmodels/public_profile_view_model.dart:19-37`, `lib/features/profile/data/profile_repository.dart:164-227`
- The repo currently has two portfolio write owners. File References: `lib/features/portfolio/services/portfolio_service.dart:12-149`, `lib/features/profile/data/profile_repository.dart:109-162`
- Live Supabase scan on 2026-03-01 confirmed:
  - `public.portfolio_items(id, owner_id, title, description, image_url, created_at)` exists.
  - RLS is enabled with owner-write policies and authenticated/public-readable select policy.
  - bucket `portfolio` exists and is public.
  - storage owner-path policies exist.
  - live rows are mixed: HTTP URLs, path-like values, and malformed `blob:`-contaminated values coexist. Live scan evidence summarized in `.TODO/protfolio.TODO.md:109-128`.
- Existing test infrastructure baseline exists and should be extended, not replaced. File References: `test/test_support/pump_app.dart:5-18`, `integration_test/support/preflight.dart:5-57`

### Missing

- No verified versioned migration files for portfolio schema/RLS/storage in `supabase/migrations/`. File References: `.TODO/protfolio.TODO.md:95-103`, `Sline_everything/SUPABASE_SETUP.md:1133-1142`, `Sline_everything/SUPABASE_SETUP.md:1581-1588`
- No portfolio-specific tests currently exist. UNVERIFIED absence-based search noted in `.TODO/protfolio.TODO.md:163-171`.
- No contract artifact exists for canonical portfolio image semantics, DTO mapping, or pagination cursor behavior. File References: `lib/features/portfolio/models/portfolio_item.dart:5-68`, `lib/features/profile/models/freelancer_profile.dart:92-128`
- No dedicated release slicing, fixture manifest, or portfolio-specific QA runbook exists. File References: `.TODO/PLAN_CRITIC_PortfolioFix_2026-03-01.md:28-92`

### Conflicts / Risks

- Docs conflict internally on generic storage guidance vs current portfolio implementation style. File References: `Sline_everything/DEVELOPER_GUIDE.md:65-65`, `Sline_everything/DEVELOPER_GUIDE.md:129-129`, `Sline_everything/DEVELOPER_GUIDE.md:422-429`, `Sline_everything/DEVELOPER_GUIDE.md:552-552`
- Historical docs conflict with live bucket privacy state. File References: `Sline_everything/Sline_Log.md:1042-1046`, `Sline_everything/DEVELOPER_GUIDE.md:73-79`
- `PortfolioScreen` still constructs its ViewModel from `SupabaseClient` in the view and can expose raw error text plus non-owner mutation affordances. File References: `lib/features/portfolio/view/portfolio_screen.dart:76-79`, `lib/features/portfolio/view/portfolio_screen.dart:107-111`, `lib/features/portfolio/view/portfolio_screen.dart:122-124`, `lib/features/portfolio/view/portfolio_screen.dart:173-180`
- Public-profile portfolio remains contract-divergent and placeholder-driven. File References: `lib/features/profile/models/freelancer_profile.dart:109-127`, `lib/features/profile/view/widgets/public_profile/public_profile_portfolio.dart:97-166`

## 4) System Impact Map

- UI:
  - `ManagePortfolioScreen`, owner profile preview, public profile portfolio tab, and `PortfolioScreen` must converge on one rendering and state contract. File References: `lib/features/profile/view/manage_portfolio_screen.dart:252-422`, `lib/features/profile/view/profile_screen.dart:309-390`, `lib/features/profile/view/widgets/public_profile/public_profile_portfolio.dart:22-167`, `lib/features/portfolio/view/portfolio_screen.dart:91-190`
- MVVM/App Logic:
  - One source of truth must replace duplicated ViewModel/repository/service ownership. File References: `lib/features/portfolio/viewmodels/portfolio_view_model.dart:46-193`, `lib/features/profile/viewmodels/profile_view_model.dart:185-323`
- Database:
  - Additive migration is feasible because live table shape is small and there are no live triggers/RPCs/views currently constraining the rollout. Live scan evidence summarized in `.TODO/protfolio.TODO.md:33-38`, `.TODO/protfolio.TODO.md:109-128`
- RLS/Security:
  - Live policies already enforce owner writes; app changes must not widen that scope and repo migrations must be restored if missing.
- Storage:
  - Public bucket remains as-is this release, but persisted canonical app data must become a storage path rather than a public URL string. File References: `lib/core/widgets/signed_image.dart:73-100`, `.TODO/PLAN_CRITIC_PortfolioFix_2026-03-01.md:1-27`
- Compatibility & Migration:
  - A compatibility window is mandatory because live rows already contain mixed and malformed image references. File References: `.TODO/protfolio.TODO.md:109-128`
- Contracts:
  - Public profile and feature portfolio currently use separate models with overlapping meaning and must converge. File References: `lib/features/portfolio/models/portfolio_item.dart:5-68`, `lib/features/profile/models/freelancer_profile.dart:92-128`

---

# ✅ Execution Phases (Checklist)

## Phase 0: Preconditions & Gates

> Primary: @Sentinel

### 0.0 Test Infrastructure Gate

- Goal:
  - Make all planned unit/widget/integration checks deterministic before feature refactor work starts.
- Why:
  - Existing harnesses exist, but portfolio has no selector map, fixture manifest, or QA runbook yet. File References: `test/test_support/pump_app.dart:5-18`, `integration_test/support/preflight.dart:5-57`, `.TODO/PLAN_CRITIC_PortfolioFix_2026-03-01.md:28-92`
- How:
  - [ ] (@Sentinel) Create `.TODO/TEST_INFRA_Portfolio_2026-03-01.md` covering harness reuse, run commands, timeout budgets, rerun policy, and failure artifact path.
  - [ ] (@Sentinel) Create `.TODO/FIXTURES_Portfolio_2026-03-01.md` listing required users, roles, sample rows, >100-row paging dataset, equal-timestamp rows, legacy URL row, path row, and malformed row.
  - [ ] (@Pixel) Create `.TODO/SELECTORS_Portfolio_2026-03-01.md` mapping stable keys/selectors for add, save, delete, retry, public-card, and read-only states across all portfolio surfaces.
  - [ ] (@Sentinel) Define fail-fast preflight rules for any integration/staging checks using the same pattern as `integration_test/support/preflight.dart:5-57`.
- Result:
  - Portfolio tests become executable, reviewable, and bounded.
- **Verify (@Sentinel):**
  - selector map exists
  - fixture manifest exists
  - run commands + retry policy exist
  - preflight requirements exist

### 0.1 Spec Lock

- Goal:
  - Lock the decisions the old draft left unresolved.
- Why:
  - Architecture, migration, and rollout work will drift again if these choices stay implicit.
- How:
  - [ ] (@Architect) Lock the canonical persisted image contract: additive `image_path` becomes canonical; legacy `image_url` is compatibility-read only; bucket privacy remains unchanged in this remediation. File References: `.TODO/PLAN_CRITIC_PortfolioFix_2026-03-01.md:12-27`
  - [ ] (@Architect) Lock `lib/features/portfolio/**` as the single portfolio write owner; profile/public-profile become consumers only. File References: `.TODO/PLAN_CRITIC_PortfolioFix_2026-03-01.md:29-41`
  - [ ] (@Architect) Lock `PortfolioScreen` as temporary read-only compatibility surface only; do not keep it as a second owner-manage entry. File References: `.TODO/PLAN_CRITIC_PortfolioFix_2026-03-01.md:43-55`
  - [ ] (@Architect) Lock three PR slices as the rollout strategy. File References: `.TODO/PLAN_CRITIC_PortfolioFix_2026-03-01.md:57-69`
- Result:
  - The plan moves from “possible options” to explicit implementation decisions.
- **Verify (@Sentinel):**
  - all four decisions are written into artifacts before DB/app work starts

### 0.2 Threat Model

- Goal:
  - Convert the identified abuse paths into explicit negative checks.
- Why:
  - This feature crosses authz UX, storage cleanup, and live malformed data handling.
- How:
  - [ ] (@ThreatModeler) Create `.TODO/THREAT_MODEL_Portfolio_2026-03-01.md` covering non-owner mutation attempts, forged owner storage paths, malformed image references, and raw-error disclosure.
  - [ ] (@ThreatModeler) Add negative checks for non-owner add/edit/delete, malformed legacy rows, and arbitrary update-field attempts. File References: `lib/features/portfolio/view/portfolio_screen.dart:107-111`, `lib/features/profile/viewmodels/profile_view_model.dart:301-323`, `lib/features/profile/data/profile_repository.dart:133-139`
- Result:
  - Security and abuse checks become explicit release blockers.
- **Verify (@Sentinel):**
  - every threat case is testable and repeated in Phase 4

### 0.3 Contracts

- Goal:
  - Freeze field-level and DTO-level portfolio contracts before refactor work.
- Why:
  - Current drift is mostly contract drift.
- How:
  - [ ] (@APIContract) Create `.TODO/CONTRACT_Portfolio_2026-03-01.md` defining canonical DB fields, app DTO fields, legacy-read rules, malformed-row behavior, and composite paging cursor semantics.
  - [ ] (@APIContract) Create `.TODO/UI_STATE_MATRIX_Portfolio_2026-03-01.md` for manage/profile/public/standalone loading, empty, error, read-only, legacy-fallback, and delete-partial-failure states.
  - [ ] (@APIContract) Define public-profile DTO replacement plan so `freelancer_profile.dart` stops acting as a second portfolio domain model. File References: `lib/features/profile/models/freelancer_profile.dart:92-128`
- Result:
  - Data shape and UI-state behavior become explicit and shared.
- **Verify (@Sentinel):**
  - contract matches live schema reality and current consumer needs

### 0.4 Migration Plan

- Goal:
  - Make live mixed rows safe to migrate without destructive assumptions.
- Why:
  - Live `image_url` values already include HTTP URLs, path-like values, and malformed rows.
- How:
  - [ ] (@DataMigration) Create `.TODO/MIGRATION_Portfolio_2026-03-01.md` with introduce/backfill/quarantine/enforce stages.
  - [ ] (@DataMigration) Include verify queries for migrated rows, untouched legacy rows, malformed rows, and missing storage objects after backfill.
  - [ ] (@DataMigration) Lock quarantine/manual remediation for malformed `blob:` rows instead of best-effort normalization. File References: `.TODO/PLAN_CRITIC_PortfolioFix_2026-03-01.md:71-83`
- Result:
  - Migration work becomes additive-first and auditable.
- **Verify (@Sentinel):**
  - compatibility window, verify queries, and quarantine branch are all measurable

### 0.5 Rollout Strategy

- Goal:
  - Make the delivery reviewable and rollback-safe.
- Why:
  - DB, architecture, UI, tests, and docs cannot land as one opaque change.
- How:
  - [ ] (@Architect) Create `.TODO/ROLLOUT_Portfolio_2026-03-01.md` with three PR slices:
    - Slice 1: test/contract artifacts + additive migration/RLS restoration
    - Slice 2: app-layer consolidation + pagination + cleanup + error taxonomy
    - Slice 3: UI convergence + tests + docs + release gate
  - [ ] (@Sentinel) Define go/no-go criteria per slice and final release gate.
- Result:
  - Each slice gets explicit review and rollback boundaries.
- **Verify (@Sentinel):**
  - each slice has done criteria and rollback notes

---

## Phase 1: Database & Security

> Primary: @Supabase_Ops

### 1.0 Live Supabase Confirmation (MANDATORY)

- Goal:
  - Reconfirm live DB and storage reality immediately before implementation.
- Why:
  - Repo docs and SQL are already behind live state.
- How:
  - [ ] (@Supabase_Ops) Re-scan `public.portfolio_items`, indexes, policies, bucket `portfolio`, and related storage policies via `@mcp:supabase-mcp-server:`.
  - [ ] (@Supabase_Ops) Recount HTTP/path/malformed row distribution before any migration runs.
  - [ ] (@Supabase_Ops) Confirm no new triggers, functions, or views have appeared since planning.
- Result:
  - Implementation starts from current reality, not stale assumptions.
- **Verify (@Sentinel):**
  - live rescan output is captured in implementation notes

### 1.1 Schema (Additive-first)

- Goal:
  - Introduce canonical image fielding without breaking existing clients during rollout.
- Why:
  - Current `image_url` is overloaded and unsafe as the long-term contract.
- How:
  - [ ] (@Supabase_Ops) Add a migration introducing `public.portfolio_items.image_path text null` without dropping or renaming `image_url`.
  - [ ] (@Supabase_Ops) Keep or improve index support for owner-scoped paging with stable ordering, including `id` as needed for composite cursor behavior.
  - [ ] (@Supabase_Ops) Restore missing versioned SQL for portfolio schema/RLS/storage policy if absent from `supabase/migrations/`.
- Result:
  - Canonical schema support exists while legacy rows remain readable.
- **Verify (@Sentinel):**
  - schema stays additive and compatible with current app until cutover

### 1.2 RLS & Storage Policies

- Goal:
  - Preserve least-privilege semantics and restore repo source-of-truth.
- Why:
  - UI fixes are not enough, and repo migrations are currently unverified.
- How:
  - [ ] (@Supabase_Ops) Create `.TODO/RLS_CHECK_Portfolio_2026-03-01.md` covering allowed/forbidden `select/insert/update/delete` cases for `portfolio_items` and storage owner-path rules for `portfolio`.
  - [ ] (@Supabase_Ops) Snapshot current live policies and mirror them in versioned SQL if missing.
  - [ ] (@ThreatModeler) Validate that owner-only write semantics still hold even if the client tries to pass another `owner_id`.
- Result:
  - Authorization becomes explicit, testable, and repo-backed.
- **Verify (@Sentinel):**
  - positive and negative cases pass against live policy behavior

### 1.3 Migration Execution

- Goal:
  - Backfill safely and keep malformed data visible rather than guessed.
- Why:
  - Live rows are mixed and partially malformed.
- How:
  - [ ] (@DataMigration) Backfill `image_path` only for safely derivable rows.
  - [ ] (@DataMigration) Quarantine malformed rows for manual repair.
  - [ ] (@DataMigration) Keep compatibility reads enabled until post-release verification shows canonical coverage is sufficient.
- Result:
  - Live data moves toward the canonical contract without destructive surprises.
- **Verify (@Sentinel):**
  - migrated, legacy, and malformed row counts match the migration artifact

---

## Phase 2: App Layer (MVVM)

> Primary: @Architect

### 2.1 Models & Mapping

- Goal:
  - Align app models to the canonical contract and replace duplicate DTO ownership.
- Why:
  - Current feature and public-profile models express overlapping domain meaning differently.
- How:
  - [ ] (@Architect) Update `lib/features/portfolio/models/portfolio_item.dart` to expose canonical image reference semantics and stable cursor fields.
  - [ ] (@Architect) Extract or replace nested public-profile portfolio DTOs from `lib/features/profile/models/freelancer_profile.dart`.
  - [ ] (@Architect) Add deterministic mapping for canonical, legacy, and malformed image references.
- Result:
  - One domain contract exists across owner and public portfolio reads.
- **Verify (@Sentinel):**
  - model fields, nullability, and fallback behavior match `.TODO/CONTRACT_Portfolio_2026-03-01.md`

### 2.2 Services & Repositories

- Goal:
  - Collapse duplicated write ownership and make data operations deterministic.
- Why:
  - Current duplication is the main source of behavioral drift.
- How:
  - [ ] (@Architect) Make `lib/features/portfolio/data/portfolio_repository.dart` the only write owner for portfolio CRUD.
  - [ ] (@Architect) Remove or deprecate portfolio CRUD/upload/delete methods from `lib/features/profile/data/profile_repository.dart` after migrating consumers.
  - [ ] (@Architect) Create `lib/features/portfolio/services/portfolio_image_service.dart` for upload, compatibility parsing, path resolution, and delete cleanup.
  - [ ] (@Architect) Replace current client-filtered paging with server-safe composite cursor logic in the feature service/repository layer.
  - [ ] (@Architect) Remove raw `Map<String, dynamic>` update surfaces in favor of typed update inputs.
- Result:
  - One repository/service path owns CRUD, upload, paging, and cleanup behavior.
- **Verify (@Sentinel):**
  - grep checks show one write owner and no raw update-map path remains

### 2.3 ViewModels

- Goal:
  - Make state ownership explicit and remove UI-coupled mutation logic.
- Why:
  - Current owner-manage logic is split between `ProfileViewModel` and `PortfolioViewModel`.
- How:
  - [ ] (@Architect) Refactor `PortfolioViewModel` so owner vs read-only mode is explicit and non-owner mutation calls never leave the VM.
  - [ ] (@Architect) Move active owner portfolio orchestration out of `ProfileViewModel` or convert it to pure delegation into the canonical portfolio path.
  - [ ] (@Architect) Replace raw exception propagation with mapped English error states.
- Result:
  - Portfolio state machine becomes explicit, testable, and MVVM-safe.
- **Verify (@Sentinel):**
  - viewmodel tests cover owner, non-owner, legacy-image, and delete-failure paths

### 2.4 Observability

- Goal:
  - Make migration and cleanup anomalies diagnosable without leaking sensitive details.
- Why:
  - Compatibility rollout needs operational visibility.
- How:
  - [ ] (@Observability) Create `.TODO/OBSERVABILITY_Portfolio_2026-03-01.md` listing required events for blocked non-owner mutation, cleanup failure, malformed legacy row encountered, and paging anomaly.
  - [ ] (@Architect) Instrument only repositories/services/viewmodels and redact raw storage paths and backend error strings from user-visible outputs.
- Result:
  - Operational issues can be triaged during rollout.
- **Verify (@Sentinel):**
  - telemetry is useful and privacy-safe

---

## Phase 3: UI Wiring

> Primary: @Pixel

### 3.1 Active Manage Flow

- Goal:
  - Keep the active owner-manage flow while removing unsafe and brittle behavior.
- Why:
  - `ManagePortfolioScreen` is the actual runtime entry today.
- How:
  - [ ] (@Pixel) Move or wrap `ManagePortfolioScreen` under `lib/features/portfolio/view/` while keeping import compatibility for the settings entry during rollout.
  - [ ] (@Pixel) Add explicit handling for save/delete failures and stop silent async failure paths in dialog actions. File References: `lib/features/profile/view/manage_portfolio_screen.dart:188-209`, `lib/features/profile/view/manage_portfolio_screen.dart:234-238`
  - [ ] (@Pixel) Use the shared portfolio image renderer and canonical ViewModel outputs only.
- Result:
  - The active owner-manage screen becomes the supported portfolio UI surface.
- **Verify (@Sentinel):**
  - add/edit/delete flows have stable states and selectors

### 3.2 Owner Preview & Public Profile

- Goal:
  - Remove placeholder-only public rendering and align owner/public displays.
- Why:
  - The current public-profile portfolio is not rendering the actual portfolio contract.
- How:
  - [ ] (@Pixel) Replace synthetic color/category cards with contract-backed portfolio rendering in `PublicProfilePortfolio`.
  - [ ] (@Pixel) Align owner preview in `ProfileScreen` and public profile rendering with the shared image component and DTO mapping.
- Result:
  - Public and owner surfaces show the same underlying portfolio data.
- **Verify (@Sentinel):**
  - parity checks pass across manage/profile/public screens

### 3.3 Standalone PortfolioScreen

- Goal:
  - Neutralize the current authz and DI risk without assuming immediate removal.
- Why:
  - `PortfolioScreen` still exists and is not verified as unreachable.
- How:
  - [ ] (@Pixel) Remove direct `SupabaseClient` construction from the view and move to provider-based composition.
  - [ ] (@Pixel) Enforce read-only mode when viewing another owner and remove raw error rendering/snackbars.
  - [ ] (@Architect) Re-verify route usage after refactor; if still unused, schedule deprecation in a follow-up cleanup slice.
- Result:
  - The standalone surface is no longer a security and architecture liability.
- **Verify (@Sentinel):**
  - non-owner UI cannot trigger mutation flows and no raw backend error text remains

---

## Phase 4: QA + Release

> Primary: @Sentinel

### 4.1 Automated Verification

- Goal:
  - Prove the contract, migration, and UI behavior are stable.
- Why:
  - This fix crosses DB, storage, app state, and UI.
- How:
  - [ ] (@Sentinel) Add unit tests for pagination cursor behavior, compatibility mapping, delete cleanup, and read-only mutation blocking.
  - [ ] (@Sentinel) Add widget tests for manage dialog states, owner/public rendering parity, and standalone read-only behavior.
  - [ ] (@Sentinel) Add integration/manual role-based checks using `.TODO/FIXTURES_Portfolio_2026-03-01.md` and the preflight contract if integration automation is introduced.
- Result:
  - The highest-risk paths have automated and repeatable coverage.
- **Verify (@Sentinel):**
  - required unit/widget checks pass and any integration/manual checks are documented with evidence

### 4.2 Live Verification

- Goal:
  - Validate post-change behavior against live Supabase reality.
- Why:
  - Repo docs and SQL started behind live state.
- How:
  - [ ] (@Sentinel) Run live verify queries for migrated, legacy, and malformed rows.
  - [ ] (@Sentinel) Re-run RLS/storage positive and negative checks from `.TODO/RLS_CHECK_Portfolio_2026-03-01.md`.
  - [ ] (@Sentinel) Validate no gaps/duplicates in large pagination windows.
- Result:
  - Release is backed by live evidence, not code-only confidence.
- **Verify (@Sentinel):**
  - SQL/live-object evidence is attached to the release checklist

### 4.3 Delivery Slices

- Goal:
  - Ship the remediation in reviewable, rollback-safe increments.
- Why:
  - The scope is too broad for one opaque change.
- How:
  - [ ] (@Architect) Slice 1: artifacts + additive migration + RLS/storage SQL restoration.
  - [ ] (@Architect) Slice 2: repository/service/viewmodel consolidation + paging + cleanup + error mapping.
  - [ ] (@Architect) Slice 3: UI convergence + tests + docs + final release gate.
- Result:
  - Each slice has explicit review and rollback boundaries.
- **Verify (@Sentinel):**
  - each slice meets done criteria before the next begins

---

## Phase 5: Documentation Sync

> Primary: @DocsKeeper

- Goal:
  - Prevent the same portfolio drift from reappearing in docs.
- Why:
  - Current docs already conflict on storage semantics and bucket history.
- How:
  - [ ] (@DocsKeeper) Update `Sline_everything/DEVELOPER_GUIDE.md` to reflect canonical `image_path` persistence, shared portfolio ownership under `lib/features/portfolio/**`, and final public-profile DTO contract.
  - [ ] (@DocsKeeper) Update `Sline_everything/SUPABASE_SETUP.md` with final portfolio schema, index, and policy source-of-truth.
  - [ ] (@DocsKeeper) Update `Sline_everything/STRUCTURE.md` and feature inventory docs if files move.
  - [ ] (@DocsKeeper) Reconcile `Sline_everything/Sline_Log.md` if it still contradicts final bucket reality.
- Result:
  - Docs match code plus live DB reality after rollout.
- **Verify (@Sentinel):**
  - final docs review passes only after post-change live rescan

## 7) Acceptance Criteria (MANDATORY)

- Portfolio writes are owned by one repository/service path under `lib/features/portfolio/**`. File References: `lib/features/portfolio/data/portfolio_repository.dart:8-68`, `lib/features/profile/data/profile_repository.dart:109-162`
- Canonical persisted image data is a storage path, with compatibility reads only for legacy rows during the migration window.
- Non-owner views cannot trigger portfolio mutation requests from UI, and RLS still blocks cross-user writes.
- Pagination returns all items beyond the first 100 rows and does not skip equal-timestamp rows.
- Public profile, owner preview, manage, and standalone surfaces render the same contract-backed portfolio data.
- Deleting a portfolio item removes the DB row and resolves cleanup deterministically for canonical and legacy rows, or reports a controlled partial failure.
- Raw backend exception strings are no longer shown directly to users in portfolio flows.
- Repo migrations contain portfolio schema/RLS/storage policy source-of-truth or an idempotent recreation of it.
- Tests and live verify queries provide evidence for paging, compatibility reads, delete cleanup, read-only behavior, and docs parity.

## 8) Rollback Plan

- DB rollback/forward-fix:
  - Keep the schema additive. If rollout fails, stop writing canonical `image_path` and continue compatibility reads from legacy `image_url`; do not drop canonical fields in the first rollback window.
  - If migration verification fails, halt enforcement and keep quarantine/manual remediation for malformed rows.
- App rollback:
  - Because Slice 2 and Slice 3 are separated, revert app-layer consolidation or UI convergence independently if needed.
  - Keep compatibility wrapper for `ManagePortfolioScreen` route/import stability during rollout.
- Emergency safety:
  - If runtime correctness is questionable, disable new owner edits/uploads while preserving read-only portfolio rendering until the issue is resolved.

## 9) References (From Scan)

- `.TODO/protfolio.TODO.md:1-354`
- `.TODO/PLAN_CRITIC_PortfolioFix_2026-03-01.md:1-287`
- `.TODO/CodexRefactor/01_FEATURES_INDEX.md:768-823`
- `test/test_support/pump_app.dart:5-18`
- `integration_test/support/preflight.dart:5-57`
- `lib/main.dart:136-191`
- `lib/core/widgets/signed_image.dart:25-201`
- `lib/features/portfolio/models/portfolio_item.dart:5-68`
- `lib/features/portfolio/services/portfolio_service.dart:12-149`
- `lib/features/portfolio/data/portfolio_repository.dart:8-68`
- `lib/features/portfolio/viewmodels/portfolio_view_model.dart:8-193`
- `lib/features/portfolio/view/portfolio_screen.dart:13-243`
- `lib/features/profile/data/profile_repository.dart:109-227`
- `lib/features/profile/viewmodels/profile_view_model.dart:185-323`
- `lib/features/profile/viewmodels/public_profile_view_model.dart:19-37`
- `lib/features/profile/viewmodels/user_profile_view_model.dart:8-108`
- `lib/features/profile/view/settings_screen.dart:85-99`
- `lib/features/profile/view/manage_portfolio_screen.dart:18-422`
- `lib/features/profile/view/profile_screen.dart:309-390`
- `lib/features/profile/view/public_profile_screen.dart:61-68`
- `lib/features/profile/view/public_profile_screen.dart:280-291`
- `lib/features/profile/models/freelancer_profile.dart:92-142`
- `lib/features/profile/view/widgets/public_profile/public_profile_portfolio.dart:9-167`
- `Sline_everything/DEVELOPER_GUIDE.md:53-79`
- `Sline_everything/DEVELOPER_GUIDE.md:383-552`
- `Sline_everything/SUPABASE_SETUP.md:689-722`
- `Sline_everything/SUPABASE_SETUP.md:1133-1142`
- `Sline_everything/SUPABASE_SETUP.md:1575-1588`
- `Sline_everything/CODE_REVIEW.md:371-374`
- `Sline_everything/STRUCTURE.md`
- `Sline_everything/Sline_Log.md:1042-1046`
- Live Supabase scan evidence from `@mcp:supabase-mcp-server:` on 2026-03-01 for `public.portfolio_items`, `pg_policies`, `pg_indexes`, `storage.buckets`, `storage.objects` policies, and mixed-value row counts.
