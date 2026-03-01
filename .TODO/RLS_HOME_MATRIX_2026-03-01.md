# Home Feed RLS Validation Matrix

## Tasks
- Anonymous:
  - `select id from public.tasks limit 1;`
  - Expected: denied after hardening.
- Authenticated:
  - `select id from public.tasks where status = 'open' limit 1;`
  - Expected: allowed.
- Authenticated involved user:
  - `select id from public.tasks where client_id = auth.uid() or owner_id = auth.uid() or freelancer_id = auth.uid() or assigned_freelancer_id = auth.uid() limit 1;`
  - Expected: allowed.

## Profiles Base Table
- Own row:
  - `select id, full_name, avatar_url, bio, active_role, skills, created_at, seller_level from public.profiles where id = auth.uid();`
  - Expected: allowed.
- Other row:
  - `select email, metadata from public.profiles where id <> auth.uid() limit 1;`
  - Expected: denied after hardening.

## Profile Summary RPC
- Authenticated:
  - `select * from public.rpc_get_profile_summaries(array[auth.uid()]);`
  - Expected: allowed.
- Anonymous:
  - `select * from public.rpc_get_profile_summaries(array['00000000-0000-0000-0000-000000000000'::uuid]);`
  - Expected: denied.

## Saved Tasks
- Own rows:
  - `select * from public.saved_tasks where user_id = auth.uid();`
  - Expected: allowed.
- Other rows:
  - `select * from public.saved_tasks where user_id <> auth.uid() limit 1;`
  - Expected: denied.
