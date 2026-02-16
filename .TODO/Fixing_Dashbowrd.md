## Freelancer Digram :-
---
config:
  look: neo
  theme: neo-dark
  layout: dagre
---
flowchart LR

F(("Freelancer"))
C(("Client"))

%% =========================
%% ENTRY POINTS (Freelancer)
%% =========================
subgraph ENTRY_F["Entry Points"]
direction TB

%% Tender entry
F1["Tender: Browse → Propose (task_requests)"] --> F2{"Awarded + Paid?"}
F2 -- "No (rejected / not paid yet)" --> F3["Stay in Inbox (Sent Proposal)"]
F2 -- "Yes" --> W_ACTIVE

%% Booking entry (Pay-first)
F4["Booking: Publish service"] --> F5["Client pays & requests"]
F5 --> W_REQ_PENDING["Request Pending (escrow held)\npaid_request_pending"]
W_REQ_PENDING --> F6{"Accept?"}
F6 -- "Decline / timeout" --> F_REFUND["Refund & Close"]
F6 -- "Accept" --> W_ACTIVE

end

%% =========================
%% UNIFIED WORK ENGINE (Post-activation Work)
%% =========================
subgraph WORK_ENGINE_F["Unified Work Engine (Post-Activation)"]
direction TB

W_ACTIVE["ACTIVE (requirements frozen)"] --> W_WORK["Work & chat"]

%% Change request
W_WORK --> W_CHANGE["Change request (extra scope)"]
W_CHANGE --> W_CHANGE_DEC{"Client accepts?"}
W_CHANGE_DEC -- "Yes (scope/time updated,\nextra escrow if needed)" --> W_WORK
W_CHANGE_DEC -- "No (keep original scope)" --> W_WORK

%% Extension request
W_WORK --> W_EXT["Request extension"]
W_EXT --> W_EXT_DEC{"Client accepts?"}
W_EXT_DEC -- "Yes (deadline updated)" --> W_WORK
W_EXT_DEC -- "No" --> W_DISPUTE

%% Delivery + review
W_WORK --> W_DEL["DELIVERED"] --> W_REVIEW["Review window (timer)"]
W_REVIEW --> W_DEC{"Decision"}
W_DEC -- "Approve OR Auto-approve" --> W_DONE["COMPLETED (payout released)"]
W_DEC -- "Revision (if remaining)" --> W_WORK
W_DEC -- "Dispute" --> W_DISPUTE

%% Cancel path (mutual only)
W_WORK --> W_CANCEL["Cancel request"]
W_CANCEL --> W_CANCEL_DEC{"Mutual?"}
W_CANCEL_DEC -- "Yes (apply refund policy)" --> W_CANCELLED["CANCELLED"]
W_CANCEL_DEC -- "No" --> W_DISPUTE

%% Dispute resolution
W_DISPUTE["DISPUTE (evidence required)"] --> W_ADMIN["Admin review"]
W_ADMIN --> W_ADMIN_DEC{"Decision"}
W_ADMIN_DEC -- "Pay freelancer" --> W_DONE
W_ADMIN_DEC -- "Refund client" --> W_CANCELLED
W_ADMIN_DEC -- "Split" --> W_SPLIT["SPLIT (partial payout/refund)"]

end

%% wiring
F --> ENTRY_F
C --> ENTRY_F

## **Freelancer Final v1 — Full Spec (Step-by-step, zero ambiguity)**

This document explains the **Freelancer** side of the **Final v1** flow in exact operational steps.

It is written so an AI can implement UI + logic **without guessing**.

---

# **0) Definitions (must be consistent everywhere)**

## **0.1 Work Item (Unified Object)**

A **Work Item** is a single operational unit shown to the freelancer once the relationship becomes real work.

A Work Item can be created from:

- **Tender Order** (client posted a task → freelancer proposed → client awarded → client paid)
- **Booking** (client purchased a service package → escrow held → freelancer accepts)

After activation, both must behave **identically** in the “Work Engine”.

**Freelancer UI rule:**

Freelancer should not need to care whether it came from Tender or Booking once it reaches ACTIVE.

It is always shown inside **Work tab** as an “Active Work Item”.

---

## **0.2 Statuses (conceptual, not implementation)**

We use only these user-facing states:

1. **Request Pending (Escrow Held)**
    
    Client paid, but freelancer has not accepted yet.
    
    Freelancer must decide: accept / decline.
    
    There is a timeout.
    
2. **Active (Requirements Frozen)**
    
    Work started. Requirements are frozen.
    
3. **Delivered (Waiting Client Review)**
    
    Freelancer delivered. Client has a review window.
    
4. **Completed (Payout Released)**
    
    Work finished. Escrow is released to freelancer.
    
5. **Cancelled (Refund Policy Applied)**
    
    Work ended without completion, and refund/payout handled by policy.
    
6. **Dispute (Admin Review)**
    
    Conflict escalated to admin. Admin decides payout/refund/split.
    

---

## **0.3 “Requirements Frozen” (critical)**

The moment a Work Item becomes **ACTIVE**, the current requirements are frozen as the baseline agreement.

