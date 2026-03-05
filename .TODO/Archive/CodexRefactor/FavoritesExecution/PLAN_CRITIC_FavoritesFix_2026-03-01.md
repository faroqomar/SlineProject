## A) Assumptions + Decision Needed (Blocking)

### Assumptions
- The target feature remains a live user-facing `favorites` surface with cross-feature entry points from Public Profile and Task Requests. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/view/favorites_screen.dart:12-138`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/profile/view/public_profile_screen.dart:138-165`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:93-129`.
- Existing Flutter test infrastructure is the baseline to extend, not replace. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/test_support/pump_app.dart:5-18`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/integration_test/support/helpers.dart:19-128`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/pubspec.yaml:59-63`.
- Live Supabase is the real contract for `favorites` and direct-DM authorization, and docs are secondary when drift exists. Live scan: `public.favorites` table/policies/indexes, `public.conversations` policy `conversations_insert_client_only`, function `public.conversations_before_insert_guard()`.
- The implementation must preserve MVVM: views do not call Supabase/services directly. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/DEVELOPER_GUIDE.md:56-66`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:112-119`.

### Decision Needed (Blocking)
1. Missing decision: canonical direct-DM authorization rule for this fix.
- Options:
  - Keep direct DMs favorites-gated.
  - Remove favorites gate from direct DMs.
- Recommended: keep direct DMs favorites-gated for this fix.
- Why: live `conversations_insert_client_only` policy already enforces it, `MVP_ROADMAP.md` still describes “Favorites-powered contact flows” as implemented, and changing this now expands scope into chat product behavior. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/MVP_ROADMAP.md:63-66`, live scan: `conversations_insert_client_only`.
- Plan impact:
  - If kept: fix drift by aligning docs/comments/trigger text to live policy.
  - If removed: this stops being a favorites repair and becomes a product/security change across chat policy, docs, and QA.

2. Missing decision: success/error contract for favorites mutations.
- Options:
  - Keep side-channel `vm.error` and `Future<void>` methods.
  - Return `bool` from add/remove.
  - Return a typed mutation result object/enum.
- Recommended: return a typed mutation result object/enum.
- Why: `bool` is too lossy for duplicate/not-authenticated/forbidden cases, and `Future<void>` already causes false-success UI. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/viewmodels/favorites_view_model.dart:52-85`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/view/favorites_screen.dart:123-128`.
- Plan impact:
  - If `Future<void>` remains: callers will continue to guess success from side effects.
  - If `bool`: duplicate/forbidden/auth failures collapse into one branch.
  - If typed result: UI and tests can make deterministic decisions.

3. Missing decision: release slicing.
- Options:
  - One PR for app + tests + docs + optional DB reconcile.
  - Two PRs: app/tests first, docs/DB reconcile second.
  - Three PRs: contracts/test infra, app fixes/tests, docs/DB reconcile/release gate.
- Recommended: three PRs.
- Why: the fix spans live DB drift, provider ownership, UI behavior, and new tests. One PR is hard to review and hard to roll back. References: live drift between `conversations_insert_client_only` and `conversations_before_insert_guard()`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/main.dart:172-175`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/view/favorites_screen.dart:19-40`.
- Plan impact:
  - One PR: fastest, weakest rollback.
  - Two PRs: acceptable if no SQL change lands.
  - Three PRs: safest and easiest to gate.

## B) Gate Status (Pass/Fail)

### Gate 0: Test Infrastructure Gate
- Status: ❌ FAIL
- Reason:
  - The plan adds unit/widget/integration tests but does not create a favorites-specific harness plan, fixture manifest, or selector/key map.
  - Existing harnesses exist, but favorites entry points currently expose no stable keys. Evidence: repo scan `rg -n "Key\(|ValueKey|ObjectKey|GlobalKey|static const .*Key" lib/features/favorites lib/features/profile/view/public_profile_screen.dart lib/features/tasks/view/widgets/requests/widgets/request_tile.dart` returned no hits.
  - Integration test support exists, but no favorites-specific staging data contract is defined. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/integration_test/support/helpers.dart:23-128`.
- What to add/fix to pass:
  - Add a Test Infrastructure Gate before contract or app work.
  - Add a selector/key map, fixture manifest, runbook, bounded waits, and failure artifact policy.

