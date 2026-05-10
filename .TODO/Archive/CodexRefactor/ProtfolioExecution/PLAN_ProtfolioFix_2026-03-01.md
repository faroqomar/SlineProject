# 📌 Plan: Portfolio Feature Recovery

## 1) Goal

- Goal: Replace the current split portfolio implementation with one MVVM-safe, additive-first portfolio flow that closes authorization UX gaps, fixes pagination/data drift, normalizes image storage semantics, and restores versioned Supabase source-of-truth. File References: `.TODO/protfolio.TODO.md:1-244`, `lib/features/portfolio/view/portfolio_screen.dart:13-243`, `lib/features/profile/view/manage_portfolio_screen.dart:18-422`, `lib/features/profile/data/profile_repository.dart:109-227`
- Why: The current repo has two portfolio CRUD stacks with already-diverged behavior around image upload/delete/rendering, direct view-level Supabase wiring, and correctness bugs in paging and cleanup. File References: `.TODO/protfolio.TODO.md:75-244`, `lib/features/portfolio/services/portfolio_service.dart:20-149`, `lib/features/profile/data/profile_repository.dart:109-162`, `lib/features/portfolio/view/portfolio_screen.dart:74-79`
- Result: One canonical portfolio contract, one write path, live-schema-compatible migration steps, verified RLS/storage policy coverage, and test/documentation coverage that matches the current repo and live Supabase reality. File References: `Sline_everything/DEVELOPER_GUIDE.md:383-429`, `Sline_everything/SUPABASE_SETUP.md:689-722`, `Sline_everything/SUPABASE_SETUP.md:1133-1142`, `.TODO/protfolio.TODO.md:211-244`

## 2) Scope

### In-Scope

- Portfolio feature module: `lib/features/portfolio/**`. File References: `.TODO/CodexRefactor/01_FEATURES_INDEX.md:768-789`, `lib/features/portfolio/view/portfolio_screen.dart:13-243`, `lib/features/portfolio/viewmodels/portfolio_view_model.dart:8-193`, `lib/features/portfolio/data/portfolio_repository.dart:8-68`, `lib/features/portfolio/services/portfolio_service.dart:12-149`
- Direct portfolio dependencies in profile/public-profile flows. File References: `lib/features/profile/view/settings_screen.dart:85-99`, `lib/features/profile/view/manage_portfolio_screen.dart:18-422`, `lib/features/profile/view/profile_screen.dart:309-390`, `lib/features/profile/view/public_profile_screen.dart:61-68`, `lib/features/profile/view/public_profile_screen.dart:280-291`, `lib/features/profile/viewmodels/profile_view_model.dart:142-281`, `lib/features/profile/viewmodels/public_profile_view_model.dart:19-37`, `lib/features/profile/data/profile_repository.dart:109-227`, `lib/features/profile/models/freelancer_profile.dart:92-142`, `lib/features/profile/view/widgets/public_profile/public_profile_portfolio.dart:9-167`
- Shared image/rendering primitives touched by portfolio flows. File References: `lib/core/widgets/signed_image.dart:25-201`
- Supabase objects directly touched by portfolio flows: `public.portfolio_items`, `storage.objects` for bucket `portfolio`, and public-profile reads that join portfolio data with `profiles` and `tasks`. File References: `lib/features/portfolio/services/portfolio_service.dart:17-18`, `lib/features/profile/data/profile_repository.dart:164-227`, `Sline_everything/SUPABASE_SETUP.md:689-722`, `Sline_everything/SUPABASE_SETUP.md:1133-1142`, `Sline_everything/SUPABASE_SETUP.md:1575-1588`

### Out-of-Scope

- Deep redesign of unrelated `profiles` editing, task feeds, or task history beyond the direct public-profile data path already reading portfolio data. File References: `lib/features/profile/data/profile_repository.dart:164-227`
- Realtime and Edge Function work unless a later live rescan proves portfolio uses them; current audited slice has no verified usage. UNVERIFIED: absence-based search only. File Reference: `.TODO/protfolio.TODO.md:35-38`
- Broad app-wide provider refactors outside the portfolio/public-profile path. File References: `lib/main.dart:136-191`

## 3) Evidence & Findings (From Scan)

### Existing

- The active manage entry point is `SettingsScreen -> ManagePortfolioScreen`, not the standalone `PortfolioScreen`. File References: `lib/features/profile/view/settings_screen.dart:85-99`, `lib/features/profile/view/manage_portfolio_screen.dart:18-422`
- Public profile rendering currently flows through `PublicProfileViewModel -> ProfileRepository.getPublicProfile() -> PublicProfilePortfolio`. File References: `lib/features/profile/view/public_profile_screen.dart:61-68`, `lib/features/profile/view/public_profile_screen.dart:280-291`, `lib/features/profile/viewmodels/public_profile_view_model.dart:19-37`, `lib/features/profile/data/profile_repository.dart:164-227`
- The repo currently has two portfolio write paths:
  - standalone feature path. File References: `lib/features/portfolio/services/portfolio_service.dart:12-149`, `lib/features/portfolio/data/portfolio_repository.dart:8-68`, `lib/features/portfolio/viewmodels/portfolio_view_model.dart:8-193`
  - profile-owned path. File References: `lib/features/profile/data/profile_repository.dart:109-162`, `lib/features/profile/viewmodels/profile_view_model.dart:142-281`, `lib/features/profile/view/manage_portfolio_screen.dart:18-422`
