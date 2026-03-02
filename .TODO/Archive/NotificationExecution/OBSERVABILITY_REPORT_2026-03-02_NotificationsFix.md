# Observability Report: NotificationsFix (Notifications + Approve-and-Release Ledger)

**Date:** 2026-03-02  
**Scope:** Notifications server-authority, auth-aware stream, deep links (task_request), modal return value, badge→DeepLink flow; ledger 20260307/20260308 (zero-amount skip, enum casts).  
**Plan:** `.TODO/Archive/NotificationExecution/PLAN_NotificationsFix_2026-03-01.md`

---

## 1. Telemetry Gaps

### Notifications & Deep Link

| Gap | Description |
|-----|-------------|
| **Notification tap by type** | Tap is logged in badge as `Notification selected id=...` and in DeepLink as `handleNotification: entityType=... id=...`. There is no **structured event** (e.g. `notification_tap`) with `related_entity_type` and outcome (success / unsupported / missing_metadata). Analytics cannot reliably count taps by type or success rate. |
| **Deep link outcome** | After `navigateToEntity`, success is not logged (only errors via "Deep link navigation failed"). No event for "navigated to task/booking/conversation" with entity type and id. |
| **task_request branch** | Branch (conversation vs task vs missing metadata) is logged at debug/warn but not as a single event with a consistent taxonomy (e.g. `deep_link_task_request_routed` / `deep_link_task_request_fallback` / `deep_link_task_request_failed`). |
| **Activity / work item taps** | `handleActivity` and `handleWorkItem` do not use tag `DeepLink` and use ad-hoc messages; not aligned with notification tap taxonomy. |

### Ledger & Release

| Gap | Description |
|-----|-------------|
| **release_with_fee success** | **BookingService:** logs "Approve and release submitted for booking $bookingId" on success and "Failed to release booking" on failure (tag `Booking`). **LedgerService:** logs "Submitting Ledger Event: release_with_fee for ..." but does **not** log success when RPC returns ok (only logs on `ok: false` or exception). Cannot distinguish "RPC succeeded" from "RPC not yet returned" in logs. |
| **release_with_fee by caller** | Task_service and direct_offers_service call `release_with_fee`; task_service only logs on error ("Failed to release offer funds") with no tag; direct_offers logs "[DirectOffers] completed offer=$offerId" but no `eventType` in message. No shared event name (e.g. `ledger_release_with_fee_success` / `ledger_release_with_fee_failure`) across booking/task_request/direct_offer. |
| **LedgerService tag** | First log in `submitPaymentEvent` has no tag; only the `ok: false` branch uses `tag: 'LedgerService'`. PostgrestException and generic catch use no tag. |

### Correlation

| Gap | Description |
|-----|-------------|
| **End-to-end flow** | No **correlation_id** is generated or propagated. A user flow "notification tap → deep link → load task/booking/chat" cannot be traced across NotificationBadgeButton → DeepLinkService → Task/Booking/MessageService in logs. |
| **Ledger RPC** | Idempotency key is generated and sent to RPC but not logged; replay or debugging of a specific release cannot be tied to a single user session flow without external tooling. |

---

## 2. Event Taxonomy: Current vs Missing

### Implemented (Log Points Present)

**Notifications (tag: `Notifications`)**

| Location | Level | Message / Content |
|----------|--------|-------------------|
| NotificationService.getNotifications | d | "getNotifications: no session, returning empty" |
| NotificationService.getNotifications | d | "getNotifications: fetching" / "getNotifications: got ${list.length}" |
| NotificationService.getNotifications | e | "Failed to fetch notifications" (error, stackTrace) |
| NotificationService.streamNotifications | d | "streamNotifications: no session..." / "connecting for user" / "received ${list.length}" |
| NotificationService.markAsRead | d | "markAsRead: $notificationId" |
| NotificationService.markAsRead | e | "Failed to mark notification as read" |
| NotificationService.markAllAsRead | d | "markAllAsRead requested" |
| NotificationService.markAllAsRead | e | "Failed to mark all as read" |
| NotificationViewModel | d | "session ready, connecting stream" / "signed out, disconnecting..." / "no session, stream not started" / "stream connect" |
| NotificationViewModel | e | "Error streaming notifications" / "Failed to update notification" / "Failed to mark all as read" |
| NotificationBadgeButton | d | "Notification badge tapped, opening modal" / "Notification selected id=..." |

