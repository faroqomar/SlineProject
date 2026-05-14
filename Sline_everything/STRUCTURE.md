# SLine App - Folder Structure Guide

**Last Updated:** 2026-05-15 (lint strictness hardening, Amber Dusk Phases 9-12, Transactional QA Recovery, SystemEvolution, and DocsKeeper sync documented)

This document describes the current repository layout. It replaces older references to `presentation/` and `controllers/`; the live Flutter codebase uses `view/` and `viewmodels/` under `lib/features/`.

## Top-Level Overview

```text
sline_app/
├── .agents/              # Local skills and workflows used by the coding agents
├── .cursor/              # Cursor agent definitions and project rules
├── .github/workflows/    # CI pipeline (lint, test, coverage artifact, build, architecture guard)
├── .githooks/            # Pre-commit hook (format + analyze)
├── .TODO/                # Audits, plans, execution logs, QA notes, docs-sync notes
├── docs/LOG/             # Session logs and SystemEvolution reports
├── docs/diagrams/        # Feature diagrams (Mermaid + explanations)
├── Sline_everything/     # Source-of-truth project documentation
├── assets/               # Bundled app assets
├── lib/                  # Flutter application source
├── supabase/             # Edge functions and SQL migrations
├── test/                 # Unit and widget tests
├── integration_test/     # End-to-end test entrypoints
├── android/ ios/ web/    # Platform runners
├── linux/ macos/ windows/# Desktop runners
├── pubspec.yaml          # Flutter package manifest
├── analysis_options.yaml # very_good_analysis + SLine safety rules + strict Dart modes
├── MIGRATION_REVIEW_CHECKLIST.md  # Phase D: 7-point checklist for migration PRs
└── README.md             # Repository overview
```

## Documentation and Agent Directories

### `.agents/`

- `skills/`: reusable local workflows such as `docs_sync`, `bug_fixer`, and `supabase_migration`
- `workflows/`: higher-order coordination docs such as `planner.md`, `executor.md`, and `Orchestrator.md`

### `.cursor/`

- `Agents/`: role definitions for the multi-agent system (16 agents)
  - **Core agents**: `Architect.md` (MVVM logic), `Pixel.md` (UI/UX), `Supabase_Ops.md` (backend), `DocsKeeper.md` (documentation), `Sentinel.md` (QA/verification)
  - **Planning & execution**: `Planner.md` (implementation architect), `Executor.md` (task orchestrator), `PlanCritic.md` (plan auditor), `Orchestrator.md` (multi-agent coordinator)
  - **Specialized**: `CodeGuard.md` (performance/security audit), `ThreatModeler.md` (security design), `APIContract.md` (contract alignment), `DataMigration.md` (schema safety), `Observability.md` (telemetry), `TemplateOwner.md` (task templates)
  - **Meta**: `SystemEvolution.md` (cross-session agent improvement — scans logs and agent files, produces upgrade reports; explicit merge runs may update agent files after the report; latest merge report: `docs/LOG/SYSTEM_EVOLUTION_REPORT_2026-05-14.md`)
- `rules/`: project-specific rules used by Cursor tooling (`flutter-mvvm.mdc`, `error-handling.mdc`)
- `skills/`: skill definitions referenced by agents for specialized work

### `.TODO/`

This folder is active working documentation, not archive-only material.

Typical files:

- feature audits: `management.TODO.md`
- plans: `PLAN_*.md`
- execution logs: `EXECUTION_LOG_*.md`
- review and QA artifacts: `MASTER_REPORT_*.md`, `CODEGUARD_REVIEW_*.md`, `SENTINEL_QA_*.md`, emulator checklists, evidence, and handoff notes
- docs sync notes: `DOCS_SYNC_*.md`

## `Sline_everything/` - Documentation Hub

Primary documents:

- `SUPABASE_SETUP.md`: database schema, RLS, RPCs, indexes, storage
- `DEVELOPER_GUIDE.md`: system map plus embedded feature references
- `DEVELOPER_GUIDE/`: feature-specific deep dives
- `STRUCTURE.md`: this file
- `MVP_ROADMAP.md`: current module status tracker
- `Sline_Log.md`: versioned project history and release notes
- `DOC_SOURCE_MAP.md`: feature-to-doc and feature-to-diagram routing
- `UI_SURFACE_INVENTORY.md`: screen, route, popup, sheet, tab, navigation, and shared-widget inventory
- `AppDiagram/README.md`: diagram index for planning and review
- `ARCHITECTURE_ANALYSIS.md`: long-form architecture guidance
- `CODE_REVIEW.md`: recurring review findings and reusable practices

