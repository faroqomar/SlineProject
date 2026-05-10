# Plan: Phase 4 — Home & Discovery Redesign

## 1) Goal
- **Goal:** Redesign the HomeScreen, FiltersModal, DiscoveryTaskSliver, SearchScreen, CategoriesScreen, FavoritesScreen, SavedTasksScreen, and FavoriteCard to match the premium design language established in Phases 0-2.
- **Why:** The Home tab is the app's main stage — first thing users see after login. Currently it uses hardcoded 200ms AnimatedContainer for chips, a hardcoded 50x50 filter button with raw BoxShadow, basic CircularProgressIndicator loading, plain text empty states, and minimal animations. The search, categories, favorites, and saved screens have zero design polish (raw Card/ListTile widgets, no skeletons, no animations, no empty state illustrations). These screens represent the core discovery flow — they must feel premium, fluid, and content-first.
- **Result:** 10 view files redesigned with design system tokens, staggered list entrance animations, shimmer loading states, illustrated empty states, refined filter modal, polished search experience. All downstream screens (categories, favorites, saved) brought to the same design quality bar.
- **Architecture:** View layer ONLY. No ViewModel, Service, Repository, or Backend changes. MVVM boundary strictly enforced.

## 2) Scope

### In-Scope
- `lib/features/home/view/home_screen.dart` — greeting, search bar, category chips, task feed, empty/loading states
- `lib/features/home/view/widgets/filters_modal.dart` — DraggableScrollableSheet, filter chips, slider, apply/reset
- `lib/features/tasks/view/widgets/discovery_task_sliver.dart` — staggered card entrance, skeleton loading, empty state
- `lib/features/search/view/search_screen.dart` — search UX, tab toggle, results, empty/loading/error states
- `lib/features/categories/view/categories_screen.dart` — category grid, search, loading/empty states
- `lib/features/favorites/view/favorites_screen.dart` — favorite list, loading/empty states
- `lib/features/favorites/view/widgets/favorite_card.dart` — card redesign with proper layout
- `lib/features/saved/view/saved_tasks_screen.dart` — saved tasks list, loading/empty states
- `lib/core/widgets/skeleton_card.dart` — add missing skeleton variants (SearchResult, Category, Favorite)
- Widget tests for redesigned screens

### Out-of-Scope
- Task card widgets (TaskCard, TenderTaskCard, BookingTaskCard) — already redesigned in Phase 2
- ViewModel changes — all existing state/data contracts are sufficient
- Service/Repository changes — no new queries needed
- Backend/Supabase changes — none
- DiscoveryFeedViewModelContract changes — the contract is stable
- HomeViewModel/TaskFilterViewModel logic — already correct
- Categories ViewModel changes — already working
- SearchViewModel changes — already working (debounce, tab switching)
- FavoritesViewModel changes — already correct (optimistic updates, mutation results)
- SavedTasksViewModel changes — already correct (toggle, auth listener)

## 3) Evidence & Findings (From Scan)

### Existing
- **Design System (Phase 0):** FULLY IMPLEMENTED — AppMotion (7 durations, 7 curves, 4 scales, 3 staggers), AppInteractionStates (8-state model, haptics, focus ring, shake), AppLayout (202 lines, formMaxWidth, screenHorizontalMargin, button heights, avatar sizes, spacing rhythm), AppColors (440 lines with semantic status + interactive state colors), AppDecorations.elevation(5 levels), AppTypography (14 styles with proper line heights)
- **Core Widgets (Phase 1):** ScaleButton (129 lines, press scale 0.96, haptic, disabled, reduced motion), StatusBadge (235 lines, semantic colors, pulse, pill shape), AppButton (294 lines, 8-state model), SignedAvatar (354 lines, signed URLs, online dot)
- **Skeleton Variants (516 lines):** SkeletonTaskCard, SkeletonBookingCard, SkeletonOfferCard, SkeletonMessageBubble, SkeletonConversationTile, SkeletonDetailsScreen + base utilities (SkeletonLoader, SkeletonText, SkeletonAvatar)
- **Route Transitions (Phase 2):** SlinePageRoute with forwardPush/modalSheet/fade. All use AppMotion tokens.
- **Home tab is index 0** in MainNavigationScreen. FAB already has spring entrance + scroll-aware hide/show.
- **TaskCard/TenderTaskCard/BookingTaskCard:** Already redesigned in Phase 2 with ScaleButton, AppDecorations.elevation(), semantic tokens, AppTypography.
- **DiscoveryTaskSliver:** Already handles initial loading (5 skeletons), empty state (icon + text), load-more sentinel with pagination.
- **Existing Tests:** 12 test files cover home, filters, cards, favorites, search, categories, saved tasks.

### Missing
- **HomeScreen animations:** No stagger entrance for task feed cards. Category chips use raw `AnimatedContainer(duration: Duration(milliseconds: 200))` instead of `AppMotion.fast`. Filter button has hardcoded `BoxShadow(color: AppColors.teal.withValues(alpha: 0.3), blurRadius: 10, offset: Offset(0, 5))` instead of AppDecorations.elevation(). Avatar border has hardcoded `AppColors.offWhite.withValues(alpha: 0.2)`.
- **HomeScreen empty state:** Uses basic `Icon(size: 64) + Text` in SliverFillRemaining. No illustration, no CTA button, no helpful description.
- **FiltersModal:** Uses raw `Duration(milliseconds: 200)` for chip animations. ChoiceChip styling hardcoded (selectedColor, shape, labelStyle). Slider hardcoded colors. Section spacing inconsistent. No apply button count ("Apply 3 filters"). No sheet snap points — uses fixed 85% height. No entrance animation.
- **DiscoveryTaskSliver:** Load-more indicator is raw `CircularProgressIndicator()`. Empty state is basic icon + text. No stagger entrance for cards.
- **SearchScreen:** Tab toggle uses raw `AnimatedContainer(duration: Duration(milliseconds: 200))`. Background gradient has hardcoded alpha values. Loading is plain `CircularProgressIndicator`. Error state has raw styling. Empty states are basic icon + text.
- **CategoriesScreen:** Uses raw `Card`, `ListTile`, `CircleAvatar`. Loading is `CircularProgressIndicator` in SizedBox(120). Empty state is plain text. Search field uses raw `InputDecoration`. No category icons, no color coding, no grid layout. Most basic screen in the app.
- **FavoritesScreen:** Loading/error/empty states are all plain text in `Center()`. No skeletons, no illustrations, no CTAs.
- **FavoriteCard:** Uses raw `Card` with `margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8)` — hardcoded. CircleAvatar with `radius: 22` — hardcoded. FilledButton for chat — no design system styling.
- **SavedTasksScreen:** Uses raw `CircularProgressIndicator`, plain text empty state with `bookmark_border` icon at size 64. Header with raw `CircleAvatar` for back button.
- **Skeleton variants missing:** No SkeletonSearchResultCard, no SkeletonCategoryCard, no SkeletonFavoriteCard.
- **Haptic feedback:** Zero HapticFeedback calls in any of these screens (Home, Search, Categories, Favorites, Saved).
- **Semantics:** No Semantics widgets in HomeScreen, FiltersModal, SearchScreen, CategoriesScreen, FavoritesScreen, SavedTasksScreen.
- **Stagger animations:** Zero stagger entrance animations in any list screen.

### Must NOT Duplicate
- TaskCard/TenderTaskCard/BookingTaskCard redesign — already done in Phase 2
- ScaleButton/StatusBadge/AppButton functionality — use existing widgets
- SkeletonTaskCard/SkeletonBookingCard — already exist, don't recreate
- HomeViewModel/TaskFilterViewModel logic — stable, don't touch
- FAB behavior in MainNavigationScreen — already polished in Phase 2

