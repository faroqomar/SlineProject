# 📌 Plan: Proposals Remediation

## 1) Goal

- Goal: eliminate the verified proposal authorization, payment-integrity, architecture, and test gaps in the current tender proposal flow, then consolidate the runtime under `lib/features/proposals`. References: `lib/features/tasks/services/task_requests_service.dart:5-299`, `lib/features/tasks/services/task_service.dart:513-920`, `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:16-301`, `lib/features/dashboard/view/tabs/inbox_tab.dart:64-146`, `lib/features/work/view/work_item_details_screen.dart:206-234`
- Why: the current code still contains caller-spoofable `SECURITY DEFINER` RPC contracts, a client-side role mutation, a split non-QiCard finalize path, feature-boundary drift, and missing proposal-focused tests. References: `supabase/migrations/20260313000000_tender_assign_only_after_payment.sql:11-189`, `supabase/migrations/20260315000000_award_to_work_cancel_and_view.sql:6-84`, `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:652-693`, `lib/features/tasks/services/task_requests_service.dart:106-121`, `lib/features/tasks/services/task_service.dart:749-799`, `test/unit/models/task_request_model_test.dart:24-105`, `test/unit/tasks/tender_payment_coordinator_test.dart:13-113`, `test/widget/tasks/tender_payment_screen_test.dart:10-51`
- Result: a server-authoritative, MVVM-compliant proposal feature with atomic payment finalization, RLS-safe reads, unified launchers, server-derived resume data, verified regression coverage, and synced documentation. References: `Sline_everything/DEVELOPER_GUIDE.md:41-68`, `Sline_everything/STRUCTURE.md:83-103`, `Sline_everything/CODE_REVIEW.md:12-25`

## 2) Scope

### In-Scope

- Proposal submit, replace, review, reject, award, resume-payment, and finalize-payment flows. References: `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart:14-325`, `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:16-301`, `lib/features/tasks/viewmodels/task_requests_view_model.dart:8-260`, `lib/features/tasks/services/task_requests_service.dart:5-299`, `lib/features/tasks/services/task_service.dart:513-920`
- Proposal launchers from task details, dashboard tabs, next-actions, and work item details. References: `lib/features/tasks/view/task_details_screen.dart:218-254`, `lib/features/tasks/view/task_details_screen.dart:668-681`, `lib/features/dashboard/view/tabs/inbox_tab.dart:64-146`, `lib/features/dashboard/view/tabs/work_tab.dart:286-317`, `lib/features/dashboard/view/widgets/next_actions_list.dart:102-135`, `lib/features/work/view/work_item_details_screen.dart:206-234`
- Direct dependencies touched by the proposal flow: profile summaries, favorites interaction, dashboard loaders, payment services, unified work items, and app DI wiring. References: `lib/features/profile/services/profile_summary_service.dart:13-33`, `lib/features/favorites/data/favorites_service.dart:52-66`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:515-760`, `lib/core/services/payment_service.dart:309-325`, `lib/core/services/qicard_payment_service.dart:491-640`, `lib/features/work/services/work_management_service.dart:24-150`, `lib/main.dart:196-199`
- Proposal-related Supabase objects: `task_requests`, `tasks`, `profiles`, `favorites`, `notifications`, `conversations`, `messages`, `vw_unified_work_items`, proposal/payment RPCs, and QiCard tender edge functions. References: `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:53-102`, `supabase/migrations/20260313000000_tender_assign_only_after_payment.sql:11-189`, `supabase/migrations/20260315000000_award_to_work_cancel_and_view.sql:6-186`, `supabase/migrations/20260311000000_replace_task_request.sql:5-81`, `supabase/functions/qicard_payment_create_tender/index.ts:22-149`, `supabase/functions/qicard_payment_recovery_tender/index.ts:20-139`

### Out-of-Scope

- Unrelated booking-only flows except where shared ledger or payment helpers are directly reused by the proposal path. References: `lib/features/booking/services/booking_service.dart`, `lib/core/services/payment_service.dart:309-325`
- Direct-offer runtime and non-proposal chat features, except for proposal-triggered notification/message side effects that share the same server contracts. References: `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:337-468`
- Storage or realtime changes unless the live Supabase scan proves proposal-specific objects exist; no such usage was verified from the audited codebase. References: `lib/features/tasks/services/task_requests_service.dart:5-299`, `lib/features/proposals/view/proposal_details_modal.dart:10-348` ; status: `UNVERIFIED` for live DB until MCP auth is available

## 3) Evidence & Findings (From Scan)

### Existing

- The documented architecture contract requires feature-local MVVM structure and forbids UI-to-backend calls outside ViewModels/services. References: `Sline_everything/DEVELOPER_GUIDE.md:43-62`, `Sline_everything/STRUCTURE.md:97-103`
- The live runtime proposal flow is not centered in `lib/features/proposals`; it is spread across `tasks`, `dashboard`, and `work`, while `lib/features/proposals` contains only a stub modal. References: `lib/features/proposals/view/proposal_details_modal.dart:10-348`, `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:16-301`, `lib/features/dashboard/view/tabs/inbox_tab.dart:64-146`, `lib/features/work/view/work_item_details_screen.dart:206-234`
- The current database/docs intent includes `task_requests`, `tasks`, `profiles`, notifications, ledger-backed payment handling, and `vw_unified_work_items` as proposal-adjacent objects. References: `Sline_everything/SUPABASE_SETUP.md:20-56`, `supabase/migrations/20260317000000_fix_task_request_amount_gross.sql:1-22`, `supabase/migrations/20260315000000_award_to_work_cancel_and_view.sql:86-186`
- The current proposal award/pay flow is routed through RPCs and tender payment helpers, not direct table writes from UI. References: `lib/features/tasks/services/task_service.dart:730-858`, `lib/features/tasks/services/tender_payment_coordinator.dart:7-105`, `lib/features/tasks/view/tender_payment_screen.dart:11-348`
- The current roadmap still claims tender payment is completed and that proposal submit no longer mutates `active_role`. References: `Sline_everything/MVP_ROADMAP.md:45-49`
- The code review guardrails require consolidated runtime surfaces to remove orphaned feature trees, stale providers, and duplicate navigation paths in the same patch. References: `Sline_everything/CODE_REVIEW.md:12-25`

### Missing

- A real proposals module containing the active model, repository/service, ViewModel, screens, and route helpers is missing. References: `lib/features/proposals/view/proposal_details_modal.dart:10-348`, `Sline_everything/STRUCTURE.md:97-103`
- A verified live Supabase scan for proposal tables/views/RPCs/policies/indexes/storage/realtime is missing in this session because the configured MCP server requires authentication. References: `@mcp:supabase-mcp-server:` attempted on `2026-03-04`; result: `Auth required`; status: `UNVERIFIED`
- Proposal-specific contract, threat-model, RLS-matrix, migration, and observability artifacts under `.TODO/` are missing. References: `.TODO/proposals.TODO.md:1-257`, `.TODO/` contents inferred from `Sline_everything/STRUCTURE.md:35-43`
- Proposal-specific unit/widget/integration coverage is missing for submit/replace/reject/award/resume/RLS abuse paths. References: `test/unit/models/task_request_model_test.dart:24-105`, `test/unit/tasks/tender_payment_coordinator_test.dart:13-113`, `test/widget/tasks/tender_payment_screen_test.dart:10-51`
- A server-derived payment deadline contract for resume surfaces is missing from the Flutter model currently used by Inbox and payment launchers. References: `lib/features/tasks/models/task_request_model.dart:10-39`, `lib/features/dashboard/view/tabs/inbox_tab.dart:72-90`

### Must NOT Duplicate

- Do not create a second profile-summary path if the existing RPC can be safely narrowed or a proposal-specific variant can replace it without leaving two overlapping public contracts. References: `lib/features/profile/services/profile_summary_service.dart:13-33`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:3-47`
- Do not keep duplicate tender payment launcher construction after adding a route helper. References: `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:143-167`, `lib/features/dashboard/view/tabs/inbox_tab.dart:72-95`, `lib/features/dashboard/view/tabs/work_tab.dart:294-317`, `lib/features/dashboard/view/widgets/next_actions_list.dart:110-135`, `lib/features/work/view/work_item_details_screen.dart:210-234`
- Do not preserve both `TaskRequestsService` and a new proposal repository as parallel active data sources after migration. References: `lib/features/tasks/services/task_requests_service.dart:5-299`, `lib/features/tasks/viewmodels/task_requests_view_model.dart:15-21`
- Do not keep the stub `ProposalDetailsModal` as an orphaned runtime surface if the active proposal UI is moved into `lib/features/proposals`. References: `lib/features/proposals/view/proposal_details_modal.dart:10-348`, `Sline_everything/CODE_REVIEW.md:15-25`

