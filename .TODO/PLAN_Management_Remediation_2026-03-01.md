# 📌 Plan: Management Remediation

## 1) Goal

- Goal: Secure, stabilize, and simplify the management timeline/note flow for task and booking detail screens without widening scope beyond the feature and its direct dependencies.
- Why: Current repo evidence shows privacy leakage in debug logs, a broken polymorphic read contract for `work_logs`, silent/draft-destroying failure behavior in the note composer, and missing verification for the RLS contract that the feature depends on.
- Result: A production-safe management flow where `work_logs` reads/writes use one verified scope contract, private note visibility remains enforced by RLS, client behavior is failure-safe, logs are privacy-safe, and the feature has contract, QA, rollback, and docs coverage.

## 2) Scope

### In-Scope

- `lib/features/management/**`
- Direct management dependencies only:
  - `lib/features/tasks/view/task_details_screen.dart`
  - `lib/features/booking/view/booking_details_screen.dart`
  - `lib/core/services/logger_service.dart`
  - `lib/core/utils/error_mapper.dart`
  - `lib/core/utils/format_date.dart`
  - `lib/core/widgets/signed_avatar.dart`
- Management-related docs and setup references:
  - `Sline_everything/DEVELOPER_GUIDE.md`
  - `Sline_everything/DEVELOPER_GUIDE/Order_Management_Feature.md`
  - `Sline_everything/SUPABASE_SETUP.md`
  - `Sline_everything/MVP_ROADMAP.md`
  - `Sline_everything/ARCHITECTURE_ANALYSIS.md`
  - `Sline_everything/CODE_REVIEW.md`
  - `Sline_everything/STRUCTURE.md`
- Existing audit baseline:
  - `.TODO/management.TODO.md`

### Out-of-Scope

- Full `tasks`, `booking`, or `work` feature redesign outside the management embedding points they already use.
- Any destructive schema rename/drop intended only to reconcile docs with code.
- New admin flows, service-role client paths, or new realtime/storage features unless the live scan proves they already exist and are required.
- Broad global error-mapping redesign beyond the minimum needed to stop management-specific authz confusion.
- Production rollout itself; this file is an execution-ready plan and gate set.

## 3) Evidence & Findings (From Scan)

### Existing

- The feature is a small MVVM module with one service, one view model, one panel view, one tile widget, and one model under `lib/features/management/`.
- The management panel is embedded in task details and booking details using local `ChangeNotifierProvider(OrderManagementViewModel)` wrappers.
- The service currently reads and writes the `work_logs` table and joins author metadata from `profiles`.
- Docs describe `work_logs` as a polymorphic, immutable table keyed by `related_entity_id` plus `related_entity_type`, guarded by RLS and `is_work_log_participant(...)`.
- Repo evidence already confirms the key defects called out in `.TODO/management.TODO.md`:
  - raw note content logging
  - missing `related_entity_type` filter on reads
  - failed send still clears draft
  - error state is hidden behind empty state
  - no feature-specific tests

### Missing

- Live Supabase scan evidence is missing in this session because `@mcp:supabase-mcp-server:` is not available here. Live confirmation of `work_logs` schema, indexes, policies, helper functions, triggers, and grants is still required before execution.
- Repo-local SQL for `work_logs` source-of-truth objects is incomplete in the current snapshot; the contract is documented in docs but not present in local `supabase/migrations/` scan.
- No management-specific unit, widget, or integration tests exist in `test/` or `integration_test/`.
- No dedicated threat model, API contract, or RLS matrix artifact exists yet for this feature.

### Must NOT duplicate

- Do not introduce a second source of truth for work-log scope; use one typed contract for both reads and writes.
- Do not duplicate provider wiring across task and booking hosts once a management wrapper can own it.
- Do not introduce client-side authorization rules that compete with RLS; client checks remain UX-only.
- Do not add a new RPC or trigger for note posting unless the live DB scan proves direct table insert is insufficient or unsafe.

### Conflicts / Risks (docs vs code vs live DB drift, naming mismatches, security/migration risks)

- Docs describe a polymorphic `getLogs(entityId, type)` contract, but current code reads by `related_entity_id` only.
- Docs describe RLS-driven participant/private-note protection, but the current session lacks live DB proof that deployed policies and helper functions still match docs.
- Docs show index intent for `work_logs` on `(related_entity_id, created_at desc)`; once the app reads by both id and type, live index adequacy must be re-checked before any performance claim is accepted.
- The feature currently relies on shared `ErrorMapper` behavior that maps `42501` to “Session expired,” which conflicts with the management docs’ intended permission-denied semantics.
- The current developer guide path/signature is stale (`data/work_log_service.dart`, `getLogs(entityId, type)`) relative to repo code.