### Conflicts / Risks
- **Typography line-height changes from Phase 0:** Body text at height 1.5 (was 1.2) takes more vertical space. Category chip text, filter labels, empty state text all affected. May need padding adjustments.
- **DiscoveryTaskSliver is shared:** Used by HomeScreen, BookingsDiscoveryScreen, and TendersScreen. Changes to the sliver affect ALL three screens. Stagger entrance must work for all use cases.
- **FavoriteCard onStartChat:** Currently creates or gets a conversation via ChatViewModel. The redesign must preserve this callback chain — UI only changes.
- **SavedTasksViewModel.toggle():** Called from bookmark buttons across multiple card widgets. The saved screen redesign must not break this cross-cutting integration.
- **CategoriesScreen onTap:** Currently has TODO (not implemented). The redesign should NOT implement this — out of scope. Keep the TODO.

## 4) System Impact Map
- **UI:** 10 view files redesigned. All changes are View layer only.
- **MVVM / App Logic:** None. No ViewModel, Service, or Repository changes.
- **Database:** None.
- **RLS / Security:** None.
- **RPC / Edge Functions:** None.
- **Storage:** None.
- **Realtime / Notifications:** None.
- **Observability:** Existing AppLogger calls preserved. No new logging events added.
- **Compatibility & Migration:** DiscoveryTaskSliver changes affect 3 screens (Home, Bookings, Tenders). All tested.
- **Contracts:** None. All data contracts stable.

## 5) Agent Map
- **Phase 0 (Preconditions):** `@Planner`, `@Sentinel`
- **Phase 1 (Codebase Discovery Scan):** `@Pixel`, `@Sentinel`
- **Phase 2 (Skeleton Variants):** `@Pixel`, `@Sentinel`
- **Phase 3 (DiscoveryTaskSliver):** `@Pixel`, `@Sentinel`
- **Phase 4 (HomeScreen):** `@Pixel`, `@Sentinel`
- **Phase 5 (FiltersModal):** `@Pixel`, `@Sentinel`
- **Phase 6 (SearchScreen):** `@Pixel`, `@Sentinel`
- **Phase 7 (CategoriesScreen):** `@Pixel`, `@Sentinel`
- **Phase 8 (FavoritesScreen + FavoriteCard):** `@Pixel`, `@Sentinel`
- **Phase 9 (SavedTasksScreen):** `@Pixel`, `@Sentinel`
- **Phase 10 (QA + Tests):** `@Sentinel`, `@CodeGuard`
- **Phase 11 (Documentation Sync):** `@DocsKeeper`, `@Sentinel`

**Session Log Path:** `docs/LOG/SESSION_PLAN_Phase4_HomeDiscovery_2026-04-08.md`

---

## Phase 0: Preconditions & Gates

**Primary Agent(s):** `@Planner`, `@Sentinel`

### 0.1 Spec Lock
- [ ] (`@Sentinel`) Acceptance criteria defined (see Section 7 below).
- [ ] (`@Architect`) Confirm touched modules: `home/view/`, `home/view/widgets/`, `tasks/view/widgets/discovery_task_sliver.dart`, `search/view/`, `categories/view/`, `favorites/view/`, `favorites/view/widgets/`, `saved/view/`, `core/widgets/skeleton_card.dart`.
- [ ] (`@DocsKeeper`) Confirm Master Plan Phase 4 (Home & Discovery, lines 701-738) + Phase 15.1-15.4 (Secondary Screens) requirements are addressed.
- **GATE CHECK:** Scope, acceptance criteria, and file list are explicit. No ViewModel/Service files in scope.

### 0.2 Design Token Verification
- [ ] (`@Sentinel`) Confirm all Phase 0/1/2 design tokens exist:
  - `AppMotion.fast` (200ms), `AppMotion.standard` (300ms), `AppMotion.emphasis` (500ms)
  - `AppMotion.staggerSmall` (30ms), `AppMotion.staggerMedium` (50ms)
  - `AppMotion.curveDecel`, `AppMotion.curveStandard`, `AppMotion.curveSpring`
  - `AppLayout.screenHorizontalMargin` (24.0), `AppLayout.spacingSection` (16.0), `AppLayout.spacingStandard` (8.0)
  - `AppLayout.avatarMedium` (44.0), `AppLayout.avatarSmall` (36.0)
  - `AppLayout.iconFeature` (48.0), `AppLayout.buttonHeight` (54.0), `AppLayout.buttonHeightCompact` (48.0)
  - `AppDecorations.elevation(1)`, `AppDecorations.elevation(2)`
  - `AppInteractionStates.hapticTap()`, `AppInteractionStates.hapticSelection()`
  - `AppTypography.h3`, `AppTypography.h5`, `AppTypography.bodyLarge`, `AppTypography.bodyMedium`, `AppTypography.bodySmall`, `AppTypography.caption`, `AppTypography.captionBold`, `AppTypography.micro`
  - Semantic colors: `colorScheme.success`, `colorScheme.warning`, `colorScheme.danger`, `colorScheme.info` + muted variants
- **GATE CHECK:** All required tokens confirmed present. No new tokens needed.

### 0.3 MVVM Boundary Lock
- [ ] (`@Architect`) Confirm: NO files in `viewmodels/`, `services/`, `data/`, or `models/` directories are in scope.
- [ ] (`@Architect`) Confirm: All view files use `Consumer<ViewModel>` / `context.read<ViewModel>()` / `context.watch<ViewModel>()` to access state. None import Supabase.
- **GATE CHECK:** Pure View layer redesign confirmed.

---

## Phase 1: Codebase Discovery Scan (MANDATORY)

**Primary Agent(s):** `@Pixel`, `@Sentinel`
**Goal:** Search the codebase for ALL files related to Home, Discovery, Search, Categories, Favorites, and Saved — including any the plan may have missed.
**Why:** Plans are snapshots. Code changes between planning and execution. New widgets, moved files, or expanded features must be caught.
**How:** Grep for feature names, widget class names, and imports of target files across `lib/`.
**Result:** Complete file inventory. Any discovered files reported before implementation begins.

### 1.1 Discovery Scan Execution
- [ ] (`@Pixel`) Grep for `HomeScreen` across `lib/` — find ALL references and callers.
- [ ] (`@Pixel`) Grep for `DiscoveryTaskSliver` across `lib/` — find ALL users (expect: HomeScreen, BookingsDiscoveryScreen, TendersScreen).
- [ ] (`@Pixel`) Grep for `FiltersModal` or `filters_modal` across `lib/` — find ALL references.
- [ ] (`@Pixel`) Grep for `SearchScreen` across `lib/` — find ALL references.
- [ ] (`@Pixel`) Grep for `CategoriesScreen` across `lib/` — find ALL references.
- [ ] (`@Pixel`) Grep for `FavoritesScreen` across `lib/` — find ALL references.
- [ ] (`@Pixel`) Grep for `FavoriteCard` across `lib/` — find ALL references.
- [ ] (`@Pixel`) Grep for `SavedTasksScreen` across `lib/` — find ALL references.
- [ ] (`@Pixel`) Grep for `skeleton_card` across `lib/` — find ALL importers.
- [ ] (`@Pixel`) Check `lib/features/home/` for any new files added since plan creation date (2026-04-08).
- [ ] (`@Pixel`) Check `lib/features/search/` for any new files added since plan creation date.
- [ ] (`@Sentinel`) Compare discovered files against plan scope. Log any additions.
- **GATE CHECK:** Full file inventory documented. Any discovered files assessed and either included or excluded with documented reason.

---

## Phase 2: New Skeleton Variants

