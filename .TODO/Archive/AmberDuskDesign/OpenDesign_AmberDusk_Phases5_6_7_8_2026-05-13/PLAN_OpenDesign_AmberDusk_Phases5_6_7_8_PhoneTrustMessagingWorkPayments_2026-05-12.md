# PLANCRITIC CORRECTED PLAN: OpenDesign Amber Dusk Phone Phases 5-8

**Date:** 2026-05-12  
**Critic:** @PlanCritic  
**Input Draft:** `.TODO/PLAN_OpenDesign_AmberDusk_Phases5_6_7_8_PhoneTrustMessagingWorkPayments_2026-05-12.md`  
**Corrected Plan:** `.TODO/PLAN_OpenDesign_AmberDusk_Phases5_6_7_8_PhoneTrustMessagingWorkPayments_2026-05-12.md`  
**Critique Artifact:** `.TODO/PLAN_CRITIQUE_2026-05-12_OpenDesign_AmberDusk_Phases5_6_7_8_PhoneTrustMessagingWorkPayments.md`  
**Parent Plan:** `.TODO/PLAN_OpenDesign_AmberDusk_Phone_2026-05-10.md`  
**Session Log:** `docs/LOG/SESSION_PLAN_OpenDesign_AmberDusk_Phases5_6_7_8_PhoneTrustMessagingWorkPayments_2026-05-12.md`

This file is the corrected source-of-truth execution plan for the Phase 5-8 block. The pre-critique draft was useful but not strict enough to be an execution gate on its own.

## A) Assumptions + Decision Needed

### Assumptions

- [ ] (@PlanCritic) This is a planning and critique rewrite step only. Flutter source implementation remains out of scope until @Executor starts a later execution step.
- [ ] (@PlanCritic) The parent roadmap source remains `.TODO/PLAN_OpenDesign_AmberDusk_Phone_2026-05-10.md`, specifically master phases 5, 6, 7, and 8.
- [ ] (@PlanCritic) The active design source is Open Design project `1674a1db-7a74-4c80-8e2c-196a0385a8f7`, entry `Sline V2 Amber Dusk.html`, plus `amber-dusk-design-system.html` and `sline-v2-amber-dusk-web.html`.
- [ ] (@PlanCritic) Phase 0 and Phase 1 created a staged Amber Dusk token/widget adapter path under `lib/core/theme/designs/amber_dusk/`; this plan must consume that path without a global `MaterialApp` theme flip.
- [ ] (@PlanCritic) Phases 5-8 are visual/view-layer redesign phases. Backend, data contracts, ViewModels, repositories, services, Supabase migrations, Edge Functions, SQL tests, RLS, storage policies, and payment authority are unchanged unless a separate plan is created.
- [ ] (@PlanCritic) The plan may create and update planning, critique, session-log, visual QA, report, docs-sync, and Mohammed web handoff artifacts, but code edits are reserved for execution.
- [ ] (@PlanCritic) Runtime visual closure requires Flutter runtime screenshots or explicit manual runtime notes. Open Design reference screenshots alone do not prove implemented app parity.

### Decision Needed (Blocking)

No product decision remains blocking after this rewrite. @PlanCritic resolves the ambiguous draft decisions as follows:

1. **Phase 6 message mode copy**
   - Missing decision in draft: `Responses`/`Requests` versus `Received`/`Sent`.
   - Options: keep existing app `Responses`/`Requests`; change to Open Design `Received`/`Sent`; defer to Executor.
   - Recommended and selected: `Received`/`Sent`.
   - Why: Open Design search confirms `Received`/`Sent` in `Sline V2 Amber Dusk.html`, `amber-dusk-design-system.html`, and `sline-v2-amber-dusk-web.html`; Dashboard already uses `Received`/`Sent`.
   - Plan impact: Phase 6 must update Messages segmented copy to `Received`/`Sent` unless product explicitly reverses it.

2. **Phase 8 wallet withdrawal behavior**
   - Missing decision in draft: active `Withdraw` versus `Coming Soon`/current-product boundary.
   - Options: activate withdrawal UI now; preserve current behavior and only style existing preview/actions; block wallet styling.
   - Recommended and selected: preserve current behavior and do not add a new active withdrawal route or request form in this visual plan.
   - Why: The master Phase 8 plan calls out `Coming Soon`, `WalletSharedBody` currently exposes a Coming Soon withdrawal preview, and active withdrawal flow behavior has backend/security implications.
   - Plan impact: Phase 8 may style existing wallet cards and previews, but any new active withdrawal flow requires a separate product/backend/security plan.

3. **Missing exact Open Design targets**
   - Missing decision in draft: whether to pixel-match auth/gates, attachment tile, notification modal, proposal detail, and payment return/WebView states without exact phone evidence.
   - Options: invent exact layouts from nearby patterns; token-normalize/adapt only; block all touched surfaces.
   - Recommended and selected: token-normalize/adapt only until exact Open Design or user screenshot evidence exists.
   - Why: Missing evidence is a design-authority gap, not permission to invent.
   - Plan impact: each phase must label missing exact evidence and may not claim pixel parity for those surfaces.

4. **Font assets**
   - Missing decision inherited from earlier phases: whether to bundle Open Design font binaries.
   - Options: bundle provided binaries; use existing app/font strategy with role mapping; block typography work.
   - Recommended and selected: do not bundle Open Design font files without license/source evidence.
   - Plan impact: typography work uses existing approved font strategy and Amber Dusk role mapping only.

## B) Gate Status

| Gate | Draft Status | Corrected Status | Reason | Required Fix Included |
|---|---|---|---|---|
| Gate 0: Test Infrastructure Gate | PARTIAL | PASS AFTER CORRECTION | Draft listed tests and fixture notes but did not elevate them into a blocking gate table. | Added this gate, provider classification, auto-load setup, singleton cleanup, bounded pumps, and coverage-floor handling as source-of-truth requirements. |
| Data / Contracts Gate | PASS | PASS | No model, DTO, ViewModel, repository, service, Provider registration, route contract, or data-contract change is planned. | Added hard stop: any missing data needed for visual work becomes a separate contract plan. |
| Security / RLS Gate | PASS | PASS | No RLS, auth policy, storage policy, or privileged operation changes are planned. | Added explicit negative checks for no client-side notification insert, no signed URL/storage path exposure, no UI-only lifecycle/payment authority. |
| Backend / Supabase Gate | PASS | PASS | Live Supabase reality was scanned as evidence only; backend mutations are out of scope. | Added no-change diff gate for `supabase/migrations`, `supabase/functions`, and `supabase/tests`. |
| UI / Integration Gate | PARTIAL | PASS AFTER CORRECTION | Draft was detailed but left message copy and withdrawal behavior ambiguous, and did not separate exact-match versus adaptation targets strongly enough. | Resolved copy/withdrawal decisions and added evidence-authority rules per phase. |
| Release / QA Gate | PARTIAL | PASS AFTER CORRECTION; VISUAL CLOSURE STILL GATED | Draft included QA but needed the PlanCritic gate artifact, runtime screenshot matrix, and no-fake-progress rule as blockers. | Added persisted critique artifact, runtime QA matrix, final sensitive-flow review, docs sync, final report, and Mohammed handoff gates. |

## C) Critical Gaps (Must-Fix)

### Gap 1: Draft was not a persisted PlanCritic source-of-truth gate.

- **Why it will break:** @Executor, @Sentinel, and @DocsKeeper need a durable critique file with gate status, decisions, risks, and the corrected-plan reference.
- **Fix:** Add `.TODO/PLAN_CRITIQUE_2026-05-12_OpenDesign_AmberDusk_Phases5_6_7_8_PhoneTrustMessagingWorkPayments.md` and reference it from this plan and the session log.
- **Owner:** @PlanCritic.
- **Acceptance check:** critique file exists, this plan references it, and the session log records the PlanCritic rewrite.

### Gap 2: Ambiguous message mode copy would create phone/web drift.

- **Why it will break:** `MessagesScreen` currently uses `Responses`/`Requests`, while the current Open Design and Dashboard direction is `Received`/`Sent`.
- **Fix:** Phase 6 must use `Received`/`Sent` for the Messages segmented control unless the product owner explicitly overrides the design-source decision.
- **Owner:** @Pixel + @PlanCritic.
- **Acceptance check:** Phase 6 evidence notes cite Open Design `Received`/`Sent`; implementation diff changes or preserves copy accordingly with a documented decision.

### Gap 3: Wallet withdrawal could become a hidden product/backend activation.

- **Why it will break:** A visual plan could make withdrawal look active without a complete product/security/payment release gate.
- **Fix:** Phase 8 preserves current wallet behavior. It may style existing wallet cards/previews, but it must not add a new active withdrawal route, form, or lifecycle path.
- **Owner:** @Architect + @ThreatModeler.
- **Acceptance check:** diff review confirms no new withdrawal service calls, routes, request forms, or ledger mutation paths are introduced by Phase 8 visual work.

### Gap 4: Exact visual matching was possible for missing design surfaces.

- **Why it will break:** Auth/gates, attachment tile, notification modal, proposal detail, payment return, and WebView states are not exact phone artboards in current Open Design.
- **Fix:** classify those as token-normalization/adaptation only unless Open Design or user screenshots provide exact evidence.
- **Owner:** @Pixel + @Sentinel.
- **Acceptance check:** every visual QA note labels evidence type and no missing-evidence surface is claimed as pixel-matched.

### Gap 5: Test infrastructure was detailed but not gate-level.

- **Why it will break:** Type B screens, auto-loading ViewModels, singleton coordinators, WebView navigation, and `PaymentPendingStore` provider typing can create flaky or misleading tests.
- **Fix:** Gate 0 must run before writing or updating tests: provider type matrix, auto-load stubs, singleton cleanup, bounded pump strategy, and no-real-Supabase test rule.
- **Owner:** @Sentinel.
- **Acceptance check:** session log contains a fixture/provider matrix before test implementation begins.

### Gap 6: Runtime visual closure could be overstated.

- **Why it will break:** Prior Amber Dusk phases proved code/test gates but still left runtime visual parity open.
- **Fix:** Phase 9 requires runtime Flutter visual evidence across route/state/width matrix before any visual completion claim.
- **Owner:** @Pixel + @Sentinel.
- **Acceptance check:** visual QA report exists or final report explicitly states the gate remains open.

### Gap 7: Sensitive-flow privacy scans were not hard release blockers.

- **Why it will break:** Phases 6-8 include private messages, attachments, direct offers, payment, wallet, disputes, and ledger-backed values.
- **Fix:** Phase 9.5 must pass no raw IDs/storage paths/message bodies/payment URLs in new routine logs, no UI-only lifecycle authority, and no backend mutations.
- **Owner:** @ThreatModeler + @Observability + @CodeGuard.
- **Acceptance check:** sensitive-flow review is recorded in the session log and master report.

## D) Invariants & Success Criteria (Non-Negotiable)

- [ ] (@Architect) No View imports or calls Supabase directly.
  - Enforce: search changed views/widgets for `Supabase.instance`, `.from(`, `.rpc(`, and direct storage calls.
  - Verify: architecture scan passes or baseline exceptions are documented.
- [ ] (@Architect) No ViewModel, service, repository, Provider registration, route contract, or business lifecycle contract changes occur in this visual plan.
  - Enforce: `git diff --name-only` review and file ownership checks.
  - Verify: source diff contains only approved view/widget/test/docs/artifact changes unless a separate plan exists.
- [ ] (@Supabase_Ops | Skill: supabase-migration) No schema, migration, RLS, RPC, trigger, storage policy, Edge Function, SQL test, or live database mutation occurs.
  - Enforce: `git diff --name-only -- supabase/migrations supabase/functions supabase/tests`.
  - Verify: command returns no changed backend files.
- [ ] (@ThreatModeler) Participant, owner, admin, payment, booking, direct-offer, tender, work, dispute, and wallet boundaries stay server/DB/service governed.
  - Enforce: UI may expose disabled/hidden states from ViewModels, but cannot create authority.
  - Verify: sensitive-flow review passes.
- [ ] (@ThreatModeler) Storage paths remain DB/storage internals and signed URLs remain short-lived render artifacts.
  - Enforce: attachment/image UI uses existing services/widgets.
  - Verify: no logs or UI text reveal private storage paths or signed URL details.
- [ ] (@Observability) New logs use `AppLogger` and avoid raw IDs, raw exception strings, message bodies, storage paths, payment URLs, gateway IDs, and correlation details in routine UI paths.
  - Enforce: review new/changed logging calls.
  - Verify: privacy log scan and manual review pass.
- [ ] (@Pixel | Skill: normalize) New reusable visual values live in `lib/core/theme/designs/amber_dusk/`, existing theme files, or approved adapters, not feature-local constants.
  - Enforce: raw visual scan and diff review.
  - Verify: no new raw color/font/duration/shadow/radius families are introduced in feature code.
- [ ] (@Pixel | Skill: normalize) No global Amber Dusk `MaterialApp` or `AppTheme` activation occurs in this Phase 5-8 plan.
  - Enforce: inspect `lib/main.dart`, `lib/core/theme/app_theme.dart`, and any app shell diffs.
  - Verify: runtime theme activation remains scoped to touched widgets/views.
- [ ] (@Pixel | Skill: normalize) No new `BackdropFilter`, `ImageFilter.blur`, frosted glass, deleted `glass_*`, or bundled Open Design font files are introduced.
  - Enforce: scan `lib/` and `pubspec.yaml`.
  - Verify: no-glass/no-font-bundling gate passes.
- [ ] (@Sentinel) Every changed screen/widget has focused tests or an explicit reason tests are deferred, and full `flutter test --coverage` confirms the existing CI floor is not regressed.
  - Enforce: phase-specific tests before broad coverage.
  - Verify: commands and coverage result are logged.
- [ ] (@DocsKeeper) Docs, session log, final report, visual QA, and Mohammed handoff describe verified reality, not planned intent.
  - Enforce: docs update only after code/test/visual gates.
  - Verify: docs path validation and cross-links pass.

