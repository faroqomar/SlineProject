# 📘 SLine App - Complete Development Log

**Last Updated:** 2026-05-11

---

## 🧭 Version 2.26.0 — Amber Dusk Phase 0 + Agent System Evolution (2026-05-11)

**Classification:** Staged Open Design token foundation + agent-system process hardening
**Plan:** `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/PLAN_OpenDesign_AmberDusk_Phase0_PhoneFoundation_2026-05-11.md`
**Plan Critique:** `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/PLAN_CRITIQUE_2026-05-11_OpenDesign_AmberDusk_Phase0_PhoneFoundation.md`
**Session Log:** `docs/LOG/SESSION_PLAN_OpenDesign_AmberDusk_Phase0_PhoneFoundation_2026-05-11.md`
**Master Report:** `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/MASTER_REPORT_2026-05-11_OpenDesign_AmberDusk_Phase0.md`
**System Evolution:** `docs/LOG/SYSTEM_EVOLUTION_REPORT_2026-05-11.md`
**Docs Sync:** `.TODO/Archive/OpenDesign_AmberDusk_Phase0_2026-05-11/DOCS_SYNC_2026-05-11_DocsKeeper_AgentSystemAmberDusk.md`
**Supabase objects changed:** none

### Scope
- Added staged Amber Dusk Open Design tokens under `lib/core/theme/designs/amber_dusk/`.
- Added `lib/core/theme/designs/amber_dusk/amber_dusk_tokens.dart` as the public barrel for colors, typography, spacing, surfaces, motion, component recipes, and phone layout constants.
- Added focused token and phone layout tests under `test/core/theme/`.
- Clarified that staged design layers are imported for token access only and are not runtime replacements for active Layer 1 `AppTheme`.
- Ran Orchestrator Step 6 review, fixed all MED findings, and produced `.TODO/EMULATOR_TEST_CHECKLIST_2026-05-11_OpenDesign_AmberDusk_Phase0.md`.
- Ran SystemEvolution Step 7 and merged evidence-backed process rules into seven `.cursor/Agents/*.md` files.

### Key Files
- `lib/core/theme/designs/amber_dusk/amber_dusk_tokens.dart`
- `lib/core/theme/designs/amber_dusk/amber_dusk_colors.dart`
- `lib/core/theme/designs/amber_dusk/amber_dusk_typography.dart`
- `lib/core/theme/designs/amber_dusk/amber_dusk_spacing.dart`
- `lib/core/theme/designs/amber_dusk/amber_dusk_surfaces.dart`
- `lib/core/theme/designs/amber_dusk/amber_dusk_motion.dart`
- `lib/core/theme/designs/amber_dusk/amber_dusk_components.dart`
- `lib/core/theme/designs/amber_dusk/phone/amber_dusk_phone_layout.dart`
- `test/core/theme/amber_dusk_tokens_test.dart`
- `test/core/theme/amber_dusk_phone_layout_test.dart`
- `.cursor/Agents/Planner.md`
- `.cursor/Agents/PlanCritic.md`
- `.cursor/Agents/Pixel.md`
- `.cursor/Agents/Executor.md`
- `.cursor/Agents/Sentinel.md`
- `.cursor/Agents/CodeGuard.md`
- `.cursor/Agents/SystemEvolution.md`

### Verification
- `flutter analyze --no-fatal-infos`: passed.
- `flutter test test/core/theme/`: passed.
- `flutter test --coverage`: passed, coverage above the 40% floor.
- `Architecture Guard / Check MVVM boundaries`: passed.
- `git diff --check`: passed.

---

## 🧭 Version 2.25.1 — Home Discovery Navigation Consolidation (2026-04-30)

**Classification:** Navigation consolidation + Home discovery polish
**Plan:** `.TODO/Archive/HomeDiscoveryNavConsolidation_2026-04-30/PLAN_HomeDiscoveryNavConsolidation_2026-04-30.md`
**Plan Critique:** `.TODO/Archive/HomeDiscoveryNavConsolidation_2026-04-30/PLAN_CRITIQUE_2026-04-30_HomeDiscoveryNavConsolidation.md`
**Session Log:** `docs/LOG/SESSION_HomeDiscoveryNavConsolidation_2026-04-30.md`
**Master Report:** `.TODO/Archive/HomeDiscoveryNavConsolidation_2026-04-30/MASTER_REPORT_2026-04-30_HomeDiscoveryNavConsolidation.md`
**System Evolution:** `docs/LOG/SYSTEM_EVOLUTION_REPORT_2026-04-30.md`
**Supabase objects changed:** none

### Scope
- Bottom navigation now exposes four app-shell destinations: Home, Dashboard, Messages, Profile.
- `Tenders` and `Bookings` moved into Home below the search bar as discovery modes alongside `All Work`.
- Added `lib/core/navigation/main_nav_destinations.dart` so shell, bottom nav, deep links, and tests share named destination indexes.
- Added `AppLogger` instrumentation for stale navigation-index normalization and Home discovery mode changes/reselects.

### Key Files
- `lib/app/main_navigation_screen.dart`
- `lib/core/navigation/main_nav_destinations.dart`
- `lib/core/widgets/custom_bottom_nav_bar.dart`
- `lib/features/home/view/home_screen.dart`
- `lib/features/profile/services/profile_deep_link_handler.dart`
- `test/core/widgets/custom_bottom_nav_bar_test.dart`
- `test/widget/app/main_navigation_screen_test.dart`
- `test/widget/home/home_screen_test.dart`
- `test/features/profile/services/profile_deep_link_handler_test.dart`
- `test/widget/auth/login_screen_test.dart`
- `test/integration_test/create_tender_task_flow_test.dart`

### Review Fixes
- Orchestrator MED-1: isolated Home route-push widget coverage with `HomeScreen.taskDetailsScreenBuilder`, preserving the production `TaskDetailsScreen(task: task)` default.
- Orchestrator MED-2: normalized `MainNavigationScreen` provider state whenever the raw provider index differs from the effective visible index.

### Verification
- Changed-file analyzer: no issues.
- Focused widget tests: custom bottom nav, main navigation, Home, profile deep links, and login screen passed.
- Full `flutter test`: `+1400 ~30`.
- Full `flutter analyze`: still fails only on unrelated pre-existing chat analyzer baseline issues in `lib/features/chat/view/widgets/message_bubble.dart` and `test/widget/chat/phase6_advanced_interactions_test.dart`.

---

## 🎨 UI Redesign Phase 5 — Chat, Dashboard & Notifications Token Normalization (2026-04-09)

**Classification:** Token Normalization + Polish Pass (NOT a visual redesign)
**Master Plan Coverage:** Phases 6, 7, 14 — token layer only; visual redesign deferred
**Plan:** `.TODO/PLAN_Phase5_ChatDashboardNotifications_2026-04-09.md`
**Session Log:** `docs/LOG/SESSION_PLAN_Phase5_ChatDashboardNotifications_2026-04-09.md`
**Master Report:** `.TODO/MASTER_REPORT_2026-04-09_Phase5_ChatDashboardNotifications.md`
**System Evolution:** `docs/LOG/SYSTEM_EVOLUTION_REPORT_2026-04-09_v2.md`

### Scope: 17 files across Chat (10), Notifications (3), Dashboard (4)

### Implemented
- **Token compliance:** All `AppColors.teal/gold/lightTeal/lightRed` → `colorScheme.primary/warning/success/danger` in modified files
- **Motion tokens:** All hardcoded `Duration(milliseconds:)` → `AppMotion.*` tokens; added `AppMotion.typingCycle` (600ms)
- **Message grouping:** `isFirstInGroup`/`isLastInGroup` booleans on `MessageBubble`, computed in `ChatScreen._buildChatItems()` (2-min window + same sender)
- **Date separators:** Sealed `_ChatListItem` pattern (`_MessageItem` + `_DateSeparatorItem`) in ChatScreen
- **Stagger animations:** MessagesScreen, NotificationsModal, ActivityFeedPreview — single controller, Interval-based, `_hasAnimatedEntrance` guard
- **Typing indicator:** 3-dot sine pulse animation in ConversationListTile
- **Spring badge:** ScaleTransition with `AppMotion.curveSpring` on NotificationBadgeButton
- **Shimmer loading:** SkeletonLoader replacing CircularProgressIndicator in AttachmentMessageTile, BookingsTab, NotificationsModal, ActivityFeedPreview
- **Shake validation:** TweenSequence with `AppInteractionStates.shakeAmplitude` on CreateOfferSheet
- **Haptic feedback:** All interactive elements (offer accept/decline, notification tap, send button, etc.)
- **Semantics:** Full coverage on all modified widgets including "Needs Your Review" section header
- **Skeleton updates:** SkeletonConversationTile (48px avatar, r18 card), SkeletonMessageBubble (75% width, r18)
- **Tests:** +17 new widget tests (8 MessageBubble, 9 OfferMessageBubble)

### Orchestrator Review Fixes (12 items)
- `AppDecorations.elevation(2)` replacing hardcoded BoxShadow in ChatScreen FAB
- `AppMotion.typingCycle` token added, used in ConversationListTile
- `Colors.green`/`Colors.red` → `colorScheme.success`/`colorScheme.danger` in WorkTab SnackBars
- Raw `$e` exception → `error: e` named param in ChatScreen image send log
- Price/title removed from CreateOfferSheet INFO log (financial data leak)
- Raw `vm.error` removed from NotificationsModal Semantics label
- `_handleCountChange` moved to post-frame callback in NotificationBadgeButton
- Dead `AnimatedOpacity` removed from MessagesScreen empty state
- `bottom: 90` → `AppLayout` token expression in ChatScreen FAB
- `Curves.easeInOut` → `AppMotion.curveSymmetric` in CreateOfferSheet shake
- Storage paths redacted to filename only in AttachmentMessageTile logs
- Stale `AppColors.lightRed` → `colorScheme.danger` in `01_app_ui_diagram.md`

### QA Results
- `flutter analyze`: 0 issues
- `flutter test`: +1366 ~30 -2 (2 pre-existing failures, 30 skipped integration)
- Architecture guards: All pass

### Key Learning
- **Phantom redesign problem identified:** This phase was labeled "Redesign" but produced zero visible UI changes. The user could not perceive any difference. Root cause: plan covered only token normalization, not the structural visual redesign specified in the Master Plan.
- **System Evolution Report v2** produced 4 new critical rules (RG-6 through RG-9) to prevent recurrence: Visual Change Classification, Visual Verification Gate, Master Plan Cross-Reference, Visual Attestation.

---

## 🎨 UI Redesign Phase 4 — Home & Discovery (2026-04-08)

**Classification:** Redesign (structural layout changes)
**Master Plan Coverage:** Phase 4
**Session Log:** `docs/LOG/SESSION_PLAN_Phase4_HomeDiscovery_2026-04-08.md`

### Scope: 10 files — HomeScreen, discovery slivers, filters modal, 3 skeleton variants
- Content-first home redesign with scrollable discovery
- FiltersModal with DraggableScrollableSheet
- 3 new skeleton variants (SkeletonSearchResultCard, SkeletonCategoryTile, SkeletonFavoriteCard)
- Stagger entrance animations on discovery sections
- 7 test regressions found and fixed in-session (sliver/Semantics crash, shimmer pumpAndSettle timeout, DraggableSheet scroll ambiguity)

---

## 🎨 UI Redesign Phase 2 — App Shell, Auth & Cards (2026-04-08)

**Classification:** Redesign (structural layout + animation changes)
**Master Plan Coverage:** Phases 2, 3, 5
**Session Log:** `docs/LOG/SESSION_PLAN_Phase2_AppShellAuthCards_2026-04-08.md`

### Scope: App shell transitions, 7 auth screens, 8 card widgets, +15 tests
- MainNavigationScreen page transitions (StatefulWidget with AnimationControllers)
- Login/signup stagger entrance animations
- 8 card types redesigned (task, tender, booking, dashboard offer, booking card, dashboard booking, work item, counters)
- ScaleButton press feedback on all interactive cards

---

## 🎨 UI Redesign Phase 0.7 — Layout Tokens (2026-04-08)

**Classification:** Token Normalization (foundation infrastructure)
**Master Plan Coverage:** Phase 0 sub-phase
**Session Log:** `docs/LOG/SESSION_PLAN_LayoutTokens_Phase0.7_2026-04-08.md`

### Scope: NEW `app_layout.dart` with 41 semantic tokens + 53 tests
- Card sizes, avatar sizes, button heights, spacing rhythm
- Design/theme separation: Layer 2 (layout) split from Layer 1 (theme)

---

## 🎨 UI Redesign Phase 1 — Core Widget Redesign (2026-04-07)

**Classification:** Redesign (structural widget changes)
**Master Plan Coverage:** Phase 1
**Session Log:** `docs/LOG/SESSION_PLAN_CoreWidgetRedesign_2026-04-07.md`

### Scope: 14 fundamental widgets redesigned + 87 tests
- AppButton, AppTextField, GlassContainer (→ solid), SignedAvatar, CustomBottomNavBar, ScaleButton (NEW), SkeletonLoader (NEW)
- NO GLASS policy enforced: all BackdropFilter removed, replaced with solid surfaces + AppDecorations.elevation

---

## 🎨 UI Redesign Phase 0 — Design System Foundation (2026-04-07)

**Classification:** Token Normalization (foundation infrastructure)
**Master Plan Coverage:** Phase 0 (sub-phases 0.1–0.6)
**Session Log:** `docs/LOG/SESSION_PLAN_DesignSystemFoundation_2026-04-07.md`

### Scope: 6 theme token files created/updated
- NEW `app_motion.dart` — 7 durations, 7 curves, 4 scales, 3 staggers
- NEW `app_states.dart` — 8-state model (default→hover→focus→active→disabled→loading→success→error)
- NEW `app_decorations.dart` — 5-level elevation shadow scale
- Updated `app_colors.dart` — semantic color expansion (success/warning/info/danger + muted)
- Updated `app_typography.dart` — line height normalization
- Updated `app_theme.dart` — CardThemeData, DialogThemeData, BottomSheetThemeData

---

## 🔧 Quality Audit Phase E — Polish (2026-04-05)

### ✅ Implemented

**E1 — APK Build Resolution:**
- Kotlin version mismatch from Phase D self-resolved via Flutter SDK / sentry_flutter plugin update
- Both APK (debug) and Web (release) builds pass

**E2 — CI Check 7 (Core→Features Boundary):**
- Added architecture guard Check 7: `core/` must not import from `features/` (max 5 threshold, hard failure above)
- File: `.github/workflows/ci.yml`

**E3 — Lint Migration (very_good_analysis):**
- Migrated from `flutter_lints` to `very_good_analysis` (~70+ rules active)
- 862 auto-fixes via `dart fix --apply`, 12 manual fixes
- 27 noisy/incompatible rules disabled with justification
- Tracking: `.TODO/LINT_DEBT_PhaseE.md`
- File: `analysis_options.yaml`

**E4 — DI Normalization (5 ViewModels):**
- `SavedTasksViewModel` — lazy `SupabaseClient` getter
- `CategoriesViewModel` — lazy `CategoriesRepository`
- `PortfolioViewModel` — lazy repo + client
- `PublicProfileViewModel` — lazy repo
- `AuthFormViewModel` — lazy `AccountGuardService`
- Pattern: `late final _repo = _explicitRepo ?? Repository(Supabase.instance.client);`

**E5 — Sealed ViewState & AppFailure:**
- `lib/core/models/view_state.dart` — `ViewState<T>` → ViewInitial, ViewLoading, ViewLoaded, ViewFailed
- `lib/core/models/app_failure.dart` — `AppFailure` → NetworkFailure, AuthFailure, ValidationFailure, BusinessFailure
- Migrated: DirectOfferDetailsVM, BookingVM, WorkItemDetailsVM
- `_actionInProgress` pattern for mutation operations preserving loaded data

**E6 — God File Decomposition (9 files → 13 delegates/widgets):**
- `task_offer_service.dart` (454L) — 13 offer/payment methods from TaskService
- `task_request_error_mapper.dart` (270L) — 6 error mapping methods
- `task_requests_award_delegate.dart` (413L) — award/payment flows
- `booking_payment_delegate.dart` (253L) — payment coordination
- `payment_response_helpers.dart` (71L) — pure helper functions
- `work_item_bottom_actions.dart` (260L), `work_item_booking_details.dart` (126L), `work_item_guard_widgets.dart` (200L)
- `wallet_hero_card.dart` (294L), `wallet_timeline_card.dart` (238L)
- `task_concept_section.dart` (287L), `booking_logistics_section.dart` (152L)
- `payment_order_summary_card.dart` (101L)

**E7 — VM Tests (171 new, 27/27 VMs covered):**
- 11 new test files: DirectOfferDetailsVM (28), SearchVM (14), SavedTasksVM (14), AuthFormVM (14), CategoriesVM (10), PortfolioVM (12), PublicProfileVM (9), UserProfileVM (11), SafetyVM (12), MyServicesVM (15), WorkItemDetailsVM (32)
- Shared mock file expanded: 9 → 21 mock classes (`test/helpers/mock_services.dart`)