## `supabase/` - Backend Runtime Assets

```text
supabase/
├── functions/
│   ├── _shared/                    # Shared edge-function helpers
│   ├── booking_decline_refund/     # Server-backed booking refund flow
│   ├── qicard_payment_create/      # Creates validated booking drafts + payment session
│   ├── qicard_payment_create_direct_offer/  # Direct-offer payment session creation
│   ├── qicard_payment_recovery/    # Recovers booking state after gateway return
│   ├── qicard_payment_recovery_direct_offer/ # Recovers direct-offer state after gateway return
│   ├── qicard_webhook_handler/     # QiCard webhook verification and ledger entry
│   ├── push-notify/                # Single push payload (optional PUSH_NOTIFY_SECRET); notification routing (13)
│   └── process-push-queue/         # Batch drain notification_push_queue → FCM (requires CRON_SECRET)
├── tests/                          # Phase D: SQL assertion tests for critical RPCs
│   ├── accept_task_request_test.sql          # 4 tests: accept, auto-reject, double-accept, task status
│   ├── escrow_idempotency_test.sql           # 5 tests: hold, replay, no duplicates, missing key, wrong currency
│   └── role_switch_rate_limit_test.sql       # 6 tests: switch, switch back, no-op, stale state, invalid role, audit
└── migrations/                     # SQL migrations applied to Supabase
```

Recent migration themes in `supabase/migrations/`:

- ledger introduction and wallet views
- booking server authority and payment remediation
- repeat slotless booking support
- management timeline scope index
- escrow idempotency (stable key + FOR UPDATE in `rpc_approve_delivery`, migration `20260307000001_escrow_idempotency_stable_key.sql`)
- **Hardened Payment Gateway & Administrator Views (v2.20, 2026-03-07):** Added `payment_intents`, `payment_events`, and `orphan_payments` tables. New admin financial views `vw_admin_finance_metrics`, `vw_admin_escrow_open`, and `vw_admin_booking_finance`.
- direct_offers table, RLS, triggers, ledger RPC and enum fix (20260303–20260308); 20260308 fixes release_with_fee zero-amount and enum cast
- **Direct Offers Work Contract (Plan 19, 2026-03-07):** `admin` schema; `admin.vw_direct_offer_money_story`, `admin.vw_direct_offer_stuck_funds`; self-offer guard `trg_direct_offer_guard_insert`; RPC `admin_refund_direct_offer` (migrations `20260307180000_admin_direct_offer_views`, `20260307180100_direct_offer_self_offer_guard`, `20260307180200_admin_refund_direct_offer`)
- **Direct Chat Offer Flow hardening (Plan DirectChatOfferFlow CRITIC, 2026-03-07/08):** `20260319000000_direct_offer_flow_harden.sql` (currency, payment_*, delivered_at, review_expires_at on direct_offers; direct_offer_id and chk_dispute_entity on disputes); `20260319110000_direct_offer_guard_rls_ledger.sql` (trigger protect price/currency, disputes_insert_own RLS, rpc_approve_delivery fee from direct_offers row); `20260319120000_direct_offer_auto_release_cron.sql` (run_auto_release_expired_direct_offers + pg_cron); `20260319130000_direct_offer_protect_fee_in_trigger.sql` (trigger also protects fee_rate_applied_bps)
- **Work contract revisions hardening (2025-03-08):** `20260308120000_harden_rpc_request_revision.sql` — state guard (status=delivered) and cap guard (revisions_used &lt; revisions_total) in `rpc_request_revision`. Plan: `.TODO/PLAN_WorkContractRevisions_2025-03-08_PlanCritic.md`.
- **Unified Work View upgrade (2026-03-08):** `20260308100000_rollback_unified_work_view.sql` (restores 3-branch view); `20260308110000_upgrade_unified_work_view.sql` (4 branches: tasks, bookings, awarded pending, direct_offers; dispute override; conversation_id; security_invoker). Plan: `.TODO/PLAN_UnifiedWorkView_2026-03-08_CRITIC.md`.
- **Booking Lifecycle (2026-03-08):** `20260308210000_booking_lifecycle_enum.sql` (add `disputed`, `no_show` to booking_status_enum); `20260308210100_booking_lifecycle_guard.sql` (fn_booking_guard: client cannot delivered→canceled; client can delivered→disputed; admin only disputed→completed/refunded; provider/admin active→no_show); `20260308210200_rpc_finalize_auto_approval_booking_ledger.sql` (booking branch calls process_payment_event_ledger); `20260308210300_admin_resolve_booking_dispute.sql`; `20260308210400_ledger_allow_disputed_booking_admin.sql`. Plan: `.TODO/PLAN_BookingLifecycle_2026-03-08_PlanCritic.md`.
- **Dispute lifecycle (2026-03-08):** `20260308140000_dispute_lifecycle_escrow_guard_rls.sql` (escrow guard in rpc_approve_delivery and rpc_finalize_auto_approval; deny policies on disputes; RLS on dispute_messages and dispute_evidence; indexes on disputes). `20260308150000_dispute_enum_guard_resolved_at.sql` (dispute_status_enum; triggers trg_dispute_guard, trg_dispute_set_resolved_at; vw_unified_work_items recreated with enum-safe disputed check). **14a Dispute Extension:** `20260308160000_14a_dispute_extension_frozen_guards.sql` (Frozen guard in rpc_submit_delivery and rpc_request_revision; partial unique indexes one open/active per task/direct_offer; rpc_submit_dispute). **Post-14a:** `20260308170000_rpc_submit_dispute_booking_eligible.sql` (dispute allowed when task or any booking for task is active/delivered); `20260308180000_tender_assign_only_after_payment.sql` (award = reserve only; assign in pay_awarded_offer); `20260308180100_award_task_offer_drop_old_overload.sql` (drop 2-param award_task_offer); `20260308190000_vw_unified_work_items_dispute_open_active_only.sql` (disputed only when dispute.status IN ('open','active')). Plan: `.TODO/PLAN_DisputeLifecycle_2026-03-08.md`, `.TODO/PLAN_14a_DisputeExtension_2026-03-08.md`.