## E) Risk Register (Predict Problems)

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|---|---:|---:|---:|---|---|---|---|
| Missing exact designs get invented | Auth/gates, attachment, notification modal, proposal detail, payment return/WebView | High | Medium | Visual drift and false parity | No screenshot/artifact path in log | Adapt/token-normalize only without evidence | Mark surface deferred and request screenshot |
| Message copy drifts from design/web | Phase 6 Messages | Medium | Medium | Phone/web handoff mismatch | `Responses`/`Requests` remains without decision | Use `Received`/`Sent` as selected source decision | Revert copy only with explicit product override |
| Wallet withdrawal is accidentally activated | Phase 8 Wallet | Medium | High | Payment/ledger/security | New route/form/service call appears | Preserve current behavior and require separate plan | Revert withdrawal-specific UI and document future work |
| Payment UI changes break return handling | Phase 8 payment checkout/return/WebView | Medium | High | Checkout failures | Pending context not cleared, URL params remain | Payment smoke tests and URL cleanup review | Restore prior payment shell and route logic |
| Chat/realtime subscriptions duplicate | Phase 6 Chat/Messages | Medium | High | Realtime load, stale UI, battery | Duplicate stream logs, double message renders | Preserve ViewModel stream topology | Revert stream-related UI code and retest |
| Provider/test harness is wrong | Phases 5-8 widget tests | Medium | Medium | Flaky CI and false confidence | ProviderNotFound, MissingStub, pump timeout | Gate 0 provider/fixture matrix | Lower-level widget tests or add explicit seam in separate plan |
| Raw visual tokens spread into feature files | All UI phases | High | Medium | Hard-to-maintain redesign | raw-token scan hits in changed files | Existing tokens/adapters first | Move values to theme/adapters or document legacy exception |
| Sensitive data leaks in logs/semantics | Chat, attachments, notifications, payment, wallet | Medium | High | Privacy and trust | raw IDs, paths, URLs, bodies in logs | Observability and ThreatModeler review | Patch logs/copy before closure |
| Runtime visual closure is faked | Cross-phase QA | High | Medium | Incorrect handoff to Mohammed | only Open Design refs in final report | runtime screenshot matrix | Keep visual gate open |
| Backend files change inside visual plan | Phases 6-8 | Low | High | Security/data regression | `supabase/` diff appears | no-backend diff gate | Stop and split separate backend plan |

## F) Pre-Mortem (How This Fails In Real Life)

- This fails when @Executor starts from the pre-critique draft and misses the persisted PlanCritic artifact.
- This fails when Open Design reference screenshots are treated as Flutter runtime QA.
- This fails when auth, notification, proposal, attachment, and payment states are pixel-matched despite missing exact evidence.
- This fails when the Messages segmented control keeps `Responses`/`Requests` without documenting a product override.
- This fails when Phase 8 makes withdrawal look fully active while the current wallet screen still treats withdrawal as a roadmap/preview surface.
- This fails when payment return/WebView visuals change route, callback, pending-store, or URL-cleanup behavior.
- This fails when work lifecycle CTAs become visually available even though ViewModel/service state says they are blocked.
- This fails when changed widget tests instantiate auto-loading ViewModels before mocks, stream controllers, or `RoleSwitchCoordinator` cleanup are ready.
- This fails when new logs include raw message bodies, storage paths, IDs, payment URLs, or raw exception strings.
- This fails when final docs say Phase 5-8 is visually complete without runtime screenshots.

## G) Plan Fixes (Concrete Additions / Expansions)

1. **Goal:** Persist the PlanCritic source-of-truth gate.
   - **Why:** Execution needs durable decisions, risks, and gate status.
   - **How:** Add `.TODO/PLAN_CRITIQUE_2026-05-12_OpenDesign_AmberDusk_Phases5_6_7_8_PhoneTrustMessagingWorkPayments.md`.
   - **Output artifact:** critique file plus this corrected plan reference.
   - **Stop condition:** execution blocked if the critique file is missing.

2. **Goal:** Resolve Phase 6 message copy before code work.
   - **Why:** Copy ambiguity creates phone/web/design-source drift.
   - **How:** Choose `Received`/`Sent` from Open Design and require Phase 6 implementation to follow it unless explicitly overridden.
   - **Output artifact:** Phase 6 session-log decision note.
   - **Stop condition:** Phase 6 blocked if copy direction is not recorded.

3. **Goal:** Preserve wallet withdrawal product authority.
   - **Why:** Active withdrawal touches payment, ledger, and security flows.
   - **How:** Style existing wallet surfaces only; no new withdrawal route/form/service path in this visual plan.
   - **Output artifact:** Phase 8 diff review and sensitive-flow note.
   - **Stop condition:** any new active withdrawal behavior triggers a separate plan.

4. **Goal:** Separate exact evidence from adaptation-only targets.
   - **Why:** Missing Open Design surfaces are likely if the executor goes screen by screen.
   - **How:** Label each target as Open Design exact, user screenshot exact, current-app runtime, old baseline, manual QA, or missing/adaptation only.
   - **Output artifact:** evidence matrix in session log and visual QA report.
   - **Stop condition:** no exact-match claim without exact evidence.

5. **Goal:** Gate test infrastructure before tests.
   - **Why:** Provider, auto-load, singleton, timer, and WebView route mistakes create flake.
   - **How:** Create provider/fixture matrix before test writing.
   - **Output artifact:** session-log test matrix.
   - **Stop condition:** missing matrix blocks new widget tests.

6. **Goal:** Make runtime visual QA non-optional.
   - **Why:** Prior phases proved code gates while visual parity remained open.
   - **How:** Add route/state/width screenshot checklist and final report requirements.
   - **Output artifact:** `.TODO/EMULATOR_TEST_CHECKLIST_2026-05-12_OpenDesign_AmberDusk_Phases5_6_7_8.md` and `VisualQA.../REPORT.md`.
   - **Stop condition:** no visual completion claim without runtime evidence.

## H) Corrected Plan (Execution-Ready, Gate-Based)

## H.1 System Impact Map

- UI: High. Phases 5-8 touch Auth, system gates, Messages, Chat, Notifications, Direct Offer Details, Task Details, Tenders, Requests/Proposals, Tender Payment, Work Details, Management Logs, Bookings, Payment Checkout/Method/Return/WebView, and Wallet.
- MVVM / App Logic: Low intended impact. Views consume existing ViewModels and services; no new business logic should be introduced in views.
- Database: None planned. Live tables are evidence only.
- RLS / Security: None planned. RLS remains server-side/live-database responsibility.
- RPC / Edge Functions: None planned. Existing payment and recovery Edge Functions remain authoritative.
- Storage: None planned. Attachment and image views keep storing DB paths and generating signed URLs through existing services/widgets.
- Realtime / Notifications: Visual changes only. Chat and notification stream topology must remain unchanged.
- Observability: Privacy-safe logs only for new UI state transitions if added.
- Compatibility & Migration: No migrations. Rollback is source/docs/test artifact rollback only.
- Contracts: No DTO/model/ViewModel/service contract changes planned. If a missing design state requires new data, stop and create a separate contract plan.

## 5) Agent Map

- Phase 0 owner: @Planner, @Architect, @Supabase_Ops, @Sentinel, @DocsKeeper.
- Phase 5 owner: @Pixel primary, @Architect boundary owner, @Sentinel verification owner, @DocsKeeper documentation owner.
- Phase 6 owner: @Pixel primary, @Architect boundary owner, @ThreatModeler sensitive-flow owner, @Observability logging/privacy owner, @Sentinel verification owner.
- Phase 7 owner: @Pixel primary, @Architect lifecycle-boundary owner, @ThreatModeler money/work/dispute owner, @Observability logging/privacy owner, @Sentinel verification owner.
- Phase 8 owner: @Pixel primary, @Architect payment/booking/wallet boundary owner, @ThreatModeler payment/wallet owner, @Observability logging/privacy owner, @Sentinel verification owner.
- QA owner: @Sentinel primary, @CodeGuard secondary, @ThreatModeler for sensitive checks.
- Documentation owner: @DocsKeeper primary, @Planner and @Sentinel evidence contributors.

## Phase 0: Preconditions, Evidence Lock, And Stop Rules

**Primary Agent(s):** @Planner, @Architect, @Supabase_Ops, @Sentinel, @DocsKeeper  
**Goal:** Lock the evidence, execution boundaries, and verification expectations before phase work starts.  
**Why:** Phases 5-8 touch trust, communication, lifecycle, payment, and wallet surfaces where visual work can accidentally become behavioral work.  
**How:** Re-check Open Design, repo inventory, Supabase reality, current docs, test harnesses, and active artifacts before any implementation.  
**Result:** Executor can start Phase 5 without guessing scope or authority.

### 0.1 Spec Lock

**Primary Agent(s):** @Planner, @Sentinel  
**Goal:** Confirm this plan covers every master Phase 5-8 target.  
**Why:** The master phone plan is broad and several targets are re-exported, embedded, or launched from other features.  
**How:** Match every master target to concrete files, design evidence, test expectations, and stop rules.  
**Result:** No Phase 5-8 surface is lost or duplicated.

- [ ] (@Planner) Treat `.TODO/PLAN_OpenDesign_AmberDusk_Phone_2026-05-10.md` as the master roadmap.
- [ ] (@Planner) Treat this plan as the execution source for phases 5-8 after PlanCritic approval.
- [ ] (@Sentinel) Record in the session log that this plan is planning-only until @Executor starts implementation.
- [ ] (@Sentinel) Confirm `git status --short --untracked-files=all` before implementation so unrelated work is not included.
- [ ] (@Architect) Confirm no source-code implementation happens during this planning step.
- **GATE CHECK:** scope, acceptance, references, and rollback expectations are explicit.

### 0.2 Open Design Evidence Lock

**Primary Agent(s):** @Planner, @Pixel, @Sentinel  
**Goal:** Establish which design evidence can drive exact matching and which can only drive token-normalization.  
**Why:** Missing auth/payment/notification designs must not be filled in from imagination.  
**How:** Re-open Open Design files and classify every evidence source.  
**Result:** Implementation steps know when to match, adapt, or stop for screenshots.

- [ ] (@Planner | Skill: extract) Re-call Open Design MCP `get_project` for project `1674a1db-7a74-4c80-8e2c-196a0385a8f7`.
- [ ] (@Planner | Skill: extract) Re-call Open Design MCP `list_files` and record `Sline V2 Amber Dusk.html`, `amber-dusk-design-system.html`, `sline-v2-amber-dusk-web.html`, screenshot assets, and font assets.
- [ ] (@Planner | Skill: extract) Read `amber-dusk-design-system.html` for system rules, color tokens, typography roles, depth tiers, system rules, and messaging/work/booking/wallet rules.
- [ ] (@Planner | Skill: extract) Read `Sline V2 Amber Dusk.html` for phone evidence: messages, dashboard/work buckets, booking cards, task cards, wallet widget, lifecycle data, create sheet references, and navigation constraints.
- [ ] (@Planner | Skill: extract) Search Open Design for `auth`, `message`, `offer`, `notification`, `attachment`, `proposal`, `booking`, `payment`, `wallet`, `checkout`, `webview`, `return`, and lifecycle terms.
- [ ] (@Pixel | Skill: audit) Classify each evidence source as design-reference evidence, current-app runtime evidence, old-app baseline, manual QA evidence, or missing evidence.
- [ ] (@Sentinel | Skill: audit) If exact phone evidence is missing, mark that target as token-normalization/adaptation only or request a screenshot before exact implementation.
- **GATE CHECK:** every planned screen has a design authority classification before implementation.

### 0.3 Supabase Reality And Backend No-Change Gate

**Primary Agent(s):** @Supabase_Ops, @ThreatModeler, @Sentinel  
**Goal:** Confirm live/current backend reality while keeping backend changes out of scope.  
**Why:** Planner requires Supabase reality, and phases 6-8 are high-risk even when visual-only.  
**How:** Use live project metadata, repo docs, migrations, functions, and table/RLS evidence as guardrails.  
**Result:** UI work is planned against real backend boundaries without planning backend edits.

- [ ] (@Supabase_Ops | Skill: supabase-migration) Record live project `isddrknbjsgaantjojhm`, region `eu-north-1`, database PostgreSQL `17.4.1`, status `ACTIVE_HEALTHY`.
- [ ] (@Supabase_Ops | Skill: supabase-migration) Record live RLS-enabled public tables relevant to this plan: `profiles`, `tasks`, `task_requests`, `conversations`, `messages`, `conversation_presence`, `bookings`, `notifications`, `direct_offers`, `work_contracts`, `change_requests`, `extension_requests`, `accounts`, `journal_entries`, `ledger_lines`, `payment_intents`, `payment_events`, `orphan_payments`, `user_devices`, and `notification_push_queue`.
- [ ] (@Supabase_Ops | Skill: supabase-migration) Record live payment Edge Functions: `qicard_payment_create`, `qicard_payment_recovery`, `qicard_payment_create_direct_offer`, `qicard_payment_recovery_direct_offer`, `qicard_payment_create_tender`, `qicard_payment_recovery_tender`, `qicard_webhook_handler`, `booking_decline_refund`, and `create_payment_intent`.
- [ ] (@Supabase_Ops | Skill: supabase-migration) Confirm this plan does not include migration, function deployment, policy, bucket, RPC, or SQL-test work.
- [ ] (@ThreatModeler) Define negative checks for phases 6-8: no UI-only lifecycle authority, no client-side payment trust, no attachment URL storage, no notification inserts from the client, and no raw sensitive data logs.
- [ ] (@Sentinel) Add a final diff gate that fails if `supabase/migrations/`, `supabase/functions/`, or `supabase/tests/` changes during execution.
- **GATE CHECK:** backend reality is confirmed, and all backend mutation work is explicitly out of scope.

### 0.4 Test Infrastructure Self-Verification

**Primary Agent(s):** @Sentinel, @Architect  
**Goal:** Prevent test-harness failures before UI execution begins.  
**Why:** Planner requires constructor DI, singleton/static state, auto-loading, and provider dependency checks for test-heavy plans.  
**How:** Classify target screens, ViewModels, provider dependencies, and cleanup methods before writing tests.  
**Result:** Executor can add tests without missing mock stubs or wrong Provider types.

- [ ] (@Sentinel) Confirm every target ChangeNotifier mock is provided with `ChangeNotifierProvider.value`.
- [ ] (@Sentinel) Confirm every plain dependency mock, such as `PaymentPendingStore`, is provided with `Provider.value`.
- [ ] (@Sentinel) Configure auto-loading mocks before constructing `AuthSessionViewModel`, `NotificationViewModel`, `ChatViewModel`, `WalletViewModel`, `WalletSharedBody`, `BookingsListScreen`, `BookingsDiscoveryScreen`, `WorkItemDetailsScreen`, `OrderManagementPanel`, and `DirectOfferDetailsScreen` tests.
- [ ] (@Sentinel) Add `RoleSwitchCoordinator().clearForTesting()` to relevant `setUp`/`tearDown` where `ChatViewModel` or `TaskViewModel` may register.
- [ ] (@Sentinel) Use bounded `pump`/`pumpAndSettle` patterns for timers, debounces, streams, animation controllers, WebView route pushes, and payment-return flows.
- [ ] (@Architect) Confirm no ViewModel constructor refactor is needed unless a new test target is not injectable.
- [ ] (@Sentinel) Do not set a new coverage percentage target in this plan. Use `flutter test --coverage` only to verify the existing CI floor and detect regressions.
- **GATE CHECK:** mocking strategy, singleton cleanup, auto-load stubs, provider types, and pump strategy are documented before new tests are added.

## Phase 5: Phone Auth, Account Gates, And System Screens

