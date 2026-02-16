# 📌 Plan: Client Dashboard v1 — Full Spec Alignment

## 1) Goal

- **Goal:** Align the existing Client-mode Dashboard with the "Client Final v1" spec, ensuring all 8 UI-facing states (of which 7 flow through the Work Engine view), 4 tabs, counters, next-actions priority, and primary actions match the spec exactly.
- **Why:** Current dashboard was built for Freelancer-first; Client-mode has gaps: missing states (`Pending Payment`, `Dispute`), incomplete counters, limited `PrimaryActionType` enum, and a `vw_unified_work_items` view that excludes pre-activation + dispute states.
- **Result:** A Client user sees the correct Overview/Bookings/Work/Inbox tabs with spec-compliant priorities, counters, and actions — without breaking Freelancer mode.

### State Model (Canonical)

> **8 UI Client States** (spec-true):
> `open_tender`, `pending_payment`, `request_pending`, `active`, `delivered`, `completed`, `canceled`, `disputed`
>
> **7 Work Engine States** (`vw_unified_work_items` outputs only post-activation + post-award):
> `pending_payment`, `request_pending`, `active`, `delivered`, `completed`, `canceled`, `disputed`
>
> **Rule:** `open_tender` (Draft/Open Tender) never appears in `vw_unified_work_items` and never appears in Work tab. It lives in the Inbox/Tenders layer (`task_requests` / tender screens).

### Buckets vs States (Locked Distinction)

> **States** = the 7 unified values emitted by `vw_unified_work_items`. These are the source of truth.
>
> **Buckets** = 4 UI-only groupings derived deterministically from states. They are NOT stored anywhere — they are computed by `_mapUnifiedStatusToBucket()` at render time.
>
> | Bucket        | States included                                                                             |
> | ------------- | ------------------------------------------------------------------------------------------- |
> | **Pending**   | `pending_payment`, `request_pending`                                                        |
> | **Active**    | `active`, `delivered` (pinned top), `disputed` (unresolved only, `resolution_type IS NULL`) |
> | **Done**      | `completed`, resolved disputes with `resolution_type IN ('payout','split')`                 |
> | **Cancelled** | `canceled`, resolved disputes with `resolution_type = 'refund'`                             |
>
> **Rule:** No bucket logic is persisted or cached. If a new state is added, it MUST be assigned to exactly one bucket before shipping.

### Strict Separation Rules

- **Work Tab** uses `vw_unified_work_items` **only**. Must exclude all pre-activation browsing states:
  - Tasks: exclude `open`, proposal-only, any unassigned/non-awarded rows.
  - Bookings: exclude `pending`, `expired_unanswered`.
  - **`confirmed` IS included** (locked decision: `confirmed` = provider accepted the booking = real active work, NOT pre-activation). Mapped to `active`.
- **Inbox Tab** never queries `vw_unified_work_items`. Inbox shows proposals/negotiation only (`task_requests` and related pre-activation chats).
- **Inbox → Work Migration Rule (DB-backed, not UI-only):**
  - Inbox query MUST exclude any `task_requests` that belong to a task where `tasks.status IN ('assigned','awarded','in_progress','delivered','completed','canceled','disputed')` OR `tasks.assigned_freelancer_id IS NOT NULL`.
  - This is enforced via a JOIN/subquery filter, not client-side filtering.
  - Once an item enters `request_pending` / `active` / `delivered` / ..., it **disappears from Inbox** (even if chat exists). Post-activation chat is accessed from Work Item details.

### Chat Routing Contract

- **Inbox chat** = pre-activation only (proposal negotiation). Shown in Inbox tab.
- **Post-activation chat** = accessed from Work Item details using `work_item_id` (or `source_id` + `source_type`).
- **Compromise (if single thread exists today):** Same chat thread is allowed, but Inbox must still hide it once the item is activated. The user accesses the same thread via Work Item details instead.
- Chat must never fragment — the same underlying conversation thread is used throughout, only the access point changes.

### Delivered Visibility Guarantee

- `delivered` is NOT "just active" in UX:
  - Delivered items must be **pinned to top** of Active list (or have a dedicated "Needs Review" filter).
  - Overview "Next Actions" must **always prioritize delivered first** (Tier-1).

### Terminology Lock

- `paid_request_pending` = **"Request Pending (Escrow Held)"** (booking-only) — treated as "waiting freelancer acceptance", NOT "waiting payment".
- `awarded` = **"Pending Payment (Awarded)"** (tender-only) — treated as "client must pay to activate".

---

## 2) Scope

### In-Scope

1. **DB View** — Expand `vw_unified_work_items` to output 7 Work Engine states: `pending_payment`, `request_pending`, `active`, `delivered`, `completed`, `canceled`, `disputed`. The 8th UI state (`open_tender`) is handled by Inbox layer only. The view must also output unified `client_id`, `freelancer_id`, and a nullable `resolution_type` column for dispute outcomes.
2. **DB Statuses** — Dashboard supports `awarded` and `disputed` task statuses _if present_; a separate plan will introduce the transitions that set these values (award-proposal action, dispute-create action). No new status values are being _created_ by this plan — only consumed.
3. **App Enums** — Expand `PrimaryActionType`, update `DashboardTab`, add/update `WorkItemStatus` client-facing labels
4. **DashboardCounters** — Add `needsReview` and `pendingPayment` fields for Client mode
5. **DashboardRepository** — Update `fetchWorkItems`, `_mapUnifiedToWorkItem`, `_mapUnifiedStatusToBucket`, and `fetchCounters` for new states
6. **DashboardViewModel** — Update `_calculateNextActions` to match spec priority (delivered > pending payment > disputes > urgent), update `activeWork`/`completedWork`/`cancelledWork` bucket logic, refine `performPrimaryAction`
7. **Overview Tab (Client)** — Counters show: Active, Needs Review, Pending Payment, Completed; Next Actions match spec §11.1
8. **Bookings Tab (Client)** — Show `paid_request_pending` as "Request Pending", split Upcoming/Past correctly
9. **Work Tab (Client)** — Add "Needs Review" visual indicator or filter for delivered items at top of Active tab
10. **Inbox Tab (Client)** — Proposals received only (pre-work offers), ensure ACTIVE items do NOT appear here
11. **WorkItemCard** — Expand `_getPrimaryButtonLabel` and status colors for new action types
12. **WorkItemPermissions** — Add `canReview`, `canDispute`, `canPayEscrow` flags

