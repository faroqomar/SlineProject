begin;

DROP POLICY IF EXISTS "Allow read access with join" ON public.tasks;
DROP POLICY IF EXISTS "Allow read tasks" ON public.tasks;
DROP POLICY IF EXISTS "Allow select for all users" ON public.tasks;
DROP POLICY IF EXISTS "tasks_select_all_auth" ON public.tasks;
DROP POLICY IF EXISTS "tasks_select_open" ON public.tasks;
DROP POLICY IF EXISTS "tasks_select_policy" ON public.tasks;

CREATE POLICY tasks_select_authenticated_open_or_involved
ON public.tasks
FOR SELECT
TO authenticated
USING (
  status = 'open'
  OR user_id = auth.uid()
  OR client_id = auth.uid()
  OR owner_id = auth.uid()
  OR freelancer_id = auth.uid()
  OR assigned_freelancer_id = auth.uid()
);

DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON public.profiles;
DROP POLICY IF EXISTS "Users can read their own profile" ON public.profiles;
DROP POLICY IF EXISTS profiles_select_self ON public.profiles;

CREATE POLICY profiles_select_self
ON public.profiles
FOR SELECT
TO authenticated
USING (id = auth.uid());

commit;
