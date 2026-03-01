# Chat Data Audit (2026-03-01)

**Purpose:** Inventory live Chat data that could break under tightened rules. Every historical outlier must have a keep/fix/defer decision. Do not author migrations until this is complete (Phase 1 gate).

---

## 1. Messages

### 1.1 Message type distribution

**Query:**

```sql
SELECT message_type, count(*) FROM public.messages GROUP BY message_type ORDER BY count(*) DESC;
```

**Output (paste on implementation day):**

- (Live counts per type. Expect snake_case enum values.)

**Outliers / decisions:**

| Finding | Count | Decision (keep/fix/defer) |
|---------|--------|----------------------------|
| Any non-enum or legacy type | - | Fix or defer with compatibility read |
| (Add rows as needed) | | |

### 1.2 Offer payload: `delivery` vs `days`

**Query:**

```sql
SELECT id, conversation_id, message_type, payload
FROM public.messages
WHERE message_type IN ('offer', 'offer_update')
  AND payload ? 'delivery'
  AND NOT (payload ? 'days');
```

**Output (paste on implementation day):**

- (Rows that have `delivery` but not `days`.)

**Decision:** Keep: app reads `delivery` for display during compatibility window. Fix: no new writes with `delivery` only; app writes `days` only. Defer: bulk backfill to add `days` from `delivery` only if product requires.

---

## 2. Conversations

### 2.1 Duplicate direct-DM pairs

**Query:**

```sql
SELECT least(user1_id, user2_id) AS u1, greatest(user1_id, user2_id) AS u2, count(*)
FROM public.conversations
WHERE task_id IS NULL
GROUP BY least(user1_id, user2_id), greatest(user1_id, user2_id)
HAVING count(*) > 1;
```

**Output (paste on implementation day):**

- (Duplicate pairs.)

**Decision:** Fix: consolidate or mark; Defer: document only. Plan: app should handle 23505 and open existing.

### 2.2 Task-linked duplicates

**Query:**

```sql
SELECT task_id, count(*) FROM public.conversations WHERE task_id IS NOT NULL GROUP BY task_id HAVING count(*) > 1;
```

**Output:**

- (Duplicate task-linked convos.)

**Decision:** keep/fix/defer per product.

### 2.3 Archive column states

**Query:**

```sql
SELECT count(*) FILTER (WHERE deleted_at_user1 IS NOT NULL) AS archived_user1,
       count(*) FILTER (WHERE deleted_at_user2 IS NOT NULL) AS archived_user2
FROM public.conversations;
```

**Output:**

- (If columns exist. Plan: archive RPC will stamp server time; confirm column names match.)

---

## 3. Storage (chat-attachments)

### 3.1 Object path pattern

**Check:** List object names in bucket `chat-attachments`. Expected pattern: `convos/<conversation_id>/...` (or project-standard).

**Outliers:** Any object not matching the path contract.

**Decision:** Keep: document; temporary exception in storage helper if needed. Fix: move or rename. Defer: add exception in policy/helper for legacy paths until cleanup.

**Output (paste or summarize on implementation day):**

- (Count by path prefix; list any exceptions.)

---

## 4. Summary

| Area | Outliers found | Decisions |
|------|----------------|-----------|
| Message types | (summary) | (keep/fix/defer) |
| Offer payload delivery/days | (summary) | Read compatibility; write days only |
| Duplicate DMs | (summary) | (per above) |
| Task-linked duplicates | (summary) | (per above) |
| Archive columns | (summary) | (per above) |
| Attachment paths | (summary) | (per above) |

**Gate:** No security migrations until every outlier has an explicit keep/fix/defer and compatibility rules are defined.