- The documented architecture requires MVVM separation and says views should not reference Supabase directly; current `PortfolioScreen` still constructs a repository from `SupabaseClient` in the view. File References: `Sline_everything/DEVELOPER_GUIDE.md:53-65`, `Sline_everything/CODE_REVIEW.md:234-241`, `lib/features/portfolio/view/portfolio_screen.dart:1-3`, `lib/features/portfolio/view/portfolio_screen.dart:74-79`, `lib/main.dart:176-187`
- The docs describe portfolio storage inconsistently:
  - general storage rule: store paths in DB and generate URLs as needed. File References: `Sline_everything/DEVELOPER_GUIDE.md:65-65`, `Sline_everything/SUPABASE_SETUP.md:115-115`
  - portfolio section: current implementation stores public URL for the public bucket. File References: `Sline_everything/DEVELOPER_GUIDE.md:129-129`, `Sline_everything/DEVELOPER_GUIDE.md:422-429`, `Sline_everything/DEVELOPER_GUIDE.md:552-552`
- Live Supabase scan on 2026-03-01 via `@mcp:supabase-mcp-server:` confirmed:
  - `public.portfolio_items` exists with columns `id`, `owner_id`, `title`, `description`, `image_url`, `created_at`
  - RLS is enabled with owner-write policies and authenticated read policy
  - bucket `portfolio` exists and is public
  - `storage.objects` policies enforce owner-path writes/deletes for `portfolio`
  - live data is mixed: HTTP URLs, raw storage paths, and malformed `blob:`-contaminated values exist in `image_url`
- Must NOT duplicate in the fix:
  - a second portfolio write path beyond one canonical repository/service pair. File References: `lib/features/portfolio/services/portfolio_service.dart:12-149`, `lib/features/profile/data/profile_repository.dart:109-162`
  - a second public-profile viewmodel path. File References: `lib/features/profile/viewmodels/public_profile_view_model.dart:19-37`, `lib/features/profile/viewmodels/user_profile_view_model.dart:8-108`
  - a third image contract beyond one canonical persisted field plus a temporary compatibility reader. File References: `lib/features/portfolio/services/portfolio_service.dart:50-79`, `lib/features/profile/data/profile_repository.dart:145-162`, `lib/core/widgets/signed_image.dart:66-121`

### Missing

- Versioned migration SQL for current portfolio schema/RLS/storage policy is not verified in `supabase/migrations`. UNVERIFIED: absence-based repo scan; docs describe intended SQL but current migration files were not evidenced. File References: `Sline_everything/SUPABASE_SETUP.md:1133-1142`, `Sline_everything/SUPABASE_SETUP.md:1575-1588`, `.TODO/protfolio.TODO.md:95-103`
- Portfolio-specific tests are missing from `test/` and `integration_test/`. UNVERIFIED: absence-based repo scan only. File Reference: `.TODO/protfolio.TODO.md:163-171`
- There is no verified contract file for portfolio item shape, image persistence semantics, or paging cursor semantics. File References: `.TODO/protfolio.TODO.md:187-244`
- There is no verified threat model or RLS check matrix artifact for portfolio. File References: `.TODO/protfolio.TODO.md:75-103`, `.TODO/protfolio.TODO.md:211-244`

### Conflicts / Risks (docs vs code vs live DB drift, naming mismatches, security/migration risks)

- The active UI path is under `profile`, while the declared feature boundary is `portfolio`; fixing only one side will keep the drift alive. File References: `.TODO/CodexRefactor/01_FEATURES_INDEX.md:768-823`, `lib/features/profile/view/settings_screen.dart:85-99`, `lib/features/portfolio/view/portfolio_screen.dart:13-243`
- `PortfolioScreen` exposes mutation affordances for non-owners and relies on RLS failures instead of preventing the action in UX. File References: `lib/features/portfolio/view/portfolio_screen.dart:55-72`, `lib/features/portfolio/view/portfolio_screen.dart:107-111`, `lib/features/portfolio/view/sheets/portfolio_details_sheet.dart:81-147`, `lib/features/portfolio/viewmodels/portfolio_view_model.dart:46-54`
- Current pagination can permanently hide older items after the newest 100 rows and can skip same-timestamp rows. File References: `lib/features/portfolio/services/portfolio_service.dart:20-48`
- The mixed `image_url` contract already causes delete/render drift, and live malformed rows mean a naive “rename field in code” rollout will lose data or strand files. File References: `lib/features/portfolio/services/portfolio_service.dart:50-79`, `lib/features/portfolio/services/portfolio_service.dart:116-148`, `lib/features/profile/data/profile_repository.dart:119-162`, `lib/core/widgets/signed_image.dart:66-121`
- Public-profile DTOs and widgets currently discard real image semantics and synthesize display-only fields, so a shared contract is not yet in place. File References: `lib/features/profile/models/freelancer_profile.dart:92-128`, `lib/features/profile/view/widgets/public_profile/public_profile_portfolio.dart:97-166`
- Historical documentation is internally inconsistent about whether the `portfolio` bucket is public or private, so docs must be reconciled against live reality rather than assumed. File References: `Sline_everything/SUPABASE_SETUP.md:1581-1588`, `Sline_everything/Sline_Log.md:1042-1046`

## 4) System Impact Map

- UI:
  - `ManagePortfolioScreen` is the current edit surface. File References: `lib/features/profile/view/manage_portfolio_screen.dart:18-422`
  - `ProfileScreen` shows owner portfolio preview tiles. File References: `lib/features/profile/view/profile_screen.dart:309-390`
  - `PublicProfilePortfolio` renders public profile portfolio cards. File References: `lib/features/profile/view/widgets/public_profile/public_profile_portfolio.dart:9-167`
  - `PortfolioScreen` is a standalone feature surface with current authz UX defects. File References: `lib/features/portfolio/view/portfolio_screen.dart:13-243`
