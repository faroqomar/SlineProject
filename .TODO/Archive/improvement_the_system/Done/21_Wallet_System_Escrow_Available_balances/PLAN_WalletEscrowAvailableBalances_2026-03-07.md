# 📌 Plan: Wallet System (Escrow + Available Balances)

## 1) Goal

- **Goal:** Implement and harden the Wallet System (Escrow + Available balances) for the Pay-First flow so that balances are derived solely from the double-entry ledger, all money moves through `process_payment_event_ledger`, and the UI shows **Available** vs **Escrow/Held** from DB views only. Withdraw is **not** implemented in this plan (treated as an **Upcoming feature**).
- **Why:** Eliminate money ambiguity, prevent client-side balance math, and ensure atomic, auditable state changes. Align code and docs with the canonical ledger (`journal_entries` + `ledger_lines`) and fix known idempotency and terminology drift from folder `21_Wallet_System_Escrow_Available_balances`.
- **Result:** Wallet screen shows correct Available/Escrow from views; Escrow hold → Release/Refund flows are idempotent and secure; Direct Offer approval path (if missing) is closed; no references to legacy `wallet_transactions` or deprecated `process_payment_event` in active code paths.

---

## 2) Scope

### In-Scope

- Double-entry ledger as single source of truth for balances (`journal_entries`, `ledger_lines`, `accounts`).
- Wallet UI reading **Available** and **Escrow/Held** (and optionally **Pending Withdrawal**) from user-scoped views only (e.g. `vw_wallet_balances_user`).
- Escrow lifecycle: **Escrow Hold** (pay-first), **Release with Fee** (approve delivery), **Refund** (decline/cancel/expire/dispute) via `process_payment_event_ledger` (and `rpc_approve_delivery` where applicable).
- **Idempotency fix:** Remove `now()` from idempotency key generation in `rpc_approve_delivery` so retries do not create duplicate ledger entries.
- **Direct Offer approval:** Ensure `rpc_approve_delivery` supports `entity_type = 'direct_offer'` so clients can approve delivery and release escrow for direct offers.
- Terminology and diagram/docs alignment: ledger-only naming in implementation docs; no reliance on `wallet_transactions`.
- Observability: `journal_entries.meta` (and optional audit) for payment events; no sensitive data in logs.
- QA: Contract compliance, RLS/security checks, functional E2E for pay → deliver → approve.

### Out-of-Scope

- **Withdraw (request payout / withdrawal lifecycle):** Treated as an **Upcoming feature**. No implementation of withdrawal request UI, `requestWithdrawal()` flow, or gateway withdrawal completion in this plan. (WalletService may already have `requestWithdrawal`; plan does not extend or remove it—only excludes it from *implementation* scope for this plan.)
- Admin dashboard finance/reconciliation (separate initiative).
- Server-side payment intents / QiCard hardening (covered by other plans).
- Dispute DB FSM / notification triggers (separate diagrams/plans).
- Availability slots UI (separate feature).

---

## 3) Evidence & Findings (From Scan)

### Existing

