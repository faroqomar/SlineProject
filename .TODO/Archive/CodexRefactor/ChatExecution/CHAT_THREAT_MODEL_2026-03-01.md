# Chat Threat Model (2026-03-01)

**Purpose:** Identify threats and define negative checks for Phase 5 verification. Each threat has a corresponding allow/deny verification step.

---

## 1. Unauthorized message read

**Threat:** An authenticated user reads messages from a conversation they are not part of.

**Mitigation:** RLS on `messages` — select only where user is participant (via conversation `user1_id`/`user2_id`).

**Negative check (Phase 5):** As a user who is not a participant, run SELECT on `messages` for that conversation; must fail or return no rows.

---

## 2. Unauthorized message insert / sender spoofing

**Threat:** A user inserts a message with `sender_id` different from `auth.uid()`, or inserts into a conversation they are not in.

**Mitigation:** RLS insert requires `sender_id = auth.uid()` and participant check (conversation membership).

**Negative check (Phase 5):** Attempt insert with spoofed `sender_id` or for a conversation where `auth.uid()` is not participant; must fail.

---

## 3. Over-broad direct DM creation

**Threat:** Users create direct conversations with anyone, bypassing favorites.

**Mitigation:** Single canonical insert rule: DM creation favorites-gated (per CHAT_DECISIONS). Policy/trigger enforce favorites check.

**Negative check (Phase 5):** As client, attempt direct conversation insert for a freelancer not in favorites; must fail.

---

## 4. Attachment path guessing / signed URL abuse

**Threat:** User guesses or reuses storage object paths to access another conversation’s attachments.

**Mitigation:** Participant-scoped storage select (helper e.g. `can_access_chat_attachment`); path contract `convos/<conversation_id>/...`; signed URLs generated server-side or via policy-checked path only.

**Negative check (Phase 5):** As user A, attempt SELECT or signed URL for an object under a conversation where A is not participant; must fail.

---

## 5. Task-linked initiation abuse

**Threat:** Task owner or unrelated user starts a task-linked conversation or bypasses RPC.

**Mitigation:** Task-linked creation only via `start_task_conversation_v1`; RPC enforces non-owner caller and task context.

**Negative check (Phase 5):** As task owner, call RPC or attempt direct insert for task-linked conversation; must fail. As user with no task role, must fail.

---

## 6. Archive misuse

**Threat:** User archives another participant’s view incorrectly, or archive used to destroy data.

**Mitigation:** Archive is per-user, server-timestamped, non-destructive (e.g. `deleted_at_user1`/`deleted_at_user2`). RPC `archive_conversation_v1` stamps only the caller’s column; rejects non-participants.

**Negative check (Phase 5):** Non-participant call to archive RPC must fail. Archive must not delete rows; only hide for caller until newer message.

---

## 7. Duplicate conversation races

**Threat:** Two clients create the same DM simultaneously; one gets unique violation, bad UX or inconsistent state.

**Mitigation:** App/service handles 23505 (unique violation): refetch existing conversation and open it instead of surfacing error. DB keeps unique constraint.

**Negative check (Phase 5):** Optional: simulate or document concurrent create; verify app recovers and opens existing conversation.

---

## 8. Mapping to Phase 5

| Threat | Phase 5 verification |
|--------|----------------------|
| Unauthorized message read | RLS matrix: non-participant SELECT messages → deny |
| Sender spoofing / wrong insert | RLS matrix: spoofed sender_id or non-participant INSERT → deny |
| Over-broad DM creation | RLS matrix: DM without favorites → deny |
| Attachment abuse | Storage matrix: non-participant object access → deny |
| Task-linked abuse | RPC + RLS: owner or non-role start → deny |
| Archive misuse | RPC: non-participant archive → deny |
| Duplicate races | App: 23505 recovery; manual or integration check |
