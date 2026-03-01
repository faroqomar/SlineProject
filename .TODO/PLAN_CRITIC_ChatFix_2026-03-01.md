# ChatFix Plan Critic Report

Target plan: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_ChatFix_2026-03-01.md`

## A) Assumptions + Decision Needed (Blocking)

### Assumptions

- The current repo state on 2026-03-01 is the execution baseline.
- The live Supabase scan from 2026-03-01 is the source of truth for tables, policies, triggers, storage, and realtime publication membership.
- Scope remains Chat plus direct dependencies only.
- DB rollout must be additive first, then app rollout, then policy tightening/removal.
- Existing test infrastructure is partial, not absent:
  - widget/unit baseline exists under `test/`
  - integration baseline exists under `integration_test/`
  - Chat still lacks the contract, RLS, and deterministic fixture coverage needed for this hardening pass.

### Decision Needed (Blocking)

#### 1) Direct DM authorization rule

- Missing decision:
  - Is direct DM creation favorites-gated, participant-only, or a hybrid rule?
- Options:
  - `Favorites-gated`
  - `Participant-only`
  - `Hybrid by entry path`
- Recommended:
  - `Favorites-gated`
- Why:
  - It is the least-privilege option, matches the stricter side of current docs, and fixes the live overexposure caused by the weak participant-only insert policy.
- Plan impact:
  - If `Favorites-gated`, keep a single canonical insert rule in RLS and align UI copy accordingly.
  - If `Participant-only`, remove favorites assumptions from docs/UI and accept a broader abuse surface.
  - If `Hybrid`, add explicit server-side branching and test matrix expansion.

#### 2) Task-linked conversation initiator rule

- Missing decision:
  - Who is allowed to start a task-linked conversation?
- Options:
  - `Non-owner only`
  - `Owner only`
  - `Both via server RPC`
- Recommended:
  - `Non-owner only`
- Why:
  - Live `start_task_conversation_v1` already enforces this. Changing it mid-fix multiplies rollout risk and creates unnecessary contract churn.
- Plan impact:
  - If `Non-owner only`, app method names/comments and UX must be aligned to the existing backend truth.
  - If `Owner only` or `Both`, backend functions, policies, and booking/deeplink behavior must all be redesigned first.

#### 3) Offer action scope

- Missing decision:
  - Are offer messages valid in every conversation, or only in task-linked conversations that map to task state?
- Options:
  - `Task-linked only`
  - `All conversations`
  - `Feature-flagged expansion later`
- Recommended:
  - `Task-linked only`
- Why:
  - Live triggers already couple offer acceptance to task assignment. Broadening offer usage without new backend rules creates undefined behavior.
- Plan impact:
  - If `Task-linked only`, UI must hide/disable offer actions outside eligible chats.
  - If `All conversations`, new backend invariants are required before UI work.

#### 4) Conversation list freshness strategy

- Missing decision:
  - Should Chat depend on realtime for conversation list updates, or should list freshness stay fetch-driven?
- Options:
  - `Fetch-refresh only`
  - `Enable conversations realtime publication`
  - `Hybrid: fetch-first, realtime later`
- Recommended:
  - `Hybrid: fetch-first, realtime later`
- Why:
  - It removes the current false assumption immediately without forcing a publication change in the same critical security release.
- Plan impact:
  - If `Fetch-refresh only`, delete conversation-list realtime work entirely.
  - If `Realtime`, add publication change, verification, and fallback.
  - If `Hybrid`, ship fallback first and gate realtime behind a later pass.

#### 5) Attachment delete/update semantics

- Missing decision:
  - Are participants allowed to modify existing chat attachments, or is attachment storage append-only?
- Options:
  - `Append-only; no delete/update UI`
  - `Uploader can delete`
  - `Both participants can manage`
- Recommended:
  - `Append-only; no delete/update UI`
- Why:
  - It is the lowest-risk contract and avoids expanding storage mutation policies during a security correction release.
- Plan impact:
  - If append-only, storage policy scope stays limited to insert/select.
  - If mutation is required, ownership semantics and cleanup jobs must be defined.

## B) Gate Status (Pass/Fail)

### Gate 0: Test Infrastructure Gate

- Status:
  - ❌ FAIL
- Reason:
  - Existing test harnesses are real but incomplete for this fix scope; there is no Chat-specific service/viewmodel fake strategy or RLS contract runner.
  - Existing Chat widget and integration tests validate happy-path send/render behavior, not the contract migrations, security denials, or realtime fallback behavior.
  - The plan does not define stable selectors for the new error/retry/archive states it wants to add.
- What to add/fix to pass:
  - Add a Chat test strategy artifact covering unit/widget/integration/RLS ownership.
  - Define deterministic test seams for repository/service/viewmodel layers.
  - Define selector keys for error, retry, archive, and manual-refresh states before UI changes.

### Gate 1: Data/Contracts Gate

- Status:
  - ❌ FAIL
- Reason:
  - The plan identifies contract drift, but leaves core product/security decisions unresolved.
  - There is no pre-change audit of existing rows/objects for legacy payload keys, storage path shape, or hidden duplicates.
  - Rollout compatibility is described, but not reduced to a hard execution order with stop conditions.
- What to add/fix to pass:
  - Lock the contract decisions first.
  - Add audit queries for message payloads, message types, conversation duplicates, and storage object paths.
  - Split additive compatibility work from enforcement removal.

### Gate 2: Security Gate

- Status:
  - ❌ FAIL
- Reason:
  - The plan schedules policy tightening, but does not require a pre-change allow/deny matrix artifact before migration authoring.
  - It does not explicitly audit whether current `chat-attachments` objects already violate the intended path contract.
  - It lacks post-change early-signal checks that would detect participant lockouts after weak policy removal.
- What to add/fix to pass:
  - Create the RLS/storage matrix before SQL changes.
  - Add storage-object audit and exception handling for invalid historical paths.
  - Add post-migration verification queries and failure thresholds.

### Gate 3: Backend/API Gate

- Status:
  - ❌ FAIL
- Reason:
  - The current plan contains stale work: it still assumes Chat sends client-side notifications, but current `MessageService` no longer does that.
  - It does not specify the exact compatibility layer for renaming misleading app APIs such as `startConversationByClient(...)`.
  - It does not define the message-stream contract clearly enough: full snapshot vs delta, dedupe rules, ordering, and receipt updates.
- What to add/fix to pass:
  - Remove obsolete tasks from scope.
  - Add exact API rename/deprecation steps.
  - Add a realtime merge contract with tests.

### Gate 4: UI/Integration Gate

- Status:
  - ❌ FAIL
- Reason:
  - The plan asks for better UI states, but does not define disable/retry behavior for send, offer, archive, and attachment actions.
  - It does not define the navigation regression matrix for booking entry, deep-link entry, and message-list entry after contract cleanup.
  - It does not specify how the UI behaves when conversation-list realtime is intentionally unavailable.
- What to add/fix to pass:
  - Add a UI state matrix and selector list.
  - Add navigation regression scenarios.
  - Add explicit refresh/fallback UX rules.

### Gate 5: Release/QA Gate

- Status:
  - ❌ FAIL
- Reason:
  - There is no execution slicing into reviewable PRs or deploy order.
  - There is no post-deploy checklist that proves live SQL, app behavior, and docs are aligned.
  - Rollback exists, but rollback triggers are not quantified.
- What to add/fix to pass:
  - Add PR slices, release order, and sign-off owners.
  - Add post-deploy smoke checks and live validation queries.
  - Add rollback thresholds and freeze conditions.

## C) Critical Gaps (Must-Fix)

### Gap 1

- Gap:
  - Core contract decisions are not locked before implementation.
- Why it will break:
  - Security and UI work will diverge immediately if DM creation, task initiator, offer scope, or realtime strategy remain ambiguous.
- Fix (exact step(s) to add / reorder):
  - Add a blocking decision artifact before any SQL or app edits.
  - Require sign-off on DM rule, task initiator, offer scope, and list freshness strategy.
- Owner:
  - Product + Backend + Frontend
- Acceptance check:
  - A single decision file exists and every later step references it without contradiction.

### Gap 2

- Gap:
  - No live data inventory exists for historical message payloads, storage objects, and conversation duplicates.
- Why it will break:
  - Tightened parsing or policies can strand historical data, hide attachments, or expose duplicate conversation behavior only after deployment.
- Fix (exact step(s) to add / reorder):
  - Add SQL/object audits before migration authoring.
  - Add compatibility rules for any discovered legacy payload/object shapes.
- Owner:
  - Backend
- Acceptance check:
  - Audit outputs exist and every outlier has a keep/fix/defer decision.

### Gap 3

- Gap:
  - The policy migration sequence is not strict enough.
- Why it will break:
  - Removing weak policies before app compatibility is verified can lock out valid users or break attachment access.
- Fix (exact step(s) to add / reorder):
  - Reorder to: capture live SQL -> add helper/RPC/fallback -> validate allow/deny matrix -> remove weak policies.
- Owner:
  - Backend
- Acceptance check:
  - No destructive policy removal happens before positive and negative checks pass.

### Gap 4

- Gap:
  - Realtime behavior is underspecified.
- Why it will break:
  - `subscribeToMessages()` currently treats a full snapshot as a single delta, and conversation-list subscription currently assumes a publication that does not exist.
- Fix (exact step(s) to add / reorder):
  - Add a realtime contract step that defines snapshot handling, dedupe, ordering, receipt merge, and fallback refresh triggers.
- Owner:
  - Frontend
- Acceptance check:
  - A single merge strategy exists and is covered by unit/widget tests.

### Gap 5

- Gap:
  - The plan includes stale work around client-side notification creation.
- Why it will break:
  - It wastes effort and can lead reviewers to remove code that no longer exists instead of verifying the remaining true notification sources.
- Fix (exact step(s) to add / reorder):
  - Remove the obsolete task.
  - Replace it with a verification task that confirms no Chat entry path performs client notification inserts.
- Owner:
  - Frontend
- Acceptance check:
  - Search-based verification and code review show no chat-path notification inserts.

### Gap 6

- Gap:
  - The plan lacks a Chat-specific test infrastructure gate.
- Why it will break:
  - Security hardening without deterministic service/viewmodel and integration coverage will regress silently.
- Fix (exact step(s) to add / reorder):
  - Add a dedicated test strategy artifact, selector inventory, fixture contract, and command list before feature changes.
- Owner:
  - QA + Frontend
- Acceptance check:
  - Chat test plan exists and every later test task maps to an existing harness.

### Gap 7

- Gap:
  - UI state handling is not formalized.
- Why it will break:
  - The implementation can improve one path while still dropping drafts, double-submitting, or hiding hard failures on another.
- Fix (exact step(s) to add / reorder):
  - Add a screen-state matrix for `MessagesScreen` and `ChatScreen`, including disable/retry/manual-refresh behavior.
- Owner:
  - Frontend
- Acceptance check:
  - Every state has an explicit UI rule and test case.

### Gap 8

- Gap:
  - Release management is under-specified.
- Why it will break:
  - This work crosses DB, app, storage, and docs. Shipping it as one opaque change increases rollback difficulty.
- Fix (exact step(s) to add / reorder):
  - Add PR slicing, release order, and rollback thresholds.
- Owner:
  - Backend + Frontend + QA
- Acceptance check:
  - The plan names the PR sequence, deploy order, and rollback triggers.

## D) Invariants & Success Criteria (Non-Negotiable)

### Invariant 1

- Invariant statement:
  - Only conversation participants can read chat messages.
- How to enforce:
  - `messages` RLS using participant-scoped policies only.
- How to verify:
  - Positive participant select passes; foreign-user select fails.

### Invariant 2

- Invariant statement:
  - Only the authenticated sender can insert a message as themselves.
- How to enforce:
  - RLS insert check plus `sender_id = auth.uid()` semantics.
- How to verify:
  - Valid sender insert passes; spoofed sender insert fails.

### Invariant 3

- Invariant statement:
  - Flutter writes only canonical message type values and canonical offer payload keys.
- How to enforce:
  - Typed model/use case layer; no anonymous UI maps on writes.
- How to verify:
  - Unit tests for model serialization and send payload construction.

### Invariant 4

- Invariant statement:
  - Offer acceptance changes task state only through server-side logic.
- How to enforce:
  - Existing trigger remains the only state-transition authority.
- How to verify:
  - Offer accept path updates task only when backend trigger conditions are met.

### Invariant 5

- Invariant statement:
  - Conversation creation follows exactly one canonical authorization rule per conversation type.
- How to enforce:
  - One policy path for direct DM creation; one RPC-backed path for task-linked creation.
- How to verify:
  - RLS matrix covers allowed and forbidden creation paths.

### Invariant 6

- Invariant statement:
  - Conversation archive is per-user, server-timestamped, and non-destructive.
- How to enforce:
  - Archive RPC stamps the correct participant column with server time.
- How to verify:
  - Archive hides conversation only for the caller until a newer message arrives.

### Invariant 7

- Invariant statement:
  - Attachment access is participant-scoped and signed URLs are never persisted as durable state.
- How to enforce:
  - Storage helper + participant-scoped policies + widget/service signed URL resolution only.
- How to verify:
  - Participant access passes; foreign-user signed URL/select fails.

### Invariant 8

- Invariant statement:
  - Realtime absence never produces a false “live” UX assumption.
- How to enforce:
  - Fetch-refresh fallback remains the source of truth unless publication is explicitly enabled and validated.
- How to verify:
  - Manual and automated tests confirm list refresh after send/archive/open without relying on missing publication.

### Invariant 9

- Invariant statement:
  - Failed sends do not silently discard user drafts.
- How to enforce:
  - UI awaits send result and clears input only on success.
- How to verify:
  - Widget tests cover failed send and retry behavior.

### Invariant 10

- Invariant statement:
  - Chat docs, code, and live Supabase rules stay aligned at release time.
- How to enforce:
  - Final docs sync only after live post-change re-scan.
- How to verify:
  - Post-release checklist includes docs/live/code sign-off.

## E) Risk Register (Predict Problems)

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|------|-------|------------|--------|--------------|-------------|-----------|----------|
| Valid users lose message access after weak policy removal | `public.messages` RLS | Med | High | Feature | Support reports or integration test denials on valid participants | Stage allow/deny matrix before removals | Restore captured policies and disable risky app path |
| Historical attachments become unreadable after storage tightening | `chat-attachments` bucket | Med | High | Feature | Signed URL fetch failures for old attachment rows | Audit object paths before policy change | Temporary exception policy for audited legacy paths |
| DM creation suddenly changes behavior for existing users | `public.conversations` insert path | High | Med | Feature | Spike in DM create failures or “no conversation created” reports | Lock direct-DM decision before migration | Re-enable previous insert policy while forward-fixing |
| App still behaves as if conversation list realtime exists | Flutter conversation list flow | High | Med | Feature | Stale message list until manual refresh | Ship fetch-refresh fallback first | Disable conversation subscription path entirely |
| Offer actions fire in unsupported conversations | `ChatScreen` + triggers | Med | High | Feature | DB validation errors or task-side side effects from unexpected chats | Scope offers to task-linked chats only | Hide offer UI behind server-confirmed eligibility |
| Archive RPC rollout hides conversations incorrectly | `public.conversations` archive path | Med | Med | Feature | Archive/manual refresh mismatch or wrong participant column stamped | Add RPC tests and per-user archive scenarios | Revert archive UI to read-only hide behavior |
| Realtime merge duplicates or drops messages | `subscribeToMessages()` / `ChatViewModel` | High | Med | Feature | Duplicate bubbles, missing receipts, out-of-order message list | Define snapshot merge contract and test it | Force refresh thread after each send/open on failure |
| Reviewers miss stale work and wrong assumptions | Plan execution | Med | Med | Delivery | PRs discuss non-existent notification writes | Remove obsolete tasks and add search-based verification | Stop release and re-baseline plan |

## F) Pre-Mortem (How this fails in real life)

- This fails when direct DM policy is tightened before the team decides whether favorites are required, and legitimate DM starts suddenly stop working.
- This fails when the app ships canonical `days` writes but historical offer payloads with `delivery` are still rendered without a compatibility rule.
- This fails when storage policies are tightened and older attachment objects do not match the expected `convos/<conversation_id>/...` path.
- This fails when conversation list realtime stays wired to a publication that does not exist, and the UI still looks “live” while being stale.
- This fails when `subscribeToMessages()` continues to collapse full snapshots to `rows.last`, hiding receipt updates or duplicating messages.
- This fails when archive behavior switches to an RPC but the UI still assumes immediate local removal without error recovery.
- This fails when release teams treat docs sync as optional and contradictory Chat rules remain in docs after shipping.
- This fails when the plan keeps chasing removed client-notification code instead of validating the live server-side notification trigger path.

## G) Plan Fixes (Concrete Additions / Expansions)

### 1) Add a blocking decision pack

- Goal:
  - Lock the Chat contract before implementation.
- Why:
  - Security and UI work cannot proceed safely while DM/task/offer/realtime rules are ambiguous.
- How:
  - Create `.TODO/CHAT_DECISIONS_2026-03-01.md` with the four blocking decisions and approved defaults.
- Output artifact:
  - Decision doc
- Stop condition:
  - Every later plan step references the approved contract without contradiction.

### 2) Add a live data audit pack

- Goal:
  - Identify historical data that would break under tightened rules.
- Why:
  - Contract cleanup without inventory is blind migration risk.
- How:
  - Create `.TODO/CHAT_DATA_AUDIT_2026-03-01.md` with SQL/object audit outputs for messages, conversations, and attachments.
- Output artifact:
  - Audit doc + SQL snippets
- Stop condition:
  - All outliers are classified as keep/fix/defer.

### 3) Add a pre-change RLS/storage matrix

- Goal:
  - Define exact allow/deny behavior before writing SQL.
- Why:
  - Least-privilege work needs an actor-by-actor matrix first.
- How:
  - Expand `.TODO/CHAT_RLS_MATRIX_2026-03-01.md` to exist before migration authoring, not during cleanup.
- Output artifact:
  - Matrix doc
- Stop condition:
  - Each actor/object/action has an expected allow/deny result.

### 4) Add a compatibility rollout matrix

- Goal:
  - Prevent DB/app deploy order mistakes.
- Why:
  - This fix crosses backend, app, and docs.
- How:
  - Create `.TODO/CHAT_ROLLOUT_MATRIX_2026-03-01.md` covering additive DB, app rollout, enforcement removal, and docs/live sign-off.
- Output artifact:
  - Rollout doc
- Stop condition:
  - Deploy order and rollback triggers are explicit.

### 5) Add a Chat test strategy artifact

- Goal:
  - Make tests execution-safe before code changes.
- Why:
  - Current baselines exist, but Chat hardening coverage is missing.
- How:
  - Create `.TODO/CHAT_TEST_STRATEGY_2026-03-01.md` covering unit/widget/integration/RLS ownership, fixtures, selectors, and commands.
- Output artifact:
  - Test strategy doc
- Stop condition:
  - Every planned test maps to a harness and command.

### 6) Add a realtime contract task

- Goal:
  - Define exactly how message and conversation updates are merged.
- Why:
  - Current stream behavior is a correctness bug, not just a refactor target.
- How:
  - Create `.TODO/CHAT_REALTIME_CONTRACT_2026-03-01.md` for snapshot semantics, dedupe, ordering, and refresh fallback.
- Output artifact:
  - Realtime contract doc
- Stop condition:
  - One merge path exists for each stream and tests are mapped to it.

### 7) Remove stale notification-removal work

- Goal:
  - Keep the plan aligned with current code.
- Why:
  - The current Chat service no longer performs client notification creation.
- How:
  - Delete that task from the execution plan and replace it with a search-based verification task.
- Output artifact:
  - Updated plan task list
- Stop condition:
  - The plan contains no obsolete Chat-specific notification removal work.

### 8) Add UI state matrix and selector inventory

- Goal:
  - Make UI hardening testable and reviewable.
- Why:
  - Error/retry/archive/manual-refresh behavior will otherwise drift by screen.
- How:
  - Add explicit widget keys and state expectations for `MessagesScreen` and `ChatScreen`.
- Output artifact:
  - Selector inventory + widget task list
- Stop condition:
  - Every new UI state is addressable in tests.

### 9) Add PR slicing and release gates

- Goal:
  - Reduce rollback blast radius.
- Why:
  - DB, app, and docs should not ship as a single opaque bundle.
- How:
  - Split into reviewable slices: contracts/data audit, security SQL, app layer, UI/tests/docs.
- Output artifact:
  - PR/release checklist
- Stop condition:
  - The release path is staged and reversible.

## H) Corrected Plan (Execution-Ready, Gate-Based)

### Phase 0: Test Infrastructure + Decision Lock

- Goal:
  - Freeze the contract and make the fix testable before implementation.
- Why:
  - Ambiguity and missing harnesses will invalidate every later step.
- How:
  - Add Chat decisions, Chat test strategy, selector inventory, and rollout matrix.
- Result:
  - The team can implement against one approved contract and one test/release baseline.
- GATE CHECK:
  - Do not start SQL or Flutter edits until the blocking decisions and Chat test strategy exist.

### Phase 1: Data/Contracts Audit

- Goal:
  - Inventory live data and align the app contract to backend truth.
- Why:
  - Historical data and wrong assumptions are the highest migration risk.
- How:
  - Run audits for messages, offers, conversations, attachments, and method naming drift.
- Result:
  - Contract changes are based on evidence, not assumptions.
- GATE CHECK:
  - Do not author migrations until outliers are classified and compatibility rules are defined.

### Phase 2: Security/RLS/Storage

- Goal:
  - Remove broad access and replace it with least-privilege behavior.
- Why:
  - Live Chat currently leaks beyond intended participant boundaries.
- How:
  - Add helper/RPC objects first, stage policy replacements, validate allow/deny results, then remove weak policies.
- Result:
  - Participant-only access for messages and attachments; no client-authority gaps.
- GATE CHECK:
  - Do not merge app-layer dependency changes until RLS/storage matrix passes.

### Phase 3: Backend/App Layer

- Goal:
  - Make Flutter follow the locked contract and backend capabilities.
- Why:
  - Current message types, payload keys, archive writes, and realtime handling are not backend-accurate.
- How:
  - Normalize models, add typed payloads, rename misleading APIs, use archive RPC, and fix stream merge logic.
- Result:
  - App writes only valid contracts and handles realtime deterministically.
- GATE CHECK:
  - Do not start UI polish until services/viewmodels pass unit coverage and integration smoke checks.

### Phase 4: UI/Integration

- Goal:
  - Make Chat UX correct under loading, error, retry, archive, and fallback conditions.
- Why:
  - Current UI hides failures and assumes capabilities that are not guaranteed.
- How:
  - Add explicit states, disable/draft preservation rules, offer gating, and refresh fallback behavior.
- Result:
  - Predictable user behavior across message list, thread, booking entry, and deep-link entry.
- GATE CHECK:
  - Do not enter release until widget/integration/manual scenarios pass.

### Phase 5: QA + Release + Docs

- Goal:
  - Prove live correctness and leave no drift behind.
- Why:
  - This feature spans app, DB, storage, and docs.
- How:
  - Run automated and manual checks, validate live SQL state, then update docs from the final live truth.
- Result:
  - A releasable Chat fix with clear rollback conditions.
- GATE CHECK:
  - Release only after post-change live re-scan, docs sync, and rollback evidence capture.

## I) Change Report (Diff-Style)

### 1) Original issues summary

- The original plan was directionally correct but not execution-safe.
- It identified the right classes of problems, but left core product/security decisions unresolved.
- It did not separate additive compatibility work from destructive policy cleanup tightly enough.
- It carried at least one stale work item from an older repo state.

### 2) Added steps

- Blocking decision pack
- Live data audit pack
- Pre-change RLS/storage matrix gate
- Compatibility rollout matrix
- Chat-specific test strategy
- Realtime contract task
- UI state matrix and selector inventory
- PR slicing and release gate checklist

### 3) Removed steps

- Remove client-side Chat notification creation from the send path

### 4) Reordered steps (from -> to)

- `Security cleanup before data audit` -> `data audit before security cleanup`
- `General QA after implementation` -> `test infrastructure gate before implementation`
- `Possible realtime publication change during app refactor` -> `fallback-first strategy before optional realtime expansion`
- `Docs update as closing task only` -> `docs update after live re-scan and release proof`

### 5) Expanded steps (what became more detailed)

- Contract lock now names explicit blocking decisions.
- Migration work now includes pre-change capture, additive rollout, validation, and destructive removal order.
- Testing now distinguishes existing baseline from missing Chat-specific coverage.
- Release work now includes PR slicing, deploy order, and rollback thresholds.

### 6) Why (short, practical)

- The original plan could still ship the wrong contract or break valid users during policy tightening.
- The corrected version reduces ambiguity, removes stale work, and forces proof before destructive changes.

### 7) Residual risks

- Product may choose a broader DM or offer policy later, which would require a second backend change set.
- Historical attachment objects may still need special handling if path drift is worse than expected.
- Optional conversation-list realtime should remain a separate risk-controlled expansion unless the product requires it immediately.