## `lib/` - Flutter Application Source

```text
lib/
├── app/
│   └── main_navigation_screen.dart
├── core/
│   ├── config/
│   ├── models/
│   ├── navigation/
│   ├── providers/
│   ├── services/
│   ├── theme/
│   ├── utils/
│   └── widgets/
├── l10n/          # Localization: ARB files, generated AppLocalizations
├── features/
│   └── <feature>/
│       ├── data/        # Repository / data-access layer when needed
│       ├── models/      # Feature models
│       ├── services/    # Supabase / backend integrations
│       ├── view/        # Screens and widgets
│       └── viewmodels/  # ChangeNotifier state + orchestration
├── shared/
│   └── constants/
└── main.dart
```

### `lib/app/`

App-level shell and navigation.

Current file:

- `lib/app/main_navigation_screen.dart`: bottom navigation shell and main app entry after authentication

### `lib/core/`

Shared cross-cutting infrastructure.

Current subfolders:

- `config/`: runtime configuration (e.g. `auth_config.dart`, `payment_runtime_config.dart`); user-facing auth strings in `lib/core/constants/auth_messages.dart`
- `models/`: global models such as `user_profile.dart` and shared `payment_return_args.dart`
  - `view_state.dart` — **Phase E** Sealed ViewState<T> (ViewInitial, ViewLoading, ViewLoaded, ViewFailed)
  - `app_failure.dart` — **Phase E** Sealed AppFailure (NetworkFailure, AuthFailure, ValidationFailure, BusinessFailure)
- `navigation/`: app-shell navigation contracts
  - `main_nav_destinations.dart` — named bottom-nav indexes for Home, Dashboard, Messages, and Profile. Keep app shell, bottom nav, profile deep links, and navigation tests on this contract instead of duplicating numeric indexes.
