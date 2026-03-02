# 📘 SLine App - Complete Development Log

**Last Updated:** 2026-03-02

---

## 🎯 Project Overview

**SLine** is a Flutter-based freelance marketplace application that connects clients with freelancers. The app enables users to post jobs, find freelancers, communicate, and manage projects through a modern mobile interface.

**Tech Stack:**

- **Frontend**: Flutter (Material Design 3)
- **Backend**: Supabase (BaaS - Backend as a Service)
- **State Management**: Provider with ChangeNotifier pattern
- **Authentication**: Supabase Auth (email/password)
- **Database**: PostgreSQL (via Supabase)
- **Storage**: Supabase Storage (for avatars, files)

---

## 📋 Version History

### 🟢 Version 2.17.0 — Direct Chat Offers (Accept-then-Pay, QiCard, Dashboard)

**Date:** 2026-03-02  
**Commit:** _Pending_ — "feat(direct_offers): accept-then-pay flow, QiCard gateway, dashboard pay, recovery, webview"

#### ✅ Implemented

- **Flow (Accept first, Pay from Dashboard)**
  - Chat: Client taps **Accept** only → `DirectOffersService.acceptOfferWithoutPayment(offerId)` → `direct_offers.status = 'accepted'`, `payment_status = 'unpaid'`; work_log entry; optional offer_accepted message.
  - Dashboard: Client sees work item as **Pending Payment**; taps **Pay & Confirm** → QiCard payment session (edge `qicard_payment_create_direct_offer`) → WebView (mobile) or browser (web); on return, `recoverPaymentAfterCallback` runs → ledger `escrow_hold` → `status = 'active'`, `payment_status = 'held'`.
  - Deliver/Complete unchanged: freelancer Mark Delivered → client Approve & release → `process_payment_event_ledger('release_with_fee', 'direct_offer', id)`.

- **App (lib/features/direct_offers/)**
  - `lib/features/direct_offers/services/direct_offers_service.dart`: `acceptOfferWithoutPayment`, `payNow(offerId)` (ledger escrow only), `recoverPaymentAfterCallback` (post-QiCard return).
  - `lib/features/direct_offers/view/direct_offer_details_screen.dart`: Detail screen with Cancel / Pay (QiCard); Open chat; Mark Delivered / Approve & release by role.
  - `lib/features/direct_offers/viewmodels/direct_offer_details_view_model.dart`: Load offer, createPaymentForCard, payNow, markDelivered, completeOffer; uses `AuthViewModel.currentUserId` (no Supabase in view).

- **Chat**
  - `lib/features/chat/viewmodels/chat_view_model.dart`: For direct offers (`offer_id` present), calls `acceptOfferWithoutPayment(offerId)` instead of acceptWithPayment; no payment in chat.
  - `lib/features/chat/view/widgets/offer_message_bubble.dart`: Button **Accept** (not "Accept & Pay") for direct offers; payment only from dashboard.

- **Dashboard**
  - `lib/features/dashboard/data/dashboard_repository.dart`: `_fetchDirectOffers` includes `status = 'accepted'`; map to `UnifiedWorkStatus.pendingPayment`, `primaryActionType = payEscrow` for client.
  - `lib/features/dashboard/viewmodels/dashboard_view_model.dart`: `performPrimaryAction` for directOffer + payEscrow calls `DirectOffersService.payNow(item.id)`; on web, opens payment in browser (no WebView).

- **Payment / Web**
  - `lib/features/booking/view/payment_webview_screen.dart`: Supports direct-offer return args (`offer_id`, `correlation_id`, `payment_request_id`); recovery delegates to `DirectOffersService.recoverPaymentAfterCallback`. On web: `webview_flutter_web` registered in `main.dart`; fallback `url_launcher` when WebView not implemented on platform.
  - `lib/core/utils/web_url_utils_web.dart`: Uses `package:web` for `clearPaymentReturnParamsFromUrl` (no `dart:html`).

- **Database (migrations)**
  - Guard: `fn_direct_offer_guard` allows `sent` → `accepted` with `payment_status = 'unpaid'`.
  - Ledger RPC: `escrow_hold` for `direct_offer` when `status IN ('sent','accepted')` and `payment_status = 'unpaid'`.
  - Ledger: `payment_event_type_enum` used for `journal_entries.event_type` (migration `20260307_fix_ledger_event_type_enum.sql`).

- **Observability / Cleanup**
  - Realtime payload guarded against non-map payload (avoids `payload[$_get] is not a function`). Debug instrumentation removed from `direct_offer_details_screen` and `lib/core/debug_session_log.dart` (if present).

#### 📊 Impact

- Direct offers follow Accept → Pending Payment (dashboard) → Pay (QiCard) → Active → Deliver → Complete. Payment happens only from dashboard; chat is gateway only. Client and freelancer both see work items in unified dashboard; freelancer can Submit Work, client can Approve & release.

#### 🧪 Verification

- Plan: `.TODO/` Direct Offer Accept-then-Pay plan; Direct_Chat_Offers.md.
- Flows: Accept in chat → item in dashboard Pending Payment; Pay & Confirm → QiCard → return → recovery → Active; Deliver → Approve → Completed.
- Web: Payment opens in browser; return URL cleared via `package:web`; no WebView platform errors.

#### 🔧 Technical Notes

- Edge functions: `qicard_payment_create_direct_offer`, `qicard_payment_recovery_direct_offer` (Supabase). Ledger RPC and guard in migrations 20260303–20260307. Rollback: revert app + migrations; feature is additive.

---

### 🟢 Version 2.16.9 — ChatFix (Archive RPC, Offer Payload, Realtime Merger)

**Date:** 2026-03-02  
**Commit:** _Pending_ — "feat(chat): server-side archive RPC, canonical offer payload, realtime merger, MessageType.system"

#### ✅ Implemented

- **Database (migration)**
  - `supabase/migrations/20260302_chat_archive_rpc_and_storage_helper.sql`: RPC `archive_conversation_v1(p_conversation_id)` for per-user server-timestamped archive; helper `can_access_chat_attachment(p_object_name, p_uid)` for participant-scoped storage; `deleted_at_user1` / `deleted_at_user2` on `conversations`.

- **Chat feature (lib/features/chat/)**
  - `lib/features/chat/models/message_model.dart`: snake_case wire for `message_type`; legacy read; added `MessageType.system` for DB enum parity.
  - `lib/features/chat/models/chat_offer_payload.dart`: canonical offer payload (`days` on write; legacy `delivery` read).
  - `lib/features/chat/services/chat_realtime_merger.dart`: merges realtime message snapshots (dedupe, sort).
  - `lib/features/chat/services/message_service.dart`: archive via RPC; `Stream<List<Message>>`; AppLogger on critical flows.
  - `lib/features/chat/data/chat_repository.dart`: `startDirectConversation`, `startTaskConversation`.
  - `lib/features/chat/view/chat_screen.dart`: offer creation uses `days` and `ChatOfferPayload`; accept/reject use `offer_accepted`/`offer_rejected`; user-safe error strings; offer button only for task-linked chats.

- **Docs and .TODO**
  - `Sline_everything/DEVELOPER_GUIDE/Chat Feature.md`, `Sline_everything/SUPABASE_SETUP.md`, `Sline_everything/STRUCTURE.md` updated. `.TODO/` plan, execution log, contract, test strategy, threat model, RLS matrix, rollout matrix, observability, and orchestrator reports (Architect, Observability, SlineDocs, CodeGuard, Master).

#### 📊 Impact

- Archive is server-authoritative; no client timestamp writes. Attachments remain participant-scoped via helper. Offer payload and realtime merge behavior are contract-aligned and documented.

#### 🧪 Verification

- Plan: `.TODO/PLAN_ChatFix_v2_2026-03-01.md`
- Execution Log: `.TODO/EXECUTION_LOG_PLAN_ChatFix_v2_2026-03-01.md`
- Review: `.TODO/CODEGUARD_REVIEW_2026-03-02_ChatFix.md`
- Master Report: `.TODO/MASTER_REPORT_2026-03-02_ChatFix.md`
- Tests: `test/unit/models/message_model_test.dart`, `test/widget/chat/`
- Check: `flutter analyze lib/features/chat`; manual archive and task-chat flows verified.

#### 🔧 Technical Notes

- Apply migration before using archive RPC. Rollback: revert app commits; DB migration is additive (RPC + helper + columns). See `.TODO/CHAT_ROLLOUT_MATRIX_2026-03-01.md`.

---

### 🟢 Version 2.16.8 — Portfolio Feature Recovery

**Date:** 2026-03-01  
**Commit:** _Pending_ — "fix(portfolio): implement signed URL image resolution and consolidate CRUD"

#### ✅ Implemented

- **Image Display Fixes**
  - Added `resolvePortfolioImageUrl()` to `lib/features/profile/data/profile_repository.dart`
  - Updated `lib/features/profile/viewmodels/profile_view_model.dart` to resolve image URLs in parallel using `Future.wait()`
  - Fixed `lib/features/profile/view/manage_portfolio_screen.dart` to pass `imagePath` through add flow
  - Fixed `lib/features/profile/view/widgets/public_profile/public_profile_portfolio.dart` to use `SignedImage` widget with `effectiveImageRef`
  - Enhanced `lib/core/widgets/signed_image.dart` with configurable bucket parameter

- **Data Model**
  - Canonical field: `image_path` (storage path like `ownerId/filename.jpg`)
  - Legacy fallback: `image_url` (public URL for backwards compatibility)
  - Resolution happens at ViewModel layer via `resolvePortfolioImageUrl()`

- **UI Fixes**
  - Fixed ScrollController attachment error in `lib/features/profile/view/public_profile_screen.dart` by adding separate controllers for each tab

#### 📊 Impact

- Portfolio images now display correctly in both Manage Portfolio and Public Profile views
- Consistent signed URL pattern across all private storage buckets
- Backwards compatible with legacy `image_url` data
- No more ScrollController errors when switching tabs

#### 🧪 Verification

- Plan: `.TODO/PLAN_ProtfolioFix_2026-03-01.md`
- Execution Log: `.TODO/EXECUTION_LOG_ProtfolioFix_2026-03-01.md`
- Contract: `.TODO/portfolio_contract_2026-03-01.md`
- Master Report: `.TODO/MASTER_REPORT_2026-03-01_PortfolioFix.md`

#### 🔧 Technical Notes

- Portfolio bucket remains public for backwards compatibility
- App uses signed URLs for security consistency with other buckets
- Two-step upload: `pickAndUploadPortfolioImage()` → `addPortfolioItem(imagePath: path)`
- Parallel URL resolution with `Future.wait()` for performance

---

### 🟢 Version 2.16.7 — Legacy Orders Dashboard Decommission

**Date:** 2026-03-01
**Commit:** _Pending_ — "refactor(dashboard): remove legacy orders module and sync docs"

#### ✅ Implemented

- **Runtime Cleanup**
  - Removed the unused app-root `OrdersViewModel` provider from `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/main.dart`.
  - Removed the dead standalone orders runtime under `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/` and kept a tombstone note at `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/README.md`.
  - Kept the active dashboard route on `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/dashboard/view/dashboard_screen.dart` and clarified in code comments that the bottom-nav still uses the legacy `NavView.orders` enum slot.
- **Tests**
  - Updated `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/app/main_navigation_screen_test.dart` so the legacy tab index is asserted as the dashboard screen, not the removed orders screen.
- **Docs Sync**
  - Updated `Sline_everything/DEVELOPER_GUIDE.md`, `Sline_everything/DEVELOPER_GUIDE/Orders Feature.md`, `Sline_everything/STRUCTURE.md`, `Sline_everything/MVP_ROADMAP.md`, and `.TODO/CodexRefactor/01_FEATURES_INDEX.md` to reflect the decommissioned module and the live dashboard contract.
  - Replaced `.TODO/CONTRACT_Orders_Runtime_2026-03-01.md` with a retirement note so it no longer claims `OrdersDashboardScreen` is live.
  - Stamped the legacy `.TODO/*orders*` audit, plan, review, observability, and pipeline files as historical/superseded so they no longer read like current runtime truth.

#### 📊 Impact

- The repo no longer carries an unused second dashboard implementation or its provider/test surface.
- The dashboard slot contract is now single-source: the app renders `DashboardScreen`, while the old `orders` module is explicitly retired.
- Current docs and feature inventory no longer point contributors toward dead runtime code.

#### 🧪 Verification

- Plan: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_OrdersFix_2026-03-01.md`
- Execution Log: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/EXECUTION_LOG_PLAN_OrdersFix_2026-03-01.md`
- Review: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/CODEGUARD_REVIEW_2026-03-01_orders.md`
- QA: `UNVERIFIED` for a dedicated Sentinel QA artifact; this decommission was verified with analyzer + targeted widget tests only.
- Docs Sync: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/DOCS_SYNC_2026-03-01_Orders_Dashboard_Decommission.md`
- Test: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/app/main_navigation_screen_test.dart`
- Test: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/dashboard/dashboard_screen_test.dart`
- Check: `flutter analyze`
- Check: `flutter test test/widget/app/main_navigation_screen_test.dart test/widget/dashboard/dashboard_screen_test.dart`

#### 🔧 Technical Notes

- `NavView.orders` remains in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/app_enums.dart` to avoid a broad enum rename during the cleanup.
- Historical `.TODO/` audit artifacts that discussed the removed module are left as snapshots; the authoritative current contract is now documented in `Sline_everything/` and the active feature index.
- Key code paths:
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/main.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/app/main_navigation_screen.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/app_enums.dart`
  - `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/dashboard/view/dashboard_screen.dart`
- Key DB objects:
  - none; this was a repo/runtime cleanup only and introduced no schema change.

### 🟢 Version 2.16.6 — Dashboard Review Ownership Sync & Work Detail CTA Clarification

