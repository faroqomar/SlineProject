# Evidence Log: 08_chat-realtime-sync

## A) RLS for messages: participant-only SELECT/INSERT

- **Claim Status**: MISSING
- **Evidence**: `grep_search` across `supabase/migrations` for `CREATE POLICY` on `public.messages` returned exactly `0` results. The only mention is in `Sline_everything/SUPABASE_SETUP.md:27` claiming RLS is "✅", but no SQL implementation backs this up in the source of truth.

## B) RLS for conversation_presence: auth.uid()=user_id AND participant

- **Claim Status**: MISSING
- **Evidence**: `grep_search` for `conversation_presence` across `supabase/migrations` returned `0` results. The table does not exist in the DB schema migrations.
- **Evidence 2**: `lib/features/chat/view/widgets/conversation_list_tile.dart:40` explicitly states: `// TODO: Online presence is not yet in Conversation model, assume false or implement presence service`.

## C) Triggers claimed by diagrams

- **Claim Status**: MISSING
- **Evidence**: The old diagram claims "Process Triggers", and `SUPABASE_SETUP.md:500` explicitly claims `expire_typing_presence` automatically expires records. However, `grep_search` across `supabase/migrations` for `expire_typing_presence` and `validate_sender_participation` yielded `0` results.

## D) Realtime publication coverage

- **Claim Status**: PARTIAL / UNVERIFIED
- **Evidence**: `SUPABASE_SETUP.md:78` claims Realtime is "Enabled on: messages, notifications". However, no `alter publication supabase_realtime add table messages;` statement exists in `supabase/migrations`. The `conversation_presence` table isn't listed or enabled either.

## E) subscribeToConversations Stream Load

- **Claim Status**: CONFIRMED (Performance Risk)
- **Evidence**: `lib/features/chat/services/message_service.dart:360-378`.
  Every time the `conversations` stream fires a heartbeat/update, `asyncMap` executes a heavy JOIN query (`select('*, profiles!..., tasks(...)')`) for all `convoIds`. While it batches via `.in_('id', convoIds)` (avoiding a strict N+1 loop per ID), it creates immense DB load by re-querying massive relationship graphs on every minor event.

## F) Delivery/Seen propagation

- **Claim Status**: PARTIAL
- **Evidence**: RPCs exist in `message_service.dart:284` (`markDelivered`) and `294` (`markSeen`). The stream listener at line 303 (`.stream(primaryKey: ['id'])`) relies on Supabase Flutter's internal list-merging. It works, but `ChatRealtimeMerger` (found at `chat_realtime_merger.dart`) is NOT used in `subscribeToMessages` line 303, despite being built specifically for this. The diagram shows the network path, but the Dart unification is fragmented.
