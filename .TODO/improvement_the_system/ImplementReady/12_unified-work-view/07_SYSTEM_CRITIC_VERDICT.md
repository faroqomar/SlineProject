# System Critic Verdict: 12_unified-work-view

## 1. Verdict: OLD vs NEW

### OLD Design (Status Quo in Repo)

- **Score**: 5/10 🔴 (Failing)
- **Evidence**:
  - `supabase/migrations/Archive/20260315000000_award_to_work_cancel_and_view.sql:L91-183` defines a 3-branch `UNION ALL` view (`tasks`, `bookings`, `task_requests` + `tasks`).
  - Missing 4th branch: The `direct_offers` table (added in v2.17 per `SUPABASE_SETUP.md:L669`) is entirely omitted.
  - Missing dispute states: `disputes` are not joined.
  - Security risk: The view lacks the `WITH (security_invoker = true)` modifier, potentially bypassing RLS on the underlying tables if called interactively.
  - Architecture drift: `WorkManagementService.dart:L62-87` manually performs a fallback query (`_getTaskUnifiedWorkItemFallback`) and bridges it via `UnifiedWorkItemFallbackMapper.dart`. The DB view is not the authoritative single source of truth.

### NEW Design (Holistic Improvement Proposal)

- **Score**: 10/10 🟢 (Ready for Production)
- **Evidence**:
  - The upgraded design enforces a pure 4-branch `UNION ALL` (Tasks, Bookings, Awarded, _and_ Direct Offers).
  - Integrates `LEFT JOIN disputes` to correctly map `disputed` status.
  - Enforces `WITH (security_invoker = true)` to inherit `tasks`, `bookings`, and `direct_offers` RLS policies natively.
  - Deletes the Dart fallback mapper, returning the system to a clean MVVM + DB boundary where the View is the undeniable source of truth.

## 2. Verification of Invariants

### A) Completeness

- **Current**: ❌ Fails. Missing `direct_offers`, leading to ghost items in the UI.
- **Proposed**: ✅ Satisfied. All 4 sources mapped to `unified_status`.

### B) Dispute Override

- **Current**: ❌ Fails. Enum `UnifiedWorkStatus.disputed` exists (`lib/core/app_enums.dart:L83`) but no logic populates it from SQL.
- **Proposed**: ✅ Satisfied. `LEFT JOIN disputes` overrides unified status when active.

### C) Security (RLS)

- **Current**: ❌ Fails. No invoker declaration in `20260315000000_*.sql`.
- **Proposed**: ✅ Satisfied. Native RLS delegation.

### D) Drift Removal (Flutter)

- **Current**: ❌ Fails. Code uses `UnifiedWorkItemFallbackMapper`.
- **Proposed**: ✅ Satisfied. Fallback logic completely stripped; API calls rely solely on `vw_unified_work_items`.

## 3. Blockers to Production (Must-Fix)

1.  **Ghost Direct Offers**: Direct chat offers are invisible in "My Work". This is a critical business logic failure.
2.  **Flutter Code Drift**: The manual fallback mapper breaks the DRY principle and hides SQL RLS failures.
3.  **Missing Security Invoker**: The view must be securely scoped to the querying user to prevent cross-tenant data leaks.

## 4. Final Recommendation

**Proceed with the Patch Plan**.
The OLD design is unsafe and incomplete. The NEW design consolidates business logic where it belongs (Postgres view) and secures it. Execute the patch plan in `.TODO/improvement_the_system/ImplementReady/12_unified-work-view/08_PATCH_PLAN.md`.
