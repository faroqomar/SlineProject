# UI SURFACES AND WIRING: Realtime Topology

## 1. Inbox / Conversations List UI

**File Path:** `lib/features/chat/view/messages_screen.dart`
**ViewModel:** `ChatViewModel` -> `fetchConversations()` and `subscribeToUserConversations()`

**Wiring:**

1. `_chatCtrl.subscribeToUserConversations()` is called in `initState`.
2. This invokes the idle `conversations` stream.
3. Because the stream yields nothing (not in DB publication), the Inbox **never** updates until the user pulls to refresh.

**What A New Message _Should_ Do:**
When an inbound message arrives, the Inbox UI needs to:

- Bump the conversation to the top (update `last_message_at`).
- Increment the unread count (`lastMessageSeenAt == null` logic).
- Update the preview text `last_message_content`.

## 2. Chat Screen UI (Active DM)

**File Path:** `lib/features/chat/view/chat_screen.dart`
**ViewModel:** `ChatViewModel` -> `subscribeToActiveConversation()`

**Wiring:**

1. Calls `_chatCtrl.subscribeToActiveConversation()` when the screen is pushed.
2. Invokes the working `messages` stream (`eq('conversation_id', conversation.id)`).
3. **Deduplication Strategy:** The SDK `.stream(primaryKey: ['id'])` handles deduplication natively by maintaining local state and merging on ID.
4. UI accurately shows messages immediately as they are inserted.
5. **Offline/Reconnect Behavior:** Standard WebSocket reconnects. On reconnect, the stream rebuilds local state by polling.

## 3. Notifications UI

**File Path:** `lib/features/notifications/view/notifications_screen.dart` (Assuming standard structure based on NotificationService).
**ViewModel:** `NotificationViewModel`

**Wiring:**

1. The `streamNotifications` function is robustly filtered to `user_id=uid`.
2. Push notifications update the UI instantly without N+1 queries.

## 4. Admin Observability UI (MISSING)

There is currently no way for an admin to verify if websockets are collapsing database connections or if they are functioning.

**Required Admin UI / Tooling (If built):**

- A dashboard view indicating: Active WebSocket Connections (via Supabase pooling metrics).
- `pg_stat_statements` views on the admin portal highlighting queries ending in `FROM conversations WHERE id IN...` (to catch N+1 regressions).
- Application logging (`AppLogger.w`) when subscriptions drop.
