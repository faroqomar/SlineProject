# 📌 Plan: Portfolio Feature Recovery

## 1) Goal

- Goal:
  - Eliminate the duplicated portfolio implementations, restore one MVVM-compliant data flow, fix pagination/data-shape drift, and align app behavior with live Supabase reality.
- Why:
  - The current repo has two competing portfolio write paths (`lib/features/portfolio/**` and profile-owned CRUD), mixed persisted image formats, and owner-only actions exposed in a reusable standalone screen. References: `lib/features/portfolio/services/portfolio_service.dart:20-149`, `lib/features/profile/data/profile_repository.dart:109-162`, `lib/features/profile/view/manage_portfolio_screen.dart:18-422`, `lib/features/portfolio/view/portfolio_screen.dart:55-191`.
- Result:
  - One canonical portfolio contract, one write path, additive-safe DB/storage reconciliation, deterministic UI behavior across manage/profile/public surfaces, and verification gates backed by live RLS/storage policy checks.

## 2) Scope

### In-Scope

- Portfolio feature module and direct dependencies that currently read, write, or render portfolio data.
- Files:
  - `lib/features/portfolio/**`
  - `lib/features/profile/data/profile_repository.dart`
  - `lib/features/profile/viewmodels/profile_view_model.dart`
  - `lib/features/profile/view/manage_portfolio_screen.dart`
  - `lib/features/profile/view/profile_screen.dart`
  - `lib/features/profile/view/public_profile_screen.dart`
  - `lib/features/profile/viewmodels/public_profile_view_model.dart`
  - `lib/features/profile/viewmodels/user_profile_view_model.dart`
  - `lib/features/profile/models/freelancer_profile.dart`
  - `lib/features/profile/view/widgets/public_profile/public_profile_portfolio.dart`
  - `lib/core/widgets/signed_image.dart`
  - `lib/main.dart` (provider/composition root only). Reference: `lib/main.dart:136-200`.
- Live Supabase objects:
  - `public.portfolio_items`
  - `storage.buckets` bucket `portfolio`
  - `storage.objects` portfolio policies
- Docs that must be reconciled if touched:
  - `Sline_everything/DEVELOPER_GUIDE.md`
  - `Sline_everything/SUPABASE_SETUP.md`
  - `Sline_everything/MVP_ROADMAP.md`
  - `Sline_everything/ARCHITECTURE_ANALYSIS.md`
  - `Sline_everything/CODE_REVIEW.md`
  - `Sline_everything/STRUCTURE.md`

### Out-of-Scope

- Tender, booking, wallet, admin, or dashboard feature changes beyond direct portfolio dependencies.
- Redesigning public profile product behavior beyond making portfolio rendering correct and stable.
- Introducing new portfolio RPCs/triggers unless Phase 1 verification shows they are required for correctness; live scan found none today.
- Changing storage bucket privacy in the same patch unless explicitly approved after compatibility review; live bucket is public today.

## 3) Evidence & Findings (From Scan)

### Existing

- The live app route used for portfolio management is `ManagePortfolioScreen`, launched from settings. References: `lib/features/profile/view/settings_screen.dart:85-99`, `lib/features/profile/view/manage_portfolio_screen.dart:18-422`.
- A second standalone portfolio surface exists in `lib/features/portfolio/view/portfolio_screen.dart`, but no verified runtime caller was found in `lib/`. References: `lib/features/portfolio/view/portfolio_screen.dart:13-243`; absence-based search result is non-file evidence and remains UNVERIFIED.
- The repo uses two separate portfolio write paths:
  - Feature-owned path: `lib/features/portfolio/services/portfolio_service.dart:20-149`, `lib/features/portfolio/data/portfolio_repository.dart:18-67`, `lib/features/portfolio/viewmodels/portfolio_view_model.dart:46-193`
  - Profile-owned path: `lib/features/profile/data/profile_repository.dart:109-162`, `lib/features/profile/viewmodels/profile_view_model.dart:142-281`, `lib/features/profile/view/manage_portfolio_screen.dart:27-245`