**Date:** 2026-03-01
**Commit:** _Pending_ — "fix(work): gate review states by permissions and clarify delivered provider state"

#### ✅ Implemented

- **Dashboard Review Ownership**
  - Added explicit `actionableNeedsReview` and `awaitingCounterpartyReview` helpers in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/dashboard/models/work_item.dart`.
  - Updated `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/dashboard/data/dashboard_repository.dart` and `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/dashboard/viewmodels/dashboard_view_model.dart` so `Needs Review` counters, sections, and next-action priority only include items where the current role can actually review.
  - Updated `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/dashboard/view/tabs/work_tab.dart` and `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/dashboard/view/widgets/work_item_card.dart` so provider-side delivered items show `Awaiting Client Review` instead of being mislabeled as client-actionable.
- **Work Detail CTA Clarification**
  - Updated `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/work/view/work_item_details_screen.dart` so delivered provider-side items render `Waiting for Client Review` instead of a blank action area.
  - Added role/status telemetry in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/work/viewmodels/work_item_details_view_model.dart` to log `is_client`, `is_freelancer`, `needs_review`, and `can_review` on detail load.
- **Documentation Reference Fixes**
  - Corrected the Work module section in `Sline_everything/DEVELOPER_GUIDE.md` to include `review_delivery_modal.dart`, the live `UnifiedWorkStatus` values, and the current review ownership contract.
  - Added regression coverage in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/dashboard/work_tab_test.dart` and `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models/work_item_model_test.dart`.

#### 📊 Impact

- Freelancer/provider users no longer see `Needs Your Review` labels for work that only the client can approve.
- Delivered work detail pages no longer look broken when no provider-side approval action exists.
- Dashboard review counters and pinned sections now reflect actionable client work only.

#### 🧪 Verification

- Docs Sync: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/DOCS_SYNC_2026-03-01_Dashboard_Work_Review_Ownership.md`
- Tests: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/dashboard/work_tab_test.dart`
- Tests: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/models/work_item_model_test.dart`
- Check: `flutter analyze`

#### 🔧 Technical Notes

- `vw_unified_work_items.needs_review` remains a raw delivered-state signal from the database view; UI surfaces must combine it with role-derived permissions before showing review CTAs.
- This is an app-layer behavior correction. No new migration or Supabase object was introduced in this patch.

### 🟢 Version 2.16.5 — Home Feed Hardening, Safe Profile Summaries, and Discovery Contract Sync

**Date:** 2026-03-01
**Commit:** _Pending_ — "fix(home): harden discovery feed and deploy safe profile summary contract"

#### ✅ Implemented

- **Home Feed Contract**
  - Added seller-level support to `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/profile/models/profile_model.dart` and `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/models/task_model.dart`.
  - Stabilized discovery pagination in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_service.dart` and `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/home/viewmodels/home_view_model.dart` with a composite `created_at + id` cursor.
  - Added `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/widgets/discovery_task_sliver.dart` and shared it across Home, Tenders, and Booking discovery.
- **Security / RLS Boundary**
  - Added repo migrations for `seller_level`, `rpc_get_profile_summaries`, safe `search_profiles`, feed index, and Home-related RLS hardening under `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_*home*`.
  - Switched cross-user enrichment to `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/profile/services/profile_summary_service.dart`.
- **State + Observability**
  - Removed the duplicate Home-only saved-task provider from `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/home/view/home_screen.dart`.
  - Added structured feed/filter telemetry in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/home/viewmodels/home_view_model.dart` and `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/viewmodels/task_filter_view_model.dart`.
  - Added shared discovery feed contract `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/viewmodels/discovery_feed_view_model_contract.dart`.
- **Testing + Docs**
  - Added/updated targeted tests under `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/home/`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/unit/profile/`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/home/`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/tasks/`, and `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/widget/booking/`.
  - Synced `DEVELOPER_GUIDE.md`, `DEVELOPER_GUIDE/Home Feature.md`, `SUPABASE_SETUP.md`, `STRUCTURE.md`, and `MVP_ROADMAP.md`.

#### 📊 Impact

- Home discovery now relies on a least-privilege profile summary contract instead of direct cross-user `profiles` reads.
- Pagination is deterministic for same-timestamp rows.
- Advanced filters are functional and measurable.
- Tender and Booking discovery surfaces no longer depend on a Home-specific API contract.

#### 🧪 Verification

- Plan: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/home.TODO.md`
- Migration Plan: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/MIGRATION_HomeFeedSellerLevel_2026-03-01.md`
- Contract: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/CONTRACT_HomeFeedFilters_2026-03-01.md`
- RLS Matrix: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/RLS_HOME_MATRIX_2026-03-01.md`
- Review: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/CODEGUARD_REVIEW_2026-03-01_home.md`

#### 🔧 Technical Notes

- This release depends on the `20260301_*home*` Supabase migrations being applied before promotion.
- Home/Tenders/Bookings now share one discovery feed notifier instance via `DiscoveryFeedViewModelContract`.

### 🟢 Version 2.16.4 — Documentation Refresh and Reference Audit

**Date:** 2026-03-01
**Commit:** _Pending_ — "docs: refresh repo docs and fix stale references"

#### ✅ Implemented

- **Structure Documentation**
  - Rewrote `Sline_everything/STRUCTURE.md` to match the live repository tree, current feature layout, and active `supabase/` assets.
- **Developer Guide Sync**
  - Refreshed `Sline_everything/DEVELOPER_GUIDE.md` and the embedded Core/Auth/Booking sections to match the live codebase.
  - Rewrote:
    - `Sline_everything/DEVELOPER_GUIDE/Core Module.md`
    - `Sline_everything/DEVELOPER_GUIDE/Auth Feature.md`
    - `Sline_everything/DEVELOPER_GUIDE/Booking Feature.md`
- **Roadmap Cleanup**
  - Replaced duplicated historical roadmap blocks in `Sline_everything/MVP_ROADMAP.md` with a single current-state module matrix.
- **Historical Doc Guardrails**
  - Added historical-context notices to `Sline_everything/ARCHITECTURE_ANALYSIS.md`, `Sline_everything/CODE_REVIEW.md`, and `Sline_everything/COMPREHENSIVE_ANALYSIS_SUMMARY.md` so older references are not mistaken for live structure.

#### 📊 Impact

- Live documentation now matches the current `view/viewmodels/services/data/models` Flutter layout.
- Auth docs no longer point to deleted files.
- Booking docs now reflect the server-backed QiCard flow, web callback handling, and repeat slotless booking support.
- Supporting analysis docs are clearly framed as historical snapshots instead of live architecture references.

#### 🧪 Verification

- Docs Sync: `.TODO/DOCS_SYNC_2026-03-01_Repo_Documentation_Refresh.md`
- Reference Fix: `.TODO/DOCS_REFERENCE_FIX_2026-03-01_Repo_Documentation_Refresh.md`

#### 🔧 Technical Notes

- Historical release notes still mention removed files where appropriate; those entries remain as audit history.
- Live path validation for the refreshed doc set completed with no missing file references.

### 🟢 Version 2.16.3 — Repeat Slotless Booking Support & Create-Flow Correlation

**Date:** 2026-03-01
**Commit:** _Pending_ — "fix(booking): allow repeat slotless bookings and trace create attempts"

#### ✅ Implemented

- **Booking Draft Rule Update**
  - Removed the unique partial index `uq_bookings_active_task_client` for slotless direct bookings and replaced it with lookup index `idx_bookings_task_client_active`.
  - Updated `public.rpc_create_booking_draft_validated(...)` so the same client can create multiple slotless bookings for the same booking task.
  - Synced repo migration at `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_allow_multiple_slotless_bookings_per_client.sql`.
- **Booking Create Telemetry**
  - Added request-scoped correlation IDs across `BookingViewModel`, `QiCardPaymentService`, `PaymentCheckoutScreen`, and edge function `qicard_payment_create`.
  - Rejected draft-create attempts now keep a stable `request_correlation_id` even when no `booking_id` exists yet.
- **Client Copy Alignment**
  - Replaced stale fallback text in `BookingViewModel` that implied only one active booking per service was allowed.

#### 📊 Impact

- **Product Behavior**: Clients can place repeat slotless direct bookings for the same service task when they want multiple projects.
- **Supportability**: Failed booking-create attempts are now traceable across client and edge logs before a booking row exists.
- **Consistency**: Docs and runtime behavior align on the new slotless booking rule.

#### 🧪 Verification

- Execution Log: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/EXECUTION_LOG_2026-03-01_Booking_Repeat_Slotless_Booking.md`
- Master Report: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/MASTER_REPORT_2026-03-01_Booking_Repeat_Slotless_Booking.md`
- Review: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/CODEGUARD_REVIEW_2026-03-01_Booking_Repeat_Slotless_Booking.md`

#### 🔧 Technical Notes

- Slot exclusivity still applies to slot-based bookings.
- Repeat slotless booking support is a business-rule change, not an RLS change.

### 🟢 Version 2.16.2 — Payment Flow Polish & UI Themes

**Date:** 2026-02-24
**Agent:** @Architect, @Pixel, @CodeGuard
**Status:** ✅ Complete

#### ✅ Implemented

- **Payment Ledger & Booking Flow Logic**
  - **BookingService**: Fixed a query building immutability error in `listSlots` and added explicit error logging to `getPendingRequests`.
  - **WorkManagementService**: Delegated booking actions (`acceptBooking`, `declineBooking`, `cancelBooking`) to `BookingService` to ensure safe, atomic transitions involving escrow and ledger.
  - **BookingViewModel**: Enforced a `price` requirement for `bookSlot()`, eliminating hardcoded values. Added an isolated `_isContactingProvider` state.
- **Dependency Injection & MVVM Architecture**
  - Updated `main.dart` to inject `BookingRepository`, `ChatRepository`, and `PaymentService` into `BookingViewModel`.
  - Refitted `WorkItemDetailsViewModel` constructors to accept authenticated context through `AuthViewModel` in the view, removing direct DB access.
  - Mitigated a rebuild issue inside `PaymentCheckoutScreen` by replacing global `context.watch` with `context.read`.
- **Payment Configs & UI Alignment**
  - **QiCard**: Removed hardcoded sandbox credentials in `QiCardPaymentService`. Secure variables must now pass via `--dart-define`.
  - **Themes**: Removed hardcoded padding and color variables from `BookingSheet` mapping them directly to `AppDimens` and `colorScheme`. Applied strict color variables for `PaymentWebViewScreen` errors.

#### 📊 Impact

- **Reliability**: Eliminates rebuild performance leaks triggered by bad state dependencies.
- **Maintainability**: Full isolation from legacy Supabase clients in ViewModels.
- **Aesthetic**: The BookingSheet aligns completely with modern `AppTheme` context.

#### 🧪 Verification

- Docs Sync: `.TODO/DOCS_SYNC_2026-02-24_Booking_And_Payment_Fixes.md`
- Check: `flutter analyze` completed with 0 issues.

---

### 🟢 Version 2.16.1 — QiService Integration, Delivery RPC Fixes & Architecture Guard

**Date:** 2026-02-24
**Commit:** _Pending_ — "feat: QiCard payment flow, delivery RPC fixes, MVVM boundary enforcement"

#### ✅ Implemented

- **QiService (QiCard) Integration**
  - **Flow**: Draft booking → `initiatePayment()` → QiCard formUrl → WebView → deep-link `sline://payment/finish` or recovery polling → webhook sets `payment_status=held` via `gateway_escrow`.
  - **Backend**: `process_payment_event_ledger` extended with `gateway_escrow`; webhook handler `qicard_webhook_handler` (signature verification, SUCCESS → gateway_escrow).
  - **App**: `lib/core/services/qicard_payment_service.dart` (initiatePayment, default sandbox credentials); feature flag `USE_QICARD_PAYMENT`; `PaymentCheckoutScreen` and `PaymentWebViewScreen`; client-side recovery and orphan-draft cancellation.
- **Delivery RPC Fixes (DB)**
  - **rpc_submit_delivery**: Booking status transition fixed — `confirmed` or `paid_request_pending` now transition to `active` first, then to `delivered` (migration: `supabase/migrations/20260224_fix_rpc_submit_delivery_booking_transition.sql`).
  - **rpc_approve_delivery**: Uses `extensions.digest()` for idempotency key when `payment_status=held` before calling `process_payment_event_ledger('release_with_fee', ...)` (migration: `supabase/migrations/20260224_fix_rpc_approve_delivery_digest_schema.sql`).
- **Architecture Guard**
  - Views no longer call Supabase directly. App-level providers in `main.dart`: `Provider<SupabaseClient>`, `Provider<ProfileRepository>`, `Provider<CategoriesRepository>`.
  - **Task requests**: `TaskRequestsService.getExistingActiveOfferForCurrentUser`; `TaskRequestsViewModel.getExistingActiveOffer`; `SubmitRequestSheet` uses ViewModel only.
  - **Fixes**: `PublicProfileScreen`, `PortfolioScreen`, `CreateTaskScreen`, `SubmitRequestSheet` now obtain dependencies via `context.read<>()`.

#### 📊 Impact

- Real card payments (QiCard sandbox) flow end-to-end; ledger reflects gateway_escrow and release.
- Work delivery submit/approve works correctly for bookings in legacy or pay-first states; ledger release uses correct schema on Supabase.
- MVVM boundaries enforced; no direct Supabase/DB access in view layer.

#### 🧪 Verification

- Plan: `.TODO/PLAN_QiService_Integration_2026-02-24.md`
- Execution Log: `.TODO/EXECUTION_LOG_PLAN_QiService_Integration_2026-02-24.md`
- Architecture Guard: `.TODO/ARCHITECTURE_GUARD_REPORT_2026-02-24.md`
- Review: `.TODO/CODEGUARD_REVIEW_2026-02-24_Booking_Work_Payment.md`
- Technical debt follow-ups: `.TODO/TECHNICAL_DEBT.md`