**E8 — Coverage Floor Raised:**
- CI threshold: 28% → 33%
- Measured coverage: 34.9%
- File: `.github/workflows/ci.yml`

**E9 — DeepLinkService Registry Refactor:**
- `lib/core/services/deep_link_registry.dart` — `DeepLinkRegistry` (register, handle, canHandle)
- `lib/core/services/deep_link_service.dart` — 0 feature imports (was 16), uses registry dispatch
- 6 feature handler files: task, booking, chat, direct_offers, work, profile
- UUID validation before routing, generic SnackBar for unknown entities

**E10 — Localization Infrastructure:**
- `l10n.yaml` config, `lib/l10n/app_en.arb` with 22 key stubs
- `generate: true` in `pubspec.yaml`
- MaterialApp wired with delegates and supported locales

**E11 — Orchestrator Review (20 findings, all fixed):**
- BLOCKER: 13 raw string literals (r'...$var...') broke log interpolation — removed r prefix
- HIGH: e.toString() leaks, _mapError fallthrough, ViewState data wipe — all fixed with ErrorMapper.map(e) and _actionInProgress
- MED/LOW: UUID validation, AppLogger in handlers, UTC fix, hardcoded colors, accessibility — all fixed

**E12 — Security Review (8 findings, all fixed):**
- Fail-closed rate limiting (return false on RPC failure)
- Removed debug log artifacts (_agentDebugLog functions)
- Production guard for QICARD_ALLOW_UNSIGNED_LOCAL_DEV
- Sentry PII sanitization (sanitizePii with Iraqi phone regex)
- localhost gated behind ENVIRONMENT !== "production"
- All e.toString()/e.message in SnackBars replaced with ErrorMapper.map(e)

**E13 — System Evolution Report v4:**
- 16 recommendations applied across all 16 agent files
- 7 new rules added (raw string guard, error sanitization, ViewState mutation, zone init, web URL cleanup, web awareness, native build gate)
- Doc/DIGRAM/ → docs/diagrams/ typo fixed across 13 files
- `docs/LOG/SYSTEM_EVOLUTION_REPORT_2026-04-05.md`

### Metrics
- Tests: 780 → 982 (+202)
- Analyze issues: 0
- Coverage floor: 28% → 33% (measured 34.9%)
- Architecture checks: 6 → 7
- VM test coverage: 16/27 → 27/27 (100%)
- God files >800 lines: 0

### Bug Fixes Applied During Phase E
- Zone mismatch: moved `WidgetsFlutterBinding.ensureInitialized()` before `runZonedGuarded()`
- Raw string in `task_requests_view_model.dart:496` — removed `r` prefix
- Web payment URL re-detection: added `clearPaymentReturnParamsFromUrl()` to `PaymentReturnScreen`

### References
- Plan: `.TODO/PLAN_PhaseE_Polish_2026-04-04.md`
- Session Log: `docs/LOG/SESSION_PLAN_PhaseE_Polish_2026-04-04.md`
- Master Report: `.TODO/MASTER_REPORT_2026-04-05_PhaseE.md`
- System Evolution: `docs/LOG/SYSTEM_EVOLUTION_REPORT_2026-04-05.md`
- Lint Debt: `.TODO/LINT_DEBT_PhaseE.md`

---

## 🏷️ Quality Audit Phase D — Harden (2026-04-04)

### ✅ Implemented

**D1 — Sentry Crash Reporting:**
- `lib/core/services/sentry_crash_reporting_service.dart` — implements `CrashReportingService` interface with `Sentry.captureException`, breadcrumbs, user identity, custom tags
- `lib/main.dart` — `SentryFlutter.init()` wraps `runZonedGuarded` as outermost error boundary. DSN from `--dart-define=SENTRY_DSN`. Empty DSN = disabled.
- `lib/features/auth/viewmodels/auth_session_view_model.dart` — attaches anonymized user UUID on login, clears on logout. No PII sent.
- PII sanitizer on breadcrumbs: strips emails and phone numbers before sending to Sentry.
- 15 tests (`test/unit/core/sentry_crash_reporting_service_test.dart`): construction, interface, safe methods, singleton swap, PII sanitizer (email, phone, UUID preservation).

**D2 — DashboardViewModel Decomposition (1149 → 537 lines):**
- `lib/features/dashboard/viewmodels/dashboard_work_delegate.dart` (362L) — work items, cached computed lists, performPrimaryAction, withdrawOffer, releaseOfferWithFee, refundOffer, cancelAwardedOffer
- `lib/features/dashboard/viewmodels/dashboard_inbox_delegate.dart` (297L) — inbox offers, pending items, myTasks, inboxGroupedByTask, awardOffer, payAwardedOffer, acceptOffer, rejectOffer
- `lib/features/dashboard/viewmodels/dashboard_booking_delegate.dart` (172L) — bookings, booking filter, acceptBooking, declineBooking, cancelBooking, updateBookingStatus
- Parent VM composes delegates via proxy getters/methods. Public API unchanged. All 20 existing tests pass unchanged.
- Dispose safety: each delegate receives `bool Function() isDisposed` callback. Checked before every `onChanged()`.
- 29 new delegate tests across 3 files.

**D3 — submit_request_sheet Decomposition (916 → 737 lines):**
- `lib/features/tasks/viewmodels/submit_request_view_model.dart` (261L) — validateTask, checkReplaceability, submitNewBid, replaceBid, computeComparison, error mapping
- Scoped `ChangeNotifierProvider.value` inside `showModalBottomSheet` builder (function-based sheet, not widget class)
- 3 extracted private widgets: `_ExistingBidInfo`, `_ComparisonRow`, `_WarningBanner`
- 15 new tests (`test/unit/viewmodels/submit_request_view_model_test.dart`)

**D4 — requests_list_screen Decomposition (1172 → 604 lines):**
- `lib/features/tasks/viewmodels/requests_filter_view_model.dart` (87L) — filter state, applyFilter, getCountString, isAwarding, pagination delegation. Subscribes to underlying TaskRequestsViewModel for reactive updates.
- `lib/features/tasks/models/expired_bid_filter.dart` (28L) — extracted enum + extension
- `lib/features/tasks/view/widgets/requests/request_award_dialog.dart` (416L) — showAwardDialog, _executeAward, showPriceMismatchDialog, _StepRow widget
- `didUpdateWidget` handles taskId changes (disposes stale filterVm)
- 15 new tests (`test/unit/viewmodels/requests_filter_view_model_test.dart`)

**D5 — pgTAP / SQL Assertion Tests:**
- `supabase/tests/accept_task_request_test.sql` — 4 tests: accept, auto-reject siblings, double-accept idempotent, task status
- `supabase/tests/escrow_idempotency_test.sql` — 5 tests: hold succeeds, replay idempotent, no duplicates, missing key, wrong currency
- `supabase/tests/role_switch_rate_limit_test.sql` — 6 tests: switch, switch back, no-op, stale state, invalid role, audit log
- All use `BEGIN`/`ROLLBACK` for zero side effects

**D6 — Migration Review Checklist:**
- `MIGRATION_REVIEW_CHECKLIST.md` — 7 sections: Naming, Rollback, Data Safety, RLS Impact, RPC Contract, Idempotency, Performance
- Referenced in `CLAUDE.md` Supabase Backend section

**D7 — Edge Function CORS Hardening:**
- `supabase/functions/_shared/bookin_payment.ts` — `"*"` replaced with `ALLOWED_ORIGIN` env var (defaults to `https://sline.app`)
- `isTrustedFinishUrl()` narrowed: HTTPS trusted only for `sline.app` (was all HTTPS domains)
- All 12 Edge Functions affected automatically (all import `corsHeaders` from shared file)

**D8 — paymentId Regex Validation:**
- `supabase/functions/qicard_webhook_handler/index.ts` — `/^[a-zA-Z0-9\-_]{1,128}$/` for both `intentId` and `paymentId` before `.or()` query
- Invalid IDs return 400. Logs truncated to 8 chars to prevent PII leakage.

**D9 — CI Coverage Floor:**
- `.github/workflows/ci.yml` — 28% regression floor. Blocks merges below threshold. Reports to `GITHUB_STEP_SUMMARY`.

**D10 — A6 Architecture Violations Fixed:**
- `lib/features/notifications/viewmodels/notification_view_model.dart` — lazy `SupabaseClient` getter via `_injectedClient` pattern
- `lib/features/saved/viewmodels/saved_tasks_view_model.dart` — `SupabaseClient? client` constructor parameter with `Supabase.instance.client` default

**D11 — Architecture Guard Check 3 Tightened:**
- `.github/workflows/ci.yml` — removed `grep -v 'Supabase\.instance\.client\.auth\.'` exclusion. Widened DI default pattern to `?? Supabase\.instance`.

### Bug Fixes Applied During Phase D
- `payEscrow` case in `DashboardWorkDelegate.performPrimaryAction()` changed from `return` to `break` — direct offer payment was unreachable
- `BookingDelegate`: defensive copy in `setBookings`, `UnmodifiableListView` on getter, `loadBookingsData` retry on failure, local list update in accept/decline/cancel
- `RequestsFilterViewModel`: subscribes to underlying TaskRequestsViewModel changes
- `SubmitRequestVM`: separate error messages for ownership vs task-closed errors

### Metrics
- Tests: 706 → 780 (+74 new). All pass. 0 analyze issues.
- Coverage: 30.6% baseline, 28% floor enforced in CI.
- Architecture guard: 6 checks pass (Check 3 tightened).

### References
- Plan: `.TODO/PLAN_PhaseD_Harden_2026-04-03.md`
- Session Log: `docs/LOG/SESSION_PLAN_PhaseD_Harden_2026-04-03.md`
- Docs Sync: `.TODO/DOCS_SYNC_2026-04-04_PhaseD.md`
- System Evolution: `docs/LOG/SYSTEM_EVOLUTION_REPORT_2026-04-04.md`

---

## 🏷️ Quality Audit Phase C — Critical Tests (2026-04-02)

### ✅ Implemented

**5 ViewModel Test Suites (162 tests):**
- `AuthSessionViewModel` (32 tests): session lifecycle, auth stream events (signedIn/signedOut/tokenRefreshed/passwordRecovery/userUpdated), profile loading with retry, logout, session expiry flag consumption, dispose safety
- `WalletViewModel` (36 tests): balance + activity parallel fetch, `ensureLoaded` deduplication, cursor-based pagination, withdrawal with AccountGuard check, FormatException vs generic error distinction
- `TenderPaymentViewModel` (53 tests): submit happy path, WebView redirect flow, payment recovery, error mapping for 5 specific error codes (INVALID_STATE, PAYMENT_NOT_SUCCESS, PAYMENT_DEADLINE_EXPIRED, FORBIDDEN, TASK_REQUEST_NOT_FOUND), edge cases (expired deadline, already processing)
- `ChatViewModel` (21 tests): conversation CRUD, message send/fetch, direct offer actions, realtime subscription lifecycle, role switch teardown, dispose with `_mounted` guard
- `DashboardViewModel` (20 tests): construction with role loading, role switch with data refresh, lazy-loaded tab data (overview on init, bookings/inbox on demand), dispose safety with `_safeNotify` and `_abortIfDisposed`

**7 New Model/DTO Test Files (129 tests):**
- `UserProfile` (10): fromMap/toMap, all-nullable fields, UTC enforcement on forceLogoutAfterUtc
- `ProfileModel` (22): defaults (activeRole='client', accountStatus='active', skills=[]), copyWith, UTC on createdAt/forceLogoutAfterUtc
- `Conversation` (22): last_message as Map/List/emptyList/null (4 branches), taskTitle flat vs nested fallback, otherUserTyping default, presenceUpdatedAt, copyWith preserving presence
- `ChatOfferPayload` (25): price type coercion (int/num/String), days vs legacy delivery fallback, toMap writes 'days' not 'delivery'
- `WalletBalanceModel` (8): all fields default to 0, zero() factory
- `WalletActivityModel` (11): numeric defaults, currency='IQD' default, UTC on createdAtUtc
- `DirectOffer` (31): 22-field parsing, type coercion on price/days/feeRateAppliedBps, 8 nullable DateTimes, 6 computed getters

**4 Existing Model Test Extensions (18 tests):**
- `BookingModel` (+6): minimal JSON defaults, unknown status fallback, British 'cancelled' spelling, dueAtUtc fallback chain, round-trip for all BookingStatus values
- `Message` (+5): null attachments, toJson excludes nulls, attachmentSize coercion, round-trip, MessageType enum round-trip
- `Task` (+4): minimal JSON, TaskStatus round-trips, 'in_progress' vs 'inProgress' mapping, owner_id vs user_id fallback
- `TaskRequest` (+3): all-optional defaults, OfferStatus round-trips, unknown status to OfferStatus.unknown

**Infrastructure:**
- Refactored `WalletViewModel` constructor: added optional `repo`, `accountGuardService` params (additive, backwards-compatible)
- Refactored `ChatViewModel` constructor: added optional `repo`, `accountGuardService`, `directOffersService` params. Fields use `final` via initializer list.
- Created `test/helpers/mock_services.dart`: 8 shared mock classes (MockWalletRepository, MockAccountGuardService, MockChatRepository, MockDirectOffersService, MockDashboardRepository, MockDashboardCacheService, MockBookingService, MockTaskService)
- Updated `test/helpers/helpers.dart` barrel to export mock_services.dart

**Production Code Fixes (pre-existing issues exposed by audit):**
- `ChatViewModel.teardownForRoleSwitch()`: moved `removeAllChannels()` from `Supabase.instance.client` to `_repo.removeAllChannels()` (MVVM violation fix)
- `ChatViewModel`: replaced `.catchError((e) {` with `.onError<Exception>()` (project convention fix)
- `DirectOffer.fromJson`: added `.toUtc()` to all 6 DateTime fields
- `Conversation.fromJson`: added `.toUtc()` to `createdAt`, `lastMessageTime`, `lastMessageSeenAt`, `presenceUpdatedAt`
- `Conversation.toJson`: added missing `last_message_sender_id` and `last_message_seen_at` fields
- `ChatRepository`: added `removeAllChannels()` method delegating to `_client.removeAllChannels()`

#### 📊 Results

- Tests: 400 → 706 (+306), 30 skipped, 0 failures
- VMs tested: 9/26 (35%) → 14/26 (54%)
- flutter analyze: 0 issues
- Architecture guard: all 6 checks pass

#### 📋 References

- Plan: `.TODO/PLAN_CriticalTests_2026-04-02.md`
- Session log: `docs/LOG/SESSION_PLAN_CriticalTests_2026-04-02.md`
- Master report: `.TODO/MASTER_REPORT_2026-04-02_PhaseC.md`
- System evolution: `docs/LOG/SYSTEM_EVOLUTION_REPORT_2026-04-02_v2.md`
- Audit: `.TODO/AUDIT_Quality_Architecture_2026-04-01.md` (Phase C section updated)

---

## 🏷️ Quality Audit Phase B — Bug Exposure (2026-04-01)

### ✅ Implemented

- **Unawaited Futures (48 → 0):** All 48 `unawaited_futures` violations resolved across 24 files. Navigator.push, StreamSubscription.cancel, and ViewModel refresh calls wrapped in `unawaited()`. Supabase query builder `.lt()` calls fixed with reassignment pattern (NOT `unawaited()`).
- **Bare Catch Blocks (258 → 0):** All 258 `avoid_catches_without_on_clauses` violations fixed across 85 files. Changed `catch (e)` to `on Exception catch (e)`. RLS tests use `on PostgrestException catch` for precision. Two places needed `on Error catch` fallback for `Supabase.instance` initialization in tests (`auth_form_view_model.dart`, `notification_view_model.dart`).
- **MVVM Violations (6 → 0):** (B4) Removed `Supabase.instance` from `submit_request_sheet.dart` — uses `context.read<AuthSessionViewModel>()`. (B5) Moved `TextEditingController`s from `ProfileViewModel` to `EditProfileScreen`. `signOut()` returns bool, no `BuildContext`. `pickAndUploadPortfolioImage()` and `pickAndUploadAvatar()` use error state fields. `material.dart` replaced with `foundation.dart`. (B6) `UserProfileViewModel` no longer imports `ChatScreen` or calls `Navigator.push`. (B7) 3 views no longer import repositories — `TaskViewModel.loadCategories()`, `PublicProfileViewModel()` self-constructs, `TaskRequestsViewModel` defaults `ProposalRepository`.
- **Architecture Guard Graduated:** Changed from `exit 0` (warning-only) to `exit 1` (hard failure). All 6 checks pass clean. Check 3 refined to exclude DI constructor defaults.
- **Additional Fixes:** Fixed `notifyListeners()` during build (deferred via `addPostFrameCallback`). Fixed bid sheet rapid-fire spam (added `_isShowingBidSheet` guard). Fixed query builder pagination (`.lt()` reassignment instead of `unawaited()`). Fixed `unnecessary_type_check` (11) and `unused_catch_clause` (10) warnings.
- **System Evolution:** Produced `docs/LOG/SYSTEM_EVOLUTION_REPORT_2026-04-02.md`. Added 7 new rules to agent system: Error vs Exception (Architect §3.2.1), notifyListeners timing (§3.4.1), async callback guards (§3.4.2), query builder pattern (§4.5), test mock audit (Executor Step 3.2), sub-phase test gate (Step 3.1), runtime smoke test (Orchestrator Stage 11.5).

