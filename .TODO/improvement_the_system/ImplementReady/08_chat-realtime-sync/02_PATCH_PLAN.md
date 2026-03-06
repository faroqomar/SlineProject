# Minimal Patch Plan: 08_chat-realtime-sync

Because critical RLS, triggers, and presence infrastructure are genuinely missing from the `supabase/migrations` and code, we must apply the following minimal patches to reach a production-grade state.

## 1. Database Patch (SQL)

**File to create:** `supabase/migrations/20260306000000_chat_presence_and_rls_patch.sql`

```sql
-- 1. Create the missing presence table
CREATE TABLE IF NOT EXISTS public.conversation_presence (
    conversation_id uuid REFERENCES public.conversations(id) ON DELETE CASCADE,
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    is_typing boolean DEFAULT false,
    updated_at timestamptz DEFAULT now(),
    PRIMARY KEY (conversation_id, user_id)
);

-- 2. Enable RLS
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversation_presence ENABLE ROW LEVEL SECURITY;

-- 3. Messages RLS (Participant only)
CREATE POLICY "Participant can select messages"
ON public.messages FOR SELECT
USING (
    conversation_id IN (
        SELECT id FROM public.conversations
        WHERE user1_id = auth.uid() OR user2_id = auth.uid()
    )
);

CREATE POLICY "Participant can insert messages"
ON public.messages FOR INSERT
WITH CHECK (
    auth.uid() = sender_id AND
    conversation_id IN (
        SELECT id FROM public.conversations
        WHERE user1_id = auth.uid() OR user2_id = auth.uid()
    )
);

-- 4. Presence RLS
CREATE POLICY "Presence viewable by participants"
ON public.conversation_presence FOR SELECT
USING (
    conversation_id IN (
        SELECT id FROM public.conversations
        WHERE user1_id = auth.uid() OR user2_id = auth.uid()
    )
);

CREATE POLICY "Presence upsert by self"
ON public.conversation_presence FOR INSERT
WITH CHECK (
    auth.uid() = user_id AND
    conversation_id IN (
        SELECT id FROM public.conversations
        WHERE user1_id = auth.uid() OR user2_id = auth.uid()
    )
);

CREATE POLICY "Presence update by self"
ON public.conversation_presence FOR UPDATE
USING (auth.uid() = user_id);

-- 5. Trigger: Expire Stale Presence (15s TTL)
-- (Run via pg_cron or handled gracefully by client timestamp diff)
-- To keep minimal, we rely on updated_at diffs on the client side:
-- e.g., view models ignore is_typing if now() - updated_at > 15s.

-- 6. Publication
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE conversation_presence;
```

## 2. Code Patch (Dart)

**File to update:** `lib/features/chat/services/message_service.dart`

**Changes needed:**

1. Use `ChatRealtimeMerger.merge` inside `subscribeToMessages` mapped stream rather than re-sorting blindly, or stick to `.stream`'s internal caching but handle errors explicitly.
2. Add `upsertPresence` method.

```dart
Future<void> upsertPresence(String conversationId, String userId, bool isTyping) async {
  await _client.from('conversation_presence').upsert({
    'conversation_id': conversationId,
    'user_id': userId,
    'is_typing': isTyping,
    'updated_at': DateTime.now().toUtc().toIso8601String()
  });
}
```

**File to update:** `lib/features/chat/view/widgets/conversation_list_tile.dart`
**Changes needed:**

1. Remove `// TODO: Online presence...`.
2. Map `Conversation.otherUserTyping` to the `isOnline` indicator.

## 3. Test Plan

1. **RLS Isolation Test**: Attempt to `INSERT INTO messages` with a `conversation_id` the user does not belong to. Ensure a `42501` exception is thrown.
2. **Presence TTL Test**: Ensure the UI ignores `is_typing == true` if the `updated_at` time is older than 15 seconds.
3. **Duplicate Delivery Test**: Send a message, simulate a stream disconnect/reconnect, and verify the UI shows exactly 1 instance of the new message.
