# protfolio — Feature Audit (Phase 1) + Verified Fix Plan

## 0) Overview
- What this feature does:
  - Portfolio CRUD (list/add/edit/delete items with optional image) for a user profile using Supabase `portfolio_items` and storage bucket `portfolio`. File Reference: `lib/features/portfolio/services/portfolio_service.dart:8-18`, `lib/features/portfolio/models/portfolio_item.dart:3-12`
- Boundaries (in scope):
  - Primary feature module `lib/features/portfolio/**`. File Reference: `.TODO/CodexRefactor/01_FEATURES_INDEX.md:768-789`
  - Direct dependencies that currently read/write/render the same portfolio data: profile repository/viewmodels/screens/widgets. File Reference: `lib/features/profile/data/profile_repository.dart:109-227`, `lib/features/profile/viewmodels/profile_view_model.dart:142-281`, `lib/features/profile/view/manage_portfolio_screen.dart:18-422`, `lib/features/profile/view/profile_screen.dart:309-390`, `lib/features/profile/view/public_profile_screen.dart:61-68`, `lib/features/profile/view/public_profile_screen.dart:280-291`, `lib/features/profile/viewmodels/public_profile_view_model.dart:19-37`, `lib/features/profile/view/widgets/public_profile/public_profile_portfolio.dart:9-167`, `lib/features/profile/models/freelancer_profile.dart:7-142`
- Boundaries (out of scope for deep audit, but touched by direct dependency):
  - `profiles` and `tasks` reads inside `ProfileRepository.getPublicProfile(...)` are acknowledged only as direct dependency context. File Reference: `lib/features/profile/data/profile_repository.dart:164-227`
- Entry points (screens/routes/calls):
  - Settings route opens `ManagePortfolioScreen` (active portfolio management entry). File Reference: `lib/features/profile/view/settings_screen.dart:85-99`
  - Public profile screen renders portfolio tab via `PublicProfilePortfolio`. File Reference: `lib/features/profile/view/public_profile_screen.dart:61-68`, `lib/features/profile/view/public_profile_screen.dart:280-291`
  - Standalone `PortfolioScreen` exists as a feature entry screen (route wiring not verified in current `lib/`; see UNVERIFIED notes). File Reference: `lib/features/portfolio/view/portfolio_screen.dart:13-19`
- Static analysis status (current repo state):
  - Targeted `flutter analyze` completed with no analyzer issues for audited files. UNVERIFIED by file reference (command output, not file content).

## 1) Feature Map (Current Repo State)
- Primary feature files (with references)
  - `lib/features/portfolio/view/portfolio_screen.dart` (screen provider scope + grid + add/delete UI). File Reference: `lib/features/portfolio/view/portfolio_screen.dart:13-243`
  - `lib/features/portfolio/viewmodels/portfolio_view_model.dart` (state, paging, add/update/delete). File Reference: `lib/features/portfolio/viewmodels/portfolio_view_model.dart:8-193`
  - `lib/features/portfolio/data/portfolio_repository.dart` (repository wrapper + update). File Reference: `lib/features/portfolio/data/portfolio_repository.dart:8-68`
  - `lib/features/portfolio/services/portfolio_service.dart` (Supabase PostgREST + storage upload/delete). File Reference: `lib/features/portfolio/services/portfolio_service.dart:12-149`
  - `lib/features/portfolio/models/portfolio_item.dart` (feature model). File Reference: `lib/features/portfolio/models/portfolio_item.dart:5-68`
  - `lib/features/portfolio/view/sheets/add_portfolio_sheet.dart` (add form + image pick). File Reference: `lib/features/portfolio/view/sheets/add_portfolio_sheet.dart:8-176`
  - `lib/features/portfolio/view/sheets/edit_portfolio_sheet.dart` (edit form). File Reference: `lib/features/portfolio/view/sheets/edit_portfolio_sheet.dart:7-138`
  - `lib/features/portfolio/view/sheets/portfolio_details_sheet.dart` (detail sheet + edit/delete actions). File Reference: `lib/features/portfolio/view/sheets/portfolio_details_sheet.dart:8-154`
  - `lib/features/portfolio/view/widgets/portfolio_tile.dart` (tile render + details open). File Reference: `lib/features/portfolio/view/widgets/portfolio_tile.dart:8-64`
- Direct dependencies (outside feature folder) (with references)
  - Active manage UI: `lib/features/profile/view/manage_portfolio_screen.dart`. File Reference: `lib/features/profile/view/manage_portfolio_screen.dart:18-422`
  - Profile VM duplicate portfolio CRUD/upload methods: `lib/features/profile/viewmodels/profile_view_model.dart`. File Reference: `lib/features/profile/viewmodels/profile_view_model.dart:142-281`
  - Profile repository duplicate portfolio CRUD/upload + public profile aggregate fetch. File Reference: `lib/features/profile/data/profile_repository.dart:109-227`
  - Profile screen portfolio preview uses `SignedImage(bucket: 'portfolio')`. File Reference: `lib/features/profile/view/profile_screen.dart:309-390`
  - Public profile VM and screen (active path). File Reference: `lib/features/profile/viewmodels/public_profile_view_model.dart:19-37`, `lib/features/profile/view/public_profile_screen.dart:61-68`, `lib/features/profile/view/public_profile_screen.dart:280-291`
  - Public profile portfolio widget and DTO model path. File Reference: `lib/features/profile/view/widgets/public_profile/public_profile_portfolio.dart:9-167`, `lib/features/profile/models/freelancer_profile.dart:7-142`
  - Shared image renderer `SignedImage`. File Reference: `lib/core/widgets/signed_image.dart:25-201`
- Supabase touchpoints (tables/RPC/storage/realtime) (with references to code or SQL docs)
  - Table `portfolio_items` (standalone feature reads/writes/deletes). File Reference: `lib/features/portfolio/services/portfolio_service.dart:17-18`, `lib/features/portfolio/services/portfolio_service.dart:30-35`, `lib/features/portfolio/services/portfolio_service.dart:102-113`, `lib/features/portfolio/services/portfolio_service.dart:124-132`, `lib/features/portfolio/data/portfolio_repository.dart:56-67`
  - Table `portfolio_items` (profile duplicate path reads/writes/deletes). File Reference: `lib/features/profile/data/profile_repository.dart:110-143`
  - Storage bucket `portfolio` (upload + public URL + delete / signed URL rendering). File Reference: `lib/features/portfolio/services/portfolio_service.dart:18`, `lib/features/portfolio/services/portfolio_service.dart:67-79`, `lib/features/portfolio/services/portfolio_service.dart:136-143`, `lib/features/profile/data/profile_repository.dart:145-162`, `lib/features/profile/view/manage_portfolio_screen.dart:357-363`, `lib/features/profile/view/profile_screen.dart:346-353`, `lib/core/widgets/signed_image.dart:95-100`
  - `profiles` table (public profile aggregate direct dependency). File Reference: `lib/features/profile/data/profile_repository.dart:167-173`
  - `tasks` table (public profile history aggregate direct dependency, out-of-scope for deep audit). File Reference: `lib/features/profile/data/profile_repository.dart:200-214`
  - RLS/storage policy expectations (docs only, not current migration SQL). File Reference: `Sline_everything/SUPABASE_SETUP.md:1135-1142`, `Sline_everything/SUPABASE_SETUP.md:1581-1588`, `Sline_everything/DEVELOPER_GUIDE/Portfolio Feature.md:25-35`
  - RPCs: UNVERIFIED (absence-based search across audited files; no `.rpc(` reference found).
  - Realtime channels: UNVERIFIED (absence-based search across audited files; no `.channel(` / realtime subscription reference found).
  - Edge functions: UNVERIFIED (absence-based search across audited files; no `functions.invoke` reference found).
  - Versioned portfolio schema/RLS SQL in `supabase/migrations/*.sql`: UNVERIFIED (no matching portfolio SQL file found in current repo state; expected definitions only documented in `Sline_everything/*`). File Reference: `Sline_everything/SUPABASE_SETUP.md:1135-1142`, `Sline_everything/SUPABASE_SETUP.md:1581-1588`

