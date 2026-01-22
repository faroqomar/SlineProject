# Notification System Fixes Plan

## Goal
Implement deep linking for notifications ("New Offer", "New Message") and prevent notification spam by throttling/grouping message notifications.

## User Review Required
> [!NOTE]
> **Deep Linking Logic**:
> - "New Offer" will open `TaskDetailsScreen` first, then immediately push `RequestsListScreen` on top. This ensures proper back navigation.
> - "New Message" will navigate to the `Messages` tab and push the specific `ChatScreen`.
>
> **Spam Prevention**:
> - We will modify `MessageService` to **check for existing unread notifications** from the same conversation before creating a new one. If one exists, we will update it with the new message preview instead of creating a duplicate. This effectively "groups" the notifications in the list.

## Proposed Changes

### 1. Notifications Feature
#### [MODIFY] [notification_view_model.dart](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/notifications/viewmodels/notification_view_model.dart)
- Add `handleNotificationTap(BuildContext context, NotificationItem item)` method.
- Implement logic:
    - `case 'offer'`: Invoke `_navigateToOffer`.
    - `case 'message'`: Invoke `_navigateToChat`.

#### [MODIFY] [notifications_modal.dart](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/notifications/view/notifications_modal.dart)
- Update `NotificationTile` `onTap` to call `vm.handleNotificationTap`.
- Close the modal (`Navigator.pop`) before navigating.

### 2. Task Feature
#### [MODIFY] [task_details_screen.dart](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/task_details_screen.dart)
- Add `final bool showProposalsInitially;` to constructor (default `false`).
- In `initState`, if `showProposalsInitially` is true, schedule a push to `RequestsListScreen`.

### 3. Chat Feature
#### [MODIFY] [message_service.dart](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/chat/services/message_service.dart)
- In `sendMessage`, before calling `createNotification`:
    - Query `notifications` table for `user_id = receiverId`, `related_entity_id = conversationId`, `is_read = false`.
    - If found: **Update** the existing record (`message = newContent`, `created_at = now()`, `metadata['count']++`).
    - If not found: **Insert** new record.

#### [MODIFY] [notification_service.dart](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/notifications/services/notification_service.dart)
- Add `updateNotification(id, fields)` method or similar support for the "Spam" fix.

## Verification Plan

### Manual Verification
1.  **Deep Link (Message)**:
    - Send a message from User A to User B.
    - User B opens Notification Modal.
    - Tap "New Message" notification.
    - **Expect**: Navigates to Chat Screen with User A.
2.  **Deep Link (Offer)**:
    - Submit proposal on User A's task.
    - User A opens Notification Modal.
    - Tap "New Offer" notification.
    - **Expect**: Navigates to Task Details -> (Auto Push) -> Requests List.
3.  **Spam Prevention**:
    - Send 3 messages in a row from User A to User B.
    - User B checks Notification List.
    - **Expect**: Only **ONE** notification entry for that conversation, showing the latest message text.
