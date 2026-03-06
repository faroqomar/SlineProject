# Test Plan (High-Value Verification) - Hardened Payment System

**Skills applied**: Test Design (High-Value Tests), Idempotency & Concurrency, Threat Modeling (Security).

These tests focus on breaking the payment logic rather than basic happy-path validation.

## 1. Security & Tamper Testing

| Test ID     | Name                             | Method                                                                                                         | Expected Result                                                                                                         |
| ----------- | -------------------------------- | -------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| **T-SEC-1** | **Metadata Signature Tampering** | Construct a valid gateway webhook but modify the `entity_id` in metadata.                                      | Webhook handler detects HMAC mismatch against server secret; inserts record to `orphan_payments`; ledger NOT triggered. |
| **T-SEC-2** | **Direct Gateway Bypass**        | Attempt to hit the webhook endpoint with a `gateway_intent_id` that was never recorded in `payment_intents`.   | Webhook lookup fails; inserts record to `orphan_payments` with reason `intent_not_found`.                               |
| **T-SEC-3** | **Amount Mismatch**              | Mock a gateway callback where the currency amount is different from the intent amount (e.g., 100.00 vs 10.00). | Webhook handler compares `intent.gross` vs `event.amount`; inserts record to `orphan_payments`.                         |

## 2. Robustness & Race Condition Testing

| Test ID     | Name                      | Method                                                                                     | Expected Result                                                                                                                                          |
| ----------- | ------------------------- | ------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **T-ROB-1** | **Webhook Replay Attack** | Send the same `payment_succeeded` webhook payload 5 times in rapid succession.             | The first call succeeds (ledger triggered). Subsequent calls detect `payment_intents.status == 'succeeded'` and return 200 OK without double-processing. |
| **T-ROB-2** | **App Crash Recovery**    | 1. Initiate payment.<br/>2. Kill client app.<br/>3. Send mock gateway webhook.             | Database entity status updates to `active`; ledger reflects escrow; user sees "Paid" when app re-opens.                                                  |
| **T-ROB-3** | **Entity State Lock**     | Attempt to create a `payment_intent` for a booking that is already `active` or `canceled`. | BFF `SELECT ... FOR UPDATE` check fails; returns error; no intent created.                                                                               |

## 3. RLS & Permission Testing

| Test ID     | Name                        | Method                                                                                         | Expected Result                                                   |
| ----------- | --------------------------- | ---------------------------------------------------------------------------------------------- | ----------------------------------------------------------------- |
| **T-RLS-1** | **Payer Impersonation**     | Authenticate as User A and attempt to create a `payment_intent` for a booking owned by User B. | Database check `auth.uid() = client_id` fails; RPC returns error. |
| **T-RLS-2** | **Append-Only Enforcement** | Attempt to UPDATE a row in `payment_events`.                                                   | Postgres error: RLS/Trigger prevents UPDATE.                      |
