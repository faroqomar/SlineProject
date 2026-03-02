# Architect Report: NotificationsFix + Approve-and-Release Ledger

**Date:** 2026-03-02  
**Scope:** Notifications server-authority completion + Approve-and-Release ledger fix  
**Plan reference:** `.TODO/Archive/NotificationExecution/PLAN_NotificationsFix_2026-03-01.md` (executed; log: `.TODO/Archive/NotificationExecution/EXECUTION_LOG_PLAN_NotificationsFix_2026-03-01.md`)  
**Additional work:** Ledger `release_with_fee` fix (migrations `20260307`, `20260308`; zero-amount line + enum cast)

**Constraints applied:** No changes to other features; strict MVVM; no breaking changes.

---

## 1. Architecture / Logic Findings

### 1.1 MVVM boundary check

| Layer | Finding | Status |
|-------|---------|--------|
| **View** | No direct Supabase, no `.from()`, no `.rpc()`. Views use `Consumer<NotificationViewModel>`, `context.read<NotificationViewModel>()`, `context.read<DeepLinkService>()`. | ✅ Compliant |
| **ViewModel** | `NotificationViewModel` holds no `BuildContext`; no navigation logic. Uses `NotificationService` for data and Supabase auth only (`onAuthStateChange`, `currentUser`) for lifecycle. | ✅ Context-free |
| **Service** | `NotificationService` is read/update-only: `getNotifications`, `streamNotifications`, `markAsRead`, `markAllAsRead`. All queries scoped by `user_id` (defense-in-depth). No `createNotification` / `createOrUpdateNotification`. | ✅ Server-authority aligned |
| **Navigation** | Lives in view layer: `NotificationBadgeButton` opens modal via `NotificationsModal.show(context)`, receives `NotificationItem?`, then calls `DeepLinkService.handleNotification(context, selected)` with **parent** context (after `context.mounted`). Modal returns selection via `Navigator.pop(context, notification)`; no navigation from disposed sheet context. | ✅ Correct |

**Evidence:**  
- Grep in `lib/features/notifications/`: Supabase/`.from`/`.rpc` only in `notification_service.dart` and `notification_view_model.dart` (auth only).  
- `notification_view_model.dart`: no `BuildContext` or `context.` usage.  
- `notifications_modal.dart`: tap flow is mark-as-read → `Navigator.pop(context, notification)`; caller (badge) owns navigation via `DeepLinkService`.

### 1.2 Data flow map

```
Server (triggers/RPCs) → public.notifications (realtime)
        ↓
NotificationService.streamNotifications() / getNotifications()
        ↓ (user_id filter)
NotificationViewModel (_connect / _disconnect on auth state)
        ↓ (notifyListeners)
View: Consumer<NotificationViewModel> → NotificationTile, badge count
        ↓ (user taps row)
Modal: vm.markAsRead(id) → Navigator.pop(context, notification)
        ↓
Badge: DeepLinkService.handleNotification(context, selected)
        ↓
DeepLinkService.navigateToEntity (task / booking / conversation / task_request / …)
```

- **task_request:** Handled in `DeepLinkService.handleNotification`: metadata `conversation_id` first, else `task_id`; routes to conversation or task; fallback SnackBar if neither present. Aligned with `.TODO/CONTRACT_notifications_2026-03-01.md`.

### 1.3 Path / contract validation

- **Notification model:** `NotificationItem.fromJson` uses `id`/`user_id` via `.toString()`, `title`/`message` as non-nullable `String`, `type` with fallback `_parseType(… ?? 'system')`, `metadata` via `_parseMetadata` (null/map safe). Contract columns `message`, `is_read`, `metadata` and server-emitted types are respected; unknown `type` → `NotificationType.system`.  
- **Optional hardening:** If the server can ever send null `title`/`message`, `fromJson` will throw on `as String`; consider `as String?` with fallback for resilience.  
- **Deep link contract:** Supported entity types (task, booking, conversation/message, direct_offer, profile, user, **task_request** via metadata) match contract; default branch logs and shows SnackBar without crashing.

### 1.4 Approve-and-Release ledger (booking_service + migrations)

- **App:** `BookingService.approveAndRelease(bookingId)` loads booking, then calls `LedgerService(_client).submitPaymentEvent(eventType: 'release_with_fee', relatedEntityType: 'booking', relatedEntityId: booking.id, amountGross: booking.price ?? 0, meta: {'fee_rate_bps': 0})`. No Supabase in view; booking/ledger usage stays in service/repository layer.  
- **Backend:**  
  - **20260307_fix_ledger_event_type_enum.sql:** `process_payment_event_ledger` casts `p_event_type` / `p_related_entity_type` to `payment_event_type_enum` / `related_entity_type_enum` on INSERT into `journal_entries`; RELEASE_WITH_FEE block inserts ledger lines with `WHERE line.amount > 0` (skips zero-amount fee line when `fee_rate_bps = 0`), and booking/direct_offer UPDATEs use explicit `::public.payment_status_enum` / `::public.booking_status_enum` casts.  
  - **20260308_fix_release_with_fee_zero_amount_and_enum.sql:** Idempotent patch that replaces the old RELEASE_WITH_FEE block with the same zero-amount skip and explicit enum casts.  
