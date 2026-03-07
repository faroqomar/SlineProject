# SYSTEM CRITIC VERDICT: Ledger Event Flow (09_ledger-event-flow)

**Verdict:** ✅ NO CHANGES REQUIRED

## A) Compare OLD vs NEW

**Differences (Behavioral & Architectural):**

1. **Trigger Scope**: OLD only modeled internal escrow/release. NEW correctly models asynchronous entry `gateway_escrow` (QiCard Webhook) and exit `withdrawal_request`.
2. **Idempotency Contract**: OLD implied synchronous unstructured calls. NEW enforces UUIDv5 deterministic key generation in the client before striking the ledger, neutralizing replay attacks.
3. **Gate Validation Routing**: OLD routed directly to the ledger. NEW routes through a `Gate Validation` node verifying entity status (`pending`/`unpaid` etc.) before allowing writes.
4. **Concurrency Locking**: OLD did not account for race conditions. NEW acknowledges atomic constraints (implemented in DB via `SELECT FOR UPDATE` on the entity row immediately inside the RPC).
5. **Double-Entry Verification**: NEW explicitly models the `Sum == 0` constraint node before commit. OLD missed this DB-level invariant check.
6. **Transaction Scope**: NEW defines explicit `Success -> Committed` and `Fail -> Rollback` branches representing the single atomic boundary of the RPC.
7. **Conditional Revenue**: OLD credited platform fee blindly. NEW enforces a conditional `if fee > 0` branch, solving the constraint violation for zero-fee tasks.
8. **Withdrawal Accounts**: NEW correctly maps the `user_pending_withdrawal` liability account during cash-out requests, preventing user balance from inflating.
9. **Meta Logging**: NEW explicitly incorporates `p_meta` context passing (for dispute forensics), which OLD ignored.
10. **Auth Boundary**: NEW models an explicit Auth/RLS check, whereas OLD assumed the caller was inherently trusted.

**Scores:**

- **OLD System (Diagram V1)**: Correctness 5, Security 4, Concurrency 2, Observability 4, Scalability 5. _(Total: 20/50)_
- **NEW System (Final)**: Correctness 10, Security 10, Concurrency 10, Observability 9, Scalability 9. _(Total: 48/50)_

## B) Verification of Critical Invariants

1. **Balanced journal (sum == 0)**: Verified. Found in the RPC implementation and reinforced by DB constraints (`ck_unbalanced_journal` logic). The RPC explicitly writes complementary DR/CR pairs.
2. **Amount > 0 constraint**: Verified. `SUPABASE_SETUP.md:1917` proves `ck_ledger_lines_amount_positive` is enforced. Migration `20260308` handles zero-fee scenarios so they don't break this constraint.
3. **Idempotency uniqueness strategy**: Verified. `LedgerService.dart:13-19` uses `UUID.v5` spanning the `entity_id` and `event_type`. This is deterministic and universally safe for these 1:1 state transitions. Duplicate calls safely hit the `uq_journal_entries` unique constraint and replay the result instead of crashing.
4. **Entity status gates + locking order**: Verified. Located `SELECT ... FOR UPDATE` precisely at line 129 in `20260225_create_process_payment_event_ledger_rpc.sql`. The entity is locked before any checks or balances are struck, perfectly guarding against cancel-vs-release races.
5. **Atomic orchestration**: Verified. The entity status (`UPDATE bookings SET payment_status = ...`) and the journal/ledger inserts all happen synchronously inside `process_payment_event_ledger`, ensuring atomicity. No two-phase commit risk remains for core flows.
6. **RLS denies direct writes**: Verified. `SUPABASE_SETUP.md:1435` and migration `20260225_create_ledger_rls_policies.sql` confirm the ledger tables are system-only. Public inserts are denied, clients MUST use the `SECURITY DEFINER` RPC.

## C) Blockers & Patch Plan

_(Not applicable. All critical invariants are demonstrably enforced in the codebase and DB migrations.)_

**Verification Checklist (Pre-Flight):**

- [x] Concurrency locking (`SELECT FOR UPDATE`) confirmed in active migration files.
- [x] Zero-fee release crash fix (`20260308`) confirmed applied.
- [x] RLS boundaries confirmed tight against rogue client inserts.
- [x] Real-world webhooks (QiCard `gateway_escrow`) safely wrapped by the same idempotency logic.

**NO CHANGES REQUIRED.** The system design depicted in `06_DIAGRAM_FINAL.md` accurately reflects a hardened, production-grade financial architecture.