- MVVM/App Logic:
  - portfolio feature VM/repository/service. File References: `lib/features/portfolio/viewmodels/portfolio_view_model.dart:8-193`, `lib/features/portfolio/data/portfolio_repository.dart:8-68`, `lib/features/portfolio/services/portfolio_service.dart:12-149`
  - profile VM/repository duplicate portfolio logic. File References: `lib/features/profile/viewmodels/profile_view_model.dart:142-281`, `lib/features/profile/data/profile_repository.dart:109-227`
  - provider graph already states that views must not reference Supabase directly. File References: `lib/main.dart:176-187`
- Database:
  - `portfolio_items` read/write/delete queries. File References: `lib/features/portfolio/services/portfolio_service.dart:17-48`, `lib/features/portfolio/services/portfolio_service.dart:102-132`, `lib/features/profile/data/profile_repository.dart:110-143`
  - public-profile aggregate reads from `profiles`, `portfolio_items`, `tasks`. File References: `lib/features/profile/data/profile_repository.dart:164-227`
- RLS/Security:
  - portfolio policies are documented in docs and confirmed live, but repo migrations are unverified. File References: `Sline_everything/DEVELOPER_GUIDE.md:396-422`, `Sline_everything/SUPABASE_SETUP.md:1133-1142`
- Realtime/Notifications (if any):
  - none verified in the audited slice. UNVERIFIED: absence-based search only. File Reference: `.TODO/protfolio.TODO.md:35-38`
- Storage:
  - `portfolio` bucket upload/delete/render flows are split today. File References: `lib/features/portfolio/services/portfolio_service.dart:67-79`, `lib/features/portfolio/services/portfolio_service.dart:136-143`, `lib/features/profile/data/profile_repository.dart:145-162`, `lib/core/widgets/signed_image.dart:66-121`
- Observability (if any):
  - no portfolio-specific instrumentation was evidenced in the audited slice. UNVERIFIED: no verified logging contract or feature event list. File References: `lib/features/portfolio/viewmodels/portfolio_view_model.dart:8-193`, `lib/features/profile/viewmodels/profile_view_model.dart:142-281`
- Compatibility & Migration:
  - live rows already contain mixed legacy formats, and the current column name `image_url` is semantically overloaded. File References: `.TODO/protfolio.TODO.md:109-128`
  - public-profile and owner-profile displays use different DTO/render pipelines. File References: `lib/features/profile/models/freelancer_profile.dart:92-128`, `lib/features/profile/view/profile_screen.dart:346-353`, `lib/features/profile/view/widgets/public_profile/public_profile_portfolio.dart:97-166`
- Contracts:
  - current app contract is duplicated between feature `PortfolioItem` and nested public-profile `PortfolioItem`. File References: `lib/features/portfolio/models/portfolio_item.dart:5-68`, `lib/features/profile/models/freelancer_profile.dart:92-128`

---

# ✅ Execution Phases (Checklist)

## Phase 0: Preconditions & Gates

> Primary: @Sentinel

### 0.1 Spec Lock

- [ ] (@Sentinel) Convert the verified audit in `.TODO/protfolio.TODO.md` into a non-regression checklist covering authz UX, pagination >100, same-timestamp paging, image render compatibility, delete cleanup, and public-profile rendering parity. File Reference: `.TODO/protfolio.TODO.md:75-244`
- [ ] (@Architect) Confirm the implementation boundary: `lib/features/portfolio/**` becomes the single portfolio write owner, while profile/public-profile code becomes consumer-only. File References: `.TODO/CodexRefactor/01_FEATURES_INDEX.md:768-823`, `lib/features/profile/view/manage_portfolio_screen.dart:18-422`, `lib/features/portfolio/services/portfolio_service.dart:12-149`
- [ ] (@Architect) Confirm the canonical persisted image contract before any code change: adopt additive-first `image_path` as the canonical DB field, keep `image_url` as temporary legacy-read compatibility only, and forbid new public-URL writes after cutover. File References: `Sline_everything/DEVELOPER_GUIDE.md:65-65`, `Sline_everything/DEVELOPER_GUIDE.md:129-129`, `lib/features/portfolio/services/portfolio_service.dart:67-79`, `lib/features/profile/data/profile_repository.dart:145-162`
- **Verify (@Sentinel):** done-conditions and rollback triggers are written before implementation starts, and each condition maps to a concrete file or live-object check.

### 0.2 Threat Model (If sensitive/high-risk)

- [ ] (@ThreatModeler) Create `.TODO/portfolio_threat_model_2026-03-01.md` covering cross-user mutation attempts, cross-user storage delete attempts, malformed legacy image references, public bucket abuse assumptions, and error-message disclosure paths. File References: `lib/features/portfolio/view/portfolio_screen.dart:107-111`, `lib/features/portfolio/view/sheets/portfolio_details_sheet.dart:81-147`, `lib/features/profile/data/profile_repository.dart:133-143`, `lib/features/portfolio/view/sheets/add_portfolio_sheet.dart:49-54`
- [ ] (@ThreatModeler) Define negative checks for owner mismatch, arbitrary update keys, orphaned storage objects, and legacy `blob:` values that must fail safely without app crashes or silent data loss. File References: `lib/features/profile/data/profile_repository.dart:133-139`, `lib/features/portfolio/services/portfolio_service.dart:116-148`, `.TODO/protfolio.TODO.md:109-128`
- **Verify (@Sentinel):** threat cases are testable and are explicitly covered again in Phase 4.

### 0.3 Contracts (If payloads change)

- [ ] (@APIContract) Create `.TODO/portfolio_contract_2026-03-01.md` defining:
  - canonical DB fields: `id`, `owner_id`, `title`, `description`, `image_path`, `created_at`
  - legacy-read fallback: `image_url`
  - app DTO fields and nullability
  - composite paging cursor contract (`created_at`, `id`)
  - delete semantics for DB row plus storage object. File References: `lib/features/portfolio/models/portfolio_item.dart:5-68`, `lib/features/profile/models/freelancer_profile.dart:92-128`, `lib/features/portfolio/services/portfolio_service.dart:20-48`, `lib/features/portfolio/services/portfolio_service.dart:116-148`