- **Docs:** `Sline_everything/SUPABASE_SETUP.md` — `wallet_transactions` frozen (trigger `trg_wallet_transactions_freeze`); `journal_entries`, `ledger_lines`, `accounts`, `wallet_balances` view; `process_payment_event_ledger` RPC (escrow_hold, release_with_fee, refund, withdrawal_request, gateway_escrow, etc.); idempotency key UNIQUE on `journal_entries`. `Sline_everything/DEVELOPER_GUIDE.md`, `DEVELOPER_GUIDE/Wallet_Feature.md` — wallet feature, `vw_wallet_balances_user`, `vw_wallet_activity_user`, LedgerService, WalletService.
- **Code:** `lib/features/wallet/` — WalletService (getWalletBalance from `vw_wallet_balances_user`, getActivity from `vw_wallet_activity_user`), LedgerService (submitPaymentEvent → `process_payment_event_ledger` with UUIDv5 idempotency), WalletViewModel, wallet_screen, wallet_balance_model, wallet_activity_model. Booking/direct_offer flows call ledger or RPCs. No direct inserts into `ledger_lines` from app.
- **DB (from docs):** View `wallet_balances` in SUPABASE_SETUP; app uses `vw_wallet_balances_user` / `vw_wallet_activity_user` (DEVELOPER_GUIDE/Wallet_Feature) — possible naming split (public view vs user-scoped view).
- **Folder 21:** `.TODO/improvement_the_system/ImplementReady/21_Wallet_System_Escrow_Available_balances/` — holistic report, gaps (legacy table refs, idempotency, platform revenue, auth checks), risk register, dependency order (idempotency hash fix, schema unification, rpc_approve_delivery direct_offer), implementation plan (Postgres hardening, then server, then Flutter), test plan, golden path (Rule of One: one entry to escrow, one exit via `rpc_approve_delivery`).
- **Idempotency bug:** `.TODO/improvement_the_system/ImplementReady/16_escrow-invariants-idempotency/` and `07_MINIMAL_PATCH_PLAN.md` — `rpc_approve_delivery` uses `extensions.digest(entity_id || ':release_with_fee:' || now(), 'sha256')`, making key unique per call; app does not send idempotency key (RPC generates internally).
- **Direct Offer:** Diagram audit (folder 19) states `rpc_approve_delivery` fails for `direct_offer`; Archive migration `20260303_direct_offer_ledger_rpc.sql` and `20260308_fix_release_with_fee_zero_amount_and_enum.sql` show `process_payment_event_ledger` supports `direct_offer` for release_with_fee. Need to confirm whether `rpc_approve_delivery` in *applied* migrations accepts `direct_offer`.

### Missing

- Live Supabase scan of: exact view names (`wallet_balances` vs `vw_wallet_balances_user`), `rpc_approve_delivery` signature and body (idempotency key logic, entity_type list), RLS on `ledger_lines`/`journal_entries`/`accounts`, and indexes.
- Contract file in `.TODO/` that ties Flutter wallet/ledger calls to RPC parameters and view shapes (partially covered by `09_ledger-event-flow/CONTRACT_ledger_event_flow.md`).
- Confirmation that no Flutter code path reads or writes `wallet_transactions`.

### Conflicts / Risks (docs vs code vs live DB drift, naming mismatches, security/migration risks)

- **Naming drift:** Diagram 21 and some docs say `wallet_balances`; app and Wallet_Feature say `vw_wallet_balances_user` / `vw_wallet_activity_user`. Need single source of truth (likely user-scoped views for RLS).
- **Idempotency:** `rpc_approve_delivery` using `now()` defeats idempotency; duplicate "Approve" taps could theoretically create multiple release entries if status gate is bypassed. Fix is DB-only (deterministic key).
- **Direct Offer:** If `rpc_approve_delivery` does not accept `direct_offer`, clients cannot release escrow for direct offers from the app; must add entity_type support and guard on `direct_offers.client_id = auth.uid()`.
- **R-LEG-01:** Any write to `wallet_transactions` will fail (frozen trigger).
- **R-INF-01:** Duplicate webhook or duplicate approve without idempotency can cause double release (mitigation: fix idempotency key).
- **R-INF-02:** Unauthorized release — RPC must enforce `auth.uid() = client_id` for approval.

---

## 4) System Impact Map

