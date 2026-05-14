# PlanCritic Corrected Plan: OpenDesign Amber Dusk Phone Phases 2, 3, And 4

**Source Plan:** `.TODO/PLAN_OpenDesign_AmberDusk_Phone_2026-05-10.md`  
**PlanCritic Artifact:** `.TODO/PLAN_CRITIQUE_2026-05-11_OpenDesign_AmberDusk_Phases2_3_4_PhoneShellDiscoveryDashboard.md`  
**Date:** 2026-05-11  
**Planner:** @Planner  
**Critic:** @PlanCritic  
**Execution Status:** PLANCRITIC CORRECTED; NOT STARTED  
**Scope:** Phone Phase 2 shell/create-post, Phase 3 discovery/search/categories/saved/favorites, and Phase 4 dashboard/tabs/dashboard sub-UI.

---

## A. PlanCritic Assumptions And Resolved Decisions

### A.1 Assumptions

- [ ] (@PlanCritic) This is a visual/view-layer redesign plan only.
- [ ] (@PlanCritic) Open Design MCP project `1674a1db-7a74-4c80-8e2c-196a0385a8f7` remains the current Amber Dusk design source.
- [ ] (@PlanCritic) Phase 0 staged tokens and Phase 1 shared-widget adapter work are available, but Phase 1 runtime emulator visual QA remains open.
- [ ] (@PlanCritic) Feature ViewModels, services, repositories, Provider registration, Supabase schema, RLS, RPCs, storage policies, and payment lifecycle code are not implementation targets.
- [ ] (@PlanCritic) Missing phone designs for Search results, Categories, Saved, and Favorites must not be invented.
- [ ] (@PlanCritic) Dashboard-launched detail/payment/work screens are not part of Phase 4 implementation unless a dashboard widget embeds their UI directly.

### A.2 Resolved Decisions

- [ ] (@PlanCritic) Decision: Missing Open Design or user screenshots for Search/Categories/Saved/Favorites means token-normalization only, not pixel matching.
- [ ] (@PlanCritic) Decision: Dashboard-launched work, booking, and payment detail screens are inventory-and-smoke only in this plan, not redesign targets.
- [ ] (@PlanCritic) Decision: Phase 1 manual emulator QA remains a release/visual-closure gate, not a reason to mutate shared widgets again during Phase 2-4 unless a concrete defect is found.
- [ ] (@PlanCritic) Decision: Do not globally flip `AppTheme` to Amber Dusk. Consume the existing Amber Dusk adapter/tokens only in the scoped widgets and screens.
- [ ] (@PlanCritic) Decision: Do not bundle Open Design font assets in Phase 2-4 because license/source evidence is still absent.
- [ ] (@PlanCritic) Decision: No screenshot pack counts as runtime QA unless it has route identity sanity and Flutter runtime capture notes.

### A.3 Blocking Decisions

No blocking product decisions remain for planning. Implementation is blocked only at the per-section gate when Open Design MCP evidence, user screenshot evidence, or runtime baseline evidence is missing for a section that needs exact matching.

---

## B. Gate Status After PlanCritic Rewrite

| Gate | Draft Status | Corrected Status | Reason | Required Execution Behavior |
|---|---|---|---|---|
| Gate 0: Test Infrastructure Gate | PARTIAL | PASS AFTER CORRECTION | Draft named tests but did not force deterministic fixtures, provider classification, and static cleanup before feature tests. | Build fixture/state matrices before tests, classify Provider types, configure auto-loading mocks before pump, and use `RoleSwitchCoordinator.clearForTesting()` where relevant. |
| Data / Contracts Gate | PASS | PASS | No model, DTO, ViewModel, repository, or service contract change is planned. | Stop and create a separate contract plan if a UI gap requires new data. |
| Security / RLS Gate | PASS | PASS | No security boundary, RLS, storage, or lifecycle enforcement change is planned. | Fail if a View adds direct Supabase, UI-only lifecycle enforcement, or sensitive data leakage. |
| Backend / Supabase Gate | PASS | PASS | Supabase is explicitly out of scope. | Any schema/RLS/RPC/storage need requires a separate `Skill: supabase-migration` plan. |
| UI / Integration Gate | PARTIAL | PASS AFTER CORRECTION | Draft had good UI decomposition but needed stricter evidence authority and release distinction. | Every section starts with MCP refresh and evidence classification; missing screenshots limit scope to token-normalization. |
| Release / QA Gate | PARTIAL | PASS AFTER CORRECTION; VISUAL CLOSURE STILL GATED | Draft listed QA but did not explicitly inherit Phase 1's open emulator evidence gate. | Do not claim final visual completion until runtime emulator screenshots/notes exist for the changed screens and Phase 1 shared-widget checklist caveat is honored. |

---

## C. Critical Corrections Applied By PlanCritic

### C.1 Evidence Authority Was Under-Specified

- [ ] (@PlanCritic) Correction: The plan now separates Open Design MCP reference evidence, user-provided new-design screenshots, old/current Flutter runtime baselines, and final runtime QA screenshots.
- [ ] (@Sentinel) Acceptance check: Session log must name the evidence type for every screenshot or note.

### C.2 Missing Screens Could Be Over-Implemented

- [ ] (@PlanCritic) Correction: Search results, Categories, Saved, and Favorites are token-normalization surfaces unless Open Design MCP or user screenshots provide exact phone screens.
- [ ] (@Sentinel) Acceptance check: No exact-match claim for these screens without a screenshot or MCP artifact path.

### C.3 Dashboard Scope Could Expand Into Payment/Work Detail Redesign

- [ ] (@PlanCritic) Correction: Dashboard-launched detail/payment/work screens are inventory-and-smoke only in Phase 4.
- [ ] (@Architect) Acceptance check: No edits to launched detail/payment/work screens unless a dashboard widget directly embeds them and the handoff is recorded.

### C.4 Test Infrastructure Was Not Strong Enough

- [ ] (@PlanCritic) Correction: Gate 0 now requires fixture/state matrices, Provider-type classification, singleton cleanup, auto-loading mock setup, and bounded pump strategy before feature tests.
- [ ] (@Sentinel) Acceptance check: The session log includes a fixture/provider matrix before any new Phase 2-4 widget tests are written.

### C.5 Phase 1 Runtime QA Risk Was Not Prominent Enough

- [ ] (@PlanCritic) Correction: Phase 1 shared-widget code gates passed, but runtime visual QA is still open and must be treated as a release gate.
- [ ] (@Sentinel) Acceptance check: Phase 2-4 final report must say whether Phase 1 emulator checklist was executed, superseded by new runtime screenshots, or remains open.

### C.6 Worker Ownership Needed A Stop Rule

- [ ] (@PlanCritic) Correction: File ownership is not just a planning table; it is a stop rule. If two workers need the same file, the main executor must pause and reassign ownership.
- [ ] (@Architect) Acceptance check: Session log records any ownership handoff before the second worker edits that file.

---

## D. Evidence Classification Matrix

| Evidence Type | Examples | May Drive Pixel-Level Matching? | Required Record |
|---|---|---:|---|
| Open Design MCP reference | `Sline V2 Amber Dusk.html`, `amber-dusk-design-system.html`, direct MCP screenshot/artifact pull | Yes, for visible authored states only | Project id, file name, artboard/state, timestamp or captured path |
| User-provided new-design screenshot | Screenshot supplied in chat or placed in repo for this phase | Yes, for visible area only | Absolute path or attachment label, screen/state, visible decisions |
| Open Design provisional screenshot pack | Phase 1 width screenshots with duplicate hash caveat | No, reference only | Path plus caveat that it is not runtime Flutter QA |
| Old/current Flutter runtime baseline | Emulator screenshot before edits | No, baseline only | Device/profile, logical size, text scale, route/state |
| Final Flutter runtime QA | Emulator/device screenshot after implementation | Yes, for runtime completion | Device/profile, logical size, text scale, route/state, pass/fail notes |
| Written manual QA note | Manual observation where screenshot is unavailable | No pixel matching; behavior/accessibility only | Exact route/state, device profile, pass/fail, limitation |

---

## E. Non-Negotiable Invariants

- [ ] (@Architect) No View imports or calls Supabase directly.
- [ ] (@Architect) No ViewModel/service/repository/backend behavior changes for visual-only work.
- [ ] (@Supabase_Ops | Skill: supabase-migration) No schema, RLS, RPC, trigger, storage policy, Edge Function, or SQL test changes in this plan.
- [ ] (@Architect) Payment, booking, tender, direct-offer, work, wallet, dispute, and role-switch lifecycle rules remain server/DB/service governed.
- [ ] (@Pixel | Skill: normalize) Reusable visual values live in theme/tokens/adapters, not feature views.
- [ ] (@Pixel | Skill: normalize) No new `BackdropFilter`, `ImageFilter.blur`, frosted-glass implementation, or `glass_*` resurrection.
- [ ] (@Pixel | Skill: harden) Text must not overflow or overlap at 360 px and text scale 1.3 for changed surfaces.
- [ ] (@Observability) New code paths use `AppLogger`; no `print()` or `debugPrint()`.
- [ ] (@Sentinel) Tests must cover every new unit/widget and every new branch introduced by the implementation.
- [ ] (@DocsKeeper) Docs/handoff must report verified reality, not planned intent.

---

## F. Corrected Execution Order

