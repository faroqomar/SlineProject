# SLine MVP Roadmap

**Last Updated:** 2026-04-05

This roadmap tracks the current code-state of the repository. Status values are intentionally simple:
- `✅ Completed`
- `🚧 In Progress`
- `⏳ Planned`

## 1. Foundation

| Area | Status | Notes |
| --- | --- | --- |
| Flutter app shell and navigation | ✅ Completed | `main.dart` + `lib/app/main_navigation_screen.dart` |
| Supabase bootstrap and app providers | ✅ Completed | shared client/bootstrap in `lib/core/services/supabase_config.dart` and root providers in `main.dart` |
| Theme system (Layer 1) | ✅ Completed | Phase 0: `app_colors.dart`, `app_typography.dart`, `app_motion.dart`, `app_states.dart`, `app_decorations.dart`, `app_theme.dart` |
| Layout tokens (Layer 2) | ✅ Completed | Phase 0.7: `app_layout.dart` (41 semantic tokens), `app_dimens.dart` (raw primitives). Three-layer architecture complete. |
| Logging and crash boundaries | ✅ Completed | `AppLogger`, `CrashReportingService`, zoned/global handlers |
| Documentation hub | ✅ Completed | maintained under `Sline_everything/` |

## 2. Identity and Profile

| Feature | Status | Notes |
| --- | --- | --- |
| Email/password auth | ✅ Completed | login, signup, forgot password |
| Session-aware logout and auth listener | ✅ Completed | `AuthSessionViewModel` + `AuthFormViewModel` + app-shell callback |
| Admin force-logout enforcement | ✅ Completed | app guard compares `profiles.force_logout_after` vs session issue time on app start/resume |
| Moderation enforcement (`active/suspended/banned`) | ✅ Completed | restricted accounts are blocked from sensitive actions and routed to dedicated restricted UX |
| Profile editing and avatar handling | ✅ Completed | profile repository/service/viewmodel flow exists |
| Role switching | ✅ Completed | v2.18: Atomic RPC with race protection, JWT claim sync, teardown contract, audit logging. See `lib/features/profile/data/role_switch_repository.dart`, `lib/core/services/role_switch_coordinator.dart`, `supabase/migrations/20260306_role_switch_foundation.sql` |

## 3. Marketplace Discovery

| Feature | Status | Notes |
| --- | --- | --- |
| Home feed and task discovery | ✅ Completed | repo implementation is live; production rollout depends on the `20260301_*home*` migrations and RLS verification |
| Category-backed task browsing | ✅ Completed | categories feature and task filters exist |
| Booking discovery feed | ✅ Completed | `BookingsDiscoveryScreen` reuses the task feed for booking tasks |
| Search | 🚧 In Progress | dedicated `search/` feature exists; ongoing refinement |
| Services/proposals surfacing | ✅ Completed | Proposals remediation (Mar 2026): models, repositories, payment route, view re-exports; secure RPCs; list/submit/award/pay from Inbox/Work/Requests; see DEVELOPER_GUIDE/Proposals_Feature.md |

## 4. Tasks and Tender Workflows

| Feature | Status | Notes |
| --- | --- | --- |
| Task creation and editing | ✅ Completed | create/detail/edit flows exist |
| Task requests / tender offers | ✅ Completed | request services, inbox award flow, task detail actions |
| Delivery submission and approval | ✅ Completed | RPC-backed delivery flow exists. **Work contract revisions (2025-03-08):** `rpc_request_revision` enforces status=delivered and revisions_used &lt; revisions_total; ErrorMapper + UI disable when no revisions left. Plan: `.TODO/PLAN_WorkContractRevisions_2025-03-08_PlanCritic.md`. |
| Tender payment flow | ✅ Completed | **Award = reserve only;** assign only after payment (`accept_task_request` and `award_task_offer` do not set freelancer; `pay_awarded_offer` assigns and sets in_progress). `TenderPaymentCoordinator` + `TenderPaymentViewModel`; award → pay from Inbox/Requests (client inbox includes accepted+unpaid offers so Pay Now appears); ledger-backed; fail-closed when Demo/QiCard (March 2026); `replace_task_request` in migrations; offer submit no longer mutates `active_role`. Migrations: 20260308180000, 20260308180100. |

