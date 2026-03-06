# 05_SINGLE_SOURCE_OF_TRUTH_GLOSSARY

This glossary is the **canonical reference** for naming, enums, and ownership across all 24 SLine system diagrams. Any term not listed here should be added before implementation.

---

## 1. Tables & Views

| Canonical Name              | Type        | Description                                                        | Used By Folders            |
| --------------------------- | ----------- | ------------------------------------------------------------------ | -------------------------- |
| `profiles`                  | Table       | User identity. Mirrors `auth.users`.                               | 01, 02, 07, 08, 15, 23     |
| `tasks`                     | Table       | Client-posted jobs. `task_type` = `tender` or `booking`.           | 03, 04, 10, 12, 14         |
| `task_requests`             | Table       | Freelancer bids on tender tasks.                                   | 04, 12                     |
| `bookings`                  | Table       | Reservation-based work contracts.                                  | 05, 10, 11, 12, 14, 22, 24 |
| `direct_offers`             | Table       | Chat-initiated work contracts (freelancer creates).                | 06, 12, 19                 |
| `conversations`             | Table       | Chat threads between two users.                                    | 07, 08, 18                 |
| `messages`                  | Table       | Individual chat messages.                                          | 08, 13, 17, 18             |
| `availability_slots`        | Table       | Freelancer time slots for bookings.                                | 05, 11                     |
| `disputes`                  | Table       | Escalated disagreements on work quality/payment.                   | 14, 16                     |
| `dispute_messages`          | Table       | Communication within a dispute.                                    | 14                         |
| `dispute_evidence`          | Table       | File attachments for a dispute.                                    | 14                         |
| `notifications`             | Table       | In-app notification records.                                       | 13, 18                     |
| `favorites`                 | Table       | Client-saved freelancers.                                          | 07                         |
| `work_contracts`            | Table       | Terms agreed upon (revisions, scope).                              | 05, 10                     |
| `accounts`                  | Table       | Named ledger accounts (e.g., `user_available`, `platform_escrow`). | 09, 21                     |
| `journal_entries`           | Table       | Ledger headers with idempotency key.                               | 09, 21, 24                 |
| `ledger_lines`              | Table       | DR/CR entries. Append-only.                                        | 09, 21, 24                 |
| `withdrawal_requests`       | Table       | Freelancer payout requests.                                        | 20                         |
| `payment_intents`           | Table (NEW) | Pre-registered payment sessions.                                   | 24                         |
| `payment_events`            | Table (NEW) | Raw webhook payloads. Append-only.                                 | 24                         |
| `orphan_payments`           | Table (NEW) | Quarantined unmatched payments.                                    | 24                         |
| `platform_settings`         | Table (NEW) | Global config (fee rate, etc.). **NOT** `system_config`.           | 22, 23                     |
| `admin_logs`                | Table       | Admin action audit trail.                                          | 20, 22, 23                 |
| ~~`wallet_transactions`~~   | ~~Table~~   | **FROZEN. DO NOT USE.** Replaced by `ledger_lines`.                | ~~21~~                     |
| `wallet_balances`           | View        | Computed from `ledger_lines`. Read-only.                           | 20, 21                     |
| `vw_unified_work_items`     | View        | My Work dashboard. 4 UNION branches. Must use `security_invoker`.  | 12                         |
| `vw_admin_finance_overview` | View (NEW)  | Platform-wide GMV, revenue, escrow. Admin only.                    | 23                         |
| `vw_admin_booking_finance`  | View (NEW)  | Per-booking money story. Admin only.                               | 23                         |

---

## 2. Enums & Status Values

### 2.1 `profiles.active_role`

| Value        | Description                        |
| ------------ | ---------------------------------- |
| `client`     | Can post tasks, book services, pay |
| `freelancer` | Can bid, deliver, receive payment  |

### 2.2 `tasks.status` (CHECK constraint, TEXT)

| Value         | Description                     | Terminal? |
| ------------- | ------------------------------- | --------- |
| `open`        | Published, accepting bids       | No        |
| `assigned`    | Bid accepted, awaiting payment  | No        |
| `in_progress` | Payment received, work underway | No        |
| `closed`      | Work completed and paid         | Yes       |
| `canceled`    | Withdrawn by owner              | Yes       |

### 2.3 `task_requests.status`

