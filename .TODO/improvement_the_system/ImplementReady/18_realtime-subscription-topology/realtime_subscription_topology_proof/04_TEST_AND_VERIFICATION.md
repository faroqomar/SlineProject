# TEST AND VERIFICATION: Realtime Topology

## DB Checklist

1. **Verify Publication:**

   ```sql
   SELECT * FROM pg_publication_tables WHERE pubname='supabase_realtime';
   ```

   **Pass Condition:** Query returns `messages` and `notifications`. It MUST NOT return `conversations`.

2. **Verify RLS for Messages Stream:**
   Check `messages_select` policy enforcing that `auth.uid()` is either `user1_id` or `user2_id` of the related `conversation_id`.

## App / Manual UI Checks

1. **Inbox Resorting without Re-fetching:**
   - Action: While User A is on the `MessagesScreen` inbox, User B sends a message to User A.
   - Verification: User A's inbox automatically moves User B's conversation to the top and bolds the text (unread = true) WITHOUT triggering a `FetchConversations` loading spinner.

2. **No N+1 Log Spam:**
   - Action: In debug mode, observe the Supabase network logs `AppLogger` output.
   - Action: Send 10 rapid messages.
   - Verification: Ensure there are NO `SELECT * FROM conversations WHERE id IN...` queries firing for each message.

3. **Background / Foreground Resync:**
   - Action: User A sends a message. User B gets the push notification but has the app minimized. User B opens the app to the chat screen.
   - Verification: The Chat ViewModel merges the new message instantly, preventing a visual duplicate from flashing on screen.

## Performance Verification (Admin)

- Run: `SELECT query, calls, mean_exec_time FROM pg_stat_statements WHERE query ILIKE '%FROM conversations%id IN%';`
- Check that the `calls` count remains flat while realtime messaging is occurring. If it spikes exactly in sync with message counts, the N+1 `asyncMap` bomb is still active.