## 5. Booking and Payment Flows

| Feature | Status | Notes |
| --- | --- | --- |
| **Booking Lifecycle hardening (2026-03-08)** | ✅ Completed | Enum `disputed`, `no_show`; `fn_booking_guard` blocks client delivered→canceled (use Report Issue→disputed); `rpc_finalize_auto_approval` booking branch calls ledger; `admin_resolve_booking_dispute` for disputed→completed/refunded. Plan: `.TODO/PLAN_BookingLifecycle_2026-03-08_PlanCritic.md`. Execution: `.TODO/EXECUTION_LOG_PLAN_BookingLifecycle_2026-03-08.md`. |
| Direct booking checkout | ✅ Completed | `PaymentCheckoutScreen` + server-backed draft creation |
| QiCard integration | 🚧 In Progress | create/recovery/webhook flow exists and continues to be hardened |
| Web payment callback handling | ✅ Completed | same-tab redirect + `PaymentReturnScreen` |
| Mobile payment callback handling | ✅ Completed | `PaymentWebViewScreen` validates trusted callbacks |
| Repeat slotless direct bookings | ✅ Completed | same client can create multiple slotless bookings for one booking task |
| Booking details and history | ✅ Completed | client/provider history lists and detail screen exist |

## 6. Collaboration and Communication

| Feature | Status | Notes |
| --- | --- | --- |
| Realtime chat (08_chat-realtime-sync + 18_topology) | ✅ Completed | Messages-only realtime: active chat `subscribeToMessages(conversationId)`; Inbox `subscribeToInboxMessages(userId)` (conversations not in publication; no N+1). Presence (typing, 15s TTL, 5s throttle); delivered/read receipts; feature flag `chat_presence_receipts_enabled`; ChatRealtimeMerger; archive via RPC `archive_conversation_v1`; offer payload. See `.TODO/PLAN_ChatRealtimeSync_2026-03-07_PlanCritic.md`, `.TODO/PLAN_RealtimeSubscriptionTopology_2026-03-07.md`, diagram 18. |
| Direct Chat Offers | ✅ Completed | accept in chat → Pending Payment in dashboard → Pay from dashboard (QiCard); `lib/features/direct_offers/`; edge `qicard_payment_create_direct_offer`, `qicard_payment_recovery_direct_offer`. **2026-03-08 hardening:** delivered_at/review_expires_at, auto-release cron, disputes.direct_offer_id, fee from row, trigger protect price/currency/fee. Plan: `.TODO/PLAN_DirectChatOfferFlow_2026-03-07_CRITIC.md`. |
| Attachments | ✅ Completed | private attachment flow; participant-scoped access via `can_access_chat_attachment` |
| Favorites-powered contact flows | ✅ Completed | favorites and chat handoff are implemented |
| Chat Creation Matrix (v2.19) | ✅ Completed | Atomic RPC `start_direct_conversation_v1` with rate limiting (20/hr), favorites enforcement, role verification. Guard trigger hardens all paths. Feature flag `enable_direct_conversation_rpc`. See `supabase/migrations/20260306000000_chat_creation_matrix.sql` |
| Notifications | ✅ Completed | Server-authority: client read/update only; badge, modal, deep links; auth-aware stream. **Notification routing (2026-03-08):** `user_devices` + `notification_push_queue`, trigger enqueue; ViewModel foreground sync then stream; Edge `push-notify`, `process-push-queue` (CRON_SECRET); runbook `.TODO/improvement_the_system/ImplementReady/13_notification-routing/RUNBOOK_notification_push.md`. Plan: `.TODO/PLAN_NotificationRouting_2026-03-08_PlanCritic.md`. Diagram: `Sline_everything/AppDigram/All_Diagrams/13_notification-routing.md`. |
| Report flows (task/user/chat) | ✅ Completed | app can submit `reports` rows from task detail, chat menu, and public profile |
| Booking dispute submission | ✅ Completed | booking details `Report Issue` when active or delivered; **Dispute lifecycle (2026-03-08):** escrow guard in rpc_approve_delivery and rpc_finalize_auto_approval; RLS deny on disputes; dispute_status_enum + trg_dispute_guard + trg_dispute_set_resolved_at; SafetyViewModel.hasOpenDisputeForTask/ForBooking/ForDirectOffer; Approve/Review disabled when disputed on booking, work item, direct offer details; vw_unified_work_items disputed check. **Plan 14a (2026-03-08):** Frozen guards in rpc_submit_delivery and rpc_request_revision; partial unique indexes (one open/active dispute per task/direct_offer); rpc_submit_dispute (eligibility + single-active); Report Issue on task and direct_offer (work item + direct offer details); open/active dispute banners. Migration: 20260308160000. Plan: `.TODO/PLAN_DisputeLifecycle_2026-03-08.md`, `.TODO/PLAN_14a_DisputeExtension_2026-03-08.md`. |