- [ ] (@Architect) Step 1: Evidence and worktree lock.
- [ ] (@Sentinel) Step 2: Test infrastructure lock and fixture/state matrix.
- [ ] (@Pixel | Skill: frontend-design) Step 3: Phase 2 Open Design refresh and screenshot decision.
- [ ] (@Pixel | Skill: arrange) Step 4: Phase 2 implementation and focused tests.
- [ ] (@Pixel | Skill: frontend-design) Step 5: Phase 3 Open Design refresh and screenshot decision.
- [ ] (@Pixel | Skill: arrange) Step 6: Phase 3 Home/feed/cards implementation and focused tests.
- [ ] (@Pixel | Skill: polish) Step 7: Phase 3 Search/Categories/Saved/Favorites token-normalization or screenshot-driven implementation and focused tests.
- [ ] (@Pixel | Skill: frontend-design) Step 8: Phase 4 Open Design refresh and screenshot decision.
- [ ] (@Pixel | Skill: arrange) Step 9: Phase 4 Dashboard shell/tabs/cards/wallet implementation and focused tests.
- [ ] (@Sentinel) Step 10: Cross-phase static, focused, coverage, emulator, and behavior QA.
- [ ] (@DocsKeeper) Step 11: Docs, web handoff, master report, and final checklist after verification only.

---

## 0. Planning Rules Locked For This Phase

- [ ] (@Architect) Treat this file as the execution source of truth after PlanCritic approval.
- [ ] (@Architect) Keep `.TODO/PLAN_OpenDesign_AmberDusk_Phone_2026-05-10.md` as the master roadmap only; do not overwrite it.
- [ ] (@Pixel | Skill: normalize) Implement only from Open Design MCP evidence, user-provided screenshots, and existing Amber Dusk tokens.
- [ ] (@Pixel | Skill: normalize) Do not improvise new visual systems outside the staged Amber Dusk design system.
- [ ] (@Pixel | Skill: harden) Use screenshots only when the user has provided them or they are pulled directly from Open Design MCP.
- [ ] (@Architect) Preserve MVVM boundaries. Views may consume ViewModels and services already wired through Provider, but must not add direct Supabase reads.
- [ ] (@Supabase_Ops | Skill: supabase-migration) Do not modify Supabase schema, RLS, RPC, Edge Functions, storage policies, or migrations in this plan.
- [ ] (@Observability) Add `AppLogger` instrumentation to every new user-facing code path, state transition, and failure path introduced during execution.
- [ ] (@Sentinel) Do not mark a visual section complete until emulator/device screenshots prove the runtime Flutter UI, not only the Open Design artifact.
- [ ] (@DocsKeeper) Keep planning, implementation notes, test results, visual QA, and handoff docs connected.

---

## 1. Goal

Complete the next phone Amber Dusk implementation block from the master plan:

- Phase 2: Phone shell, bottom navigation, Home-owned create action, and create-post flow.
- Phase 3: Phone Home discovery, search, categories, saved, favorites, feed filters, and card hierarchy.
- Phase 4: Phone dashboard shell, dashboard tabs, overview, bookings, work, wallet, inbox, cards, status surfaces, and dashboard-local sub-UI.

The result should be a phone-first Amber Dusk UI layer that preserves existing data and navigation contracts and gives Mohammed a stable web adaptation reference later.

---

## 2. In Scope

- [ ] (@Pixel | Skill: arrange) Update phone shell and navigation layout only where needed for the Phase 2 visual target.
- [ ] (@Pixel | Skill: normalize) Update `CustomBottomNavBar` only within its existing four-destination contract: Home, Dashboard, Messages, Profile.
- [ ] (@Pixel | Skill: clarify) Update `CreateTaskScreen` copy, grouping, step presentation, Tender/Booking selection, validation display, review display, and publish/failure surfaces without changing task business logic.
- [ ] (@Pixel | Skill: arrange) Update Home header, search row, feed chips, discovery sliver, filters, Tender/Booking/Task card hierarchy, and card responsive behavior.
- [ ] (@Pixel | Skill: polish) Update Categories, Search, Favorites, and Saved screens only to the evidence-backed Amber Dusk token-normalized level unless screenshots prove a more exact target.
- [ ] (@Pixel | Skill: arrange) Update Dashboard shell, tab strip, overview, bookings, work, wallet, inbox, counters, activity feed, next actions, work cards, booking cards, offer cards, wallet cards, status badges, loading, empty, and error states.
- [ ] (@Sentinel) Add or update focused widget tests for each changed widget/screen.
- [ ] (@DocsKeeper) Update docs and session logs after implementation and verification.

---

## 3. Out Of Scope

- [ ] (@Architect) Do not redesign Profile, Messages, Auth, account gates, task details, booking details, payment checkout, payment method, payment return, payment webview, work item details, or launched work/payment detail screens unless a Phase 2-4 target directly renders a visible widget from those files.
- [ ] (@Architect) Do not add a Tender or Booking item to the bottom nav.
- [ ] (@Architect) Do not change `NavigationProvider`, `MainNavDestinations`, `TaskViewModel`, `DashboardViewModel`, Home/Search/Categories/Favorites/Saved ViewModels, repositories, services, or Supabase contracts unless a documented UI contract gap blocks the plan.
- [ ] (@Supabase_Ops | Skill: supabase-migration) Do not create schema, migration, RLS, RPC, trigger, storage, or Edge Function changes.
- [ ] (@Pixel | Skill: normalize) Do not bundle fonts or add assets from Open Design unless license/source evidence is documented.
- [ ] (@Pixel | Skill: normalize) Do not port CSS `backdrop-filter`, glass blur, or web-only rendering tricks into Flutter without an explicit design-system token and performance justification.
- [ ] (@DocsKeeper) Do not archive the master phone plan, web plan, or future work files as part of this implementation.

---

## 4. Evidence And Findings From Scan

### 4.1 Existing

- [ ] (@Planner) Master plan sections exist for Phase 2, Phase 3, and Phase 4 in `.TODO/PLAN_OpenDesign_AmberDusk_Phone_2026-05-10.md`.
- [ ] (@Planner) Open Design MCP project is `1674a1db-7a74-4c80-8e2c-196a0385a8f7`, entry file `Sline V2 Amber Dusk.html`, with companion design artifact `amber-dusk-design-system.html`.
- [ ] (@Planner) Open Design phone artboard evidence is fixed around `402 x 874`.
- [ ] (@Planner) Open Design evidence confirms a dark near-black/brown shell, cream primary text, muted secondary text, amber primary accent, rust/forest/star accents, 24/22/18 radius tiers, and three shadow tiers.
- [ ] (@Planner) Open Design evidence confirms bottom navigation has four destinations only: Home, Dashboard, Messages, Profile.
- [ ] (@Planner) Open Design evidence confirms Home owns the amber floating create action.
- [ ] (@Planner) Open Design evidence confirms the create flow as a three-step bottom sheet style flow: choose Tender/Booking, fill details, review live card preview, publish into the matching Home feed.
- [ ] (@Planner) Open Design evidence confirms Home uses a unified mixed feed with search and chips for All, Bookings, and Tasks.
- [ ] (@Planner) Open Design evidence confirms Dashboard tabs: Overview, Bookings, Work, Wallet, Inbox.
- [ ] (@Planner) Open Design evidence confirms Work tab buckets: Active, Done, Cancelled.
- [ ] (@Planner) Open Design evidence confirms dashboard work cards use dark raised panels, avatar/code marks, source line, right-aligned money, and one progress row.
- [ ] (@Planner) Phase 0 already staged Amber Dusk tokens under `lib/core/theme/designs/amber_dusk/`.
- [ ] (@Planner) Phase 1 shared widget work exists, but manual emulator visual QA remains open and must not be treated as visually complete.

### 4.2 Missing

- [ ] (@Planner) Open Design evidence for full Categories phone screens is weak. The executor must request or pull screenshots before exact matching.
- [ ] (@Planner) Open Design evidence for full Saved phone screens is weak. The executor must request or pull screenshots before exact matching.
- [ ] (@Planner) Open Design evidence for full Favorites phone screens is weak. The executor must request or pull screenshots before exact matching.
- [ ] (@Planner) Open Design evidence for full Search results phone screens is limited to search bars/placeholders. The executor must request or pull screenshots before exact matching.
- [ ] (@Planner) Open Design evidence for Dashboard detail/payment/work launched screens is not strong enough to redesign them inside Phase 4.
- [ ] (@Planner) Runtime Flutter visual proof for Phase 1 shared widgets is still open.

### 4.3 Must Not Duplicate

- [ ] (@Architect) Do not recreate Amber Dusk colors, spacing, typography, motion, card recipes, bottom nav recipes, or phone layout values in feature widgets.
- [ ] (@Architect) Reuse `AmberDuskTokens`, `AmberDuskWidgetTheme`, `AmberDuskPhoneLayout`, `AppTheme`, `AppDimens`, `AppLayout`, `AppMotion`, `AppDecorations`, `AppTypography`, `AppStates`, and existing core widgets.
- [ ] (@Architect) Reuse current Provider and screen seams: `MainNavigationScreen.screens`, `MainNavigationScreen.createTaskScreenBuilder`, `HomeScreen.autoLoadOnInit`, `HomeScreen.taskDetailsScreenBuilder`, and `DashboardScreen.tabViews`.
- [ ] (@Sentinel) Reuse existing test helpers and provider harnesses instead of creating duplicate test infrastructure.

