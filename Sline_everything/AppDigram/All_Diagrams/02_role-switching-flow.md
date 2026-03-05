---
title: "Role Switching Flow"
type: "State"
status: "Implemented"
actors: ["Client", "Freelancer"]
last_verified: "2026-03-05"
sources:
  code:
    - "lib/features/profile/view/profile_view.dart — UI for Role Switching"
    - "lib/features/profile/data/profile_repository.dart — Updates active_role field"
    - "lib/core/app_enums.dart — Defines UserRole enum in code"
  database:
    - "profiles (active_role) — Field determining current persona"
    - "search_profiles() RPC — Filtering logic based on roles"
---

# 1) What this diagram is

This diagram explains how a single user account flips between working as a "Client" and earning money as a "Freelancer".

# 2) Why it exists

SLine allows a single account to act in two different personas. Managing the `active_role` safely ensures clients don’t mistakenly see freelancer UI components or get unauthorized access.

# 3) Where it lives in the product

- App entry points: Profile Settings Screen.
- Service layer: `ProfileRepository`.
- Supabase: `profiles.active_role` column and role-based searching RPCs.

# 4) Diagram (Mermaid)

```mermaid
stateDiagram-v2
    [*] --> Client: default_role 'client'
    state "profiles.active_role" as Role

    Client --> Freelancer: App action: Switch to Freelancer
    Freelancer --> Client: App action: Switch back to Client
```

# 5) Step-by-step explanation (NO complex words)

- **Start → Client**: New users start with their active role set to 'client'.
- **Client → Freelancer**: The user goes to their profile settings and toggles to Freelancer mode. The app updates `profiles.active_role`. This changes the UI and feeds.
- **Freelancer → Client**: The user switches back, returning their feed and permissions to client mode.

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
    - "lib/features/profile/view/profile_view.dart — UI for Role Switching"
    - "lib/features/profile/data/profile_repository.dart — Updates active_role field"
    - "lib/core/app_enums.dart — Defines UserRole enum in code"
  - DB:
    - "profiles (active_role) — Field determining current persona"
    - "search_profiles() RPC — Filtering logic based on roles"
- Changes made:
  - Appended verification block.
  - Confirmed DB constraints and code references match SLine Evidence Pack v2.
- Remaining gaps:
  - None. Fully backed by DB Schema and Flutter codebase.