### 📊 Impact

- `flutter analyze` dropped from 456 (Phase A baseline) → 0 issues.
- All 400 tests pass, 30 skipped, 0 failures.
- Architecture guard now hard-blocks PRs with MVVM violations.
- Agent system upgraded with 7 evidence-based rules from session analysis.

### 🔗 References

- Audit: `.TODO/AUDIT_Quality_Architecture_2026-04-01.md` (Phase B marked DONE)
- Session Log: `docs/LOG/SESSION_PhaseB_BugExposure_2026-04-01.md`
- Master Report: `.TODO/MASTER_REPORT_2026-04-01_PhaseAB.md`
- System Evolution: `docs/LOG/SYSTEM_EVOLUTION_REPORT_2026-04-02.md`
- DEVELOPER_GUIDE.md: updated §10.1 (guard status), added §10.4-10.6 (error handling, timing, query builder)
- MVP_ROADMAP.md: updated §8 (architecture guard completed, Phase B completed)

---

## 🏷️ Quality Audit Phase A — CI/CD, Lint Rules, Architecture Guard (2026-04-01)

### ✅ Implemented

- **CI/CD — GitHub Actions:** Created `.github/workflows/ci.yml` with 4 jobs: Lint & Analyze (`dart format --set-exit-if-changed` + `flutter analyze --no-fatal-infos`), Architecture Guard (6 MVVM boundary checks, warning-only), Unit & Widget Tests (`flutter test --coverage` with lcov parsing to GitHub step summary), Build (APK debug + Web release matrix). Flutter 3.38.9 pinned. Triggers on `main` push/PR. Concurrency group with cancel-in-progress. Workflow-level `permissions: contents: read` for least-privilege.
- **CI/CD — Architecture Guard:** 6 grep-based checks detect: (1) `Supabase.instance` in view layer, (2) view imports in viewmodels, (3) `Supabase.instance` in viewmodels, (4) `TextEditingController`/`GlobalKey<FormState>` in viewmodels, (5) `Navigator` calls in viewmodels, (6) repository imports in view layer. All violations output as `::warning::` annotations. Currently warning-only (`exit 0`); graduates to hard failure after Phase B.
- **Pre-commit Hook:** Created `.githooks/pre-commit` with explicit failure messaging. Runs `dart format --set-exit-if-changed .` and `flutter analyze --no-fatal-infos`. Enable: `git config core.hooksPath .githooks`. Documented in `CLAUDE.md` under "Setup (First Time)".
- **Lint Rules:** Upgraded `analysis_options.yaml` from 18 to 34 rules. Added 7 safety rules (`cancel_subscriptions`, `close_sinks`, `no_duplicate_case_values`, `throw_in_finally`, `unnecessary_statements`, `literal_only_boolean_expressions`, `no_adjacent_strings_in_list`) and 9 code quality rules (`prefer_final_locals`, `avoid_void_async`, `prefer_if_null_operators`, `prefer_null_aware_operators`, `prefer_collection_literals`, `unnecessary_await_in_return`, `use_super_parameters`, `depend_on_referenced_packages`, `sort_child_properties_last`). Impact: +12 new issues only. Safety rules caught zero new violations.
- **Test Fix:** Fixed timezone-sensitive widget test `test/widget/wallet/wallet_shared_body_test.dart`. Root cause: test used UTC-relative timestamps (`now.subtract(Duration(hours: 2))`) which fell on "yesterday" in local time when UTC offset crossed midnight. Fix: use local noon (`DateTime(year, month, day, 12).toUtc()`) for stable "Today" bucket. Also replaced fixed-pixel scroll with `tester.scrollUntilVisible`. All tests pass: 400 pass / 30 skip / 0 fail.
- **Gitignore:** Added `coverage/` and secret file patterns (`.env*`, `*.pem`, `*.p12`, `*.jks`, `secrets.json`, `credentials.json`).

### 📊 Impact

- Every push/PR to `main` is now gated by format, analysis, tests, and build checks.
- MVVM violations are visible in CI as warnings (6 documented violations currently detected).
- Pre-commit hook blocks developers from committing unformatted or warning-level code locally.
- 34 lint rules enforce type safety, resource cleanup, immutability, and dependency hygiene.
- Test suite baseline established: 400 pass, ~27% line coverage.

### 🔗 References

- Audit: `.TODO/AUDIT_Quality_Architecture_2026-04-01.md` (Sections 3, 5, 6)
- CI: `.github/workflows/ci.yml`
- Hook: `.githooks/pre-commit`
- Lint: `analysis_options.yaml`
- CLAUDE.md: updated with "Setup (First Time)" and "CI/CD" sections
- DEVELOPER_GUIDE.md: updated §10 (Testing & Quality) with §10.1–10.3
- MVP_ROADMAP.md: updated §8 (Quality and Operations) with CI/CD, lint, guard rows
- STRUCTURE.md: updated top-level overview to include `.github/`, `.githooks/`, `analysis_options.yaml`

---

## 🏷️ replace_task_request, system config, ledger & app fixes (2026-03-22)

### ✅ Implemented

- **DB — replace_task_request:** Migrations `20260322000002`–`20260322000005`: Single overload `(p_task_id, p_freelancer_id, p_message, p_price NUMERIC, p_days)`; removed `active_role` gate so replace works regardless of dashboard role; final behavior in `20260322000005_replace_task_request_update_in_place.sql` **updates the existing pending row in place** (price, days, note, updated_at) so no second row is created and `uq_task_requests_one_active_per_freelancer` is never violated. Errors include `no_pending_offer_to_replace`. See SUPABASE_SETUP §9.6, DEVELOPER_GUIDE §4.3.
- **DB — get_public_system_config:** Migration `20260322000000_ensure_get_public_system_config.sql` ensures `system_config` table and `get_public_system_config()` RPC exist; grants to anon/authenticated. Fixes "Failed to fetch" when app shell or account guard call the RPC.
- **DB — Ledger parameter 40:** Migration `20260322000001_ledger_parameter_40_text_cast.sql` patches `process_payment_event_ledger` so enum parameters use explicit text-then-enum cast, fixing "type of parameter 40 (booking_status_enum) does not match that when preparing the plan (text)" on approve delivery.
- **App — Wallet:** `WalletViewModel`: after withdrawal, refresh both balance and activities (`Future.wait`); `ensureLoaded()` uses `_loadingFuture` so concurrent callers await the same load.
- **App — Error mapper:** Generic user-facing messages (no "apply migrations"); wrapped-exception handling with `_looksLikeTechnicalMessage`; replace-offer ambiguity and technical leaks addressed; `no_pending_offer_to_replace` mapped in `TaskRequestsService._mapReplaceOfferError`.

### 📊 Impact

- Replace bid works from any dashboard role and no longer hits duplicate key; app shell and account guard no longer fail on missing system config; approve delivery no longer fails on ledger parameter type; wallet UI stays consistent after withdrawal; users see friendly errors instead of technical ones.

### 🔗 References

- SUPABASE_SETUP §9.6, §17 Version 2.20.2; DEVELOPER_GUIDE §4.3; FEATURE_BID_FLOW.md; migrations `supabase/migrations/20260322*`.

---

## 🏷️ Hardened Payment Linking (2026-03-08)

**Plan:** `.TODO/PLAN_HardenedPaymentLinking_2026-03-08_PlanCritic.md`  
**Execution log:** `.TODO/EXECUTION_LOG_HardenedPaymentLinking_2026-03-08.md`  
**Master report:** `.TODO/MASTER_REPORT_2026-03-08_HardenedPaymentLinking.md`

### ✅ Implemented

- **DB:** `20260308200000_hardened_payment_linking_schema.sql` — payment_intents (signature, currency, paid_at), orphan_payments (investigated), payment_events RLS (service_role INSERT only) + trigger trg_payment_events_append_only, payment_intents policy service_role_all_payment_intents. `20260308200100_hardened_payment_ledger_meta_payment_intent_id.sql` — process_gateway_escrow_direct_offer and process_payment_event_ledger (gateway_escrow branch) merge payment_intent_id from p_meta into journal_entries.meta.
- **Edge:** qicard_webhook_handler: when additionalInfo.intent_id present, handleIntentBasedPayment (lookup intent, insert payment_events, validate amount/currency, call submit* with paymentIntentId, update payment_intents). _shared/bookin_payment.ts: optional paymentIntentId in submitGatewayEscrowHold and submitDirectOfferGatewayEscrow, passed in p_meta. Structured logs: intent_path_processed, intent_path_orphan (no PII).
- **App:** qicard_payment_service parses intent_id from create response (booking + direct offer); payment_service QiCardDirectOfferPaymentResult.intentId; PaymentWebViewScreen optional paymentIntentId + paymentIntentStatusStream (pops on Realtime succeeded/failed); DirectOfferDetailsViewModel.streamPaymentIntentStatus; direct_offer_details_screen passes intentId + stream when present. Booking checkout already subscribed when intentId != null.

### 📊 Impact

- Every gateway payment can be tied to a payment_intent; webhook events audited in payment_events; ledger stores payment_intent_id for forensics; app can resolve success via Realtime when create returns intent_id (booking + direct offer).

### 🧪 Verification

- Plan: `.TODO/PLAN_HardenedPaymentLinking_2026-03-08_PlanCritic.md`
- Execution log: `.TODO/EXECUTION_LOG_HardenedPaymentLinking_2026-03-08.md`
- Master report: `.TODO/MASTER_REPORT_2026-03-08_HardenedPaymentLinking.md`
- Orchestrator reports: `.TODO/ARCHITECT_REPORT_2026-03-08_HardenedPaymentLinking.md`, `.TODO/OBSERVABILITY_REPORT_2026-03-08_HardenedPaymentLinking.md`, `.TODO/DOCS_REPORT_2026-03-08_HardenedPaymentLinking.md`, `.TODO/CODEGUARD_REVIEW_2026-03-08_HardenedPaymentLinking.md`
- Checklist: `.TODO/improvement_the_system/ImplementReady/24_hardened_paymentLinking_system/CHECKLIST_AND_SUMMARY.md`

### 🔧 Technical Notes

- Migrations applied via Supabase MCP. HMAC in create edge and webhook signature verification deferred (PAYMENT_HMAC_SECRET). Legacy webhook path (no intent_id) unchanged. Contract and logging rules: `.TODO/improvement_the_system/ImplementReady/24_hardened_paymentLinking_system/CONTRACT_HardenedPaymentLinking.md`, `LOGGING_AND_SECRETS.md`.

---

## 🏷️ Booking Lifecycle hardening (2026-03-08)

**Plan:** `.TODO/PLAN_BookingLifecycle_2026-03-08_PlanCritic.md` (section H)  
**Execution:** `.TODO/EXECUTION_LOG_PLAN_BookingLifecycle_2026-03-08.md`  
**Master report:** `.TODO/MASTER_REPORT_2026-03-08_BookingLifecycle.md`

### ✅ Implemented

- **DB:** Enum `disputed`, `no_show` (`20260308210000_booking_lifecycle_enum.sql`); `fn_booking_guard` replaced — client cannot delivered→canceled, client can delivered→disputed, admin only disputed→completed/refunded, provider/admin active→no_show (`20260308210100_booking_lifecycle_guard.sql`); `rpc_finalize_auto_approval` booking branch calls `process_payment_event_ledger('release_with_fee', ...)` (`20260308210200_rpc_finalize_auto_approval_booking_ledger.sql`); `admin_resolve_booking_dispute` RPC (`20260308210300_admin_resolve_booking_dispute.sql`); ledger patch for disputed+admin (`20260308210400_ledger_allow_disputed_booking_admin.sql`).
- **App:** `BookingStatus.disputed`; guard in `BookingService.updateBookingStatus` (client+delivered+cancel → StateError); StatusPresenter and UI for disputed/no_show; ViewModel treats StateError (guard) as warning log only (no crash report).
- **Docs:** 05_booking-lifecycle.md, SUPABASE_SETUP (§4.2, §9), DEVELOPER_GUIDE, MVP_ROADMAP, Sline_Log, STRUCTURE updated.

### 🔗 References

- Plan Critic: `.TODO/PLAN_BookingLifecycle_2026-03-08_PlanCritic.md`
- Execution log: `.TODO/EXECUTION_LOG_PLAN_BookingLifecycle_2026-03-08.md`
- Diagram: `Sline_everything/AppDigram/All_Diagrams/05_booking-lifecycle.md`

---

## 🏷️ Notification Routing — Push queue, Edge, foreground sync (2026-03-08)

**Plan:** `.TODO/PLAN_NotificationRouting_2026-03-08_PlanCritic.md`  
**Execution:** `.TODO/EXECUTION_LOG_Plan_NotificationRouting_2026-03-08.md`  
**Master report:** `.TODO/MASTER_REPORT_2026-03-08_NotificationRouting.md`  
**Runbook:** `.TODO/improvement_the_system/ImplementReady/13_notification-routing/RUNBOOK_notification_push.md`  
**Checklist:** `.TODO/improvement_the_system/ImplementReady/13_notification-routing/CHECKLIST_AND_SUMMARY.md`

### ✅ Implemented

- **DB:** `user_devices` (user_id, fcm_token, platform) with RLS own-only; `notification_push_queue` (notification_id, user_id, title, message, type, status); trigger `trg_notifications_after_insert_push_queue` enqueues on notifications INSERT. SUPABASE_SETUP §5.13a, §5.13b.
- **App:** `lib/features/notifications/services/push_device_service.dart` — registerDevice → user_devices upsert (login/resume/token refresh when FCM available); `NotificationService.getUnreadNotifications(50)`; ViewModel fetches unread first (foreground sync) then streams latest 50. No client INSERT into notifications.
- **Edge:** `push-notify` (single payload; optional PUSH_NOTIFY_SECRET); `process-push-queue` (batch drain; requires CRON_SECRET, 503 if unset). Observability: notification_id in error logs; push_batch structured log (processed, sent, failed).
- **Docs:** Diagram 13 updated (user_devices, queue, trigger, Edge, foreground sync, booking source); DEVELOPER_GUIDE §3 Notifications bullet; SUPABASE_SETUP §5.13a–5.13b, runbook ref; MVP_ROADMAP, STRUCTURE, Sline_Log.

### 📊 Impact

- In-app notifications: server-authority, foreground sync then stream, badge/modal/deep links. Push: device tokens in user_devices; server-only delivery via queue + Edge → FCM.

### 🔗 References

- Plan: `.TODO/PLAN_NotificationRouting_2026-03-08_PlanCritic.md`
- Execution log: `.TODO/EXECUTION_LOG_Plan_NotificationRouting_2026-03-08.md`
- Master report: `.TODO/MASTER_REPORT_2026-03-08_NotificationRouting.md`
- Runbook: `.TODO/improvement_the_system/ImplementReady/13_notification-routing/RUNBOOK_notification_push.md`
- Diagram: `Sline_everything/AppDigram/All_Diagrams/13_notification-routing.md`

---

## 🏷️ Post-14a fixes and tender/docs sync (2026-03-08)

**Workflow:** `.agents/workflows/slinedocs.md`  
**Docs sync note:** `.TODO/DOCS_SYNC_2026-03-08_DocsKeeperUpToDate.md`

### ✅ Implemented

- **DB (Supabase):**
  - **20260308170000** — `rpc_submit_dispute` task branch allows dispute when task is in_progress/delivered **or** any booking for that task is active/delivered (fixes "Entity not eligible" when reporting from booking).
  - **20260308180000** — Tender assign only after payment: `accept_task_request` and `award_task_offer` reserve task only (status = assigned, no freelancer_id); `pay_awarded_offer` assigns freelancer and sets in_progress. `task_requests.payment_status = 'unpaid'` set on accept/award.
  - **20260308180100** — Dropped `award_task_offer(uuid, bigint)` overload; only 3-param version remains (fixes "Could not choose the best candidate function").
  - **20260308190000** — `vw_unified_work_items` shows `unified_status = 'disputed'` only when linked dispute has `status IN ('open', 'active')` (was NOT IN ('resolved','closed'); enum has `canceled` not `closed`). Per 14a diagram.
- **App:**
  - **Inbox Pay Now:** `TaskService.getOffersReceived` now includes accepted+unpaid offers (filter: `.or('status.eq.pending,and(status.eq.accepted,payment_status.eq.unpaid)')`) so client sees awarded offers in Inbox with Pay Now button. `lib/features/tasks/services/task_service.dart`.
  - **Work item Report Issue for booking:** `work_item_details_screen.dart` — `_canShowReportIssue` allows booking when `vm.booking?.taskId` present; `_ReportIssueGuard` uses `hasOpenDisputeForBooking(entityId)` for booking; `_showDisputeDialog` submits via `submitDispute(taskId: vm.booking!.taskId!, ...)` for booking.
  - **Work item action row overflow:** Action row wrapped in `SingleChildScrollView` (horizontal) with `Row(mainAxisSize: MainAxisSize.min)` so Extension/Submit Work/Review/Report Issue/Message don’t overflow on narrow screens. `lib/features/work/view/work_item_details_screen.dart`.

