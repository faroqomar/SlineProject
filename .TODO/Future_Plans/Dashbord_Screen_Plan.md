# SLine Dashboard Implementation Checklist

This document serves as the **FINAL MASTER CHECKLIST** for rebuilding the Dashboard. It incorporates strict logic for roles, permissions, data integrity, and performance.

---

## 🎨 Phase 0: Dashboard UI/UX Design (Prototype Only)
**Goal:** Build a complete Dashboard design that matches the existing app design matching, with all current + planned features visible as a demo. **No backend integration.**

- [x] **0.1 Design Consistency Setup**
    - [x] Reuse existing app theme (colors, gradients, shadows, typography, radius, spacing).
    - [x] Reuse existing UI components (`AppButton`, `GlassContainer`, `AppCard`, etc.).
    - [x] Confirm layout patterns match the current app (padding, headers).

- [x] **0.2 Fake Data Layer (Mock Repository)**
    - [x] Create a local mock provider returning:
        - [x] Counters (randomized for testing).
        - [x] Bookings list (covering all statuses: Pending/Confirmed/etc).
        - [x] Tasks list (Open/Assigned/etc).
        - [x] Offers list (Accepted/Rejected/etc).
        - [x] Activity Log items.

- [x] **0.3 Dashboard Shell (UI Only)**
    - [x] Implement `DashboardScreen` scaffold.
    - [x] persistent `BottomNavigationBar` (5 tabs).
    - [x] `RoleSwitch` in AppBar (updates UI specific content immediately using mock data).

- [x] **0.4 Tab 1: Overview (UI Prototype)**
    - [x] **Counters:** Cards for both roles.
    - [x] **Next Actions:** List of "to-do" items (mock deep navigation).
    - [x] **Activity Feed:** Preview list (last 5 items) + "See All" button.

- [x] **0.5 Tab 2: Manage (UI Prototype)**
    - [x] **Freelancer:** "My Services" list with tabs (Active/Paused/Drafts).
    - [x] **Client:** "My Tasks" list with tabs (Open/Assigned/History).
    - [x] **Note:** Buttons (Edit/Pause/Cancel) are visual demo only.

- [x] **0.6 Tab 3: Bookings (UI Prototype)**
    - [x] **Filters:** Pending, Confirmed, InProgress, Completed, etc.
    - [x] **Card UI:** `scheduledAt` prominent, status badge, action buttons.
    - [x] **Demo Actions:** Confirm/Decline (Freelancer), Edit/Cancel (Client).

- [x] **0.7 Tab 4: Active Work (UI Prototype)**
    - [x] Unified `WorkItem` list (Tasks + Bookings mixed).
    - [x] **Sections:** Up Next, In Progress, In Review.
    - [x] **Demo Actions:** Start Work, Mark Completed, Approve & Close, Chat.

- [x] **0.8 Tab 5: Inbox (UI Prototype - Offers Only)**
    - [x] **Client:** Offers grouped by Task.
    - [x] **Freelancer:** My Submitted Offers.
    - [x] **Demo Actions:** Accept/Reject, Withdraw.

- [x] **0.9 Demo Details Screens**
    - [x] `BookingDetailsDemo`.
    - [x] `TaskDetailsDemo`.
    - [x] `WorkDetailsDemo`.
    - [x] `ActivityListDemo`.

- [x] **0.10 Acceptance**
    - [x] Visually matches app design system perfection.
    - [x] Navigate to all 5 tabs.
    - [x] Switch roles and see content change.
    - [x] All statuses visualized.

---

## 🎯 Phase 1: Foundation, Logic & State
**Goal:** Define the "Source of Truth" for statuses, transitions, and data models before touching UI.

- [x] **1.1 Define Enums & Constants**
    - [x] Update `TaskStatus`: `Open`, `Assigned`, `InProgress`, `Completed`, `Closed`, `Canceled`.
    - [x] Update `BookingStatus`: `Pending`, `Confirmed`, `InProgress`, `Completed`, `Canceled`, `NoShow`, `Declined`.
    - [x] Define `OfferStatus`: `Pending`, `Accepted`, `Rejected`, `Withdrawn`.
    - [x] Create `UserRole` enum: `Client`, `Freelancer`.
    - [x] Create `DashboardTab` enum: `Overview`, `Manage`, `Bookings`, `ActiveWork`, `Inbox`.

