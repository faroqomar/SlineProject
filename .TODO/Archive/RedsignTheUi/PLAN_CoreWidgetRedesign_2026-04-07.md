# Plan: Core Widget Redesign (Phase 1 of UI Redesign)

## 1) Goal
- **Goal:** Redesign all 14 core widgets in `lib/core/widgets/` to use Phase 0 design tokens (AppMotion, AppInteractionStates, AppDecorations.elevation, semantic colors), add the 8-state interaction model, haptic feedback, accessibility (Semantics), and create component-level widget tests for every widget.
- **Why:** The current widgets are basic — zero haptics, zero Semantics, hardcoded animation values, 3 architecture violations (feature imports in core), no component tests. Every screen in the app (134 files) inherits from these 14 widgets, so upgrading them transforms the entire app without touching feature code.
- **Result:** 14 redesigned widgets + 14 widget test files + 3 architecture violations fixed. All widgets reference AppMotion/AppStates/AppDecorations tokens. All have Semantics labels. All interactive widgets have haptic feedback. `flutter analyze` clean. `flutter test` baseline maintained + new tests passing.

## 2) Scope

### In-Scope
- Redesign all 14 widgets in `lib/core/widgets/`
- Fix 3 architecture violations (feature imports in signed_avatar, signed_image, status_badge)
- Migrate all hardcoded animation values to AppMotion tokens
- Add Semantics widgets to all interactive components
- Add HapticFeedback to all tappable widgets
- Add 8-state interaction model to AppButton, AppTextField, ScaleButton
- Add component-level widget tests for all 14 widgets (`test/core/widgets/`)
- Add 8 new skeleton card variants (wallet, proposal, work item, notification, service, favorite, search, profile)
- Add TextButtonTheme + OutlinedButtonTheme to app_theme.dart (deferred from Phase 0 LOW-2)
- Migrate ScaleButton from old hardcoded values (100ms, easeInOut, 0.95) to AppMotion tokens
- Migrate CustomBottomNavBar from hardcoded 300ms to AppMotion tokens
- Migrate SkeletonLoader from hardcoded 1500ms to AppMotion tokens

### Out-of-Scope
- Redesigning any feature screen (Phase 2+)
- Changing app navigation or routing (Phase 2)
- Any Supabase/backend changes
- Migrating the 817 `Colors.*` violations in feature files (Phase 2+)
- Adding new dependencies to pubspec.yaml

## 3) Evidence & Findings (From Scan)

### Existing

**14 Core Widgets (2,362 lines total):**

| # | Widget | Lines | Classes | Animations | Feature Imports | Blast Radius |
|---|--------|-------|---------|-----------|----------------|-------------|
| 1 | app_button.dart | 126 | 1 | None | None | 21 files (HIGH) |
| 2 | app_text_field.dart | 73 | 1 | None | None | 15 files (HIGH) |
| 3 | circle_icon_button.dart | 46 | 1 | None | None | 1 file (LOW) |
| 4 | scale_button.dart | 77 | 2 | Scale 100ms easeInOut | None | 2 files (glass_button, glass_card) |
| 5 | glass_button.dart | 132 | 1 | BackdropFilter + ScaleButton | None | 0 feature files |
| 6 | glass_card.dart | 47 | 1 | ScaleButton inherited | None | 8 files |
| 7 | glass_container.dart | 60 | 1 | BackdropFilter (static) | None | 21 files (HIGH) |
| 8 | custom_bottom_nav_bar.dart | 391 | 4 | Scale+Pill 300ms hardcoded | None | 1 file (main_nav) |
| 9 | signed_avatar.dart | 302 | 2 | CircularProgressIndicator | **features/profile** | 14 files (HIGH) |
| 10 | signed_image.dart | 219 | 2 | CircularProgressIndicator | **features/tasks** | 8 files |
| 11 | skeleton_loader.dart | 159 | 4 | Shimmer 1500ms hardcoded | None | 1 file (skeleton_card) |
| 12 | skeleton_card.dart | 517 | 6 | None (static) | None | 5 files |
| 13 | status_badge.dart | 135 | 1 | None | **features/dashboard** | 6 files |
| 14 | sliver_tab_bar_delegate.dart | 34 | 1 | None | None | 1 file |

**Test Infrastructure:**
- `test/test_support/pump_app.dart` — base helper wrapping MaterialApp + AppTheme.light()
- `test/helpers/mock_services.dart` — 18 mock service classes (mocktail)
- `test/helpers/mock_view_models.dart` — 12 mock ViewModel classes
- **Zero component-level widget tests** for core widgets. All 42 existing widget tests are feature-screen level.
- Baseline: 1195 passed, 30 skipped, 1 pre-existing failure

**Phase 0 Tokens Available (prerequisite confirmed complete):**
- AppMotion: 7 durations, 7 curves, 4 scales, 3 staggers, respectMotion helper
- AppInteractionStates: 8-state model, all constants, 4 haptic methods
- AppDecorations.elevation(): 5-level shadow scale
- AppColorScheme: 12 semantic/interactive colors
- 7 component themes in AppTheme

### Missing
- Widget test directory: `test/core/widgets/` does NOT exist
- Component tests for any core widget: ZERO
- Semantics on any interactive widget: ZERO (only 2 in entire codebase, both in feature widgets)
- HapticFeedback: ZERO instances in entire codebase
- TextButtonTheme / OutlinedButtonTheme: not in AppTheme (deferred Phase 0 LOW-2)

### Must NOT Duplicate
- ScaleButton and SpringButton both provide tap-to-scale. ScaleButton is used by GlassCard/GlassButton. SpringButton is used by main_navigation_screen. Keep both but ensure they reference the same AppMotion tokens. (Already done in Phase 0 for SpringButton.)
- SkeletonLoader shimmer animation is shared across all skeleton variants — change once, affects all.

### Conflicts / Risks
- **Architecture violations in 3 widgets:** signed_avatar imports features/profile, signed_image imports features/tasks, status_badge imports features/dashboard. These MUST be resolved by extracting service interfaces to core or moving the services.
- **AppButton blast radius (21 files):** Any constructor parameter change will break 21 feature files. Keep constructor backward-compatible. Add new optional params only.
- **GlassContainer blast radius (21 files):** Same — keep backward-compatible.
- **SignedAvatar blast radius (14 files):** Constructor change + architecture fix in same phase — high risk.
- **skeleton_card.dart is already 517 lines.** Adding 8 more skeletons would push it to ~900 lines. Consider splitting into skeleton_card.dart + skeleton_card_extended.dart.
- **No existing component tests** means verification before changes relies on the existing 42 feature-screen widget tests (which instantiate core widgets) and `flutter test` baseline comparison. Component tests are written alongside each widget redesign (not before), and existing feature tests serve as the regression safety net. Manual visual QA supplements automated checks after high-blast-radius phases (3, 4, 5).

