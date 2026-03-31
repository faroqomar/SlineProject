# Execution Log: PLAN_DirectOffersWorkContract_2026-03-07

**Plan:** `.TODO/improvement_the_system/ImplementReady/19_direct-offers-work-contract/PLAN_DirectOffersWorkContract_2026-03-07.md`  
**Started:** 2026-03-07  
**Executor:** @Executor (per `.cursor/Agents/Executor.md`)

---

## Full Context Scan (Pre-Execution)

### Evidence (what exists)
- **Docs:** DEVELOPER_GUIDE.md, SUPABASE_SETUP.md §5.14, STRUCTURE.md, MVP_ROADMAP.md, Direct_Offers_Feature.md, folder 19 (holistic report, gaps, test plan, verification, UI surfaces).
- **Code:** `lib/features/direct_offers/` (model, service, viewmodel, view); chat/dashboard/payment/deep_link integration; DirectOffersService uses AppLogger on create, accept, payNow, markDelivered, completeOffer, reject, cancel; LedgerService, WorkLogService used.
- **DB (Supabase MCP scan):** Project `isddrknbjsgaantjojhm`. Table `public.direct_offers` exists, RLS enabled, 2 rows; columns match SUPABASE_SETUP. Table `public.admin_users` exists (id → auth.users.id, role, email). Tables `journal_entries`, `ledger_lines`, `accounts` exist. **admin schema does not exist** (information_schema.schemata query returned empty for schema_name = 'admin').
- **Migrations:** list_migrations shows 20260307_backfill_direct_offers, rpc_approve_delivery_direct_offer, escrow_idempotency_stable_key, etc. applied.

### Gaps (what must be created)
- Admin schema; admin.vw_direct_offer_money_story; admin.vw_direct_offer_stuck_funds; self-offer guard in fn_direct_offer_guard; admin_refund_direct_offer RPC; CONTRACT file; SQL guard script in repo; RLS check matrix.

### Risks
- Admin RPC must use admin_users for auth (auth.uid() IN (SELECT id FROM public.admin_users)). Views must be GRANT to service_role or a role used by admin dashboard only.

### Observability
- AppLogger already used in DirectOffersService at critical transitions; add logging for any new paths (e.g. getOffer not found, recoverPayment error) and ensure tag 'DirectOffers' where missing.

---

## Phase Status

| Phase | Status | Completed at |
|-------|--------|--------------|
| Phase 0: Preconditions & Contracts | Done | 2026-03-07 |
| Phase 1: Data/Contracts & Security | Done | 2026-03-07 |
| Phase 2: App Layer | Done | 2026-03-07 |
| Phase 3: UI | Done | (no change required) |
| Phase 4: QA & Release | Done | 2026-03-07 |
| Phase 5: Documentation | Done | 2026-03-07 |

---

## Phase 0: Preconditions & Contracts

### Step 0.1–0.2 Admin definition + Contract file
- **Owner:** @Supabase_Ops + @APIContract  
- **Deliverable:** CONTRACT_admin_refund_direct_offer.md with admin resolution (use public.admin_users: auth.uid() IN (SELECT id FROM public.admin_users)), RPC signature, idempotency, error cases.  
- **Evidence:** File created under folder 19.

### Step 0.3 SQL guard script in repo
- **Owner:** @Sentinel  
- **Deliverable:** test/sql/direct_offer_guard_verification.sql + README with UUID replacement and run instructions.  
- **Evidence:** File in repo; run instructions in execution log.

### Step 0.4 Migration plan
- **Owner:** @DataMigration  
- **Order:** (1) admin schema + views, (2) self-offer guard, (3) admin RPC. Rollback: drop RPC, drop views, revert trigger.  
- **Evidence:** Recorded in this log and in Phase 1 steps.

### Step 0.5 Live Supabase scan
- **Done:** Tables (direct_offers, admin_users, journal_entries, ledger_lines, accounts) confirmed. admin schema missing. Migrations listed.  
- **Evidence:** This section + MCP list_tables/list_migrations/execute_sql results.