## 2) Evidence Index (Ground Truth)
| FindingID | Claim | File Reference (path + line range) | Risk | Notes |
| --- | --- | --- | --- | --- |
| PF-MAP-001 | Feature index defines `portfolio` module and expected touchpoints (`portfolio_items`, `portfolio`) | `.TODO/CodexRefactor/01_FEATURES_INDEX.md:768-823` | Low | Scope anchor for this audit |
| PF-MAP-002 | Active manage-portfolio entry point is from settings into `ManagePortfolioScreen` | `lib/features/profile/view/settings_screen.dart:85-99` | Medium | Indicates profile feature owns active CRUD UX today |
| PF-MAP-003 | Active public-profile path uses `PublicProfileViewModel` and renders `PublicProfilePortfolio` | `lib/features/profile/view/public_profile_screen.dart:61-68`, `lib/features/profile/view/public_profile_screen.dart:280-291`, `lib/features/profile/viewmodels/public_profile_view_model.dart:19-37` | Medium | Confirms direct dependency path for public portfolio display |
| PF-SEC-001 | `PortfolioScreen` always exposes add/delete UI; `PortfolioViewModel` can mutate using loaded `_ownerId` | `lib/features/portfolio/view/portfolio_screen.dart:55-72`, `lib/features/portfolio/view/portfolio_screen.dart:107-111`, `lib/features/portfolio/view/portfolio_screen.dart:147-185`, `lib/features/portfolio/view/sheets/portfolio_details_sheet.dart:81-147`, `lib/features/portfolio/viewmodels/portfolio_view_model.dart:46-54`, `lib/features/portfolio/viewmodels/portfolio_view_model.dart:115-149` | High | Broken-access-control UX; relies entirely on RLS to fail |
| PF-SEC-002 | Profile-side portfolio update accepts arbitrary `updates` map | `lib/features/profile/data/profile_repository.dart:133-139`, `lib/features/profile/viewmodels/profile_view_model.dart:258-270`, `lib/features/profile/view/manage_portfolio_screen.dart:192-200` | Medium | No client allowlist; broader mutation surface |
| PF-SEC-003 | Raw backend exception text is surfaced to end users | `lib/features/portfolio/view/sheets/add_portfolio_sheet.dart:49-54`, `lib/features/portfolio/view/sheets/add_portfolio_sheet.dart:81-87`, `lib/features/profile/viewmodels/profile_view_model.dart:224-231` | Low/Medium | Can leak policy/storage/internal error details |
| PF-SEC-004 | Portfolio RLS/storage policy definitions are documented but not verifiable from current migration SQL | `Sline_everything/SUPABASE_SETUP.md:1135-1142`, `Sline_everything/SUPABASE_SETUP.md:1581-1588` | High | UNVERIFIED source-of-truth in `supabase/migrations` |
| PF-DATA-001 | Pagination is client-side filtered after fetching up to 100 newest rows | `lib/features/portfolio/services/portfolio_service.dart:20-48` | High | Older rows become unreachable when total >100 |
| PF-DATA-002 | Cursor paging uses timestamp-only `isBefore`, which can skip equal-timestamp rows | `lib/features/portfolio/services/portfolio_service.dart:45-47` | Medium | Boundary duplicates/omissions risk |
| PF-DATA-003 | `image_url` semantics differ between implementations (public URL vs storage path) | `lib/features/portfolio/services/portfolio_service.dart:50-79`, `lib/features/portfolio/services/portfolio_service.dart:81-114`, `lib/features/profile/data/profile_repository.dart:119-130`, `lib/features/profile/data/profile_repository.dart:145-162`, `lib/features/portfolio/models/portfolio_item.dart:10-12`, `lib/features/portfolio/view/widgets/portfolio_tile.dart:40-47`, `lib/features/portfolio/view/sheets/portfolio_details_sheet.dart:57-61`, `lib/core/widgets/signed_image.dart:66-121` | High | Rendering and deletion behavior drift |
| PF-DATA-004 | Profile delete path deletes DB row only; standalone delete cleanup only handles public URL pattern | `lib/features/profile/data/profile_repository.dart:141-143`, `lib/features/portfolio/services/portfolio_service.dart:116-148` | High | Orphaned storage files likely |
| PF-DATA-005 | Manage delete is unawaited and error handling is missing in dialog action | `lib/features/profile/view/manage_portfolio_screen.dart:219-245`, `lib/features/profile/view/manage_portfolio_screen.dart:234-238`, `lib/features/profile/viewmodels/profile_view_model.dart:272-281` | Medium | Async failures can be silent/unhandled |
| PF-DATA-006 | Manage add/update dialog awaits VM calls that rethrow, but UI callback has no try/catch | `lib/features/profile/view/manage_portfolio_screen.dart:183-212`, `lib/features/profile/viewmodels/profile_view_model.dart:235-270` | Medium | Dialog flow can fail without user-safe recovery |
| PF-ARCH-001 | Duplicate portfolio CRUD stacks exist in `portfolio` feature and `profile` feature | `lib/features/portfolio/services/portfolio_service.dart:12-149`, `lib/features/portfolio/data/portfolio_repository.dart:8-68`, `lib/features/portfolio/viewmodels/portfolio_view_model.dart:8-193`, `lib/features/profile/data/profile_repository.dart:109-162`, `lib/features/profile/viewmodels/profile_view_model.dart:142-281`, `lib/features/profile/view/manage_portfolio_screen.dart:18-422` | High | Behavior drift already observable |
| PF-ARCH-002 | View layer imports/constructs with `SupabaseClient` directly | `lib/features/portfolio/view/portfolio_screen.dart:1-3`, `lib/features/portfolio/view/portfolio_screen.dart:74-79` | Medium | MVVM/DI boundary violation |
| PF-ARCH-003 | `ProfileViewModel` portfolio upload method contains UI concerns (`BuildContext`, snackbars) | `lib/features/profile/viewmodels/profile_view_model.dart:166-233` | Medium | Harder to test and reuse |
| PF-CQ-001 | Public-profile portfolio uses separate placeholder model (`color`, `category`) with random color assignment | `lib/features/profile/models/freelancer_profile.dart:92-128`, `lib/features/profile/view/widgets/public_profile/public_profile_portfolio.dart:97-166` | Medium | Duplicate domain model and non-deterministic UI state |
| PF-CQ-002 | Standalone `PortfolioScreen` and `UserProfileViewModel` appear unreferenced outside their defining files | `lib/features/portfolio/view/portfolio_screen.dart:13-19`, `lib/features/profile/viewmodels/user_profile_view_model.dart:8-108` | Medium | UNVERIFIED absence-based repo search (no external matches) |
| PF-CQ-003 | `isUploadingPortfolioImage` flag exists but is not read in shown portfolio UI path | `lib/features/profile/viewmodels/profile_view_model.dart:164` | Low | UNVERIFIED absence-based read search; likely dead state |
| PF-PERF-001 | Standalone portfolio rendering uses raw `Image.network`; profile path has optimized cached `SignedImage` available | `lib/features/portfolio/view/widgets/portfolio_tile.dart:35-47`, `lib/features/portfolio/view/sheets/portfolio_details_sheet.dart:57-61`, `lib/core/widgets/signed_image.dart:163-199` | Medium | Inconsistent caching/memory behavior |
| PF-PERF-002 | Standalone add flow reads bytes only; profile flow compresses before upload | `lib/features/portfolio/view/sheets/add_portfolio_sheet.dart:33-49`, `lib/features/profile/viewmodels/profile_view_model.dart:195-223` | Medium | Higher upload/memory pressure in one path |
| PF-PERF-003 | Public portfolio masonry widget eagerly builds all cards into two columns (non-lazy) | `lib/features/profile/view/widgets/public_profile/public_profile_portfolio.dart:45-80` | Low/Medium | Scales poorly on large lists |
| PF-PERF-004 | `PortfolioScreen` wraps full scaffold in one `Consumer` | `lib/features/portfolio/view/portfolio_screen.dart:76-116` | Low | Broad rebuild scope |
| PF-TEST-001 | No portfolio-focused tests found in `test/` or `integration_test/` by search | UNVERIFIED (absence-based search result; no matching file refs) | Medium | Need explicit tests for paging, authz UX, cleanup, mixed image semantics |
| PF-DOC-001 | Documentation conflict: `SUPABASE_SETUP` says public portfolio bucket; log says private bucket | `Sline_everything/SUPABASE_SETUP.md:1581-1588`, `Sline_everything/Sline_Log.md:1042-1046` | Medium | Access assumptions may have drifted |

