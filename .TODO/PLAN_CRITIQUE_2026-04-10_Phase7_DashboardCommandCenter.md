# @PlanCritic Audit: Phase 7 — Dashboard Command Center Redesign

**Plan Under Review:** `.TODO/PLAN_Phase7_DashboardCommandCenter_2026-04-10.md`
**Audit Date:** 2026-04-10
**Auditor:** `@PlanCritic`

---

## A) Assumptions + Decision Needed (Blocking)

### Assumptions (Inferred Safe Defaults)
1. **View-layer only is correct.** The master plan Phase 7 spec confirms Dashboard redesign is UI work. No ViewModel changes needed.
2. **Design system tokens are stable.** Phases 0-6 completed — tokens won't change during Phase 7 execution.
3. **`colorScheme.accent` maps to `AppColors.gold`.** Confirmed: `AppColorScheme.accent` is `AppColors.gold` in both light and dark factories (app_colors.dart:335, :391).
4. **Existing test count baseline is 1370 pass / 30 skip / 4 fail** (from Phase 6 session log).
5. **No new widget tests are required by this plan.** Token normalization and visual refinement don't need new tests beyond verifying existing ones pass.

### Decision Needed (Blocking)

**DN-1: `IntrinsicHeight` Performance in Next Actions Priority Bar**

- **What:** The plan (Phase 3, step 3.2.1) wraps each `WorkItemCard` in `IntrinsicHeight` + `Row` to make the priority left-bar match card height. `IntrinsicHeight` forces a two-pass layout — expensive in a list.
- **Options:**
  1. Use `IntrinsicHeight` (simple, works, but O(2n) layout per frame)
  2. Use `Container` decoration with a left `Border` on the card wrapper instead (zero extra layout cost)
  3. Use `Stack` with a positioned left bar (works but more complex)
- **Recommendation:** Option 2 — add a left `Border` to the card's `BoxDecoration` instead of an `IntrinsicHeight` wrapper. Zero performance cost, simpler code.
- **Plan change:** Replace Phase 3.2.1 implementation approach entirely.

**DN-2: Icon Size Reduction in Inbox Empty State (64→48)**

- **What:** Plan step 7.3.1 reduces inbox empty state icon from 64px → 48px (`AppLayout.iconFeature`). This is a noticeable visual change.
- **Options:**
  1. Use `AppLayout.iconFeature` (48px) for consistency with other empty states
  2. Keep 64px with a named constant (e.g., `_emptyStateIconSize = 64.0`) and comment
- **Recommendation:** Option 1. All other empty states (WorkTab, BookingsTab, ActivityFeed) already use `AppLayout.iconFeature`. Consistency wins.
- **Plan change:** None — keep as-is but add explicit "verify visual balance" verification step.

---

## B) Gate Status

### Gate 1: Data / Contracts Gate — ✅ PASS
- No data model or contract changes.
- ViewModel → View contracts unchanged.
- All Provider dependencies documented in appendix.

### Gate 2: Security / RLS Gate — ✅ PASS
- No security surface changes.
- View-layer only — no Supabase, no RLS, no auth boundary changes.

### Gate 3: Backend / Supabase Gate — ✅ PASS
- No backend work.
- Session log initialization present.
- No schema/diagram required (View-layer only).

### Gate 4: UI / Integration Gate — ❌ FAIL

**Reasons:**
1. **Test T58 will BREAK.** `dashboard_screen_test.dart:79` taps the settings button to open an `AlertDialog`, then finds role buttons inside it. Changing to `showModalBottomSheet` will break this test — the `pumpAndSettle` after `showDialog` vs `showModalBottomSheet` behaves differently, and the bottom sheet route is a different navigation route type.
2. **Missing per-phase `flutter analyze` gate.** Plan only runs `flutter analyze` in Phase 9. Token normalization across 13 files should verify analyze after EACH phase to catch issues early. A typo in Phase 3 shouldn't be discovered in Phase 9.
3. **Missing SnackBar color normalization.** Plan identifies `Colors.red` and `Colors.green` in inbox_tab.dart and next_actions_list.dart (Appendix hardcoded values table) but NO plan step addresses fixing them. These are raw Material colors that violate the token discipline.
4. **`AnimatedSize` + `ListView.builder(shrinkWrap: true)` risk.** Phase 4.2 wraps a shrinkWrap ListView in AnimatedSize. If the ListView rebuilds with different itemCount during the animation, AnimatedSize can clip or overflow. Missing: explicit `clipBehavior` parameter and test verification.
5. **Phase 4.2 modifies `overview_tab.dart` but Phase 4 claims to only modify `activity_feed_preview.dart`.** The "How" field is wrong — Phase 4 touches TWO files.
6. **No intermediate `flutter analyze` between Phase 3 (StatelessWidget→StatefulWidget conversion) and Phase 5.** This conversion is the highest-risk code change and should be verified immediately.

