You are my Product + Engineering assistant for SLine (two-sided marketplace: Client + Freelancer).
Your job: produce a complete, implementation-ready Software Requirements + UI/Logic spec for ALL screens, with role-based visibility, and break it into small, verifiable tasks (each task with acceptance criteria).
Do NOT invent new features outside scope. Keep UX minimal, extremely clear, and consistent with the "Liquid Glass" style below.
Use the provided flow rules: Booking is Pay-first; Tender(Task) acceptance creates pending payment order; Work lifecycle is unified (Order/Booking -> delivered -> review -> completed/revisions/dispute).

=====================
A) GLOBAL DESIGN STYLE (MUST FOLLOW)
=====================
Style: "Liquid Glass" Glassmorphism. Ultra-modern, clean, airy, expensive tech aesthetic.
Font: Plus Jakarta Sans.
Color Palette:
- Primary Teal: #146068
- Accent Gold: #f3bb19
- Background Off-White: #f4f3f1
- Surface: translucent white glass with blur, subtle border, soft shadow
- Text: near-black #0c0c0c
Rules:
- Light mode only.
- High readability: enforce contrast; avoid text over heavy blur; use solid glass panels behind text.
- Every card has ONE primary CTA + optional "Chat" secondary CTA only.
- Every counter is clickable and opens the matching filtered list.
- Progressive disclosure: Overview shows summary; details in dedicated screens.

=====================
B) CORE DEFINITIONS (NO CONFUSION)
=====================
Entities:
1) Service = a freelancer listing (bookable). Not "work" itself.
2) Booking = client books a service package (Pay-first, escrow held, then activation).
3) Task (Tender) = client posts a task; freelancers send proposals (bids/offers).
4) Proposal/Offer = freelancer proposal on a task.
5) Order (Task Order) = created ONLY after client accepts a proposal; status starts pending_payment; when paid -> ACTIVE with escrow held.
6) Work Item = unified execution object: Booking ACTIVE or Order ACTIVE. Work lifecycle applies here.

Perspective tags (MUST display everywhere):
- Requester = the one requesting/ordering (Client)
- Provider = the one delivering (Freelancer)
Each Work card must show: "You are: Requester/Provider" + the counterpart name.

=====================
C) STATES (MUST MATCH DIAGRAM)
=====================
1) Booking Status:
- paid_request_pending (escrow held)
- active
- delivered
- completed
- cancelled
- refunded
- expired_unanswered

Payment Status:
- unpaid
- held
- released
- refunded

2) Task Status (Tender listing):
- draft
- open
- awarded (proposal chosen, but NOT yet active work)
- cancelled
- expired
(Do NOT use in_progress/delivered for the listing itself if you have Order.)

3) Proposal Status:
- submitted
- shortlisted (optional)
- rejected
- accepted (creates Order pending_payment)

4) Order Status (Task execution object):
- pending_payment
- active
- delivered
- completed
- cancelled
- disputed (optional)
Order payment is escrow:
- when paid: held
- when completed: released
- when cancelled/refund: refunded

Unified Work Lifecycle (for Booking ACTIVE or Order ACTIVE):
active -> delivered -> (client approves -> completed + release) OR (revision -> back to active) OR (dispute -> admin decision -> refund/pay/split)

=====================
D) NAVIGATION MAP (ALL SCREENS)
=====================
Bottom Navigation (4):
1) Dashboard (Tabs inside)
2) Search
3) My Projects
4) Profile

Dashboard Tabs (4):
- Overview
- Bookings
- Work
- Inbox

Additional screens reachable:
- Wallet
- Notifications center (if separated)
- Booking Details
- Order Details (Task Order)
- Task Details (Tender)
- Proposals List (for a Task)
- Proposal Details
- Service Details
- Chat Thread
- Dispute Flow (optional MVP if already planned)
- Settings

=====================
E) ROLE-BASED CONTENT: WHAT EACH ROLE SEES (STRICT)
=====================
For EVERY screen, specify:
- Visible sections
- Data shown per section
- Primary CTA per card
- Role differences (Client vs Freelancer)
- How Booking/Task/Order appear (Requester vs Provider)
- Empty states + error states

=====================
F) SCREEN-BY-SCREEN REQUIREMENTS
=====================

---------------------
1) DASHBOARD > OVERVIEW
---------------------
Purpose: answer in 5 seconds: what should I do now, what is active, what's new, where is my money.