### Conflicts / Risks (docs vs code vs live DB drift, naming mismatches, security/migration risks)

- Docs say proposal/tender payment is completed and submit no longer mutates `active_role`, but the current code still updates `profiles.active_role` from the client during proposal submit. References: `Sline_everything/MVP_ROADMAP.md:45-49`, `lib/features/tasks/services/task_requests_service.dart:106-121`
- Docs describe feature-based MVVM organization, but the active proposal runtime remains fragmented outside `lib/features/proposals`. References: `Sline_everything/DEVELOPER_GUIDE.md:43-62`, `Sline_everything/STRUCTURE.md:97-103`, `lib/features/proposals/view/proposal_details_modal.dart:10-348`, `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:16-301`
- Current proposal RPC definitions are security-sensitive and caller-spoofable unless rewritten to bind auth inside the server function body. References: `supabase/migrations/20260313000000_tender_assign_only_after_payment.sql:11-189`, `supabase/migrations/20260315000000_award_to_work_cancel_and_view.sql:6-84`, `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:652-693`, `supabase/migrations/20260226_tender_award_payment_flow.sql:328-367`
- Current non-QiCard finalize logic can leave ledger/accounting and task/proposal state out of sync if the second step fails. References: `lib/features/tasks/services/task_service.dart:749-799`, `lib/features/tasks/services/tender_payment_coordinator.dart:77-92`
- Live-database drift is currently `UNVERIFIED` because the required Supabase MCP scan could not authenticate in this session; no destructive DB decisions should be made until that gate is cleared. References: `@mcp:supabase-mcp-server:` attempted on `2026-03-04`; result: `Auth required`

## 4) System Impact Map