### Out-of-Scope

- Escrow/payment gateway integration (payment UI is stubbed; real payment is a separate plan)
- Dispute submission screen (full dispute flow is a future plan; this plan only ensures the dashboard _shows_ dispute items)
- Auto-approve timer RPC refinement (existing `rpc_finalize_auto_approval` is sufficient)
- Push notifications / real-time subscription changes
- Freelancer-mode dashboard changes (preserved as-is, not broken)
- Admin review panel
- Full dispute submission flow (separate plan; this plan ensures dashboard _shows_ dispute items + resolution outcomes)
- Full change request / extension request flows (separate plans; this plan ensures dashboard _language_ does not imply silent changes are allowed)

---

## 3) Evidence & Findings (From Scan)

### Existing

| Layer     | Object                  | Status                                                                                                                                                                               |
| --------- | ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| DB View   | `vw_unified_work_items` | Only covers `in_progress`, `delivered`, `completed` (tasks) + `active`, `delivered`, `completed` (bookings). **Missing:** pending, awarded, paid_request_pending, canceled, disputed |
| DB Enum   | `booking_status_enum`   | 10 values: `pending, confirmed, in_progress, canceled, completed, paid_request_pending, active, delivered, refunded, expired_unanswered` — covers most spec states                   |
| DB Column | `tasks.status`          | TEXT type (no enum). Used values include: `open, assigned, in_progress, delivered, completed, canceled`. **Missing:** `awarded`, `disputed`                                          |
| DB RPCs   | 4 exist                 | `rpc_submit_delivery`, `rpc_request_revision`, `rpc_accept_change_request`, `rpc_finalize_auto_approval`                                                                             |
| App Enum  | `PrimaryActionType`     | 3 values: `startWork, markCompleted, approveClose`                                                                                                                                   |
| App Enum  | `DashboardTab`          | 5 values: `overview, manage, bookings, activeWork, inbox` — still has `manage` (removed from UI but in enum)                                                                         |
| Model     | `WorkItem`              | 21 fields + `WorkItemPermissions` (5 flags: canStart, canComplete, canApprove, canCancel, canReschedule)                                                                             |
| Model     | `DashboardCounters`     | 4 fields: activeWork, pendingRequests, newMessages, newOffers                                                                                                                        |
| Widget    | `DashboardCountersGrid` | Client mode shows: Active Bookings, Pending Approvals, New Offers, Messages                                                                                                          |
| Widget    | `WorkItemCard`          | 3 primary button labels: Start Work, Mark Completed, Complete & Close                                                                                                                |
| ViewModel | `_calculateNextActions` | Priorities: pending/paid_request_pending/delivered → urgent (48h) → recent active. **Missing:** `awarded` (pending payment), `disputed`                                              |
| ViewModel | `_fetchPendingItems`    | Only fetches for Freelancer role (client branch is `[]`)                                                                                                                             |

### Missing (From Spec)

1. **`awarded` task status** — Spec §A4-A5: Client awards freelancer, status becomes "Pending Payment (Awarded)". Not in current task status values used by dashboard. **Transition owner:** set by "award proposal" action (exists in `task_requests` flow). If action not yet implemented, dashboard simply shows 0 items in this state.
2. **`disputed` status** — Spec §10: Work can enter Dispute. Not tracked in view or buckets. **Transition owner:** set by dispute-create action (separate plan). Dashboard supports this state if present; no dead statuses created.
3. **Counters `needsReview` + `pendingPayment`** — Spec §11.1 requires distinct counters for these.
4. **Client `_fetchPendingItems`** — Currently returns empty lists for Client mode. Spec requires pending payment tenders + pending freelancer acceptance bookings.
5. **`PrimaryActionType` expansion** — Spec needs: `reviewDelivery`, `payEscrow`, `requestRevision`, `submitEvidence`, `viewDetails`.
6. **`WorkItemPermissions` expansion** — Missing: `canReview`, `canDispute`, `canPayEscrow`.
7. **"Needs Review" filter/badge** in Work Tab Active list — Spec §11.3: "Needs Review (Delivered) as a special filter or as top of Active".
8. **Review timer display** — Spec §7.2: "remaining time until auto-approve" must be shown.

### Conflicts / Risks

| Risk                                                                                         | Severity | Mitigation                                                                                                        |
| -------------------------------------------------------------------------------------------- | -------- | ----------------------------------------------------------------------------------------------------------------- |
| `tasks.status` is TEXT — `awarded`/`disputed` values may not exist yet in live data          | Low      | Dashboard supports these states if present; separate plan introduces transitions that set them. No dead statuses. |
| `vw_unified_work_items` view change affects Freelancer dashboard too                         | Medium   | New WHERE clauses are additive (UNION ALL new states). Existing rows unchanged.                                   |
| `DashboardTab` enum has stale `manage` value; changing it may break `setTab(index)` indexing | Medium   | Update enum values, verify all `DashboardTab.*.index` references.                                                 |
| Client `_fetchPendingItems` currently no-ops; enabling it means new Supabase queries         | Low      | Reuse existing `BookingService.getPendingRequests()` + new `TaskService.getAwardedTenders()`.                     |
| Escrow/payment CTA on cards but no real payment flow                                         | Medium   | Button navigates to stub/payment screen. Plan marks this as out-of-scope.                                         |
| `resolution_type` not yet in DB; view must handle gracefully                                 | Low      | View outputs `NULL::text AS resolution_type` placeholder. Routing logic is no-op when NULL.                       |
| `bookings(slot_id)` has no index; `source_deadline_at` JOIN may be slow                      | Medium   | Create `idx_bookings_slot_id` index. Run EXPLAIN ANALYZE before merging.                                          |
| `bookings.updated_at` does not exist; `last_activity_at` must not reference it               | Low      | Per-branch COALESCE uses only verified columns.                                                                   |

---

## 4) System Impact Map

