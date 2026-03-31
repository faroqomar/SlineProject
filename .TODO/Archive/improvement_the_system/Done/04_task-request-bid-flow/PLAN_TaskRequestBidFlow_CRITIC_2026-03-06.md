# 📌 Plan: Task Request Bid Flow Implementation (PlanCritic Review)

**Date**: 2026-03-06  
**PlanCritic Review**: v1.0  
**Status**: CRITIQUE COMPLETE - BLOCKING ISSUES FOUND  
**Folder**: `.TODO/improvement_the_system/ImplementReady/04_task-request-bid-flow`

---

## A) Assumptions + Decision Needed (Blocking)

### Assumptions (Inferred)

1. **Supabase RPCs exist and are functional**: The plan assumes `accept_task_request`, `reject_task_request`, `replace_task_request`, `award_task_offer`, `pay_awarded_offer`, `cancel_awarded_offer` RPCs exist with correct signatures.
2. **QiCard payment integration is operational**: Assumes `qicard_payment_create_tender` edge function is deployed.
3. **No schema changes required**: Assumes `task_requests` table has all required columns including `payment_deadline`.
4. **24h expiration cron is running**: Assumes `process_expired_requests()` is triggered by pg_cron.
5. **Bidder summaries RPC exists**: Assumes `get_proposal_bidder_summaries` RPC is available for owner view.

### Decision Needed (Blocking)

| Decision | Options | Recommended | Impact on Plan |
|----------|---------|-------------|----------------|
| **1. Bid replacement UX** | A) Replace in-place (same row) B) Soft-delete + insert new | **B** - Matches current `replace_task_request` RPC contract | UI must show "replace" vs "new" clearly |
| **2. Payment deadline duration** | A) Fixed 24h B) Configurable per task C) No deadline | **A** - 24h standard | Affects countdown timer logic |
| **3. Auto-reject notification** | A) Silent B) Push notification to rejected bidders | **B** - Required for UX | Verify `accept_task_request` creates notifications |
| **4. Expired bid visibility** | A) Show in list with "Expired" badge B) Hide completely | **A** - Transparency | Add filter for expired status |
| **5. Model consolidation** | A) Keep TaskRequest + ProposalModel separate B) Deprecate ProposalModel | **B** - Single source of truth | Migration path for ProposalRepository |

**Blocking**: Decisions 1, 3, and 5 must be resolved before Phase 3 (UI) execution.

---

## B) Gate Status (Pass/Fail)

### Gate 0: Test Infrastructure Gate (NEW - Required)
**Status**: ❌ **FAIL**
- **Reason**:
  - No test harness for task request unit tests
  - No fixture manifest for bid test data
  - No deterministic mock for Supabase RPC responses
- **Fix Required**:
  1. Create `test/unit/task_requests/` directory structure
  2. Add `MockSupabaseClient` helper for RPC mocking
  3. Create fixture factories for `TaskRequest`, `ProposalModel`
  4. Document test run commands

### Gate 1: Data/Contracts Gate
**Status**: ❌ **FAIL**
- **Reason**:
  - No live Supabase scan performed (plan assumed existence)
  - API contract document not created
  - Unclear if `payment_deadline` column exists in `task_requests`
- **Fix Required**:
  1. Execute MCP scan for `task_requests` table columns
  2. Verify all RPC signatures match expected
  3. Create `API_CONTRACT.md` with request/response shapes

### Gate 2: Security Gate
**Status**: ⚠️ **CONDITIONAL PASS**
- **Reason**:
  - RLS policies exist but not verified to block direct status updates
  - No explicit audit for bid manipulation attack vectors
  - Missing rate limiting for bid submission (spam risk)
- **Fix Required**:
  1. RLS negative test: Attempt direct UPDATE on task_requests.status
  2. Verify RPC security definer settings
  3. Add rate limiting check for submit/replace operations

### Gate 3: Backend/API Gate
**Status**: ⚠️ **CONDITIONAL PASS**
- **Reason**:
  - `TaskRequestsService` exists but missing bid expiration helper
  - No `process_expired_requests` cron verification
  - Missing error mapping for new RPC errors
- **Fix Required**:
  1. Add `getBidExpirationTime()` helper
  2. Add `isBidExpired()` check
  3. Verify all RPC error codes are mapped

### Gate 4: UI/Integration Gate
**Status**: ❌ **FAIL**
- **Reason**:
  - No countdown timer implementation for expiration
  - No "Replace Bid" UI flow in `SubmitRequestSheet`
  - Missing payment deadline display in award dialog
  - No realtime subscription for bid status changes