- UI: task-details proposal CTA, submit sheet, requests list, dashboard Inbox/Work/Next Actions, work details resume path, payment screen, and the stub proposals modal all change. References: `lib/features/tasks/view/task_details_screen.dart:218-254`, `lib/features/tasks/view/task_details_screen.dart:668-681`, `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:16-301`, `lib/features/dashboard/view/tabs/inbox_tab.dart:64-146`, `lib/features/dashboard/view/tabs/work_tab.dart:286-317`, `lib/features/dashboard/view/widgets/next_actions_list.dart:102-135`, `lib/features/work/view/work_item_details_screen.dart:206-234`, `lib/features/proposals/view/proposal_details_modal.dart:10-348`
- MVVM/App Logic: model/repository/service/ViewModel ownership moves from `tasks` into `proposals`, DI must become explicit, and legacy compatibility methods must be retired. References: `lib/features/tasks/models/task_request_model.dart:8-202`, `lib/features/tasks/services/task_requests_service.dart:5-299`, `lib/features/tasks/viewmodels/task_requests_view_model.dart:8-260`, `lib/main.dart:196-199`
- Database: touched objects include `task_requests`, `tasks`, `profiles`, `favorites`, `notifications`, `conversations`, `messages`, `vw_unified_work_items`, proposal RPCs, and ledger finalize helpers. References: `Sline_everything/SUPABASE_SETUP.md:20-56`, `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:53-102`, `supabase/migrations/20260315000000_award_to_work_cancel_and_view.sql:86-186`
- RLS/Security: `task_requests` policies, `profiles_select_self`, cross-user profile summary scope, actor-bound `SECURITY DEFINER` RPCs, and role-switch side effects are the primary security boundary. References: `supabase/migrations/20260301_harden_home_related_read_policies.sql:23-31`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:3-47`, `supabase/migrations/20260313000000_tender_assign_only_after_payment.sql:11-189`, `lib/features/tasks/services/task_requests_service.dart:106-121`
- Realtime/Notifications (if any): server-generated notifications remain in scope; no proposal-specific realtime subscription was verified locally and must remain unchanged unless the live scan proves otherwise. References: `supabase/migrations/20260313000000_tender_assign_only_after_payment.sql:78-104`, `supabase/migrations/20260315000000_award_to_work_cancel_and_view.sql:63-77`; proposal realtime status: `UNVERIFIED`
- Storage: no proposal-specific storage object was verified in code; no storage changes are planned unless the live scan contradicts this. References: `lib/features/tasks/services/task_requests_service.dart:5-299`, `lib/features/proposals/view/proposal_details_modal.dart:10-348`; storage status: `UNVERIFIED` live
- Observability (if any): payment and proposal transition logging should move into repositories/services and payment finalize server code, with no PII or sensitive profile leakage. References: `Sline_everything/DEVELOPER_GUIDE.md:56-60`, `lib/features/tasks/services/task_service.dart:749-799`, `lib/features/tasks/services/tender_payment_coordinator.dart:77-92`
- Compatibility & Migration: plan must stay additive-first, keep compatibility wrappers during path moves, and avoid drops/renames until Flutter callers are switched and verified. References: `Sline_everything/DEVELOPER_GUIDE.md:49-50`, `Sline_everything/CODE_REVIEW.md:20-25`
- Contracts: Flutter model shapes, route arguments, owner/freelancer resume payloads, profile summary outputs, and award/finalize RPC signatures all change together and require a locked contract document. References: `lib/features/tasks/models/task_request_model.dart:8-202`, `lib/features/tasks/viewmodels/tender_payment_view_model.dart:5-202`, `lib/features/profile/services/profile_summary_service.dart:13-33`, `lib/features/tasks/services/task_service.dart:730-858`

---

# ✅ Execution Phases (Checklist)

## Phase 0: Preconditions & Gates

> Primary: @Sentinel

### 0.1 Spec Lock

- [ ] (@Sentinel) Freeze the proposal remediation acceptance list around the verified defects: actor-spoofable RPC auth, client-side role mutation, non-atomic finalize path, RLS-unsafe profile joins, dashboard resume drift, feature-fragmentation, dead stub UI, and missing tests. References: `supabase/migrations/20260313000000_tender_assign_only_after_payment.sql:11-189`, `lib/features/tasks/services/task_requests_service.dart:106-121`, `lib/features/tasks/services/task_service.dart:749-799`, `lib/features/tasks/services/task_requests_service.dart:50-76`, `lib/features/dashboard/view/tabs/inbox_tab.dart:72-146`, `lib/features/proposals/view/proposal_details_modal.dart:10-348`
- [ ] (@Architect) Confirm the surviving runtime entry points and final rename map into `lib/features/proposals`, including temporary compatibility exports during migration. References: `lib/features/tasks/view/task_details_screen.dart:218-254`, `lib/features/tasks/view/task_details_screen.dart:668-681`, `lib/features/dashboard/view/tabs/inbox_tab.dart:64-146`, `lib/features/work/view/work_item_details_screen.dart:206-234`
- [ ] (@Pixel) Lock terminology and UX copy so the final surface consistently uses English-only proposal/payment language instead of mixed "offer/request/proposal" terminology. References: `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:184-239`, `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:74-91`, `Sline_everything/DEVELOPER_GUIDE.md:66-68`
- **Verify (@Sentinel):** done-conditions, stop-conditions, and rollback triggers are written before any code or SQL changes begin.

### 0.2 Threat Model (If sensitive/high-risk)

- [ ] (@ThreatModeler) Create `.TODO/THREAT_MODEL_proposals_2026-03-04.md` covering actor spoofing in proposal RPCs, cross-user proposal/profile reads, partial payment finalization, role-side-effect abuse, self-favorite misuse, and replay/idempotency risks. References: `supabase/migrations/20260313000000_tender_assign_only_after_payment.sql:11-189`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:3-47`, `lib/features/tasks/services/task_requests_service.dart:106-121`, `lib/features/tasks/services/task_service.dart:749-799`, `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:50-65`
- [ ] (@ThreatModeler) Define negative test actors for anon, unrelated authenticated user, freelancer, client/owner, and admin-equivalent paths; proposals have money/security scope so this phase is mandatory. References: `Sline_everything/DEVELOPER_GUIDE.md:45-60`, `Sline_everything/SUPABASE_SETUP.md:20-56`
- **Verify (@Sentinel):** every threat maps to a concrete SQL, app, or QA check in Phase 4.

