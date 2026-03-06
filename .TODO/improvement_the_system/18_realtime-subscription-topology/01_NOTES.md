# Audit Notes: Realtime Subscription Topology

## 1. Skills Selected

1. **Evidence-First Reading**: To verify if the streams mentioned in the Code/DB actually match the configuration.
2. **Threat Modeling (Security)**: To assess the impact of subscribing to unfiltered streams or missing RLS.
3. **Idempotency & Concurrency**: To handle the side effects of realtime streams firing rapidly.
4. **Observability (Logs/Alerts)**: To ensure we can trace realtime payload errors.
5. **RLS & Privilege Boundaries**: To ensure subscriptions do not bypass access controls.

## 2. Findings

1. **The `conversations` stream is a complete hallucination / silent failure.**
   - Code `message_service.dart:340` calls `.stream(primaryKey: ['id']).order('created_at')` on `conversations`.
   - DB `SUPABASE_SETUP.md` explicitly lists `Realtime Enabled on: messages, notifications`. `conversations` is NOT enabled.
   - RESULT: The stream connects but receives 0 events. The conversation list does not update in real-time.
2. **The `conversations` stream is an N+1 CPU bomb if it ever worked.**
   - Code `message_service.dart:352` maps the stream payload: `asyncMap... await _client.from('conversations').select(...)`.
   - Every realtime event triggers a bulk `select()` query for all conversations the user is part of.
3. **Missing client-side filter on `conversations`.**
   - The stream has no `.or('user1_id.eq.$userId,user2_id.eq.$userId')`.
   - If `conversations` was added to publication, the DB would evaluate RLS for every single conversation update platform-wide against every connected user.
4. **`messages` and `notifications` streams are correct.**
   - `messages` filters by `conversation_id`.
   - `notifications` filters by `user_id`.
   - Both are published in `supabase_realtime`.

## 3. RLS Context

- `notifications_select_own` enforced on realtime push (safe).
- `messages_select` enforced on realtime push (safe).
- If `conversations` stream is fixed by adding to publication, it needs the `conversations_select` RLS. But client-side `.or()` filter is MANDATORY.

## 4. Remediation Plan

- Add `conversations` to `supabase_realtime` publication.
- Fix `message_service.dart` to use `.stream(primaryKey: ['id']).eq('user1_id', userId)` ... wait, `.stream()` doesn't support `.or()`.
- Actually, Supabase `.stream()` does not support `.or()`. To filter `conversations` efficiently without `.or()`, we must use `.on('postgres_changes', ...)` which supports complex filters, or we accept that RLS does all the work. If we accept RLS does the work, we MUST add it to publication. But wait, if `.stream()` is used, and `.or()` is unsupported, maybe listening to `messages` and triggering a refetch of `conversations` is better?
- A better approach: The conversation list should listen to `messages` where `receiver_id=userId` or `sender_id=userId`? Unfortunately, Supabase realtime channels for `messages` without a `conversation_id` might be too broad.
- Easiest fix: Just allow `conversations` in `supabase_realtime`. It relies on RLS filtering.
- Wait, the N+1 in `.asyncMap` MUST be replaced. It should only fetch the _changed_ conversation(s), or we don't use `.stream()` and instead use `channel('client-chats').on('postgres_changes', {event:'*', schema:'public', table:'conversations'})`.
