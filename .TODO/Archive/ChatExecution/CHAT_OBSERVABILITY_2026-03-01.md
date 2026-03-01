# Chat Observability (2026-03-01)

**Purpose:** Minimum useful event/error list and early signals. No raw message content or PII in logs. Use AppLogger only (no print).

---

## 1. Log points (implemented / to verify)

| Flow | Event | Where | Level |
|------|--------|--------|--------|
| Conversations fetch | start / success count / failure | MessageService.getUserConversations, ChatViewModel.fetchConversations | d / i / e |
| Messages fetch | start / success / failure | MessageService.getMessages, ChatViewModel.fetchMessages | d / i / e |
| Send message | start / success / failure | MessageService.sendMessage, ChatViewModel.sendMessage | d / i / e |
| Archive conversation | start / success / failure | MessageService.deleteConversation (archive_conversation_v1) | i / i / e |
| Realtime messages | subscription start / parse error / stream error | MessageService.subscribeToMessages, ChatViewModel | d / e / e |
| Realtime conversations | parse error / stream error | ChatViewModel.subscribeToUserConversations | e / e |
| Conversation create | DM existing / DM created / task RPC success / task RPC failure | MessageService.createOrGetConversation | i / i / i / e |
| Attachments | upload start/success/failure, message-insert failure after upload | send_attachment_usecase, attachment_service | w / i / e / e |

---

## 2. What NOT to log

- Raw message content (body, payload text).
- Participant names/ids in a way that identifies users in logs (conversation id and high-level “fetch failed” is OK).
- Signed URLs or tokens.

---

## 3. Correlation

- Use conversation id and conversationId in error messages where useful (e.g. “conversation fetch failed conversationId=…”).
- Tag: `tag: 'Chat'` or similar in AppLogger where supported.

---

## 4. Early signals (for rollback / ops)

- `[ARCHIVE] failed` — archive RPC failing (e.g. permission or missing function).
- `Realtime message parse error` — stream payload shape change.
- `Error fetching conversations` / `Error fetching messages` — RLS or network; may indicate policy too strict after change.
- `Failed to send message` — contract or RLS (e.g. message type or payload validation).

---

## 5. Verification

- After Phase 3: grep Chat feature for `print(` → none.
- Confirm AppLogger used in message_service, chat_view_model, send_attachment_usecase, chat_screen, messages_screen for critical paths above.