- `providers/`: app-wide providers such as navigation and theme mode
- `services/`: Supabase bootstrap, payment services, cache, deep links, crash reporting, logging, **role switch coordinator**
  - `deep_link_registry.dart` — **Phase E** DeepLinkRegistry with feature-side handler registration
  - `payment_response_helpers.dart` — **Phase E** Pure helper functions for payment response parsing
- `theme/`: Three-layer design system (Theme → Layout → Components)
  - `app_colors.dart` — color palette + 44-property AppColorScheme (semantic status + interactive colors)
  - `app_typography.dart` — 14 text styles with per-style line heights (1.0–1.5)
  - `app_dimens.dart` — raw spacing primitives (p0–p100), border radii (r4–r50), icon sizes
  - `app_layout.dart` — **Phase 0.7** semantic layout tokens (card, avatar, button, spacing, icon, nav, border)
  - `app_motion.dart` — **Phase 0** animation tokens (7 durations, 7 curves, 4 scales, 3 staggers)
  - `app_states.dart` — **Phase 0** interaction state constants (8-state model, haptic mapping)
  - `app_decorations.dart` — 5-level elevation shadow scale + decoration methods
  - `app_theme.dart` — Material 3 ThemeData assembly + 13 component themes
  - `theme_dashboard.dart` — documentation-only reference for all design tokens
  - `designs/amber_dusk/` — **Amber Dusk Phase 0-12 + Transactional QA** Open Design token layer plus shared-widget adapter; `amber_dusk_tokens.dart` exports all Amber Dusk token files and `AmberDuskTokens.widgetTheme` for scoped phone/web redesign phases without globally flipping `MaterialApp`
    - `amber_dusk_widget_theme.dart` — Phase 1 typed shared-widget recipes for buttons, fields, cards, nav, tabs, badges, skeletons, and signed-media placeholders
- `utils/`: error mapping, formatting, loading overlays, URL cache, route transitions, web error filters, **ledger forensics** (p_meta session_id/request_id for ledger event flow)
- `widgets/`: shared UI widgets such as signed media, buttons, badges, loaders, bottom nav
- `mixins/`: shared behavior mixins such as `role_switch_aware.dart`

Important current core files:

- `lib/core/services/supabase_config.dart`
- `lib/core/navigation/main_nav_destinations.dart` — Home/Dashboard/Messages/Profile named index contract for the authenticated bottom navigation
- `lib/core/services/crash_reporting_service.dart` — Abstract interface + NoOp stub for crash reporting
- `lib/core/services/sentry_crash_reporting_service.dart` — Phase D: Sentry implementation of CrashReportingService
- `lib/core/services/payment_service.dart`
- `lib/core/services/qicard_payment_service.dart`
- `lib/core/services/payment_pending_store.dart`
- `lib/core/services/role_switch_coordinator.dart` — Cross-ViewModel teardown coordination for role switching
- `lib/core/mixins/role_switch_aware.dart` — Mixin interface for ViewModels participating in role switch teardown
- `lib/core/utils/loading_utils.dart`
- `lib/core/utils/flutter_error_filters.dart`
- `lib/core/utils/ledger_forensics.dart` — Ledger forensics (session_id, request_id) for p_meta; single source for ledger event flow (09)
- `lib/core/widgets/signed_avatar.dart`
- `lib/core/widgets/signed_image.dart`
- `lib/core/widgets/fullscreen_image_viewer.dart` — **Phase 6** Reusable fullscreen image viewer with pinch-to-zoom and optional caption

### `lib/features/`

Current feature folders:

- `auth`
- `booking`
- `categories`
- `chat`
- `dashboard`
- `direct_offers`
- `favorites`
- `home`
- `management`
- `notifications`
- `portfolio`
- `profile`
- `proposals`
- `saved`
- `search`
- `services`
- `tasks`
- `wallet`
- `work`

Not every feature uses every subfolder, but the standard live convention is:

- `view/` instead of `presentation/`
- `viewmodels/` instead of `controllers/`
- `data/` for repositories when a repository layer exists
- `services/` for low-level integrations

### Feature Highlights

