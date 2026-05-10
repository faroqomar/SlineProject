# 📌 Plan: Unified Work View (12_unified-work-view)

## 1) Goal

- **Goal:** Upgrade `vw_unified_work_items` to a single source of truth that includes Tasks, Bookings, Awarded (unpaid) Tasks, and **Direct Offers**, with dispute status override and RLS-safe `security_invoker`, and remove all Flutter fallback mappers so the app reads only from the view.
- **Why:** Direct offers are currently missing from the view, causing "ghost" items; dispute status is not reflected; view may not enforce RLS; and duplicate logic in Dart (fallback mappers + direct_offer merge) creates drift risk.
- **Result:** One feed for "My Work" with four item types, correct `disputed`/`pending_payment` status, no fallback code, and view that respects RLS via `security_invoker`.

---

## 2) Scope

### In-Scope

- Replace `vw_unified_work_items` with a 4-branch UNION ALL (Tasks in progress, Bookings, Awarded pending payment, **Direct Offers**).
- Add LEFT JOIN to `disputes` in each branch and override `unified_status` to `'disputed'` when an open dispute exists.
- Create view with `WITH (security_invoker = true)`.
- Remove `UnifiedWorkItemFallbackMapper` and all usages; remove `_getTaskUnifiedWorkItemFallback`, `_fetchAwardedPendingPaymentFallback`, `_fetchDirectOffers` and merge logic from Dashboard/Work services.
- Update `DashboardRepository._mapUnifiedToWorkItem` to map `source_type == 'direct_offer'` to `WorkItemType.directOffer`.
- Ensure `UnifiedWorkItemModel` and `UnifiedWorkStatus` support `direct_offer` and `disputed` (model already supports; enum has `disputed`).
- Update tests that depend on fallback mapper; remove or repurpose fallback mapper tests.
- Documentation sync (SUPABASE_SETUP §6.4, DEVELOPER_GUIDE Work Management, STRUCTURE if needed).

### Out-of-Scope

- Changes to `direct_offers` or `disputes` table schema.
- New RPCs or triggers for work items.
- UI redesign of work/dashboard screens (only wiring to single view).
- Observability instrumentation beyond optional logging of "loaded from view" (Phase 0 in spec).

---

## 3) Evidence & Findings (From Scan)

### Existing

- **View definition:** `supabase/migrations/Archive/20260315000000_award_to_work_cancel_and_view.sql` — 3 branches (tasks in progress, bookings, awarded pending payment). No `security_invoker`; no disputes join; no direct_offers.
- **Docs:** `Sline_everything/SUPABASE_SETUP.md` §6.4 describes 3-branch view; §5.14 `direct_offers`; §5.24 `disputes` with columns `task_id`, `direct_offer_id` (no `related_entity_id`/`related_entity_type`).
- **Flutter:**  
  - `lib/features/work/services/work_management_service.dart` — `getUnifiedWorkItem` uses view then `_getTaskUnifiedWorkItemFallback` for task; `listUnifiedWorkItems` from view only.  
  - `lib/features/dashboard/data/dashboard_repository.dart` — fetches from view, then `_fetchAwardedPendingPaymentFallback`, then `_fetchDirectOffers` and merges/sorts.  
  - `lib/features/work/models/unified_work_item_fallback_mapper.dart` — maps task_request+task and booking to `UnifiedWorkItemModel`.  
  - `lib/features/work/viewmodels/work_item_details_view_model.dart` — uses `UnifiedWorkItemFallbackMapper.fromBooking` when view returns null and booking exists.  
  - `lib/features/work/models/unified_work_item_model.dart` — `sourceType` string, `_mapStatus` includes `disputed`; has `isTask`/`isBooking` (no `isDirectOffer` needed if mapping in repo).  
  - `lib/features/dashboard/models/work_item.dart` — `WorkItemType.directOffer` exists; dashboard already maps direct offers to `WorkItem` via `_mapDirectOfferToWorkItem`.
- **Spec folder:** `.TODO/improvement_the_system/ImplementReady/12_unified-work-view/` — 00_HOLISTIC_REPORT, 02_GAPS_AND_FIXES, 03_RISK_REGISTER, 04_TEST_PLAN, 07_SYSTEM_CRITIC_VERDICT, **08_PATCH_PLAN** (SQL + Flutter cleanup).

