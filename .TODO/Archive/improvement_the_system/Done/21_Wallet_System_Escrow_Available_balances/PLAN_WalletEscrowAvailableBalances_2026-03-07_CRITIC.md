# @PlanCritic — Wallet Escrow Available Balances (Corrected Plan)

**Source plan:** `.TODO/PLAN_WalletEscrowAvailableBalances_2026-03-07.md`  
**Date:** 2026-03-07

---

## A) Assumptions + Decision Needed (Blocking)

### Assumptions (inferred)

- Flutter app already uses `vw_wallet_balances_user` and `vw_wallet_activity_user`; live DB has these views or equivalent user-scoped views. If `wallet_balances` is the only view, app must be updated to use a user-scoped view (or view must exist with RLS).
- `rpc_approve_delivery` exists and is called from the app for booking/task; signature is `(entity_id, entity_type?)` or equivalent. No client today sends `p_idempotency_key`; RPC generates it internally.
- Supabase MCP or manual SQL can be used for “live scan” before Phase 1. No separate staging DB contract—production-like schema is the source of truth.
- Withdraw: `WalletService.requestWithdrawal()` may remain in codebase; it is not removed and not in scope. No UI for withdraw in this plan.
- Team can run migrations in order; rollback = revert migration files and redeploy. No blue/green DB required.
- Test types: unit (service/model), widget (wallet screen states), integration (RPC/views via test Supabase or mocks), manual E2E for pay→deliver→approve. No new test harness specified—assumed existing `flutter test` + possible RLS test pattern from repo.

### Decision Needed (Blocking)

| # | What decision is missing | Options | Recommended | What changes in plan |
|---|--------------------------|---------|-------------|----------------------|
| D1 | Idempotency key source for `rpc_approve_delivery`: who generates it? | (1) RPC only, deterministic from entity state (2) Client sends UUID, RPC uses it (3) RPC accepts optional client key, fallback to deterministic | (1) RPC only, deterministic from entity_id + entity status/payment_status (no `now()`). | Plan must not add “client sends idempotency key” to Flutter; migration only. If (2) chosen, add step: LedgerService or approval call site generates UUIDv5 and passes to RPC. |
| D2 | Canonical view name for user balance in app and docs | (1) `vw_wallet_balances_user` only (2) `wallet_balances` with RLS filter in view (3) Both exist, document which is canonical | (1) User-scoped view `vw_wallet_balances_user` is canonical; deprecate or alias `wallet_balances` in docs if it exists. | Phase 1 must confirm view exists; Phase 5 docs must name one view as source of truth. Grep codebase for `wallet_balances` vs `vw_wallet_balances_user` and fix references. |
| D3 | Direct offer approval: is `rpc_approve_delivery` already extended in applied migrations? | (1) Yes, only verification needed (2) No, migration required (3) Unknown, must run live scan first | (3) Run live scan first; then (1) or (2). Plan already has “confirm” step; add explicit “Decision: migrate vs verify” after 1.0. | Phase 1.0 must produce a one-line decision: “direct_offer supported: YES | NO”. If NO, 1.3 migration is mandatory. |

---

## B) Gate Status (Pass / Fail)