### 📊 Impact

- Clients can pay from Inbox after awarding; booking disputes work from work item when opened as booking; disputed state only for open/active disputes; award no longer assigns before payment.

### 🔗 References

- SUPABASE_SETUP §17 changelog (20260308170000, 20260308180000, 20260308180100, 20260308190000)
- STRUCTURE recent migrations; DEVELOPER_GUIDE dispute and tender sections
- Diagram: `Sline_everything/AppDigram/All_Diagrams/14a_dispute-entity-freeze-integration.md`

---

## 🏷️ Unified Work View — 4-branch upgrade, direct offers, no fallbacks (2026-03-08)

**Plan:** `.TODO/PLAN_UnifiedWorkView_2026-03-08_CRITIC.md`  
**Execution:** `.TODO/EXECUTION_LOG_PLAN_UnifiedWorkView_2026-03-08_CRITIC.md`  
**Master report:** `.TODO/MASTER_REPORT_2026-03-08_UnifiedWorkView.md`  
**Docs sync:** `.TODO/DOCS_SYNC_2026-03-08_UnifiedWorkView.md`

### ✅ Implemented

- **DB:** Migration `20260308110000_upgrade_unified_work_view.sql` — `vw_unified_work_items` upgraded to 4 branches (tasks in progress, bookings, awarded pending payment, **direct_offers**); dispute override; `conversation_id` for direct offers; `security_invoker = true`. Rollback: `20260308100000_rollback_unified_work_view.sql` restores 3-branch view.
- **App:** Single source of truth: `WorkManagementService` and `DashboardRepository` read only from the view; removed `UnifiedWorkItemFallbackMapper` and file `unified_work_item_fallback_mapper.dart`; removed dashboard fallbacks `_fetchAwardedPendingPaymentFallback`, `_fetchDirectOffers`, and merge logic. `_mapUnifiedToWorkItem` supports `source_type == 'direct_offer'` → `WorkItemType.directOffer` with `conversationId`. When view returns no row, work detail shows "Work item not found" (no booking fallback). AppLogger with tags `WorkDetails` and `WorkManagement`; type-safe `Map<String, dynamic>.from(e as Map)` in list.
- **Tests:** Replaced `unified_work_item_fallback_mapper_test.dart` with `unified_work_item_view_contract_test.dart` (fromJson for task, direct_offer, pending_payment, conversation_id).
- **Docs:** SUPABASE_SETUP §6.4 (four branches, direct_offers, security_invoker); DEVELOPER_GUIDE work section (single source of truth, no fallbacks); Sline_Log system map entry (Unified Work View); contract `.TODO/contract_vw_unified_work_items.md`; checklist `.TODO/CHECKLIST_AND_SUMMARY_UnifiedWorkView.md`.

### 📊 Impact

- Work list and detail come only from `vw_unified_work_items`; direct offers appear in My Work with correct conversation deep link; clear "not found" when view has no row.

### 🔗 References

- Plan (Critic): `.TODO/PLAN_UnifiedWorkView_2026-03-08_CRITIC.md`
- Execution log: `.TODO/EXECUTION_LOG_PLAN_UnifiedWorkView_2026-03-08_CRITIC.md`
- Master report: `.TODO/MASTER_REPORT_2026-03-08_UnifiedWorkView.md`
- Contract: `.TODO/contract_vw_unified_work_items.md`
- Diagram: `Sline_everything/AppDigram/All_Diagrams/12_unified-work-view.md`

### 🔧 Technical Notes

- View uses alias `doff` for `direct_offers` (PostgreSQL reserves `do`). Dispute JOIN: task_id for tasks/bookings, direct_offer_id for direct_offers; "open" = status IN ('open','active').

---

## 🏷️ 14a Dispute Extension — Frozen guards, unique index, Report Issue (task/direct_offer), banners (2026-03-08)

**Plan:** `.TODO/PLAN_14a_DisputeExtension_2026-03-08.md`  
**Execution:** `.TODO/EXECUTION_LOG_14a_DisputeExtension_2026-03-08.md`  
**Master report:** `.TODO/MASTER_REPORT_2026-03-08_14aDisputeExtension.md`

### ✅ Implemented

- **Migration:** `20260308160000_14a_dispute_extension_frozen_guards.sql` — rpc_submit_delivery restored with Frozen guard (task, booking); rpc_request_revision Frozen guard (task, booking); partial unique indexes uq_disputes_one_open_active_per_task, uq_disputes_one_open_active_per_direct_offer; rpc_submit_dispute (eligibility + single open/active per entity). Applied via Supabase MCP.
- **App:** DisputeService submitDispute(taskId | directOfferId) via rpc_submit_dispute; getDisputeStatusForTask/ForBooking/ForDirectOffer; ErrorMapper for Frozen and dispute-submit errors; work item details Report Issue for task and direct_offer; direct offer details Report Issue; booking/details Report Issue when active or delivered (with dispute guard); open/active dispute banners on all three screens.
- **Docs:** SUPABASE_SETUP §9.1, §9.2, §9.2a, §17; DEVELOPER_GUIDE dispute entry points and Frozen behaviour; MVP_ROADMAP, STRUCTURE, Sline_Log.

### 🔗 References

- Plan: `.TODO/PLAN_14a_DisputeExtension_2026-03-08.md`
- Spec: `Sline_everything/AppDigram/All_Diagrams/14a_dispute-entity-freeze-integration.md`

---

## 🏷️ Dispute Lifecycle — escrow guard, RLS, enum, UI (2026-03-08)

**Plan:** `.TODO/PLAN_DisputeLifecycle_2026-03-08.md`  
**Execution:** `.TODO/EXECUTION_LOG_DisputeLifecycle_2026-03-08.md`  
**Master report:** `.TODO/MASTER_REPORT_2026-03-08_DisputeLifecycle.md`

### ✅ Implemented

- **Migrations:** `20260308140000_dispute_lifecycle_escrow_guard_rls.sql` (escrow guard in rpc_approve_delivery and rpc_finalize_auto_approval; deny policies on disputes; RLS on dispute_messages and dispute_evidence; indexes). `20260308150000_dispute_enum_guard_resolved_at.sql` (dispute_status_enum; triggers trg_dispute_guard, trg_dispute_set_resolved_at; vw_unified_work_items recreated with enum-safe disputed check).
- **App:** DisputeService hasOpenDisputeForTask, hasOpenDisputeForBooking, hasOpenDisputeForDirectOffer; SafetyViewModel exposes them; _ApproveWithDisputeGuard on booking details and direct offer details; _ReviewWithDisputeGuard and disputed banner on work item details; booking details uses hasOpenDisputeForBooking(booking.id).
- **Test:** `test/unit/safety/dispute_service_test.dart` (submitDispute and validation tests).
- **Docs:** SUPABASE_SETUP §1, §5.24–5.26, §6.4, §17; DEVELOPER_GUIDE §5.3 dispute lifecycle; STRUCTURE test + migrations; MVP_ROADMAP; diagram 14; this Sline_Log entry.

### 🔗 References

- Plan: `.TODO/PLAN_DisputeLifecycle_2026-03-08.md`
- Execution log: `.TODO/EXECUTION_LOG_DisputeLifecycle_2026-03-08.md`
- Master report: `.TODO/MASTER_REPORT_2026-03-08_DisputeLifecycle.md`
- DOCS_REPORT: `.TODO/DOCS_REPORT_2026-03-08_DisputeLifecycle.md`
- RLS matrix: `.TODO/improvement_the_system/ImplementReady/14_dispute-lifecycle/RLS_CHECK_MATRIX.md`

---

## 🏷️ Work Contract Revisions — RPC hardening (2025-03-08)

**Workflow:** `.agents/workflows/slinedocs.md`  
**Docs sync note:** `.TODO/DOCS_SYNC_2026-03-08_WorkContractRevisions.md`

**Plan:** `.TODO/PLAN_WorkContractRevisions_2025-03-08_PlanCritic.md`  
**Execution:** `.TODO/EXECUTION_LOG_WorkContractRevisions_2025-03-08.md`  
**Review:** `.TODO/MASTER_REPORT_2025-03-08_WorkContractRevisions.md`

### ✅ Implemented

- **Migration:** `supabase/migrations/20260308120000_harden_rpc_request_revision.sql` — `rpc_request_revision` now enforces state guard (status = 'delivered') and cap guard (revisions_used < revisions_total) for task and booking; applied via Supabase MCP.
- **App:** ErrorMapper branches for "Can only request revision on delivered work", "No revisions remaining", "Only client can request revision"; WorkItemDetailsViewModel uses ErrorMapper in requestRevision and acceptChangeRequest catch; ReviewDeliveryModal shows getRevisionError and disables "Request Changes" when no revisions left; WorkManagementService logs success/error with tag and outcome.
- **Docs:** SUPABASE_SETUP §9.2 and §1 updated; DEVELOPER_GUIDE work table note for revision error mapping.

### 🔗 References

- Plan (Critic): `.TODO/PLAN_WorkContractRevisions_2025-03-08_PlanCritic.md`
- Execution log: `.TODO/EXECUTION_LOG_WorkContractRevisions_2025-03-08.md`
- Master report: `.TODO/MASTER_REPORT_2025-03-08_WorkContractRevisions.md`

---

## 🏷️ Docs Sync — Realtime Topology (18) reference integrity (2026-03-08)

**Workflow:** `.agents/workflows/slinedocs.md`  
**Note:** `.TODO/DOCS_SYNC_2026-03-08_RealtimeTopology.md`

### ✅ Updated

- **DEVELOPER_GUIDE.md:** Chat message_service description and §7 Realtime bullet — "messages (active chat + Inbox)" only; conversations not in realtime publication; link to diagram 18.
- **DEVELOPER_GUIDE/Chat Feature.md:** §7 Realtime bullet — same correction (messages stream only; diagram 18).
- **MVP_ROADMAP.md:** Realtime chat row — added 18_topology; Inbox subscribeToInboxMessages; plan 18 and diagram 18 refs.
- **STRUCTURE.md:** Chat bullet — Inbox realtime subscribeToInboxMessages; diagram 18 and plan 18 refs.

### 📊 Impact

- No remaining "Subscribe to messages and conversations streams" in core docs. Single source of truth: Inbox = messages stream (receiver_id); conversations not in publication.

### 🔗 References

- DOCS_SYNC: `.TODO/DOCS_SYNC_2026-03-08_RealtimeTopology.md`
- Plan 18: `.TODO/PLAN_RealtimeSubscriptionTopology_2026-03-07.md`
- Diagram 18: `Sline_everything/AppDigram/All_Diagrams/18_realtime-subscription-topology.md`

---

## 🏷️ Chat Realtime Sync — Presence, Receipts, Feature Flag (2026-03-08)

**Date:** 2026-03-08  
**Plan:** `.TODO/PLAN_ChatRealtimeSync_2026-03-07_PlanCritic.md`  
**Execution:** `.TODO/EXECUTION_LOG_ChatRealtimeSync_2026-03-07.md`

### ✅ Implemented

- **Presence:** `conversation_presence` table (conversation_id, user_id, is_typing, updated_at); RLS policies (participant SELECT, self INSERT/UPDATE); table in `supabase_realtime`; client 15s TTL for typing; 5s throttle on upsert.
- **Receipts:** `delivered_at`/`seen_at` on messages; RPCs `mark_conversation_delivered`, `mark_conversation_seen`; UI ticks (sent/delivered/read) when feature flag on.
- **Feature flag:** `app_config.chat_presence_receipts_enabled` (`'true'`/`'false'`); when false, no presence upsert, no receipt ticks (single tick only).
- **Realtime merge:** ChatRealtimeMerger in ViewModel; accumulation in ViewModel (`_lastMessages`); stream error restores last list.
- **Migrations:** `20260307219900_chat_presence_and_rls_full.sql` (canonical: table, RLS, publication, app_config), `20260307220000_chat_realtime_presence_publication.sql` (idempotent ADD TABLE), `20260307220100_chat_presence_receipts_flag.sql` (app_config insert).

### 🔗 References

- Plan: `.TODO/PLAN_ChatRealtimeSync_2026-03-07_PlanCritic.md`
- Execution log: `.TODO/EXECUTION_LOG_ChatRealtimeSync_2026-03-07.md`
- Contract: `.TODO/08_chat_realtime_contract.md`
- RLS matrix: `.TODO/RLS_Matrix_Chat_2026-03-07.md`
- RLS verification: `.TODO/08_RLS_verification_chat.md`
- Master report: `.TODO/MASTER_REPORT_2026-03-08_ChatRealtimeSync.md`
- Checklist & app verification: `.TODO/CHECKLIST_AND_SUMMARY_ChatRealtimeSync_Fixes_2026-03-08.md`
- Docs sync (this pass): `.TODO/DOCS_SYNC_2026-03-08_DocsKeeperUpToDate.md`

---

## 🏷️ Direct Chat Offer Flow — Hardening (2026-03-08)

**Date:** 2026-03-08  
**Plan:** `.TODO/PLAN_DirectChatOfferFlow_2026-03-07_CRITIC.md`  
**Execution Log:** `.TODO/EXECUTION_LOG_DirectChatOfferFlow_2026-03-07_CRITIC.md`

### ✅ Implemented

- **Migrations:** `20260319000000_direct_offer_flow_harden.sql` (currency, payment_*, delivered_at, review_expires_at on direct_offers; direct_offer_id and chk_dispute_entity on disputes; idx_direct_offers_processing); `20260319110000_direct_offer_guard_rls_ledger.sql` (trigger protect price/currency, disputes_insert_own RLS, rpc_approve_delivery fee from row); `20260319120000_direct_offer_auto_release_cron.sql` (run_auto_release_expired_direct_offers + pg_cron hourly); `20260319130000_direct_offer_protect_fee_in_trigger.sql` (trigger also protects fee_rate_applied_bps).
- **DirectOffer model:** New nullable fields (currency, feeRateAppliedBps, paymentRequestId, paymentGatewayId, paymentCorrelationId, paymentExpiresAt, paymentRecoveredAt, deliveredAt, reviewExpiresAt).
- **DirectOffersService:** acceptOfferWithoutPayment stamps fee_rate_applied_bps and currency; markDelivered sets delivered_at and review_expires_at (now + 3 days); recoverPaymentAfterCallback success log includes payment_request_id.
- **Tests:** `test/features/direct_offers/direct_offers_service_test.dart` (client cannot cancelOffer, freelancer cannot payNow, markDelivered throws when !isActive).
- **.TODO artifacts:** 06_direct_offer_contract.md, 06_direct_offer_threat_model.md, 06_direct_offer_migration_plan.md, 06_direct_offers_rls_matrix.md.

### 🔗 References

- Plan: `.TODO/PLAN_DirectChatOfferFlow_2026-03-07_CRITIC.md`
- Execution log: `.TODO/EXECUTION_LOG_DirectChatOfferFlow_2026-03-07_CRITIC.md`
- Master Report: `.TODO/MASTER_REPORT_2026-03-08_DirectChatOfferFlow.md`

---

## 🏷️ Plan 19 — Direct Offers Work Contract (2026-03-07 / 2026-03-08)

**Date:** 2026-03-07 (execution); 2026-03-08 (docs sync + report fixes)  
**Plan:** `.TODO/improvement_the_system/ImplementReady/19_direct-offers-work-contract/PLAN_DirectOffersWorkContract_2026-03-07.md`  
**Execution Log:** `.TODO/improvement_the_system/ImplementReady/19_direct-offers-work-contract/EXECUTION_LOG_PLAN_DirectOffersWorkContract_2026-03-07.md`

### ✅ Implemented

- **DB (Supabase):** `admin` schema; views `admin.vw_direct_offer_money_story`, `admin.vw_direct_offer_stuck_funds`; trigger `trg_direct_offer_guard_insert` + `fn_direct_offer_guard_insert` (reject INSERT when `client_id = freelancer_id`); RPC `admin_refund_direct_offer(p_offer_id, p_reason, p_idempotency_key)` — admin-only, idempotent. Migrations: `20260307180000_admin_direct_offer_views.sql`, `20260307180100_direct_offer_self_offer_guard.sql`, `20260307180200_admin_refund_direct_offer.sql`.
- **App:** `lib/features/direct_offers/services/direct_offers_service.dart` — AppLogger for accept/pay/recover/cancelAccepted/markDelivered/completeOffer (offer not found + success/failure); after Master Report fixes: AppLogger.w for "offer not found" in `rejectOffer` and `cancelOffer`.
- **Docs:** `Sline_everything/SUPABASE_SETUP.md` §5.14 — `direct_offers` table completed with columns from migrations: `fee_rate_applied_bps`, `fee_amount`, `net_amount` (`20260307_02_add_fee_columns.sql`); `currency`, `payment_request_id`, `payment_gateway_id`, `payment_correlation_id`, `payment_expires_at`, `payment_recovered_at`, `delivered_at`, `review_expires_at` (`20260319000000_direct_offer_flow_harden.sql`). No app code calls admin RPC; admin tooling is service_role/dashboard only.
- **Artifacts:** Contract `.TODO/improvement_the_system/ImplementReady/19_direct-offers-work-contract/CONTRACT_admin_refund_direct_offer.md`; RLS matrix in folder 19; execution summary in folder 19; orchestrator reports and Master Report in `.TODO/`.