### 0.3 Contracts (If payloads change)

- [ ] (@APIContract) Create `.TODO/CONTRACT_proposals_rpc_and_models_2026-03-04.md` that defines the authoritative proposal model, payment summary model, resume payload, owner/freelancer permissions, and replacement/finalize RPC shapes before implementation. References: `lib/features/tasks/models/task_request_model.dart:8-202`, `lib/features/tasks/viewmodels/tender_payment_view_model.dart:5-202`, `lib/features/tasks/services/task_service.dart:730-858`
- [ ] (@APIContract) Lock the minimum proposal profile shape needed by UI so cross-user lookup does not continue exposing `bio`, `active_role`, `skills`, and `seller_level` unless product explicitly requires them. References: `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:3-39`, `lib/features/tasks/services/task_service.dart:47-69`, `lib/features/tasks/services/task_service.dart:515-572`
- **Verify (@Sentinel):** contract fields, nullability, and status enums match live schema reality once the Supabase MCP gate is cleared.

### 0.4 Migration Plan (If schema/data changes)

- [ ] (@DataMigration) Create `.TODO/MIGRATION_proposals_2026-03-04.md` with introduce/backfill/enforce/cleanup sequencing, release order, rollback, and compatibility window. References: `Sline_everything/DEVELOPER_GUIDE.md:49-50`, `Sline_everything/SUPABASE_SETUP.md:10`
- [ ] (@DataMigration) Reserve additive-first migration slots for the proposal fix sequence: `supabase/migrations/20260304060000_secure_proposal_rpc_contract.sql`, `supabase/migrations/20260304061000_narrow_rpc_get_profile_summaries_for_proposals.sql` or a contract-compatible alternative, `supabase/migrations/20260304062000_finalize_awarded_offer_payment.sql`, and a deadline/resume contract migration only if the live scan proves no equivalent server field already exists. References: `supabase/migrations/20260313000000_tender_assign_only_after_payment.sql:11-189`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:3-47`
- **Verify (@Sentinel):** the migration plan has a measurable compatibility window and no drops/renames in the first rollout.

### 0.5 Feature Flag/Rollout (If risky)

- [ ] (@Architect) Use phased rollout via additive SQL + compatibility exports + route helper adoption; no verified proposals feature flag exists today, so rollout risk must be handled by sequencing rather than assumptions. References: `lib/main.dart:196-199`, `Sline_everything/CODE_REVIEW.md:20-25`; feature flag status: `UNVERIFIED`
- [ ] (@Observability) Define rollback triggers for finalize failures, unauthorized RPC attempts, and missing awarded-unpaid resume records before rollout. References: `lib/features/tasks/services/task_service.dart:749-799`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:615-647`
- **Verify (@Sentinel):** rollout order and emergency disable path are documented before Phase 1 execution.

---

## Phase 1: Database & Security (If applicable)

> Primary: @Supabase_Ops

### 1.0 Live Supabase Confirmation (MANDATORY)

- [ ] (@Supabase_Ops) Authenticate and re-scan the live Supabase project via `@mcp:supabase-mcp-server:` for `task_requests`, `tasks`, `profiles`, `favorites`, `notifications`, `conversations`, `messages`, `vw_unified_work_items`, proposal/payment RPCs, indexes, buckets, and realtime publication state. Current status: `UNVERIFIED` because MCP auth failed on `2026-03-04`.
- [ ] (@Supabase_Ops) Compare live objects against repo migrations and docs, then record every drift item before writing SQL; treat docs as intent and live scan as reality. References: `Sline_everything/SUPABASE_SETUP.md:1-10`, `Sline_everything/MVP_ROADMAP.md:45-49`
- **Verify (@Sentinel):** all drift and safe reconcile steps are recorded before any migration is executed.

### 1.1 Schema (Additive-first)

- [ ] (@Supabase_Ops) Confirm whether a server-owned payment-deadline or resume field already exists for awarded proposals; if absent, add an additive field or view contract so UI no longer fabricates `DateTime.now() + 24h`. References: `lib/features/dashboard/view/tabs/inbox_tab.dart:72-90`, `lib/features/tasks/models/task_request_model.dart:10-39`; live field status: `UNVERIFIED`
- [ ] (@Supabase_Ops) Add or refine indexes only for the final query shapes used by awarded-unpaid and pending-payment proposal surfaces after live explain verification; preserve existing indexes until replacements are proven. References: `supabase/migrations/20260316000000_task_requests_view_index.sql:1-4`, `lib/features/tasks/services/task_service.dart:860-900`
- [ ] (@DataMigration) Backfill any new additive proposal resume fields from existing server timestamps/state, without changing ownership semantics or historical payment status. References: `supabase/migrations/20260313000000_tender_assign_only_after_payment.sql:11-189`
- **Verify (@Sentinel):** schema changes are additive-first, query-backed, and do not break existing app versions during the compatibility window.

