# EVIDENCE MAP: Realtime Subscription Topology

## Ground Truth 1: Code Subscriptions

| File Path                                                          | Function/Line              | Subscription Client                                                               | Map Filter / Details                                                 |
| ------------------------------------------------------------------ | -------------------------- | --------------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| `lib/features/chat/services/message_service.dart:340`              | `subscribeToConversations` | `.stream(primaryKey: ['id']).order('created_at')` on `conversations`              | NO client filter. Unfiltered WS channel targeting ALL conversations. |
| `lib/features/chat/services/message_service.dart:451`              | `subscribeToMessages`      | `.stream(primaryKey: ['id']).eq('conversation_id', conversationId)` on `messages` | Filtered exactly to the active chat screen.                          |
| `lib/features/notifications/services/notification_service.dart:67` | `streamNotifications`      | `.stream(primaryKey: ['id']).eq('user_id', userId).limit(50)` on `notifications`  | Filtered exactly to the connected user.                              |

## Ground Truth 2: DB Publication Map (Truth)

| Object                          | Evidence / Content                                                                                                                                       |
| ------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `supabase_realtime` Publication | `SUPABASE_SETUP.md` explicitly lists: "Realtime Enabled on: messages, notifications". The `conversations` table is entirely absent from the publication. |
| Result from code mismatch       | The `.stream` for `conversations` connects but yields 0 events because the database never pushes updates for that table.                                 |

## Ground Truth 3: RLS Policy Security Check

| Table           | RLS Policy                 | Condition                                                                                                                              | Impact on Realtime                                                                                                                                                                         |
| --------------- | -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `messages`      | `messages_select`          | `EXISTS(SELECT 1 FROM conversations c WHERE c.id = messages.conversation_id AND (c.user1_id = auth.uid() OR c.user2_id = auth.uid()))` | Safe. Even if a user tried to spoof `.eq('conversation_id')`, realtime pushes evaluate auth context against RLS.                                                                           |
| `notifications` | `notifications_select_own` | `user_id = auth.uid()`                                                                                                                 | Safe. Strict ownership map.                                                                                                                                                                |
| `conversations` | `conversations_select`     | `user1_id = auth.uid() OR user2_id = auth.uid()`                                                                                       | Potentially harmful if published _without_ client filters, because Supabase would pump every conversation platform-wide into the RLS engine to check `auth.uid()`, suffocating the DB CPU. |