#### 🔧 Technical Notes

- QiCard default credentials are sandbox; production must use `--dart-define` (see CodeGuard follow-ups).
- `rpc_approve_delivery` idempotency key: `encode(extensions.digest(entity_id::text || ':release_with_fee:' || now()::text, 'sha256'), 'hex')`.

---

### 🟢 Version 2.15.1 — Navigation & UI Polish (Hotfixes)

**Date:** 2026-02-22
**Agent:** @Architect, @Pixel, @SlineDocs
**Status:** ✅ Complete

#### ✅ Implemented

- **Navigation & Routing Fixes**
  - **Global State**: Promoted `DashboardViewModel` to the global `MultiProvider` in `main.dart` to fix `ProviderNotFoundException` when accessing dashboard state from `MyServicesScreen` and deep links.
  - **Chat Routing**: Fixed UI conditional logic in `WorkItemDetailsScreen` so that the "Message" button correctly appears for freelancers on active tasks, directly opening `ChatScreen` instead of dropping them in the generic Inbox.
- **Database Schema Patches**
  - **Profile History Query**: Removed obsolete column references (`title`, `location`, `verified`, `offers`) from the explicit `.select()` query in `ProfileRepository.getPublicProfile()`. This prevents the `42703` `PostgrestException` when navigating to a user's profile.
  - **Task Relations**: Updated the profile relation hint in the task history query from the legacy `tasks_user_id_fkey` to the modern `tasks_client_id_fkey` to prevent the `PGRST200` schema relation error.
- **UI Polish**
  - **Notification Indication**: Resolved duplicate notification bell icons. Merged the functional realtime `NotificationBadgeButton` directly into the `GlassContainer` header of `HomeScreen`.
  - **Cleanup**: Removed the floating, duplicate notification ring from `MainNavigationScreen` and eliminated unused imports.

#### 📊 Impact

- **UX**: Freelancers can now instantly directly message clients from the task details page.
- **Stability**: Deep linking and global access to the dashboard state no longer crash the app.
- **Polish**: The app header is cleaner with a single, functional, glassmorphic notification bell.

#### 🧪 Verification

- Execution Log: `.TODO/PLAN_NavChat_Fixes_2026-02-21.md`
- Docs Sync: `.TODO/DOCS_SYNC_2026-02-22_Navigation_And_UI_Fixes.md`

---

### 🟢 Version 2.15 — Profile Security & Observability Baseline

**Date:** 2026-02-19
**Agent:** @ThreatModeler, @Observability, @CodeGuard
**Status:** ✅ Complete

#### ✅ Implemented

- **Security Hardening (Profile Access)**
  - **Data Minimization**: `ProfileRepository.getPublicProfile` now strictly selects safe columns (`id, full_name, avatar_url, bio, active_role, skills, created_at, title, location, verified`). Eliminated `select(*)` risk.
  - **Efficient History**: Task history fetch is now server-side filtered for `completed`/`closed` status and limited to 20 items, preventing data leakage of active tasks.
  - **Threat Model**: Created `THREAT_MODEL_2026-02-19_ProfileAccess.md` identifying risks.

- **Booking Logic Fix**
  - **Bug Fix**: `UnifiedWorkItemModel` now correctly maps `paid_request_pending` status to `UnifiedWorkStatus.requestPending`.
  - **Impact**: Restored "Accept/Decline" buttons for Freelancers and "Cancel" for Clients on pending bookings.

- **Observability Baseline**
  - **Crash Reporting**: Implemented `CrashReportingService` abstraction (ready for Sentry/Firebase).
  - **Global Error Handling**: Wrapped app in `runZonedGuarded` to catch async errors.
  - **Logging**: Enforced `AppLogger` usage; audited and removed `print()` statements.

- **UI Refactoring**
  - **Public Profile**: Removed legacy `UserProfileScreen`.
  - **Navigation**: All profile links now use the `showProfilePreview` modal for a consistent, context-preserving experience.

#### 📊 Impact

- **Security**: PII leakage vectors in public profile fetching are closed.
- **Reliability**: App is now observable; uncaught exceptions are logged centrally.
- **UX**: Booking flow actions are restored; Profile navigation is unified.

#### 🧪 Verification

- Security Audit: `_TODO/CODEGUARD_REVIEW_2026-02-19_Profile_And_Booking_Fixes.md` (Verified)
- Threat Model: `_TODO/THREAT_MODEL_2026-02-19_ProfileAccess.md` (Verified)
- Observability Plan: `_TODO/OBSERVABILITY_PLAN_2026-02-19_Baseline.md` (Verified)

---

### 🟢 Version 2.14 — Work Delivery & Dashboard Optimization

**Date:** 2026-02-19
**Agent:** @Architect, @Observability, @ThreatModeler
**Status:** ✅ Complete

#### ✅ Implemented

- **Work Management: Delivery & Approval**
  - **Flow**: Freelancer submits delivery (`submitDelivery`) -> Client reviews -> Approve/Reject (`approveDelivery`, `requestRevision`).
  - **Audit**: Structured logging (`jsonPayload`) added to `WorkManagementService` for heavy ops.
  - **Security**: Threat Model analysis completed for delivery state transitions.
  - **UI**: Added `ReviewDeliveryModal` and `WorkItemDetailsScreen` approval logic.

- **Dashboard Architecture Optimization (F1-F9)**
  - **Data Flow**: Parallelized 6 independent fetches (`fetchWorkItems`, `fetchBookings`, etc.) using `Future.wait`.
  - **Performance**: Eliminated duplicate "Inbox Offers" query; cached `nextActions` computation (O(1) lookups).
  - **Structure**: Added Dependency Injection for `BookingService` in `DashboardViewModel`.
  - **Hygiene**: Removed stale comments; verified `flutter analyze` passes with 0 issues.

#### 📊 Impact

- **Performance**: Dashboard load time significantly reduced (parallel fetching).
- **Safety**: Delivery flow is now auditable and secured by RLS/RPC.
- **Maintainability**: Dashboard ViewModel is now testable via DI.

#### 🧪 Verification

- Architect Audit: `ARCHITECT_PATCH_2026-02-19_WorkManagement_Audit.md` (Verified)
- Optimization Report: `ARCHITECT_PATCH_2026-02-19_Dashboard_Optimization.md` (Verified)
- Observability Audit: `OBSERVABILITY_PATCH_2026-02-19_Dashboard_Audit.md` (Verified)

---

### 🟢 Version 2.13 — Freelancer Unified Flow

**Date:** 2026-02-16
**Agent:** @Architect, @Supabase_Ops, @CodeGuard
**Status:** ✅ Complete

#### ✅ Implemented

- **Database (3 tables, 1 view, 4 RPCs, 2 triggers)**
  - `work_contracts` table — versioned scope snapshots with RLS (SELECT)
  - `change_requests` table — scope/price/days change proposals with RLS (SELECT, INSERT)
  - `extension_requests` table — deadline extension proposals with RLS (SELECT, INSERT)
  - `vw_unified_work_items` view — UNION ALL of tasks + bookings with normalized statuses
  - `rpc_submit_delivery` — atomic delivery: status + timestamp + contract snapshot
  - `rpc_request_revision` — client revision with limit checks
  - `rpc_accept_change_request` — accept change with scope diffs + new contract version
  - `rpc_finalize_auto_approval` — auto-approve after review window (server-time)
  - `trg_activate_contract` — auto-create contract on booking confirmation
  - `trg_freeze_contract_fields` — block direct scope changes on active work
- **Flutter Module** (`lib/features/work/`)
  - `WorkManagementService` (316 lines) — single source of truth for all unified work queries
  - `WorkItemDetailsViewModel` (273 lines) — screen-scoped ChangeNotifier with parallel fetches
  - `WorkItemDetailsScreen` (502 lines) — 3-tab interface (Overview, Extensions, Contract)
  - `SubmitDeliveryModal` + `RequestExtensionModal` — bottom sheet modals
  - 4 models: `UnifiedWorkItemModel`, `WorkContractModel`, `ChangeRequestModel`, `ExtensionRequestModel`
  - 2 new enums in `app_enums.dart`: `WorkItemType`, `UnifiedWorkStatus`
- **Tests**
  - 7 ViewModel unit tests with `MockWorkManagementService` — all passing

#### 📊 Impact

- **UX**: Freelancers now have a unified view of all active work (tasks and bookings)
- **Trust**: Versioned contracts create accountability for scope changes
- **Safety**: State machine triggers prevent booking status bypass and unauthorized scope changes

#### 🧪 Verification

- Plan: `.TODO/PLAN_Freelancer_Unified_Flow_2026-02-16.md`
- Architect Patch: `.TODO/ARCHITECT_PATCH_2026-02-16_Unified_Flow.md`
- Review: `.TODO/CODEGUARD_REVIEW_2026-02-16_Freelancer_Unified_Flow.md`

#### 🔧 Technical Notes

- `declineBooking` uses `refunded` status (not `declined`) per `fn_booking_guard` transitions
- ViewModel uses fallback mapper when `vw_unified_work_items` view has refresh lag
- Provider is screen-scoped (not global) — each instance tied to a specific work item ID

---

### 🟢 Version 2.12 — Unified Profile & Search Polish (Phase 4)

**Date:** 2026-02-01
**Agent:** @Architect, @Pixel, @CodeGuard
**Status:** ✅ Complete

#### ✅ Implemented

- **Profile Refactor**
  - **Structure**: Converted to `NestedScrollView` with pinned `TabBar` (About, Portfolio, History, Reviews).
  - **History Tab**: Displays completed tasks/bookings with correct status ("Completed" vs "Expired").
  - **Navigation**: Added "Work History" shortcut menu item to navigate directly to the History tab.
- **Search Polish**
  - **UI**: Added empty states, improved gradient backgrounds, and refined `SearchResultProfileCard`.
  - **Avatars**: Switched to `SignedAvatar` for secure, cached profile images in search results.
  - **Logic**: Implemented batch fetching in `SearchService` to prevent N+1 queries during results enrichment.
- **Code Quality**
  - **Linting**: Fixed all lint errors in search module (relative imports, deprecations).
  - **Architecture**: Enforced MVVM pattern in Profile and Search features.

#### 📊 Impact

- **UX**: Profile feels like a complete professional identity with history and portfolio.
- **Performance**: Search results load efficiently without slamming the database for every profile/category.

---

### 🟢 Version 2.11 — Freelancer Wallet MVP (Phase 4)

**Date:** 2026-01-31
**Agent:** @Supabase_Ops, @Architect, @Pixel
**Status:** ✅ Complete

#### ✅ Implemented

- **Wallet Dashboard**
  - **Database**: Created secure view `wallet_balances` to aggregate `released` vs `held` funds.
  - **Logic**: Updated `WalletService` to use the view for accurate "Net Worth" calculation.
  - **UI**: Updated `WalletScreen` with split balance cards (Teal for Available, Amber for Escrow) and clear transaction history.

#### 📊 Impact

- **Financial Clarity**: Zero ambiguity between "money I have" and "money coming soon".
- **Security**: Aggregation logic moved to database layer (View) prevents client-side math errors.

---

### 🟢 Version 2.10 — Unified Management System (Phase 1)

**Date:** 2026-01-31
**Agent:** @Architect, @Supabase_Ops, @Pixel
**Status:** ✅ Complete

#### ✅ Implemented

- **Unified Management & Notes**
  - **Database**: Created `work_logs` table for immutable notes/events with RLS.
  - **Logic**: Implemented `OrderManagementViewModel` to manage private notes and timeline events.
  - **UI**: Added generic `OrderManagementPanel` widget (Glassmorphic) for centralized order tracking.
  - **Integration**: Embedded panel into `BookingDetailsScreen` and `TaskDetailsScreen`.

#### 📊 Impact

- **Truth**: Single source of truth for "what happened" on an order.
- **Privacy**: Private notes allow users to keep personal records without sharing.
- **Consistency**: Unified UI for both Task and Booking management.

#### 🔧 Technical Notes

- **Polymorphic Relation**: `work_logs` links to either `tasks` or `bookings` via `related_entity_id`/`type`.
- **Helper Function**: `is_work_log_participant` DB function simplifies RLS logic for shared logs.

---

### 🟢 Version 2.9 — Phase 1: Pay-First Booking Flow & Wallet

**Date:** 2026-01-31
**Agent:** @Supabase_Ops, @Architect, @Pixel
**Status:** ✅ Complete

#### ✅ Implemented

- **Booking Flow v2 ("Pay-First")**
  - **Database**: Updated `booking_status_enum` with detailed lifecycle (`pending` → `paid_request_pending` → `active` → `delivered` → `completed`).
  - **Security**: Updated `fn_booking_guard` trigger to strictly enforce these transitions.
  - **Logic**: Implemented `BookingService` methods to handle simulated payment (Escrow), Provider Acceptance (Active), and Completion (Release).
- **Wallet System Foundation**
  - **Database**: Created `wallet_transactions` table with RLS Policies.
  - **Backend**: Implemented `process_payment_event` RPC to handle atomic Escrow/Release/Refund transactions.
  - **UI**: Added `WalletScreen` displaying transaction history and balance.
  - **Logic**: Added `WalletViewModel` to fetch and display financial data.
- **UI & UX**
  - **Booking**: Updated `BookingSheet` to simulate payment process before booking confirmation.
  - **Details**: `BookingDetailsScreen` now shows context-aware banners and buttons for every status (e.g., "Mark Delivered", "Release Funds").

#### 📊 Impact

- **Trust & Safety**: Funds are now logically "held" in escrow (simulated) before work starts.
- **Clarity**: Both parties see the exact state of the booking (Paid Request, Active, Delivered).
- **Architecture**: Solid foundation for integrating real payment gateways (Stripe) in Phase 2.

#### 🔧 Technical Notes