## 4) System Impact Map
- **UI:** All 14 core widgets change. 134 feature files inherit visual/behavioral changes but are NOT modified in this phase. Constructor signatures must remain backward-compatible.
- **MVVM / App Logic:** 3 architecture fixes move service references from core → proper location.
- **Database:** None.
- **RLS / Security:** None.
- **RPC / Edge Functions:** None.
- **Storage:** None.
- **Realtime / Notifications:** None.
- **Observability:** AppLogger NOT added to widgets (theme layer doesn't log per Phase 0 Orchestrator finding). HapticFeedback is output-only.
- **Compatibility & Migration:** All constructor changes MUST be backward-compatible (optional params only). No breaking changes to widget API.
- **Contracts:** None.

## 5) Agent Map
- **Phase 0 (Preconditions):** `@Sentinel` (primary), `@SlinePlanner` (gate)
- **Phase 1 (Architecture Fixes):** `@Architect` (primary), `@Sentinel` (gate)
- **Phase 2 (Test Infrastructure):** `@Sentinel` (primary), `@Architect` (support)
- **Phase 3 (Foundation Widgets):** `@Pixel` (primary), `@Architect` (review), `@Sentinel` (gate)
- **Phase 4 (Interactive Widgets):** `@Pixel` (primary), `@Architect` (review), `@Sentinel` (gate)
- **Phase 5 (Display Widgets):** `@Pixel` (primary), `@Sentinel` (gate)
- **Phase 6 (Composite Widgets):** `@Pixel` (primary), `@Sentinel` (gate)
- **Phase 7 (Skeleton Expansion):** `@Pixel` (primary), `@Sentinel` (gate)
- **Phase 8 (Button Theme Completion):** `@Pixel` (primary), `@Sentinel` (gate)
- **Phase 9 (QA + Verification):** `@Sentinel` (primary), `@CodeGuard` (review)

---

## Phase 0: Preconditions & Gates

**Primary Agent(s):** `@Sentinel`, `@SlinePlanner`

### 0.1 Phase 0 Completion Verification
- [ ] (`@Sentinel`) Confirm all 12 Phase 0 acceptance criteria pass (see PLAN_DesignSystemFoundation Section 7).
- [ ] (`@Sentinel`) Confirm `flutter analyze` passes clean.
- [ ] (`@Sentinel`) Confirm `flutter test` baseline: 1195 passed, 30 skipped, 1 pre-existing failure.
- **GATE CHECK:** Phase 0 Design System Foundation is complete. All tokens available.

### 0.2 Backward Compatibility Lock
- [ ] (`@Architect`) Document every current public constructor signature for all 14 widgets. Any parameter removal or type change is a BLOCKER.
- [ ] (`@Architect`) Rule: all new parameters MUST be optional with sensible defaults. No required parameter additions.
- **GATE CHECK:** Backward compatibility contract documented.

### 0.3 Test Baseline Snapshot
- [ ] (`@Sentinel`) Run `flutter test --reporter=compact`. Record exact counts.
- [ ] (`@Sentinel`) Identify any feature widget tests that directly instantiate core widgets — these are the highest regression risk.
- **GATE CHECK:** Baseline captured in session log.

---

## Phase 1: Architecture Violation Fixes

**Primary Agent(s):** `@Architect`
**Goal:** Remove 3 feature imports from core widgets without breaking any feature code.
**Why:** Core widgets must not import from features — this is a strict MVVM boundary. These violations prevent clean layer separation and create circular dependency risk.
**How:** Extract service interfaces to core, or inject services via constructor.
**Result:** Zero `import.*features/` in `lib/core/widgets/`.

### 1.1 Fix signed_avatar.dart (imports features/profile/services/avatar_service.dart)

- [ ] (`@Architect`) Read `lib/features/profile/services/avatar_service.dart` and identify the exact methods `signed_avatar.dart` calls.
- [ ] (`@Architect`) Create `lib/core/services/avatar_service_interface.dart` with an abstract class containing only the methods signed_avatar needs.
- [ ] (`@Architect`) Make the existing `AvatarService` in features/profile implement this interface.
- [ ] (`@Architect`) Update `signed_avatar.dart` to import the core interface, not the feature service.
- [ ] (`@Architect`) Update `signed_avatar.dart` constructor to accept the service via optional parameter (DI pattern matching existing SLine convention).
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.
- [ ] (`@Sentinel`) Run `flutter test` — confirm zero new failures.
- [ ] (`@Sentinel`) Grep for `import.*features/` in `lib/core/widgets/signed_avatar.dart` — must return 0.
- **GATE CHECK:** signed_avatar.dart has zero feature imports. Tests pass.

### 1.2 Fix signed_image.dart (imports features/tasks/services/task_image_service.dart)

- [ ] (`@Architect`) Read `lib/features/tasks/services/task_image_service.dart` and identify exact methods used.
- [ ] (`@Architect`) Create `lib/core/services/image_service_interface.dart` with abstract class.
- [ ] (`@Architect`) Make existing `TaskImageService` implement this interface.
- [ ] (`@Architect`) Update `signed_image.dart` to import core interface.
- [ ] (`@Architect`) Update constructor for DI.
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.
- [ ] (`@Sentinel`) Run `flutter test` — zero new failures.
- [ ] (`@Sentinel`) Grep for `import.*features/` in `lib/core/widgets/signed_image.dart` — must return 0.
- **GATE CHECK:** signed_image.dart has zero feature imports. Tests pass.

### 1.3 Fix status_badge.dart (imports features/dashboard/models/work_item.dart)

**Decision: Move WorkItem model to core.** Scan evidence shows WorkItem is imported by 8 files (6 in dashboard feature, 2 in core layer). Both core imports are violations. Moving the model to core is the correct fix since it is already shared across layers.

- [ ] (`@Architect`) Move `lib/features/dashboard/models/work_item.dart` → `lib/core/models/work_item.dart` (including `WorkItemPermissions` nested class).
- [ ] (`@Architect`) Update ALL 8 import paths:
  1. `lib/core/widgets/status_badge.dart` (core violation)
  2. `lib/core/services/dashboard_cache_service.dart` (core violation)
  3. `lib/features/dashboard/viewmodels/dashboard_work_delegate.dart`
  4. `lib/features/dashboard/viewmodels/dashboard_view_model.dart`
  5. `lib/features/dashboard/view/tabs/work_tab.dart`
  6. `lib/features/dashboard/view/widgets/work_item_card.dart`
  7. `lib/features/dashboard/data/dashboard_repository.dart`
  8. `lib/features/dashboard/services/dashboard_permission_service.dart`
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.
- [ ] (`@Sentinel`) Run `flutter test` — zero new failures.
- [ ] (`@Sentinel`) Grep for `import.*features/` in ALL `lib/core/widgets/*.dart` — must return 0 total.
- [ ] (`@Sentinel`) Grep for `import.*features/.*work_item` in `lib/core/` — must return 0 total.
- **GATE CHECK:** All 3 architecture violations fixed. WorkItem in core/models. Zero feature imports in core/widgets.

---

## Phase 2: Widget Test Infrastructure

**Primary Agent(s):** `@Sentinel`, `@Architect`
**Goal:** Create the test directory structure and base helpers for core widget component tests.
**Why:** Zero component tests exist. We need a foundation before writing tests alongside redesigned widgets.
**How:** Create test directory, helpers, and 2-3 baseline tests for unchanged widgets to verify the infrastructure works.
**Result:** `test/core/widgets/` directory with working test infrastructure.

### 2.1 Create test directory and helpers
- [ ] (`@Sentinel`) Create directory `test/core/widgets/`.
- [ ] (`@Sentinel`) Create `test/core/widgets/widget_test_helpers.dart` with:
  - Sub-step 2.1.1: `pumpWidget` helper that wraps widget in MaterialApp + AppTheme.light() (similar to existing pumpApp but for isolated widgets, not full screens).
  - Sub-step 2.1.2: `pumpWidgetDark` helper for dark mode testing.
  - Sub-step 2.1.3: Helper to find widgets by type and verify Semantics labels.
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.

### 2.2 Baseline tests for simple widgets
- [ ] (`@Sentinel`) Create `test/core/widgets/sliver_tab_bar_delegate_test.dart` — simplest widget, verifies test infra works.
  - Test: renders with TabBar child.
  - Test: maxExtent and minExtent return correct values.
- [ ] (`@Sentinel`) Create `test/core/widgets/circle_icon_button_test.dart`:
  - Test: renders with correct icon.
  - Test: onTap fires callback.
  - Test: custom colors applied.
- [ ] (`@Sentinel`) Run `flutter test test/core/widgets/` — both files pass.
- **GATE CHECK:** Widget test infrastructure works. 2 passing test files.

---

## Phase 3: Foundation Widget Redesign (ScaleButton, GlassContainer, GlassCard)

**Primary Agent(s):** `@Pixel`, `@Architect`
**Goal:** Redesign the 3 foundation widgets that other widgets depend on. These must be done FIRST because AppButton, GlassButton, and all glass cards depend on them.
**Why:** ScaleButton wraps AppButton/GlassButton/GlassCard. GlassContainer wraps 21+ feature files. Changes here cascade everywhere.
**How:** Migrate to AppMotion tokens, add Semantics, add haptics, keep constructors backward-compatible.
**Result:** 3 redesigned widgets + 3 test files.

### 3.1 ScaleButton — Migrate to AppMotion + Add Haptics
- [ ] (`@Pixel` | Skill: `animate`) In `lib/core/widgets/scale_button.dart`:
  - Sub-step 3.1.1: Replace `Duration(milliseconds: 100)` default → `AppMotion.micro`.
  - Sub-step 3.1.2: Replace `0.95` default → `AppMotion.pressScale` (0.96).
  - Sub-step 3.1.3: Replace `Curves.easeInOut` → `AppMotion.curveSpring`.
  - Sub-step 3.1.4: Add `callbackDelay` optional parameter (default `Duration(milliseconds: 50)`) to maintain backward compatibility. Callers can pass `Duration.zero` to fire immediately. Internally: if `callbackDelay == Duration.zero`, call `onPressed` in `_onTapUp` directly; otherwise use `Future.delayed(callbackDelay, onPressed)`.
  - Sub-step 3.1.5: Add `HapticFeedback.selectionClick()` on `_onTapDown`.
  - Sub-step 3.1.6: Add `disabled` parameter (optional, default false). When true: `AbsorbPointer` + `Opacity(AppInteractionStates.disabledOpacity)`.
  - Sub-step 3.1.7: Wrap with `AppMotion.respectMotion()` — if reduced motion, skip scale animation.
  - Sub-step 3.1.8: Add `Semantics(button: true)` wrapper.
- [ ] (`@Architect`) Review: no feature imports, all tokens from AppMotion/AppStates.
- [ ] (`@Sentinel`) `flutter analyze` clean.
- [ ] (`@Sentinel`) `flutter test` — zero new failures (GlassButton, GlassCard still work).
- [ ] (`@Pixel`) Write `test/core/widgets/scale_button_test.dart`:
  - Test: scales down on tap-down.
  - Test: scales back up on tap-up.
  - Test: fires onPressed callback.
  - Test: disabled state blocks interaction.
  - Test: has Semantics button=true.
- **GATE CHECK:** ScaleButton migrated. Tests pass. GlassButton/GlassCard not broken.

### 3.2 GlassContainer → Solid Surface (NO GLASS — see .impeccable.md)
- [ ] (`@Pixel` | Skill: `distill`) In `lib/core/widgets/glass_container.dart`:
  - Sub-step 3.2.1: **Remove ALL BackdropFilter / ClipRRect blur logic.** Replace with a simple Container.
  - Sub-step 3.2.2: Background: `colorScheme.cardBackground` (solid, no gradient, no transparency).
  - Sub-step 3.2.3: Border: `colorScheme.cardBorder` (1px, subtle).
  - Sub-step 3.2.4: Add `elevation` parameter (optional, default 1) using `AppDecorations.elevation(level, isDark: colorScheme.isDark)`.
  - Sub-step 3.2.5: Remove `blurRadius` parameter entirely (it's glass-specific). Keep `padding`, `margin`, `borderRadius`, `child` parameters unchanged for backward compatibility.
  - Sub-step 3.2.6: Remove `kIsWeb` platform branching (no blur = no platform difference).
  - Sub-step 3.2.7: Remove import of `dart:ui` (if only used for BackdropFilter/ImageFilter).
  - Sub-step 3.2.8: Update `AppDecorations.glassBoxDecoration()` — either deprecate with `@Deprecated` or convert to `solidCardDecoration()` with cardBackground + cardBorder + elevation.
- [ ] (`@Architect`) Review: backward compatible (padding/margin/borderRadius/child unchanged). blurRadius removal is breaking but intentional per NO GLASS POLICY.
- [ ] (`@Sentinel`) `flutter analyze` clean.
- [ ] (`@Sentinel`) `flutter test` — zero new failures (21 feature files still compile since they pass child/padding/margin/borderRadius).
- [ ] (`@Sentinel`) Run app on emulator — verify 3+ screens with GlassContainer render correctly with solid backgrounds.
- [ ] (`@Pixel`) Write `test/core/widgets/glass_container_test.dart`:
  - Test: renders child widget with solid background.
  - Test: does NOT contain BackdropFilter (no glass).
  - Test: applies elevation shadow at given level.
  - Test: respects borderRadius parameter.
- **GATE CHECK:** GlassContainer is now a solid-surface container. Zero glass/blur in the widget. 21 feature files verified.

### 3.3 GlassCard → Solid Card (NO GLASS)
- [ ] (`@Pixel` | Skill: `distill`) In `lib/core/widgets/glass_card.dart`:
  - Sub-step 3.3.1: GlassCard wraps GlassContainer, which is now solid. Verify it inherits solid surface automatically.
  - Sub-step 3.3.2: Verify ScaleButton wrapper provides haptics and AppMotion tokens from Phase 3.1.
  - Sub-step 3.3.3: Add `elevation` parameter (optional, default 1) — passes through to GlassContainer.
  - Sub-step 3.3.4: Add `disabled` parameter (optional, default false) — forwards to ScaleButton's `disabled` parameter. When true, GlassCard disables tap + applies `AppInteractionStates.disabledOpacity`.
  - Sub-step 3.3.5: Add `Semantics(container: true)` wrapper.
- [ ] (`@Sentinel`) `flutter analyze` clean.
- [ ] (`@Sentinel`) `flutter test` — zero new failures.
- [ ] (`@Pixel`) Write `test/core/widgets/glass_card_test.dart`:
  - Test: renders child with solid container (no glass).
  - Test: tappable when onTap provided.
  - Test: applies elevation shadow.
  - Test: has Semantics container=true.
- **GATE CHECK:** GlassCard is now a solid card. Tests pass.

---

## Phase 4: Interactive Widget Redesign (AppButton, AppTextField, CircleIconButton, GlassButton)

**Primary Agent(s):** `@Pixel`, `@Architect`
**Goal:** Add the 8-state interaction model, haptics, accessibility, and animations to all interactive widgets.
**Why:** These widgets are the primary touch targets in every screen. They need to feel alive and be accessible.
**How:** Apply AppInteractionStates constants, add Semantics, add HapticFeedback.
**Result:** 4 redesigned widgets + 4 test files. All support 8 interactive states.

### 4.1 AppButton — 8-State Model (HIGHEST BLAST RADIUS: 21 files)

**Sub-phase 4.1a: Convert StatelessWidget → StatefulWidget**
- [ ] (`@Pixel` | Skill: `harden`) Convert `AppButton` from `StatelessWidget` to `StatefulWidget` with `SingleTickerProviderStateMixin` (needed for success animation). Move build logic to State class. Keep ALL constructor params unchanged.
- [ ] (`@Sentinel`) `flutter analyze` clean. `flutter test` — zero new failures across 21 feature files.

**Sub-phase 4.1b: Add 8-State Interaction Model**
- [ ] (`@Pixel` | Skill: `harden`) In `lib/core/widgets/app_button.dart`:
  - Sub-step 4.1b.1: **Widget tree:** Use ScaleButton as OUTER gesture/scale wrapper. Keep Material widget INSIDE (with shape from borderRadius and elevation from `AppDecorations.elevation(1)`) and InkWell inside Material to preserve ripple effects. The nesting is: `ScaleButton > Material > InkWell > content`. This preserves Material semantics, elevation, and ripples while adding scale feedback and haptics.
  - Sub-step 4.1b.2: **Default state:** Normal appearance. Elevation Level 1.
  - Sub-step 4.1b.3: **Hover state (desktop/web):** Apply `colorScheme.hoverOverlay` via InkWell's `hoverColor`. Elevation Level 2. (Automatic via Material+InkWell).
  - Sub-step 4.1b.4: **Focus state:** Apply `AppInteractionStates.focusRingWidth` outline via InkWell's `focusColor` and `highlightShape`. (Automatic via Material+InkWell).
  - Sub-step 4.1b.5: **Active/pressed state:** ScaleButton provides press scale + `HapticFeedback.lightImpact()`. InkWell provides ripple. Both fire simultaneously.
  - Sub-step 4.1b.6: **Disabled state (`isDisabled` param, optional, default false):** `AbsorbPointer` wraps the entire widget. Opacity `AppInteractionStates.disabledOpacity`. Elevation Level 0. `Semantics(enabled: false)`.
  - Sub-step 4.1b.7: **Loading state (`isLoading` param, existing):** Keep button same size. Swap text for `SizedBox(AppInteractionStates.loadingSize)` CircularProgressIndicator with `AppMotion.fast` crossfade. `AbsorbPointer` active. `Semantics(enabled: false)`.
  - Sub-step 4.1b.8: **Success state:** Triggered by calling `onSuccess` callback after async action completes. Sets internal `_isInSuccessState = true`. Disables all input (treat as disabled: `AbsorbPointer`, ignores taps). Flashes `colorScheme.success` at `AppInteractionStates.flashOverlayOpacity` for `AppInteractionStates.flashDuration` (300ms). Shows animated check icon for an additional 200ms (total visible: 500ms). Then auto-reverts `_isInSuccessState = false` after `AppInteractionStates.revertDelay` (1500ms). Fires `AppInteractionStates.hapticSuccess()`. `Semantics(enabled: false)` during animation.
  - Sub-step 4.1b.9: **Error state:** Triggered externally via `isError` param (optional, default false). Flashes `colorScheme.danger` at `AppInteractionStates.flashOverlayOpacity` for `AppInteractionStates.flashDuration`. Fires `AppInteractionStates.hapticHeavy()`. Auto-reverts.
  - Sub-step 4.1b.10: **Semantics:** `Semantics(button: true, label: text, enabled: !isDisabled && !isLoading && !_isInSuccessState)`.
  - Sub-step 4.1b.11: Replace hardcoded shadow (`blurRadius: 15, alpha: 0.3, Offset(0,8)`) with `AppDecorations.elevation(1)`. Level 0 when disabled/loading/success.
  - Sub-step 4.1b.12: Keep ALL existing constructor params unchanged. Add new optional params only: `isDisabled`, `onSuccess`, `isError`.
- [ ] (`@Architect`) Review: backward compatible. All 21 feature files compile. Material+InkWell ripple preserved.
- [ ] (`@Sentinel`) `flutter analyze` clean.
- [ ] (`@Sentinel`) `flutter test` — zero new failures across all 21 affected feature tests.
- [ ] (`@Pixel`) Write `test/core/widgets/app_button_test.dart`:
  - Test: renders text.
  - Test: fires onPressed.
  - Test: shows loading indicator when isLoading=true.
  - Test: disabled state blocks taps.
  - Test: success state shows check icon then reverts.
  - Test: has Semantics button=true with label, enabled=false during loading/disabled/success.
  - Test: contains Material widget (ripple preserved).
  - Test: icon variant renders icon + text.
- **GATE CHECK:** AppButton supports all 8 states. 21 feature files verified.

### 4.2 AppTextField — Clear Button + Password Toggle + Counter + Accessibility

**Sub-phase 4.2a: Convert StatelessWidget → StatefulWidget + Password Toggle**
- [ ] (`@Pixel` | Skill: `clarify`) Convert `AppTextField` from `StatelessWidget` to `StatefulWidget`. Needed for: internal obscure toggle state, listening to controller for clear button visibility, and future error shake animation.
  - Sub-step 4.2a.1: Add `showPasswordToggle` parameter (optional, default false). When true and `obscureText` is initially true, show eye icon toggle as suffix. Maintain internal `_obscureText` state that toggles on icon tap.
  - Sub-step 4.2a.2: Add `Semantics(textField: true, label: hintText)` wrapper.
  - Sub-step 4.2a.3: Keep ALL existing constructor params. Add new optional params only.
- [ ] (`@Sentinel`) `flutter analyze` clean. `flutter test` — zero new failures.

**Sub-phase 4.2b: Clear Button + Character Counter**
- [ ] (`@Pixel` | Skill: `clarify`) In `lib/core/widgets/app_text_field.dart`:
  - Sub-step 4.2b.1: Add `showClearButton` parameter (optional, default false). When true and field has value, show animated X icon (fade in `AppMotion.micro`).
  - Sub-step 4.2b.2: **Suffix composition:** When BOTH `showClearButton` and `showPasswordToggle` are true, compose a `Row(mainAxisSize: MainAxisSize.min)` containing both icons (password toggle first, then clear X). Each icon has its own `GestureDetector` and `Semantics` label. Hit testing and accessibility order preserved.
  - Sub-step 4.2b.3: If user provides `suffixIcon` via constructor, it takes priority over clear/toggle (backward compatibility).
  - Sub-step 4.2b.4: Add `maxLength` parameter (optional). When set, show live character counter below field (right-aligned, AppTypography.caption, textTertiary color).
  - Sub-step 4.2b.5: Internal `TextEditingController` management: if user provides `controller`, use it. If not and `showClearButton` is true, create an internal one. Dispose safely — never dispose user-provided controllers, only internally-created ones.
- [ ] (`@Sentinel`) `flutter analyze` clean. `flutter test` — zero new failures.
- [ ] (`@Pixel`) Write `test/core/widgets/app_text_field_test.dart`:
  - Test: renders with hintText.
  - Test: calls onChanged when text entered.
  - Test: validator shows error.
  - Test: clear button appears when text entered (showClearButton=true).
  - Test: password toggle switches obscureText.
  - Test: both clear + toggle shown simultaneously when both enabled.
  - Test: character counter shows current/max.
  - Test: has Semantics textField=true.
  - Test: user-provided suffixIcon takes priority over clear/toggle.
- **GATE CHECK:** AppTextField redesigned. Tests pass.

### 4.3 CircleIconButton — Haptics + Accessibility
- [ ] (`@Pixel` | Skill: `harden`) In `lib/core/widgets/circle_icon_button.dart`:
  - Sub-step 4.3.1: Wrap in ScaleButton for press feedback.
  - Sub-step 4.3.2: Add `AppInteractionStates.hapticTap()` on tap.
  - Sub-step 4.3.3: Add `tooltip` optional parameter.
  - Sub-step 4.3.4: Add `Semantics(button: true, label: tooltip ?? '')`.
  - Sub-step 4.3.5: Ensure minimum touch target is 48px (if size < 48, add transparent hit area).
- [ ] (`@Sentinel`) `flutter analyze` clean. `flutter test` — zero new failures.
- [ ] (`@Pixel`) **Update** `test/core/widgets/circle_icon_button_test.dart` (created in Phase 2.2 — add new tests to existing file):
  - Test (new): applies tooltip.
  - Test (new): has Semantics button=true.
  - Test (new): minimum 48px touch target enforced.
  - Test (new): haptic fires on tap.
- [ ] (`@Sentinel`) Run `flutter test test/core/widgets/circle_icon_button_test.dart` — all tests pass (Phase 2.2 baseline + Phase 4.3 additions).
- **GATE CHECK:** CircleIconButton redesigned. Tests pass.

### 4.4 GlassButton → Solid Button (NO GLASS — see .impeccable.md)
- [ ] (`@Pixel` | Skill: `distill`) In `lib/core/widgets/glass_button.dart`:
  - Sub-step 4.4.1: **Remove ALL BackdropFilter / blur logic.** Replace with solid-surface button.
  - Sub-step 4.4.2: Primary style: solid `colorScheme.primary` background + white text.
  - Sub-step 4.4.3: Secondary style: solid `colorScheme.cardBackground` + `colorScheme.primary` text + border.
  - Sub-step 4.4.4: Replace `0.5` disabled opacity with `AppInteractionStates.disabledOpacity`. Forward `disabled` state to the ScaleButton wrapper so that ScaleButton's AbsorbPointer + Opacity also activate.
  - Sub-step 4.4.5: Add `Semantics(button: true, label: text, enabled: !isLoading)`.
  - Sub-step 4.4.6: Verify ScaleButton wrapper provides haptics (from Phase 3.1) and disabled propagation.
  - Sub-step 4.4.7: Remove hardcoded gradient alphas — use solid colors from colorScheme.
- [ ] (`@Sentinel`) `flutter analyze` clean. `flutter test` — zero new failures.
- [ ] (`@Pixel`) Write `test/core/widgets/glass_button_test.dart`:
  - Test: renders text with solid background (no BackdropFilter).
  - Test: fires onPressed.
  - Test: loading state shows spinner.
  - Test: disabled state reduces opacity.
  - Test: primary vs secondary styling differs.
  - Test: has Semantics.
- **GATE CHECK:** GlassButton is now a solid-surface button. Tests pass.

---

## Phase 5: Display Widget Redesign (SignedAvatar, SignedImage, StatusBadge)

**Primary Agent(s):** `@Pixel`
**Goal:** Add shimmer loading, fade-in animations, semantic colors, and accessibility. Architecture violations already fixed in Phase 1.
**Why:** These are the most-visible non-interactive widgets. Loading states need polish, status colors need to use semantic tokens.
**How:** Replace CircularProgressIndicator with shimmer, add fade-in, migrate hardcoded colors.
**Result:** 3 redesigned widgets + 3 test files.

### 5.1 SignedAvatar — Shimmer + Fade-In + Initials Fallback
- [ ] (`@Pixel` | Skill: `delight`) In `lib/core/widgets/signed_avatar.dart`:
  - Sub-step 5.1.1: Replace `CircularProgressIndicator` loading with `SkeletonAvatar` (shimmer circle).
  - Sub-step 5.1.2: Add `FadeTransition` on image load (opacity 0→1, `AppMotion.standard`, `AppMotion.curveDecel`).
  - Sub-step 5.1.3: Add `initials` optional parameter. When image fails to load, show initials in colored circle (gold background, white text) instead of generic person icon.
  - Sub-step 5.1.4: Add optional `showOnlineIndicator` parameter (default false). When true, show 12px green circle with 2px white border at bottom-right.
  - Sub-step 5.1.5: Add `Semantics(image: true, label: 'User avatar')`.
- [ ] (`@Sentinel`) `flutter analyze` clean. `flutter test` — zero new failures.
- [ ] (`@Pixel`) Write `test/core/widgets/signed_avatar_test.dart`:
  - Test: renders shimmer while loading.
  - Test: shows initials fallback on error.
  - Test: online indicator visible when enabled.
  - Test: has Semantics image=true.
- **GATE CHECK:** SignedAvatar redesigned. 14 feature files verified.

### 5.2 SignedImage — Shimmer + Error Retry
- [ ] (`@Pixel` | Skill: `harden`) In `lib/core/widgets/signed_image.dart`:
  - Sub-step 5.2.1: Replace `CircularProgressIndicator` with `SkeletonLoader` rectangle (matching widget dimensions).
  - Sub-step 5.2.2: Add fade-in on load (`AppMotion.standard`).
  - Sub-step 5.2.3: Add error state: show icon + "Tap to retry" text. `GestureDetector` retries `_resolve()`.
  - Sub-step 5.2.4: Add `Semantics(image: true, label: 'Image')`.
- [ ] (`@Sentinel`) `flutter analyze` clean. `flutter test` — zero new failures.
- [ ] (`@Pixel`) Write `test/core/widgets/signed_image_test.dart`:
  - Test: renders shimmer while loading.
  - Test: shows error state on failure.
  - Test: has Semantics.
- **GATE CHECK:** SignedImage redesigned. Tests pass.

### 5.3 StatusBadge — Semantic Colors + Icons + Pulse
- [ ] (`@Pixel` | Skill: `colorize`) In `lib/core/widgets/status_badge.dart`:
  - Sub-step 5.3.1: Replace hardcoded `Colors.green` / `AppColors.lightRed` / `AppColors.gold` / `AppColors.teal` with `colorScheme.success` / `.danger` / `.warning` / `.info` from context.
  - Sub-step 5.3.2: Add `icon` to each status (check_circle for completed, schedule for pending, cancel for cancelled, etc.). Icon always present for colorblind accessibility.
  - Sub-step 5.3.3: Change shape from `RoundedRectangleBorder(r12)` to `StadiumBorder` (pill).
  - Sub-step 5.3.4: Add optional pulse animation on "pending" statuses (subtle opacity 0.7→1.0, `AppMotion.dramatic` duration, 3 repetitions then stop — bounded to prevent battery drain). Pulse activates when `_getColorForStatus()` maps to `colorScheme.warning` (pending, draft, paid_request_pending). No separate "urgent" status is introduced — urgency is handled by countdown widgets in feature code, not by StatusBadge. Use `AppMotion.respectMotion()` to skip pulse on reduced motion.
  - Sub-step 5.3.5: Add `Semantics(label: 'Status: $text')`.
- [ ] (`@Sentinel`) `flutter analyze` clean. `flutter test` — zero new failures.
- [ ] (`@Pixel`) Write `test/core/widgets/status_badge_test.dart`:
  - Test: renders text with correct color.
  - Test: shows icon for each status.
  - Test: has Semantics with status text.
  - Test: pill shape (StadiumBorder).
- **GATE CHECK:** StatusBadge redesigned. Tests pass.

---

## Phase 6: Navigation Widget Redesign (CustomBottomNavBar, SliverTabBarDelegate)

**Primary Agent(s):** `@Pixel`
**Goal:** Migrate nav bar to AppMotion tokens, add labels, badge animation, haptics.
**Why:** The nav bar is visible on every screen. It's the most polished widget but still has hardcoded values.
**How:** Replace 300ms with AppMotion.standard, add labels, animate badges, add haptics.
**Result:** 2 redesigned widgets + test updates.

### 6.1 CustomBottomNavBar — Solid Surface + Labels + Badge Animation + Haptics (NO GLASS)
- [ ] (`@Pixel` | Skill: `delight`) In `lib/core/widgets/custom_bottom_nav_bar.dart`:
  - Sub-step 6.1.0: **Remove ALL BackdropFilter / frosted glass** from nav bar. Replace with solid surface: `colorScheme.cardBackground` + `AppDecorations.elevation(3)` shadow + `colorScheme.cardBorder` border. Remove `_buildLiquidGlassDecoration()` method. Remove `AppDecorations.bottomNavBarDecoration()` usage.
  - Sub-step 6.1.1: Replace `Duration(milliseconds: 300)` → `AppMotion.standard`.
  - Sub-step 6.1.2: Replace `Curves.easeOutBack` → `AppMotion.curveSpring`.
  - Sub-step 6.1.3: Replace `Curves.easeOutCubic` → `AppMotion.curveStandard`.
  - Sub-step 6.1.4: Replace `Tween<double>(1.0, 1.15)` → `Tween<double>(1.0, AppMotion.badgeEntrance)`.
  - Sub-step 6.1.5: Add `HapticFeedback.selectionClick()` in `_onTap`.
  - Sub-step 6.1.6: Add tiny label text below each icon (AppTypography.micro, fades in when active, out when inactive).
  - Sub-step 6.1.7: Change notification badge from 10x10 dot to pill with count text (max "99+"). Animate entrance with scale spring.
  - Sub-step 6.1.8: Add `Semantics` to each nav item (label: item.label, selected: isActive).
  - Sub-step 6.1.9: Replace hardcoded alpha values and sizes with AppDimens/AppColors where applicable.
- [ ] (`@Sentinel`) `flutter analyze` clean. `flutter test` — zero new failures.
- [ ] (`@Pixel`) Update `test/widget/app/main_navigation_screen_test.dart` if needed for new labels/badges.
- [ ] (`@Pixel`) Write `test/core/widgets/custom_bottom_nav_bar_test.dart`:
  - Test: renders 6 navigation items.
  - Test: active item has label visible.
  - Test: notification badge shows count.
  - Test: each item has Semantics with label.
- **GATE CHECK:** CustomBottomNavBar migrated. Nav still works.

### 6.2 SliverTabBarDelegate — Minimal Polish (NO GLASS)
- [ ] (`@Pixel` | Skill: `polish`) In `lib/core/widgets/sliver_tab_bar_delegate.dart`:
  - Sub-step 6.2.1: Add solid `colorScheme.cardBackground` when pinned (no blur — per NO GLASS POLICY).
  - Sub-step 6.2.2: Add bottom border when pinned (1px, `colorScheme.divider`).
- [ ] (`@Sentinel`) `flutter analyze` clean. Test file already exists from Phase 2.
- **GATE CHECK:** SliverTabBarDelegate polished.

---

## Phase 7: Skeleton Expansion

**Primary Agent(s):** `@Pixel`
**Goal:** Add 8 new skeleton card variants matching real card layouts across the app.
**Why:** Every list/grid screen needs skeleton loading. Currently only 6 exist, missing 8+ card types.
**How:** Create skeleton variants matching the real widget layouts (dimensions, spacing, shapes).
**Result:** 8 new skeleton classes. skeleton_card.dart may be split if too large.

### 7.1 Assess File Size + Split Decision
- [ ] (`@Pixel`) Count current skeleton_card.dart lines (517). Adding 8 skeletons at ~40-60 lines each = 320-480 new lines. Total would be 837-997 lines.
- [ ] (`@Pixel`) If projected total > 800 lines: split into `skeleton_card.dart` (existing 6) + `skeleton_card_extended.dart` (new 8). Export both from a barrel file or keep separate imports.
- [ ] (`@Architect`) Review split decision.

### 7.2 Create New Skeleton Variants

**Implementation pattern:** Each skeleton is a separate `StatelessWidget` class (same pattern as existing `SkeletonTaskCard`, `SkeletonBookingCard`, etc.). NOT factory constructors — separate classes allow independent import and tree-shaking. Place all 8 in `skeleton_card_extended.dart` (per Phase 7.1 split decision). Export from that file. Feature code imports the specific skeleton it needs.

- [ ] (`@Pixel` | Skill: `extract`) Create 8 new skeleton `StatelessWidget` classes in `lib/core/widgets/skeleton_card_extended.dart`:
  - Sub-step 7.2.1: `SkeletonWalletHeroCard` — gradient placeholder, shimmer balance text, chip row.
  - Sub-step 7.2.2: `SkeletonProposalTile` — avatar circle + 2 text lines + price line.
  - Sub-step 7.2.3: `SkeletonWorkItemCard` — colored header bar + body lines + button area.
  - Sub-step 7.2.4: `SkeletonNotificationTile` — icon circle + 2 lines + time placeholder.
  - Sub-step 7.2.5: `SkeletonServiceCard` — image rectangle + title + price.
  - Sub-step 7.2.6: `SkeletonFavoriteCard` — avatar + name line + stats row.
  - Sub-step 7.2.7: `SkeletonSearchResultCard` — avatar + 2 lines + tag row.
  - Sub-step 7.2.8: `SkeletonProfileCard` — large avatar + 3 text lines + stats row.
- [ ] (`@Sentinel`) `flutter analyze` clean.
- [ ] (`@Pixel`) Write `test/core/widgets/skeleton_card_test.dart`:
  - Test: each skeleton variant renders without error.
  - Test: skeletons match expected dimensions.
- **GATE CHECK:** 8 new skeletons created. All render correctly.

### 7.3 Migrate SkeletonLoader to AppMotion
- [ ] (`@Pixel` | Skill: `normalize`) In `lib/core/widgets/skeleton_loader.dart`:
  - Sub-step 7.3.1: Replace `Duration(milliseconds: 1500)` → `AppMotion.shimmer`.
  - Sub-step 7.3.2: Replace `Curves.easeInOutSine` → `AppMotion.curveSymmetric`.
- [ ] (`@Sentinel`) `flutter analyze` clean. `flutter test` — zero new failures.
- **GATE CHECK:** SkeletonLoader uses AppMotion tokens.

---

## Phase 8: Button Theme Completion (Deferred from Phase 0 LOW-2)

**Primary Agent(s):** `@Pixel`
**Goal:** Add TextButtonTheme and OutlinedButtonTheme to app_theme.dart.
**Why:** Only ElevatedButtonTheme was themed in Phase 0. TextButton and OutlinedButton use Material defaults.
**How:** Add matching themes in `_buildTheme()`.
**Result:** Updated app_theme.dart with 2 additional component themes.

### 8.1 Add TextButtonTheme
- [ ] (`@Pixel` | Skill: `normalize`) In `lib/core/theme/app_theme.dart`:
  - Sub-step 8.1.1: Add `textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: appColorScheme.primary, textStyle: AppTypography.bodyMedium, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.r14)), padding: EdgeInsets.symmetric(horizontal: AppDimens.p16, vertical: AppDimens.p12)))`. All values reference existing tokens — no hardcoded values.

### 8.2 Add OutlinedButtonTheme
- [ ] (`@Pixel` | Skill: `normalize`) In `lib/core/theme/app_theme.dart`:
  - Sub-step 8.2.1: Add `outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(foregroundColor: appColorScheme.primary, side: BorderSide(color: appColorScheme.primary, width: 1), textStyle: AppTypography.bodyMedium, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.r14)), padding: EdgeInsets.symmetric(horizontal: AppDimens.p16, vertical: AppDimens.p12)))`. All values reference existing tokens.
- [ ] (`@Sentinel`) `flutter analyze` clean. `flutter test` — zero new failures.
- **GATE CHECK:** 9 total component themes (7 from Phase 0 + 2 new).

---

## Phase 9: QA + Verification (MANDATORY)

**Primary Agent(s):** `@Sentinel`, `@CodeGuard`

### 9.1 Static Analysis
- [ ] (`@Sentinel`) Run `flutter analyze` — zero errors, zero warnings.
- [ ] (`@Sentinel`) Run `dart format .` — zero changes.

### 9.2 Test Suite
- [ ] (`@Sentinel`) Run `flutter test` — record total, passed, failed, skipped.
- [ ] (`@Sentinel`) Compare against Phase 0.3 baseline (1195/30/1). New tests should ADD to the passed count. Zero new failures.
- [ ] (`@Sentinel`) Run `flutter test test/core/widgets/` — all new component tests pass.

### 9.3 Architecture Verification
- [ ] (`@Sentinel`) Grep for `import.*features/` in ALL `lib/core/widgets/*.dart` — must return 0 total.
- [ ] (`@Sentinel`) Grep for `Duration(milliseconds:` in `lib/core/widgets/` — should return 0 (all migrated to AppMotion).
- [ ] (`@Sentinel`) Grep for `Curves\.` in `lib/core/widgets/` — should return 0 (all migrated to AppMotion).
- [ ] (`@Sentinel`) Grep for `HapticFeedback` in `lib/core/widgets/` — should return >= 4 (ScaleButton, CircleIconButton, CustomBottomNavBar, AppButton via ScaleButton).
- [ ] (`@Sentinel`) Grep for `Semantics` in `lib/core/widgets/` — should return >= 8 (one per interactive widget).

### 9.4 Backward Compatibility Verification
- [ ] (`@Sentinel`) Confirm no feature files in `lib/features/` were modified except for architecture-fix import paths (WorkItem moved to core in Phase 1.3 — 6 dashboard files updated import path only, zero logic changes).
- [ ] (`@Sentinel`) Confirm all existing widget constructor parameters remain unchanged (no removals, no type changes). New optional params only.

### 9.5 Visual Spot Check
- [ ] (`@Pixel` | Skill: `audit`) Run app on emulator. Navigate to: Home, Dashboard, Chat, Profile, Task Details. Verify:
  - Buttons have press feedback (scale + haptic + ripple).
  - Containers render with solid backgrounds (NO glass/blur anywhere).
  - Status badges show icons + pill shape.
  - Bottom nav has labels and badge counts.
  - No visual regressions.
- **GATE CHECK:** All checks pass. Ready to commit.

---

## 7) Acceptance Criteria (MANDATORY)

1. All 14 widgets in `lib/core/widgets/` use AppMotion tokens (zero hardcoded Duration or Curves).
2. All interactive widgets have `Semantics` labels.
3. All tappable widgets have `HapticFeedback`.
4. Zero `import.*features/` in `lib/core/widgets/`.
5. AppButton supports all 8 interaction states: default (base), hover (via InkWell hoverColor on desktop), focus (via InkWell focusColor for keyboard), active/pressed (ScaleButton scale + InkWell ripple), disabled (`isDisabled`), loading (`isLoading`), success (`onSuccess` flash), error (`isError` flash).
6. GlassContainer is a solid-surface container (NO glass/blur) using `cardBackground` + `cardBorder` + `elevation()` shadow.
7. SignedAvatar uses shimmer loading + initials fallback.
8. StatusBadge uses semantic colors from AppColorScheme.
9. 8 new skeleton card variants created.
10. TextButtonTheme + OutlinedButtonTheme added to app_theme.dart.
11. `test/core/widgets/` directory exists with >= 12 test files.
12. `flutter analyze` passes with zero errors.
13. `flutter test` passes with zero new failures + new tests passing.
14. No feature files (`lib/features/`) modified (except architecture fixes moving models/interfaces to core).
15. All constructor changes are backward-compatible (optional params only).

## 8) Rollback Plan

- **Architecture fixes (Phase 1):** Can be reverted by restoring original imports. Interface files in core can be deleted.
- **Widget redesigns (Phases 3-6):** Each widget is independently revertible via git revert of its commit. Constructor backward compatibility means feature files don't need reverting.
- **Skeleton expansion (Phase 7):** New skeleton files can be deleted. No feature code depends on them yet.
- **Button themes (Phase 8):** Can be removed from app_theme.dart. Material defaults take over.
- **Commit strategy:** One commit per phase (9 commits total). Each independently revertible.

## 9) References (From Scan)

### Docs Scanned
- Sline_everything/DEVELOPER_GUIDE.md — v2.22.0
- Sline_everything/STRUCTURE.md — 2026-04-07
- .TODO/PLAN_UI_Redesign_MasterPlan_2026-04-06.md — Phase 1 specs
- .TODO/PLAN_DesignSystemFoundation_2026-04-07.md — Phase 0 completion
- .TODO/PLAN_CRITIQUE_2026-04-07_DesignSystemFoundation.md — Deferred items
- .TODO/MASTER_REPORT_2026-04-07_DesignSystemFoundation.md — Orchestrator findings
- docs/LOG/SESSION_PLAN_DesignSystemFoundation_2026-04-07.md — Execution evidence

### Code Paths Scanned
- lib/core/widgets/ — all 14 files (2,362 lines total)
- lib/core/theme/ — all 8 files (Phase 0 tokens)
- lib/core/utils/app_animations.dart — migrated SpringButton/AnimatedRotationButton
- test/core/widgets/ — does NOT exist (to be created)
- test/test_support/pump_app.dart — base test helper
- test/helpers/ — mock services and ViewModels

### Session Log
- **Path:** docs/LOG/SESSION_PLAN_CoreWidgetRedesign_2026-04-07.md

## 10) Scan Evidence (Mandatory Appendix)

### File Line Counts
| File | Lines | Blast Radius |
|------|-------|-------------|
| app_button.dart | 126 | 21 files |
| app_text_field.dart | 73 | 15 files |
| circle_icon_button.dart | 46 | 1 file |
| scale_button.dart | 77 | 2 files (glass_button, glass_card) |
| glass_button.dart | 132 | 0 feature files |
| glass_card.dart | 47 | 8 files |
| glass_container.dart | 60 | 21 files |
| custom_bottom_nav_bar.dart | 391 | 1 file (main_nav) |
| signed_avatar.dart | 302 | 14 files |
| signed_image.dart | 219 | 8 files |
| skeleton_loader.dart | 159 | 1 file (skeleton_card) |
| skeleton_card.dart | 517 | 5 files |
| status_badge.dart | 135 | 6 files |
| sliver_tab_bar_delegate.dart | 34 | 1 file |
| **TOTAL** | **2,362** | — |

### Architecture Violations
| Widget | Violation | Import |
|--------|-----------|--------|
| signed_avatar.dart | features/profile | `features/profile/services/avatar_service.dart` |
| signed_image.dart | features/tasks | `features/tasks/services/task_image_service.dart` |
| status_badge.dart | features/dashboard | `features/dashboard/models/work_item.dart` |

### Animation Baseline (Pre-Migration)
| Widget | Duration | Curve | Token After |
|--------|----------|-------|------------|
| scale_button | 100ms | easeInOut | AppMotion.micro + curveSpring |
| custom_bottom_nav_bar | 300ms | easeOutBack/easeOutCubic | AppMotion.standard + curveSpring/curveStandard |
| skeleton_loader | 1500ms | easeInOutSine | AppMotion.shimmer + curveSymmetric |

### Test Infrastructure
- Existing component tests: 0
- Test helper: test/test_support/pump_app.dart (19 lines)
- Mock services: test/helpers/mock_services.dart (18 mocks)
- Mock ViewModels: test/helpers/mock_view_models.dart (12 mocks)
- Baseline: 1195 passed, 30 skipped, 1 pre-existing failure

END.
