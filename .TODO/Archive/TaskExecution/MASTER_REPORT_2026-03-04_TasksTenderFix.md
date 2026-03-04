# Master Report: Tasks Tender Fix — Multi-Agent Review

**Scope:** Tasks Tender Fix (PLAN_Tasks_Fix_All_2026-03-01 executed subset)  
**Plan reference:** `.TODO/PLAN_Tasks_Fix_All_2026-03-01.md`  
**Date:** 2026-03-04  
**Orchestrator:** Per `.agents/workflows/orchestrator.md`  
**Pipeline:** @Architect → @Observability → @SlineDocs → @CodeGuard

---

## A) Executive Summary

| Item | Result |
|------|--------|
| **What was reviewed** | Tender payment fail-closed (TenderPaymentCoordinator), active_role removal and RLS error mapping (TaskRequestsService), replace_task_request migration, coordinator unit tests. |
| **Overall risk level** | **LOW–MED** (payment/RLS touched; no BLOCKERs). |
| **Final decision** | **Ready ✅** — CodeGuard APPROVED with one MED recommendation to address in follow-up. |

---

## B) Consolidated Findings (Deduplicated)

### Security

| ID | Severity | Owner | Location | Fix |
|----|----------|--------|----------|-----|
| S1 | MED | CodeGuard / Architect | `supabase/migrations/20260311000000_replace_task_request.sql` | Add explicit `is_freelancer(v_me)` check before INSERT, or verify in Postgres that RLS still applies to SECURITY DEFINER INSERT so non-freelancers cannot insert. |

All other security findings: tender fail-closed ✅, ledger gate ✅, no profile mutation ✅, no secrets ✅.

### Data Integrity

| ID | Severity | Owner | Location | Fix |
|----|----------|--------|----------|-----|
| — | — | — | No data-integrity blockers. | replace_task_request withdraws then inserts; params match Flutter. |

### Architecture / MVVM

| ID | Severity | Owner | Location | Fix |
|----|----------|--------|----------|-----|
| A1 | LOW | Architect | `tender_payment_coordinator.dart` | Optional: when adding a real tender payment service, introduce a marker interface or remove QiCard check to avoid coupling to concrete types. |

MVVM boundaries respected; no view-layer Supabase or direct service misuse.

### Performance

| ID | Severity | Owner | Location | Fix |
|----|----------|--------|----------|-----|
| — | — | — | No performance blockers. | Type checks and re-fetch after replace are acceptable. |

### Observability

| ID | Severity | Owner | Location | Fix |
|----|----------|--------|----------|-----|
| O1 | LOW | Observability | `task_requests_service.dart` replaceOffer | Optional: add AppLogger.i on successful replace. |
| O2 | LOW | Observability | Future | Optional: correlation ID across award → pay → ledger. |

No print(); AppLogger used; no PII/secrets in logs.

### Docs / Reference Integrity

| ID | Severity | Owner | Location | Fix |
|----|----------|--------|----------|-----|
| D1 | MED | SlineDocs | SUPABASE_SETUP.md | Add changelog entry for migration 20260311000000_replace_task_request.sql. |
| D2 | MED | SlineDocs | DEVELOPER_GUIDE.md | Document tender fail-closed (demo/QiCard) and active_role removal for offer submit. |
| D3 | LOW | SlineDocs | Sline_Log.md / MVP_ROADMAP | Optional: log Tasks Tender Fix and tender hardening status. |

No broken refs; paths and names validated.

---

## C) Fix Plan (Ordered, Step-by-Step)

| Step | Owner | Action | Verification |
|------|--------|--------|----------------|
| 1 | @Supabase_Ops or @Architect | Harden replace_task_request: add is_freelancer(v_me) check before INSERT (or document that RLS applies to definer). | Re-run migration or apply patch; regression test replace flow. |
| 2 | @SlineDocs | Update SUPABASE_SETUP.md changelog with 20260311000000_replace_task_request and replace_task_request now in repo. | Grep changelog for migration name. |
| 3 | @SlineDocs | Update DEVELOPER_GUIDE.md (or Task Feature): tender fail-closed when Demo/QiCard; offer submit no longer mutates active_role; RLS/UX message. | Read Task/tender section for new wording. |
| 4 | @Observability (optional) | Add AppLogger.i on replaceOffer success in TaskRequestsService. | Log present in replace path. |
| 5 | @CodeGuard | Re-run review after Step 1 if migration changed. | CODEGUARD_REVIEW updated; no BLOCKER. |

---

## D) Regression Checklist

| Flow | How to test quickly |
|------|----------------------|
| Tender payment (demo / QiCard) | Run app; open tender payment screen; attempt pay → expect fail-closed message; no ledger/pay RPC. |
| Tender payment (real path) | When real payment service exists: pay → ledger then pay_awarded_offer; success. |
| Submit offer (freelancer) | As freelancer, submit offer on open task → success. |
| Submit offer (non-freelancer) | As client-only, submit offer → RLS deny + “Switch to freelancer mode” message. |
| Replace offer | As freelancer with pending offer, replace → RPC success; re-fetch shows new offer. |
| Unit tests | `flutter test test/unit/tasks/tender_payment_coordinator_test.dart` — all 4 tests pass. |

---

## E) Rollback Notes

| Area | Rollback |
|------|----------|
| TenderPaymentCoordinator | Revert fail-closed checks (remove Demo/QiCard branches) to allow demo path again; not recommended for production. |
| TaskRequestsService | Revert to re-add profiles.active_role update before insert; redeploy. |
| replace_task_request | Migration is additive. To “roll back”: revoke EXECUTE or drop function; Flutter replaceOffer will fail at RPC until reverted or new RPC. Keep migration in repo for new envs. |
| Tests | Revert new coordinator tests if coordinator behavior is reverted. |

---

## F) Next Actions

1. **Recommended:** Apply Step 1 (replace_task_request is_freelancer or RLS verification) and Step 2–3 (docs).
2. **Optional:** Apply Step 4 (replace success log) and Step 5 (CodeGuard re-check if migration changed).
3. **Ongoing:** Run regression checklist after any change to tender or task-request flows.
4. **Pipeline:** No BLOCKER; pipeline complete. No PIPELINE_BLOCKED file issued.