- **Fix Required**:
  1. Add expiration countdown widget
  2. Implement replace bid UX
  3. Add payment deadline countdown
  4. Add Supabase realtime listener for `task_requests`

### Gate 5: Release/QA Gate
**Status**: ❌ **FAIL**
- **Reason**:
  - No regression test list for existing proposal flow
  - No E2E test for complete bid lifecycle
  - No rollback procedure for payment issues
- **Fix Required**:
  1. Create regression checklist for `ProposalRepository`
  2. Write E2E test script for bid flow
  3. Document emergency rollback steps

---

## C) Critical Gaps (Must-Fix)

### Gap 1: Model Duplication Drift
| | Details |
|---|---|
| **Gap** | `TaskRequest` and `ProposalModel` are nearly identical but maintained separately |
| **Why it will break** | Feature updates will be applied to one model but not the other, causing UI inconsistencies |
| **Fix** | 1. Audit field differences 2. Create shared base interface 3. Deprecate `ProposalModel` over 2 sprints 4. Update `ProposalRepository` to return `TaskRequest` |
| **Owner** | @Architect |
| **Acceptance check** | Both models have identical fields; migration plan documented |

### Gap 2: Missing Realtime Updates
| | Details |
|---|---|
| **Gap** | Bid list does not auto-refresh when bids are accepted/rejected by owner |
| **Why it will break** | Freelancer sees stale "pending" bid after owner already accepted/rejected |
| **Fix** | 1. Add Supabase realtime subscription to `task_requests` table 2. Filter by `task_id` 3. Call `loadInitial()` on `UPDATE` events 4. Handle subscription lifecycle (dispose on screen close) |
| **Owner** | @Architect |
| **Acceptance check** | Bid status updates in real-time without manual refresh |

### Gap 3: No Bid Expiration Handling
| | Details |
|---|---|
| **Gap** | UI does not handle expired bids (no countdown, no filter, no visual distinction) |
| **Why it will break** | Freelancers submit bids believing they are active; owners see expired bids as pending |
| **Fix** | 1. Add `isExpired` getter to `TaskRequest` 2. Add expiration countdown widget 3. Add "Expired" badge to `RequestTile` 4. Add filter toggle in `RequestsListScreen` 5. Prevent actions on expired bids |
| **Owner** | @Pixel |
| **Acceptance check** | Expired bids show "Expired" badge; countdown visible for pending bids |

### Gap 4: Missing Payment State UI
| | Details |
|---|---|
| **Gap** | UI does not distinguish between "Accepted (Unpaid)" and "In Progress (Paid)" |
| **Why it will break** | Freelancer may start work before payment; client may think work started |
| **Fix** | 1. Add payment status badge to `RequestTile` 2. Show "Payment Pending" vs "Escrow Held" 3. Add payment deadline countdown for unpaid accepted bids 4. Disable "Start Work" actions until payment held |
| **Owner** | @Pixel |
| **Acceptance check** | Clear visual distinction between unpaid/held payment states |

### Gap 5: No Rate Limiting on Bid Submission
| | Details |
|---|---|
| **Gap** | No client-side or server-side rate limiting for bid spam |
| **Why it will break** | Malicious user could spam bids; legitimate user could accidentally double-submit |
| **Fix** | 1. Add debounce to submit button (2s) 2. Add `isSubmitting` flag to prevent double-submit 3. Verify RLS policy prevents rapid inserts (if needed, add rate limit function) |
| **Owner** | @Architect |
| **Acceptance check** | Double-clicking submit button only creates one bid |

### Gap 6: Missing Error Recovery
| | Details |
|---|---|
| **Gap** | Payment failure does not provide clear retry path |
| **Why it will break** | Client stuck in "Accepted but Unpaid" state with no way to retry payment |
| **Fix** | 1. Add "Retry Payment" button to bid tile 2. Add "Cancel Award" action 3. Show clear error message with recovery options |
| **Owner** | @Pixel |
| **Acceptance check** | User can retry payment or cancel award after failure |

---

## D) Invariants & Success Criteria (Non-Negotiable)

### Invariant 1: One Active Bid Per Freelancer Per Task
- **Statement**: A freelancer can only have one non-deleted bid on a task at any time
- **Enforcement**: 
  - DB: `uq_task_requests_one_active_per_freelancer` unique constraint on `(task_id, freelancer_id) WHERE deleted_at IS NULL`
  - Code: `replace_task_request` RPC handles atomic replace
