# SCALE RISKS: Realtime Topology

## 1. N+1 Ingestion Bomb (Critical Risk)

**The Vulnerability:**
When `subscribeToConversations` receives an event, it maps the payload using `.asyncMap()`.

```dart
final convoIds = rows.map((r) => r['id'] as String).toList();
await _client.from('conversations').select(...).in_('id', convoIds);
```

**Why this destroys scale:**
Supabase `.stream()` emits the _entire_ accumulated local array every time a single row changes.
If a user has 50 active conversations in their list, and they receive ONE message in ONE conversation:

1. The DB pushes the conversation update.
2. The stream yields 50 rows.
3. The Dart code executes `SELECT ... IN ('id1', 'id2', ... 'id50')`.
4. If they receive 10 messages in a row, the app executes 10 queries of 50 IDs each.
   This exponential multiplication of queries per event will exhaust the PostgreSQL connection pool almost immediately for any highly active user.

**The Fix:**
Never run `select()` inside a realtime stream `asyncMap()` over the entire array.
Realtime streams must join data locally (O(1)) by either:
a) Ensuring the stream payload includes the necessary denormalized data.
b) Subscribing to individual `postgres_changes` events, finding the delta, and only fetching that _single_ updated row.

## 2. Global DB CPU Starvation (High Risk)

**The Vulnerability:**
Subscribing to `conversations` broadly without an `.eq()` filter (e.g., just `.stream()`).
**Why this destroys scale:**
If `conversations` were published to `supabase_realtime`, the Elixir WS engine would receive every conversation change from the Postgres WAL across the entire platform. For every connected client observing the `conversations` channel, the engine asks Postgres to execute the `conversations_select` RLS policy.
1000 connected clients * 100 platform-wide conversation updates = 100,000 RLS evaluations per second.
**The Fix:**
Only subscribe to channels that are drastically filtered at the Postgres level *before\* RLS evaluation.
The `messages` stream with `.eq('receiver_id', uid)` drops events before RLS checking.
Option 2 in the verdict mandates avoiding `conversations` publication entirely.