| Value             | Description                                  | Terminal? |
| ----------------- | -------------------------------------------- | --------- |
| `pending`         | Fresh bid from freelancer                    | No        |
| `replaced`        | Superseded by newer bid from same freelancer | Yes       |
| `expired`         | TTL exceeded (24h)                           | Yes       |
| `rejected`        | Declined by task owner                       | Yes       |
| `auto_rejected`   | Task accepted another bid                    | Yes       |
| `accepted_unpaid` | Bid accepted, awaiting escrow                | No        |
| `active_held`     | Escrow held, work started                    | No        |

### 2.4 `booking_status_enum`

| Value                  | Description                           | Terminal? |
| ---------------------- | ------------------------------------- | --------- |
| `pending`              | Client submitted request              | No        |
| `paid_request_pending` | Escrow held, awaiting provider accept | No        |
| `active`               | Provider accepted, work in progress   | No        |
| `delivered`            | Freelancer submitted deliverable      | No        |
| `completed`            | Client approved; funds released       | Yes       |
| `canceled`             | Pre-delivery cancellation             | Yes       |
| `refunded`             | Post-dispute client refund            | Yes       |
| `expired_unanswered`   | Provider didn't respond in time       | Yes       |
| `no_show` **(NEW)**    | Provider didn't attend scheduled slot | Yes       |
| `disputed` **(NEW)**   | Escalated to dispute resolution       | No        |

### 2.5 `direct_offers.status`

| Value       | Description                                     | Terminal? |
| ----------- | ----------------------------------------------- | --------- |
| `sent`      | **NOT** `pending`. Fresh offer from freelancer. | No        |
| `accepted`  | Client accepted (unpaid)                        | No        |
| `active`    | Escrow held. Work in progress.                  | No        |
| `delivered` | Freelancer submitted deliverable                | No        |
| `completed` | Client approved; funds released                 | Yes       |
| `canceled`  | Offer withdrawn/declined before payment         | Yes       |
| `rejected`  | Client declined                                 | Yes       |

### 2.6 `direct_offers.payment_status`

| Value      | Description                     |
| ---------- | ------------------------------- |
| `unpaid`   | Default state                   |
| `held`     | Escrow locked                   |
| `released` | Payment to freelancer completed |

### 2.7 `disputes.status` (NEW ENUM)

| Value                | Description                                 | Terminal? |
| -------------------- | ------------------------------------------- | --------- |
| `open`               | Filed by complainant                        | No        |
| `active`             | Under admin review                          | No        |
| `resolved`           | Admin decision rendered (refund or release) | Yes       |
| `canceled` **(NEW)** | Withdrawn by complainant                    | Yes       |

### 2.8 `withdrawal_requests.status`

| Value        | Description                                    | Terminal? |
| ------------ | ---------------------------------------------- | --------- |
| `requested`  | Freelancer initiated withdrawal                | No        |
| `processing` | Admin dispatching to bank                      | No        |
| `completed`  | Bank confirmed receipt                         | Yes       |
| `failed`     | Bank rejected transfer                         | Yes       |
| `canceled`   | Freelancer canceled (only before `processing`) | Yes       |

### 2.9 `payment_intents.status` (NEW TABLE)

| Value             | Description               | Terminal? |
| ----------------- | ------------------------- | --------- |
| `created`         | BFF generated intent      | No        |
| `gateway_created` | Gateway session opened    | No        |
| `succeeded`       | Webhook confirmed payment | Yes       |
| `failed`          | Payment failed or expired | Yes       |

### 2.10 Ledger Event Types

| Event                         | Description       | DR Account                | CR Account                                  |
| ----------------------------- | ----------------- | ------------------------- | ------------------------------------------- |
| `escrow_hold`                 | Client pays       | `client_available`        | `platform_escrow`                           |
| `release_with_fee`            | Work approved     | `platform_escrow`         | `freelancer_available` + `platform_revenue` |
| `refund`                      | Dispute/cancel    | `platform_escrow`         | `client_available`                          |
| `withdrawal_request`          | Payout initiation | `user_available`          | `user_pending_withdrawal`                   |
| `withdrawal_complete`         | Bank confirmed    | `user_pending_withdrawal` | `system_cash_out`                           |
| `withdrawal_failed`           | Bank rejected     | `user_pending_withdrawal` | `user_available`                            |
| `withdrawal_cancel` **(NEW)** | User cancels      | `user_pending_withdrawal` | `user_available`                            |