**Primary Agent(s):** @Pixel, @Architect, @Sentinel, @DocsKeeper  
**Goal:** Redesign auth and blocking system screens from the master Phase 5 scope.  
**Why:** These screens are first-run and trust-critical, but Open Design has no exact auth/gate phone artboards.  
**How:** Adapt Amber Dusk form/system patterns while preserving AuthFormViewModel, AuthSessionViewModel, SystemConfigViewModel, account guard, and auth repository behavior.  
**Result:** Auth and gates are visually aligned, readable, resilient, and behaviorally unchanged.

### 5.1 Design Context Lock

**Primary Agent(s):** @Pixel, @Planner, @Sentinel  
**Goal:** Lock the Phase 5 visual authority before implementation.  
**Why:** Dedicated auth/gate designs are mostly missing.  
**How:** Use Open Design form/settings/system patterns as adaptation evidence only.  
**Result:** Phase 5 does not claim pixel-level matching without screenshots.

- [ ] (@Planner | Skill: extract) Record that Open Design has no dedicated `login`, `signup`, `forgot password`, `reset password`, `restricted`, `maintenance`, or `update required` phone screen.
- [ ] (@Pixel | Skill: frontend-design) Derive Phase 5 only from available Amber Dusk form/system evidence: dark panels, grouped fields, primary/ghost actions, cream text, amber active states, muted helper copy, and security/privacy settings rows.
- [ ] (@Pixel | Skill: clarify) Keep auth copy user-facing and non-technical; never show raw backend error text.
- [ ] (@Sentinel | Skill: audit) If the user provides auth/gate screenshots before execution, classify them as user-provided new-design screenshot evidence and bind each to the visible route/state only.
- **GATE CHECK:** no Phase 5 target is marked exact-match without screenshot or direct Open Design evidence.

### 5.2 Layout / Structure

**Primary Agent(s):** @Pixel, @Architect, @Sentinel  
**Goal:** Plan the structural changes for every Phase 5 screen.  
**Why:** Auth and gate views must feel coherent without changing session behavior.  
**How:** Update layout composition and state placement through existing widgets and ViewModels.  
**Result:** Forms, validation, success/error, and blocking states have a common Amber Dusk structure.

- [ ] (@Pixel | Skill: arrange) Update `lib/features/auth/view/login_screen.dart` with a compact trust-first form layout, stable logo/header zone, visible validation, disabled signup messaging, password visibility control, and loading CTA state.
- [ ] (@Pixel | Skill: arrange) Update `lib/features/auth/view/signup_screen.dart` with grouped account fields, password requirement hierarchy, disabled-signup state, terms/trust copy placement, and loading/error CTA state.
- [ ] (@Pixel | Skill: arrange) Update `lib/features/auth/view/forgot_password_screen.dart` with single-purpose email recovery layout, success confirmation, retry affordance, and back-to-login affordance.
- [ ] (@Pixel | Skill: arrange) Update `lib/features/auth/view/reset_password_update_screen.dart` with password requirement hierarchy, recovery-session feedback, success state, loading state, and invalid-session fallback.
- [ ] (@Pixel | Skill: arrange) Update `lib/features/auth/view/account_restricted_screen.dart` as a serious account status gate with clear reason, next action, sign-out behavior, and no decorative distraction.
- [ ] (@Pixel | Skill: arrange) Update `lib/features/auth/view/maintenance_screen.dart` as a system-gate screen with app status, retry, and quiet Amber Dusk system material.
- [ ] (@Pixel | Skill: arrange) Update `lib/features/auth/view/update_required_screen.dart` as a system-gate screen with version urgency, update CTA, retry/check action, and readable constraints.
- [ ] (@Architect) Preserve `AuthFormViewModel`, `AuthSessionViewModel`, `AuthRepository`, `AccountGuardService`, and `SystemConfigViewModel` behavior.
- [ ] (@Sentinel | Skill: audit) Verify every changed screen still renders at 360, 390, 402, and 430 logical widths without overlapping form text, CTAs, or keyboard-safe content.
- **GATE CHECK:** every Phase 5 file is either changed or explicitly documented as already compliant.

### 5.3 Visual Direction

**Primary Agent(s):** @Pixel, @Sentinel  
**Goal:** Apply Amber Dusk visual language to Phase 5 without inventing new token families.  
**Why:** Auth screens need high trust, not decorative novelty.  
**How:** Use existing theme APIs and Amber Dusk recipes.  
**Result:** Auth surfaces align with the redesign while staying controlled by tokens.

- [ ] (@Pixel | Skill: normalize) Use `AppColors`, `AppTypography`, `AppDimens`, `AppLayout`, `AppMotion`, `AppDecorations`, and Amber Dusk adapters instead of raw reusable constants.
- [ ] (@Pixel | Skill: colorize) Use amber/cream/muted semantic emphasis from Amber Dusk tokens; avoid blue/purple accents.
- [ ] (@Pixel | Skill: typeset) Use display typography only for screen titles and trust headers; keep inputs, labels, helper text, and buttons in compact interface roles.
- [ ] (@Pixel | Skill: polish) Replace any touched raw `BoxShadow`, `fontSize`, or hardcoded color with tokens unless the old value is a documented legacy exception.
- [ ] (@Sentinel | Skill: audit) Run a feature-view raw-visual scan on touched files before the Phase 5 gate.
- **GATE CHECK:** Phase 5 has no new raw Amber Dusk visual values in feature views.

### 5.4 Interaction / Motion

**Primary Agent(s):** @Pixel, @Architect, @Sentinel  
**Goal:** Preserve auth interactions while improving feedback quality.  
**Why:** Auth failures, disabled signup, and reset success states must be understandable and safe.  
**How:** Keep existing ViewModel actions and only improve UI response.  
**Result:** Auth state changes are visible, accessible, and behaviorally unchanged.

- [ ] (@Pixel | Skill: animate) Use `AppMotion` for any loading, entrance, focus, or CTA transition touched in auth screens.
- [ ] (@Pixel | Skill: clarify) Keep validation messages next to the relevant field or action region.
- [ ] (@Pixel | Skill: clarify) Ensure disabled-signup copy explains the app state without blaming the user.
- [ ] (@Pixel | Skill: clarify) Ensure forgot/reset success copy states what happened and the next step.
- [ ] (@Architect) Keep navigation decisions in the View layer and auth operations in ViewModels/repositories.
- [ ] (@Sentinel) Verify loading buttons cannot double-submit.
- **GATE CHECK:** validation, loading, success, disabled, and error states are represented without behavior changes.

### 5.5 Hardening / Responsive / Accessibility

**Primary Agent(s):** @Pixel, @Sentinel  
**Goal:** Make auth and gates robust under narrow widths, larger text, and failure states.  
**Why:** Auth screens are often used under stress.  
**How:** Test overflow, semantics, focus order, error copy, and keyboard paths.  
**Result:** Phase 5 remains readable and operable on phone widths.

- [ ] (@Pixel | Skill: harden) Ensure long emails, long names, long error messages, and long password requirement text wrap cleanly.
- [ ] (@Pixel | Skill: harden) Ensure 360 px and text scale 1.3 do not clip CTAs or field labels.
- [ ] (@Pixel | Skill: harden) Ensure error banners and system-gate copy are announced correctly by semantics.
- [ ] (@Pixel | Skill: harden) Ensure keyboard appearance does not hide the active field or primary CTA in auth forms.
- [ ] (@Sentinel | Skill: audit) Verify raw backend errors do not appear in screenshots, tests, or semantics labels.
- **GATE CHECK:** Phase 5 passes overflow, semantics, keyboard, and user-facing error checks.

### 5.6 Final Audit / QA

**Primary Agent(s):** @Sentinel, @CodeGuard, @DocsKeeper  
**Goal:** Verify Phase 5 behavior and visuals before moving to Phase 6.  
**Why:** Auth regressions block access to every later screen.  
**How:** Run focused tests, scans, and manual route/state checks.  
**Result:** Phase 5 closes with evidence.

- [ ] (@Sentinel) Run `flutter test test/unit/auth/ test/widget/auth/ test/integration_test/app_startup_login_flow_test.dart`.
- [ ] (@Sentinel) Add missing focused widget tests for changed forgot/reset/gate screens if they are not already covered.
- [ ] (@Sentinel) Run `rg 'Supabase\\.instance|\\.from\\(|\\.rpc\\(' lib/features/auth/view`.
- [ ] (@Sentinel) Run `rg 'Color\\(0x|#[0-9A-Fa-f]{6}|Colors\\.|BoxShadow\\(|Duration\\(milliseconds:|fontSize:' lib/features/auth/view`.
- [ ] (@CodeGuard) Review Phase 5 diff for MVVM, raw visuals, raw error leaks, and auth behavior changes.
- [ ] (@DocsKeeper) Record Phase 5 evidence and any missing exact-design caveats in the session log.
- **GATE CHECK:** Phase 5 passes focused tests, static scans, and documented visual/runtime checks.

## Phase 6: Phone Chat, Direct Offers, Attachments, And Notifications

**Primary Agent(s):** @Pixel, @Architect, @ThreatModeler, @Observability, @Sentinel  
**Goal:** Redesign communication surfaces from the master Phase 6 scope.  
**Why:** Chat, offers, attachments, and notifications are realtime, trust-sensitive, and action-heavy.  
**How:** Apply Amber Dusk list, bubble, offer, attachment, and notification patterns without changing realtime topology or service contracts.  
**Result:** Messaging surfaces are visually coherent and behaviorally intact.

### 6.1 Design Context Lock

**Primary Agent(s):** @Pixel, @Planner, @Sentinel  
**Goal:** Lock message/offers/notification visual evidence.  
**Why:** Open Design has strong message-list evidence but weak attachment and notification-modal evidence.  
**How:** Use exact evidence where present and token-normalization where missing.  
**Result:** Phase 6 avoids invented attachment/notification designs.

- [ ] (@Planner | Skill: extract) Record message list evidence from `Sline V2 Amber Dusk.html`: compact rows, avatar, attached work title, latest line, unread indicator, time/status, online strip, and Received/Sent mode.
- [ ] (@Planner | Skill: extract) Record offer evidence from the web artifact: direct-offer action context, scoped-offer copy, bubbles, active conversation, and work context.
- [ ] (@Planner | Skill: extract) Record that attachment tile and notification modal visuals are weak/missing in Open Design.
- [ ] (@Pixel | Skill: clarify) Implement the PlanCritic-selected message mode copy: `Received` and `Sent`. Do not keep `Responses`/`Requests` unless the product owner explicitly overrides the current Open Design/design-system direction and the override is recorded.
- [ ] (@Sentinel | Skill: audit) Mark attachment and notification modal exact matching as blocked until screenshot or direct Open Design evidence exists.
- **GATE CHECK:** Phase 6 copy and evidence authority are recorded before UI edits.

### 6.2 Layout / Structure

**Primary Agent(s):** @Pixel, @Architect, @Sentinel  
**Goal:** Plan the structure for messages, chat, offers, attachments, and notifications.  
**Why:** These surfaces have many hidden states and modals.  
**How:** Update visible structure while keeping existing controllers, streams, and services.  
**Result:** Conversation and notification flows remain complete.

- [ ] (@Pixel | Skill: arrange) Update `lib/features/chat/view/messages_screen.dart` for message modes, search, online strip, empty inbox, search no-results, unread state, delete dialog, and navigation to chat.
- [ ] (@Pixel | Skill: arrange) Update `lib/features/chat/view/chat_screen.dart` for header/context, message list, composer, reply quote, attachment entry, report action, scroll-to-bottom, and loading/empty/error states.
- [ ] (@Pixel | Skill: polish) Update `lib/features/chat/view/widgets/conversation_list_tile.dart` for compact Amber Dusk row geometry, unread count, online/presence cues, long-name handling, and latest-message truncation.
- [ ] (@Pixel | Skill: polish) Update `lib/features/chat/view/widgets/message_bubble.dart` for own/other bubbles, emoji-only rendering, link treatment, reply quote, timestamp/read-state alignment, and long text.
- [ ] (@Pixel | Skill: polish) Update `lib/features/chat/view/widgets/offer_message_bubble.dart` for offer amount, status, CTA area, accepted/rejected/active/delivered/completed/refunded states, and disabled actions.
- [ ] (@Pixel | Skill: harden) Update `lib/features/chat/attachments/widgets/attachment_message_tile.dart` using token-normalized geometry only unless screenshot evidence is added.
- [ ] (@Pixel | Skill: clarify) Update `lib/features/chat/view/widgets/create_offer_sheet.dart` for clear field grouping, validation, price/days/scoped offer review, and disabled/loading states.
- [ ] (@Pixel | Skill: clarify) Update `lib/features/chat/view/widgets/chat_context_widget.dart` for work/task context hierarchy without adding data calls.
- [ ] (@Pixel | Skill: harden) Update `lib/features/notifications/view/notifications_modal.dart` for loading, empty, error, read/unread, deep-link, and retry states.
- [ ] (@Pixel | Skill: harden) Update `lib/features/notifications/view/widgets/notification_badge_button.dart` and `lib/features/notifications/view/widgets/notification_tile.dart` for badge counts, unread styling, long titles/messages, and semantics.
- [ ] (@Architect) Preserve `ChatViewModel`, `NotificationViewModel`, `DirectOffersService`, `AttachmentService`, `MessageService`, realtime subscriptions, and notification read/update-only rule.
- **GATE CHECK:** every Phase 6 file is covered, and missing design areas are not over-claimed.

### 6.3 Visual Direction

**Primary Agent(s):** @Pixel, @Sentinel  
**Goal:** Apply Amber Dusk visual language to communication surfaces.  
**Why:** Messages need density, hierarchy, and low-friction scanning.  
**How:** Use compact rows, muted metadata, amber active states, and raised dark surfaces.  
**Result:** Chat and notifications fit the redesign without becoming decorative.

- [ ] (@Pixel | Skill: normalize) Use existing Amber Dusk card, row, chip, button, badge, and skeleton recipes where applicable.
- [ ] (@Pixel | Skill: colorize) Use semantic status colors for offer state: amber for waiting/review, forest for active/won, cream for completed/closed/refunded, rust for rejection/cancel/failure, muted for setup/timeout.
- [ ] (@Pixel | Skill: typeset) Keep names and work titles readable while metadata stays compact.
- [ ] (@Pixel | Skill: polish) Keep attachment and notification surfaces quiet until exact designs exist.
- [ ] (@Sentinel | Skill: audit) Verify no blue/purple accents or one-off glow systems are added.
- **GATE CHECK:** Phase 6 uses existing Amber Dusk visual systems only.

### 6.4 Interaction / Motion

**Primary Agent(s):** @Pixel, @Architect, @Sentinel  
**Goal:** Improve communication feedback without destabilizing realtime behavior.  
**Why:** Chat regressions often come from subscriptions, optimistic state, and route timing.  
**How:** Keep existing stream lifecycle and use ViewModel methods for state changes.  
**Result:** Message opening, sending, offers, attachments, and notification interactions remain fast and safe.

