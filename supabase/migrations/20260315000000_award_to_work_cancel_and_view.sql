-- Award → Work: cancel_awarded_offer RPC + extend vw_unified_work_items for awarded pending payment.
-- Enables task to appear in Work tab as "Waiting payment" after award; client can Pay or Cancel.
BEGIN;

-- 1. cancel_awarded_offer: revert award so task goes back to open and reappears in Inbox
CREATE OR REPLACE FUNCTION public.cancel_awarded_offer(
  p_request_id UUID,
  p_client_id UUID DEFAULT auth.uid()
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_request RECORD;
  v_task RECORD;
  v_freelancer UUID;
BEGIN
  SELECT * INTO v_request
  FROM public.task_requests
  WHERE id = p_request_id
    AND status = 'accepted'
    AND payment_status = 'unpaid';

  IF v_request IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Request not found or not in awarded-unpaid state');
  END IF;

  SELECT * INTO v_task
  FROM public.tasks
  WHERE id = v_request.task_id;

  IF v_task IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Task not found');
  END IF;

  IF v_task.owner_id IS DISTINCT FROM p_client_id THEN
    RETURN jsonb_build_object('success', false, 'error', 'Only task owner can cancel the award');
  END IF;

  v_freelancer := COALESCE(v_request.freelancer_id, v_request.bidder_id);

  -- Revert task_request to rejected and soft-delete so uq_task_requests_one_active_per_freelancer allows a new offer
  UPDATE public.task_requests
  SET status = 'rejected',
      payment_status = NULL,
      payment_deadline = NULL,
      awarded_at = NULL,
      awarded_by = NULL,
      updated_at = NOW(),
      deleted_at = NOW()
  WHERE id = p_request_id;

  -- Reopen task so it can receive offers again
  UPDATE public.tasks
  SET status = 'open',
      freelancer_id = NULL,
      assigned_freelancer_id = NULL,
      updated_at = NOW()
  WHERE id = v_request.task_id;

  -- Notify freelancer
  IF v_freelancer IS NOT NULL THEN
    PERFORM public.private_create_notification(
      p_user_id => v_freelancer,
      p_title => 'Award cancelled',
      p_message => 'The client cancelled the award. The task is open again.',
      p_type => 'offer_award_cancelled',
      p_related_entity_id => p_request_id,
      p_related_entity_type => 'task_request',
      p_metadata => jsonb_build_object(
        'task_id', v_request.task_id,
        'request_id', p_request_id
      )
    );
  END IF;

  RETURN jsonb_build_object('success', true);
END;
$$;

COMMENT ON FUNCTION public.cancel_awarded_offer(UUID, UUID) IS
  'Cancels an awarded-but-unpaid offer. Reverts task to open so it reappears in Inbox.';

-- 2. Extend vw_unified_work_items: add awarded pending payment branch and awarded_request_id / payment_deadline columns.
-- Existing view may not have sort_rank/last_activity_at/work_item_id/needs_review in DB; app uses defaults if missing.
-- We add a third branch and new columns; existing branches supply NULL for new columns.
DROP VIEW IF EXISTS public.vw_unified_work_items;

CREATE VIEW public.vw_unified_work_items AS
-- Branch 1: Tasks in progress (already assigned)
SELECT
    t.id,
    'task'::text AS source_type,
    t.status AS source_status,
    CASE
        WHEN t.status = 'in_progress' THEN 'active'
        WHEN t.status = 'delivered' THEN 'delivered'
        WHEN t.status = 'completed' THEN 'completed'
        WHEN t.status = 'canceled' THEN 'canceled'
        ELSE t.status
    END AS unified_status,
    t.title,
    COALESCE(t.budget, 0)::numeric AS price,
    t.deadline,
    COALESCE(t.client_id, t.owner_id) AS client_id,
    t.assigned_freelancer_id AS freelancer_id,
    t.delivered_at,
    t.review_expires_at,
    COALESCE(t.revisions_total, 3) AS revisions_total,
    COALESCE(t.revisions_used, 0) AS revisions_used,
    ('task:' || t.id::text) AS work_item_id,
    GREATEST(t.updated_at, t.delivered_at) AS last_activity_at,
    (t.status = 'delivered') AS needs_review,
    4 AS sort_rank,
    NULL::uuid AS awarded_request_id,
    NULL::timestamptz AS payment_deadline
FROM public.tasks t
WHERE t.assigned_freelancer_id IS NOT NULL
  AND t.status IN ('in_progress', 'delivered', 'completed')

UNION ALL

-- Branch 2: Bookings
SELECT
    b.id,
    'booking'::text AS source_type,
    b.status::text AS source_status,
    b.status::text AS unified_status,
    (COALESCE(t.title, 'Session') || ' - Session') AS title,
    b.price,
    av.starts_at AS deadline,
    b.client_id,
    b.provider_id AS freelancer_id,
    b.delivered_at,
    b.review_expires_at,
    COALESCE(b.revisions_total, 3) AS revisions_total,
    COALESCE(b.revisions_used, 0) AS revisions_used,
    ('booking:' || b.id::text) AS work_item_id,
    COALESCE(b.delivered_at, b.created_at) AS last_activity_at,
    (b.status = 'delivered') AS needs_review,
    CASE b.status
        WHEN 'active' THEN 4
        WHEN 'delivered' THEN 5
        ELSE 6
    END AS sort_rank,
    NULL::uuid AS awarded_request_id,
    NULL::timestamptz AS payment_deadline
FROM public.bookings b
LEFT JOIN public.tasks t ON b.task_id = t.id
LEFT JOIN public.availability_slots av ON b.slot_id = av.id
WHERE b.status IN ('active', 'delivered', 'completed')

UNION ALL

-- Branch 3: Awarded pending payment (task assigned but unpaid; no freelancer on task yet)
SELECT
    t.id,
    'task'::text AS source_type,
    'assigned'::text AS source_status,
    'pending_payment'::text AS unified_status,
    t.title,
    tr.price,
    t.deadline,
    COALESCE(t.client_id, t.owner_id) AS client_id,
    COALESCE(tr.freelancer_id, tr.bidder_id) AS freelancer_id,
    NULL::timestamptz AS delivered_at,
    NULL::timestamptz AS review_expires_at,
    3 AS revisions_total,
    0 AS revisions_used,
    ('task:' || t.id::text) AS work_item_id,
    COALESCE(tr.updated_at, t.updated_at) AS last_activity_at,
    false AS needs_review,
    2 AS sort_rank,
    tr.id AS awarded_request_id,
    tr.payment_deadline
FROM public.tasks t
JOIN public.task_requests tr ON tr.task_id = t.id
  AND tr.status = 'accepted'
  AND tr.payment_status = 'unpaid'
WHERE t.status = 'assigned'
  AND t.assigned_freelancer_id IS NULL;

COMMENT ON VIEW public.vw_unified_work_items IS
  'Unified work items: tasks (in progress + awarded pending payment), bookings. Client/freelancer filter by client_id/freelancer_id.';

COMMIT;