- **Verification**: 
  - Test: Attempt to insert second pending bid → expect unique constraint violation
  - Query: `SELECT COUNT(*) FROM task_requests WHERE task_id = X AND freelancer_id = Y AND deleted_at IS NULL GROUP BY task_id, freelancer_id HAVING COUNT(*) > 1` should return 0 rows

### Invariant 2: Only RPC Can Change Bid Status
- **Statement**: Direct client UPDATE on `task_requests.status` must be blocked by RLS
- **Enforcement**:
  - RLS: No UPDATE policy allowing `status` column modification for `authenticated` role
  - RPC: `accept_task_request`, `reject_task_request` are SECURITY DEFINER
- **Verification**:
  - Test: Attempt `supabase.from('task_requests').update({status: 'accepted'}).eq('id', X)` → expect 401/403
  - Audit: Review RLS policies confirm no status UPDATE allowed

### Invariant 3: Task Status Synchronized with Bid Acceptance
- **Statement**: When a bid is accepted, task.status becomes 'assigned' and task.assigned_freelancer_id is set
- **Enforcement**:
  - RPC: `accept_task_request` performs both updates in single transaction
- **Verification**:
  - Test: Accept bid → query task → verify status='assigned' AND assigned_freelancer_id=bidder_id
  - E2E: Verify `trg_tasks_after_status_change_notify_parties` fires

### Invariant 4: Sibling Bids Auto-Rejected on Acceptance
- **Statement**: When one bid is accepted, all other pending bids on the same task are rejected automatically
- **Enforcement**:
  - RPC: `accept_task_request` updates siblings to 'rejected' in same transaction
- **Verification**:
  - Test: Create 3 pending bids → accept one → verify other 2 are 'rejected'
  - Query: `SELECT COUNT(*) FROM task_requests WHERE task_id = X AND status = 'pending'` should be 0 after acceptance

### Invariant 5: Payment Required Before Work Starts
- **Statement**: Task status cannot transition to 'in_progress' without payment_status='held' on the accepted bid
- **Enforcement**:
  - RPC: `pay_awarded_offer` or `process_payment_event_ledger` with `gateway_escrow` updates both bid.payment_status and task.status
- **Verification**:
  - Test: Attempt to set task.status='in_progress' with bid.payment_status='unpaid' → expect failure
  - E2E: Complete payment → verify task.status='in_progress'

---

## E) Risk Register (Predict Problems)

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|------|-------|------------|--------|--------------|-------------|-----------|----------|
| **Double acceptance race** | `accept_task_request` RPC | Med | High | Feature | Two bids show 'accepted' for same task | RPC transaction checks task.status='open' before accepting | Manual intervention to reject incorrect bid |
| **Payment desync** | `pay_awarded_offer` flow | Med | High | Feature | Ledger shows escrow but bid.payment_status='unpaid' | Two-phase commit: update ledger first, then DB | Reconciliation job detects and fixes mismatch |
| **Stale bid list** | `RequestsListScreen` | High | Med | UX | Freelancer sees pending bid after owner rejected | Add realtime subscription for live updates | Manual refresh button as temporary fix |
| **Expired bid confusion** | Bid submission | Med | Med | UX | Freelancer submits bid that expires before owner sees it | Show expiration countdown prominently | Allow owner to "extend" expired bids if they want to accept |
| **Model drift** | ProposalModel vs TaskRequest | High | Med | App-wide | Fields missing in one model cause serialization errors | Shared interface + deprecation plan | Hotfix to sync fields |
| **RLS bypass attempt** | Security audit | Low | High | Security-breach | Logs show direct UPDATE attempts on task_requests | Strict RLS + security tests | Immediate policy patch |
| **Rate limit exhaustion** | Bid submission | Low | Low | Local | User reports "too many requests" error | Client-side debounce + clear error messages | Exponential backoff retry |
| **QiCard integration failure** | Payment screen | Med | High | Feature | Payment WebView shows error | Fallback to manual escrow process | Disable QiCard, enable manual payment flow |

---

## F) Pre-Mortem (How this fails in real life)

1. **This fails when** a freelancer submits a bid, the owner accepts it, but the freelancer sees "pending" because the list didn't auto-refresh. The freelancer withdraws and submits a new bid, causing confusion and duplicate work.
   - *Maps to*: Gap 2 (Missing Realtime Updates)

2. **This fails when** a client accepts a bid and pays, but due to a race condition, another bid also shows as accepted. Both freelancers think they won and start working.
   - *Maps to*: Risk 1 (Double acceptance race)

