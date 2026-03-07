# Risk Register: Chat Creation Matrix

## 1) Current System Risks (Status Quo)

| ID     | Risk Description                                                                                                                           | Severity | Likelihood | Impact                                | Evidence                                                           |
| :----- | :----------------------------------------------------------------------------------------------------------------------------------------- | :------- | :--------- | :------------------------------------ | :----------------------------------------------------------------- |
| **R1** | **Direct DM Spam**: Clients can mass-favorite freelancers to bypass spam limits.                                                           | Medium   | Low        | Platform noise, freelancer annoyance. | `SUPABASE_SETUP.md:83` rule is shallow if favorites are unlimited. |
| **R2** | **Race Condition on Insert**: Non-atomic check-then-insert leads to duplicate conversation errors.                                         | High     | Medium     | App crash/UI failure for users.       | `MessageService.dart:55-78` implementation.                        |
| **R3** | **Freelancer Bypass**: A freelancer could theoretically spoof a `task_id` in a direct `insert` to start a DM with a client they shouldn't. | High     | Low        | Security breach of DM privacy rules.  | `Archive/20260305071000...sql` guard allows any `task_id`.         |
| **R4** | **Orphaned Conversations**: Task-linked conversations remaining open after a task is "Canceled" or "Closed".                               | Low      | High       | CX confusion.                         | No trigger found that closes chats upon task status transition.    |

## 2) Improvement Implementation Risks

| ID     | Risk Description                                                                                                            | Severity | Likelihood | Mitigation                                              |
| :----- | :-------------------------------------------------------------------------------------------------------------------------- | :------- | :--------- | :------------------------------------------------------ |
| **M1** | **Migration Friction**: Changing the guard logic might block existing valid conversations if not carefully handled.         | High     | Low        | Use `ON CONFLICT DO NOTHING` and versioned RPCs (`v2`). |
| **M2** | **Performance Overhead**: Adding complex exists checks in a `BEFORE INSERT` trigger can slow down chat initiation at scale. | Low      | Low        | favorites table is indexed (`idx_favorites_client`).    |
| **M3** | **Client/Freelancer Role Confusion**: Users switching roles mid-flow might hit guard exceptions.                            | Medium   | Medium     | Re-verify `active_role` in the guard logic.             |
