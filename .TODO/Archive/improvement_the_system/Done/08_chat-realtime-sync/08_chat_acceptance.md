# Chat Realtime Sync — Acceptance & Non-Regression

## Acceptance (must hold after implementation)

- RLS blocks non-participant: User C cannot SELECT/INSERT messages for A–B conversation; cannot upsert presence for A–B.
- Presence in UI within 15s TTL: Typing indicator appears when other user types; disappears within 15s if no update (client-side TTL).
- Receipts: Sender sees single tick → double grey (delivered) → double blue (read) after receiver delivers and opens chat.
- No duplicate messages on reconnect: Message list shows exactly one row per message id after stream reconnect (ChatRealtimeMerger + ViewModel accumulation).
- Conversation list does not full re-fetch on every tick: Client-side merge or reduced re-fetch (no full JOIN on every realtime emission).

## Non-Regression

- Existing chat: send/receive text and attachments still works.
- Conversation list: load and realtime updates still work.
- mark_conversation_delivered and mark_conversation_seen RPCs still work when feature flag is on.