Any change after that must go through a **Change Request** process.

No silent requirement changes are allowed.

---

# **1) Freelancer Entry Points (how the freelancer “enters” work)**

Freelancer has two entry routes, both end at the same engine:

## **1.1 Entry Route A — Tender: “Browse → Propose”**

### **Step A1 — Browse Tenders**

**Where it appears:**

A “Tenders” browsing screen (marketplace feed) visible to freelancer.

**Freelancer action:**

Scroll/search/filter → open a tender.

**Client involvement:**

Client has already posted the tender; no action yet.

---

### **Step A2 — Propose**

**Where it appears:**

Tender details screen includes a “Send Proposal” action.

**Freelancer action:**

Submit a proposal containing:

- price
- timeframe
- message/cover letter
    
    (Optional: ask questions in comments/chat before proposing, if your product allows.)
    

**What happens next:**

Freelancer waits. This is not work yet.

---

### **Step A3 — “Client awards?”**

**Freelancer sees:**

Proposal status changes:

- Rejected (end)
- Awarded but not paid (not active yet)
- Awarded + paid (becomes ACTIVE)

**Important rule (global-grade):**

A tender does NOT become real work until the client has paid and escrow is held.

**Client action required to proceed:**

Client must:

1. award the freelancer
2. pay to create escrow

If the client does not pay, freelancer does not start work.

---

### **Step A4 — “Yes + client pays” → ACTIVE**

Once the client pays, the tender transforms into an **ACTIVE Work Item** and enters the unified engine.

---

## **1.2 Entry Route B — Booking: “Publish service → client pays → freelancer accepts”**

### **Step B1 — Publish Service**

**Where it appears:**

A “My Services” management screen for freelancer.

**Freelancer action:**

Create/edit service + packages:

- price
- delivery time
- revision count (or revision policy)

**Client involvement:**

None until the service is live.

---

### **Step B2 — Client pays & requests**

Client chooses a package, submits requirements, and pays.

Payment is held in escrow immediately.

**Result:**

A Booking request is created as:

**Request Pending (Escrow Held)**

---

### **Step B3 — Request Pending (Escrow Held)**

**Where it appears (must be obvious):**

- On the Dashboard “Next Actions” (Freelancer mode) as top priority
- In a dedicated list: “Requests / Pending”
- Also can appear as a badge in “Bookings” tab

**What freelancer must do:**

Freelancer must choose:

- Accept
- Decline
    
    Or do nothing (timeout occurs automatically)
    

**Time rule:**

There is a hard expiration window (example: 24h).

If freelancer does not act, the booking auto-expires and client is refunded.

---

### **Step B4 — Accept → ACTIVE**

If freelancer accepts, it becomes an **ACTIVE Work Item** and enters the unified engine.

### **Step B5 — Decline/timeout → Refund & Close**

If declined or timed out:

- escrow is refunded to client
- request is closed
- it must not appear in Active work

---

# **2) Unified Work Engine (Freelancer Operational Flow)**

Once a Work Item is **ACTIVE**, the freelancer follows this engine.

## **2.1 ACTIVE (Requirements Frozen)**

**Where it appears:**

- Work tab → “Active”
- Dashboard counters: Active count increases
- Dashboard next actions may list it if urgent

**What freelancer must do immediately:**

1. Open the work item
2. Review requirements
3. Confirm understanding or request missing info (via chat)

**Client actions in this phase:**

- Answer questions
- Provide missing files/details

**Hard rule:**

No hidden change in scope. Anything new after freeze becomes a Change Request.

---

## **2.2 Work & Chat**

This is the main working period.

**Where it appears:**

Inside the Work Item:

- Chat thread
- Requirements section
- Deliverables section
- Timeline/status section

**Freelancer does:**

- execute the work
- communicate progress
- optionally send preview/partial updates (optional UX)

**Client does:**

- responds to questions
- stays updated

---

# **3) Change Request (Extra scope) — the only legal way to change requirements**

## **3.1 When it triggers**

Trigger condition:

- Client asks for additional features/extra work not included in frozen requirements
- Freelancer discovers missing scope that changes cost/time materially

This must become a **Change Request**.

## **3.2 UI behavior (freelancer side)**

**Where it appears:**

Inside the work item, a structured action:

- “Propose Change” / “Request Extra Scope”
    
    This is not a casual chat message; it’s a formal step.
    

**Freelancer must define:**

- what changes
- impact on delivery time
- impact on price (if any)

## **3.3 Client accepts?**

**If client accepts:**

- scope is updated
- timeline updated
- if extra payment is required → client pays → escrow for extra is held/added
- work continues normally

**If client declines:**

- scope stays as original frozen requirements
- work continues under original scope
    
    No dispute automatically unless one party refuses to continue.
    

---

# **4) Extension Request — formal handling of delays**

## **4.1 When it triggers**

Freelancer cannot meet original deadline due to:

- complexity
- external blockers
- client delays providing info
- change requests

## **4.2 UI behavior**

**Where it appears:**

Inside work item, structured action:

- “Request Extension”

Freelancer must specify:

