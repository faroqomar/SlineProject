# 📌 Plan: Direct Offers Work Contract (ImplementReady 19) — Plan Critic Edition

**Source:** Original plan rewritten per `.agents/workflows/plan_critic.md`.  
**Goal:** Implement improvements from `.TODO/improvement_the_system/ImplementReady/19_direct-offers-work-contract` so the direct-offer lifecycle is production-hardened, observable, and supportable.

---

## A) Assumptions + Decision Needed (Blocking)

### Assumptions (Inferred)

- Live Supabase project is reachable via MCP or SQL; migrations apply to a single target (staging or prod).
- Existing `direct_offers` lifecycle and `fn_direct_offer_guard` / `process_payment_event_ledger` / `rpc_approve_delivery` are correct; this plan only adds admin tooling and optional hardening.
- “Admin” is defined elsewhere in the project (e.g. `profiles.role` or a backend list); this plan will reference that definition once chosen.
- Manual E2E and SQL verification use staging/dev data; test UUIDs are replaced per environment (no production data in scripts).
- Optional items (expires_at, self-offer guard, audit trigger) can be dropped from this release without blocking; “Must have” = admin views + admin refund RPC + test execution + docs.

### Decision Needed (Blocking)

| # | Decision | Options | Recommendation | Plan impact |
|---|----------|---------|----------------|-------------|
| 1 | How is “admin” defined for views and refund RPC? | A) `profiles.role = 'admin'` (or similar); B) Fixed list of UUIDs in RPC + GRANT; C) service_role only (no anon key) | **B** — Explicit allow-list in RPC and GRANT to a dedicated role; no dependency on profiles.role until product defines it. | Contract and migration must name the role/function that resolves admin; RPC and view GRANT use it. |
| 2 | Scope of “optional” items for this release | A) All optional out (views + RPC + tests + docs only); B) Views + RPC + self-offer check (DB) + tests + docs; C) Everything including expires_at and audit trigger | **B** — Views, RPC, self-offer guard, tests, docs. Defer expires_at and audit trigger to a follow-up. | Phase 1 must include self-offer guard in `fn_direct_offer_guard`; no expires_at or audit trigger in this plan. |

---

## B) Gate Status (Pass / Fail)

| Gate | Status | Reason | What to add/fix to pass |
|------|--------|--------|-------------------------|
| **0) Test Infrastructure** | ❌ FAIL | No checked-in SQL guard script; no fixture/manifest for direct_offer; E2E steps only in folder doc. | Check in SQL guard script under `test/sql/` or `.TODO/.../19_.../` with run instructions; document fixture (e.g. 2 users, 1 conversation, 1 offer). |
| **1) Data/Contracts** | ❌ FAIL | Admin RPC contract not written; admin identity not decided; view DDL not in repo. | Define admin (Decision 1); add contract file for `admin_refund_direct_offer`; add migration with view DDL. |
| **2) Security** | ❌ FAIL | Admin access (who can call RPC / read views) not specified; no RLS check matrix. | Document admin resolution; GRANT SELECT on views to admin role only; RPC checks admin; add RLS check matrix in `.TODO/`. |
| **3) Backend/API** | ❌ FAIL | Migrations not applied; admin RPC not deployed. | Apply migrations in order; verify views and RPC in target DB. |
| **4) UI/Integration** | ✅ PASS | No app UI changes required; existing flows unchanged. | None. |
| **5) Release/QA** | ❌ FAIL | SQL guard script and manual E2E not yet run and recorded. | Run SQL script and E2E; record results; add to Definition of Done. |

---

## C) Critical Gaps (Must-Fix)