3. **This fails when** a bid expires after 24h, but the UI still shows it as "pending" without any expiration indicator. The owner tries to accept and gets a confusing error.
   - *Maps to*: Gap 3 (No Bid Expiration Handling)

4. **This fails when** a developer updates `TaskRequest` model but forgets to update `ProposalModel`. The owner view (using ProposalRepository) shows corrupted data.
   - *Maps to*: Gap 1 (Model Duplication Drift)

5. **This fails when** payment succeeds at QiCard but the webhook fails to update the database. The client is charged but the task never starts, and there's no retry mechanism.
   - *Maps to*: Risk 2 (Payment desync)

6. **This fails when** a malicious user spams 1000 bids on popular tasks, overwhelming the database and notification system.
   - *Maps to*: Gap 5 (No Rate Limiting)

7. **This fails when** a client pays for a bid, but the UI still shows "Payment Pending" due to missing state refresh. They pay twice.
   - *Maps to*: Gap 4 (Missing Payment State UI)

8. **This fails when** the app crashes on bid submission because `ProposalModel` and `TaskRequest` have incompatible `toMap` implementations.
   - *Maps to*: Gap 1 (Model Duplication Drift)

9. **This fails when** a freelancer finds an RLS loophole and directly updates their bid status to 'accepted' without payment.
   - *Maps to*: Risk 6 (RLS bypass attempt)

10. **This fails when** the owner rejects a bid but the freelancer never receives a notification, so they keep waiting for a response.
    - *Maps to*: Decision 3 (Auto-reject notification not verified)

---

## G) Plan Fixes (Concrete Additions / Expansions)

### Fix 1: Test Infrastructure Setup

**Goal**: Create test harness for task request unit tests  
**Why**: Cannot verify correctness without deterministic tests  
**How**:
1. Create `test/unit/task_requests/` directory
2. Add `test/helpers/mock_supabase_rpc.dart` for RPC mocking
3. Create `test/fixtures/task_request_factory.dart` with factory methods
4. Add `flutter test test/unit/task_requests/` command to CI

**Output artifact**: Test directory structure + mock helpers + fixture factories  
**Stop condition**: `flutter test` passes with at least 3 task request unit tests

---

### Fix 2: Live Supabase Verification

**Goal**: Confirm all RPCs and table columns exist as expected  
**Why**: Plan assumes existence without verification  
**How**:
1. Use MCP to query `task_requests` column definitions
2. Use MCP to list all RPCs with parameters
3. Verify `payment_deadline` column exists
4. Document any discrepancies

**Output artifact**: `LIVE_DB_VERIFICATION.md` with actual vs expected comparison  
**Stop condition**: All required objects confirmed present or documented gap

---

### Fix 3: Model Consolidation Plan

**Goal**: Eliminate ProposalModel/TaskRequest duplication  
**Why**: Prevents drift and maintenance burden  
**How**:
1. Create shared `BidModel` interface
2. Update `ProposalRepository` to return `TaskRequest`
3. Add deprecation annotation to `ProposalModel`
4. Create migration guide for ProposalModel users
5. Update `TaskRequest.fromProposal` factory

**Output artifact**: `MODEL_CONSOLIDATION_PLAN.md` + updated code with deprecation warnings  
**Stop condition**: `ProposalModel` marked deprecated, `TaskRequest` has all ProposalModel fields

---

### Fix 4: Realtime Subscription Implementation

**Goal**: Auto-refresh bid list on status changes  
**Why**: Prevents stale data confusion  
**How**:
1. Add `SupabaseRealtimeService` for channel management
2. Subscribe to `task_requests` table with `task_id` filter
3. Listen for `UPDATE` events on `status` column
4. Call `loadInitial()` on changes
5. Dispose subscription in `dispose()`

**Output artifact**: `SupabaseRealtimeService` class + integration in `TaskRequestsViewModel`  
**Stop condition**: Bid status updates in real-time without manual refresh

---

### Fix 5: Expiration Handling

**Goal**: Show bid expiration state clearly  
**Why**: Prevents actions on expired bids  
**How**:
1. Add `isExpired`, `expirationTime`, `timeUntilExpiration` getters to `TaskRequest`
2. Create `ExpirationCountdown` widget
3. Add "Expired" badge to `RequestTile`
4. Add filter toggle in app bar
5. Disable accept/reject actions on expired bids

**Output artifact**: `ExpirationCountdown` widget + updated `RequestTile` + filter logic  
**Stop condition**: Expired bids show badge, countdown accurate to within 1 minute

---

### Fix 6: Payment State Clarity