### 🔗 References

- Plan: `.TODO/improvement_the_system/ImplementReady/19_direct-offers-work-contract/PLAN_DirectOffersWorkContract_2026-03-07.md`
- Execution log: `.TODO/improvement_the_system/ImplementReady/19_direct-offers-work-contract/EXECUTION_LOG_PLAN_DirectOffersWorkContract_2026-03-07.md`
- Master report: `.TODO/improvement_the_system/ImplementReady/19_direct-offers-work-contract/MASTER_REPORT_2026-03-07_DirectOffersWorkContract.md`
- Contract: `.TODO/improvement_the_system/ImplementReady/19_direct-offers-work-contract/CONTRACT_admin_refund_direct_offer.md`
- Docs sync (this pass): `.TODO/improvement_the_system/ImplementReady/19_direct-offers-work-contract/DOCS_SYNC_2026-03-08_Plan19_DirectOffersWorkContract.md`
- Checklist/summary: `.TODO/improvement_the_system/ImplementReady/19_direct-offers-work-contract/CHECKLIST_AND_SUMMARY_Plan19_DirectOffersWorkContract.md`

---

## 🏷️ Docs Sync — Reference Integrity & Full Sync (2026-03-08)

**Date:** 2026-03-08  
**Workflow:** `.agents/workflows/slinedocs.md`

### ✅ Implemented

- **Reference integrity (09/16):** All `Sline_everything/` references to ledger (09) and escrow idempotency (16) point to **Done** folders. Paths `ImplementReady/09_ledger-event-flow/` and `ImplementReady/16_escrow-invariants-idempotency/` were updated in a prior pass.
- **Reference integrity (21):** Plan 21 (Wallet System Escrow Available balances) was moved to **Done**. All references in `Sline_everything/` updated: `Sline_Log.md`, `AppDigram/All_Diagrams/21_Wallet_System_Escrow_Available_balances.md`, `DEVELOPER_GUIDE/Wallet_Feature.md`, `MVP_ROADMAP.md` now point to `.TODO/improvement_the_system/Done/21_Wallet_System_Escrow_Available_balances/`.
- **Direct Chat Offer Flow:** Sline_Log entry completed with Impact, Verification, Technical Notes; MVP_ROADMAP Direct Chat Offers row updated with hardening note and plan path; SUPABASE_SETUP and STRUCTURE Last Updated lines refreshed.
- **Diagram 09:** `Sline_everything/AppDigram/All_Diagrams/09_ledger-event-flow.md` updated to full diagram-doc standard (checklist, OLD diagram preserved, Implemented diagram v2 with forensics/idempotency/gates/withdrawal/gateway); references in diagram point to `.TODO/improvement_the_system/Done/09_ledger-event-flow/`.
- **SUPABASE_SETUP:** §6.6 `vw_wallet_activity_user` updated to match migration `20260307160000_wallet_activity_include_spent.sql` (include spent / gateway_escrow; security_invoker; new columns). Changelog §17: added bullet for this view change.

### 📊 Impact

- No dead paths in core docs; plan/contract/runbook links resolve.
- Single source of truth for wallet activity view and ledger/escrow artifact locations.

### 🔗 References

- DOCS_SYNC note: `.TODO/DOCS_SYNC_2026-03-08_DocsKeeperReferenceIntegrity.md`
- This pass (full scan + ref integrity): `.TODO/DOCS_SYNC_2026-03-08_DocsKeeperUpToDate.md` — Sline_Log 16/21 paths, MVP_ROADMAP full paths, SUPABASE_SETUP changelog bullet for wallet_activity_include_spent.
- Diagram 09: `Sline_everything/AppDigram/All_Diagrams/09_ledger-event-flow.md`
- Done 09: `.TODO/improvement_the_system/Done/09_ledger-event-flow/`
- Done 16: `.TODO/improvement_the_system/Done/16_escrow-invariants-idempotency/`

---

## 🏷️ Realtime Subscription Topology — Inbox from messages stream (2026-03-07)

**Date:** 2026-03-07  
**Plan:** `.TODO/PLAN_RealtimeSubscriptionTopology_2026-03-07.md`  
**Execution Log:** `.TODO/EXECUTION_LOG_PLAN_RealtimeSubscriptionTopology_2026-03-07.md`

### ✅ Implemented

- **Inbox realtime:** Inbox (conversation list) is driven by the **messages** stream (`receiver_id=userId`), not the `conversations` table. `subscribeToConversations` removed; `subscribeToInboxMessages(userId)` added in `message_service.dart`. ChatViewModel merges message events into the conversation list (new Conversation instances via copyWith); new conversations hydrated via `getConversationById` with guard to prevent double fetch.
- **N+1 removed:** No `.select()` or asyncMap over stream payload; no bulk `conversations ... IN (...)` in realtime handlers.
- **Publication contract:** `conversations` is **not** in `supabase_realtime`. Migration `20260307230000_realtime_topology_no_conversations.sql` enforces it (idempotent drop if ever added). Publication contains messages, notifications (and conversation_presence for typing).
- **Docs:** Diagram 18, SUPABASE_SETUP Realtime section, DEVELOPER_GUIDE Chat Feature §2.6 updated. Manual E2E script: `.TODO/improvement_the_system/ImplementReady/18_realtime-subscription-topology/MANUAL_E2E_INBOX_REALTIME.md`.
- **Review fix:** `Conversation.copyWith` preserves `otherUserTyping` and `presenceUpdatedAt` so typing indicator is not lost on Inbox merge.

### 📊 Impact

- Inbox updates in realtime when the user receives a message (no full refetch). No N+1; single stream and guarded single fetch per new conversation.
- Diagram and docs match code and DB; future misuse (adding conversations to publication) is prevented by migration.

### 🔗 References

- Plan: `.TODO/PLAN_RealtimeSubscriptionTopology_2026-03-07.md`
- Master Report: `.TODO/MASTER_REPORT_2026-03-07_RealtimeSubscriptionTopology.md`
- Diagram 18: `Sline_everything/AppDigram/All_Diagrams/18_realtime-subscription-topology.md`
- Migration: `supabase/migrations/20260307230000_realtime_topology_no_conversations.sql`

---

## 🏷️ Dashboard Wallet Tab (2026-03-07)

**Date:** 2026-03-07  
**Plan:** Dashboard Wallet Tab Implementation Plan

### ✅ Implemented

- **Dashboard:** New **Wallet** tab (5 tabs: Overview, Bookings, Work, Wallet, Inbox). `lib/features/dashboard/view/tabs/wallet_tab.dart` — total balance, available to withdraw, Coming Soon withdraw section, transaction history with Money received / Money spent subsections and source/destination labels.
- **Helper:** `lib/features/wallet/utils/transaction_label_helper.dart` — `getTransactionSourceOrDestination()`, `isReceivedTransaction()` for human-readable labels.
- **Balance rule:** All displayed balances clamped to non-negative; spent shown only in transaction rows.
- **Tests:** `test/widget/dashboard/dashboard_screen_test.dart` updated for 5 tabs.

### 📊 Impact

- **UX:** Dedicated wallet visibility in dashboard; users see balance and activity without leaving dashboard.
- **Consistency:** Reuses WalletViewModel; same data as WalletScreen and Overview snapshot.

### 🔗 References

- Master Report: `.TODO/MASTER_REPORT_2026-03-07_DashboardWalletAndEscrow.md`
- Wallet Feature: `Sline_everything/DEVELOPER_GUIDE/Wallet_Feature.md`

---

## 🏷️ Ledger Event Flow — Forensics, Contract, Tests, Runbook (2026-03-07)

**Date:** 2026-03-07  
**Plan:** `.TODO/PLAN_LedgerEventFlow_2026-03-07.md`  
**Contract:** `.TODO/improvement_the_system/Done/09_ledger-event-flow/CONTRACT_ledger_event_flow.md`

### ✅ Implemented

- **Forensics:** LedgerService injects `session_id` (auth user id) and `request_id` (per-call UUID) into `p_meta` via `lib/core/utils/ledger_forensics.dart`; single source for all ledger call sites.
- **Logging:** AppLogger only; start/success/error log lines include optional `request_id` for correlation; no PII or full meta in logs.
- **Tests:** `test/unit/wallet/ledger_service_test.dart`, `wallet_service_test.dart`, `test/rls/ledger_rls_test.dart`; 6 tests passing.
- **Docs:** DEVELOPER_GUIDE (Finance & Payment Ledger), Wallet_Feature.md updated; CONTRACT and SMOKE_CHECKLIST_AND_RUNBOOK in 09_ledger-event-flow folder.
- **Runbook:** Withdrawal orphan detection query and runbook steps in SMOKE_CHECKLIST_AND_RUNBOOK.md.

### 📊 Impact

- **Audit:** journal_entries.meta stores session_id and request_id for dispute forensics.
- **Observability:** request_id in logs enables correlation with DB journal entry.

### 🧪 Verification

- Plan: `.TODO/PLAN_LedgerEventFlow_2026-03-07.md`
- Execution Log: `.TODO/EXECUTION_LOG_PLAN_LedgerEventFlow_2026-03-07.md`
- Review: `.TODO/CODEGUARD_REVIEW_2026-03-07_LedgerEventFlow.md`
- Master Report: `.TODO/MASTER_REPORT_2026-03-07_LedgerEventFlow.md`
- Contract / Runbook: `.TODO/improvement_the_system/Done/09_ledger-event-flow/`

---

## 🏷️ Wallet Escrow Available Balances — direct_offer in rpc_approve_delivery (2026-03-07)

**Date:** 2026-03-07  
**Plan:** `.TODO/improvement_the_system/Done/21_Wallet_System_Escrow_Available_balances/PLAN_WalletEscrowAvailableBalances_2026-03-07_CRITIC.md`  
**Execution Log:** `.TODO/improvement_the_system/Done/21_Wallet_System_Escrow_Available_balances/EXECUTION_LOG_PLAN_WalletEscrowAvailableBalances_2026-03-07.md`

### ✅ Implemented

- **Database:** `rpc_approve_delivery` extended with **direct_offer** branch (migration `20260307120000_rpc_approve_delivery_direct_offer.sql`). Client can approve delivery and release escrow for direct offers; same deterministic idempotency key and FOR UPDATE pattern as booking.
- **App:** `DirectOffersService.completeOffer()` now calls `rpc_approve_delivery(entity_type: 'direct_offer', entity_id)` instead of LedgerService.submitPaymentEvent for release — single exit point for escrow release. AppLogger added for completeOffer (start, validation, error, success) and WalletService.getWalletBalance (error path).
- **Docs:** Diagram 21 (Withdraw = Upcoming; entry point wording); CONTRACT_rpc_approve_delivery, LIVE_SCAN, RLS_CHECK_MATRIX in `.TODO/improvement_the_system/Done/21_Wallet_System_Escrow_Available_balances/`; DEVELOPER_GUIDE Wallet_Feature (§4 Approve delivery), Direct_Offers_Feature (4.5), SUPABASE_SETUP §9.5 (entity_type task, booking, direct_offer).

### 📊 Impact

- **Consistency:** Booking and direct offer both use the same RPC for approve delivery; idempotency and auth enforced in one place.
- **Observability:** Wallet and direct-offer completion flows logged with AppLogger.

### 🔗 References

- Master Report: `.TODO/improvement_the_system/Done/21_Wallet_System_Escrow_Available_balances/MASTER_REPORT_2026-03-07_WalletEscrowAvailableBalances.md`
- Contract: `.TODO/improvement_the_system/Done/21_Wallet_System_Escrow_Available_balances/CONTRACT_rpc_approve_delivery.md`

---

## 🏷️ Diagram 21 + Wallet activity include spent (2026-03-08)

**Date:** 2026-03-08  
**Scope:** Documentation sync (DocsKeeper); reference integrity; diagram and schema docs aligned with implemented behaviour.

### ✅ Implemented / Updated

- **Diagram 21:** `Sline_everything/AppDigram/All_Diagrams/21_Wallet_System_Escrow_Available_balances.md` — Full checklist (Purpose, Scope, Glossary, Legend, Actors, System Components, Step-by-step Flow, State Machine, Invariants, Guards, Failure Modes, Security, Data Model, Observability, Verification, Dependencies, Open Questions, Final Status). OLD diagram (v1 legacy) retained; NEW/Implemented diagram (v2) updated with gateway_escrow, `vw_wallet_activity_user` including spent (user_available DEBIT, user_pending_withdrawal DEBIT). References fixed to use full paths under `.TODO/improvement_the_system/Done/21_Wallet_System_Escrow_Available_balances/`.
- **Wallet activity view:** Migration `supabase/migrations/20260307160000_wallet_activity_include_spent.sql` — `vw_wallet_activity_user` expanded to include client “spent” (user_available DEBIT, user_pending_withdrawal DEBIT for gateway_escrow). Documented in diagram 21, SUPABASE_SETUP changelog, DEVELOPER_GUIDE Wallet_Feature.
- **Reference fixes:** Execution log and plan paths in diagram 21 and Sline_Log corrected to full `.TODO/.../21_Wallet_System_Escrow_Available_balances/` paths. Master Report path in Sline_Log Wallet Escrow entry corrected.

### 📊 Impact

- **Single source of truth:** Diagram 21 and core docs now match implemented behaviour (direct_offer release, activity include spent, gateway_escrow).
- **Reference integrity:** No dead paths; all cross-references validated per DocsKeeper workflow.

### 🧪 Verification

- Docs sync note: `.TODO/DOCS_SYNC_2026-03-08_Diagram21_WalletDocs.md`
- Diagram 21: `Sline_everything/AppDigram/All_Diagrams/21_Wallet_System_Escrow_Available_balances.md`

### 🔗 References

- Workflow: `.agents/workflows/slinedocs.md`
- Contract: `.TODO/improvement_the_system/Done/21_Wallet_System_Escrow_Available_balances/CONTRACT_rpc_approve_delivery.md`

---

## 🏷️ Escrow Idempotency — Stable Key & FOR UPDATE (2026-03-07)

**Date:** 2026-03-07  
**Plan:** `.TODO/PLAN_EscrowInvariantsIdempotency_2026-03-07_CRITIC.md`  
**Commit:** _Pending_ — "feat(escrow): stable idempotency key + FOR UPDATE for approve delivery"

### ✅ Implemented

- **Database:** `rpc_approve_delivery` — booking branch now uses a **stable idempotency key** (entity_id + status + payment_status, no `now()`) and `SELECT ... FOR UPDATE` so retries do not double-release escrow. Duplicate index `idx_journal_entries_idempotency` dropped.
- **Migration:** `supabase/migrations/20260307000001_escrow_idempotency_stable_key.sql` (applied via Supabase MCP).
- **App:** `lib/features/work/services/work_management_service.dart` — `approveDelivery` with optional `correlationId`, AppLogger (tag WorkManagement). `lib/features/work/viewmodels/work_item_details_view_model.dart` — `approveDelivery` generates correlationId and passes to service; AppLogger (tag WorkItemDetails). `lib/features/work/view/widgets/review_delivery_modal.dart` — `_hasApproved` one-shot guard, AppLogger (tag ReviewDelivery).
- **Docs:** Diagram 16 and SUPABASE_SETUP §9.5 updated; CONTRACT and RUNBOOK in `.TODO/improvement_the_system/Done/16_escrow-invariants-idempotency/`; DEVELOPER_GUIDE Finance & Payment Ledger idempotency bullet added.

### 📊 Impact

- **Data integrity:** Approve delivery is safe to retry; at most one release per entity.
- **Observability:** Approval flow tagged and logged with optional correlationId for tracing.

### 🧪 Verification

- Plan: `.TODO/PLAN_EscrowInvariantsIdempotency_2026-03-07_CRITIC.md`
- Execution Log: `.TODO/EXECUTION_LOG_PLAN_EscrowInvariantsIdempotency_2026-03-07.md`
- Review: `.TODO/CODEGUARD_REVIEW_2026-03-07_EscrowInvariantsIdempotency.md`
- Master Report: `.TODO/MASTER_REPORT_2026-03-07_EscrowInvariantsIdempotency.md`
- RUNBOOK (T1/T2/T4): `.TODO/improvement_the_system/Done/16_escrow-invariants-idempotency/RUNBOOK_EscrowIdempotency_T1_T2.md`

### 🔧 Technical Notes