## 4) System Impact Map

- UI:
  - `lib/features/management/view/order_management_panel.dart`
  - `lib/features/management/view/widgets/work_log_tile.dart`
  - `lib/features/tasks/view/task_details_screen.dart`
  - `lib/features/booking/view/booking_details_screen.dart`
- MVVM/App Logic:
  - `lib/features/management/viewmodels/order_management_view_model.dart`
  - `lib/features/management/services/work_log_service.dart`
  - `lib/features/management/models/work_log_model.dart`
- Database:
  - `work_logs`
  - joined `profiles` relation for author metadata
- RLS/Security:
  - `work_logs_select`
  - `work_logs_insert`
  - `work_logs_deny_update`
  - `work_logs_deny_delete`
  - `is_work_log_participant(...)`
  - client log redaction behavior
- Realtime/Notifications (if any):
  - No management-owned realtime or notification path was found in the current scan; treat as absent unless live scan reveals otherwise.
- Storage:
  - No management-owned storage writes were found.
  - Avatar rendering is indirect via `SignedAvatar` and profile image paths.
- Observability (if any):
  - `AppLogger` and shared error mapping behavior affect management privacy and support diagnostics.
- Compatibility & Migration:
  - additive-first only if live scan reveals index/policy drift or missing DB helpers
  - app compatibility matters for task and booking host screens that embed the panel
- Contracts:
  - Flutter panel/viewmodel/service scope contract
  - `work_logs` row shape
  - `profiles` join shape
  - RLS participant/private-note contract

---

# ✅ Execution Phases (Checklist)

## Phase 0: Preconditions & Gates

> Primary: @Sentinel

### 0.1 Spec Lock

- [ ] (@Sentinel) Freeze the measurable acceptance and non-regression list using `.TODO/management.TODO.md` as the audit baseline for security, data integrity, architecture, performance, and testing.
- [ ] (@Architect) Confirm the exact management scope and direct dependencies that remain in execution scope: `lib/features/management/**`, host embeddings in task/booking details, and shared logger/error-mapper helpers only.
- **Verify (@Sentinel):** Every implementation task maps to a verified finding or a required dependency; no unrelated task/booking/work scope is pulled in.

### 0.2 Threat Model (If sensitive/high-risk)

- [ ] (@ThreatModeler) Create `.TODO/THREATMODEL_Management_2026-03-01.md` covering private-note leakage, non-participant read/write attempts, replay/duplicate note submission, draft-loss UX masking failed writes, and sensitive log exposure.
- [ ] (@ThreatModeler) Define negative checks for broken private-note visibility, incorrect participant scope, misleading authz/session messaging, and accidental note-content logging.
- **Verify (@Sentinel):** Every identified threat has a testable negative case and at least one prevention control mapped into Phases 1-4.

### 0.3 Contracts (If payloads change)

- [ ] (@APIContract) Create `.TODO/CONTRACT_Management_WorkLogs_2026-03-01.md` covering the canonical scope contract (`entityId` + `entityType` or `WorkLogScope`), the `work_logs` select shape, the joined `profiles` shape, and UI-visible error states.
- [ ] (@APIContract) Lock one canonical read/write contract for task and booking embeddings so the same scope semantics are used at panel, view model, and service layers.
- **Verify (@Sentinel):** Contract file specifies required fields, nullability, authorization assumptions, and error semantics that match the live schema once Phase 1.0 is completed.

### 0.4 Migration Plan (If schema/data changes)

- [ ] (@DataMigration) Create `.TODO/MIGRATION_Management_2026-03-01.md` only if the live scan proves schema/index/policy drift that requires SQL changes; keep the plan additive-first and reversible.
- [ ] (@DataMigration) Predefine the safe reconcile path for a composite index or policy/helper fix if live DB reality does not match docs.
- **Verify (@Sentinel):** No DB action proceeds without a measured compatibility/rollback path, and no destructive change is used to “make docs match.”

### 0.5 Feature Flag/Rollout (If risky)

- [ ] (@Architect) Decide whether a rollout toggle is unnecessary for app-only fixes, and document the threshold that would require one if live DB changes are introduced.
- [ ] (@Observability) Define the rollback trigger signals for management-specific regression: RLS denials rising unexpectedly, private-note visibility mismatch, repeated send failures, or panel load failures.
- **Verify (@Sentinel):** A clear rollback path exists even if no formal feature flag is introduced.