- [ ] (@Pixel | Skill: animate) Use `AppMotion` for reply swipe, unread transitions, attachment loading, badge count changes, and sheet transitions only where touched.
- [ ] (@Architect) Preserve deferred chat navigation behavior; do not reintroduce blocking `fetchMessages` before route push.
- [ ] (@Architect) Preserve optimistic unread handling and background refresh behavior.
- [ ] (@Architect) Preserve `NotificationViewModel` foreground sync then stream behavior.
- [ ] (@Architect) Preserve direct-offer service/payment contracts; Phase 6 may style offer creation and offer bubbles but must not change lifecycle authority.
- [ ] (@Sentinel) Verify no double subscriptions, pending timers, or N+1 conversation fetch patterns are introduced.
- **GATE CHECK:** realtime behavior and direct-offer contracts remain unchanged.

### 6.5 Hardening / Responsive / Accessibility

**Primary Agent(s):** @Pixel, @ThreatModeler, @Observability, @Sentinel  
**Goal:** Harden chat/notification UX under edge states.  
**Why:** These surfaces contain private messages, attachments, offer amounts, and deep links.  
**How:** Verify overflow, semantics, privacy, attachment states, and notification states.  
**Result:** Phase 6 is secure, readable, and accessible.

- [ ] (@Pixel | Skill: harden) Verify long participant names, long latest-message text, long URLs, emoji-only messages, long offer descriptions, and long notification copy.
- [ ] (@Pixel | Skill: harden) Verify empty inbox, unread inbox, active chat, own/other bubbles, typing, attachment loading/error/retry/fullscreen, notification loading/empty/read/unread/error.
- [ ] (@ThreatModeler) Verify attachment UI does not expose private storage paths or signed URL details.
- [ ] (@ThreatModeler) Verify notifications remain client-read/update only and no client insert path is added.
- [ ] (@Observability) Verify no raw conversation IDs, user IDs, storage paths, raw exception strings, or message bodies are added to routine logs.
- [ ] (@Sentinel | Skill: audit) Verify 360 px and text scale 1.3 for message rows, bubbles, offer cards, attachment tiles, notification tiles, and sheets.
- **GATE CHECK:** Phase 6 passes privacy, overflow, semantics, and state coverage checks.

### 6.6 Final Audit / QA

**Primary Agent(s):** @Sentinel, @CodeGuard, @ThreatModeler, @DocsKeeper  
**Goal:** Verify Phase 6 before moving to work/payment surfaces.  
**Why:** Realtime and notification regressions can be subtle.  
**How:** Run focused tests, architecture scans, and manual runtime QA.  
**Result:** Phase 6 closes with test and scan evidence.

- [ ] (@Sentinel) Run `flutter test test/unit/chat/ test/features/chat/services/chat_realtime_merger_test.dart test/widget/chat/`.
- [ ] (@Sentinel) Run `flutter test test/unit/notifications/ test/widget/notifications/`.
- [ ] (@Sentinel) Run `flutter test test/features/direct_offers/direct_offers_service_test.dart test/unit/direct_offers/ test/widget/direct_offers/`.
- [ ] (@Sentinel) Run `flutter test test/integration_test/chat_message_flow_test.dart test/integration_test/notification_deeplink_flow_test.dart integration_test/chat_creation_test.dart`.
- [ ] (@Sentinel) Add focused widget tests for changed attachment tile, create offer sheet, chat context, notification badge, and notification tile gaps.
- [ ] (@Sentinel) Run `rg 'Supabase\\.instance|\\.from\\(|\\.rpc\\(' lib/features/chat/view lib/features/chat/attachments/widgets lib/features/notifications/view lib/features/direct_offers/view`.
- [ ] (@CodeGuard) Review for realtime subscriptions, no direct Supabase in views, raw visual values, privacy-safe logging, and raw error leaks.
- [ ] (@DocsKeeper) Record Phase 6 copy decision, evidence gaps, verification, and any web handoff notes.
- **GATE CHECK:** Phase 6 passes focused tests, scans, and privacy-sensitive review.

## Phase 7: Phone Tasks, Tenders, Proposals, Direct Offers, And Work Details

**Primary Agent(s):** @Pixel, @Architect, @ThreatModeler, @Observability, @Sentinel  
**Goal:** Redesign all work-intent and work-detail surfaces from master Phase 7.  
**Why:** These screens carry bids, awards, payment deadlines, delivery, revisions, disputes, direct offers, and work management.  
**How:** Apply Amber Dusk task/work/lifecycle patterns while preserving existing lifecycle logic.  
**Result:** Work execution surfaces are visually complete and lifecycle-safe.

### 7.1 Design Context Lock

**Primary Agent(s):** @Pixel, @Planner, @Sentinel  
**Goal:** Lock the Phase 7 design evidence and gaps.  
**Why:** Open Design has strong task/work-card evidence but weak full proposal/detail flow evidence.  
**How:** Use task card, lifecycle status, and work bucket evidence; adapt missing screens conservatively.  
**Result:** Work detail and proposal screens do not over-claim exact design matching.

- [ ] (@Planner | Skill: extract) Record task-card evidence: quiet raised card, price/status pills, offer avatar stack, compact metadata, `Make offer`, and no visible edge stroke.
- [ ] (@Planner | Skill: extract) Record lifecycle evidence: 24 statuses, Active/Done/Cancelled buckets, progress bar rows, status stage/next/meaning, and semantic colors.
- [ ] (@Planner | Skill: extract) Record weak evidence for proposal details, submit proposal sheet, and direct-offer detail screen.
- [ ] (@Pixel | Skill: frontend-design) Treat missing proposal/detail evidence as adaptation from task/work/card/status systems, not exact screenshot matching.
- [ ] (@Sentinel | Skill: audit) Require screenshot evidence before claiming exact proposal or direct-offer details parity.
- **GATE CHECK:** Phase 7 exact-match boundaries are recorded.

### 7.2 Layout / Structure

**Primary Agent(s):** @Pixel, @Architect, @Sentinel  
**Goal:** Plan structure for all Phase 7 task, request, proposal, direct-offer, work, and management surfaces.  
**Why:** The master phase names broad targets that map to many current files.  
**How:** Cover each file once with clear ownership and no backend changes.  
**Result:** Every work-intent surface is included.

- [ ] (@Pixel | Skill: arrange) Update `lib/features/tasks/view/task_details_screen.dart` for task header, price/status area, concept/logistics sections, image region, request CTA, owner actions, report/dispute entry, loading/error, and long-description handling.
- [ ] (@Pixel | Skill: arrange) Update `lib/features/tasks/view/tenders_screen.dart` for search/filter, list density, loading/empty/error, and card rhythm.
- [ ] (@Pixel | Skill: harden) Update `lib/features/tasks/view/tender_payment_screen.dart` for payment deadline, payment method area, order summary, unavailable/expired states, pending WebView launch, success/failure, and safe navigation.
- [ ] (@Pixel | Skill: polish) Update `lib/features/tasks/view/widgets/requests/requests_list_screen.dart` for owner/freelancer modes, filters, empty/error/loading, pagination, and action hierarchy.
- [ ] (@Pixel | Skill: polish) Update `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart` for bid amount, days, status, payment status, favorite/profile affordance, replacement status, and long message handling.
- [ ] (@Pixel | Skill: clarify) Update `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart` for validation, replacement/resubmit explanation, bid amount/days, message, guard errors, loading, and success/failure states.
- [ ] (@Pixel | Skill: clarify) Update `lib/features/tasks/view/widgets/requests/request_award_dialog.dart` for award confirmation, price mismatch, already accepted, payment deadline, loading, and destructive/cancel actions.
- [ ] (@Pixel | Skill: normalize) Treat `lib/features/proposals/view/proposals_list_screen.dart`, `lib/features/proposals/view/widgets/proposal_tile.dart`, `lib/features/proposals/view/widgets/submit_proposal_sheet.dart`, and `lib/features/proposals/view/proposal_payment_screen.dart` as re-export entry points; do not duplicate their implementations.
- [ ] (@Pixel | Skill: polish) Update `lib/features/proposals/view/proposal_details_modal.dart` for proposal detail hierarchy, CTA placement, state labels, and long notes.
- [ ] (@Pixel | Skill: harden) Update `lib/features/direct_offers/view/direct_offer_details_screen.dart` for accepted/unpaid, active, delivered, completed, canceled, refunded, loading/error/not-found, pay/cancel/deliver/complete/open-chat, dispute/report guards, and card payment action states.
- [ ] (@Pixel | Skill: harden) Update `lib/features/work/view/work_item_details_screen.dart` for work header, source type, lifecycle status, contract summary, booking details, change/extension lists, review/delivery actions, cancel award, dispute/report, loading/error, and refresh behavior.
- [ ] (@Pixel | Skill: clarify) Update `lib/features/work/view/widgets/submit_delivery_modal.dart`, `review_delivery_modal.dart`, and `request_extension_modal.dart` for field grouping, validation, destructive/confirm copy, loading, success, and error states.
- [ ] (@Pixel | Skill: harden) Update `lib/features/work/view/widgets/work_item_bottom_actions.dart`, `work_item_guard_widgets.dart`, and `work_item_booking_details.dart` for CTA priority, disabled/frozen/dispute states, overflow, and semantics.
- [ ] (@Pixel | Skill: polish) Update `lib/features/management/view/order_management_panel.dart`, `order_management_section.dart`, and `work_log_tile.dart` for timeline/log hierarchy, note composer, loading, empty, action error, and long log entries.
- [ ] (@Architect) Preserve `TaskRequestsViewModel`, `SubmitRequestViewModel`, `TenderPaymentViewModel`, `DirectOfferDetailsViewModel`, `WorkItemDetailsViewModel`, `OrderManagementViewModel`, services, delegates, and repositories.
- **GATE CHECK:** every Phase 7 target is mapped and covered exactly once.

### 7.3 Visual Direction

**Primary Agent(s):** @Pixel, @Sentinel  
**Goal:** Apply Amber Dusk work/lifecycle patterns without flattening critical status meaning.  
**Why:** Work screens need clear hierarchy between money, state, next action, and risk.  
**How:** Use task-card, panel-card, lifecycle-card, and status-color evidence.  
**Result:** Users can scan status and next action without lifecycle confusion.

- [ ] (@Pixel | Skill: normalize) Use Amber Dusk task-card and work-card materials for list/detail surfaces.
- [ ] (@Pixel | Skill: colorize) Map status colors semantically: muted for setup/timeout, amber for waiting/review, forest for active/won, cream for completed/closed/refunded, rust for failure/cancellation.
- [ ] (@Pixel | Skill: typeset) Use major money typography carefully; do not overuse display type in compact panels.
- [ ] (@Pixel | Skill: arrange) Keep next action and payment deadline visually close to the relevant work item, not separated into decorative blocks.
- [ ] (@Pixel | Skill: polish) Ensure status chips and progress bars do not become the whole card concept; status stays secondary to work title, owner, amount, and next action.
- [ ] (@Sentinel | Skill: audit) Verify no old teal/blue/purple visual leftovers remain in changed Phase 7 surfaces unless documented as legacy exceptions.
- **GATE CHECK:** work statuses are visually clear and token-controlled.

### 7.4 Interaction / Motion

**Primary Agent(s):** @Pixel, @Architect, @Sentinel  
**Goal:** Keep work lifecycle interactions safe.  
**Why:** Award, payment, delivery, revision, extension, dispute, and completion actions cannot become client-only visual state.  
**How:** Preserve existing ViewModel and service action paths; only improve UI feedback.  
**Result:** Phase 7 visuals do not change work authority.

- [ ] (@Pixel | Skill: animate) Use `AppMotion` only for touched sheet transitions, status feedback, loading states, and CTA pressed states.
- [ ] (@Architect) Preserve tender-only bid rules.
- [ ] (@Architect) Preserve award-before-payment and assignment-after-payment rules.
- [ ] (@Architect) Preserve direct-offer escrow rules and direct-offer payment recovery boundaries.
- [ ] (@Architect) Preserve frozen/dispute guards and CTA resolver behavior.
- [ ] (@Architect) Preserve `PaymentWebViewScreen` launch path from `TenderPaymentScreen`.
- [ ] (@Sentinel) Verify double-tap/double-submit prevention remains in award, submit, replace, pay, deliver, review, and extension actions.
- **GATE CHECK:** no lifecycle behavior is moved into UI-only code.

### 7.5 Hardening / Responsive / Accessibility

**Primary Agent(s):** @Pixel, @ThreatModeler, @Observability, @Sentinel  
**Goal:** Harden work surfaces under complex statuses and long content.  
**Why:** These surfaces combine user content, money, deadlines, and dispute states.  
**How:** Test all critical statuses and sensitive controls.  
**Result:** Phase 7 remains usable and safe.

- [ ] (@Pixel | Skill: harden) Verify pending, accepted, rejected, expired, unpaid, paid, active, delivered, revision, disputed, completed, canceled, withdrawn, lost, refunded, no-show, and error states where applicable.
- [ ] (@Pixel | Skill: harden) Verify long task titles, proposal messages, direct-offer descriptions, delivery notes, revision feedback, extension reasons, and management log entries.
- [ ] (@ThreatModeler) Verify payment, award, direct-offer, delivery, revision, extension, and dispute controls are governed by ViewModel/service state.
- [ ] (@ThreatModeler) Verify no UI path hides a server-blocked state or presents an action as available when the ViewModel says it is not.
- [ ] (@Observability) Verify new logs do not include raw task IDs, request IDs, direct offer IDs, work IDs, user IDs, or raw exception strings in routine UI paths.
- [ ] (@Sentinel | Skill: audit) Verify changed Phase 7 surfaces at 360 px and text scale 1.3.
- **GATE CHECK:** Phase 7 passes money/work/dispute hardening checks.

### 7.6 Final Audit / QA

**Primary Agent(s):** @Sentinel, @CodeGuard, @ThreatModeler, @DocsKeeper  
**Goal:** Verify Phase 7 before moving to booking/payment/wallet.  
**Why:** Work lifecycle regressions have direct financial and trust impact.  
**How:** Run focused unit/widget/integration tests and sensitive scans.  
**Result:** Phase 7 closes with evidence.

- [ ] (@Sentinel) Run `flutter test test/unit/tender/ test/unit/tasks/ test/unit/viewmodels/ test/widget/tasks/`.
- [ ] (@Sentinel) Run `flutter test test/unit/proposals/ test/widget/proposals/`.
- [ ] (@Sentinel) Run `flutter test test/unit/direct_offers/ test/widget/direct_offers/`.
- [ ] (@Sentinel) Run `flutter test test/unit/work/ test/widget/work/ test/unit/management/ test/widget/management/`.
- [ ] (@Sentinel) Run `flutter test test/integration_test/task_requests/bid_lifecycle_test.dart test/integration_test/proposals/proposal_regression_test.dart`.
- [ ] (@Sentinel) Add focused widget tests for changed proposal detail, proposal re-export behavior if needed, delivery modal, review modal, extension modal, and management log gaps.
- [ ] (@Sentinel) Run `rg 'Supabase\\.instance|\\.from\\(|\\.rpc\\(' lib/features/tasks/view lib/features/proposals/view lib/features/direct_offers/view lib/features/work/view lib/features/management/view`.
- [ ] (@CodeGuard) Review for lifecycle authority, raw visual constants, raw exception leaks, privacy-safe logging, and test coverage adequacy.
- [ ] (@DocsKeeper) Record Phase 7 lifecycle/status decisions and web handoff notes.
- **GATE CHECK:** Phase 7 passes focused tests, sensitive-flow review, and architecture scans.