### 1.2 RLS

- [ ] (@Supabase_Ops) Re-audit `task_requests` and `profiles` access so owner proposal reads become RLS-safe without weakening `profiles_select_self` unless the threat model explicitly proves that change is necessary. References: `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:53-102`, `supabase/migrations/20260301_harden_home_related_read_policies.sql:23-31`, `lib/features/tasks/services/task_requests_service.dart:50-76`
- [ ] (@Supabase_Ops) Create `.TODO/RLS_MATRIX_proposals_2026-03-04.md` covering positive/negative access for submit, replace, reject, award, resume, cancel, and read flows by role and non-party actor. References: `Sline_everything/DEVELOPER_GUIDE.md:45-60`
- [ ] (@ThreatModeler) Add explicit negative checks for cross-user profile summary access and actor-spoof attempts on every proposal RPC. References: `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:3-47`, `supabase/migrations/20260313000000_tender_assign_only_after_payment.sql:11-189`
- **Verify (@Sentinel):** all allowed reads pass and all non-party / spoofed reads fail under the final matrix.

### 1.3 Triggers/RPC (If needed)

- [ ] (@Supabase_Ops) Patch `award_task_offer`, `pay_awarded_offer`, `cancel_awarded_offer`, `get_client_awarded_unpaid_offers`, and `get_freelancer_awarded_unpaid_offers` so authorization binds to `auth.uid()` inside the function body and caller-supplied actor IDs are either removed or ignored. References: `supabase/migrations/20260313000000_tender_assign_only_after_payment.sql:11-189`, `supabase/migrations/20260315000000_award_to_work_cancel_and_view.sql:6-84`, `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:652-693`, `supabase/migrations/20260226_tender_award_payment_flow.sql:328-367`
- [ ] (@Supabase_Ops) Introduce a server-owned atomic finalize RPC for non-QiCard tender payments that wraps ledger event processing, proposal/task state transition, and idempotency so the client cannot create ledger-only success states. References: `lib/features/tasks/services/task_service.dart:749-799`, `supabase/functions/_shared/bookin_payment.ts:383-437`
- [ ] (@Supabase_Ops) Narrow the public profile-summary contract for proposal reads, either by replacing `rpc_get_profile_summaries` for proposal use or by introducing a minimum-field proposal-specific RPC. References: `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:3-39`, `lib/features/profile/services/profile_summary_service.dart:21-33`
- [ ] (@APIContract) Preserve a short-lived compatibility layer if RPC signatures change so old app code does not fail mid-rollout. References: `lib/features/tasks/services/task_service.dart:730-858`
- **Verify (@Sentinel):** authorization is server-owned, finalize is atomic/idempotent, and no proposal RPC leaks cross-user data beyond the locked contract.

### 1.4 Migration Execution (If needed)

- [ ] (@DataMigration) Apply introduce migrations first on staging, verify with targeted SQL, switch app callers, then enforce or narrow deprecated wrappers only after the new app path is confirmed stable.
- [ ] (@DataMigration) Keep old wrappers or compatibility views until the Flutter rollout is complete; do not drop prior contracts in the first remediation release. References: `Sline_everything/CODE_REVIEW.md:20-25`
- **Verify (@Sentinel):** migration verify queries and staged app builds pass before any cleanup migration is approved.

---

## Phase 2: App Layer (MVVM)

> Primary: @Architect

### 2.1 Models & Contract Compliance

- [ ] (@Architect) Create `lib/features/proposals/models/proposal_model.dart` from the current `TaskRequest` shape and add only contract-backed fields such as server-provided payment deadline, display title, and explicit capability/status fields. References: `lib/features/tasks/models/task_request_model.dart:8-202`
- [ ] (@Architect) Create `lib/features/proposals/models/proposal_payment_summary.dart` so all resume launchers consume one typed payload instead of reconstructing ad hoc route arguments. References: `lib/features/dashboard/view/tabs/inbox_tab.dart:72-95`, `lib/features/dashboard/view/tabs/work_tab.dart:294-317`, `lib/features/work/view/work_item_details_screen.dart:210-234`
- [ ] (@APIContract) Update mapping and error contracts for submit/replace/reject/award/finalize failures so ViewModels receive stable domain errors, not transport-specific ambiguity. References: `lib/core/utils/error_mapper.dart`, `lib/features/tasks/services/task_requests_service.dart:190-265`, `lib/features/tasks/services/task_service.dart:730-858`
- **Verify (@Sentinel):** model types, nullability, enums, and route payloads match the locked contract and no screen fabricates missing server state.

### 2.2 Services/Repositories

