# Holistic Audit Report: Chat Creation Matrix

## 1. Skill Selection Protocol

- **Skills applied**:
  1. **Evidence-First Reading**: Every claim is tied to `MessageService.dart` or `SUPABASE_SETUP.md`.
  2. **Threat Modeling (Security)**: Analyzed spam vectors and role-bypass scenarios.
  3. **Invariants & Contracts**: Defined the hard boundaries between Task and Direct DMs.
  4. **Diagram Crafting (Mermaid)**: Produced a production-ready system flowchart.
  5. **RLS & Privilege Boundaries**: Audited the `favorites` vs `participant` access model.
- **Why these skills fit**: This audit focuses on secure access control and system integrity in a multi-user marketplace.
- **Skills intentionally not used**: DB-First Financial Modeling (creation of chat is a pre-financial event).

---

## A) What This Diagram Is

The **Chat Creation Matrix** describes the logic for initiating a one-to-one conversation between SLine users. It defines the "Decision Tree" used by both the Flutter app (Services) and the Supabase DB (Triggers/RLS) to permit OR deny a new chat row.

## B) Why It Exists

- **Spam Control**: Prevents freelancers from mass-DMing clients to pitch services.
- **Context Integrity**: Ensures chats related to a specific task are properly linked to that task object.
- **Security**: Prevents unauthorized users from creating "phantom" conversations on behalf of others.

## C) Where It Lives in the Product

- **App Entry Points**:
  - `Message` button on User Profile (Direct DM path).
  - `Contact` / `Reply` button on Task Bids (Task Context path).
- **Service Layer**: `lib/features/chat/services/message_service.dart`.
- **Database Layer**: `public.conversations` table, guarded by `conversations_before_insert_guard()` function and RLS policies.

## D) Current Diagram Evaluation (Score)

- **What’s good**: Clearly distinguishes between Task and Direct contexts. Correctly identifies "Favorites" as a requirement for Clients.
- **What’s missing**: The "Reject Offer" exception, atomicity details (RPC vs Insert), and the "Freelancer Forbidden" rule for Direct DMs.
- **What’s unsafe**: Implicitly suggests a client can start a DM without atomicity, which leads to race conditions.
- **Score NOW: 6/10**
  - _Why_: Good functional overview, but lacks the technical hardening (guards, exceptions, atomicity) required for a production-grade system.

---

## E) Extracted Invariants & Contracts

1. **Identity Integrity**: `initiated_by` MUST equal `auth.uid()`. (Evidence: `Archive/20260305071000...sql:21`).
2. **Task Ownership Boundary**: Task owners cannot start a task-linked conversation (Evidence: `SUPABASE_SETUP.md:84`), unless performing a bid rejection (Evidence: `Archive/20260305071000...sql:29`).
3. **DM Privilege**: Clients can only DM favorited freelancers. (Evidence: `SUPABASE_SETUP.md:83`).
4. **Role Symmetry**: Freelancers are strictly forbidden from initiating unprompted direct DMs with clients. (Evidence: `SUPABASE_SETUP.md:59`).

## F) Failure Modes & Attack Scenarios

| Scenario             | Current State                               | Improved State                                                       | Fix Location          |
| :------------------- | :------------------------------------------ | :------------------------------------------------------------------- | :-------------------- |
| **Spam Attack**      | Client favorites 1000 users and DMs them.   | Implement platform-wide "new conversation" rate limits.              | Database Trigger      |
| **Race Condition**   | Duplicate conversation creation error.      | Move logic to atomic `start_direct_conversation_v1` RPC.             | `MessageService.dart` |
| **Role Bypass**      | Freelancer spoofs Role as Client.           | Backend guard must verify `profiles.active_role = 'client'`.         | SQL Guard             |
| **Context Spoofing** | User attaches random `task_id` to start DM. | Guard must verify user is a participant or bidder on that `task_id`. | SQL Guard             |

---

## G) Production-Grade Improvement Plan

### Phase 0: Observability & Logs

- **Action**: Add `admin_logs` entry for every successful `conversation` creation to track platform growth/spam.
- **Why**: Allows moderators to identify bad actors.

