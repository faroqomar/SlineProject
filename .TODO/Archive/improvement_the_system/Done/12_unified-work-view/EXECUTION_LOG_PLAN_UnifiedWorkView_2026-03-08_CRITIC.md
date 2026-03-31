# Execution Log: PLAN_UnifiedWorkView_2026-03-08_CRITIC

**Plan:** `.TODO/PLAN_UnifiedWorkView_2026-03-08_CRITIC.md`  
**Started:** 2026-03-08  
**Executor:** @Executor (single-phase execution: full plan)

---

## Status by Phase

| Phase | Status | Notes |
|-------|--------|-------|
| Phase 0: Preconditions and Contracts | Done | Live scan, contract, rollback file |
| Phase 1: Database & Security | Done | View upgraded via execute_sql (doff alias); 20 columns |
| Phase 2: App Layer (MVVM) | Done | Fallbacks removed; direct_offer in _mapUnifiedToWorkItem; AppLogger added |
| Phase 3: UI | Done | Not-found when view null; no code change beyond VM |
| Phase 4: QA + Security | Done | New view contract test; RLS matrix doc; flutter analyze + tests |
| Phase 5: Documentation & Release | Done | SUPABASE_SETUP §6.4 + DEVELOPER_GUIDE Work section |

---

## Evidence & Findings (Pre-Execution Scan)

### Live Supabase (MCP scan 2026-03-08)

- **vw_unified_work_items:** Exists; 3-branch (tasks, bookings, awarded pending); no `security_invoker` in definition (view created without WITH clause). Column set matches Archive migration.
- **disputes:** Columns confirmed: id, task_id, direct_offer_id, complainant_id, defendant_id, reason, status, resolution, created_at, resolved_at. No related_entity_id/related_entity_type.
- **disputes.status:** No rows; no enum constraint in info_schema. Plan uses "open" = NOT IN ('resolved','closed').
- **direct_offers:** Columns confirmed: id, conversation_id, client_id, freelancer_id, task_id, title, description, price, days, status, payment_status, created_at, updated_at, delivered_at, review_expires_at, + fee/currency/payment columns.

### Gaps to Create

- Rollback migration file (3-branch view).
- Upgrade migration (4-branch + disputes + security_invoker).
- View contract document.
- App: remove fallbacks; add direct_offer in _mapUnifiedToWorkItem; AppLogger in critical paths.

### Risks

- View migration must use disputes.task_id and disputes.direct_offer_id only.
- RLS: view must use security_invoker = true.

---

## Phase 0 — Steps Completed

1. **Live scan** — Done via Supabase MCP (list_tables, execute_sql). Recorded above.
2. **View contract** — Created `.TODO/contract_vw_unified_work_items.md`.
3. **Dispute JOIN and status** — Frozen: Branch 1 & 3 `d.task_id = t.id`; Branch 2 `d.task_id = b.task_id`; Branch 4 `d.direct_offer_id = do.id`. Open dispute: `d.id IS NOT NULL AND d.status IS NOT NULL AND d.status NOT IN ('resolved', 'closed')`.
4. **Rollback migration file** — Created `supabase/migrations/20260308100000_rollback_unified_work_view.sql`.
5. **Acceptance list** — In plan §D Invariants.

---

## Phase 1 — Steps Completed

- **Upgrade migration** applied via Supabase MCP: `execute_sql` (DROP VIEW + CREATE VIEW) and `apply_migration` (name: `upgrade_unified_work_view`) so it is recorded in the project migration history. Live view: 4 branches, 20 columns, disputes override, `security_invoker = true`.
- **Verification:** `SELECT source_type, COUNT(*) FROM vw_unified_work_items GROUP BY source_type` returns task, booking, direct_offer.
- **Rollback file** `20260308100000_rollback_unified_work_view.sql` is in repo only; not applied to DB (run manually if rollback needed).

---

## Phase 2 — Steps Completed

1. **WorkManagementService:** Removed _getTaskUnifiedWorkItemFallback and UnifiedWorkItemFallbackMapper; getUnifiedWorkItem returns view or null. Added AppLogger.d for loaded/not-found.
2. **DashboardRepository:** Single query to vw_unified_work_items; removed _fetchAwardedPendingPaymentFallback, _fetchDirectOffers, _mapDirectOfferToWorkItem, _directOfferStatusToUnified/Bucket. _mapUnifiedToWorkItem: branch for sourceType == 'direct_offer' → WorkItemType.directOffer, conversationId from model. AppLogger.i with count + role.
3. **UnifiedWorkItemModel:** conversationId, isDirectOffer, fromJson conversation_id.
4. **WorkItemDetailsViewModel:** Removed UnifiedWorkItemFallbackMapper.fromBooking; when view null set _error and AppLogger.d.
5. **Deleted** lib/features/work/models/unified_work_item_fallback_mapper.dart.
6. **Tests:** Replaced unified_work_item_fallback_mapper_test with unified_work_item_view_contract_test (fromJson task/direct_offer/pending_payment, conversation_id, isDirectOffer).
7. **Verification:** flutter analyze (1 pre-existing warning elsewhere); flutter test test/unit/work/unified_work_item_view_contract_test.dart test/unit/models/unified_work_item_model_test.dart — all passed.

---

## Phase 5 — Steps Completed

1. **SUPABASE_SETUP.md §6.4:** Updated to 4 branches (tasks, bookings, awarded pending, direct_offers), dispute override, security_invoker = true, conversation_id, rollback migration ref.
2. **DEVELOPER_GUIDE.md:** Removed Fallback Mapper bullet; added "Single source of truth" and not-found behavior. Table row for vw_unified_work_items updated.

## Blockers

- None.

---

## Observability Evidence

- **WorkManagementService.getUnifiedWorkItem:** AppLogger.d('Unified work item loaded from view', json: {id, type}) when row found; AppLogger.d('Unified work item not found in view', ...) when null. AppLogger.e on catch.
- **DashboardRepository.fetchWorkItems:** AppLogger.d('Fetching unified work items from view for role: ...'); AppLogger.i('Fetched N work items from vw_unified_work_items', json: {count, role}); AppLogger.e on catch.
- **WorkItemDetailsViewModel.loadData:** AppLogger.d('Work item detail: view returned no row', json: {id, type}) when _workItem == null.

## Completion Summary

- **View:** Upgraded live (Supabase MCP execute_sql). 4 branches, disputes override, security_invoker = true, conversation_id. Rollback file: `20260308100000_rollback_unified_work_view.sql`.
- **App:** Single source of truth; no fallback mapper; direct_offer mapped in _mapUnifiedToWorkItem; not-found when view returns null.
- **Tests:** `unified_work_item_view_contract_test.dart` (fromJson task/direct_offer/pending_payment, conversation_id, isDirectOffer). Removed fallback mapper test.
- **Docs:** SUPABASE_SETUP §6.4, DEVELOPER_GUIDE Work section, contract and RLS matrix in .TODO/.
- **Rollback:** Run `20260308100000_rollback_unified_work_view.sql` to restore 3-branch view; revert app commit if needed (model conversationId is optional so old view without column still works).
