# Gaps & Fixes - Hardened Payment Linking System

**Skills applied**: Threat Modeling (Security), Invariants & Contracts, Idempotency & Concurrency.

## 1. Structural Gaps

### G1: Missing Persistence for Payment Intent

- **Gap**: Diag 24 relies on a `payment_intents` table to bind entities ([Diag 24:L99](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/AppDigram/All_Diagrams/24_hardened_paymentLinking_system.md#L99)), but this table does not exist in the current schema.
- **Risk**: Without this table, the platform cannot "pre-authorize" a specific payment amount/fee, leading to potential price-tampering at the gateway (if parameters are client-side).
- **Fix**: Part of the implementation plan must include creating `payment_intents`.

### G2: Absence of Signature Verification in Webhooks

- **Gap**: Current `qicard_webhook_handler` ("must reject unsigned payloads" - [SUPABASE_SETUP.md:L1452](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/SUPABASE_SETUP.md#L1452)) logic is not detailed. Standard webhook verification is entry-level; the "Hardened" design requires a **double-check**:
  1. Gateway signature (authenticity).
  2. Internal metadata signature (binding integrity).
- **Fix**: The webhook must use a `server_secret` to verify the `signature` field in the metadata before calling the ledger.

### G3: Ledger Sync (BFF <-> DB)

- **Gap**: Diag 24 shows the Server (API) creating the intent, then the Webhook finalizing it. If the Ledger RPC is called by the Webhook, it needs to ensure the `payment_intent_id` is linked to the `journal_entry` for full auditability.
- **Fix**: Add `related_payment_intent_id` (uuid) to `journal_entries` table.

## 2. Process Gaps

### G4: Result Polling / App Crash Recovery

- **Gap**: Diag 24 correctly states "Webhook only finalization" ([Rule 5](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/AppDigram/All_Diagrams/24_hardened_paymentLinking_system.md#L179)). However, the UI needs a way to know the webhook succeeded.
- **Fix**: Use Supabase Realtime to subscribe to `payment_intents` status changes or the specific entity's `payment_status`.

### G5: Orphan Reconciliation

- **Gap**: There is no defined process for "Manual Review" mentioned in [Diag 24:L130](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/AppDigram/All_Diagrams/24_hardened_paymentLinking_system.md#L130).
- **Fix**: Redesign the Admin Dashboard to include an "Actionable Orphan Queue".
