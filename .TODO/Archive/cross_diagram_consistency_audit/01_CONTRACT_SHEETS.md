# 01_CONTRACT_SHEETS: Per-Folder Extracted Contracts

---

## 01: Auth & Profile Provisioning

- **A) Entities**: `auth.users`, `public.profiles`
- **B) States/Enums**: `account_status`: `active`, `banned`, `suspended`
- **C) RPCs/Triggers**: `AFTER INSERT` trigger on `auth.users` → auto-create `profiles`; `AccountGuardService.evaluateCurrentUser()`
- **D) Invariants**: 1:1 identity contract (every auth user → one profile). Guard on all entry paths (login + session restore).
- **E) Ownership**: Users own their own profile row (`id = auth.uid()`).
- **F) Time Mechanics**: Retry loop (3×, 500ms backoff) for profile fetch post-signup. Orphan sweep cron (>15 min without profile → delete auth user).
- **G) Money Events**: None.
- **H) Diagram**: Sequence Diagram. Claims both race-condition handling and session restore are covered.

---

## 02: Role Switching Flow

- **A) Entities**: `profiles` (`active_role` column), `search_profiles`, JWT `app_metadata`
- **B) States/Enums**: `active_role`: `client`, `freelancer`
- **C) RPCs/Triggers**: `switch_active_role` RPC (proposed, uses `expected_old_role` for atomicity); Supabase Auth Hooks for JWT claims
- **D) Invariants**: JWT claim `app_metadata.active_role` is source of truth for RLS. Atomic RPC prevents race. Session refresh required post-switch.
- **E) Ownership**: Only the profile owner can switch roles. RLS on `tasks` (INSERT requires `client`), `task_requests` (INSERT requires `freelancer`), `availability_slots` (requires `freelancer`).
- **F) Time Mechanics**: None explicit.
- **G) Money Events**: None.
- **H) Diagram**: Sequence Diagram.

---

## 03: Tender Task Lifecycle

- **A) Entities**: `tasks` (type=tender), `task_requests`, `categories`
- **B) States/Enums**: `tasks.status`: `open`, `assigned`, `in_progress`, `closed`, `canceled`. DB uses `CHECK` constraint (TEXT), NOT an ENUM type.
- **C) RPCs/Triggers**: `accept_task_request`, `process_payment_event_ledger` (gateway_escrow). Proposed: unpaid timeout cron.
- **D) Invariants**: `assigned` → `in_progress` ONLY via escrow payment success. Cancellation post-escrow requires dispute pipeline. Optimal concurrency on accept (expected price guard).
- **E) Ownership**: Task owner (`owner_id = auth.uid()`) controls acceptance/rejection.
- **F) Time Mechanics**: Proposed 24h auto-revert for unpaid `assigned` tasks.
- **G) Money Events**: `gateway_escrow` → `release_with_fee` → (or `refund` on dispute).
- **H) Diagram**: State Diagram (`stateDiagram-v2`).

---

## 04: Task Request (Bid) Flow

- **A) Entities**: `task_requests`, `tasks`, `conversations`
- **B) States/Enums**: `task_requests.status`: `pending`, `replaced`, `expired`, `rejected`, `auto_rejected`, `accepted_unpaid`, `active_held`. **Task sync**: `open` → `assigned` → `in_progress`.
- **C) RPCs/Triggers**: `accept_task_request`, `reject_task_request`, `process_expired_requests` (cron). `qicard_payment_recovery_tender` edge function.
- **D) Invariants**: One active bid per freelancer (`uq_task_requests_one_active_per_freelancer`). Owner-only accept/reject (`SUPABASE_SETUP.md:1469`). Conversation guard bypass on rejection.
- **E) Ownership**: `task.owner_id` controls bid lifecycle.
- **F) Time Mechanics**: 24h TTL on bids (`process_expired_requests` cron).
- **G) Money Events**: QiCard payment → `gateway_escrow` → task becomes `in_progress`.
- **H) Diagram**: Parallel State Diagram.

---

## 05: Booking Lifecycle