**Primary Agent(s):** `@Pixel`
**Goal:** Add missing skeleton loading variants to `skeleton_card.dart` so all redesigned screens have content-matched shimmer placeholders.
**Why:** Currently only SkeletonTaskCard and SkeletonBookingCard exist. Search results, categories, and favorites screens need their own skeleton shapes. Using generic CircularProgressIndicator breaks the premium feel.
**How:** Add 3 new skeleton widgets matching the target card layouts.
**Result:** `skeleton_card.dart` gains SkeletonSearchResultCard, SkeletonCategoryTile, SkeletonFavoriteCard.

### 2.1 Add SkeletonSearchResultCard
- [ ] (`@Pixel` | Skill: `extract`) Add `SkeletonSearchResultCard` to `lib/core/widgets/skeleton_card.dart`:
  - Sub-step 2.1.1: Layout matches search result cards: avatar circle (36px) + two text lines + trailing tag pill.
  - Sub-step 2.1.2: Use existing `SkeletonLoader`, `SkeletonText`, `SkeletonAvatar` base widgets.
  - Sub-step 2.1.3: Padding: `AppDimens.p16` horizontal, `AppDimens.p12` vertical.
  - Sub-step 2.1.4: Border radius: `AppDimens.r16`.
  - Sub-step 2.1.5: Add doc comment: `/// Skeleton placeholder for search result cards.`
- [ ] (`@Sentinel`) Verify widget builds without error in isolation.

### 2.2 Add SkeletonCategoryTile
- [ ] (`@Pixel` | Skill: `extract`) Add `SkeletonCategoryTile` to `lib/core/widgets/skeleton_card.dart`:
  - Sub-step 2.2.1: Layout: icon circle (40px) + title line + subtitle line. Grid-friendly (fixed height).
  - Sub-step 2.2.2: Use existing base skeleton widgets.
  - Sub-step 2.2.3: Padding: `AppDimens.p12` all.
  - Sub-step 2.2.4: Border radius: `AppDimens.r16`.
  - Sub-step 2.2.5: Add doc comment.
- [ ] (`@Sentinel`) Verify widget builds without error.

### 2.3 Add SkeletonFavoriteCard
- [ ] (`@Pixel` | Skill: `extract`) Add `SkeletonFavoriteCard` to `lib/core/widgets/skeleton_card.dart`:
  - Sub-step 2.3.1: Layout matches FavoriteCard target: avatar circle (44px) + name/date lines + action button placeholder.
  - Sub-step 2.3.2: Use existing base skeleton widgets.
  - Sub-step 2.3.3: Padding: `AppDimens.p16` all.
  - Sub-step 2.3.4: Border radius: `AppDimens.r16`.
  - Sub-step 2.3.5: Add doc comment.
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.
- **GATE CHECK:** 3 new skeleton widgets exist. All build without error. `flutter analyze` clean.

---

## Phase 3: DiscoveryTaskSliver Redesign

**Primary Agent(s):** `@Pixel`
**Goal:** Upgrade the shared DiscoveryTaskSliver with staggered card entrance, improved skeleton loading, and a richer empty state.
**Why:** This sliver is used by HomeScreen, BookingsDiscoveryScreen, and TendersScreen. Upgrading it once transforms three screens. Currently load-more uses raw CircularProgressIndicator and empty state is basic icon + text.
**How:** Add stagger entrance animation, replace load-more indicator, enhance empty state.
**Result:** All three consuming screens get premium loading/empty/entrance animations.

### 3.1 Stagger Card Entrance Animation
- [ ] (`@Pixel` | Skill: `animate`) In `lib/features/tasks/view/widgets/discovery_task_sliver.dart`:
  - Sub-step 3.1.1: Wrap each task card in a `SlideTransition` + `FadeTransition` that plays on first build.
  - Sub-step 3.1.2: Stagger delay: `AppMotion.staggerMedium` (50ms) between cards, capped at first 10 cards.
  - Sub-step 3.1.3: Duration: `AppMotion.standard` (300ms) per card.
  - Sub-step 3.1.4: Curve: `AppMotion.curveDecel` (easeOutQuart) for entrance.
  - Sub-step 3.1.5: Slide offset: `Offset(0, 0.05)` — subtle vertical rise.
  - Sub-step 3.1.6: Use `respectMotion` helper — skip animation if reduced motion enabled.
  - Sub-step 3.1.7: Only animate on initial load, NOT on load-more (cards appended to list should appear without stagger).
  - Sub-step 3.1.8: Add doc comment explaining stagger behavior and reduced-motion support.
- [ ] (`@Sentinel`) Verify stagger works on initial load. Verify load-more appends without re-animating existing cards.

### 3.2 Improved Load-More Indicator
- [ ] (`@Pixel` | Skill: `polish`) In `discovery_task_sliver.dart`:
  - Sub-step 3.2.1: Replace `Center(child: CircularProgressIndicator())` with a smaller, themed indicator.
  - Sub-step 3.2.2: Use `SizedBox(height: AppInteractionStates.loadingSize, width: AppInteractionStates.loadingSize)` for spinner.
  - Sub-step 3.2.3: Set `strokeWidth: AppInteractionStates.loadingStrokeWidth`.
  - Sub-step 3.2.4: Color: `colorScheme.primary`.
  - Sub-step 3.2.5: Wrap in `Padding(padding: EdgeInsets.symmetric(vertical: AppDimens.p24))`.
- [ ] (`@Sentinel`) Verify load-more indicator appears and disappears correctly.

### 3.3 Enhanced Empty State
- [ ] (`@Pixel` | Skill: `onboard`) In `discovery_task_sliver.dart`:
  - Sub-step 3.3.1: Replace basic `Icon + Text` with a richer column: icon in colored circle background + title (h5) + description (bodySmall, secondary) + optional CTA button.
  - Sub-step 3.3.2: Icon container: 80x80, `colorScheme.primary.withValues(alpha: 0.08)`, circular.
  - Sub-step 3.3.3: Icon: use `emptyIcon` parameter at `AppLayout.iconFeature` (48px) size, `colorScheme.primary`.
  - Sub-step 3.3.4: Title: `emptyTitle` in `AppTypography.h5`, `colorScheme.text`.
  - Sub-step 3.3.5: Description: "Try adjusting your filters or check back later." in `AppTypography.bodySmall`, `colorScheme.textSecondary`.
  - Sub-step 3.3.6: Center vertically in `SliverFillRemaining(hasScrollBody: false)`.
  - Sub-step 3.3.7: Add `Semantics(label: emptyTitle)` wrapper.
- [ ] (`@Sentinel`) Verify empty state renders correctly with different emptyTitle/emptyIcon values.
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.
- **GATE CHECK:** DiscoveryTaskSliver has stagger entrance, themed load-more, and rich empty state. All three consuming screens verified. `flutter analyze` clean.

---

## Phase 4: HomeScreen Redesign

**Primary Agent(s):** `@Pixel`
**Goal:** Redesign the HomeScreen with refined greeting, polished search bar, animated category chips, and proper spacing using design tokens.
**Why:** The Home tab is the first screen users see. Currently uses hardcoded BoxShadow on filter button, hardcoded 200ms duration on chips, hardcoded avatar border color, and basic empty state. Must feel premium and content-first.
**How:** Replace all hardcoded values with design tokens, add stagger entrance, polish category chip transitions, refine search + filter bar.
**Result:** HomeScreen is polished, token-based, and animated.

