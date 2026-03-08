-- Upgrade vw_unified_work_items: 4 branches (tasks, bookings, awarded pending, direct_offers),
-- dispute status override, security_invoker = true, conversation_id for direct_offer.
-- Contract: .TODO/contract_vw_unified_work_items.md
-- Disputes: task_id for tasks/bookings, direct_offer_id for direct_offers. Open = status NOT IN ('resolved','closed').
BEGIN;

DROP VIEW IF EXISTS public.vw_unified_work_items;

CREATE VIEW public.vw_unified_work_items WITH (security_invoker = true) AS
-- Branch 1: Tasks in progress (already assigned)
SELECT
    t.id,
    'task'::text AS source_type,
    t.status AS source_status,
    CASE
        WHEN d.id IS NOT NULL AND d.status IS NOT NULL AND d.status NOT IN ('resolved', 'closed') THEN 'disputed'
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
    GREATEST(t.updated_at, COALESCE(t.delivered_at, t.updated_at)) AS last_activity_at,
    (t.status = 'delivered') AS needs_review,
    4 AS sort_rank,
    NULL::uuid AS awarded_request_id,
    NULL::timestamptz AS payment_deadline,
    NULL::uuid AS conversation_id
FROM public.tasks t
LEFT JOIN public.disputes d ON d.task_id = t.id
WHERE t.assigned_freelancer_id IS NOT NULL
  AND t.status IN ('in_progress', 'delivered', 'completed')

UNION ALL

-- Branch 2: Bookings
SELECT
    b.id,
    'booking'::text AS source_type,
    b.status::text AS source_status,
    CASE
        WHEN d.id IS NOT NULL AND d.status IS NOT NULL AND d.status NOT IN ('resolved', 'closed') THEN 'disputed'
        ELSE b.status::text
    END AS unified_status,
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
    NULL::timestamptz AS payment_deadline,
    NULL::uuid AS conversation_id
FROM public.bookings b
LEFT JOIN public.tasks t ON b.task_id = t.id
LEFT JOIN public.availability_slots av ON b.slot_id = av.id
LEFT JOIN public.disputes d ON d.task_id = b.task_id
WHERE b.status IN ('active', 'delivered', 'completed')

UNION ALL

-- Branch 3: Awarded pending payment
SELECT
    t.id,
    'task'::text AS source_type,
    'assigned'::text AS source_status,
    CASE
        WHEN d.id IS NOT NULL AND d.status IS NOT NULL AND d.status NOT IN ('resolved', 'closed') THEN 'disputed'
        ELSE 'pending_payment'::text
    END AS unified_status,
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
    tr.payment_deadline,
    NULL::uuid AS conversation_id
FROM public.tasks t
JOIN public.task_requests tr ON tr.task_id = t.id
  AND tr.status = 'accepted'
  AND tr.payment_status = 'unpaid'
LEFT JOIN public.disputes d ON d.task_id = t.id
WHERE t.status = 'assigned'
  AND t.assigned_freelancer_id IS NULL

UNION ALL

-- Branch 4: Direct Offers (alias doff: do is reserved in PostgreSQL)
SELECT
    doff.id,
    'direct_offer'::text AS source_type,
    doff.status AS source_status,
    CASE
        WHEN d.id IS NOT NULL AND d.status IS NOT NULL AND d.status NOT IN ('resolved', 'closed') THEN 'disputed'
        WHEN doff.status = 'accepted' AND doff.payment_status = 'unpaid' THEN 'pending_payment'
        WHEN doff.status = 'active' THEN 'active'
        WHEN doff.status = 'delivered' THEN 'delivered'
        WHEN doff.status = 'completed' THEN 'completed'
        ELSE doff.status
    END AS unified_status,
    COALESCE(NULLIF(TRIM(doff.title), ''), 'Direct Offer') AS title,
    doff.price,
    (doff.created_at + (COALESCE(doff.days, 0) || ' days')::interval)::timestamptz AS deadline,
    doff.client_id,
    doff.freelancer_id,
    doff.delivered_at,
    doff.review_expires_at,
    0 AS revisions_total,
    0 AS revisions_used,
    ('direct_offer:' || doff.id::text) AS work_item_id,
    doff.updated_at AS last_activity_at,
    (doff.status = 'delivered') AS needs_review,
    CASE
        WHEN doff.status = 'accepted' AND doff.payment_status = 'unpaid' THEN 2
        WHEN doff.status = 'active' THEN 4
        WHEN doff.status = 'delivered' THEN 5
        ELSE 6
    END AS sort_rank,
    NULL::uuid AS awarded_request_id,
    NULL::timestamptz AS payment_deadline,
    doff.conversation_id AS conversation_id
FROM public.direct_offers doff
LEFT JOIN public.disputes d ON d.direct_offer_id = doff.id
WHERE doff.status IN ('accepted', 'active', 'delivered', 'completed');

COMMENT ON VIEW public.vw_unified_work_items IS
  'Unified work items: tasks, bookings, awarded pending, direct_offers. security_invoker=true. Disputes override unified_status.';

COMMIT;