## Phase 8: Phone Booking, Payment, And Wallet Standalone

**Primary Agent(s):** @Pixel, @Architect, @ThreatModeler, @Observability, @Sentinel  
**Goal:** Redesign booking, payment, and standalone wallet surfaces from master Phase 8.  
**Why:** These are high-risk money and lifecycle screens.  
**How:** Apply Amber Dusk booking/payment/wallet visual patterns while preserving server payment authority and ledger boundaries.  
**Result:** Booking, payment, and wallet phone sections are visually complete and payment-safe.

### 8.1 Design Context Lock

**Primary Agent(s):** @Pixel, @Planner, @Sentinel  
**Goal:** Lock booking/payment/wallet evidence and gaps.  
**Why:** Booking and wallet evidence is strong; payment checkout/return/WebView evidence is weak.  
**How:** Use exact booking/wallet evidence and conservative payment adaptation.  
**Result:** Payment screens are not over-designed beyond evidence or product authority.

- [ ] (@Planner | Skill: extract) Record booking-card evidence: rust hero material, avatar, chips, price, IQD, period, heart/message actions, and cream CTA.
- [ ] (@Planner | Skill: extract) Record wallet evidence: hero wallet material, available balance, pending clearance, recent activity, transaction rows, and major wallet value typography.
- [ ] (@Planner | Skill: extract) Record weak/missing exact evidence for payment method, checkout, return, WebView, success, failure, pending, canceled, retry, and trusted callback states.
- [ ] (@Pixel | Skill: clarify) Preserve current wallet withdrawal behavior: style existing wallet cards/previews, but do not add a new active withdrawal route, request form, or ledger-affecting UI path in this visual plan.
- [ ] (@Sentinel | Skill: audit) Require screenshot evidence before claiming exact payment WebView/return parity.
- **GATE CHECK:** booking/wallet exact evidence and payment adaptation boundaries are recorded.

### 8.2 Layout / Structure

**Primary Agent(s):** @Pixel, @Architect, @Sentinel  
**Goal:** Plan structure for booking, payment, and wallet files.  
**Why:** Phase 8 crosses discovery, list, detail, checkout, return, WebView, and ledger-backed wallet surfaces.  
**How:** Update UI layout only and preserve current ViewModel/services.  
**Result:** Booking and wallet sections are covered end to end.

- [ ] (@Pixel | Skill: arrange) Update `lib/features/booking/view/bookings_discovery_screen.dart` for booking discovery header, filters/search, booking card rhythm, loading, empty, error, and pagination/load-more behavior.
- [ ] (@Pixel | Skill: arrange) Update `lib/features/booking/view/bookings_list_screen.dart` for client/provider filters, loading, empty, error, load more, and booking-row hierarchy.
- [ ] (@Pixel | Skill: arrange) Update `lib/features/booking/view/booking_details_screen.dart` for booking identity, status, payment status, requirements, provider/client actions, chat action, report/dispute guards, delivery/approval/cancel/decline flows, loading/error, and long content.
- [ ] (@Pixel | Skill: harden) Update `lib/features/booking/view/payment_checkout_screen.dart` for payment summary, payment mode, pending context, error/retry/cancel, loading, double-submit prevention, demo/real payment copy, and trusted return guidance.
- [ ] (@Pixel | Skill: harden) Update `lib/features/booking/view/payment_method_screen.dart` for method selection, disabled/unavailable methods, validation, and CTA clarity.
- [ ] (@Pixel | Skill: harden) Update `lib/features/booking/view/payment_return_screen.dart` for success, failure, pending, canceled, expired/missing pending context, retry, URL cleanup evidence, and safe navigation.
- [ ] (@Pixel | Skill: harden) Update `lib/features/booking/view/payment_webview_screen.dart` for shell, loading, load error, external callback state, trusted-host callback handling, close/cancel, and retry without changing parser logic.
- [ ] (@Pixel | Skill: polish) Update `lib/features/booking/view/widgets/payment_order_summary_card.dart` for compact money hierarchy, IQD labels, status rows, and long task/provider names.
- [ ] (@Pixel | Skill: polish) Update `lib/features/booking/view/widgets/booking_card.dart` and confirm `dashboard_booking_card.dart` remains consistent with Phase 4 patterns.
- [ ] (@Pixel | Skill: polish) Update `lib/features/wallet/view/wallet_screen.dart` and `wallet_dashboard_screen.dart` as entry shells around the shared wallet body.
- [ ] (@Pixel | Skill: polish) Update `lib/features/wallet/view/widgets/wallet_shared_body.dart` for balance, activity, insights, withdrawal Coming Soon or current-product action behavior, loading, error, empty activity, and refresh.
- [ ] (@Pixel | Skill: polish) Update `lib/features/wallet/view/widgets/wallet_hero_card.dart`, `wallet_snapshot_card.dart`, and `wallet_timeline_card.dart` for Amber Dusk wallet material, transaction timeline, pending/held/available breakdown, and long labels.
- [ ] (@Architect) Preserve `BookingViewModel`, `BookingPaymentDelegate`, `BookingRepository`, `BookingService`, `PaymentService`, `PaymentPendingStore`, `PaymentReturnArgs`, `WalletViewModel`, `WalletRepository`, `WalletService`, `LedgerService`, and payment helper behavior.
- **GATE CHECK:** every Phase 8 target is mapped and behavior-preserving.

### 8.3 Visual Direction

**Primary Agent(s):** @Pixel, @Sentinel  
**Goal:** Apply Amber Dusk booking/wallet/payment visual patterns.  
**Why:** Money surfaces must feel premium, clear, and trustworthy.  
**How:** Use hero material selectively and keep payment states practical.  
**Result:** Booking and wallet visuals align without hiding state meaning.

- [ ] (@Pixel | Skill: normalize) Use booking hero material only where it maps to booking/provider identity or wallet/money hero context.
- [ ] (@Pixel | Skill: colorize) Use semantic payment colors for success, pending, failure, refund, and canceled states.
- [ ] (@Pixel | Skill: typeset) Use Fraunces/display roles only for major wallet values, booking provider names, and screen titles where appropriate.
- [ ] (@Pixel | Skill: arrange) Keep payment checkout compact and action-focused; do not add marketing-like explanation cards.
- [ ] (@Pixel | Skill: polish) Keep WebView shell plain enough not to fight gateway content.
- [ ] (@Sentinel | Skill: audit) Verify no payment/wallet surface uses raw status colors or misleading active affordances.
- **GATE CHECK:** visual hierarchy reinforces, rather than obscures, payment state.

### 8.4 Interaction / Motion

**Primary Agent(s):** @Pixel, @Architect, @Sentinel  
**Goal:** Improve payment and wallet UI feedback without changing authority.  
**Why:** Payment flows are sensitive to duplicate actions, pending contexts, callbacks, and route cleanup.  
**How:** Keep existing payment delegate, pending store, helper, and Edge Function boundaries.  
**Result:** Payment interactions remain safe and testable.

- [ ] (@Pixel | Skill: animate) Use `AppMotion` for touched loading, pending, refresh, and route/sheet transitions.
- [ ] (@Architect) Preserve hardened payment intent creation and recovery through existing Edge Function/service paths.
- [ ] (@Architect) Preserve `PaymentPendingStore` save/load/clear semantics and provider type as plain `Provider.value` in tests.
- [ ] (@Architect) Preserve trusted callback host validation and return parsing in WebView/return flows.
- [ ] (@Architect) Preserve URL cleanup after payment return parsing.
- [ ] (@Architect) Preserve booking lifecycle guard and ledger boundaries.
- [ ] (@Sentinel) Verify payment actions cannot double-submit and retry/cancel paths keep pending context consistent.
- **GATE CHECK:** payment authority remains service/Edge/DB governed.

### 8.5 Hardening / Responsive / Accessibility

**Primary Agent(s):** @Pixel, @ThreatModeler, @Observability, @Sentinel  
**Goal:** Harden booking/payment/wallet under all critical states.  
**Why:** These screens carry money, commitments, and private financial context.  
**How:** Test state matrix, overflow, semantics, logs, and payment smoke paths.  
**Result:** Phase 8 is payment-safe and accessible.

- [ ] (@Pixel | Skill: harden) Verify booking pending, confirmed, active, delivered, completed, canceled, refunded, disputed, no-show, declined, paid-request-pending, and expired-unanswered states where applicable.
- [ ] (@Pixel | Skill: harden) Verify payment success, failure, pending, canceled, retry, expired, missing context, demo provider, real provider, trusted callback, and WebView load error states.
- [ ] (@Pixel | Skill: harden) Verify wallet loading, empty activity, activity list, error, refresh, available/held/pending balances, and withdrawal disabled/Coming Soon if current product requires it.
- [ ] (@ThreatModeler) Verify UI never treats gateway URL content as trusted beyond existing parser/host checks.
- [ ] (@ThreatModeler) Verify no ledger mutation or payment status assumption is added to UI code.
- [ ] (@Observability) Verify new logs do not include raw payment request IDs, gateway IDs, correlation IDs, booking IDs, wallet account IDs, raw URLs, or raw exception strings in routine UI paths.
- [ ] (@Sentinel | Skill: audit) Verify 360 px and text scale 1.3 for booking cards, payment checkout, payment return, WebView shell, wallet hero, and wallet timeline.
- **GATE CHECK:** Phase 8 passes payment, wallet, overflow, semantics, and privacy checks.

### 8.6 Final Audit / QA

**Primary Agent(s):** @Sentinel, @CodeGuard, @ThreatModeler, @DocsKeeper  
**Goal:** Verify Phase 8 and money-flow safety.  
**Why:** Booking/payment/wallet regressions are high impact.  
**How:** Run focused tests, payment smoke checks, scans, and docs evidence.  
**Result:** Phase 8 closes with evidence.

- [ ] (@Sentinel) Run `flutter test test/unit/booking/ test/widget/booking/`.
- [ ] (@Sentinel) Run `flutter test test/unit/wallet/ test/widget/wallet/wallet_shared_body_test.dart`.
- [ ] (@Sentinel) Run `flutter test test/unit/core/payment_runtime_config_test.dart test/unit/core/demo_payment_service_test.dart`.
- [ ] (@Sentinel) Run `flutter test test/rls/ledger_rls_test.dart test/integration_test/booking_request_flow_test.dart`.
- [ ] (@Sentinel) Add focused widget tests for changed bookings list, payment method, payment WebView shell, payment order summary, wallet screen, and wallet dashboard gaps.
- [ ] (@Sentinel) Run `rg 'Supabase\\.instance|\\.from\\(|\\.rpc\\(' lib/features/booking/view lib/features/wallet/view`.
- [ ] (@CodeGuard) Review payment pending store provider type, trusted callback behavior, URL cleanup, raw visual constants, raw errors, and log privacy.
- [ ] (@DocsKeeper) Record payment/wallet evidence, smoke results, and unresolved exact-design gaps.
- **GATE CHECK:** Phase 8 passes focused tests, sensitive-flow review, and payment smoke checks.

## Phase 9: Cross-Phase QA, Visual Runtime Matrix, And Release Readiness

**Primary Agent(s):** @Sentinel, @CodeGuard, @ThreatModeler, @Pixel  
**Goal:** Verify phases 5-8 together.  
**Why:** The block spans auth, realtime, work, payment, and wallet; integration bugs can cross phase boundaries.  
**How:** Run full static gates, focused tests, coverage floor, builds, visual QA, and architecture scans.  
**Result:** The block is ready for PlanCritic/Orchestrator review and Mohammed handoff.

### 9.1 Static And Architecture Gates

**Primary Agent(s):** @Sentinel, @CodeGuard  
**Goal:** Run project-quality checks.  
**Why:** CI must not discover basic issues.  
**How:** Run format, analyze, diff, architecture, visual-token, and backend-no-change scans.  
**Result:** Static quality is proven.

- [ ] (@Sentinel) Run `dart format --set-exit-if-changed .`.
- [ ] (@Sentinel) Run `flutter analyze --no-fatal-infos`.
- [ ] (@Sentinel) Run `git diff --check`.
- [ ] (@Sentinel) Run `rg 'Supabase\\.instance|\\.from\\(|\\.rpc\\(' lib/features/*/view`.
- [ ] (@Sentinel) Run `rg 'Color\\(0x|#[0-9A-Fa-f]{6}|Colors\\.|BoxShadow\\(|Duration\\(milliseconds:|fontSize:' lib/features`.
- [ ] (@Sentinel) Run `rg 'BackdropFilter|ImageFilter\\.blur|glass_' lib/core lib/features`.
- [ ] (@Sentinel) Run `git diff --name-only -- supabase/migrations supabase/functions supabase/tests` and require no output.
- [ ] (@CodeGuard) Review all modified files for MVVM, design-token usage, raw error leakage, privacy-safe logs, and no global theme flip.
- **GATE CHECK:** static and architecture scans pass or every exception is documented.

### 9.2 Automated Test Gates

**Primary Agent(s):** @Sentinel, @CodeGuard  
**Goal:** Verify behavior with focused and broad test coverage.  
**Why:** Phases 5-8 touch high-risk areas.  
**How:** Run focused phase test bundles first, then full coverage.  
**Result:** Behavior is verified before docs closure.

- [ ] (@Sentinel) Run each phase-specific test bundle from phases 5.6, 6.6, 7.6, and 8.6.
- [ ] (@Sentinel) Run `flutter test --coverage`.
- [ ] (@Sentinel) Parse `coverage/lcov.info` only after the coverage run and confirm the existing CI floor is not regressed.
- [ ] (@Sentinel) Remove or leave untracked generated coverage artifacts according to repo practice before final status.
- [ ] (@CodeGuard) Confirm no new test depends on real Supabase initialization unless it is an intended integration/RLS test.
- **GATE CHECK:** focused and full test gates pass, and coverage artifact handling is clean.

### 9.3 Build Gates

**Primary Agent(s):** @Sentinel, @CodeGuard  
**Goal:** Confirm platform compilation.  
**Why:** Payment/WebView/native package surfaces can fail outside analyzer/tests.  
**How:** Run existing CI build checks.  
**Result:** The block compiles for release targets.

- [ ] (@Sentinel) Run `flutter build apk --debug`.
- [ ] (@Sentinel) Run `flutter build web --release`.
- [ ] (@CodeGuard) Record build output status in the session log.
- **GATE CHECK:** APK debug and web release build checks pass or blockers are documented.

### 9.4 Runtime Visual QA Matrix