| Area                       | Impact                                                                                                |
| -------------------------- | ----------------------------------------------------------------------------------------------------- |
| **UI**                     | 4 widgets updated (CountersGrid, WorkItemCard, NextActionsList, WorkTab); Overview greeting unchanged |
| **MVVM/App Logic**         | ViewModel ~15 method changes; Repository mapping updates; new service methods                         |
| **Database**               | View `vw_unified_work_items` expanded; no table schema changes; no new tables                         |
| **RLS/Security**           | No RLS changes (view uses existing table policies)                                                    |
| **Realtime/Notifications** | None (out-of-scope)                                                                                   |
| **Storage**                | None                                                                                                  |
| **Observability**          | AppLogger calls updated for new states                                                                |
| **Compatibility**          | Freelancer mode must not regress; all changes are additive                                            |
| **Contracts**              | `WorkItem` model field additions (non-breaking); `DashboardCounters` field additions (non-breaking)   |

---

# ✅ Execution Phases (Checklist)

## Phase 0: Preconditions & Gates

> Primary: @Sentinel

### 0.1 Spec Lock

- [ ] (@Sentinel) Define acceptance criteria (see §7 below)
- [ ] (@Architect) Confirm entry points: `DashboardViewModel`, `DashboardRepository`, `vw_unified_work_items`
- **Verify (@Sentinel):** Acceptance list is measurable and testable

### 0.2 Contracts

- [ ] (@APIContract) Document `WorkItem` model expansion (new fields, new enum values) in `.TODO/CONTRACT_Dashboard_v1.md`
- [ ] (@APIContract) Document `DashboardCounters` expansion
- **Verify (@Sentinel):** Contract matches spec §0.2 states + §11 tab content

---

## Phase 1: Database & View Expansion

> Primary: @Supabase_Ops

### 1.0 Live Supabase Confirmation

- [ ] (@Supabase_Ops) Re-scan `vw_unified_work_items`, `booking_status_enum`, `tasks` columns via MCP
- [ ] (@Supabase_Ops) Confirm no conflicts with existing data
- [ ] (@Supabase_Ops) **Verify `assigned` status meaning:** DB evidence shows 1 live task with `status='assigned'`, `assigned_freelancer_id` set, `client_id` set — this IS real post-assignment work. **Decision: include `assigned` in view, map to `active`.**
- [ ] (@Supabase_Ops) **Verify booking statuses:** `confirmed` and `in_progress` exist in `booking_status_enum` (0 rows today, but represent accepted/active bookings). **Decision: include both, map to `active`.** **Locked:** `confirmed` = provider accepted = real work (not pre-activation).
- [ ] (@Supabase_Ops) **Verify column existence** for `last_activity_at`: confirm `delivered_at`, `revision_requested_at`, `review_expires_at`, `updated_at` (tasks only), `created_at` exist. **Confirmed: `bookings.updated_at` does NOT exist.**
- [ ] (@Supabase_Ops) **Schema drift test:** Run a migration test query selecting every computed column from the view to ensure no branch references missing columns:
  ```sql
  SELECT id, source_type, source_id, work_item_id, unified_status,
         client_id, freelancer_id, last_activity_at, needs_review,
         sort_rank, source_deadline_at, resolution_type,
         dispute_requires_user_action
  FROM vw_unified_work_items
  LIMIT 0;
  -- Must succeed with no errors. This is the CI-like guardrail.
  ```
- **Verify (@Sentinel):** Scan results match §3 evidence; schema drift test passes with 0 errors

### 1.1 Expand `vw_unified_work_items` View

> **Rule:** Raw DB statuses collapse into exactly **7** Work Engine states: `pending_payment`, `request_pending`, `active`, `delivered`, `completed`, `canceled`, `disputed`. The 8th UI state (`open_tender`) is excluded — it lives in Inbox (`task_requests` only). The view must NOT include pre-work browsing states (`tasks.status = 'open'`) or proposal-only items.

- [ ] (@Supabase_Ops) `CREATE OR REPLACE VIEW vw_unified_work_items` to add:
  - Tasks: `WHERE status IN ('assigned', 'awarded', 'in_progress', 'delivered', 'completed', 'canceled', 'disputed') AND assigned_freelancer_id IS NOT NULL`
    - **`assigned` IS included** (DB evidence: 1 live row with freelancer + client assigned — this is real post-assignment work, not browsing). Mapped to `active`.
    - Excludes `open` (32 rows, pre-activation browsing)
  - Bookings: `WHERE status IN ('paid_request_pending', 'confirmed', 'active', 'in_progress', 'delivered', 'completed', 'canceled', 'refunded')`
    - **`confirmed` and `in_progress` ARE included** (0 rows today, but exist in `booking_status_enum` and represent accepted/active bookings). Mapped to `active`.
    - **Collapse lock:** `active`, `in_progress`, `confirmed` are all distinct `booking_status_enum` values but identical in the unified layer → all map to `active`. UI must NEVER display raw booking labels; only unified labels.
    - Excludes `pending` (pre-payment), `expired_unanswered` (dead)
  - New `unified_status` mapping (raw → unified, **7 values**):
    - `awarded` → `pending_payment`
    - `paid_request_pending` → `request_pending` (**Definition locked:** `paid_request_pending` = client has paid/held funds, awaiting freelancer acceptance. NOT waiting for payment or admin.)
    - `assigned` / `confirmed` / `in_progress` / `active` → `active`
    - `delivered` → `delivered`
    - `completed` → `completed`
    - `canceled` / `refunded` → `canceled`
    - `disputed` → `disputed`

  > **`request_pending` Source Lock (v1):**
  >
  > - `request_pending` exists for **bookings only** in v1 (raw = `paid_request_pending`).
  > - Tasks do NOT have a raw status that maps to `request_pending`. Task-side "waiting freelancer acceptance" is NOT supported in v1 — the `assigned` status means work is already accepted (freelancer_id is set). If a future task status represents "offer sent, awaiting freelancer", it must be explicitly added to this mapping.
  > - **Phantom guard:** `_mapUnifiedToWorkItem()` must not produce `request_pending` for task-sourced items. If `source_type == 'task'` and `unified_status == 'request_pending'`, log a warning and fall back to `active`.

  > **`assigned` Hard Guard:**
  >
  > - `assigned` enters the view ONLY if `assigned_freelancer_id IS NOT NULL` (already enforced by the WHERE clause).
  > - If `assigned` is later repurposed for "soft assignment" (no freelancer yet), that status must NOT enter the view. The WHERE clause `AND assigned_freelancer_id IS NOT NULL` prevents this.
  > - This guard is structural (SQL WHERE), not application-level.