### 4.1 Greeting & Avatar Section
- [ ] (`@Pixel` | Skill: `arrange`) In `lib/features/home/view/home_screen.dart`:
  - Sub-step 4.1.1: Replace hardcoded avatar size `52` with `AppLayout.avatarMedium` (44.0) or keep 52 if intentional (verify with current visual).
  - Sub-step 4.1.2: Replace hardcoded border `AppColors.offWhite.withValues(alpha: 0.2)` with `colorScheme.cardBorder`.
  - Sub-step 4.1.3: Add subtle fade-in on greeting text: `FadeTransition` with `AppMotion.standard` duration, `AppMotion.curveDecel` curve.
  - Sub-step 4.1.4: Add `Semantics(label: 'Home screen greeting')` on greeting row.
- [ ] (`@Sentinel`) Verify greeting renders correctly in light and dark mode.

### 4.2 Search Bar & Filter Button
- [ ] (`@Pixel` | Skill: `arrange`) In `home_screen.dart`:
  - Sub-step 4.2.1: Replace filter button `Container(width: 50, height: 50)` with `SizedBox(width: AppLayout.minTouchTarget, height: AppLayout.minTouchTarget)`.
  - Sub-step 4.2.2: Replace filter button `BoxShadow(color: AppColors.teal.withValues(alpha: 0.3), blurRadius: 10, offset: Offset(0, 5))` with `AppDecorations.elevation(1, isDark: isDark)`.
  - Sub-step 4.2.3: Replace filter button border radius with `AppDimens.r14`.
  - Sub-step 4.2.4: Add `Semantics(button: true, label: 'Open filters')` on filter button.
  - Sub-step 4.2.5: Add `AppInteractionStates.hapticTap()` on filter button tap.
  - Sub-step 4.2.6: Wrap filter button in `ScaleButton` for press feedback.
- [ ] (`@Sentinel`) Verify search bar and filter button render correctly. Filter button opens FiltersModal.

### 4.3 Category Chips
- [ ] (`@Pixel` | Skill: `animate`) In `home_screen.dart`:
  - Sub-step 4.3.1: Replace `AnimatedContainer(duration: const Duration(milliseconds: 200))` with `AnimatedContainer(duration: AppMotion.fast, curve: AppMotion.curveStandard)`.
  - Sub-step 4.3.2: Replace chip shadow `BoxShadow(color: AppColors.teal.withValues(alpha: 0.3), blurRadius: 8, offset: Offset(0, 4))` with `AppDecorations.elevation(1, isDark: isDark)` for selected state.
  - Sub-step 4.3.3: Ensure chip padding uses `AppDimens` tokens (currently `symmetric(horizontal: AppDimens.p16, vertical: AppDimens.p10)` — already correct).
  - Sub-step 4.3.4: Add `AppInteractionStates.hapticSelection()` on chip tap.
  - Sub-step 4.3.5: Add `Semantics(selected: isSelected, label: 'Category: $label')` on each chip.
- [ ] (`@Sentinel`) Verify chip animation timing matches AppMotion.fast. Verify haptic fires on tap.

### 4.4 Task Feed Section
- [ ] (`@Pixel` | Skill: `animate`) In `home_screen.dart`:
  - Sub-step 4.4.1: The DiscoveryTaskSliver now handles stagger entrance (Phase 3). Verify it integrates correctly with HomeScreen's CustomScrollView.
  - Sub-step 4.4.2: Add `Semantics(label: 'Task feed')` on the sliver section.
  - Sub-step 4.4.3: Verify pull-to-refresh works with stagger (should NOT re-animate existing cards on refresh — only new data triggers entrance).
- [ ] (`@Sentinel`) Verify pull-to-refresh cycle: loading → skeletons → stagger entrance → stable list.

### 4.5 Loading & Empty States
- [ ] (`@Pixel` | Skill: `onboard`) In `home_screen.dart`:
  - Sub-step 4.5.1: Initial loading already uses SkeletonTaskCard (5x) — verify it still works after DiscoveryTaskSliver changes.
  - Sub-step 4.5.2: Empty state now handled by DiscoveryTaskSliver (Phase 3) — verify the enhanced empty state renders correctly within HomeScreen's context.
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.
- **GATE CHECK:** HomeScreen uses all design tokens. No hardcoded BoxShadow, Duration, or Color values remain. Category chips animated with AppMotion. Filter button has ScaleButton + elevation + haptic. Semantics on key elements. `flutter analyze` clean.

---

## Phase 5: FiltersModal Redesign

**Primary Agent(s):** `@Pixel`
**Goal:** Redesign the FiltersModal with DraggableScrollableSheet snap points, design-token-based styling, filter count on apply button, and entrance animation.
**Why:** Currently uses fixed 85% height container, hardcoded 200ms durations, raw ChoiceChip styling with inline colors, and no apply count. The modal should feel like a polished sheet with spring physics.
**How:** Convert to DraggableScrollableSheet, tokenize all styling, add filter count, add entrance animation.
**Result:** FiltersModal is a premium DraggableScrollableSheet with consistent design language.

### 5.1 Convert to DraggableScrollableSheet
- [ ] (`@Pixel` | Skill: `arrange`) In `lib/features/home/view/widgets/filters_modal.dart`:
  - Sub-step 5.1.1: Replace the fixed `Container(height: MediaQuery.of(context).size.height * 0.85)` with `DraggableScrollableSheet(initialChildSize: 0.7, minChildSize: 0.5, maxChildSize: 0.9, snap: true, snapSizes: [0.5, 0.7, 0.9])`.
  - Sub-step 5.1.2: Wrap content in `DraggableScrollableSheet.builder` → `ListView`.
  - Sub-step 5.1.3: Add drag handle at top: `Center(child: Container(width: 32, height: 4, decoration: BoxDecoration(color: colorScheme.outline, borderRadius: BorderRadius.circular(2))))`.
  - Sub-step 5.1.4: Sheet background: `colorScheme.cardBackground`, border radius `AppDimens.r24` top.
- [ ] (`@Sentinel`) Verify sheet snaps correctly at 50%, 70%, 90%.

### 5.2 Tokenize Filter Styling
- [ ] (`@Pixel` | Skill: `normalize`) In `filters_modal.dart`:
  - Sub-step 5.2.1: Replace ChoiceChip `selectedColor` hardcoded with `colorScheme.primary`.
  - Sub-step 5.2.2: Replace ChoiceChip `backgroundColor` with `colorScheme.inputBackground`.
  - Sub-step 5.2.3: Replace ChoiceChip `shape` border with `colorScheme.inputBorder` (unselected) and `colorScheme.primary` (selected).
  - Sub-step 5.2.4: Replace ChoiceChip label style with `AppTypography.captionBold`.
  - Sub-step 5.2.5: Replace Slider `activeColor` with `colorScheme.primary`.
  - Sub-step 5.2.6: Replace Slider `inactiveColor` with `colorScheme.textSecondary.withValues(alpha: 0.2)`.
  - Sub-step 5.2.7: Replace seller level Container colors with semantic tokens.
  - Sub-step 5.2.8: Replace all `SizedBox(height: N)` spacing with `AppDimens.pN` equivalents.
  - Sub-step 5.2.9: Replace section title text styles with `AppTypography.h5` for main headers and `AppTypography.captionBold` for sub-labels.
- [ ] (`@Sentinel`) Verify all filter sections render correctly in light and dark mode.

### 5.3 Apply Button with Filter Count
- [ ] (`@Pixel` | Skill: `clarify`) In `filters_modal.dart`:
  - Sub-step 5.3.1: Calculate active filter count: count non-default values (sortBy != 'Relevance', minBudget set, maxBudget set, deliveryTimes not empty, sellerLevels not empty).
  - Sub-step 5.3.2: Display count on apply button: "Apply Filters" if count == 0, "Apply N Filters" if count > 0.
  - Sub-step 5.3.3: Apply button uses `AppButton` (not raw button).
  - Sub-step 5.3.4: Reset button: `TextButton` with `AppTypography.captionBold`, `colorScheme.primary` color.