| Gate | Status | Reason | What to add/fix to pass |
|------|--------|--------|--------------------------|
| **1) Data/Contracts Gate** | ❌ FAIL | (1) Contract for `rpc_approve_delivery` (params, entity_type, idempotency) not yet in `.TODO/`. (2) View naming `wallet_balances` vs `vw_wallet_balances_user` unresolved. (3) Live Supabase scan not done—actual RPC body and view list unknown. | Add contract file or extend `09_ledger-event-flow/CONTRACT_ledger_event_flow.md` with `rpc_approve_delivery`. Resolve view name in contract. Run live scan and record result in plan. |
| **2) Security Gate** | ❌ FAIL | (1) Threat model and negative tests not yet written. (2) RLS matrix for ledger + views not in repo. (3) “Only RPC can write ledger” not verified by test or checklist. | Add threat-model doc and RLS check matrix. Add explicit step: “Verify no GRANT INSERT on ledger_lines/journal_entries to authenticated”. Add at least 2 RLS tests (allowed / forbidden). |
| **3) Backend/API Gate** | ❌ FAIL | (1) Idempotency fix not implemented—key still uses `now()`. (2) direct_offer support in `rpc_approve_delivery` unconfirmed. (3) No migration files yet for idempotency or direct_offer. | Implement migrations (idempotency key deterministic; direct_offer branch with client_id check). Apply and verify in dev. |
| **4) UI/Integration Gate** | ⚠️ CONDITIONAL | UI reads from ViewModel; no direct Supabase in view. Missing: explicit check that no widget calls `Supabase.instance.client.from('wallet_transactions')` or `.from('ledger_lines')`. Double-submit (approve button) not explicitly disabled on pending. | Add grep/checklist: zero references to `wallet_transactions` and `ledger_lines` in `lib/features/**/view/`. Add step: disable Approve button while request in flight. |
| **5) Release/QA Gate** | ❌ FAIL | (1) No smoke test list or regression list. (2) No flake/retry policy or timeout budget for E2E. (3) Idempotency “double-tap” test not specified (manual vs automated). | Add measurable regression list; define “idempotency test” (e.g. call RPC twice with same entity_id, assert one journal entry). Document E2E timeout and retry policy. |

---

## C) Critical Gaps (Must-Fix)

| Gap | Why it will break | Fix (exact step(s)) | Owner | Acceptance check |
|-----|-------------------|----------------------|-------|-------------------|
| **G1: Live DB state unknown** | Migrations may conflict with actual schema; view names may be wrong; RPC signature may differ. | Before Phase 1: Run Supabase scan (MCP or SQL). Record in plan: view names, `rpc_approve_delivery` arg list and body (idempotency line), RLS on `journal_entries`/`ledger_lines`/`accounts`. | @Supabase_Ops | Artifact: “Live scan result” section or file; plan updated with actual names. |
| **G2: Idempotency key uses `now()`** | Duplicate Approve (retry/race) can create two release ledger entries; double payout risk. | Migration: In `rpc_approve_delivery`, replace idempotency expression with deterministic: e.g. `encode(extensions.digest(entity_id::text || ':release_with_fee:' || COALESCE(entity.payment_status::text, '') || entity.updated_at::text, 'sha256'), 'hex')`. No `now()`. | @Supabase_Ops | Same entity_id + held status called twice → single new row in `journal_entries` for release. |
| **G3: direct_offer not approvable** | Clients cannot release escrow for direct offers from app; funds stuck. | After G1: If `rpc_approve_delivery` does not accept `direct_offer`, add migration: extend `entity_type` branch to `direct_offer`, validate `direct_offers.client_id = auth.uid()` and status delivered, call `process_payment_event_ledger('release_with_fee', 'direct_offer', ...)`. | @Supabase_Ops | Client can call `rpc_approve_delivery(entity_id, 'direct_offer')` for own direct_offer and ledger updates. |
| **G4: No contract for rpc_approve_delivery** | Frontend and backend can diverge on params/behavior; regression hard to detect. | Add or extend contract: `rpc_approve_delivery(p_entity_id uuid, p_entity_type text?)`. Allowed types: `booking`, `task`, `direct_offer`. Idempotency: deterministic key from entity state. Response shape. | @APIContract | Contract file in `.TODO/`; Flutter call sites match contract. |
| **G5: wallet_transactions still referenced** | Any code path reading/writing `wallet_transactions` will fail (frozen) or corrupt data. | Grep `lib/` and `test/` for `wallet_transactions`; remove or replace with ledger/views. Docs: replace mentions with “ledger / vw_wallet_balances_user”. | @Architect | Grep returns zero matches for `wallet_transactions` in code; docs updated. |
| **G6: No RLS verification tests** | RLS misconfiguration could leak balances or allow inserts. | Add (or confirm existing) tests: (1) Authenticated user SELECT from `vw_wallet_balances_user` returns only own row. (2) Authenticated user INSERT into `ledger_lines` fails. | @Sentinel | Two tests in repo; both pass. |
| **G7: Approve button double-submit** | User double-tap can fire two RPC calls before first response; idempotency fixes backend but UX is poor. | In approval flow: set “loading” or “pending” on first tap; disable button until RPC returns or fails. | @Pixel / @Architect | Approve button disabled while request in flight. |
| **G8: Test plan not gate-based** | QA runs without clear pass/fail; “manual E2E” is vague. | Define Release/QA gate: (1) Smoke: wallet screen loads, balance from view. (2) Critical path: pay → deliver → approve → balance moved. (3) Idempotency: two approve calls → one ledger entry. (4) RLS: two tests above. Document how each is run (manual vs automated). | @Sentinel | Checklist with pass/fail and runner (e.g. “Manual” or “flutter test integration”). |

