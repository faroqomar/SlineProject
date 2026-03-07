# 24_hardened_paymentLinking_system Folder Report

## 1. Diagram Title & Version

- **Exact Name:** hardened_paymentLinking_system
- **Version:** System Design Final
- **Author:** Unspecified

## 2. Global Problem & Scope

- **Problem Solved:** Prevents "free-floating" payments, identity spoofing, and lost payments when gateway callbacks occur during app crashes.
- **Scope Includes:** Gateway intent creation, webhook processing, `payment_intents` / `payment_events` tables, Orphan Payment quarantine.

## 3. Assumptions & Invariants

- **Assumptions:** The app may die mid-payment, so webhook is the _only_ finalization authority.
- **Invariants:** Rule 1: No client creates gateway intents. Rule 2: Payment mandates a `payment_intent_id`. Rule 3: Signed binding (HMAC) in gateway metadata. Rule 4: Gross and currency must match precisely.

## 4. Glossary

- `payment_intents`: The binding contract (pre-payment record state).
- `payment_events`: Raw gateway webhook appends.
- `orphan_payments`: Quarantine table for unmatched or invalid webhooks.

## 5. Actors & Permissions

- **Client App:** Taps "Pay".
- **Server App (BFF):** Creates intents and verifies webhooks.
- **Gateway:** Captures payment and fires webhook.

## 6. System Architecture Map

- **UI/App:** "Pay" buttons on checkout screens.
- **Backend:** Next.js / FastAPI functions (`create_payment_intent`, `finalize_payment_webhook`).
- **Database:** `payment_intents`, `payment_events`, `orphan_payments`.

## 7. Step-by-Step Flow (The "Golden Path")

1.  **Intent Creation:** Client taps Pay. Server validates entity ownership, status, computing gross. Inserts `payment_intents` row. Generates secure gateway intent.
2.  **Payment Processing:** Client pays at gateway.
3.  **Webhook Validation:** Gateway fires server webhook. Server inserts `payment_events`, validates metadata/signature.
4.  **Finalization:** Server updates `payment_intents` -> `succeeded`, calls `process_payment_event('escrow')`.
5.  **Quarantine (Alternative):** Mismatch/bad signature -> insert into `orphan_payments`.

## 8. Failure Modes & State Machine

- Client app crash -> Valid webhook still arrives and processes everything.
- Signature mismatch -> Routed to quarantine.
- `payment_intents` status: created -> gateway_created -> succeeded (or failed).

## 9. Data Model & RLS

- `payment_intents` (id, entity_type, payer_id, gross, fee_rate_locked, signature).
- `payment_events` (raw payload).

## 10. Security & Threat Model

- HMAC signature embeds critical binding fields into metadata so the gateway payload cannot be maliciously modified.

## 11. Verification & Observability

- `orphan_payments` alerts admins to investigate if fraudulent or broken payments occur.
- `vw_admin_entity_payment_trace` provides complete provenance.

## 12. Cross-Diagram Dependencies

- Calls RPC `process_payment_event('escrow')` from Diagram 21/09.
- Provides the exact data locking for fees defined in Diagram 22.

## 13. Open Questions & Blockers

- Marked as missing extraction verification ("To mark as VERIFIED, we need extraction of physical DB schema...").
- Does the `create_payment_intent` mechanism exist in reality (e.g., Supabase Edge Function) or is it fully conceptual at this moment?

## 14. Final Status

- **Verdict:** PARTIAL / UNVERIFIED (Excellent design, structurally unconfirmed in codebase).
- **Production Ready:** NO (Needs physical presence verification of `payment_intents`).
- **Next Actions:** Verify the presence of Edge functions and `payment_intents` table schema in the codebase.
