# Gaps & Fixes: Realtime Subscription Topology

**Skills Applied**:

- Threat Modeling (Security)
- RLS & Privilege Boundaries
- Idempotency & Concurrency

## 1. Discovered Gaps

### GAP 1: Silent Failure on Conversations Stream

- **Evidence:** `message_service.dart:340` calls `.stream(primaryKey: ['id']).order('created_at')` on the `conversations` table.
- **Evidence:** `SUPABASE_SETUP.md` (Section 1) states `Realtime Enabled on: messages, notifications`. The `conversations` table is NOT in the `supabase_realtime` publication.
- **Impact:** The stream yields no events. New chat updates (e.g., sorting the conversation list to the top when a new message arrives) do not happen automatically unless the user is specifically looking at the Chat Screen.

### GAP 2: N+1 CPU Bomb on Stream Yield

- **Evidence:** `message_service.dart:352` maps the stream payload: `asyncMap( (rows) async { ... await _client.from('conversations').select(...).in_('id', convoIds) ... })`.
- **Impact:** `stream()` yields the ENTIRE dataset matching the query on every diff. So if a user has 10 conversations, every single update in _any_ conversation triggers a bulk `SELECT * FROM conversations ...` query for all 10 conversations. At 50 chats getting rapid messages, this causes exponential query generation per user.

### GAP 3: Missing Stream Owner Filter

- **Evidence:** `message_service.dart:340` uses no `.eq()` or `.or()` filter on `conversations` stream.
- **Impact:** Supabase evaluates RLS for every single `conversations` change across the entire app for EVERY connected client, causing heavy DB CPU starvation at scale.

## 2. Recommended Architecture Fixes

### FIX 1: Enable Realtime for `conversations`

- Must add `conversations` to the `supabase_realtime` publication so the server actually pushes the events.

```sql
alter publication supabase_realtime add table conversations;
```

### FIX 2: Migrate to `on('postgres_changes')` with targeted updates

- Instead of using `.stream()` which maintains a full local state array and triggers bulk `.asyncMap()` queries, the app should use the lower-level Supabase realtime channel to listen to specific events and only fetch the affected row.
- **For `messages`**: The current `.stream().eq('conversation_id')` is fine because the dataset is usually bounded per chat and fetching relations is not done inside `asyncMap()`.
- **For `conversations`**:
  ```dart
  _client.channel('public:conversations')
    .on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(event: '*', schema: 'public', table: 'conversations'),
      (payload, [ref]) {
         // evaluate if payload affects the user
         // if yes, trigger a focused refetch for exactly ONE conversation ID
         // or just merge payload into ViewModel state.
      }
    ).subscribe();
  ```

### FIX 3: Push-driven Conversation Updates

- To avoid listening to the whole `conversations` table, a better architectural pattern is to rely on `messages` inserts to drive conversation list updates (since `messages` table already has realtime enabled and it represents 99% of "conversation list" state changes via the `last_message` relation).
- If the `status` of a conversation changes, the related `message_type=system` insert will notify the client.