### Gate 1: Data/Contracts Gate
- Status: ❌ FAIL
- Reason:
  - The plan recognizes parser nullability and DM drift, but it does not make the DM rule and mutation contract explicit blocking artifacts.
  - It does not lock the joined favorites response contract (root `freelancer_id` fallback + missing joined profile behavior) before model/service changes.
  - It does not define one typed caller contract for add/remove success vs duplicate vs forbidden vs unauthenticated.
- What to add/fix to pass:
  - Add a blocking DM decision file.
  - Add a joined-response contract artifact.
  - Add a typed mutation-result decision before UI rewrites.

### Gate 2: Security Gate
- Status: ❌ FAIL
- Reason:
  - The plan treats live doc/code/DB drift as work to reconcile, but not as a release blocker with explicit verify queries and go/no-go criteria.
  - It does not specify the exact negative checks for cross-user favorites access, duplicate add, and DM without favorites under the canonical rule.
  - It does not define the provenance strategy for missing source-controlled favorites SQL.
- What to add/fix to pass:
  - Add a release-blocking security matrix and SQL verify checklist.
  - Add a provenance note for `favorites` schema/policies missing from `supabase/migrations/`.
  - Add explicit negative tests and manual SQL checks.

### Gate 3: Backend/API Gate
- Status: ❌ FAIL
- Reason:
  - The plan says “reconcile trigger/policy/comments” but does not choose whether the fix is docs-only, SQL-only, or both under the locked DM rule.
  - It does not define idempotency and error taxonomy for add/remove mutations beyond generic intent.
  - It does not specify whether the service will keep dual-query loading or move to a single joined response as the canonical read path.
- What to add/fix to pass:
  - Add a direct decision tree for DB reconcile.
  - Add a mutation error/idempotency matrix.
  - Add a single canonical read-path decision.

### Gate 4: UI/Integration Gate
- Status: ❌ FAIL
- Reason:
  - The plan does not include a UI state matrix for favorites screen, public profile toggle, and request-tile action paths.
  - It does not explicitly require stable selectors/keys for the screens it wants to test.
  - It does not define the exact post-action UI behavior for duplicate add, forbidden add, unauthenticated add, remove failure, or chat-start failure.
- What to add/fix to pass:
  - Add a UI state matrix artifact.
  - Add stable keys/selectors.
  - Add acceptance criteria for each visible error/success state.

### Gate 5: Release/QA Gate
- Status: ❌ FAIL
- Reason:
  - The plan has no branch/PR slicing rule, review checklist, rerun policy, or failure artifact path.
  - It does not define a final release gate tying together SQL verification, widget/unit/integration evidence, and docs sync.
  - It lacks a fast-fail staging preflight for favorites-specific integration tests.
- What to add/fix to pass:
  - Add PR slicing, reviewer checklist, and go/no-go release criteria.
  - Add a favorites-specific staging fixture/preflight contract.
  - Add rerun thresholds and failure artifact capture notes.

## C) Critical Gaps (Must-Fix)

### Gap 1
- Gap: No Test Infrastructure Gate.
- Why it will break: tests are scheduled, but the plan does not define selectors, fixtures, or failure artifacts first.
- Fix (exact step(s) to add / reorder):
  - Add `Phase 0.0 Test Infrastructure Gate` before all contract work.
  - Create `.TODO/TEST_INFRA_Favorites_2026-03-01.md` and `.TODO/FIXTURES_Favorites_2026-03-01.md`.
- Owner: Frontend
- Acceptance check: stable selectors, fixture manifest, run commands, and timeout/retry rules exist before new tests are written.

### Gap 2
- Gap: Direct-DM rule is not locked as a blocking decision.
- Why it will break: docs, trigger comments, and live policy already disagree.
- Fix (exact step(s) to add / reorder):
  - Add `.TODO/DECISION_Favorites_DM_2026-03-01.md` in Phase 0 and block implementation until it is written.
- Owner: Product
- Acceptance check: one canonical DM rule is documented and reused by DB/app/docs tasks.

