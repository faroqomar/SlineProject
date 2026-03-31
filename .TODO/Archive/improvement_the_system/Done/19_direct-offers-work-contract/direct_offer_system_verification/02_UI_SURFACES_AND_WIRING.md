# 02_UI_SURFACES_AND_WIRING

## E1) Flutter App Surfaces

### 1) Chat Screen (Offer Message)

- **UI Surface**: `CreateOfferSheet` (Freelancer creates), `OfferMessageBubble` (Client views/accepts).
- **Wiring (Create)**: Input calls `DirectOffersService.createOffer()` -> Inserts into `direct_offers` -> Adds Chat Message payload via `MessageService`.
- **Wiring (Accept)**: `OfferMessageBubble` calls `DirectOffersService.acceptOfferWithoutPayment()` -> Updates DB status to `accepted`.

### 2) Client Dashboard (Direct Offer Details)

- **UI Surface**: `DirectOfferDetailsScreen` wrapped with `DirectOfferDetailsViewModel`.
- **Wiring (Pay Now / QiCard)**: `canPay` is true when status is `accepted` + `unpaid`.
- Action triggers `payNow()` (Ledger Wallet) or `createPaymentForCard()` (QiCard gateway).
- **Concurrency Guard**: `_payInProgress` and `_cardPaymentInProgress` boolean lock the UI.

### 3) Freelancer Dashboard (Mark Delivered)

- **UI Surface**: `DirectOfferDetailsScreen` (Freelancer view).
- **Wiring**: `canMarkDelivered` is true when `active` + `held` and `auth.uid() == freelancer_id`.
- Action triggers `DirectOfferDetailsViewModel.markDelivered()`.
- **Concurrency Guard**: `_markDeliveredInProgress` locks the UI button.

### 4) Client Completion UI

- **UI Surface**: `DirectOfferDetailsScreen` (Client view).
- **Wiring**: `canComplete` is true when `delivered` + `held`.
- Action triggers `DirectOfferDetailsViewModel.completeOffer()`. This sends `submitPaymentEvent('release_with_fee', 'direct_offer', offerId)` to the LedgerService.
- **Concurrency Guard**: `_completeInProgress` locks the UI button.

## E2) Admin/Support Surfaces (Observability)

To safely observe and debug direct offers, the following views are necessary for an Admin Dashboard:

**1. "Direct Offer Money Story" View**

```sql
CREATE OR REPLACE VIEW admin.vw_direct_offer_money_story AS
SELECT
  do.id AS offer_id,
  do.client_id,
  do.freelancer_id,
  do.status,
  do.payment_status,
  je.event_type,
  je.created_at AS ledger_timestamp,
  ll.amount,
  ll.direction,
  acc.account_code
FROM public.direct_offers do
JOIN public.journal_entries je ON je.related_entity_id = do.id AND je.related_entity_type = 'direct_offer'
JOIN public.ledger_lines ll ON ll.journal_entry_id = je.id
JOIN public.accounts acc ON acc.id = ll.account_id
ORDER BY do.created_at DESC, je.created_at ASC;
```

**2. "Stuck Funds" View**

```sql
CREATE OR REPLACE VIEW admin.vw_direct_offer_stuck_funds AS
SELECT id, client_id, freelancer_id, status, payment_status, created_at
FROM public.direct_offers
WHERE (status = 'delivered' AND payment_status = 'held' AND updated_at < NOW() - INTERVAL '7 days')
   OR (status = 'active' AND payment_status = 'held' AND updated_at < NOW() - INTERVAL '30 days');
```