- **RPC Usage**: Use `process_payment_event` for all financial state changes to ensure atomicity.
- **Status Mapping**: Dart `BookingStatus` enum mapped precisely to DB strings (e.g., `paidRequestPending` -> `paid_request_pending`).

---

### 🟢 Version 2.8.3 — Open Messaging & Profile Previews

**Date:** 2026-01-19
**Agent:** @Architect, @CodeGuard
**Status:** ✅ Complete

#### ✅ Implemented

- **Open Direct Messaging**
  - **Restriction Removed**: Users no longer need to "Favorite" a profile before messaging them.
  - **Backend**: Updated `conversations_before_insert_guard` trigger to allow non-task-linked DM creation.
  - **Error Handling**: Removed `P0001` error catching in `PublicProfileScreen`.
- **Public Profile Preview**
  - **Feature**: View a freelancer's public profile (Bio, Skills, Portfolio) via a modal without leaving the current screen.
  - **UI**: Added `showProfilePreview` modal logic.
  - **Component**: Refactored `PublicProfileScreen` into modular widgets (`PublicProfileHeader`, `PublicProfileStats`, etc.).
- **Code Refactoring & Stability**
  - **Fixes**: Resolved `taskId` nullability crash in `Conversation` model for DMs.
  - **Refactor**: Created reusable `CircleIconButton` widget.
  - **Audit**: CodeGuard audit passed for performance and security.

#### 📊 Impact

- **UX**: Frictionless communication—users can reach out to freelancers immediately.
- **Engagement**: Profile previews encourage exploration without navigating away from tasks/bookings.
- **Maintainability**: Cleaner, more modular profile code.

#### 🔧 Technical Notes

- `Conversation.taskId` is now nullable (`String?`) to correctly model Direct Messages.
- **Security Note**: Open messaging increases potential for spam; monitoring recommended.

---

### 🟢 Version 2.8 — Booking Packages & Payment UI

**Date:** 2026-01-11
**Agent:** @Architect, @SlineDocs
**Status:** ✅ Complete

---

### 🟢 Version 2.8.2 — Chat UX & Context Integration (Polish)

**Date:** 2026-01-12
**Agent:** @Pixel, @CodeGuard
**Status:** ✅ Complete

#### ✅ Implemented

- **Chat Context Improvements**
  - **`ChatContextWidget`**: Redesigned using `GlassContainer` for dark/light mode consistency (Gold/Teal accents).
  - **Navigation**: Added interaction handler to context banner → fetches Task → navigates to `TaskDetailsScreen`.
  - **List View**: Added "Task Context" row (Icon + Title) to `ConversationListTile` for at-a-glance context.
- **UX Responsiveness (Loading States)**
  - Created `LoadingUtils` (blocking overlay) to provide immediate visual feedback during async navigation.
  - Applied `LoadingUtils` to:
    - Chat Context banner tap.
    - Task Details "Message" button tap.
  - Eliminates "frozen UI" perception on slow networks.
- **Data Exposure**
  - Updated `TaskViewModel` & `TaskRepository` to expose direct `getTaskById` for navigation support.

#### 📊 Impact

- **UX**: Chat feels deeply integrated rather than isolated. Users navigate fluidly between Talk and Task.
- **Polish**: Glassmorphism extends to chat context, matching the app's premium aesthetic.
- **Performance**: Blocking loaders prevent race conditions and improve perceived responsiveness.

#### 🗂️ Files Touched

- **New:** `lib/core/utils/loading_utils.dart`
- **Modified:** `lib/features/chat/view/widgets/chat_context_widget.dart`, `lib/features/chat/view/widgets/conversation_list_tile.dart`, `lib/features/tasks/view/task_details_screen.dart`, `lib/features/tasks/viewmodels/task_view_model.dart`

#### ✅ Implemented

- **Booking Packages System**
  - Updated `tasks` table with `packages` jsonb column (Basic/Standard/Premium tiers).
  - Implemented `CreateTaskScreen` package editor with price, description, delivery time, and revisions.
  - Updated `BookingSheet` to support package selection and tier-based pricing.
  - Implemented `package_tier` logic ensuring bookings carry specific package data.

- **Payment Infrastructure (Demo)**
  - Created `PaymentService` abstract class for dependency injection.
  - Implemented `DemoPaymentService` for mock credit card processing (2-second delay simulation).
  - Created `PaymentMethodScreen` with Glassmorphism UI (Card Holder, Number, Expiry, CVV).
  - Integrated payment flow into `BookingSheet`: Select Package -> Add Note -> Enter Payment -> Confirm Booking.

- **Sentinel Workflow Optimization**
  - Refined Sentinel's role to focus on QA, Security, and Documentation.
  - Removed mandatory unit/widget testing requirements to streamline velocity.
  - Removed outdated test files (`booking_view_model_test.dart`).

#### 📊 Impact

- **Revenue Ready**: The app now supports the full "Order" lifecycle with tiered pricing.
- **UX**: Seamless transition from "Select Slot" to "Pay & Book".
- **Developer Experience**: Sentinel workflow is now leaner and more focused on high-level verification.

#### 🗂️ Files Touched

- **New Features:** `lib/features/booking/view/payment_method_screen.dart`, `lib/core/services/payment_service.dart`
- **Modified:** `lib/features/booking/viewmodels/booking_view_model.dart`, `lib/features/booking/view/booking_sheet.dart`, `lib/features/tasks/view/create_task_screen.dart`
- **Documentation:** `.agent/workflows/sentinel.md`, `Sline_Log.md`, `MVP_ROADMAP.md`

#### 🔧 Technical Notes

- `packages` column in `tasks` stores JSON: `{ "basic": {...}, "standard": {...}, "premium": {...} }`.
- Payment Service is designed for easy swap with Stripe/Paddle implementations later.
- `BookingViewModel` refactored to support DI for `PaymentService`.

---

### 🟢 Version 2.7.2 — UI Polish: Skeleton Loading & Tab Transitions

**Date:** 2026-01-02
**Agent:** @Pixel, @CodeGuard
**Status:** ✅ Complete

#### ✅ Implemented

- **Skeleton Loading States**
  - Created `lib/core/widgets/skeleton_loader.dart` — Reusable shimmer animation base with `SkeletonLoader`, `SkeletonText`, `SkeletonAvatar`.
  - Created `lib/core/widgets/skeleton_card.dart` — Pre-built skeleton cards:
    - `SkeletonTaskCard`: Matches `TenderTaskCard` layout (left accent bar, date, title, description, footer).
    - `SkeletonBookingCard`: Matches `BookingTaskCard` layout (header gradient, overlapping avatar, rating pill, tags, price + button).
    - `SkeletonOfferCard`, `SkeletonConversationTile`, `SkeletonDetailsScreen`.
  - Integrated skeleton loading in:
    - `home_screen.dart` — 5 skeleton cards on initial load.
    - `tenders_screen.dart` — Uses `Consumer2` with `HomeViewModel.isLoading`.
    - `bookings_discovery_screen.dart` — Uses `SkeletonBookingCard`.
    - `requests_list_screen.dart`, `messages_screen.dart`, `bookings_list_screen.dart`.

- **Smooth Tab Transitions**
  - Updated `main_navigation_screen.dart` — Replaced `IndexedStack` with `AnimatedSwitcher` for fade transitions (250ms, `Curves.easeInOut`).

- **Layout Fixes**
  - Fixed `task_details_screen.dart` — Refactored to `Column` layout (Header + Scrollable Content + Footer) for correct bottom bar positioning.

#### 📊 Impact

- **UX**: Loading states now show content-shaped placeholders instead of generic spinners, reducing perceived load time.
- **Polish**: Tab transitions feel smoother and more premium.
- **Stability**: Detail screen layouts now correctly anchor bottom bars.

#### 🗂️ Files Touched

- **New:** `lib/core/widgets/skeleton_loader.dart`, `lib/core/widgets/skeleton_card.dart`
- **Modified:** `home_screen.dart`, `tenders_screen.dart`, `bookings_discovery_screen.dart`, `main_navigation_screen.dart`, `task_details_screen.dart`, `requests_list_screen.dart`, `messages_screen.dart`, `bookings_list_screen.dart`

#### 🔧 Technical Notes

- Skeleton cards use theme-aware colors (`colorScheme.cardBackground`, `colorScheme.divider`) for automatic dark/light mode support.
- `AnimatedSwitcher` uses `KeyedSubtree` with `ValueKey<int>` to trigger transitions on index change.
- Skeleton animations use `AnimationController` with `AutomaticKeepAliveClientMixin` for smooth shimmer effects.

---

### 🔧 Version 2.7.1 — CodeGuard Maintenance Audit

**Date:** 2025-12-19
**Agent:** @CodeGuard
**Status:** ✅ Passed

#### ✅ Maintenance Updates

- **Lint Fixes**: Resolved `curly_braces_in_flow_control_structures` in 4 files (`booking_view_model.dart`, `message_model.dart`, etc).
- **Formatting**: Applied `dart format .` to 142 files.
- **Analysis**: `flutter analyze` is now clean (0 issues).

#### ⚠️ Dependency Audit

- **Critical**: `supabase_flutter` needs update (1.10.x -> 2.12.x). High risk.
- **Warning**: `js` package is discontinued (transitive dependency).

---

### 🟢 Version 2.7 — Notification System End-to-End

**Date:** 2025-12-19
**Commit:** _Pending_ — "feat(notifications): Realtime notifications system, TaskStatus enum expansion, and UI integration"

#### ✅ Implemented

- **Notification System Core**
  - Database: `notifications` table + RLS policies (insert_any, select_own, update_own).
  - Service: `NotificationService` for realtime listening, fetching, and "mark as read".
  - State: `NotificationViewModel` with badge count tracking.
- **Task Notifications**
  - Logic: Notifications triggered for Task Completion (`TaskStatus.closed`) and Cancellation (`TaskStatus.canceled`).
  - Integration: `TaskService` now notifies relevant parties (Owner ↔ Freelancer).
- **UI Enhancements**
  - `NotificationBadgeButton`: Realtime unread count indicator in app bar.
  - `Tasks` Models & Widgets: Added `canceled` status to `TaskStatus` enum.
  - `ServiceCard` & `OrderCard`: UI support for `TaskStatus.canceled` (Gray theme).

#### 📊 Impact

- **Engagement**: Users are instantly notified of critical task events.
- **Completeness**: Handling of 'Cancellation' and 'Completion' closes the task lifecycle loop.
- **Robustness**: Enum alignment prevents runtime errors with database status values.

#### 🔧 Technical Notes

- `notifications` table uses Realtime subscription for instant badge updates.
- `TaskService` performs a pre-fetch before status updates to determine the correct recipient ID.
- `TaskStatus` enum now fully matches Supabase constraints (`open`, `assigned`, `in_progress`, `closed`, `canceled`).

---

### 🟢 Version 2.6 — Forgot Password Flow

**Date:** 2025-12-17
**Commit:** _Pending_ — "feat(auth): forgot password flow with glassmorphism UI"

#### ✅ Implemented

- **Forgot Password UI**
  - Created `ForgotPasswordScreen` with matching Glassmorphism design.
  - Added "Forgot Password?" button to `LoginScreen` with navigation.
- **Backend Logic**
  - Updated `AuthRepository` to wrap `resetPasswordForEmail`.
  - Updated `AuthViewModel` with `resetPassword` method and error mapping.

#### 📊 Impact

- **UX**: Users can now self-serve password recovery vs. getting stuck.
- **Completeness**: Closes a critical gap in the authentication lifecycle.

#### 🔧 Technical Notes

- Uses Supabase's built-in email recovery flow.
- Deep linking is handled by the OS/Supabase default for now; app just triggers the email.

### 🟢 Version 2.5 — Saved Projects Feature Fix & Optimization

**Date:** 2025-12-17
**Commit:** _Pending_ — "feat(saved): global state, UI toggles, profile badge optimization"

#### ✅ Implemented

- **Global Saved Tasks State**
  - Promoted `SavedTasksViewModel` to a global provider in `main.dart`.
  - Added `_initAuthListener` to automatically load/clear tasks on login/logout.
  - Ensures bookmark state is consistent across Home, Search, and Profile screens.

- **Saved Projects UI**
  - **Profile Screen**: Added "Saved Projects" menu item with live counter badge.
  - **Optimization**: Used `Selector` for the badge to preventing full-screen rebuilds on toggle.
  - **Task Cards**: Added bookmark (heart) icon to `TenderTaskCard` and `BookingTaskCard` header.
  - **Saved Screen**: `SavedTasksScreen` now consumes the global ViewModel.

- **Critical Bug Fix (PGRST200)**
  - **Issue**: "Unknown User" and app crash due to missing foreign key relationship between `saved_tasks` and `profiles` via `tasks` table.
  - **Fix**: Updated `SavedTasksService.listMineWithDetails` to perform a robust 2-step fetch:
    1. Fetch saved tasks.
    2. Extract user IDs and fetch profiles in a batch.
    3. Merge profile data (name/avatar) into Task objects manually.
  - **Result**: Eliminates schema dependency risks and ensures author data always loads.

#### 📊 Impact

- **UX**: Users can bookmark tasks instantly from any card; state reflects immediately.
- **Performance**: Zero-rebuild updates for the Profile screen badge.
- **Stability**: Database schema looseness no longer causes "Unknown User" crashes.

#### 🗂️ Files Touched

- **Modified:**
  - `lib/features/saved/viewmodels/saved_tasks_view_model.dart` (Auth listener)
  - `lib/features/saved/data/saved_tasks_service.dart` (Manual join fix)
  - `lib/features/profile/view/profile_screen.dart` (Selector optimization)
  - `lib/features/tasks/view/widgets/tender_task_card.dart` (Toggle UI)
  - `lib/features/tasks/view/widgets/booking_task_card.dart` (Toggle UI)
  - `lib/main.dart` (Global provider)

#### 🔧 Technical Notes

- `SavedTasksService` manual join pattern works around the missing `tasks.user_id` FK reference in the generated Postgrest client, preventing `PGRST200` errors.