### Gap 3
- Gap: Joined favorites response contract is underspecified.
- Why it will break: parser fixes can still regress if the service shape is not locked first.
- Fix (exact step(s) to add / reorder):
  - Add `.TODO/CONTRACT_FavoritesJoin_2026-03-01.md` with required fields, nullability, and placeholder behavior.
- Owner: Backend
- Acceptance check: model parser, service query, and widget fallback all align to one contract.

### Gap 4
- Gap: Mutation success/error contract is too vague.
- Why it will break: `FavoritesScreen` already demonstrates that `Future<void>` plus `vm.error` produces false success.
- Fix (exact step(s) to add / reorder):
  - Add a blocking contract step choosing a typed mutation result and list every consumer to update.
- Owner: Backend
- Acceptance check: `add` and `remove` return deterministic results that UI and tests can assert.

### Gap 5
- Gap: No UI state matrix.
- Why it will break: the plan can still ship with inconsistent behavior between Favorites screen, Public Profile, and Request Tile.
- Fix (exact step(s) to add / reorder):
  - Create `.TODO/UI_STATE_MATRIX_Favorites_2026-03-01.md` before Phase 3 UI work.
- Owner: Frontend
- Acceptance check: each user-visible state has one expected render path and one test case.

### Gap 6
- Gap: No provenance strategy for missing favorites SQL in repo migrations.
- Why it will break: the team may try to “backfill” a fake migration or silently ignore the drift.
- Fix (exact step(s) to add / reorder):
  - Add a DB provenance note to the migration plan: no retroactive fake migration; only forward reconcile if live contract changes.
- Owner: Backend
- Acceptance check: plan explicitly says how repo/live DB drift is documented without unsafe retroactive SQL.

### Gap 7
- Gap: No PR slicing or release criteria.
- Why it will break: DB drift, UI wiring, provider unification, and tests in one stream are review-hostile.
- Fix (exact step(s) to add / reorder):
  - Add `.TODO/PR_PLAN_Favorites_2026-03-01.md` and a final release checklist.
- Owner: Product
- Acceptance check: work is split into reviewable slices with rollback points.

## D) Invariants & Success Criteria (Non-Negotiable)

1. Invariant: one shared `FavoritesViewModel` instance owns favorites state across app surfaces.
- How to enforce: remove screen-owned provider duplication and use the global provider only.
- How to verify: code review plus widget/integration tests across Favorites screen and Public Profile. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/main.dart:172-175`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/view/favorites_screen.dart:19-40`.

2. Invariant: missing joined profile rows never crash favorites load.
- How to enforce: contract + parser fallback on root `freelancer_id`.
- How to verify: unit test for joined row with `freelancer == null`. Reference: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/models/favorite_model.dart:65-73`.

3. Invariant: direct-DM authorization rule is identical across live DB policy, code comments, and docs.
- How to enforce: decision lock + DB reconcile/docs sync.
- How to verify: SQL policy/function checks plus docs diff. Live scan + `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/SUPABASE_SETUP.md:81-83`.

4. Invariant: remove success is shown only after successful persistence.
- How to enforce: typed mutation result or rethrow contract.
- How to verify: widget/unit tests and manual forced-failure scenario. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/viewmodels/favorites_view_model.dart:68-85`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/favorites/view/favorites_screen.dart:123-128`.

5. Invariant: widgets never call `FavoritesService` directly.
- How to enforce: callback/VM-only request tile wiring.
- How to verify: grep check `rg -n "FavoritesService\(" lib/features/tasks/view --glob '*.dart'`. Current violation: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:114-115`.

