# Risk Register: Dynamic Platform Fee

## J1) Risks if we keep the current system

| Risk                     | Severity | Likelihood | Impact                                                     | Evidence                                                    |
| ------------------------ | -------- | ---------- | ---------------------------------------------------------- | ----------------------------------------------------------- |
| **Financial Drift**      | High     | Medium     | Revenue won't match agreements.                            | RPC defaults to 1000 bps regardless of dashboard changes.   |
| **Audit Failure**        | Medium   | High       | Cannot explain to a user _why_ a specific fee was charged. | No record of applied fee rate on the booking object.        |
| **Client Spoofing**      | High     | Low        | Clients bypassing fees by sending custom meta.             | `process_payment_event_ledger` reads fee bps from `p_meta`. |
| **Schema Inconsistency** | Low      | High       | Developer confusion leading to bugs.                       | RPC uses `amount_gross` while table uses `price`.           |

## J2) Risks introduced by improvements

| Risk                    | Complexity | Mitigation                                                                                 |
| ----------------------- | ---------- | ------------------------------------------------------------------------------------------ |
| **Migration Downtime**  | Low        | Standard schema migration (ADD COLUMN) is non-blocking in Postgres.                        |
| **Legacy Data**         | Medium     | Backfill existing bookings with the current default (10%) to maintain invariants.          |
| **RPC Breaking Change** | Low        | Keep `p_meta` support for admin overrides but prioritize entity's locked rate for clients. |
