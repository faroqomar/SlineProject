# RLS Matrix: user_devices

**Table:** `public.user_devices`  
**Plan:** Notification Routing (Plan Critic)

---

## Policies (to be created in migration)

| Policy name                    | Command | Roles       | Expression                          | Purpose              |
|--------------------------------|--------|-------------|-------------------------------------|----------------------|
| user_devices_select_own        | SELECT | authenticated | (user_id = auth.uid())              | User sees own devices |
| user_devices_insert_own        | INSERT | authenticated | (user_id = auth.uid())               | User registers own token |
| user_devices_update_own        | UPDATE | authenticated | (user_id = auth.uid())               | User updates own token |
| user_devices_delete_own        | DELETE | authenticated | (user_id = auth.uid())               | User removes own device |

- **anon:** No access (no policy for anon).
- **service_role:** Bypasses RLS (used by Edge Function to read user_devices for push).

---

## Verification (negative / positive)

| Test | Expected |
|------|----------|
| User A SELECT user_devices WHERE user_id = B | 0 rows (RLS blocks) |
| User A INSERT user_devices (user_id = B, ...) | Blocked (violates INSERT with_check) |
| User A UPDATE user_devices SET fcm_token = 'x' WHERE user_id = B | 0 rows updated |
| User A DELETE FROM user_devices WHERE user_id = B | 0 rows deleted |
| User A SELECT/INSERT/UPDATE/DELETE own row (user_id = A) | Allowed |

---

## notifications table (existing — no change)

- **INSERT:** No policy for anon/authenticated → blocked. Only server (private_upsert_notification / private_create_notification) can insert.
- **SELECT:** notifications_select_authenticated (own rows).
- **UPDATE:** notifications_update_authenticated (own rows).
