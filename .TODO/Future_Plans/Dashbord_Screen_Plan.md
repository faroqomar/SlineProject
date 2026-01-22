# SLine Dashboard Implementation Checklist

This document serves as the **FINAL MASTER CHECKLIST** for rebuilding the Dashboard. It incorporates strict logic for roles, permissions, data integrity, and performance.

---

## 🎨 Phase 0: Dashboard UI/UX Design (Prototype Only)
**Goal:** Build a complete Dashboard design that matches the existing app design matching, with all current + planned features visible as a demo. **No backend integration.**

- [ ] **0.1 Design Consistency Setup**
    - [ ] Reuse existing app theme (colors, gradients, shadows, typography, radius, spacing).
    - [ ] Reuse existing UI components (`AppButton`, `GlassContainer`, `AppCard`, etc.).
    - [ ] Confirm layout patterns match the current app (padding, headers).

- [ ] **0.2 Fake Data Layer (Mock Repository)**
    - [ ] Create a local mock provider returning:
        - [ ] Counters (randomized for testing).
        - [ ] Bookings list (covering all statuses: Pending/Confirmed/etc).
        - [ ] Tasks list (Open/Assigned/etc).
        - [ ] Offers list (Accepted/Rejected/etc).
        - [ ] Activity Log items.

- [ ] **0.3 Dashboard Shell (UI Only)**
    - [ ] Implement `DashboardScreen` scaffold.
    - [ ] persistent `BottomNavigationBar` (5 tabs).
    - [ ] `RoleSwitch` in AppBar (updates UI specific content immediately using mock data).

- [ ] **0.4 Tab 1: Overview (UI Prototype)**
    - [ ] **Counters:** Cards for both roles.
    - [ ] **Next Actions:** List of "to-do" items (mock deep navigation).
    - [ ] **Activity Feed:** Preview list (last 5 items) + "See All" button.

- [ ] **0.5 Tab 2: Manage (UI Prototype)**
    - [ ] **Freelancer:** "My Services" list with tabs (Active/Paused/Drafts).
    - [ ] **Client:** "My Tasks" list with tabs (Open/Assigned/History).
    - [ ] **Note:** Buttons (Edit/Pause/Cancel) are visual demo only.

- [ ] **0.6 Tab 3: Bookings (UI Prototype)**
    - [ ] **Filters:** Pending, Confirmed, InProgress, Completed, etc.
    - [ ] **Card UI:** `scheduledAt` prominent, status badge, action buttons.
    - [ ] **Demo Actions:** Confirm/Decline (Freelancer), Edit/Cancel (Client).

- [ ] **0.7 Tab 4: Active Work (UI Prototype)**
    - [ ] Unified `WorkItem` list (Tasks + Bookings mixed).
    - [ ] **Sections:** Up Next, In Progress, In Review.
    - [ ] **Demo Actions:** Start Work, Mark Completed, Approve & Close, Chat.

- [ ] **0.8 Tab 5: Inbox (UI Prototype - Offers Only)**
    - [ ] **Client:** Offers grouped by Task.
    - [ ] **Freelancer:** My Submitted Offers.
    - [ ] **Demo Actions:** Accept/Reject, Withdraw.

- [ ] **0.9 Demo Details Screens**
    - [ ] `BookingDetailsDemo`.
    - `TaskDetailsDemo`.
    - `WorkDetailsDemo`.
    - `ActivityListDemo`.

- [ ] **0.10 Acceptance**
    - [ ] Visually matches app design system perfection.
    - [ ] Navigate to all 5 tabs.
    - [ ] Switch roles and see content change.
    - [ ] All statuses visualized.

---

## 🎯 Phase 1: Foundation, Logic & State
**Goal:** Define the "Source of Truth" for statuses, transitions, and data models before touching UI.