- [ ] (@APIContract) Define the public-profile read contract so `PublicProfilePortfolio` consumes a dedicated DTO instead of the nested placeholder `PortfolioItem`. File References: `lib/features/profile/models/freelancer_profile.dart:92-128`, `lib/features/profile/view/widgets/public_profile/public_profile_portfolio.dart:97-166`
- **Verify (@Sentinel):** the contract matches both the live schema rescan and the Flutter model shapes before coding starts.

### 0.4 Migration Plan (If schema/data changes)

- [ ] (@DataMigration) Create `.TODO/portfolio_migration_plan_2026-03-01.md` with an additive-first sequence:
  - introduce nullable `image_path`
  - backfill parsable legacy values from `image_url`
  - isolate malformed `blob:` rows for manual remediation
  - keep compatibility reads during the window
  - switch new writes to `image_path`
  - enforce and later deprecate legacy writes only after verification. File References: `.TODO/protfolio.TODO.md:109-128`, `lib/features/portfolio/services/portfolio_service.dart:67-79`, `lib/features/profile/data/profile_repository.dart:145-162`
- [ ] (@DataMigration) Include verify queries for counts by format, unparsable legacy rows, and any rows whose storage object is missing after backfill. File References: `.TODO/protfolio.TODO.md:109-128`
- **Verify (@Sentinel):** the compatibility window, forward-fix path, and manual-remediation branch for malformed rows are measurable and explicit.

### 0.5 Feature Flag/Rollout (If risky)

- [ ] (@Architect) Keep a one-release compatibility wrapper at `lib/features/profile/view/manage_portfolio_screen.dart` if the active screen is moved into `lib/features/portfolio/view/manage_portfolio_screen.dart`, so the settings route import stays stable during rollout. File References: `lib/features/profile/view/settings_screen.dart:85-99`, `.TODO/protfolio.TODO.md:187-207`
- [ ] (@Architect) Decide whether the new canonical image contract needs a temporary runtime fallback path in the repository/service layer; do not add a broad app-wide flag unless the live rescan shows unexpected schema drift. File References: `lib/features/portfolio/services/portfolio_service.dart:12-149`, `lib/features/profile/data/profile_repository.dart:109-162`
- **Verify (@Sentinel):** rollback can revert to compatibility reads without DB drops or route breakage.

---

## Phase 1: Database & Security (If applicable)

> Primary: @Supabase_Ops

### 1.0 Live Supabase Confirmation (MANDATORY)

- [ ] (@Supabase_Ops) Re-scan `public.portfolio_items`, `storage.objects` policies for bucket `portfolio`, indexes, views, and any touched routines using `@mcp:supabase-mcp-server:` immediately before implementation. File References: `Sline_everything/SUPABASE_SETUP.md:689-722`, `Sline_everything/SUPABASE_SETUP.md:1133-1142`, `Sline_everything/SUPABASE_SETUP.md:1575-1588`
- [ ] (@Supabase_Ops) Snapshot the live policy names and current column list into the implementation notes so repo migrations can be written to match reality instead of outdated docs. File References: `Sline_everything/SUPABASE_SETUP.md:1133-1142`, `Sline_everything/Sline_Log.md:1042-1046`
- **Verify (@Sentinel):** any drift between docs, repo SQL, and live objects is recorded before DDL changes begin.

### 1.1 Schema (Additive-first)

- [ ] (@Supabase_Ops) Add an additive migration that introduces `public.portfolio_items.image_path text null` without dropping or renaming `image_url`, and preserve existing `idx_portfolio_owner_created` behavior or replace it only with an equivalent or better composite index supporting `(owner_id, created_at desc, id desc)`. File References: `Sline_everything/SUPABASE_SETUP.md:689-722`, `Sline_everything/SUPABASE_SETUP.md:1575-1575`, `lib/features/portfolio/services/portfolio_service.dart:20-48`
- [ ] (@Supabase_Ops) Add a migration that backfills `image_path` from valid legacy `image_url` values and leaves malformed legacy rows explicitly untouched for manual remediation rather than guessing. File References: `.TODO/protfolio.TODO.md:109-128`
- [ ] (@Supabase_Ops) Restore missing versioned SQL for `portfolio_items` and storage policies if the live rescan confirms they are not represented in `supabase/migrations`. UNVERIFIED current repo migration state. File References: `Sline_everything/SUPABASE_SETUP.md:1133-1142`, `Sline_everything/SUPABASE_SETUP.md:1581-1588`
- **Verify (@Sentinel):** all schema changes are additive-first, idempotent where possible, and safe against live data with mixed legacy formats.

### 1.2 RLS

- [ ] (@Supabase_Ops) Preserve least-privilege owner-write policies for `portfolio_items` and public/authenticated read behavior exactly as intended by product, and export the verified policies into repo migrations if absent. File References: `Sline_everything/DEVELOPER_GUIDE.md:415-422`, `Sline_everything/SUPABASE_SETUP.md:1133-1142`
- [ ] (@Supabase_Ops) Create `.TODO/portfolio_rls_check_matrix_2026-03-01.md` covering owner create/update/delete, non-owner mutation denial, and storage path ownership checks for `portfolio`. File References: `Sline_everything/SUPABASE_SETUP.md:1581-1588`, `.TODO/protfolio.TODO.md:75-103`
- **Verify (@Sentinel):** positive cases pass, negative cases fail, and no policy depends on client-side guards for correctness.

### 1.3 Triggers/RPC (If needed)

