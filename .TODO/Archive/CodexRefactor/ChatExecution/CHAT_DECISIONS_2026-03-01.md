# Chat Contract Decisions (2026-03-01)

**Purpose:** Lock the Chat contract before any SQL or Flutter change. All later checklist items must be compatible with these decisions.

---

## 1. Direct DM creation rule

**Decision:** Favorites-gated.

**Meaning:** A direct (non–task-linked) conversation may be created only if the initiator (client) has the other user (freelancer) in favorites. No participant-only insert without favorites.

**App-facing consequences:**
- UI must not offer "Start conversation" for a freelancer who is not in the client's favorites (or must add to favorites first).
- Repository/service must not attempt direct DM insert when favorites check would fail; backend RLS/policy enforces the same rule.
- Docs and error messages must state that DMs require the freelancer to be in favorites.

---

## 2. Task-linked conversation initiator rule

**Decision:** Non-owner only.

**Meaning:** Only the non-owner (e.g. freelancer/bidder) may start a task-linked conversation. The task owner cannot start it; they use `start_task_conversation_v1` only as the non-owner path. Live RPC already enforces this.

**App-facing consequences:**
- App method names and comments must reflect "non-owner starts task chat" (e.g. rename/deprecate `startConversationByClient` where it implied owner starts).
- Booking/deep-link entry must use the path that calls `start_task_conversation_v1` when the current user is the non-owner.
- Docs must state that task-linked chat is started by the non-owner via RPC.

---

## 3. Offer scope

**Decision:** Task-linked only.

**Meaning:** Offer messages (create/accept/reject) are valid only in task-linked conversations that map to task state. Offer actions are not supported in pure DMs.

**App-facing consequences:**
- UI must hide or disable offer actions (create offer, accept/reject) when the conversation is not task-linked or when task context is missing.
- Backend triggers already tie offer acceptance to task assignment; no change to that. No offer semantics in non–task-linked chats.

---

## 4. Conversation-list freshness strategy

**Decision:** Hybrid — fetch-first, realtime later.

**Meaning:** Ship with fetch-refresh as the source of truth (screen open, post-send, post-archive, pull-to-refresh). Do not assume `conversations` is in the realtime publication for the first release. Realtime for the conversation list can be added in a later, gated pass.

**App-facing consequences:**
- MessageService must not assume `subscribeToConversations` receives events; implement explicit refresh triggers.
- UI may show a manual-refresh hint when list is not updated in real time.
- No removal of fetch path; realtime is additive when publication is enabled and verified.

---

## 5. Attachment mutation policy

**Decision:** Append-only; no delete/update UI in this pass.

**Meaning:** Participants do not delete or update existing chat attachments. Storage policy scope stays insert + participant-scoped select only. No uploader-delete or shared-manage in this release.

**App-facing consequences:**
- No UI for "delete attachment" or "edit attachment" in chat.
- Storage policies: no delete/update policies for `chat-attachments` in this pass.
- Future expansion would require ownership semantics and cleanup jobs.

---

## 6. Sign-off and compatibility

- Every later plan step (Phase 1–5) must reference these decisions without contradiction.
- If product overrides any decision, this document must be updated and the plan rechecked for consistency.