---

## Phase 1: Database & Security (If applicable)

> Primary: @Supabase_Ops

### 1.0 Live Supabase Confirmation (MANDATORY)

- [ ] (@Supabase_Ops) Re-scan via `@mcp:supabase-mcp-server:` for touched objects: `work_logs`, joined `profiles` access, `is_work_log_participant(...)`, related indexes, triggers, grants, and policies.
- [ ] (@Supabase_Ops) Confirm whether live DB reality matches docs for:
  - `related_entity_type` column presence and type
  - `is_private` and `metadata` columns
  - `work_logs_select` / `work_logs_insert` / immutable policies
  - `is_work_log_participant(...)` behavior for `task` and `booking`
  - index coverage for the corrected read query
- **Verify (@Sentinel):** Drift between docs, repo code, and live DB is recorded in `.TODO/` before any DB-facing implementation starts.

### 1.1 Schema (Additive-first)

- [ ] (@Supabase_Ops) Keep schema changes optional and additive-only; only add SQL if Phase 1.0 proves the live schema/index set is insufficient for the corrected app contract.
- [ ] (@Supabase_Ops) If live index coverage is weak for `(related_entity_id, related_entity_type, created_at)`, plan an additive index migration instead of query compromises.
- [ ] (@DataMigration) Prepare an additive reconcile path if live helper/policy names differ from docs but app behavior still depends on equivalent semantics.
- **Verify (@Sentinel):** No schema change is introduced unless it is directly justified by the live scan and tied to a measured query/policy requirement.

### 1.2 RLS

- [ ] (@Supabase_Ops) Verify live `work_logs` policies against the intended docs rules for participant reads, self-only private reads, participant inserts, and immutable update/delete denial.
- [ ] (@Supabase_Ops) Create `.TODO/RLS_Management_2026-03-01.md` with a matrix for task client, task freelancer, booking client, booking provider, unrelated authenticated user, and service role.
- [ ] (@ThreatModeler) Require that client-side visibility hardening remains defense-in-depth only and does not replace RLS as the source of truth.
- **Verify (@Sentinel):** Positive party access passes, private-note isolation holds, and non-party access fails for all touched operations.

### 1.3 Triggers/RPC (If needed)

- [ ] (@Supabase_Ops) Do not add a new RPC/trigger by default; only introduce one if the live scan shows direct `work_logs` inserts cannot enforce a required invariant safely.
- [ ] (@APIContract) If a server-side primitive becomes necessary, define the exact request/response contract before implementation and keep the change additive-first.
- **Verify (@Sentinel):** Server-side primitives are added only for verified invariants, not as unnecessary abstraction.

### 1.4 Migration Execution (If needed)

- [ ] (@DataMigration) Execute introduce/backfill/enforce steps only if `.TODO/MIGRATION_Management_2026-03-01.md` is activated by Phase 1.0 findings.
- [ ] (@Supabase_Ops) Validate post-migration policy behavior and query plans for task and booking timeline loads.
- **Verify (@Sentinel):** The corrected app contract works against the migrated schema without breaking existing task/booking timelines.

---

## Phase 2: App Layer (MVVM)

> Primary: @Architect

### 2.1 Models & Contract Compliance

- [ ] (@Architect) Introduce one canonical management scope contract, preferably `lib/features/management/models/work_log_scope.dart`, and migrate the panel/viewmodel/service to use it.
- [ ] (@Architect) Align `WorkLog` model parsing and required fields to the locked contract, including author/avatar join fields and system-event metadata.
- [ ] (@APIContract) Decide whether `authorName` and `eventType` remain necessary; remove them only after contract review and usage verification.
- **Verify (@Sentinel):** Types, nullability, and scope semantics match the contract and no layer can read without the required entity type.

### 2.2 Services/Repositories

- [ ] (@Architect) Fix `WorkLogService.getLogs(...)` to use the full scope contract and filter by both `related_entity_id` and `related_entity_type`.
- [ ] (@Architect) Remove raw note content from management success logs and replace it with privacy-safe metadata only.
- [ ] (@Architect) Normalize note content before insert and keep service behavior aligned with RLS-safe direct inserts unless Phase 1 requires a server-side primitive.
- [ ] (@Architect) Decide whether to keep a single `WorkLogService` or introduce a facade-compatible split into query/command services without duplicating data access logic.
- **Verify (@Sentinel):** Service layer is RLS-safe, privacy-safe, contract-compliant, and free of UI-originating Supabase calls.

