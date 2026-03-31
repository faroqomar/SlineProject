# Contract: vw_unified_work_items

**Frozen:** 2026-03-08 (Unified Work View plan execution)

## Columns (all branches same types)

| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| id | uuid | NO | PK of source row (task.id, booking.id, task.id, direct_offer.id) |
| source_type | text | NO | 'task' \| 'booking' \| 'direct_offer' |
| source_status | text | NO | Raw status from source |
| unified_status | text | NO | active, delivered, completed, pending_payment, disputed, canceled, etc. |
| title | text | NO | |
| price | numeric | NO | |
| deadline | timestamptz | YES | |
| client_id | uuid | NO | |
| freelancer_id | uuid | NO | |
| delivered_at | timestamptz | YES | |
| review_expires_at | timestamptz | YES | |
| revisions_total | int | NO | |
| revisions_used | int | NO | |
| work_item_id | text | NO | 'task:\<uuid>', 'booking:\<uuid>', 'direct_offer:\<uuid>' |
| last_activity_at | timestamptz | YES | |
| needs_review | boolean | NO | |
| sort_rank | int | NO | 2=pending_payment, 4=active, 5=delivered, 6=completed/done |
| awarded_request_id | uuid | YES | Set for branch 3 (awarded unpaid task) |
| payment_deadline | timestamptz | YES | Set for branch 3 |
| conversation_id | uuid | YES | Set for branch 4 (direct_offer) only; NULL others |

## Dispute JOIN (frozen)

- Branch 1 (tasks): `LEFT JOIN disputes d ON d.task_id = t.id`
- Branch 2 (bookings): `LEFT JOIN disputes d ON d.task_id = b.task_id`
- Branch 3 (awarded): no dispute join (task not yet in progress) or same as Branch 1 via t.id
- Branch 4 (direct_offers): `LEFT JOIN disputes d ON d.direct_offer_id = do.id`

Open dispute condition: `d.id IS NOT NULL AND d.status NOT IN ('resolved', 'closed')` → override unified_status to 'disputed'.

## source_type / unified_status

- source_type: task | booking | direct_offer
- unified_status: active | delivered | completed | pending_payment | disputed | canceled | request_pending | paid_request_pending | pending | unknown (app maps unknown for unknown values)

## Security

- View MUST be created with `WITH (security_invoker = true)` so RLS on tasks, bookings, task_requests, direct_offers applies.
