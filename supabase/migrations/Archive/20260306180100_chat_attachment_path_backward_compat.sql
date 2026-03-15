-- Backward compatibility: allow chat-attachments paths with legacy double prefix
-- convos/convos/<conversation_id>/<filename> (old bug) in addition to convos/<conversation_id>/<filename>.
-- No data migration; RLS helper accepts both path shapes so existing messages load.

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

  v_parts := string_to_array(p_object_name, '/');
  IF array_length(v_parts, 1) < 2 OR v_parts[1] <> 'convos' THEN
    RETURN false;
  END IF;

  -- Legacy: convos/convos/<conversation_id>/<filename> (double prefix from old client bug)
  IF array_length(v_parts, 1) >= 4 AND v_parts[2] = 'convos' THEN
    BEGIN
      v_conversation_id := v_parts[3]::uuid;
    EXCEPTION WHEN OTHERS THEN
      RETURN false;
    END;
  ELSE
    -- Normal: convos/<conversation_id>/...
    BEGIN
      v_conversation_id := v_parts[2]::uuid;
    EXCEPTION WHEN OTHERS THEN
      RETURN false;
    END;
  END IF;

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
  'Chat: true if p_uid is participant of conversation in path convos/<id>/... or legacy convos/convos/<id>/...';
