begin;

CREATE OR REPLACE FUNCTION public.rpc_get_profile_summaries(p_ids uuid[])
RETURNS TABLE (
  id uuid,
  full_name text,
  avatar_url text,
  bio text,
  active_role text,
  skills text[],
  created_at timestamptz,
  seller_level public.seller_level_enum
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'AUTH_REQUIRED'
      USING ERRCODE = '42501';
  END IF;

  IF COALESCE(array_length(p_ids, 1), 0) = 0 THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    p.id,
    p.full_name,
    p.avatar_url,
    p.bio,
    p.active_role,
    COALESCE(p.skills, ARRAY[]::text[]),
    p.created_at,
    p.seller_level
  FROM public.profiles p
  WHERE p.id = ANY (p_ids);
END;
$$;

REVOKE ALL ON FUNCTION public.rpc_get_profile_summaries(uuid[]) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.rpc_get_profile_summaries(uuid[]) FROM anon;
REVOKE ALL ON FUNCTION public.rpc_get_profile_summaries(uuid[]) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_get_profile_summaries(uuid[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_get_profile_summaries(uuid[]) TO service_role;

commit;
