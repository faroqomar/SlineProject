# Direct Chat Offers – API Contract (Flutter ↔ DB)

## 1. Table: `direct_offers`

| Column             | Type         | Nullable | Description                          |
|--------------------|--------------|----------|--------------------------------------|
| id                 | uuid         | NO       | PK, default gen_random_uuid()        |
| conversation_id    | uuid         | NO       | FK → conversations.id               |
| client_id          | uuid         | NO       | FK → profiles.id                     |
| freelancer_id      | uuid         | NO       | FK → profiles.id                     |
| task_id            | uuid         | YES      | FK → tasks.id (optional task link)   |
| title              | text         | YES      | Optional summary                     |
| description        | text         | YES      | Scope/notes                          |
| price              | numeric      | NO       | Amount (IQD)                         |
| days               | int          | NO       | Delivery days                        |
| status             | text         | NO       | See status enum below                |
| payment_status     | payment_status_enum | NO | unpaid, held, released, refunded    |
| created_at         | timestamptz  | NO       | default now()                        |
| updated_at         | timestamptz  | NO       | default now()                        |

**Status values:** `sent`, `accepted`, `rejected`, `active`, `delivered`, `completed`, `canceled`, `refunded`

## 2. Message payload (offer message)

When `message_type = 'offer'` and payload is from a direct offer:

- `offer_id` (uuid) – id of row in `direct_offers`
- `price`, `days`, `title`, `description`, `status` – same as table (for display/backward compat)

Legacy messages may have no `offer_id`; treat as message-only offer (no Accept & Pay).

## 3. RPC: `process_payment_event_ledger`

- **related_entity_type:** `'direct_offer'` supported for events: `escrow_hold`, `release_with_fee`, `refund`.
- **direct_offer escrow_hold:** Allowed when status = `sent`, payment_status = `unpaid`. Client only. On success: set payment_status = `held`, status = `active`.
- **direct_offer release_with_fee:** Allowed when status = `delivered`, payment_status = `held`. Client only. On success: set payment_status = `released`, status = `completed`.
- **direct_offer refund:** Allowed when payment_status = `held`. On success: set payment_status = `refunded`, status = `refunded` or `canceled`.

## 4. Work logs

- `work_logs.related_entity_type` = `'direct_offer'`
- `work_logs.related_entity_id` = `direct_offers.id`
- Participant check: client_id or freelancer_id = auth.uid() on `direct_offers`.
