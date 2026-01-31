# Phase 4: Search, Profile & Polish Implementation Plan

## Overview
Implement robust search capabilities, enhance the profile with portfolio/history aggregation, and apply the final "Liquid Glass" polish.

## Prerequisites
- Phase 3 (Dashboard) completion.
- Supabase migrations must run first for Search RPCs.

## Phase 0: Strategic Planning (Completed)

## Phase 4.1: Search Engine

**Goal:** Allow Clients to find Freelancers and Freelancers to find Tasks using Full Text Search.
**Agent:** `@Supabase_Ops` for DB, `@Architect` for Code.

1.  **Database Layer (`@Supabase_Ops`)**:
    -   [ ] Create `search_tasks` RPC function.
        -   Params: `query` (text), `category_id` (uuid?), `limit`, `offset`.
        -   Logic: ILIKE or `websearch_to_tsquery` on title/description/skills.
    -   [ ] Create `search_profiles` RPC function.
        -   Params: `query` (text), `role` (text), `limit`.
        -   Logic: ILIKE or `websearch_to_tsquery` on full_name/skills.
    -   [ ] Add GIN indexes on `tasks(title, description)` and `profiles(full_name, skills)`.

2.  **Service Layer (`@Architect`)**:
    -   [ ] Create `lib/features/search/services/search_service.dart`.
    -   [ ] Implement `searchTasks` and `searchFreelancers`.
    -   [ ] Create `lib/features/search/models/search_result_model.dart` (or reuse existing).

3.  **ViewModel (`@Architect`)**:
    -   [ ] Create `lib/features/search/viewmodels/search_view_model.dart`.
    -   [ ] Handle debounced search input.

4.  **UI (`@Pixel`)**:
    -   [ ] Create `lib/features/search/view/search_screen.dart`.
    -   [ ] Use `GlassTextField` for search bar.
    -   [ ] Tabs: "Find Work" (Freelancer) / "Find Talent" (Client).

## Phase 4.2: Profile & Portfolio Upgrade

**Goal:** A rich profile showing both uploaded portfolio items and platform capabilities.
**Agent:** `@Architect` & `@Pixel`.

1.  **Portfolio Logic (`@Architect`)**:
    -   [ ] Update `PortfolioViewModel` (or create `ProfileViewModel` aggregation).
    -   [ ] Fetch "Verified History" via `TaskService.getTasksByUser(status='closed')`.
    -   [ ] Fetch "Portfolio Gallery" via `PortfolioService.listItems()`.

2.  **Profile UI (`@Pixel`)**:
    -   [ ] Refactor `PublicProfileScreen` tabs.
    -   [ ] Tab 1: **About** (Bio, Skills, Stats).
    -   [ ] Tab 2: **Portfolio** (Grid of images from `portfolio` bucket).
    -   [ ] Tab 3: **History** (List of completed SLine tasks with ratings).

## Phase 4.3: "Liquid" Polish

**Goal:** The "Wow" factor.
**Agent:** `@Pixel`.

1.  **Micro-Animations**:
    -   [ ] Add `flutter_animate` to `GlassCard` (fade in on scroll).
    -   [ ] Add "Scale" effect to all buttons using `ScaleButton`.
    -   [ ] Add "Shimmer" loading states for search results.

2.  **Empty States**:
    -   [ ] Create beautiful SVG/Icon illustrations for "No Results", "No History".

## Verification Plan
- **Search**: Run SQL `search_tasks('logo')` matches. UI shows results.
- **Profile**: Verify History updates when a task is closed.
- **Polish**: Navigate app, check animations feel smooth (60fps).
