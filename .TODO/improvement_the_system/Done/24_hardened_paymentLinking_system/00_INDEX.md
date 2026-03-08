# 00_INDEX

## Skills Selection Protocol

- **Evidence-First Reading**: Used to anchor every claim to the source of truth, specifically `SUPABASE_SETUP.md`.
- **Threat Modeling (Security)**: Crucial for identifying gaps in webhook and payment intent trust boundaries.
- **Invariants & Contracts**: Essential for guaranteeing state validity across app crashes, network failures, or gateway manipulations.
- **Idempotency & Concurrency**: Required for auditing whether the ledger integration can handle replay attacks or race conditions gracefully.
- **DB-First Financial Modeling**: Critical for ensuring the new gateway intents mathematically align with the existing double-entry ledger logic (`process_payment_event_ledger`).

**Intentionally Not Used**:

- **Repo Mapping**: The focus of this specific sprint is the core architecture and DB layer orchestration; full repository traversal adds noise and distracts from the core ledger logic defined in `SUPABASE_SETUP.md`.
- **Observability (Logs/Alerts/Admin Trace)**: While necessary later, the core priority is establishing structural invariants first.

---

## Reviewed Files

1. **24_hardened_paymentLinking_system.md** -> **PARTIAL**
   - _Why_: The diagram's defensive concepts (preventing orphan payments, enforcing server-side intent) are excellent, but it references non-existent tables (`payment_intents`) and the legacy function (`process_payment_event`) instead of the v2.16 ledger integration.
2. **SUPABASE_SETUP.md** -> **PASS**
   - _Why_: Provides a strong double-entry foundation (`ledger_lines`). However, the "Hardened Payment Linking System" concepts are missing and need to be implemented on top of it.

---

## Blockers

- **Missing Tables**: `payment_intents`, `payment_events`, and `orphan_payments` definitions do not exist in the current Supabase schema.
- **Webhook Trust Gap**: No existing documentation or code snippet proves an HMAC/Signature verification flow exists before hitting the ledger RPC.

---

## Recommended Implementation Sequence (Dependency Order)

1. **Database Schema Additions**: Create `payment_intents`, `payment_events`, `orphan_payments` tables, Enums, and RLS policies.
2. **Ledger RPC Updates**: Modify `process_payment_event_ledger` to support a `p_payment_intent_id` foreign key.
3. **Backend (Edge/Next.js)**: Implement the Intent generation (HMAC signing) endpoint and the Webhook Handler (HMAC verification).
4. **App Integration**: Implement Supabase Realtime logic for checkout screens to transition states securely.
5. **Admin Flow**: Develop the `orphan_payments` investigation queue in the Next.js admin dashboard.