- [ ] (@Supabase_Ops) Add unified identity columns to the view:
  - `client_id` — from `tasks.client_id` (tasks) / `bookings.client_id` (bookings). **Confirmed:** the existing view already uses `t.client_id`, not `t.user_id`.
  - `freelancer_id` — from `tasks.assigned_freelancer_id` (tasks) / `bookings.provider_id` (bookings). **Note:** The existing view already filters `WHERE assigned_freelancer_id IS NOT NULL` for tasks, so `freelancer_id` is guaranteed non-null for task rows. For bookings, `provider_id` is a NOT NULL column.
- [ ] (@Supabase_Ops) Add computed columns to the view:
  - `last_activity_at` — computed **per UNION branch using only columns that exist in that source table**:
    - **Tasks branch:** `COALESCE(t.delivered_at, t.revision_requested_at, t.review_expires_at, t.updated_at, t.created_at)`
      - Verified columns exist: `delivered_at` ✔, `revision_requested_at` ✔, `review_expires_at` ✔, `updated_at` ✔, `created_at` ✔
    - **Bookings branch:** `COALESCE(b.delivered_at, b.revision_requested_at, b.review_expires_at, b.created_at)`
      - Verified columns exist: `delivered_at` ✔, `revision_requested_at` ✔, `review_expires_at` ✔, `created_at` ✔
      - **`bookings.updated_at` does NOT exist** — intentionally omitted
  - `needs_review` (boolean, NULL-safe) — `unified_status = 'delivered' AND review_expires_at IS NOT NULL AND now() < review_expires_at`. **Fallback:** when `review_expires_at IS NULL` and `unified_status = 'delivered'`, `needs_review` is `FALSE` but the item still appears as delivered; the UI shows "Review pending" without a timer.
  - `sort_rank` (integer) — priority rank for dashboard sorting: delivered=1, pending_payment=2, disputed=3, request_pending=4, active=5, completed=6, canceled=7
  - `source_deadline_at` — `tasks.deadline` (tasks) / `availability_slots.starts_at` via `bookings.slot_id` LEFT JOIN (bookings). Unifies the urgency threshold for "deadline < 48h" logic.
    - **NULL behavior:** If `slot_id` is NULL or the slot row is missing, `source_deadline_at` is `NULL`. Urgency logic must treat `NULL` deadline as "not urgent" (never crashes, never marks urgent). ViewModel: `if (item.sourceDeadlineAt == null) { /* skip urgency */ }`.
  - `resolution_type` (nullable text) — **Existence guard:** `tasks.resolution_type` and `bookings.resolution_type` **do NOT exist today**. The view must output `NULL::text AS resolution_type` as a placeholder until the dispute/admin plan introduces the real outcome columns. Resolved dispute routing is enabled only when `resolution_type IS NOT NULL`.
  - `dispute_requires_user_action` (nullable boolean) — **Existence guard:** Column may not exist yet. View outputs `NULL::boolean AS dispute_requires_user_action` as placeholder. When available: `TRUE` = client must submit evidence or respond; `FALSE` = waiting for admin/other party. Used to split Next Actions Tier-3 (only disputes requiring action appear in top-3).
- [ ] (@Supabase_Ops) **Unified identifier contract** — add to both UNION branches:
  - `source_type` (text) — already exists: `'task'` or `'booking'`
  - `source_id` (uuid) — alias for `id` (the raw table PK). Already exists as `id`.
  - `work_item_id` (text) — **NEW:** computed as `source_type || ':' || id::text`. Example: `'task:6ae4c000-...'`. This is the stable, unique key for navigation + caching across refresh.
- [ ] (@Supabase_Ops) **`work_item_id` uniqueness verification** — run after view creation:
  ```sql
  SELECT work_item_id, COUNT(*)
  FROM vw_unified_work_items
  GROUP BY 1
  HAVING COUNT(*) > 1;
  -- Must return 0 rows
  ```
- [ ] (@Architect) **`work_item_id` format check in code** — enforce regex `^(task|booking):[0-9a-f-]{36}$` in `WorkItem.fromJson()`. If format doesn't match, log error and reject the item.
- [ ] (@Supabase_Ops) **Performance guard** for `availability_slots` JOIN:
  - **Required index:** `CREATE INDEX IF NOT EXISTS idx_bookings_slot_id ON bookings(slot_id)` — does NOT exist today (verified: only `bookings_pkey` exists).
  - `availability_slots(id)` already has PK index ✔.
  - **Verification step:** Run `EXPLAIN ANALYZE SELECT * FROM vw_unified_work_items` after the view change, before merging. Confirm no sequential scan on `availability_slots`.
- [ ] (@Supabase_Ops) **Paging contract (Locked):**
  - **Default order:** `sort_rank ASC, last_activity_at DESC, work_item_id DESC`
  - **Cursor:** Composite `(sort_rank, last_activity_at, work_item_id)` — not just timestamp. This prevents duplicates/missing items between pages.
  - **Page size:** 20 items per page.
  - Inbox must NOT join `vw_unified_work_items`; it reads `task_requests` only with minimal joins (task title + profile).
- **Verify (@Sentinel):** `SELECT * FROM vw_unified_work_items` returns rows for all 7 unified status categories when data exists. No rows with `status = 'open'` or `status = 'pending'` (booking) leak in. `client_id` is non-null for all rows. `freelancer_id` is non-null for all rows. `assigned` tasks appear as `active`. `resolution_type` is `NULL` for all rows (until dispute outcome columns are created). `work_item_id` is unique and matches format `^(task|booking):[uuid]$`. Existing rows still appear.

### 1.2 Verify RLS (No Changes Expected)

- [ ] (@Supabase_Ops) Confirm view inherits underlying table RLS (tasks + bookings)
- [ ] (@Supabase_Ops) Run provable verification SQL:

  ```sql
  -- As authenticated client user:
  SELECT count(*) FROM vw_unified_work_items WHERE client_id != auth.uid();
  -- Must return 0

  -- As random non-participant user:
  SELECT count(*) FROM vw_unified_work_items;
  -- Must return 0 (no rows visible)
  ```