---

## 3. RPCs & Triggers

| Canonical Name                      | Type      | Auth              | Description                                    | Folders                    |
| ----------------------------------- | --------- | ----------------- | ---------------------------------------------- | -------------------------- |
| `process_payment_event_ledger`      | RPC       | SECURITY DEFINER  | Core financial engine. All money flows.        | 09, 16, 19, 20, 21, 22, 24 |
| ~~`process_payment_event`~~         | ~~RPC~~   | —                 | **DEPRECATED. DO NOT USE.**                    | —                          |
| `switch_active_role`                | RPC (NEW) | SECURITY DEFINER  | Atomic role swap with optimistic lock          | 02                         |
| `rpc_approve_delivery`              | RPC       | SECURITY DEFINER  | Release escrow. Must check disputes.           | 16                         |
| `rpc_request_revision`              | RPC       | SECURITY DEFINER  | Revision request. Must check status + cap.     | 10                         |
| `rpc_submit_delivery`               | RPC       | SECURITY DEFINER  | Freelancer submits work.                       | 10                         |
| `rpc_create_withdrawal_request`     | RPC (NEW) | SECURITY DEFINER  | Atomic withdrawal + ledger lock.               | 20                         |
| `accept_task_request`               | RPC       | SECURITY DEFINER  | Accept bid, auto-reject others.                | 04                         |
| `start_direct_conversation_v1`      | RPC (NEW) | SECURITY DEFINER  | Create DM with favorites check.                | 07                         |
| `start_task_conversation_v1`        | RPC (NEW) | SECURITY DEFINER  | Create task-linked conversation.               | 07                         |
| `fn_booking_guard`                  | Trigger   | —                 | Status transition validator for bookings.      | 05                         |
| `fn_direct_offer_guard`             | Trigger   | —                 | Status transition validator for direct offers. | 06, 19                     |
| `fn_reject_overlapping_slots`       | Trigger   | —                 | GiST overlap prevention on slots.              | 11                         |
| `trg_freeze_contract_fields`        | Trigger   | —                 | Prevents modifying locked contract terms.      | 10                         |
| `conversations_before_insert_guard` | Trigger   | —                 | Chat creation validation (favorites, role).    | 07                         |
| `private_upsert_notification`       | Function  | service_role only | System-only notification write path.           | 13                         |

---

## 4. Storage Buckets

| Bucket             | Visibility | Path Convention                           | TTL   | Access Rule                       |
| ------------------ | ---------- | ----------------------------------------- | ----- | --------------------------------- |
| `avatars`          | Private    | `avatars/{userId}/{timestamp}.jpg`        | 7200s | Owner + admin                     |
| `task-images`      | Private    | `tasks/{taskId}/{idx}.jpg`                | 3600s | Participants + admin              |
| `chat-attachments` | Private    | `convos/{conversationId}/{messageId}.ext` | 3600s | Conversation participants + admin |
| `portfolio`        | Private    | `portfolio/{userId}/{itemId}.ext`         | 3600s | Public read via signed URL        |

> **Rule**: DB stores **paths**, never signed URLs. Signed URLs are generated at render time with short TTLs.

---

## 5. Supabase Realtime Publication

| Table           | Published? | Notes                                                    |
| --------------- | ---------- | -------------------------------------------------------- |
| `messages`      | ✅ Yes     | Primary stream for chat + inbox                          |
| `notifications` | ✅ Yes     | Primary stream for alerts                                |
| `conversations` | ❌ **No**  | NOT published. Do not subscribe. Use `messages` instead. |

---

## 6. Deprecated / Frozen References

| Term                          | Status                                           | Replacement                        |
| ----------------------------- | ------------------------------------------------ | ---------------------------------- |
| `wallet_transactions`         | **FROZEN** — Table exists but writes are blocked | `ledger_lines` + `journal_entries` |
| `process_payment_event`       | **DEPRECATED** — Old version of ledger RPC       | `process_payment_event_ledger`     |
| `system_config`               | **NAMING DRIFT** — Some docs use this            | Use `platform_settings`            |
| `public.users` view           | **DROP IMMEDIATELY** — PII leak                  | Query `profiles` directly          |
| `rpc_approve_delivery` (lite) | **INCOMPLETE** — Missing dispute check           | Patch to include dispute guard     |