- **A) Entities**: `bookings`, `availability_slots`, `work_contracts`
- **B) States/Enums**: `booking_status_enum`: `pending`, `paid_request_pending`, `active`, `delivered`, `completed`, `canceled`, `refunded`, `expired_unanswered`. **MISSING from DB**: `no_show`, `disputed`.
- **C) RPCs/Triggers**: `fn_booking_guard`, `fn_reject_overlapping_slots`, `process_payment_event_ledger`, `fn_check_expired_reviews` (cron).
- **D) Invariants**: Escrow lock before `active`. Slot exclusivity. Immutable delivery (no client cancel after `delivered` — must dispute). Terminal states emit ledger events.
- **E) Ownership**: `client_id` / `provider_id` roles.
- **F) Time Mechanics**: `review_expires_at` for auto-approve cron. `expired_unanswered` for provider timeout.
- **G) Money Events**: `escrow_hold` on payment, `release_with_fee` on completion, `refund` on cancellation/dispute.
- **H) Diagram**: State Diagram.

---

## 06: Direct Chat Offer Flow

- **A) Entities**: `direct_offers`, `conversations`, `messages`
- **B) States/Enums**: `direct_offers.status`: `sent`, `accepted`, `active`, `delivered`, `completed`, `canceled`, `rejected`. `payment_status`: `unpaid`, `held`, `released`. NOTE: DB uses `sent` NOT `pending`.
- **C) RPCs/Triggers**: `fn_direct_offer_guard`, `process_payment_event_ledger`, `markDelivered`, `payNow`
- **D) Invariants**: Freelancer creates. `active` requires `payment_status=held`. `completed` requires `payment_status=released`. Only freelancer marks delivered.
- **E) Ownership**: `freelancer_id` creates; `client_id` accepts/pays/approves.
- **F) Time Mechanics**: **MISSING**: `review_expires_at`, `delivered_at` columns. No auto-approve cron for direct offers.
- **G) Money Events**: `escrow_hold`, `release_with_fee`. **GAP**: No `refund` path for active offers.
- **H) Diagram**: Composite State Diagram.

---

## 07: Chat Creation Matrix

- **A) Entities**: `conversations`, `favorites`, `task_requests`, `profiles`
- **B) States/Enums**: Context types: Task-Linked vs Direct DM. Roles: Client, Freelancer.
- **C) RPCs/Triggers**: `conversations_before_insert_guard()`, `start_direct_conversation_v1` (proposed RPC), `start_task_conversation_v1`
- **D) Invariants**: `initiated_by = auth.uid()`. Task owners cannot start task-linked convos (except rejection bypass). Clients can only DM favorited freelancers. Freelancers CANNOT initiate DMs.
- **E) Ownership**: Both participants. Normalized: `user1_id < user2_id`.
- **F) Time Mechanics**: None.
- **G) Money Events**: None (pre-financial).
- **H) Diagram**: Flowchart.

---

## 08: Chat Realtime Sync

- **A) Entities**: `messages`, `conversation_presence`, `conversations`
- **B) States/Enums**: Message status: `SENT`, `DELIVERED`, `READ` (via `delivered_at`, `seen_at`). Presence: `isTyping: true/false`.
- **C) RPCs/Triggers**: `validate_sender_participation` trigger, `expire_typing_presence` trigger (15s TTL), `mark_delivered` RPC, `mark_seen` RPC
- **D) Invariants**: Normalization (`user1_id < user2_id`). Isolation (participant-only access). Presence TTL (15s).
- **E) Ownership**: `sender_id` / receiver. Both are conversation participants.
- **F) Time Mechanics**: 15s typing TTL. Deduplication via `ChatRealtimeMerger`.
- **G) Money Events**: None.
- **H) Diagram**: Sequence Diagram.

---

## 09: Ledger Event Flow

- **A) Entities**: `accounts`, `journal_entries`, `ledger_lines`
- **B) States/Enums**: Event types: `escrow_hold`, `release_with_fee`, `refund`, `withdrawal_request`, `withdrawal_complete`, `withdrawal_failed`, `withdrawal_cancel`
- **C) RPCs/Triggers**: `process_payment_event_ledger` (SECURITY DEFINER)
- **D) Invariants**: [INV-01] Double-entry: DR + CR = 0. [INV-02] All amounts > 0 (`ck_ledger_lines_amount_positive`). [INV-03] Replay protection via `idempotency_key`.
- **E) Ownership**: `ledger_lines` is system-only (`service_role`). `authenticated` cannot INSERT/UPDATE.
- **F) Time Mechanics**: None intrinsic.
- **G) Money Events**: ALL financial flows route through this engine.
- **H) Diagram**: Flowchart + Sequence.

---