#### 🔜 Next

- **Localization**: RTL support.

### 🟢 Version 2.4 — Portfolio Management & iOS Stability

**Date:** 2025-12-16
**Commit:** _Pending_ — "feat(profile): Portfolio CRUD, FilePicker migration, iOS crash fix"

#### ✅ Implemented

- **Portfolio Management Feature**
  - Added `ManagePortfolioScreen` accessible from Settings with full CRUD operations
  - Added `addPortfolioItem`, `updatePortfolioItem`, `deletePortfolioItem`, `uploadPortfolioImage` methods to `ProfileRepository`
  - Added portfolio state management (`portfolioItems`, `isLoadingPortfolio`, `fetchPortfolio`) to `ProfileViewModel`
  - Portfolio items display in `ProfileScreen` using `SignedImage` with `bucket: 'portfolio'`
  - Navigation tile added to `SettingsScreen` for portfolio management

- **iOS Crash Fix** (CRITICAL)
  - **Root cause**: `SignedImage` widget rendering immediately after upload triggered native iOS memory/timing crash
  - **Fix**: Replaced in-dialog image preview with success checkmark indicator
  - **Migration**: Replaced `ImagePicker` with `FilePicker` in `ProfileViewModel` for better iOS stability
  - **Compression**: Added `FlutterImageCompress` for image resizing (max 1920px, 80% quality)

- **macOS Permissions Fixes**
  - Added `NSPhotoLibraryUsageDescription` and `NSCameraUsageDescription` to `macos/Runner/Info.plist`
  - Added `com.apple.security.files.user-selected.read-only` and `com.apple.security.network.client` to macOS entitlements

- **SignedImage Memory Optimization**
  - Added `memCacheWidth` and `memCacheHeight` to `CachedNetworkImage` to decode images at display size only
  - Prevents OOM crashes when rendering large images on iOS

#### 📊 Impact

- Freelancers can now manage portfolio items (add, edit, delete with images)
- iOS upload stability significantly improved (no more native crashes)
- Reduced memory footprint for image rendering across app

#### 🗂️ Files Touched

- **New:**
  - `lib/features/profile/view/manage_portfolio_screen.dart`
- **Modified:**
  - `lib/features/profile/data/profile_repository.dart` (portfolio CRUD + upload)
  - `lib/features/profile/viewmodels/profile_view_model.dart` (FilePicker, portfolio state)
  - `lib/features/profile/view/settings_screen.dart` (navigation to portfolio)
  - `lib/features/profile/view/profile_screen.dart` (portfolio display)
  - `lib/core/widgets/signed_image.dart` (bucket param, memCache optimization)
  - `macos/Runner/Info.plist` (permissions)
  - `macos/Runner/DebugProfile.entitlements` (file/network access)
  - `macos/Runner/Release.entitlements` (file/network access)

#### 🔧 Technical Notes

- `FilePicker` uses `UIDocumentPickerViewController` on iOS instead of `PHPicker`, avoiding `WFIsolatedShortcutRunner` crash
- Dialog now shows checkmark after upload; image renders in portfolio list view (not immediately in dialog)
- Storage bucket `portfolio` uses private access with signed URLs (2hr TTL)

#### 🔜 Next

- Profile Skills management (add/remove skills tags)
- Enhanced portfolio item details view

### 🟢 Version 2.3 — Phase 2: Orders Dashboard & Task Card Differentiation

**Date:** 2025-12-14
**Commit:** _Pending_ — "feat(orders): Orders dashboard, Tender/Booking cards, offer management"

#### ✅ Implemented

- **Phase 2.1: Tender vs Booking Cards** (UI/UX)
  - Created specialized `TenderTaskCard`: Coral theme, author info, offer count, deadline countdown.
  - Created specialized `BookingTaskCard`: Teal theme, provider info, availability status.
  - Updated `TaskCard` to dynamically delegate to the correct widget based on `task.taskType`.
  - Added visual cues (icons, badges) to clearly distinguish task types.

- **Phase 2.2: Orders Dashboard Overhaul** (Client View)
  - Implemented `OrdersDashboardScreen` to manage published tasks.
  - Features:
    - **Status Tabs**: Open, In Progress, Completed, Cancelled.
    - **Offer Management**: View offers in `OfferListSheet`, accept/reject bids.
    - **Task Management**: Edit and Delete actions via `OrderCard` menu.
  - Architecture: Added `OrdersViewModel` and `OrdersService` (aggregating Task/Request services).

- **Critical Bug Fixes** (Stability)
  - **Fixed PGRST204 Crash**: Removed `packages` and `offers` fields from `Task.toJson` updates, as these columns do not yet exist in the DB or are computed.
  - **Task Editing Fix**: Updated `CreateTaskScreen` to properly handle category selection (UUID vs legacy Name) to prevent `22P02` invalid input syntax errors.
  - **Offer List Crash**: Fixed `RangeError` in `OfferListSheet` when bidder name is empty.

#### 📊 Impact

- **UX**: Clients can now fully manage their task lifecycle (Post -> Review Offers -> Assign -> Complete).
- **Clarity**: Distinct visual languages for Tenders vs Bookings help users understand context immediately.
- **Stability**: Resolved blocking crashes in the "Create/Edit Task" flow.

#### 🗂️ Files Touched

- **New Features:**
  - `lib/features/orders/` (entire module: view, viewmodels, services, widgets)
  - `lib/features/tasks/view/widgets/tender_task_card.dart`
  - `lib/features/tasks/view/widgets/booking_task_card.dart`
- **Modified:**
  - `lib/features/tasks/models/task_model.dart` (removed problematic fields from toJson)
  - `lib/features/tasks/view/create_task_screen.dart` (fixed update logic)
  - `lib/features/tasks/view/widgets/task_card.dart` (delegation logic)
  - `lib/features/tasks/services/task_requests_service.dart` (added profile join)

#### 🔧 Technical Notes

- `TaskRequest` model updated to include `bidderName` and `bidderAvatar` from joined profile data to avoid N+1 queries in the offer list.
- `OrderCard` uses `PopupMenuButton` for Edit/Delete actions.

#### 🔜 Next

- **Phase 2.3**: Chat System Overhaul
- **Phase 2.4**: Profile Screen Enhancement

---

### 🟢 Version 2.2 — Phase 1 Foundation: Performance, Error Handling & Session Management

**Date:** 2025-12-14
**Commit:** _Pending_ — "feat(core): Phase 1 foundation - performance, error handling, session management"

#### ✅ Implemented

- **Phase 1.1: Task Card Image Display** (BUG FIX)
  - Updated `lib/features/tasks/view/widgets/task_card.dart` to display task images using `SignedImage` widget
  - Added conditional rendering: shows task image when `task.imagePaths` is not empty, falls back to colored header
  - Proper gradient overlay and placeholder sizing for loading/error states

- **Phase 1.2: App Performance Optimization**
  - Added `cached_network_image: ^3.4.1` to `pubspec.yaml` for image disk/memory caching
  - Updated `lib/core/widgets/signed_image.dart` to use `CachedNetworkImage` - reduced network calls on subsequent loads
  - Updated `lib/core/widgets/signed_avatar.dart` to use `CachedNetworkImage` and `CachedNetworkImageProvider`
  - Implemented cursor-based pagination in `lib/features/tasks/services/task_service.dart` via `getOpenTasksForHome(limit, cursorCreatedAtIso)`
  - Updated `lib/features/home/viewmodels/home_view_model.dart` with `loadMoreTasks()` for infinite scroll, pagination state (`_cursor`, `_hasMore`, `_isLoadingMore`)
  - Optimized `lib/features/tasks/viewmodels/task_view_model.dart` to minimize redundant `notifyListeners()` calls

- **Phase 1.3: Supabase Connection Verification** (AUDIT)
  - Created `lib/core/utils/error_mapper.dart` - centralized error-to-user-message mapping following `.cursor/rules/error-handling.mdc`
  - Updated `lib/features/tasks/services/task_service.dart` with proper `PostgrestException` handling and `ErrorMapper.map()` for all methods
  - Enhanced `lib/features/tasks/services/task_image_service.dart` with:
    - Authentication validation before upload
    - User-friendly error messages for storage errors
    - Added `deleteImage()` method for cleanup
    - Proper logging with `[TaskImages]` tag
  - Implemented session expiry handling in `lib/features/auth/viewmodels/auth_view_model.dart`:
    - Added Supabase auth state listener (`onAuthStateChange`)
    - Added `onSessionExpired` callback with pending queue to prevent race conditions
    - Proper subscription cleanup in `dispose()`
  - Updated `lib/main.dart` with `_AppWithAuthListener` wrapper for session expiry navigation

#### 📊 Impact

- **Performance**: Image caching reduces network calls significantly; cursor pagination prevents loading all tasks at once
- **UX**: User-friendly error messages instead of technical exceptions
- **Reliability**: Session expiry properly detected and handled with redirect to login
- **Maintainability**: Centralized `ErrorMapper` utility for consistent error handling

#### 🗂️ Files Touched

- **New Files:**
  - `lib/core/utils/error_mapper.dart` - Error mapping utility
- **Modified:**
  - `lib/features/tasks/view/widgets/task_card.dart` - Image display in headers
  - `lib/features/tasks/services/task_service.dart` - Pagination, error handling
  - `lib/features/tasks/services/task_image_service.dart` - Enhanced error handling
  - `lib/features/home/viewmodels/home_view_model.dart` - Pagination support
  - `lib/features/tasks/viewmodels/task_view_model.dart` - Optimized notifications
  - `lib/features/auth/viewmodels/auth_view_model.dart` - Session listener
  - `lib/core/widgets/signed_image.dart` - CachedNetworkImage
  - `lib/core/widgets/signed_avatar.dart` - CachedNetworkImage
  - `lib/main.dart` - Auth listener wrapper
  - `pubspec.yaml` - Added cached_network_image

#### 🔧 Technical Notes

- Cursor pagination uses `created_at` timestamps (ISO 8601) per project rules (no offset pagination)
- `ErrorMapper` handles `PostgrestException`, `AuthException`, `StorageException`, and network errors
- Session expiry events are queued if they occur before callback is set (prevents startup race condition)
- Image caching uses disk + memory cache via `flutter_cache_manager` (transitive dependency)

#### 🔜 Next

- Phase 2.1: Differentiate Tender vs Booking Cards
- Phase 2.2: Orders Dashboard Overhaul
- Plan `supabase_flutter` v2.x migration (30 outdated packages detected)

---

### 🟢 Version 2.1 — Theme System Dashboard, iOS 26 Liquid Glass Nav & CodeGuard Agent

**Date:** 2025-12-08
**Commit:** _Pending_ — "feat(theme): centralized theme dashboard, liquid glass nav bar, CodeGuard agent"

#### ✅ Implemented

- **Theme System Dashboard**
  - Created `lib/core/theme/theme_dashboard.dart` - comprehensive single source of truth for all theme values
  - Documents all `AppColors`, `AppTypography`, `AppDimens`, `AppDecorations` with usage examples
  - Includes design token mapping from Figma/design to Flutter
  - Added anti-patterns guide to prevent hardcoded values

- **iOS 26 Liquid Glass Bottom Navigation**
  - Redesigned `lib/core/widgets/custom_bottom_nav_bar.dart` with frosted glass effect
  - Features: `BackdropFilter` blur (sigma: 25), animated pill indicator, scale animations
  - Theme-adaptive: works in both light and dark modes with different opacity values
  - Notification badge support with glow effect

- **CodeGuard Agent** (New)
  - Created `.cursor/Agents/CodeGuard.md` - Performance, Security & Compatibility Auditor
  - Focus: Code reviews, performance optimization, security hardening, dependency updates
  - Triggers: `@CodeGuard`, "review code", "performance check", "security audit", "update dependencies"
  - Features: Review report template, automated checks, anti-pattern tables

- **Feature Inventory System**
  - Created `.TODO/Future_Plans/FEATURE_INVENTORY.md` - tracks design vs implementation status
  - Documents all features from `.TODO/New_Design/` matched to Flutter implementation
  - Categorizes features as: Implemented, Partially Implemented, Not Implemented

- **Video Call Feature Removal**
  - Removed `lib/features/chat/view/video_call_modal.dart`
  - Removed video call button from `chat_screen.dart` header
  - Removed `VideoCallModal` references from design files
  - Removed `ActiveCall` interface from types

- **Designer References**
  - Added `Sline_everything/designer_references/liquid_glass.md` - iOS 26 liquid glass documentation

#### 📊 Impact

- Theme changes now centralized - edit once, apply everywhere
- Bottom navigation matches iOS 26 design language with premium feel
- Code quality improvements via CodeGuard agent audits
- Clear roadmap for remaining design implementation work

#### 🗂️ Files Touched

- **Theme:** `lib/core/theme/theme_dashboard.dart` (new), `lib/core/theme/app_typography.dart`, `lib/core/theme/app_dimens.dart`
- **Navigation:** `lib/core/widgets/custom_bottom_nav_bar.dart`, `lib/app/main_navigation_screen.dart`
- **Agents:** `.cursor/Agents/CodeGuard.md` (new)
- **Documentation:** `GEMINI.md`, `.cursorrules`, `.cursor/PROJECT_CONTEXT.md`
- **Removed:** `lib/features/chat/view/video_call_modal.dart`, video call references in chat

#### 🔜 Next

- Audit `Colors.*` usage → migrate to `AppColors`
- Update Supabase Flutter to v2.x (major version migration)
- Implement remaining features from FEATURE_INVENTORY.md

---

### 🟢 Version 2.0 — Visual Parity & Task Card Redesign

**Date:** 2025-12-08
**Commit:** _Pending_ — "feat(ui): TaskCard redesign, isHot/bgColor support, offer count trigger"

#### ✅ Implemented

