-- Harden rpc_request_revision: state guard (status = 'delivered') and cap guard (revisions_used < revisions_total).
-- When revisions_total is NULL or 0, no revisions allowed. Order: SELECT -> client check -> status check -> cap check -> UPDATE.

CREATE OR REPLACE FUNCTION public.rpc_request_revision(
  entity_type text,
  entity_id uuid,
  p_note text DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
  _client_id uuid;
  _owner_id uuid;
  _status text;
  _revisions_used int;
  _revisions_total int;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF entity_type = 'task' THEN
    SELECT t.client_id, t.owner_id, t.status::text, COALESCE(t.revisions_used, 0), COALESCE(t.revisions_total, 0)
    INTO _client_id, _owner_id, _status, _revisions_used, _revisions_total
    FROM public.tasks t
    WHERE t.id = entity_id;
    IF _client_id IS NULL THEN _client_id := _owner_id; END IF;
    IF _client_id <> auth.uid() THEN
      RAISE EXCEPTION 'Only client can request revision';
    END IF;
    IF _status IS NULL THEN
      RAISE EXCEPTION 'Task not found';
    END IF;
    IF _status <> 'delivered' THEN
      RAISE EXCEPTION 'Can only request revision on delivered work';
    END IF;
    IF _revisions_used >= _revisions_total THEN
      RAISE EXCEPTION 'No revisions remaining';
    END IF;
    UPDATE public.tasks
    SET status = 'active',
        delivered_at = NULL,
        review_expires_at = NULL,
        revision_note = p_note,
        revisions_used = _revisions_used + 1,
        revision_requested_at = now()
    WHERE id = entity_id;
  ELSIF entity_type = 'booking' THEN
    SELECT b.client_id, b.status::text, COALESCE(b.revisions_used, 0), COALESCE(b.revisions_total, 0)
    INTO _client_id, _status, _revisions_used, _revisions_total
    FROM public.bookings b
    WHERE b.id = entity_id;
    IF _client_id <> auth.uid() THEN
      RAISE EXCEPTION 'Only client can request revision';
    END IF;
    IF _status IS NULL THEN
      RAISE EXCEPTION 'Booking not found';
    END IF;
    IF _status <> 'delivered' THEN
      RAISE EXCEPTION 'Can only request revision on delivered work';
    END IF;
    IF _revisions_used >= _revisions_total THEN
      RAISE EXCEPTION 'No revisions remaining';
    END IF;
    UPDATE public.bookings
    SET status = 'active',
        delivered_at = NULL,
        review_expires_at = NULL,
        revision_note = p_note,
        revisions_used = _revisions_used + 1,
        revision_requested_at = now()
    WHERE id = entity_id;
  ELSE
    RAISE EXCEPTION 'Invalid entity type';
  END IF;
END;
$$;

COMMENT ON FUNCTION public.rpc_request_revision(text, uuid, text) IS
  'Client requests revision on delivered work. Enforces status=delivered and revisions_used < revisions_total. Resets status to active and increments revisions_used.';