- **Contract:** App sends `release_with_fee` + `fee_rate_bps: 0`; backend computes `v_fee_amount = 0` and omits the platform_revenue line; provider still receives full `v_net_amount`. Aligned with `ck_ledger_lines_amount_positive` and avoids prepared-plan type mismatch (parameter 40).

---

## 2. Proposed refactors and contract checks

- **No mandatory refactors.** Current structure respects MVVM, server-authority notifications, and ledger usage.  
- **Optional:**  
  - **NotificationItem.fromJson:** If backend can send null `title` or `message`, use safe casts (e.g. `as String?` with default) to avoid runtime errors.  
  - **DeepLinkService:** Consider extracting a small “supported entity types” list or enum for consistency with `.TODO/CONTRACT_notifications_2026-03-01.md` and future additions.  
- **Contract checks:**  
  - Notifications: App is read/update-only; server-emitted types and `task_request` routing match CONTRACT.  
  - Ledger: `release_with_fee` with zero fee is supported by 20260307/20260308; app payload matches RPC expectations.

---

## 3. Files / paths scanned and references

### 3.1 Scanned paths (evidence)

| Path | Purpose |
|------|--------|
| `lib/features/notifications/models/notification_model.dart` | Model, fromJson, type/metadata parsing |
| `lib/features/notifications/services/notification_service.dart` | Read/update-only API, user_id filter |
| `lib/features/notifications/viewmodels/notification_view_model.dart` | Auth-aware lifecycle, no context |
| `lib/features/notifications/view/notifications_modal.dart` | Modal, keys, tap → pop(notification) |
| `lib/features/notifications/view/widgets/notification_badge_button.dart` | Badge, show modal, DeepLinkService.handleNotification |
| `lib/features/notifications/view/widgets/notification_tile.dart` | Tile UI, no Supabase |
| `lib/core/services/deep_link_service.dart` | handleNotification, task_request, navigateToEntity |
| `lib/features/booking/services/booking_service.dart` | approveAndRelease, LedgerService.submitPaymentEvent |
| `lib/features/wallet/services/ledger_service.dart` | submitPaymentEvent, RPC params |
| `supabase/migrations/20260307_fix_ledger_event_type_enum.sql` | Enum casts, RELEASE_WITH_FEE zero-amount skip |
| `supabase/migrations/20260308_fix_release_with_fee_zero_amount_and_enum.sql` | Idempotent patch for same |
| `lib/main.dart` | NotificationViewModel and DeepLinkService provider registration |
| `.TODO/Archive/NotificationExecution/PLAN_NotificationsFix_2026-03-01.md` | Plan and scope |
| `.TODO/Archive/NotificationExecution/EXECUTION_LOG_PLAN_NotificationsFix_2026-03-01.md` | Execution status |
| `.TODO/CONTRACT_notifications_2026-03-01.md` | Notification and routing contract |

### 3.2 Core/services notification-related

- **Grep:** `lib/core/services` for “notification” → only `deep_link_service.dart` (handles notification routing). No separate `notification*` service in core; notification logic correctly lives under `lib/features/notifications/`.

### 3.3 Missing or invalid references

- **None.** All references to `NotificationItem`, `NotificationViewModel`, `NotificationService`, `NotificationsModal`, and `DeepLinkService` are valid.  
- `lib/features/dashboard/view/widgets/next_actions_list.dart` uses `context.read<sline_deep_link.DeepLinkService>()` via import alias `as sline_deep_link`; same type as `lib/core/services/deep_link_service.dart`.  
- No dangling or broken imports in the scanned notification and ledger paths.

---

## 4. Evidence summary

| Check | Result | Evidence |
|-------|--------|----------|
| No direct Supabase in notification **views** | Pass | Grep: no Supabase/`.from`/`.rpc` in `view/` or `view/widgets/` |
| ViewModel context-free | Pass | No `BuildContext` or `context.` in `notification_view_model.dart` |
| Navigation in view layer | Pass | Badge calls `NotificationsModal.show(context)` then `DeepLinkService.handleNotification(context, selected)` with mounted context |
| Service read/update-only | Pass | Only getNotifications, streamNotifications, markAsRead, markAllAsRead; user_id on all |
| task_request routing | Pass | DeepLinkService.handleNotification branches on type, uses metadata conversation_id / task_id |
| Ledger release_with_fee (zero fee) | Pass | 20260307/20260308 skip zero-amount line; enum casts on booking/direct_offer |
| approveAndRelease → LedgerService | Pass | BookingService uses LedgerService.submitPaymentEvent; no Supabase in booking views for this path |

**Conclusion:** The NotificationsFix scope and the approve-and-release ledger fix are architecturally sound, MVVM-compliant, and consistent with the plan and contract. No blocking refactors; optional hardening and contract documentation improvements are noted above.