- [ ] **1.1 Define Enums & Constants**
    - [ ] Update `TaskStatus`: `Open`, `Assigned`, `InProgress`, `Completed`, `Closed`, `Canceled`.
    - [ ] Update `BookingStatus`: `Pending`, `Confirmed`, `InProgress`, `Completed`, `Canceled`, `NoShow`, `Declined`.
    - [ ] Define `OfferStatus`: `Pending`, `Accepted`, `Rejected`, `Withdrawn`.
    - [ ] Create `UserRole` enum: `Client`, `Freelancer`.
    - [ ] Create `DashboardTab` enum: `Overview`, `Manage`, `Bookings`, `ActiveWork`, `Inbox`.

- [ ] **1.2 Define Transition Rules & Permissions (Backend Enforced)**
    - [ ] **Task Rules:**
        - [ ] `Open` / `Assigned` → `Canceled` (Client only, requires reason).
        - [ ] `InProgress` → `Canceled` (Restricted: requires Admin or Mutual Agreement - *Defer to Dispute System*).
        - [ ] `Completed` → `Canceled` (Disallowed).
        - [ ] `Completed` → `Closed` (Client only).
    - [ ] **Booking Rules:**
        - [ ] `Pending` → `Confirmed` (Freelancer only).
        - [ ] `Pending` → `Declined` (Freelancer only).
        - [ ] `Pending` → `Canceled` (Client only).
        - [ ] `Confirmed` → `InProgress` (Freelancer when starting).
        - [ ] `InProgress` → `Completed` (Freelancer only).
        - [ ] `Completed` → `Closed` (Client approval required? **Yes, consistency with Tasks**).
        - [ ] `Confirmed` → `Canceled` (Both, requires reason).

- [ ] **1.3 Unified "Active Work" Model (Enhanced)**
    - [ ] Create `WorkItem` model to unify Tasks and Bookings for the UI.
    - [ ] **Fields**:
        - `id`, `type` (Task/Booking).
        - `title`.
        - `counterpartyId`, `counterpartyName`, `counterpartyAvatar`, `counterpartyRole`.
        - `sourceId` (Original entity ID).
        - `statusRaw` (Original Enum), `statusUiBucket` (Active, Waiting, Done).
        - `createdAt`, `dueAt` / `scheduledAt`.
        - `lastUpdate`.
        - `primaryActionType` (Enum: Start, Pay, Review, etc.).
        - `deepLinkRoute`.
        - `permissions` (Computed object: `canStart`, `canComplete`, `canApprove`, `canCancel`, `canReschedule`).

- [ ] **1.4 Dashboard Navigation Shell**
    - [ ] Create `DashboardScreen` scaffold with persistent `BottomNavigationBar`.
    - [ ] Implement `RoleSwitch` (Client ↔ Freelancer) persisting to local storage.
    - [ ] Ensure role switch triggers full viewmodel refresh.

---

## 📊 Phase 2: Tab 1 - Overview (The Hub)
**Goal:** Immediate insight.

- [ ] **2.1 Summary Counters (Role-Corrected)**
    - [ ] **Freelancer View:**
        - [ ] `Pending Bookings` (Received, waiting my confirm).
        - [ ] `Active Work` (InProgress count).
        - [ ] `New Messages` (Unread count).
        - [ ] `New Offers` (On my posted tasks - *If applicable*).
    - [ ] **Client View:**
        - [ ] `Active Bookings` (Confirmed/InProgress).
        - [ ] `Open Tasks` (Waiting for offers).
        - [ ] `New Offers` (Received on tasks).
        - [ ] `Unread Messages`.

- [ ] **2.2 "Next Actions" Widget**
    - [ ] Query high-priority items based on Phase 1.2 rules.
    - [ ] Example: "Confirm Booking #123", "Approve Work".

- [ ] **2.3 Activity Feed (Integrated Source)**
    - [ ] **Schema Definition (`activity_log`):**
        - `id`, `actor_id`, `actor_role`, `target_type`, `target_id`, `event_type`, `metadata`, `created_at`.
    - [ ] **Writer:** Database Triggers (for status changes) + Service Layer (manual events).
    - [ ] **Minimum Events:**
        - Booking: `created`, `confirmed`, `canceled`, `declined`, `started`, `completed`, `closed`.
        - Task: `created`, `assigned`, `started`, `completed`, `closed`, `canceled`.
        - Offer: `submitted`, `withdrawn`, `accepted`, `rejected`.
    - [ ] **UI:** Last 5-10 items with deep links.