| Gap | Why it will break | Fix | Owner | Acceptance |
|-----|-------------------|-----|--------|------------|
| Admin identity undefined | RPC and GRANT cannot be implemented; security review will block. | Add step: “Define admin (allow-list or role); document in contract; use in RPC and in GRANT for admin views.” | @Supabase_Ops + Product | Contract file states how admin is determined; migration uses same mechanism. |
| Optional vs must-have unclear | Everything gets deferred; no shippable slice. | Split scope: Must = admin views, admin RPC, self-offer guard, SQL guard run, E2E run, docs. Nice-to-have = expires_at, audit trigger (later). | @Architect | Plan § Scope lists “Must this release” vs “Later”. |
| SQL guard script not in repo | Script lives only in folder; not repeatable; no single source of truth. | Check in script under `test/sql/direct_offer_guard_verification.sql` (or `.TODO/.../19_.../`) with README: replace UUIDs, run in Supabase SQL editor. | @Sentinel | File in repo; run instructions in plan or DEVELOPER_GUIDE. |
| No run record for E2E | We cannot prove the flow was tested. | Add step: “Run manual E2E (Create→Accept→Pay→Deliver→Complete); record result (pass/fail + env) in execution log or PR.” | @Sentinel | Execution log or QA doc with date and result. |
| Admin views depend on `admin` schema | Migration may fail if schema missing. | In migration: `CREATE SCHEMA IF NOT EXISTS admin;` before creating views. | @Supabase_Ops | Migration runs from clean state without error. |

---

## D) Invariants & Success Criteria (Non-Negotiable)

| Invariant | How to enforce | How to verify |
|-----------|----------------|---------------|
| direct_offers status transitions only via guard + ledger | `fn_direct_offer_guard` on INSERT/UPDATE; completion via `rpc_approve_delivery` → ledger. | SQL guard script: illegal transitions raise; legal transitions succeed. |
| Only client or freelancer see their offers | RLS on `direct_offers`: SELECT where client_id or freelancer_id = auth.uid(). | RLS test: other user cannot SELECT row. |
| Admin views and refund RPC only for admin | GRANT SELECT on views to admin role; RPC body checks admin (allow-list or role) and raises otherwise. | Negative test: anon/regular user cannot SELECT views or call RPC. |
| Refund is idempotent and ledger-consistent | `process_payment_event_ledger('refund', ...)` with idempotency key; admin RPC passes key. | Second call with same key returns success without double-refund. |
| No regression in create→accept→pay→deliver→complete | No change to public RPCs or app code for happy path (except optional self-offer in app or DB). | Manual E2E script passes; no change to DirectOffersService completion path. |

---

## E) Risk Register

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|------|--------|-------------|--------|--------------|--------------|------------|----------|
| Admin RPC called by non-admin | RPC `admin_refund_direct_offer` | Med | High | Security-breach | Audit log / RLS test | RPC checks auth.uid() in allow-list; GRANT EXECUTE to admin only | Revoke EXECUTE; fix RPC; re-deploy |
| View leaks PII to non-admin | admin.vw_* views | Low | High | Security-breach | RLS test / review | GRANT SELECT to admin role only; no anon access | Revoke SELECT; fix GRANT |
| Migration order wrong (schema before views) | Phase 1 migrations | Low | Med | Feature | Migration failure on apply | Create admin schema first in same migration as views | Add migration that creates schema then views |
| Self-offer guard breaks valid flow | fn_direct_offer_guard INSERT | Low | Med | Feature | Integration test / manual create | Guard only rejects when client_id = freelancer_id | Revert guard migration; fix logic |
| Stuck escrow (client never completes) | delivered + held, no release | Med | Med | App-wide | vw_direct_offer_stuck_funds | Admin view for ops; future: cron or timeout | Manual admin refund via new RPC |
| SQL script uses wrong UUIDs | test/sql guard script | Med | Low | Local | Script fails in CI/staging | README: replace placeholders with staging UUIDs | Document env-specific fixture in plan |

---

## F) Pre-Mortem (How this fails in real life)