### 4.4 Mismatches

- [ ] (@Planner) Master plan says `NavView`, but current visible nav implementation uses `MainNavDestinations`; `NavView` is legacy context and must not drive execution.
- [ ] (@Planner) Master plan says "Create post"; current implementation is `CreateTaskScreen` with `TaskType.tender` and `TaskType.booking`.
- [ ] (@Planner) Master plan says "Tender Post" and "Booking Post"; current implementation has type cards and local step state, not standalone files.
- [ ] (@Planner) Master plan says "wallet cards"; current files are `wallet_shared_body.dart`, `wallet_hero_card.dart`, `wallet_snapshot_card.dart`, and `wallet_timeline_card.dart`.
- [ ] (@Planner) Master plan says preserve `HomeViewModel`; current Home screen also consumes `DiscoveryFeedViewModelContract`, `TaskFilterViewModel`, `ProfileViewModel`, and `SavedTasksViewModel`.

### 4.5 Risks And Constraints

- [ ] (@CodeGuard) Several target files still contain teal-era direct references or comments and need careful migration to Amber Dusk tokens.
- [ ] (@CodeGuard) Some local animation/duration/font-size values remain; migrate only semantic values and document intentional exceptions.
- [ ] (@CodeGuard) Phase 4 can expand into payment and work lifecycle screens. Keep execution scoped to dashboard-rendered views/widgets and document future work.
- [ ] (@CodeGuard) Dashboard sub-UI is state-heavy: accepted-unpaid, active, delivered, completed, disputed, no-show, canceled, empty, loading, error, and role-sensitive variants require tests and manual QA.
- [ ] (@Sentinel) Coverage baseline from local LCOV was 11,308 hit lines out of 24,162 found lines, or 46.80 percent. Do not lower below the CI floor.
- [ ] (@Supabase_Ops | Skill: supabase-migration) Local scan of target view files found no direct `Supabase.instance`, `.from`, or `.rpc` calls. Preserve this boundary.

---

## 5. Path Validation

### 5.1 Phase 2 Files

- [ ] (@Pixel | Skill: arrange) `lib/app/main_navigation_screen.dart` - shell, screen switching, Home-owned FAB, runtime banner, scroll-aware FAB.
- [ ] (@Pixel | Skill: normalize) `lib/core/widgets/custom_bottom_nav_bar.dart` - compact four-item nav surface and active capsule.
- [ ] (@Pixel | Skill: clarify) `lib/features/tasks/view/create_task_screen.dart` - current create-post implementation.
- [ ] (@Pixel | Skill: normalize) `lib/features/tasks/view/widgets/task_concept_section.dart` - create flow concept section if still rendered by `CreateTaskScreen`.
- [ ] (@Pixel | Skill: normalize) `lib/features/tasks/view/widgets/booking_logistics_section.dart` - create flow booking details if still rendered by `CreateTaskScreen`.

### 5.2 Phase 3 Files

- [ ] (@Pixel | Skill: arrange) `lib/features/home/view/home_screen.dart`.
- [ ] (@Pixel | Skill: arrange) `lib/features/tasks/view/widgets/discovery_task_sliver.dart`.
- [ ] (@Pixel | Skill: normalize) `lib/features/home/view/widgets/filters_modal.dart`.
- [ ] (@Pixel | Skill: normalize) `lib/features/tasks/view/widgets/task_card.dart`.
- [ ] (@Pixel | Skill: normalize) `lib/features/tasks/view/widgets/tender_task_card.dart`.
- [ ] (@Pixel | Skill: normalize) `lib/features/tasks/view/widgets/booking_task_card.dart`.
- [ ] (@Pixel | Skill: normalize) `lib/features/booking/view/widgets/booking_card.dart`.
- [ ] (@Pixel | Skill: polish) `lib/features/categories/view/categories_screen.dart`.
- [ ] (@Pixel | Skill: polish) `lib/features/search/view/search_screen.dart`.
- [ ] (@Pixel | Skill: polish) `lib/features/search/view/widgets/search_result_profile_card.dart`.
- [ ] (@Pixel | Skill: polish) `lib/features/favorites/view/favorites_screen.dart`.
- [ ] (@Pixel | Skill: polish) `lib/features/favorites/view/widgets/favorite_card.dart`.
- [ ] (@Pixel | Skill: polish) `lib/features/saved/view/saved_tasks_screen.dart`.
- [ ] (@Pixel | Skill: polish) `lib/features/saved/view/widgets/saved_task_tile.dart`.

### 5.3 Phase 4 Files

- [ ] (@Pixel | Skill: arrange) `lib/features/dashboard/view/dashboard_screen.dart`.
- [ ] (@Pixel | Skill: normalize) `lib/features/dashboard/view/tabs/overview_tab.dart`.
- [ ] (@Pixel | Skill: normalize) `lib/features/dashboard/view/tabs/bookings_tab.dart`.
- [ ] (@Pixel | Skill: normalize) `lib/features/dashboard/view/tabs/work_tab.dart`.
- [ ] (@Pixel | Skill: normalize) `lib/features/dashboard/view/tabs/wallet_tab.dart`.
- [ ] (@Pixel | Skill: normalize) `lib/features/dashboard/view/tabs/inbox_tab.dart`.
- [ ] (@Pixel | Skill: polish) `lib/features/dashboard/view/widgets/dashboard_counters_grid.dart`.
- [ ] (@Pixel | Skill: polish) `lib/features/dashboard/view/widgets/activity_feed_preview.dart`.
- [ ] (@Pixel | Skill: polish) `lib/features/dashboard/view/widgets/next_actions_list.dart`.
- [ ] (@Pixel | Skill: polish) `lib/features/dashboard/view/widgets/work_item_card.dart`.
- [ ] (@Pixel | Skill: colorize) `lib/features/booking/view/widgets/dashboard_booking_card.dart`.
- [ ] (@Pixel | Skill: colorize) `lib/features/tasks/view/widgets/dashboard_offer_card.dart`.
- [ ] (@Pixel | Skill: colorize) `lib/features/wallet/view/widgets/wallet_shared_body.dart`.
- [ ] (@Pixel | Skill: colorize) `lib/features/wallet/view/widgets/wallet_hero_card.dart`.
- [ ] (@Pixel | Skill: colorize) `lib/features/wallet/view/widgets/wallet_snapshot_card.dart`.
- [ ] (@Pixel | Skill: colorize) `lib/features/wallet/view/widgets/wallet_timeline_card.dart`.
- [ ] (@Pixel | Skill: colorize) `lib/features/wallet/view/wallet_screen.dart`.
- [ ] (@Pixel | Skill: colorize) `lib/features/wallet/view/wallet_dashboard_screen.dart`.

### 5.4 Read-Only Guard Files

- [ ] (@Architect) `lib/core/providers/navigation_provider.dart` - read only unless a documented test seam gap blocks execution.
- [ ] (@Architect) `lib/core/navigation/main_nav_destinations.dart` - read only unless a documented nav contract gap blocks execution.
- [ ] (@Architect) `lib/features/tasks/viewmodels/task_view_model.dart` - read only unless a documented UI contract gap blocks execution.
- [ ] (@Architect) `lib/features/home/viewmodels/home_view_model.dart` - read only unless a documented UI contract gap blocks execution.
- [ ] (@Architect) `lib/features/tasks/viewmodels/discovery_feed_view_model_contract.dart` - read only unless a documented UI contract gap blocks execution.
- [ ] (@Architect) `lib/features/tasks/viewmodels/task_filter_view_model.dart` - read only unless a documented UI contract gap blocks execution.
- [ ] (@Architect) `lib/features/categories/viewmodels/categories_view_model.dart` - read only unless a documented UI contract gap blocks execution.
- [ ] (@Architect) `lib/features/search/viewmodels/search_view_model.dart` - read only unless a documented UI contract gap blocks execution.
- [ ] (@Architect) `lib/features/favorites/viewmodels/favorites_view_model.dart` - read only unless a documented UI contract gap blocks execution.
- [ ] (@Architect) `lib/features/saved/viewmodels/saved_tasks_view_model.dart` - read only unless a documented UI contract gap blocks execution.
- [ ] (@Architect) `lib/features/**/services/**`, `lib/features/**/data/**`, `lib/core/services/**`, and `supabase/**` - no writes in this plan.

---

## 6. Screenshot And Design Evidence Required Before Implementation

### 6.1 Pull From Open Design MCP First

- [x] (@Pixel | Skill: frontend-design) Pull Open Design MCP screenshot/evidence for the phone artboard before Phase 2 implementation.
- [x] (@Pixel | Skill: frontend-design) Pull Open Design MCP screenshot/evidence for Home All, Home Bookings, and Home Tasks before Phase 3 implementation.
- [x] (@Pixel | Skill: frontend-design) Pull Open Design MCP screenshot/evidence for Dashboard Overview, Bookings, Work, Wallet, and Inbox before Phase 4 implementation.
- [x] (@Pixel | Skill: frontend-design) Record exact Open Design file names, node/artboard labels, and screenshot paths in the session log.

### 6.2 Ask User For Missing New-Design Screenshots