- [x] **1.2 Define Transition Rules & Permissions (Backend Enforced)**
    - [x] **Task Rules:**
        - [x] `Open` / `Assigned` → `Canceled` (Client only, requires reason).
        - [x] `InProgress` → `Canceled` (Restricted: requires Admin or Mutual Agreement - *Defer to Dispute System*).
        - [x] `Completed` → `Canceled` (Disallowed).
        - [x] `Completed` → `Closed` (Client only).
    - [x] **Booking Rules:**
        - [x] `Pending` → `Confirmed` (Freelancer only).
        - [x] `Pending` → `Declined` (Freelancer only).
        - [x] `Pending` → `Canceled` (Client only).
        - [x] `Confirmed` → `InProgress` (Freelancer when starting).
        - [x] `InProgress` → `Completed` (Freelancer only).
        - [x] `Completed` → `Closed` (Client approval required? **Yes, consistency with Tasks**).
        - [x] `Confirmed` → `Canceled` (Both, requires reason).
        - [x] **Data Update Rules:**
            - [x] `Reschedule`: Update `scheduledAt`, store `rescheduled_by`, `reschedule_note`, emit `booking_rescheduled`.

- [x] **1.3 Unified "Active Work" Model (Enhanced)**
    - [x] Create `WorkItem` model to unify Tasks and Bookings for the UI.
    - [x] **Fields**:
        - `id`, `type` (Task/Booking).
        - `title`.
        - `counterpartyId`, `counterpartyName`, `counterpartyAvatar`, `counterpartyRole`.
        - `sourceId` (Original entity ID).
        - `statusRaw` (Original Enum), `statusUiBucket` (Active, Waiting, Done).
        - `createdAt`, `dueAt` / `scheduledAt`.
        - `completedAt`.
        - `lastUpdate`.
        - `primaryActionType` (Enum: Start, Pay, Review, etc.).
        - `deepLinkRoute`.
        - `permissions` (Computed object: `canStart`, `canComplete`, `canApprove`, `canCancel`, `canReschedule`).

- [x] **1.4 Dashboard Navigation Shell**
    - [x] Create `DashboardScreen` scaffold with persistent `BottomNavigationBar`.
    - [x] Implement `RoleSwitch` (Client ↔ Freelancer) persisting to local storage.
    - [x] Ensure role switch triggers full viewmodel refresh.

---

## 📊 Phase 2: Tab 1 - Overview (The Hub)
**Goal:** Immediate insight.

- [x] **2.1 Summary Counters (Role-Corrected)**
    - [x] **Freelancer View:**
        - [x] `Pending Bookings` (Received, waiting my confirm).
        - [x] `Active Work` (InProgress count).
        - [x] `New Messages` (Unread count).
        - [x] `New Offers` (On my posted tasks - *If applicable*).
    - [x] **Client View:**
        - [x] `Active Bookings` (Confirmed/InProgress).
        - [x] `Open Tasks` (Waiting for offers).
        - [x] `New Offers` (Received on tasks).
        - [x] `Unread Messages`.

- [x] **2.2 "Next Actions" Widget**
    - [x] Query high-priority items based on Phase 1.2 rules.
    - [x] Example: "Confirm Booking #123", "Approve Work".

- [x] **2.3 Activity Feed (Integrated Source)**
    - [x] **Schema Definition (`activity_log`):**
        - `id`, `actor_id`, `actor_role`, `target_type`, `target_id`, `event_type`, `metadata`, `created_at`.
    - [x] **Writer:** Database Triggers (for status changes) + Service Layer (manual events).
    - [x] **Minimum Events:**
        - Booking: `created`, `confirmed`, `canceled`, `declined`, `started`, `completed`, `closed`, `rescheduled`.
        - Task: `created`, `assigned`, `started`, `completed`, `closed`, `canceled`.
        - Offer: `submitted`, `withdrawn`, `accepted`, `rejected`.
    - [x] **UI:** Last 5-10 items with deep links.