**Goal**: Clearly distinguish unpaid vs held payment states  
**Why**: Prevents work-before-payment confusion  
**How**:
1. Add `PaymentStatusBadge` widget with color coding
2. Show "Payment Pending" + deadline countdown for accepted unpaid
3. Show "Escrow Held" for paid bids
4. Add "Retry Payment" button for failed payments
5. Add "Cancel Award" action for unpaid accepted bids

**Output artifact**: `PaymentStatusBadge` + updated `RequestTile` + action buttons  
**Stop condition**: User can clearly see payment state and take appropriate actions

---

### Fix 7: Rate Limiting & Debounce

**Goal**: Prevent bid spam and double-submit  
**Why**: Protects UX and database integrity  
**How**:
1. Add 2s debounce to submit button in `SubmitRequestSheet`
2. Add `isSubmitting` flag to disable button during submission
3. Verify `replace_task_request` RPC has rate limiting
4. Add client-side submit attempt counter

**Output artifact**: Debounce logic in `SubmitRequestSheet` + loading state handling  
**Stop condition**: Double-clicking submit only creates one bid

---

### Fix 8: Replace Bid UX

**Goal**: Clear UI for replacing existing bid  
**Why**: Freelancers need to update bids without confusion  
**How**:
1. Detect existing bid in `SubmitRequestSheet` init
2. Show "Replace Bid" title vs "Submit Bid"
3. Show comparison: old price/days vs new
4. Add confirmation dialog explaining replace action
5. Call `replace_task_request` RPC instead of insert

**Output artifact**: Updated `SubmitRequestSheet` with replace flow  
**Stop condition**: Freelancer can clearly replace bid with confirmation

---

### Fix 9: API Contract Document

**Goal**: Document all RPC contracts  
**Why**: Single source of truth for Flutter/Supabase interface  
**How**:
1. Document `accept_task_request` params/return
2. Document `reject_task_request` params/return
3. Document `replace_task_request` params/return
4. Document `award_task_offer`, `pay_awarded_offer`, `cancel_awarded_offer`
5. Document `process_expired_requests` cron behavior

**Output artifact**: `API_CONTRACT.md` with all RPC signatures  
**Stop condition**: All RPCs documented with example request/response

---

### Fix 10: RLS Security Test Suite

**Goal**: Verify RLS prevents unauthorized bid manipulation  
**Why**: Critical security boundary  
**How**:
1. Test: Direct UPDATE on status → expect 403
2. Test: Non-owner accept → expect 401
3. Test: Non-bidder replace → expect 401
4. Test: Delete non-owned bid → expect 403
5. Document all security tests

**Output artifact**: `test/security/task_requests_rls_test.dart`  
**Stop condition**: All RLS tests pass, documenting security boundaries

---

## H) Corrected Plan (Execution-Ready, Gate-Based)

### Phase -1: Test Infrastructure (BLOCKING - Must Complete First)

**Goal**: Create deterministic test harness for all subsequent verification  
**Why**: Cannot safely verify changes without tests  

#### Subphase -1.1: Test Directory Setup
- **Step 1**: Create `test/unit/task_requests/` directory
- **Step 2**: Create `test/helpers/mock_supabase_rpc.dart` with `MockSupabaseClient` class
- **Step 3**: Create `test/fixtures/task_request_factory.dart` with:
  - `TaskRequest createTaskRequest({...})`
  - `Map<String, dynamic> createTaskRequestRow({...})`
- **Step 4**: Add test dependencies to `pubspec.yaml` if missing

**GATE CHECK**: `flutter test test/unit/task_requests/` runs without errors (tests can be empty)

---

### Phase 0: Verification & Contracts (BLOCKING)

**Goal**: Verify live Supabase state matches expectations; lock API contracts  
**Why**: Foundational; everything else depends on correct schema/RPCs  

#### Subphase 0.1: Live Supabase Scan
- **Step 1**: Use MCP to get `task_requests` table columns
- **Step 2**: Verify `payment_deadline` column exists (if not, document gap)
- **Step 3**: Use MCP to list all RPCs
- **Step 4**: Verify all required RPCs exist with correct signatures
- **Step 5**: Document discrepancies in `LIVE_DB_VERIFICATION.md`

**GATE CHECK**: `LIVE_DB_VERIFICATION.md` shows all required objects present OR gaps documented with plan