- **UI:** Wallet screen and any balance snapshot widgets: data from ViewModel → service → `vw_wallet_balances_user` (and activity from `vw_wallet_activity_user`). No balance math in UI. Withdraw button/flow excluded from this plan (upcoming).
- **MVVM/App Logic:** WalletViewModel, WalletService, LedgerService unchanged in contract; ensure all ledger writes go through `process_payment_event_ledger`; approval flows use `rpc_approve_delivery` with correct entity_type (booking / task / direct_offer). No new direct Supabase calls from View.
- **Database:** Possibly new migration(s): (1) `rpc_approve_delivery` idempotency key fix (deterministic, no `now()`); (2) `rpc_approve_delivery` accept `direct_offer` and validate `direct_offers.client_id = auth.uid()`. No drops/renames of tables; no new tables for this scope.
- **RLS/Security:** Ledger tables and views already RLS-covered; ensure only RPC/service_role can insert into ledger_lines/journal_entries; user-scoped views enforce `auth.uid()`.
- **Realtime/Notifications:** Optional: booking/delivery status change notifications (out of scope unless already present).
- **Storage:** Not applicable.
- **Observability:** Ensure payment/ledger events are logged in `journal_entries.meta` (and optional admin_logs) without PII; AppLogger in LedgerService already in place.
- **Compatibility & Migration:** Additive-only DB changes; older app versions may not pass direct_offer to approve_delivery (graceful degradation: direct offer approval only after update). No migration of legacy `wallet_transactions` data in this plan.
- **Contracts:** Align with `.TODO/improvement_the_system/ImplementReady/09_ledger-event-flow/CONTRACT_ledger_event_flow.md`; add/update contract for `rpc_approve_delivery` (parameters, entity_type, idempotency) if not already documented.

---

# ✅ Execution Phases (Checklist)

## Phase 0: Preconditions & Gates

> Primary: @Sentinel

### 0.1 Spec Lock

- [ ] (@Sentinel) Acceptance + non-regression list (measurable): balances from view only; no wallet_transactions usage; idempotent approve; direct_offer approvable; RLS blocks cross-user ledger read.
- [ ] (@Architect) Confirm modules/entry points: wallet feature, booking/direct_offer approval call sites.
- **Verify (@Sentinel):** done-conditions + rollback triggers documented.

### 0.2 Threat Model (wallet/money)

- [ ] (@ThreatModeler) Threat model + security requirements + negative checks (in `.TODO/` or this folder): double-spend, unauthorized release, balance tampering.
- **Verify (@Sentinel):** testable and included in Phase 4.

### 0.3 Contracts (payloads / RPC)

- [ ] (@APIContract) Contract file(s) in `.TODO/`: Flutter ↔ `process_payment_event_ledger` and `rpc_approve_delivery` (parameters, entity_type, idempotency key source). Reuse or extend `09_ledger-event-flow/CONTRACT_ledger_event_flow.md`.
- **Verify (@Sentinel):** contract matches schema + shapes.

### 0.4 Migration Plan (schema/RPC changes)

- [ ] (@DataMigration) Plan: (1) Migration to fix `rpc_approve_delivery` idempotency key (deterministic); (2) Migration to add `direct_offer` support to `rpc_approve_delivery` with client_id check. Rollback: revert migrations; no data backfill required.
- **Verify (@Sentinel):** measurable compatibility window and rollback steps.

### 0.5 Feature Flag/Rollout (optional)

- [ ] (@Architect) Toggle strategy if needed (e.g. direct_offer approval behind flag).
- **Verify (@Sentinel):** rollback path documented.

---

## Phase 1: Database & Security

> Primary: @Supabase_Ops

### 1.0 Live Supabase Confirmation (MANDATORY)

- [ ] (@Supabase_Ops) Re-scan via `@mcp:supabase-mcp-server:` for: `journal_entries`, `ledger_lines`, `accounts`, `wallet_balances` / `vw_wallet_balances_user`, `vw_wallet_activity_user`, `rpc_approve_delivery` definition, RLS on ledger tables.
- [ ] (@Supabase_Ops) Confirm no conflicts with existing (avoid drops/renames unless planned).
- **Verify (@Sentinel):** drift + safe approach recorded in plan or risk register.

### 1.1 Schema (Additive-first)

- [ ] (@Supabase_Ops) No new tables; confirm view definitions and that user-scoped views exist and match app usage.
- **Verify (@Sentinel):** naming consistent, minimal risk.

### 1.2 RLS

