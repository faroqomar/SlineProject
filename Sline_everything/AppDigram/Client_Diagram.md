---
config:
  look: neo
  theme: neo-dark
  layout: dagre
---
flowchart LR

C(("Client"))
F(("Freelancer"))

%% =========================================================
%% ENTRY POINTS (Client)  +  STRICT SEPARATION NOTE
%% =========================================================
subgraph ENTRY_C["Entry Points (Pre-Activation)"]
direction TB

%% Tender (Open Tender -> Awarded -> Pending Payment -> Active)
T0["OPEN TENDER (Draft/Open)\nCollect proposals (task_requests)\n(Does NOT enter Work Engine view)"] --> T1{"Award freelancer?"}
T1 -- "No" --> T2["Edit / Close tender"]
T1 -- "Yes" --> T3["PENDING PAYMENT (Awarded)\nClient must pay to activate"]
T3 --> T4["Pay (escrow held)\nActivate work"] --> W_ACTIVE

%% Booking (Pay-first -> Request Pending -> Active)
B0["Browse services"] --> B1["Select package + requirements"] --> B2["Pay & Request (escrow held)"]
B2 --> B3["REQUEST PENDING (Escrow Held)\nWaiting freelancer acceptance"]
B3 --> B4{"Freelancer accepts?"}
B4 -- "Decline/timeout" --> B5["REFUND (booking closes)\nMoves to Cancelled history"]
B4 -- "Accept" --> W_ACTIVE

end

%% =========================================================
%% UNIFIED WORK ENGINE (Post-Activation Only)
%% Source: vw_unified_work_items (7 unified states)
%% =========================================================
subgraph WORK_ENGINE_C["Unified Work Engine (Post-Activation)\n(vw_unified_work_items only)"]
direction TB

W_ACTIVE["ACTIVE (requirements frozen)"] --> W_WAIT["Work + chat (post-activation)"]

%% Change Request (legal scope change)
W_WAIT --> W_CHANGE["CHANGE REQUEST (extra scope)\nstructured change only"]
W_CHANGE --> W_CHANGE_DEC{"Client accepts?"}
W_CHANGE_DEC -- "Yes (pay extra if needed)\nscope/time updated" --> W_WAIT
W_CHANGE_DEC -- "No (keep original scope)" --> W_WAIT

%% Extension Request (legal deadline change)
W_WAIT --> W_EXT["EXTENSION REQUEST\nnew deadline proposed"]
W_EXT --> W_EXT_DEC{"Client accepts?"}
W_EXT_DEC -- "Yes (deadline updated)" --> W_WAIT
W_EXT_DEC -- "No (deadlock avoidance)" --> W_DISPUTE

%% Delivery + Review (Needs Review pinned in UI)
W_WAIT --> W_DEL["DELIVERED (Needs Review)\nReview timer starts"]
W_DEL --> W_REVIEW["Review window (timer visible)"]
W_REVIEW --> W_DEC{"Client decision"}
W_DEC -- "Approve OR Auto-approve" --> W_DONE["COMPLETED (payout released)"]
W_DEC -- "Request revision (if remaining)" --> W_WAIT
W_DEC -- "Dispute" --> W_DISPUTE

%% Cancellation (mutual only)
W_WAIT --> W_CANCEL["CANCEL REQUEST (mutual)"]
W_CANCEL --> W_CANCEL_DEC{"Freelancer agrees?"}
W_CANCEL_DEC -- "Yes (refund policy applied)" --> W_CANCELLED["CANCELED / REFUNDED"]
W_CANCEL_DEC -- "No (deadlock avoidance)" --> W_DISPUTE

%% Dispute (Admin resolves to refund/payout/split)
W_DISPUTE["DISPUTED (Admin Review)\nEvidence may be required"] --> W_ADMIN["Admin review"]
W_ADMIN --> W_ADMIN_DEC{"Decision"}
W_ADMIN_DEC -- "Refund client" --> W_CANCELLED
W_ADMIN_DEC -- "Pay freelancer" --> W_DONE
W_ADMIN_DEC -- "Split" --> W_SPLIT["SPLIT (resolved)\nDone bucket w/ Split label"]

end

%% wiring
C --> ENTRY_C
F --> ENTRY_C

## **Client Final v1 — Full Spec (Step-by-step, zero ambiguity)**

This document explains the **Client** side of the **Final v1** flow in exact operational steps.

It is written so an AI can implement UI + logic **without guessing**.

