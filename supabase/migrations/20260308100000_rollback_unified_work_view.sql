-- Rollback: restore vw_unified_work_items to 3-branch view (no direct_offers, no disputes, no security_invoker).
-- Run this if upgrade_unified_work_view causes issues. Content from Archive/20260315000000_award_to_work_cancel_and_view.sql.
BEGIN;

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
  'Unified work items: tasks (in progress + awarded pending payment), bookings. ROLLBACK VERSION - no direct_offers, no disputes.';

COMMIT;