- `lib/features/auth/`: login, signup, forgot password, auth session handling. Amber Dusk Phase 5 tokenizes auth and system-gate screens while preserving existing Auth/ViewModel behavior. Transactional QA recovery resets successful signup to Main/Home to avoid stale detail-route stacks.
- `lib/features/booking/`: direct booking checkout, booking lists/details, payment return/webview screens. Amber Dusk Phase 8 tokenizes booking/payment surfaces, keeps payment authority in existing services, and restricts WebView logging to safe URL facts. Transactional QA recovery passes booking intent streams into WebView, accepts sanitized callbacks, refreshes booking/dashboard state after held recovery, and keeps raw payment metadata out of customer UI.
  - `viewmodels/booking_payment_delegate.dart` — **Phase E** Payment coordination delegate
  - `services/booking_deep_link_handler.dart` — **Phase E** Deep link handler for booking routes
  - `view/widgets/payment_order_summary_card.dart` — **Phase E** Extracted payment order summary widget
- `lib/features/profile/`: profile editing, avatar upload, **role switching (v2.18)**, portfolio management. Amber Dusk Phases 9-12 align profile, public profile, settings, avatar, portfolio, services, and related secondary surfaces without backend contract changes.
  - `data/profile_repository.dart` — Main profile repository (legacy `changeRole()` deprecated)
  - `data/role_switch_repository.dart` — **NEW (v2.18)** Atomic role switching with RPC, session refresh, JWT verification
  - `models/role_switch_result.dart` — **NEW (v2.18)** RPC response model with error taxonomy
  - `services/profile_deep_link_handler.dart` — **Phase E** Deep link handler for profile routes
- `lib/features/chat/`: conversations, messages, attachments, realtime updates. Amber Dusk Phase 6 updates messaging, attachments, context, and offer surfaces while keeping signed URL resolution behind `ChatViewModel`/services. Transactional QA recovery aligns chat, offer bubbles, create-offer sheet, composer active/focused states, and Messages search guidance with Amber Dusk/IQD semantics.
  - `services/chat_deep_link_handler.dart` — **Phase E** Deep link handler for chat routes
  - `view/widgets/conversation_list_tile.dart` — **Phase 6** Elevated card tile with unread indicators, relative time, online dot
  - `view/widgets/message_bubble.dart` — **Phase 6** Emoji-only rendering, link detection, reply quotes
  - `view/widgets/offer_message_bubble.dart` — **Phase 6** Elevated offer card with status borders
- `lib/features/dashboard/`: unified dashboard tabs (Overview, Bookings, Work, Wallet, Inbox) and role-based work summaries, including the live bottom-nav dashboard slot. Amber Dusk Phase 4 updates dashboard shell/tabs/cards in this feature while keeping card ownership in booking/tasks/wallet. Transactional QA recovery adds empty-state CTAs, removes the disabled Inbox Sent placeholder, and keeps canceled/terminal booking drafts out of active/upcoming buckets. Tab cards (booking, offer, wallet snapshot) live in owning features: `booking/view/widgets/dashboard_booking_card.dart`, `tasks/view/widgets/dashboard_offer_card.dart`, `wallet/view/widgets/wallet_snapshot_card.dart`; dedicated Wallet tab in `view/tabs/wallet_tab.dart`; shared status helpers in `core/utils/status_presenter.dart`
- `lib/features/direct_offers/`: direct chat offers (create, accept, pay, deliver, complete) and payment recovery
  - `services/direct_offer_deep_link_handler.dart` — **Phase E** Deep link handler for direct offer routes
