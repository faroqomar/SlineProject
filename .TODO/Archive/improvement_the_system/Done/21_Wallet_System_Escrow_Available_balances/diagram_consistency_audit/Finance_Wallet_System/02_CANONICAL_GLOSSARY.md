# 02 CANONICAL GLOSSARY

This establishes the frozen, non-negotiable terminology for the SLine platform architecture moving forward. Any deviation from these terms in code, UI, or DB schema must be corrected.

## Core Entities

| Term                   | Definition                                                                                             | DB Target               |
| ---------------------- | ------------------------------------------------------------------------------------------------------ | ----------------------- |
| **Booking**            | A client-scheduled work session initiated directly from a Freelancer's service listing.                | `bookings`              |
| **Task / Tender**      | A public job post created by a Client looking for Freelancers to place bids.                           | `tasks`                 |
| **Task Request (Bid)** | A proposal submitted by a Freelancer on a public Tender/Task.                                          | `task_requests`         |
| **Direct Offer**       | A scoped work agreement initiated via direct chat bypassing public tenders.                            | `direct_offers`         |
| **Unified Work Item**  | The consolidated abstraction layer that merges Bookings, Tasks, and Direct Offers for UI presentation. | `vw_unified_work_items` |

## Financial & Escrow Terms

| Term             | Definition                                                                                                   | DB Target                     |
| ---------------- | ------------------------------------------------------------------------------------------------------------ | ----------------------------- |
| **Escrow**       | Funds reserved and locked in connection with an active job. Neither Client nor Freelancer can withdraw them. | `accounts` (Escrow Liability) |
| **Gross Amount** | The total amount paid by the Client upfront.                                                                 | `gross_amount`                |
| **Platform Fee** | The commission taken by the SLine platform for facilitating the transaction.                                 | `fee_amount`                  |
| **Net Amount**   | The final payout available to the Freelancer (`Gross Amount - Platform Fee`).                                | `net_amount`                  |
| **Fee Rate**     | The percentage basis-points config captured at the moment of Escrow Hold.                                    | `fee_rate_applied_bps`        |

## Payment Event Types (`payment_event_type_enum`)

| Event                  | Action Performed                                                      |
| ---------------------- | --------------------------------------------------------------------- |
| **escrow_hold**        | Drains Client Available Balance, Mints Escrow.                        |
| **release_with_fee**   | Drains Escrow, Mints Freelancer Available Balance & Platform Revenue. |
| **refund**             | Drains Escrow, returns Gross Amount to Client Available Balance.      |
| **withdrawal_request** | Locks available funds into a pending hold until gateway clears.       |

## Double-Entry Ledger Components

| Term              | Definition                                                                                            | DB Target         |
| ----------------- | ----------------------------------------------------------------------------------------------------- | ----------------- |
| **Journal Entry** | A single financial event transaction grouping multiple ledger lines. Holds the idempotency key.       | `journal_entries` |
| **Ledger Line**   | The actual Debit or Credit movement specifying an account and an amount.                              | `ledger_lines`    |
| **Account**       | Sub-ledgers for entity state (e.g., User Available, User Pending, Platform Escrow, Platform Revenue). | `accounts`        |

## Unified Statuses (`booking_status_enum` / Unified Mapping)

- `pending`: Awaiting acceptance (Task/Tender only).
- `paid_request_pending`: Escrow funded, awaiting Freelancer acceptance.
- `active`: In progress.
- `delivered`: Work submitted, awaiting Client approval.
- `completed`: Approved, Escrow released.
- `canceled`: Canceled, Escrow refunded.
- `disputed`: Held in mediation.
