# FULL REPORT: 12 Unified Work View

## 0) Skill Selection

- **Skills selected**: Repo Mapping, Evidence-First Reading, Threat Modeling (Security), State Machine & Lifecycle, RLS & Privilege Boundaries.
- **Why these fit**: Evaluates SQL `<->` Flutter compatibility for `vw_unified_work_items`. RLS inheritance for SQL Views is a massive security risk if `security_invoker` is missed. State machines must cleanly map overlapping status enums across 4 tables.
- **Skills not used**: DB-First Financial Modeling.

## 1) Folder Identity

- **Folder name + path**: `.TODO/improvement_the_system/ImplementReady/12_unified-work-view`
- **What system/feature it describes**: Aggregates Tasks, Bookings, Direct Offers, and Awards into a single Normalized feed.
- **Entities involved**: `vw_unified_work_items` (PostgreSQL View), `WorkManagementService`, Tasks, Bookings, Direct Offers, Disputes.

## 2) Human Explanation

To simplify the UI, the DB provides `vw_unified_work_items` using `UNION ALL`. This merges all active work into one list where `freelancer_id` or `client_id` matches the user. Each source branch maps its native status (e.g., a Booking's `confirmed`) into a single `UnifiedWorkStatus` (e.g., `active`). Crucially, a `LEFT JOIN` on `disputes` temporarily overrides any work item's status to `disputed` if a conflict is open. This View has `security_invoker = true` to guarantee it safely reads the underlying protected rows.

## 3) Symbol Legend

- **Rectangles**: Source tables acting as inputs (`tasks`, `bookings`, `direct_offers`).
- **Dashed Logic**: Conditional `LEFT JOIN` overrides.
- **Green Box**: Aggregation output (Unified View).
- **Red Border**: RLS constraint applying `auth.uid()`.

## 4) Extracted Contracts & Invariants

1. **Role Invariant**: Items must strictly bind `client_id` or `freelancer_id` to `auth.uid()`.
2. **Status Unification**: E.g., `in_progress` (Task) and `confirmed` (Booking) -> `active` (Unified).
3. **Award Linkage**: Awarded tasks extract their final `price` from the associated `task_requests` row.

## 5) Conflict Scan Results

### 5.1 Naming Drift

- **Conflict**: "Active" meaning changes depending on table.
- **Resolution**: Use `UnifiedWorkStatus` enum precisely inside Flutter to standardize handling.

### 5.2 Logic Drift

- **Conflict**: Direct Chat Offers were absent from the View's `UNION ALL`.
- **Resolution**: Expand the View definition to include a fourth branch for `direct_offers`.

### 5.3 Data Model Drift

- **Conflict**: The `disputes` join was poorly articulated.
- **Resolution**: Use explicit `LEFT JOIN disputes on related_entity_id = id` -> `CASE WHEN d.status = 'open' THEN 'disputed'`.

## 6) Security & Failure Modes (Adversarial)

- **RLS Information Leak**: A View defined without `security_invoker = true` bypasses RLS on source tables.
  - _Mitigation_: The `WITH (security_invoker = true)` definition is non-negotiable.
- **UI Desync (Ghost Offer)**: Missing `direct_offers` branch means user pays for a chat offer but it disappears from their dashboard.
  - _Mitigation_: Incorporate the Direct Offers SQL branch.

## 7) UI Mapping

### 7.1 Mobile App UI

- **Screens**: "My Work" Dashboard Tab.
- **States**: Rendering unified list grouped by Active, Completed, Disputed.
- **Guardrails**: Do not allow manual status mapping on the client. Trust the View's unified status strictly.

### 7.2 Admin Dashboard UI

- **Pages**: Unnecessary here. Admins typically query native tables directly for support issues.

### 7.3 Implementation Hooks

- `DashboardRepository.getUnifiedWorkItems()` -> Simple `select` against the view.

## 8) Diagram Verdict + Best Diagram Type

- **Score now**: 10/10
- **Best Diagram Type**: Functional Decomposition/Flow mapping sources -> View Sink -> Flutter Map.

## 9) Upgrade Plan

- **Phase 0: Observability**: Ensure `source_id` exists in the View to help tracing.
- **Phase 1: Contracts**: Upgrade `vw_unified_work_items` to the 4-branch `UNION ALL` (Tasks, Bookings, Direct, Awarded Tasks).
- **Phase 2: Hardening**: Add the Disputes override via `LEFT JOIN`.
- **Phase 3: RLS Standardization**: Double-check `security_invoker`. Remove fallback Dart code mapping logic inside `WorkManagementService`.

## 10) Risks

### 10.1 Risks if current version kept

- **Ghost Offers**: Total UI breakdown for Direct Offers missing from Dashboard.

### 10.2 Risks introduced by fixes

- **Performance Drag**: `UNION ALL` across four massive tables could scan slowly. _Mitigation_: Partial indexes on `status` and user columns.

## 11) Test Plan (High-value)

- **Integration**: Create 1 Task, 1 Booking, 1 Direct Offer -> Verify the unified view returns `count=3`.
- **Security**: Authenticate as User A -> query View -> Assert none of User B's entries appear.

## 12) Production Checklist

- [ ] View branch for Direct Offers is deployed.
- [ ] View branch for Dispute tracking is active.
- [ ] Postgres confirms View is marked as "RLS Active" / Security Invoker.
