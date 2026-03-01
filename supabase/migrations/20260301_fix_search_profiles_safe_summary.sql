begin;

DROP FUNCTION IF EXISTS public.search_profiles(text, text, integer, integer);

CREATE OR REPLACE FUNCTION public.search_profiles(
  query text,
  role_filter text DEFAULT NULL,
  limit_val integer DEFAULT 20,
  offset_val integer DEFAULT 0
)
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
AS $function$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'AUTH_REQUIRED'
      USING ERRCODE = '42501';
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
  WHERE auth.uid() IS NOT NULL
    AND (
      to_tsvector('english', COALESCE(p.full_name, '')) @@ websearch_to_tsquery('english', query)
      OR COALESCE(p.full_name, '') ILIKE '%' || query || '%'
    )
    AND (
      role_filter IS NULL
      OR role_filter = p.active_role
      OR role_filter = ANY (COALESCE(p.roles, ARRAY[]::text[]))
    )
  ORDER BY p.created_at DESC
  LIMIT limit_val OFFSET offset_val;
END;
$function$;

REVOKE ALL ON FUNCTION public.search_profiles(text, text, integer, integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.search_profiles(text, text, integer, integer) FROM anon;
REVOKE ALL ON FUNCTION public.search_profiles(text, text, integer, integer) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.search_profiles(text, text, integer, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.search_profiles(text, text, integer, integer) TO service_role;

commit;
