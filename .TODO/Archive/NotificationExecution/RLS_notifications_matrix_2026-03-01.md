# RLS Notifications Verification Matrix (2026-03-01)

## Assumptions

- RLS enabled on `public.notifications`.
- Policies: `notifications_select_own` (SELECT where user_id = auth.uid()), `notifications_update_own` (UPDATE where user_id = auth.uid()). No INSERT for authenticated/anon (server-only via SECURITY DEFINER functions).

## Positive checks (must pass)

1. **User A select own**  
   As user A: `SELECT * FROM public.notifications WHERE user_id = auth.uid();`  
   Expect: returns only A's rows.

2. **User A update own**  
   As user A: `UPDATE public.notifications SET is_read = true WHERE id = <A's notification id> AND user_id = auth.uid();`  
   Expect: 1 row updated.

## Negative checks (must fail or return empty)

3. **User A select user B's**  
   As user A: `SELECT * FROM public.notifications WHERE user_id = '<B's user id>';`  
   Expect: 0 rows (RLS filters to own only).

4. **User A update user B's by ID**  
   As user A: `UPDATE public.notifications SET is_read = true WHERE id = '<B's notification id>';`  
   Expect: 0 rows updated.

5. **User A insert**  
   As user A: `INSERT INTO public.notifications (user_id, title, message, type, is_read) VALUES (auth.uid(), 'Test', 'Test', 'system', false);`  
   Expect: policy violation / denied (no insert policy for authenticated).

## How to run

- In Supabase SQL editor or psql: switch context to user A (e.g. set role or use auth.uid() simulation if available). Run 1–2 as A. Switch to user B or use B's notification ID for 3–4. Run 5 as A.
- Optional: automate via integration test or backend test that uses service role to create two users and notifications, then anon/authenticated client to run selects/updates/insert and assert expected row counts.
