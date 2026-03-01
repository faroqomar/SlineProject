# SLine MVP Roadmap

**Last Updated:** 2026-03-02

This roadmap tracks the current code-state of the repository. Status values are intentionally simple:
- `✅ Completed`
- `🚧 In Progress`
- `⏳ Planned`

## 1. Foundation

| Area | Status | Notes |
| --- | --- | --- |
| Flutter app shell and navigation | ✅ Completed | `main.dart` + `lib/app/main_navigation_screen.dart` |
| Supabase bootstrap and app providers | ✅ Completed | shared client/bootstrap in `lib/core/services/supabase_config.dart` and root providers in `main.dart` |
| Theme system | ✅ Completed | centralized in `lib/core/theme/` |
| Logging and crash boundaries | ✅ Completed | `AppLogger`, `CrashReportingService`, zoned/global handlers |
| Documentation hub | ✅ Completed | maintained under `Sline_everything/` |

## 2. Identity and Profile

| Feature | Status | Notes |
| --- | --- | --- |
| Email/password auth | ✅ Completed | login, signup, forgot password |
| Session-aware logout and auth listener | ✅ Completed | `AuthViewModel` + app-shell callback |
| Profile editing and avatar handling | ✅ Completed | profile repository/service/viewmodel flow exists |
| Role switching | ✅ Completed | role flows exist in profile/dashboard surfaces |

## 3. Marketplace Discovery

| Feature | Status | Notes |
| --- | --- | --- |
| Home feed and task discovery | ✅ Completed | repo implementation is live; production rollout depends on the `20260301_*home*` migrations and RLS verification |
| Category-backed task browsing | ✅ Completed | categories feature and task filters exist |
| Booking discovery feed | ✅ Completed | `BookingsDiscoveryScreen` reuses the task feed for booking tasks |
| Search | 🚧 In Progress | dedicated `search/` feature exists; ongoing refinement |
| Services/proposals surfacing | 🚧 In Progress | feature folders exist; product surface is still maturing |

## 4. Tasks and Tender Workflows

| Feature | Status | Notes |
| --- | --- | --- |
| Task creation and editing | ✅ Completed | create/detail/edit flows exist |
| Task requests / tender offers | ✅ Completed | request services, inbox award flow, task detail actions |
| Delivery submission and approval | ✅ Completed | RPC-backed delivery flow exists |
| Tender payment flow | 🚧 In Progress | payment path exists and is still being hardened alongside ledger flows |

## 5. Booking and Payment Flows

| Feature | Status | Notes |
| --- | --- | --- |
| Direct booking checkout | ✅ Completed | `PaymentCheckoutScreen` + server-backed draft creation |
| QiCard integration | 🚧 In Progress | create/recovery/webhook flow exists and continues to be hardened |
| Web payment callback handling | ✅ Completed | same-tab redirect + `PaymentReturnScreen` |
| Mobile payment callback handling | ✅ Completed | `PaymentWebViewScreen` validates trusted callbacks |
| Repeat slotless direct bookings | ✅ Completed | same client can create multiple slotless bookings for one booking task |
| Booking details and history | ✅ Completed | client/provider history lists and detail screen exist |

## 6. Collaboration and Communication

| Feature | Status | Notes |
| --- | --- | --- |
| Realtime chat | ✅ Completed | conversations/messages/realtime updates; archive via RPC `archive_conversation_v1`; offer payload + realtime merger in place |
| Attachments | ✅ Completed | private attachment flow; participant-scoped access via `can_access_chat_attachment` |
| Favorites-powered contact flows | ✅ Completed | favorites and chat handoff are implemented |
| Notifications | 🚧 In Progress | notification feature exists and is integrated into the dashboard shell |

## 7. Workspace, Orders, and Management

| Feature | Status | Notes |
| --- | --- | --- |
| Unified dashboard/workspace | 🚧 In Progress | `dashboard` and `work` are the live workspace surfaces; the standalone `orders` dashboard was removed after consolidation into the unified dashboard slot |
| Booking/task CTA resolution | ✅ Completed | unified CTA resolver is used by work/booking screens |
| Order management timeline | ✅ Completed | management feature is live for task and booking details |
| Wallet and ledger views | 🚧 In Progress | wallet feature and ledger schema exist; ongoing finance hardening continues |

## 8. Quality and Operations

| Area | Status | Notes |
| --- | --- | --- |
| Unit and widget test coverage | 🚧 In Progress | targeted coverage exists under `test/unit` and `test/widget` |
| Supabase migrations | ✅ Completed | repo contains live migration history under `supabase/migrations/` |
| Edge functions | ✅ Completed | booking/payment functions are checked into `supabase/functions/` |
| Docs sync discipline | ✅ Completed | docs now reflect current `view/viewmodels/data/services` layout and payment/runtime helpers |

## 9. Current Focus

1. Continue hardening QiCard webhook/recovery behavior.
2. Expand automated coverage around dashboard, wallet, and payment edge cases.
3. Keep `Sline_everything/` aligned with code and Supabase migrations after every flow change.