### Phase 1: Core Contracts Enforcement

- **Action**: Update `conversations_before_insert_guard` to explicitly verify `favorites` for `task_id IS NULL` rows.
- **How**: `IF NEW.task_id IS NULL THEN PERFOM check_favorites(...); END IF;`

### Phase 2: Hardening (Security & Idempotency)

- **Action**: Deprecate direct `insert` in `MessageService` for DMs.
- **Switch to**: `start_direct_conversation_v1` RPC which returns existing convo if it exists (Idempotent).

### Phase 3: Performance & Scale

- **Action**: Add partial index `idx_conversations_active` where `deleted_at` is null.
- **Action**: Ensure `favorites` check is lightning fast using the `uq_favorites_client_freelancer` index.

---

## H) Best Diagram Recommendation

A **Sequence Diagram** is superior for developers to understand the RPC/Trigger handshake, but a **State/Flowchart** (the current type) is best for auditing the decision logic. We recommend maintaining both.

---

## I) Final Improved Diagram (Mermaid)

```mermaid
flowchart TD
    START[User attempts startConversation] --> AUTH{Auth.uid() correct?}
    AUTH -->|No| DENY_AUTH[DENY: Unauthenticated or Identity Theft]
    AUTH -->|Yes| CTX{Context Type?}

    %% Path A: Task-Linked
    CTX -->|Task Context| T1{User Role?}
    T1 -->|Freelancer| T2{Has active bid or booking?}
    T1 -->|Owner| T3{app.allow_owner_task_conversation?}

    T2 -->|Yes| ALLOW_T[ALLOW via start_task_conversation_v1]
    T2 -->|No| DENY_T1[DENY: Task access restricted]

    T3 -->|true| ALLOW_REJECT[ALLOW: Reject Flow Exception]
    T3 -->|false| DENY_T2[DENY: Owner cannot initiate chat]

    %% Path B: Direct DM
    CTX -->|Direct DM| R1{Active Role?}
    R1 -->|Freelancer| DENY_F[DENY: Freelancers cannot initiate DMs]
    R1 -->|Client| R2{Freelancer in Favorites?}

    R2 -->|Yes| ALLOW_D[ALLOW via start_direct_conversation_v1]
    R2 -->|No| DENY_D[DENY: Favorites rule not satisfied]

    %% Post-Insert
    ALLOW_T --> NORM[Normalize user1_id < user2_id]
    ALLOW_REJECT --> NORM
    ALLOW_D --> NORM
    NORM --> DONE[Conversation Established]

    style ALLOW_T fill:#9f9,stroke:#333,stroke-width:2px
    style ALLOW_REJECT fill:#9f9,stroke:#333,stroke-width:2px
    style ALLOW_D fill:#9f9,stroke:#333,stroke-width:2px
```

---

## J) Risk Register

### J1) Risks if we keep the current system

- **Severity: High** | **Likelihood: Medium** | Duplicate conversation errors caused by race conditions in `MessageService.dart`.
- **Severity: Medium** | **Likelihood: Low** | Spam bypass via un-guarded direct `insert` if RLS policies have gaps.

### J2) Risks introduced by improvements

- **Complexity**: Moving logic to RPCs increases backend dependency. _Mitigation_: Comprehensive integration tests.

---

## K) Verification Checklist (Production Readiness)

- [ ] **T1**: Verify `start_direct_conversation_v1` atomicity under load.
- [ ] **T2**: Confirm `reject_task_request` flow still creates chats.
- [ ] **T3**: Attempt DM as freelancer → verify blocked.
- [ ] **T4**: Attempt DM to non-favorite → verify blocked.
- [ ] **RLS**: Run `conversations` policy check script.

---

## L) Final Verdict

- **Score AFTER fixes: 10/10**
- **Blockers to production**: None, provided the RPC migration is completed.
- **Ship Criteria**:
  1. RPC established.
  2. SQL guard hardened with Favorites check.
  3. UI handled "Blocked" state gracefully.

**Auditor Signature**: SLine System Improvement Auditor (Antigravity)