- Live Supabase reality:
  - `public.portfolio_items` exists with columns `id, owner_id, title, description, image_url, created_at`; RLS is enabled.
  - Live policies exist on `public.portfolio_items`: `portfolio_select_all_auth`, `portfolio_insert_owner`, `portfolio_update_owner`, `portfolio_delete_owner`.
  - Live index exists: `idx_portfolio_owner_created (owner_id, created_at desc)`.
  - Live storage bucket `portfolio` exists and is public.
  - Live storage policies exist on `storage.objects` for `portfolio` owner-path insert/update/delete and authenticated select.
  - Live row sample shows mixed persisted values in `image_url`: HTTP public URLs and non-HTTP storage-path-like values. Live Supabase scan evidence: `@mcp:supabase-mcp-server:`
    - columns query
    - pg_policies query on `public.portfolio_items`
    - pg_indexes query on `public.portfolio_items`
    - storage bucket listing
    - pg_policies query on `storage.objects`
    - mixed-value counts query (`rows_with_http_url = 2`, `rows_with_non_http_value = 4`)
- Current UI renderers are inconsistent:
  - standalone feature uses `Image.network` on `item.imageUrl`. References: `lib/features/portfolio/view/widgets/portfolio_tile.dart:35-47`, `lib/features/portfolio/view/sheets/portfolio_details_sheet.dart:57-61`
  - profile surfaces use `SignedImage(storagePathOrUrl: ..., bucket: 'portfolio')`. References: `lib/features/profile/view/manage_portfolio_screen.dart:357-363`, `lib/features/profile/view/profile_screen.dart:346-353`, `lib/core/widgets/signed_image.dart:66-121`
- The broader docs scan confirms current architecture intent:
  - strict MVVM, views should not call Supabase directly, repositories/services own backend access, and storage paths are preferred in DB for future private-bucket compatibility. References: `Sline_everything/DEVELOPER_GUIDE.md:34-55`, `Sline_everything/DEVELOPER_GUIDE.md:90-107`, `Sline_everything/STRUCTURE.md:99-107`

### Missing

- No versioned portfolio migration files were found in current `supabase/migrations/` scan output, even though live DB objects exist. This means repo migrations are missing or incomplete for this feature. Live/code/doc evidence: live Supabase scan + `Sline_everything/SUPABASE_SETUP.md:1135-1142`, `Sline_everything/SUPABASE_SETUP.md:1581-1588`.
- No portfolio-specific unit/widget/integration tests were found by search in `test/` or `integration_test/`. UNVERIFIED as file evidence because this is absence-based search only.
- No live triggers, portfolio-specific RPCs, or portfolio-backed views were found for `portfolio_items`. Live Supabase scan evidence: `@mcp:supabase-mcp-server:` trigger/function/view queries returned empty results.
- No explicit contract file exists for portfolio data shape, image semantics, or compatibility window. Current shape is implicit and split across multiple models. References: `lib/features/portfolio/models/portfolio_item.dart:5-68`, `lib/features/profile/models/freelancer_profile.dart:92-128`
- Must NOT duplicate again:
  - another portfolio repository/service pair in profile or public-profile features
  - another public-profile portfolio DTO with overlapping semantics
  - another image renderer that bypasses the canonical portfolio image contract

### Conflicts / Risks (docs vs code vs live DB drift, naming mismatches, security/migration risks)

- Docs/live conflict on bucket privacy history:
  - current docs + live bucket: public portfolio bucket. References: `Sline_everything/DEVELOPER_GUIDE.md:73-79`, live Supabase bucket listing.
  - historical log: private portfolio bucket. Reference: `Sline_everything/Sline_Log.md:1042-1046`.
- Code/live conflict on persisted image semantics:
  - feature-owned code writes public URL into `image_url`. Reference: `lib/features/portfolio/services/portfolio_service.dart:75-79`, `lib/features/portfolio/services/portfolio_service.dart:93-113`
  - profile-owned code writes storage path into `image_url`. Reference: `lib/features/profile/data/profile_repository.dart:145-162`, `lib/features/profile/data/profile_repository.dart:119-130`
  - live data contains both formats plus malformed path values containing `blob:http://localhost...`. Live Supabase scan evidence: sample rows query.
