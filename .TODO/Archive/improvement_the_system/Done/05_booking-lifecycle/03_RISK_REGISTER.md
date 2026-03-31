# Risk Register: Booking Lifecycle

## Skills Selected

- **Evidence-First Reading**: Verification of current state
- **State Machine & Lifecycle**: Logical flow analysis
- **Idempotency & Concurrency**: Race condition evaluation
- **DB-First Financial Modeling**: Escrow and refund flows
- **Diagram Crafting (Mermaid)**: Visual communication

## J1) Risks if we keep the current system (Diagram/Logic gaps)

| Risk                      | Severity | Likelihood | Impact                                                                             | Evidence                                                                                            |
| :------------------------ | :------- | :--------- | :--------------------------------------------------------------------------------- | :-------------------------------------------------------------------------------------------------- |
| **No-Show Exploitation**  | High     | Medium     | Provider gets paid for not showing up if client forgets to dispute.                | `BookingStatus.noShow` is in enum but not in lifecycle constraints.                                 |
| **Auto-Approval Bypass**  | Medium   | High       | Providers wait indefinitely for payment if clients abandon the app after delivery. | Diagram lacks `review_expires_at` cron transition; if not implemented, funds are trapped in escrow. |
| **Griefing Cancelation**  | High     | Low        | Client cancels immediately after delivery to trigger an automatic refund bypass.   | Diagram shows `delivered -> canceled: Client Cancels`. This is dangerous without a dispute gate.    |
| **Slot Overbooking Race** | High     | Medium     | Two clients pay for the same `pending` slot simultaneously.                        | Both reach `paid_request_pending`. Provider accepts one; the other must be gracefully refunded.     |

## J2) Risks introduced by improvements

| Risk                            | Mitigation                                                                                                                              |
| :------------------------------ | :-------------------------------------------------------------------------------------------------------------------------------------- |
| **Complexity in Dispute Logic** | Introduce a clear `disputed` state that freezes funds and escalates to admin, rather than an automatic refund.                          |
| **Cron Job Failures**           | Ensure the idempotency key for the cron job processing `review_expires_at` prevents double-charging or double-releasing funds.          |
| **Migration Overload**          | Phase the deployment: handle `no_show` and `disputed` as minor status additions before rewriting the strict `fn_booking_guard` trigger. |
