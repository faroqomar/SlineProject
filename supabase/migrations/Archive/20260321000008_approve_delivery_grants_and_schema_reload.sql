-- Ensure both approve-delivery RPC signatures are executable by app callers
-- and force PostgREST to reload its schema cache after compatibility changes.

BEGIN;

CREATE OR REPLACE FUNCTION public.rpc_approve_delivery(
  entity_id uuid,
  entity_type text
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  RETURN public.rpc_approve_delivery(entity_type, entity_id);
END;
$function$;

GRANT EXECUTE ON FUNCTION public.rpc_approve_delivery(text, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_approve_delivery(text, uuid) TO service_role;
REVOKE EXECUTE ON FUNCTION public.rpc_approve_delivery(text, uuid) FROM anon;

GRANT EXECUTE ON FUNCTION public.rpc_approve_delivery(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_approve_delivery(uuid, text) TO service_role;
REVOKE EXECUTE ON FUNCTION public.rpc_approve_delivery(uuid, text) FROM anon;

NOTIFY pgrst, 'reload schema';

COMMIT;