**DeepLink (tag: `DeepLink` where noted)**

| Location | Level | Message / Content |
|----------|--------|-------------------|
| DeepLinkService.handleNotification | i | "handleNotification: entityType=... id=..." (tag: DeepLink) |
| DeepLinkService (task_request) | d | "task_request: routing to conversation $convId" / "routing to task $taskId" (tag: DeepLink) |
| DeepLinkService (task_request) | w | "task_request: no conversation_id or task_id in metadata" (tag: DeepLink) |
| DeepLinkService.navigateToEntity | w | "Cannot navigate: ID or Type is null" (no tag) |
| DeepLinkService.navigateToEntity | w | "Notification route not supported: entityType=..." (tag: DeepLink) |
| DeepLinkService.navigateToEntity | e | "Deep link navigation failed" (tag: DeepLink) |
| DeepLinkService.handleActivity | i | "Handling activity tap: ..." (no tag) |
| DeepLinkService.handleWorkItem | i | "Handling work item tap: ..." (no tag) |

**Booking (tag: `Booking`)**

| Location | Level | Message / Content |
|----------|--------|-------------------|
| BookingService | i | "Updated booking ... status to ..." / "Escrow hold submitted..." / "Approve and release submitted for booking ..." / "Marked booking ... as delivered" / "Accepted booking ..." / etc. |
| BookingService | e | "Failed to list client bookings" / "Failed to release booking ..." / etc. |
| BookingService | w | "Promoting pending held booking before accept" (json: booking_id) |

**Ledger**

| Location | Level | Message / Content |
|----------|--------|-------------------|
| LedgerService.submitPaymentEvent | i | "Submitting Ledger Event: $eventType for $relatedEntityType:$relatedEntityId" (no tag) |
| LedgerService (result ok: false) | e | "Ledger RPC returned ok: false" (tag: LedgerService) |
| LedgerService (PostgrestException) | e | "Ledger RPC Failed: ..." (no tag) |
| LedgerService (catch) | e | "Unexpected Ledger Error" (no tag) |

**Task / Direct offers (release_with_fee call sites)**

| Location | Level | Message / Content |
|----------|--------|-------------------|
| task_service | e | "Failed to release offer funds" (no tag) |
| direct_offers_service | i | "[DirectOffers] completed offer=$offerId" (no eventType in message) |

### Missing (Recommended for Observability Plan)

- **Structured events (event_name + required fields):**
  - `notification_tap` — feature=notifications, entity_type, entity_id, notification_id (no body/title).
  - `deep_link_routed` — feature=deeplink, entity_type, entity_id, source=notification|activity|work_item, outcome=success|unsupported|missing_metadata.
  - `ledger_release_with_fee_submitted` / `ledger_release_with_fee_success` / `ledger_release_with_fee_failure` — feature=ledger, entity_type, entity_id, caller=booking|task_request|direct_offer.
- **Consistent tagging:** All LedgerService and DeepLink (handleActivity, handleWorkItem) log points should use a stable tag.
- **Success log in LedgerService:** After RPC returns successfully, log once with tag and entity/event type (no sensitive payload).

---

## 3. Privacy-Safe Logging Plan

### Do NOT log

- **Notification content:** `message`, `title` (may contain PII or sensitive text). Already not logged in current code.
- **Full user identifiers:** No need to log full `userId` in notification logs; current code logs notification `id` (UUID) and `relatedEntityId` which are acceptable for support/debug.
- **Metadata payloads:** Log only what is needed for routing (e.g. presence of conversation_id/task_id), not full `metadata` JSON (could contain internal IDs only—acceptable if redacted elsewhere; avoid logging entire object).
- **Tokens / keys:** Idempotency key should not be logged in full if it could be reused; optional last 4 chars for debugging only.

### Safe to log (current and recommended)

- **IDs:** notification id, related_entity_id, task_id, booking_id, conversation_id (UUIDs/opaque IDs).
- **Types:** related_entity_type, entityType, route (task/booking/conversation).
- **Outcomes:** success/failure, error codes (e.g. ERR_GATE_NOT_ALLOWED), sanitized error messages.
- **Counts:** list length, unread count (already in stream logs).
- **Flow markers:** "routing to conversation", "routing to task", "no conversation_id or task_id" (no user content).