## 10: Work Contract Revisions

- **A) Entities**: `tasks`, `bookings`, `work_contracts`
- **B) States/Enums**: `revisions_used`, `revisions_total`. Status rollback: `delivered` → `active`.
- **C) RPCs/Triggers**: `rpc_request_revision` (tasks), `rpc_request_revision` (bookings), `rpc_submit_delivery`, `trg_freeze_contract_fields`
- **D) Invariants**: Client-only revision request. Increment counter. State rollback clears `delivery_at`. **CRITICAL GAP**: No `revisions_total` cap check. No `status='delivered'` pre-check.
- **E) Ownership**: `client_id` requests revisions; `freelancer_id` submits deliveries.
- **F) Time Mechanics**: None.
- **G) Money Events**: None directly (escrow stays held during revision loops).
- **H) Diagram**: Sequence Diagram.

---

## 11: Availability Overlap Guard

- **A) Entities**: `availability_slots`, `bookings`
- **B) States/Enums**: `is_blocked`: `true/false`. GiST index on `tstzrange(starts_at, ends_at)`.
- **C) RPCs/Triggers**: `trg_no_overlap_slots` → `fn_reject_overlapping_slots()`. RLS: `slots_write_owner`.
- **D) Invariants**: No overlapping slots for same provider. Owner-only creation. `starts_at < ends_at`.
- **E) Ownership**: `provider_id = auth.uid()`.
- **F) Time Mechanics**: Slot times use `tstzrange` with `[)` bounds.
- **G) Money Events**: None (pre-financial).
- **H) Diagram**: Sequence Diagram. **NOTE: Zero Flutter implementation.**

---

## 12: Unified Work View

- **A) Entities**: `vw_unified_work_items` (Postgres VIEW), `tasks`, `bookings`, `direct_offers`, `task_requests`, `disputes`
- **B) States/Enums**: `UnifiedWorkStatus`: maps `in_progress`(task) and `active`(booking) → `active`(unified). Proposal adds `disputed` override.
- **C) RPCs/Triggers**: None. View is a UNION ALL.
- **D) Invariants**: Role isolation (client_id OR freelancer_id). Award uses `task_request.price`, not task budget. **GAP**: `direct_offers` branch missing. `security_invoker` missing.
- **E) Ownership**: User sees only items where they are `client_id` or `freelancer_id`.
- **F) Time Mechanics**: None.
- **G) Money Events**: None (read-only aggregation).
- **H) Diagram**: Functional Decomposition / Flow.

---

## 13: Notification Routing

- **A) Entities**: `notifications`, `messages`
- **B) States/Enums**: `is_read` flag. Notification types: message, bid, booking, dispute, offer.
- **C) RPCs/Triggers**: `private_upsert_notification` (system-only write path), `trg_messages_after_insert_notify_receiver`. Proposed: `trg_notifications_after_insert` → FCM webhook.
- **D) Invariants**: `private_upsert_notification` is the ONLY write path. Idempotency via key. Users can only read/update own notifications.
- **E) Ownership**: `user_id = auth.uid()` for SELECT/UPDATE.
- **F) Time Mechanics**: Realtime via WebSocket. **GAP**: No FCM/APNs push fallback.
- **G) Money Events**: None.
- **H) Diagram**: Flowchart (Data Flow).

---

## 14: Dispute Lifecycle

- **A) Entities**: `disputes`, `dispute_messages`, `dispute_evidence`
- **B) States/Enums**: Status: `open`, `active`, `resolved`. **PROPOSED**: add `canceled`. **GAP**: No `dispute_status_enum` in DB (plain text).
- **C) RPCs/Triggers**: `submitDispute()`, `process_payment_event_ledger` for resolution. **PROPOSED**: `trg_dispute_guard`, task-lock trigger.
- **D) Invariants**: `complainant_id = auth.uid()`. `task_id` must exist. `resolved_at` set on resolution.
- **E) Ownership**: Complainant creates. Admin resolves.
- **F) Time Mechanics**: None specified.
- **G) Money Events**: Resolution triggers `refund` or `release_with_fee` via ledger.
- **H) Diagram**: State Diagram.

---

## 15: RLS Authorization Map