- **This fails when** we deploy the admin RPC without defining “admin” and a normal user calls it → refund runs for any user. (Gap: admin identity.)
- **This fails when** we add admin views but GRANT to public or anon → PII and money flow visible. (Gap: Security Gate.)
- **This fails when** the SQL guard script is only in the folder and never run in CI/staging → guard regressions go unnoticed. (Gap: test artifact in repo.)
- **This fails when** we treat “optional” as “do it all” and ship late or with half-done expires_at → scope creep. (Gap: optional vs must-have.)
- **This fails when** migration assumes `admin` schema exists and it doesn’t → migration fails on apply. (Gap: schema creation.)
- **This fails when** we don’t run the E2E script and a regression in pay or complete slips → production incident. (Gap: run record.)

---

## G) Plan Fixes (Concrete Additions / Expansions)

| Goal | Why | How | Output artifact | Stop condition |
|------|-----|-----|------------------|-----------------|
| Define admin for this feature | RPC and views need a single definition. | Decide allow-list or role; document in `.TODO/.../CONTRACT_admin_refund_direct_offer.md`. | Contract file with “admin resolution” section | Contract approved; migration and RPC use same rule. |
| Lock must-have scope | Avoid deferring everything. | List in plan: Must = views, RPC, self-offer guard, guard script run, E2E run, docs. Rest = later. | Plan § Scope (Must / Later) | No optional work in critical path. |
| Repo-owned SQL guard script | Repeatable verification. | Add `test/sql/direct_offer_guard_verification.sql` (or under folder 19) from 04_TEST_AND_VERIFICATION.md; README with UUID replacement and run instructions. | SQL file + short README | File in repo; one successful run documented. |
| E2E run and record | Prove flow works. | Add checklist step: run manual E2E; write result to execution log or QA doc. | Execution log or QA section | Log entry: date, env, pass/fail. |
| Admin schema exists before views | Migration must not fail. | In same migration: `CREATE SCHEMA IF NOT EXISTS admin;` then CREATE VIEW. | Migration file | Migration applies cleanly. |
| Self-offer guard in DB | Prevent freelancer creating offer to self. | In migration: extend `fn_direct_offer_guard` to raise on INSERT when `NEW.client_id = NEW.freelancer_id`. | Migration file | Insert with same client/freelancer fails. |

---

## H) Corrected Plan (Execution-Ready, Gate-Based)

### Scope (Locked)

- **Must this release:** Admin views (`admin.vw_direct_offer_money_story`, `admin.vw_direct_offer_stuck_funds`); admin refund RPC (`admin_refund_direct_offer`); self-offer guard in DB; SQL guard script in repo and run once; manual E2E run and recorded; docs update (SUPABASE_SETUP, Direct_Offers_Feature, STRUCTURE/MVP_ROADMAP as needed).
- **Later:** expires_at, audit trigger for status history, full dispute UX, cron for stuck escrow.

---

### Phase 0: Preconditions & Contracts

**Goal:** Resolve blocking decisions and produce contracts and test artifacts so Phase 1 can run.  
**Why:** Without admin definition and contracts, security and backend gates stay FAIL.  
**How:** Decide admin (Decision 1); write contract for admin RPC; add SQL guard script to repo; document fixture (2 users, 1 conv, 1 offer).

**Steps:**

0.1 (@Supabase_Ops + Product) **Admin definition**  
- Choose: allow-list of UUIDs or role (e.g. from profiles).  
- Document in `.TODO/improvement_the_system/ImplementReady/19_direct-offers-work-contract/CONTRACT_admin_refund_direct_offer.md`: signature, idempotency, error cases, how admin is resolved.

0.2 (@APIContract) **Contract file**  
- Same file: `admin_refund_direct_offer(offer_id uuid, reason text, idempotency_key text?)`; success/error shapes; idempotency behavior.

0.3 (@Sentinel) **SQL guard script in repo**  
- Add script from folder 19 `04_TEST_AND_VERIFICATION.md` to `test/sql/direct_offer_guard_verification.sql` (or under folder 19).  
- README: replace placeholder UUIDs with staging IDs; run in Supabase SQL editor; expected: illegal transitions raise, legal ones succeed.