No code. No implementation details. Only behavior, UI placement, and required actions.

---

# **0) Definitions (must be consistent everywhere)**

## **0.1 Work Item (Unified Object)**

A **Work Item** is a single operational unit shown to the client once it becomes real work.

A Work Item can be created from:

- **Tender Order** (client posts tender → reviews proposals → awards freelancer → pays escrow → becomes ACTIVE)
- **Booking** (client selects service package → submits requirements → pays escrow → freelancer accepts → becomes ACTIVE)

After activation, both must behave identically inside the “Work Engine”.

**Client UI rule:**

Client should not need to care whether it came from Tender or Booking once it reaches ACTIVE.

It must be shown inside **Work tab** as an “Active Work Item”.

---

## **0.2 User-facing states (Client)**

Use only these states in the UI:

1. **Draft / Open Tender**
    
    Tender is posted and collecting proposals.
    
2. **Pending Payment (Awarded)**
    
    Client awarded a freelancer but hasn’t paid yet (tender only).
    
3. **Request Pending (Escrow Held)**
    
    Client paid, but freelancer has not accepted yet (booking only).
    
4. **Active (Requirements Frozen)**
    
    Work started. Requirements are frozen.
    
5. **Delivered (Needs Review)**
    
    Freelancer delivered work. Client must decide.
    
6. **Completed (Payout Released)**
    
    Work finished. Payment released.
    
7. **Cancelled (Refund Policy Applied)**
    
    Work ended early. Refund/payout handled.
    
8. **Dispute (Admin Review)**
    
    Conflict escalated. Admin decides payout/refund/split.
    

---

## **0.3 “Requirements Frozen” (critical)**

The moment a Work Item becomes **ACTIVE**, the current requirements are frozen as the baseline agreement.

Any change after that must go through a **Change Request** process.

No silent changes are allowed.

---

# **1) Client Entry Points (how client starts work)**

Client has two routes:

- Tender path (post and hire)
- Booking path (buy service package)

Both end in the same unified work engine.

---

# **2) Entry Route A — Tender (Client posts → hires via proposals)**

## **Step A1 — Post Tender**

**Where it appears:**

- A “Post Tender” entry on Home/Dashboard (Client mode)
- A dedicated “Tenders” section

**Client action:**

Fill tender details:

- title
- description
- budget
- deadline
- optional attachments

Then publish.

**System result:**

Tender becomes “Open” and visible to freelancers.

---

## **Step A2 — Wait for Proposals**

**Where it appears:**

- Tender details screen shows “Proposals count”
- Dashboard “Next Actions” can show “Tender has new proposals” (if any)

**Client action:**

Wait or optionally edit tender.

---

## **Step A3 — Review Proposals**

**Where it appears:**

Tender details → proposals list.

**Client action:**

Open proposals; compare:

- price
- delivery time
- cover letter
- profile trust signals

Optional actions:

- Message freelancer (chat)
- Shortlist
- Reject

---

## **Step A4 — Award Freelancer**

**Where it appears:**

Proposal details → “Award / Accept” button.

**Client action:**

Award one freelancer.

**System result:**

Tender enters: **Pending Payment (Awarded)**

**Global-grade rule:**

Award ≠ work start.

Work is not active until payment is made and escrow is held.

---

## **Step A5 — Pending Payment (Awarded)**

**Where it appears (must be obvious):**

- Dashboard “Next Actions” (Client mode) as high priority: “Complete payment to start”
- Work/Orders list shows it as “Pending Payment” with a “Pay Now” CTA

**Client actions available:**

- Pay now (recommended)
- Pay later (allowed, but must auto-expire after a defined time)
- Cancel before payment (no escrow, no work)

**System requirements:**

If the client does not pay within the allowed window:

- The order auto-expires/cancels
- The freelancer should not start work

---

## **Step A6 — Pay (Escrow Held) → ACTIVE**

Client pays; money is held in escrow.

**System result:**

A unified Work Item becomes **ACTIVE**.

Requirements are now frozen.

---

# **3) Entry Route B — Booking (Client buys a service package)**

## **Step B1 — Browse Services**

**Where it appears:**

- “Browse Services” entry on Dashboard/Home (Client mode)
- Search/filter UI

**Client action:**

Search, filter, open service details.

Optional:

- Chat before buying (ask questions)

---

## **Step B2 — Choose Package + Requirements**

**Where it appears:**

Service details → packages section.

**Client action:**

- Select package (Basic/Standard/Premium)
- Fill requirements (answers/description/files)

