---

# **1) What this diagram is**

Shows how SLine’s **Wallet System (Escrow + Available balances)** works during the **Pay-First Booking Flow**:

- Client pays first
- Money is held in **Escrow (Held)**
- After delivery + approval, funds are **Released** to the freelancer’s **Available** balance (minus platform fee)
- If something fails (decline/cancel/expire/dispute outcome), money is **Refunded** to the client

Withdraw is explicitly **out of scope** (no implementation right now).

---

# **2) Why it exists**

Because marketplaces die from two things: **money ambiguity** and **non-atomic updates**.

This system exists to ensure:

- No “he said / she said” about who owns what money
- The app never does fragile client-side math
- All money state changes happen through **one atomic backend entry point**: process_payment_event
- Both parties always see the truth as: **Held vs Available**

---

# **3) Where it lives in the product**

**User-facing**

- Wallet screen shows:
    - **Available** (released)
    - **Escrow/Held** (money reserved for active work)
    - Transaction history

**Service/Logic layer**

- WalletService uses the DB view to compute balances (no client-side aggregation).
- Booking flow methods call the RPC for escrow/release/refund transitions.

**Database (Supabase/Postgres)**

- wallet_transactions table (with RLS)
- wallet_balances view aggregates **released vs held**
- process_payment_event RPC performs **atomic** Escrow/Release/Refund and updates booking state

---

# **4) Diagram (Mermaid)**

```mermaid
sequenceDiagram
    participant C as Client App
    participant B as Booking Service
    participant RPC as process_payment_event (RPC)
    participant DB as Postgres (wallet_transactions + booking)
    participant W as wallet_balances View
    participant F as Freelancer App
    participant P as Platform (Fee Accounting)

    %% 1) Client pays -> Escrow
    C->>B: Tap "Pay" on booking
    B->>RPC: event='escrow' (booking_id, gross_amount)
    RPC->>DB: Insert escrow txns (atomic)
    RPC->>DB: Update booking_status -> paid_request_pending
    DB-->>RPC: OK

    %% 2) Freelancer accepts -> Active
    F->>B: Accept booking
    B->>DB: booking_status -> active (guarded transition)

    %% 3) Freelancer delivers -> Delivered
    F->>B: Mark Delivered
    B->>DB: booking_status -> delivered

    %% 4) Client approves -> Release funds (minus fee)
    C->>B: Approve delivery
    B->>RPC: event='release' (booking_id)
    RPC->>DB: Compute fee + net
    RPC->>DB: Move from HELD -> RELEASED (net to freelancer)
    RPC->>DB: Record platform fee (revenue event)
    RPC->>DB: Update booking_status -> completed
    DB-->>RPC: OK

    %% 5) Wallet UI reads balances (both sides)
    F->>W: SELECT held, released WHERE user_id=fid
    W-->>F: Available + Escrow balances
    C->>W: (optional client ledger view)
    W-->>C: Payments + refunds history
```

---

# **5) Evidence Table**

> Evidence below is based on your
> 
> 
> **current plan state**
> 

| **Element** | **Code Evidence** | **DB Evidence** | **Verified** |
| --- | --- | --- | --- |
| Wallet foundation exists | Logged: WalletService, WalletViewModel, WalletScreen added | Logged: wallet_transactions created with RLS | PARTIAL |
| Balance aggregation via DB view | Logged: wallet_balances view aggregates released vs held | Logged: view exists | PARTIAL |
| Atomic money changes via RPC | Logged: process_payment_event handles Escrow/Release/Refund atomically | Logged: RPC exists | PARTIAL |
| Booking lifecycle supports pay-first | Logged: booking_status_enum includes pending → paid_request_pending → active → delivered → completed | Logged: enum updated + guard trigger enforces transitions | PARTIAL |
| Withdraw excluded | Not implemented by design | Not in current scope | YES (by requirement) |

---

# **6) Evidence checklist**

- ✅ Wallet System Foundation recorded as complete (table + RPC + UI + VM)
- ✅ Wallet balances aggregated in DB (wallet_balances view) recorded as complete
- ✅ Booking pay-first lifecycle recorded as complete and guarded
- ⚠️ Exact schema columns for wallet_transactions not extracted here
- ⚠️ Exact fee formula + storage location (config/table/constant) not confirmed here
- ❌ RLS SQL policies and RPC SQL body not captured here (needs DB query/export)

---

# **7) Open questions / Missing evidence**

To make this “100% production-hard” (without building withdraw), we still need to confirm:

- wallet_transactions schema:
    - Does it store direction, entity linkage, fee breakdown, counterparty?
- Fee source of truth:
    - fixed rate? per-category? per-user tier?
- The actual RPC internals:
    - idempotency?
    - double-spend protection?
    - booking ownership checks?
- RLS policies:
    - ensure users only read their own wallet rows
    - ensure only RPC can insert transitions (no client inserts)

---

# **8) Verification result**

- Verdict: **PARTIAL VERIFIED** (architecture + components exist, details not fully extracted)
- Date: **2026-03-06**
- Verified (by project log):
    - Wallet foundation (table + RPC + UI + VM)
    - DB view aggregation (Held vs Released)
    - Booking pay-first lifecycle integration
- Unverified (needs extraction):
    - exact SQL definitions (table/view/RPC)
    - fee calculation specifics
    - RLS policy text + edge-case protections

---