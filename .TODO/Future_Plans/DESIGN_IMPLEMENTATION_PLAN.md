# 🎨 New Design Implementation Plan

**Status:** Draft
**Agent:** @SlinePlanner
**Source:** `.TODO/New_Design_Code/Organized/`
**Target:** Flutter MVVM Architecture (`lib/`)

This document outlines the strategic plan to migrate the `sline_app` to the new "Glassmorphism" React/Tailwind design. It prioritizes a centralized design system for easy future customization, followed by a step-by-step feature migration.

---

## 1. 🏗️ Phase 1: Design System Architecture (The "Control Center")

**Goal:** Centralize all styling knobs (colors, font sizes, spacing, radius) into one folder so the app is easy to customize later.

### 1.1. Theme Directory Structure (`lib/core/theme/`)
We will expand the existing `lib/core/theme/` to include:

*   **`app_colors.dart`**: Define the new palette (`#146068` Teal, `#93ccce` Light Teal, `#f3bb19` Yellow, etc.).
    *   *Action:* Map React `Theme.ts` colors to static `Color` constants.
*   **`app_typography.dart`**: Define `TextStyles` for Headers, Body, Captions using `GoogleFonts.plusJakartaSans`.
    *   *Action:* Create a static class `AppTypography` with getters like `h1`, `bodySmall`, etc.
*   **`app_dimens.dart`**: Centralize spacing and sizes.
    *   *Action:* Define constants for `padding`, `borderRadius` (e.g., `radius20`, `radius30`), `iconSize`.
*   **`app_theme.dart`**: The main `ThemeData` factory.
    *   *Action:* Combine Colors and Typography into `ThemeData.light()` and `ThemeData.dark()`. Use `ThemeExtension` for custom gradients (Glassmorphism).
*   **`app_decorations.dart`**: **(New)** Reusable `BoxDecoration` for Glassmorphism.
    *   *Action:* Create helpers for "Glass" effects (blur, border, gradient background) that mimic the React `.backdrop-blur-xl` and border logic.

### 1.2. Shared Widgets (`lib/core/widgets/`)
Before building screens, we need the Lego blocks.

*   **`GlassContainer`**: A widget that applies the blur, gradient, and border defined in `app_decorations.dart`.
*   **`AppButton`**: Primary and Secondary buttons matching the design's shadow and radius.
*   **`AppTextField`**: Input fields with the specific border and focus states from `AuthScreens.tsx`.
*   **`CustomBottomNav`**: The floating "Island" navigation bar.

---

## 2. 🚀 Phase 2: Feature Migration (Step-by-Step)

We will implement features in this specific order to ensure dependencies are met.

### Step 1: Authentication (`features/auth`)
*   **Source:** `.TODO/New_Design_Code/Organized/Auth/AuthScreens.tsx`
*   **Task:**
    1.  Update `AuthView` to use the new `GlassContainer` layout.
    2.  Implement the Login/Signup toggle animation.
    3.  Ensure `AuthViewModel` binds to the new inputs.

### Step 2: Core Navigation & Home (`features/home`)
*   **Source:** `.TODO/New_Design_Code/Organized/App.tsx` (Navigation logic) & `Home/HomeView.tsx`
*   **Task:**
    1.  Build the "Main Wrapper" scaffold with the animated gradient background and noise texture.
    2.  Implement the floating `CustomBottomNav`.
    3.  Update `HomeView` with the new Header (Greeting + Search) and `TaskCard` widgets.

### Step 3: Task Discovery (`features/tasks` & `features/booking`)
*   **Source:** `Tenders/TenderListView.tsx` & `Bookings/BookingListView.tsx`
*   **Task:**
    1.  Refactor `TaskTile` to match the new design (Hot badge, gradient overlay).
    2.  Implement the "Tender" vs "Booking" visual distinction.

### Step 4: Task Details & Proposals (`features/task_details`)
*   **Source:** `TaskDetails/TaskDetailsOverlay.tsx`
*   **Task:**
    1.  Create a new route/modal for Task Details.
    2.  Implement the "Submit Proposal" modal (bottom sheet).
    3.  **Gap:** If "Packages" (Basic/Standard/Premium) don't exist in the Flutter model yet, add them to the UI using Demo Data (see Phase 3).

### Step 5: Messaging (`features/chat`)
*   **Source:** `Messages/MessagesListView.tsx` & `ChatOverlay.tsx`
*   **Task:**
    1.  Update the Chat List UI.
    2.  **New Feature:** Implement the "Create Offer" modal in the chat view.
    3.  **New Feature:** Render "Custom Offer" bubbles in the chat stream.

### Step 6: Wallet & Orders (`features/wallet` - NEW, `features/orders` - NEW)
*   **Source:** `Wallet/WalletDashboard.tsx` & `Orders/OrdersDashboard.tsx`
*   **Task:**
    1.  Create new feature folders `lib/features/wallet` and `lib/features/orders`.
    2.  Implement the Glass Credit Card component.
    3.  Implement the Orders tabs (Active, Revision, Completed).

### Step 7: Profile (`features/profile`)
*   **Source:** `Profile/ProfileView.tsx`
*   **Task:**
    1.  Update Profile Header (Avatar + Stats).
    2.  Implement the "Dark Mode" toggle switch in settings.

---

## 3. 🔮 Phase 3: Gap Analysis & Future Tasks

Features present in the Design but potentially missing in the current Flutter Backend/Logic.

**Strategy:** Implement the **UI** fully now using the `MockData.ts` translated to Dart. This allows us to visualize the "Future State" immediately. We will mark these sections with `// TODO: Connect to Backend`.

| Feature | Status | Action |
| :--- | :--- | :--- |
| **Wallet System** | ❌ Missing in Backend | Build `WalletScreen` using mock balance/transactions. |
| **Service Packages** | ❌ Missing in Task Model | Add `packages` list to `Task` model (UI only for now). |
| **Chat Offers** | ❌ Missing in Chat Logic | Build "Offer Bubble" widget. Mock sending an offer. |
| **Advanced Filters** | ❌ Missing Logic | Build `FilterBottomSheet` UI. Logic can wait. |
| **Public Profile** | ⚠️ Partially Exists | Ensure `PublicProfileOverlay` matches the new design. |

---

## 4. 🛠️ Execution Commands

To start, I recommend running these commands to set up the Theme Foundation (Phase 1):

1.  `mkdir -p lib/core/theme`
2.  `touch lib/core/theme/app_theme.dart lib/core/theme/app_colors.dart lib/core/theme/app_typography.dart lib/core/theme/app_dimens.dart lib/core/theme/app_decorations.dart`

(Wait for user confirmation to begin implementing Phase 1).