**Hard rule:**

Client cannot proceed to pay without requirements being submitted (or explicitly marked “to be provided later”, if you support that).

---

## **Step B3 — Pay & Request (Escrow Held)**

**Where it appears:**

Checkout/payment screen.

**Client action:**

Pay now.

**System result:**

Booking is created as:

**Request Pending (Escrow Held)**

Freelancer must accept/decline within a window.

---

## **Step B4 — Waiting for Freelancer Response**

**Where it appears:**

- Work list shows: “Request Pending”
- Dashboard “Next Actions”: “Waiting freelancer acceptance” (medium priority)

**Client action:**

Wait. Optionally send additional clarifications in chat.

**System rule:**

If freelancer declines or times out:

- booking closes
- escrow is refunded to client
- item moves to Cancelled/Refunded history

---

## **Step B5 — Freelancer Accepts → ACTIVE**

When freelancer accepts:

- Work item becomes **ACTIVE**
- Requirements become frozen
- The unified engine starts

---

# **4) Unified Work Engine (Client operations inside ACTIVE work)**

Once ACTIVE, tender and booking behave the same.

## **4.1 ACTIVE (Requirements Frozen)**

**Where it appears:**

- Work tab → Active
- Dashboard counters: Active increases
- Dashboard “Next Actions” may show “Freelancer asked a question” if needed

**Client must do:**

- Confirm requirements are complete
- Respond to freelancer questions quickly

**Rule:**

Any new scope request must go through Change Request.

---

## **4.2 Wait + Chat**

**Where it appears:**

Inside the work item:

- chat thread
- requirements section
- timeline/status section

**Client does:**

- answers questions
- confirms progress steps if needed
- avoids adding scope informally

---

# **5) Change Request (extra scope) — only legal way to change requirements**

## **5.1 When it triggers**

Trigger condition:

- Client wants extra features beyond frozen requirements
- Client wants to change the original request meaningfully

## **5.2 How it appears**

Inside the work item as a structured object:

- “Change Request” with:
    - scope change summary
    - added time
    - added price (if any)

## **5.3 Client decision**

**If client accepts:**

- scope updates
- timeline updates
- if extra payment exists → client pays → escrow holds extra
- work continues

**If client declines:**

- scope remains original
- work continues under original scope

No automatic dispute unless one party refuses to continue fairly.

---

# **6) Extension Request (deadline change)**

## **6.1 When it triggers**

Freelancer requests more time.

## **6.2 Where it appears**

Inside the work item:

- structured “Extension Request”
- includes new delivery date/time + reason

## **6.3 Client decision**

**Accept:**

- deadline updates
- work continues

**Decline:**

- system treats it as a conflict path
- next step is Dispute if it blocks completion (to prevent deadlocks)

---

# **7) Delivery & Review (most important client responsibility)**

## **7.1 Delivered → Needs Review**

Freelancer marks DELIVERED.

**Where it appears (must be aggressive):**

- Dashboard “Next Actions” (Client mode) as top priority
- Work tab: item moves to “Needs Review”
- push notification + in-app badge

**Client must do:**

Open the delivery and choose one of:

- Approve
- Request revision (if remaining)
- Dispute
    
    Or do nothing (auto-approve happens)
    

---

## **7.2 Review Window (timer)**

A review window starts immediately after delivery.

**Client view must show:**

- remaining time until auto-approve
- the actions clearly

---

# **8) Client Decision Outcomes**

## **8.1 Approve → COMPLETED (release payout)**

Client approves.

**System result:**

- Escrow releases to freelancer
- Work item becomes COMPLETED

**Client UI:**

- show completion summary
- show “Leave rating/review” (optional, but global-grade)

---

## **8.2 Auto-approve (client silent) → COMPLETED**

If client takes no action until the timer ends:

- system auto-approves
- payout releases

**Client UI:**

- show “Auto-completed due to no response”
- still allow dispute only if you have a strict post-completion policy (optional; many systems restrict it)

---

## **8.3 Request Revision (if remaining)**

Client requests revision.

**Rules:**

- Allowed only if revision count remains
- Must include clear feedback and requested changes

**System result:**

- item returns to ACTIVE work state
- freelancer works again and re-delivers

If no revisions remain:

- client must either approve, accept a paid change request, or dispute

---

## **8.4 Dispute**

Client disputes the delivery or overall work quality.

**Client must provide:**

- evidence
- explanation
- what outcome they want (refund / partial / rework)

**System result:**

