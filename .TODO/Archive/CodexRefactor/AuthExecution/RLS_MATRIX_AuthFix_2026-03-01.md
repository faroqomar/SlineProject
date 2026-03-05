# RLS Matrix (AuthFix 2026-03-01)

Target table: `public.profiles`

## Allowed Tests

- [ ] SELECT self: `SELECT * FROM profiles WHERE id = auth.uid();` -> Returns 1 row.
- [ ] INSERT self: `INSERT INTO profiles (id) VALUES (auth.uid());` -> Succeeds (during compatibility window only).
- [ ] UPDATE self: `UPDATE profiles SET role = 'client' WHERE id = auth.uid();` -> Succeeds.
- [ ] DELETE self: Can delete own profile -> Succeeds.

## Forbidden Tests

- [ ] SELECT cross-user: `SELECT * FROM profiles;` -> Returns ONLY self profile.
- [ ] SELECT specific cross-user: `SELECT * FROM profiles WHERE id != auth.uid();` -> Returns 0 rows.
- [ ] UPDATE cross-user: `UPDATE profiles SET active_role = 'client' WHERE id != auth.uid();` -> Updates 0 rows.
- [ ] DELETE cross-user: `DELETE FROM profiles WHERE id != auth.uid();` -> Deletes 0 rows.

Note: Cross-user profile lookups must be executed via `rpc_get_profile_summaries` or `search_profiles` safe RPCs.
