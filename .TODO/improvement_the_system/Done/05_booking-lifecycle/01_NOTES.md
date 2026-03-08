# Booking Lifecycle Audit Notes

## Skills Selected:

- **Evidence-First Reading**: To read the diagram and app code to verify the current state
- **State Machine & Lifecycle**: To analyze the booking state transitions.
- **Idempotency & Concurrency**: To evaluate race conditions like double bookings on the same slot.
- **DB-First Financial Modeling**: To analyze the payment transition logic and escrow.
- **Diagram Crafting (Mermaid)**: To output the final optimized diagram.

## Unused Skills:

- _Repo Mapping_: The files are well identified already.
- _Threat Modeling (Security)_: Partially used for race conditions, but focus is more on logic/lifecycle.
- _Invariants & Contracts_: Included in State Machine & Lifecycle.
- _Production Migration Planning_: No schema changes identified yet.

## Initial Observations from Diagram:

- Transitions:
  - pending -> paid_request_pending (Client pays)
  - pending -> canceled (Client cancels)
  - paid_request_pending -> active (Provider accepts)
  - paid_request_pending -> refunded (Provider declines)
  - paid_request_pending -> expired_unanswered (Cron expiry)
  - active -> delivered (Provider submits work)
  - active -> canceled (Client/Provider cancels, triggers refund)
  - delivered -> completed (Client approves)
  - delivered -> canceled (Client cancels)

## Questions/Gaps:

- Can a provider accept multiple bookings for the same slot before they overlap? (Slot overlap prevention).
- When a booking expires unanswered, does the client get automatically refunded? The diagram says `expired_unanswered -> [*]` but doesn't mention the refund explicitly like `declined (refunded)`.
- Can a client cancel an `active` or `delivered` booking without a dispute process? The diagram says "Canceled (Either / Refunds rules apply)" from `active`. But from `delivered` it just says "Client Cancels -> canceled". That's a huge risk if a client can just cancel _after_ delivery to get an automatic refund.
- What if the provider never delivers? Is there an `expired_undelivered` state?