---

## D) Invariants & Success Criteria (Non-Negotiable)

| Invariant | How to enforce | How to verify |
|-----------|----------------|----------------|
| Single source of truth for wallet totals | Balances only from DB view(s); no client-side sum over transactions. | Code review + grep: no arithmetic on balance fields in view layer. View definition sums ledger_lines. |
| Ledger parity (double-entry) | DB constraint or trigger: sum of amounts per journal_entry = 0 (DEBIT/CREDIT). | Unit test or SQL: insert unbalanced entry fails. |
| No user writes to ledger | RLS: no INSERT/UPDATE/DELETE on `journal_entries`/`ledger_lines` for role authenticated. Only RPC (SECURITY DEFINER) or service role. | RLS test: INSERT as authenticated fails. |
| Only owner sees own balance | User-scoped view or view RLS: rows filtered by `auth.uid()`. | RLS test: user A cannot see user B’s balance via view. |
| Approve is idempotent | Deterministic idempotency key in `rpc_approve_delivery`; unique constraint on `journal_entries.idempotency_key`. | Call RPC twice for same entity in held state; exactly one new journal entry for release. |
| Status transitions guarded | RPC and/or trigger: release only when entity is delivered and payment_status = held. | Negative test: call approve when not delivered → error. |

---

## E) Risk Register (Predict Problems)

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|------|-------|-------------|--------|--------------|--------------|------------|----------|
| Double release (no idempotency) | rpc_approve_delivery | High | High | Data-loss / financial | Duplicate journal_entries for same entity | Fix key (no now()) | Manual void/refund; audit |
| Unauthorized release | rpc_approve_delivery | Med | High | Security-breach | Wrong user balance increases | client_id = auth.uid() in RPC | RLS + audit log |
| View name wrong in app | WalletService / views | Med | Med | Feature | Wallet screen empty or error | Live scan + contract | Fix view name or create view |
| wallet_transactions still used | Any caller | Low | High | App-wide | Exception in prod | Grep + remove | Deploy fix; no DB rollback |
| Migration order wrong | Supabase migrations | Low | Med | Feature | RPC fails after deploy | Ordered migrations; test in dev | Revert migration |
| Direct offer approve missing | rpc_approve_delivery | Med | Med | Feature | Client cannot complete direct offer | Add entity_type direct_offer | Deploy migration |
| Stale balance after approve | Wallet UI | Med | Low | Local | User sees old balance | Refresh on return or realtime | Pull-to-refresh; doc |
| E2E flake / no timeout | Manual QA | Med | Low | Delivery | Inconclusive test runs | Timeout and retry policy | Re-run; document env |

---

## F) Pre-Mortem (How this fails in real life)