### Missing

- Live view in non-archived migration: current view may be created by a migration that’s not in Archive (to be confirmed by Supabase live scan).
- RLS check matrix file in `.TODO/` for the view (optional; plan Phase 1.2).

### Conflicts / Risks (docs vs code vs live DB drift, naming mismatches, security/migration risks)

- **Disputes JOIN:** `08_PATCH_PLAN.md` uses `d.related_entity_id` and `d.related_entity_type` on `disputes`. **SUPABASE_SETUP §5.24** states `disputes` has `task_id` and `direct_offer_id` only. Migration SQL **must** use: Branch 1 & 3 `LEFT JOIN disputes d ON d.task_id = t.id`; Branch 2 `LEFT JOIN disputes d ON d.task_id = b.task_id`; Branch 4 `LEFT JOIN disputes d ON d.direct_offer_id = do.id`. Override when `d.id IS NOT NULL AND d.status NOT IN ('resolved', 'closed')` (or equivalent).
- **View location:** Archived migration suggests the view may have been re-applied or superseded elsewhere; live DB scan will confirm current definition and whether `security_invoker` is set.
- **Column types:** All UNION branches must return identical types (e.g. `price` numeric, `work_item_id` text). Patch plan’s Branch 4 uses `('direct_offer:' || do.id::text)` — consistent with existing `work_item_id` pattern.
- **direct_offers columns:** Patch uses `do.status`, `do.days`, `do.created_at`, `do.updated_at`, `do.price`, `do.client_id`, `do.freelancer_id`, `do.title`. Match `SUPABASE_SETUP` §5.14 (e.g. `days` is int; deadline as `created_at + (days || ' days')::interval`).
- **Regression:** Removing fallback mappers can break work detail or dashboard if view RLS or branch logic excludes rows that were previously shown via fallback; Phase 4 QA must cover awarded-pending-payment and direct-offer flows.

---

## 4) System Impact Map

- **UI:** Dashboard "My Work" and Work detail screen; no new screens; same lists with direct offers and disputed items coming from view only.
- **MVVM/App Logic:** `WorkManagementService`, `DashboardRepository`, `WorkItemDetailsViewModel`; removal of fallback paths and direct_offer merge; `_mapUnifiedToWorkItem` extended for `direct_offer`.
- **Database:** One view replacement (`vw_unified_work_items`); no new tables; optional indexes on `tasks(assigned_freelancer_id, status)` and `bookings(status, provider_id)` if not present (scale phase).
- **RLS/Security:** View must use `WITH (security_invoker = true)` so RLS on `tasks`, `bookings`, `task_requests`, `direct_offers` applies; no RLS on view itself.
- **Realtime/Notifications:** None.
- **Storage:** None.
- **Observability:** Optional: log when item is loaded from view vs not found (until fallbacks removed, then N/A).
- **Compatibility & Migration:** New migration replaces view; app change is coordinated (view first, then app); no backward compatibility window for old app.
- **Contracts:** View column contract (id, source_type, source_status, unified_status, title, price, deadline, client_id, freelancer_id, delivered_at, review_expires_at, revisions_total, revisions_used, work_item_id, last_activity_at, needs_review, sort_rank, awarded_request_id, payment_deadline) unchanged; new rows with `source_type = 'direct_offer'`.

---

# ✅ Execution Phases (Checklist)

## Phase 0: Preconditions & Gates

> Primary: @Sentinel

### 0.1 Spec Lock

- [ ] (@Sentinel) Acceptance: (1) All 4 source types appear in My Work when applicable; (2) Disputed items show unified_status delivered/active overridden to disputed; (3) RLS: User A cannot see User B’s items via view; (4) No fallback mapper or _fetchDirectOffers/_fetchAwardedPendingPaymentFallback in codebase. Non-regression: existing task/booking flows unchanged.
- [ ] (@Architect) Confirm modules: `lib/features/work/` (service, models, viewmodel), `lib/features/dashboard/data/dashboard_repository.dart`, entry points: Dashboard Work tab, Work detail screen.
- **Verify (@Sentinel):** Done-conditions and rollback triggers documented in §8.

### 0.2 Threat Model (If sensitive/high-risk)