- `lib/features/notifications/`: in-app notification list (server-authority; foreground sync then stream), badge/modal/deep links; `PushDeviceService` registers FCM tokens in `user_devices`; push delivery via `notification_push_queue` + Edge (`push-notify`, `process-push-queue`). `NotificationViewModel` preserves cached notifications and reconnects on transient Supabase Realtime close codes `1002`/`1006`. Diagram: `Sline_everything/AppDiagram/All_Diagrams/13_notification-routing.md`. Plan: `.TODO/PLAN_NotificationRouting_2026-03-08_PlanCritic.md`.
- `lib/features/management/`: order timeline / note management for tasks and bookings
- `lib/features/orders/`: decommissioned placeholder folder with `README.md` only; standalone orders runtime was removed on 2026-03-01
- `lib/features/proposals/`: proposal models, data (repositories), routes (payment); view re-exports from tasks for list/submit/tile/payment screens
- `lib/features/tasks/`: task creation, details, requests/offers, tender payment, delivery flows. Amber Dusk Phases 2-4 touch create flow, task/tender/booking card widgets, dashboard offer cards, and `models/task_model.dart` package-detail helper accessors without changing Supabase contracts. Amber Dusk Phase 7 tokenizes tender/request/payment-adjacent work surfaces while preserving ViewModel/service lifecycle authority. Transactional QA recovery adds `CreateTaskResult`, poster-visible Home refresh, category-specific Home copy, and whole-IQD proposal/request amount handling.
  - `exceptions/offer_exceptions.dart` — **NEW (v2.20)** Custom exceptions: `PriceMismatchException`, `OfferAlreadyAcceptedException`
  - `models/expired_bid_filter.dart` — **Phase D** Extracted `ExpiredBidFilter` enum + extension for bid list filtering
  - `viewmodels/award_expiration_monitor.dart` — **NEW (v2.20)** Countdown timer for unpaid awards with urgency levels
  - `viewmodels/submit_request_view_model.dart` — **Phase D** Business logic for bid submission/replacement (validateTask, checkReplaceability, submitNewBid, replaceBid)
  - `viewmodels/requests_filter_view_model.dart` — **Phase D** Filter/sort/award state for requests list (subscribes to TaskRequestsViewModel)
  - `view/widgets/requests/request_award_dialog.dart` — **Phase D** Extracted award confirmation dialog + payment flow + price mismatch dialog
  - `services/task_offer_service.dart` — **Phase E** 13 offer/payment methods extracted from TaskService
  - `services/task_request_error_mapper.dart` — **Phase E** 6 error mapping methods for task requests
  - `viewmodels/task_requests_award_delegate.dart` — **Phase E** Award/payment/accept/cancel flows delegate
  - `services/task_deep_link_handler.dart` — **Phase E** Deep link handler for task routes
  - `view/widgets/task_concept_section.dart` — **Phase E** Extracted task concept section widget
  - `view/widgets/booking_logistics_section.dart` — **Phase E** Extracted booking logistics section widget
- `lib/features/wallet/`: wallet state and ledger-backed balance views; `utils/transaction_label_helper.dart` — human-readable transaction source/destination labels. Amber Dusk Phases 4 and 8 update wallet screen/dashboard card surfaces, localization labels, disabled action semantics, and accessibility labels without changing wallet data contracts or activating withdrawals. Transactional QA recovery makes withdraw unavailability intentional with a reason and preserves IQD display semantics.
  - `view/widgets/wallet_hero_card.dart` — **Phase E** Extracted wallet hero/balance card
  - `view/widgets/wallet_timeline_card.dart` — **Phase E** Extracted wallet transaction timeline card
- `lib/features/work/`: unified work item details and CTA resolution
  - `services/work_deep_link_handler.dart` — **Phase E** Deep link handler for work routes
  - `view/widgets/work_item_bottom_actions.dart` — **Phase E** Extracted work item bottom action bar
  - `view/widgets/work_item_booking_details.dart` — **Phase E** Extracted work item booking details section
  - `view/widgets/work_item_guard_widgets.dart` — **Phase E** Extracted work item guard/state widgets

## `test/` - Automated Test Layout

