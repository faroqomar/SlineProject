# 03_RISK_REGISTER

## J1) Risks If We Keep the Current System

### 1. Permanent Escrow Lock (AFK Client Risk)

- **Severity**: CRITICAL
- **Likelihood**: High
- **Impact**: Freelancers do the work, mark it delivered, and never get paid because the client abandons the app.
- **Evidence**: The `direct_offers` table schema (`SUPABASE_SETUP.md` line 669) lacks `delivered_at` or `review_expires_at` columns. Standard tasks and bookings use these for an automated 3-day approval release. Direct offers have no such mechanism, pinning the payment to permanent escrow hold until the client manually releases it.

### 2. Missing Active Offer Cancellation / Refund Flow

- **Severity**: HIGH
- **Likelihood**: Medium
- **Impact**: If a client pays for an offer (`active` status) and the freelancer ghosts them or they mutually agree to cancel, there is no UI workflow or service method to execute a refund.
- **Evidence**: `lib/features/direct_offers/services/direct_offers_service.dart` only provides `cancelAcceptedOffer` (restricted to `accepted` status and `unpaid` payment_status). There is no `cancelActiveOffer` or dispute initiation from the service layer specifically bound to direct offers.

### 3. Freelancer Sent Offer Lock

- **Severity**: LOW
- **Likelihood**: Low
- **Impact**: It is handled via logic, but visually the diagram misses the freelancer's right to cancel a sent offer before the client accepts it.
- **Evidence**: The diagram only shows Client rejecting or accepting. However, `cancelOffer` exists in the Dart service for freelancers.

## J2) Risks Introduced by Improvements

### 1. Auto-Release Cron & Schema Migration

- **Risk**: Adding `review_expires_at` and `delivered_at` to `direct_offers` requires a schema migration and an update to the cron job that automatically releases funds.
- **Mitigation**: Standardize `direct_offers` with `bookings` by using the same expiration logic, and thoroughly test the pg_cron trigger `fn_check_expired_reviews`.

### 2. Resolution/Refund Authority

- **Risk**: Adding cancellation for `active` offers in a direct chat could lead to accidental refunds or abuse (e.g., client canceling after delivery but before approval).
- **Mitigation**: Implement a dual-consent cancellation for active offers (mutual cancellation) or force `active` cancellations to require admin intervention via the `disputes` system. Do NOT let clients unilaterally cancel an `active` offer.