- Architecture drift risk:
  - current active runtime path is profile-owned, while docs/index still frame portfolio as its own feature module. References: `.TODO/CodexRefactor/01_FEATURES_INDEX.md:768-789`, `lib/features/profile/view/settings_screen.dart:85-99`, `lib/features/portfolio/view/portfolio_screen.dart:13-19`
- Security risk:
  - standalone screen can expose mutation UI for non-owner usage and currently relies on RLS failure as the only guard. References: `lib/features/portfolio/view/portfolio_screen.dart:55-72`, `lib/features/portfolio/view/portfolio_screen.dart:107-111`, `lib/features/portfolio/view/portfolio_screen.dart:147-185`, `lib/features/portfolio/viewmodels/portfolio_view_model.dart:46-54`, `lib/features/portfolio/viewmodels/portfolio_view_model.dart:115-149`
- Migration risk:
  - normalizing live mixed `image_url` values cannot assume every non-HTTP value is valid; malformed browser blob-derived names already exist in live rows. Live Supabase scan evidence: sample rows query.

## 4) System Impact Map

- UI:
  - `ManagePortfolioScreen`, `ProfileScreen` portfolio preview, `PublicProfilePortfolio`, and optionally `PortfolioScreen` all need to converge on one image/render contract. References: `lib/features/profile/view/manage_portfolio_screen.dart:252-422`, `lib/features/profile/view/profile_screen.dart:309-390`, `lib/features/profile/view/public_profile_screen.dart:280-291`, `lib/features/profile/view/widgets/public_profile/public_profile_portfolio.dart:9-167`, `lib/features/portfolio/view/portfolio_screen.dart:91-191`
- MVVM/App Logic:
  - One source of truth is required; current duplicate ViewModel/repository/service responsibilities must collapse into the feature-owned path. References: `lib/features/portfolio/viewmodels/portfolio_view_model.dart:46-193`, `lib/features/profile/viewmodels/profile_view_model.dart:142-281`
- Database:
  - Live table is small and additive-safe migration is feasible; no live triggers/RPC/views currently constrain rollout. Live Supabase scan evidence.
- RLS/Security:
  - Live RLS and storage policies already enforce owner writes and authenticated reads, so app-side changes must preserve these assumptions and avoid widening read/write scope. Live Supabase scan evidence: `pg_policies` results for `public.portfolio_items` and `storage.objects`.
- Realtime/Notifications (if any):
  - None relevant in current live/code scan for portfolio.
- Storage:
  - Public bucket today, but contract should still avoid persisting public URLs as canonical data because docs and shared patterns prefer storage paths for future privacy changes. References: `Sline_everything/DEVELOPER_GUIDE.md:49-55`, `lib/core/widgets/signed_image.dart:73-100`
- Observability (if any):
  - Portfolio paths currently log operational failures but do not have a normalized correlation/error taxonomy; migration anomalies and cleanup failures should become observable without exposing sensitive data to users. References: `lib/features/portfolio/viewmodels/portfolio_view_model.dart:70-73`, `lib/features/profile/viewmodels/profile_view_model.dart:224-231`
- Compatibility & Migration:
  - Compatibility window is required because live rows already contain mixed formats and the app has two active-ish storage semantics. Live Supabase scan evidence + `lib/features/portfolio/services/portfolio_service.dart:75-79`, `lib/features/profile/data/profile_repository.dart:151-162`
- Contracts:
  - Contract work is required for portfolio item model shape, image reference semantics, and public-profile mapping. References: `lib/features/portfolio/models/portfolio_item.dart:5-68`, `lib/features/profile/models/freelancer_profile.dart:92-128`

---

# ✅ Execution Phases (Checklist)

## Phase 0: Preconditions & Gates

