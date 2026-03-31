# Direct Offer Flow — Threat Model

**Plan:** PLAN_DirectChatOfferFlow_2026-03-07_CRITIC  
**Owner:** @ThreatModeler  
**Date:** 2026-03-07

---

## Testable negative cases

1. **Permanent escrow lock:** Delivered offer never gets review_expires_at → cron never runs → funds stuck. **Mitigation:** markDelivered sets delivered_at + review_expires_at; cron branch for direct_offers. **Test:** Deliver → set review_expires_at in past → run cron → payment_status = released.
2. **Timeout abuse:** Freelancer marks delivered with empty work, waits 3 days for auto-release. **Mitigation:** Client notification on deliver; dispute path before timeout. **Test:** (Manual) verify notification; dispute can be opened for delivered offer.
3. **Double webhook / double recovery:** Two escrow_hold for same offer. **Mitigation:** Idempotency key; journal_entries unique on idempotency_key. **Test:** Same key twice → one journal entry.
4. **Fee tampering:** Client or freelancer changes fee after accept. **Mitigation:** Trigger/guard blocks UPDATE of fee_rate_applied_bps/price/currency when status != 'sent' or payment_status != 'unpaid'. **Test:** RLS/trigger: UPDATE price on accepted row as client fails.
5. **Unauthorized cancel:** Client cancels active (paid) offer or freelancer cancels after accept. **Mitigation:** cancelOffer only when isSent; cancelAcceptedOffer only when accepted+unpaid. **Test:** Service test: cancelOffer as client throws; payNow as freelancer throws.
6. **Recovery without DB anchor:** App crashes after redirect; recovery by offer_id only allows wrong session. **Mitigation:** Persist payment_request_id before redirect; recovery validates payment_request_id matches row. **Test:** Recovery with wrong payment_request_id fails.