- **Verify (@Sentinel):** Both queries return 0. This makes the "no RLS change" claim provable.

---

## Phase 2: App Layer (MVVM)

> Primary: @Architect

### 2.1 Enums & Models

#### 2.1.1 Update `app_enums.dart`

- [ ] (@Architect) Expand `PrimaryActionType`:
  ```dart
  enum PrimaryActionType {
    startWork,
    markCompleted,
    approveClose,
    reviewDelivery,   // NEW: Client reviews delivered work
    payEscrow,        // NEW: Client pays to activate
    requestRevision,  // NEW: Review-screen-only (see purity rule below)
    submitEvidence,   // NEW: Dispute evidence submission
    viewDetails,      // NEW: Generic navigation-only
  }
  ```
  > **`requestRevision` Purity Rule:** `requestRevision` is kept in the enum for the review-screen UI, but it must NEVER be produced by `_mapUnifiedToWorkItem()`. It is only used inside the Review Delivery screen logic. Repository/mapping layer must never emit it.
- [ ] (@Architect) Clean up `DashboardTab` enum (remove stale `manage`):
  ```dart
  enum DashboardTab { overview, bookings, work, inbox }
  ```
- [ ] (@Architect) **Tab index migration guard:** Do NOT rely on `.index` for persisted state. Store tab as string key (`'overview'` | `'bookings'` | `'work'` | `'inbox'`), not int. If old int indices are cached/persisted anywhere:
  - Add remap guard in `initState` / `_loadCachedTab()`: if old index == 1 (was `manage`), default to `overview` (0)
  - Audit all `setTab(int)` callers to ensure they use `DashboardTab.*.index` not hardcoded ints
- [ ] (@Architect) Add `UnifiedWorkStatusLabel` helper for client-facing labels:
  ```dart
  // Maps raw status strings to spec §0.2 labels
  String clientStatusLabel(String statusRaw) { ... }
  ```
- **Verify (@Sentinel):** All enum usages compile; no broken references

#### 2.1.2 Update `WorkItemPermissions`

- [ ] (@Architect) Add 3 new flags:
  ```dart
  final bool canReview;   // Client can approve/revise delivered work
  final bool canDispute;  // Either party can escalate
  final bool canPayEscrow; // Client can pay to activate
  ```
- [ ] (@Architect) Update `toJson()` + `fromJson()` for new fields
- **Verify (@Sentinel):** Serialization round-trips correctly

#### 2.1.3 Update `DashboardCounters`

- [ ] (@Architect) Add 2 new fields for Client mode:
  ```dart
  final int needsReview;     // Delivered items awaiting client decision
  final int pendingPayment;  // Awarded tenders awaiting payment
  ```
- [ ] (@Architect) Update `toMap()` + `fromMap()` for new fields
- **Verify (@Sentinel):** Cache serialization works with new fields

### 2.2 Services/Repository

#### 2.2.1 Update `DashboardRepository`

