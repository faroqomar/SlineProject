# 03_RISKS_AND_ATTACKS

## 1. Double Accept (Idempotency Risk)

**Attack Vector**: Client taps "Accept" multiple times rapidly or simulates multiple API requests.
**App Protection**: `DirectOfferDetailsViewModel` uses the `_cancelInProgress` and logic state checks.
**Database Protection**: Unnecessary as the update is `status = 'accepted'`. Updating to the same state is naturally idempotent and `fn_direct_offer_guard` allows it (if the state changes, or simply does nothing if `OLD.status == NEW.status`).

## 2. Unauthorized Delivery

**Attack Vector**: A malicious user attempts to call `.update({ 'status': 'delivered' })` on an active offer they don't own.
**Database Protection**: `fn_direct_offer_guard` explicitly checks:

```sql
IF OLD.status = 'active' AND NEW.status = 'delivered' THEN
    IF auth.uid() != OLD.freelancer_id THEN
        RAISE EXCEPTION 'direct_offer: only freelancer can mark delivered';
    END IF;
    RETURN NEW;
END IF;
```

**Conclusion**: MITIGATED by DB Guard.

## 3. Double Release (Stolen Escrow)

**Attack Vector**: Client calls `completeOffer()` twice quickly, attempting to release funds multiple times to the freelancer.
**App Protection**: `_completeInProgress` flag in the ViewModel.
**Database Protection**: `submitPaymentEvent('release_with_fee')` in the Ledger uses an `idempotency_key`. Furthermore, `process_payment_event_ledger` verifies `v_payment_status = 'held'`, so the second call will fail the gate check since the first call updates it to `released`.
**Conclusion**: MITIGATED heavily by the Ledger constraints.

## 4. Stuck Escrow (Client Abandonment)

**Attack Vector**: Freelancer delivers work, but the client never returns to click "Complete", leaving the escrow funds locked in `platform_escrow`.
**Database Protection**: The current evidence does not show a `review_expires_at` equivalent for `direct_offer` as exists for `booking` and `task`.
**Risk Level**: **Medium**.
**Mitigation Note**: Admin tooling (`vw_direct_offer_stuck_funds` from the UI Surfaces doc) is required to manually investigate and resolve these. If this happens frequently at scale, a cron job (via Edge Function + `process_expired_requests` equivalent) using `admin_credit` or `release_with_fee` should be introduced.