## 3) Findings
### 3.1 Security (Highest Priority)
- `PF-SEC-001` — Unauthorized mutation UI is exposed in standalone portfolio read views. File Reference: `lib/features/portfolio/view/portfolio_screen.dart:55-72`, `lib/features/portfolio/view/portfolio_screen.dart:107-111`, `lib/features/portfolio/view/portfolio_screen.dart:147-185`, `lib/features/portfolio/view/sheets/portfolio_details_sheet.dart:81-147`, `lib/features/portfolio/viewmodels/portfolio_view_model.dart:46-54`, `lib/features/portfolio/viewmodels/portfolio_view_model.dart:115-149`
  - Impact: `PortfolioScreen(ownerId: someOtherUser)` can still show add/edit/delete actions; writes then target `_ownerId` loaded from the viewed profile.
  - Exploit/Failure scenario: If RLS is missing or weakened, a user could mutate another user's portfolio. If RLS is correct, the UI still triggers unauthorized writes and exposes avoidable failure states.
- `PF-SEC-002` — Profile-side update API accepts arbitrary column updates via raw `Map<String,dynamic>`. File Reference: `lib/features/profile/data/profile_repository.dart:133-139`, `lib/features/profile/viewmodels/profile_view_model.dart:258-270`, `lib/features/profile/view/manage_portfolio_screen.dart:192-200`
  - Impact: Client code can attempt updates beyond intended editable fields (`title`, `description`, image field).
  - Exploit/Failure scenario: A future UI change or bug passes `owner_id`/system fields into `updates`; if policy checks drift, unauthorized field mutation becomes possible.
- `PF-SEC-003` — Raw exception messages are shown in snackbars. File Reference: `lib/features/portfolio/view/sheets/add_portfolio_sheet.dart:49-54`, `lib/features/portfolio/view/sheets/add_portfolio_sheet.dart:81-87`, `lib/features/profile/viewmodels/profile_view_model.dart:224-231`
  - Impact: Internal backend/storage/RLS details can leak to end users.
  - Exploit/Failure scenario: Storage/RLS error text (policy names, object path details) is displayed directly, increasing information disclosure surface.
- `PF-SEC-004` — RLS/storage policy source-of-truth is UNVERIFIED in current versioned migrations. File Reference: `Sline_everything/SUPABASE_SETUP.md:1135-1142`, `Sline_everything/SUPABASE_SETUP.md:1581-1588`
  - Impact: Authorization assumptions are documentation-backed, not migration-backed in this repo snapshot.
  - Exploit/Failure scenario: Client code appears safe under documented policies, but deployed or current SQL may differ and permit broader reads/writes.

### 3.2 Data Integrity
- `PF-DATA-001` — Pagination truncates reachable history beyond the newest ~100 rows. File Reference: `lib/features/portfolio/services/portfolio_service.dart:20-48`
  - `take` is forced to at least 100, query always fetches newest `take`, then cursor filtering happens client-side.
  - Older items become unreachable when total items exceed the fetched cap.
- `PF-DATA-002` — Timestamp-only cursor can skip rows with equal `created_at`. File Reference: `lib/features/portfolio/services/portfolio_service.dart:45-47`
  - `isBefore(cursor)` excludes rows equal to cursor timestamp.
- `PF-DATA-003` — `image_url` column carries mixed payload types across flows (public URL vs storage path). File Reference: `lib/features/portfolio/services/portfolio_service.dart:50-79`, `lib/features/portfolio/services/portfolio_service.dart:81-114`, `lib/features/profile/data/profile_repository.dart:119-130`, `lib/features/profile/data/profile_repository.dart:145-162`, `lib/features/portfolio/models/portfolio_item.dart:10-12`, `lib/features/portfolio/view/widgets/portfolio_tile.dart:40-47`, `lib/features/portfolio/view/sheets/portfolio_details_sheet.dart:57-61`, `lib/core/widgets/signed_image.dart:66-121`
  - Standalone feature stores public URL and uses `Image.network`.
  - Profile path stores storage path and uses `SignedImage`.
  - Cross-flow rendering and cleanup behavior become inconsistent.
- `PF-DATA-004` — Storage cleanup behavior is inconsistent and can orphan files. File Reference: `lib/features/profile/data/profile_repository.dart:141-143`, `lib/features/portfolio/services/portfolio_service.dart:116-148`
  - Profile delete path removes only DB row.
  - Standalone cleanup tries storage delete only if `image_url` matches a public URL pattern.