- [ ] (`@Sentinel`) Verify filter count updates correctly as filters are changed.

### 5.4 Entrance Animation & Haptics
- [ ] (`@Pixel` | Skill: `animate`) In `filters_modal.dart`:
  - Sub-step 5.4.1: Add `AppInteractionStates.hapticSelection()` on each ChoiceChip tap.
  - Sub-step 5.4.2: Add `AppInteractionStates.hapticSelection()` on seller level tile tap.
  - Sub-step 5.4.3: Add `Semantics(label: 'Filters panel')` on the sheet.
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.
- **GATE CHECK:** FiltersModal uses DraggableScrollableSheet with snap points. All styling tokenized. Apply button shows filter count. Haptics on selections. `flutter analyze` clean.

---

## Phase 6: SearchScreen Redesign

**Primary Agent(s):** `@Pixel`
**Goal:** Polish the SearchScreen with proper design tokens, skeleton loading, richer empty/error states, and consistent tab toggle.
**Why:** Currently uses hardcoded gradient background with inline alpha values, raw AnimatedContainer(200ms) for tab toggle, raw CircularProgressIndicator, and basic empty states. Search is a core discovery feature — must feel responsive and polished.
**How:** Tokenize all values, add skeletons, enhance states, refine tab toggle.
**Result:** SearchScreen matches premium design language.

### 6.1 Background & Layout
- [ ] (`@Pixel` | Skill: `arrange`) In `lib/features/search/view/search_screen.dart`:
  - Sub-step 6.1.1: Replace gradient background hardcoded alpha values with semantic token references or simplify to solid `colorScheme.background`.
  - Sub-step 6.1.2: Replace `Scaffold(backgroundColor: Colors.transparent, extendBodyBehindAppBar: true)` with standard scaffold if gradient is removed.
  - Sub-step 6.1.3: Ensure search field uses `AppTextField` consistently (already does — verify).
- [ ] (`@Sentinel`) Verify layout in light and dark mode.

### 6.2 Tab Toggle
- [ ] (`@Pixel` | Skill: `normalize`) In `search_screen.dart`:
  - Sub-step 6.2.1: Replace tab toggle `AnimatedContainer(duration: Duration(milliseconds: 200))` with `AnimatedContainer(duration: AppMotion.fast, curve: AppMotion.curveStandard)`.
  - Sub-step 6.2.2: Replace tab toggle colors: selected → `colorScheme.primary` bg, `Colors.white` text; unselected → `Colors.transparent` bg, `colorScheme.textSecondary` text.
  - Sub-step 6.2.3: Replace tab container border with `colorScheme.cardBorder`.
  - Sub-step 6.2.4: Replace text styles with `AppTypography.captionBold`.
  - Sub-step 6.2.5: Add `AppInteractionStates.hapticSelection()` on tab tap.
  - Sub-step 6.2.6: Add `Semantics(selected: isSelected, label: 'Search tab: $label')` on each tab.
- [ ] (`@Sentinel`) Verify tab switching animates with AppMotion.fast.

### 6.3 Loading State
- [ ] (`@Pixel` | Skill: `delight`) In `search_screen.dart`:
  - Sub-step 6.3.1: Replace `Center(child: CircularProgressIndicator())` with a list of `SkeletonSearchResultCard` (5x) for task results or skeleton profile cards for talent results.
  - Sub-step 6.3.2: Use existing `SkeletonTaskCard` for task tab, new `SkeletonSearchResultCard` for profile tab.
- [ ] (`@Sentinel`) Verify skeleton matches the correct tab.

### 6.4 Error State
- [ ] (`@Pixel` | Skill: `clarify`) In `search_screen.dart`:
  - Sub-step 6.4.1: Replace raw error styling with: icon in colored circle (80x80, `colorScheme.danger.withValues(alpha: 0.08)`) + title (`AppTypography.h5`) + message (`AppTypography.bodySmall`, secondary) + "Try Again" `AppButton`.
  - Sub-step 6.4.2: Error icon: `Icons.error_outline` at `AppLayout.iconFeature` (48px), `colorScheme.danger`.
- [ ] (`@Sentinel`) Verify error state displays correctly. Retry button calls vm.retry().

### 6.5 Empty States
- [ ] (`@Pixel` | Skill: `onboard`) In `search_screen.dart`:
  - Sub-step 6.5.1: "Start typing to search" state: icon in circle (80x80, primary alpha 0.08) + `Icons.search` (48px, primary) + "Start typing to search" (h5) + "Find tasks or freelancers" (bodySmall, secondary).
  - Sub-step 6.5.2: "No results" state: icon in circle (80x80, primary alpha 0.08) + `Icons.search_off` (48px, textSecondary) + "No results found" (h5) + "Try different keywords or filters" (bodySmall, secondary).
  - Sub-step 6.5.3: Add `Semantics(label: ...)` on each empty state.
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.
- **GATE CHECK:** SearchScreen tokenized. Tab toggle uses AppMotion. Skeleton loading for both tabs. Rich error and empty states. Semantics. `flutter analyze` clean.

---

## Phase 7: CategoriesScreen Redesign

**Primary Agent(s):** `@Pixel`
**Goal:** Redesign CategoriesScreen from raw ListTile/CircleAvatar to a polished grid with category icons, color coding, skeleton loading, and proper empty state.
**Why:** This is the most basic screen in the app — raw Card, ListTile, CircleAvatar with first-letter fallback. No design tokens used anywhere. Must match the premium feel of the rest of the app.
**How:** Complete visual overhaul. Grid layout with category cards, icon + color per category, design system tokens throughout.
**Result:** CategoriesScreen is a polished, branded grid.

### 7.1 Layout Restructure
- [ ] (`@Pixel` | Skill: `arrange`) In `lib/features/categories/view/categories_screen.dart`:
  - Sub-step 7.1.1: Replace `ListView` with `GridView.builder` (2 columns, crossAxisSpacing: `AppDimens.p12`, mainAxisSpacing: `AppDimens.p12`).
  - Sub-step 7.1.2: Replace `ListTile` items with category cards: `Container` with `colorScheme.cardBackground`, `AppDimens.r16` border radius, `AppDecorations.elevation(1)`, `colorScheme.cardBorder` border.
  - Sub-step 7.1.3: Category card content: icon in colored circle (40px diameter, category color at 10% alpha) + category name (`AppTypography.captionBold`) + item count if available (`AppTypography.micro`, secondary).
  - Sub-step 7.1.4: Wrap each card in `ScaleButton` for press feedback with `AppInteractionStates.hapticTap()`.
  - Sub-step 7.1.5: Card padding: `AppDimens.p16` all.
  - Sub-step 7.1.6: Screen padding: `EdgeInsets.symmetric(horizontal: AppLayout.screenHorizontalMargin)`.
- [ ] (`@Sentinel`) Verify grid renders correctly with various category counts (0, 1, 5, 20+).

### 7.2 Search Field
- [ ] (`@Pixel` | Skill: `clarify`) In `categories_screen.dart`:
  - Sub-step 7.2.1: Replace raw `TextField(decoration: InputDecoration(labelText: 'Search categories'))` with `AppTextField(hintText: 'Search categories', prefixIcon: Icon(Icons.search))`.
  - Sub-step 7.2.2: Place search field above grid with `AppDimens.p16` bottom spacing.
- [ ] (`@Sentinel`) Verify search filtering works after field replacement.