- [ ] (@Supabase_Ops) Do not introduce new RPC or trigger logic unless the service layer cannot express the composite paging cursor or cleanup guarantees safely through standard queries; if a server-side helper becomes necessary, scope it narrowly to portfolio paging or deterministic cleanup only. File References: `lib/features/portfolio/services/portfolio_service.dart:20-48`, `lib/features/portfolio/services/portfolio_service.dart:116-148`
- [ ] (@APIContract) If an RPC is introduced, add it to `.TODO/portfolio_contract_2026-03-01.md` with exact request/response shapes and failure cases before Flutter code changes. File References: `.TODO/protfolio.TODO.md:187-244`
- **Verify (@Sentinel):** state rules remain deterministic and idempotent, and new server-side surfaces are documented before use.

### 1.4 Migration Execution (If needed)

- [ ] (@DataMigration) Run the introduce/backfill steps in sequence, produce before/after counts for legacy URL rows, path rows, and malformed rows, and keep legacy reads enabled until the malformed set is either remediated or explicitly accepted. File References: `.TODO/protfolio.TODO.md:109-128`
- [ ] (@DataMigration) Validate that delete flows still resolve the correct storage object path after backfill for both old and new rows. File References: `lib/features/portfolio/services/portfolio_service.dart:116-148`, `lib/features/profile/data/profile_repository.dart:141-162`
- **Verify (@Sentinel):** verify queries pass, legacy rows still render or fail gracefully, and no storage objects are silently orphaned by the migration itself.

---

## Phase 2: App Layer (MVVM)

> Primary: @Architect

### 2.1 Models & Contract Compliance

- [ ] (@Architect) Update the portfolio domain model to follow the agreed contract: canonical `imagePath` in app code, optional legacy-read support only in mapping, and a composite paging cursor model instead of timestamp-only state. File References: `lib/features/portfolio/models/portfolio_item.dart:5-68`, `lib/features/portfolio/viewmodels/portfolio_view_model.dart:17-21`, `lib/features/portfolio/services/portfolio_service.dart:20-48`
- [ ] (@Architect) Extract public-profile DTOs from `lib/features/profile/models/freelancer_profile.dart` into dedicated files so public portfolio items are explicitly typed and no longer collide with the feature `PortfolioItem`. File References: `lib/features/profile/models/freelancer_profile.dart:92-142`
- [ ] (@Architect) Normalize error mapping so the app exposes stable English portfolio error messages and keeps raw exception text out of UI. File References: `lib/features/portfolio/view/sheets/add_portfolio_sheet.dart:49-54`, `lib/features/profile/viewmodels/profile_view_model.dart:224-231`
- **Verify (@Sentinel):** model nullability, field naming, and error states match the contract and the live schema rescan.

### 2.2 Services/Repositories

- [ ] (@Architect) Make `lib/features/portfolio/data/portfolio_repository.dart` the single portfolio write/read owner, and remove portfolio CRUD methods from `lib/features/profile/data/profile_repository.dart` after consumers are migrated. File References: `lib/features/portfolio/data/portfolio_repository.dart:8-68`, `lib/features/profile/data/profile_repository.dart:109-162`
- [ ] (@Architect) Create `lib/features/portfolio/services/portfolio_image_service.dart` to centralize upload, legacy URL parsing, path resolution, and delete cleanup so both owner and public flows share one image rule. File References: `lib/features/portfolio/services/portfolio_service.dart:67-79`, `lib/features/portfolio/services/portfolio_service.dart:116-148`, `lib/features/profile/data/profile_repository.dart:145-162`
- [ ] (@Architect) Split read-only public profile aggregation into `lib/features/profile/data/public_profile_repository.dart` so `ProfileRepository` no longer mixes mutable profile concerns with public-profile composition. File References: `lib/features/profile/data/profile_repository.dart:164-227`, `lib/features/profile/viewmodels/public_profile_view_model.dart:19-37`
- [ ] (@Architect) Enforce the storage rule in code: new writes persist path only, renderer/service derives public or signed URL at display time, and delete always works from path. File References: `Sline_everything/DEVELOPER_GUIDE.md:65-65`, `Sline_everything/CODE_REVIEW.md:374-374`, `lib/core/widgets/signed_image.dart:66-121`
- [ ] (@Architect) Fix paging in the service layer with server-side filters and a stable composite cursor; do not keep the current “fetch 100 newest then client-filter” approach. File References: `lib/features/portfolio/services/portfolio_service.dart:20-48`
- **Verify (@Sentinel):** there are no UI-to-Supabase calls, no raw update maps, no duplicate write paths, and service behavior is compatible with both legacy and canonical rows during rollout.

### 2.3 ViewModels

- [ ] (@Architect) Remove portfolio CRUD/upload responsibilities from `ProfileViewModel` and move owner portfolio management into a dedicated portfolio feature VM that exposes explicit state, loading, and failure modes. File References: `lib/features/profile/viewmodels/profile_view_model.dart:142-281`, `lib/features/portfolio/viewmodels/portfolio_view_model.dart:8-193`
- [ ] (@Architect) Add owner/read-only mode awareness to the portfolio VM so non-owner screens cannot emit mutation requests even before RLS denies them. File References: `lib/features/portfolio/viewmodels/portfolio_view_model.dart:46-54`, `lib/features/portfolio/view/portfolio_screen.dart:107-111`
- [ ] (@Architect) Collapse duplicate public-profile VM paths by keeping `PublicProfileViewModel` as the canonical entry and deleting or merging `UserProfileViewModel` only after usage is rechecked. File References: `lib/features/profile/viewmodels/public_profile_view_model.dart:19-37`, `lib/features/profile/viewmodels/user_profile_view_model.dart:8-108`
- **Verify (@Sentinel):** state transitions are recoverable, mutation methods are explicit, and only one VM owns each portfolio workflow.

### 2.4 Observability (If needed)