- [ ] (@ThreatModeler) Threat model for unified view: RLS bypass (view as definer), cross-tenant leak. Mitigation: `security_invoker = true`; negative test: query as User B must not return User A’s rows. Document in `.TODO/` if new file created.
- **Verify (@Sentinel):** Security checks included in Phase 4.2.

### 0.3 Contracts (If payloads change)

- [ ] (@APIContract) Contract: view columns and types; `source_type` values `task` | `booking` | `direct_offer`; `unified_status` includes `disputed`, `pending_payment`. Optional: `.TODO/` contract file for Flutter ↔ view.
- **Verify (@Sentinel):** Contract matches migration SQL and `UnifiedWorkItemModel.fromJson`.

### 0.4 Migration Plan (If schema/data changes)

- View replacement only; no table migrations. Rollback: re-create view from previous 3-branch definition (and optionally without security_invoker if restoring exact prior state).
- **Verify (@Sentinel):** Rollback SQL documented in §8.

### 0.5 Feature Flag/Rollout (If risky)

- [ ] (@Architect) Optional: no feature flag required; view + app deploy together. If desired, can gate “use view only” behind a flag and keep fallbacks temporarily.
- **Verify (@Sentinel):** Rollback path documented.

---

## Phase 1: Database & Security

> Primary: @Supabase_Ops

### 1.0 Live Supabase Confirmation (MANDATORY)

- [ ] (@Supabase_Ops) Scan live DB via MCP (`list_tables`, `execute_sql` for `\d vw_unified_work_items` equivalent) for: `vw_unified_work_items` definition, `direct_offers` and `disputes` columns (task_id, direct_offer_id), existing indexes on tasks/bookings.
- [ ] (@Supabase_Ops) Confirm no naming/type conflicts; note if view already has `security_invoker` or different column set.
- **Verify (@Sentinel):** Drift and safe approach recorded in execution log or plan appendix.

### 1.1 Schema (Additive-first)

- [ ] (@Supabase_Ops) Create migration (e.g. `supabase/migrations/YYYYMMDD_upgrade_unified_work_view.sql`): `DROP VIEW IF EXISTS public.vw_unified_work_items;` then `CREATE VIEW public.vw_unified_work_items WITH (security_invoker = true) AS` with 4 branches. Branch 1: tasks (in_progress, delivered, completed) + LEFT JOIN disputes ON d.task_id = t.id. Branch 2: bookings + LEFT JOIN disputes ON d.task_id = b.task_id. Branch 3: awarded pending payment (unchanged). Branch 4: direct_offers (accepted, active, delivered, completed) + LEFT JOIN disputes ON d.direct_offer_id = do.id. All branches: same column list; dispute override `CASE WHEN d.id IS NOT NULL AND d.status NOT IN ('resolved', 'closed') THEN 'disputed' ELSE ...`. Use `SUPABASE_SETUP` §5.14/5.24 for column names (no related_entity_id on disputes).
- [ ] (@Supabase_Ops) Ensure UNION ALL column types align (numeric, text, timestamptz, uuid).
- **Verify (@Sentinel):** No leak/break; naming consistent with docs.

### 1.2 RLS

- [ ] (@Supabase_Ops) View uses `security_invoker = true`; no separate RLS on view. RLS on base tables (tasks, bookings, task_requests, direct_offers) applies to view query.
- [ ] (@Supabase_Ops) Optional: add RLS check matrix to `.TODO/` (user A/B, client/freelancer, expected rows).
- **Verify (@Sentinel):** Negative: User B cannot see User A’s items. Positive: User sees own items for all 4 types.

### 1.3 Triggers/RPC (If needed)

- Not required for view.
- **Verify (@Sentinel):** N/A.

### 1.4 Migration Execution (If needed)

- [ ] (@DataMigration or @Supabase_Ops) Apply migration to target environment (e.g. via Supabase MCP `apply_migration` or dashboard).
- **Verify (@Sentinel):** Query `vw_unified_work_items` returns expected columns and sample rows for each branch.

---

## Phase 2: App Layer (MVVM)

> Primary: @Architect

### 2.1 Models & Contract Compliance

