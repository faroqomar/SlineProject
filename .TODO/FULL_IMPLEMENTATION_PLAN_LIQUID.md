# SLine "Liquid Glass" Implementation Plan (Refined V4)

This is the master plan to transform SLine into the "Liquid Glass" premium marketplace.
**Guidance**: This plan is authoritative. All changes must align with the "Liquid Glass" style rules and the "Work Lifecycle" definitions.

---

## 🔹 Phase 1: Foundation, Logic & Lifecycle (CRITICAL)
**Goal**: Build ALL underlying logic (Wallet, Orders, Lifecycle, Stats, Operational Flows) *before* touching the UI.
**Why**: The Dashboard (Phase 3) relies on these numbers being 100% correct. We cannot build the display if the data source doesn't exist.

### 1.1 Fix Wallet Logic (The "Zero State" Fix)
- **Goal**: Make Wallet Screen & Dashboard Snapshot show correct REAL data for everyone from a single source.
- **How**:
  - Update `wallet_balances` view to use `COALESCE(SUM(...), 0)` to return 0 instead of null.
  - **Single Source of Truth**: `WalletRepository.getWalletBalance()` MUST call the exact same view used by Dashboard Snapshot. NO duplicate queries.
  - **New User Handling**: Ensure a wallet row exists on signup OR the view handles "no rows" gracefully.
  - Verify RLS: User can ONLY see their own wallet.
- **Acceptance**:
  - Existing user sees correct balance on both Dashboard and Wallet Screen.
  - **New User** sees "Available: $0.00 / Held: $0.00" (Not loading, not error).

### 1.2 Dashboard Stats Definitions (Strict Math)
- **Goal**: Implement `DashboardViewModel.fetchStats()` with these EXACT definitions.
- **Definitions**:
  1. **Pending Actions (Red Dot)**:
     - *Client*: `unpaid_bookings` + `active_orders_pending_payment` + `delivered_work_awaiting_review` + `paid_request_pending_bookings` (if manual confirm needed).
     - *Freelancer*: `paid_request_pending_bookings` + `overdue_deliverables` + `revisions_requested`.
  2. **Active Work**:
     - *Both*: `bookings(active | delivered)` + `orders(active | delivered)`.
  3. **Offers**:
     - *Client*: `proposals(status=submitted)` on `tasks(status=open)`.
     - *Freelancer*: `my_proposals(status=submitted | shortlisted)`.
  4. **Messages**:
     - *Both*: `unread_chat_count`.
- **Requirement**: Each counter must have a corresponding "Deep Link" logic to open the filtered list.

### 1.3 Next Actions Definitions (Strict Priority)
- **Goal**: Determine exact top 1-3 items for the "Overview" tab.
- **Sorting Rule**: Tier (Money/Trust) > Urgency (Time) > CreatedAt.
- **Client Sources**:
  1. `Orders(pending_payment)` | `Bookings(unpaid)` (Money).
  2. `Work(delivered)` (Review needed - Trust).
  3. `Extension Requests` (Time Decision).
  4. `Tasks(open)` with >0 new proposals.
- **Freelancer Sources**:
  1. `Bookings(paid_request_pending)` (Money/Acceptance).
  2. `Work(overdue)` | `Work(revision_requested)`.
- **Result**: "What to do now" is never empty if there is real work.

### 1.4 Entity Ownership Fields (Data & Display)
- **Goal**: Eliminate "Who booked this?" confusion.
- **Data Requirements**:
  - `Bookings`: `client_id`, `freelancer_id`.
  - `Orders`: `client_id`, `freelancer_id`, `task_id`.
  - `Tasks`: `owner_id` (client).
  - `Proposals`: `freelancer_id`.
- **UI Logic (Counterpart Face)**:
  - If `currentUser == client_id` -> Show `freelancer` (Label: "Assigned to").
  - If `currentUser == freelancer_id` -> Show `client` (Label: "Booked by").
- **Acceptance**: Every card strictly follows this logic. No "You" vs "You".

### 1.5 Unified Work Lifecycle & Details Screen
- **Goal**: One unified interface for 'doing the work'.
- **Entity**: `WorkItemDetailsScreen` (Handles BOTH Order & Booking).
- **Sections**:
  1. **Summary**: Header, Status, Price, Counterpart.
  2. **Requirements**: Description, Deliverables.
  3. **Timeline**: Start date, Due date, Extension history.
  4. **Action Center**: The decision buttons (see 1.6).
  5. **Extension Requests**: If pending, shows approval buttons (Client).
  6. **Delivery History**: Past submissions, revisions.
  7. **Chat Shortcut**: Floating action or fixed header button.

