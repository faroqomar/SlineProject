# CodeGuard Review: ChatFix

**Scope:** ChatFix  
**Date:** 2026-03-02

---

## 1. Performance

- **Realtime:** `subscribeToMessages` now emits full `List<Message>` per snapshot instead of single row; ViewModel replaces list. No N+1; acceptable.
- **Conversation list:** Fetch and optional realtime refetch with full select; no change from pre-fix. Acceptable.
- No performance BLOCKER.

---

## 2. Security

- **Archive:** Server-side RPC with `auth.uid()` and participant check; no client timestamp writes. Good.
- **Storage helper:** `can_access_chat_attachment` is SECURITY DEFINER, validates path format and conversation membership. Safe.
- **RLS:** Migration is additive (RPC + helper); no removal of policies in this migration. Policy tightening deferred per plan. No BLOCKER.
- **Logging:** No raw message content or PII in AppLogger calls. Good.

---

## 3. Compatibility

- **Message types:** Snake_case write and legacy camelCase read; DB enum parity with `system` added. Backward compatible.
- **Offer payload:** `days` on write; read supports `delivery`. Backward compatible.
- **Archive:** App calls RPC; migration must be applied before deploy. Documented in rollout matrix.
- No compatibility BLOCKER.

---

## 4. Verification commands

- `flutter analyze lib/features/chat` — expected clean.
- `flutter test test/unit/models/message_model_test.dart test/widget/chat/` — expected pass.
- After migration apply: verify `archive_conversation_v1` and `can_access_chat_attachment` exist in DB.

---

## 5. Decision

**APPROVED.** No BLOCKER. ChatFix implementation is acceptable for merge; apply migration in staging first per CHAT_ROLLOUT_MATRIX.
