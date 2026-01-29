
A) Global UI Rules (Applies Everywhere)

A1) Notifications (UI + Behavior)
	•	Delete floating notification icon
	•	Merge notifications into the existing top bar icon (Home screen top bar)
	•	Top bar notification icon state:
	•	Red = there is at least 1 unread notification
	•	Gray = no unread notifications

A2) Skeleton Loader (Booking Screen)
	•	Fix booking screen skeleton loader:
	•	Must be identical to the real booking/task card layout
	•	Same padding, same lines, same structure (no “generic skeleton”)

⸻

B) Booking Model (No Slot, Pay First) — Core Logic

B1) Booking UX Decision
	•	The booking screen must NOT have slot selection.
	•	Client flow:
	•	Open booking → choose package → fill requirements → pay immediately
	•	No slot, no confirmation step before payment.

B2) Record Creation Timing
	•	Booking/Order record is created only AFTER payment is completed.

B3) Paid Request Intermediate State (Required)

Because the booking record is created after payment, add:
	•	PAID_REQUEST_PENDING_REVIEW
	•	This exists after payment, before booking creation.

B4) Freelancer Review Rules
	•	Freelancer can:
	•	Accept → booking record created → BOOKING_ACTIVE
	•	Decline (if request not logical / not aligned with package) → Refund flow
	•	Optional (if you want negotiation): Change Proposal (price/time/scope)

B5) Refund + Timeout Rules (Must be defined)
	•	If freelancer declines:
	•	Define: Full refund / partial refund / wallet credit
	•	Freelancer response deadline:
	•	Freelancer must respond within X hours
	•	If no response → Auto-refund (recommended for safety)

B6) Minimum Requirements Validation (Before Payment)
	•	Prevent empty/abusive paid requests:
	•	Required fields before payment (e.g., description, answers, attachments if needed)
	•	Otherwise block payment or mark request “Incomplete” and expire with refund

⸻

C) Orders & Bookings Management (Inside Card) — Both Roles

C1) Unified “Management Panel” inside Task/Booking Card

After entering a task booking card / order card, show management actions.

Freelancer must have full access to manage client orders & bookings:
	•	Chat with client
	•	Private notes (freelancer-only)
	•	Client update notes (visible to client, updated continuously)
	•	Cancel order/booking (policy-based)
	•	Request time extension
	•	Request price change
	•	(Optional) custom offer / upgrades
	•	Dispute + evidence

Client must have full access to manage his orders & bookings:
	•	Chat
	•	View freelancer updates
	•	Approve / request revision
	•	Accept/decline time extension
	•	Accept/decline price change
	•	Cancel request (policy-based)
	•	Dispute + evidence

Goal: more user-friendly and efficient for both sides.

⸻

D) Freelancer Dashboard (Final Structure)

D1) Overview (Clean UI)
	•	Show only compact summary cards (counts)
	•	Recent Activity list is hidden by default
	•	Button: “View Recent Activity” to expand/collapse

D2) Booking Section (Active Only)
	•	Delete “Manage” section and merge into Booking section (see D3)
	•	Booking section shows ONLY active bookings
	•	Completed bookings move to Work section

D3) Dashboard IA Change
	•	Delete “Manage”
	•	Merge Manage into Booking (all booking-related management entry points live under Booking/Work cards)

D4) Work Section (With Top Navigation Tabs)

Work section must have a top navigation bar to switch:
	•	Active
	•	Completed
	•	Cancelled

Work contains:
	•	Tender orders (active/completed/cancelled)
	•	Completed bookings (moved here)
	•	Cancelled bookings (if applicable)

⸻

E) Client Dashboard (Final Structure)

E1) Overview (Clean UI)
	•	Compact summary cards
	•	Recent Activity hidden by default + “View Recent Activity”

E2) Tasks (Client Tender Posting)

Client can:
	•	Create task
	•	Receive proposals
	•	Compare proposals
	•	Accept proposal → order pending payment
	•	Pay → order becomes active
	•	Track active/completed/cancelled

Suggested tabs:
	•	Open
	•	Awarded / Pending Payment
	•	Active
	•	Completed
	•	Cancelled / Expired

E3) Work (Client)

Top tabs:
	•	Active
	•	Completed
	•	Cancelled

Includes:
	•	Tender orders
	•	Active bookings (after freelancer accepts)

E4) Bookings (Client) — No Slot + Pay First

Tabs:
	•	Paid Requests (Pending Freelancer Review)
	•	Active Bookings
	•	Completed
	•	Cancelled / Refunded

⸻

F) Create Task Screen UI Fixes

F1) Fix overall UI in Create Task screen
	•	Fix layout consistency, spacing, sections, and validation UX (no broken alignment)

F2) Details Section — Remove Upload Image Button
	•	In Create Task screen Details section:
	•	No upload image button (for booking or task)
	•	Only keep images where they are truly part of the model (if needed elsewhere)

⸻

G) Booking Screen Navigation Fix
	•	Booking screen must not show slot UI
	•	Booking flow must go directly to payment screen after requirements/package selection

⸻

H) Spam Risk (Business Logic)

H1) Identified risk
	•	Trigger: conversations_before_insert_guard
	•	Removing Favorites requirement for DMs → any user can DM anyone → spam risk

H2) Plan action
	•	Monitor spam
	•	Future mitigation (if spam appears):
	•	Message Request system
	•	(Optional) rate limits + report/block

⸻

I) Freelancer Wallet (MVP, Simple)

I1) هدف المحفظة
	•	Simple but functional to connect flows and test everything.

I2) Wallet must show
	•	Total earnings (released)
	•	Pending earnings (in escrow / waiting approval)
	•	Number of projects worked on
	•	Per project breakdown:
	•	Project/order name
	•	Status (active/completed/cancelled)
	•	Amount
	•	Released vs pending

I3) Transactions (simple)
	•	Escrow hold created
	•	Payment released
	•	Refund
	•	(Optional) withdrawal mock

No complex payout integration الآن.

⸻