- [ ] (@Architect) `UnifiedWorkItemModel`: already accepts `source_type` string; ensure `fromJson` handles `source_type == 'direct_offer'`; add `isDirectOffer` getter if used, or rely on `_mapUnifiedToWorkItem`. Confirm `_mapStatus` handles `'disputed'` (already does).
- [ ] (@Architect) No new DTOs; view row shape = existing contract.
- **Verify (@Sentinel):** Types and nullability match view columns; `direct_offer` and `disputed` round-trip.

### 2.2 Services/Repositories

- [ ] (@Architect) **WorkManagementService:** Remove `_getTaskUnifiedWorkItemFallback` and call to it; remove import of `UnifiedWorkItemFallbackMapper`. `getUnifiedWorkItem` returns view result or null (no fallback). Keep `listUnifiedWorkItems` as-is (view only).
- [ ] (@Architect) **DashboardRepository:** Remove `_fetchAwardedPendingPaymentFallback` and `_fetchDirectOffers`; remove merge/sort of direct offers and fallback list; single query to `vw_unified_work_items` filtered by client_id/freelancer_id. Remove `_mapDirectOfferToWorkItem` and `_directOfferStatusToUnified` / `_directOfferStatusToBucket` if only used for merged direct offers. Update `_mapUnifiedToWorkItem` to map `u.sourceType == 'direct_offer'` to `WorkItemType.directOffer` (and set status/sort from unified row).
- [ ] (@Architect) Delete `lib/features/work/models/unified_work_item_fallback_mapper.dart`. Remove all imports/usages (WorkManagementService, DashboardRepository, WorkItemDetailsViewModel).
- [ ] (@Architect) Storage: N/A. No N+1; single view query.
- **Verify (@Sentinel):** No UI→Supabase except via service/repo; no remaining fallback or direct_offers merge.

### 2.3 ViewModels

- [ ] (@Architect) **WorkItemDetailsViewModel:** Remove use of `UnifiedWorkItemFallbackMapper.fromBooking` when view returns null; optionally keep booking-only fallback only if product accepts “detail from booking when view has no row” (else remove and show not-found). For `type == 'direct_offer'`, ensure detail loads from view (getUnifiedWorkItem(id, 'direct_offer')).
- [ ] (@Architect) **DashboardViewModel:** No direct change if repository API unchanged; ensure it uses single list from repo.
- **Verify (@Sentinel):** Recoverable state; no duplicated query paths.

### 2.4 Observability (If needed)

- [ ] (@Observability) Optional: log when work item is loaded from view vs null (until fallbacks removed). After cleanup, no special event required.
- **Verify (@Sentinel):** No sensitive data in logs.

---

## Phase 3: UI (After logic)

> Primary: @Pixel

### 3.1 Wiring

- [ ] (@Pixel) Dashboard Work tab and Work detail: already consume ViewModel/repo; ensure loading/empty/error states when view returns no item (e.g. direct_offer detail by id/type).
- [ ] (@Pixel) Work item cards and next actions: already support `WorkItemType.directOffer`; no change if repo returns correct type from view.
- **Verify (@Sentinel):** Stable UX when view returns empty or single item.

### 3.2 Polish (Optional)

- [ ] (@Pixel) Optional micro-interactions; low risk only.
- **Verify (@Sentinel):** No perf regression.

---

## Phase 4: QA + Security (MANDATORY)

> Primary: @Sentinel

### 4.1 Contract + Migration Checks

- [ ] (@Sentinel) View column list and types match contract; Flutter `fromJson` and `_mapUnifiedToWorkItem` handle all source_type and unified_status values.
- [ ] (@Sentinel) Run migration verification query (4 branches return rows with correct source_type).
- **Verify (@Sentinel):** No mismatch.

### 4.2 Security + Abuse Tests

- [ ] (@Sentinel) RLS: As User A, select from view; as User B, select from view; assert no overlap of ids. Optionally use `SET ROLE` / `auth.uid()` simulation if available.
- [ ] (@Sentinel) Storage: N/A for this feature.
- **Verify (@Sentinel):** Unauthorized access impossible.

### 4.3 Functional QA