---

## 📝 Phase 3: Tab 2 - Management (Supply & Demand)
**Goal:** Manage what I sell (Services) or buy (Tasks).

- [ ] **3.1 Freelancer: "My Services"**
    - [ ] List views for `services` table.
    - [ ] Tabs: `Active`, `Drafts`, `Paused` (Archived).

- [ ] **3.2 Client: "My Tasks"**
    - [ ] List views for `tasks` table.
    - [ ] Tabs: `Open`, `Assigned`, `History` (Completed/Closed).
    - [ ] Actions: View Offers (for Open), Cancel.

---

## 📅 Phase 4: Tab 3 - Bookings (Calendar)
**Goal:** Reservation management.

- [ ] **4.1 Bookings List Filters**
    - [ ] **Filters:** `Pending`, `Confirmed`, `InProgress`, `Completed`, `Canceled/Declined`.
    - [ ] **Sorting:** By `scheduledAt` descending (future first).

- [ ] **4.2 Booking Actions (Role-Based)**
    - [ ] **Freelancer:** Confirm, Decline, Propose New Time.
    - [ ] **Client:** Edit Note, Cancel, Reschedule.

---

## 🚀 Phase 5: Tab 4 - Active Work (Execution)
**Goal:** The Unified Workspace.

- [ ] **5.1 Merged List & Logic**
    - [ ] Merge `Tasks` and `Bookings` into `WorkItem` list.
    - [ ] **Sorting Rules:**
        - `Up Next`: Sort by `dueAt` ASC.
        - `In Progress`: Sort by `lastUpdate` DESC.
        - `In Review`: Sort by `completedAt` DESC.

- [ ] **5.2 Primary Execution Actions (One Click)**
    - [ ] Derived from `WorkItem.permissions`.
    - [ ] `Start Work`, `Mark Completed`, `Approve & Close`.

---

## 📬 Phase 6: Tab 5 - Inbox (Negotiation Only)
**Goal:** Offers and pre-contract discussions. **NO MESSAGES HERE.**

- [ ] **6.1 Offers Scope**
    - [ ] **Client:** Offers Received (grouped by Task).
    - [ ] **Freelancer:** My Submitted Offers.
    - [ ] **Strict Rule:** Chat/Messages live in `ChatModule`, not here.

- [ ] **6.2 Actions**
    - [ ] Accept/Reject (Client).
    - [ ] Withdraw (Freelancer).

---

## 🔗 Phase 7: Deep Linking & Routing
**Goal:** Notifications work perfectly.

- [ ] **7.1 Route Mapping**
    - [ ] `booking_created` -> `Dashboard(Bookings) -> BookingDetails`.
    - [ ] `task_assigned` -> `Dashboard(ActiveWork) -> WorkDetails`.
    - [ ] `offer_received` -> `Dashboard(Inbox) -> TaskOffers`.
    - [ ] `message_new` -> `ChatScreen`.

- [ ] **7.2 Fallback Rules**
    - [ ] Target Not Found -> `Dashboard(Overview)` with snackbar "Item not available".
    - [ ] Access Denied -> `Dashboard(Overview)` with snackbar "Access denied".

---

## ⚙️ Phase 8: Polish & Performance
**Goal:** Production ready.

- [ ] **8.1 Performance Rules**
    - [ ] **Single Fetch Rule:** Each tab uses max 1 list fetch + 1 counters fetch.
    - [ ] **Realtime Scope:** Strictly limited to counters (unread, pending, new offers).
    - [ ] **Caching:** Cache last result locally to show instantly on load.

- [ ] **8.2 Empty States**
    - [ ] "No Bookings? Create a Service." (Freelancer).
    - [ ] "No Active Work? Find a Freelancer." (Client).