- **Task Visuals (DB)**
  - Added `is_hot` (boolean), `bg_color` (text), `offers` (int) to `tasks` table.
  - Added trigger `update_task_offer_count` to auto-update `offers` when requests are added/removed.
- **Task Visuals (Flutter)**
  - Updated `Task` model to include new fields (safe null handling).
  - Updated `TaskService` to select all columns (`*`).
  - **Redesigned `TaskCard`**: now matches React `HomeList` design with header color block, floating badges, and rich footer.
- **Theme**
  - Added `AppDimens.p128` for card headers.
  - Added `toHex` utility for colors.

#### 📊 Impact

- Achieved 100% visual parity with the new Glassmorphism design for Task Cards.
- Home, Tenders, and Bookings screens now look consistent and premium.
- Offer counts are now cached on the task record for instant display.

### 🟢 Version 1.9 — Private Avatars & Task Images (Signed URLs)

**Date:** 2025-09-20  
**Commit:** _Pending_ — "feat(storage): avatars & task-images buckets + signed render; show task images; unify ProfileController"

#### ✅ Implemented

- **Storage**
  - Created private buckets: **`avatars`**, **`task-images`**.
  - RLS on `storage.objects`:
    - INSERT: authenticated owner only (`owner = auth.uid()` and correct `bucket_id`).
    - SELECT: authenticated users for respective bucket (for signed URLs).
- **Database**
  - Added `ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS image_paths text[] DEFAULT '{}'::text[];`
  - Forced PostgREST cache reload via `NOTIFY pgrst, 'reload schema';`.
- **Services**
  - `AvatarService`: switched to `avatars` bucket, use bytes upload, `createSignedUrl` (Supabase v2), store **storage path** in `profiles.avatar_url`.
  - **`TaskImageService`**: upload bytes to `task-images` under `tasks/<taskId>/<timestamp>.<ext>` and generate signed URLs.
- **Controllers**
  - Unified `ProfileController` (removed duplicate UI-layer version).
  - `TaskController`: finalize images after create/update and persist `image_paths`.
- **Widgets/UI**
  - **`SignedAvatar`**: renders avatar from storage path or legacy URL with in-memory TTL cache.
  - **`SignedImage`**: renders task image from storage path/URL with caching.
  - `task_card.dart`: shows first task image (thumbnail).
  - `task_details_screen.dart`: shows first task image above description.
- **Code Hygiene**
  - Replaced deprecated `.withOpacity` → `.withValues(alpha: ...)`.
  - Removed unused imports and variables.

#### 🐛 Bugs Fixed

- 403 on avatar upload due to missing RLS → fixed by policies on `avatars`.
- “column `image_paths` does not exist” during insert → added column and reloaded PostgREST cache.
- Home avatars not refreshing → `SignedAvatar` with signed URL cache.
- Duplicate `ProfileController` type → unified import path.

#### 📊 Impact

- Consistent, secure image handling (avatars + task images) via private buckets.
- Faster perceived loads thanks to signed-URL caching.
- Tasks on Home and Details now visually rich with thumbnail.

#### 🗂️ Files Touched

- **Core Widgets:** `lib/core/widgets/signed_avatar.dart`, `lib/core/widgets/signed_image.dart`
- **Profile:** `features/profile/services/avatar_service.dart`, `features/profile/controllers/profile_controller.dart`, `features/profile/ui/widgets/profile_avatar.dart`, `features/profile/ui/widgets/profile_view.dart`
- **Tasks:** `features/tasks/services/task_service.dart`, **`features/tasks/services/task_image_service.dart`**, `features/tasks/controllers/task_controller.dart`, `features/tasks/presentation/widgets/task_card.dart`, `features/tasks/presentation/task_details_screen.dart`
- **Misc:** minor cleanups in theme & imports

#### 🧪 Smoke Tests

- Create task with 1–3 images → `image_paths` updated and visible in Home + Details.
- Change avatar → profile + home avatars refresh instantly.
- Web upload works (no `dart:io`).

#### 🔜 Next

- Task gallery (carousel) for multiple images in `task_details_screen`.
- Pull-to-refresh on Home.
- Image compression on upload (reduce bandwidth).

### 🟢 Version 1.8 — Profile Avatars Revamp & Home Avatar Fix

**Date:** 2025-09-19  
**Commit:** _Pending_ — "fix: unify ProfileController, add SignedAvatar, private avatars bucket + RLS"

#### ✅ Implemented

- **Storage (Supabase):** Created private bucket **`avatars`**.
  - Path convention: `<uid>/<timestamp>.<ext>` (no bucket prefix inside `name`).
  - Added RLS policies on `storage.objects`:
    - INSERT/UPDATE/DELETE: authenticated users can write only under their own folder (`name like auth.uid() || '/%'`).
    - SELECT: authenticated users can read from `bucket_id = 'avatars'` (for client-side signed URLs).
- **AvatarService:**
  - Switched bucket from `portfolio` → **`avatars`**.
  - Fixed `createSignedUrl` to use Supabase v2 API (returns `String`).
  - Upload now uses binary bytes (web-safe) and stores **storage path** in `profiles.avatar_url`.
- **ProfileController:**
  - Unified single source of truth (removed duplicate controller under `ui/controller/`).
  - Added `pickAndUploadAvatar(context)` and `refreshAvatarSignedUrl()`.
  - New state fields: `avatarSignedUrl`, `avatarUploading`.
  - Cleaned imports: removed `dart:io`/legacy picker service.
- **UI (Profile):**
  - `profile_avatar.dart` now uses controller methods/fields above and shows a loading overlay.
  - `profile_view.dart` import fixed to point to the unified controller.
- **UI (Home/Tasks):**
  - New reusable widget **`SignedAvatar`** (`lib/core/widgets/signed_avatar.dart`).
    - Accepts either legacy **URL** or new **storage path**.
    - Generates signed URL on the fly + in-memory TTL cache (~90m).
  - `task_card.dart`: replaced raw `NetworkImage` with `SignedAvatar` so avatars refresh correctly on Home.
- **Deprecations & Cleanup:**
  - Replaced `.withOpacity(..)` → `.withValues(alpha: ..)` where applicable.
  - Addressed `surfaceVariant` deprecation (migrate to `surfaceContainer*` as we polish theme).
  - Removed unused imports/variables; analyzer warnings resolved.

#### 🐛 Bugs Fixed

- **403 RLS on upload** (`new row violates row-level security policy`): bucket policies added to allow authenticated INSERT under `<uid>/...`.
- **Duplicate `ProfileController` type conflict**: removed legacy controller & fixed imports across widgets.
- **Home avatars not updating**: `SignedAvatar` resolves storage paths to fresh signed URLs (with caching) — fixes stale images on Task cards.
- **Web compatibility**: avatar upload avoids `dart:io` and uses `XFile.readAsBytes()`.

#### 📈 Impact

- Consistent, secure avatar flow across Web/iOS/Android.
- Faster perceived loads for avatars via lightweight cache.
- Cleaner architecture: single ProfileController + shared avatar widget.

#### 🔬 Notes / Migration

- Legacy rows where `profiles.avatar_url` stores a **public URL** still render (widget detects `http` and uses it directly).
- New uploads store **storage path** only; rendering always uses a **signed URL**.

#### 🧪 Smoke Test Checklist

- Upload avatar → loader shows → image updates immediately.
- Re-open Profile/Home → image still shows (signed URL regenerated on view).
- Web upload works; no 403; no `dart:io` usage.

### 🟢 Version 1.7 — Sprint 2 Complete: Booking (A2–A4) + Categories (DB-first) + Portfolio v1**Date:** 2025-08-23

**Commit:** _Pending_ — "feat(booking): availability & bookings polish; add categories DB-first + tasks.category_id"

#### ✅ Implemented

### 🟢 Version 1.7 — Sprint 2 Complete: Booking (A2–A4) + Categories (DB-first) + Portfolio v1

- **Portfolio (B2)**
  - DB: `portfolio_items` + private `portfolio` bucket with RLS
  - Flutter: `PortfolioService`, `PortfolioController`, `PortfolioScreen`
  - Features: upload image (image_picker), create, edit, delete, details sheet
  - iOS: added NSPhotoLibraryUsageDescription in Info.plist

- **Tasks (Long-term category name)**
  - All task `.select(...)` now include `categories(name)` embed.
  - `TaskModel` adds `categoryName` resolved from embed (fallback to legacy text).
  - `TaskCard` & `TaskDetailsScreen` display `categoryName` (no UUID / null).
  - Fixed `AvailabilityScreen` navigation to pass correct `taskId` (`task.id`).
- **Booking (Frontend)**
  - `AvailabilityScreen`: grid/list toggle, pull-to-refresh, infinite scroll, role guard (provider-only Add Slot).
  - `BookingsListScreen`: tabs (As Client / As Provider), status filter, pagination with hasMore + inline loader.
  - `BookingSheet`: wired with `taskId`, `providerId`, `slotId`.
  - `AddSlotSheet`: pick local start/end, convert to UTC, create blocked/open slot.
  - `format_date.dart`: `formatRangeUtcToLocal`, `formatUtcToLocal` utilities (consistent local-time display).
- **Booking (Logic/Service/Controller)**
  - `BookingService.createSlot` now sets `provider_id = auth.uid()` (RLS requirement).
  - `BookingService.bookSlot` now sets `client_id = auth.uid()` (RLS requirement).
  - `BookingController`: friendly error mapper (`23505` → already booked, overlap trigger → overlapping slot), unified pagination flags (`slotsHasMore`, `bookingsClientHasMore`, `bookingsProviderHasMore`), and cursor handling.
- **Booking (DB/RLS)**
  - Partial unique index on `bookings(slot_id)` for `status in ('pending','confirmed')`.
  - Overlap prevention for `availability_slots` via trigger on insert/update using `tstzrange &&`.
  - Indexes: `idx_slots_provider_starts`, `idx_bookings_client_created`, `idx_bookings_provider_created`.
- **Categories (B1, DB-first)**
  - Table `public.categories` with `uq_categories_name` and `idx_categories_name_lower`.
  - RLS: **read-only** for authenticated users (select policy only).
  - Seed: Design/Development/Marketing/Photography/Writing/Cleaning/Other (idempotent).
  - Migration: `tasks.category_id` (nullable) + index + optional backfill from existing text field.

#### 📈 Impact

- End-to-end booking happy-path works on Web/iOS with proper RLS compliance.
- Clear UX: provider adds slots; client books; lists are paginated with robust states.
- Categories are now managed in DB (UI can switch later without breaking current flows).

#### 🔬 Notes

- Timezone: store UTC in DB; display local in Flutter via `toLocal()` (+ utilities).
- Providers are scoped by route; bottom sheets use the existing navigator to avoid Provider scope issues.
- Policies remain conservative; category writes are admin/server-only for now.

### 🟢 Version 1.6 — Tender Offers Complete & Booking Kickoff

**Date:** 2025-08-22  
**Commit:** _Pending_ — "feat: complete tender offers; add task_type & UI separation; provider fixes"

#### ✅ Implemented

- **DB:** `task_type_enum ('tender','booking')`, `task_requests` table with indexes and RLS.
- **Policies:** Owner sees all offers for their tender task; bidder sees only their offers; owner can accept/reject.
- **Triggers:** Prevent offers on booking tasks; optional trigger to allow updating `status` only.
- **Indexes:** `idx_tasks_type_created_at(task_type, created_at desc)`, `idx_task_requests_task_created(task_id, created_at desc)`, unique pending-per-user (`task_id,bidder_id` where `status='pending'`).
- **Flutter Model:** `TaskType` enum + `taskType` field; `isTender/isBooking` getters.
- **Services:** Explicit `select(..., task_type, ...)` in `task_service.dart`.
- **UI:**
  - `TaskDetailsScreen` shows **View Offers / Submit Offer** for tender; **Check Availability / Book Now** placeholders for booking.
  - `RequestsListScreen` **guarded** for non-tender with info message.
  - Submit-offer BottomSheet receives controller by parameter; `useRootNavigator: false`.
- **Bugfix:** Resolved `ProviderNotFoundException` when opening submit-offer sheet.

#### 📈 Impact

- Clear separation between bidding (tender) and scheduling (booking).
- Robust UX with no cross-route provider issues.
- Ready foundation for Sprint 2 (Booking: availability + reservations).

#### 🔜 Next (Sprint 2)

- Add `availability_slots` + `bookings` tables + RLS.
- Implement `AvailabilityScreen` + `BookingSheet`.
- Realtime updates for bookings; prevent double-booking with trigger.

### 🔰 Version 0.1 - Initial State (Baseline)

**Date**: Before 2025-07-25
**Status**: Basic Flutter project with minimal functionality

#### What Existed

- ✅ Basic Flutter project structure
- ✅ Supabase integration setup
- ✅ Basic authentication system (email/password)
- ✅ Simple profile management
- ✅ Database tables: `users`, `roles`, `user_roles`
- ✅ Row-level security (RLS) policies
- ✅ Basic UI with login/signup screens

#### Project Structure (v0.1)

```
lib/
├── core/
│   ├── models/
│   ├── repositories/
│   └── services/
├── features/
│   ├── auth/
│   │   ├── controller/
│   │   ├── data/
│   │   ├── model/
│   │   └── ui/
│   ├── profile/
│   │   └── ui/
│   ├── home/
│   ├── booking/
│   ├── chat/
│   └── tasks/
└── main.dart
```

#### Key Features (v0.1)

- Basic authentication flow
- User profile editing
- Avatar upload functionality
- Role switching (client/freelancer)
- Simple navigation between screens

#### Issues in v0.1

- ❌ Inconsistent folder structure
- ❌ Mixed naming conventions
- ❌ No proper navigation system
- ❌ Incomplete feature implementation
- ❌ No standardized architecture

---

### 🚀 Version 1.1 - Major Architecture Restructuring