> Primary: @Sentinel

### 0.1 Spec Lock

- [ ] (@Sentinel) Write a measurable non-regression checklist in `.TODO/` covering: owner-only mutation UX, all-items pagination beyond 100 rows, image rendering parity across manage/profile/public screens, and storage cleanup behavior.
- [ ] (@Architect) Confirm the canonical runtime entry points that will survive this fix: `ManagePortfolioScreen`, `ProfileScreen` preview, `PublicProfileScreen` portfolio tab, and whether `PortfolioScreen` remains supported or is deprecated. References: `lib/features/profile/view/settings_screen.dart:85-99`, `lib/features/profile/view/profile_screen.dart:309-390`, `lib/features/profile/view/public_profile_screen.dart:61-68`, `lib/features/portfolio/view/portfolio_screen.dart:13-19`
- [ ] (@Architect) Lock the canonical persisted image contract for this feature: storage path as canonical data, with compatibility reads for legacy public URLs during rollout. References: `Sline_everything/DEVELOPER_GUIDE.md:49-55`, live Supabase mixed-value scan, `lib/core/widgets/signed_image.dart:73-100`
- **Verify (@Sentinel):** done-conditions and rollback triggers are explicit, measurable, and tied to the surviving runtime surfaces.

### 0.2 Threat Model (If sensitive/high-risk)

- [ ] (@ThreatModeler) Create `.TODO/THREAT_MODEL_Portfolio_2026-03-01.md` describing negative checks for unauthorized mutation UI, forged owner paths in storage uploads, malformed `image_url` compatibility rows, and public bucket enumeration assumptions.
- [ ] (@ThreatModeler) Define abuse cases for mixed legacy data, including malformed path strings and public URL replay across profile/public screens.
- **Verify (@Sentinel):** negative checks are testable and included in Phase 4.

### 0.3 Contracts (If payloads change)

- [ ] (@APIContract) Create `.TODO/CONTRACT_Portfolio_2026-03-01.md` defining canonical portfolio item shape for app code and the compatibility rules for `image_url`/`image_path` handling.
- [ ] (@APIContract) Define public-profile mapping contract so `freelancer_profile.dart` no longer invents random presentation-only domain data for persisted portfolio items. References: `lib/features/profile/models/freelancer_profile.dart:92-128`
- **Verify (@Sentinel):** contract matches live schema, app nullability, and public-profile shape requirements.

### 0.4 Migration Plan (If schema/data changes)

- [ ] (@DataMigration) Create `.TODO/MIGRATION_Portfolio_2026-03-01.md` with introduce/backfill/enforce/rollback stages for portfolio image normalization.
- [ ] (@DataMigration) Make the migration additive-first: introduce canonical image fielding without dropping/renaming live columns in the same release.
- [ ] (@DataMigration) Include a compatibility window and manual-review path for malformed live rows that cannot be safely normalized automatically. Live Supabase scan evidence: rows containing `blob:http://localhost...` in `image_url`.
- **Verify (@Sentinel):** compatibility window, backfill verification, and rollback thresholds are measurable.

### 0.5 Feature Flag/Rollout (If risky)

- [ ] (@Architect) Decide whether the standalone `PortfolioScreen` should be hidden/deprecated behind composition cleanup while the active profile-owned manage flow is being moved. References: `lib/features/portfolio/view/portfolio_screen.dart:13-19`, `lib/features/profile/view/settings_screen.dart:85-99`
- [ ] (@Architect) If the screen remains reachable, define a temporary read-only mode toggle for non-owner usage until the full refactor lands.
- **Verify (@Sentinel):** rollback path is documented for runtime surface changes.

---

## Phase 1: Database & Security (If applicable)

> Primary: @Supabase_Ops

### 1.0 Live Supabase Confirmation (MANDATORY)

