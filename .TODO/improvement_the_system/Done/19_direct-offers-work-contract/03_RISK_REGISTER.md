# Risk Register: Direct Offers Work Contract

## J1) Risks if we keep the current system

| Risk                        | Severity | Likelihood | Impact                                                                                             | Evidence                                                                                              |
| :-------------------------- | :------- | :--------- | :------------------------------------------------------------------------------------------------- | :---------------------------------------------------------------------------------------------------- |
| **Silent Delivery Failure** | High     | Medium     | Client pays but status doesn't update, leading to stuck funds.                                     | `rpc_approve_delivery` fails for direct_offer; depends on client-side Ledger call.                    |
| **Unauthorized Delivery**   | High     | Low        | Non-freelancer marks work as delivered.                                                            | `fn_direct_offer_guard` enforces `auth.uid() = freelancer_id`, but client-side logic must also check. |
| **Double Release**          | Med      | Low        | Ledger release triggered twice for the same offer.                                                 | `process_payment_event_ledger` uses idempotency keys, but `direct_offer` path needs validation.       |
| **State Mismatch**          | Med      | Medium     | Offer status is `delivered` but `payment_status` is `unpaid` (if accept-without-payment was used). | `fn_direct_offer_guard` allows `sent -> accepted (unpaid)` but prevents `active` without `held`.      |

## J2) Risks introduced by improvements

| Risk                 | Severity | Likelihood | Impact                                        | Mitigation                                                                  |
| :------------------- | :------- | :--------- | :-------------------------------------------- | :-------------------------------------------------------------------------- |
| **Migration Drift**  | Low      | Low        | New RLS/triggers conflict with existing data. | Use `SECURITY DEFINER` and thorough testing on staging.                     |
| **Logic Complexity** | Med      | Medium     | More guards make the system harder to debug.  | Clear logging via `WorkLogService` as seen in `direct_offers_service.dart`. |
| **Admin Bypass**     | Med      | Low        | Admin tools bypass lifecycle guards.          | Ensure triggers are `BEFORE UPDATE` and not bypassable by non-superusers.   |
