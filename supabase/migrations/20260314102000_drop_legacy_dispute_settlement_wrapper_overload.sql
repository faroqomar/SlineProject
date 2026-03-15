-- Remove the legacy overloaded wrapper so Supabase RPC targets a single settlement entrypoint.

DROP FUNCTION IF EXISTS public.admin_resolve_dispute_settlement(
  uuid,
  uuid,
  text,
  text,
  uuid,
  bigint,
  bigint,
  text
);
