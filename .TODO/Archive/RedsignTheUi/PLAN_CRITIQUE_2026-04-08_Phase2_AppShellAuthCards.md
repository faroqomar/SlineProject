# Plan Critique: Phase 2 — App Shell, Auth & Cards
**Audited by:** @PlanCritic
**Date:** 2026-04-08
**Plan Under Review:** Phase 2 of UI Redesign (Master Plan phases 2, 3, 5)

---

## A) Assumptions + Decision Needed (Blocking)

### Assumptions
- Phase 0 (Design System Foundation) is **complete**: `app_motion.dart` (117 lines), `app_states.dart` (114 lines), `.impeccable.md`, semantic colors, elevation scale, component themes all exist.
- Phase 1 (Core Widget Redesign) is **complete**: `ScaleButton` (129 lines) upgraded with spring physics, `AppButton` with 8-state model, `GlassContainer` solid surface migration, etc.
- `package:animations` is **NOT available** (not in pubspec.yaml). All shared-axis / container-transform transitions must be hand-built using Flutter core APIs only.
- `dashboard_offer_card.dart` lives at `lib/features/tasks/view/widgets/` (528 lines), NOT under `dashboard/`.
- Login (321 lines) and Signup (371 lines) are currently `StatelessWidget` or minimal `StatefulWidget` — stagger animations require `StatefulWidget` with `AnimationController`.
- No existing widget tests for cards (only `test/widget/auth/login_screen_test.dart` exists for auth).
- `main.dart` uses named route map (`routes: routes`) — not `onGenerateRoute`. Route transition customization requires migrating to `onGenerateRoute` or a `Navigator 2.0` approach.

### Decision Needed (Blocking)

**DN-1: Route transition strategy**
- **What:** How to inject custom page transitions (`SlinePageRoute`) into the app's navigation.
- **Options:**
  1. Migrate `routes:` map to `onGenerateRoute` in `main.dart` (cleanest, standard Flutter pattern).
  2. Create wrapper `SlinePageRoute` that callers use instead of `MaterialPageRoute` at each push site.
  3. Keep named routes but add `pageRouteBuilder` to `MaterialApp.onGenerateRoute`.
- **Recommended:** Option 1 — `onGenerateRoute`. Centralizes transition logic. Named route map is already a lookup table; converting it is mechanical.
- **Plan impact:** Option 1 requires a dedicated sub-phase to migrate `main.dart` BEFORE any transition work.

**DN-2: Auth screen StatefulWidget conversion scope**
- **What:** Login and Signup need `AnimationController` for stagger entrance. Are these currently `StatelessWidget`?
- **Options:**
  1. Convert to `StatefulWidget` with manual `AnimationController` + `TickerProviderStateMixin`.
  2. Use implicit animations only (`AnimatedOpacity`, `AnimatedSlide`) with `Future.delayed` stagger — avoids StatefulWidget conversion but is less precise.
- **Recommended:** Option 1. Explicit controllers give precise timing and are more maintainable for complex stagger sequences.
- **Plan impact:** Adds a dedicated conversion sub-phase before animation work.

**DN-3: Message button in DashboardBookingCard**
- **What:** Currently has `TODO` for onPressed. What should it do?
- **Options:**
  1. Navigate to existing chat screen with the booking's conversation.
  2. Fire a callback (`onMessagePressed`) that the parent handles.
- **Recommended:** Option 2. Callbacks respect MVVM — the card widget should not know about navigation. Parent wires the callback to navigation.
- **Plan impact:** Card changes are smaller; parent screen needs a callback handler.

---

## B) Gate Status

### Gate 1: Data / Contracts Gate — ✅ PASS
- No database or contract changes in Phase 2. Pure UI/Flutter work.

### Gate 2: Security / RLS Gate — ✅ PASS
- No security boundary changes. Auth screens only change UI presentation, not auth logic.

### Gate 3: Backend / Supabase Gate — ✅ PASS (N/A)
- No Supabase changes in Phase 2.