---

## 📝 Phase 3: Tab 2 - Management (Supply & Demand)
**Goal:** Manage what I sell (Services) or buy (Tasks).

- [x] **3.1 Freelancer: "My Services"**
    - [x] List views for `services` table.
    - [x] Tabs: `Active`, `Drafts`, `Paused` (Archived).

- [x] **3.2 Client: "My Tasks"**
    - [x] List views for `tasks` table.
    - [x] Tabs: `Open`, `Assigned`, `History` (Completed/Closed).
    - [x] Actions: View Offers (for Open), Cancel.

---

## 📅 Phase 4: Tab 3 - Bookings (Calendar)
**Goal:** Reservation management.

- [x] **4.1 Bookings List Filters**
    - [x] **Filters:** `Pending`, `Confirmed`, `InProgress`, `Completed`, `Canceled/Declined`.
    - [x] **Sorting:** `scheduledAt` ASC (upcoming first). Separate into "Upcoming" and "Past" sections.

- [x] **4.2 Booking Actions (Role-Based)**
    - [x] **Freelancer:** Confirm, Decline, Propose New Time.
    - [x] **Client:** Edit Note, Cancel, Reschedule.

---

## 🚀 Phase 5: Tab 4 - Active Work (Execution)
**Goal:** The Unified Workspace.

- [x] **5.1 Merged List & Logic**
    - [x] Merge `Tasks` and `Bookings` into `WorkItem` list.
    - [x] **Sorting Rules:**
        - `Up Next`: Sort by `dueAt` ASC.
        - `In Progress`: Sort by `lastUpdate` DESC.
        - `In Review`: Sort by `completedAt` DESC.

- [x] **5.2 Primary Execution Actions (One Click)**
    - [x] Derived from `WorkItem.permissions`.
    - [x] `Start Work`, `Mark Completed`, `Approve & Close`.

---

## 📬 Phase 6: Tab 5 - Inbox (Negotiation Only)
**Goal:** Offers and pre-contract discussions. **NO MESSAGES HERE.**

- [x] **6.1 Offers Scope**
    - [x] **Client:** Offers Received (grouped by `taskId`, sorted by newest `created_at`).
    - [x] **Freelancer:** My Submitted Offers.
    - [x] **Strict Rule:** Chat/Messages live in `ChatModule`, not here.

- [x] **6.2 Actions**
    - [x] Accept/Reject (Client).
    - [x] Withdraw (Freelancer).

---

## 🔗 Phase 7: Deep Linking & Routing
**Goal:** Notifications work perfectly.

- [x] **7.1 Route Mapping**
    - [x] `booking_created` -> `Dashboard(Bookings) -> BookingDetails(bookingId)`.
    - [x] `task_assigned` -> `Dashboard(ActiveWork) -> WorkDetails(type=task, id=taskId)`.
    - [x] `offer_received` -> `Dashboard(Inbox) -> TaskOffers(taskId)`.
    - [x] `message_new` -> `ChatScreen(conversationId)`.

- [x] **7.2 Fallback Rules**
    - [x] Target Not Found -> `Dashboard(Overview)` with snackbar "Item not available".
    - [x] Access Denied -> `Dashboard(Overview)` with snackbar "Access denied".

---

## ⚙️ Phase 8: Polish & Performance
**Goal:** Production ready.

- [x] **8.1 Performance Rules**
    - [x] **Single Fetch Rule:** Each tab uses max 1 list fetch + 1 counters fetch.
    - [x] **Realtime Scope:** Strictly limited to counters (unread, pending, new offers).
    - [x] **Caching:** Cache last result locally to show instantly on load.

- [x] **8.2 Empty States**
    - [x] "No Bookings? Create a Service." (Freelancer).
    - [x] "No Active Work? Find a Freelancer." (Client).