# Plan Critique: HomeDiscoveryNavConsolidation

## A) Assumptions + Decision Needed (Blocking)

### Assumptions

- The user wants Tenders and Bookings removed from the bottom navigation, not deleted from the app.
- Existing standalone `TendersScreen` and `BookingsDiscoveryScreen` can remain as non-bottom-nav surfaces.
- Wallet is currently not visible in bottom nav and should remain out of the bottom nav.
- Home mode filtering can reuse `TaskFilterViewModel.filteredTasks`; no new query or backend contract is required.
- The integration test environment may not be available locally, so targeted widget tests are mandatory and integration skips must be recorded.

### Decision Needed (Blocking)

1. Discovery row `All` label
   - Missing decision: whether to show `All` or avoid conflict with the category-row `All`.
   - Options: `All`, `All Work`, `Everything`.
   - Recommended: `All Work`.
   - Why: prevents two adjacent `All` chips with different meanings.
   - Plan impact: Home tests and integration selectors expect `All Work`.

2. Navigation source of truth
   - Missing decision: keep scattered integer indexes or create named visible-nav indices.
   - Options: scattered literals, shared visible-nav helper/constants, expand `NavView`.
   - Recommended: shared visible-nav helper/constants.
   - Why: `NavView` includes hidden Wallet and legacy `orders`; scattered literals caused the current risk.
   - Plan impact: main shell, bottom nav, profile deep link, and tests use named visible indices.

3. Removed nav keys
   - Missing decision: keep `tendersNavKey`/`bookingsNavKey` as deprecated hidden keys or remove them.
   - Options: keep deprecated keys, remove keys after tests update.
   - Recommended: remove keys after replacing all references.
   - Why: hidden destination keys invite future tests/code to target removed nav items.
   - Plan impact: integration test moves to Home discovery chip keys.

## B) Gate Status

| Gate | Original Status | Reason | Fix in Corrected Plan |
|---|---:|---|---|
| Gate 0: Test Infrastructure Gate | FAIL | Tests were listed, but selector strategy and deterministic task fixtures were not front-loaded. | Added Phase 0 for harness, keys, and fixtures. |
| Data / Contracts Gate | PASS | No data model changes are required. | Added invariant that Home filters existing ViewModel data only. |
| Security / RLS Gate | PASS | No new backend access or storage access is planned. | Added no-Supabase View/ViewModel invariant checks. |
| Backend / Supabase Gate | PASS WITH WATCH | Original plan noted drift but did not make no-backend-change enforceable. | Added no `supabase/` diff invariant and backend stop condition. |
| UI / Integration Gate | FAIL | UI steps lacked skill tags, audit details, duplicate `All` decision, and responsive/accessibility audit. | Added dedicated UI phase, skill tags, visual audit, and `All Work` decision. |
| Release / QA Gate | FAIL | Original plan had tests but weak release evidence, no stale grep gate, and optional integration handling was too loose. | Added static verification, targeted commands, session log update, and rollback scope. |

## C) Critical Gaps (Must-Fix)

### Gap 1: Visible navigation contract was not locked

- Why it will break: removing two nav items while using positional indexes can make Dashboard, Messages, or Profile open the wrong screen.
- Fix: add named visible-nav indices and use them in bottom nav, main shell, deep links, and tests.
- Owner: Frontend / Architecture.
- Acceptance check: `setCurrentIndex(1)` renders Dashboard; Profile deep link selects Profile.

### Gap 2: Original plan left Wallet ambiguous

- Why it will break: the current screen list includes Wallet but the bottom nav does not render it; a careless rewrite could delete hidden behavior or add Wallet accidentally.
- Fix: explicitly keep Wallet out of bottom nav and verify no current runtime code uses `setCurrentIndex(6)`.
- Owner: Product / Architecture.
- Acceptance check: stale-reference grep has no unexpected Wallet/index hits.

### Gap 3: Home discovery labels were ambiguous

- Why it will break: Home already has an `All` category chip; a second `All` chip creates unclear UI behavior.
- Fix: use `All Work` for the discovery mode.
- Owner: Product / UI.
- Acceptance check: Home renders `All Work`, `Bookings`, `Tenders`, and category `All` remains distinct.