- No breaking changes; RPC signature unchanged. Rollback: redeploy previous `rpc_approve_delivery` body; recreate `idx_journal_entries_idempotency` if needed.

---

## 🏷️ Task Request Bid Flow — FULL_REPORT Fixes (v2.20.1)

**Date:** 2026-03-08  
**Report:** `.TODO/improvement_the_system/Done/21_Wallet_System_Escrow_Available_balances/diagram_consistency_audit/04_task-request-bid-flow/FULL_REPORT.md`

### ✅ Implemented

- **Inbox Award — Optimistic Price Lock:**
  - `lib/features/dashboard/viewmodels/dashboard_view_model.dart` — `awardOffer()` now passes `expectedPriceCents: (offer.price * 100).round()` to `TaskService.awardOffer()`
  - Prevents bait-and-switch when awarding from Inbox tab (client-captured price validated at RPC time)

- **accept_task_request — Single Winner Rule:**
  - `supabase/migrations/20260308000000_accept_task_request_reject_remaining_bids.sql` — Rejects all other pending bids on the same task when one is accepted
  - Ensures atomic "one accepted per task" invariant

### 📊 Impact

- **Security:** Inbox award flow now has same optimistic concurrency protection as Requests list
- **Data Integrity:** No orphaned pending bids when client accepts one offer

### 🔗 References

- FULL_REPORT: `.TODO/.../04_task-request-bid-flow/FULL_REPORT.md`
- SUPABASE_SETUP: §9.6 accept_task_request, §17 Changelog v2.20.1

---

## 🏷️ Tender Task Lifecycle — Price Validation & Auto-Expiry (v2.20)

**Date:** 2026-03-06  
**Plan:** `.TODO/improvement_the_system/ImplementReady/03_tender-task-lifecycle`  
**Master Report:** `.TODO/MASTER_REPORT_2026-03-06_TenderTaskLifecycle.md`

### ✅ Implemented

- **Database Layer:**
  - `idx_task_requests_awarded_unpaid` — Index for efficient expired award queries
  - `idx_one_accepted_per_task` — Partial unique index enforces single accepted offer per task
  - `award_task_offer` RPC — Optimistic concurrency with `p_expected_price_cents`, idempotency, audit logging
  - `accept_task_request` RPC — Price validation, idempotency, activity_log integration
  - `cleanup_expired_awards` RPC — 1-hour grace period, notifications to both parties, audit logging
  - `cleanup-expired-awards` cron job — Runs every 10 minutes
  - `system_config` entries — `platform_fee_bps` and `tender_payment_timeout_hours`

- **Application Layer:**
  - `PriceMismatchException` — Custom exception with user-friendly message formatting
  - `OfferAlreadyAcceptedException` — Idempotency handling for duplicate accepts
  - `AwardExpirationMonitor` — Timer-based countdown with urgency levels (relaxed/urgent/critical/expired)
  - `TaskRequestsService.accept()` — Price validation parameter support
  - `TaskRequestsViewModel.acceptOffer()` — Captures expected price at UI interaction time
  - `DashboardOfferCard` — Payment deadline countdown with color-coded urgency and pulse animation
  - `RequestsListScreen` — Price mismatch error dialog with refresh option

- **Security & Data Integrity:**
  - Price validation: Client-captured price validated at RPC time prevents race conditions
  - Idempotency: Duplicate accept operations return success without side effects
  - Auto-expiry: Unpaid awards auto-expire after 48 hours (configurable) with notifications
  - Audit trail: All price mismatches and expiry events logged to `admin_logs`

- **Test Infrastructure:**
  - `test/fixtures/tender_tasks.dart` — Comprehensive fixtures for 7 task states and 4 request states
  - `test/unit/tender/award_expiration_monitor_test.dart` — Timer, urgency, and disposal tests
  - `test/unit/tender/task_requests_service_test.dart` — Exception class tests
  - `test/unit/tender/task_requests_view_model_test.dart` — ViewModel behavior tests

- **Documentation:**
  - `Sline_everything/DEVELOPER_GUIDE.md` — Complete tender lifecycle section
  - `.TODO/CONTRACT_accept_task_request_v2.md` — API contract with error codes
  - `.TODO/SMOKE_TEST_TENDER.md` — Manual verification steps
  - `.TODO/ROLLBACK_TRIGGERS.md` — Data-driven rollback procedures

### 📊 Impact

- **Security:** Price validation prevents bidding manipulation attacks
- **Reliability:** Idempotent operations ensure consistent state across retries
- **User Experience:** Clear payment deadlines with visual urgency indicators
- **Observability:** Full audit trail for all tender lifecycle events
- **Maintainability:** Configurable timeouts and fees via system_config

---

## 🔒 Chat Creation Matrix — Secure Conversation Creation (v2.19)

**Date:** 2026-03-06  
**Plan:** `.TODO/MASTER_REPORT_2026-03-06_ChatCreationMatrix.md`  
**Master Report:** `.TODO/MASTER_REPORT_2026-03-06_ChatCreationMatrix.md`

### ✅ Implemented

- **Database Layer:**
  - `start_direct_conversation_v1()` RPC — Atomic, idempotent DM creation with ON CONFLICT
  - `is_client(uuid)` function — Checks `active_role = 'client'` for role enforcement
  - `check_conversation_rate_limit(uuid)` function — Enforces 20 conversations/hour limit
  - `conversations_before_insert_guard()` trigger — Hardened with identity, role, favorites, rate limit checks
  - `app_config` table — Feature flag `enable_direct_conversation_rpc` for zero-downtime rollout
  - `admin_logs` integration — Full audit trail for all conversation creation attempts

- **Application Layer:**
  - `MessageService` — Feature flag routing (RPC path vs legacy path)
  - `ChatViewModel` — `isCreatingConversation` state for double-tap prevention
  - `ErrorMapper` — User-friendly error messages for SQL exceptions
  - UI call sites — All updated to handle nullable `Conversation?` returns

- **Security & Access Control:**
  - Role enforcement: Only clients can initiate direct DMs
  - Favorites enforcement: Clients can only DM freelancers in their favorites
  - Rate limiting: 20 conversation creations per hour per user
  - Identity integrity: `initiated_by` must equal `auth.uid()`
  - Self-conversation prevention: Blocked at RPC level

- **Test Infrastructure:**
  - `test/services/message_service_test.dart` — Unit tests (feature flag, RPC, idempotency)
  - `integration_test/chat_creation_test.dart` — E2E flows (favorite DM, task bid, reject)
  - `test/rls/chat_creation_security_test.dart` — Security tests (spoofing, bypass, privacy)

- **Migration:** `supabase/migrations/20260306000000_chat_creation_matrix.sql`

### 📊 Impact

- **Security:** Database-level enforcement prevents role bypass, favorites spoofing, and spam
- **Reliability:** Atomic RPC eliminates race conditions; idempotent design prevents duplicates
- **Observability:** Full audit trail in `admin_logs` with structured error classification
- **Deployability:** Feature flag enables gradual rollout with instant rollback capability
- **Backward Compatibility:** Legacy INSERT path remains functional during migration window

### 🧪 Verification

- All unit tests pass (`flutter test test/services/message_service_test.dart`)
- All integration tests pass (`flutter test integration_test/chat_creation_test.dart`)
- All security tests pass (`flutter test test/rls/chat_creation_security_test.dart`)
- `flutter analyze` — no issues
- MCP verification — all functions, triggers, and policies confirmed active

### 🔗 References

- Plan: `.TODO/improvement_the_system/ImplementReady/07_chat-creation-matrix/`
- Master Report: `.TODO/MASTER_REPORT_2026-03-06_ChatCreationMatrix.md`
- Architect Report: `.TODO/ARCHITECT_REPORT_2026-03-06_ChatCreationMatrix.md`
- Observability Report: `.TODO/OBSERVABILITY_REPORT_2026-03-06_ChatCreationMatrix.md`
- Docs Report: `.TODO/DOCS_REPORT_2026-03-06_ChatCreationMatrix.md`
- CodeGuard Review: `.TODO/CODEGUARD_REVIEW_2026-03-06_ChatCreationMatrix.md`

---

## 🟢 Role Switching Flow Hardening — Atomic RPC, JWT Claims, Teardown Contract

**Date:** 2026-03-06  
**Plan:** `.TODO/PLAN_RoleSwitchingFlow_CRITIC_2026-03-06.md`  
**Master Report:** `.TODO/MASTER_REPORT_2026-03-06_RoleSwitching.md`

### ✅ Implemented

- **Database Layer:**
  - `switch_active_role` RPC — Atomic role switching with `expected_old_role` guard, idempotency, rate limiting (3/minute), and audit logging
  - `sync_role_to_jwt_claims` trigger — Syncs `profiles.active_role` to `auth.users.app_metadata` for JWT claims
  - `check_role_switch_rate_limit` function — Server-side rate limiting enforcement
  - 4 new JWT-based RLS policies — `task_requests_insert_freelancer_jwt`, `availability_slots_insert/update_freelancer_jwt`, `tasks_insert_client_jwt`
  - Full audit trail — All role switches logged to `audit_logs` table (success and failure)

- **Application Layer:**
  - `RoleSwitchCoordinator` singleton — Cross-ViewModel teardown coordination without violating MVVM boundaries
  - `RoleSwitchAware` mixin — Standardized teardown interface for ViewModels
  - `RoleSwitchRepository` — Encapsulates RPC calls, session refresh, JWT verification
  - `RoleSwitchResult` model — Type-safe RPC response handling with error taxonomy
  - Enhanced `ProfileViewModel.changeRole()` — Full atomic flow: rate check → RPC → session refresh → JWT verification → teardown → profile reload

- **ViewModel Teardown Contract:**
  - `ChatViewModel` — Disconnects realtime channels, clears conversations/messages
  - `DashboardViewModel` — Clears work items, bookings, inbox, counters
  - `TaskViewModel` — Clears task lists, picked images
  - `HomeViewModel` — Clears featured tasks, resets pagination

- **Test Infrastructure:**
  - `test/fixtures/profiles.dart` — Profile fixtures, JWT payloads, error responses
  - `test/helpers/mock_supabase.dart` — Mock Supabase client
  - `test/helpers/role_switch_helpers.dart` — Coordinator mock, simulator, verification utilities
  - `test/unit/profile/role_switch_result_test.dart` — Model unit tests (17 tests, all passing)

- **Migration:** `supabase/migrations/20260306_role_switch_foundation.sql`

### 📊 Impact

- **Security:** Atomic role switching prevents race conditions (multi-device, double-tap). JWT claims enable performant RLS without table joins.
- **Data Integrity:** Teardown contract prevents persona data leakage (no client messages visible in freelancer mode).
- **Observability:** 40+ AppLogger events for complete flow tracing. Full audit trail in database.
- **Backward Compatibility:** Legacy `changeRole()` deprecated but functional during 14-day migration window.

### 🧪 Verification

- All 17 unit tests pass (`flutter test test/unit/profile/`)
- `flutter analyze` — no issues
- Supabase MCP verification — all 3 functions, 1 trigger, 4 RLS policies confirmed active

### 🔗 References

- Plan: `.TODO/PLAN_RoleSwitchingFlow_CRITIC_2026-03-06.md`
- Execution log: `.TODO/EXECUTION_LOG_RoleSwitchingFlow_CRITIC_2026-03-06.md`
- Architect review: `.TODO/ARCHITECT_REPORT_2026-03-06_RoleSwitching.md`
- Observability review: `.TODO/OBSERVABILITY_REPORT_2026-03-06_RoleSwitching.md`
- Docs review: `.TODO/DOCS_REPORT_2026-03-06_RoleSwitching.md`
- CodeGuard review: `.TODO/CODEGUARD_REVIEW_2026-03-06_RoleSwitching.md`

---

## 🗂️ Storage Signed URLs Flow v2 — RLS Hardening, Centralized TTL, Error Caching

**Date:** 2026-03-06  
**Plan:** `.TODO/improvement_the_system/ImplementReady/17_storage-signed-urls-flow/`  
**Master Report:** `.TODO/MASTER_REPORT_2026-03-06_StorageSignedUrls.md`

### ✅ Implemented

- **Database Layer (RLS v2):**
  - `is_admin(uuid)` function — Checks `roles @> '{admin}'` for admin access
  - `can_access_chat_attachment(path, uid)` function — Validates conversation participation + admin bypass
  - `can_access_task_image(path, uid)` function — Validates image ownership + admin bypass
  - `app_config` table — Feature flag `storage_rls_v2_enabled` for gradual rollout
  - 3 new RLS v2 policies — `avatars_select_v2`, `task_images_select_restricted_v2`, `chat_attach_select_restricted_v2`
  - Atomic policy swap — Old broad policies removed, new strict policies active with fallback

- **Application Layer:**
  - `SharedStorageConfig` — Centralized TTL constants (3600s/7200s), cache durations, max cache size
  - `SignedUrlCache` — Enhanced with error caching (30s), LRU eviction, bounded size (1000 entries)
  - `AvatarService` — Updated to use `SharedStorageConfig.avatarTtlSeconds`
  - `TaskImageService` — Updated to use `SharedStorageConfig.taskImageTtlSeconds`
  - `AttachmentService` — Updated to use `SharedStorageConfig.chatAttachmentTtlSeconds`
  - `SignedAvatar` widget — Now uses `SharedStorageConfig` for TTL
  - `SignedImage` widget — Now uses `SharedStorageConfig` for TTL
  - `AttachmentMessageTile` — Integrated `SignedUrlCache` with `ErrorMapper` for consistent error messages

- **Test Infrastructure:**
  - `test/rls/storage_rls_test_harness.dart` — Storage-specific RLS testing utilities
  - `test/storage_rls_test.dart` — 6 security tests (T50-T53 + anonymous access)
  - `test/fixtures/storage_rls_test_data.sql` — Test fixtures for conversations/profiles

- **Migrations:**
  - `20260306_add_app_config_feature_flag.sql`
  - `20260306_storage_rls_helper_functions.sql`
  - `20260306_storage_rls_v2_policy_swap.sql`

### 📊 Impact

- **Security:** Object-level RLS prevents path guessing attacks. Non-participants get 403 on chat attachments. Non-owners get 403 on task images.
- **Performance:** 90-minute URL caching reduces API calls. Error caching prevents retry storms on 403s.
- **Consistency:** Centralized TTL configuration eliminates hardcoded values across services.
- **Reliability:** Feature flag allows instant rollback without code deploy.
- **Cache Safety:** Bounded cache (1000 entries) with LRU eviction prevents memory exhaustion.

### 🧪 Verification

- All 6 RLS security tests defined (T50-T53)
- Cache unit tests pass (`flutter test test/unit/core/signed_url_cache_test.dart`)
- `flutter analyze` — no issues in scope files
- Supabase MCP verification — all 3 functions, 3 policies, 1 table confirmed active

### 🔗 References

- Master Report: `.TODO/MASTER_REPORT_2026-03-06_StorageSignedUrls.md`
- Schema: `.TODO/PLAN_StorageSignedUrls_SCHEMA.md`
- Contract: `.TODO/PLAN_StorageSignedUrls_CONTRACT.md`
- Threats: `.TODO/PLAN_StorageSignedUrls_THREATS.md`
- Rollback: `.TODO/PLAN_StorageSignedUrls_ROLLBACK.md`
- Architect: `.TODO/ARCHITECT_REPORT_2026-03-06_StorageSignedUrls.md`
- Docs: `.TODO/DOCS_REPORT_2026-03-06_StorageSignedUrls.md`
- CodeGuard: `.TODO/CODEGUARD_REVIEW_2026-03-06_StorageSignedUrls.md`

---

## 🔒 RLS Authorization Map Implementation — Policy Hardening & Test Infrastructure

**Date:** 2026-03-06  
**Plan:** `.TODO/PLAN_RLS_Authorization_Map_CRITIC_2026-03-06.md`  
**Execution Log:** `.TODO/EXECUTION_LOG_RLS_Authorization_Map_CRITIC_2026-03-06.md`

### ✅ Implemented

**Security Fixes (4 Critical Blockers):**
- Dropped `public.users` view (PII exposure fix)
- Removed wide-open messages policies (cross-user read/insert protection)
- Fixed `admin_logs` INSERT to service_role only (log injection prevention)
- Dropped `bookings_update_status_only` policy with NULL with_check

**Policy Migration:**
- Migrated ~30 policies from `public` → `authenticated` role
- Dropped ~17 redundant/dangerous policies
- Created ~15 new authenticated policies

**View Hardening:**
- Dropped `wallet_balances` legacy view
- Recreated `tasks_mvp` and `user_conversations` with `security_invoker = true`
- Restricted 6 admin/analytics views to service_role only

**Test Infrastructure:**
- `test/rls/rls_test_helper.dart` — 8 assertion methods for RLS testing
- `test/rls/fixtures/rls_test_users.dart` — 5 test user fixtures
- `test/rls/critical_blockers_test.dart` — 4 critical security tests (12 total)
- `test/rls/view_security_test.dart` — 7 view security tests
- `test/rls/role_switch_jwt_test.dart` — 7 JWT policy tests
- **Total: 26 automated RLS tests**