**Fixes Required:**
1. Add test update step to Phase 1 for T58 migration.
2. Add `flutter analyze` gate after each implementation phase (Phases 1-8).
3. Add explicit SnackBar color normalization steps to Phase 5 (next_actions_list) and Phase 7 (inbox_tab).
4. Add `clipBehavior: Clip.none` and explicit verification to Phase 4.2.
5. Fix Phase 4 "How" field to list both files.
6. Add analyze gate after Phase 3.

### Gate 5: Release / QA Gate — ✅ PASS (conditional)
- Rollback plan is clear and safe.
- No migrations or backend changes.
- **Conditional:** Passes only if Gate 4 fixes are applied.

---

## C) Critical Gaps (Must-Fix)

### GAP-1: Test T58 Will Break on Settings Migration
- **Gap:** `test/widget/dashboard/dashboard_screen_test.dart` test T58 opens `AlertDialog` via settings button. Changing to `showModalBottomSheet` will break this test.
- **Why it will break:** `showDialog` creates a `DialogRoute`; `showModalBottomSheet` creates a `ModalBottomSheetRoute`. The `pumpAndSettle` behavior, route dismissal, and widget tree structure differ. `find.byKey(DashboardScreen.clientRoleButtonKey)` may not find the button if it's in a different route/overlay.
- **Fix:** Add step 1.2.10 to Phase 1: Update `dashboard_screen_test.dart` test T58 to handle `showModalBottomSheet` instead of `showDialog`. Verify `pumpAndSettle` finds the bottom sheet, then tap role buttons. May need `tester.tap(find.text('Client'))` instead of key-based lookup if the bottom sheet renders in a different overlay.
- **Owner:** Frontend (@Pixel + @Sentinel)
- **Acceptance check:** `flutter test test/widget/dashboard/dashboard_screen_test.dart` passes all 3 tests.