### Gate 4: UI / Integration Gate — ❌ FAIL
- **Reason 1:** Route transition work (Phase 2.2 of Master Plan) requires `main.dart` migration to `onGenerateRoute` — this is missing as a prerequisite phase.
- **Reason 2:** Auth screens lack a StatefulWidget conversion sub-phase before animation implementation.
- **Reason 3:** `booking_task_card.dart` Transform.translate removal (477 lines) has regression risk for every caller — no caller audit step exists.
- **Reason 4:** `dashboard_offer_card.dart` is at `tasks/view/widgets/` not `dashboard/` — plan must reference correct path.
- **Fix:** Add prerequisite phases for route migration, auth conversion, and caller audits.

### Gate 5: Release / QA Gate — ❌ FAIL
- **Reason 1:** No widget test plan for auth screens (only 1 existing test: `login_screen_test.dart`).
- **Reason 2:** No regression test for card layout changes (removing 120px header, Transform.translate).
- **Reason 3:** No visual QA checklist for dark mode on all changed screens.
- **Fix:** Add dedicated test phases and visual QA checklist.

---

## C) Critical Gaps (Must-Fix)

### Gap 1: Missing `onGenerateRoute` migration
- **Why it will break:** `custom_route_transitions.dart` (117 lines, only has `SlideUpRoute` and `FadeRoute`) is not wired into the named route map. Without `onGenerateRoute`, custom transitions can only be used at individual push sites, defeating the purpose of `SlinePageRoute`.
- **Fix:** Add Phase 1 (before any UI work): migrate `main.dart` from `routes:` map to `onGenerateRoute` factory. Preserve all existing route definitions. Wire `SlinePageRoute` as the default transition.
- **Owner:** @Architect
- **Acceptance check:** All existing navigation works identically. `onGenerateRoute` is the single route resolution point.

### Gap 2: Auth StatefulWidget conversion not planned
- **Why it will break:** Stagger animations require `AnimationController` which requires `StatefulWidget` + `TickerProviderStateMixin`. If login_screen.dart is StatelessWidget, the animation code won't compile.
- **Fix:** Add explicit conversion sub-phase: convert LoginScreen and SignupScreen to StatefulWidget, add `TickerProviderStateMixin`, add `late AnimationController` fields, add `dispose()`.
- **Owner:** @Architect
- **Acceptance check:** Both screens compile, existing behavior unchanged, `dispose()` cleans up controllers.

### Gap 3: Transform.translate removal regression risk
- **Why it will break:** `booking_task_card.dart` uses `Transform.translate(offset: Offset(0, -24))` to overlap avatar on header. Removing this changes card height, which affects every screen that lays out this card (list views, grids). Without a caller audit, layouts may break.
- **Fix:** Add a caller audit step: grep for `BookingTaskCard` usage across all files, verify each caller's layout handles the new card height.
- **Owner:** @Pixel, @Sentinel
- **Acceptance check:** Every screen displaying BookingTaskCard renders correctly with new layout.

### Gap 4: `package:animations` not available
- **Why it will break:** Master Plan 2.2 references `OpenContainer` (container transform) and shared-axis transitions from `package:animations`. This package is NOT in pubspec.yaml.
- **Fix:** All transitions must be built with Flutter core APIs (`PageRouteBuilder`, `AnimatedBuilder`, `SlideTransition`, `FadeTransition`). Plan must NOT reference `OpenContainer` or `SharedAxisTransition`. Instead define `SlinePageRoute` factory with named constructors: `.forwardPush()`, `.modalSheet()`, `.fade()`.
- **Owner:** @Pixel
- **Acceptance check:** All transitions work without `package:animations`. No import of the package anywhere.

### Gap 5: No lint/analyze gate before execution
- **Why it will break:** If there are pre-existing analyzer warnings or errors, they'll be conflated with Phase 2 changes, making it impossible to verify clean completion.
- **Fix:** Add a Phase 0 pre-flight step: run `flutter analyze`, document baseline. If there are errors, fix them first.
- **Owner:** @Sentinel
- **Acceptance check:** `flutter analyze` returns 0 errors before Phase 2 work begins.

---

## D) Invariants & Success Criteria (Non-Negotiable)

