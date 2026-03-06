# FULL REPORT: 07 Chat Creation Matrix

## 0) Skill Selection

- **Skills selected**: Evidence-First Reading, Threat Modeling (Security), Invariants & Contracts, Diagram Crafting, RLS & Privilege Boundaries.
- **Why these fit**: Chat creation determines who can talk to whom. Threat modeling identifies spam vectors. Invariants establish the strict rules (e.g., Freelancers cannot initiate DMs). RLS boundaries ensure users only see their own chats.
- **Skills not used**: DB-First Financial Modeling.

## 1) Folder Identity

- **Folder name + path**: `.TODO/improvement_the_system/ImplementReady/07_chat-creation-matrix`
- **What system/feature it describes**: The decision tree and logic for initiating a 1-on-1 conversation (Direct DM vs Task-Linked DM).
- **Entities involved**: `conversations` (table), `MessageService`, `conversations_before_insert_guard` (DB Trigger).

## 2) Human Explanation

When a user tries to start a chat, the system evaluates their role and context. If it's a Task-Linked DM, the system verifies the user is either the task owner or an active bidder. Task owners cannot arbitrarily start chats unless replying to a bid. If it's a Direct DM, Freelancers are strictly forbidden from initiating. Clients can initiate Direct DMs ONLY if the Freelancer is in their `favorites` list. If all checks pass, an atomic RPC `start_direct_conversation_v1` ensures no duplicate conversation is created before returning the chat ID.

## 3) Symbol Legend

- **Diamonds**: Logic Gates (Auth UID check, Type check, Role check).
- **Rectangles**: End States (Allow vs Deny).
- **Solid Arrows**: Evaluated path.

## 4) Extracted Contracts & Invariants

1. **Identity Integrity**: `initiated_by` MUST equal `auth.uid()`.
2. **Task Ownership Boundary**: Task owners cannot start a task-linked conversation unless rejecting a bid.
3. **DM Privilege**: Clients can only DM favorited freelancers.
4. **Role Symmetry**: Freelancers are strictly forbidden from initiating unprompted direct DMs with clients.

## 5) Conflict Scan Results

### 5.1 Naming Drift

- **Conflict**: Diagram referenced generic "startConversation".
- **Resolution**: Split into explicit RPCs `start_task_conversation_v1` and `start_direct_conversation_v1`.

### 5.2 Logic Drift

- **Conflict**: Client app assumed it could run `INSERT INTO conversations`.
- **Resolution**: All clients MUST use the atomic RPCs to prevent race conditions (duplicate chats).

### 5.3 Data Model Drift

- None detected. `conversations_before_insert_guard` aligns with schema.

## 6) Security & Failure Modes (Adversarial)

- **Spam Attack**: Client favorites 1000 users and DMs them.
  - _Mitigation_: Trigger-level rate limits on new conversation creation per day.
- **Context Spoofing**: User attaches a random `task_id` to bypass the Favorites rule.
  - _Mitigation_: The DB guard explicitly cross-checks the user's participation in the provided `task_id`.

## 7) UI Mapping

### 7.1 Mobile App UI

- **Screens**: Freelancer Profile (Message Button), Task Bids (Contact Button).
- **States**: Button disabled/enabled based on Favorites status.
- **Guardrails**: Hide the DM button for Freelancers viewing Client profiles.

### 7.2 Admin Dashboard UI

- **Pages**: Moderation / Spam Control.
- **Metrics**: Number of conversations initiated per user per day.
- **Drilldowns**: Flag users triggering >10 `start_direct_conversation` denials in an hour.

### 7.3 Implementation Hooks

- `MessageService.startConversation(userId)` -> `rpc('start_direct_conversation_v1')`.

## 8) Diagram Verdict + Best Diagram Type

- **Score now**: 10/10
- **Best Diagram Type**: Flowchart (Decision Tree) perfectly maps the logic gates.

## 9) Upgrade Plan

- **Phase 0: Observability**: Log all DENY events from the RPCs to track malicious actors.
- **Phase 1: Contracts**: Enforce the `favorites` lookups inside the SQL Guard for Direct DMs.
- **Phase 2: Hardening**: Deprecate client-side `INSERT` in favor of Idempotent RPCs.
- **Phase 3: Scale**: Add partial indexes on active conversations.

## 10) Risks

### 10.1 Risks if current version kept

- **Race Conditions**: Creating parallel duplicate conversations between two users.

### 10.2 Risks introduced by fixes

- **Complexity**: Moving logic to RPC means Flutter devs must handle Postgres error codes cleanly.

## 11) Test Plan (High-value)

- **Security**: Attempt DM as freelancer -> verify blocked by DB.
- **Security**: Attempt DM to non-favorite -> verify blocked by DB.
- **Concurrency**: Fire two `start_direct_conversation_v1` calls simultaneously -> verify exactly 1 chat returned.

## 12) Production Checklist

- [ ] `start_direct_conversation_v1` implemented and active.
- [ ] DB Guard rejects non-favorite DMs.
- [ ] Flutter UI gracefully explains "Must favorite to message".
