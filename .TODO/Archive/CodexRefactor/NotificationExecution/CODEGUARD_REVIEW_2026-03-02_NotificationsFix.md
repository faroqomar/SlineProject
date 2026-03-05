# CodeGuard Review Report: NotificationsFix

## Scope

- **Change Type:** MEDIUM (notifications server-authority + ledger approve-and-release fix)
- **Areas:** Notifications (UI / MVVM / Service), Deep links, DB migrations (ledger enum + zero-fee), RLS (notifications)
- **Files Reviewed:** NotificationService, NotificationViewModel, DeepLinkService, NotificationsModal, NotificationBadgeButton, notification_model, migrations 20260307 + 20260308, notification unit/widget tests

## Evidence Collected

- **Commands run:**
  - `flutter analyze lib/features/notifications test/unit/models/notification_model_test.dart test/unit/notifications test/widget/notifications` → **No issues found** (after removing 2 unused imports in tests).
  - `dart format lib/ test/` → 6 files reformatted (notification-related files were among them; format is now applied).
  - `flutter pub outdated` → See Dependency Status below.
  - `flutter test test/unit/models/notification_model_test.dart test/unit/notifications/notification_view_model_test.dart test/widget/notifications/notifications_modal_test.dart` → **11 tests passed.**
- **Grep gates:**
  - `createNotification(`, `createOrUpdateNotification(`, `.from('notifications').insert` in `lib/` → **No matches** (no client notification inserts).
  - `Supabase.instance` / `.from(` in `lib/features/notifications/view/` → **No matches** (no direct Supabase in views).
  - `service_role` in `lib/` → **No matches.**
- **Docs scanned:** `Sline_everything/DEVELOPER_GUIDE.md`, `Sline_everything/SUPABASE_SETUP.md`, `Sline_everything/CODE_REVIEW.md`, plan in `.TODO/Archive/NotificationExecution/PLAN_NotificationsFix_2026-03-01.md`.
- **Web freshness:** Not run for this scope; dependency status from `flutter pub outdated` only.

---

## Risk Rating

| Area           | Rating | Notes |
|----------------|--------|--------|
| **Overall**    | MEDIUM | Touches auth lifecycle, RLS contract, and ledger; no new client write paths. |
| **Security**   | MEDIUM | RLS + user_id scoping verified; ledger actor + idempotency in DB only. |
| **Performance**| LOW    | Stream limit 50, single subscription, disposal on logout. |
| **Compatibility** | LOW | Flutter/Supabase client unchanged; migrations add enum casts and zero-amount guard. |

---

## Critical Issues (BLOCKERS)

**None.**

- No RLS missing for notifications (client insert policy removed in `20260301_harden_notification_writes.sql`).
- No `service_role` or client notification inserts in app code.
- Ledger idempotency and actor checks present in `process_payment_event_ledger` (20260307).
- Views do not call Supabase directly.

---

## Warnings (Should Fix)

1. **Pre-existing analyzer infos (out of NotificationsFix scope)**  
   - Multiple `curly_braces_in_flow_control_structures` in `lib/features/chat/`, `lib/features/direct_offers/`.  
   - **Suggestion:** Fix in a dedicated lint pass.  
   - **Owner:** Implementer.

2. **Full-codebase `flutter analyze`**  
   - Exit code 1 is from the above infos elsewhere; notification scope is clean.  
   - **Suggestion:** Run `flutter analyze` on full repo and address or suppress per project policy.

---

## Passed Checks

- **Security**
  - NotificationService is read/update-only; all reads/updates filtered by `user_id` from `auth.currentUser?.id`.
  - No client notification inserts: grep for `createNotification(`, `createOrUpdateNotification(`, `.from('notifications').insert` in `lib/` returns no matches.
  - No direct Supabase usage in `lib/features/notifications/view/`.
  - No `service_role` in `lib/`.
  - RLS: `notifications_insert_any` dropped in `20260301_harden_notification_writes.sql`; notifications created only via SECURITY DEFINER triggers/functions.
  - Ledger: `process_payment_event_ledger` uses `v_actor_user_id := auth.uid()`, idempotency key check, and per-event actor validation (e.g. client for escrow_hold/release_with_fee).

- **Performance**
  - Realtime stream limited to 50 rows (`.limit(50)`).
  - Single active stream per session; `_disconnect()` cancels subscription and clears state on sign-out.
  - ViewModel disposes `_authSubscription` and `_subscription` in `dispose()`.
  - No N+1 in notification code; list from single stream/query.

- **Compatibility**
  - Notification model matches `public.notifications` (id, user_id, title, message, type, related_entity_id, related_entity_type, is_read, created_at, metadata).
  - 20260307: `event_type` and `related_entity_type` cast to enum in INSERTs (`payment_event_type_enum`, `related_entity_type_enum`).
  - 20260308: release_with_fee ledger lines use `WHERE line.amount > 0` (ck_ledger_lines_amount_positive); booking/direct_offer UPDATEs use explicit enum casts.

- **MVVM**
  - ViewModel has no BuildContext; navigation is in view layer (NotificationBadgeButton calls `DeepLinkService.handleNotification(context, selected)` after modal returns).
  - Modal returns selected `NotificationItem?`; caller uses `context.mounted` before handling.
  - DeepLinkService handles `task_request` from metadata (`conversation_id` first, else `task_id`).

- **Tests**
  - Unit: notification model parsing, ViewModel markAsRead/markAllAsRead/retry and auth-aware behavior.
  - Widget: modal empty state and stable keys.
  - All 11 notification tests pass.

---

## Verification Commands

```bash
# Notification scope (clean after unused-import fixes)
flutter analyze lib/features/notifications test/unit/models/notification_model_test.dart test/unit/notifications test/widget/notifications

# No client notification writes
rg -n "createNotification\(|createOrUpdateNotification\(|\.from\(['\"]notifications['\"]\)\.insert" lib/

# No direct Supabase in notification views
rg -n "Supabase\.instance|\.from\(" lib/features/notifications/view/

# Notification tests
flutter test test/unit/models/notification_model_test.dart test/unit/notifications/notification_view_model_test.dart test/widget/notifications/notifications_modal_test.dart
```

---

## Freshness / Dependency Status

- **Outdated (relevant):** `supabase_flutter` current 1.10.25, latest 2.12.0 (major). No change required for this scope.
- **Deprecated:** `js` (transitive) discontinued; not introduced by NotificationsFix.
- **Security advisories:** Not checked for this review.
- **Recommendation:** Schedule `supabase_flutter` major upgrade separately with compatibility testing.

---

## Risk Notes

- **Ledger:** 20260307/20260308 alter `process_payment_event_ledger` (release_with_fee: zero-amount lines skipped, enum casts). Deployed environments must run migrations in order; idempotency and actor checks remain in place.
- **Regression:** Badge tap → modal → tap row → pop with selected item → handleNotification from parent context is correct; no navigation from disposed sheet context.

---

## Final Decision

**APPROVED**

- No blockers; security (RLS, user_id, no client inserts, ledger actor + idempotency), performance (stream limit, disposal), and compatibility (enum/DB contract) checks pass.
- Notification scope is analyze-clean and all 11 notification tests pass.
- Optional next steps: fix pre-existing lint infos project-wide; plan `supabase_flutter` major upgrade and run integration smoke.