- **A) Entities**: All core tables (`profiles`, `tasks`, `bookings`, `messages`, `ledger_lines`, etc.)
- **B) States/Enums**: Roles: `public`, `authenticated`, `service_role`, `admin`.
- **C) RPCs/Triggers**: RLS policies (USING/WITH CHECK). SECURITY DEFINER functions. `pg_policies`.
- **D) Invariants**: Profile isolation (`id = uid`). Task ownership (`owner_id = uid`). Ledger system-only. Messenger privacy.
- **E) Ownership**: Per-table RLS predicates.
- **F) Time Mechanics**: None.
- **G) Money Events**: None (authorization layer).
- **H) Diagram**: Hierarchical Authorization Flow. **CRITICAL**: `public.users` view exposes PII.

---

## 16: Escrow Invariants & Idempotency

- **A) Entities**: `journal_entries`, `ledger_lines`, `tasks`, `bookings`
- **B) States/Enums**: `payment_status`: `held` → `released`. Status: `delivered` → `completed`.
- **C) RPCs/Triggers**: `rpc_approve_delivery`, `process_payment_event_ledger`. `extensions.digest` for key generation.
- **D) Invariants**: Balanced ledger. Held-to-released gate. Owner-only trigger. **CRITICAL**: Key uses `now()` = broken idempotency.
- **E) Ownership**: Task/booking `client_id` triggers release.
- **F) Time Mechanics**: None.
- **G) Money Events**: `release_with_fee` via ledger.
- **H) Diagram**: Flowchart + State.

---

## 17: Storage Signed URLs Flow

- **A) Entities**: `profiles.avatar_url`, `messages.attachment_url`, `tasks.image_paths`, Storage buckets
- **B) States/Enums**: URL lifecycle: Unsigned → Signed → Expired.
- **C) RPCs/Triggers**: None. Service-layer logic (`AvatarService`, `AttachmentService`).
- **D) Invariants**: DB stores paths, NOT URLs. Short-lived TTL. Chat attachment paths start with `convos/`. Authenticated sessions only.
- **E) Ownership**: Participants + admin for chat attachments. Owner for avatars.
- **F) Time Mechanics**: TTLs: `600s` (diagram) vs `3600s`/`7200s` (code) — **MISMATCH**. Proposed: `TimedCache`.
- **G) Money Events**: None.
- **H) Diagram**: Sequence Diagram.

---

## 18: Realtime Subscription Topology

- **A) Entities**: Supabase Realtime Publication, `messages`, `notifications`, `conversations`
- **B) States/Enums**: Publication tables: `messages`, `notifications`. **`conversations` is NOT published**.
- **C) RPCs/Triggers**: `.stream()` in `MessageService`, `NotificationService`. N+1 `asyncMap` transforms.
- **D) Invariants**: Stream filter must match published table. No unbounded REST calls inside stream handlers.
- **E) Ownership**: RLS filters events to participant.
- **F) Time Mechanics**: None.
- **G) Money Events**: None.
- **H) Diagram**: Component / Data Flow. **CRITICAL**: `conversations` stream is silently broken.

---

## 19: Direct Offers Work Contract

- **A) Entities**: `direct_offers`, `conversations`
- **B) States/Enums**: `status`: `sent`, `accepted`, `active`, `delivered`, `completed`, `canceled`, `rejected`. `payment_status`: `unpaid`, `held`, `released`.
- **C) RPCs/Triggers**: `fn_direct_offer_guard`, `process_payment_event_ledger`. **NOTE**: `rpc_approve_delivery` is INCOMPATIBLE with direct offers.
- **D) Invariants**: Initial state `sent/unpaid`. `active` requires `held`. `completed` requires `released`. Freelancer-only delivery.
- **E) Ownership**: `freelancer_id` creates; `client_id` pays/approves.
- **F) Time Mechanics**: **GAP**: No `sent` offer expiry/timeout.
- **G) Money Events**: `escrow_hold`, `release_with_fee`.
- **H) Diagram**: Sequence Diagram.

---

## 20: Withdrawals Lifecycle