0.4 (@DataMigration) **Migration plan**  
- Order: (1) admin schema + views, (2) self-offer guard (trigger change), (3) admin RPC. Rollback: drop RPC, drop views, revert trigger (optional).  
- No expires_at or audit trigger in this release.

0.5 (@Supabase_Ops) **Live Supabase scan**  
- List tables (direct_offers), views (admin.*), RPCs, migrations. Record drift vs SUPABASE_SETUP.md.

**GATE CHECK Phase 0:** Contract file exists; admin definition documented; SQL script in repo; migration order and rollback written; scan result recorded. If any missing → block Phase 1.

---

### Phase 1: Data / Contracts & Security (Backend)

**Goal:** Add admin schema, views, self-offer guard, and admin RPC; enforce admin-only access.  
**Why:** Data/Contracts and Security gates must pass before any app or QA.  
**How:** Single migration or ordered migrations: schema, views, trigger update, RPC. GRANT views to admin only; RPC checks admin.

**Steps:**

1.1 (@Supabase_Ops) **Schema and views**  
- Migration: `CREATE SCHEMA IF NOT EXISTS admin;`  
- Create `admin.vw_direct_offer_money_story` (per 02_UI_SURFACES_AND_WIRING.md).  
- Create `admin.vw_direct_offer_stuck_funds`.  
- GRANT SELECT on both views to role that represents admin (per contract).

1.2 (@Supabase_Ops) **Self-offer guard**  
- Migration: extend `fn_direct_offer_guard` so INSERT raises when `NEW.client_id = NEW.freelancer_id`.

1.3 (@Supabase_Ops) **Admin RPC**  
- Migration: create `admin_refund_direct_offer(offer_id uuid, reason text, idempotency_key text default gen_random_uuid()::text)`.  
- Body: resolve admin (allow-list or role); if not admin, raise; else call `process_payment_event_ledger('refund', 'direct_offer', offer_id, idempotency_key, ...)` with valid meta.  
- GRANT EXECUTE to admin role only.

1.4 (@Supabase_Ops) **RLS check matrix**  
- Add `.TODO/.../19_.../RLS_CHECK_MATRIX_direct_offers_admin.md`: who can SELECT/EXECUTE; negative cases.

1.5 (@DataMigration) **Apply migrations**  
- Apply in order; verify views return rows and RPC runs (as admin) and fails (as non-admin).

**GATE CHECK Phase 1:** Migrations applied; views queryable by admin only; RPC callable by admin only; self-offer INSERT rejected. If any fail → fix before Phase 2.

---

### Phase 2: App Layer (MVVM)

**Goal:** No regression; optional app-level self-offer check only if DB guard is not yet applied.  
**Why:** Single source of truth for self-offer is DB; app can add early validation for UX.  
**How:** If DB guard is live, no app change required for self-offer. Ensure no app code calls admin views or admin RPC.

**Steps:**

2.1 (@Architect) **Confirm no admin calls from app**  
- Grep: no reference to admin schema or admin_refund_direct_offer in lib/.  
- **Output:** Verification note in execution log.

2.2 (@Architect) **Optional: self-offer in service**  
- If DB guard is deferred: in `DirectOffersService.createOffer`, assert `clientId != freelancerId` and throw.  
- **Output:** Code change or “skipped – DB guard used”.

**GATE CHECK Phase 2:** App does not call admin objects; self-offer rejected (DB or app). Proceed to Phase 3.

---

### Phase 3: UI

**Goal:** Confirm existing loading/empty/error states; no regression.  
**Why:** UI gate already PASS; only sanity check.  
**How:** No new screens; confirm DirectOfferDetailsScreen and dashboard handle states.

**Steps:**

3.1 (@Pixel) **Confirm states**  
- DirectOfferDetailsScreen: loading, empty, error. Dashboard: direct offer cards and actions.  
- **Output:** Checklist done (no code change required).