6. Invariant: tests are deterministic and fail fast on missing favorites fixtures.
- How to enforce: selector map, fixture manifest, bounded waits, preflight.
- How to verify: test infra docs and integration preflight execution. Reference: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/integration_test/support/helpers.dart:23-128`.

## E) Risk Register (Predict Problems)

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|------|-------|------------|--------|--------------|-------------|-----------|----------|
| Parser fix still crashes on partial join | `favorite_model.dart` | High | High | Feature | Favorites screen lands in error for one corrupted row | Lock joined contract and add null-join unit test | Temporary fallback to simple favorites list without joined profile |
| Shared-state refactor breaks profile/favorites sync | `main.dart`, `favorites_screen.dart`, `public_profile_screen.dart` | Med | High | Feature | Favorite icon differs across screens after mutation | Unify provider ownership and add cross-screen integration test | Revert provider refactor only, keep parser/error fixes |
| Request tile loses add-to-favorites behavior during MVVM cleanup | `request_tile.dart`, `requests_list_screen.dart` | Med | High | Feature | Offer list button stops working or no snackbar appears | Add callback contract and widget tests before removing fallback | Temporarily inject shared VM from parent with minimal UI change |
| DM rule drift remains unresolved after code fix | live `conversations` policy/function + docs | High | High | Security-breach | SQL verify output and docs still disagree | Block release on explicit DM decision + SQL verify | Freeze DM CTA while keeping favorites CRUD |
| No stable selectors leads to brittle widget/integration tests | favorites/profile/request tile UI | High | Med | Delivery | Tests depend on text/layout and fail after cosmetic changes | Add selector map before test authoring | Limit release gate to unit + manual evidence until selectors land |
| Missing fixtures make staging integration inconclusive | integration_test harness | Med | High | Delivery | Preflight fails late or tests hang on login/data setup | Create favorites fixture manifest and fast-fail preflight | Run manual staging SQL + scripted smoke test |
| Raw backend error still leaks in chat-start path | `favorites_screen.dart` | Med | Med | Feature | Snackbar includes `PostgrestException` or SQL text | Add sanitized UI copy and grep check | Replace with generic fallback string at release block |
| Release becomes unreviewable | mixed app/test/docs/DB changes | High | High | App-wide | Large PR with unclear rollback | Slice into 3 PRs with per-slice DoD | Ship only low-risk app fixes first |

## F) Pre-Mortem (How this fails in real life)
- This fails when the parser is “fixed” but the service still omits root `freelancer_id`, so a null join still crashes the screen.
- This fails when Favorites screen uses the global provider but Public Profile still assumes favorites are loaded without an `ensureLoaded()` contract.
- This fails when the team removes the `RequestTile` fallback but forgets to pass a callback/VM from `requests_list_screen`, leaving add-to-favorites dead in offers.
- This fails when docs say DMs do not require favorites, QA follows the docs, and production still rejects the insert because the live policy was never reconciled.
- This fails when widget/integration tests are added without selectors and become text-fragile, so they get ignored before release.
- This fails when release combines provider refactor, parser changes, docs edits, and optional SQL reconcile in one PR and rollback becomes impossible.

## G) Plan Fixes (Concrete Additions / Expansions)
1. Goal: add a Test Infrastructure Gate.
- Why: the current plan schedules tests without the prerequisites.
- How: create `TEST_INFRA_Favorites`, `FIXTURES_Favorites`, and a selector map before new tests.
- Output artifact: test harness/helper and fixture manifest docs.
- Stop condition: favorites test prerequisites exist and are reviewable.

2. Goal: lock the direct-DM rule.
- Why: live DB and docs disagree.
- How: create `DECISION_Favorites_DM` and require SQL verify output in release gate.
- Output artifact: decision doc + verify checklist.
- Stop condition: one canonical DM rule is recorded and reused everywhere.

3. Goal: lock joined favorites response semantics.
- Why: parser, service, and widget fallback must consume the same nullability contract.
- How: create `CONTRACT_FavoritesJoin` and update plan ordering so model/service work waits on it.
- Output artifact: contract doc.
- Stop condition: root `freelancer_id`, joined profile nullability, and placeholder behavior are explicit.

4. Goal: define a typed favorites mutation result.
- Why: false-success UI is already present.
- How: add a mutation contract step and update all consumers around it.
- Output artifact: contract note + implementation target file list.
- Stop condition: caller behavior is deterministic for success/duplicate/forbidden/unauthenticated/failure.

5. Goal: add a UI state matrix.
- Why: three entry points currently risk diverging behavior.
- How: add `UI_STATE_MATRIX_Favorites` before Phase 3.
- Output artifact: state matrix doc.
- Stop condition: every visible state has one render path and one test.

6. Goal: make release reviewable.
- Why: app, docs, tests, and optional DB reconcile are too broad for one undifferentiated change.
- How: add PR slicing and final release gate.
- Output artifact: PR plan + release checklist.
- Stop condition: each slice has explicit rollback.

## H) Corrected Plan (Execution-Ready, Gate-Based)

### Phase 0: Test Infrastructure Gate
- Goal: make favorites test work deterministic.
- Why: existing harnesses are reusable, but favorites-specific selectors and fixtures are missing.
- How:
  - Reuse `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/test_support/pump_app.dart:5-18` and `/Users/eros/Dev/Eros_Projects/Sline/sline_app/integration_test/support/helpers.dart:19-128`.
  - Add favorites/profile/request-tile selectors.
  - Add fixture manifest, runbook, timeout/retry budgets, and failure artifact path.
- Result: test work is executable before feature changes begin.
- GATE CHECK: selectors, fixtures, run commands, and preflight exist.

### Phase 1: Data/Contracts
- Goal: lock contracts before implementation.
- Why: parser and DM issues are contract drift problems.
- How:
  - Lock DM rule.
  - Lock joined favorites response contract.
  - Lock typed mutation contract.
  - Add UI state matrix.
- Result: one source of truth for DB/app/UI behavior.
- GATE CHECK: DM rule, joined contract, mutation contract, and state matrix are written.

### Phase 2: Security/RLS
- Goal: reconcile live DB behavior with the locked contract.
- Why: UI/app fixes are unsafe if policy/docs drift remains unresolved.
- How:
  - Re-scan live `favorites` and `conversations`.
  - Decide docs-only vs SQL reconcile for DM drift.
  - Add positive/negative RLS matrix and provenance note for missing favorites migration SQL.
- Result: live security behavior is explicit and release-blocking.
- GATE CHECK: SQL verify outputs and RLS matrix exist.

### Phase 3: App Layer + UI Wiring
- Goal: implement the favorites fix safely.
- Why: current runtime has split state, boundary leaks, and false-success UX.
- How:
  - Unify provider ownership.
  - Fix joined parser/service shape.
  - Replace `RequestTile` fallback with callback/VM wiring.
  - Introduce typed mutation result.
  - Add stable keys and state-driven UI feedback.
- Result: favorites works consistently across all entry points.
- GATE CHECK: no UI -> service call remains, no false success, no raw backend errors, no parser crash.

### Phase 4: QA + Release
- Goal: prove the fix is safe and shippable.
- Why: the feature crosses DB auth, app state, UI, and docs.
- How:
  - Add unit/widget/integration tests.
  - Run SQL verify + staging checks.
  - Sync docs and execute PR/release checklist.
- Result: release decision is evidence-based.
- GATE CHECK: tests pass, SQL verifies, docs match, PR slices are completed.

## I) Change Report (Diff-Style)
1. Original issues summary
- The original plan identified the right defects, but it was still optimistic about execution safety.
- It lacked a Test Infrastructure Gate, a blocking DM decision artifact, a UI state matrix, and a release slicing rule.

2. Added steps
- Test Infrastructure Gate
- DM decision artifact
- joined-response contract artifact
- typed mutation contract decision
- UI state matrix
- fixture manifest / selector map
- provenance note for missing favorites SQL
- PR slicing + release checklist

3. Removed steps (if any)
- Removed the implicit assumption that tests can be written safely later without upfront selectors/fixtures.
- Removed the implicit assumption that DM drift can be “reconciled later” without blocking release.

4. Reordered steps (from → to)
- Tests from late-phase implementation → upfront Test Infrastructure Gate.
- App/UI fixes before explicit contract lock → Data/Contracts first.
- Docs sync only at end without release gate → final gated release phase with SQL verify and PR slicing.

5. Expanded steps (what became more detailed)
- Mutation handling expanded into a typed result contract.
- Security work expanded into provenance, SQL verify, and explicit DM contract locking.
- QA work expanded into selectors, fixtures, bounded waits, and artifact policy.

6. Why (short, practical)
- The original plan would likely create motion but not reliable execution. These additions make the work reviewable, testable, and releasable.

7. Residual risks (what still remains risky even after fixes)
- Live `conversations` policy/index sprawl may still need a later dedicated cleanup.
- If product wants non-favorites direct DMs, that remains a separate contract change after this repair.
- Missing historical favorites migrations will remain a provenance/documentation risk unless separately backfilled via a safe forward documentation strategy.
