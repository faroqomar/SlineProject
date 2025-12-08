# ✨ Phase 6: Polish & Animations Implementation Plan

**Status:** Completed
**Agent:** @SlinePlanner
**Source:** `.TODO/Future_Plans/NEW_DESIGN_MIGRATION_PLAN.md`
**Target:** `lib/`

This phase focused on elevating the user experience with refined animations, smooth transitions, and visual polish.

---

## 1. 🔄 Transitions & Navigation

**Goal:** Replace standard Material transitions with custom "Slide Up" or "Fade" transitions.

- [x] **Global Transition Theme**
    - **Agent:** `@Pixel`
    - **File:** `lib/core/theme/app_theme.dart`
    - **Task:** Configured `pageTransitionsTheme` to use `FadeUpwardsPageTransitionsBuilder` for Android and iOS.

- [x] **Custom Route Animations**
    - **Agent:** `@Pixel`
    - **File:** `lib/core/utils/transitions/custom_route_transitions.dart`
    - **Task:** Implemented `SlideUpRoute` and `FadeRoute` builders.

---

## 2. 🤏 Micro-interactions

**Goal:** Add tactile feedback to buttons and cards.

- [x] **Scale Button Wrapper**
    - **Agent:** `@Pixel`
    - **File:** `lib/core/widgets/scale_button.dart`
    - **Task:** Created `ScaleButton` widget that scales down (0.95) on press.

- [x] **Integration**
    - **Agent:** `@Pixel`
    - **File:** `lib/core/widgets/app_button.dart`
    - **Task:** Wrapped `AppButton` container with `ScaleButton`.
    - **File:** `lib/features/tasks/view/widgets/task_card.dart`
    - **Task:** Wrapped `TaskCard` container with `ScaleButton`.

- [x] **Hero Animations**
    - **Agent:** `@Pixel`
    - **Files:** `TaskCard` and `TaskDetailsScreen`.
    - **Task:** Connected the avatar image with `Hero(tag: 'avatar_${task.id}')` for smooth shared element transition.

---

## 3. 📜 Scroll Physics & polish

**Goal:** Ensure consistent, bouncy scrolling everywhere.

- [x] **Global Scroll Configuration**
    - **Agent:** `@Pixel`
    - **File:** `lib/main.dart`
    - **Task:** Set `scrollBehavior` to use `BouncingScrollPhysics` in `MaterialApp`.

- [x] **List View Padding**
    - **Agent:** `@Pixel`
    - **Files:** `HomeScreen`, `TendersScreen`, `BookingsDiscoveryScreen`.
    - **Task:** Verified `SliverPadding` bottom is `AppDimens.p100` to account for the floating nav bar.

---

## 4. 🧹 Final Audit

- [x] `flutter analyze` passes with no issues.