# Chat Realtime Sync — Contract (DB ↔ Flutter)

**Purpose:** Single reference for messages, conversation_presence, and RPCs to avoid drift.

---

## 1. Table: `public.messages`

Columns used by the app:

| Column            | Type      | Nullable | Usage                    |
|-------------------|-----------|----------|--------------------------|
| id                | uuid      | NO       | PK                       |
| conversation_id   | uuid      | YES      | FK conversations         |
| sender_id         | uuid      | YES      | FK profiles; must = auth.uid() on INSERT |
| receiver_id       | uuid      | YES      | FK profiles; UPDATE delivered_at/seen_at allowed for receiver |
| content           | text      | NO       | Body                      |
| message_type      | enum      | NO       | text, offer, etc.        |
| payload           | jsonb     | NO       | Extra data                |
| attachment_url    | text      | YES      | Storage path              |
| attachment_type   | text      | YES      | image \| file             |
| attachment_name   | text      | YES      | Original filename         |
| attachment_size   | bigint    | YES      | Bytes                     |
| delivered_at      | timestamptz | YES    | Set by receiver (RPC)     |
| seen_at           | timestamptz | YES    | Set by receiver (RPC)     |
| created_at        | timestamptz | YES    | Default now()             |

**RLS:** SELECT/INSERT participant-only; UPDATE for receiver_id = auth.uid() (participant) on delivered_at, seen_at.

---

## 2. Table: `public.conversation_presence`

| Column            | Type      | Nullable | Default | Usage                |
|-------------------|-----------|----------|---------|----------------------|
| conversation_id   | uuid      | NO       | -       | FK conversations (PK part) |
| user_id           | uuid      | NO       | -       | FK profiles(id) (PK part)   |
| is_typing         | boolean   | NO       | false   | Typing indicator     |
| updated_at        | timestamptz | NO     | now()   | TTL: client ignores if > 15s |

**RLS:** SELECT participant-only; INSERT/UPDATE only auth.uid() = user_id and participant.

---

## 3. RPCs

| RPC name                    | Params                          | Purpose                          |
|-----------------------------|----------------------------------|----------------------------------|
| mark_conversation_delivered | p_conversation_id uuid           | Set delivered_at for current user as receiver |
| mark_conversation_seen      | p_conversation_id uuid           | Set seen_at for current user as receiver      |

(Existing RPCs; no signature change.)

---

## 4. Realtime

- **Publication:** `supabase_realtime` includes `messages` and `conversation_presence`.
- **Payload shape:** Same as table row (snake_case). Flutter maps to Message / presence map.
