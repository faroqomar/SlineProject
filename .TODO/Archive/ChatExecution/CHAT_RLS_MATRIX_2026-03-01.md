# Chat RLS & Storage Matrix (2026-03-01)

**Purpose:** Define expected allow/deny behavior before writing any SQL. Each actor/object/action has an expected result. Used for Phase 2 migration design and Phase 5 verification.

---

## 1. Messages

| Actor | Action | Expected | Notes |
|-------|--------|----------|--------|
| Participant (user1 or user2) | SELECT | Allow | Only for conversations where auth.uid() in (user1_id, user2_id) |
| Non-participant | SELECT | Deny | No rows for other conversations |
| Participant as sender | INSERT | Allow | sender_id = auth.uid(); conversation participant |
| Non-participant | INSERT | Deny | |
| Spoofed sender_id | INSERT | Deny | sender_id must equal auth.uid() |
| Receiver | UPDATE (receipts) | Allow | Only receipt columns where intended |
| Non-receiver | UPDATE | Deny | |
| Sender | DELETE | Allow (if supported) | Only own messages |
| Non-sender | DELETE | Deny | |

---

## 2. Conversations

| Actor | Action | Expected | Notes |
|-------|--------|----------|--------|
| Participant | SELECT | Allow | auth.uid() in (user1_id, user2_id) |
| Non-participant | SELECT | Deny | |
| Client, other in favorites | INSERT (direct DM) | Allow | Favorites-gated; one canonical policy |
| Client, other not in favorites | INSERT (direct DM) | Deny | |
| Any (direct insert task-linked) | INSERT (task-linked) | Deny | Task-linked only via RPC |
| Participant | UPDATE (e.g. archive columns via RPC) | Allow | Only via archive_conversation_v1 |
| Non-participant | UPDATE | Deny | |
| Participant | DELETE | Per product | Usually not exposed; if supported, participant only |

---

## 3. Storage (chat-attachments bucket)

| Actor | Action | Expected | Notes |
|-------|--------|----------|--------|
| Participant (conversation for object path) | SELECT (list/read) | Allow | Path convos/<conversation_id>/... ; caller is participant of that conversation |
| Non-participant | SELECT | Deny | |
| Participant (uploader) | INSERT | Allow | Valid path format; uploader identity in path or metadata as needed |
| Non-participant | INSERT | Deny | |
| (This pass) | DELETE / UPDATE | N/A | Append-only; no policies for delete/update in this release |

---

## 4. Notifications

| Actor | Action | Expected | Notes |
|-------|--------|----------|--------|
| Owner (receiver) | SELECT / UPDATE | Allow | Owner = recipient |
| Client (app) | INSERT (receiver notification) | Deny | Server trigger only creates receiver notifications |
| Server trigger | INSERT | Allow | messages_after_insert_notify_receiver |

---

## 5. RPCs

| RPC | Caller | Expected |
|-----|--------|----------|
| start_task_conversation_v1(p_task_id) | Non-owner (e.g. freelancer) | Allow; returns conversation |
| start_task_conversation_v1(p_task_id) | Task owner | Deny |
| archive_conversation_v1(p_conversation_id) | Participant | Allow; stamps caller’s archive column |
| archive_conversation_v1(p_conversation_id) | Non-participant | Deny |

---

## 6. Use for migration

- **Phase 2:** Add/replace policies to satisfy this matrix; remove only policies that conflict after positive/negative checks.
- **Phase 5:** Re-run allow/deny tests against this matrix in staging and after production rollout.