- **This fails when** a client double-taps Approve and the RPC still uses `now()` in the idempotency key, so two journal entries are created and the freelancer is credited twice. (G2)
- **This fails when** the app or docs reference `wallet_balances` but the only view in DB is `vw_wallet_balances_user`, so queries fail or RLS is wrong. (G1, D2)
- **This fails when** a malicious user calls `rpc_approve_delivery` for another user’s booking because the RPC does not enforce `auth.uid() = client_id`. (R-INF-02, G3)
- **This fails when** a developer adds a “quick fix” that reads from `wallet_transactions` and the frozen trigger throws in production. (G5)
- **This fails when** direct offers are delivered but the app never calls approve with `entity_type = 'direct_offer'`, so escrow is never released. (G3)
- **This fails when** QA reports “sometimes balance is wrong” but there is no idempotency test, so the bug is not caught before release. (G2, G8)
- **This fails when** RLS is relaxed on a view and one user can read another’s balance; no RLS test exists to catch it. (G6)

---

## G) Plan Fixes (Concrete Additions / Expansions)

| Goal | Why | How | Output artifact | Stop condition |
|------|-----|-----|------------------|----------------|
| Resolve view naming | App and docs must use one canonical view. | Run live scan; list views. Decide: `vw_wallet_balances_user` canonical. Grep code/docs for `wallet_balances`; replace or alias. | Plan section “Canonical views”; code/doc edits | Single view name in contract and WalletService. |
| Contract for rpc_approve_delivery | Avoid drift and regression. | Add section to contract file: signature, entity_type enum, idempotency rule, response shape, error codes. | `.TODO/.../CONTRACT_rpc_approve_delivery.md` or extend 09 contract | Contract reviewed; Flutter call sites match. |
| Idempotency migration | Prevent double release. | Write migration: replace idempotency key in `rpc_approve_delivery` with deterministic expression (no now()). Test: call twice, assert one new journal entry. | `supabase/migrations/YYYYMMDD_rpc_approve_delivery_idempotency.sql` | Two identical approve calls → one ledger entry. |
| direct_offer in rpc_approve_delivery | Clients must release escrow for direct offers. | After scan: if missing, add migration with branch `entity_type = 'direct_offer'`, guard `direct_offers.client_id = auth.uid()`, call process_payment_event_ledger. | Migration file | Client can approve own direct_offer; ledger updates. |
| RLS matrix + 2 tests | Security gate must pass. | Document: who can SELECT/INSERT on ledger tables and views. Add test: user SELECT own balance OK; user INSERT ledger_lines FAIL. | `.TODO/.../RLS_CHECK_MATRIX_wallet_ledger.md`; 2 tests in test/ | Matrix in repo; tests pass. |
| No wallet_transactions in code | Frozen table must not be used. | Grep lib/ and test/ for wallet_transactions. Remove or replace with view/ledger. | Code changes | Grep returns 0 matches. |
| Approve button disabled while pending | Prevent double submit. | In approval screen/VM: on Approve tap set loading true; disable button; on RPC complete set loading false. | Code in view/viewmodel | Button disabled until RPC returns. |
| QA gate checklist | Release gate must be testable. | List: (1) Wallet loads from view, (2) Pay→Deliver→Approve→balance moved, (3) Idempotency test, (4) RLS tests. Define runner and timeout. | Plan section “Release/QA Gate checklist” | All items have pass criterion and runner. |

---

## H) Corrected Plan (Execution-Ready, Gate-Based)

### Phase 0: Data & Contracts (BLOCKING)

**Goal:** Single source of truth for view names and RPC contract; no work on backend/UI until this passes.

**Why:** Prevents building on wrong schema or contract.

**How:**