- [ ] (@Supabase_Ops) Confirm policies: users cannot INSERT/UPDATE/DELETE on `ledger_lines`/`journal_entries`; SELECT only via secure views (e.g. `vw_wallet_balances_user`, `vw_wallet_activity_user`).
- [ ] (@Supabase_Ops) RLS check matrix file in `.TODO/` if not already present.
- **Verify (@Sentinel):** negative fails, positive passes.

### 1.3 Triggers/RPC (Idempotency + Direct Offer)

- [ ] (@Supabase_Ops) Migration: Fix `rpc_approve_delivery` idempotency key — use deterministic expression (e.g. `entity_id || ':release_with_fee:' || entity.status` or accept `p_idempotency_key` from client); remove `now()` from digest.
- [ ] (@Supabase_Ops) Migration: Extend `rpc_approve_delivery` to accept `entity_type = 'direct_offer'`; validate `direct_offers.client_id = auth.uid()` and entity in deliverable state; call `process_payment_event_ledger('release_with_fee', 'direct_offer', ...)` with same idempotency semantics.
- **Verify (@Sentinel):** state rules enforced; duplicate calls do not create duplicate ledger entries.

### 1.4 Migration Execution

- [ ] (@DataMigration) Apply migrations per plan (idempotency fix, direct_offer support).
- **Verify (@Sentinel):** verify RPC and ledger queries pass.

---

## Phase 2: App Layer (MVVM)

> Primary: @Architect

### 2.1 Models & Contract Compliance

- [ ] (@Architect) WalletBalanceModel and WalletActivityModel aligned to view columns (`vw_wallet_balances_user`, `vw_wallet_activity_user`).
- [ ] (@Architect) Domain error mapping for ledger/RPC errors (user-friendly messages).
- **Verify (@Sentinel):** types/nullability match contract and view shapes.

### 2.2 Services/Repositories

- [ ] (@Architect) WalletService: only reads from user-scoped views; no `wallet_transactions`. LedgerService: only writes via `process_payment_event_ledger` with deterministic idempotency key.
- [ ] (@Architect) Approval flows: ensure booking and direct_offer approval call `rpc_approve_delivery` with correct `entity_type` (and entity_id). No direct ledger INSERT from app.
- **Verify (@Sentinel):** RLS-safe, no UI→Supabase direct calls.

### 2.3 ViewModels

- [ ] (@Architect) WalletViewModel: single source of truth for balance/activity from service; loading/error states.
- [ ] (@Architect) Work/booking/direct_offer ViewModels: approve delivery calls RPC with correct entity_type.
- **Verify (@Sentinel):** recoverable state + correct transitions.

### 2.4 Observability (optional)

- [ ] (@Observability) Event list + correlation strategy (in `.TODO/`) if not already present.
- [ ] (@Architect) Instrument LedgerService/WalletService (not UI); no sensitive data in logs.
- **Verify (@Sentinel):** consistent correlation, no PII in logs.

---

## Phase 3: UI (After logic)

> Primary: @Pixel

### 3.1 Wiring

- [ ] (@Pixel) Wallet screen uses ViewModel only; displays Available, Escrow/Held (and Pending Withdrawal if in view); no client-side balance aggregation.
- [ ] (@Pixel) Loading/empty/error states for balance and activity list.
- **Verify (@Sentinel):** stable UX on slow/empty data.

### 3.2 Polish (Optional)

- [ ] (@Pixel) Micro-interactions (low-risk only).
- **Verify (@Sentinel):** no perf regression.

---

## Phase 4: QA + Security (MANDATORY)

> Primary: @Sentinel

### 4.1 Contract + Migration Checks

- [ ] (@Sentinel) Shapes/types match contract; view columns match models.
- [ ] (@Sentinel) Run migration verify queries (if any).
- **Verify (@Sentinel):** no mismatch.

### 4.2 Security + Abuse Tests

- [ ] (@Sentinel) Execute ThreatModeler negative checks (unauthorized release, cross-user read).
- [ ] (@Sentinel) RLS: user cannot INSERT into ledger_lines; user cannot read other users’ balances via views.
- **Verify (@Sentinel):** unauthorized access impossible.

### 4.3 Functional QA