## 7. Workspace, Orders, and Management

| Feature | Status | Notes |
| --- | --- | --- |
| Unified dashboard/workspace | ✅ Completed | Single `DashboardScreen`; cache wiring, lazy-load by tab, wallet snapshot on entry; MyServices off dashboard; booking/offer/wallet cards in owning features + `StatusPresenter`. **Work list and detail (2026-03-08):** Single source `vw_unified_work_items` (4 branches: tasks, bookings, awarded pending, direct_offers); no fallback mappers; Plan 12: `.TODO/PLAN_UnifiedWorkView_2026-03-08_CRITIC.md`, `.TODO/MASTER_REPORT_2026-03-08_UnifiedWorkView.md`. |
| Booking/task CTA resolution | ✅ Completed | unified CTA resolver is used by work/booking screens |
| Order management timeline | ✅ Completed | management feature is live for task and booking details |
| Wallet and ledger views | 🚧 In Progress | Wallet feature and ledger schema exist; ongoing finance hardening. **2026-03-07:** Escrow idempotency (stable key + FOR UPDATE); **rpc_approve_delivery** extended for **direct_offer** (single exit for escrow release); DirectOffersService.completeOffer uses RPC. Dashboard includes dedicated **Wallet tab** (balance, activity, Coming Soon withdraw). See `.TODO/improvement_the_system/Done/21_Wallet_System_Escrow_Available_balances/PLAN_WalletEscrowAvailableBalances_2026-03-07_CRITIC.md`, `.TODO/improvement_the_system/Done/21_Wallet_System_Escrow_Available_balances/EXECUTION_LOG_PLAN_WalletEscrowAvailableBalances_2026-03-07.md`, `Sline_everything/DEVELOPER_GUIDE/Wallet_Feature.md` §4, `.TODO/improvement_the_system/Done/09_ledger-event-flow/CONTRACT_ledger_event_flow.md`. Withdraw = Upcoming. |
| Runtime system config UX | ✅ Completed | maintenance screen, minimum-version gate, signup-disable messaging, and shell app-banner are wired to public config |

## 8. Quality and Operations

| Area | Status | Notes |
| --- | --- | --- |
| CI/CD pipeline | ✅ Completed | GitHub Actions: lint + test + build + architecture guard. `.github/workflows/ci.yml`. Added 2026-04-01. |
| Pre-commit hook | ✅ Completed | `.githooks/pre-commit` runs format + analyze locally. Enable: `git config core.hooksPath .githooks`. Added 2026-04-01. |
| Lint rules (34 rules) | ✅ Completed | `analysis_options.yaml`: 18 core + 7 safety + 9 code quality. Strong mode enabled. Updated 2026-04-01. |
| Architecture guard | ✅ Completed | 7 MVVM boundary checks in CI (hard failure). Graduated 2026-04-01 after Phase B fixed all violations. |
| Phase B: Bug Exposure | ✅ Completed | 48 unawaited_futures → 0, 258 bare catches → 0, 6 MVVM violations → 0. `flutter analyze` = 0 issues. Completed 2026-04-01. |
| Phase C: Critical Tests | ✅ Completed | 706 pass / 30 skip / 0 fail (+306 tests). 14/26 VMs tested (54%). 14 model test files. WalletVM + ChatVM refactored for DI. Shared mock file created. Completed 2026-04-02. |
| Supabase migrations | ✅ Completed | repo contains live migration history under `supabase/migrations/` |
| Edge functions | ✅ Completed | booking/payment functions are checked into `supabase/functions/` |
| Docs sync discipline | ✅ Completed | docs now reflect current `view/viewmodels/data/services` layout and payment/runtime helpers |