- status becomes DISPUTE
- normal completion actions are locked

---

# **9) Cancellation (Mutual only)**

## **9.1 Cancel request**

Client can request cancellation during ACTIVE (and optionally after delivery).

**Where it appears:**

Inside the work item: “Request Cancellation”

## **9.2 Freelancer agrees?**

**Yes:**

- status becomes CANCELLED
- refund policy applies
- escrow handled

**No:**

- escalates to DISPUTE to avoid deadlock

---

# **10) Dispute → Admin Review → Decision**

## **10.1 Dispute screen (client requirements)**

UI must show:

- claim summary
- evidence upload
- timeline of events (requirements freeze, changes, delivery timestamps)

Client must submit:

- what was promised vs what was delivered
- what’s missing
- any proof

---

## **10.2 Admin decision (final outcomes)**

Admin selects one:

### **A) Refund client**

- client receives refund (full/partial depending on policy)
- work ends as CANCELLED

### **B) Pay freelancer**

- payout releases to freelancer
- work ends as COMPLETED

### **C) Split**

- partial refund to client + partial payout to freelancer
- work ends as SPLIT (resolved)

Client UI must show:

- final amounts
- short reason
- outcome label

---

# **11) Where each state must appear in the Dashboard (Client mode)**

This must match your Dashboard tabs: Overview / Bookings / Work / Inbox.

## **11.1 Overview Tab (Client mode)**

Must show:

**Next Actions (top 3):**

1. Delivered needs review (highest priority)
2. Tender awarded but pending payment (very high priority)
3. Dispute requiring evidence / admin updates (high priority)
    
    Then:
    
- Pending freelancer acceptance (booking request pending)

**Counters grid:**

- Active
- Needs Review (Delivered)
- Pending Payment
- Completed

---

## **11.2 Bookings Tab (Client mode)**

Shows only booking-related timeline items:

- Request Pending
- Active bookings
- Past bookings (completed/cancelled/refunded)

---

## **11.3 Work Tab (Client mode)**

This is the main list for both Tender Orders and Bookings once ACTIVE.

Must show filters:

- Active
- Done
- Cancelled
    
    Optionally:
    
- Needs Review (Delivered) as a special filter or as top of Active.

---

## **11.4 Inbox Tab (Client mode)**

Only pre-work offers and negotiation items:

- proposals received (tender offers)
- chats related to offers before payment/activation

Once a work item becomes ACTIVE, it must move to Work.

---

# **12) Non-negotiable global-grade rules (must be enforced)**

1. **Tender work does not start until escrow is held** (award alone is not enough)
2. **Requirements freeze at ACTIVE**
3. **Change request is the only valid scope change**
4. **Extension request is the only valid deadline change**
5. **Client must review delivered work within a window or auto-approve triggers**
6. **Revisions are limited**
7. **Cancellation requires mutual agreement; otherwise dispute**
8. **Dispute must end in Pay / Refund / Split**

---

If you want the “final-final” version next, I can convert this into a **shorter “AI Execution Rules” checklist** (same rules, fewer words) so it’s easier to paste into agents and prevent mistakes.

.

# SLine Dashboard Documentation (Current Implementation)

## 1. Overview

The Dashboard is the central hub of the SLine application (Index 3 in Main Navigation). It serves as the landing page for users to manage their operational activities.

**Key Characteristics:**

- **Role-Based:** Instantly switchable between `Freelancer` and `Client` views using the `_RoleSwitch` widget.
- **Offline-First:** Uses `DashboardCacheService` to load data instantly before syncing with Supabase.
- **Strict MVVM:** UI (`DashboardScreen`) listens to `DashboardViewModel` and never calls Supabase directly.

## 2. Architecture & Diagram

### Widget Tree Structure

```mermaid
graph TD
    MainNavigation[MainNavigationScreen] -->|Index 3| DashboardScreen

    subgraph DashboardScreen
        Header[AppBar & Role Switcher]
        TabBar[Overview | Bookings | Work | Inbox]

        subgraph Tabs
            Overview[OverviewTab] --> Wallet[WalletSnapshotCard]
            Overview --> Counters[DashboardCountersGrid]
            Overview --> NextActions[NextActionsList]
            Overview --> Activity[ActivityFeedPreview]

            Bookings[BookingsTab] --> BookingList[Upcoming & Past Lists]

            Work[WorkTab] --> WorkFilters[Active | Done | Cancelled Tabs]
            Work --> WorkList[WorkItem Cards]

            Inbox[InboxTab] --> OfferList[Offer Cards]
        end
    end

    DashboardScreen -->|Provider| VM[DashboardViewModel]
    VM -->|Data| Repo[DashboardRepository]
    VM -->|Data| Cache[DashboardCacheService]
    VM -->|Data| Services[TaskService, BookingService]
```