- [ ] (@Pixel | Skill: critique) Ask the user for new-design screenshots for Categories if Open Design MCP does not expose a full phone target.
- [ ] (@Pixel | Skill: critique) Ask the user for new-design screenshots for Saved if Open Design MCP does not expose a full phone target.
- [ ] (@Pixel | Skill: critique) Ask the user for new-design screenshots for Favorites if Open Design MCP does not expose a full phone target.
- [ ] (@Pixel | Skill: critique) Ask the user for new-design screenshots for Search results if Open Design MCP does not expose a full phone target.
- [ ] (@Pixel | Skill: critique) Ask the user for new-design screenshots for create flow review/failure states if Open Design MCP only shows the happy path.
- [ ] (@Pixel | Skill: critique) Ask the user for new-design screenshots for dashboard empty/error/loading states if Open Design MCP only shows populated states.

### 6.3 Runtime Baseline Screenshots To Request Or Capture

- [ ] (@Sentinel) Capture old/current Flutter runtime Home All at 390 px and 402 px before changing Home.
- [ ] (@Sentinel) Capture old/current Flutter runtime Home Bookings at 390 px and 402 px before changing Home.
- [ ] (@Sentinel) Capture old/current Flutter runtime Home Tasks/Tenders at 390 px and 402 px before changing Home.
- [ ] (@Sentinel) Capture old/current Flutter runtime create type selection, details, review, validation failure, and publish failure states before changing `CreateTaskScreen`.
- [ ] (@Sentinel) Capture old/current Flutter runtime Dashboard Overview, Bookings, Work Active, Work Done, Work Cancelled, Wallet, and Inbox before changing Dashboard.
- [ ] (@Sentinel) Capture old/current Flutter runtime Search, Categories, Saved, and Favorites if those screens receive token-normalization changes.

### 6.4 Screenshot Decision Rule

- [ ] (@Pixel | Skill: harden) If no new-design screenshot exists for a surface, implement only token alignment, spacing cleanup, accessibility hardening, and known shared component usage.
- [ ] (@Pixel | Skill: harden) If a new-design screenshot exists, implement against that screenshot and attach before/after runtime screenshots to the session log.
- [ ] (@Sentinel) Do not claim pixel parity for a surface that lacks both Open Design MCP evidence and runtime after screenshots.

### 6.5 Exported Open Design MCP Screenshot Pack And Visual Notes

Open Design MCP was re-checked on 2026-05-11 immediately before these notes were written.

- Project: `1674a1db-7a74-4c80-8e2c-196a0385a8f7` (`Sline V2 Amber Dusk.html`).
- Entry file: `Sline V2 Amber Dusk.html`.
- Design system file present in project: `amber-dusk-design-system.html`.
- Current render source used for screenshots: `/Users/eros/Library/Application Support/Open Design/namespaces/release-stable/data/projects/1674a1db-7a74-4c80-8e2c-196a0385a8f7/Sline V2 Amber Dusk.html`.
- Export directory: `.TODO/OpenDesign_AmberDusk_Phases2_3_4_OpenDesignScreenshots_2026-05-11/`.
- Screenshot pack index and SHA-256 hashes: `.TODO/OpenDesign_AmberDusk_Phases2_3_4_OpenDesignScreenshots_2026-05-11/README.md`.
- Screenshot dimensions: `430x930` PNG exports.

#### 6.5.1 Exported Screenshot Inventory

| Phase | Screenshot | Executor Use |
|---|---|---|
| 2 | `phase2-home-shell-fab-nav.png` | Main phone shell, Home active bottom nav, Amber create FAB, and first-pass shell spacing. |
| 2 | `phase2-dashboard-nav-active.png` | Dashboard active bottom nav state and nav capsule behavior. |
| 2 | `phase2-messages-nav-active.png` | Messages active bottom nav state. |
| 2 | `phase2-profile-nav-active.png` | Profile active bottom nav state. |
| 2 | `phase2-create-type-tender-selected.png` | Create sheet type-selection step with Tender selected. |
| 2 | `phase2-create-type-booking-selected.png` | Create sheet type-selection step with Booking selected. |
| 2 | `phase2-create-tender-details.png` | Tender create details step. |
| 2 | `phase2-create-tender-review.png` | Tender create review step. |
| 2 | `phase2-create-booking-details.png` | Booking create details step. |
| 2 | `phase2-create-booking-review.png` | Booking create review step. |
| 3 | `phase3-home-all-feed.png` | Home All feed; intentionally same visual state as `phase2-home-shell-fab-nav.png`. |
| 3 | `phase3-home-bookings-filter.png` | Home Bookings filter state. |
| 3 | `phase3-home-tasks-filter.png` | Home Tasks filter state. |
| 4 | `phase4-dashboard-overview.png` | Dashboard overview; intentionally same visual state as `phase2-dashboard-nav-active.png`. |
| 4 | `phase4-dashboard-bookings.png` | Dashboard Bookings tab. |
| 4 | `phase4-dashboard-work-active.png` | Dashboard Work tab, Active bucket. |
| 4 | `phase4-dashboard-work-done.png` | Dashboard Work tab, Done bucket. |
| 4 | `phase4-dashboard-work-cancelled.png` | Dashboard Work tab, Cancelled bucket. |
| 4 | `phase4-dashboard-wallet.png` | Dashboard Wallet tab. |
| 4 | `phase4-dashboard-inbox.png` | Dashboard Inbox tab. |

#### 6.5.2 Visual Notes For Implementation

- Phase 2 shell: the phone shell keeps Home/Dashboard/Messages/Profile as the four persistent bottom-nav destinations; Tender and Booking are create-flow choices, not nav destinations.
- Phase 2 nav: the active destination uses a compact rounded capsule with icon-plus-label treatment; inactive destinations remain icon-first and lower contrast.
- Phase 2 create: the amber FAB opens a three-step create sheet flow: type selection, details, and review. The Tender branch is quieter and task-card-like; the Booking branch uses a stronger service/booking card hierarchy.
- Phase 3 Home: the feed uses a segmented All/Bookings/Tasks filter. All is a mixed feed, Bookings emphasizes higher-priority booking cards, and Tasks emphasizes quieter tender/task cards.
- Phase 3 missing surfaces: the current Open Design MCP artifact does not expose full phone screens for Search results, Categories, Saved, or Favorites. These surfaces must stay token-normalization/accessibility-only unless user screenshots or an updated Open Design artifact are supplied.
- Phase 4 Dashboard: the dashboard uses Overview, Bookings, Work, Wallet, and Inbox tabs. Work has Active/Done/Cancelled bucket states. Wallet uses the strongest hero-style balance treatment, while Inbox is compact row-first.
- Phase 4 boundary: dashboard-launched work detail, booking detail, and payment screens are not represented as separate phone screenshots in the current MCP export; keep them to inventory/smoke coverage unless new evidence is added.

#### 6.5.3 Missing From Current MCP Export

Exact visual implementation is blocked for these states until the user supplies screenshots or Open Design is updated:

- Search results screen.
- Categories screen.
- Saved list.
- Favorites list.
- Loading states.
- Empty states.
- Error states.
- Create validation failure, create loading, create success, and create failure states.
- Dashboard role-specific variants beyond the visible prototype.
- Dashboard empty, loading, and error states.
- Dashboard-launched work, booking, and payment detail screens.

#### 6.5.4 Executor Screenshot Rules

- Use the exported MCP screenshots as the new-design reference wherever a screenshot exists in `6.5.1`.
- Use user-provided screenshots only when explicitly supplied after this plan update.
- For missing MCP states in `6.5.3`, implement only token alignment, existing design-system component usage, accessibility hardening, layout cleanup, and tests. Do not claim exact Amber Dusk parity.
- Before marking any phase visually complete, capture Flutter runtime after screenshots and compare them against the matching MCP screenshot paths.

---

## 7. Mocking Strategy Classification

| Screen Or Widget | Type | Mock Targets | Base Class / Provider Notes | Test Pattern |
|---|---|---|---|---|
| `MainNavigationScreen` | Type A with constructor seams | `NavigationProvider`, optional `SystemConfigViewModel`, injected `screens`, injected `createTaskScreenBuilder` | `NavigationProvider` is a Provider-owned state object; verify exact base class before tests | Use production screen with fake tab widgets and injected create screen |
| `CustomBottomNavBar` | Stateless/controlled widget | Tap callbacks and `currentIndex` | No ViewModel dependency | Pump directly with keys and callbacks |
| `CreateTaskScreen` | Type A | `TaskViewModel`, `CategoriesRepository` | `TaskViewModel` likely uses `ChangeNotifierProvider.value`; `CategoriesRepository` is plain `Provider.value` | Configure task/category stubs before pump |
| `HomeScreen` | Type A | `DiscoveryFeedViewModelContract`, `TaskFilterViewModel`, `ProfileViewModel`, `SavedTasksViewModel`, notification dependencies used by header widgets | Verify each VM base class; use `.value` providers | Use `autoLoadOnInit: false` unless testing bootstrap |
| `FiltersModal` | Type A | `TaskFilterViewModel` | Provider-owned state | Pump modal content with fake filter state |
| `DiscoveryTaskSliver` | Controlled widget with callbacks | Task list, callbacks, loading/error flags | No direct ViewModel if props are supplied | Pump in a `CustomScrollView` harness |
| `TaskCard` / `TenderTaskCard` / `BookingTaskCard` / `BookingCard` | Controlled widgets | Model fixtures, callbacks | No service dependency | Pump direct fixtures with long text and large price variants |
| `CategoriesScreen` | Type B risk | `CategoriesViewModel` or services created internally | Verify if VM falls back to `Supabase.instance.client`; prefer lower-level view/widget harness if no seam | Add seam only if needed and documented |
| `SearchScreen` | Type B risk | `SearchViewModel` or service dependencies created internally | Verify constructor before test; prefer content harness if no seam | Add seam only if needed and documented |
| `FavoritesScreen` | Type A | `FavoritesViewModel`, `ChatViewModel` for start-chat path | Use `ChangeNotifierProvider.value` only for ChangeNotifier classes | Test list, empty, error, remove, and start-chat states |
| `SavedTasksScreen` | Type A | `SavedTasksViewModel`, route/details builder if available | Use Provider ancestor and controlled fixtures | Test list, empty, error, unsave, route tap |
| `DashboardScreen` | Type A plus tab seam | `DashboardViewModel`, `DirectOffersService`, `PaymentService`, optional `tabViews` | Preserve web payment recovery behavior; do not expand it | Use `tabViews` seam for shell tests, full providers for integration-like widget tests |
| Dashboard tabs and cards | Mostly Type A/controlled | `DashboardViewModel` data, booking/work/offer fixtures, wallet VM/service dependencies | Verify each widget constructor before test | Pump each tab/card in isolation when possible |
| Wallet cards/body | Type A or controlled, to verify | Wallet ViewModel/service fixtures | Verify constructors before tests | Pump direct card fixtures; avoid payment service changes |