- [ ] (@Supabase_Ops) Re-scan live `public.portfolio_items`, live RLS policies, indexes, storage bucket `portfolio`, and storage policies immediately before implementation starts.
- [ ] (@Supabase_Ops) Record the live row-format distribution again (HTTP vs non-HTTP `image_url` values) before any migration work.
- [ ] (@Supabase_Ops) Confirm no live triggers, functions, or views were introduced since planning for this feature.
- **Verify (@Sentinel):** any drift from this plan is recorded and the implementation approach is adjusted without destructive shortcuts.

### 1.1 Schema (Additive-first)

- [ ] (@Supabase_Ops) Add the minimum additive schema needed to support a canonical image contract safely.
- [ ] (@Supabase_Ops) Preferred approach: introduce `image_path` (nullable) on `public.portfolio_items` rather than renaming `image_url` in-place, because live app code and live rows still depend on `image_url` today.
- [ ] (@Supabase_Ops) Add/confirm indexes remain aligned to the actual queries (`owner_id, created_at desc`) and any new compatibility filters.
- **Verify (@Sentinel):** schema is additive, naming is consistent, and no current client path is broken during the compatibility window.

### 1.2 RLS

- [ ] (@Supabase_Ops) Preserve least-privilege owner-write policies on `public.portfolio_items`; do not widen roles or read scope beyond current product intent without explicit approval.
- [ ] (@Supabase_Ops) Create `.TODO/RLS_CHECK_Portfolio_2026-03-01.md` covering positive/negative cases for select/insert/update/delete on `public.portfolio_items` and storage owner-path rules on `storage.objects`.
- [ ] (@ThreatModeler) Validate that owner-only write semantics remain true even if app-side UI accidentally passes another user's `owner_id`.
- **Verify (@Sentinel):** negative cases fail and positive cases still pass against live policies.

### 1.3 Triggers/RPC (If needed)

- [ ] (@Supabase_Ops) Avoid introducing portfolio RPCs/triggers unless Phase 1 verification proves client-side compatibility parsing cannot safely enforce normalization.
- [ ] (@APIContract) If an RPC becomes necessary for pagination or normalization, define the exact request/response shape before implementation.
- **Verify (@Sentinel):** any new server-side object has a clear necessity, explicit contract, and idempotent behavior.

### 1.4 Migration Execution (If needed)

- [ ] (@DataMigration) Run introduce/backfill/enforce stages for canonical image fielding.
- [ ] (@DataMigration) Backfill valid storage paths from existing public URLs and existing non-HTTP values where safe; quarantine malformed rows for manual repair rather than destructive guessing.
- [ ] (@DataMigration) Keep legacy reads alive until the app no longer depends on mixed formats.
- **Verify (@Sentinel):** verification queries show expected row counts for migrated, legacy, and quarantined cases before any enforcement step.

---

## Phase 2: App Layer (MVVM)

> Primary: @Architect

### 2.1 Models & Contract Compliance

- [ ] (@Architect) Align `lib/features/portfolio/models/portfolio_item.dart` to the canonical contract (explicit canonical image ref + compatibility parsing where required). References: `lib/features/portfolio/models/portfolio_item.dart:5-68`
- [ ] (@Architect) Split or replace the nested public-profile `PortfolioItem` model in `lib/features/profile/models/freelancer_profile.dart` so it stops acting like a second portfolio domain model. References: `lib/features/profile/models/freelancer_profile.dart:92-128`
- [ ] (@Architect) Add deterministic mapping and domain error mapping for legacy/invalid image values instead of passing raw mixed strings through the UI layers.
- **Verify (@Sentinel):** types, nullability, and compatibility fallbacks match the contract and live data realities.

### 2.2 Services/Repositories

