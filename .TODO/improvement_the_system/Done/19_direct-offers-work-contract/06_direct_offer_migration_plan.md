# Direct Offer Flow — Migration Plan

**Plan:** PLAN_DirectChatOfferFlow_2026-03-07_CRITIC  
**Owner:** @DataMigration  
**Date:** 2026-03-07

---

## Introduce (additive only)

- **direct_offers:** ADD COLUMN currency text NOT NULL DEFAULT 'IQD', payment_request_id text, payment_gateway_id text, payment_correlation_id text, payment_expires_at timestamptz, payment_recovered_at timestamptz, delivered_at timestamptz, review_expires_at timestamptz. (fee_rate_applied_bps already exists in live DB.)
- **disputes:** ADD COLUMN direct_offer_id uuid REFERENCES direct_offers(id). Ensure one of task_id or direct_offer_id: either make task_id nullable + CHECK (task_id IS NOT NULL OR direct_offer_id IS NOT NULL), or add CHECK and leave task_id as-is if schema allows one null.

## Backfill

- Existing direct_offers: SET currency = 'IQD' where null (if column added nullable first then set default); fee_rate_applied_bps already present, backfill only if any row has null (e.g. DEFAULT 1000).

## Rollback

- Do NOT drop new columns. To roll back feature: disable cron branch for direct_offers only; app revert; backend tolerates null delivered_at/review_expires_at and null payment_*.

## Compatibility window

- Old app may not set delivered_at/review_expires_at. Cron MUST only consider rows where review_expires_at IS NOT NULL so no auto-release for old-delivered rows until app updated.