- [ ] (@Observability) Create `.TODO/portfolio_observability_2026-03-01.md` listing sanitized events for upload started/succeeded/failed, create/update/delete failed, migration compatibility fallback used, and malformed legacy row encountered. File References: `lib/features/portfolio/viewmodels/portfolio_view_model.dart:115-193`, `lib/features/profile/viewmodels/profile_view_model.dart:166-281`
- [ ] (@Architect) Instrument only repositories/services/viewmodels, not widgets, and redact storage paths or policy names from any user-visible or analytics-facing payloads. File References: `lib/features/portfolio/view/sheets/add_portfolio_sheet.dart:49-54`, `lib/features/profile/viewmodels/profile_view_model.dart:224-231`
- **Verify (@Sentinel):** telemetry is useful for rollout diagnosis and does not leak object paths, policy names, or raw backend errors.

---

## Phase 3: UI (After logic)

> Primary: @Pixel

### 3.1 Wiring

- [ ] (@Pixel) Move the active owner manage screen to `lib/features/portfolio/view/manage_portfolio_screen.dart` and keep `lib/features/profile/view/manage_portfolio_screen.dart` as a temporary wrapper import if needed during rollout. File References: `lib/features/profile/view/manage_portfolio_screen.dart:18-422`, `lib/features/profile/view/settings_screen.dart:85-99`
- [ ] (@Pixel) Replace direct `SupabaseClient` construction in `PortfolioScreen` with provider-based VM wiring so the view consumes only a ViewModel. File References: `lib/features/portfolio/view/portfolio_screen.dart:1-3`, `lib/features/portfolio/view/portfolio_screen.dart:74-79`, `lib/main.dart:176-187`
- [ ] (@Pixel) Hide add/edit/delete affordances for non-owners in all portfolio surfaces and show stable empty/loading/error states instead of backend exception text. File References: `lib/features/portfolio/view/portfolio_screen.dart:107-111`, `lib/features/portfolio/view/sheets/portfolio_details_sheet.dart:81-147`, `lib/features/profile/view/manage_portfolio_screen.dart:183-245`
- [ ] (@Pixel) Create a shared `lib/features/portfolio/view/widgets/portfolio_image.dart` and use it across owner preview, standalone cards, detail sheet, and public profile so image rendering and fallback behavior is consistent. File References: `lib/features/portfolio/view/widgets/portfolio_tile.dart:35-47`, `lib/features/portfolio/view/sheets/portfolio_details_sheet.dart:57-61`, `lib/features/profile/view/profile_screen.dart:346-353`, `lib/features/profile/view/widgets/public_profile/public_profile_portfolio.dart:97-166`
- [ ] (@Pixel) Update public-profile portfolio cards to render actual portfolio image/title/description contract data rather than synthetic color/category placeholders. File References: `lib/features/profile/models/freelancer_profile.dart:109-127`, `lib/features/profile/view/widgets/public_profile/public_profile_portfolio.dart:97-166`
- **Verify (@Sentinel):** the UI stays stable with slow network, empty lists, legacy rows without valid images, and read-only non-owner views.

### 3.2 Polish (Optional)

- [ ] (@Pixel) Narrow rebuild scope in `PortfolioScreen` and avoid full-screen rebuilds on every state change. File References: `lib/features/portfolio/view/portfolio_screen.dart:76-116`
- [ ] (@Pixel) Replace eager public-profile masonry construction with a lazy or cheaper layout only after correctness work lands; do not change visual structure before contract parity is working. File References: `lib/features/profile/view/widgets/public_profile/public_profile_portfolio.dart:45-80`
- [ ] (@Pixel) Keep image upload compression/progress behavior consistent between owner flows after the shared image service is in place. File References: `lib/features/portfolio/view/sheets/add_portfolio_sheet.dart:33-49`, `lib/features/profile/viewmodels/profile_view_model.dart:195-223`
- **Verify (@Sentinel):** optional polish introduces no new paging, upload, or rendering regressions.

---

## Phase 4: QA + Security (MANDATORY)

> Primary: @Sentinel

### 4.1 Contract + Migration Checks

- [ ] (@Sentinel) Run `flutter analyze` and targeted `flutter test` suites for portfolio repository, VM, public-profile DTO mapping, and widget rendering after contract changes land. File References: `.TODO/protfolio.TODO.md:163-171`
- [ ] (@Sentinel) Execute migration verify queries for:
  - rows with `image_path is null and image_url is not null`
  - malformed legacy values remaining
  - duplicate or missing items across pagination windows
  - any rows whose storage object path does not resolve. File References: `.TODO/protfolio.TODO.md:109-128`, `lib/features/portfolio/services/portfolio_service.dart:20-48`
- [ ] (@Sentinel) Compare live policy state after migration against `.TODO/portfolio_rls_check_matrix_2026-03-01.md`. File References: `Sline_everything/SUPABASE_SETUP.md:1133-1142`, `Sline_everything/SUPABASE_SETUP.md:1581-1588`
- **Verify (@Sentinel):** no contract mismatch remains between Flutter models, repo SQL, and live Supabase objects.

### 4.2 Security + Abuse Tests

- [ ] (@Sentinel) Execute the ThreatModeler negative checks: non-owner add/edit/delete attempt, arbitrary field update attempt, cross-user storage delete attempt, malformed legacy image rendering, and raw-error disclosure attempt. File References: `lib/features/portfolio/view/portfolio_screen.dart:107-111`, `lib/features/profile/data/profile_repository.dart:133-139`, `lib/features/portfolio/services/portfolio_service.dart:116-148`, `lib/features/portfolio/view/sheets/add_portfolio_sheet.dart:49-54`
- [ ] (@Sentinel) Audit storage behavior for both canonical `image_path` rows and legacy `image_url` rows to confirm delete cleanup is deterministic and no object outside the owner path can be touched. File References: `lib/features/portfolio/services/portfolio_service.dart:136-143`, `lib/features/profile/data/profile_repository.dart:145-162`
- **Verify (@Sentinel):** unauthorized access stays impossible under both UI and RLS checks, and error disclosure stays sanitized.