- [ ] (@Architect) Consolidate writes onto one portfolio repository/service path; remove duplicate portfolio CRUD methods from `ProfileRepository` after migration-safe adapters are in place. References: `lib/features/portfolio/data/portfolio_repository.dart:18-67`, `lib/features/profile/data/profile_repository.dart:109-162`
- [ ] (@Architect) Implement storage rule: DB stores canonical paths only after migration, while URLs are generated at render/service time.
- [ ] (@Architect) Replace current client-side capped pagination with server-safe cursor logic that does not truncate history or skip equal-timestamp rows. References: `lib/features/portfolio/services/portfolio_service.dart:20-48`
- [ ] (@Architect) Ensure delete paths clean both DB row and storage object for canonical and legacy rows. References: `lib/features/portfolio/services/portfolio_service.dart:116-148`, `lib/features/profile/data/profile_repository.dart:141-143`
- [ ] (@APIContract) Define exactly how compatibility reads behave while both image formats coexist.
- [ ] (@Architect) No N+1 or extra duplicate queries should remain across manage/profile/public portfolio surfaces.
- **Verify (@Sentinel):** implementation is RLS-safe, app layers never bypass the canonical repository/service path, and UI layers do not call Supabase directly.

### 2.3 ViewModels

- [ ] (@Architect) Refactor `PortfolioViewModel` so owner vs read-only mode is explicit and mutations are blocked client-side when the viewed owner is not the authenticated owner. References: `lib/features/portfolio/viewmodels/portfolio_view_model.dart:46-54`, `lib/features/portfolio/viewmodels/portfolio_view_model.dart:115-149`
- [ ] (@Architect) Move profile-owned portfolio orchestration out of `ProfileViewModel` or make it delegate to the canonical portfolio feature ViewModel/service path. References: `lib/features/profile/viewmodels/profile_view_model.dart:142-281`
- [ ] (@Architect) Remove duplicated fetch/update logic and define one source of truth for loading/error/retry behavior.
- [ ] (@Architect) Replace raw `Map<String, dynamic>` update surfaces with typed methods.
- **Verify (@Sentinel):** state is recoverable, transitions are correct, and non-owner mutation attempts fail before network calls while still preserving server-side RLS authority.

### 2.4 Observability (If needed)

- [ ] (@Observability) Create `.TODO/OBSERVABILITY_Portfolio_2026-03-01.md` listing required logs/events for normalization failures, storage cleanup failures, unauthorized mutation attempts blocked in UI, and migration anomaly counts.
- [ ] (@Architect) Instrument services/viewmodels only, not widgets, and replace raw user-facing exception strings with mapped English messages. References: `lib/features/portfolio/view/sheets/add_portfolio_sheet.dart:49-54`, `lib/features/profile/viewmodels/profile_view_model.dart:224-231`
- [ ] (@ThreatModeler) Ensure logs do not emit sensitive storage paths or user-identifying data beyond what is operationally required.
- **Verify (@Sentinel):** telemetry is actionable, correlated, and privacy-safe.

---

## Phase 3: UI (After logic)

> Primary: @Pixel

### 3.1 Wiring

- [ ] (@Pixel) Update `ManagePortfolioScreen`, `ProfileScreen`, and `PublicProfilePortfolio` to consume only canonical ViewModel/repository outputs and shared image rendering.
- [ ] (@Pixel) Add explicit loading/empty/error states for add/update/delete failure flows in the active manage screen. References: `lib/features/profile/view/manage_portfolio_screen.dart:183-245`
- [ ] (@Pixel) If `PortfolioScreen` remains supported, hide add/edit/delete controls in read-only mode and remove direct view-level client construction patterns where possible. References: `lib/features/portfolio/view/portfolio_screen.dart:74-116`, `lib/features/portfolio/view/sheets/portfolio_details_sheet.dart:81-147`
- [ ] (@Pixel) Replace public-profile placeholder-only cards with contract-backed portfolio rendering, unless product signs off on a deliberate placeholder-only design.
- **Verify (@Sentinel):** UX is stable on slow, empty, and failed data states across all portfolio surfaces.

### 3.2 Polish (Optional)

- [ ] (@Pixel) Add low-risk improvements only after correctness lands: consistent image placeholders, predictable list item affordances, and a real `View All` behavior or its removal if unsupported. References: `lib/features/profile/view/widgets/public_profile/public_profile_portfolio.dart:25-40`
- [ ] (@Pixel) Reduce broad rebuild scope in `PortfolioScreen` if it remains live. References: `lib/features/portfolio/view/portfolio_screen.dart:76-116`
- **Verify (@Sentinel):** no performance regression is introduced by polish changes.