- [ ] (@Architect) Move `lib/features/tasks/services/task_requests_service.dart` into `lib/features/proposals/data/proposal_repository.dart` and split award/payment logic out of `lib/features/tasks/services/task_service.dart` into `lib/features/proposals/data/proposal_award_repository.dart`. References: `lib/features/tasks/services/task_requests_service.dart:5-299`, `lib/features/tasks/services/task_service.dart:513-920`
- [ ] (@Architect) Remove the client-side `profiles.active_role` mutation from submit and replace it with an explicit role requirement/error surfaced through the ViewModel. References: `lib/features/tasks/services/task_requests_service.dart:106-121`, `Sline_everything/MVP_ROADMAP.md:45-49`
- [ ] (@Architect) Replace direct `profiles!task_requests_freelancer_id_fkey(...)` joins with the final RLS-safe profile summary contract and keep owner/freelancer proposal reads in one repository. References: `lib/features/tasks/services/task_requests_service.dart:8-13`, `lib/features/tasks/services/task_requests_service.dart:50-89`, `lib/features/profile/services/profile_summary_service.dart:13-33`
- [ ] (@Architect) Create `lib/features/proposals/routes/proposal_payment_route.dart` so every launcher constructs the payment flow in one place. References: `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:143-167`, `lib/features/dashboard/view/tabs/inbox_tab.dart:72-95`, `lib/features/dashboard/view/tabs/work_tab.dart:294-317`, `lib/features/dashboard/view/widgets/next_actions_list.dart:110-135`, `lib/features/work/view/work_item_details_screen.dart:210-234`
- [ ] (@Architect) Enforce the documented MVVM rule that views use ViewModels only and do not directly reach services/Supabase. References: `Sline_everything/DEVELOPER_GUIDE.md:54-62`, `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart:254-301`
- **Verify (@Sentinel):** app-layer code is RLS-safe, single-sourced, DI-friendly, and free of UI-to-service bypasses.

### 2.3 ViewModels

