# CROSS-DIAGRAM HOLISTIC REPORT: SLine System Alignment

## Executive Summary

This report analyzes the consolidated flow of 24 distinct sub-systems dictating SLine's marketplace model. Through rigorous "Zero-Trust" analysis against Ledger structures, Row Level Security, and Postgres Triggers, the audit confirms that SLine's foundation is architecturally robust (Double-Entry Ledger, Idempotency patterns) but previously exhibited catastrophic implementation weaknesses (time-variable hashes, `public.users` exposure, and withdrawal fund trapping).

This Master Document is the canonical dictionary and guide for aligning the Data Model, Engineering Constraints, and Security Posture for production readiness.

---

## 1. Conflict Truth Matrix & Canonical Dictionary

Throughout the 24 diagrams, severe Naming and Logic drifts were caught. The following establishes the canonical truth to which all SQL, Dart, and Admin code MUST adhere.

| Component / Layer       | Common Hallucination (Drift)         | Canonical Truth (SLine Production Standard)           | Note                                                        |
| :---------------------- | :----------------------------------- | :---------------------------------------------------- | :---------------------------------------------------------- | ------------------ | ------------------------------------------------------- |
| **Financial API**       | `process_payment_event`              | `process_payment_event_ledger`                        | Legacy vs V2.16                                             |
| **Legacy Wallet Table** | `wallet_transactions`                | `ledger_lines`, `journal_entries`                     | Legacy table strictly frozen.                               |
| **Escrow States**       | `paid`, `funded`, `pending`          | `payment_status` = `'unpaid'`, `'held'`, `'released'` | Exact enum mapping explicitly checked by Guards.            |
| **Idempotency Keys**    | Server created `Uuid.v4()` + `now()` | `digest(entity_id                                     |                                                             | status, 'sha256')` | Time-variables break multi-retry limits on connections. |
| **Global Fee Configs**  | Passed by Flutter UI `meta`          | `public.platform_settings.fee_rate_default`           | UI values explicitly discarded to prevent Hacker kickbacks. |
| **Realtime Inbox**      | `subscribeToConversations()`         | `subscribeToMessages(receiver_id=auth.uid)`           | Dart Code triggered dangerous N+1 memory bombs.             |
| **Withdrawal States**   | Cancelling rewrites the DB status    | Cancelling executes `withdrawal_cancel` Ledger entry  | Deletion without DB ledger reversals trapped money.         |
| **Platform Revenue**    | "The 10% Platform Cut"               | Snapshotted `fee_rate_applied` at exactly checkout.   | Global rates changing retroactively ruins contracts.        |

---

## 2. Integrated "Golden Path" Lifecycle (System Alignment)

A single "Golden Path" task flow correctly touches over 11 distinct diagrams sequentially. Understanding this dependency map prevents isolated feature breakdowns.

1. **[Diag 01] Registration**: User A registers. Trigger Provisions `public.profiles`.
2. **[Diag 07] DM Context**: Client A favorites Freelancer B.
3. **[Diag 19] Offer Context**: Client A starts context and sends an unpaid `direct_offer`.
4. **[Diag 24] Guarding**: App locks checkout intent. Server signs intent. Payload sent to Gateway.
5. **[Diag 22] Fee Extraction**: Snapshot `fee_rate_bps` globally and freeze against the checkout payload.
6. **[Diag 09/21] Ingress Ledger**: Webhook hits intent endpoint. Triggers Ledger. Moves Client cash into `platform_escrow`.
7. **[Diag 18/13] Notification**: Realtime pushes alert. Push (FCM) acts as fallback if device is sleeping.
8. **[Diag 14] Arbitration Guard (Alt)**: Freelancer delivers. Client disputes. System locks the workflow natively using `dispute_status` table triggers locking the task target.
9. **[Diag 16] Egress Ledger**: Client clicks "Approve". `FOR UPDATE` serializes the payload. Ledger debits `platform_escrow` -> credits `freelancer_available_account` AND `platform_revenue_account`.
10. **[Diag 20] Capital Flight**: Freelancer executes `Withdrawal`. Admin flags the transaction `processing` ensuring no app-side cancellation reversals. Ledger outputs final cache wire update.

---

## 3. High-Leverage Upgrades (Recommended Patch Sequence)

This is NOT the architectural sequence list (which exists in `00_INDEX.md`). This outlines the targeted implementation sprint.

### Sprint A: The "Bleed Arresters" (Security & Money Locks)

- [ ] Drop `public.users` from all deployments immediately. Ensure Flutter references `rpc` summaries.
- [ ] Delete `now()` inputs generating idempotency keys. Write stable entity hashing.
- [ ] Implement `withdrawal_cancel` matching symmetric event within `process_payment_event_ledger`.
- [ ] Rewrite flutter stream connection `message_service.dart:352`. Convert strictly to explicit `.eq` filters utilizing Denormalized relationships.

### Sprint B: Defensive Fortifications (Gateways & Enums)

- [ ] Centralize `payment_intents` + `HMAC` signatures. Remove any trace of the application trusting client-provided pricing metrics to pass on checkout.
- [ ] Rollout `platform_settings` table and force the Ledger to read `fee_rate_applied` configurations strictly from the PG environment, completely blocking overriding headers.
- [ ] Introduce the Disputes Lock-Out PostgREST Trigger protecting Tasks from accidental client completions.
- [ ] Standardize the Universal Work View SQL (`vw_unified_work_items`) integrating a `UNION ALL` spanning `Direct Offers` for holistic dashboards.

### Sprint C: Polishing (Push & Storage Scale)

- [ ] Design and map Local storage Caches mapping signed URL blobs to their exact path matching.
- [ ] Finalize standard webhook integrations pointing into FCM/APNs targeting `private_upsert_notification` inserts.

---

## Final Concluding Thoughts

The SLine underlying database logic is architecturally beautiful. By adopting a strict Double-Entry ledger that never records a transaction unless it sums identically to $0.00, SLine is far more rigorous than most competing marketplace platforms.

The danger currently existing within SLine entirely revolves around UI applications skipping intermediate guardrails, failing to cache queries, or passing untrusted time variables down to the trusted environment. By strictly tightening the API and Edge Function layers, SLine is fully capable of launching into Production.
