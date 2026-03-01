# 📌 Plan: Services Feature Remediation

## 1) Goal

- Goal:
  - Fix the `services` feature end-to-end so it has a verified ownership contract, correct typed rendering, feature-local MVVM state, and automated regression coverage. References: `lib/features/services/models/service_model.dart:1-59`, `lib/features/services/services/services_service.dart:1-53`, `lib/features/profile/view/my_services_screen.dart:1-75`, `lib/features/dashboard/view/widgets/manage_service_list.dart:1-136`.
- Why:
  - The current implementation has verified correctness defects, architecture drift, and an unverified live RLS contract for direct client writes. References: `lib/features/services/view/widgets/service_card.dart:17-23`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:24-52`, `Sline_everything/SUPABASE_SETUP.md:862-876`.
- Result:
  - A services module that owns its screens/state, loads safely for the resolved user role, renders real data, enforces verified owner-only writes, and is covered by unit/widget/security validation. References: `Sline_everything/DEVELOPER_GUIDE.md:42-57`, `Sline_everything/DEVELOPER_GUIDE.md:169-173`.

## 2) Scope

### In-Scope

- `lib/features/services/**` feature files. References: `lib/features/services/models/service_model.dart:1-59`, `lib/features/services/services/services_service.dart:1-53`, `lib/features/services/view/widgets/service_card.dart:1-53`.
- Direct profile and dashboard consumers of services state/UI. References: `lib/features/profile/view/my_services_screen.dart:1-75`, `lib/features/profile/view/profile_screen.dart:412-425`, `lib/features/dashboard/view/widgets/manage_service_list.dart:1-136`, `lib/features/dashboard/view/tabs/manage_tab.dart:64-72`.
- Current state owner and root provider wiring. References: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:24-52`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:108-118`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:392-476`, `lib/main.dart:136-185`.
- `public.services` contract, related RLS/policy verification, and any additive migration needed to reconcile status or ownership rules. References: `Sline_everything/SUPABASE_SETUP.md:862-876`, `Sline_everything/DEVELOPER_GUIDE.md:44-57`.
- Tests and docs needed to make the feature safe to maintain. References: `Sline_everything/DEVELOPER_GUIDE.md:169-173`, `Sline_everything/STRUCTURE.md:35-52`.

### Out-of-Scope

- Unrelated dashboard tabs and non-service task/booking/chat flows except where current dashboard orchestration directly loads or refreshes services. References: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:396-418`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:460-476`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:588-639`.
- New marketplace product scope beyond fixing the existing service listing/management surface.
- Service media storage rollout unless a live Supabase scan proves an existing storage contract that must be supported. Current repo evidence only shows a `text[] image_urls` column. Reference: `Sline_everything/SUPABASE_SETUP.md:875`.

## 3) Evidence & Findings (From Scan)

### Existing

- The feature currently consists of one model, one Supabase service, and one dynamic card widget. References: `lib/features/services/models/service_model.dart:1-59`, `lib/features/services/services/services_service.dart:1-53`, `lib/features/services/view/widgets/service_card.dart:1-53`.
- Profile launches `MyServicesScreen`, which reads `DashboardViewModel.myServices` and renders `ServiceCard`. References: `lib/features/profile/view/profile_screen.dart:412-425`, `lib/features/profile/view/my_services_screen.dart:13-64`.
- Dashboard manage tab mounts three service-status lists from the same global state source. References: `lib/features/dashboard/view/tabs/manage_tab.dart:64-72`, `lib/features/dashboard/view/widgets/manage_service_list.dart:14-34`.
- `DashboardViewModel` currently owns `_myServices`, constructs `ServicesService` directly, and fetches services during constructor-triggered `_loadData()`. References: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:33-43`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:47-51`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:112-113`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:396-418`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:460-468`.
- Local docs define per-feature MVVM and require services/repositories for backend access and tests across unit/widget/integration layers. References: `Sline_everything/DEVELOPER_GUIDE.md:42-57`, `Sline_everything/DEVELOPER_GUIDE.md:169-173`, `Sline_everything/STRUCTURE.md:83-96`.
- Local docs define a `public.services` table with columns `freelancer_id`, `title`, `description`, `price`, `delivery_days`, `status`, `image_urls`, `created_at`. References: `Sline_everything/SUPABASE_SETUP.md:862-876`.

### Missing

- No feature-local `ServicesViewModel` exists. References: `lib/features/services/` file inventory above; `lib/features/dashboard/viewmodels/dashboard_view_model.dart:108-118`.
- No repo-local `services` RLS/policy SQL was found in `supabase/migrations/`. Reference: `Sline_everything/SUPABASE_SETUP.md:862-876`.
- No verified service-specific tests exist under `test/unit/services/`, `test/widget/services/`, or `integration_test/`. References: `Sline_everything/STRUCTURE.md:159-177`, `Sline_everything/DEVELOPER_GUIDE.md:169-173`.
- No wired create/edit/pause flow exists despite write methods and UI controls being present. References: `lib/features/services/services/services_service.dart:26-50`, `lib/features/profile/view/my_services_screen.dart:60-69`, `lib/features/dashboard/view/widgets/manage_service_list.dart:95-105`.
- Live Supabase confirmation is blocked in this session because `@mcp:supabase-mcp-server:` returns `Auth required` for table, SQL, and bucket scans. Live state is `UNVERIFIED`.

### Must NOT duplicate

- Do not introduce a second service state source alongside `DashboardViewModel.myServices`; the fix must consolidate onto one feature-local source of truth. References: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:112-113`, `Sline_everything/ARCHITECTURE_ANALYSIS.md:118-126`.
- Do not keep two service-card implementations after remediation. References: `lib/features/services/view/widgets/service_card.dart:7-53`, `lib/features/dashboard/view/widgets/manage_service_list.dart:38-115`.
- Do not add privileged or service-role behavior in the Flutter client. References: `Sline_everything/DEVELOPER_GUIDE.md:44-57`, `lib/features/services/services/services_service.dart:26-46`.
- Do not resolve the status mismatch by silently deleting support for an existing live value until live DB reality is verified.

### Conflicts / Risks (docs vs code vs live DB drift, naming mismatches, security/migration risks)

- Status mismatch:
  - Code uses `active`, `draft`, `paused`. References: `lib/features/services/models/service_model.dart:8`, `lib/features/dashboard/view/tabs/manage_tab.dart:68-71`.
  - Local schema doc only names `active`, `paused`. Reference: `Sline_everything/SUPABASE_SETUP.md:874`.
- Rendering mismatch:
  - `MyServicesScreen` passes `ServiceModel`; `ServiceCard` only reads `Map`. References: `lib/features/profile/view/my_services_screen.dart:56-63`, `lib/features/services/view/widgets/service_card.dart:17-23`.
- Startup/loading mismatch:
  - `DashboardViewModel` starts in freelancer mode and loads immediately before cached/backend role sync completes. References: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:47-51`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:286-316`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:396-418`.
- Security drift risk:
  - Direct client writes exist, but live `public.services` RLS could not be verified because the Supabase MCP session is unauthenticated.
- Migration risk:
  - Any schema or policy change must be additive-first and preserve compatibility until the app layer and tests are updated. References: `Sline_everything/DEVELOPER_GUIDE.md:48-50`, `Sline_everything/MVP_ROADMAP.md:79-84`.

## 4) System Impact Map

- UI:
  - `MyServicesScreen`, `ManageServiceList`, and the service card widgets. References: `lib/features/profile/view/my_services_screen.dart:19-73`, `lib/features/dashboard/view/widgets/manage_service_list.dart:9-136`, `lib/features/services/view/widgets/service_card.dart:7-53`.
- MVVM/App Logic:
  - `DashboardViewModel` currently owns service state; target state is a feature-local services VM with dashboard/profile entry-point adapters. References: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:108-118`, `Sline_everything/DEVELOPER_GUIDE.md:53-57`.
- Database:
  - `public.services` shape and any status/ownership reconciliation migration. References: `Sline_everything/SUPABASE_SETUP.md:862-876`.
- RLS/Security:
  - Owner-only read/write policy verification or server-side write replacement for `public.services`. References: `lib/features/services/services/services_service.dart:11-17`, `lib/features/services/services/services_service.dart:26-46`.
- Realtime/Notifications (if any):
  - None verified for the current feature. Live scan required to confirm absence.
- Storage:
  - None verified for the current feature. Current code uses only table reads/writes; docs only mention `image_urls` as a column. References: `lib/features/services/services/services_service.dart:11-46`, `Sline_everything/SUPABASE_SETUP.md:875`.
- Observability (if any):
  - Existing `AppLogger` is available and token masking exists, but service failures are currently flattened before the UI can act on them. References: `lib/core/services/logger_service.dart:59-74`, `lib/features/services/services/services_service.dart:20-22`, `lib/features/services/services/services_service.dart:35-37`, `lib/features/services/services/services_service.dart:48-50`.
- Compatibility & Migration:
  - Must preserve current entry points while moving ownership to the `services` feature. References: `lib/features/profile/view/profile_screen.dart:412-425`, `lib/features/dashboard/view/tabs/manage_tab.dart:64-72`.
- Contracts:
  - App contract today is implicitly string-based and partly conflicts with docs; phase 0 must make the contract explicit before implementation. References: `lib/features/services/models/service_model.dart:1-59`, `Sline_everything/SUPABASE_SETUP.md:862-876`.

---

# ✅ Execution Phases (Checklist)

## Phase 0: Preconditions & Gates

> Primary: @Sentinel

### 0.1 Spec Lock

- [ ] (@Sentinel) Freeze the defect list and acceptance list from the current audit: typed rendering, verified owner-only writes, resolved status contract, feature-local state ownership, and test coverage.
- [ ] (@Architect) Confirm entry points and touched modules: `services`, `profile`, `dashboard`, `main.dart`, and `public.services`. References: `lib/features/profile/view/profile_screen.dart:412-425`, `lib/features/dashboard/view/tabs/manage_tab.dart:64-72`, `lib/main.dart:166-184`.
- **Verify (@Sentinel):** every implementation task maps back to a current finding and a touched file set.

### 0.2 Threat Model (If sensitive/high-risk)

- [ ] (@ThreatModeler) Create `.TODO/THREAT_MODEL_services_<YYYY-MM-DD>.md` covering cross-user reads, forged `freelancer_id`, unsupported `status` writes, stale-role startup state, and empty-state masking.
- [ ] (@ThreatModeler) Define negative checks for read/write abuse against `public.services` and for any future create/edit/pause UI flow. References: `lib/features/services/services/services_service.dart:11-17`, `lib/features/services/services/services_service.dart:26-46`.
- **Verify (@Sentinel):** threat cases are testable and feed directly into Phase 4.2.

### 0.3 Contracts (If payloads change)

- [ ] (@APIContract) Create `.TODO/CONTRACT_services_<YYYY-MM-DD>.md` defining the canonical Flutter ↔ DB contract for `ServiceModel`, allowed `status` values, nullability, and error states. References: `lib/features/services/models/service_model.dart:1-59`, `Sline_everything/SUPABASE_SETUP.md:862-876`.
- [ ] (@APIContract) Record the unresolved `draft` mismatch and mark live DB confirmation as a gate before any destructive status cleanup. References: `lib/features/services/models/service_model.dart:8`, `lib/features/dashboard/view/tabs/manage_tab.dart:68-71`, `Sline_everything/SUPABASE_SETUP.md:874`.
- **Verify (@Sentinel):** contract matches repo docs and is ready to be reconciled with live DB reality.

### 0.4 Migration Plan (If schema/data changes)

- [ ] (@DataMigration) Create `.TODO/MIGRATION_services_<YYYY-MM-DD>.md` with additive-first paths for status normalization, nullability tightening, and policy rollout only after live scan confirmation.
- [ ] (@DataMigration) Include rollback and compatibility window rules for any new enum/check constraint/policy migration; do not plan drops or renames in the first pass.
- **Verify (@Sentinel):** migration plan has introduce/verify/enforce sequencing and a forward-fix path if live DB differs from docs.

### 0.5 Feature Flag/Rollout (If risky)

- [ ] (@Architect) Decide whether service writes or the new feature-local VM need a temporary rollout toggle; if not, document why a flag is unnecessary.
- [ ] (@Sentinel) Define an emergency read-only fallback: disable create/edit/pause UI while keeping list rendering available if DB contract verification fails.
- **Verify (@Sentinel):** rollback path is explicit before Phase 1 starts.

---

## Phase 1: Database & Security (If applicable)

> Primary: @Supabase_Ops

### 1.0 Live Supabase Confirmation (MANDATORY)

- [ ] (@Supabase_Ops) Authenticate `@mcp:supabase-mcp-server:` for this session and re-run live scans for `public.services`, its columns, policies, indexes, and any related bucket objects.
- [ ] (@Supabase_Ops) Compare live results against `Sline_everything/SUPABASE_SETUP.md:862-876` and the current code’s `draft`/owner-write assumptions. References: `lib/features/services/services/services_service.dart:11-46`, `lib/features/services/models/service_model.dart:8`.
- **Verify (@Sentinel):** if live scan remains blocked, stop Phase 1 and do not ship DB/security changes based on docs alone.

### 1.1 Schema (Additive-first)

- [ ] (@Supabase_Ops) Confirm whether `status` should remain `text` or be migrated to a constrained enum/check-backed contract after live verification.
- [ ] (@DataMigration) If live data requires normalization, plan additive migration plus backfill before any enforcement.
- [ ] (@Supabase_Ops) Add or confirm indexes that support owner-filtered service reads and status-filtered management queries, aligned with final RLS predicates.
- **Verify (@Sentinel):** schema changes are additive-first, naming is consistent, and no live rows are orphaned by status/nullability enforcement.

### 1.2 RLS

- [ ] (@Supabase_Ops) Define or verify least-privilege `SELECT`, `INSERT`, and `UPDATE` policies for `public.services`; owner-only is the safe baseline until a public browsing requirement is explicitly confirmed.
- [ ] (@ThreatModeler) Add an RLS check matrix file under `.TODO/` for anon, owner, and non-owner access attempts.
- **Verify (@Sentinel):** positive owner cases pass and negative cross-user cases fail for reads and writes.

### 1.3 Triggers/RPC (If needed)

- [ ] (@Supabase_Ops) Decide whether direct client writes can remain table-based after RLS verification or whether create/update must move behind RPC/Edge Functions for enforced ownership and valid transitions.
- [ ] (@APIContract) If RPC is introduced, define exact input/output payloads and compatibility rules for the app layer before implementation.
- **Verify (@Sentinel):** chosen write path enforces idempotent, owner-safe transitions and blocks forged payloads.

### 1.4 Migration Execution (If needed)

- [ ] (@DataMigration) Execute introduce/backfill/enforce in the order defined by the migration plan after live verification is complete.
- [ ] (@Supabase_Ops) Capture verify queries proving row counts, policy coverage, and any status backfill results.
- **Verify (@Sentinel):** migration verify queries pass and rollback SQL is documented.

---

## Phase 2: App Layer (MVVM)

> Primary: @Architect

### 2.1 Models & Contract Compliance

- [ ] (@APIContract) Reconcile `ServiceModel` with the final verified DB contract, including nullability, supported statuses, and whether `activeOrdersCount` / `rating` are real or derived placeholders. References: `lib/features/services/models/service_model.dart:1-59`, `Sline_everything/SUPABASE_SETUP.md:862-876`.
- [ ] (@Architect) Add `lib/features/services/models/service_status.dart` and remove raw string status handling from UI and model parsing paths.
- [ ] (@Architect) Convert the parser to safe mapping with explicit error surfaces instead of throwing the full list away.
- **Verify (@Sentinel):** model types, nullability, and status mapping match the verified contract and do not silently degrade to empty-state behavior.

### 2.2 Services/Repositories

- [ ] (@Architect) Move low-level table access into `lib/features/services/data/services_repository.dart` and keep `lib/features/services/services/` thin or remove it after migration. References: `lib/features/services/services/services_service.dart:1-53`, `Sline_everything/STRUCTURE.md:83-96`.
- [ ] (@Architect) Remove caller-owned `freelancer_id` from create/update flows; the repository contract must not let UI or VM code forge ownership. References: `lib/features/services/models/service_model.dart:48-57`, `lib/features/services/services/services_service.dart:26-46`.
- [ ] (@Architect) Replace flattened `[]` / `null` / `false` returns with domain result/error types that the ViewModel can surface.
- [ ] (@Architect) Keep storage out of scope unless Phase 1 proves an existing service-media contract; if storage is added later, store paths only and generate signed URLs in the repository/service layer.
- **Verify (@Sentinel):** all service DB access is centralized, RLS-safe, and no UI file calls Supabase directly.

### 2.3 ViewModels

- [ ] (@Architect) Create `lib/features/services/viewmodels/services_view_model.dart` as the single source of truth for service list state, loading/error states, refresh, and future create/edit/pause actions.
- [ ] (@Architect) Remove `_myServices` ownership from `DashboardViewModel` and replace it with delegation or a thin adapter during migration. References: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:108-118`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:460-468`.
- [ ] (@Architect) Fix startup ordering so services are not loaded under the wrong role and are fetched only when the effective role and entry surface require them.
- **Verify (@Sentinel):** service state transitions are recoverable, role-safe, and backed by one query source.

### 2.4 Observability (If needed)

- [ ] (@Observability) Define `.TODO/OBSERVABILITY_services_<YYYY-MM-DD>.md` with service load/write events, correlation IDs if needed, and privacy-safe error logging requirements.
- [ ] (@Architect) Add instrumentation in repository/ViewModel layers only; do not add business logging to widgets.
- **Verify (@Sentinel):** logs are actionable, avoid sensitive payloads, and distinguish empty state from actual failure.

---

## Phase 3: UI (After logic)

> Primary: @Pixel

### 3.1 Wiring

- [ ] (@Pixel) Move `MyServicesScreen` to `lib/features/services/view/my_services_screen.dart` and keep profile as an entry point only. References: `lib/features/profile/view/my_services_screen.dart:1-75`, `lib/features/profile/view/profile_screen.dart:412-425`.
- [ ] (@Pixel) Move `ManageServiceList` into the `services` feature and wire both profile/dashboard service surfaces to the new `ServicesViewModel`.
- [ ] (@Pixel) Replace the dynamic `ServiceCard` with typed service summary/management widgets and render explicit loading/empty/error states.
- [ ] (@Pixel) Remove or fully wire create/edit/pause controls; no placeholder actions remain visible.
- **Verify (@Sentinel):** service UI uses only ViewModels, renders real data, and stays stable on slow/empty/error states.

### 3.2 Polish (Optional)

- [ ] (@Pixel) Apply low-risk polish only after correctness is complete: spacing consistency, status badge clarity, and action-label alignment with the verified status model.
- [ ] (@Pixel) Avoid new animations or heavy UI changes that would obscure regression testing.
- **Verify (@Sentinel):** no performance regression and no new placeholder UI behavior.

---

## Phase 4: QA + Security (MANDATORY)

> Primary: @Sentinel

### 4.1 Contract + Migration Checks

- [ ] (@Sentinel) Validate the final Flutter model/repository/VM contract against the verified live schema and the Phase 0 contract file.
- [ ] (@Sentinel) Run migration verify queries and confirm any status/nullability changes match live row reality.
- **Verify (@Sentinel):** no contract mismatch remains between code, docs, and live DB.

### 4.2 Security + Abuse Tests

- [ ] (@Sentinel) Execute the `@ThreatModeler` negative matrix: cross-user reads, forged owner ids, unsupported status writes, and role-switch startup leakage.
- [ ] (@Sentinel) Execute an RLS leak audit for `public.services` and confirm no storage leak exists if service media support was introduced.
- **Verify (@Sentinel):** unauthorized access is blocked and owner flows remain functional.

### 4.3 Functional QA

- [ ] (@Sentinel) Run a manual E2E script for profile entry, dashboard manage entry, empty/error/loading states, and any wired create/edit/pause action.
- [ ] (@Sentinel) Validate edge cases: null/legacy rows, stale cached role, network failure, and parser failures.
- **Verify (@Sentinel):** no crashes, no placeholder data leakage, and consistent state recovery.

### 4.4 Observability Validation (If included)

- [ ] (@Sentinel) Confirm required service logs/events exist and differentiate empty state from backend failure.
- [ ] (@Sentinel) Verify privacy redaction remains enforced for any auth/session data touched during service flows.
- **Verify (@Sentinel):** telemetry is useful without exposing sensitive data.

---

## Phase 5: Documentation Sync (MANDATORY)

> Primary: @SlineDocs

- [ ] (@SlineDocs) Update `Sline_everything/DEVELOPER_GUIDE.md` for the final `services` architecture, contract, and test coverage.
- [ ] (@SlineDocs) Update `Sline_everything/SUPABASE_SETUP.md` if schema/RLS/status contract changed or was newly documented from live verification.
- [ ] (@SlineDocs) Update `Sline_everything/MVP_ROADMAP.md` if the services surface status changes after remediation.
- [ ] (@SlineDocs) Update `Sline_everything/STRUCTURE.md` if service screens/widgets/viewmodels move into the feature folder.
- **Verify (@Sentinel):** docs match code and verified live DB reality.

## 7) Acceptance Criteria (MANDATORY)

- `public.services` live schema, policies, and any related objects are verified through an authenticated `@mcp:supabase-mcp-server:` scan before DB/security implementation proceeds.
- Service read/write ownership is enforced by verified RLS or a verified server-side RPC/Edge Function path; the Flutter client no longer controls `freelancer_id`.
- The status contract is single-sourced, typed, and reconciled between code, docs, and live DB; undocumented values are either migrated safely or intentionally supported with documentation.
- `MyServicesScreen` and dashboard manage services render actual service data with loading/empty/error states and no placeholder action handlers.
- Service state is owned by a feature-local `ServicesViewModel`; global dashboard startup does not pre-load wrong-role service data.
- Duplicate service-card logic is removed, and the `services` feature owns its screens/widgets under `lib/features/services/`.
- Automated coverage exists for model parsing, repository error handling, ViewModel state, widget rendering, and at least one security/RLS verification path.
- `flutter analyze` passes and the targeted service tests pass without adding new analyzer issues or architecture violations.
- Docs under `Sline_everything/` match the final code structure and verified live DB contract.

## 8) Rollback Plan

- DB rollback / forward-fix:
  - If a `public.services` migration causes access regressions, apply the prepared down migration or a forward-fix migration that restores owner access without reopening broad permissions.
  - If live data contains unexpected statuses or nullability patterns, stop enforcement and keep the compatibility adapter until data is reconciled.
- App rollback:
  - Keep temporary wrapper/export files for moved service screens/widgets until the new feature-local module is proven stable.
  - Preserve a compatibility bridge in `DashboardViewModel` during rollout so profile/dashboard entry points can be reverted without reintroducing duplicated data logic.
- Emergency disable strategy:
  - If DB/RLS verification fails late, ship read-only service listing only and hide create/edit/pause actions until the contract is corrected.
  - If the new services VM regresses startup behavior, temporarily route profile/dashboard back to the previous list rendering while keeping the DB write path disabled.

## 9) References (From Scan)

- Docs:
  - `Sline_everything/DEVELOPER_GUIDE.md`
  - `Sline_everything/SUPABASE_SETUP.md`
  - `Sline_everything/MVP_ROADMAP.md`
  - `Sline_everything/ARCHITECTURE_ANALYSIS.md`
  - `Sline_everything/CODE_REVIEW.md`
  - `Sline_everything/STRUCTURE.md`
- Code:
  - `lib/main.dart`
  - `lib/features/services/models/service_model.dart`
  - `lib/features/services/services/services_service.dart`
  - `lib/features/services/view/widgets/service_card.dart`
  - `lib/features/profile/view/my_services_screen.dart`
  - `lib/features/profile/view/profile_screen.dart`
  - `lib/features/dashboard/view/widgets/manage_service_list.dart`
  - `lib/features/dashboard/view/tabs/manage_tab.dart`
  - `lib/features/dashboard/viewmodels/dashboard_view_model.dart`
  - `lib/core/services/logger_service.dart`
- Live Supabase scan evidence:
  - `@mcp:supabase-mcp-server:` `list_tables`, `execute_sql`, and `list_storage_buckets` were attempted on 2026-03-01 for the `services` feature and failed with `Auth required`.
  - Until MCP authentication is completed and the scan is re-run, live schema/RLS/storage reality remains `UNVERIFIED`.
