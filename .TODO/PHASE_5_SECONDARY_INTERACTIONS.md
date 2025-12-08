# 👤 Phase 5: Secondary Interactions Implementation Plan

**Status:** Completed
**Agent:** @SlinePlanner
**Source:** `.TODO/New_Design/PublicProfile/`
**Target:** `lib/features/profile/`

This document outlines the plan to implement "Secondary Interactions" – specifically the Public Profile View. This is crucial for the marketplace experience, allowing clients to view freelancer details before hiring.

---

## 1. 🏗️ Public Profile Architecture

**Goal:** Create a reusable, visually rich profile screen that can be viewed by any user (client or freelancer).

### 1.1. UI Components (`lib/features/profile/view/widgets/`)
We will break down the complex `PublicProfileModal.tsx` into manageable widgets.

*   **`PublicProfileHeader`**: The top section with the gradient background, back button, and overlapping avatar.
*   **`PublicProfileStats`**: The row showing Job Success, Total Jobs, and Hourly Rate.
*   **`PublicProfilePortfolio`**: A grid view of the user's portfolio items.
*   **`PublicProfileReviews`**: A list of recent reviews.
*   **`PublicProfileBottomBar`**: The sticky action bar ("Message", "Hire Now").

### 1.2. Logic & State (`lib/features/profile/viewmodels/`)
We need a `PublicProfileViewModel` to handle fetching data for a *specific* user ID (distinct from the current user's `ProfileViewModel`).

*   **`PublicProfileViewModel`**:
    *   `loadProfile(String userId)`: Fetches public profile data.
    *   `isLoading`: Loading state.
    *   `profile`: The `FreelancerProfile` object.

### 1.3. Navigation
*   **Route**: `/public-profile/:id`
*   **Entry Points**:
    *   Task Details -> Click Author Name/Avatar.
    *   Proposal Details -> Click Freelancer Name/Avatar.

---

## 2. 🚀 Implementation Steps

### Step 1: ViewModel & Repository
*   **Task:** Create `lib/features/profile/viewmodels/public_profile_view_model.dart`.
*   **Action:** Define the `PublicProfileViewModel` class. For now, it can use the same repository as the main profile or a dedicated `PublicProfileRepository` if the data structure differs significantly (often public profiles exclude private data like email/balance).
*   **Mocking:** Initially, `loadProfile` can return the `mockFreelancerProfile` data to match the UI design phase.

### Step 2: Widgets Construction
*   **Task:** Create the sub-widgets in `lib/features/profile/view/widgets/public_profile/`.
    *   `public_profile_header.dart`
    *   `public_profile_stats.dart`
    *   `public_profile_portfolio.dart`
    *   `public_profile_reviews.dart`
*   **Design:** Use `GlassContainer`, `AppColors`, and `AppTypography` to match the Figma/React reference.

### Step 3: Screen Assembly
*   **Task:** Create `lib/features/profile/view/public_profile_screen.dart` (replacing the placeholder modal if needed, or refining it).
*   **Action:**
    *   Use `Scaffold` with transparent background.
    *   Use `CustomScrollView` to allow the header to scroll away but keep the bottom bar pinned (or use a Stack).
    *   Inject `PublicProfileViewModel`.

### Step 4: Wiring Navigation
*   **Task:** Update `TaskDetailsScreen` and `ProposalDetailsModal`.
*   **Action:** Replace the `Navigator.push` to the placeholder with a push to the new `PublicProfileScreen`, passing the `userId`.

---

## 3. 🔮 Future Connections (Backend)

*   [ ] **Database**: Ensure `profiles` table has `bio`, `hourly_rate`, `job_success_score`, `total_jobs`.
*   [ ] **Portfolio**: Create `portfolio_items` table.
*   [ ] **Reviews**: Create `reviews` table.

---

## 4. 🛠️ Execution Plan

1.  [x] **Create ViewModel:** Set up the state management.
2.  [x] **Refactor Modal to Screen:** Convert the existing `PublicProfileModal` (if it exists as a single large file) into a proper Screen with broken-down widgets.
3.  [x] **Connect Data:** Bind the UI to the ViewModel's `profile` object instead of a raw Map.
4.  [x] **Link:** Verify navigation from Task Details.