### 7.3 Loading State
- [ ] (`@Pixel` | Skill: `delight`) In `categories_screen.dart`:
  - Sub-step 7.3.1: Replace `SizedBox(height: 120) + Center(child: CircularProgressIndicator())` with `GridView.builder` showing 6x `SkeletonCategoryTile` (from Phase 2).
  - Sub-step 7.3.2: Skeleton grid uses same 2-column layout as real grid.
- [ ] (`@Sentinel`) Verify skeleton layout matches real card layout.

### 7.4 Empty & Error States
- [ ] (`@Pixel` | Skill: `onboard`) In `categories_screen.dart`:
  - Sub-step 7.4.1: Empty state: icon in circle (80x80, primary alpha 0.08) + `Icons.category` (48px, primary) + "No categories found" (h5) + "Try a different search term" (bodySmall, secondary).
  - Sub-step 7.4.2: Error state: icon in circle (80x80, danger alpha 0.08) + `Icons.error_outline` (48px, danger) + error message (bodySmall, secondary) + "Try Again" `AppButton` calling vm.refresh().
  - Sub-step 7.4.3: Replace raw `SizedBox(height: 120)` containers with proper centered layouts.
  - Sub-step 7.4.4: Add `Semantics` labels on empty and error states.
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.
- **GATE CHECK:** CategoriesScreen is a polished grid. All styling tokenized. Skeleton loading. Rich empty/error states. ScaleButton + haptics on cards. `flutter analyze` clean.

---

## Phase 8: FavoritesScreen + FavoriteCard Redesign

**Primary Agent(s):** `@Pixel`
**Goal:** Redesign FavoritesScreen and FavoriteCard with proper design tokens, skeleton loading, polished card layout, and rich empty state.
**Why:** Currently FavoritesScreen uses raw `Center(CircularProgressIndicator)` for loading, plain text for empty/error, and FavoriteCard uses raw Card with hardcoded `margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8)` and `CircleAvatar(radius: 22)`. Zero design polish.
**How:** Token-based redesign of both screen and card.
**Result:** Favorites flow matches premium design language.

### 8.1 FavoriteCard Redesign
- [ ] (`@Pixel` | Skill: `arrange`) In `lib/features/favorites/view/widgets/favorite_card.dart`:
  - Sub-step 8.1.1: Replace raw `Card(margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8))` with `Container` using `colorScheme.cardBackground`, `AppDimens.r16` border radius, `colorScheme.cardBorder` border (1px), `AppDecorations.elevation(1)`.
  - Sub-step 8.1.2: Replace `CircleAvatar(radius: 22)` with `SignedAvatar` at `AppLayout.avatarMedium` (44px) diameter, using `favorite.freelancerAvatar` as the image path.
  - Sub-step 8.1.3: Card padding: `AppDimens.p16` all.
  - Sub-step 8.1.4: Card margin: `EdgeInsets.only(bottom: AppDimens.p12)`.
  - Sub-step 8.1.5: Name: `AppTypography.bodyLarge` with `fontWeight: FontWeight.w700`, max 1 line, ellipsis.
  - Sub-step 8.1.6: Date: `AppTypography.caption`, `colorScheme.textSecondary`.
  - Sub-step 8.1.7: "Start Chat" button: `AppButton` compact variant (`height: AppLayout.buttonHeightSmall`), outlined style.
  - Sub-step 8.1.8: Remove button: `IconButton` with `Icons.delete_outline`, `colorScheme.danger`, size 20.
  - Sub-step 8.1.9: Wrap entire card in `ScaleButton` with `AppInteractionStates.hapticTap()`.
  - Sub-step 8.1.10: Add `Semantics(button: true, label: '${favorite.freelancerName} favorite card')`.
- [ ] (`@Sentinel`) Verify FavoriteCard renders correctly with and without avatar URL.

### 8.2 FavoritesScreen Loading State
- [ ] (`@Pixel` | Skill: `delight`) In `lib/features/favorites/view/favorites_screen.dart`:
  - Sub-step 8.2.1: Replace `Center(child: CircularProgressIndicator())` with `ListView.builder` showing 5x `SkeletonFavoriteCard` (from Phase 2).
  - Sub-step 8.2.2: ListView padding: `EdgeInsets.symmetric(horizontal: AppLayout.screenHorizontalMargin, vertical: AppDimens.p16)`.
- [ ] (`@Sentinel`) Verify skeleton layout matches FavoriteCard layout.

### 8.3 FavoritesScreen Empty & Error States
- [ ] (`@Pixel` | Skill: `onboard`) In `favorites_screen.dart`:
  - Sub-step 8.3.1: Empty state: icon in circle (80x80, primary alpha 0.08) + `Icons.favorite_border` (48px, primary) + "No favorites yet" (h5) + "Find and save your favorite freelancers" (bodySmall, secondary) + "Find Freelancers" CTA `AppButton` (navigates to search or home).
  - Sub-step 8.3.2: Error state: icon in circle (80x80, danger alpha 0.08) + `Icons.error_outline` (48px, danger) + error message + "Try Again" AppButton.
  - Sub-step 8.3.3: Replace raw `Text` error display with styled error card.
  - Sub-step 8.3.4: Add `Semantics` labels on empty and error states.
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.
- **GATE CHECK:** FavoriteCard uses SignedAvatar, AppButton, design tokens. FavoritesScreen has skeleton loading, rich empty/error states. `flutter analyze` clean.

---

## Phase 9: SavedTasksScreen Redesign

**Primary Agent(s):** `@Pixel`
**Goal:** Polish SavedTasksScreen with design tokens, skeleton loading, improved header, and rich empty state.
**Why:** Currently uses raw CircularProgressIndicator, plain text empty state, and a raw CircleAvatar for back button. The header styling is inconsistent with other screens.
**How:** Token-based polish on all elements.
**Result:** SavedTasksScreen matches premium design language.

### 9.1 Header Refinement
- [ ] (`@Pixel` | Skill: `arrange`) In `lib/features/saved/view/saved_tasks_screen.dart`:
  - Sub-step 9.1.1: Back button: Replace raw `CircleAvatar(backgroundColor: colorScheme.cardBackground)` with `ScaleButton` wrapping a `Container(decoration: BoxDecoration(color: colorScheme.cardBackground, shape: BoxShape.circle, border: Border.all(color: colorScheme.cardBorder)))`.
  - Sub-step 9.1.2: Back button size: 40x40 (consistent with `AppLayout.avatarDefault`).
  - Sub-step 9.1.3: Title: `AppTypography.h4` (already correct — verify).
  - Sub-step 9.1.4: Refresh button: add `AppInteractionStates.hapticTap()` on tap.
  - Sub-step 9.1.5: Header padding: verify uses `AppLayout.screenHorizontalMargin`.
  - Sub-step 9.1.6: Add `Semantics(label: 'Saved tasks screen')` on screen.
- [ ] (`@Sentinel`) Verify header layout matches other screens.

### 9.2 Loading State
- [ ] (`@Pixel` | Skill: `delight`) In `saved_tasks_screen.dart`:
  - Sub-step 9.2.1: Replace `SliverFillRemaining(child: Center(child: CircularProgressIndicator()))` with `SliverPadding` + `SliverList` showing 5x `SkeletonTaskCard`.
  - Sub-step 9.2.2: Padding: `EdgeInsets.symmetric(horizontal: AppDimens.p16)`.
- [ ] (`@Sentinel`) Verify skeleton loading matches task card layout.

