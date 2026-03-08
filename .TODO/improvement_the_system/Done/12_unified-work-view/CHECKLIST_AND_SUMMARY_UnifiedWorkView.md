# Unified Work View — What Changed & How to Check

## What we did (short)

**Goal:** Work list and work detail come only from the database view `vw_unified_work_items`. No more fallback logic in the app; if the view has no row, the app shows “not found”.

### Added
- **DB:** 4th branch in the view for **direct offers** (alias `doff`), plus dispute override and `security_invoker = true`.
- **App:** Support for `source_type == 'direct_offer'` → `WorkItemType.directOffer` and `conversationId` so direct-offer items open the right chat.
- **Logging:** `AppLogger` in work service (load/list/error), dashboard repo (fetch start/success/error), work-detail VM (not-found + success with tag `WorkDetails`; list success with tag `WorkManagement`).
- **Tests:** `unified_work_item_view_contract_test.dart` (fromJson for task, direct_offer, pending_payment, conversation_id).
- **Docs:** SUPABASE_SETUP §6.4, DEVELOPER_GUIDE work section, contract file, rollback migration, execution log, RLS check note.

### Removed
- **App:** `UnifiedWorkItemFallbackMapper` and `unified_work_item_fallback_mapper.dart` (task fallback).
- **App:** Dashboard repo fallbacks: `_fetchAwardedPendingPaymentFallback`, `_fetchDirectOffers`, and merging with view data.
- **App:** Work-detail “booking fallback” when the view returns no row (now we only show error + log).
- **Tests:** `unified_work_item_fallback_mapper_test.dart` (replaced by view contract test).

### Modified
- **DB:** View `vw_unified_work_items` upgraded (4 branches, disputes, `conversation_id`, `security_invoker`).
- **App:** `WorkManagementService` — single view for get + list; type-safe `Map<String, dynamic>.from(e as Map)` in list; success log with count.
- **App:** `DashboardRepository` — single view query and `_mapUnifiedToWorkItem` with direct_offer branch and `conversationId`.
- **App:** `WorkItemDetailsViewModel` — no fallback; comment updated (“optional booking for booking-type detail”); logs tagged `WorkDetails`.
- **Docs:** `Sline_Log.md` — fallback mapper bullet replaced by “single source of truth from view” description.

---

## Why

- **Single source of truth:** One view, one query path; no duplicated or conflicting fallback logic.
- **Direct offers in work list:** Clients and providers see direct-offer items and can open the right conversation.
- **Clear “not found”:** If the view has no row (e.g. no access, wrong id), user sees “Work item not found” instead of a wrong fallback.
- **Security:** View runs with `security_invoker = true` so RLS applies correctly.
- **Observability:** Tagged logs (`WorkDetails`, `WorkManagement`) and success/count logs make debugging and monitoring easier.

---

## Checklist — What to check in the app

Use this on a real device/emulator with real (or test) data.

### Work list (dashboard / work tab)

- [ ] **As client:** Work list loads and shows your tasks, bookings, awarded-pending-payment items, and **direct offers** (if any). No crash, no empty list when data exists.
- [ ] **As provider:** Same: tasks, bookings, awarded-pending, **direct offers** (if any). No crash.
- [ ] **Empty state:** If you have no work items, list is empty (no error). Optional: check logs for “Listed unified work items from view” with `count: 0`.

### Work detail (tap an item)

- [ ] **Task / booking / awarded-pending:** Detail screen opens with correct title, status, and actions. No “Work item not found” when the item exists.
- [ ] **Direct offer:** Detail opens and (if implemented) “Open chat” or similar uses the correct **conversation** (conversation_id from view).
- [ ] **Not found:** Open a detail for an id that doesn’t exist or you’re not allowed to see (e.g. another user’s item). You should see **“Work item not found”** (no wrong data, no booking fallback). Optional: check logs for “Work item detail: view returned no row” with tag `WorkDetails`.

### Logs (optional)

- [ ] On loading work list: one “Listed unified work items from view” with tag `WorkManagement` and `count` (and `isClient`).
- [ ] On loading work detail successfully: “Work item details loaded” with tag `WorkDetails`.
- [ ] On not-found detail: “Work item detail: view returned no row” with tag `WorkDetails`.

### Regression

- [ ] No new crashes on app start, dashboard open, or work list/detail.
- [ ] Existing flows (create task, book, accept bid, etc.) still work; only the **data source** for list/detail changed (view only, no fallbacks).

---

## One-line summary

**We moved work list and detail to a single DB view (`vw_unified_work_items`) with 4 branches including direct offers, removed all fallback mappers and merge logic, and added tagged logging; use the checklist above to confirm list, detail, direct offers, and “not found” behave correctly in the app.**