1. (@Supabase_Ops) **Live scan:** List views (wallet_balances, vw_wallet_balances_user, vw_wallet_activity_user), `rpc_approve_delivery` signature and idempotency line, RLS on journal_entries/ledger_lines/accounts. Record result in plan or `.TODO/.../LIVE_SCAN_YYYYMMDD.md`.
2. (@APIContract) **Contract:** Add or extend contract for `rpc_approve_delivery` (params, entity_type, idempotency, response). Canonical view name for balance = `vw_wallet_balances_user` (or per scan).
3. (@Architect) **Codebase grep:** Zero references to `wallet_transactions` in lib/ and test/. Zero direct `.from('ledger_lines')` or `.from('journal_entries')` in view layer.
4. (@Sentinel) **Acceptance:** Contract file exists; scan result documented; grep clean.

**GATE CHECK (Phase 0):** Contract written; canonical view name decided; no wallet_transactions in code; live scan done. If FAIL, do not proceed to Phase 1.

---

### Phase 1: Security & Backend (DB + RLS + RPC)

**Goal:** Idempotent approve; direct_offer approvable; only RPC can write ledger; users only read own balance via views.

**Why:** Security and correctness are prerequisites for UI.

**How:**

1. (@Supabase_Ops) **RLS matrix:** Document SELECT/INSERT/UPDATE/DELETE for authenticated and service_role on journal_entries, ledger_lines, accounts, vw_wallet_balances_user, vw_wallet_activity_user. Ensure no INSERT to ledger for authenticated.
2. (@Supabase_Ops) **Migration – Idempotency:** Change `rpc_approve_delivery` to compute idempotency key deterministically (e.g. entity_id + payment_status + updated_at); remove `now()`. Deploy; verify two identical calls → one journal entry.
3. (@Supabase_Ops) **Migration – direct_offer (if needed):** If scan showed rpc_approve_delivery does not support direct_offer: add branch for entity_type = 'direct_offer', validate direct_offers.client_id = auth.uid() and status delivered, call process_payment_event_ledger('release_with_fee', 'direct_offer', ...).
4. (@Sentinel) **RLS tests:** (1) User can SELECT from vw_wallet_balances_user (own row). (2) User INSERT into ledger_lines fails.
5. (@Sentinel) **Idempotency test:** Same entity_id, held status; call rpc_approve_delivery twice; assert exactly one new journal_entry for release_with_fee.

**GATE CHECK (Phase 1):** Migrations applied; RLS matrix and 2 RLS tests pass; idempotency test passes. If FAIL, do not proceed to Phase 2.

---

### Phase 2: App Layer (MVVM)

**Goal:** Models match contract; services use only views and RPC; approval flows pass correct entity_type; no UI→Supabase.

**Why:** Keeps architecture clean and testable.

**How:**

1. (@Architect) **Models:** WalletBalanceModel and WalletActivityModel match view columns (vw_wallet_balances_user, vw_wallet_activity_user). Error mapping for RPC errors.
2. (@Architect) **WalletService:** Reads only from vw_wallet_balances_user and vw_wallet_activity_user. No wallet_transactions.
3. (@Architect) **Approval flows:** Booking and direct_offer approval call rpc_approve_delivery with correct entity_type. Disable Approve button while request in flight (loading state).
4. (@Sentinel) **Verify:** No direct Supabase in view layer; no wallet_transactions; button disabled on pending.

**GATE CHECK (Phase 2):** Models match contract; services use views only; approval uses RPC with correct entity_type; double-submit prevented. If FAIL, do not proceed to Phase 3.

---

### Phase 3: UI & Integration

**Goal:** Wallet screen shows Available and Escrow from ViewModel; loading/empty/error states; no client-side balance math.

**Why:** User sees correct, stable data.

**How:**

1. (@Pixel) **Wallet screen:** Data from ViewModel only. Display Available, Escrow/Held (and Pending Withdrawal if in view). Loading, empty, error states.
2. (@Pixel) **Approval screen:** Approve button disabled while RPC in progress.
3. (@Sentinel) **Smoke:** Wallet screen loads; balance comes from view (no crash on empty).

