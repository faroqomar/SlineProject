-- Compatibility wrapper for PostgREST schema-cache mismatches on rpc_approve_delivery.
-- Why: some clients/schema-cache states resolve the RPC as
-- public.rpc_approve_delivery(entity_id, entity_type) instead of the canonical
-- public.rpc_approve_delivery(entity_type, entity_id).

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

COMMENT ON FUNCTION public.rpc_approve_delivery(uuid, text) IS
  'Compatibility wrapper that forwards rpc_approve_delivery(entity_id, entity_type) to the canonical rpc_approve_delivery(entity_type, entity_id).';

GRANT EXECUTE ON FUNCTION public.rpc_approve_delivery(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_approve_delivery(uuid, text) TO service_role;
REVOKE EXECUTE ON FUNCTION public.rpc_approve_delivery(uuid, text) FROM anon;

COMMIT;
