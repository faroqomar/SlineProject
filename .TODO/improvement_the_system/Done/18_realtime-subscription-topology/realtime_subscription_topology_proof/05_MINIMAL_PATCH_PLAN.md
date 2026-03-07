# MINIMAL PATCH PLAN: Realtime Topology Blockers

## Context

The current codebase in `message_service.dart` subscribes to a `conversations` stream that is NOT published by DB and maps it with a dangerous N+1 bulk query.
To correct this, and adopt the **NEW** Topology's architecture (Option 2), we will redirect Inbox realtime resorting to rely on the already-published `messages` stream where `receiver_id` matches the user.

## Code Changes Needed (Dart Only)

**File: `lib/features/chat/services/message_service.dart`**

1. **Delete:** `subscribeToConversations` function completely.
2. **Add:** A new function `subscribeToInboxMessages(String userId)`:
   ```dart
   Stream<List<Message>> subscribeToInboxMessages(String userId) {
     return _client
         .from('messages')
         .stream(primaryKey: ['id'])
         .eq('receiver_id', userId)
         .order('created_at')
         .map((rows) => rows.map((json) => Message.fromJson(json)).toList());
   }
   ```

**File: `lib/features/chat/data/chat_repository.dart`**

1. **Delete:** `subscribeToConversations` pass-through.
2. **Add:** `subscribeToInboxMessages(String userId) => _service.subscribeToInboxMessages(userId);`

**File: `lib/features/chat/viewmodels/chat_view_model.dart`**

1. **Modify:** `subscribeToUserConversations()`
   - Change `_repo.subscribeToConversations` to `_repo.subscribeToInboxMessages`.
   - Update the `.listen` payload handler: instead of expecting a list of full `conversations`, it will now receive a list of `Message` objects.
   - For each new message:
     a. Find the matching `Conversation` in `conversations` list by checking `messages.conversation_id == convo.id`.
     b. If found, update its `last_message_content`, `last_message_at`, and `last_message_sender_id` to match the newly arrived payload.
     c. Sort `conversations` array descending by `last_message_at`.
     d. Call `_notify()`.
   - If a message arrives for a conversation ID _not_ in the local `conversations` list (e.g., a brand new inbound chat), gracefully call `fetchConversations()` or fetch that specific conversation via DB.

## SQL Changes Needed

**NONE.** By pivoting the codebase to use `messages` (which is already in `supabase_realtime` per `SUPABASE_SETUP.md` and has correct RLS), no SQL changes are required.

## Verification

- Run Flutter App.
- Log in on 2 devices (or 2 personas).
- Device 1 sends message to Device 2.
- Device 2 (on Inbox Screen) sees the preview text instantly update and jump to the top without full-page reloads.
- No N+1 queries seen in logs.