### Gap 4: Test infrastructure was not treated as a gate

- Why it will break: tests will fail late when old `tendersNavKey` references disappear.
- Fix: add Home discovery keys and update integration selectors before removing keys.
- Owner: QA / Frontend.
- Acceptance check: integration test no longer references `CustomBottomNavBar.tendersNavKey`.

### Gap 5: UI audit was too vague

- Why it will break: the implementation can pass tests while visually clipping labels or crowding Home.
- Fix: add visual, accessibility, and responsive audit phase with session-log evidence.
- Owner: UI / QA.
- Acceptance check: session log records bottom-nav and Home chip audit results.

### Gap 6: Backend no-change rule was not enforceable

- Why it will break: Supabase drift exists; accidental backend edits would be risky and unrelated.
- Fix: add explicit invariant and grep that no `supabase/` files change.
- Owner: Backend / QA.
- Acceptance check: `git diff --name-only | rg "^supabase/"` has no implementation hits.

## D) Invariants & Success Criteria (Non-Negotiable)

- No View imports or calls Supabase directly.
  - Enforce: Home filters existing `filteredTasks`.
  - Verify: grep Home/navigation views for Supabase imports/calls.
- No ViewModel adds direct Supabase access for this change.
  - Enforce: do not edit ViewModel data access paths.
  - Verify: diff review.
- Sensitive table access remains protected by existing RLS.
  - Enforce: no new query path.
  - Verify: no service/repository changes.
- Critical booking/tender lifecycle transitions remain server-enforced.
  - Enforce: no lifecycle logic changes.
  - Verify: no task/booking service transition changes.
- DB stores storage paths, not signed URLs.
  - Enforce: no storage model changes.
  - Verify: no storage file diffs.
- AppLogger is used instead of `print()`.
  - Enforce: logging steps require `AppLogger`.
  - Verify: diff grep.
- Query shapes remain bounded and index-supported.
  - Enforce: no new query.
  - Verify: no service/repository diff.
- Task template/create-task flows remain intact.
  - Enforce: FAB unchanged, integration test updated around new discovery surface.
  - Verify: create tender integration path or documented skip.

## E) Risk Register

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|---|---|---:|---:|---|---|---|---|
| Dashboard opens old Tender screen | Main nav index mapping | High | High | All users | `setCurrentIndex(1)` test fails | Named visible indices | Revert main nav and bottom nav together |
| Profile deep link opens wrong tab | Profile deep-link handler | Medium | High | Deep-link users | Profile link lands on Messages/Home | Use named Profile index | Revert handler with old nav order |
| Duplicate `All` chips confuse users | Home UI | High | Medium | Home discovery | Visual audit flags ambiguity | Use `All Work` | Rename chip |
| Integration test fails after key removal | Integration test | High | Medium | CI | missing `tendersNavKey` compile error | Add Home discovery keys first | Temporarily keep deprecated key until test rewrite |
| Visual clipping on small devices | Bottom nav/Home chips | Medium | Medium | Mobile UX | clipped labels/screenshots | Horizontal chip row and audit | Adjust spacing/font within existing tokens |
| Accidental backend edit during drift | Supabase files | Low | High | DB/release | `git diff --name-only` shows `supabase/` | No-backend invariant | Remove backend changes and split plan |
| Standalone discovery screen tests regress | Existing screens | Medium | Low | Test suite | tenders/bookings widget tests fail | Keep standalone screen logic untouched | Fix only imports/providers |
| Stale hidden Wallet index crashes shell | Main nav | Low | Medium | Rare programmatic nav | stale-index test fails | Clamp and normalize invalid indices | Render Home on invalid index |

## F) Pre-Mortem

- This fails when the bottom nav removes Tenders/Bookings but `MainNavigationScreen` still uses the old screen list.
- This fails when Dashboard is assumed to remain index `3`.
- This fails when profile deep links keep calling `setCurrentIndex(5)`.
- This fails when tests still import `CustomBottomNavBar.tendersNavKey` after the key is removed.
- This fails when Home shows two `All` chips and users cannot tell mode filtering from category filtering.
- This fails when the executor adds service calls from Home instead of filtering existing ViewModel data.
- This fails when a stale index causes `screens[currentIndex]` to throw.
- This fails when visual review is skipped and the four-item nav/FAB overlap is not caught.