**Date**: 2025-07-25
**Status**: Complete project restructuring and navigation implementation
**Commit**: `97f9704` - "feat: Complete project restructuring to align with STRUCTURE.md"

#### 🏗️ Major Changes

##### 1. Complete Architecture Restructuring

- **Reorganized entire project** to follow STRUCTURE.md standards
- **Implemented modular feature-based architecture** with proper separation of concerns
- **All features now follow** `presentation/`, `controllers/`, `services/`, `models/` pattern
- **Standardized naming conventions** across the entire project

##### 2. Bottom Navigation System Implementation

- **Added complete 4-tab navigation system**: Home, Chat, Tasks, Profile
- **Implemented MainNavigationScreen** with IndexedStack for state preservation
- **Created CustomBottomNavBar component** with NavigationProvider for state management
- **Material Design 3 consistent theming** throughout the app

##### 3. Core Infrastructure Enhancements

- **Added `core/utils/`** with PriceFormatter and DateFormatter utilities
- **Created `core/providers/navigation_provider.dart`** for app-wide navigation state
- **Enhanced `core/widgets/`** with reusable CustomBottomNavBar component
- **Proper Provider setup** with dependency injection in main.dart

##### 4. Feature-by-Feature Restructuring

###### Auth Feature Restructuring

- **Before**: `controller/`, `data/`, `model/`, `ui/`
- **After**: `presentation/`, `controllers/`, `services/`
- **Changes**:
  - Moved AuthController to use ChangeNotifier pattern
  - Created AuthService for Supabase integration
  - Updated LoginScreen with proper Provider integration
  - Fixed navigation to use MainNavigationScreen

###### Home Feature Enhancement

- **Added**: `controllers/`, `widgets/`
- **Changes**:
  - Created HomeController for managing featured tasks
  - Added ServiceCard widget for displaying task listings
  - Enhanced HomeScreen with pull-to-refresh and loading states
  - Integrated with TaskModel for data structure
  - Added mock data for featured tasks display

###### Chat Feature Implementation

- **Added**: `controllers/`, `models/`
- **Changes**:
  - Created ChatController with message management
  - Added ChatMessage model with JSON serialization
  - Prepared structure for real-time messaging- ✅ **Documentation** fully synced
- 🔜 Next: Localization & Real Payment Integration

# 🎯 Summary (v2.8.2)

- ✅ **Chat Context UX**: Glassmorphism redesign & Task navigation
- ✅ **UX Responsiveness**: `LoadingUtils` blocking loader for async actions
- ✅ **List Polish**: Context row in Conversation Tiles

###### Tasks Feature Implementation

- **Added**: `controllers/`, `models/`, `services/`
- **Changes**:
  - Implemented TaskController with CRUD operations
  - Created Task model with TaskStatus enum
  - Added TaskService for Supabase integration
  - Prepared for job posting and browsing functionality
  - Mock data implementation for testing

###### Profile Feature Restructuring

- **Before**: Mixed structure with old ProfileView
- **After**: `controllers/`, `widgets/`
- **Changes**:
  - Restructured to use ProfileController with ChangeNotifier
  - Created ProfileAvatarWidget for image upload functionality
  - Enhanced ProfileScreen with complete form validation
  - Fixed ProviderNotFoundException by updating import structure
  - Added logout functionality in app bar

##### 5. Provider Integration & Bug Fixes

- **Updated main.dart** with all controllers (Auth, Home, Chat, Tasks, Profile, Navigation)
- **Proper MultiProvider setup** for dependency injection
- **Fixed all import paths** to use new structure
- **Resolved ProviderNotFoundException** by updating ProfileScreen
- **Added proper initialization** for all controllers

##### 6. Documentation & Reference

- **Added comprehensive STRUCTURE.md** guide
- **Created Windserf_Refrence.md** with complete project analysis
- **Updated README_SLINE_OVERVIEW.md** placeholder
- **Documented all architectural decisions** and patterns

#### 📁 New Project Structure (v1.0)

> Historical snapshot note: the tree below is an archival v1 structure example. The live repository no longer uses `controllers/` / `presentation/` folders here, and `lib/features/home/view/widgets/service_card.dart` has been removed.

```
lib/
├── app/                     # Main App Configs
│   └── main_navigation_screen.dart
├── core/                    # Shared Resources
│   ├── models/              # Global data models
│   ├── providers/           # App-wide state
│   │   └── navigation_provider.dart
│   ├── repositories/        # Data access layer
│   ├── services/            # Core services
│   │   └── supabase_config.dart
│   ├── utils/               # Helper functions
│   │   └── format_price.dart
│   └── widgets/             # Shared UI components
│       └── custom_bottom_nav_bar.dart
├── features/                # Feature-based organization
│   ├── auth/
│   │   ├── controllers/
│   │   │   └── auth_controller.dart
│   │   ├── presentation/
│   │   │   └── login_screen.dart
│   │   └── services/
│   │       └── auth_service.dart
│   ├── chat/
│   │   ├── controllers/
│   │   │   └── chat_controller.dart
│   │   ├── models/
│   │   │   └── chat_message_model.dart
│   │   └── presentation/
│   │       └── chat_screen.dart
│   ├── home/
│   │   ├── controllers/
│   │   │   └── home_controller.dart
│   │   ├── presentation/
│   │   │   └── home_screen.dart
│   │   └── widgets/
│   │       └── service_card.dart
│   ├── profile/
│   │   ├── controllers/
│   │   │   └── profile_controller.dart
│   │   ├── presentation/
│   │   │   └── profile_screen.dart
│   │   └── widgets/
│   │       └── profile_avatar_widget.dart
│   └── tasks/
│       ├── controllers/
│       │   └── task_controller.dart
│       ├── models/
│       │   └── task_model.dart
│       ├── presentation/
│       │   └── tasks_screen.dart
│       └── services/
│           └── task_service.dart
└── main.dart
```

#### ✅ Key Features Implemented (v1.0)

##### Navigation System

- **4-tab bottom navigation**: Home, Chat, Tasks, Profile
- **IndexedStack implementation** for state preservation
- **NavigationProvider** for reactive state management
- **Consistent Material Design 3** theming

##### Home Screen

- **Featured tasks display** with ServiceCard widgets
- **Pull-to-refresh functionality**
- **Loading states and empty state handling**
- **Mock data integration** for testing

##### Profile Management

- **Complete profile editing form** with validation
- **Avatar upload functionality** with image picker
- **Role switching capabilities**
- **Logout functionality**
- **Real-time data sync** with Supabase

##### Authentication System

- **Email/password authentication**
- **User session management**
- **Proper error handling** and user feedback
- **Navigation integration** with main app flow

##### Data Models & Services

- **Task model** with status management
- **ChatMessage model** for messaging
- **Service layer** for Supabase integration
- **Utility functions** for formatting

#### 🔧 Technical Improvements (v1.0)

##### Architecture

- **Modular design**: Each feature is self-contained and testable
- **Separation of concerns**: UI, logic, and services properly separated
- **Scalable structure**: Easy to add new features without breaking others
- **Reusable components**: Shared components and services in core/

##### State Management

- **Provider pattern**: Consistent ChangeNotifier usage
- **Proper dependency injection**: All controllers registered in main.dart
- **Reactive UI updates**: Consumer widgets for state changes
- **No global state pollution**: Each feature manages its own state

##### Code Quality

- **English comments**: All code documented in English
- **Consistent naming**: Following Dart conventions
- **Proper error handling**: Try-catch blocks with user feedback
- **Form validation**: Complete input validation throughout

#### 🎯 Current Capabilities (v1.0)

##### What Users Can Do

1. **Authentication**: Register, login, logout
2. **Navigation**: Seamlessly switch between 4 main sections
3. **Profile Management**: Edit profile, upload avatar, change role
4. **Home Dashboard**: View featured tasks, refresh content
5. **Basic UI**: Consistent Material Design interface

##### What's Ready for Development

1. **Chat System**: Controller and model structure ready for real-time messaging
2. **Task Management**: Complete CRUD operations structure ready
3. **Booking System**: Placeholder structure ready for implementation
4. **Enhanced Features**: All foundations laid for advanced functionality

#### 🐛 Issues Fixed (v1.0)

- ✅ **ProviderNotFoundException**: Fixed by updating ProfileScreen structure
- ✅ **Inconsistent folder structure**: Standardized to STRUCTURE.md
- ✅ **Mixed naming conventions**: Unified to Dart standards
- ✅ **Navigation issues**: Implemented proper bottom navigation
- ✅ **Import path problems**: Updated all imports to new structure
- ✅ **State management issues**: Proper Provider integration

#### 📊 Development Statistics (v1.0)

- **Files Changed**: 24 files
- **Lines Added**: 2,065 lines
- **Lines Removed**: 4 lines
- **New Features Created**: 5 major features
- **Controllers Implemented**: 6 controllers
- **Models Created**: 2 data models
- **Services Added**: 2 service classes
- **Widgets Created**: 3 custom widgets

---

## 🔮 Future Development Roadmap

### 📋 Next Priority Features

- **Update** B1 (Categories DB) is provisioned in DB; upcoming step is to switch Task form dropdown to use CategoriesService.

#### Version 1.1 - Task Management System

- **Task Posting**: Complete UI for clients to post jobs
- **Task Browsing**: Freelancer interface for browsing available tasks
- **Task Details**: Detailed view with bidding functionality
- **Task Status Management**: Progress tracking and updates
- **Search & Filters**: Advanced task search capabilities

#### Version 1.2 - Real-time Chat System

- **Supabase Realtime Integration**: Live messaging functionality
- **Chat Threads**: Conversation management between users
- **Message History**: Persistent chat storage and retrieval
- **Push Notifications**: Real-time message notifications
- **File Sharing**: Document and image sharing in chats

#### Version 1.3 - Booking & Payment System

- **Project Booking**: Formal project agreement system
- **Milestone Management**: Project phase tracking
- **Payment Integration**: Stripe or similar payment processor
- **Invoice Generation**: Automated billing system
- **Dispute Resolution**: Conflict management tools

#### Version 1.4 - Enhanced User Experience

- **Reviews & Ratings**: User feedback system
- **User Profiles**: Enhanced freelancer/client profiles
- **Portfolio Management**: Showcase work and skills
- **Advanced Search**: AI-powered matching system
- **Analytics Dashboard**: Performance metrics for users

### 🔧 Technical Debt & Improvements

- **Legacy Folder Cleanup**: Remove any remaining old structure files
- **Performance Optimization**: Image compression, lazy loading
- **Offline Support**: Local caching for core features
- **Testing Implementation**: Unit tests, widget tests, integration tests
- **CI/CD Pipeline**: Automated testing and deployment

---

## 📚 Development Guidelines

### 🎯 Architecture Principles

1. **Follow STRUCTURE.md**: Maintain consistent folder structure
2. **Separation of Concerns**: Keep UI, logic, and data layers separate
3. **Provider Pattern**: Use ChangeNotifier for state management
4. **English Documentation**: All code and comments in English
5. **Modular Design**: Each feature should be self-contained

### 🔄 Development Workflow

1. **Feature Planning**: Define requirements and structure
2. **Model Creation**: Design data models first
3. **Service Implementation**: Create service layer for data operations
4. **Controller Development**: Implement business logic
5. **UI Implementation**: Build presentation layer
6. **Testing**: Ensure functionality works correctly
7. **Documentation**: Update logs and documentation
8. **Git Commit**: Detailed commit messages

### 📝 Commit Message Format

```
feat/fix/docs: Brief description

🎯 What was implemented:
- Feature 1
- Feature 2

🔧 Technical changes:
- Change 1
- Change 2

📊 Impact:
- Impact description
```

---

## 🎯 Key Learnings & Decisions

### ✅ What Worked Well

1. **Modular Architecture**: Easy to navigate and maintain
2. **Provider Pattern**: Consistent state management across features
3. **STRUCTURE.md Guide**: Clear development standards
4. **Feature-based Organization**: Logical code separation
5. **Comprehensive Documentation**: Easy to understand and continue

### 🔄 What Could Be Improved

1. **Testing Coverage**: Need comprehensive test suite
2. **Performance Monitoring**: Add performance tracking
3. **Error Handling**: More robust error management
4. **User Feedback**: Better loading states and error messages
5. **Code Reviews**: Implement peer review process

### 📋 Important Notes for Future Development

1. **Always follow STRUCTURE.md** when adding new features
2. **Update this log** with every significant change
3. **Maintain Provider pattern** for state management
4. **Keep documentation updated** with architectural changes
5. **Test thoroughly** before committing major changes

---

_This log should be updated with every major version release and significant feature implementation._

---

### 📦 Version 1.3 - My Tasks & Task Editing

**Date**: 2025-08-02  
**Status**: Completed My Tasks feature with edit/delete support  
**Commit**: _Pending_ - "feat: Add My Tasks tab with edit and delete functionality"

#### 🆕 Implemented Features

##### 1. My Tasks Section

- Added "My Tasks" tab inside Profile screen
- Displays list of tasks created by the logged-in user
- Auto-loads tasks when the Profile screen is opened

##### 2. Edit/Delete Task

- Edit: Reuses CreateTaskScreen in edit mode with prefilled data
- Delete: Removes selected task with confirmation and state refresh
- TaskService updated with `updateTask` method
- ProfileController extended with `fetchMyTasks`, `deleteMyTask`, `updateMyTask`

#### 📊 Impact

- Users can now manage their posted tasks from Profile
- Improves user experience by allowing direct editing and deletion of tasks
- Prepares the groundwork for request and messaging features

---

### 📦 Version 1.2 - Task Creation Feature

**Date**: 2025-07-26  
**Status**: Task creation fully implemented with Supabase integration  
**Commit**: _Pending_ - "feat: Implement task creation with full UI and Supabase integration"

#### 🆕 Implemented Features

##### 1. Create Task Flow

