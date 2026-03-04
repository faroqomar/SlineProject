# CodeGuard Review: Award to Work Waiting Payment

**Date:** 2026-03-04  
**Scope:** Award to Work Waiting Payment  
**Plan:** Award → Work Section + Waiting Payment + Cancel

---

## 1. Performance

- **fetchWorkItems:** Single query to vw_unified_work_items + direct offers + batch profile enrichment. No N+1. **OK.**
- **Cancel/Pay from Work:** Single RPC (cancel_awarded_offer) or navigation to TenderPaymentScreen; refresh after cancel is full reload. Acceptable for current scope.
- **View:** Third branch of vw_unified_work_items is a JOIN (tasks + task_requests) with filters; index on task_requests(task_id, status, payment_status) would help. Not verified in repo. **LOW.**

---

## 2. Security

- **cancel_awarded_offer:** SECURITY DEFINER, validates `v_task.owner_id = p_client_id`. Only accepted/unpaid requests are reverted. **OK.**
- **award_task_offer** (existing): Owner check via task.owner_id. **OK.**
- **vw_unified_work_items:** Security invoker; RLS on base tables. Client sees only their client_id rows. **OK.**
- **App:** No sensitive data (cards, request ids) logged beyond existing AppLogger usage. **OK.**

---

## 3. Compatibility

- **tasks.client_id:** Migration uses COALESCE(t.client_id, t.owner_id). If schema has only owner_id, works. If both exist, works. **OK.**
- **UnifiedWorkItemModel / WorkItem:** New optional fields (awardedRequestId, paymentDeadline, price); fromJson/toJson handle null. **OK.**
- **WorkItem.fromJson (cache):** New keys awardedRequestId, paymentDeadline, price; optional. Old cache without these still parses. **OK.**

---

## 4. Risk Rating

| Area | Rating | Note |
|------|--------|------|
| Security | LOW | RPC and view properly scoped |
| Data integrity | LOW | Cancel reverts state consistently |
| Performance | LOW | No new N+1; view branch may benefit from index |
| Compatibility | LOW | Optional fields; COALESCE for client_id |

---

## 5. Verification Commands

```bash
flutter analyze lib/features/dashboard lib/features/work/models/unified_work_item_model.dart lib/features/tasks/services/task_service.dart
```

```bash
# After applying migration (Supabase)
# Verify view returns rows for awarded-unpaid task:
# SELECT id, unified_status, awarded_request_id FROM vw_unified_work_items WHERE unified_status = 'pending_payment';
```

---

## 6. Freshness Checks

- Migration 20260315000000 is self-contained (cancel_awarded_offer + view). Depends on task_requests and tasks schema from earlier migrations (20260313000000 drops tasks_assigned_requires_freelancer). **Order correct.**

---

## 7. Blockers

- **None.** No BLOCKER identified.

---

**Decision: APPROVED ✅**

No blocking issues. Optional: add index on task_requests(task_id, status, payment_status) for the view’s third branch; add Observability-recommended logs in work_tab; apply doc updates from SlineDocs report.
