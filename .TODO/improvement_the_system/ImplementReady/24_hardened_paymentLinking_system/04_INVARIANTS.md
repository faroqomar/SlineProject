# Invariants & Contracts - Hardened Payment Linking System

**Skills applied**: Invariants & Contracts, DB-First Financial Modeling.

## 1. Data Invariants (Must always be true)

| Invariant ID | Definition                                                                                                                     | Evidence/Location                                                                                                                                      |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **INV-1**    | Every `payment_intent` must be uniquely bound to an `entity_id` and `entity_type`.                                             | [Diag 24:L10](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/AppDigram/All_Diagrams/24_hardened_paymentLinking_system.md#L10)   |
| **INV-2**    | A `payment_intent` status can only transition forward: `created` -> `gateway_created` -> `succeeded` (or `canceled`/`failed`). | [Diag 24:L122](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/AppDigram/All_Diagrams/24_hardened_paymentLinking_system.md#L122) |
| **INV-3**    | The `gross_amount` and `currency` in the `payment_intent` must exactly match the gateway event payload.                        | [Diag 24:L175](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/AppDigram/All_Diagrams/24_hardened_paymentLinking_system.md#L175) |
| **INV-4**    | Every `ledger_line` generated from a payment must reference the `payment_intent_id` (via `journal_entries.related_entity_id`). | Derived from [SUPABASE_SETUP.md:L1437](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/SUPABASE_SETUP.md#L1437)                  |

## 2. Process Contracts (System guarantees)

### C1: Server-Side Intent Creation

- Only the server (Next.js/FastAPI) can create a `payment_intent`.
- RLS Policy: `payment_intents` INSERT is forbidden for all roles except service_role.

### C2: Webhook Idempotency

- The same `gateway_intent_id` must never trigger two `journal_entries`.
- Constraint: `journal_entries.idempotency_key` must include the `gateway_intent_id` or `payment_intent_id`.

### C3: Signature Check

- The `signature` stored in `payment_intent` must be re-verified during the webhook using the `metadata` returned by the gateway.
- Logic: `HMAC(key, metadata_fields) == signature`.

### C4: Append-Only Events

- `payment_events` are immutable. Once written, they can never be modified or deleted, ensuring a permanent audit trail.
- RLS Policy: `payment_events` UPDATE/DELETE set to `false`.
