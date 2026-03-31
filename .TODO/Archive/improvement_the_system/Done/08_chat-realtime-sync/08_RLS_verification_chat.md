# RLS Verification — Chat (messages & conversation_presence)

Run these checks before release. Use Supabase Dashboard SQL or MCP `execute_sql` with appropriate auth context if possible.

---

## Check 1: Participant can SELECT and INSERT messages (positive)

1. Sign in as User A (participant in conversation C with User B).
2. Run:
   ```sql
   SELECT id, content, created_at FROM public.messages WHERE conversation_id = '<C_ID>' ORDER BY created_at LIMIT 5;
   ```
3. **Expected:** Rows returned (or empty if no messages).
4. Run:
   ```sql
   INSERT INTO public.messages (conversation_id, sender_id, receiver_id, content)
   VALUES ('<C_ID>', auth.uid(), '<B_ID>', 'RLS test message');
   ```
5. **Expected:** 1 row inserted (or success).

---

## Check 2: Non-participant cannot SELECT messages (negative)

1. Sign in as User C (not participant in conversation C between A and B).
2. Run:
   ```sql
   SELECT id FROM public.messages WHERE conversation_id = '<C_ID>';
   ```
3. **Expected:** 0 rows (RLS filters) or error 42501 (permission denied).

---

## Check 3: Receiver can UPDATE delivered_at/seen_at (positive)

1. Sign in as User B (receiver in conversation C).
2. Call RPC `mark_conversation_delivered(p_conversation_id := '<C_ID>')` or equivalent UPDATE.
3. **Expected:** Success. Then call `mark_conversation_seen(p_conversation_id := '<C_ID>')`.
4. **Expected:** Success.

---

## Check 4: Non-participant cannot INSERT presence (negative)

1. Sign in as User C.
2. Run:
   ```sql
   INSERT INTO public.conversation_presence (conversation_id, user_id, is_typing)
   VALUES ('<C_ID>', auth.uid(), true);
   ```
3. **Expected:** 0 rows or error 42501 (C is not participant in C_ID).

---

**Pass criteria:** Checks 1–4 pass as expected. Document run date and outcome in execution log.
