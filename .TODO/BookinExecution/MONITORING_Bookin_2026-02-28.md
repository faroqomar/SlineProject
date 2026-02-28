# Monitoring — Bookin — 2026-02-28

## Queries

### Duplicate correlation ids

```sql
select correlation_id, count(*)
from public.booking_payment_audits
group by correlation_id
having count(*) > 1;
```

### Held payments without `paid_request_pending` booking

```sql
select id, status, payment_status, payment_gateway_id
from public.bookings
where payment_status = 'held'
  and status = 'pending';
```

### Rejected webhook events

```sql
select created_at, booking_id, correlation_id, payload
from public.booking_payment_audits
where event_type = 'webhook_reject'
order by created_at desc;
```

### Stale unpaid drafts

```sql
select id, client_id, payment_expires_at
from public.bookings
where status = 'pending'
  and coalesce(payment_status::text, 'unpaid') = 'unpaid'
  and payment_expires_at is not null
  and payment_expires_at < now();
```

## Alerting Hints

- Any sustained `webhook_reject` rate above background noise is a stop-ship signal.
- Any growth in stale unpaid drafts after checkout release indicates recovery/webhook drift.