**Artifacts:**
- `.TODO/VIEW_USAGE_AUDIT.md` — View usage verification (0 references found)
- `.TODO/BACKUP_policies_2026-03-06.json` — 108 policy backup for rollback

### 📊 Impact

- **Security:** 4 critical vulnerabilities resolved; 108 policies now enforce proper access control
- **Performance:** JWT-based policies eliminate table joins for role checks
- **Testability:** Automated RLS test suite prevents security regressions
- **Observability:** Full AppLogger instrumentation throughout test infrastructure

### 🧪 Verification

- All 26 RLS tests pass (`flutter test test/rls/`)
- All 17 role switch unit tests pass
- `flutter analyze` — no issues
- 12 SQL migrations executed via Supabase MCP

### 🔗 References

- Plan: `.TODO/PLAN_RLS_Authorization_Map_CRITIC_2026-03-06.md`
- Execution Log: `.TODO/EXECUTION_LOG_RLS_Authorization_Map_CRITIC_2026-03-06.md`
- View Audit: `.TODO/VIEW_USAGE_AUDIT.md`
- Policy Backup: `.TODO/BACKUP_policies_2026-03-06.json`
- Master Report: `.TODO/MASTER_REPORT_2026-03-06_RLS_Authorization_Map.md`

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

### 🟢 Auth profile provisioning hardening — retry, orphan sweep, guard on cold start

**Date:** 2026-03-06  
**Plan:** `.TODO/PLAN_AuthProfileProvisioning_CRITIC_2026-03-06.md`

#### ✅ Implemented

- **Repository:** `AuthRepository.getCurrentUserProfileWithRetry()` with configurable max retries and delay (`AuthConfig`). Single-attempt `_fetchProfileOnce()` uses `.maybeSingle()`. Full AppLogger on attempt/success/failure.
- **ViewModels:** `AuthSessionViewModel._loadInitialProfile()` uses retry; on null after retries or exception: logout and set user-facing error (`AuthMessages`). `AuthFormViewModel.register()` calls retry after signUp; on null: signOut and show profile provisioning failed message.
- **UI:** `LoginScreen` shows `AuthSessionViewModel.error` in SnackBar when present (e.g. after session restore failure). Centralized strings in `lib/core/constants/auth_messages.dart`.
- **Database:** View `vw_orphaned_auth_users`, function `sweep_orphaned_auth_users()` (SECURITY DEFINER, 15‑minute filter). Optional `pg_cron` schedule documented in migration (run manually if pg_cron not enabled).
- **Docs:** `SUPABASE_SETUP.md` updated with view, function, and auth provisioning rule. `DEVELOPER_GUIDE.md` updated with retry and AccountGuard cold start. Subsection "4.3 Profile provisioning retry" added under Auth Feature Reference.
- **Post–Master Report fixes (2026-03-06):** `AuthFormViewModel`: all auth failure logs use `AppLogger.e(message, tag: 'Auth', error: e)` (no exception interpolation in message). `AuthSessionViewModel.logout()` calls `clearError()` so stale session error is cleared on sign-out.

#### 📊 Impact

- New signups tolerate profile trigger latency (retry up to ~1.5s). Failed provisioning clears session and shows error instead of corrupt state.
- Orphaned auth users (no profile) can be cleaned up; monitoring via `vw_orphaned_auth_users`.
- Banned/suspended users are blocked on cold start as well as on explicit login.

#### 🧪 Verification

- `flutter test test/unit test/widget`: 158 passed. `test/unit/auth/auth_repository_test.dart` covers null-user retry path.
- Supabase MCP: RLS and trigger verified; orphan count query returns 0.

#### 🔗 References

- Plan: `.TODO/PLAN_AuthProfileProvisioning_CRITIC_2026-03-06.md`
- Execution log: `.TODO/EXECUTION_LOG_AuthProfileProvisioning_CRITIC.md`
- Review: `.TODO/CODEGUARD_REVIEW_2026-03-06_AuthProfileProvisioning.md`
- Master report: `.TODO/MASTER_REPORT_2026-03-06_AuthProfileProvisioning.md`
- App verification checklist: `.TODO/CHECKLIST_AuthProfileProvisioning_Verification.md`
- Docs sync: `.TODO/DOCS_SYNC_2026-03-06_DocsKeeperFullSync.md`

---

### 🟢 Auth Refactor — Split ViewModels and Trigger-Based Bootstrapping

**Date:** 2026-03-05  
**Issue:** authentication components were monolithic (`AuthViewModel` handling session state and transient form state interchangeably), profile bootstrapping was brittle, and tests contained unhandled pending timers.

#### ✅ Implemented

- **Architecture:** Split `AuthViewModel` into `AuthSessionViewModel` (for long-lived session state, logout, profile loading) and `AuthFormViewModel` (for transient loading/error states in login, signup, and reset forms).
- **Backend Trigger:** Enforced the creation of `public.profiles` rows automatically via Supabase Postgres trigger `trg_on_auth_user_created`, reducing client-side bootstrap race conditions.
- **Test Infrastructure:** Migrated `login_screen_test.dart` to use the new `AuthFormViewModel` structure and removed an errant `Future.delayed` from `_FakeAuthFormViewModel`, which resolved testing timer exceptions.
- **UI Wiring:** Updated `ProfileScreen`, `SettingsScreen`, `LoginScreen`, and `SignupScreen` to use the split ViewModels (`AuthSessionViewModel.logout()` replaced `signOut()`).

#### 📊 Impact

- Clearer separation of concerns: form progress (loading/error visuals) is separate from global application session state.
- Faster, more reliable signup path with profile rows synchronously generated by the database.
- Completely stable widget test suite with no asynchronous timer leaks.

#### 🧪 Verification

- Ran `flutter test test/widget/auth/login_screen_test.dart` successfully.
- Verified test robustness and strict MVVM compliance without direct UI-to-service calls.
- Updated `DEVELOPER_GUIDE.md` to document the new `AuthSessionViewModel` / `AuthFormViewModel` split.

---

### 🟢 Offer Submission Role Requirement Fix — removed active_role check

**Date:** 2026-03-05  
**Issue:** Freelancers had to explicitly switch `active_role` to `freelancer` to submit an offer, which caused friction and errors in the UI.

#### ✅ Implemented

- **Database RLS:** Removed the `is_freelancer(auth.uid()) = true` check from the `tr_insert` policy on the `public.task_requests` table.
- **Client Code:** Removed the explicit pre-insert check for `active_role == 'freelancer'` inside `lib/features/tasks/services/task_requests_service.dart`.
- **Error Messages:** Updated the client-side error fallback to correctly state the RLS reasoning (task is closed or user is task owner) instead of demanding a role switch.

#### 📊 Impact

- Users currently in `client` mode can submit offers on tasks without explicitly switching roles in the settings page. Friction reduced.

#### 🧪 Verification

- Verified SQL constraints via Supabase MCP.
- Ran `flutter test test/unit/services/` and `flutter analyze` successfully.

---

### 🟢 Work Full Remediation — fallback mapper, booking chat, work tables & RPCs

**Date:** 2026-03-05  
**Plan:** `.TODO/Archive/WorkExectuion/PLAN_Work_Full_Remediation_2026-03-04.md`, `work.TODO.md`

#### ✅ Implemented

- **Unified Work View (vw_unified_work_items):** Single source of truth for work list and detail. View has 4 branches (tasks in progress, bookings, awarded pending payment, direct_offers) with dispute override and `security_invoker = true`. App reads only from the view; no fallback mappers. See `lib/features/work/`, `lib/features/dashboard/data/dashboard_repository.dart`, SUPABASE_SETUP §6.4.
- **Booking chat:** Work detail uses taskId only when `item.isTask` (task-linked path); booking uses DM path. MessageService logs path at debug.
- **WorkItemDetailsViewModel:** Optional `ChatViewModel` and `DashboardViewModel`; `openConversation()`, `refreshDashboard()`, `cancelAward(requestId)`; partial-failure tolerance in `loadData` (optional contract/requests failure does not blank screen).
- **Work detail screen:** Provider create injects Chat/Dashboard VMs; no direct chat/dashboard orchestration from view.
- **Migrations:** `20260305180000_work_contracts_change_extension_requests.sql` (work_contracts, change_requests, extension_requests + RLS); `20260305180100_work_revision_and_change_rpcs.sql` (rpc_request_revision, rpc_accept_change_request). Applied via Supabase MCP.
- **Observability:** Work service success logs at debug; work VM logs at debug (no PII at info).
- **Docs:** DEVELOPER_GUIDE work section; SUPABASE_SETUP migration refs; this log entry.

#### 📊 Impact

- Work tab and work detail load reliably; booking and task semantics aligned; optional data failures no longer blank the screen.

---

### 🟢 Reject-offer conversation guard — owner can create task convo from reject path

**Date:** 2026-03-05  
**Checklist:** `.TODO/Archive/ProposalesExecution/CHECKLIST_Proposals_App_Verification_2026-03-05.md`

#### ✅ Implemented

- **DB migration** `supabase/migrations/20260305071000_conversations_guard_allow_owner_reject.sql`:
  - Replaces `conversations_before_insert_guard()` so task-linked conversation creation allows the task owner when `app.allow_owner_task_conversation = 'true'` (transaction-local GUC). Otherwise enforces `initiated_by = auth.uid()` and non-owner for task-linked.
  - Updates `reject_task_request(p_task_id, p_request_id)`: sets the GUC before inserting the conversation, uses `initiated_by = v_owner` so both "initiated_by must equal current user" and the non-owner rule (with GUC exception) pass.
- **Superseded:** `20260305070000_reject_task_request_conversation_initiator.sql` (used `initiated_by = v_freelancer`, which violated "initiated_by must equal current user").

#### 📊 Impact

- Reject offer from Inbox (Offer card) and from task Offers list succeeds; conversation and `offer_rejected` message are created; freelancer receives notification.

#### 🧪 Verification

- App verification: `.TODO/Archive/ProposalesExecution/CHECKLIST_Proposals_App_Verification_2026-03-05.md` (Reject-offer fix section).

#### 🔧 Technical Notes

- Apply migration `20260305071000_conversations_guard_allow_owner_reject.sql` to live DB (Dashboard SQL or Supabase MCP). If your live `conversations_before_insert_guard()` has extra logic (e.g. DM/favorites), merge it into the migration function before applying.

---

### 🟢 Proposals Remediation — Secure RPCs, route helper, proposals module boundary

**Date:** 2026-03-05  
**Plan:** `.TODO/Archive/ProposalesExecution/PLAN_ProposalsRemediation_v2_2026-03-04.md`

#### ✅ Implemented

- **Proposals feature boundary:** `lib/features/proposals/` — models (`ProposalModel`, `ProposalPaymentSummary`), repositories (`ProposalRepository`, `ProposalAwardRepository`), route `openProposalPayment(context, summary)`; view re-exports for list/submit/tile/payment from tasks.
- **Secure RPCs:** Migrations bind all proposal RPCs to `auth.uid()` (award_task_offer, pay_awarded_offer, cancel_awarded_offer, get_client/freelancer_awarded_unpaid_offers); `get_proposal_bidder_summaries` for owner list; `finalize_awarded_offer_payment` wrapper.
- **Payment entry:** Inbox, Work tab, Next Actions, Work item details, and Requests list (after award) use `openProposalPayment` with `ProposalPaymentSummary` (server-derived deadline/task title where available).
- **No client active_role mutation:** Submit offer fails fast with role message; RLS enforces freelancer.
- **Self-favorite guard:** Request tile hides favorite button when viewer is the bidder.
- **Deprecated:** `ProposalDetailsModal` (no call sites); DEPRECATION_Proposals doc.
- **Tests:** Unit (proposal_model, proposal_payment_summary), widget (proposal_payment_screen), integration placeholder under `test/integration_test/proposals/`.
- **Docs:** DEVELOPER_GUIDE.md, STRUCTURE.md, MVP_ROADMAP.md, Sline_Log; new `DEVELOPER_GUIDE/Proposals_Feature.md`.

#### 📊 Impact

- Single payment entry point; RLS-safe profile reads; release blocked until live DB evidence per RELEASE_CHECKLIST.

---

### 🟢 Award → Work Waiting Payment — cancel_awarded_offer, vw_unified_work_items third branch

**Date:** 2026-03-04  
**Plan:** Award → Work Section + Waiting Payment + Cancel

#### ✅ Implemented

- **Award → Work:** After awarding an offer from Inbox, the task appears in the Work tab as "Waiting payment"; the client can Pay (opens `TenderPaymentScreen`) or Cancel from there.
- **cancel_awarded_offer RPC:** Reverts an awarded-unpaid offer (task_request → rejected, task → open), notifies freelancer; client-only, SECURITY DEFINER with owner check.
- **vw_unified_work_items:** Extended with a third branch: tasks with `status = 'assigned'`, no freelancer, joined to accepted/unpaid `task_requests`; exposes `awarded_request_id`, `payment_deadline` for Pay/Cancel UI.
- **App:** WorkItem/DashboardRepository map new fields; DashboardPermissionService sets `canCancel` for client + pendingPayment; TaskService/DashboardViewModel `cancelAwardedOffer`; Work tab and NextActionsList open TenderPaymentScreen for task+payEscrow+awardedRequestId and show Cancel when applicable.
- **Observability:** AppLogger in work_tab (Pay/Cancel from Work), next_actions_list (opening tender payment), inbox_tab (award success, switching to Work tab). Tag: `dashboard.work`, `dashboard.inbox`.
- **Docs:** DEVELOPER_GUIDE.md updated (vw_unified_work_items description, Award → Work sentence); SUPABASE_SETUP.md §6.4 describes view branches and migration.

#### 📊 Impact

- Single source of truth for "waiting payment" items in Work tab; cancel path allows re-award without payment.

---

### 🟢 Tasks Tender Fix — Fail-Closed Payment, replace_task_request, active_role Removal

**Date:** 2026-03-04  
**Plan:** `.TODO/PLAN_Tasks_Fix_All_2026-03-01.md` (executed subset)

#### ✅ Implemented

- **Tender payment fail-closed:** `TenderPaymentCoordinator` throws before ledger/pay when `PaymentService` is `DemoPaymentService` or `QiCardPaymentService` (processPayment delegates to demo). Prevents tender state advancing on demo success; server-backed tender flow required for real payment.
- **replace_task_request RPC:** Migration `20260311000000_replace_task_request.sql` originally added the RPC (withdraw + insert, active_role). **Current behavior (2026-03-22):** Migrations `20260322000002`–`20260322000005` — update-in-place, no role gate, single overload, errors including `no_pending_offer_to_replace`. See top Sline_Log entry and SUPABASE_SETUP §9.6, §17.
- **Offer submit (no active_role mutation):** `TaskRequestsService.submitOffer()` no longer updates `profiles.active_role`; RLS (`is_freelancer(auth.uid())`) controls insert. On RLS denial (e.g. 42501), app shows: "You must be in freelancer mode to submit an offer. Switch your role in profile settings."
- **Tests:** `test/unit/tasks/tender_payment_coordinator_test.dart` — fail-closed tests for Demo and QiCard payment services; payAwardedOffer never called when payment is demo.

#### 📊 Impact

- Tender payment cannot advance from demo/client-only result. replace_task_request is in repo migrations; offer submission relies on server-side role.

#### 🧪 Verification

- Execution log: `.TODO/EXECUTION_LOG_PLAN_Tasks_Fix_All_2026-03-01.md`
- Multi-agent review: `.TODO/MASTER_REPORT_2026-03-04_TasksTenderFix.md` (Architect, Observability, DocsKeeper, CodeGuard)

---

### 🟢 Version 2.17.2 — Dashboard Full Remediation (Widget Moves, Lazy-Load, StatusPresenter)

**Date:** 2026-03-02  
**Commit:** _Pending_ — "refactor(dashboard): move cards to owning features, StatusPresenter, lazy-load flags, lint fix"

#### ✅ Implemented

- **Widget moves**
  - `lib/features/booking/view/widgets/dashboard_booking_card.dart`: Dashboard booking card with callback API (onTapDetails, onAccept, onDecline, onCancel, onUpdateStatus, onRefresh); no DashboardViewModel dependency.
  - `lib/features/tasks/view/widgets/dashboard_offer_card.dart`: Dashboard offer card moved from dashboard; uses `StatusPresenter` for badge.
  - `lib/features/wallet/view/widgets/wallet_snapshot_card.dart`: Wallet snapshot card moved from dashboard to wallet feature.
  - Removed: `lib/features/dashboard/view/widgets/booking_card.dart`, `offer_card.dart`, `wallet_snapshot_card.dart`.

- **Shared status**
  - `lib/core/utils/status_presenter.dart`: Booking and offer status color/label helpers used by dashboard booking and offer cards.

- **Dashboard behavior**
  - Lazy-load by tab: overview loads first; Bookings and Inbox load on first visit. Full refresh sets `_bookingsLoaded` and `_inboxLoaded` so tab switch does not reload.
  - BookingsTab and InboxTab pass VM callbacks to `DashboardBookingCard` and `DashboardOfferCard`; OverviewTab imports `WalletSnapshotCard` from wallet feature.