### 2.3 ViewModels

- [ ] (@Architect) Refactor `OrderManagementViewModel` so `loadLogs(...)` and `postNote(...)` share the same scope contract and produce explicit success/failure semantics.
- [ ] (@Architect) Ensure failed sends preserve drafts, load errors surface a distinct error state, and send/load transitions remain recoverable.
- [ ] (@Architect) Remove or isolate unused scaffold methods (`proposePriceChange`, `requestExtension`) if they are not part of a verified near-term integration contract.
- [ ] (@Architect) Consolidate repeated async/send/error handling into one internal helper to avoid drift.
- **Verify (@Sentinel):** View-model state is recoverable, one user action maps to one authoritative mutation attempt, and failure states are visible and testable.

### 2.4 Observability (If needed)

- [ ] (@Observability) Create `.TODO/OBSERVABILITY_Management_2026-03-01.md` defining the minimum useful management logs/events and privacy redaction rules.
- [ ] (@Architect) Instrument service/viewmodel events only where they improve supportability, never with raw note content or user-sensitive payloads.
- [ ] (@ThreatModeler) Review all management logging for private-note leakage, authz signal clarity, and correlation usefulness.
- **Verify (@Sentinel):** Telemetry is actionable for send/load failures and authz issues without exposing note content or other sensitive data.

---

## Phase 3: UI (After logic)

> Primary: @Pixel

### 3.1 Wiring

- [ ] (@Pixel) Update `OrderManagementPanel` to load using the corrected scope contract and to render explicit loading, empty, error, and populated states.
- [ ] (@Pixel) Clear composer text only on confirmed success and keep retry-safe draft behavior on failures.
- [ ] (@Pixel) Extract a shared management wrapper (`order_management_section.dart`) if it removes duplicate provider wiring from task and booking detail hosts without widening scope.
- [ ] (@Pixel) Keep all user-facing strings in English only for any new state or error copy.
- **Verify (@Sentinel):** Slow, empty, failed, and successful note flows are stable and understandable in both task and booking embeddings.

### 3.2 Polish (Optional)

- [ ] (@Pixel) Split the panel into timeline and composer widgets if it reduces complexity without changing the contract or adding duplicate logic.
- [ ] (@Pixel) Add low-risk UX protections only: disabled send during in-flight work, stable private-toggle behavior after success, and sensible long-list handling.
- **Verify (@Sentinel):** UI polish does not widen rebuild scope, reintroduce business logic into widgets, or regress timeline performance.

---

## Phase 4: QA + Security (MANDATORY)

> Primary: @Sentinel

### 4.1 Contract + Migration Checks

- [ ] (@Sentinel) Run `flutter analyze` for management and direct embedding dependencies after remediation.
- [ ] (@Sentinel) Run focused Flutter tests for management unit/widget coverage and any new integration/manual automation checks.
- [ ] (@APIContract) Confirm the final panel/viewmodel/service contract matches the contract file and the verified live DB schema from Phase 1.0.
- [ ] (@Sentinel) Run DB verification queries or live scan checks for schema/index/policy expectations if any DB change was introduced.
- **Verify (@Sentinel):** No contract mismatch remains between app code, docs, and live DB reality.

### 4.2 Security + Abuse Tests

- [ ] (@Sentinel) Execute the ThreatModeler negative checks:
  - private note visible only to author
  - non-participant cannot read/write logs
  - authz denial is not mislabeled as session expiry
  - note text never appears in management logs
  - repeated send failure does not destroy draft text
- [ ] (@ThreatModeler) Perform a management-focused RLS leak audit for task and booking participant permutations.
- [ ] (@Sentinel) Confirm no client artifact reintroduces privileged or policy-bypassing logic in the management path.
- **Verify (@Sentinel):** Unauthorized access is blocked by RLS, client UX does not leak sensitive data, and privacy-safe logging is enforced.

### 4.3 Functional QA

- [ ] (@Sentinel) Execute a manual E2E script covering task public note, task private note, booking public note, booking private note, and retry-on-failure behavior.
- [ ] (@Sentinel) Execute edge cases: network loss during send, initial load failure, true empty timeline, long history rendering, and repeated send taps.
- [ ] (@Sentinel) Confirm host embeddings in both task and booking screens still create and dispose local management state correctly.
- **Verify (@Sentinel):** No crashes, draft-loss regressions, contradictory UI states, or cross-entity timeline mix-ups remain.