```text
test/
├── test_support/
├── fixtures/           # Test data fixtures
│   └── profiles.dart   # Role switching fixtures, JWT payloads, error responses
├── helpers/            # Test utilities and mocks
│   ├── helpers.dart             # Barrel file — re-exports all helpers
│   ├── mock_supabase.dart       # Mock Supabase client for unit testing
│   ├── mock_supabase_rpc.dart   # Mock RPC helper with chainable query support
│   ├── mock_services.dart       # Shared mock classes (8): MockWalletRepository, MockAccountGuardService, MockChatRepository, MockDirectOffersService, MockDashboardRepository, MockDashboardCacheService, MockBookingService, MockTaskService
│   ├── role_switch_helpers.dart # Role switch coordinator mock, simulator
│   └── ledger_rpc_invoker.dart  # Ledger RPC helpers for fee locking tests
├── rls/                # RLS policy security tests
│   ├── rls_test_helper.dart    # RLS assertion library (8 methods)
│   ├── fixtures/
│   │   └── rls_test_users.dart # Test user definitions (5 users)
│   ├── critical_blockers_test.dart  # 4 critical security tests (12 total)
│   ├── view_security_test.dart      # View security tests (7 tests)
│   └── role_switch_jwt_test.dart  # JWT policy tests (7 tests)
├── unit/
│   ├── auth/
│   │   ├── auth_repository_test.dart
│   │   ├── auth_session_view_model_test.dart  # Phase C: 32 tests (session lifecycle, auth stream, profile, logout, dispose)
│   │   └── auth_form_view_model_test.dart     # Phase E: auth form validation and submission tests
│   ├── booking/
│   ├── chat/
│   │   └── chat_view_model_test.dart          # Phase C: 21 tests (CRUD, messages, offers, realtime, role switch, dispose)
│   ├── categories/
│   │   └── categories_view_model_test.dart    # Phase E: categories loading, filtering, error handling
│   ├── core/
│   │   ├── sentry_crash_reporting_service_test.dart  # Phase D: 10 tests (construction, interface, safe methods, singleton)
│   │   ├── deep_link_registry_test.dart       # Phase E: registry, handler registration, route matching
│   │   └── models/
│   │       ├── view_state_test.dart            # Phase E: ViewState sealed class tests
│   │       └── app_failure_test.dart           # Phase E: AppFailure sealed class tests
│   ├── dashboard/
│   │   ├── dashboard_permission_service_test.dart
│   │   ├── dashboard_view_model_test.dart     # Phase C: 20 tests (role loading, role switch, refresh, lazy-loading, dispose)
│   │   ├── dashboard_work_delegate_test.dart  # Phase D: 10 tests (work items, caches, actions, dispose safety)
│   │   ├── dashboard_inbox_delegate_test.dart # Phase D: 8 tests (inbox state, grouping, reject, dispose safety)
│   │   └── dashboard_booking_delegate_test.dart # Phase D: 11 tests (bookings, filter, accept/decline/cancel)
│   ├── direct_offers/
│   │   └── direct_offer_details_view_model_test.dart  # Phase E: direct offer details, accept, pay, deliver
│   ├── home/
│   ├── management/
│   ├── models/                                # 14 test files (7 original + 7 new in Phase C)
│   ├── portfolio/
│   │   └── portfolio_view_model_test.dart     # Phase E: portfolio CRUD, reorder, error handling
│   ├── profile/
│   │   ├── role_switch_result_test.dart
│   │   ├── public_profile_view_model_test.dart  # Phase E: public profile loading, reviews, stats
│   │   └── user_profile_view_model_test.dart    # Phase E: user profile editing, avatar, settings
│   ├── proposals/
│   ├── saved/
│   │   └── saved_tasks_view_model_test.dart   # Phase E: saved tasks toggle, list, error handling
│   ├── safety/
│   │   ├── dispute_service_test.dart
│   │   └── safety_view_model_test.dart        # Phase E: safety/dispute view model tests
│   ├── search/
│   │   └── search_view_model_test.dart        # Phase E: search query, results, pagination
│   ├── services/
│   │   └── my_services_view_model_test.dart   # Phase E: my services CRUD, publish, error handling
│   ├── tasks/
│   │   ├── task_view_model_test.dart
│   │   ├── task_filter_view_model_test.dart
│   │   ├── tender_payment_coordinator_test.dart
│   │   └── tender_payment_view_model_test.dart  # Phase C: 53 tests (submit, WebView, recovery, error mapping, edge cases)
│   ├── viewmodels/           # Phase D: extracted ViewModel tests
│   │   ├── submit_request_view_model_test.dart    # Phase D: 15 tests (validate, replaceability, submit, replace, comparison)
│   │   └── requests_filter_view_model_test.dart   # Phase D: 15 tests (filter, count, awarding state, pagination)
│   ├── tender/               # Tender lifecycle unit tests
│   │   ├── award_expiration_monitor_test.dart
│   │   ├── task_requests_service_test.dart
│   │   └── task_requests_view_model_test.dart
│   ├── work/
│   │   └── work_item_details_view_model_test.dart  # Phase E: work item details, CTA, state transitions
│   └── wallet/
│       ├── ledger_service_test.dart
│       ├── wallet_presentation_helper_test.dart
│       ├── wallet_service_test.dart
│       └── wallet_view_model_test.dart          # Phase C: 36 tests (balance, dedup, pagination, withdrawal, errors)
└── widget/
    ├── app/
    ├── auth/
    ├── booking/
    ├── chat/
    ├── dashboard/
    ├── home/
    ├── management/
    ├── proposals/
    └── tasks/
```