**Primary Agent(s):** @Pixel, @Sentinel  
**Goal:** Capture runtime Flutter evidence for phases 5-8.  
**Why:** Open Design reference evidence does not close Flutter runtime visual QA.  
**How:** Use simulator/device screenshots and manual notes across route/state/width matrix.  
**Result:** Visual completion is based on implemented app evidence.

- [ ] (@Pixel | Skill: audit) Create `.TODO/EMULATOR_TEST_CHECKLIST_2026-05-12_OpenDesign_AmberDusk_Phases5_6_7_8.md`.
- [ ] (@Pixel | Skill: audit) Create `.TODO/VisualQA_OpenDesign_AmberDusk_Phases5_6_7_8_iOSSimulator_2026-05-12/REPORT.md`.
- [ ] (@Sentinel) Capture or request runtime evidence for widths 360, 390, 402, and 430 where feasible.
- [ ] (@Sentinel) Cover Phase 5 routes: login, signup, forgot success, reset, restricted, maintenance, update required.
- [ ] (@Sentinel) Cover Phase 6 routes/states: messages empty/populated/unread/search, chat own/other/typing/attachment/offer, notifications empty/loading/read/unread/error.
- [ ] (@Sentinel) Cover Phase 7 routes/states: task details, tenders, requests/proposals, submit sheet, award dialog, tender payment, direct offer details, work item details, delivery/review/extension, management logs.
- [ ] (@Sentinel) Cover Phase 8 routes/states: booking discovery/list/detail, payment checkout/method/return/WebView, wallet screen/dashboard/loading/error/empty/activity.
- [ ] (@Pixel | Skill: polish) Compare implemented runtime screenshots against Open Design where exact evidence exists and record adaptation notes where exact evidence is missing.
- **GATE CHECK:** no visual completion claim without runtime Flutter evidence.

### 9.5 Final Sensitive-Flow Review

**Primary Agent(s):** @ThreatModeler, @Observability, @CodeGuard, @Sentinel  
**Goal:** Confirm sensitive workflows remain safe.  
**Why:** Phases 6-8 include private messages, attachments, offers, payment, wallet, and disputes.  
**How:** Run negative checks and diff review.  
**Result:** Visual work does not create security or privacy regressions.

- [ ] (@ThreatModeler) Verify no client notification insert path was added.
- [ ] (@ThreatModeler) Verify no view stores or exposes signed URLs or private storage paths.
- [ ] (@ThreatModeler) Verify no UI-only payment, ledger, award, direct-offer, dispute, delivery, revision, extension, or booking transition was added.
- [ ] (@Observability) Verify new logs are structured and privacy-safe.
- [ ] (@CodeGuard) Verify no service/repository/backend changes are mixed into the visual phase without a separate plan.
- [ ] (@Sentinel) Record all sensitive-flow checks in the session log and final report.
- **GATE CHECK:** sensitive-flow review passes before docs closure.

## Phase 10: Documentation, Handoff, And Closure

**Primary Agent(s):** @DocsKeeper, @Sentinel, @Planner  
**Goal:** Sync documentation and handoff artifacts after verified execution.  
**Why:** Amber Dusk workflow keeps planning, evidence, implementation, verification, and handoff connected.  
**How:** Update docs only from verified implementation reality.  
**Result:** The repo contains a trustworthy record for future phone/web continuation.

### 10.1 Docs Sync

**Primary Agent(s):** @DocsKeeper, @Sentinel  
**Goal:** Update core docs with verified Phase 5-8 reality.  
**Why:** Docs must reflect actual changed surfaces and open visual gates.  
**How:** Sync SLine docs after tests and visual QA.  
**Result:** Documentation remains current.

- [ ] (@DocsKeeper) Update `Sline_everything/DEVELOPER_GUIDE.md` with Amber Dusk phases 5-8 scope, affected files, validation, and open visual gates.
- [ ] (@DocsKeeper) Update `Sline_everything/STRUCTURE.md` with date and phase ownership notes for auth, chat, notifications, tasks, proposals, direct offers, work, management, booking, payment, and wallet surfaces.
- [ ] (@DocsKeeper) Update `Sline_everything/MVP_ROADMAP.md` status rows for auth/system, chat/notifications, tasks/proposals/direct offers/work, booking/payment, and wallet.
- [ ] (@DocsKeeper) Update `Sline_everything/CODE_REVIEW.md` with Phase 5-8 review rules, especially payment/log privacy/token compliance.
- [ ] (@DocsKeeper) Update `Sline_everything/Sline_Log.md` if current project practice requires a milestone entry.
- [ ] (@DocsKeeper) Write `.TODO/DOCS_SYNC_2026-05-12_OpenDesign_AmberDusk_Phases5_6_7_8.md`.
- [ ] (@Sentinel) Validate docs reference only files that exist.
- **GATE CHECK:** docs match verified implementation, not planned intent.

### 10.2 Master Report And Handoff

**Primary Agent(s):** @DocsKeeper, @Planner, @Sentinel  
**Goal:** Produce closeout artifacts and web handoff.  
**Why:** Mohammed needs a clean handoff after phone proof.  
**How:** Summarize scope, evidence, tests, visual QA, gaps, and web notes.  
**Result:** Phase 5-8 work can be reviewed and adapted without guessing.

- [ ] (@DocsKeeper) Write `.TODO/MASTER_REPORT_2026-05-12_OpenDesign_AmberDusk_Phases5_6_7_8.md`.
- [ ] (@DocsKeeper) Write `.TODO/WebRedsign/HANDOFF_OpenDesign_AmberDusk_Phases5_6_7_8_ToWeb_2026-05-12.md`.
- [ ] (@Planner) Record exact Open Design evidence files and missing evidence caveats in the master report.
- [ ] (@Sentinel) Record all commands run, pass/fail status, and manual visual QA results in the session log.
- [ ] (@Sentinel) Record any remaining open gates, especially missing screenshot evidence or runtime parity gaps.
- **GATE CHECK:** final report, handoff, session log, docs sync, and visual QA are cross-linked.

## H.12 Acceptance Criteria

- [ ] (@PlanCritic) The persisted critique artifact exists at `.TODO/PLAN_CRITIQUE_2026-05-12_OpenDesign_AmberDusk_Phases5_6_7_8_PhoneTrustMessagingWorkPayments.md` and this corrected plan references it.
- [ ] (@Sentinel) Every master Phase 5-8 target is implemented, explicitly documented as already compliant, or explicitly blocked by missing design/product evidence.
- [ ] (@Architect) No view adds direct Supabase calls, direct storage calls, raw RPC calls, or backend lifecycle authority.
- [ ] (@Supabase_Ops | Skill: supabase-migration) No Supabase migrations, Edge Functions, policies, buckets, SQL tests, or live backend mutations are part of this visual plan.
- [ ] (@Pixel | Skill: normalize) New reusable visual values live in theme/tokens/adapters, not scattered feature files.
- [ ] (@Pixel | Skill: harden) Changed UI fits 360, 390, 402, and 430 widths with text scale 1.3 where applicable.
- [ ] (@ThreatModeler) Payment, booking, wallet, direct-offer, tender, work, and dispute controls remain service/DB/Edge governed.
- [ ] (@Observability) New logs are structured and privacy-safe.
- [ ] (@Sentinel) Focused phase tests and full `flutter test --coverage` pass.
- [ ] (@Sentinel) `flutter analyze --no-fatal-infos`, `dart format --set-exit-if-changed .`, `flutter build apk --debug`, and `flutter build web --release` pass.
- [ ] (@Sentinel) Runtime Flutter visual QA evidence exists before visual completion is claimed.
- [ ] (@DocsKeeper) Docs, session log, final report, visual QA checklist/report, and Mohammed handoff are synced after verification.

## H.13 Rollback Plan

- [ ] (@Architect) Roll back one phase at a time: Phase 5 auth/gates, Phase 6 chat/notifications, Phase 7 work lifecycle, or Phase 8 booking/payment/wallet.
- [ ] (@Architect) Roll back source files, matching tests, docs sync entries, visual QA artifacts, and session log notes together so evidence does not lie about current code.
- [ ] (@Supabase_Ops | Skill: supabase-migration) No database rollback is planned because no backend changes are allowed.
- [ ] (@ThreatModeler) If a sensitive-flow regression is found after merge, prefer source rollback for visual files or a forward fix that restores the original ViewModel/service authority. Do not patch backend from the UI plan.
- [ ] (@Sentinel) Before choosing rollback vs forward-fix, inspect failing tests, architecture scans, and git diff scope.
- [ ] (@DocsKeeper) If rollback happens after docs sync, update docs and session log to mark the rollback and remaining open phase state.

## H.14 References (From Scan)

- `.cursor/Agents/Planner.md`
- `.cursor/Agents/PlanCritic.md`
- `.TODO/PLAN_CRITIQUE_2026-05-12_OpenDesign_AmberDusk_Phases5_6_7_8_PhoneTrustMessagingWorkPayments.md`
- `.cursor/Agents/Pixel.md`
- `.cursor/Agents/Architect.md`
- `.cursor/Agents/Sentinel.md`
- `.cursor/Agents/Supabase_Ops.md`
- `.cursor/Agents/ThreatModeler.md`
- `.cursor/Agents/Observability.md`
- `.cursor/Agents/DocsKeeper.md`
- `.cursor/skills/frontend-design/SKILL.md`
- `.cursor/skills/arrange/SKILL.md`
- `.cursor/skills/normalize/SKILL.md`
- `.cursor/skills/colorize/SKILL.md`
- `.cursor/skills/typeset/SKILL.md`
- `.cursor/skills/clarify/SKILL.md`
- `.cursor/skills/harden/SKILL.md`
- `.cursor/skills/polish/SKILL.md`
- `.cursor/skills/audit/SKILL.md`
- `.cursor/skills/animate/SKILL.md`
- `.cursor/skills/extract/SKILL.md`
- `.cursor/skills/supabase-migration/SKILL.md`
- `.TODO/PLAN_OpenDesign_AmberDusk_Phone_2026-05-10.md`
- `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/PLAN_OpenDesign_AmberDusk_Phase0_PhoneFoundation_2026-05-11.md`
- `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/PLAN_OpenDesign_AmberDusk_Phase1_CorePhoneWidgets_2026-05-11.md`
- `.TODO/Archive/OpenDesign_AmberDusk_Phases2_3_4_2026-05-12/PLAN_OpenDesign_AmberDusk_Phases2_3_4_PhoneShellDiscoveryDashboard_2026-05-11.md`
- `.TODO/Archive/OpenDesign_AmberDusk_Phases2_3_4_2026-05-12/MASTER_REPORT_2026-05-12_OpenDesign_AmberDusk_Phases2_3_4_Step6.md`
- `docs/LOG/SESSION_PLAN_OpenDesign_AmberDusk_Phases2_3_4_PhoneShellDiscoveryDashboard_2026-05-11.md`
- `Sline_everything/DEVELOPER_GUIDE.md`
- `Sline_everything/SUPABASE_SETUP.md`
- `Sline_everything/MVP_ROADMAP.md`
- `Sline_everything/ARCHITECTURE_ANALYSIS.md`
- `Sline_everything/CODE_REVIEW.md`
- `Sline_everything/STRUCTURE.md`
- `.cursor/PROJECT_CONTEXT.md`
- Live Supabase project `isddrknbjsgaantjojhm`
- Open Design project `1674a1db-7a74-4c80-8e2c-196a0385a8f7`
- Open Design files: `Sline V2 Amber Dusk.html`, `amber-dusk-design-system.html`, `sline-v2-amber-dusk-web.html`

## H.15 Scan Evidence

### Constructor Signatures

| Target | Constructor / Pattern | Base Class | Mocking Notes |
|---|---|---|---|
| `AuthFormViewModel` | `AuthFormViewModel({AuthRepository? authRepo, AccountGuardService? accountGuardService, SupabaseClient? client})` | `ChangeNotifier` | Fully injectable enough for tests; default guard tries `Supabase.instance` lazily in helper and can be avoided with mocks. |
| `AuthSessionViewModel` | `AuthSessionViewModel({AuthRepository? authRepo, Stream<AuthState>? authStateChanges})` | `ChangeNotifier` | Auto-loads listener/profile in constructor; configure auth stream and repo stubs before construction. |
| `ChatViewModel` | `ChatViewModel({ChatRepository? repo, AccountGuardService? accountGuardService, DirectOffersService? directOffersService, SupabaseClient? client})` | `ChangeNotifier with RoleSwitchAware` | Registers with `RoleSwitchCoordinator`; use mocks and `clearForTesting()` cleanup. |
| `NotificationViewModel` | `NotificationViewModel({NotificationService? service, Stream<AuthState>? authStateChanges, SupabaseClient? client})` | `ChangeNotifier` | Auto-inits auth listener and may connect if current user exists; configure stream/service/client before construction. |
| `DirectOfferDetailsViewModel` | `DirectOfferDetailsViewModel({required offerId, conversationId, currentUserId, required DirectOffersService directOffersService, required PaymentService paymentService})` | `ChangeNotifier` | Fully injectable; screen creates it internally from Provider services. |
| `WorkItemDetailsViewModel` | `WorkItemDetailsViewModel({WorkManagementService? workService, required String uid, ChatViewModel? chatViewModel, DashboardViewModel? dashboardViewModel})` | `ChangeNotifier` | Service injectable; screen creates internally from Provider context and calls `loadData` after frame. |
| `BookingViewModel` | `BookingViewModel({required BookingRepository repo, required ChatRepository chatRepository, PaymentService? paymentService})` | `ChangeNotifier` | Fully injectable; payment delegate created from repo/service. |
| `WalletViewModel` | `WalletViewModel({WalletRepository? repo, AccountGuardService? accountGuardService, SupabaseClient? client})` | `ChangeNotifier` | Injectable but default uses `Supabase.instance`; provide mocks in tests. |
| `TaskRequestsViewModel` | `TaskRequestsViewModel({required taskId, isOwner=false, TaskRequestsService? service, TaskService? taskService, ProposalRepository? proposalRepo})` | `ChangeNotifier` | Service injectable; creates proposal repo when owner and missing. |
| `SubmitRequestViewModel` | `SubmitRequestViewModel({required TaskService taskService, required TaskRequestsService requestsService, required TaskRequestsViewModel controller, required taskId, required userId, required budget})` | `ChangeNotifier` | Fully injectable; sheet-scoped Provider. |
| `TenderPaymentViewModel` | `TenderPaymentViewModel({required TenderPaymentCoordinator coordinator, required requestId, required taskTitle, required freelancerName, required amount, required paymentDeadline})` | `ChangeNotifier` | Fully injectable; WebView route side effects must be tested with Navigator observer. |
| `OrderManagementViewModel` | `OrderManagementViewModel([WorkLogService? service])` | `ChangeNotifier` | Service injectable; `OrderManagementPanel` auto-loads in `initState`. |
| `PaymentPendingStore` | `PaymentPendingStore(SharedPreferences prefs)` | Plain class | Use `Provider.value`, not `ChangeNotifierProvider.value`. |

### Screen Mocking Classification