**GATE CHECK Phase 3:** No UI regression. Proceed to Phase 4.

---

### Phase 4: QA & Release

**Goal:** Run SQL guard script and manual E2E; record results; security checks.  
**Why:** Release gate must pass with evidence.  
**How:** Run script and E2E in staging; document; run negative tests for admin.

**Steps:**

4.1 (@Sentinel) **SQL guard script**  
- Replace UUIDs; run `direct_offer_guard_verification.sql`; record pass/fail and env.

4.2 (@Sentinel) **Manual E2E**  
- Create → Accept → Pay → Deliver → Complete (per 04_TEST_AND_VERIFICATION.md). Record in execution log: date, env, result.

4.3 (@Sentinel) **Security**  
- Negative: anon/regular user cannot SELECT admin views; cannot call admin_refund_direct_offer.  
- RLS: other user cannot read another’s direct_offers row.

4.4 (@Sentinel) **Idempotency**  
- Call admin_refund_direct_offer twice with same idempotency_key; second call succeeds without double-refund.

**GATE CHECK Phase 4:** Guard script passed; E2E passed; security negatives passed; idempotency verified. If any fail → fix and re-run before release.

---

### Phase 5: Documentation & Release

**Goal:** Docs match code and DB; plan and folder 19 updated.  
**Why:** Definition of Done includes docs.  
**How:** Update SUPABASE_SETUP, Direct_Offers_Feature, STRUCTURE/MVP_ROADMAP; add execution summary.

**Steps:**

5.1 (@DocsKeeper) **SUPABASE_SETUP.md**  
- Admin section or §5.14: admin schema, vw_direct_offer_money_story, vw_direct_offer_stuck_funds, admin_refund_direct_offer, self-offer guard.

5.2 (@DocsKeeper) **Direct_Offers_Feature.md**  
- Admin tooling (views + RPC); refund path; self-offer rule; link to contract.

5.3 (@DocsKeeper) **STRUCTURE.md / MVP_ROADMAP.md**  
- Note new migration(s) and admin objects if needed.

5.4 (@DocsKeeper) **Execution summary**  
- In folder 19 or .TODO: link to this plan; “Completed: views, RPC, self-offer guard, guard script run, E2E run, docs.”

**GATE CHECK Phase 5:** Docs updated; summary written. Release gate PASS.

---

## I) Change Report (Diff-Style)

### 1) Original issues summary

- Admin identity not defined; RPC and GRANT could not be implemented.
- “Optional” scope blurred; risk of doing nothing or doing everything.
- SQL guard script and E2E not in repo / not run and recorded.
- No Test Infrastructure Gate; no explicit fixture or run instructions.
- Migration order for admin schema not explicit; risk of view creation failure.
- Gates not stated (Pass/Fail) or used as phase exits.

### 2) Added steps

- Define admin and document in contract (Phase 0).
- Add CONTRACT_admin_refund_direct_offer.md with admin resolution and RPC contract.
- Check in SQL guard script with README (Phase 0).
- Document fixture (2 users, 1 conv, 1 offer) and run instructions.
- Create admin schema in same migration as views (`CREATE SCHEMA IF NOT EXISTS admin`).
- RLS check matrix file for direct_offers and admin.
- Explicit “run E2E and record result” in Phase 4.
- GATE CHECK at end of each phase with block condition.

### 3) Removed steps

- None removed; optional “expires_at” and “audit trigger” moved to “Later” and dropped from execution steps.

### 4) Reordered steps

- Contracts and admin definition before any migration (Phase 0 before Phase 1).
- Migration order: schema → views → self-offer guard → admin RPC (was implied; now explicit).
- Security checks (negative tests, idempotency) in Phase 4 before doc sync (Phase 5).

### 5) Expanded steps

- Phase 0: from “spec lock + threat model + contracts” to concrete contract file, admin definition, and SQL script check-in.
- Phase 1: from “create views and RPC” to schema creation, GRANT, self-offer guard, and RLS matrix.
- Phase 4: from “run SQL and E2E” to run + record result + security negatives + idempotency.