Use `integration_test/` for device/browser flows that need platform navigation or full app boot.

## `assets/`

Current bundled asset folder:

- `assets/images/`

## Structure Rules

- Views do not call Supabase directly.
- Feature state lives in `viewmodels/`.
- Low-level DB/storage/network access lives in `services/` and `data/`.
- Shared UI and runtime helpers belong in `lib/core/`.
- `Sline_everything/` must be updated whenever structure or contracts change.

## Recent Structure-Sensitive Updates

- **Tender Task Lifecycle (v2.20, 2026-03-06):** New `lib/features/tasks/exceptions/offer_exceptions.dart` with `PriceMismatchException` and `OfferAlreadyAcceptedException`. New `lib/features/tasks/viewmodels/award_expiration_monitor.dart` for payment deadline countdown. New test folder `test/unit/tender/` with comprehensive unit tests. Database indexes `idx_task_requests_awarded_unpaid` and `idx_one_accepted_per_task`. RPCs: `award_task_offer`, `pay_awarded_offer`, `cleanup_expired_awards`. See migration `20260306_tender_guardrails.sql`.
- **Chat Creation Matrix (v2.19, 2026-03-06):** New atomic RPC path for conversation creation. `MessageService` now routes via feature flag (`enable_direct_conversation_rpc`). New RPC functions: `start_direct_conversation_v1`, `is_client`, `check_conversation_rate_limit`. Hardened guard trigger `conversations_before_insert_guard`. Updated UI call sites handle nullable `Conversation?` returns.
- **Role Switching (v2.18, 2026-03-06):** New `lib/core/services/role_switch_coordinator.dart`, `lib/core/mixins/role_switch_aware.dart`, `lib/features/profile/data/role_switch_repository.dart`. ViewModels implementing teardown contract: `ChatViewModel`, `DashboardViewModel`, `TaskViewModel`, `HomeViewModel`.
- **Chat Realtime Sync (08, 2026-03-08):** Presence table `conversation_presence`, typing indicator (15s TTL client-side), delivered/read receipts, feature flag `chat_presence_receipts_enabled`; `chat_realtime_merger.dart` + `chat_realtime_merger_test.dart`; ViewModel accumulation + debounced offer refresh.
- Chat feature includes `models/chat_offer_payload.dart` (canonical offer payload) and `services/chat_realtime_merger.dart` (realtime snapshot merge); archive uses RPC `archive_conversation_v1`. Inbox realtime: `subscribeToInboxMessages(userId)` (messages stream, not conversations); see diagram 18 and `.TODO/PLAN_RealtimeSubscriptionTopology_2026-03-07.md`.
- Booking flow now uses `payment_checkout_screen.dart`, `payment_webview_screen.dart`, and `payment_return_screen.dart` instead of older slot-sheet-only docs.
- Core runtime now includes `payment_runtime_config.dart`, `payment_pending_store.dart`, and `flutter_error_filters.dart`.
- Management now includes `work_log_scope.dart` and `view/widgets/order_management_section.dart`.
- Loading overlays use `LoadingHandle` from `lib/core/utils/loading_utils.dart`; the old dialog `show/hide` pattern is obsolete.
- Profile cross-user reads are centralized in `lib/features/profile/services/profile_summary_service.dart`; views and sibling features should not query another user from base `profiles`.
- Home, Tenders, and Booking discovery now share `lib/features/tasks/viewmodels/discovery_feed_view_model_contract.dart` as their feed API, while `home/viewmodels/home_view_model.dart` remains the concrete notifier.
- Discovery list rendering is shared in `lib/features/tasks/view/widgets/discovery_task_sliver.dart` and reused by Home, Tenders, and Booking discovery screens.
- `lib/features/home/view/widgets/service_card.dart` was removed as dead code during the home-feed refactor.