| Screen / Widget | Type | Mock Targets | Provider Type | Notes |
|---|---|---|---|---|
| `LoginScreen` | Type B | `AuthRepository`, `AccountGuardService`, `AuthSessionViewModel`, `SystemConfigViewModel` | `ChangeNotifierProvider.value` for VMs | Screen creates `AuthFormViewModel`; provide repo/guard context. |
| `SignupScreen` | Type B | `AuthRepository`, `AuthSessionViewModel`, `SystemConfigViewModel` | `ChangeNotifierProvider.value` | Screen creates `AuthFormViewModel`; signup-disabled state comes from config. |
| `ForgotPasswordScreen` | Type B | `AuthRepository` | `Provider.value` for repo if exposed | Screen creates `AuthFormViewModel`. |
| `ResetPasswordUpdateScreen` | Type B | `AuthRepository`, recovery/session inputs | `Provider.value` / `ChangeNotifierProvider` | Configure reset/update mocks before pump. |
| `AccountRestrictedScreen` | Type A | `AuthSessionViewModel` | `ChangeNotifierProvider.value` | Sign-out action reads session VM. |
| `MaintenanceScreen` | Type A/Static | `SystemConfigViewModel` if routed with config | `ChangeNotifierProvider.value` | Verify retry/update state only. |
| `UpdateRequiredScreen` | Type A/Static | `SystemConfigViewModel` if routed with config | `ChangeNotifierProvider.value` | Verify CTA and copy. |
| `MessagesScreen` | Type A | `ChatViewModel`, `DeepLinkService` if notification/deep link path tested | `ChangeNotifierProvider.value` | Auto subscribes/fetches in `initState`; configure stubs before pump. |
| `ChatScreen` | Type A | `ChatViewModel`, `SafetyViewModel`, attachment services if injected | `ChangeNotifierProvider.value` | Auto fetches/subscribes in `initState`. |
| `ConversationListTile` | Type A | `ChatViewModel` for tap/read actions | `ChangeNotifierProvider.value` | Test row states directly where possible. |
| `MessageBubble` | Stateless/Type A | Message fixture only | None or inherited theme | Direct widget tests for own/other/emoji/link/reply. |
| `OfferMessageBubble` | Stateless/Type A | Message/offer fixture, callbacks | None or callback fakes | Test offer status/action combinations. |
| `AttachmentMessageTile` | Stateless/Type A | Attachment payload/generator callbacks | None or dependency fakes | Add direct widget tests for loading/error/fullscreen affordance. |
| `CreateOfferSheet` | Type B/Sheet | `ChatViewModel`, `DirectOffersService` through chat VM path | `ChangeNotifierProvider.value` | Validate fields and loading without service calls in view. |
| `NotificationsModal` | Type A | `NotificationViewModel`, `DeepLinkService` | `ChangeNotifierProvider.value` | Modal reads VM and returns selected item. |
| `NotificationBadgeButton` | Type A | `NotificationViewModel`, `DeepLinkService` | `ChangeNotifierProvider.value` | Count animation must be pumped deterministically. |
| `NotificationTile` | Stateless/Type A | Notification fixture | None | Add direct read/unread/long-copy tests. |
| `TaskDetailsScreen` | Type A | `TaskRequestsViewModel`, `TaskViewModel`, `SafetyViewModel`, favorites/profile dependencies | `ChangeNotifierProvider.value` | Existing tests are broad; avoid real details route dependencies. |
| `TendersScreen` | Type A | `DiscoveryFeedViewModelContract`, `TaskFilterViewModel` | `ChangeNotifierProvider.value` | List/filter behavior from existing VMs. |
| `TenderPaymentScreen` | Type A | `TenderPaymentViewModel`, `DashboardViewModel` | `ChangeNotifierProvider.value` | Navigator observer for payment WebView route. |
| `RequestsListScreen` | Type A/B mixed | `TaskRequestsViewModel`, `RequestsFilterViewModel`, `FavoritesViewModel` | `ChangeNotifierProvider.value` | Existing tests cover many states; keep fixtures deterministic. |
| `RequestTile` | Type A | `TaskRequestsViewModel`, `FavoritesViewModel`, callbacks | `ChangeNotifierProvider.value` | Test statuses and action states. |
| `SubmitRequestSheet` | Type B/Sheet | `SubmitRequestViewModel`, `TaskRequestsViewModel`, services | `ChangeNotifierProvider.value` | Configure validation/replaceability before pump. |
| `RequestAwardDialog` | Dialog | `TaskRequestsViewModel` / callbacks | `ChangeNotifierProvider.value` if needed | Test price mismatch and already accepted states. |
| `ProposalDetailsModal` | Modal/Stateless | Proposal fixture/callbacks | None or callback fakes | Add direct tests if changed. |
| `DirectOfferDetailsScreen` | Type B | `DirectOffersService`, `PaymentService`, `AuthSessionViewModel`, `SafetyViewModel` | `Provider.value` for services, `ChangeNotifierProvider.value` for VMs | Screen creates `DirectOfferDetailsViewModel` and calls `loadOffer`. |
| `WorkItemDetailsScreen` | Type B | `WorkManagementService`, `AuthSessionViewModel`, `ChatViewModel`, `DashboardViewModel`, `SafetyViewModel` | `Provider.value` / `ChangeNotifierProvider.value` | Auto loads after frame; configure mocks first. |
| `OrderManagementPanel` | Type A | `OrderManagementViewModel` | `ChangeNotifierProvider.value` | Auto loads logs in `initState`. |
| `BookingsDiscoveryScreen` | Type A | `DiscoveryFeedViewModelContract`, `TaskFilterViewModel` | `ChangeNotifierProvider.value` | Auto loads featured booking tasks. |
| `BookingsListScreen` | Type A | `BookingViewModel` | `ChangeNotifierProvider.value` | Auto loads client/provider lists. |
| `BookingDetailsScreen` | Type A | `BookingViewModel`, `SafetyViewModel`, `ChatViewModel` if chat action tested | `ChangeNotifierProvider.value` | Preserve report/dispute guards. |
| `PaymentCheckoutScreen` | Type A | `BookingViewModel`, `PaymentPendingStore` | `ChangeNotifierProvider.value`; `Provider.value` for store | Verify pending save/load/clear. |
| `PaymentMethodScreen` | Type A/Static | Payment method callbacks/config | Callback fakes | Add direct tests if changed. |
| `PaymentReturnScreen` | Type A | `BookingViewModel`, `PaymentPendingStore` | `ChangeNotifierProvider.value`; `Provider.value` for store | Configure pending context before pump. |
| `PaymentWebViewScreen` | Stateful/Route | WebView navigation delegate, return args | Navigator observer / route harness | Use route tests; avoid real network. |
| `WalletScreen` | Type A | `WalletViewModel` | `ChangeNotifierProvider.value` | Shell around shared body. |
| `WalletDashboardScreen` | Type A | `WalletViewModel` | `ChangeNotifierProvider.value` | Shell around shared body. |
| `WalletSharedBody` | Type A | `WalletViewModel` | `ChangeNotifierProvider.value` | Auto ensureLoaded in `initState`. |

### Singleton/Static State

- [ ] `RoleSwitchCoordinator` is a singleton and has `clearForTesting()`. Use cleanup where `ChatViewModel` or `TaskViewModel` are constructed.
- [ ] `PaymentPendingStore` uses `SharedPreferences`; tests must set mock initial values and clear pending context.
- [ ] `AuthSessionViewModel` and `NotificationViewModel` subscribe to auth streams; tests must close stream controllers and dispose VMs.
- [ ] `ChatViewModel` uses stream subscriptions and timers; tests must dispose VM and clear coordinator registrations.
- [ ] `MessagesScreen` uses search debounce timer; tests must advance time or dispose cleanly.
- [ ] `ChatScreen` uses subscriptions, scroll, reply animation, and timers; tests must bound pumps and dispose cleanly.

### Auto-Loading Constructors / InitState Calls

- [ ] `AuthSessionViewModel` calls `_initAuthListener()` and `_loadInitialProfile()` in constructor.
- [ ] `NotificationViewModel` calls `_init()` in constructor and may connect to streams.
- [ ] `WalletSharedBody` calls `ensureLoaded()` in `initState`.
- [ ] `BookingsDiscoveryScreen` loads featured tasks in `initState`.
- [ ] `BookingsListScreen` loads client/provider bookings in `initState`.
- [ ] `MessagesScreen` fetches conversations and subscribes in `initState`.
- [ ] `ChatScreen` fetches messages and subscribes in `initState`.
- [ ] `WorkItemDetailsScreen` calls `loadData()` after frame.
- [ ] `OrderManagementPanel` calls `loadLogs()` in `initState`.
- [ ] `DirectOfferDetailsScreen` creates VM and calls `loadOffer()`.

### Line Counts

| File | Lines |
|---|---:|
| `lib/features/auth/view/login_screen.dart` | 586 |
| `lib/features/auth/view/signup_screen.dart` | 780 |
| `lib/features/auth/view/forgot_password_screen.dart` | 285 |
| `lib/features/auth/view/reset_password_update_screen.dart` | 343 |
| `lib/features/auth/view/account_restricted_screen.dart` | 144 |
| `lib/features/auth/view/maintenance_screen.dart` | 113 |
| `lib/features/auth/view/update_required_screen.dart` | 113 |
| `lib/features/chat/view/messages_screen.dart` | 1104 |
| `lib/features/chat/view/chat_screen.dart` | 1446 |
| `lib/features/chat/view/widgets/conversation_list_tile.dart` | 446 |
| `lib/features/chat/view/widgets/message_bubble.dart` | 450 |
| `lib/features/chat/view/widgets/offer_message_bubble.dart` | 538 |
| `lib/features/chat/attachments/widgets/attachment_message_tile.dart` | 356 |
| `lib/features/chat/view/widgets/create_offer_sheet.dart` | 345 |
| `lib/features/chat/view/widgets/chat_context_widget.dart` | 147 |
| `lib/features/notifications/view/notifications_modal.dart` | 430 |
| `lib/features/notifications/view/widgets/notification_badge_button.dart` | 201 |
| `lib/features/notifications/view/widgets/notification_tile.dart` | 160 |
| `lib/features/tasks/view/task_details_screen.dart` | 695 |
| `lib/features/tasks/view/tenders_screen.dart` | 124 |
| `lib/features/tasks/view/tender_payment_screen.dart` | 338 |
| `lib/features/tasks/view/widgets/requests/requests_list_screen.dart` | 679 |
| `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart` | 565 |
| `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart` | 737 |
| `lib/features/tasks/view/widgets/requests/request_award_dialog.dart` | 553 |
| `lib/features/proposals/view/proposals_list_screen.dart` | 3 |
| `lib/features/proposals/view/widgets/proposal_tile.dart` | 3 |
| `lib/features/proposals/view/proposal_details_modal.dart` | 371 |
| `lib/features/proposals/view/widgets/submit_proposal_sheet.dart` | 3 |
| `lib/features/proposals/view/proposal_payment_screen.dart` | 3 |
| `lib/features/direct_offers/view/direct_offer_details_screen.dart` | 737 |
| `lib/features/work/view/work_item_details_screen.dart` | 780 |
| `lib/features/work/view/widgets/submit_delivery_modal.dart` | 67 |
| `lib/features/work/view/widgets/review_delivery_modal.dart` | 202 |
| `lib/features/work/view/widgets/request_extension_modal.dart` | 79 |
| `lib/features/work/view/widgets/work_item_bottom_actions.dart` | 265 |
| `lib/features/work/view/widgets/work_item_guard_widgets.dart` | 205 |
| `lib/features/work/view/widgets/work_item_booking_details.dart` | 126 |
| `lib/features/management/view/order_management_panel.dart` | 228 |
| `lib/features/management/view/widgets/order_management_section.dart` | 29 |
| `lib/features/management/view/widgets/work_log_tile.dart` | 130 |
| `lib/features/booking/view/bookings_discovery_screen.dart` | 127 |
| `lib/features/booking/view/bookings_list_screen.dart` | 218 |
| `lib/features/booking/view/booking_details_screen.dart` | 745 |
| `lib/features/booking/view/payment_checkout_screen.dart` | 769 |
| `lib/features/booking/view/payment_method_screen.dart` | 257 |
| `lib/features/booking/view/payment_return_screen.dart` | 320 |
| `lib/features/booking/view/payment_webview_screen.dart` | 654 |
| `lib/features/booking/view/widgets/payment_order_summary_card.dart` | 98 |
| `lib/features/booking/view/widgets/booking_card.dart` | 184 |
| `lib/features/wallet/view/wallet_screen.dart` | 63 |
| `lib/features/wallet/view/wallet_dashboard_screen.dart` | 45 |
| `lib/features/wallet/view/widgets/wallet_shared_body.dart` | 554 |
| `lib/features/wallet/view/widgets/wallet_hero_card.dart` | 269 |
| `lib/features/wallet/view/widgets/wallet_snapshot_card.dart` | 203 |
| `lib/features/wallet/view/widgets/wallet_timeline_card.dart` | 206 |

### Coverage Baseline

- [ ] `coverage/lcov.info` was absent during planning.
- [ ] This plan does not set a new coverage percentage target.
- [ ] Executor must run `flutter test --coverage`, parse `coverage/lcov.info`, confirm the existing CI 40% floor is not regressed, and avoid leaving generated coverage artifacts in final review scope unless CI requires them.

### Provider Dependencies

- [ ] Auth screens depend on `AuthRepository`, `AuthSessionViewModel`, `AuthFormViewModel` created internally, and `SystemConfigViewModel` for disabled signup/system configuration.
- [ ] Chat screens depend on `ChatViewModel`, `SafetyViewModel`, direct-offer services through ViewModel/provider wiring, attachment services, and route/navigation context.
- [ ] Notifications depend on `NotificationViewModel` and `DeepLinkService`.
- [ ] Direct Offer Details depends on `AuthSessionViewModel`, `DirectOffersService`, `PaymentService`, `SafetyViewModel`, and screen-created `DirectOfferDetailsViewModel`.
- [ ] Work Details depends on `AuthSessionViewModel`, `WorkManagementService`, `ChatViewModel`, `DashboardViewModel`, `SafetyViewModel`, and screen-created `WorkItemDetailsViewModel`.
- [ ] Booking screens depend on `BookingViewModel`, `SafetyViewModel`, `ChatViewModel` for chat actions, `PaymentPendingStore`, payment services, and route arguments.
- [ ] Wallet screens depend on `WalletViewModel`.
- [ ] Request/proposal screens depend on `TaskRequestsViewModel`, `RequestsFilterViewModel`, `SubmitRequestViewModel`, `TaskService`, `TaskRequestsService`, `TenderPaymentViewModel`, `TenderPaymentCoordinator`, and favorites/profile providers as applicable.

### Path Validation