### 4.3 Functional QA

- [ ] (@Sentinel) Run a manual E2E script:
  - owner opens settings and manages portfolio
  - add item with image
  - edit title/description
  - delete item and confirm storage cleanup
  - view same profile publicly
  - verify non-owner cannot mutate
  - verify pagination beyond 100 items
  - verify same-timestamp rows are reachable. File References: `lib/features/profile/view/settings_screen.dart:85-99`, `lib/features/profile/view/manage_portfolio_screen.dart:18-422`, `lib/features/profile/view/public_profile_screen.dart:280-291`, `lib/features/portfolio/services/portfolio_service.dart:20-48`
- [ ] (@Sentinel) Cover edge cases: offline/slow network, empty portfolio, legacy rows with missing/malformed image data, and upload failure rollback. File References: `lib/features/portfolio/view/sheets/add_portfolio_sheet.dart:33-87`, `lib/features/profile/view/manage_portfolio_screen.dart:183-245`, `.TODO/protfolio.TODO.md:109-171`
- **Verify (@Sentinel):** no crashes, silent failures, or inconsistent owner/public views remain.

### 4.4 Observability Validation (If included)

- [ ] (@Sentinel) Confirm the rollout emits the required sanitized portfolio events and that malformed legacy-row fallback is observable during the compatibility window. File References: `.TODO/portfolio_observability_2026-03-01.md` (planned artifact), `.TODO/protfolio.TODO.md:109-128`
- [ ] (@Sentinel) Confirm privacy redaction: no raw storage paths, policy names, or Supabase exception strings appear in analytics, logs, or snackbars. File References: `lib/features/portfolio/view/sheets/add_portfolio_sheet.dart:49-54`, `lib/features/profile/viewmodels/profile_view_model.dart:224-231`
- **Verify (@Sentinel):** telemetry is actionable without introducing new leakage.

---

## Phase 5: Documentation Sync (MANDATORY)

> Primary: @DocsKeeper

- [ ] (@DocsKeeper) Update `Sline_everything/DEVELOPER_GUIDE.md` so portfolio storage semantics, MVVM ownership, and public-profile DTO ownership describe the new canonical contract and no longer conflict internally. File References: `Sline_everything/DEVELOPER_GUIDE.md:65-65`, `Sline_everything/DEVELOPER_GUIDE.md:129-129`, `Sline_everything/DEVELOPER_GUIDE.md:383-429`, `Sline_everything/DEVELOPER_GUIDE.md:552-552`
- [ ] (@DocsKeeper) Update `Sline_everything/SUPABASE_SETUP.md` with the final portfolio schema, index, and policy source-of-truth, including `image_path` if introduced and the actual bucket privacy model verified live. File References: `Sline_everything/SUPABASE_SETUP.md:689-722`, `Sline_everything/SUPABASE_SETUP.md:1133-1142`, `Sline_everything/SUPABASE_SETUP.md:1575-1588`
- [ ] (@DocsKeeper) Update `Sline_everything/STRUCTURE.md` and any feature inventory docs if `ManagePortfolioScreen` or public-profile repositories/models move paths. File References: `Sline_everything/STRUCTURE.md`, `.TODO/CodexRefactor/01_FEATURES_INDEX.md:768-823`
- [ ] (@DocsKeeper) Reconcile historical notes in `Sline_everything/Sline_Log.md` if they still state a private `portfolio` bucket after the live rescan confirms the final state. File References: `Sline_everything/Sline_Log.md:1042-1046`
- **Verify (@Sentinel):** docs match the merged code and the post-change live Supabase reality, with no remaining portfolio storage-contract contradictions.

## 7) Acceptance Criteria (MANDATORY)

- Portfolio writes are owned by one repository/service path under `lib/features/portfolio/**`; `ProfileRepository` no longer performs portfolio CRUD. File References: `lib/features/portfolio/data/portfolio_repository.dart:8-68`, `lib/features/profile/data/profile_repository.dart:109-162`
- The active owner manage UI consumes a ViewModel only; no portfolio view constructs or reads `SupabaseClient` directly. File References: `lib/features/portfolio/view/portfolio_screen.dart:1-3`, `lib/main.dart:176-187`
- Non-owner portfolio views expose no mutation controls, and owner-only mutation attempts are still denied by RLS in live Supabase. File References: `lib/features/portfolio/view/portfolio_screen.dart:107-111`, `lib/features/portfolio/view/sheets/portfolio_details_sheet.dart:81-147`, `Sline_everything/DEVELOPER_GUIDE.md:415-422`
- Pagination returns all portfolio rows beyond the first 100 and does not skip equal-timestamp rows. File References: `lib/features/portfolio/services/portfolio_service.dart:20-48`
- New writes persist only the canonical image path contract; legacy `image_url` values are read only for compatibility during the migration window. File References: `Sline_everything/DEVELOPER_GUIDE.md:65-65`, `lib/features/portfolio/services/portfolio_service.dart:67-79`, `lib/features/profile/data/profile_repository.dart:145-162`
- Deleting a portfolio item removes the DB row and the correct storage object path, or reports a controlled partial failure without silent orphaning. File References: `lib/features/portfolio/services/portfolio_service.dart:116-148`, `lib/features/profile/data/profile_repository.dart:141-162`
- Public profile, owner preview, and manage/detail surfaces render the same portfolio contract and no longer use synthetic placeholder-only data. File References: `lib/features/profile/view/profile_screen.dart:346-353`, `lib/features/profile/view/widgets/public_profile/public_profile_portfolio.dart:97-166`, `lib/features/profile/models/freelancer_profile.dart:109-127`
- Repo migrations contain the live portfolio schema/RLS/storage policy source-of-truth or an idempotent recreation of it, and the post-change live rescan matches that repo state. File References: `Sline_everything/SUPABASE_SETUP.md:1133-1142`, `Sline_everything/SUPABASE_SETUP.md:1575-1588`
- Portfolio-focused tests exist for paging, legacy image compatibility, delete cleanup, read-only authz UX, and public-profile mapping. File Reference: `.TODO/protfolio.TODO.md:163-171`
- Portfolio docs no longer conflict about storage semantics or bucket privacy. File References: `Sline_everything/DEVELOPER_GUIDE.md:65-65`, `Sline_everything/DEVELOPER_GUIDE.md:129-129`, `Sline_everything/SUPABASE_SETUP.md:1581-1588`, `Sline_everything/Sline_Log.md:1042-1046`