### Redaction

- AppLogger already masks `access_token` and `refresh_token` in JSON. Ensure no notification `message` or `title` is ever passed into AppLogger or crash context.

---

## 4. Correlation Strategy

### Current state

- No correlation_id is generated or passed.
- Notification tap → modal return → `handleNotification(context, selected)` → `navigateToEntity` is a single async flow; logs are ordered by time but not linked by a single id.

### Recommended approach

1. **Generate correlation_id on notification tap (view layer or ViewModel):**
   - When user taps a notification row, generate a UUID (or use a short id) as `correlation_id` for that tap.
2. **Pass correlation_id into DeepLinkService:**
   - e.g. `handleNotification(context, item, {String? correlationId})`.
3. **Log at each step with same correlation_id:**
   - Badge: "notification_tap" with correlation_id, entity_type, entity_id.
   - DeepLink: "deep_link_handling" / "deep_link_routed" with same correlation_id.
   - Optional: pass to TaskService.getTaskById / BookingService.getBookingById / MessageService.getConversationById as a logging-only parameter (or thread-local / zone) so service-layer logs can include it.
4. **Ledger flows:**
   - For approve-and-release, optionally pass a correlation_id from the booking/details screen into BookingService.approveAndRelease and LedgerService, and log it on submit and on success/failure so a single release can be traced across app and RPC.

### Minimal implementation

- Add correlation_id only to the notification→deep link path (badge → handleNotification → navigateToEntity), with 2–3 log points carrying the same id. Ledger correlation can be a follow-up.

---

## 5. Evidence: Files Scanned

| File | Purpose |
|------|--------|
| `lib/features/notifications/services/notification_service.dart` | Read/update-only API; AppLogger tag `Notifications`; getNotifications, streamNotifications, markAsRead, markAllAsRead. |
| `lib/features/notifications/viewmodels/notification_view_model.dart` | Auth-aware stream lifecycle; tag `Notifications`; connect/disconnect, retry, markAsRead/markAllAsRead errors. |
| `lib/features/notifications/view/notifications_modal.dart` | Modal show/return selected item; no direct logging. |
| `lib/features/notifications/view/widgets/notification_badge_button.dart` | Badge tap → modal → DeepLink; logs "badge tapped" and "Notification selected id=..." with tag `Notifications`. |
| `lib/features/notifications/models/notification_model.dart` | Model fields (id, userId, title, message, type, relatedEntityType, relatedEntityId, metadata, etc.); no logging. |
| `lib/core/services/deep_link_service.dart` | handleNotification (tag DeepLink), task_request routing, navigateToEntity; handleActivity/handleWorkItem without DeepLink tag. |
| `lib/features/booking/services/booking_service.dart` | getBookingById, approveAndRelease (release_with_fee), escrow_hold, decline, markDelivered, accept; tag `Booking`; success/error logs. |
| `lib/features/wallet/services/ledger_service.dart` | submitPaymentEvent; logs submit (no tag), ok:false (tag LedgerService), exceptions (no tag); no success log. |
| `lib/features/tasks/services/task_service.dart` | release_with_fee for task_request; only error log "Failed to release offer funds" (no tag). |
| `lib/features/direct_offers/services/direct_offers_service.dart` | release_with_fee for direct_offer; logs "[DirectOffers] completed offer=$offerId". |
| `lib/core/services/logger_service.dart` | AppLogger API; token masking in JSON; no notification-specific redaction. |

---

## Summary

- **Gaps:** Notification tap and deep link outcome are not structured events; release_with_fee success is not explicitly logged in LedgerService; no correlation_id end-to-end; inconsistent tags (Ledger, DeepLink for activity/work item).
- **Taxonomy:** Notifications and Booking use consistent tags; DeepLink is partial; Ledger and task/direct_offer release paths need aligned event names and tags.
- **Privacy:** No notification body or title in logs; only IDs and types—acceptable. Keep message/title and full metadata out of logs.
- **Correlation:** Introduce a correlation_id for notification tap → deep link → destination and optionally for approve-and-release flows.
- **Evidence:** All listed files were scanned; log points and tags are as described above.