---

## Phase 4: QA + Security (MANDATORY)

> Primary: @Sentinel

### 4.1 Contract + Migration Checks

- [ ] (@Sentinel) Verify app model shapes match the contract and live schema after changes.
- [ ] (@Sentinel) Run migration verification queries for canonical image fielding, compatibility fallback counts, and malformed-row handling.
- [ ] (@APIContract) Confirm public-profile mapping still matches the contract after DTO cleanup.
- **Verify (@Sentinel):** no schema/model mismatch remains.

### 4.2 Security + Abuse Tests

- [ ] (@Sentinel) Execute `@ThreatModeler` negative checks for unauthorized mutation UI, forged owner storage paths, and invalid legacy image payloads.
- [ ] (@Sentinel) Re-run RLS leak audit + storage audit against live `portfolio_items` and `storage.objects` policies.
- [ ] (@ThreatModeler) Validate that public bucket assumptions do not leak private-only data or bypass owner write restrictions.
- **Verify (@Sentinel):** unauthorized access is impossible under both client-side misuse and direct DB/storage calls.

### 4.3 Functional QA

- [ ] (@Sentinel) Execute manual E2E script for owner add/edit/delete, profile preview rendering, public profile portfolio rendering, and pagination across >100 rows.
- [ ] (@Sentinel) Cover edge cases: network failure, null image, malformed legacy row, duplicate timestamps, storage delete failure, and session expiry.
- [ ] (@Sentinel) Confirm malformed live rows are either rendered safely, flagged for repair, or both.
- **Verify (@Sentinel):** no crashes, no silent data loss, and consistent behavior across all entry points.

### 4.4 Observability Validation (If included)

- [ ] (@Sentinel) Validate required logs/events for migration anomalies, cleanup failures, and blocked unauthorized actions.
- [ ] (@Sentinel) Confirm privacy redaction rules are enforced in logs.
- **Verify (@Sentinel):** telemetry is useful for support/debugging without leaking sensitive data.

---

## Phase 5: Documentation Sync (MANDATORY)

> Primary: @DocsKeeper

- [ ] (@DocsKeeper) Update `Sline_everything/DEVELOPER_GUIDE.md`, `Sline_everything/SUPABASE_SETUP.md`, `Sline_everything/MVP_ROADMAP.md`, `Sline_everything/STRUCTURE.md`, and `Sline_everything/Sline_Log.md` to reflect the surviving portfolio architecture, canonical image contract, and live DB/storage reality.
- [ ] (@DocsKeeper) If `PortfolioScreen` is deprecated or removed, document that consolidation explicitly and remove dead-runtime references in the same patch, following the architecture cleanup rule. References: `Sline_everything/ARCHITECTURE_ANALYSIS.md:8-15`, `Sline_everything/CODE_REVIEW.md:11-21`
- **Verify (@Sentinel):** docs match code and live Supabase reality with no stale parallel-surface references.

---

## 7) Acceptance Criteria (MANDATORY)

- Portfolio writes come from one canonical repository/service path only; profile-owned duplicate CRUD logic is removed or reduced to a compatibility adapter.
- Portfolio item pagination can traverse beyond 100 rows without omissions caused by client-side capped filtering.
- Canonical portfolio image storage semantics are defined and enforced; live mixed-format rows are either migrated, supported during a compatibility window, or quarantined for manual repair.
- Owner-only mutations remain enforced by live RLS/storage policies and are not exposed as active UX for non-owner views.
- `ManagePortfolioScreen`, profile preview, and public profile portfolio all render the same persisted items correctly under the canonical contract.
- User-facing error text remains English and no raw backend/storage/RLS exception text is shown in snackbars.
- No new UI layer makes direct Supabase calls for portfolio behavior.
- Live Supabase drift is reconciled into repo migrations/docs or explicitly recorded as an approved compatibility gap.
- Portfolio-specific tests cover pagination, mutation gating, delete cleanup, mixed image compatibility, and failure handling.
- Docs and structure references are synchronized with the final implementation and live DB reality.