## 8) Rollback Plan

- DB rollback/forward-fix:
  - Because the schema plan is additive-first, rollback means stop reading/writing `image_path` in app code and continue compatibility reads from legacy `image_url`; do not drop `image_path` during the first rollback window. File References: `.TODO/protfolio.TODO.md:187-244`
  - Keep backfill idempotent and reversible only by forward-fix; do not attempt destructive reverse migration on live mixed rows. File References: `.TODO/protfolio.TODO.md:109-128`
  - If policy migration causes drift, reapply the pre-change live policy snapshot from the implementation notes and rerun the RLS check matrix before reopening the feature. File References: `Sline_everything/SUPABASE_SETUP.md:1133-1142`, `Sline_everything/SUPABASE_SETUP.md:1581-1588`
- App rollback (flag/revert):
  - Keep the temporary wrapper at `lib/features/profile/view/manage_portfolio_screen.dart` so the route import can point back to the last-known-good owner screen without touching the settings entry point. File References: `lib/features/profile/view/settings_screen.dart:85-99`, `.TODO/protfolio.TODO.md:187-207`
  - Preserve legacy image-read fallback in the repository/service until malformed-row remediation is complete and post-release telemetry stays clean. File References: `lib/features/portfolio/services/portfolio_service.dart:67-79`, `lib/features/profile/data/profile_repository.dart:145-162`
- Emergency disable strategy (if applicable):
  - If a release blocks portfolio correctness, disable new image uploads and edits in the owner UI while keeping read-only portfolio display and compatibility reads alive; do not disable public reads unless the live rescan finds a true data leak. File References: `lib/features/profile/view/manage_portfolio_screen.dart:183-245`, `lib/features/profile/view/public_profile_screen.dart:280-291`

## 9) References (From Scan)

- Docs
  - `Sline_everything/DEVELOPER_GUIDE.md:42-79`
  - `Sline_everything/DEVELOPER_GUIDE.md:383-552`
  - `Sline_everything/SUPABASE_SETUP.md:33-115`
  - `Sline_everything/SUPABASE_SETUP.md:689-722`
  - `Sline_everything/SUPABASE_SETUP.md:1133-1142`
  - `Sline_everything/SUPABASE_SETUP.md:1575-1588`
  - `Sline_everything/MVP_ROADMAP.md`
  - `Sline_everything/ARCHITECTURE_ANALYSIS.md:5-5`
  - `Sline_everything/ARCHITECTURE_ANALYSIS.md:94-94`
  - `Sline_everything/ARCHITECTURE_ANALYSIS.md:653-653`
  - `Sline_everything/CODE_REVIEW.md:234-241`
  - `Sline_everything/CODE_REVIEW.md:371-446`
  - `Sline_everything/STRUCTURE.md`
  - `Sline_everything/Sline_Log.md:1042-1046`
- Audit
  - `.TODO/protfolio.TODO.md:1-244`
  - `.TODO/CodexRefactor/01_FEATURES_INDEX.md:768-823`
- App code
  - `lib/main.dart:136-191`
  - `lib/core/widgets/signed_image.dart:25-201`
  - `lib/features/portfolio/models/portfolio_item.dart:5-68`
  - `lib/features/portfolio/services/portfolio_service.dart:12-149`
  - `lib/features/portfolio/data/portfolio_repository.dart:8-68`
  - `lib/features/portfolio/viewmodels/portfolio_view_model.dart:8-193`
  - `lib/features/portfolio/view/portfolio_screen.dart:13-243`
  - `lib/features/portfolio/view/sheets/add_portfolio_sheet.dart:8-176`
  - `lib/features/portfolio/view/sheets/edit_portfolio_sheet.dart:7-138`
  - `lib/features/portfolio/view/sheets/portfolio_details_sheet.dart:8-154`
  - `lib/features/portfolio/view/widgets/portfolio_tile.dart:8-64`
  - `lib/features/profile/data/profile_repository.dart:109-227`
  - `lib/features/profile/viewmodels/profile_view_model.dart:142-281`
  - `lib/features/profile/viewmodels/public_profile_view_model.dart:19-37`
  - `lib/features/profile/viewmodels/user_profile_view_model.dart:8-108`
  - `lib/features/profile/view/settings_screen.dart:85-99`
  - `lib/features/profile/view/manage_portfolio_screen.dart:18-422`
  - `lib/features/profile/view/profile_screen.dart:309-390`
  - `lib/features/profile/view/public_profile_screen.dart:61-68`
  - `lib/features/profile/view/public_profile_screen.dart:280-291`
  - `lib/features/profile/view/widgets/public_profile/public_profile_portfolio.dart:9-167`
  - `lib/features/profile/models/freelancer_profile.dart:92-142`
- Live Supabase scan evidence
  - `@mcp:supabase-mcp-server:` rescan on 2026-03-01 confirmed live `public.portfolio_items` schema, indexes, RLS enabled state, policy names, public `portfolio` bucket, storage owner-path policies, and mixed legacy `image_url` data formats.