- Added full-screen `CreateTaskScreen` under `features/tasks/presentation/`
- Integrated form fields: title, description, budget, skills, and category
- Connected to `TaskController` for business logic
- Used `TaskModel` to structure task data
- Implemented validation and submission feedback

##### 2. Supabase Integration

- Task is created via `TaskService.createTask()` method
- Task is saved to Supabase with correct userId and category field
- Implemented error handling and loading state

##### 3. Category Field Support

- TaskModel updated to include `category` field
- Supabase `tasks` table now includes a `category` column (type: text)
- UI dropdown for category selection integrated in create task screen
- Home screen updated to show category inside task cards

##### 4. UI/UX Enhancements

- Applied proper theming and spacing for Material 3
- Included success SnackBar after task is posted
- Disabled button when loading to prevent multiple submissions

##### 5. Publisher Info Display

- TaskCard now displays publisher full_name and avatar_url
- Implemented Supabase relationship (tasks → users) for fetching user info
- Added SnackBar confirmation after successful task posting to replace black screen issue
- Ensured BottomNavigationBar persists after publishing task

#### 📊 Impact

- Users (clients) can now post tasks into the marketplace
- Category is now a required field, shown in both posting and display
- Feature unlocks the next step: browsing tasks for freelancers

#### 📌 Next Steps After v1.2

- Implement task browsing screen for freelancers
- Display task details screen on tap
- Enable filtering by category and skill

# --- v0.7 Logger Integration & Messaging Fix ---

### 📦 Version 0.7 - Logger Integration & Messaging Fix

**Date**: 2025-08-03  
**Status**: Completed logger integration and messaging display fixes  
**Commit**: _Pending_ - "feat: Integrate AppLogger and enhance messaging UI"

#### 🆕 Implemented Features

##### 1. Centralized Logger Integration

- Added `core/services/logger_service.dart` with `AppLogger` using PrettyPrinter
- Replaced all `debugPrint` calls with `AppLogger` (d/i/w/e)
- Ensured logs only display in debug mode using `kDebugMode`

##### 2. Messaging System Enhancements

- Extended `Conversation` model with `lastMessage` and `lastMessageTime`
- Updated `message_service.dart` to fetch `last_message` safely (handles Map/List/null)
- Updated `messages_screen.dart` UI to WhatsApp-style preview:
  - Avatar + name of other user
  - Last message content
  - Timestamp of last message
- Fixed conversation fetching to prevent type cast errors
- Verified Supabase queries handle relationships with `profiles` table

##### 3. Supabase Adjustments

- Confirmed `conversations` table foreign keys:
  - `user1_id → auth.users.id`
  - `user2_id → auth.users.id`
  - `task_id → tasks.id`
- Adjusted Supabase query joins for `profiles` to fetch user names
- Added safe handling for `messages` relation returning arrays

##### 4. Task Publishing Confirmation

- Replaced black screen issue after posting task with success SnackBar
- Ensured BottomNavigationBar persists after publishing

#### 📊 Impact

- Debug console now shows structured, meaningful logs only in debug mode
- Messaging tab reliably displays all conversations with last message + time
- Groundwork laid for Supabase Realtime integration for live chat
- Users receive clear feedback when posting tasks, eliminating confusion from previous black screen issue

# --- v0.8 Supabase Realtime Messaging ---

### 📦 Version 0.8 - Supabase Realtime Messaging

**Date**: 2025-08-03  
**Status**: Enabled Supabase Realtime for conversations and messages  
**Commit**: _Pending_ - "feat: Enable Supabase Realtime for conversations and messages"

#### 🆕 Implemented Features

##### 1. Supabase Realtime Integration

- Enabled realtime on `messages` and `conversations` tables
- Subscribed to conversation and message changes using `supabase.channel`
- UI now auto-updates when new messages are sent/received between users

##### 2. Security Policies

- Added row-level security policies to restrict access:
  - Conversations visible only to participants
  - Messages visible only to sender and participants of a conversation
- Insert policies restricted to authenticated users

##### 3. UI Enhancements

- Conversations list updates in real-time when a new message is added
- Last message preview updates instantly without refresh
- Fixed null/empty lastMessage cases to prevent crashes

##### 4. Debug Logging

- Extended AppLogger to show realtime subscription events
- Clear logs for join, insert, update, and delete events

#### 📊 Impact

- True real-time messaging between accounts without manual refresh
- Improved user experience with instant updates in the Chat tab
- Secure policies ensure no unauthorized data access

# --- v0.9 Realtime Messaging Fix & Cleanup ---

### 📦 Version 0.9 - Realtime Messaging Fix & Cleanup

**Date**: 2025-08-05  
**Status**: Fixed realtime sync issues and cleaned message flow  
**Commit**: _Pending_ - "fix: Enhance realtime chat sync & clean message handling"

#### 🆕 Implemented Features

##### 1. Realtime Messaging Fixes

- Fixed issue where new messages did not appear instantly on the receiver’s side
- Added `listenToMessagesRealtime()` in `message_service.dart` and integrated it in `chat_controller.dart`
- Verified Supabase channel subscription for reliable event listening

##### 2. Code Cleanup & Refactor

- Removed unused and duplicate code from:
  - `messages_screen.dart`
  - `chat_controller.dart`
  - `message_service.dart`
- Cleaned up redundant imports

##### 3. Bug Fixes

- Resolved ambiguous import for `Conversation` by using alias imports
- Replaced deprecated `inFilter()` with `.in_()` for Supabase queries
- Fixed type cast issue in message fetching methods by adding explicit casting

##### 4. Logging & Documentation

- Enhanced AppLogger output for realtime events:
  - ✅ Conversations fetched
  - ✅ Conversations updated
  - 📩 New message received and messages refreshed
- Added detailed English documentation/comments in:
  - `chat_controller.dart`
  - `message_service.dart`
  - `messages_screen.dart`

#### 📊 Impact

- Users now see new messages instantly without refreshing
- Reduced risk of runtime errors due to cleaner code
- Improved maintainability with consistent documentation
- Debug console provides clear feedback for realtime chat operations

# 📘 SLine App - Complete Development Log

**Last Updated:** 2025-08-17

---

## 🎯 Project Overview

Flutter + Supabase freelance marketplace with real-time chat, tasks, and profiles.

---

## 📋 Version History

### 🟢 Version 1.4 — Chat Attachments & Storage

**Date:** 2025-08-17  
**Commit:** _Pending_ — "feat: chat attachments with Supabase Storage (private)"

#### ✅ Implemented

- Message model extended with: `receiver_id`, `attachment_url`, `attachment_type`, `attachment_name`, `attachment_size`.
- Private bucket `chat-attachments` created; upload via `AttachmentService`.
- Storage RLS policies for INSERT/SELECT using `policyname` (fixed `polname` error) and `schemaname='storage'`.
- `MessageService` updated:
  - `createOrGetConversation` with order-insensitive pair filter.
  - `sendMessage` accepts text and/or attachment.
  - `getMessages` returns attachment fields.
  - Realtime ordered by `created_at`.
- `ChatScreen` UI:
  - Image/File pickers (`image_picker`, `file_picker`).
  - Image thumbnails via signed URL; file chip with name.
- DB index on `(conversation_id, created_at)` for messages.

#### 🧪 Verification

- Upload image/file → appears instantly on both sides (realtime).
- Storage objects visible in `chat-attachments` under `conversationId/…`.
- Signed URL works for authenticated users (policy SELECT present).
- `flutter analyze` clean except minor `.withOpacity` notice (optional: use `.withValues(alpha: 0.85)`).

#### 🛠 SQL Snapshot

```sql
ALTER TABLE public.messages
  ADD COLUMN IF NOT EXISTS receiver_id uuid REFERENCES public.profiles(id),
  ADD COLUMN IF NOT EXISTS attachment_url text,
  ADD COLUMN IF NOT EXISTS attachment_type text,
  ADD COLUMN IF NOT EXISTS attachment_name text,
  ADD COLUMN IF NOT EXISTS attachment_size integer;

CREATE INDEX IF NOT EXISTS idx_messages_convo_created
  ON public.messages (conversation_id, created_at);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'chat_attach_insert_auth'
      AND schemaname = 'storage'
      AND tablename  = 'objects'
  ) THEN
    CREATE POLICY "chat_attach_insert_auth"
    ON storage.objects
    FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'chat-attachments' AND owner = auth.uid());
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'chat_attach_select_auth'
      AND schemaname = 'storage'
      AND tablename  = 'objects'
  ) THEN
    CREATE POLICY "chat_attach_select_auth"
    ON storage.objects
    FOR SELECT
    TO authenticated
    USING (bucket_id = 'chat-attachments');
  END IF;
END$$;
```

---

### 📦 Version 1.3 — My Tasks & Task Editing

**Date:** 2025-08-02  
**Status:** Completed  
**Commit:** _Pending_ — "feat: Add My Tasks tab with edit and delete functionality"

(unchanged content retained)

---

### 📦 Version 1.2 — Task Creation Feature

**Date:** 2025-07-26  
**Status:** Completed

(unchanged content retained)

---

### 🧱 v0.9 / v0.8 / v0.7 — Realtime & Logger groundwork

(unchanged content retained; see previous notes)

# 📘 SLine App - Complete Development Log (Consolidated)

**Last Updated:** 2025-08-17

---

## 🎯 Overview

Flutter + Supabase freelance marketplace with real-time chat, tasks, and profiles.

---

## 📋 Version History (highlights)

### 🟢 Version 1.5 — Realtime Optimizations & Attachments Isolation

**Date:** 2025-08-17  
**Commit:** _Pending_ — "fix: realtime upsert, chats render images instantly; tighten queries"

#### ✅ Implemented

- **Realtime (messages):** in-place **upsert** on events (insert/replace + sort by `created_at`).
- **Immediate image rendering:** append server-returned message directly after send.
- **Query stability:** chain `.or()` / `.in_()` **before** `.order()` / `.limit()`.
- **Conversations last_message:** `order(created_at desc)` + `limit 1` on embedded `messages`.
- **Null-safety in ChatScreen:** guard `user?.id` when computing `isMine`.
- **Attachments isolation:** `features/chat/attachments/` (services + widgets).

#### 📦 Impact

- Lower network usage and smoother UI in long threads.
- No temporary `[photo]` text bubbles — images show immediately.
- Fewer edge-case crashes (null auth, heavy relations).

#### 🔧 Files (high level)

- `chat_controller.dart`: send flow + realtime listener upsert
- `message_service.dart`: query order/limit + filter order
- `chat/presentation/`: `ChatScreen`, `AttachmentMessageTile`
- `attachments/services/`: `upload_service.dart` wrapper → `AttachmentService`

---

### 🟢 Version 1.4 — Chat Attachments & Storage

**Date:** 2025-08-17  
**Commit:** _Pending_ — "feat: chat attachments with Supabase Storage (private)"

#### ✅ Implemented

- Message model extended: `receiver_id`, `attachment_url`, `attachment_type`, `attachment_name`, `attachment_size`.
- Storage bucket `chat-attachments` (private) with INSERT/SELECT policies.
- `AttachmentService` (upload + signed URL), UI image/file bubbles.
- DB index `(conversation_id, created_at)` for messages.

#### 🧪 SQL Snapshot

(see `SUPABASE_SETUP.md`).

---

### 📦 Version 1.3 — My Tasks & Task Editing (2025-08-02)

- "My Tasks" in Profile with edit/delete.

### 📦 Version 1.2 — Task Creation (2025-07-26)

- CreateTaskScreen + TaskService integration.

### 🔧 v0.9 / v0.8 / v0.7 — Realtime & Logger groundwork

- Realtime enabled for conversations/messages, AppLogger integrated.

---

## 🧭 Notes

- Docs consolidated: **STRUCTURE.md**, **SUPABASE_SETUP.md**, **MVP_ROADMAP.md**.
- Keep comments and docs in **English**; product UI bilingual later.

> ملاحظة: إذا عندك لقسم قديم باسم “6.2 حارس إنشاء المحادثات (Client-only)”، استبدله بالكامل بالنص الجديد أعلاه.

---

# 2) Sline_Log.md

## أضِف مدخلة نسخة جديدة تحت “Version History”

ابحث عن عنوان `## 📋 Version History` وألصق المقطع التالي **مباشرة بعده**:

### 🟢 Version 2.16 — Payment Ledger (Phase 3) & Navigation Fix

**Date:** 2026-02-24
**Commit:** _Pending_ — "feat: Payment Ledger Phase 3 (Escrow Enforced) + Nav Crash Fix"

#### ✅ Implemented

- **Payment Ledger (Phase 3):**
  - Enforced escrow payment on all bookings (removed "skip payment" shortcut).
  - Frozen legacy `wallet_transactions` table with DB trigger `trg_wallet_transactions_freeze`.
  - Backfilled legacy data into new ledger system via SQL migration.
  - Updated booking flow to include `PaymentCheckoutScreen` before creation.
- **Navigation (Crash Fix):**
  - Redesigned `BookingSheet` to return `BookingSheetResult` (note + price).
  - `AvailabilityScreen` handles navigation to `PaymentCheckoutScreen` from parent context.
  - Fixes `_state!` null assertion error when navigating from a disposed bottom sheet.
- **Gateway Status Clarified:**
  - QiCard integration: Backend ready with high-security webhook handler and signature verification.
  - Flutter app: Still uses `DemoPaymentService` for frontend (Arch ready for swap).

#### 📊 Impact

- Booking flow is now secure and follows the new ledger system.
- Eliminated common navigation crash in the booking module.
- Legacy financial data preserved and write-protected.

#### 🧪 Verification

- Plan: `Sline_everything/Payment_Gateway/Qi_Service/documentation.md` (Reference)
- QA: Manual verification of booking flow (Payment -> Success -> Booking Created).
- Tests: `flutter analyze` clean.

---

### 🟢 Version 1.8 — Chat guard flip (owner blocked) + RPC v1 + UI guard
