-- Work feature: rpc_request_revision, rpc_accept_change_request.
-- Client-only revision; recipient-only change accept. SECURITY DEFINER with auth.uid() checks.

-- rpc_request_revision: client rejects delivery and requests changes (resets to active, increments revisions_used).
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
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF entity_type = 'task' THEN
    SELECT t.client_id, t.owner_id INTO _client_id, _owner_id
    FROM public.tasks t
    WHERE t.id = entity_id;
    IF _client_id IS NULL THEN _client_id := _owner_id; END IF;
    IF _client_id <> auth.uid() THEN
      RAISE EXCEPTION 'Only client can request revision';
    END IF;
    UPDATE public.tasks
    SET status = 'active',
        delivered_at = NULL,
        review_expires_at = NULL,
        revision_note = p_note,
        revisions_used = COALESCE(revisions_used, 0) + 1,
        revision_requested_at = now()
    WHERE id = entity_id;
  ELSIF entity_type = 'booking' THEN
    SELECT b.client_id INTO _client_id
    FROM public.bookings b
    WHERE b.id = entity_id;
    IF _client_id <> auth.uid() THEN
      RAISE EXCEPTION 'Only client can request revision';
    END IF;
    UPDATE public.bookings
    SET status = 'active',
        delivered_at = NULL,
        review_expires_at = NULL,
        revision_note = p_note,
        revisions_used = COALESCE(revisions_used, 0) + 1,
        revision_requested_at = now()
    WHERE id = entity_id;
  ELSE
    RAISE EXCEPTION 'Invalid entity type';
  END IF;
END;
$$;

COMMENT ON FUNCTION public.rpc_request_revision(text, uuid, text) IS
  'Client requests revision on delivered work. Resets status to active and increments revisions_used.';

-- rpc_accept_change_request: recipient accepts a change request (by request id).
CREATE OR REPLACE FUNCTION public.rpc_accept_change_request(request_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
  _req RECORD;
  _is_participant boolean;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT * INTO _req
  FROM public.change_requests
  WHERE id = request_id AND status = 'pending';

  IF _req IS NULL THEN
    RAISE EXCEPTION 'Change request not found or not pending';
  END IF;

  _is_participant := public.is_work_log_participant(_req.related_entity_id, _req.related_entity_type, auth.uid());
  IF _req.requester_id = auth.uid() THEN
    RAISE EXCEPTION 'Requester cannot accept own change request';
  END IF;
  IF NOT _is_participant THEN
    RAISE EXCEPTION 'Only the other participant can accept the change request';
  END IF;

  UPDATE public.change_requests
  SET status = 'accepted', resolved_at = now()
  WHERE id = request_id;

  -- Minimal apply: mark accepted. Full apply (update task/booking columns, wallet) can be done in a trigger or separate step.
  -- App expects RPC to exist and accept by id; state is now accepted.
END;
$$;

COMMENT ON FUNCTION public.rpc_accept_change_request(uuid) IS
  'Recipient accepts a pending change request. Updates status to accepted.';

GRANT EXECUTE ON FUNCTION public.rpc_request_revision(text, uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_accept_change_request(uuid) TO authenticated;
