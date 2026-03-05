# Observability Report: ChatFix

**Scope:** ChatFix  
**Date:** 2026-03-02

---

## 1. Telemetry gaps

- **Conversation fetch:** `MessageService.getUserConversations` logs `[CONVOS] fetch start` and `[CONVOS]` error on catch; success path logs in ViewModel. Adequate.
- **Messages fetch:** `MessageService.getMessages` logs `[MESSAGES] fetch start`; failure propagates to ViewModel which logs. Adequate.
- **Archive:** `[ARCHIVE] start` / `success` / `failed` with conversationId in MessageService. Adequate.
- **Realtime:** Message stream logs subscription start and parse error; conversation stream logs parse/error in ViewModel. Adequate.
- **Attachments:** `send_attachment_usecase` and related paths use AppLogger; no raw content. Adequate.

---

## 2. What to log

- High-level events: fetch start/success/failure, send start/success/failure, archive start/success/failure, subscription start/error.
- Correlation: conversation id (no user content or PII).
- Already aligned with `.TODO/CHAT_OBSERVABILITY_2026-03-01.md`.

---

## 3. What NOT to log

- Raw message content or payload body.
- Participant names/identifiers in a way that identifies users.
- Signed URLs or tokens.
- No violations found in Chat code (grep for AppLogger usage confirms high-level messages only).

---

## 4. Correlation strategy

- Use `conversationId` (or `conversation_id`) in log messages for archive, fetch, and send flows. Already present in archive and message fetch logs.

---

## 5. Conclusion

- No BLOCKER. Observability is aligned with CHAT_OBSERVABILITY; no print() in chat feature.