- [ ] (@Architect) Update `fetchWorkItems()` — the view now returns more states; ensure mapping handles them all
- [ ] (@Architect) Update `_mapUnifiedToWorkItem()`:

  > **Rule:** `PrimaryActionType` is role-dependent. The same `unified_status` maps to different actions for Client vs Freelancer. This must be enforced in the mapping function, never hardcoded per-status without role check.
  - Map `unified_status` → correct `PrimaryActionType` **per role**:
    - `pending_payment` → `payEscrow` (Client) / `viewDetails` (Freelancer waits)
    - `request_pending` → `viewDetails` (Client waits) / `startWork` (Freelancer accepts)
    - `active` → `viewDetails` (Client) / `startWork` (Freelancer)
    - `delivered` → `reviewDelivery` (Client) / `viewDetails` (Freelancer waits)
    - `completed` → `viewDetails` (both)
    - `canceled` → `viewDetails` (both)
    - `disputed` → `submitEvidence` (Client, only if `dispute_requires_user_action == true`) / `viewDetails` (otherwise)

  > **CTA Lock:** `reviewDelivery` is the card-level primary CTA for `delivered`. Inside the review screen, the user can choose **Approve / Request Revision / Dispute**. Therefore `requestRevision` is triggered from the review screen — it must NOT appear as a card primary action. This prevents conflicting CTAs on the card.

  > **`dispute_requires_user_action` v1 Default:** In v1, `dispute_requires_user_action` is always `NULL` (column doesn't exist yet). **`NULL` is treated as `false`** — disputes do NOT elevate to Tier-3 Next Actions and do NOT show `submitEvidence` CTA. When the dispute module lands and the column becomes real, disputes with `TRUE` will begin appearing in Tier-3 and showing `submitEvidence`. This prevents disputes from spamming Next Actions without real data.
  - Map permissions:
    - `canPayEscrow = true` when `pending_payment` + role == client
    - `canReview = true` when `delivered` + role == client
    - `canDispute = true` when `active` or `delivered`

- [ ] (@Architect) Update `_mapUnifiedStatusToBucket()`:
  - `pending_payment` → `'Pending'`
  - `request_pending` → `'Pending'`
  - `active` → `'Active'`
  - `delivered` → `'Active'` (but flagged as Needs Review — **pinned to top per Delivered Visibility Guarantee**)
  - `completed` → `'Done'`
  - `canceled` → `'Cancelled'`
  - `disputed` → `'Active'` (but flagged as Dispute)

> **Dispute Resolution Outcome:** When `unified_status == 'disputed'` and `resolution_type != null`, the item has been resolved:
>
> - `resolution_type = 'refund'` → move to Cancelled history, show "Resolved: Refund" badge
> - `resolution_type = 'payout'` → move to Completed history, show "Resolved: Paid" badge
> - `resolution_type = 'split'` → move to Completed history, show "Resolved: Split" badge
>
> **Disabled-until-exists switch (Repository):** If `resolution_type == null` for ALL rows (because DB doesn't have the columns yet), do NOT attempt resolved dispute routing. Keep all `disputed` items in Active. This avoids phantom behavior before the admin/dispute plan lands. Repository checks: `if (workItems.every((i) => i.resolutionType == null)) { /* skip routing logic */ }`

- [ ] (@Architect) Update `fetchCounters()` to compute counters from work items using locked definitions:

  > **Counter Definitions (Locked):**
  >
  > | Counter             | Formula                                                                                                                                                           |
  > | ------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
  > | **Active**          | `count(unified_status IN ('active', 'request_pending', 'pending_payment'))` + **unresolved disputes** (`unified_status = 'disputed' AND resolution_type IS NULL`) |
  > | **Needs Review**    | `count(unified_status = 'delivered')`                                                                                                                             |
  > | **Pending Payment** | `count(unified_status = 'pending_payment')` _(subset of Active)_                                                                                                  |
  > | **Completed**       | `count(unified_status = 'completed')` + resolved disputes routed to Done (`resolution_type IN ('payout','split')`)                                                |
  >
  > **Disputed visibility rule:** Unresolved disputes (`resolution_type IS NULL`) count inside Active counter. Resolved disputes are excluded from Active and routed to Done/Cancelled per `resolution_type`. This ensures counter matches the Work tab list at all times.

- **Verify (@Sentinel):** Freelancer mapping logic unchanged; Client mapping produces correct buckets; counter values match tab item counts

#### 2.2.2 New Service Methods

- [ ] (@Architect) Add `TaskService.getAwardedTenders(String clientId)`:
  - Query: `tasks.select().eq('client_id', clientId).eq('status', 'awarded')` — uses `client_id` (confirmed as canonical field in live view)
- [ ] (@Architect) Update `_fetchPendingItems()` for Client mode:
  - Fetch `paid_request_pending` bookings where `client_id = uid`
  - Fetch `awarded` tenders where `client_id = uid`
- **Verify (@Sentinel):** Queries respect RLS; no N+1 patterns

### 2.3 ViewModel

#### 2.3.1 Update `_calculateNextActions()` for Client Mode

- [ ] (@Architect) Rewrite priority tiers per spec §11.1:
  1. **Tier 1 (Highest):** `delivered` → "Needs Review"
  2. **Tier 2:** `pending_payment` (awarded) → "Complete Payment"
  3. **Tier 3:** `disputed` where `dispute_requires_user_action == true` → "Dispute: Action Required" _(v1: always empty because column is NULL)_
  4. **Tier 4:** `request_pending` → "Waiting Freelancer"
  5. **Tier 5:** Urgent active (deadline < 48h, `source_deadline_at` non-NULL)
  6. **Tier 6:** Recent active
  - **Max-per-tier rule:** Each tier contributes at most 3 items to Next Actions. If a tier has >3 items, show the newest 3 by `last_activity_at DESC`. Total Next Actions shown = top 3 across all tiers.
  - **Tie-break order** (same as paging): `sort_rank ASC, last_activity_at DESC, work_item_id DESC`
  - **Rule:** Disputes where `dispute_requires_user_action == false` (or `NULL`) appear as normal Active items but NOT in top-3 Next Actions. In v1, this means NO disputes appear in Tier-3.
- [ ] (@Architect) Ensure Freelancer priority path is preserved (conditional on `_currentRole`)
- **Verify (@Sentinel):** `nextActions` returns correct top-3 for each role; disputes without required action don't displace higher-priority items; tie-break order is deterministic

#### 2.3.2 Update Work Bucket Getters

- [ ] (@Architect) `activeWork` getter — include `pending_payment`, `request_pending`, `active`, `delivered`, `disputed` (only unresolved disputes where `resolution_type IS NULL`)
- [ ] (@Architect) Add `deliveredWork` getter — items with `statusRaw == 'delivered'` for the "Needs Review" indicator. **Must sort to top of Active list per Delivered Visibility Guarantee.**
- [ ] (@Architect) `completedWork` — include `completed` + resolved disputes with `resolution_type = 'payout'` + resolved disputes with `resolution_type = 'split'` (with "Split" badge)
- [ ] (@Architect) `cancelledWork` — include `canceled`, `refunded` + resolved disputes with `resolution_type = 'refund'`

> **Deterministic Dispute Routing (Locked):**
>
> - `resolution_type = 'payout'` → bucket to **Done**
> - `resolution_type = 'refund'` → bucket to **Cancelled**
> - `resolution_type = 'split'` → bucket to **Done** + badge "Resolved: Split"
> - `resolution_type IS NULL` (or column doesn't exist yet) → stays in **Active** as unresolved dispute

- **Verify (@Sentinel):** Buckets are exhaustive and mutually exclusive

#### 2.3.3 Update `performPrimaryAction()`

- [ ] (@Architect) Handle new `PrimaryActionType` values:
  - `reviewDelivery` → navigate to Work Item Details (review screen)
  - `payEscrow` → navigate to Payment/Checkout screen (stub)
  - `requestRevision` → call `rpc_request_revision`
  - `submitEvidence` → navigate to Dispute screen (stub)
  - `viewDetails` → navigate to Work Item Details
- **Verify (@Sentinel):** Each action type has a handler; no unhandled cases

#### 2.3.4 Fix `setTab()` Index Mapping

- [ ] (@Architect) After removing `manage` from `DashboardTab`, verify `setTab(int index)` matches TabController indices:
  - 0 = overview, 1 = bookings, 2 = work, 3 = inbox
- **Verify (@Sentinel):** Tab navigation doesn't jump to wrong tab

---

## Phase 3: UI (After Logic)

> Primary: @Pixel

### 3.1 Counters Grid (Client Mode)

- [ ] (@Pixel) Update `DashboardCountersGrid` Client section to show:
  1. **Active** (activeWork count) — teal
  2. **Needs Review** (needsReview count) — gold, urgent feel
  3. **Pending Payment** (pendingPayment count) — lightRed
  4. **Completed** (completedWork.length) — lightTeal
- [ ] (@Pixel) Tap on "Needs Review" → navigate to Work tab + highlight delivered items
- [ ] (@Pixel) Tap on "Pending Payment" → navigate to Work tab + highlight awarded items
- **Verify (@Sentinel):** Counters display correctly for 0 and non-0 values; Freelancer mode counters unchanged

### 3.2 WorkItemCard Expansion

- [ ] (@Pixel) Add status colors for new states:
  - `pending_payment` / `awarded` → `AppColors.lightRed` (urgent, needs money)
  - `request_pending` / `paid_request_pending` → `AppColors.gold` (waiting)
  - `disputed` → deep red or warning color
  - `delivered` → `AppColors.gold` (attention needed)
- [ ] (@Pixel) Update `_getPrimaryButtonLabel()` for new types:
  - `reviewDelivery` → "Review Delivery" _(card-level CTA for delivered — opens review screen)_
  - `payEscrow` → "Pay Now"
  - `submitEvidence` → "Submit Evidence" _(only shown when `dispute_requires_user_action == true`)_
  - `viewDetails` → "View Details"
  - **Note:** `requestRevision` is NOT a card CTA — it's an option inside the Review Delivery screen. Do NOT show it on WorkItemCard.
- [ ] (@Pixel) Add review timer indicator when `item.statusRaw == 'delivered'`:
  - Show countdown text: "Auto-approves in X hours" using `review_expires_at`
- [ ] (@Pixel) Add a "delivered" badge/indicator on cards in the Active list
- **Verify (@Sentinel):** All action buttons visible and tappable; no layout overflow

### 3.3 Work Tab Client Refinements

- [ ] (@Pixel) In Active tab, sort delivered items to top with visual distinction (e.g., gold border or "NEEDS REVIEW" badge). **This is a MUST per Delivered Visibility Guarantee, not optional.**
- [ ] (@Pixel) Add a "Needs Review" chip/filter above the Active list for quick access
- [ ] (@Pixel) Resolved disputes: show explicit outcome badge ("Resolved: Refund" / "Resolved: Paid" / "Resolved: Split") on history cards
- **Verify (@Sentinel):** Delivered items are visually prominent; no confusion with normal active items; resolved disputes show outcome label

### 3.4 Bookings Tab Client Refinements

- [ ] (@Pixel) Ensure `paid_request_pending` bookings appear under "Upcoming" with status label "Request Pending"
- [ ] (@Pixel) Show "Waiting for freelancer to accept" subtitle
- **Verify (@Sentinel):** `paid_request_pending` bookings show correctly; past bookings include `refunded`

### 3.5 Inbox Tab (Client-Only Refinements)

- [ ] (@Pixel) Verify no ACTIVE work items leak into Inbox (only pre-work offers)
- [ ] (@Pixel) Label should say "Proposals" not just "Offers" for client view clarity
- [ ] (@Pixel) Ensure items that have transitioned to `request_pending` or beyond **disappear from Inbox** (post-activation chat is accessed from Work Item details, not Inbox)
- [ ] (@Architect) **Inbox hard filter (DB-backed):** Inbox query must JOIN or subquery-filter to exclude `task_requests` where:
  ```dart
  // Pseudo-SQL for the Inbox query
  SELECT tr.* FROM task_requests tr
  LEFT JOIN tasks t ON tr.task_id = t.id
  WHERE tr.status = 'pending'
    AND (
      -- Normal case: task exists and is still open
      (t.id IS NOT NULL
       AND t.status NOT IN ('assigned','awarded','in_progress','delivered','completed','canceled','disputed')
       AND t.assigned_freelancer_id IS NULL)
      OR
      -- Orphan case: task_id is NULL or task row missing — show in Inbox
      t.id IS NULL
    )
  ```
  **Orphan handling rule:** If `task_id` is NULL or the task row is missing (orphaned request), Inbox still shows it only if `tr.status = 'pending'`. This prevents breaking Inbox on dirty data. Orphaned requests with non-pending status are excluded.
- **Verify (@Sentinel):** Inbox is clean; only `task_requests` with `status = pending` appear AND (parent task is still `open` OR task_id is NULL/orphaned); no work items with `unified_status` IN `request_pending/active/delivered/...` leak in

### 3.6 Loading/Empty/Error States

- [ ] (@Pixel) Each tab shows correct empty state message for Client mode
- [ ] (@Pixel) Loading indicators work for all new data paths
- **Verify (@Sentinel):** Stable UX on slow/empty data

---

## Phase 4: QA + Security

> Primary: @Sentinel

### 4.1 Contract Checks

- [ ] (@Sentinel) Verify `WorkItem` model matches updated view output shapes
- [ ] (@Sentinel) Verify `DashboardCounters` serialization includes new fields
- **Verify (@Sentinel):** No runtime type mismatch

### 4.2 Functional QA

- [ ] (@Sentinel) Manual test: Client mode with mix of awarded/active/delivered/canceled items
- [ ] (@Sentinel) Manual test: Freelancer mode operates identically to before (regression)
- [ ] (@Sentinel) Edge cases:
  - No items at all (empty dashboard)
  - Items in every state simultaneously
  - Role switch mid-session
  - Cache with old format + new code (backwards compat)
- **Verify (@Sentinel):** No crashes, correct state display

### 4.3 Security

- [ ] (@Sentinel) Verify client cannot see other users' items via view
- [ ] (@Sentinel) Verify `performPrimaryAction` respects permissions (can't approve if not owner)
- **Verify (@Sentinel):** Unauthorized access impossible

---

## Phase 5: Documentation Sync

> Primary: @SlineDocs

- [ ] (@SlineDocs) Update `DEVELOPER_GUIDE.md` — Dashboard section with new Client states
- [ ] (@SlineDocs) Update `SUPABASE_SETUP.md` — Updated `vw_unified_work_items` definition
- [ ] (@SlineDocs) Update `Sline_Log.md` — Version entry for this change
- [ ] (@SlineDocs) Update `MVP_ROADMAP.md` — Dashboard alignment milestone
- [ ] (@SlineDocs) Document **Work Engine Guardrails** (frozen requirements rule, change request policy, extension request policy):
  - When a Work Item becomes `active`, requirements are frozen as baseline (snapshot displayed in Work Item details).
  - Change Request is the **only** legal scope change (no silent edits after `active`).
  - Extension Request is the **only** legal deadline change (no silent deadline updates).
  - Even if full flows are out-of-scope, the dashboard must not display language/actions that imply silent changes are allowed.
- **Verify (@Sentinel):** Docs match code + live DB; no UI copy implies silent changes are possible

---

## 7) Acceptance Criteria

| #     | Criterion                                                                                                                                                           | Measurable                                  |
| ----- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------- | -------------------------------------------- |
| AC-1  | Client Overview shows 4 counters: Active, Needs Review, Pending Payment, Completed                                                                                  | Visual + data check                         |
| AC-2  | Next Actions top-3 follows spec §11.1 priority: Delivered > Pending Payment > Disputes > Urgent                                                                     | Manual test with mixed data                 |
| AC-3  | Work Tab Active list shows delivered items at top with visual "Needs Review" indicator                                                                              | Visual check                                |
| AC-4  | Work Tab Active includes `pending_payment`, `request_pending`, `active`, `delivered`, `disputed` states                                                             | Query + visual check                        |
| AC-5  | Bookings Tab shows `paid_request_pending` as "Request Pending" under Upcoming                                                                                       | Visual check                                |
| AC-6  | Inbox Tab shows only pre-work proposals (no ACTIVE items)                                                                                                           | Data verification                           |
| AC-7  | WorkItemCard shows correct primary button for each state (`Review Delivery`, `Pay Now`, etc.)                                                                       | Visual + tap test                           |
| AC-8  | Review timer countdown visible on delivered cards                                                                                                                   | Visual check with known `review_expires_at` |
| AC-9  | Freelancer mode dashboard is unchanged (no regression)                                                                                                              | Side-by-side comparison                     |
| AC-10 | `vw_unified_work_items` can return rows for all 7 unified states when data exists (including `pending_payment`/`disputed` if those transitions have been triggered) | SQL verification with seed data             |
| AC-11 | Cache handles new fields gracefully (old cache format doesn't crash)                                                                                                | Cold-start test                             |
| AC-12 | Inbox never queries `vw_unified_work_items`; Inbox reads `task_requests` only                                                                                       | Code audit + data verification              |
| AC-13 | UI defines 8 client-facing states; Work Engine view outputs only 7 (`open_tender` excluded — lives in Inbox/Tenders layer)                                          | Code audit + spec cross-check               |
| AC-14 | Inbox never shows any item once it enters `request_pending` or beyond (no active chat leakage) — enforced via DB JOIN filter, not client-side                       | Manual test with state transitions + SQL    |
| AC-15 | Delivered items are always visually prioritized (pinned to top / dedicated filter) in Work tab                                                                      | Visual check                                |
| AC-16 | Resolved disputes show explicit outcome label (`refund` / `pay` / `split`) in history cards/details                                                                 | Visual check with resolved dispute data     |
| AC-17 | `work_item_id` is unique and stable across refresh + cache (format: `^(task                                                                                         | booking):[uuid]$`)                          | SQL uniqueness query (0 dupes) + regex check |
| AC-18 | Counter values match tab item counts (Active counter = active+request_pending+pending_payment+unresolved disputes visible in Work tab)                              | Count verification                          |
| AC-19 | `requestRevision` never appears as a card-level CTA — only inside review screen; never produced by `_mapUnifiedToWorkItem()`                                        | Visual + code audit                         |
| AC-20 | Schema drift test query (SELECT all computed columns LIMIT 0) passes with 0 errors                                                                                  | SQL execution in Phase 1.0                  |
| AC-21 | Setting a task to `awarded` causes the corresponding `task_request` to disappear from Inbox within 1 refresh cycle (DB-backed filter proof)                         | Manual state transition test + SQL          |
| AC-22 | The same item appears in Work tab under `pending_payment` within 1 refresh cycle after being set to `awarded`                                                       | Manual state transition test + visual       |

---

## 8) Rollback Plan

| Step | Action                                                                                                            |
| ---- | ----------------------------------------------------------------------------------------------------------------- |
| 1    | **DB View:** `CREATE OR REPLACE VIEW vw_unified_work_items AS ...` with original definition (saved before change) |
| 2    | **App Enums:** Revert enum changes (additive, so removing new values is backward-compatible)                      |
| 3    | **ViewModel/Repository:** Revert to previous mapping logic                                                        |
| 4    | **Cache:** Clear dashboard cache on rollback (users get fresh data on next load)                                  |

**Emergency:** If view change causes performance issues, the original view definition can be restored in < 1 minute via Supabase SQL editor.

---

## 9) References (From Scan)

### Documentation

- [DEVELOPER_GUIDE.md](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/DEVELOPER_GUIDE.md) — Dashboard deep-dive
- [SUPABASE_SETUP.md](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/SUPABASE_SETUP.md) — View + trigger definitions
- [STRUCTURE.md](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/STRUCTURE.md) — Feature module layout
- [CODE_REVIEW.md](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/CODE_REVIEW.md) — Code quality patterns
- [Fixing_Dashbowrd.md](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/Fixing_Dashbowrd.md) — Client Final v1 Spec (source spec)

### Code

- [dashboard_view_model.dart](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/dashboard/viewmodels/dashboard_view_model.dart) — 674 lines, 25 methods
- [dashboard_repository.dart](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/dashboard/data/dashboard_repository.dart) — 252 lines, view mapping
- [dashboard_screen.dart](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/dashboard/view/dashboard_screen.dart) — 4-tab layout
- [work_item.dart](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/dashboard/models/work_item.dart) — WorkItem + WorkItemPermissions models
- [dashboard_counters.dart](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/dashboard/models/dashboard_counters.dart) — Counter model
- [app_enums.dart](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/app_enums.dart) — PrimaryActionType, DashboardTab, WorkItemType
- [overview_tab.dart](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/dashboard/view/tabs/overview_tab.dart) — Overview layout
- [work_tab.dart](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/dashboard/view/tabs/work_tab.dart) — Active/Done/Cancelled tabs
- [bookings_tab.dart](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/dashboard/view/tabs/bookings_tab.dart) — Upcoming/Past split
- [inbox_tab.dart](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/dashboard/view/tabs/inbox_tab.dart) — Offers list
- [dashboard_counters_grid.dart](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/dashboard/view/widgets/dashboard_counters_grid.dart) — Counter cards
- [work_item_card.dart](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/dashboard/view/widgets/work_item_card.dart) — Card widget
- [next_actions_list.dart](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/dashboard/view/widgets/next_actions_list.dart) — Priority list

### Supabase Live Scan

- `vw_unified_work_items` — Current definition covers only post-activation states
- `booking_status_enum` — 10 values (all needed states present)
- `tasks.status` — TEXT column, no enum constraint
- 4 RPCs: `rpc_submit_delivery`, `rpc_request_revision`, `rpc_accept_change_request`, `rpc_finalize_auto_approval`
- `wallet_balances` view exists (used by WalletSnapshotCard)