- `PF-DATA-005` — Delete action in `ManagePortfolioScreen` is not awaited and has no error UI. File Reference: `lib/features/profile/view/manage_portfolio_screen.dart:219-245`, `lib/features/profile/view/manage_portfolio_screen.dart:234-238`, `lib/features/profile/viewmodels/profile_view_model.dart:272-281`
  - Failure can occur after dialog close without feedback.
- `PF-DATA-006` — Add/update dialog callbacks call VM methods that rethrow, but callback lacks try/catch. File Reference: `lib/features/profile/view/manage_portfolio_screen.dart:183-212`, `lib/features/profile/viewmodels/profile_view_model.dart:235-270`
  - UI may close or error out without a consistent user-facing failure state.
- `PF-DATA-007` — Local state normalization mismatch after standalone edit (`''` vs `null` description). File Reference: `lib/features/portfolio/data/portfolio_repository.dart:50-67`, `lib/features/portfolio/viewmodels/portfolio_view_model.dart:170-193`
  - Repository trims empty description to `null`, but local list update uses raw input string.

### 3.3 Architecture
- `PF-ARCH-001` — Duplicate portfolio implementations exist in parallel (`portfolio` feature and profile-side portfolio CRUD). File Reference: `lib/features/portfolio/services/portfolio_service.dart:12-149`, `lib/features/portfolio/data/portfolio_repository.dart:8-68`, `lib/features/portfolio/viewmodels/portfolio_view_model.dart:8-193`, `lib/features/profile/data/profile_repository.dart:109-162`, `lib/features/profile/viewmodels/profile_view_model.dart:142-281`, `lib/features/profile/view/manage_portfolio_screen.dart:18-422`
  - This is the primary source of drift (image semantics, cleanup, upload/compression, error handling).
- `PF-ARCH-002` — `PortfolioScreen` view layer directly imports and consumes `SupabaseClient` to construct a ViewModel. File Reference: `lib/features/portfolio/view/portfolio_screen.dart:1-3`, `lib/features/portfolio/view/portfolio_screen.dart:74-79`
  - Violates the stated MVVM dependency direction (`View -> ViewModel -> Service -> Supabase`).
- `PF-ARCH-003` — `ProfileViewModel` portfolio upload API is UI-coupled (`BuildContext` + `ScaffoldMessenger`). File Reference: `lib/features/profile/viewmodels/profile_view_model.dart:166-233`
  - Reduces testability and mixes presentation concerns into VM logic.
- `PF-ARCH-004` — Public-profile portfolio uses a separate nested `PortfolioItem` model instead of a shared portfolio DTO. File Reference: `lib/features/profile/models/freelancer_profile.dart:92-128`, `lib/features/profile/view/widgets/public_profile/public_profile_portfolio.dart:9-167`
  - Causes naming collisions and placeholder-only display behavior.

### 3.4 Code Quality
- `PF-CQ-001` — Public-profile portfolio model injects random colors and placeholder category values (`'Project'`). File Reference: `lib/features/profile/models/freelancer_profile.dart:109-127`
  - Non-deterministic presentation data is created during parsing.
- `PF-CQ-002` — Public-profile portfolio widget ignores `imageUrl` and renders style-only cards. File Reference: `lib/features/profile/view/widgets/public_profile/public_profile_portfolio.dart:97-166`, `lib/features/profile/models/freelancer_profile.dart:97-99`
  - Behavior differs from profile/manage and standalone feature previews.
- `PF-CQ-003` — `ManagePortfolioScreen` dialog controllers are allocated inside `_showAddEditDialog(...)` with no explicit disposal. File Reference: `lib/features/profile/view/manage_portfolio_screen.dart:27-35`
  - Low-severity leak risk per dialog open.
- `PF-CQ-004` — `isUploadingPortfolioImage` flag is declared but not connected to visible UI state in the audited portfolio manage flow. File Reference: `lib/features/profile/viewmodels/profile_view_model.dart:164`
  - UNVERIFIED absence-based read usage; likely stale state field.
- `PF-CQ-005` — Standalone `PortfolioScreen` and `UserProfileViewModel` appear unused outside definitions. File Reference: `lib/features/portfolio/view/portfolio_screen.dart:13-19`, `lib/features/profile/viewmodels/user_profile_view_model.dart:8-108`
  - UNVERIFIED absence-based search (no external `\bPortfolioScreen(` / `\bUserProfileViewModel(` matches in `lib/`).

### 3.5 Performance
- `PF-PERF-001` — Standalone portfolio list/detail uses uncached `Image.network` while shared `SignedImage` provides caching and decode-size optimization. File Reference: `lib/features/portfolio/view/widgets/portfolio_tile.dart:35-47`, `lib/features/portfolio/view/sheets/portfolio_details_sheet.dart:57-61`, `lib/core/widgets/signed_image.dart:163-199`
  - Increases network/memory usage and creates inconsistent image behavior across screens.
- `PF-PERF-002` — Standalone add flow loads image bytes without compression; profile flow compresses before upload. File Reference: `lib/features/portfolio/view/sheets/add_portfolio_sheet.dart:33-49`, `lib/features/profile/viewmodels/profile_view_model.dart:195-223`
  - Higher upload payloads and memory pressure in standalone flow.
- `PF-PERF-003` — Public-profile portfolio masonry builds all children eagerly using `toList()` in both columns. File Reference: `lib/features/profile/view/widgets/public_profile/public_profile_portfolio.dart:45-80`
  - Non-lazy rendering scales poorly for large portfolios.
- `PF-PERF-004` — `PortfolioScreen` wraps full `Scaffold` in one `Consumer`. File Reference: `lib/features/portfolio/view/portfolio_screen.dart:76-116`
  - App bar/FAB/body rebuild together on every state change.

### 3.6 Testing Gaps
- `PF-TEST-001` — No portfolio-focused tests were found by search in `test/` and `integration_test/`. UNVERIFIED (absence-based search; no file refs).
- Missing critical tests (derived from verified risk areas):
  - Pagination >100 items and same-timestamp boundary behavior. File Reference: `lib/features/portfolio/services/portfolio_service.dart:20-48`
  - Mixed `image_url` semantics compatibility (URL vs storage path). File Reference: `lib/features/portfolio/services/portfolio_service.dart:50-79`, `lib/features/profile/data/profile_repository.dart:145-162`, `lib/core/widgets/signed_image.dart:66-121`, `lib/features/portfolio/view/widgets/portfolio_tile.dart:40-47`
  - Delete cleanup (DB + storage object). File Reference: `lib/features/profile/data/profile_repository.dart:141-143`, `lib/features/portfolio/services/portfolio_service.dart:116-148`
  - Unauthorized mutation UX in read-only ownerId mode. File Reference: `lib/features/portfolio/view/portfolio_screen.dart:107-111`, `lib/features/portfolio/view/sheets/portfolio_details_sheet.dart:81-147`, `lib/features/portfolio/viewmodels/portfolio_view_model.dart:46-54`
  - Profile manage dialog error handling for add/update/delete failures. File Reference: `lib/features/profile/view/manage_portfolio_screen.dart:183-245`, `lib/features/profile/viewmodels/profile_view_model.dart:235-281`