- new expected delivery date/time
- reason

## **4.3 Client accepts?**

**Yes:**

Deadline updates → work continues.

**No:**

This becomes a conflict.

Freelancer can:

- continue and try to deliver anyway, or
- escalate to Dispute if it blocks completion fairly

In Final v1 engine, “No” routes to Dispute to avoid unclear outcomes.

---

# **5) Delivery**

## **5.1 DELIVERED**

Freelancer submits the final output.

**Where it appears:**

Inside the work item:

- “Deliver Work” action
- Delivered files/links area
- Delivered timestamp

**Freelancer must provide:**

- deliverable(s)
- short delivery note
- what was done + how to verify

**Client must see immediately:**

- notification
- item moved to “Needs Review” on client side

---

## **5.2 Client Review Window**

After delivery, the system enters a review window.

**Freelancer view:**

- status: “Delivered — Waiting client review”
- timer indicator (review deadline)

**Client obligations:**

- approve
- request revision (if remaining)
- open dispute (if serious issue)
- or do nothing (auto-approve occurs)

---

# **6) Client Decision (after delivery)**

## **6.1 Approve / Auto-approve → COMPLETED**

### **Approve**

Client approves within review window.

### **Auto-approve**

If client takes no action until review window ends:

- system auto-approves
- payout is released

**Freelancer view:**

- status becomes “Completed”
- wallet balance increases
- work item moves to Done/Completed list

---

## **6.2 Revision (if remaining)**

Client requests revision.

**Rule:**

Revisions are allowed only if:

- revision count remains (based on package/policy)
- request is within revision window (optional but recommended)

**Freelancer view:**

- status remains ACTIVE (or goes to “Revision Requested” inside ACTIVE)
- revision request is visible as a structured item + message

**Freelancer must do:**

- perform revision
- re-deliver using DELIVERED step again

If no revisions remaining:

- client must either approve, accept a paid change request, or dispute.

---

## **6.3 Dispute**

Client disputes the delivery.

Freelancer view:

- status becomes DISPUTE
- work becomes locked from normal completion actions
- evidence exchange begins

---

# **7) Cancellation (Mutual)**

## **7.1 Cancel request**

Can be initiated during ACTIVE (and optionally even after delivery).

In Final v1 we treat it as:

- A formal cancellation request

**Where it appears:**

Inside the work item: “Request Cancellation”.

## **7.2 Mutual?**

**If both agree:**

- status becomes CANCELLED
- refund policy applies (full/partial/none depending on rules)
- escrow handled accordingly

**If other party refuses:**

- it escalates to DISPUTE to avoid a deadlock.

---

# **8) Dispute → Admin Review → Decision**

## **8.1 DISPUTE**

**What freelancer must do:**

Submit evidence:

- deliverables
- messages
- timelines
- proofs of scope and work done
- change request history (if any)

**What client does:**

Submits their evidence similarly.

**UI requirement:**

Dispute screen must show:

- claim summary
- evidence upload area
- timeline of events

---

## **8.2 Admin review**

Admin assesses.

**Important rule:**

Admin decision must be final and auditable.

---

## **8.3 Admin decision outcomes**

### **A) Pay freelancer**

Escrow released to freelancer → status becomes COMPLETED.

### **B) Refund client**

Escrow refunded → status becomes CANCELLED.

### **C) Split**

Partial payout to freelancer + partial refund to client → status becomes SPLIT (resolved).

Freelancer UI must show:

- final outcome
- amounts (payout/refund)
- reason summary (short)

---

# **9) Where each state must appear inside the current app (Dashboard integration)**

Based on your Dashboard documentation (role switch + tabs), freelancer flow must surface like this:

## **9.1 Overview Tab (Freelancer mode)**

Must show:

- **Next Actions**:
    1. Request Pending (must be #1 priority)
    2. Delivered waiting review (high priority)
    3. Dispute requiring evidence (high priority)
- **Counters**: Active / Delivered / Completed / Disputes

## **9.2 Bookings Tab (Freelancer mode)**

Must show booking-related items:

- Request Pending
- Active bookings
- Past/completed/cancelled

## **9.3 Work Tab (Freelancer mode)**

This is the operational list.

Must show:

- Active Work Items (from both Tender and Booking)
- Done (Completed / Split resolved)
- Cancelled (Cancelled / Refunded)
    
    Optionally Dispute as its own filter or grouped under Active with strong badge.
    

## **9.4 Inbox Tab (Freelancer mode)**

Only for pre-work negotiation artifacts:

- Sent proposals (tender)
- messages not yet active work
    
    Once work becomes ACTIVE, it must appear in Work, not Inbox.
    

---

# **10) Non-negotiable global-grade rules (must be enforced)**

1. **No work without escrow held** (tender must be paid before active)
2. **Requirements freeze at ACTIVE**
3. **Change request is the only legal scope change**
4. **Extension request is the only legal deadline change**
5. **Auto-approve if client is silent after delivery**
6. **Revisions are limited**
7. **If cancel is not mutual → dispute**
8. **Dispute outcome must be Pay / Refund / Split**