**GATE CHECK (Phase 3):** Wallet displays view data; no balance arithmetic in UI; approval UX prevents double-tap. If FAIL, do not proceed to Phase 4.

---

### Phase 4: QA & Release

**Goal:** All gates pass; regression list covered; docs updated; Withdraw marked upcoming.

**Why:** Ship only when measurable criteria are met.

**How:**

1. (@Sentinel) **Regression list:** Wallet from view; no wallet_transactions; idempotent approve; direct_offer approvable; RLS blocks cross-user read; loading/empty/error.
2. (@Sentinel) **Run:** Smoke, critical path (pay→deliver→approve), idempotency test, RLS tests. Document runner (manual / automated) and timeout/retry.
3. (@ThreatModeler) **Negative:** Unauthorized approve attempt fails; cross-user balance read fails.
4. (@DocsKeeper) **Docs:** DEVELOPER_GUIDE, Wallet_Feature, diagram 21: ledger-only terminology; canonical view name; Withdraw = Upcoming feature. SUPABASE_SETUP if RPC/view changed.

**GATE CHECK (Phase 4):** All regression items pass; threat checks pass; docs updated. If FAIL, do not release.

---

### Phase 5: Documentation Sync (parallel or after Phase 4)

- (@DocsKeeper) Update DEVELOPER_GUIDE, Wallet_Feature, SUPABASE_SETUP (if needed), diagram 21. Mark Withdraw as **Upcoming feature**.
- (@Sentinel) Docs match code and live DB (view names, RPC contract).

---

## I) Change Report (Diff-Style)

### 1) Original issues summary

- Data/Contracts gate not passed: no single contract for rpc_approve_delivery; view naming unresolved; live scan not done.
- Security gate: no threat model, no RLS matrix, no RLS tests.
- Backend gate: idempotency and direct_offer not implemented/verified.
- UI: no explicit double-submit prevention; no grep for wallet_transactions.
- Release/QA: no concrete regression list; idempotency test and RLS tests not specified.

### 2) Added steps

- Live scan (artifact) before Phase 1.
- Contract for rpc_approve_delivery (params, entity_type, idempotency).
- Grep for wallet_transactions and ledger_lines in view layer.
- RLS check matrix and 2 RLS tests (own balance OK; INSERT ledger_lines FAIL).
- Idempotency test (two approve calls → one journal entry).
- Disable Approve button while request in flight.
- Release/QA gate checklist with runner and pass criterion.
- Explicit GATE CHECK after each phase (block next phase if fail).
- Decision table (D1–D3) for idempotency source, view name, direct_offer.

### 3) Removed steps

- None; optional “feature flag” and “observability” kept but not expanded (low risk).

### 4) Reordered steps

- “Live Supabase Confirmation” moved to Phase 0 and made blocking; Phase 1 then assumes scan result.
- RLS matrix and RLS tests moved into Phase 1 (Security & Backend) and must pass before Phase 2.
- Documentation sync remains at end but Release gate (Phase 4) now includes “docs updated” as pass condition.

### 5) Expanded steps

- Phase 0: From “preconditions” to a full **Data/Contracts Gate** with scan, contract, and grep.
- Phase 1: From “confirm RLS” to “RLS matrix + 2 tests + idempotency migration + idempotency test + direct_offer migration (if needed).”
- Phase 4: From “Manual E2E” to “Regression list + smoke + critical path + idempotency test + RLS tests + threat negatives,” with runner and timeout.
- Each phase now has explicit **GATE CHECK** and “If FAIL, do not proceed.”

### 6) Why (short, practical)

- Gates prevent fake progress: no UI work until contract and DB are fixed.
- RLS and idempotency tests catch regressions before release.
- Double-submit prevention improves UX and reduces load even with idempotent backend.
- Single view name and contract avoid production errors from naming/signature drift.

### 7) Residual risks