### 4.4 Observability Validation (If included)

- [ ] (@Sentinel) Verify required management logs/events exist and are useful for support/debugging.
- [ ] (@Observability) Confirm privacy redaction rules prevent note-content leakage while preserving actionable error signals.
- **Verify (@Sentinel):** Operators can diagnose management failures without access to private note bodies.

---

## Phase 5: Documentation Sync (MANDATORY)

> Primary: @SlineDocs

- [ ] (@SlineDocs) Update management-related docs after implementation:
  - `Sline_everything/DEVELOPER_GUIDE/Order_Management_Feature.md`
  - `Sline_everything/DEVELOPER_GUIDE.md`
  - `Sline_everything/SUPABASE_SETUP.md` if live DB reconcile work occurred
  - `Sline_everything/STRUCTURE.md` if file paths change
  - `Sline_everything/Sline_Log.md`
- [ ] (@SlineDocs) Record docs-vs-code-vs-live reconciliation explicitly instead of silently rewriting docs to fit assumptions.
- **Verify (@Sentinel):** Docs match code and verified live DB reality, and all introduced wrappers/contracts/tests are documented.

## 7) Acceptance Criteria (MANDATORY)

- Management note success logs contain no raw note content.
- Every management read path uses a verified scope that includes both `related_entity_id` and `related_entity_type`.
- Failed note sends preserve the draft text and surface a visible error state.
- Load failure is visually distinct from a true empty timeline in both task and booking embeddings.
- RLS remains the source of truth for private/public/non-participant access, and live DB confirmation exists before rollout.
- Task and booking host screens both use the corrected management contract without divergent provider wiring behavior.
- No direct UI -> Supabase calls are introduced in the management view layer.
- Management unit/widget tests cover scope filtering, draft retention, error-state rendering, and private-note rendering behavior.
- Any doc drift for management paths/contracts is corrected and the live-DB gap is explicitly reconciled.
- If DB changes are required, they are additive-first, reversible, and verified against live query/policy behavior.

## 8) Rollback Plan

- DB rollback/forward-fix steps:
  - avoid DB changes unless Phase 1.0 proves they are required
  - if an index/policy/helper migration is introduced, prefer forward-fix over destructive rollback once app code depends on it
  - preserve older compatible DB behavior during any compatibility window documented in `.TODO/MIGRATION_Management_2026-03-01.md`
- app rollback (flag/revert):
  - revert the management scope-contract refactor in one commit if task/booking embeddings break
  - revert logging and error-state changes independently if needed while keeping DB-safe fixes
  - keep compatibility wrappers/facades temporarily if service splitting occurs
- emergency disable strategy (if applicable):
  - hide or disable note composer CTA in the app if live DB/RLS verification fails after rollout preparation
  - fall back to read-only timeline mode if write-path integrity is in doubt
  - pause rollout if private-note visibility cannot be proven by live RLS checks

## 9) References (From Scan)

- Workflow instruction:
  - `.agents/workflows/planner.md`
- Existing audit baseline:
  - `.TODO/management.TODO.md`
- Docs scanned:
  - `Sline_everything/DEVELOPER_GUIDE.md`
  - `Sline_everything/DEVELOPER_GUIDE/Order_Management_Feature.md`
  - `Sline_everything/SUPABASE_SETUP.md`
  - `Sline_everything/MVP_ROADMAP.md`
  - `Sline_everything/ARCHITECTURE_ANALYSIS.md`
  - `Sline_everything/CODE_REVIEW.md`
  - `Sline_everything/STRUCTURE.md`
- App/code scanned:
  - `lib/features/management/services/work_log_service.dart`
  - `lib/features/management/viewmodels/order_management_view_model.dart`
  - `lib/features/management/view/order_management_panel.dart`
  - `lib/features/management/view/widgets/work_log_tile.dart`
  - `lib/features/management/models/work_log_model.dart`
  - `lib/features/tasks/view/task_details_screen.dart`
  - `lib/features/booking/view/booking_details_screen.dart`
  - `lib/core/services/logger_service.dart`
  - `lib/core/utils/error_mapper.dart`
  - `lib/core/utils/format_date.dart`
  - `lib/core/widgets/signed_avatar.dart`
- Live Supabase scan evidence:
  - `@mcp:supabase-mcp-server:` scan results are still missing in this session and must be captured in Phase 1.0 before execution begins.