#### Subphase 0.2: API Contract Document
- **Step 1**: Create `.TODO/improvement_the_system/ImplementReady/04_task-request-bid-flow/API_CONTRACT.md`
- **Step 2**: Document each RPC:
  - `accept_task_request(p_task_id, p_request_id) -> uuid`
  - `reject_task_request(p_task_id, p_request_id) -> uuid`
  - `replace_task_request(p_task_id, p_freelancer_id, p_message, p_price, p_days) -> void`
  - `award_task_offer(p_request_id) -> jsonb`
  - `pay_awarded_offer(p_request_id) -> jsonb`
  - `cancel_awarded_offer(p_request_id) -> jsonb`
- **Step 3**: Document table row shape for `task_requests`

**GATE CHECK**: `API_CONTRACT.md` complete with all RPCs documented

#### Subphase 0.3: Model Consolidation Plan
- **Step 1**: Compare `TaskRequest` vs `ProposalModel` fields
- **Step 2**: Create `MODEL_CONSOLIDATION_PLAN.md` with migration steps
- **Step 3**: Add deprecation annotation to `ProposalModel`
- **Step 4**: Update `TaskRequest` to include any missing ProposalModel fields

**GATE CHECK**: `TaskRequest` has all fields from `ProposalModel`; deprecation documented

#### Subphase 0.4: Threat Model Document
- **Step 1**: Create `THREAT_MODEL.md` with:
  - Bypass attack: Direct status UPDATE
  - Race condition: Double acceptance
  - Payment desync: Work without escrow
  - Spam: Bid flooding
- **Step 2**: Define mitigation for each threat
- **Step 3**: Define security tests

**GATE CHECK**: `THREAT_MODEL.md` complete with mitigations and test requirements

---

### Phase 1: Security & Data Layer

**Goal**: Lock down security; ensure data layer handles all edge cases  
**Why**: Security cannot be bolted on later  

#### Subphase 1.1: RLS Verification
- **Step 1**: Review existing RLS policies on `task_requests`
- **Step 2**: Verify no policy allows direct status UPDATE
- **Step 3**: Document policy matrix in `RLS_CHECK_MATRIX.md`
- **Step 4**: If gaps found, create migration to fix

**GATE CHECK**: RLS matrix shows no unauthorized UPDATE allowed

#### Subphase 1.2: RLS Security Tests
- **Step 1**: Create `test/security/task_requests_rls_test.dart`
- **Step 2**: Test direct UPDATE → expect 403
- **Step 3**: Test non-owner accept → expect 401
- **Step 4**: Test non-bidder replace → expect 401
- **Step 5**: Run tests, document results

**GATE CHECK**: All security tests pass

#### Subphase 1.3: Service Layer Enhancements
- **Step 1**: Add `getBidExpirationTime()` to `TaskRequestsService`
- **Step 2**: Add `isBidExpired()` helper
- **Step 3**: Add `isBidReplaceable()` helper
- **Step 4**: Add comprehensive error mapping for new RPCs
- **Step 5**: Add rate limiting check (client-side debounce)

**GATE CHECK**: All new helpers have unit tests

#### Subphase 1.4: Model Updates
- **Step 1**: Add `isExpired` getter to `TaskRequest`
- **Step 2**: Add `expirationTime` getter (created_at + 24h)
- **Step 3**: Add `timeUntilExpiration` method
- **Step 4**: Add `paymentDeadline` field (if missing)

**GATE CHECK**: Model unit tests pass with new getters

---

### Phase 2: Backend Integration (MVVM)

**Goal**: Realtime updates; robust state management  
**Why**: Prevents stale data; ensures smooth UX  

#### Subphase 2.1: Realtime Service
- **Step 1**: Create `SupabaseRealtimeService` class
- **Step 2**: Implement `subscribeToTaskRequests(taskId, onUpdate)`
- **Step 3**: Implement channel lifecycle management (subscribe/unsubscribe)
- **Step 4**: Add error handling for subscription failures

**GATE CHECK**: Realtime subscription works; `onUpdate` called on DB changes

#### Subphase 2.2: ViewModel Integration
- **Step 1**: Add realtime subscription to `TaskRequestsViewModel.init`
- **Step 2**: Call `loadInitial()` on update events
- **Step 3**: Dispose subscription in `dispose()` method
- **Step 4**: Add debounce to prevent rapid reloads

**GATE CHECK**: Bid list auto-refreshes when status changes in DB

#### Subphase 2.3: State Management Hardening
- **Step 1**: Add `isSubmitting` flag to prevent double-submit
- **Step 2**: Add `isProcessing` flag for accept/reject actions
- **Step 3**: Ensure loading states prevent concurrent operations
- **Step 4**: Add optimistic updates with rollback on error