- [ ] (@Sentinel) Manual E2E: Pay (escrow) → Deliver → Approve → balance moves from Held to Available; Refund path; Direct offer approve path (if implemented).
- [ ] (@Sentinel) Idempotency: double-tap Approve does not duplicate ledger entries.
- [ ] (@Sentinel) Edge cases: network error, null session, stale data.
- **Verify (@Sentinel):** no crashes, consistent behavior.

### 4.4 Observability Validation (if included)

- [ ] (@Sentinel) Required logs/events exist and are useful.
- [ ] (@Sentinel) Privacy redaction enforced.
- **Verify (@Sentinel):** actionable telemetry without leaks.

---

## Phase 5: Documentation Sync (MANDATORY)

> Primary: @DocsKeeper

- [ ] (@DocsKeeper) Update DEVELOPER_GUIDE, Wallet_Feature, SUPABASE_SETUP (if view names or RPC changed), and diagram `21_Wallet_System_Escrow_Available_balances.md` to ledger-only terminology; mark Withdraw as **Upcoming feature**.
- **Verify (@Sentinel):** docs match code + live DB reality.

---

## 7) Acceptance Criteria (MANDATORY)

- Balances (Available, Escrow/Held) are read only from DB views; no client-side aggregation.
- No code path reads or writes `wallet_transactions`; all payment state changes go through `process_payment_event_ledger` (or RPCs that call it).
- `rpc_approve_delivery` uses a deterministic idempotency key (no `now()`); duplicate approve requests do not create duplicate ledger entries.
- Clients can approve delivery for direct offers (entity_type `direct_offer`) where they are the client; RPC enforces `auth.uid() = direct_offers.client_id`.
- RLS prevents users from inserting into ledger tables and from reading other users’ ledger data; user-scoped views enforce ownership.
- Wallet UI shows loading/empty/error states; no crashes on slow or empty data.
- Documentation and diagram 21 reference ledger views and RPCs only; Withdraw is explicitly documented as **Upcoming feature**.

---

## 8) Rollback Plan

- **DB:** Revert migrations (idempotency key, direct_offer support) in reverse order; no data loss (additive RPC logic only).
- **App:** Revert code changes; if RPC signature changed, keep backward-compatible RPC behavior (e.g. optional entity_type defaulting to booking/task).
- **Emergency:** Disable approval button or route approval through a feature flag if critical issue found post-release.

---

## 9) References (From Scan)

- `Sline_everything/DEVELOPER_GUIDE.md`, `Sline_everything/DEVELOPER_GUIDE/Wallet_Feature.md`
- `Sline_everything/SUPABASE_SETUP.md` (ledger, wallet_balances, process_payment_event_ledger, rpc_approve_delivery, wallet_transactions freeze)
- `Sline_everything/MVP_ROADMAP.md`, `Sline_everything/ARCHITECTURE_ANALYSIS.md`, `Sline_everything/STRUCTURE.md`
- `.TODO/improvement_the_system/ImplementReady/21_Wallet_System_Escrow_Available_balances/` — 00_HOLISTIC_REPORT.md, 02_GAPS_AND_FIXES.md, 03_RISK_REGISTER.md, 04_TEST_PLAN.md, diagram_consistency_audit/Finance_Wallet_System/03_DEPENDENCY_ORDER.md, 04_GOLDEN_PATH_SYSTEM.md, 05_UI_MAPPING.md, 06_IMPLEMENTATION_PLAN.md, diagram_consistency_audit/21_wallet-system-balances/FULL_REPORT.md
- `.TODO/improvement_the_system/ImplementReady/09_ledger-event-flow/CONTRACT_ledger_event_flow.md`
- `.TODO/improvement_the_system/ImplementReady/16_escrow-invariants-idempotency/` (idempotency evidence + 07_MINIMAL_PATCH_PLAN.md)
- `lib/features/wallet/` (wallet_service.dart, ledger_service.dart, viewmodels, view, models)
- `@mcp:supabase-mcp-server:` — live scan required before Phase 1 execution.