- [ ] (@Architect) Create `lib/features/proposals/viewmodels/proposals_view_model.dart` and `lib/features/proposals/viewmodels/proposal_payment_view_model.dart`, then inject dependencies from `main.dart` instead of constructing new service instances internally. References: `lib/features/tasks/viewmodels/task_requests_view_model.dart:15-21`, `lib/features/tasks/viewmodels/tender_payment_view_model.dart:5-202`, `lib/main.dart:196-199`
- [ ] (@Architect) Replace legacy compatibility methods and duplicate state paths only after migration cutover: `payForAwardedOffer()`, legacy `accept()`, deprecated dashboard `acceptOffer()`, and any unused awarded-unpaid getters. References: `lib/features/tasks/viewmodels/task_requests_view_model.dart:147-191`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:737-760`, `lib/features/tasks/services/task_service.dart:830-858`
- [ ] (@Architect) Replace heavy full-list refetches with local state reconciliation for mutate-one-row actions once repository responses are contract-stable. References: `lib/features/tasks/viewmodels/task_requests_view_model.dart:119-181`
- **Verify (@Sentinel):** ViewModels become the single source of truth, state transitions are recoverable, and deprecated paths are removed only after cutover.

### 2.4 Observability (If needed)

- [ ] (@Observability) Create `.TODO/OBSERVABILITY_proposals_2026-03-04.md` listing correlation IDs and events for proposal submit attempts, proposal replacement, award start, payment resume opened, finalize success/failure, and authorization rejection.
- [ ] (@Architect) Instrument repository/service/ViewModel layers only; do not log raw payment payloads, private profile fields, or cross-user data. References: `Sline_everything/DEVELOPER_GUIDE.md:56-60`, `lib/features/tasks/services/task_service.dart:749-799`
- [ ] (@ThreatModeler) Review proposed logs for PII leakage and abuse signal quality before release.
- **Verify (@Sentinel):** telemetry is actionable, privacy-safe, and sufficient to detect finalize regressions during rollout.

---

## Phase 3: UI (After logic)

> Primary: @Pixel

### 3.1 Wiring

- [ ] (@Pixel) Move the active proposal runtime UI into `lib/features/proposals/view/proposals_list_screen.dart`, `lib/features/proposals/view/widgets/submit_proposal_sheet.dart`, `lib/features/proposals/view/widgets/proposal_tile.dart`, and `lib/features/proposals/view/proposal_payment_screen.dart`. References: `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:16-301`, `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart:14-325`, `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:9-132`, `lib/features/tasks/view/tender_payment_screen.dart:11-348`
- [ ] (@Pixel) Update task-details, dashboard Inbox/Work/Next Actions, and work-item-details launchers to use `proposal_payment_route.dart` and the final typed resume payload. References: `lib/features/tasks/view/task_details_screen.dart:218-254`, `lib/features/tasks/view/task_details_screen.dart:668-681`, `lib/features/dashboard/view/tabs/inbox_tab.dart:64-146`, `lib/features/dashboard/view/tabs/work_tab.dart:286-317`, `lib/features/dashboard/view/widgets/next_actions_list.dart:102-135`, `lib/features/work/view/work_item_details_screen.dart:206-234`
- [ ] (@Pixel) Remove or replace `lib/features/proposals/view/proposal_details_modal.dart`; if there is no surviving product requirement, delete it after call sites are proven absent. References: `lib/features/proposals/view/proposal_details_modal.dart:10-348`, `Sline_everything/CODE_REVIEW.md:15-25`
- [ ] (@Pixel) Fix the verified UI correctness issues: auto-open scheduling from `build()`, UUID-as-title in payment, fabricated Inbox deadline, and non-owner favorite mis-scope. References: `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:153-217`, `lib/features/dashboard/view/tabs/inbox_tab.dart:72-90`, `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:50-65`
- [ ] (@Pixel) Keep all user-facing strings in English and standardize naming on the final chosen proposal terminology. References: `Sline_everything/DEVELOPER_GUIDE.md:66-68`
- **Verify (@Sentinel):** UI uses ViewModels only, slow/empty/error states remain stable, and the payment resume experience is consistent across all launchers.

### 3.2 Polish (Optional)

- [ ] (@Pixel) Add only low-risk UX polish such as consistent empty/error copy and disabled submit/pay states; do not introduce layout churn during the remediation release.
- [ ] (@Pixel) Keep route transitions and rebuild behavior stable, especially around bottom sheets and payment flow returns. References: `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:205-217`
- **Verify (@Sentinel):** no performance or navigation regression appears in rebuild-heavy flows.

---

## Phase 4: QA + Security (MANDATORY)

> Primary: @Sentinel

### 4.1 Contract + Migration Checks

- [ ] (@Sentinel) Run `flutter analyze lib/features/proposals lib/features/tasks lib/features/profile lib/core`.
- [ ] (@Sentinel) Run existing regression tests, then new proposal suites once added: `flutter test test/unit/models/task_request_model_test.dart test/unit/tasks/tender_payment_coordinator_test.dart test/widget/tasks/tender_payment_screen_test.dart` and `flutter test test/unit/proposals test/widget/proposals`.
- [ ] (@Sentinel) Execute SQL verify queries for final RPC signatures, policies, indexes, deadline/resume fields, and compatibility wrappers against the live-scanned environment.
- **Verify (@Sentinel):** contract shapes, migrations, and app callers all match with no drift.

### 4.2 Security + Abuse Tests

- [ ] (@Sentinel) Execute the ThreatModeler negative matrix: spoof actor IDs on proposal RPCs, unauthorized cancel/pay/read, cross-user profile-summary queries, silent role mutation attempts, self-favorite misuse, and partial finalize recovery attempts.
- [ ] (@Sentinel) Audit logs and user-visible errors to ensure no private profile fields, actor UUIDs, or payment-sensitive data leak.
- [ ] (@ThreatModeler) Sign off on the final abuse-case results before release.
- **Verify (@Sentinel):** unauthorized access and partial-state corruption are no longer possible through the tested proposal paths.

### 4.3 Functional QA

- [ ] (@Sentinel) Run manual E2E scripts for freelancer submit/replace, owner review/reject/award, client resume payment from Requests/Inbox/Work/Next Actions, non-QiCard finalize, QiCard recovery, and freelancer pending-payment visibility.
- [ ] (@Sentinel) Cover edge cases: slow network, stale dashboard caches, repeated rebuilds after validation failure, session expiry during submit/pay, role mismatch, and retry after transient failure.
- **Verify (@Sentinel):** no crashes, duplicate sheets, missing resume records, or wrong deadlines/titles appear in the final flow.

### 4.4 Observability Validation (If included)

- [ ] (@Sentinel) Confirm the required logs/events exist and correlate award -> resume -> finalize without sensitive payloads.
- [ ] (@Observability) Validate alertability or at least queryability for finalize failure spikes and authorization rejection spikes during rollout.
- **Verify (@Sentinel):** telemetry is useful enough to support rollback decisions without exposing private data.

---

## Phase 5: Documentation Sync (MANDATORY)

> Primary: @SlineDocs

- [ ] (@SlineDocs) Update `Sline_everything/DEVELOPER_GUIDE.md`, `Sline_everything/SUPABASE_SETUP.md`, `Sline_everything/MVP_ROADMAP.md`, `Sline_everything/STRUCTURE.md`, and `Sline_everything/Sline_Log.md` so docs match the final proposal module paths, live RPC/RLS contracts, and rollout status. References: `Sline_everything/CODE_REVIEW.md:20-25`
- [ ] (@SlineDocs) Add or update a proposal-specific deep-dive under `Sline_everything/DEVELOPER_GUIDE/` if `lib/features/proposals` becomes the real runtime home for this feature. References: `Sline_everything/DEVELOPER_GUIDE.md:37-45`
- **Verify (@Sentinel):** docs match code and live DB reality, not historical intent.

## 7) Acceptance Criteria (MANDATORY)

- Proposal RPC authorization is bound to `auth.uid()` inside the server function bodies, and spoofed caller actor IDs no longer change read or mutation outcomes. References: `supabase/migrations/20260313000000_tender_assign_only_after_payment.sql:11-189`, `supabase/migrations/20260315000000_award_to_work_cancel_and_view.sql:6-84`
- Proposal submit no longer mutates `profiles.active_role` from the client, and role mismatch is surfaced as an explicit UX error instead. References: `lib/features/tasks/services/task_requests_service.dart:106-121`
- Non-QiCard proposal payment finalization is atomic and idempotent; there is no client path where ledger success survives proposal/task state failure. References: `lib/features/tasks/services/task_service.dart:749-799`, `supabase/functions/_shared/bookin_payment.ts:383-437`
- Owner and freelancer proposal reads are RLS-safe, and proposal UI does not rely on forbidden direct `profiles` joins. References: `lib/features/tasks/services/task_requests_service.dart:50-76`, `supabase/migrations/20260301_harden_home_related_read_policies.sql:23-31`
- Every payment resume surface uses the same typed route helper, shows the real task title, and displays a server-derived deadline. References: `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:153-167`, `lib/features/dashboard/view/tabs/inbox_tab.dart:72-95`, `lib/features/work/view/work_item_details_screen.dart:210-234`
- The active proposal runtime lives under `lib/features/proposals`, with DI-managed ViewModels/services and no stub-only feature folder remaining. References: `Sline_everything/STRUCTURE.md:97-103`, `lib/features/proposals/view/proposal_details_modal.dart:10-348`
- Proposal unit/widget/integration or SQL contract tests cover submit, replace, reject, award, resume, finalize, and abuse scenarios, and they pass in CI/local verification. References: `test/unit/models/task_request_model_test.dart:24-105`, `test/unit/tasks/tender_payment_coordinator_test.dart:13-113`, `test/widget/tasks/tender_payment_screen_test.dart:10-51`
- Documentation reflects the final code and live DB reality, including the prior docs drift around `active_role` mutation and proposal module ownership. References: `Sline_everything/MVP_ROADMAP.md:45-49`, `Sline_everything/DEVELOPER_GUIDE.md:43-62`

## 8) Rollback Plan

- DB rollback / forward-fix:
  - If the secure proposal RPC or atomic finalize rollout fails before Flutter is switched, revert only the newest additive proposal migrations or forward-fix them with wrapper functions; do not drop historical columns/objects in the emergency path.
  - If the app is already deployed against the new contract, prefer forward-fix wrappers that preserve the secured auth model rather than reverting to caller-spoofable RPC behavior.
  - Do not perform destructive cleanup migrations until staging and production verification pass through the compatibility window.
- App rollback:
  - Keep compatibility exports at old `tasks` paths until the `proposals` imports are fully cut over and validated.
  - If the structural move regresses navigation, roll back the file/path refactor while keeping the secured server-side SQL in place, then re-ship the app fix separately.
- Emergency disable strategy:
  - There is no verified proposals-specific feature flag today; emergency disable is a temporary UI guard on award/pay launchers plus a server-side deny or wrapper patch on the new finalize path if severe corruption risk is detected. Status: `UNVERIFIED` until the live scan confirms existing runtime toggles.

## 9) References (From Scan)

- `Sline_everything/DEVELOPER_GUIDE.md:41-68`
- `Sline_everything/SUPABASE_SETUP.md:1-56`
- `Sline_everything/MVP_ROADMAP.md:39-49`
- `Sline_everything/STRUCTURE.md:83-150`
- `Sline_everything/CODE_REVIEW.md:12-25`
- `lib/main.dart:196-199`
- `lib/features/proposals/view/proposal_details_modal.dart:10-348`
- `lib/features/tasks/models/task_request_model.dart:8-202`
- `lib/features/tasks/services/task_requests_service.dart:5-299`
- `lib/features/tasks/services/task_service.dart:513-920`
- `lib/features/tasks/services/tender_payment_coordinator.dart:7-105`
- `lib/features/tasks/viewmodels/task_requests_view_model.dart:8-260`
- `lib/features/tasks/viewmodels/tender_payment_view_model.dart:5-202`
- `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:16-301`
- `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart:14-325`
- `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:9-132`
- `lib/features/tasks/view/task_details_screen.dart:218-254`
- `lib/features/tasks/view/task_details_screen.dart:668-681`
- `lib/features/dashboard/viewmodels/dashboard_view_model.dart:515-760`
- `lib/features/dashboard/view/tabs/inbox_tab.dart:64-146`
- `lib/features/dashboard/view/tabs/work_tab.dart:286-317`
- `lib/features/dashboard/view/widgets/next_actions_list.dart:102-135`
- `lib/features/work/view/work_item_details_screen.dart:206-234`
- `lib/features/work/services/work_management_service.dart:24-150`
- `lib/features/profile/services/profile_summary_service.dart:13-33`
- `lib/features/favorites/data/favorites_service.dart:52-66`
- `lib/core/services/payment_service.dart:309-325`
- `lib/core/services/qicard_payment_service.dart:491-640`
- `supabase/migrations/20260226_tender_award_payment_flow.sql:328-367`
- `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:53-102`
- `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:337-468`
- `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:652-693`
- `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:3-47`
- `supabase/migrations/20260301_harden_home_related_read_policies.sql:23-31`
- `supabase/migrations/20260311000000_replace_task_request.sql:5-81`
- `supabase/migrations/20260312000000_profiles_update_own_for_active_role.sql:1-12`
- `supabase/migrations/20260313000000_tender_assign_only_after_payment.sql:11-189`
- `supabase/migrations/20260315000000_award_to_work_cancel_and_view.sql:6-186`
- `supabase/migrations/20260316000000_task_requests_view_index.sql:1-4`
- `supabase/migrations/20260317000000_fix_task_request_amount_gross.sql:1-22`
- `supabase/functions/_shared/bookin_payment.ts:97-166`
- `supabase/functions/_shared/bookin_payment.ts:383-437`
- `supabase/functions/qicard_payment_create_tender/index.ts:22-149`
- `supabase/functions/qicard_payment_recovery_tender/index.ts:20-139`
- `test/unit/models/task_request_model_test.dart:24-105`
- `test/unit/tasks/tender_payment_coordinator_test.dart:13-113`
- `test/widget/tasks/tender_payment_screen_test.dart:10-51`
- `@mcp:supabase-mcp-server:` attempted on `2026-03-04`; live scan blocked by authentication requirement; live DB evidence remains `UNVERIFIED` until authenticated re-scan completes