---

## 8. Singleton And Static State Cleanup

- [ ] (@Sentinel) Before writing tests, scan target files for `RoleSwitchCoordinator`, `register`, `static final`, `factory`, `SharedPreferences`, and any static caches.
- [ ] (@Sentinel) Use `RoleSwitchCoordinator.clearForTesting()` in `tearDown` for dashboard/home/task VM tests if those VMs register during the test.
- [ ] (@Sentinel) Clear or isolate route/navigation observers, fake logger sinks, fake timers, and any seeded static fixtures introduced by tests.
- [ ] (@Sentinel) If a singleton lacks a test reset and blocks reliable tests, add a minimal reset method in a separate infrastructure sub-phase and document why.

---

## 9. Implementation Ownership Map

No worker may edit the same file as another worker unless the main executor explicitly coordinates and records the handoff in the session log.

| Worker | Write Scope | Notes |
|---|---|---|
| Worker 1 | Phase 2 shell/create files only | `main_navigation_screen.dart`, `custom_bottom_nav_bar.dart`, `create_task_screen.dart`, create flow helper widgets, and their tests |
| Worker 2 | Phase 3 Home/feed/card files only | `home_screen.dart`, `discovery_task_sliver.dart`, `filters_modal.dart`, task/booking card files, and their tests |
| Worker 3 | Phase 3 secondary discovery screens only | categories/search/favorites/saved screens/widgets and their tests |
| Worker 4 | Phase 4 dashboard shell/tabs/widgets only | dashboard screen, tabs, dashboard cards, wallet cards, and their tests |
| Worker 5 | Verification/docs only after code freeze | test checklist, session log, docs sync, master report, visual QA references |

---

## 10. Phase 0: Execution Preflight And Evidence Lock

**Primary Agents:** @Architect + @Pixel + @Sentinel

### 10.1 Source Lock

- [ ] (@Architect) Read this plan and the master phone plan before editing.
- [ ] (@Architect) Confirm the working branch and current `git status --short --untracked-files=all`.
- [ ] (@Architect) Record unrelated dirty files and ignore them unless they directly affect Phase 2-4.
- [ ] (@DocsKeeper) Initialize or update the session log from `docs/LOG/SESSION_PLAN_OpenDesign_AmberDusk_Phases2_3_4_PhoneShellDiscoveryDashboard_2026-05-11.md`.
- [ ] (@Sentinel) Confirm Phase 1 shared-widget visual QA status before relying on shared widgets as visually complete.

### 10.2 Open Design MCP Lock

- [ ] (@Pixel | Skill: frontend-design) Re-check Open Design MCP and record current project/file/artboard names before Phase 2.
- [ ] (@Pixel | Skill: frontend-design) Re-check Open Design MCP and record current project/file/artboard names before Phase 3.
- [ ] (@Pixel | Skill: frontend-design) Re-check Open Design MCP and record current project/file/artboard names before Phase 4.
- [ ] (@Sentinel) Save pulled Open Design screenshots or references into the session log before implementation begins for each section.
- [ ] (@Sentinel) Block exact matching for any surface where Open Design evidence is absent and user screenshots are absent.

### 10.3 Repo Discovery Lock

- [ ] (@Architect) Re-run `rg` for each target class name before editing so newly added files are not missed.
- [ ] (@Architect) Re-run `rg "Supabase.instance|\\.from\\(|\\.rpc\\("` across all target view/widget files and record any direct data access found.
- [ ] (@Architect) Re-run `rg "Color\\(|AppColors|Colors\\.|BackdropFilter|glass|Glass"` across all target files and classify visual leftovers.
- [ ] (@Architect) Re-run `rg "Duration\\(|Curves\\.|BoxShadow\\(|fontSize:"` across all target files and classify semantic token migration candidates.
- [ ] (@Sentinel) Record all discovered files in the session log before worker ownership is finalized.

### 10.4 Test Infrastructure Lock

- [ ] (@Sentinel) Verify constructor signatures for every target screen/widget that will receive tests.
- [ ] (@Sentinel) Verify Provider type for every mocked dependency: `ChangeNotifierProvider.value` only for `ChangeNotifier`, `Provider.value` for plain classes.
- [ ] (@Sentinel) Configure auto-loading ViewModel mocks before widget construction.
- [ ] (@Sentinel) Add fixture/state matrices before writing visual assertions.
- [ ] (@Sentinel) Run `flutter test` focused on existing Phase 2-4 tests before edits if time permits, and record failures.

### 10.5 Gate

- [ ] (@Sentinel) PASS only if Open Design evidence is logged for the section about to be edited.
- [ ] (@Sentinel) PASS only if file ownership is locked.
- [ ] (@Sentinel) PASS only if read-only MVVM/service files are listed.
- [ ] (@Sentinel) PASS only if no backend work is planned.

---

## 11. Phase 2: Phone Shell, Navigation, And Create Post

**Primary Agents:** @Pixel + @Architect + @Sentinel

### 11.1 Phase 2 Design Context Lock

- [ ] (@Pixel | Skill: frontend-design) Pull and log Open Design evidence for shell background, bottom nav, Home FAB, and create flow.
- [ ] (@Pixel | Skill: critique) Compare Open Design evidence against current `MainNavigationScreen`, `CustomBottomNavBar`, and `CreateTaskScreen`.
- [ ] (@Pixel | Skill: normalize) Map every shell/nav/create token to existing Amber Dusk token names before editing.
- [ ] (@Architect) Confirm the four-destination nav contract: Home, Dashboard, Messages, Profile.
- [ ] (@Sentinel) Record missing screenshot states: create validation, review, loading, publish success, publish failure.

### 11.2 Shell Layout And Background

- [ ] (@Pixel | Skill: arrange) Update `MainNavigationScreen` shell surfaces to use Amber Dusk theme/context tokens instead of teal-era visual leftovers.
- [ ] (@Pixel | Skill: normalize) Keep the default screen list unchanged: `HomeScreen`, `DashboardScreen`, `MessagesScreen`, `ProfileScreen`.
- [ ] (@Pixel | Skill: animate) Preserve existing directional tab transitions and use `AppMotion` or Amber Dusk motion tokens for any changed timing.
- [ ] (@Pixel | Skill: harden) Preserve safe-area handling for bottom navigation and the FAB.
- [ ] (@Observability) Preserve existing navigation `AppLogger` calls and add logging only for new branches or failure paths.
- [ ] (@Sentinel) Verify no layout shift when switching between the four tabs.

### 11.3 Bottom Navigation

- [ ] (@Pixel | Skill: normalize) Keep `CustomBottomNavBar` compact and four-column.
- [ ] (@Pixel | Skill: colorize) Use Amber Dusk bottom nav surface, active icon capsule, inactive label/icon, notification badge, safe-area, and elevation tokens.
- [ ] (@Pixel | Skill: harden) Preserve semantics and tap targets for all four nav items.
- [ ] (@Pixel | Skill: harden) Preserve Messages notification dot/badge behavior.
- [ ] (@Architect) Do not add Tender or Booking nav items.
- [ ] (@Sentinel) Verify active state for Home, Dashboard, Messages, and Profile at 360, 390, 402, and 430 logical widths.

### 11.4 Home-Owned Create Action

- [ ] (@Pixel | Skill: arrange) Keep the create FAB visible only on Home unless a documented existing behavior proves otherwise.
- [ ] (@Pixel | Skill: animate) Preserve scroll-aware FAB hide/show behavior and tokenized motion.
- [ ] (@Pixel | Skill: colorize) Use Amber Dusk amber action treatment and correct icon sizing.
- [ ] (@Pixel | Skill: harden) Verify the FAB is reachable with screen readers and has a clear tooltip/semantics label.
- [ ] (@Architect) Keep `createTaskScreenBuilder` as the test seam.
- [ ] (@Sentinel) Add/update tests proving the FAB opens the injected create screen and is absent or inactive outside Home, depending on implementation.

### 11.5 Create Type Selection