### GAP-2: SnackBar `Colors.red` / `Colors.green` Not Addressed
- **Gap:** `next_actions_list.dart:171` uses `Colors.green`, lines 180 uses `Colors.red`. `inbox_tab.dart:51,59` uses `Colors.red`. These violate the "all colors use `colorScheme.*`" acceptance criterion (AC #12).
- **Why it will break:** Acceptance criterion 12 says "All dashboard widgets use `colorScheme.*` semantic tokens (not `AppColors.*`)". Raw `Colors.*` is even worse than `AppColors.*`. Plan will fail its own acceptance criteria.
- **Fix:** Add explicit steps:
  - Phase 3 (next_actions_list): Replace `Colors.green` → `colorScheme.success`, `Colors.red` → `colorScheme.danger` in SnackBar backgrounds.
  - Phase 7 (inbox_tab): Replace `Colors.red` → `colorScheme.danger` in SnackBar backgrounds.
- **Owner:** Frontend (@Pixel)
- **Acceptance check:** `grep -r "Colors\.\(red\|green\)" lib/features/dashboard/` returns zero matches.

### GAP-3: `AppLayout.avatarSmall / 2` Non-Const Expression
- **Gap:** Plan step 5.2.8 suggests using `AppLayout.avatarSmall / 2` as a radius value. `AppLayout.avatarSmall` is `static const double = 36.0`. While `36.0 / 2` is `18.0` and works as a const expression in Dart, it ONLY works in const contexts if both operands are const. In a `const CircleAvatar(radius: AppLayout.avatarSmall / 2)` this works. But if inside a non-const constructor, it's fine. Verify the usage context.
- **Why it will break:** If the executor tries to use it in a `const` widget constructor, it may not compile depending on Dart's const evaluation rules. More importantly, `AppLayout.avatarSmall / 2` is unclear — the intent is "avatar radius matching avatarSmall diameter". Better: introduce `AppLayout.avatarSmallRadius` or use a local constant.
- **Fix:** Use a local constant: `final avatarRadius = AppLayout.avatarSmall / 2;` in the build method. Clear intent, no const-context risk.
- **Owner:** Frontend (@Pixel)
- **Acceptance check:** `flutter analyze` passes.

### GAP-4: `AnimatedSize` Clipping Risk
- **Gap:** Phase 4.2 wraps `ActivityFeedPreview` in `AnimatedSize`. The feed uses `ListView.builder(shrinkWrap: true)`. During expand from 3 items to full list, the ListView height increases. If items rebuild during animation (e.g., ViewModel notifies), `AnimatedSize` may clip the overflow.
- **Why it will break:** `AnimatedSize` defaults to `clipBehavior: Clip.hardEdge`. During the animation between old and new size, content beyond the current animated height is clipped. If the user taps "See All" and new items load simultaneously, visual glitches occur.
- **Fix:** Add `clipBehavior: Clip.none` to `AnimatedSize`. Add explicit sub-step: "Verify that tapping See All while data is refreshing does not cause visual artifacts."
- **Owner:** Frontend (@Pixel)
- **Acceptance check:** Visual verification of expand/collapse during data refresh.

### GAP-5: Missing Per-Phase Analyze Gates
- **Gap:** `flutter analyze` only runs in Phase 9. 13 files across 8 implementation phases with no intermediate verification.
- **Why it will break:** A type error in Phase 3 (StatelessWidget→StatefulWidget conversion) won't be caught until Phase 9. By then, 5 more phases may have accumulated errors, making debugging harder.
- **Fix:** Add `flutter analyze` step at the end of each implementation phase's GATE CHECK (Phases 1-8).
- **Owner:** @Sentinel
- **Acceptance check:** Every GATE CHECK includes `flutter analyze` clean.

### GAP-6: Phase 4 "How" Field Incorrect
- **Gap:** Phase 4 says "Modify `activity_feed_preview.dart` only" but Phase 4.2 modifies `overview_tab.dart` (wrapping in `AnimatedSize`).
- **Why it will break:** Executor may skip reading `overview_tab.dart` before modifying it.
- **Fix:** Update Phase 4 "How" field to: "Modify `activity_feed_preview.dart` and `overview_tab.dart`."
- **Owner:** @SlinePlanner
- **Acceptance check:** "How" field lists both files.

---

## D) Invariants & Success Criteria (Non-Negotiable)

### INV-1: No View imports Supabase directly
- **Enforce:** `grep -r "supabase_flutter\|Supabase.instance" lib/features/dashboard/view/` returns zero matches.
- **Verify:** Phase 9.2 architecture guard.

### INV-2: No ViewModel imports Flutter widgets
- **Enforce:** `grep -r "import.*material\|import.*widgets" lib/features/dashboard/viewmodels/` returns zero matches.
- **Verify:** Phase 9.2 architecture guard.

### INV-3: All colors use semantic tokens
- **Enforce:** `grep -r "AppColors\.\|Colors\.\(red\|green\|blue\|orange\|grey\)" lib/features/dashboard/view/` returns zero matches after Phase 8.
- **Verify:** Phase 9.2 token audit.

### INV-4: All animation durations use AppMotion tokens
- **Enforce:** `grep -r "Duration(milliseconds:" lib/features/dashboard/view/` returns zero matches.
- **Verify:** Phase 9.2 token audit.

### INV-5: All interactive elements have Semantics
- **Enforce:** Every tappable widget (InkWell, GestureDetector, button) has a Semantics wrapper or `tooltip`/`semanticLabel`.
- **Verify:** Phase 9.2 accessibility audit.

### INV-6: Existing tests continue to pass
- **Enforce:** `flutter test` baseline: 1370 pass / 30 skip / 4 fail. Phase 7 must not increase failures.
- **Verify:** Phase 9.3 test execution.

### INV-7: AppLogger discipline maintained
- **Enforce:** No `print()` or `debugPrint()` added. Existing `AppLogger` calls preserved.
- **Verify:** `grep -r "print\(\|debugPrint\(" lib/features/dashboard/view/` returns zero matches.

---

## E) Risk Register

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|------|-------|------------|--------|--------------|-------------|-----------|----------|
| Test T58 breaks after AlertDialog→BottomSheet | dashboard_screen_test.dart | **100%** | Medium | 1 test file | Test run after Phase 1 | Update test in Phase 1 | Revert settings change |
| AnimatedSize clips during expand | overview_tab.dart | Medium (40%) | Low | Visual glitch | Manual test during Phase 4 | `clipBehavior: Clip.none` | Remove AnimatedSize, use instant toggle |
| `colorScheme.warning` looks wrong in dark mode for gold items | counters_grid, work_item_card | Low (20%) | Medium | All counter/card widgets | Dark mode screenshot | Verify AppColorScheme.warning dark value | Revert to AppColors.gold for those specific uses |
| `AppLayout.avatarSmall / 2` non-const in const context | work_item_card.dart | Low (15%) | Low | 1 file | `flutter analyze` | Use local variable | Use raw `18.0` with comment |
| Stagger animation re-triggers on ViewModel notify | next_actions_list.dart | Medium (30%) | Low | Visual stutter | Test with pull-to-refresh | Guard with `_hasAnimatedEntrance` flag | Skip stagger, use instant render |
| Time grouping itemCount mismatch | activity_feed_preview.dart | Medium (35%) | Medium | Activity feed crash | Test with 0, 1, 3, 10 items | Pre-compute flat list of items+headers | Revert to ungrouped list |
| Cross-feature card changes break non-dashboard rendering | wallet/booking/tasks features | Low (15%) | High | 3 features | Visual check on wallet screen, booking screen | Check all render sites before modifying | Revert cross-feature changes |
| SnackBar colors missed in audit | next_actions_list, inbox_tab | **100% without fix** | Low | Token discipline | grep check | Add explicit steps | Add to Phase 9 remediation |

---

## F) Pre-Mortem (How This Fails In Real Life)

1. **This fails when** the executor implements Phase 1 bottom sheet, runs Phase 2-8, then discovers in Phase 9 that test T58 has been failing since Phase 1 — 8 phases of accumulated uncertainty about whether the bottom sheet actually works in test harness.

2. **This fails when** the executor replaces `AppColors.gold` → `colorScheme.warning` in counter cards, but `colorScheme.warning` in dark mode is a different shade of amber that looks wrong against the dark card background — noticed only in user testing, not in code review.

3. **This fails when** the executor adds `IntrinsicHeight` around WorkItemCard for the priority bar, and the dashboard overview becomes noticeably slower on older devices because IntrinsicHeight forces double layout passes on 3 cards inside a nested scroll.

4. **This fails when** the time grouping in Phase 4 miscounts items because the pre-computed list includes headers, but the stagger animation cache was built with the original item count — causing index-out-of-bounds on the cached `_slideAnimations` list.

5. **This fails when** `AnimatedSize` around the activity feed clips the last item during expand animation, making it look like the feed is broken — user taps "See All" and the 4th item appears cut in half for 300ms.

6. **This fails when** the executor modifies `dashboard_offer_card.dart` (626 lines, StatefulWidget with complex state), introduces a subtle regression in the offer action flow, and no test catches it because widget tests for the offer card don't exist.

7. **This fails when** the executor changes the inbox empty state icon from 64→48px, but the "No Proposals Yet" heading is still `AppTypography.h3` (not downgraded to h5), making the layout feel bottom-heavy with a small icon and large text.

8. **This fails when** the `screenHorizontalMargin` (24px) replacement in overview_tab changes the visual alignment with the TabBar area above (which uses 16px padding from the AppBar), creating a visible misalignment between the tab labels and the content below.

---

## G) Plan Fixes (Concrete Additions / Expansions)

### FIX-1: Add Test T58 Migration Step
- **Goal:** Update widget test to handle bottom sheet instead of dialog.
- **Why:** Test T58 uses `showDialog`-based assertions. Changing to `showModalBottomSheet` will break it.
- **How:** Add sub-step 1.2.10 in Phase 1: Read `test/widget/dashboard/dashboard_screen_test.dart`. Update `_pumpDashboardScreen` and T58 to `pumpAndSettle` the bottom sheet. Verify role buttons are findable inside the sheet.
- **Output artifact:** Updated test file.
- **Stop condition:** `flutter test test/widget/dashboard/dashboard_screen_test.dart` passes all 3 tests.

### FIX-2: Replace IntrinsicHeight with Border Decoration
- **Goal:** Avoid O(2n) layout cost for priority bar.
- **Why:** `IntrinsicHeight` is expensive in scrollable lists.
- **How:** Replace Phase 3.2.1 approach: Instead of wrapping in `Row` + `IntrinsicHeight`, add a left `Border` to the existing card wrapper's `BoxDecoration`. The border color maps to the priority action type.
- **Output artifact:** Modified `next_actions_list.dart`.
- **Stop condition:** Priority bar renders as a left border on each card without `IntrinsicHeight`.

### FIX-3: Add SnackBar Color Normalization
- **Goal:** Replace `Colors.red`/`Colors.green` in dashboard SnackBars.
- **Why:** Violates acceptance criterion #12.
- **How:** Add explicit sub-steps:
  - Phase 3 (next_actions_list): Step 3.5 — Replace `Colors.green` → `colorScheme.success`, `Colors.red` → `colorScheme.danger`.
  - Phase 7 (inbox_tab): Step 7.4 — Replace `Colors.red` → `colorScheme.danger`.
- **Output artifact:** Updated files.
- **Stop condition:** `grep -r "Colors\.\(red\|green\)" lib/features/dashboard/` returns zero matches.

### FIX-4: Add Per-Phase Analyze Gates
- **Goal:** Catch errors early.
- **Why:** 13 files across 8 phases without intermediate verification is risky.
- **How:** Add `flutter analyze` to each Phase 1-8 GATE CHECK.
- **Output artifact:** None (process change).
- **Stop condition:** Every GATE CHECK includes analyze.

### FIX-5: Add AnimatedSize Clip Fix
- **Goal:** Prevent visual clipping during expand/collapse animation.
- **Why:** `AnimatedSize` defaults to `Clip.hardEdge` which clips overflow during animation.
- **How:** Add `clipBehavior: Clip.none` to Phase 4.2 AnimatedSize widget. Add explicit verification step.
- **Output artifact:** Modified `overview_tab.dart`.
- **Stop condition:** Expand/collapse shows no clipping artifacts.

### FIX-6: Fix Phase 4 "How" Field
- **Goal:** Accurate file scope documentation.
- **Why:** Executor needs to know all files touched per phase.
- **How:** Update Phase 4 "How" to "Modify `activity_feed_preview.dart` and `overview_tab.dart`."
- **Output artifact:** Updated plan.
- **Stop condition:** "How" field lists both files.

### FIX-7: Add Time Grouping Stagger Cache Coordination Step
- **Goal:** Prevent index-out-of-bounds when stagger animations meet time group headers.
- **Why:** The stagger animation cache is indexed by item position. If time group headers are inserted between items, the index mapping breaks.
- **How:** Add sub-step 4.1.6: Ensure stagger animations are keyed to ACTIVITY items only (not header items). Headers should render without stagger animation. The `_slideAnimations` / `_fadeAnimations` lists should be indexed against the activity item index, not the flat list index.
- **Output artifact:** Modified `activity_feed_preview.dart`.
- **Stop condition:** Stagger animations play on activity rows only, not on headers. No index errors with 0, 1, 3, 10 items.

### FIX-8: Add `screenHorizontalMargin` Alignment Verification
- **Goal:** Prevent visual misalignment between tab bar and content.
- **Why:** TabBar uses the AppBar's default padding. Content area uses `screenHorizontalMargin` (24px). If these differ, there's a visible step.
- **How:** Add verification sub-step 2.3.5: Check that `AppLayout.screenHorizontalMargin` (24px) aligns with the TabBar's effective horizontal padding. If not, use `AppDimens.p16` for content padding to match.
- **Output artifact:** None (verification step).
- **Stop condition:** Tab labels and content are visually aligned.

---

## H) Corrected Plan (Execution-Ready, Gate-Based)

> **Diff note:** Only the CHANGED sections are shown. Unchanged phases/sub-phases from the original plan are included by reference. Every addition is marked with `[NEW]` or `[CHANGED]`.

### Phase 1: Dashboard Screen — TabBar & Settings Redesign

*All existing sub-steps from original plan retained. Additions:*

#### 1.2 Settings Bottom Sheet — `[CHANGED]` Add Test Migration

- [All existing 1.2.1–1.2.9 sub-steps retained]
- [ ] (`@Pixel`) `[NEW]` Sub-step 1.2.10: Read `test/widget/dashboard/dashboard_screen_test.dart`. Update test T58:
  - Change the test to handle `showModalBottomSheet` instead of `showDialog`.
  - After `tester.tap(find.byKey(DashboardScreen.settingsButtonKey))`, use `tester.pumpAndSettle()` to wait for the bottom sheet animation to complete.
  - Verify `find.byKey(DashboardScreen.clientRoleButtonKey)` still finds the button inside the bottom sheet.
  - If the bottom sheet uses a different overlay structure, adjust the finder accordingly.
  - Run `flutter test test/widget/dashboard/dashboard_screen_test.dart` — all 3 tests must pass.
- [ ] (`@Sentinel`) Verify: T58 test passes after bottom sheet migration.

#### 1.X GATE CHECK — `[CHANGED]`
- **GATE CHECK:** `flutter analyze` clean. All 3 dashboard_screen_test tests pass. Bottom sheet settings functional.

---

### Phase 2: Overview Tab — `[CHANGED]` Add Alignment Verification

#### 2.3 Spacing Rhythm

- [All existing 2.3.1–2.3.4 sub-steps retained]
- [ ] (`@Pixel`) `[NEW]` Sub-step 2.3.5: Verify that content horizontal padding aligns with TabBar label positioning. If `AppLayout.screenHorizontalMargin` (24px) creates a visible step relative to the AppBar TabBar, use `AppDimens.p16` instead and document the reason.

#### 2.X GATE CHECK — `[CHANGED]`
- **GATE CHECK:** `flutter analyze` clean. Overview tab spacing consistent, no alignment mismatch with tab bar.

---

### Phase 3: Next Actions List — `[CHANGED]` Priority Bar Approach + SnackBar Colors

#### 3.2 Priority Left Bar — `[CHANGED]` No IntrinsicHeight

- [ ] (`@Pixel` | Skill: `colorize`) Add a colored left border to each action item card:
  - Sub-step 3.2.1 `[CHANGED]`: Wrap each `WorkItemCard` in a `Container` with `BoxDecoration` that includes a left `Border`:
    - `border: Border(left: BorderSide(width: 4, color: priorityColor))`
    - `borderRadius: BorderRadius.circular(AppDimens.r16)` (match card radius)
    - Color mapping unchanged from original plan.
    - **Do NOT use `IntrinsicHeight`.** The border inherits the container's height naturally.
  - Sub-step 3.2.2: [unchanged — Semantics]

#### 3.5 SnackBar Color Normalization — `[NEW]`

- [ ] (`@Pixel` | Skill: `colorize`) Replace hardcoded SnackBar colors in `next_actions_list.dart`:
  - Sub-step 3.5.1: Replace `backgroundColor: Colors.green` (line 171) → `backgroundColor: colorScheme.success`.
  - Sub-step 3.5.2: Replace `backgroundColor: Colors.red` (line 180) → `backgroundColor: colorScheme.danger`.
  - Sub-step 3.5.3: Note: `colorScheme` is not available in the `SnackBar` builder directly. Use `context.colorScheme.success` from the outer build context (which is available in the callback closure).
- [ ] (`@Sentinel`) Verify: No `Colors.red` or `Colors.green` in `next_actions_list.dart`.

#### 3.X GATE CHECK — `[CHANGED]`
- **GATE CHECK:** `flutter analyze` clean. Priority bars render. SnackBar colors use semantic tokens. Stagger animation plays once.

---

### Phase 4: Activity Feed — `[CHANGED]` Fix File Scope + Stagger Coordination + Clip

**How:** `[CHANGED]` Modify `activity_feed_preview.dart` AND `overview_tab.dart`.

#### 4.1 Time Grouping Headers — `[CHANGED]` Add Stagger Coordination

- [All existing 4.1.1–4.1.5 sub-steps retained]
- [ ] (`@Pixel`) `[NEW]` Sub-step 4.1.6: Ensure stagger animations are keyed to ACTIVITY ITEMS only (not group header widgets). When building the flat display list:
  - Track a separate `activityItemIndex` that increments only for activity rows (not headers).
  - Use `activityItemIndex` to index into `_slideAnimations` / `_fadeAnimations`.
  - Group headers render without stagger animation (instant, no transition).
  - Test edge cases: 0 items (empty state), 1 item (single group), 3 items all today (one group), 10 items across all groups.

#### 4.2 Expand/Collapse Animation — `[CHANGED]` Add Clip Fix

- [Existing 4.2.1–4.2.3 retained]
- [ ] (`@Pixel`) `[NEW]` Sub-step 4.2.4: Set `clipBehavior: Clip.none` on the `AnimatedSize` widget to prevent content clipping during the height transition.
- [ ] (`@Pixel`) `[NEW]` Sub-step 4.2.5: Manually test: tap "See All" while data is refreshing (pull-to-refresh + toggle simultaneously). Verify no visual artifacts.

#### 4.X GATE CHECK — `[CHANGED]`
- **GATE CHECK:** `flutter analyze` clean. Time groups render. AnimatedSize expand/collapse smooth with no clipping. Stagger animations don't crash with grouped items.

---

### Phase 5: Dashboard Counters Grid + Work Item Card — `[CHANGED]` Avatar Radius Fix

#### 5.2 Work Item Card Status Color Normalization

- [All existing sub-steps retained, plus:]
- Sub-step 5.2.8 `[CHANGED]`: Replace hardcoded `radius: 18` for avatar. Use a local variable in the `build` method: `final avatarRadius = AppLayout.avatarSmall / 2;` then use `avatarRadius` for both the `CircleAvatar` radius and the icon size. Do NOT use in a `const` context.
- Sub-step 5.2.9 `[CHANGED]`: Same — use `avatarRadius` local variable for icon size.

#### 5.X GATE CHECK — `[CHANGED]`
- **GATE CHECK:** `flutter analyze` clean. Counter colors correct in light and dark mode. Work item card status colors correct in light and dark mode.

---

### Phase 6: Work Tab — `[UNCHANGED]`
- Add `flutter analyze` to GATE CHECK.

### Phase 7: Bookings Tab + Inbox Tab — `[CHANGED]` Add SnackBar Fix

#### 7.4 Inbox Tab SnackBar Color Normalization — `[NEW]`

- [ ] (`@Pixel` | Skill: `colorize`) Replace hardcoded SnackBar colors in `inbox_tab.dart`:
  - Sub-step 7.4.1: Replace `backgroundColor: Colors.red` (lines 51, 59) → `backgroundColor: colorScheme.danger`.
- [ ] (`@Sentinel`) Verify: No `Colors.red` in `inbox_tab.dart`.

#### 7.X GATE CHECK — `[CHANGED]`
- **GATE CHECK:** `flutter analyze` clean. Inbox skeleton loading works. Empty state matches pattern. No raw `Colors.*` in inbox_tab.dart.

### Phase 8: Cross-Feature Cards — `[CHANGED]` Add Cross-Site Verification

#### 8.X GATE CHECK — `[NEW]` Add Cross-Site Render Check

- [ ] (`@Sentinel`) `[NEW]` Verify cross-feature cards render correctly OUTSIDE the dashboard:
  - Wallet snapshot card: check on standalone WalletScreen.
  - Dashboard booking card: check on standalone BookingsDiscoveryScreen (if it uses this card).
  - Dashboard offer card: check on standalone task detail/proposal views.
- **GATE CHECK:** `flutter analyze` clean. Cross-feature cards render correctly both on dashboard and in their standalone contexts.

---

### Phase 9: QA + Verification — `[CHANGED]` Add Invariant Checks

#### 9.2 Architecture Guard — `[CHANGED]` Add Explicit Grep Checks

- [ ] (`@Sentinel`) Run: `grep -r "AppColors\." lib/features/dashboard/view/` — must return zero matches (all migrated to `colorScheme.*`).
- [ ] (`@Sentinel`) Run: `grep -r "Colors\.\(red\|green\|blue\|orange\)" lib/features/dashboard/view/` — must return zero matches.
- [ ] (`@Sentinel`) Run: `grep -r "Duration(milliseconds:" lib/features/dashboard/view/` — must return zero matches.
- [ ] (`@Sentinel`) Run: `grep -r "print\(\|debugPrint\(" lib/features/dashboard/view/` — must return zero matches.

---

## I) Change Report (Diff-Style)

### 1. Original Issues Summary
The plan was well-structured with good over-decomposition and thorough appendix evidence. However, it had 6 critical gaps: a guaranteed test breakage, missing SnackBar color normalization, a performance-costly IntrinsicHeight approach, an AnimatedSize clipping risk, a stagger animation/time-grouping coordination gap, and no intermediate analyze gates.

### 2. Added Steps
| Step | Phase | Why |
|------|-------|-----|
| 1.2.10: Test T58 migration | Phase 1 | **WILL BREAK** without this |
| 3.5: SnackBar color normalization (next_actions_list) | Phase 3 | Violates AC #12 |
| 4.1.6: Stagger/group header coordination | Phase 4 | Index-out-of-bounds risk |
| 4.2.4: AnimatedSize `clipBehavior: Clip.none` | Phase 4 | Visual clipping during animation |
| 4.2.5: Concurrent refresh+toggle test | Phase 4 | Edge case verification |
| 7.4: SnackBar color normalization (inbox_tab) | Phase 7 | Violates AC #12 |
| 8.X: Cross-site render verification | Phase 8 | Cross-feature regression |
| Per-phase `flutter analyze` | Phases 1-8 | Early error detection |
| 9.2: Explicit grep invariant checks | Phase 9 | Machine-verifiable invariants |

### 3. Removed Steps
None.

### 4. Reordered Steps
None.

### 5. Expanded Steps
| Step | What Changed |
|------|-------------|
| 3.2.1 (Priority bar) | `IntrinsicHeight` → `BoxDecoration` left border |
| 5.2.8-9 (Avatar radius) | `AppLayout.avatarSmall / 2` const → local variable |
| Phase 4 "How" field | Added `overview_tab.dart` to file list |
| 2.3 (Spacing rhythm) | Added alignment verification sub-step 2.3.5 |

### 6. Why
- **Test breakage (GAP-1):** Guaranteed failure. Non-negotiable fix.
- **SnackBar colors (GAP-2):** Plan's own acceptance criteria (#12) would fail without this.
- **IntrinsicHeight (DN-1):** Performance concern in scrollable list. Better alternative exists.
- **AnimatedSize clipping (GAP-4):** Known Flutter behavior that causes visual bugs.
- **Stagger coordination (FIX-7):** Non-obvious interaction between two features modified in the same phase.
- **Per-phase analyze (GAP-5):** 8 phases without intermediate verification is reckless.

### 7. Residual Risks
1. **Dark mode semantic color mismatch:** `colorScheme.warning` may not visually match `AppColors.gold` in dark mode. Requires manual dark mode verification per phase. Mitigation: screenshot comparison before/after.
2. **Cross-feature card regression:** Modifying cards in wallet/booking/tasks modules affects those features globally. Mitigation: cross-site render check in Phase 8.
3. **Time grouping edge cases:** Empty activity feed, single item, all items same day — each needs separate verification. Mitigation: added explicit test cases in step 4.1.6.
4. **626-line DashboardOfferCard complexity:** Token normalization on a 626-line StatefulWidget with complex state management has inherent risk. No widget tests exist for this card. Mitigation: `flutter analyze` + manual visual verification.

---

**Plan verdict: ❌ FAIL (6 critical gaps). Apply fixes above, then re-gate.**

After applying all fixes: **✅ PASS (conditional on manual dark mode verification per phase).**

END.