**GATE CHECK**: Double-clicking actions only executes once

---

### Phase 3: UI Implementation

**Goal**: Complete, polished UI with all bid flow states  
**Why**: User-facing feature must be intuitive and complete  

#### Subphase 3.1: Expiration Widgets
- **Step 1**: Create `ExpirationCountdown` widget
- **Step 2**: Show countdown for pending bids
- **Step 3**: Show "Expired" badge for expired bids
- **Step 4**: Update `RequestTile` to use countdown

**GATE CHECK**: Countdown accurate; expired badge visible

#### Subphase 3.2: Payment State Widgets
- **Step 1**: Create `PaymentStatusBadge` widget
- **Step 2**: Color code: unpaid (orange), held (green), released (blue), refunded (grey)
- **Step 3**: Add payment deadline countdown for accepted unpaid
- **Step 4**: Update `RequestTile` with badge

**GATE CHECK**: All payment states clearly distinguishable

#### Subphase 3.3: Replace Bid UX
- **Step 1**: Detect existing bid in `SubmitRequestSheet` init
- **Step 2**: Show "Replace Bid" title when replacing
- **Step 3**: Show old vs new comparison
- **Step 4**: Add confirmation dialog
- **Step 5**: Call `replace_task_request` RPC

**GATE CHECK**: Replace flow clear; confirmation shown

#### Subphase 3.4: Award Dialog Enhancement
- **Step 1**: Add payment deadline explanation
- **Step 2**: Show comparison with budget
- **Step 3**: Add "What happens next" section
- **Step 4**: Clear "Award" vs "Cancel" actions

**GATE CHECK**: Award dialog explains full consequences

#### Subphase 3.5: Error Recovery UI
- **Step 1**: Add "Retry Payment" button for failed payments
- **Step 2**: Add "Cancel Award" action for unpaid accepted
- **Step 3**: Show clear error messages with recovery options
- **Step 4**: Add loading states for retry actions

**GATE CHECK**: User can recover from all error states

#### Subphase 3.6: Empty/Filter States
- **Step 1**: Add filter toggle for expired bids
- **Step 2**: Polish "No offers" empty state
- **Step 3**: Add "Refresh" button for error states
- **Step 4**: Add skeleton loaders for initial load

**GATE CHECK**: All states have appropriate UI

---

### Phase 4: QA & Release

**Goal**: Verify correctness; document release steps  
**Why**: Prevents regressions; enables safe deployment  

#### Subphase 4.1: Integration Tests
- **Step 1**: Test complete bid lifecycle:
  - Submit → List → Accept → Pay → Complete
- **Step 2**: Test replace bid flow
- **Step 3**: Test reject bid flow
- **Step 4**: Test expiration flow (mock time or use short TTL)

**GATE CHECK**: All integration tests pass

#### Subphase 4.2: Regression Tests
- **Step 1**: Verify `ProposalRepository` still works
- **Step 2**: Verify `ProposalsListScreen` renders correctly
- **Step 3**: Verify dashboard inbox shows bids correctly
- **Step 4**: Verify existing task flows unaffected

**GATE CHECK**: No regressions in existing proposal/task flows

#### Subphase 4.3: E2E Manual Testing
- **Step 1**: Create `E2E_TEST_SCRIPT.md` with step-by-step scenarios
- **Step 2**: Test as freelancer: submit, replace, withdraw
- **Step 3**: Test as owner: accept, reject, pay
- **Step 4**: Test edge cases: network failure, double-click, expired bid

**GATE CHECK**: All E2E scenarios pass

#### Subphase 4.4: Documentation Update
- **Step 1**: Update `Sline_everything/DEVELOPER_GUIDE.md`
- **Step 2**: Update `Sline_everything/SUPABASE_SETUP.md` if schema changes
- **Step 3**: Update `.cursor/PROJECT_CONTEXT.md`
- **Step 4**: Create `FEATURE_BID_FLOW.md` guide for developers

**GATE CHECK**: All docs current with implementation

#### Subphase 4.5: Release Checklist
- **Step 1**: Create `RELEASE_CHECKLIST.md` with:
  - Pre-release verification steps
  - Deployment order
  - Rollback procedure
  - Monitoring alerts
- **Step 2**: Define rollback triggers
- **Step 3**: Define monitoring metrics

**GATE CHECK**: Release checklist approved by team

---

## I) Change Report (Diff-Style)

### Original Issues Summary