- **Pull-to-refresh on every tab**
  - Overview, Bookings, Inbox, and Work tabs (including Work sub-tabs Active / Done / Cancelled) each wrap content in `RefreshIndicator` with `onRefresh: () => vm.refresh()`. Empty states use `SingleChildScrollView` + `AlwaysScrollableScrollPhysics` so pull works. Files: `lib/features/dashboard/view/tabs/overview_tab.dart`, `bookings_tab.dart`, `inbox_tab.dart`, `work_tab.dart`.

- **Lint**
  - Removed unnecessary non-null assertions in `lib/features/dashboard/viewmodels/dashboard_view_model.dart` (cache use in `_loadOverviewData` and cache save after overview fetch).

- **Docs**
  - `Sline_everything/DEVELOPER_GUIDE.md`: §2.1 Current dashboard behavior (cache, lazy-load, wallet snapshot, MyServices, tender payment, card paths, StatusPresenter).
  - `Sline_everything/MVP_ROADMAP.md`: Tender payment flow and Unified dashboard/workspace set to ✅ Completed.
  - `Sline_everything/STRUCTURE.md`: Dashboard bullet updated with card paths and `status_presenter.dart`.
  - `Sline_everything/DEVELOPER_GUIDE.md`: §2.1 extended with pull-to-refresh on every tab (paths for overview_tab, bookings_tab, inbox_tab, work_tab).

#### 📊 Impact

- Dashboard cards live in owning features; status presentation is centralized. Lazy-load reduces initial load; refresh correctly marks tab data as loaded. Docs and roadmap reflect current behavior.

#### 🧪 Verification

- Plan: `.TODO/PLAN_Dashboard_Full_Remediation_2026-03-01.md`
- Reports: `.TODO/ARCHITECT_REPORT_2026-03-02_DashboardRemediation.md`, `.TODO/CODEGUARD_REVIEW_2026-03-02_DashboardRemediation.md`, `.TODO/MASTER_REPORT_2026-03-02_DashboardRemediation.md`
- Test: `flutter test test/widget/dashboard/booking_card_test.dart`; `flutter analyze` (no warnings in dashboard_view_model.dart for this scope).

#### 🔧 Technical Notes

- No DB or RLS changes. Rollback: revert widget moves and doc edits; restore deleted dashboard widget files from git.

---

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

### 🟢 Version 2.17.1 — Notifications Completion + Approve-and-Release Ledger Fix

**Date:** 2026-03-02  
**Commit:** _Pending_ — "fix(notifications,ledger): server-authority notifications, release_with_fee zero-amount and enum cast"

#### ✅ Implemented

- **Notifications (server-authority, auth-aware, deep links)**
  - `lib/features/notifications/services/notification_service.dart`: Read/update-only; all queries filtered by `user_id` from `auth.currentUser`; `getNotifications`, `streamNotifications`, `markAsRead`, `markAllAsRead`; AppLogger tag `Notifications`.
  - `lib/features/notifications/viewmodels/notification_view_model.dart`: No `BuildContext`; auth-aware stream (connect on sign-in, disconnect on sign-out); optional `authStateChanges` for tests; `retry()`; navigation delegated to view layer.
  - `lib/core/services/deep_link_service.dart`: `task_request` routing from metadata (`conversation_id` first, else `task_id`); AppLogger tag `DeepLink`.
  - `lib/features/notifications/view/notifications_modal.dart`: `NotificationsModal.show(context)` returns `Future<NotificationItem?>`; stable keys `NotificationsModalKeys`; error UI with Retry.
  - `lib/features/notifications/view/widgets/notification_badge_button.dart`: Opens modal, on selection calls `DeepLinkService.handleNotification(context, selected)`.
  - `lib/features/notifications/models/notification_model.dart`: `fromJson` hardened (`_parseMetadata`, safe `toString()` for id/userId/relatedEntityId, type default `'system'`).
  - DB: `supabase/migrations/20260226_tender_award_payment_flow.sql` — notification INSERTs use `message`, `metadata`, `is_read` (not `body`, `data`, `read`).

- **Approve-and-Release (ledger)**
  - **Issue 1:** With `fee_rate_bps: 0`, `release_with_fee` inserted a platform_revenue line with `amount = 0`, violating `ck_ledger_lines_amount_positive`.
  - **Issue 2:** `UPDATE bookings SET payment_status = 'released', status = 'completed'` caused prepared-plan type mismatch (parameter 40: `booking_status_enum` vs text).
  - **Fix:** `supabase/migrations/20260307_fix_ledger_event_type_enum.sql` (in-file) and `supabase/migrations/Archive/20260308_fix_release_with_fee_zero_amount_and_enum.sql` (patch for already-applied DBs): (1) Ledger lines inserted only where `amount > 0`; (2) Explicit enum casts for bookings/direct_offers. **Follow-up (2026-03-08):** For DBs that had `20260308210400_ledger_allow_disputed_booking_admin` without the Archive enum-cast patch, migration `20260308210500_ledger_release_enum_cast_parameter_40.sql` applies the same casts to the current function body (fixes direct-offer Complete "parameter 40" error). See Sline_Log entry "Ledger release_with_fee enum cast (parameter 40) fix".
  - Remote DB: Fix applied via Supabase MCP `apply_migration` (project `isddrknbjsgaantjojhm`).

- **Misc**
  - `lib/core/services/qicard_payment_service.dart`: `_errorMessageFromResponse` — added braces for clarity (lint/style).

#### 📊 Impact

- Notifications are server-authoritative; client only reads and marks read; auth-aware stream avoids stale data after sign-out. Approve and release works for bookings/direct_offers with zero fee and avoids enum/plan mismatch errors.

#### 🧪 Verification

- Plan: `.TODO/Archive/NotificationExecution/PLAN_NotificationsFix_2026-03-01.md`
- Execution Log: `.TODO/Archive/NotificationExecution/EXECUTION_LOG_PLAN_NotificationsFix_2026-03-01.md`
- Manual checklist: `.TODO/Archive/NotificationExecution/CHECKLIST_NotificationsFix_Manual_Test.md`
- Ledger: Manual approve-and-release flow on remote DB after MCP migration.

#### 🔧 Technical Notes

- For existing DBs that already ran 20260307, run 20260308 (patch) or apply the same SQL via Dashboard/MCP. Local `supabase migration up` requires `supabase start`; `supabase db push` may report version mismatch if remote history uses different migration version names.

- **Docs sync:** `.TODO/DOCS_SYNC_2026-03-02_NotificationsAndReleaseFix.md`

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
  - `Sline_everything/DEVELOPER_GUIDE/Chat Feature.md`, `Sline_everything/SUPABASE_SETUP.md`, `Sline_everything/STRUCTURE.md` updated. `.TODO/` plan, execution log, contract, test strategy, threat model, RLS matrix, rollout matrix, observability, and orchestrator reports (Architect, Observability, DocsKeeper, CodeGuard, Master).

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
**Agent:** @Architect, @Pixel, @DocsKeeper
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
- Work list and detail read only from `vw_unified_work_items` (no fallback mapper); when view returns no row, app shows "Work item not found". See Plan 12 (Unified Work View, 2026-03-08).
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
**Agent:** @Architect, @DocsKeeper
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

---

### 🟢 Version 2.19 — Task Request (Bid) Flow Complete

**Date**: 2026-03-06  
**Status**: Phase 4.4 Complete — Full bid lifecycle with two-step award & payment escrow  
**Commit**: _Pending_ — "feat: Task Request Bid Flow with two-step award, price validation, and auto-expiry"

#### ✅ Implemented

- **Two-Step Award Flow**:
  - Step 1 (`accept_task_request`): Client awards offer, locks freelancer, sets 48h payment deadline
  - Step 2 (`pay_awarded_offer`): Client completes payment, funds held in escrow, work begins
  - Optimistic concurrency control: Price validation prevents race conditions during award
  - Idempotency: Double-clicking "Award" returns 'already_accepted' without side effects

- **Bid Lifecycle Management**:
  - `submitOffer`: Freelancers submit offers with 24-hour response window
  - `replaceOffer`: Freelancers can withdraw and replace pending offers
  - `reject`: Client rejection with automatic conversation creation
  - `cancelAwardedOffer`: Cancel unpaid awards, revert task to open

- **Auto-Expiry System**:
  - `cleanup_expired_awards()`: Cron job runs every 10 minutes
  - Expires unpaid offers 1 hour after payment deadline
  - Sends notifications to both parties
  - Reverts task.status to 'open' automatically

- **Security Hardening**:
  - `idx_one_accepted_per_task`: Unique index prevents double acceptance
  - Rate limiting: 2-second debounce prevents bid spam
  - RLS policies: No direct status updates, only RPC can modify
  - Audit logging: PRICE_MISMATCH_ATTEMPT, OFFER_ACCEPTED, AWARD_AUTO_EXPIRED

- **Flutter Implementation**:
  - `TaskRequest` model with OfferStatus/PaymentStatus enums
  - `TaskRequestsService`: RPC calls with comprehensive error mapping
  - `TaskRequestsViewModel`: MVVM with loading flags (prevents double-submit)
  - `AwardExpirationMonitor`: Live countdown timer for payment deadline
  - `PriceMismatchException`, `OfferAlreadyAcceptedException`: Typed errors

#### 📁 New Files

| File | Purpose |
|------|---------|
| `lib/features/tasks/models/task_request_model.dart` | TaskRequest entity (23 fields) |
| `lib/features/tasks/services/task_requests_service.dart` | Service layer with RPC calls |
| `lib/features/tasks/viewmodels/task_requests_view_model.dart` | MVVM state holder |
| `lib/features/tasks/viewmodels/award_expiration_monitor.dart` | Countdown timer |
| `lib/features/tasks/exceptions/offer_exceptions.dart` | Custom exceptions |
| `lib/features/tasks/view/widgets/expiration_countdown.dart` | Countdown UI |
| `lib/features/tasks/view/widgets/payment_status_badge.dart` | Payment status indicator |
| `test/unit/tender/*` | Unit tests for service, viewmodel, monitor |
| `test/fixtures/tender_tasks.dart` | Test fixtures |
| `Sline_everything/FEATURE_BID_FLOW.md` | Quick reference guide |

#### 🔧 Migration Files

- `20260306_tender_guardrails.sql`: Indexes, accept_task_request, cleanup_expired_awards
- `20260305*_reject_task_request_conversation_initiator.sql`: Reject with conversation
- `20260322000002`–`20260322000005`: replace_task_request (single overload, update-in-place; final: `20260322000005_replace_task_request_update_in_place.sql`)

#### 📚 Documentation

- **API Contract**: `.TODO/improvement_the_system/ImplementReady/04_task-request-bid-flow/API_CONTRACT.md`
- **Threat Model**: `.TODO/improvement_the_system/ImplementReady/04_task-request-bid-flow/THREAT_MODEL.md`
- **Developer Guide**: `Sline_everything/DEVELOPER_GUIDE.md#task-request-bid-flow` (new section)
- **Quick Reference**: `Sline_everything/FEATURE_BID_FLOW.md` (new file)
- **Project Context**: `.cursor/PROJECT_CONTEXT.md` (bid flow overview)

#### 📊 Impact

- Complete bid lifecycle from submission through payment
- Race condition protection with price validation
- Automatic cleanup of stale awards
- Comprehensive error handling with user-friendly messages
- Full test coverage (unit, widget, RLS)

#### 🧪 Verification

- Unit tests: `flutter test test/unit/tender/`
- RLS tests: `flutter test test/rls/task_requests_rls_test.dart`
- Smoke test: `.TODO/SMOKE_TEST_TENDER.md`
- Manual: Award → Payment → Work activation flow

#### 🔐 Security Verification

- [x] RLS negative tests pass (direct UPDATE → 403)
- [x] Race condition tests pass (concurrent accepts)
- [x] State machine validation (work without escrow blocked)
- [x] Rate limiting tests (2s debounce)
- [x] Notification verification (reject creates notification)

### 🟢 Version 2.25 — Phase 6 Chat & Messaging Redesign

**Date**: 2026-04-10
**Status**: Phase 6 Complete — Chat & Messaging visual redesign with advanced interactions
**Commit**: _Pending_

#### ✅ Implemented

- **Conversation List Redesign**: Elevated card tiles with `AppDecorations.elevation(1)`, left accent bar (3.5px primary) for unread state, inline unread dot (7px), primary border glow, "You:" prefix on sent messages, relative time formatting (Just now/Xm/Xh/Yesterday/weekday/MMMd), 50px circular avatar with online status dot
- **Unread State Management**: Optimistic local update via `markConversationReadLocally()` + background `fetchConversations()` reconciliation. Unread pill badge in header showing total count
- **Message Bubble Enhancements**: Emoji-only rendering (large without bubble for 1-3 emoji), link detection with tappable URLs via RichText, reply quote display (sender name + quoted text)
- **Chat Interaction Features**: Swipe-to-reply gesture, long-press context menu, reply preview bar in composer
- **Instant Chat Navigation**: Deferred `fetchMessages` from pre-navigation blocking call to `ChatScreen.initState()` with loading spinner, eliminating ~500ms+ lag
- **Auto-Scroll Fix**: Differentiated initial load (always scroll to bottom) vs incremental updates (scroll only if within 300px of bottom)
- **Offer Message Bubble**: Elevated card with AnimatedContainer, status-colored border, CUSTOM OFFER badge, status chips (Pending/Accepted/Declined/Completed)
- **FullscreenImageViewer**: New reusable core widget with InteractiveViewer (pinch-to-zoom), close button, optional caption bar, full Semantics coverage
- **Search Bar**: Debounced filtering (300ms) in MessagesScreen header with animated toggle
- **Typing Indicator**: Disabled (TODO) — backend `otherUserTyping` unreliable, sine-wave dot pulse glitches. Downgraded from `TickerProviderStateMixin` to `SingleTickerProviderStateMixin`

#### 📁 New Files

| File | Purpose |
|------|---------|
| `lib/core/widgets/fullscreen_image_viewer.dart` | Reusable fullscreen image viewer with pinch-to-zoom |

#### 🔧 Modified Files

| File | Changes |
|------|---------|
| `lib/features/chat/view/widgets/conversation_list_tile.dart` | Complete redesign: elevated card, unread indicators, relative time, typing disabled |
| `lib/features/chat/view/messages_screen.dart` | Search bar, unread badge, deferred navigation, optimistic read clearing |
| `lib/features/chat/view/chat_screen.dart` | initState fetchMessages, loading spinner, auto-scroll fix, swipe-to-reply |
| `lib/features/chat/view/widgets/message_bubble.dart` | Emoji-only rendering, link detection, reply quotes |
| `lib/features/chat/view/widgets/offer_message_bubble.dart` | Elevated card, status borders, AnimatedContainer |
| `lib/features/chat/view/widgets/chat_context_widget.dart` | Pill polish with icon differentiation |
| `lib/features/chat/attachments/widgets/attachment_message_tile.dart` | Fullscreen viewer integration |
| `lib/features/chat/viewmodels/chat_view_model.dart` | Added `markConversationReadLocally()` |
| `lib/features/notifications/view/widgets/notification_badge_button.dart` | Ticker mixin fix |
| `test/widget/chat/phase6_advanced_interactions_test.dart` | 19 new widget tests (47 total chat tests pass) |

#### 📚 Documentation

- **Session Log**: `docs/LOG/SESSION_PLAN_Phase6_ChatAdvancedInteractions_2026-04-10.md`
- **System Evolution**: `docs/LOG/SYSTEM_EVOLUTION_REPORT_2026-04-10.md`
- **Developer Guide**: Updated Chat Feature Reference file inventory (v2.25.0)
- **Structure**: Updated core/widgets/ and features/chat/ entries
- **Code Review**: 3 new guardrail notes (Deferred Navigation, Optimistic Updates, Auto-Scroll)

#### 📊 Impact

- Chat conversations open instantly (no pre-fetch lag)
- Unread indicators clear immediately on conversation open
- Emoji messages render at large size for visual emphasis
- URLs are tappable inline within message bubbles
- Image attachments viewable fullscreen with pinch-to-zoom
- Conversation list visually distinguishes read vs unread at a glance

#### 🧪 Verification

- Widget tests: `flutter test test/widget/chat/` — 47/47 pass
- Full suite: `flutter test` — 1392 pass, 30 skip, 1 pre-existing flaky
- Analyzer: `flutter analyze` — 0 errors, 0 warnings, 4 pre-existing infos
- Formatter: `dart format --set-exit-if-changed .` — clean

#### 🔒 Known Limitations (Backend Gaps)

- Reply storage: needs `reply_to_message_id` column + MessageService + ChatViewModel.sendReply()
- Message deletion: needs `delete_message` RPC with ownership verification
- Delivery/read receipts: needs full status chain (sending→sent→delivered→read)
- Explicit online status: using `presenceUpdatedAt` within 60s as heuristic (no `isOnline` field)
