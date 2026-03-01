BEGIN;

CREATE OR REPLACE FUNCTION public.private_upsert_notification(
  p_user_id UUID,
  p_title TEXT,
  p_message TEXT,
  p_type TEXT,
  p_related_entity_id UUID DEFAULT NULL,
  p_related_entity_type TEXT DEFAULT NULL,
  p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_notification_id UUID;
  v_existing_metadata JSONB := '{}'::jsonb;
  v_count INTEGER := 1;
BEGIN
  IF p_user_id IS NULL THEN
    RETURN;
  END IF;

  SELECT id, COALESCE(metadata, '{}'::jsonb)
  INTO v_notification_id, v_existing_metadata
  FROM public.notifications
  WHERE user_id = p_user_id
    AND type = p_type
    AND is_read = FALSE
    AND related_entity_id IS NOT DISTINCT FROM p_related_entity_id
    AND related_entity_type IS NOT DISTINCT FROM p_related_entity_type
  ORDER BY created_at DESC
  LIMIT 1
  FOR UPDATE;

  IF v_notification_id IS NOT NULL THEN
    v_count := COALESCE(NULLIF(v_existing_metadata ->> 'count', '')::INTEGER, 1) + 1;

    UPDATE public.notifications
    SET title = p_title,
        message = p_message,
        metadata = v_existing_metadata
          || COALESCE(p_metadata, '{}'::jsonb)
          || jsonb_build_object('count', v_count),
        created_at = NOW()
    WHERE id = v_notification_id;

    RETURN;
  END IF;

  INSERT INTO public.notifications (
    user_id,
    title,
    message,
    type,
    related_entity_id,
    related_entity_type,
    metadata,
    is_read,
    created_at
  ) VALUES (
    p_user_id,
    p_title,
    p_message,
    p_type,
    p_related_entity_id,
    p_related_entity_type,
    COALESCE(p_metadata, '{}'::jsonb),
    FALSE,
    NOW()
  );
END;
$$;

REVOKE ALL ON FUNCTION public.private_upsert_notification(UUID, TEXT, TEXT, TEXT, UUID, TEXT, JSONB) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.private_upsert_notification(UUID, TEXT, TEXT, TEXT, UUID, TEXT, JSONB) FROM anon;
REVOKE ALL ON FUNCTION public.private_upsert_notification(UUID, TEXT, TEXT, TEXT, UUID, TEXT, JSONB) FROM authenticated;

CREATE OR REPLACE FUNCTION public.messages_after_insert_notify_receiver()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_title TEXT := 'New Message';
  v_message TEXT := COALESCE(NULLIF(NEW.content, ''), 'You have a new message.');
  v_type TEXT := 'message';
BEGIN
  IF NEW.receiver_id IS NULL OR NEW.receiver_id = NEW.sender_id THEN
    RETURN NEW;
  END IF;

  IF NEW.message_type = 'offer' THEN
    v_title := 'New Offer Received';
    v_message := format(
      'You received an offer of %s',
      COALESCE(NEW.payload ->> 'price', '?')
    );
    v_type := 'offer';
  ELSIF NEW.message_type = 'offer_accepted' THEN
    v_title := 'Offer Accepted';
    v_message := 'Your offer has been accepted!';
    v_type := 'offer';
  ELSIF NEW.message_type = 'offer_rejected' THEN
    v_title := 'Offer Rejected';
    v_message := 'Your offer has been rejected.';
    v_type := 'offer';
  END IF;

  PERFORM public.private_upsert_notification(
    p_user_id => NEW.receiver_id,
    p_title => v_title,
    p_message => v_message,
    p_type => v_type,
    p_related_entity_id => NEW.conversation_id,
    p_related_entity_type => 'conversation',
    p_metadata => jsonb_build_object(
      'conversation_id', NEW.conversation_id,
      'message_id', NEW.id
    )
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_messages_after_insert_notify_receiver ON public.messages;
CREATE TRIGGER trg_messages_after_insert_notify_receiver
AFTER INSERT ON public.messages
FOR EACH ROW
EXECUTE FUNCTION public.messages_after_insert_notify_receiver();

CREATE OR REPLACE FUNCTION public.tasks_after_status_change_notify_parties()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.status IS NOT DISTINCT FROM OLD.status THEN
    RETURN NEW;
  END IF;

  IF NEW.assigned_freelancer_id IS NULL THEN
    RETURN NEW;
  END IF;

  IF auth.uid() = NEW.owner_id AND NEW.status = 'closed' THEN
    PERFORM public.private_create_notification(
      p_user_id => NEW.assigned_freelancer_id,
      p_title => 'Task Completed',
      p_message => format('The client has marked "%s" as completed.', COALESCE(NEW.title, 'your task')),
      p_type => 'task',
      p_related_entity_id => NEW.id,
      p_related_entity_type => 'task',
      p_metadata => jsonb_build_object(
        'task_id', NEW.id,
        'event', 'task_closed'
      )
    );
  ELSIF auth.uid() = NEW.owner_id AND NEW.status = 'canceled' THEN
    PERFORM public.private_create_notification(
      p_user_id => NEW.assigned_freelancer_id,
      p_title => 'Task Cancelled',
      p_message => format('The client has cancelled "%s".', COALESCE(NEW.title, 'your task')),
      p_type => 'task',
      p_related_entity_id => NEW.id,
      p_related_entity_type => 'task',
      p_metadata => jsonb_build_object(
        'task_id', NEW.id,
        'event', 'task_canceled'
      )
    );
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_tasks_after_status_change_notify_parties ON public.tasks;
CREATE TRIGGER trg_tasks_after_status_change_notify_parties
AFTER UPDATE OF status ON public.tasks
FOR EACH ROW
EXECUTE FUNCTION public.tasks_after_status_change_notify_parties();

DROP POLICY IF EXISTS notifications_insert_any ON public.notifications;

COMMIT;
