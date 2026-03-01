-- Chat: additive Phase 2 — archive RPC and storage access helper.
-- Apply in staging first. Capture pre-change policy/function state in .TODO/CHAT_LIVE_SQL_BASELINE before applying.
-- Rollback: see .TODO/CHAT_ROLLOUT_MATRIX; restore captured policies if rollback trigger fires.

-- 1) Ensure archive columns exist on conversations (app already uses them; may exist in live)
ALTER TABLE public.conversations
  ADD COLUMN IF NOT EXISTS deleted_at_user1 timestamptz,
  ADD COLUMN IF NOT EXISTS deleted_at_user2 timestamptz;

-- 2) Archive RPC: server-authoritative, per-user, non-destructive
CREATE OR REPLACE FUNCTION public.archive_conversation_v1(p_conversation_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_user1 uuid;
  v_user2 uuid;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT user1_id, user2_id INTO v_user1, v_user2
  FROM public.conversations
  WHERE id = p_conversation_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Conversation not found';
  END IF;

  IF v_uid <> v_user1 AND v_uid <> v_user2 THEN
    RAISE EXCEPTION 'Not a participant';
  END IF;

  IF v_uid = v_user1 THEN
    UPDATE public.conversations
    SET deleted_at_user1 = now()
    WHERE id = p_conversation_id;
  ELSE
    UPDATE public.conversations
    SET deleted_at_user2 = now()
    WHERE id = p_conversation_id;
  END IF;
END;
$$;

COMMENT ON FUNCTION public.archive_conversation_v1(uuid) IS
  'Chat: archive conversation for caller only; server time; participant-only.';

-- 3) Storage helper: participant-scoped access for chat-attachments path convos/<conversation_id>/...
CREATE OR REPLACE FUNCTION public.can_access_chat_attachment(p_object_name text, p_uid uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_parts text[];
  v_conversation_id uuid;
  v_user1 uuid;
  v_user2 uuid;
BEGIN
  IF p_uid IS NULL OR p_object_name IS NULL OR p_object_name = '' THEN
    RETURN false;
  END IF;

  -- Expected path: convos/<conversation_id>/...
  v_parts := string_to_array(p_object_name, '/');
  IF array_length(v_parts, 1) < 2 OR v_parts[1] <> 'convos' THEN
    RETURN false;
  END IF;

  BEGIN
    v_conversation_id := v_parts[2]::uuid;
  EXCEPTION WHEN OTHERS THEN
    RETURN false;
  END;

  SELECT user1_id, user2_id INTO v_user1, v_user2
  FROM public.conversations
  WHERE id = v_conversation_id;

  IF NOT FOUND THEN
    RETURN false;
  END IF;

  RETURN p_uid = v_user1 OR p_uid = v_user2;
END;
$$;

COMMENT ON FUNCTION public.can_access_chat_attachment(text, uuid) IS
  'Chat: true if p_uid is participant of conversation in path convos/<conversation_id>/...';

-- Note: New RLS policies that USE this helper (e.g. storage.objects SELECT for chat-attachments)
-- should be added in a follow-up migration after validating allow/deny matrix.
-- Do NOT drop existing broad policies in this migration (additive only).
