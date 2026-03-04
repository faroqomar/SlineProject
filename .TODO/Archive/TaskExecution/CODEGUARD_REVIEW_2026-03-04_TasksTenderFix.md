# CodeGuard Review: Tasks Tender Fix

**Scope:** Tasks Tender Fix (tender fail-closed, replace_task_request migration, active_role removal, tests)  
**Plan reference:** `.TODO/PLAN_Tasks_Fix_All_2026-03-01.md`  
**Date:** 2026-03-04  
**Agent:** @CodeGuard  
**Review mode:** HARD-GATE (payments/tender, RLS, RPC)

---

## 1. Files Reviewed

| Path | Risk area |
|------|-----------|
| `lib/features/tasks/services/tender_payment_coordinator.dart` | Payment flow, fail-closed |
| `lib/features/tasks/services/task_requests_service.dart` | RLS, no profile mutation |
| `supabase/migrations/20260311000000_replace_task_request.sql` | RPC, SECURITY DEFINER, RLS |
| `test/unit/tasks/tender_payment_coordinator_test.dart` | Coverage |

---

## 2. Security

| Finding | Severity | Detail |
|---------|----------|--------|
| Tender demo/QiCard fail-closed | ✅ | Coordinator throws before ledger/pay when payment is Demo or QiCard; no state advance. |
| Ledger before pay_awarded_offer | ✅ | LedgerService throws on ok:false; pay_awarded_offer not called after ledger failure. |
| replace_task_request auth | MED | RPC checks v_me = p_freelancer_id and task open/not own. INSERT runs as SECURITY DEFINER; if RLS is bypassed, a user without is_freelancer could insert. Recommend: add explicit is_freelancer(v_me) check before INSERT, or verify RLS still applies to definer INSERT. |
| active_role removal | ✅ | No client-side profile mutation; RLS denial mapped to clear UX message. |
| No secrets in code | ✅ | No tokens or keys in changed files. |

**Security verdict:** No BLOCKER. One MED: harden replace_task_request with is_freelancer check or document/verify RLS behavior.

---

## 3. Performance

| Finding | Severity |
|---------|----------|
| Coordinator type check | LOW — two `is` checks per executePayment; negligible. |
| replaceOffer | Re-fetch after RPC is one extra query; acceptable. |
| No N+1 in changed paths | ✅ |

**Performance verdict:** No BLOCKER.

---

## 4. Compatibility

| Check | Result |
|-------|--------|
| Flutter/Dart | No new dependencies; existing patterns. ✅ |
| Supabase RPC params | replace_task_request params match migration (p_task_id, p_freelancer_id, p_message, p_price, p_days). ✅ |
| task_requests.status | 'withdrawn' used in migration; app enum has withdrawn. ✅ |
| Migration additive | Only CREATE OR REPLACE + GRANT; no drops. ✅ |

**Compatibility verdict:** No BLOCKER.

---

## 5. Verification Commands

```bash
flutter analyze
flutter test test/unit/tasks/tender_payment_coordinator_test.dart test/unit/tasks/task_view_model_test.dart test/unit/models/task_request_model_test.dart
```

Both must pass (already evidenced in execution log).

---

## 6. Freshness / Dependencies

- No new pub dependencies in this change set. General project freshness: run `flutter pub outdated` per project policy.

---

## 7. Decision

**APPROVED ✅** with one MED recommendation (replace_task_request is_freelancer or RLS verification). No BLOCKER; pipeline may proceed. Fix MED in a follow-up or accept as documented risk.