- [ ] (@Pixel | Skill: clarify) Present Tender and Booking as distinct creation choices using the Open Design evidence.
- [ ] (@Pixel | Skill: arrange) Make the selected type visually clear without changing `TaskType` behavior.
- [ ] (@Pixel | Skill: harden) Ensure long localized labels, text scale 1.3, and 360 px width do not overflow.
- [ ] (@Architect) Preserve edit-mode behavior for existing tasks.
- [ ] (@Sentinel) Add/update tests for Tender type selection, Booking type selection, selected state, and validation persistence when switching steps.

### 11.6 Tender Details Step

- [ ] (@Pixel | Skill: arrange) Group Tender fields according to the evidence: title, description, budget, location, work type/category, deadline.
- [ ] (@Pixel | Skill: normalize) Use `AppTextField`, `AppButton`, `AppCardContainer`, or other core widgets where they already fit.
- [ ] (@Pixel | Skill: clarify) Keep validation copy understandable and localized if new strings are introduced.
- [ ] (@Architect) Preserve `TaskViewModel.createTask` and `TaskViewModel.updateTask` contract.
- [ ] (@Sentinel) Add/update tests for required Tender validation, valid submission, loading state, and failure state.

### 11.7 Booking Details Step

- [ ] (@Pixel | Skill: arrange) Group Booking fields according to the evidence: package/title, role, level, price, period/delivery, location, experience.
- [ ] (@Pixel | Skill: normalize) Preserve existing package tier state and controller persistence.
- [ ] (@Pixel | Skill: harden) Verify large price, long package text, and tier switching at 360 px.
- [ ] (@Architect) Preserve current booking package data shape.
- [ ] (@Sentinel) Add/update tests for package tier persistence, valid booking submission, validation, and edit prefill.

### 11.8 Review And Publish Step

- [ ] (@Pixel | Skill: polish) Show a live preview that matches the relevant Tender/Booking card treatment where evidence exists.
- [ ] (@Pixel | Skill: clarify) Make primary and secondary actions unambiguous without adding new business steps.
- [ ] (@Pixel | Skill: harden) Preserve loading, success, error, and post-pop mounted safety.
- [ ] (@Observability) Add `AppLogger` entries for new publish/review failure branches only.
- [ ] (@Sentinel) Add/update tests for review display, publish success, publish failure, and post-dispose safety.

### 11.9 Phase 2 Verification

- [ ] (@Sentinel) Run `dart format --set-exit-if-changed` on changed Phase 2 files.
- [ ] (@Sentinel) Run focused tests: `flutter test test/widget/app/main_navigation_screen_test.dart test/core/widgets/custom_bottom_nav_bar_test.dart test/widget/tasks/create_task_screen_test.dart`.
- [ ] (@Sentinel) Run `flutter analyze --no-fatal-infos` after Phase 2 edits.
- [ ] (@Sentinel) Capture emulator screenshots for shell Home/Dashboard/Messages/Profile and create Tender/Booking flows.
- [ ] (@Sentinel) PASS only if no Tender/Booking nav item is added, no direct Supabase is introduced, and `AppLogger` covers new branches.

---

## 12. Phase 3: Phone Home, Discovery, Search, Categories, Saved, Favorites

**Primary Agents:** @Pixel + @Architect + @Sentinel

### 12.1 Phase 3 Design Context Lock

- [ ] (@Pixel | Skill: frontend-design) Pull and log Open Design evidence for Home All, Home Bookings, Home Tasks, search bar, filter chips, feed cards, and profile/result cards.
- [ ] (@Pixel | Skill: critique) Mark Categories, Search results, Saved, and Favorites as exact-match only if screenshots exist; otherwise mark them token-normalization surfaces.
- [ ] (@Pixel | Skill: normalize) Map Home discovery tokens to Amber Dusk card, search, chip, status, media, avatar, spacing, and motion recipes.
- [ ] (@Architect) Confirm no Home/Search/Categories/Favorites/Saved ViewModel contract changes are needed.
- [ ] (@Sentinel) Record all missing screenshots before edits.

### 12.2 Home Header And Search Entry

- [ ] (@Pixel | Skill: arrange) Update Home header spacing, profile/avatar treatment, notification action, and hierarchy to match Amber Dusk evidence.
- [ ] (@Pixel | Skill: normalize) Replace teal-era visual leftovers with tokens.
- [ ] (@Pixel | Skill: clarify) Keep search affordance clear and preserve existing search callback/delegation behavior.
- [ ] (@Pixel | Skill: harden) Verify long names and text scale 1.3.
- [ ] (@Sentinel) Add/update Home tests for search entry rendering, search tap behavior, profile/header loading, and refresh behavior.

### 12.3 Discovery Mode Chips

- [ ] (@Pixel | Skill: arrange) Align All, Bookings, and Tasks/Tenders mode chips with Open Design evidence.
- [ ] (@Pixel | Skill: normalize) Use tokenized active/inactive chip colors, typography, radius, spacing, and motion.
- [ ] (@Architect) Preserve local `_HomeDiscoveryMode` presentation-only state.
- [ ] (@Sentinel) Add/update tests for All, Bookings, and Tenders/Tasks filtering without changing ViewModel data ownership.

### 12.4 Discovery Sliver And Feed States

- [ ] (@Pixel | Skill: arrange) Update `DiscoveryTaskSliver` spacing, stagger, loading sentinel, empty state, error state, and load-more state.
- [ ] (@Pixel | Skill: animate) Keep or migrate existing stagger behavior to `AppMotion`; document any intentional per-item delay exception.
- [ ] (@Pixel | Skill: harden) Verify long titles, large prices, missing images, and 360 px width.
- [ ] (@Architect) Preserve pagination/load-more callbacks and `DiscoveryFeedViewModelContract`.
- [ ] (@Sentinel) Add/update tests for populated, loading, empty, error, load-more, and no-layout-shift states.

### 12.5 Tender And Task Cards

- [ ] (@Pixel | Skill: normalize) Update `TaskCard` and `TenderTaskCard` surfaces, title hierarchy, category, location, deadline, budget, owner, and CTA treatment.
- [ ] (@Pixel | Skill: colorize) Use Amber Dusk semantic status/accent tokens, not raw colors.
- [ ] (@Pixel | Skill: harden) Verify long title, large budget, missing category, missing owner, missing deadline, saved/unsaved, and favorite affordances.
- [ ] (@Architect) Preserve task detail navigation and callback contracts.
- [ ] (@Sentinel) Add/update direct widget tests for card visual state, semantics, overflow, callbacks, and token use.

### 12.6 Booking Cards

- [ ] (@Pixel | Skill: normalize) Update `BookingTaskCard` and `BookingCard` to match the Open Design booking hero/card evidence.
- [ ] (@Pixel | Skill: arrange) Preserve package, role/level, price, period, location, experience, owner/provider, and CTA hierarchy.
- [ ] (@Pixel | Skill: harden) Verify missing image/avatar fallback, long package names, large prices, and compact 360 px width.
- [ ] (@Architect) Preserve booking navigation and callbacks.
- [ ] (@Sentinel) Add/update direct widget tests for booking card states and overflow.

### 12.7 Filters Modal

- [ ] (@Pixel | Skill: arrange) Update `FiltersModal` structure, sections, chips, sliders/inputs, reset/apply actions, and sheet rhythm.
- [ ] (@Pixel | Skill: normalize) Use Amber Dusk sheet/card/input/button tokens and avoid ad hoc colors.
- [ ] (@Pixel | Skill: clarify) Keep filter labels and active-filter summaries understandable.
- [ ] (@Architect) Preserve `TaskFilterViewModel` behavior.
- [ ] (@Sentinel) Add/update tests for apply, reset, active filters, empty filters, and 360 px text scale.

### 12.8 Search Screen

- [ ] (@Pixel | Skill: polish) If Open Design or user screenshots provide a Search results target, align `SearchScreen` and `SearchResultProfileCard` to that target.
- [ ] (@Pixel | Skill: normalize) If no full target exists, token-normalize only: surface, input, result card, empty, loading, error, and no-results states.
- [ ] (@Architect) Preserve `SearchViewModel` contract and avoid direct Supabase in the view.
- [ ] (@Sentinel) Verify Type B construction before tests and add a seam only if needed.
- [ ] (@Sentinel) Add/update tests for query entry, loading, results, no-results, error, and profile result tap where supported.

### 12.9 Categories Screen

- [ ] (@Pixel | Skill: polish) If Open Design or user screenshots provide a Categories target, align `CategoriesScreen` and `_CategoryCard` to that target.
- [ ] (@Pixel | Skill: normalize) If no full target exists, token-normalize only: grid/list surfaces, card background, icon/accent, text, empty, loading, and error states.
- [ ] (@Architect) Preserve `CategoriesViewModel` behavior and repository/service ownership.
- [ ] (@Sentinel) Verify Type B construction before tests and add a seam only if needed.
- [ ] (@Sentinel) Add/update tests for populated categories, loading, error, empty, and category tap.

### 12.10 Saved Screen

- [ ] (@Pixel | Skill: polish) If Open Design or user screenshots provide a Saved target, align `SavedTasksScreen` and `SavedTaskTile` to that target.
- [ ] (@Pixel | Skill: normalize) If no full target exists, token-normalize only: list surface, saved tile, empty, loading, error, and unsave affordance.
- [ ] (@Architect) Preserve `SavedTasksViewModel` behavior.
- [ ] (@Sentinel) Add/update tests for saved list, empty, loading, error, unsave, and detail tap.