### 1.6 Work Item Action Surface (Operational Spec)
- **Goal**: Define exactly WHERE decisions happen and WHAT options are available per status.
- **Rule**: **Work Tab** = Execution Management. **Inbox** = Communication only (No decisions).
- **Freelancer View Logic**:
  - **A) paid_request_pending (Booking)**: `Accept` (Active), `Decline` (Refund).
  - **B) active**: `Deliver Work` (Upload Sheet), `Request Extension` (Sheet).
  - **C) delivered**: View Only (Waiting for Review).
  - **D) revision_requested**: `Update & Re-deliver`.
- **Client View Logic**:
  - **A) pending_payment (Order)**: `Pay Now` (Activates).
  - **B) active**: `Open` (Monitor), **Extension Requests** (See below).
  - **C) delivered**: `Approve & Release` (Completed), `Request Revision` (Active), `Dispute`.
- **Extension Decision Flow (Client)**:
  - Location: **Overview Next Actions** (Urgency) OR **WorkItemDetails**.
  - Actions:
     - **Accept**: Updates `due_date`, marks request `accepted`.
     - **Reject**: Marks request `rejected`, notifies freelancer.

---

## 🔹 Phase 2: The "Liquid Glass" Design System
**Goal**: Create the visual language (Tokens & Components). UI development speed will 3x after this.

### 2.1 Design Tokens Setup
- **How**: Update `AppColors` (Teal `#146068`, Gold `#f3bb19`, Off-White `#f4f3f1`, Text `#0c0c0c`) & `AppTypography` ("Plus Jakarta Sans").

### 2.2 Reusable Glass Components
- **How**: `GlassCard`, `GlassButton`, `StatusBadge`, `GlassContainer` (optimized).

---

## 🔹 Phase 3: Dashboard Overhaul (The Core)
**Goal**: Rebuild the 4 tabs matching the "Liquid Glass" style and "Role-Based" content. Logic is READY from Phase 1.

### 3.1 Overview Tab (Home)
- **Goal**: "Answer in 5 seconds: What to do now?"
- **How**:
  - **Wallet Snapshot**: Connect to `1.1` data.
  - **Stats Grid**: Connect to `1.2` definitions. Deep Links enabled.
  - **Next Actions**: Connect to `1.3` logic. Shows top 3 items.

### 3.2 Bookings Tab (Service Bookings)
- **Goal**: Service Management.
- **How**:
  - **Card**: Use `1.4` Entity Ownership Logic.
  - **Actions**: Wired to `1.6` Operational Spec.

### 3.3 Work Tab (Tenders & Orders)
- **Goal**: Strict Separation based on `1.6` Rules.
- **Layout**:
  - **Client**:
    1. `Active Work` (Orders + Bookings) - Execution.
    2. `Posted Tasks` - Hiring.
    3. `Offers Inbox` - Reviewing.
  - **Freelancer**:
    1. `My Deliverables` (Orders + Bookings) - Execution.
    2. `My Proposals` - Sales.
    3. `My Services` - Assets.
- **Result**: "Execution" happens here.

### 3.4 Inbox Tab
- **Goal**: Clean Comms.
- **How**: Remove Offers. Show only Chats & System Notifications.

---

## 🔹 Phase 4: Search, Profile & Polish
**Goal**: Secondary screens and finishing touches.

### 4.1 Search Screens
- **Client**: Search Services/Freelancers.
- **Freelancer**: Search Open Tasks.

### 4.2 Profile & Projects
- **Assets**: My Projects (History), Portfolio Grid.

### 4.3 QA & "Liquid" Polish
- **Goal**: The "Wow" Factor.
- **How**: Micro-animations, Light Mode contrast, Empty state illustrations.

---

## 🔹 Verification Checklist (Definition of Done)
- [ ] Wallet shows $0.00 for new users from Single Source.
- [ ] Work Tab `Active Work` lists BOTH Orders and Bookings.
- [ ] `WorkItemDetailsScreen` is used for BOTH Orders and Bookings.
- [ ] Client sees "Accept/Reject" for Extension Requests in Next Actions.
- [ ] Work Tab contains NO Proposals in the Active/Deliverable lists (only in dedicated sections).
- [ ] Inbox contains NO Offers.