### Data Flow

1. **Init:** `DashboardViewModel` loads cached data immediately (WorkItems, Activity, Counters).
2. **Sync:** Fetches fresh data from Supabase in the background.
3. **Role Switch:** updating `UserRole` triggers a UI refresh and re-filters data (e.g., fetching `client` bookings vs `provider` bookings).

## 3. Tabs & Detailed Breakdown

### A. Overview Tab (`OverviewTab`)

**Goal:** Provide a high-level summary and immediate "Next Actions" so the user knows what to do next.

**Components:**

1. **Greeting:** "Hello, [Name]!" with a role-specific tagline.
    - *Freelancer:* "Ready to pick up some work?"
    - *Client:* "Let's get your projects moving."
2. **Wallet Snapshot (`WalletSnapshotCard`):** Displays current balance (mocked or from Wallet feature).
3. **Counters Grid (`DashboardCountersGrid`):**
    - 4 Stats: Active Jobs, Pending Requests, Completed, Rating/Earnings.
4. **Next Actions (`NextActionsList`):**
    - **Logic:** The VM calculates the top 3 most urgent items based on:
        - **Money/Trust:** Pending payments, delivered work needing review. (Highest Priority)
        - **Urgency:** Items scheduled within 48 hours.
        - **Recency:** Most recently updated active items.
5. **Activity Feed (`ActivityFeedPreview`):**
    - Shows recent logs (e.g., "New offer received", "Booking confirmed").
    - Expandable with "See All".

### B. Bookings Tab (`BookingsTab`)

**Goal:** Manage calendar-based appointments (Tenders/Bookings).

**Logic:**

- **Freelancer View:** Shows bookings where user is the `Provider`.
- **Client View:** Shows bookings where user is the `Client`.
- **Sections:**
    1. **Upcoming:** `scheduledAt` is in the future OR status is Pending/Confirmed.
    2. **Past:** `scheduledAt` is past.

### C. Work Tab (`WorkTab`)

**Goal:** The main operational list for all Tasks and Bookings.

**Structure:**
Uses a nested `TabBar` with 3 filters:

1. **Active:**
    - Statuses: `open`, `assigned`, `pending`, `confirmed`, `inprogress`, `paid_request_pending`.
    - Sorted by: Urgency (Schedule) > Creation Date.
2. **Done:**
    - Statuses: `completed`, `paid`, `reviewed`.
    - Sorted by: Completion Date (Newest first).
3. **Cancelled:**
    - Statuses: `cancelled`, `rejected`, `declined`.

**Item Model (`WorkItem`):**

- Unifies `Task` and `Booking` models into a single displayable item.
- **Primary Actions:** Smart button on the card (e.g., "Start Work", "Mark Complete", "Pay Now") determined by the item's status.

### D. Inbox Tab (`InboxTab`)

**Goal:** Manage offers (Task Requests) before they become active work.

**Logic:**

- **Client View:** Shows offers *received* from freelancers.
- **Freelancer View:** Shows offers *submitted* to clients.
- **Grouped View (VM Logic):** Offers are grouped by `Task` (e.g., "Fix my Sink" might have 3 offers). *Note: The UI currently shows a flat list in `InboxTab` but the VM supports grouping.*

**Actions:**

- **Accept:** Calls `acceptOffer` RPC -> Converts offer to Active Work.
- **Reject:** Removes offer.
- **Withdraw:** (Freelancer only) Cancels sent offer.

## 4. Services & Dependencies

- **DashboardRepository:** Aggregates calls to Supabase.
- **DashboardCacheService:** Local storage (Hive/SharedPreferences) for offline access.
- **TaskService:** Fetches Tasks, Offers, Tenders.
- **BookingService:** Fetches Calendar Bookings.
- **ServicesService:** Fetches User's listed services (for Management view - currently lazy loaded).

## 5. User Roles (Client vs Freelancer)

- **Freelancer Mode:**
    - See jobs assigned to YOU.
    - See bookings where YOU are the provider.
    - See offers YOU sent.
- **Client Mode:**
    - See jobs YOU posted.
    - See bookings where YOU hired someone.
    - See offers YOU received.