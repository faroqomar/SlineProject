# Chat Live SQL Baseline (2026-03-01)

**Purpose:** Capture current live definitions for Chat-related objects on implementation day. Implementation must use a fresh live baseline, not stale assumptions. Re-scan using Supabase Dashboard or `@mcp:supabase-mcp-server:` (or equivalent) and paste outputs below.

**Reference (docs):** `Sline_everything/SUPABASE_SETUP.md` — message_type_enum (§4.3), conversations/messages policies (§7.4–7.5), chat-attachments storage (§11), realtime (§12).

---

## 1. Policies to capture

### 1.1 `public.messages`

Run (or equivalent):

```sql
SELECT policyname, cmd, permissive, qual, with_check
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'messages';
```

**Paste current definitions here (implementation day):**

- (Live output: policy names and definitions. Plan notes: remove broad authenticated read/insert; keep participant/sender-only.)

### 1.2 `public.conversations`

```sql
SELECT policyname, cmd, permissive, qual, with_check
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'conversations';
```

**Paste current definitions here:**

- (Live output. Plan notes: one canonical DM insert matching favorites-gated rule.)

### 1.3 `storage.objects` for chat-attachments

```sql
SELECT policyname, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'storage' AND tablename = 'objects'
  AND (qual::text LIKE '%chat-attachments%' OR with_check::text LIKE '%chat-attachments%');
```

**Paste current definitions here:**

- (Live output. Plan notes: replace bucket-wide auth select with participant-scoped.)

---

## 2. Functions / RPCs

### 2.1 start_task_conversation_v1

```sql
SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname = 'start_task_conversation_v1';
```

**Paste or summarize:**

- (Live output.)

### 2.2 mark_conversation_delivered / mark_conversation_seen

(Optional: capture if changed.)

### 2.3 messages_before_insert_validate, messages_after_insert_offer_accept, messages_after_insert_notify_receiver

```sql
SELECT proname, pg_get_functiondef(oid) FROM pg_proc
WHERE proname IN ('messages_before_insert_validate', 'messages_after_insert_offer_accept', 'messages_after_insert_notify_receiver');
```

**Paste or summarize:**

- (Live output. Plan: offer payload must require `days`; notifications server-only.)

### 2.4 conversations_before_insert_guard, normalize_conversation_users

(Optional: capture if relevant to DM rule.)

### 2.5 Helper functions (for policies)

```sql
SELECT proname, pg_get_functiondef(oid) FROM pg_proc
WHERE proname IN ('is_conversation_participant', 'is_client');
```

**Paste or summarize:**

- (Live output.)

---

## 3. Realtime publication

```sql
SELECT schemaname, tablename
FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
  AND schemaname = 'public'
  AND tablename IN ('messages', 'notifications', 'conversations');
```

**Paste result:**

- (Live output. Plan: currently messages + notifications; conversations may be missing — app must use fetch-refresh fallback.)

---

## 4. Enum values

```sql
SELECT e.enumlabel FROM pg_type t
JOIN pg_enum e ON e.enumtypid = t.oid
WHERE t.typname = 'message_type_enum'
ORDER BY e.enumsortorder;
```

**Paste result:**

- (Expected: text, system, offer, offer_update, offer_accepted, offer_rejected, delivery_submitted, end_early_request, dispute_report.)

---

## 5. Rollback

Before applying any destructive policy change, copy the **current** policy/function definitions from this baseline into a rollback snippet file or CHAT_ROLLOUT_MATRIX so they can be re-applied if a rollback trigger fires.