### 9.3 Empty & Error States
- [ ] (`@Pixel` | Skill: `onboard`) In `saved_tasks_screen.dart`:
  - Sub-step 9.3.1: Empty state: icon in circle (80x80, primary alpha 0.08) + `Icons.bookmark_border` (48px, primary) + "No saved tasks yet" (h5) + "Browse and save tasks you're interested in" (bodySmall, secondary) + "Browse Tasks" CTA AppButton.
  - Sub-step 9.3.2: Error state: icon in circle (80x80, danger alpha 0.08) + error text + "Try Again" AppButton.
  - Sub-step 9.3.3: Replace raw error `Text(style: TextStyle(color: AppColors.lightRed))` with tokenized `colorScheme.danger`.
  - Sub-step 9.3.4: Add `Semantics` labels on empty and error states.
- [ ] (`@Sentinel`) Verify `flutter analyze` passes clean.
- **GATE CHECK:** SavedTasksScreen header polished. Skeleton loading. Rich empty/error states. Design tokens throughout. `flutter analyze` clean.

---

## Phase 10: QA + Verification (MANDATORY)

**Primary Agent(s):** `@Sentinel`, `@CodeGuard`

### 10.1 Static Analysis
- [ ] (`@Sentinel`) Run `flutter analyze` — must pass with zero errors, zero warnings (deprecation infos OK).
- [ ] (`@Sentinel`) Run `dart format .` — must produce no changes.

### 10.2 Test Suite
- [ ] (`@Sentinel`) Run `flutter test` — must produce zero new failures.
- [ ] (`@Sentinel`) If test failures occur, document each failure with file name, test name, and root cause. Fix before proceeding.

### 10.3 MVVM Boundary Verification
- [ ] (`@Sentinel`) Grep all modified view files for `Supabase` import — must find zero.
- [ ] (`@Sentinel`) Grep all modified view files for `SupabaseClient` — must find zero.
- [ ] (`@Sentinel`) Verify no business logic was added to view files (no new service calls, no new data fetching).

### 10.4 Token Compliance Audit
- [ ] (`@Sentinel`) Grep modified files for hardcoded `Duration(milliseconds:` — should be zero (all replaced with AppMotion).
- [ ] (`@Sentinel`) Grep modified files for hardcoded `BoxShadow(` — should be zero (all replaced with AppDecorations.elevation).
- [ ] (`@Sentinel`) Grep modified files for `Color(0x` or `Colors.` — should be zero or minimal (all replaced with colorScheme/AppColors tokens).
- [ ] (`@Sentinel`) Grep modified files for hardcoded `fontSize:` — should be zero (all replaced with AppTypography).

### 10.5 Widget Tests
- [ ] (`@Sentinel`) Update `test/widget/home/home_screen_test.dart` — verify existing tests pass with redesigned HomeScreen. Add test for: category chip haptic, filter button ScaleButton presence.
- [ ] (`@Sentinel`) Update `test/widget/home/filters_modal_test.dart` — verify existing tests pass with DraggableScrollableSheet conversion. Add test for: filter count display on apply button.
- [ ] (`@Sentinel`) Verify `test/widget/cards/task_card_test.dart` and `test/widget/cards/booking_task_card_test.dart` still pass (DiscoveryTaskSliver changes could affect card rendering in tests).
- [ ] (`@Sentinel`) Run full test suite: `flutter test` — document pass/fail/skip counts.

### 10.6 Visual Spot Check
- [ ] (`@Pixel` | Skill: `audit`) Run the app on a device/emulator. Navigate through: Home → tap category chip → open filters → apply → search → categories → favorites → saved tasks. Verify:
  - Stagger entrance on task feed (initial load only)
  - Category chip animation timing feels correct
  - Filter modal snaps at 50%, 70%, 90%
  - Search tab toggle animation matches design
  - Categories grid layout looks good on phone size
  - Empty states render correctly on all screens
  - Dark mode looks correct on all screens
  - No visual regressions from Phase 2 card redesigns
- **GATE CHECK:** All tests pass. Token compliance verified. MVVM boundary intact. Visual spot check clean.

---

## Phase 11: Documentation Sync (MANDATORY)

**Primary Agent(s):** `@DocsKeeper`

### 11.1 Session Log
- [ ] (`@DocsKeeper`) Update `docs/LOG/SESSION_PLAN_Phase4_HomeDiscovery_2026-04-08.md` with all phase completions, metrics, and evidence.

### 11.2 Plan Closure
- [ ] (`@DocsKeeper`) Mark this plan as COMPLETED with final metrics.
- **GATE CHECK:** Session log complete. Plan closed.

---

## 7) Acceptance Criteria (MANDATORY)

1. HomeScreen uses `AppMotion` tokens for all animations (no hardcoded Duration).
2. HomeScreen uses `AppDecorations.elevation()` for all shadows (no hardcoded BoxShadow).
3. HomeScreen filter button wrapped in `ScaleButton` with haptic feedback.
4. Category chips animated with `AppMotion.fast` and `AppMotion.curveStandard`.
5. DiscoveryTaskSliver has staggered card entrance animation (first 10 cards, 50ms delay, 300ms each).
6. DiscoveryTaskSliver has themed load-more indicator (not raw CircularProgressIndicator).
7. DiscoveryTaskSliver has enhanced empty state (icon in circle + title + description).
8. FiltersModal uses DraggableScrollableSheet with snap points (50%, 70%, 90%).
9. FiltersModal apply button shows active filter count.
10. SearchScreen tab toggle uses AppMotion tokens.
11. SearchScreen has skeleton loading for both tabs.
12. SearchScreen has rich error and empty states.
13. CategoriesScreen is a 2-column grid with category cards (not ListTile).
14. CategoriesScreen has skeleton grid loading.
15. FavoriteCard uses SignedAvatar, AppButton, and design tokens (no raw Card/CircleAvatar).
16. FavoritesScreen has skeleton loading and rich empty state with CTA.
17. SavedTasksScreen has skeleton loading, rich empty state with CTA, and polished header.
18. ALL modified screens have `Semantics` labels on key elements.
19. ALL modified screens have `HapticFeedback` on interactive elements.
20. `flutter analyze` passes with zero errors.
21. `flutter test` passes with zero new failures.
22. No View file imports Supabase.
23. No feature files outside the scope list were modified.

## 8) Rollback Plan

- **All changes are View layer only and fully reversible:**
  - All modified view files can be reverted with `git checkout` to pre-phase state.
  - New skeleton variants in `skeleton_card.dart` are additive — removing them doesn't break existing code.
  - No ViewModel, Service, Repository, or Backend changes to revert.
  - No database, RLS, or migration changes.
- **DiscoveryTaskSliver is the highest-risk change:**
  - Used by 3 screens (Home, Bookings, Tenders). If stagger animation causes issues, revert the sliver and all 3 screens return to pre-phase behavior.
  - Forward-fix preference: disable stagger via `respectMotion` flag rather than full revert.
- **Rollback strategy:** `git revert` the Phase 4 commit(s). No backend changes to coordinate.

## 9) References (From Scan)

### Docs Scanned
- `Sline_everything/DEVELOPER_GUIDE.md` — v2.21.0, Phase F
- `.TODO/PLAN_UI_Redesign_MasterPlan_2026-04-06.md` — Phase 4 (lines 701-738), Phase 15 (lines 1287-1308)
- `.TODO/PLAN_DesignSystemFoundation_2026-04-07.md` — Phase 0 token inventory
- `docs/LOG/SESSION_PLAN_Phase2_AppShellAuthCards_2026-04-08.md` — Phase 2 completion evidence (cards, transitions, auth)