- [ ] `rg --files` confirmed all listed target files under `lib/features/auth`, `lib/features/chat`, `lib/features/notifications`, `lib/features/tasks`, `lib/features/proposals`, `lib/features/direct_offers`, `lib/features/work`, `lib/features/management`, `lib/features/booking`, `lib/features/wallet`, `lib/core/widgets`, `lib/core/theme`, and `lib/app`.
- [ ] `wc -l` succeeded for every major target file listed in the Line Counts table.
- [ ] Existing focused test files were found under `test/unit`, `test/widget`, `test/features`, `test/rls`, `test/security`, and `test/integration_test`.
- [ ] Planned docs artifacts to create after execution: `.TODO/DOCS_SYNC_2026-05-12_OpenDesign_AmberDusk_Phases5_6_7_8.md`, `.TODO/MASTER_REPORT_2026-05-12_OpenDesign_AmberDusk_Phases5_6_7_8.md`, `.TODO/EMULATOR_TEST_CHECKLIST_2026-05-12_OpenDesign_AmberDusk_Phases5_6_7_8.md`, `.TODO/VisualQA_OpenDesign_AmberDusk_Phases5_6_7_8_iOSSimulator_2026-05-12/REPORT.md`, and `.TODO/WebRedsign/HANDOFF_OpenDesign_AmberDusk_Phases5_6_7_8_ToWeb_2026-05-12.md`.

### Token Value Sources

- [ ] Open Design `amber-dusk-design-system.html` and `Sline V2 Amber Dusk.html` define color sources: `--page #0E0B08`, `--bg #1A1612`, `--bg2 #241F1A`, `--bg3 #2F2822`, `--bg4 #3A312A`, `--cream #F2E8D5`, `--primary #D4906A`, `--primary-deep #A36A48`, `--amber #E6B87A`, `--rust #C9695C`, `--forest #7FA872`, `--hero #3E2418`, `--hero-top #4A2D1F`, `--hero-deep #2E1810`.
- [ ] Open Design defines typography roles: DM Sans for controls/labels/body, Fraunces for page titles, freelancer names, and major wallet values.
- [ ] Open Design defines radius tiers: 24 px booking hero surfaces, 22 px task cards, 18 px stats/utility panels, 26 px bottom nav.
- [ ] Open Design defines depth tiers: `--shadow-surface`, `--shadow-raised`, `--shadow-hero`, `--shadow-cta`, and `--shadow-nav`.
- [ ] Open Design defines system rules: no blue/purple accents, bottom nav remains compact, active state is amber with small glow, message modes are Received/Sent, Dashboard tabs are Overview/Bookings/Work/Wallet/Inbox, Work buckets are Active/Done/Cancelled.
- [ ] Existing token overlap must be checked against `lib/core/theme/designs/amber_dusk/` before adding any new token or component recipe.

## H.16 Open Design Screenshot Export And Visual Notes

**Export date:** 2026-05-12  
**Export folder:** `.TODO/OpenDesign_AmberDusk_Phases5_6_7_8_OpenDesignScreenshots_2026-05-12/`  
**Manifest:** `.TODO/OpenDesign_AmberDusk_Phases5_6_7_8_OpenDesignScreenshots_2026-05-12/README.md`  
**Open Design re-check:** project `1674a1db-7a74-4c80-8e2c-196a0385a8f7` still resolves to `Sline V2 Amber Dusk.html`; `list_files(since: 1778418973981)` returned no newer files before these notes were appended.  
**Export method:** local render of the Open Design project files through headless Chrome using the Open Design artifact HTML. Open Design MCP exposes project/file evidence, but not a direct screenshot-export endpoint.

### Screenshot Authority

- [ ] Phone screenshots are implementation references only for surfaces represented in the phone artifact.
- [ ] Supplemental web screenshots can clarify copy, taxonomy, and density, but cannot become phone pixel-parity targets.
- [ ] Missing exact phone artboards remain adaptation-only until Open Design or user screenshots provide exact evidence.
- [ ] Open Design screenshots do not replace Flutter runtime QA; runtime screenshots remain required before visual completion.

### Exported Screenshot Matrix

| Phase | File | Authority | Visual note |
|---|---|---|---|
| 5 | `phase5-phone-profile-account-settings.png` | Phone reference | Use account/settings row density and quiet edit controls for trust-adjacent surfaces. |
| 5 | `phase5-phone-profile-security-sheet.png` | Phone pattern only | Use sheet structure for security/account surfaces; exact auth screens are still missing. |
| 5 | `phase5-phone-profile-payout-sheet.png` | Phone pattern only | Use payout/account sheet rhythm without adding payment authority. |
| 5 | `phase5-phone-profile-privacy-sheet.png` | Phone pattern only | Use privacy/data density for restricted or gate copy, not as exact gate parity. |
| 6 | `phase6-phone-messages-received-source-copy-conflict.png` | Phone reference with copy conflict | Use row/avatar/unread density; do not keep `Responses` unless product overrides. |
| 6 | `phase6-phone-messages-sent-source-copy-conflict.png` | Phone reference with copy conflict | Use sent-mode row rhythm; corrected plan copy remains `Sent`. |
| 6 | `phase6-phone-dashboard-inbox-received-sent.png` | Phone source decision | Confirms `Received` and `Sent` grouping for phone dashboard inbox. |
| 7 | `phase7-phone-tenders-list.png` | Phone reference | Use tender card/search/status density; lifecycle actions remain ViewModel governed. |
| 7 | `phase7-phone-dashboard-work-active.png` | Phone reference | Use active work bucket pattern while preserving server/ViewModel lifecycle authority. |
| 7 | `phase7-phone-dashboard-work-done.png` | Phone reference | Use done bucket pattern without inventing new completed-state actions. |
| 7 | `phase7-phone-dashboard-work-cancelled.png` | Phone reference | Use cancelled bucket pattern without creating UI-only recovery/refund authority. |
| 8 | `phase8-phone-bookings-browse.png` | Phone reference | Use booking discovery/list card pattern. |
| 8 | `phase8-phone-dashboard-bookings.png` | Phone reference | Use dashboard bookings summary structure. |
| 8 | `phase8-phone-dashboard-wallet.png` | Phone reference with behavior guard | Style wallet summary only; no new active withdrawal route/form/service path. |
| 5 | `supplemental-web-profile-settings.png` | Supplemental web | Clarifies settings row density only. |
| 6 | `supplemental-web-messages-received.png` | Supplemental web | Confirms `Received` copy and three-pane web handoff direction. |
| 6 | `supplemental-web-messages-sent.png` | Supplemental web | Confirms `Sent` copy and sent-offer grouping. |
| 7 | `supplemental-web-dashboard-work-active.png` | Supplemental web | Clarifies work status taxonomy, not phone layout. |
| 7 | `supplemental-web-dashboard-work-done.png` | Supplemental web | Clarifies completed/refunded/closed grouping, not phone layout. |
| 7 | `supplemental-web-dashboard-work-cancelled.png` | Supplemental web | Clarifies cancelled/rejected/expired/lost/withdrawn/no-show grouping. |
| 8 | `supplemental-web-dashboard-bookings.png` | Supplemental web | Clarifies booking dashboard information grouping only. |
| 8 | `supplemental-web-dashboard-wallet.png` | Supplemental web | Clarifies wallet dashboard grouping only; visual reference, no behavior authority. |

### Phase Visual Notes

- [ ] Phase 5: Use the profile settings and bottom-sheet screenshots for spacing, label hierarchy, form fields, and action-row rhythm. Exact auth and system-gate artboards are still missing, so login, signup, reset, maintenance, update-required, and account-restricted screens remain adaptation-only.
- [ ] Phase 5: The Open Design sheets visually blur the background. The implementation must preserve the corrected plan's no-glass/no-backdrop rule and use approved dim overlays/elevation tokens instead.
- [ ] Phase 6: The current phone Messages screenshot has a source-copy conflict: the state is received/sent, but the visible labels are `Responses`/`Requests`. The corrected plan still uses `Received`/`Sent` because dashboard inbox, web, and design-system evidence agree.
- [ ] Phase 6: Message rows should stay compact: avatar, strong participant name, muted preview, right-side time/unread count, and restrained amber active state. Attachment, notification modal, direct-offer-detail, and chat edge states remain adaptation-only where exact artboards are absent.
- [ ] Phase 7: Tender and work-dashboard screenshots define density and status grouping, but lifecycle CTA availability, dispute/refund transitions, and award/payment authority must remain ViewModel/service/DB governed.
- [ ] Phase 7: Supplemental web status screenshots may be used for taxonomy labels and grouping only; phone implementation must not import the web layout.
- [ ] Phase 8: Booking screenshots define booking list and dashboard-summary treatment. Payment method, checkout, return, trusted callback, and WebView screens still lack exact Open Design phone artboards and remain adaptation-only.
- [ ] Phase 8: Wallet screenshots are visual references only. Do not make withdrawal look newly active, and do not add a withdrawal route, request form, service call, or ledger-affecting UI path.

## I) Change Report (Diff-Style)

### Original Issues Summary

- The draft plan was detailed but did not start with the required PlanCritic A-I source-of-truth gate.
- The draft plan did not create a persisted critique artifact for @Executor, @Sentinel, @DocsKeeper, and @SystemEvolution.
- The draft plan left the Phase 6 messaging-copy conflict to the executor instead of resolving it from current design evidence.
- The draft plan left the Phase 8 wallet withdrawal conflict too open and could allow a visual pass to imply new active withdrawal behavior.
- The draft plan contained evidence gaps but did not make exact-match versus adaptation-only authority prominent enough at the top gate.
- The draft plan described test infrastructure, runtime QA, and sensitive-flow checks, but those were not elevated into explicit gate status.

### Added Steps

- Added PlanCritic sections A-I to the corrected plan.
- Added a persisted critique artifact requirement and path.
- Added Gate 0: Test Infrastructure Gate.
- Added explicit Data / Contracts, Security / RLS, Backend / Supabase, UI / Integration, and Release / QA gate statuses.
- Added critical gaps with owner and acceptance checks.
- Added non-negotiable invariants with enforcement and verification methods.
- Added risk register and pre-mortem.
- Added concrete plan fixes with output artifacts and stop conditions.
- Added acceptance criteria requiring the critique artifact.

### Removed Steps

- Removed executor discretion for `Responses`/`Requests` versus `Received`/`Sent`.
- Removed any implicit permission to introduce active withdrawal behavior during a visual wallet pass.
- Removed any implication that exact pixel parity can be claimed from missing Open Design surfaces.

### Reordered Steps

- PlanCritic source-of-truth gate now appears before the execution phases.
- Gate decisions now happen before Phase 0 evidence lock.
- Test infrastructure is now an explicit pre-edit gate rather than only a QA appendix.
- Runtime visual QA remains after implementation, but it is now a release blocker instead of a documentation nicety.

### Expanded Steps

- Phase 6 copy decision was expanded with design-source evidence and acceptance criteria.
- Phase 8 wallet behavior was expanded with product/backend/security stop rules.
- Missing exact design evidence was expanded into evidence-type authority requirements.
- Sensitive-flow review was expanded into a final blocking release gate.
- Acceptance criteria now explicitly require the persisted critique artifact and no-fake-progress runtime evidence.

### Why

The draft had enough implementation detail to guide work, but not enough PlanCritic structure to safely serve as the gate. The rewrite makes the highest-risk decisions explicit before execution begins and prevents visual work from hiding product, backend, security, or payment changes.

### Residual Risks

- Open Design still lacks exact phone artboards for several Phase 5-8 surfaces; these remain adaptation-only unless new screenshots arrive.
- Runtime Flutter visual QA is still future work and must not be inferred from Open Design screenshots.
- Wallet withdrawal implementation exists below the UI layer, but this visual plan must not activate or reshape it without a separate product/security gate.
- Payment/WebView tests can still be brittle; the Gate 0 harness matrix must be created before new widget tests are added.
- Large files such as `chat_screen.dart`, `messages_screen.dart`, `payment_checkout_screen.dart`, and `work_item_details_screen.dart` can create review risk; implementation should split commits or ownership by phase.

## J) Execution Status - 2026-05-12

- Status: implemented and verified for the current scoped Phase 5-8 Flutter pass.
- Open Design MCP re-check: project `1674a1db-7a74-4c80-8e2c-196a0385a8f7` still resolves to `Sline V2 Amber Dusk.html`, `updatedAt` remains `1778418973981`, and no newer files were returned after that timestamp.
- Messaging decision preserved: `Received` and `Sent` remain the implemented copy based on current Open Design phone, web, and design-system evidence.
- Wallet behavior guard preserved: wallet/dashboard visuals remain summary-only; no withdrawal route, request form, service call, or ledger-affecting UI path was added.
- Execution caveat: worker agents did not return final reports; their workspace edits were found after closure and were treated as untrusted integration patches before verification.
- Verification completed:
  - `flutter analyze --no-fatal-infos` passed.
  - Focused touched-surface widget tests passed.
  - Full `flutter test` passed with final counter `+1525 ~30`.
  - Post-cleanup booking focused tests passed with final counter `+51`.
  - `git diff --check` passed.

## K) Step 5 Gap Scan Status - 2026-05-12

- Status: Step 5 gap scan complete after read-only explorer review and main-agent repair.
- Open Design and Computer Use reference check:
  - Computer Use confirmed Open Design is active on project `1674a1db-7a74-4c80-8e2c-196a0385a8f7`, file `Sline V2 Amber Dusk.html`.
  - Open Design MCP `get_artifact` re-confirmed solid Amber Dusk surfaces, raised amber panels, compact list density, 22-24 px card radii, Received/Sent message modes, grouped profile settings, and wallet/booking visual direction.
- Plan gaps fixed:
  - `BookingCard` now routes task image paths through task-image rendering instead of avatar storage.
  - Chat attachment signed URL resolution moved out of the widget and into the ViewModel/service layer.
  - Attachment upload service construction is lazy, keeping ViewModel unit tests free of global Supabase initialization.
  - Messages use `Received` and `Sent` with latest-message direction filtering.
  - Dashboard Inbox `Sent` remains present but disabled until a sent-offer data contract exists.
  - Wallet quick actions now communicate soon/disabled state instead of appearing active.
  - Sensitive UI logs in auth, payment, payment return, WebView, and award-dialog paths were sanitized.
  - Signup validation now matches the visible 8-character requirement.
  - Proposal payment wrapper tests now use the same app theme extension as the shared tender payment screen.
- Visual authority preserved:
  - Exact parity is not claimed for missing phone-artboard surfaces: auth gates, attachment tile, notification modal, proposal detail, payment return, and WebView.
  - Profile/account settings received token cleanup only; full grouped settings editor parity remains larger than this Step 5 repair.
  - Runtime Flutter screenshot comparison remains pending for later workflow steps.
- Verification after Step 5 repair:
  - `flutter analyze --no-fatal-infos` passed.
  - `flutter test` passed with final counter `+1525 ~30`.
  - `git diff --check` passed.
  - View-scope direct Supabase/storage diff scan had no hits.
  - Backend diff gate for `supabase/migrations`, `supabase/functions`, and `supabase/tests` had no changed files.