## 9. Completed Phases

### ✅ Phase D: Harden (2026-04-04)

All 11 items (D1–D11) completed:
- Sentry crash reporting (replaces NoOp)
- DashboardVM decomposition (1149→537L, 3 delegates)
- submit_request_sheet decomposition (916→737L, SubmitRequestViewModel)
- requests_list_screen decomposition (1172→604L, RequestsFilterViewModel + award dialog)
- pgTAP SQL tests (3 files, 15 test cases)
- Migration review checklist (7 sections)
- Edge Function CORS hardening (wildcard `*` → `sline.app` allowlist)
- paymentId regex validation in webhook handler
- CI coverage floor (28% regression prevention)
- A6 architecture violations fixed (NotificationVM, SavedTasksVM)
- Architecture guard Check 3 tightened

Tests: 706 → 780 (+74). Coverage floor: 40%. All 6 architecture guard checks pass.

### Phase E: Polish (2026-04-05) ✅
- **E1** — APK build self-resolved (Kotlin version mismatch fixed by SDK update)
- **E2** — CI Check 7 added: `core/` → `features/` boundary guard (max 5 threshold)
- **E3** — Lint migration to `very_good_analysis` (862 auto-fixes, 27 rules disabled with tracking in `.TODO/LINT_DEBT_PhaseE.md`)
- **E4** — 5 ViewModels DI-normalized with lazy getter pattern (SavedTasks, Categories, Portfolio, PublicProfile, AuthForm)
- **E5** — Sealed `ViewState<T>` and `AppFailure` classes created; 3 VMs migrated (DirectOfferDetails, Booking, WorkItemDetails)
- **E6** — 9 god files decomposed below 800 lines (13 new delegate/widget files, 29% average line reduction)
- **E7** — 171 new VM tests (27/27 VMs now have test coverage); 982 total tests
- **E8** — Coverage floor raised from 28% to 33% (measured: 34.9%)
- **E9** — DeepLinkService refactored to registry pattern (0 feature imports, 6 feature handler files)
- **E10** — Localization infrastructure scaffolded (l10n.yaml, app_en.arb with 22 key stubs)
- **E11** — Orchestrator review: 20 findings (1 BLOCKER + 4 HIGH + 8 MED + 7 LOW) — all fixed
- **E12** — Security review: 8 findings (2 HIGH + 3 MED + 3 LOW) — all fixed
- **E13** — System Evolution Report v4: 16 recommendations applied to all 16 agent files

**References:**
- Plan: `.TODO/PLAN_PhaseE_Polish_2026-04-04.md`
- Session Log: `docs/LOG/SESSION_PLAN_PhaseE_Polish_2026-04-04.md`
- Master Report: `.TODO/MASTER_REPORT_2026-04-05_PhaseE.md`
- System Evolution: `docs/LOG/SYSTEM_EVOLUTION_REPORT_2026-04-05.md`
- Lint Debt: `.TODO/LINT_DEBT_PhaseE.md`

## 10. Current Focus

### Current Focus
1. **Phase F: Ship Preparation** (planned) — Arabic/Kurdish translations, widget tests for critical views, remaining lint debt adoption, GitHub repo safeguards (branch protection, CODEOWNERS, PR templates), non-atomic payment RPC consolidation