## 4) Dead/Unused Code Candidates
- `lib/features/profile/viewmodels/user_profile_view_model.dart` — Candidate unused.
  - Why: Active public-profile UI path instantiates `PublicProfileViewModel`, not `UserProfileViewModel`. File Reference: `lib/features/profile/view/public_profile_screen.dart:61-68`, `lib/features/profile/viewmodels/public_profile_view_model.dart:19-37`, `lib/features/profile/viewmodels/user_profile_view_model.dart:8-108`
  - How to confirm: Repo-wide search for `\bUserProfileViewModel\(` and route/provider registrations. UNVERIFIED (absence-based search currently returned no matches outside definition).
- `lib/features/portfolio/view/portfolio_screen.dart` and companion standalone portfolio stack (`lib/features/portfolio/**`) — Candidate partially or fully unused.
  - Why: Settings route points to `ManagePortfolioScreen` (profile path), and no verified caller to standalone `PortfolioScreen` was found in `lib/`. File Reference: `lib/features/profile/view/settings_screen.dart:85-99`, `lib/features/portfolio/view/portfolio_screen.dart:13-19`
  - How to confirm: Check route table/navigation registry and deep-link handlers; run repo-wide search for `\bPortfolioScreen\(` and route names. UNVERIFIED (absence-based search currently returned no external matches).
- `lib/features/profile/viewmodels/profile_view_model.dart` field `isUploadingPortfolioImage` — Candidate dead state.
  - Why: Declaration is present but no verified read in audited manage portfolio UI path. File Reference: `lib/features/profile/viewmodels/profile_view_model.dart:164`, `lib/features/profile/view/manage_portfolio_screen.dart:27-217`
  - How to confirm: Search reads/writes and remove only if no bindings exist. UNVERIFIED (absence-based read search not included as file evidence).

## 5) Duplicate Code Candidates
- Portfolio CRUD + upload duplication
  - Duplicate implementations: `lib/features/portfolio/services/portfolio_service.dart:12-149`, `lib/features/portfolio/data/portfolio_repository.dart:8-68`, `lib/features/portfolio/viewmodels/portfolio_view_model.dart:8-193` vs `lib/features/profile/data/profile_repository.dart:109-162`, `lib/features/profile/viewmodels/profile_view_model.dart:142-281`, `lib/features/profile/view/manage_portfolio_screen.dart:18-422`
  - Proposed shared abstraction:
    - Single `PortfolioRepository` + `PortfolioImageService` (feature-owned) consumed by both standalone/profile UIs.
    - Typed update input (no raw map) shared by both callers.
- Portfolio image rendering duplication
  - Duplicate/inconsistent renderers: `lib/features/portfolio/view/widgets/portfolio_tile.dart:35-47`, `lib/features/portfolio/view/sheets/portfolio_details_sheet.dart:57-61`, `lib/features/profile/view/manage_portfolio_screen.dart:357-363`, `lib/features/profile/view/profile_screen.dart:346-353`, `lib/core/widgets/signed_image.dart:66-121`
  - Proposed shared abstraction:
    - `PortfolioImage` widget that accepts canonical image ref and internally handles URL/path resolution + caching.
- Portfolio domain model duplication
  - Duplicates: `lib/features/portfolio/models/portfolio_item.dart:5-68` and nested `PortfolioItem` in `lib/features/profile/models/freelancer_profile.dart:92-128`
  - Proposed shared abstraction:
    - Separate `public_portfolio_item.dart` DTO (profile/public UI specific) or reuse feature model with adapter/mapping layer.
- Public profile loading path duplication
  - Duplicates: `lib/features/profile/viewmodels/public_profile_view_model.dart:6-38` and `lib/features/profile/viewmodels/user_profile_view_model.dart:8-108`
  - Proposed shared abstraction:
    - Keep one public-profile VM path; delete or merge the unused one after usage confirmation.

## 6) Refactor Plan (Exact Paths)
- Refactor target: make portfolio data/write logic single-source under `lib/features/portfolio/**`, while profile/public-profile screens consume that API.
- Proposed moves/splits/merges (exact paths)
  - Split `lib/features/profile/data/profile_repository.dart` into:
    - Keep: `lib/features/profile/data/profile_repository.dart` (profile/account/avatar only) [source to edit: `lib/features/profile/data/profile_repository.dart:1-227`]
    - Create: `lib/features/profile/data/public_profile_repository.dart` (public profile aggregate reads from `profiles`, `portfolio_items`, `tasks`) [new file; proposal]
  - Move active manage UI:
    - Move `lib/features/profile/view/manage_portfolio_screen.dart` -> `lib/features/portfolio/view/manage_portfolio_screen.dart` [source: `lib/features/profile/view/manage_portfolio_screen.dart:1-422`]
    - Keep temporary compatibility wrapper at `lib/features/profile/view/manage_portfolio_screen.dart` forwarding to new screen (proposal)
  - Extract portfolio image handling:
    - Create `lib/features/portfolio/services/portfolio_image_service.dart` (upload/delete/resolve path-or-url strategy) [new file; proposal]
    - Create `lib/features/portfolio/view/widgets/portfolio_image.dart` (shared renderer using caching/signing strategy) [new file; proposal]
  - Split public profile DTOs from `freelancer_profile.dart`:
    - Keep `lib/features/profile/models/freelancer_profile.dart` (aggregate only)
    - Create `lib/features/profile/models/public_portfolio_item.dart`
    - Create `lib/features/profile/models/public_review_item.dart`
  - Remove/merge duplicate public profile VM after confirmation:
    - Delete or merge `lib/features/profile/viewmodels/user_profile_view_model.dart` (proposal; only after usage confirmation)
- Migration strategy (compat wrappers if needed)
  - Keep compatibility wrapper for old `ManagePortfolioScreen` import path for one release to avoid breaking `settings_screen.dart`. File Reference (current caller): `lib/features/profile/view/settings_screen.dart:85-99`
  - Support both existing `image_url` formats (public URL + storage path) during rollout before any data migration. File Reference: `lib/features/portfolio/services/portfolio_service.dart:75-79`, `lib/features/profile/data/profile_repository.dart:151-162`, `lib/core/widgets/signed_image.dart:73-100`

## 7) Fix Plan (Phases)
### Phase 1: Critical security & correctness
1. Read-only mutation gating in standalone portfolio UI
   - What to change: Hide/disable add/edit/delete actions when viewing another user's portfolio; enforce client-side mutation guard in `PortfolioViewModel` for non-owner mode (UX only, RLS still authoritative).
   - Exact file(s) to edit/create: `lib/features/portfolio/view/portfolio_screen.dart`, `lib/features/portfolio/view/sheets/portfolio_details_sheet.dart`, `lib/features/portfolio/viewmodels/portfolio_view_model.dart`
   - Acceptance criteria: `PortfolioScreen(ownerId != currentUser.id)` shows no add/edit/delete controls and no mutation request is sent from UI interactions. File Reference (current risky code): `lib/features/portfolio/view/portfolio_screen.dart:107-111`, `lib/features/portfolio/view/portfolio_screen.dart:147-185`, `lib/features/portfolio/view/sheets/portfolio_details_sheet.dart:81-147`, `lib/features/portfolio/viewmodels/portfolio_view_model.dart:46-54`, `lib/features/portfolio/viewmodels/portfolio_view_model.dart:115-149`