## 8) Rollback Plan

- DB rollback/forward-fix steps
  - If additive schema is introduced (for example `image_path`), do not drop legacy columns during the first rollout.
  - If backfill produces unexpected malformed-row volume, stop at compatibility mode and forward-fix with a repair migration rather than destructive rollback.
  - If policy reconciliation uncovers drift, keep live policies unchanged until replacement migrations are verified in a safe environment.
- app rollback (flag/revert)
  - Keep the compatibility adapter for legacy image values until the release is proven stable.
  - If consolidated portfolio wiring regresses, revert runtime callers back to the previously stable screen path without removing the compatibility parser.
  - If `PortfolioScreen` surface changes are risky, keep it hidden/read-only rather than deleting it immediately.
- emergency disable strategy (if applicable)
  - Disable add/edit/delete affordances from the standalone screen first.
  - Keep profile/public display read-only while storage cleanup or migration anomalies are investigated.
  - Pause enforcement stage of any migration until verification queries are green.

## 9) References (From Scan)

- Docs scanned
  - `Sline_everything/DEVELOPER_GUIDE.md`
  - `Sline_everything/SUPABASE_SETUP.md`
  - `Sline_everything/MVP_ROADMAP.md`
  - `Sline_everything/ARCHITECTURE_ANALYSIS.md`
  - `Sline_everything/CODE_REVIEW.md`
  - `Sline_everything/STRUCTURE.md`
- Code scanned
  - `lib/main.dart`
  - `lib/core/widgets/signed_image.dart`
  - `lib/features/portfolio/models/portfolio_item.dart`
  - `lib/features/portfolio/data/portfolio_repository.dart`
  - `lib/features/portfolio/services/portfolio_service.dart`
  - `lib/features/portfolio/view/portfolio_screen.dart`
  - `lib/features/portfolio/view/sheets/add_portfolio_sheet.dart`
  - `lib/features/portfolio/view/sheets/edit_portfolio_sheet.dart`
  - `lib/features/portfolio/view/sheets/portfolio_details_sheet.dart`
  - `lib/features/portfolio/view/widgets/portfolio_tile.dart`
  - `lib/features/portfolio/view/widgets/image_placeholder.dart`
  - `lib/features/profile/data/profile_repository.dart`
  - `lib/features/profile/viewmodels/profile_view_model.dart`
  - `lib/features/profile/view/manage_portfolio_screen.dart`
  - `lib/features/profile/view/profile_screen.dart`
  - `lib/features/profile/view/public_profile_screen.dart`
  - `lib/features/profile/viewmodels/public_profile_view_model.dart`
  - `lib/features/profile/viewmodels/user_profile_view_model.dart`
  - `lib/features/profile/models/freelancer_profile.dart`
  - `lib/features/profile/view/widgets/public_profile/public_profile_portfolio.dart`
  - `lib/features/profile/view/settings_screen.dart`
  - `.TODO/protfolio.TODO.md`
- Live Supabase scan evidence referenced
  - `@mcp:supabase-mcp-server:` `list_tables` for `public` schema
  - `@mcp:supabase-mcp-server:` `list_storage_buckets`
  - `@mcp:supabase-mcp-server:` `get_storage_config`
  - `@mcp:supabase-mcp-server:` SQL scan for `public.portfolio_items` columns
  - `@mcp:supabase-mcp-server:` SQL scan for `public.portfolio_items` policies
  - `@mcp:supabase-mcp-server:` SQL scan for `public.portfolio_items` indexes
  - `@mcp:supabase-mcp-server:` SQL scan for `storage.objects` portfolio policies
  - `@mcp:supabase-mcp-server:` SQL scan for portfolio triggers/functions/views (none found)
  - `@mcp:supabase-mcp-server:` SQL scan for live `image_url` format distribution and sample rows
