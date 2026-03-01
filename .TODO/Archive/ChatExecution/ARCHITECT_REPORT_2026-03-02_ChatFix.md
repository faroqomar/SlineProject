# Architect Report: ChatFix

**Scope:** ChatFix (PLAN_ChatFix_v2_2026-03-01 execution)  
**Date:** 2026-03-02  
**Plan:** .TODO/PLAN_ChatFix_v2_2026-03-01.md

---

## 1. Architecture / logic findings

### MVVM boundary check
- **Views:** No direct Supabase usage in `lib/features/chat/view/`. Confirmed; views use `ChatViewModel` / `context.read<ChatViewModel>()` only.
- **ViewModel:** `ChatViewModel` uses `ChatRepository` only; no Supabase client access.
- **Repository/Service:** `ChatRepository` delegates to `MessageService`; `MessageService` holds `SupabaseClient` and performs all DB/RPC/stream calls. Boundary respected.

### Data flow
- Conversation list: `MessagesScreen` → `ChatViewModel.fetchConversations()` / `subscribeToUserConversations()` → `ChatRepository` → `MessageService.getUserConversations()` / `subscribeToConversations()`.
- Thread: `ChatScreen` → `ChatViewModel` (messages, send, receipts) → `ChatRepository` → `MessageService` (getMessages, sendMessage, subscribeToMessages, markDelivered, markSeen).
- Archive: `MessagesScreen` dismiss → `ChatViewModel.deleteConversation()` → `ChatRepository.deleteConversation()` → `MessageService.deleteConversation()` → RPC `archive_conversation_v1`. Correct server-authoritative path.

### Contract checks
- **Message types:** Wire values snake_case in `message_model.dart` (`messageTypeToString`); read path accepts legacy camelCase and snake_case. `MessageType.system` added for DB enum parity.
- **Offer payload:** `ChatOfferPayload` uses `days` on write; `daysFromPayload()` reads `days` or legacy `delivery`. Aligned with CHAT_CONTRACT.
- **Archive:** Client no longer writes `deleted_at_user1`/`deleted_at_user2`; calls `archive_conversation_v1` RPC. Aligned.

### Path validation
- Referenced files exist: `message_model.dart`, `chat_offer_payload.dart`, `chat_realtime_merger.dart`, `message_service.dart`, `chat_repository.dart`, `chat_view_model.dart`, `chat_screen.dart`, `messages_screen.dart`, migration `20260302_chat_archive_rpc_and_storage_helper.sql`.

---

## 2. Proposed refactors (optional)

- **ViewModel split:** Plan mentioned `chat_conversations_view_model` and `chat_thread_view_model`; current state keeps a single `ChatViewModel`. Acceptable for this release; split can be a follow-up to reduce rebuild scope.
- **ChatRealtimeMerger:** Implemented but not yet used in the message stream (service maps full snapshot to list directly). Merger available for future incremental-merge use; no change required.

---

## 3. Conclusion

- No BLOCKER. MVVM boundaries and contract alignment are satisfied. Optional refactors are documented for later.