Sections (top-to-bottom):
A) Wallet Snapshot (MUST EXIST)  [Fix problem #1]
- Show: Available balance, Held balance
- Client CTA: "Add funds" and/or "Pay now" when there is any unpaid/pending payment
- Freelancer CTA: "View wallet" (and "Withdraw" only if exists)

B) Stats Grid (4 counters, clickable)
Counters are role-aware:
1) Pending Actions:
- Client: unpaid bookings; delivered work awaiting review (booking/order); tasks open with new proposals; orders pending_payment
- Freelancer: bookings paid_request_pending waiting response; active work near/overdue; revisions requested; critical account blockers
2) Active Work:
- Client: bookings active/delivered + orders active/delivered
- Freelancer: bookings active/delivered + orders active/delivered
3) Messages: unread chat count
4) Offers:
- Client: new proposals on open tasks
- Freelancer: my submitted proposals not yet decided (and shortlisted if used)

C) Next Actions (1–3 items only, strict priority)
Priority: Money/Trust > Time > Growth
Examples:
- Client: "Pay for Order pending_payment", "Review delivery", "Review 6 proposals"
- Freelancer: "Respond to paid booking request", "Deliver overdue order", "Complete profile"
Each action routes to exact screen.

D) Recent Activity (last 20 events)
Events: booking/order status changes, payment changes, delivery submitted, proposal accepted/rejected, messages.

Acceptance criteria:
- Wallet is visible on Overview.
- All counters open filtered pages matching counts.
- Next Actions prioritizes pay/review/deliver over profile.

---------------------
2) DASHBOARD > BOOKINGS TAB
---------------------
Shows Booking list ONLY (service bookings).
Filters (chips): All, paid_request_pending, active, delivered, completed, cancelled, refunded, expired_unanswered
Card fields (MUST):
- Type badge: BOOKING
- Perspective: Requester/Provider
- Counterpart name (Client sees freelancer; Freelancer sees client) [Fix problem #4]
- Booking status + payment status
- Price
- Scheduled/deadline
- Primary CTA (role+status):
  Client:
  - unpaid -> Pay
  - paid_request_pending -> Waiting/Cancel policy
  - active -> View/Chat
  - delivered -> Review
  Freelancer:
  - paid_request_pending -> Accept/Decline
  - active -> Deliver
  - delivered -> Waiting approval
Secondary CTA: Chat only
Booking Details screen sections:
- Summary
- Requirements
- Timeline
- Deliverables
- Payment panel
- Actions (matrix)
- Dispute link (if allowed)

---------------------
3) DASHBOARD > WORK TAB (MUST FIX MESS)  [Fix problem #3 + #4]
---------------------
Work MUST be separated clearly into sections, different per role.

3A) Client Work Tab sections:
Section 1: "My Active Work" (execution items)
- Includes: Bookings(active/delivered) + Orders(active/delivered)
- Card MUST show:
  - Type: BOOKING/ORDER
  - "Assigned to: FreelancerName"
  - Status (active/delivered)
  - Price
  - Payment status (held/released)
  - Primary CTA: View / Review if delivered
  - Secondary: Chat
Section 2: "My Posted Tasks" (tenders I created)
- Shows: Tasks (draft/open/awarded/cancelled/expired)
- Card MUST show:
  - Type: TASK (POSTED)
  - Proposals count (new + total)
  - Status
  - Budget
  - Primary CTA:
    open -> Review proposals
    awarded -> Pay now (creates/opens Order pending_payment)
Section 3: "Offers Inbox" (proposal comparison)
- Grouped by task
- For each proposal: freelancer, price, time, rating, CTA Accept/Chat
- Must support sorting: best match, price, fastest
Section 4: History (completed/cancelled bookings/orders)

