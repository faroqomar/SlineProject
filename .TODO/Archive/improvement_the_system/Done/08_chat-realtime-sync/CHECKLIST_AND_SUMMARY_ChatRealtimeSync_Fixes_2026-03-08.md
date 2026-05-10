# Chat Realtime Sync — Fixes Checklist & Summary (2026-03-08)

**Context:** Fixes applied from `.TODO/MASTER_REPORT_2026-03-08_ChatRealtimeSync.md`.  
**Scope:** Docs, contract, PII logging, receipt logging, performance (debounce + receipt calls), migration idempotency.

---

## Part 1: App verification checklist

Use this list to confirm behavior in the running app.

### Chat screen (open a conversation)

- [ ] **Messages load** — Open a conversation; messages appear. No crash.
- [ ] **Realtime updates** — With two devices/clients: send a message from A; B sees it without refresh. No duplicate messages.
- [ ] **Typing indicator** — User B types; User A sees “Typing…” (if feature flag is on). After B stops typing, “Typing…” disappears within ~15 seconds.
- [ ] **Receipt ticks** — As receiver, open the chat: sender’s messages show delivered (double tick) then read (blue) when flag is on. As sender, you see sent → delivered → read.
- [ ] **Feature flag off** — If you set `app_config.chat_presence_receipts_enabled` to `'false'`: no “Typing…” and only single tick (no delivered/read). No errors.

### Conversation list

- [ ] **List loads** — Inbox/conversation list shows your conversations.
- [ ] **Presence in list** — When the other user is typing in that conversation, the list tile can show typing (within 15s). No crash.

### Errors and logs (optional)

- [ ] **Receipt failure** — If you force a receipt error (e.g. wrong RLS or network off), check logs: the error line should include `conversation_id=...` and `operation=delivered` (or `seen`). Tag `ChatVM`.
- [ ] **No PII in logs** — In debug logs you should not see raw message content or the other user’s name/avatar from conversation parsing.

### Performance (optional)

- [ ] **No obvious lag** — While receiving many messages (or many with offers), the chat stays responsive. Offer status refresh is debounced (not on every single message).

---

## Part 2: What was done — short summary

### Why we did it

The Orchestrator pipeline (Architect, Observability, DocsKeeper, CodeGuard) reviewed the Chat Realtime Sync feature and produced a Master Report. We applied all recommended fixes: docs accuracy, PII safety, traceability, performance, and migration safety.

---

### Documentation

| What | Change | Why |
|------|--------|-----|
| **SUPABASE_SETUP.md** | Removed mention of `expire_typing_presence` trigger; said presence expiry is **client-only** (15s in app). | That trigger doesn’t exist; only the app enforces 15s TTL. |
| **SUPABASE_SETUP.md** | Added `conversation_presence` to Realtime §12 publication list. | Table was added to realtime; docs were outdated. |
| **SUPABASE_SETUP.md** | Documented `chat_presence_receipts_enabled` in app_config §5.8. | New feature flag had no doc. |
| **SUPABASE_SETUP.md** | Removed §8.7 “Conversation Presence Triggers” row for `trg_expire_presence`. | Trigger doesn’t exist in migrations. |
| **08_chat_realtime_contract.md** | Changed `user_id` from “FK auth.users” to **“FK profiles(id)”**. | DB and migrations use `profiles(id)`. |
| **Sline_Log.md** | Added version entry for Chat Realtime Sync (plan, execution, contract, migrations). | Traceability and history. |
| **MVP_ROADMAP.md** | Updated “Realtime chat” row to mention presence, receipts, feature flag, ChatRealtimeMerger. | Roadmap matches current behavior. |
| **STRUCTURE.md** | Added one line under “Recent Structure-Sensitive Updates” for Chat Realtime Sync (08). | Structure changes are documented. |

---

### Code — removed

| Where | What was removed | Why |
|------|-------------------|-----|
| **conversation_model.dart** | Debug log of `rawLastMessage` (could contain message body). | PII: must not log message content. |
| **conversation_model.dart** | Debug log of `other_user_name` and `other_user_avatar`. | PII: must not log identifiable user data. |
| **conversation_model.dart** | Unused import of `logger_service.dart`. | No remaining logs in that file. |
| **chat_view_model.dart** | Extra call to `markReceiptsForActive` at end of `subscribeToActiveConversation()`. | One call on subscribe is enough; reduces redundant RPCs. |
| **chat_view_model.dart** | Calling `markReceiptsForActive` on **every** message stream emission. | Now only when there are new messages from the other party (receiver = you). |

---

### Code — added

| Where | What was added | Why |
|------|-----------------|-----|
| **chat_view_model.dart** | Receipt error log now includes `conversation_id` and `operation` (e.g. `delivered+seen`) and tag `ChatVM`. | So support/debug can see which conversation and which operation failed. |
| **chat_view_model.dart** | **Debounce** (500 ms) for `refreshOfferStatusesForCurrentMessages()`: timer instead of calling on every emission. | Fewer DB calls when many messages arrive; avoids lag. |
| **chat_view_model.dart** | **Defensive clear**: at start of `subscribeToActiveConversation()`, if `_lastMessages` is for a different conversation, clear it. | Prevents mixing two conversations if a future entry point doesn’t call `fetchMessages` first. |
| **chat_view_model.dart** | Cancel `_offerRefreshDebounce` in `dispose()` and `unsubscribeFromConversation()`. | No timers left running after leave/teardown. |

---

### Code — modified (behavior)

| Where | What changed | Why |
|------|----------------|-----|
| **chat_view_model.dart** | `markReceiptsForActive` in the message listener is only called when `hasNewFromOther` is true (new messages where you are the receiver). | Cuts unnecessary RPCs; only mark receipts when you actually got new messages. |
| **chat_view_model.dart** | Message listener no longer `await refreshOfferStatusesForCurrentMessages()`; it schedules a 500 ms debounced run instead. | Same offer refresh behavior with less load under heavy realtime traffic. |

---

### Database / migrations

| What | Change | Why |
|------|--------|-----|
| **20260307220000_chat_realtime_presence_publication.sql** | Replaced raw `ALTER PUBLICATION ... ADD TABLE` with a **DO block**: add `conversation_presence` only if it’s not already in the publication. | Idempotent: safe when 19900 already added the table; avoids “already in publication” on deploy. |

---

## Part 3: One-line recap

- **Docs:** Corrected SUPABASE_SETUP (no fake trigger, realtime list, app_config), contract FK, and added Sline_Log / MVP_ROADMAP / STRUCTURE entries.
- **Privacy:** Stopped logging message content and other-user name/avatar in conversation model.
- **Observability:** Receipt failure logs now include conversation_id and operation.
- **Performance:** Debounced offer refresh (500 ms); mark receipts only when there are new messages from the other party.
- **Safety:** Defensive clear of merge state when switching conversation; idempotent presence publication migration.