2. Typed/allowlisted profile-side portfolio updates
   - What to change: Replace raw `updates` map path with explicit fields (`title`, `description`, `image_url`/canonical image ref) and allowlist in repository.
   - Exact file(s) to edit/create: `lib/features/profile/data/profile_repository.dart`, `lib/features/profile/viewmodels/profile_view_model.dart`, `lib/features/profile/view/manage_portfolio_screen.dart`
   - Acceptance criteria: Repository update method rejects/ignores unsupported keys by design; UI cannot pass arbitrary DB columns. File Reference (current risky code): `lib/features/profile/data/profile_repository.dart:133-139`, `lib/features/profile/view/manage_portfolio_screen.dart:192-200`
3. Fix pagination correctness (>100 items and timestamp boundary)
   - What to change: Replace client-side filtering cap with server-side cursor filtering (PostgREST cursor if supported, or fallback RPC/query strategy), and use stable cursor (`created_at` + `id`) to avoid skips.
   - Exact file(s) to edit/create: `lib/features/portfolio/services/portfolio_service.dart`, `lib/features/portfolio/viewmodels/portfolio_view_model.dart` (cursor shape), optionally `supabase/migrations/<new_portfolio_paging_rpc>.sql` if RPC is required
   - Acceptance criteria: Users can load all items beyond 100; no missing rows when multiple items share the same timestamp. File Reference (current bug): `lib/features/portfolio/services/portfolio_service.dart:20-48`
4. Standardize portfolio image field semantics + compatibility read path
   - What to change: Choose one canonical persisted format for portfolio images (public URL or storage path), add compatibility parser for legacy rows, and update all renderers accordingly.
   - Exact file(s) to edit/create: `lib/features/portfolio/services/portfolio_service.dart`, `lib/features/profile/data/profile_repository.dart`, `lib/features/portfolio/models/portfolio_item.dart`, `lib/features/portfolio/view/widgets/portfolio_tile.dart`, `lib/features/portfolio/view/sheets/portfolio_details_sheet.dart`, `lib/core/widgets/signed_image.dart` (if reused), plus optional migration SQL if DB column behavior changes
   - Acceptance criteria: Items created in either current flow render correctly in all portfolio displays; delete cleanup can resolve the stored value consistently. File Reference (current mismatch): `lib/features/portfolio/services/portfolio_service.dart:50-79`, `lib/features/profile/data/profile_repository.dart:145-162`, `lib/features/portfolio/view/widgets/portfolio_tile.dart:40-47`, `lib/core/widgets/signed_image.dart:66-121`
5. Storage cleanup correctness on delete
   - What to change: Ensure delete flows remove storage objects (or intentionally retain with documented policy) for both public-URL and path-based records.
   - Exact file(s) to edit/create: `lib/features/profile/data/profile_repository.dart`, `lib/features/portfolio/services/portfolio_service.dart`, optionally shared `lib/features/portfolio/services/portfolio_image_service.dart`
   - Acceptance criteria: Deleting an item with image removes DB row and associated storage object (or logs and reports a controlled partial-failure state). File Reference (current inconsistency): `lib/features/profile/data/profile_repository.dart:141-143`, `lib/features/portfolio/services/portfolio_service.dart:116-148`
6. User-safe error messaging in portfolio flows
   - What to change: Replace raw exception text in snackbars with mapped English messages; log detailed exceptions only.
   - Exact file(s) to edit/create: `lib/features/portfolio/view/sheets/add_portfolio_sheet.dart`, `lib/features/profile/viewmodels/profile_view_model.dart`, `lib/features/profile/view/manage_portfolio_screen.dart` (add try/catch in callbacks)
   - Acceptance criteria: UI messages remain English and generic; internal exception text is not shown to users. File Reference (current leakage): `lib/features/portfolio/view/sheets/add_portfolio_sheet.dart:49-54`, `lib/features/portfolio/view/sheets/add_portfolio_sheet.dart:81-87`, `lib/features/profile/viewmodels/profile_view_model.dart:224-231`
7. Verify and restore RLS/storage policy source-of-truth in versioned SQL
   - What to change: Add or restore portfolio table/storage policy migrations in `supabase/migrations` if missing from repo.
   - Exact file(s) to edit/create: `supabase/migrations/<timestamp>_portfolio_items_rls.sql`, `supabase/migrations/<timestamp>_portfolio_storage_policies.sql` (exact names to be chosen), plus any schema migration if portfolio table definition is absent
   - Acceptance criteria: Repo contains versioned SQL defining `portfolio_items` owner-write policies and `portfolio` bucket owner path policies matching product intent. File Reference (current docs-only evidence): `Sline_everything/SUPABASE_SETUP.md:1135-1142`, `Sline_everything/SUPABASE_SETUP.md:1581-1588`; UNVERIFIED current `supabase/migrations` state.

### Phase 2: Refactor/structure
1. Consolidate portfolio write path to one implementation
   - What to change: Remove duplicate portfolio CRUD/upload logic from profile repository/VM path and route profile manage UI through feature-owned portfolio repository/service.
   - Exact file(s) to edit/create: `lib/features/profile/data/profile_repository.dart`, `lib/features/profile/viewmodels/profile_view_model.dart`, `lib/features/profile/view/manage_portfolio_screen.dart`, `lib/features/portfolio/data/portfolio_repository.dart`, `lib/features/portfolio/services/portfolio_service.dart`
   - Acceptance criteria: Only one code path performs portfolio table/storage writes; behavior is consistent across screens. File Reference (current duplication): `lib/features/portfolio/services/portfolio_service.dart:12-149`, `lib/features/profile/data/profile_repository.dart:109-162`
2. Restore MVVM/DI boundaries for standalone portfolio screen
   - What to change: Remove direct `SupabaseClient` dependency from view construction; inject VM/factory/provider via higher-level composition.
   - Exact file(s) to edit/create: `lib/features/portfolio/view/portfolio_screen.dart`, provider composition site (route/wrapper file; UNVERIFIED until route wiring is identified)
   - Acceptance criteria: `portfolio_screen.dart` no longer imports `SupabaseClient` directly. File Reference (current violation): `lib/features/portfolio/view/portfolio_screen.dart:1-3`, `lib/features/portfolio/view/portfolio_screen.dart:74-79`
3. Separate public profile aggregate repository from profile account repository
   - What to change: Split `ProfileRepository` responsibilities so portfolio/public-profile aggregation is not mixed with mutable account/profile settings concerns.
   - Exact file(s) to edit/create: `lib/features/profile/data/profile_repository.dart`, create `lib/features/profile/data/public_profile_repository.dart`, update `lib/features/profile/viewmodels/public_profile_view_model.dart`
   - Acceptance criteria: `PublicProfileViewModel` depends on a read-focused repository; `ProfileRepository` shrinks to profile/account concerns. File Reference (current mixed responsibilities): `lib/features/profile/data/profile_repository.dart:109-227`, `lib/features/profile/viewmodels/public_profile_view_model.dart:6-26`