- QiCard/webhook flows are out of scope; duplicate webhook could still be a risk if not handled elsewhere.
- Manual E2E may be flaky; timeout and retry policy reduce but do not eliminate risk.
- Older app versions not sending entity_type for direct_offer: graceful degradation (direct offer approval only after update) is assumed; no backfill.

---

---

## Mandatory Critique Checklist (Failures Found)

### 3.1 Scope & Requirements
- **Goal measurable?** Yes (balances from view only; idempotent approve; direct_offer approvable).
- **Non-goals stated?** Yes (Withdraw = upcoming; admin dashboard; QiCard hardening; dispute FSM).
- **Edge cases:** Retries/double-tap covered by idempotency fix; cancel/refund in scope via process_payment_event_ledger. Abuse: unauthorized release addressed by client_id check.

### 3.2 Dependencies & Ordering
- **UI before stable data/contracts?** Original plan had Phase 3 UI after Phase 1–2 but did not block Phase 2 on a formal Data/Contracts gate. **Fix:** Phase 0 added; Gate Check blocks progress.
- **DB/RLS before API/UI?** Yes after correction (Phase 0 → 1 → 2 → 3).
- **Backfill/migration path?** Additive migrations only; rollback = revert. No backfill in scope.

### 3.3 Data Model & Contracts
- **Tables/enums/constraints?** No new tables; views and RPC in scope. **Gap:** Contract for rpc_approve_delivery missing—added in G4/G7.
- **DTO boundaries?** Models aligned to views; contract defines RPC params.
- **Status transitions?** RPC and process_payment_event_ledger enforce status gates; invariant table added.

### 3.4 Security (RLS + AuthZ)
- **Explicit read/write per role?** Original plan said “confirm” but did not require RLS matrix or tests. **Fail:** Security gate failed; RLS matrix + 2 tests added.
- **Public read leak?** User-scoped views; no public read of ledger raw tables.
- **Privileged actions isolated?** RPC is SECURITY DEFINER; only RPC writes ledger. **Gap:** No test that INSERT fails—added.
- **Audit logs?** journal_entries.meta; optional admin_logs. Not expanded in critic.

### 3.5 Performance & Scalability
- **Pagination/indexes?** Activity list uses cursor; balance is single row. Not deeply audited; acceptable for current scope.
- **N+1?** Wallet reads one view; no loop over ledger in app.
- **Realtime?** Not in scope for wallet balances; optional refresh.

### 3.6 Error Handling & Observability
- **Error taxonomy?** LedgerService maps RPC errors; user-facing messages. Not fully enumerated—acceptable.
- **Correlation id?** Optional observability; not mandatory in critic.
- **User-facing error states?** Yes in Phase 3 (loading/empty/error).

### 3.7 UX & State Machine
- **Loading/empty/error?** Yes.
- **Double submit / race?** **Gap:** Approve button not explicitly disabled—added G7.
- **Offline/timeout/retry?** Not specified; residual risk.

### 3.8 Testing & QA
- **Smoke / regression?** **Fail:** No list in original—added in G8 and Phase 4.
- **RLS tests?** **Fail:** Not required in original—added 2 tests (allowed + forbidden).
- **Idempotency test?** **Fail:** Only “manual” mentioned—added as explicit test (two calls → one entry).
- **Test infra / fixtures / timeout?** Assumed existing flutter test; E2E timeout/retry policy added in Release gate.

### 3.9 Release & Migration Safety
- **Feature flag?** Optional in original; kept.
- **Backward compatibility?** Additive RPC; old app may not send direct_offer—graceful degradation.
- **Rollback plan?** Present; critic did not change.

### 3.10 Developer Workflow
- **Branch/review/DoD?** Not in original plan; not added (assumed team process).
- **Documentation update?** Yes in Phase 5; Release gate now requires docs updated.

---

**End of @PlanCritic output.** Use this corrected plan as the execution-ready version; run Phase 0 first and do not skip gate checks.
