-- Admin schema and direct offer observability views (Plan 19: Direct Offers Work Contract).
-- Access: service_role only (no GRANT to anon/authenticated).

CREATE SCHEMA IF NOT EXISTS admin;

CREATE OR REPLACE VIEW admin.vw_direct_offer_money_story AS
SELECT
  d.id AS offer_id,
  d.client_id,
  d.freelancer_id,
  d.status,
  d.payment_status,
  je.event_type,
  je.created_at AS ledger_timestamp,
  ll.amount,
  ll.direction,
  acc.account_code
FROM public.direct_offers d
LEFT JOIN public.journal_entries je ON je.related_entity_id = d.id AND je.related_entity_type = 'direct_offer'
LEFT JOIN public.ledger_lines ll ON ll.journal_entry_id = je.id
LEFT JOIN public.accounts acc ON acc.id = ll.account_id
ORDER BY d.created_at DESC, je.created_at ASC;

CREATE OR REPLACE VIEW admin.vw_direct_offer_stuck_funds AS
SELECT id, client_id, freelancer_id, status, payment_status, created_at, updated_at
FROM public.direct_offers
WHERE (status = 'delivered' AND payment_status = 'held' AND updated_at < NOW() - INTERVAL '7 days')
   OR (status = 'active' AND payment_status = 'held' AND updated_at < NOW() - INTERVAL '30 days');

COMMENT ON VIEW admin.vw_direct_offer_money_story IS 'Admin: money story per direct offer (ledger entries). Service-role only.';
COMMENT ON VIEW admin.vw_direct_offer_stuck_funds IS 'Admin: direct offers with stuck escrow (delivered 7+ days or active 30+ days). Service-role only.';