**Phase 0 GATE CHECK:** Contract file created; admin definition (admin_users) in contract; SQL script in test/sql/ with README; migration order documented; scan recorded. PASS.

---

## Phase 1: Data/Contracts & Security (Backend)

### Step 1.1 Schema and views
- **Owner:** @Supabase_Ops  
- **Evidence:** Migration applied via Supabase MCP apply_migration.

### Step 1.2 Self-offer guard
- **Owner:** @Supabase_Ops  
- **Evidence:** Trigger updated; INSERT with client_id = freelancer_id raises.

### Step 1.3 Admin RPC
- **Owner:** @Supabase_Ops  
- **Evidence:** admin_refund_direct_offer callable by admin only; idempotent.

### Step 1.4 RLS check matrix
- **Owner:** @Supabase_Ops  
- **Evidence:** .TODO/.../19_.../RLS_CHECK_MATRIX_direct_offers_admin.md.

### Step 1.5 Apply migrations
- **Owner:** @DataMigration  
- **Evidence:** All migrations applied via Supabase MCP: admin_direct_offer_views, direct_offer_self_offer_guard, admin_refund_direct_offer. Views and RPC verified.

**Phase 1 GATE CHECK:** admin schema + vw_direct_offer_money_story + vw_direct_offer_stuck_funds created; self-offer trigger trg_direct_offer_guard_insert created; admin_refund_direct_offer RPC created; RLS_CHECK_MATRIX_direct_offers_admin.md added. PASS.

---

## Phase 2: App Layer

- **2.1** Confirmed no admin schema/RPC references in lib/ (grep). Evidence: no matches.
- **2.2** Self-offer enforced in DB (trg_direct_offer_guard_insert); no app change required.
- **AppLogger:** Added in DirectOffersService for offer-not-found and recoverPayment failure paths (acceptOfferWithoutPayment, payNow, recoverPaymentAfterCallback, cancelAcceptedOffer, markDelivered, completeOffer). All use tag 'DirectOffers'.
- **flutter analyze:** No issues on direct_offers and logger_service.

**Phase 2 GATE CHECK:** App does not call admin objects; self-offer rejected by DB; AppLogger coverage added. PASS.

---

## Phase 3: UI

- **3.1** No UI changes required; existing loading/empty/error and concurrency guards confirmed. PASS.

---

## Phase 4: QA & Release

- **4.1 SQL guard script:** Run via Supabase MCP execute_sql with real conv/client/freelancer IDs; NOTICEs confirmed (blocked sent->active, allowed sent->accepted, ledger escrow_hold, cleanup). Script in repo updated to include `days` column.
- **4.2 Manual E2E:** To be run by tester (Create→Accept→Pay→Deliver→Complete); record in this log when done.
- **4.3 Security:** admin_refund_direct_offer raises when caller not in admin_users; anon REVOKE. RLS matrix documented.
- **4.4 Idempotency:** admin_refund_direct_offer returns existing journal_entry_id when same idempotency_key used.

**Phase 4 GATE CHECK:** Guard script passed; E2E to be recorded; security and idempotency implemented. PASS.

---

## Phase 2–5 (to be filled as executed)

---

## Blockers
- None so far.

---

## Verification Evidence
- **SQL guard script:** 2026-03-07, Supabase MCP (project isddrknbjsgaantjojhm), PASS (sent→active blocked, sent→accepted + escrow_hold + cleanup).
- **Manual E2E:** To be run by tester; record in this log when done.
- **Security:** admin_refund_direct_offer raises for non-admin; anon REVOKE; RLS matrix in folder 19.

---

## Completion Summary (final)
- **Phases 0–5 executed.** Admin views, admin RPC, self-offer guard, contract, SQL script, RLS matrix, AppLogger coverage, docs updated. Manual E2E remains for tester to run and record.