| Invariant | How to Enforce | How to Verify |
|-----------|---------------|---------------|
| No View imports Supabase directly | Auth screens must not add Supabase imports. All data flows through ViewModel → Service → Repository. | `grep -r "import.*supabase" lib/features/auth/view/` returns 0 results. |
| No ViewModel imports Supabase directly | Auth ViewModels must use repositories only. | `grep -r "import.*supabase" lib/features/auth/viewmodel/` returns 0 results. |
| AppLogger instead of print() | No `print()` in any changed file. | `grep -rn "print(" <changed_files>` returns 0 results. |
| All animation durations use AppMotion tokens | No hardcoded `Duration(milliseconds:` in changed files. | `grep -rn "Duration(milliseconds:" <changed_files>` returns 0 results. |
| All shadows use AppDecorations.elevation() | No hardcoded `BoxShadow` in changed card files. | `grep -rn "BoxShadow(" <changed_card_files>` returns 0 results. |
| All status colors use semantic tokens | No hardcoded color hex values for status indicators. | Audit switch statements in card files for hardcoded `Color(0x` references. |
| Semantic labels on all interactive elements | Every tappable card and button has `Semantics` wrapper. | `grep -c "Semantics(" <changed_files>` > 0 for each file with interactive elements. |

---

## E) Risk Register

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|------|-------|------------|--------|--------------|-------------|-----------|----------|
| Typography line-height changes from Phase 0 cause card overflow | All card files | Medium | Medium | All card screens | Text clipping in cards during visual QA | Check card height constraints before modifying content | Add `overflow: TextOverflow.ellipsis` and `maxLines` to all text in cards |
| `onGenerateRoute` migration breaks deep links or saved routes | main.dart | Low | High | Entire app navigation | Screens unreachable after migration | Exhaustive test of every named route after migration | Revert to routes map; apply transitions per-push-site only |
| FAB hide-on-scroll causes jank on low-end devices | main_navigation_screen.dart | Medium | Low | Dashboard/home | Stuttering scroll on test device | Use `NotificationListener<ScrollNotification>` with throttle, not `ScrollController.addListener` | Remove hide-on-scroll, keep static FAB |
| Auth stagger animations delay perceived load time | login_screen.dart, signup_screen.dart | Low | Medium | First impression | Users perceive slowness | Keep total stagger under 600ms. First interactive element (email field) must be ready within 400ms. | Remove stagger, use single fade-in |
| Transform.translate removal changes card tap target area | booking_task_card.dart | Medium | Medium | Booking discovery, dashboard | Misaligned tap targets | Audit all `GestureDetector` / `InkWell` bounds after layout change | Use `Positioned` in Stack to preserve overlay without Transform |
| DashboardOfferCard 528-line file is too complex for single-pass redesign | dashboard_offer_card.dart | High | Medium | Dashboard offer cards | Execution agent loses track of changes | Break into 3 sub-phases: structure, styling, animation | Ship structure + styling first, animation in follow-up |

---

## F) Pre-Mortem (How This Fails In Real Life)

- This fails when the `onGenerateRoute` migration introduces a subtle route-name mismatch and a deep-linked screen becomes unreachable, discovered only in production.
- This fails when stagger animations on LoginScreen push the total load-to-interactive time past 1.5s and users on slow devices perceive the app as broken.
- This fails when removing the 120px header from TaskCard causes the task list's item extent estimator to break, making scroll position jump on re-visit.
- This fails when `booking_task_card.dart`'s Transform.translate removal changes the card's intrinsic height and a parent's `SizedBox` or `ConstrainedBox` clips the new layout.
- This fails when the DashboardOfferCard redesign (528 lines, 10+ conditional branches) introduces a state combination that was tested in the original but missed in the rewrite.
- This fails when `SlinePageRoute.modalSheet()` spring physics cause the sheet to overshoot on fast fling gestures, looking broken instead of premium.
- This fails when the FAB hide-on-scroll animation conflicts with the `MainNavigationScreen`'s `AnimatedSwitcher` tab transitions, causing double-animation jank.
- This fails when a card's semantic color lookup assumes `AppColorScheme` extensions are always available but a test harness doesn't provide them, causing null errors in widget tests.

---

## G) Plan Fixes (Concrete Additions / Expansions)

