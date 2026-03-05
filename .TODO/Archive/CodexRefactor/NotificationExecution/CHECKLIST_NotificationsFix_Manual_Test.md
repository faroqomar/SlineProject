# Manual test checklist: Notifications fix (app)

Use this list to verify all edited behavior on a real device/emulator with the app running against your Supabase project.

---

## 1. Auth and stream lifecycle

- [ ] **Signed out**
  - Open app while signed out (or sign out from profile).
  - Confirm no crash; notification bell is visible in home header.
  - Tap bell → modal opens; expect **empty state** (“No notifications yet”) or loading then empty.
  - Close modal. No errors in console/logs (optional: filter logs by tag `Notifications`).
- [ ] **Sign in**
  - Sign in with an account that has at least one notification (or trigger one from another flow).
  - After sign-in, open notification bell → list loads and shows notifications (or “No notifications yet” if none).
  - Confirm unread count badge shows correctly (0, 1–9, or 9+).
- [ ] **Sign out again**
  - From profile, sign out.
  - Open notification bell again → expect empty state (stream disconnected, list cleared).
  - No crash; no stale notifications from previous user.

---

## 2. Modal and tap flow

- [ ] **Open modal**
  - Signed in, tap bell → bottom sheet opens with “Notifications” title and “Mark all as read” / close.
  - If list is empty: “No notifications yet” is visible.
  - If list has items: rows show title, message, time; unread rows have subtle highlight.
- [ ] **Tap a notification**
  - Tap one notification row.
  - Modal **closes first**, then app navigates to the correct screen (task, booking, chat, etc.).
  - No “context used after dispose” or similar error in logs.
  - That notification appears as read (no highlight) if you reopen the modal.
- [ ] **Mark all as read**
  - With several unread notifications, tap “Mark all as read”.
  - All rows show as read; badge count goes to 0.
  - Reopen modal → all still read.
- [ ] **Dismiss without selecting**
  - Open modal, tap outside or close (X) without tapping a row.
  - No navigation occurs; no error.

---

## 3. Deep links by type

Test with real notifications of each type (create them via normal app flows if needed):

- [ ] **Task** – Tap notification → Task details screen opens for the correct task.
- [ ] **Booking** – Tap notification → Booking details screen opens for the correct booking.
- [ ] **Conversation / message** – Tap notification → Chat screen opens for the correct conversation.
- [ ] **task_request** (if you have offer/award/payment notifications):
  - Tap → opens **conversation** when metadata has `conversation_id`, or **task** when only `task_id` is present.
  - If metadata is missing both: SnackBar “Cannot open this notification.” and no crash.
- [ ] **Unsupported type** – If any notification has an unknown `related_entity_type`: SnackBar “Cannot open this item type: …” and no crash.

---

## 4. Error and retry

- [ ] **Stream error (simulate)**
  - Optional: turn off network or use an invalid Supabase URL to force stream failure.
  - Open modal → error message and **Retry** button appear.
  - Tap Retry (with network/URL fixed) → list loads or empty state.
- [ ] **Normal empty/loading**
  - With good network: loading spinner appears briefly, then list or “No notifications yet”.
  - No error state unless the stream actually fails.

---

## 5. Logging (optional)

- [ ] Filter logs by tag `Notifications` and/or `DeepLink`:
  - Badge tap → “Notification badge tapped, opening modal”.
  - After selecting a row → “Notification selected id=…”.
  - Deep link → “handleNotification: entityType=… id=…” and, for task_request, “task_request: routing to …”.
  - No **message body** or other PII in logs; only type, entity type, IDs.

---

## 6. Regression (other features)

- [ ] **Home** – Home screen loads; bell is visible and tappable; no regression in feed or header.
- [ ] **Chat** – Send/receive messages; message notifications still appear in notification list (server-created).
- [ ] **Tasks / bookings** – Create or update task/booking; any server-created notifications appear in list and open the right screen when tapped.

---

## Quick smoke (minimal run)

If time is short, do at least:

1. Sign in → tap bell → see list or empty.
2. Tap one notification → modal closes → correct screen opens.
3. Sign out → tap bell → empty state, no crash.
4. Mark all as read → count 0, all rows read.

---

**Reference:** Changes from `.TODO/PLAN_NotificationsFix_2026-03-01.md` and execution log `EXECUTION_LOG_PLAN_NotificationsFix_2026-03-01.md`.