4. Split public-profile portfolio/review DTOs from `freelancer_profile.dart`
   - What to change: Extract nested `PortfolioItem` and `ReviewItem` classes to dedicated files with explicit naming.
   - Exact file(s) to edit/create: `lib/features/profile/models/freelancer_profile.dart`, create `lib/features/profile/models/public_portfolio_item.dart`, create `lib/features/profile/models/public_review_item.dart`, update imports in `lib/features/profile/view/widgets/public_profile/public_profile_portfolio.dart`
   - Acceptance criteria: `freelancer_profile.dart` no longer defines nested generic `PortfolioItem`; public portfolio DTO naming no longer collides with feature model. File Reference (current collision): `lib/features/profile/models/freelancer_profile.dart:92-142`
5. Resolve duplicate public-profile viewmodel path
   - What to change: Delete `UserProfileViewModel` or merge needed behavior into active `PublicProfileViewModel` after usage confirmation.
   - Exact file(s) to edit/create: `lib/features/profile/viewmodels/user_profile_view_model.dart`, `lib/features/profile/viewmodels/public_profile_view_model.dart`, `lib/features/profile/view/public_profile_screen.dart` (only if merging behavior)
   - Acceptance criteria: One canonical public-profile VM path remains. File Reference (active path + duplicate candidate): `lib/features/profile/view/public_profile_screen.dart:61-68`, `lib/features/profile/viewmodels/public_profile_view_model.dart:19-37`, `lib/features/profile/viewmodels/user_profile_view_model.dart:8-108`

### Phase 3: Tests
1. Portfolio service pagination tests
   - What to change: Add unit tests for >100 items and equal-timestamp cursor boundaries.
   - Exact file(s) to edit/create: `test/unit/portfolio/portfolio_service_test.dart` (new)
   - Acceptance criteria: Tests reproduce and then prevent truncation/skip regressions. File Reference (bug source): `lib/features/portfolio/services/portfolio_service.dart:20-48`
2. Portfolio delete cleanup tests
   - What to change: Add unit tests for delete behavior with public URL and storage-path records.
   - Exact file(s) to edit/create: `test/unit/portfolio/portfolio_delete_cleanup_test.dart` (new) or fold into `portfolio_service_test.dart`
   - Acceptance criteria: Deletion attempts storage cleanup for both supported image formats. File Reference (cleanup logic): `lib/features/portfolio/services/portfolio_service.dart:116-148`, `lib/features/profile/data/profile_repository.dart:141-143`
3. ViewModel authz UX and error-state tests
   - What to change: Add tests for owner/non-owner mode mutation guard and error mapping.
   - Exact file(s) to edit/create: `test/unit/portfolio/portfolio_view_model_test.dart` (new)
   - Acceptance criteria: Non-owner mode blocks mutations client-side; owner mode still calls repository. File Reference (current behavior): `lib/features/portfolio/viewmodels/portfolio_view_model.dart:46-54`, `lib/features/portfolio/viewmodels/portfolio_view_model.dart:115-149`
4. Manage portfolio screen widget tests
   - What to change: Add widget tests for add/update/delete failure handling and user-visible messages.
   - Exact file(s) to edit/create: `test/widget/profile/manage_portfolio_screen_test.dart` (new)
   - Acceptance criteria: Failed add/update/delete produces stable English feedback and no unhandled async error. File Reference (current gaps): `lib/features/profile/view/manage_portfolio_screen.dart:183-245`, `lib/features/profile/viewmodels/profile_view_model.dart:235-281`
5. Cross-flow rendering compatibility tests
   - What to change: Add widget tests that render both URL and storage-path portfolio image values in all portfolio UIs.
   - Exact file(s) to edit/create: `test/widget/portfolio/portfolio_image_compat_test.dart` (new), optional `test/widget/profile/public_profile_portfolio_test.dart` (new)
   - Acceptance criteria: URL and path variants render correctly (or intentionally fail with explicit placeholder behavior where designed). File Reference (mixed consumers): `lib/features/portfolio/view/widgets/portfolio_tile.dart:40-47`, `lib/features/portfolio/view/sheets/portfolio_details_sheet.dart:57-61`, `lib/core/widgets/signed_image.dart:66-121`

### Phase 4: Polish/perf
1. Unify portfolio image rendering on cached widget
   - What to change: Replace raw `Image.network` in standalone feature with shared cached resolver widget.
   - Exact file(s) to edit/create: `lib/features/portfolio/view/widgets/portfolio_tile.dart`, `lib/features/portfolio/view/sheets/portfolio_details_sheet.dart`, create `lib/features/portfolio/view/widgets/portfolio_image.dart` (if not created earlier)
   - Acceptance criteria: Consistent caching/error/placeholder behavior across portfolio UIs. File Reference (current inconsistency): `lib/features/portfolio/view/widgets/portfolio_tile.dart:40-47`, `lib/features/portfolio/view/sheets/portfolio_details_sheet.dart:57-61`, `lib/core/widgets/signed_image.dart:163-199`
2. Add compression/size validation to standalone add flow
   - What to change: Match profile flow safeguards (compression + size/type validation) in `AddPortfolioSheet` path, preferably moved below UI layer.
   - Exact file(s) to edit/create: `lib/features/portfolio/view/sheets/add_portfolio_sheet.dart`, `lib/features/portfolio/services/portfolio_service.dart` or new `portfolio_image_service.dart`
   - Acceptance criteria: Large images do not cause excessive memory/upload cost; user gets clear English error on invalid file. File Reference (current gap): `lib/features/portfolio/view/sheets/add_portfolio_sheet.dart:33-49`, comparison `lib/features/profile/viewmodels/profile_view_model.dart:195-223`
3. Reduce rebuild scope in `PortfolioScreen`
   - What to change: Split `Consumer` usage so app bar/FAB/body rebuilds are scoped.
   - Exact file(s) to edit/create: `lib/features/portfolio/view/portfolio_screen.dart`
   - Acceptance criteria: State changes (e.g., loading more) do not rebuild unaffected scaffold regions. File Reference (current broad scope): `lib/features/portfolio/view/portfolio_screen.dart:76-116`
4. Public profile portfolio lazy rendering or cap
   - What to change: Use lazy list/grid or cap + “View All” behavior for large lists.
   - Exact file(s) to edit/create: `lib/features/profile/view/widgets/public_profile/public_profile_portfolio.dart`
   - Acceptance criteria: Rendering remains smooth for large portfolio lists. File Reference (current eager build): `lib/features/profile/view/widgets/public_profile/public_profile_portfolio.dart:45-80`