### 12.11 Favorites Screen

- [ ] (@Pixel | Skill: polish) If Open Design or user screenshots provide a Favorites target, align `FavoritesScreen` and `FavoriteCard` to that target.
- [ ] (@Pixel | Skill: normalize) If no full target exists, token-normalize only: list/grid surface, favorite card, empty, loading, error, remove, and start-chat affordance.
- [ ] (@Architect) Preserve `FavoritesViewModel` behavior and existing `ChatViewModel` dependency for chat start.
- [ ] (@Sentinel) Add/update tests for favorites list, empty, loading, error, remove, start-chat, and callback behavior.

### 12.12 Phase 3 Verification

- [ ] (@Sentinel) Run `dart format --set-exit-if-changed` on changed Phase 3 files.
- [ ] (@Sentinel) Run focused tests for Home, filters, cards, Search, Categories, Saved, and Favorites.
- [ ] (@Sentinel) Run `flutter analyze --no-fatal-infos` after Phase 3 edits.
- [ ] (@Sentinel) Capture emulator screenshots for Home All, Home Bookings, Home Tasks/Tenders, filters, Search, Categories, Saved, and Favorites at 390 or 402 px.
- [ ] (@Sentinel) Capture at least one 360 px overflow screenshot for long title/large price/feed cards.
- [ ] (@Sentinel) PASS only if every Phase 3 surface is either implemented from evidence or explicitly documented as token-normalized due missing evidence.

---

## 13. Phase 4: Phone Dashboard And Dashboard Sub-UI

**Primary Agents:** @Pixel + @Architect + @Sentinel

### 13.1 Phase 4 Design Context Lock

- [ ] (@Pixel | Skill: frontend-design) Pull and log Open Design evidence for Dashboard Overview, Bookings, Work, Wallet, Inbox, counters, activity, next actions, booking cards, work cards, offer cards, and wallet surfaces.
- [ ] (@Pixel | Skill: critique) Classify dashboard-launched detail/payment/work screens as future work unless the Phase 4 target directly renders them inline.
- [ ] (@Pixel | Skill: normalize) Map dashboard shell, tab, card, status, money, avatar, progress, wallet, and action tokens before editing.
- [ ] (@Architect) Confirm `DashboardScreen.tabViews` remains available for tests.
- [ ] (@Sentinel) Record missing screenshots for empty, error, loading, and role-specific dashboard states.

### 13.2 Dashboard Shell And Tabs

- [ ] (@Pixel | Skill: arrange) Update `DashboardScreen` shell layout, background, top controls, settings entry, and tab structure.
- [ ] (@Pixel | Skill: normalize) Use Amber Dusk tab and surface tokens, avoiding teal-era visuals.
- [ ] (@Pixel | Skill: animate) Preserve tokenized tab transitions and bottom sheet motion.
- [ ] (@Architect) Preserve `DashboardViewModel` lazy load, refresh behavior, role switch behavior, and web payment return recovery.
- [ ] (@Observability) Preserve existing payment recovery logs and add logs only for new dashboard UI branches.
- [ ] (@Sentinel) Add/update tests for five tabs, settings sheet, role switch sheet, tab tap, and injected `tabViews`.

### 13.3 Overview Tab

- [ ] (@Pixel | Skill: arrange) Update `OverviewTab` structure, section cards, overview hierarchy, and dashboard rhythm.
- [ ] (@Pixel | Skill: normalize) Use Amber Dusk card, typography, spacing, and status tokens.
- [ ] (@Pixel | Skill: harden) Verify empty, loading, error, and role-sensitive content.
- [ ] (@Architect) Preserve data consumption from `DashboardViewModel`.
- [ ] (@Sentinel) Add/update direct widget tests for populated, empty, loading, and error overview states.

### 13.4 Counters Grid

- [ ] (@Pixel | Skill: arrange) Update `DashboardCountersGrid` density, icon/value/label hierarchy, and responsive grid behavior.
- [ ] (@Pixel | Skill: colorize) Use semantic Amber Dusk colors for counter states and avoid raw colors.
- [ ] (@Pixel | Skill: animate) Preserve count-up/shimmer behavior only if tokenized and not layout-shifting.
- [ ] (@Sentinel) Add/update tests for counter values, shimmer/loading, compact width, and text scale.

### 13.5 Activity Feed Preview

- [ ] (@Pixel | Skill: arrange) Update `ActivityFeedPreview`, activity rows, icon/avatar treatments, timestamps, and empty state.
- [ ] (@Pixel | Skill: clarify) Keep activity labels concise and understandable.
- [ ] (@Pixel | Skill: harden) Verify long names, long activity text, missing avatars, and 360 px width.
- [ ] (@Architect) Preserve activity source data and callbacks.
- [ ] (@Sentinel) Add/update tests for populated, empty, loading, error, and tap states.

### 13.6 Next Actions

- [ ] (@Pixel | Skill: arrange) Update `NextActionsList` grouping, priority, CTA hierarchy, and empty state.
- [ ] (@Pixel | Skill: colorize) Use semantic urgency/status tokens from Amber Dusk.
- [ ] (@Pixel | Skill: harden) Verify accepted-unpaid Pay Now, missing action data, long titles, and role-sensitive states.
- [ ] (@Architect) Preserve CTA resolver behavior and payment/work navigation callbacks.
- [ ] (@Sentinel) Add/update tests for Pay Now, action tap, empty, loading, error, and role-specific actions.

### 13.7 Bookings Tab And Booking Cards

- [ ] (@Pixel | Skill: arrange) Update `BookingsTab` list/sections, headers, skeletons, empty/error/loading states, and scroll rhythm.
- [ ] (@Pixel | Skill: normalize) Update `DashboardBookingCard` to Amber Dusk booking status, deadline, avatar, money, and CTA treatment.
- [ ] (@Pixel | Skill: harden) Verify upcoming, pending, accepted, completed, canceled, empty, loading, and error states.
- [ ] (@Architect) Preserve booking callbacks and data model usage.
- [ ] (@Sentinel) Add/update widget tests for tab states and booking card variants.

### 13.8 Work Tab And Work Cards

- [ ] (@Pixel | Skill: arrange) Update `WorkTab` buckets for Active, Done, and Cancelled according to Open Design evidence.
- [ ] (@Pixel | Skill: normalize) Update `WorkItemCard` with dark raised panel, avatar/code mark, source line, right-aligned money, progress row, and status secondary treatment.
- [ ] (@Pixel | Skill: colorize) Use Amber Dusk semantic status colors for active, delivered, completed, disputed, no-show, and canceled.
- [ ] (@Pixel | Skill: harden) Verify long work titles, missing client/provider, large money values, and compact widths.
- [ ] (@Architect) Preserve work item navigation and lifecycle callbacks.
- [ ] (@Sentinel) Add/update tests for Active, Done, Cancelled, delivered, completed, disputed, no-show, canceled, empty, loading, and error states.

### 13.9 Inbox Tab And Offer Cards

- [ ] (@Pixel | Skill: arrange) Update `InboxTab` surface, grouping, empty inbox, accepted-unpaid state, and action hierarchy.
- [ ] (@Pixel | Skill: normalize) Update `DashboardOfferCard` offer status, countdown, payment deadline, owner/provider, CTA, and fallback states.
- [ ] (@Pixel | Skill: animate) Replace local hardcoded countdown animation timing with tokens if the value is semantic; otherwise document the exception.
- [ ] (@Architect) Preserve offer action callbacks, payment callbacks, and existing lifecycle logic.
- [ ] (@Sentinel) Add/update tests for accepted-unpaid Pay Now, pending, accepted, rejected, expired, canceled, countdown, empty, loading, and error states.

### 13.10 Wallet Tab And Wallet Cards

- [ ] (@Pixel | Skill: arrange) Update `WalletTab` shell and `WalletSharedBody` layout only within dashboard-visible wallet scope.
- [ ] (@Pixel | Skill: colorize) Update `WalletHeroCard`, `WalletSnapshotCard`, and `WalletTimelineCard` using Amber Dusk money, escrow, available, timeline, empty, and error tokens.
- [ ] (@Pixel | Skill: clarify) Keep withdrawal and Coming Soon copy clear without changing payment/withdrawal logic.
- [ ] (@Pixel | Skill: harden) Verify wallet loading, empty activity, error, withdraw Coming Soon, large balances, and text scale.
- [ ] (@Architect) Preserve wallet ViewModel/service behavior and payment ledger logic.
- [ ] (@Sentinel) Add/update tests for wallet hero, snapshot, timeline, loading, error, empty activity, and withdraw disabled/coming-soon states.

### 13.11 Dashboard-Launched Screens Boundary

- [ ] (@Architect) Inventory links from Dashboard cards to `work_item_details_screen.dart`, booking details, and payment screens.
- [ ] (@Architect) Do not redesign launched detail/payment screens in this plan unless a dashboard widget visually embeds them.
- [ ] (@DocsKeeper) Record launched-screen redesign needs as future work if visual mismatches remain.
- [ ] (@Sentinel) Smoke-test that dashboard card taps still route to the same destinations.

### 13.12 Phase 4 Verification