- **A) Entities**: `withdrawal_requests`, `accounts`, `ledger_lines`
- **B) States/Enums**: `status`: `requested`, `processing`, `completed`, `failed`, `canceled`.
- **C) RPCs/Triggers**: `rpc_create_withdrawal_request` (proposed atomic RPC), `process_payment_event_ledger` (events: `withdrawal_request`, `withdrawal_complete`, `withdrawal_failed`, `withdrawal_cancel`).
- **D) Invariants**: `Total Balance = Available + PendingWithdrawal`. No deletion (terminal states only). Cancellation blocked once `processing`.
- **E) Ownership**: Freelancer owns their withdrawal. Admin controls `processing` transition.
- **F) Time Mechanics**: Admin marks `processing` before bank dispatch.
- **G) Money Events**: `withdrawal_request` (lock), `withdrawal_complete` (settle), `withdrawal_failed`/`withdrawal_cancel` (revert). **GAP**: `withdrawal_cancel` ledger reversal missing.
- **H) Diagram**: Sequence Diagram.

---

## 21: Wallet System (Escrow & Available Balances)

- **A) Entities**: `ledger_lines`, `journal_entries`, `accounts`, `wallet_balances` (view). **LEGACY**: `wallet_transactions` (frozen).
- **B) States/Enums**: Account types: `user_available`, `user_pending_withdrawal`, `platform_escrow`, `platform_revenue`, `system_cash_out`.
- **C) RPCs/Triggers**: `process_payment_event_ledger`. **DEPRECATED**: `process_payment_event`.
- **D) Invariants**: DR + CR = 0. Frozen `wallet_transactions` (no writes). Idempotency keys.
- **E) Ownership**: System-only writes. Users can read their own `wallet_balances`.
- **F) Time Mechanics**: None.
- **G) Money Events**: All flow types: `escrow_hold`, `release_with_fee`, `refund`, `withdrawal_*`.
- **H) Diagram**: Sequence Diagram. **CRITICAL**: Old diagram references deprecated tables/RPCs.

---

## 22: Dynamic Platform Fee

- **A) Entities**: `platform_settings` (PROPOSED), `bookings` (+`fee_rate_applied`, `fee_amount`, `net_amount`), `ledger_lines`
- **B) States/Enums**: Fee rate in basis points (bps). Snapshotted at escrow time.
- **C) RPCs/Triggers**: `process_payment_event_ledger` (must read `platform_settings` and lock rate). `admin_update_system_config`.
- **D) Invariants**: Lock Rule: fee_rate frozen at `held` time. Gross = Net + Fee. DR/CR balanced.
- **E) Ownership**: Admin-only settings. System-only ledger writes.
- **F) Time Mechanics**: Fee snapshot timestamp (at escrow).
- **G) Money Events**: `escrow_hold` (with fee snapshot), `release_with_fee` (uses locked rate).
- **H) Diagram**: Sequence Diagram. **CRITICAL**: `platform_settings` table doesn't exist; RPC uses hardcoded 10%.

---

## 23: Admin Dashboard Wallet & Finance

- **A) Entities**: `system_config` (or `platform_settings`?), `vw_admin_finance_overview`, `vw_admin_booking_finance`, `admin_logs`, `journal_entries`, `ledger_lines`
- **B) States/Enums**: Admin RBAC: `profiles.active_role = 'admin'`.
- **C) RPCs/Triggers**: `admin_update_system_config`, `admin_triage_report`.
- **D) Invariants**: Fee locking snapshot. Double-entry equilibrium. Admin exclusivity for finance views.
- **E) Ownership**: `service_role` / admin only.
- **F) Time Mechanics**: None.
- **G) Money Events**: Read-only aggregation of all ledger events.
- **H) Diagram**: Functional Component + Sequence. **CRITICAL**: `public.users` PII leak still present.

---

## 24: Hardened Payment Linking System

- **A) Entities**: `payment_intents` (NEW), `payment_events` (NEW), `orphan_payments` (NEW), `bookings`, `tasks`, `direct_offers`
- **B) States/Enums**: `payment_intents.status`: `created`, `gateway_created`, `succeeded`, `failed`. `payment_events` is append-only.
- **C) RPCs/Triggers**: `PaymentIntentService` (BFF), `WebhookHandler` (Edge Function), `process_payment_event_ledger`. HMAC-SHA256 signature.
- **D) Invariants**: [INV-1] One intent per entity+attempt. [INV-2] Amount match (webhook vs intent). [INV-3] Append-only events. [INV-4] Ledger link.
- **E) Ownership**: `service_role` only for `payment_events` INSERT. Intent created by BFF.
- **F) Time Mechanics**: Webhook async handling. Retry tolerance via idempotency.
- **G) Money Events**: `escrow_hold` linked to `payment_intent_id`.
- **H) Diagram**: Sequence + State Transition. Tables not yet created.
