# SLine Diagram Consistency Audit Index

This file acts as the master reference list for the entire comprehensive `SLine Diagram Consistency Audit` (Batch 1 through Batch 6). It tracks the overall progress, verdicts, identified blockers, and recommended safe execution sequences.

## 1) Execution Order (Safe Path for Changes)

Before addressing UI flows or application-side logic, foundational security and schema definitions MUST be resolved in this exact dependency order to prevent cascade failures.

1.  **Drop Critical RLS Vulnerabilities** (Diagram 15): Drop `public.users` view immediately to patch PII leakage limit views to `SECURITY INVOKER`.
2.  **Harmonize Ledger Invariants** (Diagrams 09, 16, 21, 22): Update `idempotency_key` logic to remove `now()`, integrate `platform_settings` table, and unify ledger calculation methods across all financial pathways.
3.  **Harden The Payment Orchestration Gate** (Diagram 24): Roll out `payment_intents`, `payment_events`, and `orphan_payments`. Route the edge handlers purely through this pipeline.
4.  **Strengthen Base Contracts & State Machines** (Diagrams 03, 04, 05, 14, 19, 20): Lock in enum transitions, enforce Escrow holds strictly before work is allowed, and deploy the `disputes_guard` locks.
5.  **Refactor Core Views for UI Scaling** (Diagram 12): Apply UNION updates to `vw_unified_work_items` to natively support Direct Offers without client side stitching.
6.  **Fix Feature Logic Holes & Triggers** (Diagrams 01, 07, 10, 11): Apply the revisions limit directly in PostgreSQL triggers, protect against spam constraints, fix Auth webhook race-conditions.
7.  **Overhaul WebSockets & Storage** (Diagrams 08, 13, 17, 18): Rebuild signed URL logic via local timed caching, remove explicit `conversations` real-time `.stream()` logic, redirect inbox feeds via `messages`, and formulate push fallback triggers.

---

## 2) Master Diagram Registry

| Diagram ID | Diagram Name                    | Current Score / Verdict | Critical Blockers Identified                                   |
| :--------- | :------------------------------ | :---------------------- | :------------------------------------------------------------- |
| `01`       | Auth Profile Provisioning       | 10/10 PASS              | Race Condition in Signup JWT propagation.                      |
| `02`       | Role Switching Flow             | 9/10 PASS               | None.                                                          |
| `03`       | Tender Task Lifecycle           | 9/10 PASS               | Task states rely on missing automated expirations for non-pay. |
| `04`       | Task Request Bid Flow           | 9/10 PASS               | None.                                                          |
| `05`       | Booking Lifecycle               | 9/10 PASS               | Booking squats lock availability indefinitely.                 |
| `06`       | Direct Chat Offer Flow          | 9/10 PASS               | Ledger integrations missing for Direct Offers.                 |
| `07`       | Chat Creation Matrix            | 10/10 PASS              | `INSERT` needs RPC wrapping to prevent parallel conversation.  |
| `08`       | Chat Realtime Sync              | 9/10 PASS               | Presence streams need DB 15s TTL.                              |
| `09`       | Ledger Event Flow               | 9.5/10 PASS             | Need exact `p_idempotency` bindings everywhere.                |
| `10`       | Work Contract Revisions         | 9/10 PASS               | Revision caps need Database side transaction logic.            |
| `11`       | Availability Overlap Guard      | 9/10 PASS               | 0% Dart Client Coverage mapping.                               |
| `12`       | Unified Work View               | 10/10 PASS              | Needs Direct Offers and Disputes `UNION ALL` injections.       |
| `13`       | Notification Routing            | 9/10 PASS               | Needs Push (FCM/APN) async architecture for offline users.     |
| `14`       | Dispute Lifecycle               | 9/10 PASS               | Race condition vs Ledger Approval without table locks.         |
| `15`       | RLS Authorization Map           | 9.5/10 PASS             | **CRITICAL**: `public.users` view exposed globally.            |
| `16`       | Escrow Invariants & Idempotency | 10/10 PASS              | **CRITICAL**: Using `now()` in ID generation breaks retries.   |
| `17`       | Storage Signed URLs Flow        | 9.5/10 PASS             | Guessable paths / High API costs without localized caching.    |
| `18`       | Realtime Subscription Topology  | 9/10 PASS               | **CRITICAL**: N+1 stream handling in Dart on `conversations`.  |
| `19`       | Direct Offers Work Contract     | 9/10 PASS               | Incomplete mapping of `fn_direct_offer_guard`.                 |
| `20`       | Withdrawals Lifecycle           | 9.5/10 PASS             | **CRITICAL**: Cancellation failed to return Ledger Funds.      |
| `21`       | Wallet System Balances          | 10/10 PASS              | Legacy `wallet_transactions` tables failing to freeze.         |
| `22`       | Dynamic Platform Fee            | 10/10 PASS              | Ledger reads generic rate. Needs `platform_settings` table.    |
| `23`       | Admin Dashboard Wallet Finance  | 9/10 PASS               | Views leak data unless locked strictly to `service_role`.      |
| `24`       | Hardened Payment Linking System | 10/10 PASS              | Payer webhook mapping missing HMAC signatures.                 |

---

## 3) Stop-Ship Production Blockers 🚨

The following structural flaws **MUST** be patched in code before the application is permitted to handle real banking transactions:

1.  **RLS Vulnerability (`public.users`)**: The View exposes sensitive PII and circumvents Row-Level privacy entirely.
2.  **Idempotency Flaw (`now()` in RPC hashes)**: The Ledger generated unique hashes on every retry utilizing the current timestamp, actively failing to catch duplicated user requests.
3.  **Realtime Starvation Payload (N+1)**: Unbounded relationships mapped to `.asyncMap` on the Flutter Realtime socket listener inside `message_service.dart`.
4.  **Withdrawal Orphan Risk**: If a user cancels a withdrawal, the DB status flips but the double-entry Ledger does not refund their available balance, trapping cash.
5.  **Dynamic Fee Bypass**: Failure to lock the `fee_rate_bps` on Escrow creation fundamentally means Admins can raise rates manually and retroactively steal funds from already-completed freelancing work.