3B) Freelancer Work Tab sections:
Section 1: "My Deliverables" (execution items)
- Includes: Bookings(active/delivered) + Orders(active/delivered)
- Card MUST show:
  - Type: BOOKING/ORDER
  - "Booked by: ClientName" [Fix problem #4]
  - Status
  - Price
  - Deadline
  - Primary CTA: Deliver (if active), View (if delivered)
  - Secondary: Chat
Section 2: "My Proposals" (marketplace bids I submitted)
- Shows proposals with status: submitted/shortlisted/rejected/accepted
- Card: task title, my price, status, CTA View/Edit/Withdraw (if allowed)
Section 3: "My Services" (listings management)
- Shows services + packages + booking count per service
- CTA: Edit/Publish/Pause
Section 4: History

Acceptance criteria:
- Work tab is NOT a mixed list. It is clearly separated by: Active Work vs Posted Tasks vs Offers (client) / Deliverables vs Proposals vs Services (freelancer).
- Every card shows counterpart (who booked/assigned).
- Every card shows price + status + type badge.

---------------------
4) DASHBOARD > INBOX TAB (CHATS + NOTIFICATIONS ONLY)
---------------------
Inbox must not be used as Offers center.
Sections:
A) Chats
- threads linked to booking/order/task
- unread count, last message, badge type
B) Notifications (system/financial)
- critical (pay/review/deadline), normal, info
Acceptance criteria:
- Offers are removed from Inbox logic; offers live in Work tab sections.

=====================
G) BOTTOM NAV SCREENS
=====================

---------------------
5) SEARCH
---------------------
Client:
- Search services/freelancers/tasks
- Filters: category, rating, price, availability
- CTA: View profile, Book service, Invite to task (optional)
Freelancer:
- Search tasks (open only)
- Filters: category, budget, deadline
- CTA: Apply (create proposal), Save

---------------------
6) MY PROJECTS (My assets & history)
---------------------
Client:
- All posted tasks + proposals overview
- All orders/bookings history
- Saved freelancers/services
Freelancer:
- All proposals history
- All orders/bookings history
- Portfolio (if exists)

---------------------
7) PROFILE
---------------------
Common:
- Edit profile
- Role management (if dual)
- Wallet shortcut
- Settings, Support, Security
Freelancer extras:
- Portfolio
- Availability
- Services management shortcut

---------------------
8) WALLET (MUST FIX BALANCE)  [Fix problem #2]
---------------------
Wallet must have:
A) Balance header:
- Available balance
- Held balance
B) Transactions list:
- credit/debit/hold/release/refund
C) Deep links:
- tap transaction -> related booking/order details
Rules:
- Wallet is source-of-truth: balances computed from ledger or maintained by triggers/RPC.
- RLS must allow user to read ONLY their wallet and transactions.
Acceptance criteria:
- Wallet screen always shows the balance (no empty balance bug).
- Dashboard wallet snapshot matches wallet screen balance.

=====================
H) REQUIRED FIXES (CURRENT PROBLEMS) — TASK BREAKDOWN
=====================
Break into small tasks with acceptance criteria:

Task 1: Wallet snapshot on Overview
- Add fetchWalletSnapshot in DashboardViewModel init
- Render wallet card on Overview
- Acceptance: wallet visible + values non-null

Task 2: Wallet screen balance not showing
- Diagnose: missing wallet row vs RLS vs query
- Implement: create wallet on signup OR use RPC/view for balances
- Acceptance: wallet shows available+held for any user

Task 3: Work tab restructuring
- Implement sections per role exactly as above
- Create unified WorkCard schema (type, perspective, counterpart, status, price, payment, CTA)
- Acceptance: no mixed list; each item appears in correct section

Task 4: Show who booked/assigned everywhere
- Ensure every Booking/Order card displays counterpartName + role label
- Acceptance: user always sees who is on the other side

Task 5: Tender accepted -> Order pending_payment -> paid -> active
- Ensure after accepting proposal, create Order pending_payment
- Add Pay now action for client
- Acceptance: task acceptance never becomes active until payment

Task 6: Delivery & review for Orders and Bookings
- Provider can mark delivered
- Client can approve or request revision
- Acceptance: unified lifecycle works end-to-end

Task 7: Inbox separation
- Remove offers from Inbox logic
- Chats + Notifications only
- Acceptance: Inbox is clean and message-focused

=====================
I) OUTPUT FORMAT (WHAT YOU MUST DELIVER)
=====================
1) A complete screen list with role-based sections and CTAs (like above but finalized and consistent).
2) A navigation map (routes + entry points).
3) A state machine summary for Booking/Task/Order.
4) A task plan split into small tasks (1–4 hours each) with acceptance criteria.
5) A "Definition of Done" checklist for the dashboard and wallet.

Important: Do not propose UI redesign beyond the Liquid Glass style. Focus on clarity, role separation, correct business rules, and fixing the listed problems.