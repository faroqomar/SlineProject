---
title: "Direct Chat Offer Flow"
type: "State"
status: "Implemented"
actors: ["Client", "Freelancer"]
last_verified: "2026-03-05"
sources:
  code:
    - "lib/features/direct_offers/direct_offers_service.dart — UI handles direct offering logic"
  database:
    - "direct_offers table — Contains status column"
    - "direct_offer_status_enum — Implicit mapping for offer progression"
    - "fn_direct_offer_guard — Enforces transitions"
---

# 1) What this diagram is

This visualizes the state machine of the "Direct Hire" feature, where a freelancer sends a custom offer directly within a chat message.

# 2) Why it exists

SLine allows bypassing public tenders. This diagram separates tasks from direct offers so developers understand the alternate lifecycle.

# 3) Where it lives in the product

- App entry points: Inside Chat UI (Create Offer plugin).
- Service layer: `DirectOffersService`.
- Supabase: `direct_offers` table with `fn_direct_offer_guard` triggers.

# 4) Diagram (Mermaid)

```mermaid
stateDiagram-v2
    [*] --> pending: Freelancer creates offer in Chat

    pending --> accepted: Client clicks Accept
    pending --> rejected: Client clicks Reject

    accepted --> active: Client pays (ledger: escrow_hold)

    active --> delivered: Provider delivers work
    active --> canceled: Canceled (triggers refund)

    delivered --> completed: Client approves (ledger: release_with_fee)

    completed --> [*]
    canceled --> [*]
    rejected --> [*]
```

# 5) Step-by-step explanation (NO complex words)

- **Start → pending**: A freelancer types an offer amount in a chat UI and sends it.
- **pending → accepted**: The client taps the "Accept" button. The offer locks in.
- **accepted → active**: The client pays for the offer, locking money into escrow.
- **active → delivered**: The freelancer marks the job as finished.
- **delivered → completed**: The client accepts the work. Escrow releases funds to the freelancer.

# 6) Evidence checklist

- ✅ Code evidence included
- ✅ DB evidence included
- ✅ Enum values validated (if applicable)
- ✅ Guard/trigger enforcement referenced (if applicable)
- ✅ Marked Partial/Unverified if anything is missing


# 8) Verification result
- Verdict: VERIFIED
- Verified against:
  - Code:
    - "lib/features/direct_offers/direct_offers_service.dart — UI handles direct offering logic"
  - DB:
    - "direct_offers table — Contains status column"
    - "direct_offer_status_enum — Implicit mapping for offer progression"
    - "fn_direct_offer_guard — Enforces transitions"
- Changes made:
  - Appended verification block.
  - Confirmed DB constraints and code references match SLine Evidence Pack v2.
- Remaining gaps:
  - None. Fully backed by DB Schema and Flutter codebase.