### Code Paths Scanned
- `lib/features/home/` — 3 files (home_screen.dart, home_view_model.dart, filters_modal.dart)
- `lib/features/tasks/view/widgets/` — 4 files (task_card.dart, tender_task_card.dart, booking_task_card.dart, discovery_task_sliver.dart)
- `lib/features/tasks/viewmodels/task_filter_view_model.dart`
- `lib/features/search/` — 2 files (search_screen.dart, search_view_model.dart)
- `lib/features/categories/` — 2 files (categories_screen.dart, categories_view_model.dart)
- `lib/features/favorites/` — 3 files (favorites_screen.dart, favorites_view_model.dart, favorite_card.dart)
- `lib/features/saved/` — 2 files (saved_tasks_screen.dart, saved_tasks_view_model.dart)
- `lib/core/widgets/skeleton_card.dart` — 516 lines, 6 existing variants
- `lib/core/theme/` — all 7 theme files verified present with Phase 0 tokens
- `lib/core/widgets/` — ScaleButton, StatusBadge, SignedAvatar, AppButton verified
- `lib/app/main_navigation_screen.dart` — Home tab index 0, FAB behavior verified
- `lib/main.dart` — HomeViewModel provider registration verified

### Existing Tests Verified
- `test/unit/home/home_view_model_test.dart`
- `test/unit/tasks/task_filter_view_model_test.dart`
- `test/unit/search/search_view_model_test.dart`
- `test/unit/categories/categories_view_model_test.dart`
- `test/unit/saved/saved_tasks_view_model_test.dart`
- `test/features/favorites/viewmodels/favorites_view_model_test.dart`
- `test/features/favorites/view/favorites_screen_test.dart`
- `test/widget/home/home_screen_test.dart`
- `test/widget/home/filters_modal_test.dart`
- `test/widget/cards/task_card_test.dart`
- `test/widget/cards/booking_task_card_test.dart`
- `test/core/widgets/skeleton_card_extended_test.dart`

### Existing .TODO/ Artifacts
- `.TODO/PLAN_UI_Redesign_MasterPlan_2026-04-06.md` — parent plan
- `.TODO/PLAN_DesignSystemFoundation_2026-04-07.md` — Phase 0 plan (completed)

---

## 10) Scan Evidence (Mandatory Appendix)

### File Line Counts
| File | Lines | Role |
|------|-------|------|
| `lib/features/home/view/home_screen.dart` | 355 | View — primary target |
| `lib/features/home/viewmodels/home_view_model.dart` | 302 | ViewModel — NOT modified |
| `lib/features/home/view/widgets/filters_modal.dart` | 345 | View — primary target |
| `lib/features/tasks/view/widgets/task_card.dart` | 230 | View — NOT modified (Phase 2 done) |
| `lib/features/tasks/view/widgets/tender_task_card.dart` | 300 | View — NOT modified (Phase 2 done) |
| `lib/features/tasks/view/widgets/booking_task_card.dart` | 450 | View — NOT modified (Phase 2 done) |
| `lib/features/tasks/view/widgets/discovery_task_sliver.dart` | 181 | View — primary target |
| `lib/features/tasks/viewmodels/task_filter_view_model.dart` | 319 | ViewModel — NOT modified |
| `lib/features/search/view/search_screen.dart` | 289 | View — primary target |
| `lib/features/search/viewmodels/search_view_model.dart` | 109 | ViewModel — NOT modified |
| `lib/features/categories/view/categories_screen.dart` | 110 | View — primary target |
| `lib/features/categories/viewmodels/categories_view_model.dart` | 65 | ViewModel — NOT modified |
| `lib/features/favorites/view/favorites_screen.dart` | 162 | View — primary target |
| `lib/features/favorites/viewmodels/favorites_view_model.dart` | 192 | ViewModel — NOT modified |
| `lib/features/favorites/view/widgets/favorite_card.dart` | 73 | View — primary target |
| `lib/features/saved/view/saved_tasks_screen.dart` | 170 | View — primary target |
| `lib/features/saved/viewmodels/saved_tasks_view_model.dart` | 154 | ViewModel — NOT modified |
| `lib/core/widgets/skeleton_card.dart` | 516 | Shared widget — adding 3 variants |
| **Total target lines (View files only)** | **2,271** | |

### Design Token Availability
| Token Category | Source File | Lines | Status |
|---|---|---|---|
| Motion durations & curves | `app_motion.dart` | 117 | Phase 0 ✓ |
| Interaction states & haptics | `app_states.dart` | 114 | Phase 0 ✓ |
| Layout tokens (spacing, sizes) | `app_layout.dart` | 202 | Phase 0 ✓ |
| Semantic + interactive colors | `app_colors.dart` | 440 | Phase 0 ✓ |
| Elevation shadow scale | `app_decorations.dart` | 113 | Phase 0 ✓ |
| Typography with line heights | `app_typography.dart` | 143 | Phase 0 ✓ |
| Spacing primitives | `app_dimens.dart` | 54 | Existing ✓ |

### ViewModel Dependencies (NOT MODIFIED — for reference only)
| ViewModel | Constructor Dependencies | Base Class |
|---|---|---|
| `HomeViewModel` | `TaskService?` (default: `TaskService()`) | `ChangeNotifier` + `RoleSwitchAware` |
| `TaskFilterViewModel` | None (no-arg constructor) | `ChangeNotifier` |
| `SearchViewModel` | `SearchService?` (default: `SearchService()`) | `ChangeNotifier` |
| `CategoriesViewModel` | `CategoriesRepository?` (default: via Supabase) | `ChangeNotifier` |
| `FavoritesViewModel` | `FavoritesService` (required) | `ChangeNotifier` |
| `SavedTasksViewModel` | `SavedTasksService` (required), `SupabaseClient?` | `ChangeNotifier` |

### DiscoveryTaskSliver Consumer Audit
| Consumer | File | Surface | Empty Title | Empty Icon |
|---|---|---|---|---|
| HomeScreen | `home_screen.dart` | 'home' | "No projects found" | `Icons.work_outline` |
| BookingsDiscoveryScreen | `bookings_discovery_screen.dart` | 'booking' | varies | varies |
| TendersScreen | `tenders_screen.dart` | 'tender' | varies | varies |

### Existing Skeleton Variants
| Variant | Exists | Used By |
|---|---|---|
| `SkeletonTaskCard` | ✓ | HomeScreen, TendersScreen |
| `SkeletonBookingCard` | ✓ | BookingsDiscoveryScreen |
| `SkeletonOfferCard` | ✓ | Various |
| `SkeletonMessageBubble` | ✓ | ChatScreen |
| `SkeletonConversationTile` | ✓ | MessagesScreen |
| `SkeletonDetailsScreen` | ✓ | Various detail screens |
| `SkeletonSearchResultCard` | **MISSING** | SearchScreen (to be created) |
| `SkeletonCategoryTile` | **MISSING** | CategoriesScreen (to be created) |
| `SkeletonFavoriteCard` | **MISSING** | FavoritesScreen (to be created) |

### Singleton/Static State
- `RoleSwitchCoordinator` (singleton): HomeViewModel registers with it. NOT modified in this phase. Tests must call `clearForTesting()` in tearDown if HomeViewModel is tested.
- `TaskFilterViewModel`: stateless at construction. No singleton issues.

### Provider Dependencies (for test setup reference)
| Screen | Providers Required | Source |
|---|---|---|
| HomeScreen | `HomeViewModel`, `TaskFilterViewModel`, `SavedTasksViewModel`, `NavigationProvider`, `ProfileViewModel` | `context.watch<>` / `context.read<>` |
| FiltersModal | `TaskFilterViewModel` | `context.read<>` |
| SearchScreen | `SearchViewModel` | `ChangeNotifierProvider.value` |
| CategoriesScreen | `CategoriesViewModel` | `ChangeNotifierProvider` |
| FavoritesScreen | `FavoritesViewModel`, `ChatViewModel` | `context.watch<>` / `context.read<>` |
| SavedTasksScreen | `SavedTasksViewModel` | `context.watch<>` |

END.
