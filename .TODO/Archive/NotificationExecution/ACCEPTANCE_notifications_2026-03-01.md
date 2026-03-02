# Acceptance Criteria: Notifications Server-Authority (2026-03-01)

## Mandatory (from plan §5)

1. **No client notification writes**  
   App does not write notifications from chat, tasks, task_requests, or booking business code. Verification: grep for `createNotification(`, `createOrUpdateNotification(` in producer features returns no business callsites.

2. **NotificationService read/update-only**  
   `NotificationService` exposes only read and update operations; user-scoped (current user filter where applicable). No insert/upsert for business logic.

3. **ViewModel context-free and auth-aware**  
   `NotificationViewModel` does not take `BuildContext` for navigation; does not use `Provider`/`context.read` inside ViewModel. Stream connection is auth-aware (connect when session ready, clear/disconnect on logout).

4. **task_request routing**  
   Notifications with `related_entity_type = 'task_request'` route correctly using metadata: `conversation_id` first, else `task_id`. No "Cannot open this item type" for supported server-emitted types.

5. **Modal tap flow safe**  
   Tapping a notification does not use a disposed modal context. Navigation runs from a stable context (e.g. parent). Verification: widget test or manual QA; no "context used after dispose" in logs.

6. **Fresh bootstrap**  
   Applying repo migrations from scratch (including patched 20260226) succeeds through the March 1 notification baseline without notification-contract errors.

7. **RLS**  
   Two-user checks: user A can select/update own notifications; user A cannot select/update user B's; user A cannot insert. Documented in `.TODO/RLS_notifications_matrix_2026-03-01.md` and executed in Phase 4/5.

8. **Tests**  
   Notification unit and widget tests exist and pass. Integration uses deterministic fixture or skip-with-message when prerequisites missing; stable selectors used.

9. **Docs**  
   `Sline_everything/SUPABASE_SETUP.md` (and related docs) match live DB and code: notification write contract, realtime, policies, triggers.

10. **AppLogger**  
    All notification-related flows use `AppLogger`; no `print()`. No PII (e.g. message body) in logs; type/entity type/IDs only where needed.

## Touched modules (locked)

- `lib/features/notifications/**`
- `lib/core/services/deep_link_service.dart`
- `lib/main.dart`
- `lib/features/home/view/home_screen.dart`
- Producer services (chat, tasks, task_requests, booking) — read-only; no new notification writes.
- `supabase/migrations/` (patch 20260226 + any policy capture)
- `test/features/notifications/**`, `integration_test/notification_deeplink_flow_test.dart`, `integration_test/support/`
- `Sline_everything/SUPABASE_SETUP.md`, `DEVELOPER_GUIDE.md`, `MVP_ROADMAP.md`
