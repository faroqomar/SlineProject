# Test Plan: 08_chat-realtime-sync

## Automated Verification

### 1. RLS Chat Isolation Test

- **Goal**: Verify that User C cannot see or insert messages into a conversation between User A and User B.
- **Command**:
  ```bash
  # Note: Requires manual SQL execution in Supabase dashboard or pgTAP
  -- Sign in as User C
  -- Try to SELECT from messages WHERE conversation_id = (A-B Conversation)
  -- Expected: 0 rows returned (blocked by RLS)
  ```

### 2. Presence TTL Test

- **Goal**: Verify that `conversation_presence` records expire after 15 seconds.
- **Command**:
  ```sql
  INSERT INTO conversation_presence (conversation_id, user_id, is_typing) VALUES ('...', '...', true);
  -- Wait 16 seconds
  SELECT count(*) FROM conversation_presence;
  -- Expected: 0
  ```

### 3. Stream Merging Unit Test

- **Goal**: Ensure `ChatRealtimeMerger` correctly dedupes and sorts messages.
- **Test File**: `test/features/chat/services/chat_realtime_merger_test.dart`
- **Action**: Create a test that passes a list with an older message and a new row with the same ID but updated content.

## Manual Verification (Production Readiness)

### 1. Connection Drop Recovery

- **Steps**:
  1. Open Chat Screen.
  2. Turn on Airplane Mode.
  3. Send a message (Expected: Shows "Sending" or error state).
  4. Turn off Airplane Mode.
  5. **Expected**: App automatically reconnects and sends the pending message or marks it as failed; stream resumes without duplicates.

### 2. Multi-Device Type Receipt

- **Steps**:
  1. User A sends message to User B.
  2. User B opens app but doesn't open the specific chat (Wait for `markDelivered` RPC).
  3. Check User A's screen (Expected: Double-grey ticks).
  4. User B opens chat (Wait for `markSeen` RPC).
  5. Check User A's screen (Expected: Double-blue ticks).

### 3. Presence Visual Check

- **Steps**:
  1. User A starts typing.
  2. **Expected**: User B sees "Typing..." indicator in the chat header or conversation list.
  3. User A stops typing or leaves app.
  4. **Expected**: Indicator disappears within 15 seconds.