## G) Plan Fixes (Concrete Additions / Expansions)

### Fix 1: Add Test Infrastructure Gate

- Goal: prepare keys, fixtures, and selectors.
- Why: old nav keys are being removed.
- How: add Home discovery keys and fixture strategy before test rewrites.
- Output artifact: updated corrected plan Phase 0.
- Stop condition: all tests have stable selectors.

### Fix 2: Add Visible-Nav Contract

- Goal: remove index ambiguity.
- Why: `NavView` includes hidden and legacy entries.
- How: add visible-nav constants/helper and use everywhere.
- Output artifact: updated corrected plan Phase 1.
- Stop condition: grep has no stale bottom-nav index assumptions.

### Fix 3: Resolve `All` Label Ambiguity

- Goal: prevent duplicate `All` chips.
- Why: Home already has category `All`.
- How: use `All Work`.
- Output artifact: corrected UI requirements.
- Stop condition: tests assert `All Work` discovery chip.

### Fix 4: Add UI Audit Phase

- Goal: verify actual rendering.
- Why: visual change is the core request.
- How: add visual/accessibility/responsive audit and session log evidence.
- Output artifact: updated corrected plan Phase 8.
- Stop condition: audit recorded.

### Fix 5: Add Backend No-Change Enforcement

- Goal: avoid accidental Supabase work.
- Why: remote/local drift exists.
- How: add `git diff --name-only | rg "^supabase/"` check.
- Output artifact: invariant and static verification phase.
- Stop condition: no backend diffs.

## H) Corrected Plan (Execution-Ready, Gate-Based)

Corrected plan reference:

- `.TODO/PLAN_HomeDiscoveryNavConsolidation_2026-04-30.md`

The corrected plan rewrites the work into:

- Phase 0: Test Infrastructure Gate
- Phase 1: Navigation Contract Gate
- Phase 2: Main Shell Implementation
- Phase 3: Bottom Navigation Implementation
- Phase 4: Home Discovery Mode UI
- Phase 5: Deep Links and Stale Reference Cleanup
- Phase 6: Test Rewrite and New Coverage
- Phase 7: Static Verification
- Phase 8: Visual, Accessibility, and Responsive Audit
- Phase 9: Release QA and Rollback Readiness

## I) Change Report (Diff-Style)

### 1. Original issues summary

- Plan had correct high-level scope but left too many execution decisions open.
- Navigation source of truth was optional instead of required.
- UI phase was present but not audit-grade.
- Test infrastructure was not a gate.
- Backend no-change rule was not mechanically verified.

### 2. Added steps

- Added locked product decisions.
- Added non-negotiable invariants.
- Added test infrastructure gate.
- Added visible-nav contract phase.
- Added stale-index normalization details.
- Added Home discovery keys.
- Added fixture strategy for Home filtering tests.
- Added explicit visual/a11y/responsive audit.
- Added backend no-change grep.
- Added session-log update requirements.

### 3. Removed steps

- Removed optional wording that allowed either `All` or `All Work`.
- Removed reliance on `NavView.values.length`.
- Removed ambiguity around Wallet as a visible bottom-nav candidate.

### 4. Reordered steps

- Test infrastructure moved before implementation.
- Navigation contract moved before `MainNavigationScreen` and `CustomBottomNavBar` edits.
- Stale reference cleanup moved before test execution.
- Visual audit moved before release QA.

### 5. Expanded steps

- Bottom-nav change expanded into metadata, tap behavior, and layout audit.
- Home UI change expanded into keys, state, metadata, rendering, filtering, logging, and semantics.
- Test phase expanded by test file and behavior.
- Release phase expanded into commands, session logging, and rollback scope.

### 6. Why

- The original plan could still produce a build that compiles but opens wrong screens.
- It could also leave fragile tests and ambiguous Home UI.
- The corrected plan closes those failure paths before implementation starts.

### 7. Residual risks

- Integration test may be skipped if credentials/environment are unavailable.
- Existing remote/local Supabase migration drift remains outside this UI plan.
- Standalone Tenders/Bookings screens remain in code and may require future product cleanup if no longer routeable.