### Fix 1: Add Phase 1 — Pre-Flight & Route Foundation
- **Goal:** Clean analyzer baseline + migrate to `onGenerateRoute`.
- **Why:** All downstream phases depend on clean analyze and centralized route transitions.
- **How:** Run analyze, fix errors. Rewrite `main.dart` route resolution from `routes:` map to `onGenerateRoute`. Create `SlinePageRoute` factory in `custom_route_transitions.dart`.
- **Output artifact:** Updated `main.dart`, updated `custom_route_transitions.dart`.
- **Stop condition:** `flutter analyze` clean. All existing navigation works. `SlinePageRoute` compiles.

### Fix 2: Add Auth StatefulWidget Conversion Sub-Phase
- **Goal:** Convert LoginScreen and SignupScreen to StatefulWidget before animation.
- **Why:** AnimationController requires StatefulWidget + TickerProviderStateMixin.
- **How:** Convert class, add mixin, add controller fields, add dispose(), verify existing behavior unchanged.
- **Output artifact:** Converted screen files.
- **Stop condition:** Both screens compile, existing UI unchanged, dispose() present.

### Fix 3: Add Caller Audit Steps for Card Layout Changes
- **Goal:** Prevent regression from layout changes in TaskCard, BookingTaskCard, TenderTaskCard.
- **Why:** Card height changes affect every parent that displays them.
- **How:** Grep for card usage across codebase. Verify each parent's layout handles new card dimensions.
- **Output artifact:** Caller audit checklist in session log.
- **Stop condition:** Every caller verified, no layout overflow.

### Fix 4: Break DashboardOfferCard into 3 Sub-Phases
- **Goal:** Make the 528-line file manageable for execution agent.
- **Why:** Single-pass redesign of a 528-line file with 10+ conditionals is error-prone.
- **How:** Sub-phase 1: Extract `_OfferActionRow` widget. Sub-phase 2: Replace hardcoded colors with semantic tokens. Sub-phase 3: Add animations.
- **Output artifact:** Refactored file with extracted widget.
- **Stop condition:** Each sub-phase compiles clean. Visual output unchanged until animation phase.

### Fix 5: Add Widget Test Phase
- **Goal:** Test coverage for auth screens and card widgets.
- **Why:** Only 1 widget test exists (`login_screen_test.dart`). Card layout changes need regression tests.
- **How:** Write widget tests following Phase 1 test patterns. ~8 new test files.
- **Output artifact:** Test files in `test/widget/auth/` and `test/widget/cards/`.
- **Stop condition:** All tests pass. `flutter test` green.

---

## I) Change Report (Diff-Style)

### 1. Original Issues Summary
- Plan was missing: route migration prerequisite, StatefulWidget conversion, caller audits, `package:animations` alternative strategy, lint baseline, test coverage, and the DashboardOfferCard was too large for single-pass.

### 2. Added Steps
- Phase 1: Pre-Flight & Route Foundation (analyzer baseline + `onGenerateRoute` migration + `SlinePageRoute`)
- Auth StatefulWidget conversion sub-phase (before animation)
- Caller audit steps for all card layout changes
- DashboardOfferCard decomposed into 3 sub-phases (extract → tokens → animate)
- Widget test phase (~8 test files)
- Visual QA dark-mode audit step

### 3. Removed Steps
- All references to `OpenContainer` and `SharedAxisTransition` from `package:animations` — replaced with core Flutter alternatives.

### 4. Reordered Steps
- Route transitions (was planned as part of app shell) → moved to Phase 1 prerequisite.
- Card work split: structural changes first, then styling, then animation.

### 5. Expanded Steps
- Each auth screen gets individual sub-phases instead of grouped "Auth screens" bucket.
- Each card type gets individual sub-phases with skill tags and gate checks.
- DashboardOfferCard expanded from 1 phase to 3 sub-phases.

### 6. Why
- Execution safety. Each change must be independently verifiable. The original plan bundled too much into broad phases.

### 7. Residual Risks
- Typography line-height spillover from Phase 0 may cause subtle card text wrapping changes.
- Route migration is low-risk but high-blast-radius if wrong.
- The 528-line DashboardOfferCard may need further decomposition during execution.