### 6) Why (short, practical)

- Admin definition and contract unblock backend and security; without them the plan cannot be implemented safely.
- Scope split (Must vs Later) prevents scope creep and ensures a shippable slice.
- Script in repo and run record give repeatable verification and evidence for release.
- Gate checks prevent advancing with failing preconditions.

### 7) Residual risks

- Stuck escrow (client never completes) still requires manual use of admin view + refund RPC; no cron in this plan.
- “Admin” implementation (allow-list vs role) depends on product; if changed later, RPC and GRANT must be updated.
- E2E is manual; flakiness (e.g. payment gateway) can cause false fails; consider tagged integration test later.

---

## 7) Acceptance Criteria (Unchanged, Measurable)

- Admin views exist and are queryable by admin only.
- Admin refund RPC exists, callable by admin only, idempotent; triggers ledger refund.
- Self-offer create rejected (DB guard).
- SQL guard script in repo and run successfully once; manual E2E run and recorded.
- No regression in create → accept → pay → deliver → complete.
- Documentation updated (SUPABASE_SETUP, Direct_Offers_Feature, STRUCTURE/MVP_ROADMAP as needed).

---

## 8) Rollback Plan (Unchanged)

- **DB:** Drop admin RPC; drop admin views; revert self-offer guard change if needed. No data revert.
- **App:** No mandatory app change; if self-offer check added in app, revert that commit.
- **Emergency:** Revoke EXECUTE on admin RPC if abuse detected.

---

## Mandatory Critique Checklist Results (plan_critic §3)

- **3.1 Scope & Requirements:** Goal measurable ✅. Non-goals stated ✅. Edge/abuse (double accept, double complete, non-admin call) now in scope and tests ✅.
- **3.2 Dependencies & Ordering:** Fixed: contracts and admin definition before DB; schema before views; no UI before stable data ✅.
- **3.3 Data Model & Contracts:** Contract file and admin definition added; status transitions already guarded; DTO (admin RPC) in contract ✅.
- **3.4 Security (RLS + AuthZ):** Explicit admin-only for views and RPC; RLS matrix step added; audit for refund via work_log/ledger ✅.
- **3.5 Performance & Scalability:** No new pagination; views are admin-only, low volume; N+1 not introduced ✅.
- **3.6 Error Handling & Observability:** Error cases in contract; WorkLogService already used; no new user-facing errors ✅.
- **3.7 UX & State Machine:** Existing loading/empty/error and double-submit guards confirmed; no change ✅.
- **3.8 Testing & QA:** **Failures found:** No test harness for direct_offer in repo; no fixture manifest; SQL script not in repo. **Fixed:** Script check-in, run instructions, E2E run record; RLS/security negatives added. Smoke (guard script + E2E) and regression (no change to flow) covered ✅.
- **3.9 Release & Migration:** Additive migrations; rollback documented; no feature flag (low risk) ✅.
- **3.10 Developer Workflow:** Doc update in Phase 5; review implied by gate checks; DoD = acceptance criteria + gate passes ✅.

---

## 9) References (Unchanged)

- Folder 19: `00_HOLISTIC_REPORT.md`, `01_NOTES.md`, `02_GAPS_AND_FIXES.md`, `03_RISK_REGISTER.md`, `04_TEST_PLAN.md`, `06_DIAGRAM_FINAL.md`, `direct_offer_system_verification/*`.
- `Sline_everything/DEVELOPER_GUIDE.md`, `DEVELOPER_GUIDE/Direct_Offers_Feature.md`, `SUPABASE_SETUP.md` §5.14, `STRUCTURE.md`, `MVP_ROADMAP.md`, `ARCHITECTURE_ANALYSIS.md`.
- `lib/features/direct_offers/`, `supabase/migrations/` (direct_offer related).
- Live Supabase: scan before Phase 1; record in plan or execution log.