5. Clean dead state and dead code after confirmation
   - What to change: Remove `isUploadingPortfolioImage` if unused and delete unused VM/screen paths after verification.
   - Exact file(s) to edit/create: `lib/features/profile/viewmodels/profile_view_model.dart`, `lib/features/profile/viewmodels/user_profile_view_model.dart`, possibly `lib/features/portfolio/view/portfolio_screen.dart` and related files (only after route-usage confirmation)
   - Acceptance criteria: No unreachable portfolio/public-profile code remains; analyzer/tests pass. File Reference (candidates): `lib/features/profile/viewmodels/profile_view_model.dart:164`, `lib/features/profile/viewmodels/user_profile_view_model.dart:8-108`, `lib/features/portfolio/view/portfolio_screen.dart:13-243`

## 8) Verification Checklist
### Commands
- `flutter analyze lib/features/portfolio lib/features/profile/view/manage_portfolio_screen.dart lib/features/profile/view/profile_screen.dart lib/features/profile/view/public_profile_screen.dart lib/features/profile/view/widgets/public_profile/public_profile_portfolio.dart lib/features/profile/viewmodels/profile_view_model.dart lib/features/profile/viewmodels/public_profile_view_model.dart lib/features/profile/data/profile_repository.dart`
- `flutter test` (after Phase 3 test additions)
- Targeted tests (after creation):
  - `flutter test test/unit/portfolio/portfolio_service_test.dart`
  - `flutter test test/unit/portfolio/portfolio_view_model_test.dart`
  - `flutter test test/widget/profile/manage_portfolio_screen_test.dart`
  - `flutter test test/widget/portfolio/portfolio_image_compat_test.dart`
- Grep/rg checks (post-refactor hygiene):
  - `rg -n "\.from\('portfolio_items'\)" lib -g '*.dart'`
  - `rg -n "\bPortfolioScreen\(" lib -g '*.dart' -g '!lib/features/portfolio/view/portfolio_screen.dart'` (if deprecating standalone screen)
  - `rg -n "\bUserProfileViewModel\(" lib -g '*.dart' -g '!lib/features/profile/viewmodels/user_profile_view_model.dart'` (before deleting)
  - `rg -n "\brpc\(" lib/features/portfolio lib/features/profile -g '*.dart'` (confirm no hidden portfolio RPC dependencies)

### Manual Scenarios
- Owner manage flow (active path)
  - Open Settings -> Manage Portfolio. File Reference (entry): `lib/features/profile/view/settings_screen.dart:85-99`
  - Add item with image, edit item, delete item.
  - Verify consistent feedback and persisted results in profile preview and public profile tabs. File Reference (consumers): `lib/features/profile/view/profile_screen.dart:309-390`, `lib/features/profile/view/public_profile_screen.dart:280-291`
- Non-owner / read-only flow (standalone portfolio)
  - Open `PortfolioScreen(ownerId: otherUserId)` (if screen remains reachable).
  - Verify add/edit/delete controls are hidden/disabled and no mutation request occurs. File Reference (current risky controls): `lib/features/portfolio/view/portfolio_screen.dart:107-111`, `lib/features/portfolio/view/portfolio_screen.dart:147-185`, `lib/features/portfolio/view/sheets/portfolio_details_sheet.dart:81-147`
- Cross-flow image compatibility
  - Create/update items from profile manage path and display in standalone/path-based consumers.
  - Verify URL/path variants render in all places without broken images. File Reference: `lib/features/profile/data/profile_repository.dart:145-162`, `lib/features/portfolio/services/portfolio_service.dart:50-79`, `lib/features/portfolio/view/widgets/portfolio_tile.dart:40-47`, `lib/core/widgets/signed_image.dart:66-121`
- Large portfolio pagination
  - Seed >100 items for one user.
  - Scroll until all pages load; verify no gaps/duplicates around equal timestamps. File Reference (current paging): `lib/features/portfolio/services/portfolio_service.dart:20-48`
- Failure handling
  - Simulate storage upload failure and DB mutation failure.
  - Verify user sees stable English messages (no raw exception text). File Reference (current leakage paths): `lib/features/portfolio/view/sheets/add_portfolio_sheet.dart:49-54`, `lib/features/portfolio/view/sheets/add_portfolio_sheet.dart:81-87`, `lib/features/profile/viewmodels/profile_view_model.dart:224-231`

### Supabase/RLS Contract Checks
- `portfolio_items` table policies must exist (source-of-truth SQL in `supabase/migrations`, not docs only)
  - Required intent (owner write / public or intended read policy) is currently documented only. File Reference: `Sline_everything/SUPABASE_SETUP.md:1135-1142`, `Sline_everything/DEVELOPER_GUIDE/Portfolio Feature.md:25-30`
  - Validate by checking migration SQL files and running SQL diff / Supabase CLI migration status. UNVERIFIED current repo migration coverage.
- `portfolio` storage bucket policies must exist for owner-scoped object paths
  - Required documented policy shape is owner path prefix (`split_part(name, '/', 1) = uid`). File Reference: `Sline_everything/SUPABASE_SETUP.md:1581-1588`
  - Validate actual deployed/project SQL or dashboard policy definitions; reconcile public/private bucket intent conflict. File Reference (conflict): `Sline_everything/SUPABASE_SETUP.md:1585-1588`, `Sline_everything/Sline_Log.md:1044-1046`
- Authorization rule reminder
  - Client-side checks are UX only; RLS must remain the final authorization control. File Reference (client-side mutation paths): `lib/features/portfolio/view/portfolio_screen.dart:107-111`, `lib/features/profile/view/manage_portfolio_screen.dart:183-245`

## 9) Risks & Rollback Notes
- What could break
  - Route/import breakage if `ManagePortfolioScreen` is moved without wrapper. File Reference (current caller): `lib/features/profile/view/settings_screen.dart:85-99`
  - Existing rows may store mixed `image_url` values (URL or storage path), so strict format changes can break rendering/deletes. File Reference: `lib/features/portfolio/services/portfolio_service.dart:75-79`, `lib/features/profile/data/profile_repository.dart:151-162`
  - Public profile portfolio display may change visually when switching from placeholder cards to real images. File Reference: `lib/features/profile/view/widgets/public_profile/public_profile_portfolio.dart:97-166`, `lib/features/profile/models/freelancer_profile.dart:109-127`
  - RLS policy normalization may change behavior if docs and deployed policies have drifted. File Reference: `Sline_everything/SUPABASE_SETUP.md:1135-1142`, `Sline_everything/SUPABASE_SETUP.md:1581-1588`, `Sline_everything/Sline_Log.md:1044-1046`
- Rollback steps
  - Land Phase 1 fixes in small commits (UI gating, paging, cleanup, error mapping) so each can be reverted independently. File Reference (affected code clusters): `lib/features/portfolio/view/portfolio_screen.dart:55-191`, `lib/features/portfolio/services/portfolio_service.dart:20-149`, `lib/features/profile/data/profile_repository.dart:109-162`, `lib/features/profile/view/manage_portfolio_screen.dart:183-245`
  - Keep compatibility handling for both image formats until data is migrated and verified. File Reference: `lib/core/widgets/signed_image.dart:73-100`, `lib/features/portfolio/view/widgets/portfolio_tile.dart:40-47`
  - If refactor causes regressions, retain compatibility wrapper and revert route wiring first before deleting duplicate code paths. File Reference (active route caller): `lib/features/profile/view/settings_screen.dart:85-99`