- [ ] (@Sentinel) Remove or repurpose `test/unit/work/unified_work_item_fallback_mapper_test.dart` and any test that depends on `UnifiedWorkItemFallbackMapper`; add or adjust tests for view-only path and `_mapUnifiedToWorkItem` with `direct_offer`.
- [ ] (@Sentinel) Manual E2E: Create task (in progress), booking (active), awarded unpaid task, direct offer (accepted then active). Open My Work as client and freelancer; assert all appear with correct status. Open work detail for each type; assert no crash and correct data.
- [ ] (@Sentinel) Dispute: File dispute on a task; refresh dashboard; assert status shows Disputed where expected.
- [ ] (@Sentinel) Edge: network error, null view row for valid id/type — app shows not-found or error, no crash.
- **Verify (@Sentinel):** No crashes; consistent behavior.

### 4.4 Observability Validation (If included)

- [ ] (@Sentinel) If logging added: required events present and non-sensitive.
- **Verify (@Sentinel):** Actionable without PII leak.

---

## Phase 5: Documentation Sync (MANDATORY)

> Primary: @DocsKeeper

- [ ] (@DocsKeeper) Update `Sline_everything/SUPABASE_SETUP.md` §6.4: view now 4 branches (tasks, bookings, awarded pending, direct_offers); disputes override; `security_invoker = true`; column list unchanged.
- [ ] (@DocsKeeper) Update Work Management section in `Sline_everything/DEVELOPER_GUIDE.md` if it references fallback or direct-offer merge; state that view is single source of truth.
- [ ] (@DocsKeeper) Optional: STRUCTURE.md or MVP_ROADMAP if Work/dashboard behavior is summarized there.
- **Verify (@Sentinel):** Docs match code and live view.

---

## 7) Acceptance Criteria (MANDATORY)

- All four item types (task in progress, booking, awarded pending payment, direct offer) appear in My Work when applicable for the current user.
- Disputed items show `unified_status = disputed` in UI where applicable.
- RLS: Querying the view as one user does not return another user’s work items.
- No references to `UnifiedWorkItemFallbackMapper`, `_getTaskUnifiedWorkItemFallback`, `_fetchAwardedPendingPaymentFallback`, or `_fetchDirectOffers` merge in codebase (except tests that assert their removal or legacy behavior).
- `flutter analyze` clean; existing tests updated or removed as needed.
- Documentation (§6.4 and Work Management) reflects 4-branch view and single source of truth.

---

## 8) Rollback Plan

- **DB rollback:** Re-apply previous view definition (3-branch, no security_invoker, no disputes, no direct_offers) via a new migration or manual `CREATE OR REPLACE VIEW` from archived migration content. No table drops.
- **App rollback:** Revert app commit (reintroduce fallback mapper and direct_offer merge) so old behavior works with old view. Deploy view rollback first if app expects 3-branch view.
- **Emergency:** If view replacement causes errors, roll back view to last known good; keep app on single-query path but view returns only 3 types until Branch 4 and dispute logic are fixed and re-applied.

---

## 9) References (From Scan)

- `.TODO/improvement_the_system/ImplementReady/12_unified-work-view/00_HOLISTIC_REPORT.md`, `01_NOTES.md`, `02_GAPS_AND_FIXES.md`, `03_RISK_REGISTER.md`, `04_TEST_PLAN.md`, `06_DIAGRAM_FINAL.md`, `07_SYSTEM_CRITIC_VERDICT.md`, `08_PATCH_PLAN.md`
- `Sline_everything/DEVELOPER_GUIDE.md`, `Sline_everything/SUPABASE_SETUP.md` (§5.14 direct_offers, §5.24 disputes, §6.4 vw_unified_work_items), `Sline_everything/MVP_ROADMAP.md`, `Sline_everything/STRUCTURE.md`
- `supabase/migrations/Archive/20260315000000_award_to_work_cancel_and_view.sql`
- `lib/features/work/services/work_management_service.dart`, `lib/features/work/models/unified_work_item_model.dart`, `lib/features/work/models/unified_work_item_fallback_mapper.dart`, `lib/features/work/viewmodels/work_item_details_view_model.dart`
- `lib/features/dashboard/data/dashboard_repository.dart`, `lib/features/dashboard/models/work_item.dart`
- `lib/core/app_enums.dart` (UnifiedWorkStatus)
- Live Supabase: to be confirmed via MCP `list_tables` / `execute_sql` before Phase 1.1.
