# SLine App - Folder Structure Guide

**Last Updated:** 2026-03-08 (Direct Chat Offer Flow hardening migrations; 21_Wallet refs → Done)

This document describes the current repository layout. It replaces older references to `presentation/` and `controllers/`; the live Flutter codebase uses `view/` and `viewmodels/` under `lib/features/`.

## Top-Level Overview

```text
sline_app/
├── .agents/              # Local skills and workflows used by the coding agents
├── .cursor/              # Cursor agent definitions and project rules
├── .TODO/                # Audits, plans, execution logs, QA notes, docs-sync notes
├── Sline_everything/     # Source-of-truth project documentation
├── assets/               # Bundled app assets
├── lib/                  # Flutter application source
├── supabase/             # Edge functions and SQL migrations
├── test/                 # Unit and widget tests
├── integration_test/     # End-to-end test entrypoints
├── android/ ios/ web/    # Platform runners
├── linux/ macos/ windows/# Desktop runners
├── pubspec.yaml          # Flutter package manifest
└── README.md             # Repository overview
```

## Documentation and Agent Directories

### `.agents/`

- `skills/`: reusable local workflows such as `docs_sync`, `bug_fixer`, and `supabase_migration`
- `workflows/`: higher-order coordination docs such as `planner.md`, `executor.md`, and `orchestrator.md`

### `.cursor/`

- `Agents/`: role definitions such as `Architect`, `CodeGuard`, `Sline_Docs`, and `Supabase_Ops`
- project-specific agent guidance and rules used by Cursor tooling

### `.TODO/`

This folder is active working documentation, not archive-only material.

Typical files:

- feature audits: `management.TODO.md`
- plans: `PLAN_*.md`
- execution logs: `EXECUTION_LOG_*.md`
- review and QA artifacts: `CODEGUARD_REVIEW_*.md`, `SENTINEL_QA_*.md`
- docs sync notes: `DOCS_SYNC_*.md`

## `Sline_everything/` - Documentation Hub

Primary documents:

- `SUPABASE_SETUP.md`: database schema, RLS, RPCs, indexes, storage
- `DEVELOPER_GUIDE.md`: system map plus embedded feature references
- `DEVELOPER_GUIDE/`: feature-specific deep dives
- `STRUCTURE.md`: this file
- `MVP_ROADMAP.md`: current module status tracker
- `Sline_Log.md`: versioned project history and release notes
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
│   └── qicard_webhook_handler/     # QiCard webhook verification and ledger entry
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

## `lib/` - Flutter Application Source

```text
lib/
├── app/
│   └── main_navigation_screen.dart
├── core/
│   ├── config/
│   ├── models/
│   ├── providers/
│   ├── services/
│   ├── theme/
│   ├── utils/
│   └── widgets/
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
- `providers/`: app-wide providers such as navigation and theme mode
- `services/`: Supabase bootstrap, payment services, cache, deep links, crash reporting, logging, **role switch coordinator**
- `theme/`: color, spacing, typography, decorations, theme assembly, theme dashboard
- `utils/`: error mapping, formatting, loading overlays, URL cache, route transitions, web error filters, **ledger forensics** (p_meta session_id/request_id for ledger event flow)
- `widgets/`: shared UI widgets such as signed media, buttons, badges, loaders, bottom nav
- `mixins/`: shared behavior mixins such as `role_switch_aware.dart`

Important current core files:

- `lib/core/services/supabase_config.dart`
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

- `lib/features/auth/`: login, signup, forgot password, auth session handling
- `lib/features/booking/`: direct booking checkout, booking lists/details, payment return/webview screens
- `lib/features/profile/`: profile editing, avatar upload, **role switching (v2.18)**, portfolio management
  - `data/profile_repository.dart` — Main profile repository (legacy `changeRole()` deprecated)
  - `data/role_switch_repository.dart` — **NEW (v2.18)** Atomic role switching with RPC, session refresh, JWT verification
  - `models/role_switch_result.dart` — **NEW (v2.18)** RPC response model with error taxonomy
- `lib/features/chat/`: conversations, messages, attachments, realtime updates
- `lib/features/dashboard/`: unified dashboard tabs (Overview, Bookings, Work, Wallet, Inbox) and role-based work summaries, including the live bottom-nav dashboard slot. Tab cards (booking, offer, wallet snapshot) live in owning features: `booking/view/widgets/dashboard_booking_card.dart`, `tasks/view/widgets/dashboard_offer_card.dart`, `wallet/view/widgets/wallet_snapshot_card.dart`; dedicated Wallet tab in `view/tabs/wallet_tab.dart`; shared status helpers in `core/utils/status_presenter.dart`
- `lib/features/direct_offers/`: direct chat offers (create, accept, pay, deliver, complete) and payment recovery
- `lib/features/management/`: order timeline / note management for tasks and bookings
- `lib/features/orders/`: decommissioned placeholder folder with `README.md` only; standalone orders runtime was removed on 2026-03-01
- `lib/features/proposals/`: proposal models, data (repositories), routes (payment); view re-exports from tasks for list/submit/tile/payment screens
- `lib/features/tasks/`: task creation, details, requests/offers, tender payment, delivery flows
  - `exceptions/offer_exceptions.dart` — **NEW (v2.20)** Custom exceptions: `PriceMismatchException`, `OfferAlreadyAcceptedException`
  - `viewmodels/award_expiration_monitor.dart` — **NEW (v2.20)** Countdown timer for unpaid awards with urgency levels
- `lib/features/wallet/`: wallet state and ledger-backed balance views; `utils/transaction_label_helper.dart` — human-readable transaction source/destination labels
- `lib/features/work/`: unified work item details and CTA resolution

## `test/` - Automated Test Layout

```text
test/
├── test_support/
├── fixtures/           # Test data fixtures
│   └── profiles.dart   # Role switching fixtures, JWT payloads, error responses
├── helpers/            # Test utilities and mocks
│   ├── mock_supabase.dart      # Mock Supabase client for unit testing
│   └── role_switch_helpers.dart # Role switch coordinator mock, simulator
├── rls/                # RLS policy security tests
│   ├── rls_test_helper.dart    # RLS assertion library (8 methods)
│   ├── fixtures/
│   │   └── rls_test_users.dart # Test user definitions (5 users)
│   ├── critical_blockers_test.dart  # 4 critical security tests (12 total)
│   ├── view_security_test.dart      # View security tests (7 tests)
│   └── role_switch_jwt_test.dart  # JWT policy tests (7 tests)
├── unit/
│   ├── auth/
│   ├── booking/
│   ├── core/
│   ├── dashboard/
│   ├── home/
│   ├── management/
│   ├── models/
│   ├── profile/
│   │   └── role_switch_result_test.dart  # RoleSwitchResult model tests
│   ├── proposals/
│   ├── tasks/
│   └── tender/               # **NEW (v2.20)** Tender lifecycle unit tests
│       ├── award_expiration_monitor_test.dart  # Timer and urgency tests
│       ├── task_requests_service_test.dart      # Exception handling tests
│       └── task_requests_view_model_test.dart   # Flow logic tests
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
