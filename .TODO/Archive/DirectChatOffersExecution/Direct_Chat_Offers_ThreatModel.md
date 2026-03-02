# Direct Chat Offers – Threat Model (Phase 0.2)

## Assets

- Direct offer rows (price, client/freelancer identity).
- Escrow funds (client balance → platform_escrow when accepting).

## Threats & Mitigations

| Threat | Mitigation |
|--------|------------|
| Non-participant reads/updates offer | RLS: SELECT/UPDATE only for client_id or freelancer_id = auth.uid(). |
| Client accepts without paying | Guard: escrow_hold must succeed before status → active; trigger blocks status change without payment_status = held. |
| Freelancer marks delivered before active | Guard trigger: allow delivered only when status = active. |
| Client releases before delivered | RPC: release_with_fee only when status = delivered and payment_status = held. |
| Double escrow / replay | Idempotency key on process_payment_event_ledger; unique constraint on journal_entries.idempotency_key. |
| Non-freelancer creates offer | RLS INSERT: freelancer_id = auth.uid() and conversation participant. |
| Non-client accepts | RPC: only client_id can call escrow_hold for direct_offer. |

## Negative tests (Phase 4)

- User A cannot SELECT/UPDATE direct_offer where A is not client or freelancer.
- Client cannot set status to active without payment_status = held (trigger).
- release_with_fee for direct_offer fails when status != delivered or payment_status != held.
