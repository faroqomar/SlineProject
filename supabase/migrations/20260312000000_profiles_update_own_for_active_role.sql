-- Allow authenticated users to update their own profile row.
-- Required so offer submission can set active_role to 'freelancer' before
-- inserting into task_requests (RLS tr_insert uses is_freelancer(auth.uid())).
BEGIN;

DROP POLICY IF EXISTS profiles_update_self ON public.profiles;
CREATE POLICY profiles_update_self
ON public.profiles
FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

COMMIT;
