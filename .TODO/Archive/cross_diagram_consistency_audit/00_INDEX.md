# 00_INDEX: Cross-Diagram Consistency Audit

**Auditor**: SLine Cross-Diagram Consistency Auditor
**Date**: 2026-03-06
**Folders Scanned**: 24 / 24

---

## Folder Status Summary

| #   | Folder                         | Path                  | Status     | Key Issue                                                                  |
| --- | ------------------------------ | --------------------- | ---------- | -------------------------------------------------------------------------- |
| 01  | auth-profile-provisioning      | `ImplementReady/01_*` | ✅ PASS    | Minor: cron for orphan sweep not wired                                     |
| 02  | role-switching-flow            | `ImplementReady/02_*` | ⚠️ PARTIAL | `switch_active_role` RPC + JWT hooks not yet implemented                   |
| 03  | tender-task-lifecycle          | `ImplementReady/03_*` | ⚠️ PARTIAL | Missing `delivered`/`review_phase` sub-states in DB enum                   |
| 04  | task-request-bid-flow          | `ImplementReady/04_*` | ⚠️ PARTIAL | Optimistic concurrency on `accept_task_request` missing                    |
| 05  | booking-lifecycle              | `ImplementReady/05_*` | ⚠️ PARTIAL | `no_show` + `disputed` missing from DB enum; `fn_booking_guard` incomplete |
| 06  | direct-chat-offer-flow         | `ImplementReady/06_*` | ⚠️ PARTIAL | Missing `review_expires_at` + `delivered_at` on `direct_offers`            |
| 07  | chat-creation-matrix           | `ImplementReady/07_*` | ✅ PASS    | RPC migration to `start_direct_conversation_v1` pending                    |
| 08  | chat-realtime-sync             | `ImplementReady/08_*` | ⚠️ PARTIAL | Presence `TODO` in code; Dual-tick receipts unbuilt                        |
| 09  | ledger-event-flow              | `ImplementReady/09_*` | ✅ PASS    | Structurally sound; minor logging gap                                      |
| 10  | work-contract-revisions        | `ImplementReady/10_*` | ❌ FAIL    | `rpc_request_revision` **lacks** state guard + revision cap                |
| 11  | availability-overlap-guard     | `ImplementReady/11_*` | ❌ FAIL    | **Zero Flutter implementation**; DB trigger only                           |
| 12  | unified-work-view              | `ImplementReady/12_*` | ⚠️ PARTIAL | `direct_offers` missing from UNION; `security_invoker` missing             |
| 13  | notification-routing           | `ImplementReady/13_*` | ⚠️ PARTIAL | No FCM/APNs push fallback                                                  |
| 14  | dispute-lifecycle              | `14_*`                | ⚠️ PARTIAL | No `dispute_status_enum`; no task-lock trigger                             |
| 15  | rls-authorization-map          | `15_*`                | ❌ FAIL    | `public.users` view exposes PII; DEFINER views bypass RLS                  |
| 16  | escrow-invariants-idempotency  | `16_*`                | ⚠️ PARTIAL | Idempotency key uses `now()` — effectively broken                          |
| 17  | storage-signed-urls-flow       | `17_*`                | ⚠️ PARTIAL | Broad `SELECT` on `chat-attachments`; no `TimedCache`                      |
| 18  | realtime-subscription-topology | `18_*`                | ❌ FAIL    | `conversations` NOT in realtime publication; N+1 bomb in code              |
| 19  | direct-offers-work-contract    | `19_*`                | ✅ PASS    | DB guard (`fn_direct_offer_guard`) is robust                               |
| 20  | withdrawals-lifecycle          | `20_*`                | ⚠️ PARTIAL | Ledger reversal on `withdrawal_cancel` missing                             |
| 21  | wallet-system-escrow-balances  | `21_*`                | ❌ FAIL    | References frozen `wallet_transactions` + deprecated RPC                   |
| 22  | dynamic-platform-fee           | `22_*`                | ❌ FAIL    | `platform_settings` table missing; RPC uses hardcoded 10%                  |
| 23  | admin-dashboard-wallet-finance | `23_*`                | ⚠️ PARTIAL | `system_config` naming drift; `public.users` PII leak                      |
| 24  | hardened-payment-linking       | `24_*`                | ⚠️ PARTIAL | `payment_intents` table not yet created; HMAC not wired                    |

---

## Summary Statistics

- **PASS**: 4 folders (01, 07, 09, 19)
- **PARTIAL**: 14 folders (02, 03, 04, 05, 06, 08, 12, 13, 14, 16, 17, 20, 23, 24)
- **FAIL**: 6 folders (10, 11, 15, 18, 21, 22)

---

## Top 10 Cross-System Blockers

| #   | Blocker                                                         | Severity | Affected Folders | Root Cause                                                     |
| --- | --------------------------------------------------------------- | -------- | ---------------- | -------------------------------------------------------------- |
| 1   | **`public.users` view exposes PII**                             | CRITICAL | 15, 23           | `SECURITY DEFINER` view on `auth.users` readable by all        |
| 2   | **Broken idempotency key generation**                           | CRITICAL | 16, 09, 21       | Key uses `now()` → changes every retry → defeats uniqueness    |
| 3   | **`platform_settings` / `system_config` table doesn't exist**   | HIGH     | 22, 23           | Fee rate source missing; RPC hardcodes 10% fallback            |
| 4   | **`wallet_transactions` frozen but still referenced**           | HIGH     | 21               | Legacy table still used in wallet diagram; deprecated in v2.16 |
| 5   | **`rpc_request_revision` has zero guards**                      | HIGH     | 10               | No `status='delivered'` check, no `revisions_total` cap        |
| 6   | **Zero Flutter code for availability slots**                    | HIGH     | 11               | DB trigger exists but no `AvailabilityService` or UI           |
| 7   | **`conversations` NOT in Supabase Realtime publication**        | HIGH     | 18, 08           | Inbox shows stale data; N+1 queries on workaround streams      |
| 8   | **`direct_offers` missing from `vw_unified_work_items`**        | HIGH     | 12, 06, 19       | Offers invisible on "My Work" dashboard                        |
| 9   | **Missing `booking_status_enum` values: `no_show`, `disputed`** | HIGH     | 05, 14           | Diagrams require them but DB constraint lacks them             |
| 10  | **Naming drift: `platform_settings` vs `system_config`**        | MED      | 22, 23           | Same concept, two names across folders                         |