- [ ] (@Sentinel) Run `dart format --set-exit-if-changed` on changed Phase 4 files.
- [ ] (@Sentinel) Run focused dashboard, bookings, work, inbox, wallet, counters, activity, next actions, booking card, offer card, and wallet card tests.
- [ ] (@Sentinel) Run `flutter analyze --no-fatal-infos` after Phase 4 edits.
- [ ] (@Sentinel) Capture emulator screenshots for Dashboard Overview, Bookings, Work Active, Work Done, Work Cancelled, Wallet, and Inbox at 390 or 402 px.
- [ ] (@Sentinel) Capture at least one role-sensitive dashboard state and one accepted-unpaid Pay Now state.
- [ ] (@Sentinel) PASS only if every dashboard tab and dashboard-local sub-widget is covered by code, test, and screenshot evidence or explicitly documented as deferred.

---

## 14. Cross-Phase QA And Regression Sweep

**Primary Agents:** @Sentinel + @CodeGuard + @Architect

### 14.1 Static Checks

- [ ] (@Sentinel) Run `dart format --set-exit-if-changed lib test`.
- [ ] (@Sentinel) Run `flutter analyze --no-fatal-infos`.
- [ ] (@Sentinel) Run `git diff --check`.
- [ ] (@CodeGuard) Run `rg "Color\\(0x|fontSize:|Duration\\(|BoxShadow\\(|BackdropFilter|glass|Glass" lib/app lib/core/widgets lib/features/home lib/features/tasks lib/features/booking lib/features/categories lib/features/search lib/features/favorites lib/features/saved lib/features/dashboard lib/features/wallet` and classify remaining hits.
- [ ] (@Architect) Run `rg "Supabase.instance|\\.from\\(|\\.rpc\\("` across changed view/widget files and fail if new direct data access appears.

### 14.2 Focused Tests

- [ ] (@Sentinel) Run Phase 2 focused tests.
- [ ] (@Sentinel) Run Phase 3 focused tests.
- [ ] (@Sentinel) Run Phase 4 focused tests.
- [ ] (@Sentinel) Run `flutter test test/core/widgets/` if shared widgets were touched.
- [ ] (@Sentinel) Run `flutter test --coverage` after focused tests pass.
- [ ] (@Sentinel) Parse `coverage/lcov.info` and record hit/found/percent in the session log.

### 14.3 Manual Emulator QA

- [ ] (@Sentinel) Test widths 360, 390, 402, and 430 logical px where emulator tooling permits.
- [ ] (@Sentinel) Test text scale 1.0 and 1.3.
- [ ] (@Sentinel) Test safe area/system nav overlap for shell, Home, create flow, and dashboard tabs.
- [ ] (@Sentinel) Test light/dark only if runtime theming supports it; otherwise document Amber Dusk staged-token limitation.
- [ ] (@Sentinel) Attach or record screenshot paths for every screen in the emulator checklist.

### 14.4 Behavioral Smoke

- [ ] (@Sentinel) Verify Home refresh still refreshes feed, profile header, and saved tasks.
- [ ] (@Sentinel) Verify Home card tap still opens task details.
- [ ] (@Sentinel) Verify create Tender and Booking publish still call the correct ViewModel paths.
- [ ] (@Sentinel) Verify Dashboard tab switching still works.
- [ ] (@Sentinel) Verify Dashboard role switch still works.
- [ ] (@Sentinel) Verify Dashboard Pay Now and work/booking/offer action callbacks still route or no-op exactly as before.
- [ ] (@Sentinel) Verify Saved/Favorites/Search/Categories interactions still route or call callbacks exactly as before.

### 14.5 Gate

- [ ] (@Sentinel) PASS only if analyze passes.
- [ ] (@Sentinel) PASS only if focused tests pass.
- [ ] (@Sentinel) PASS only if full test or approved subset result is recorded.
- [ ] (@Sentinel) PASS only if runtime screenshots are logged.
- [ ] (@CodeGuard) PASS only if no unreviewed visual leftovers remain.
- [ ] (@Architect) PASS only if no MVVM boundary regression appears.

---

## 15. Documentation And Handoff

**Primary Agents:** @DocsKeeper + @Sentinel

### 15.1 Session Docs

- [ ] (@DocsKeeper) Append implementation notes, test results, command outputs, screenshot paths, and known limitations to the session log.
- [ ] (@DocsKeeper) Create or update a Master Report for the completed Phase 2-4 implementation only after execution and review.
- [ ] (@DocsKeeper) Create or update an emulator checklist only after code and gap-scan work is complete.

### 15.2 Project Docs

- [ ] (@DocsKeeper) Update `Sline_everything/MVP_ROADMAP.md` with actual Phase 2-4 status after verification.
- [ ] (@DocsKeeper) Update `Sline_everything/DEVELOPER_GUIDE.md` only for durable UI/theming patterns that changed.
- [ ] (@DocsKeeper) Update `Sline_everything/CODE_REVIEW.md` only if new review guidance was learned.
- [ ] (@DocsKeeper) Update `Sline_everything/STRUCTURE.md` only if file structure changed.
- [ ] (@DocsKeeper) Update `.cursor/PROJECT_CONTEXT.md` only if the current architecture or theme state changed.

### 15.3 Web Handoff

- [ ] (@DocsKeeper) Update or create a web handoff note for Mohammed only after runtime screenshots and accepted Phase 2-4 scope are available.
- [ ] (@DocsKeeper) Include exact Flutter files touched, screenshots, token names, and known non-implemented surfaces.
- [ ] (@DocsKeeper) Do not claim web parity; this remains phone implementation evidence for later web adaptation.

---

## 16. Acceptance Criteria

- [ ] (@Sentinel) Phase 2 shell/nav/create flow matches Open Design evidence where evidence exists.
- [ ] (@Sentinel) Phase 2 keeps Home-owned create action and four-item bottom nav.
- [ ] (@Sentinel) Phase 2 preserves create Tender/Booking behavior and edit mode.
- [ ] (@Sentinel) Phase 3 Home discovery, cards, filters, Search, Categories, Saved, and Favorites are either evidence-matched or explicitly token-normalized due missing evidence.
- [ ] (@Sentinel) Phase 3 covers populated, loading, empty, error, saved, unsaved, favorite, no-results, and filter-active states where applicable.
- [ ] (@Sentinel) Phase 4 covers Dashboard Overview, Bookings, Work, Wallet, Inbox, counters, activity, next actions, booking cards, offer cards, wallet cards, and dashboard-local status surfaces.
- [ ] (@Sentinel) Phase 4 preserves dashboard payment recovery, role switching, action callbacks, and route behavior.
- [ ] (@Sentinel) Every new code path has `AppLogger` instrumentation.
- [ ] (@Sentinel) Every new unit/widget has focused tests.
- [ ] (@Sentinel) `flutter analyze --no-fatal-infos` passes.
- [ ] (@Sentinel) Focused tests pass.
- [ ] (@Sentinel) Full `flutter test --coverage` result is recorded or the reason it could not be run is documented.
- [ ] (@Sentinel) Runtime emulator screenshots are captured and referenced.
- [ ] (@Architect) No direct Supabase access is added to Views.
- [ ] (@Architect) No schema/backend changes are introduced.
- [ ] (@DocsKeeper) Docs and handoff artifacts reflect actual verified implementation, not aspirations.

---

## 17. Rollback Plan

- [ ] (@Architect) Keep changes grouped by phase and file ownership so Phase 2, Phase 3, or Phase 4 can be reverted independently if needed.
- [ ] (@Architect) If Phase 2 navigation regresses, revert only `main_navigation_screen.dart`, `custom_bottom_nav_bar.dart`, and their tests.
- [ ] (@Architect) If create flow regresses, revert only `create_task_screen.dart`, create helper widgets, and create tests.
- [ ] (@Architect) If Phase 3 feed/search/categories/saved/favorites regress, revert only the relevant screen/card subset and keep unrelated phases intact.
- [ ] (@Architect) If Phase 4 dashboard regresses, revert dashboard tabs/cards/wallet subsets independently.
- [ ] (@Sentinel) Before any rollback, save failing command output, screenshot, and exact regression note in the session log.
- [ ] (@DocsKeeper) Update docs/handoff after rollback so they do not claim removed work.

---

## 18. References

- `.cursor/Agents/Planner.md`
- `.TODO/PLAN_OpenDesign_AmberDusk_Phone_2026-05-10.md`
- `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/MASTER_REPORT_2026-05-11_OpenDesign_AmberDusk_Phase0.md`
- `.TODO/Archive/OpenDesign_AmberDusk_Phase1_2026-05-11/MASTER_REPORT_2026-05-11_OpenDesign_AmberDusk_Phase1_CoreWidgets.md`
- `.TODO/EMULATOR_TEST_CHECKLIST_2026-05-11_OpenDesign_AmberDusk_Phase1_CoreWidgets.md`
- `docs/LOG/SESSION_PLAN_OpenDesign_AmberDusk_Phase0_PhoneFoundation_2026-05-11.md`
- `docs/LOG/SESSION_PLAN_OpenDesign_AmberDusk_Phase1_CorePhoneWidgets_2026-05-11.md`
- `Sline_everything/DEVELOPER_GUIDE.md`
- `Sline_everything/SUPABASE_SETUP.md`
- `Sline_everything/MVP_ROADMAP.md`
- `Sline_everything/ARCHITECTURE_ANALYSIS.md`
- `Sline_everything/CODE_REVIEW.md`
- `Sline_everything/STRUCTURE.md`
- `.cursor/PROJECT_CONTEXT.md`