1. **Missing test infrastructure**: No unit test setup for task requests
2. **No live Supabase verification**: Assumed RPCs/columns exist without checking
3. **Model duplication**: TaskRequest and ProposalModel maintained separately
4. **No realtime updates**: Bid list would show stale data
5. **No expiration handling**: Missing 24h TTL UI
6. **No payment state clarity**: Unclear unpaid vs held distinction
7. **No rate limiting**: Risk of double-submit and spam
8. **Incomplete replace UX**: Replace flow not designed
9. **Missing API contract**: No documented RPC interfaces
10. **No security test suite**: RLS not verified

### Added Steps (Major Additions)

| Phase | Step | Why |
|-------|------|-----|
| -1 | Test Infrastructure Setup | Cannot verify without tests |
| 0.1 | Live Supabase Scan | Must verify reality vs assumptions |
| 0.3 | Model Consolidation Plan | Prevent drift between TaskRequest/ProposalModel |
| 0.4 | Threat Model Document | Security must be designed in |
| 1.2 | RLS Security Tests | Verify security boundaries |
| 1.3 | Service Helpers (expiration, replaceable) | Core business logic missing |
| 2.1 | Realtime Service | Prevent stale data |
| 2.3 | State Management Hardening | Prevent race conditions |
| 3.1 | Expiration Widgets | 24h TTL requirement |
| 3.2 | Payment State Widgets | Payment flow clarity |
| 3.3 | Replace Bid UX | Required for bid updates |
| 3.5 | Error Recovery UI | Handle payment failures |
| 4.4 | Documentation Update | Keep docs in sync |

### Removed Steps

- None (all original steps kept, expanded with more detail)

### Reordered Steps

| From | To | Reason |
|------|-----|--------|
| Phase 0: Spec Lock | Phase -1: Test Infrastructure | Tests must exist before verification |
| Phase 1: Database | Phase 0: Verification | Must verify before building |
| Phase 3: UI | Phase 3: UI (after backend hardening) | UI depends on working realtime/state mgmt |

### Expanded Steps

| Original | Expanded To | What Changed |
|----------|-------------|--------------|
| "Verify TaskRequestsService" | 4 detailed subphases with specific methods | Added helpers, error mapping, rate limiting |
| "Enhance RequestTile" | 6 UI subphases (expiration, payment, replace, award, error, empty) | Broke down into specific widgets |
| "Functional QA" | Integration + Regression + E2E + Documentation + Release | Comprehensive QA coverage |

### Why (Short)

1. **Tests first**: Cannot verify correctness without deterministic tests
2. **Verify reality**: Plans often assume; reality must be checked
3. **Security gates**: Must verify before building on top
4. **Real-time**: Stale data is a UX killer; must be designed in
5. **State completeness**: Edge cases (expiration, payment states) are core requirements

### Residual Risks (Even After Fixes)

| Risk | Mitigation | Monitoring |
|------|-----------|------------|
| QiCard integration may fail in production | Fallback to manual escrow | Payment success rate metric |
| 24h expiration may be too short/long for some markets | Make configurable in future | Bid expiration rate |
| Realtime subscription may have race conditions with pagination | Debounce + optimistic updates | Subscription error logs |
| Model consolidation may break existing ProposalRepository users | Gradual deprecation period | Error rates in proposal screens |

---

## Summary: Execution Order

**BLOCKING GATES**: Must pass before proceeding
1. ❌ **Gate 0**: Test Infrastructure (PHASE -1)
2. ❌ **Gate 1**: Data/Contracts (PHASE 0)
3. ⚠️ **Gate 2**: Security (PHASE 1.1-1.2)
4. ❌ **Gate 3**: Backend (PHASE 1.3-2.3)
5. ❌ **Gate 4**: UI (PHASE 3)
6. ❌ **Gate 5**: Release (PHASE 4)

**RECOMMENDED EXECUTION**:
1. **PHASE -1**: Set up test infrastructure (1 day)
2. **PHASE 0**: Verify Supabase + create contracts (1 day)
3. **PHASE 1**: Security + service layer (2 days)
4. **PHASE 2**: Realtime + state management (2 days)
5. **PHASE 3**: UI implementation (3 days)
6. **PHASE 4**: QA + documentation (2 days)

**TOTAL ESTIMATE**: 11 days with 1 developer, or 5 days with 2 developers (parallel: one on backend, one on UI after contracts locked).

---

**PlanCritic Review Complete**  
**Status**: CRITICAL GAPS FOUND - DO NOT EXECUTE UNTIL GATES PASS  
**Next Action**: Resolve blocking decisions and complete Phase -1/0 before proceeding to implementation.
