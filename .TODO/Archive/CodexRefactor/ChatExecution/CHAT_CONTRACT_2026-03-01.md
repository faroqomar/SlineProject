# Chat Contract (2026-03-01)

**Purpose:** Canonical definitions for wire formats, semantics, and app/backend boundaries. No migration is authored until this and CHAT_RLS_MATRIX exist.

---

## 1. Message type wire values

**Canonical (DB enum):** snake_case only.

- `text`
- `system`
- `offer`
- `offer_update`
- `offer_accepted`
- `offer_rejected`
- `delivery_submitted`
- `end_early_request`
- `dispute_report`

**App:** Flutter must write only these values. No camelCase on insert. Read path may accept legacy camelCase temporarily for backward compatibility during migration; write path is snake_case only.

**Deprecation:** Remove any app code that sends `offerAccepted` / `offerRejected` etc.; replace with `offer_accepted` / `offer_rejected`.

---

## 2. Offer payload shape

**Canonical write:** `{ "price": number, "days": number, ... }`. The backend trigger validates `days` (integer). Do not send `delivery` for new offers.

**Legacy read:** UI and parsers may read `delivery` from existing payloads for display only (temporary compatibility). New writes use `days` only.

**Optional display-only fields:** e.g. `title`, `description`, `status` — allowed for UI; backend validation focuses on `price` and `days` for offer validation.

---

## 3. Conversation creation semantics

- **Direct DM:** Favorites-gated. One canonical insert path; policy/trigger enforces that initiator has the other user in favorites. See CHAT_DECISIONS.
- **Task-linked:** Only via RPC `start_task_conversation_v1(p_task_id)`. Non-owner starts. No direct insert for task-linked conversations by app.

**App API rename:** Replace misleading `startConversationByClient(...)` with explicit methods, e.g. `startDirectConversation(...)` and `startTaskConversation(...)`. Temporary compatibility wrapper allowed only for staged migration.

---

## 4. Archive semantics

- **Server-authoritative:** Archive is per-user, server-timestamped. RPC `archive_conversation_v1(p_conversation_id)` stamps the caller’s archive column with server time. Rejects non-participants.
- **Non-destructive:** No row delete; conversation hidden for caller until a newer message arrives (per-product rule).
- **App:** Stop writing client timestamps for archive; call archive RPC only.

---

## 5. Notification source of truth

- **Server only:** Receiver notifications are created by server trigger `messages_after_insert_notify_receiver`. Client must not insert into `notifications` for chat receiver notifications.
- **Verification:** No Chat code path performs client-side notification insert (search-based verification in plan).

---

## 6. Attachment storage/access contract

- **Path:** `convos/<conversation_id>/<filename_or_uuid>` (or project-standard variant). All objects in `chat-attachments` must match this pattern for participant-scoped checks.
- **Access:** Participant-scoped only. Helper e.g. `can_access_chat_attachment(p_object_name, p_uid)` determines access from conversation membership. Signed URLs generated at render time; never persist signed URLs as durable state.
- **Mutation:** Append-only in this pass; no delete/update policies for this bucket in ChatFix scope.

---

## 7. Public method deprecation (app)

- `startConversationByClient(...)` — replace with `startDirectConversation(...)` and `startTaskConversation(...)`. Document in CHAT_CONTRACT and CHAT_ROLLOUT_MATRIX; keep compatibility wrapper only if staged migration requires it.

---

## 8. App contract reconciliation (Phase 1)

**Exact rename and compatibility:**
- Canonical write values: snake_case only (message types, no camelCase on insert).
- Offer payload: app reads legacy `delivery` temporarily; app writes `days` only.
- Replace misleading `startConversationByClient(...)` with explicit `startDirectConversation(...)` and `startTaskConversation(...)`.

**Planned file work:**
- Edit `lib/features/chat/models/message_model.dart` (snake_case wire, legacy read).
- Create `lib/features/chat/models/chat_offer_payload.dart`.
- Create `lib/features/chat/services/chat_realtime_merger.dart`.
- Edit `lib/features/chat/services/message_service.dart` (archive RPC, merge, fallback).
- Edit `lib/features/chat/data/chat_repository.dart` (explicit direct/task methods).
