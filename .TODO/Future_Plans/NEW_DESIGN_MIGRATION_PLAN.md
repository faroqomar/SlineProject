# 🎨 New Design Migration Plan (Flutter)

**Status:** Planning
**Agent:** @SlinePlanner
**Source:** `.TODO/New_Design/`
**Target:** `lib/`

This plan outlines the remaining steps to achieve 100% parity with the new "Glassmorphism" React/Tailwind design. It builds upon the work done in Phases 1 & 2.

---

## 🚧 Phase 3: Missing Tabs & Navigation (Immediate)

The `MainNavigationScreen` currently has placeholders for "Tenders" and "Bookings". We need to implement these discovery screens.

### 1. Tenders Discovery Tab
*   **Source:** `.TODO/New_Design/Tenders/TenderList.tsx`
*   **Task:** Create `lib/features/tasks/view/tenders_screen.dart`.
*   **Details:**
    *   Use `CustomScrollView` with `SliverToBoxAdapter` header (Title "Tenders", Subtitle "Open proposals...").
    *   Use `SliverList` rendering `TaskCard` widgets (filtered by `isTender`).
    *   Match the header style from `HomeView` but specific to Tenders.

### 2. Bookings Discovery Tab
*   **Source:** `.TODO/New_Design/Bookings/BookingList.tsx`
*   **Task:** Create `lib/features/booking/view/booking_discovery_screen.dart`.
*   **Details:**
    *   Similar structure to Tenders screen.
    *   Header: "Bookings" / "Direct hire opportunities".
    *   Filter tasks by `isBooking`.

### 3. Navigation Integration
*   **Task:** Update `lib/app/main_navigation_screen.dart` to replace `Center(child: Text(...))` placeholders with the new `TendersScreen` and `BookingDiscoveryScreen`.

---

## 🛠️ Phase 4: Advanced Modals & Flows

The simple screens are done. Now we tackle the complex, multi-state modals.

### 1. Create Task Wizard
*   **Source:** `.TODO/New_Design/CreateTask/CreateTaskModal.tsx`
*   **Target:** `lib/features/tasks/view/create_task_screen.dart` (Refactor)
*   **Task:** Implement the 3-step wizard.
    *   **State:** Manage `step` (1: Concept, 2: Details, 3: Logistics).
    *   **UI:**
        *   Step 1: Big cards for "Request" vs "Service", Category Grid.
        *   Step 2: Title, Description, Tags inputs.
        *   Step 3:
            *   If Tender: Budget, Deadline.
            *   If Booking: Package configuration (Basic/Standard/Premium toggle).
    *   **Animation:** Animated progress bar at top.

### 2. Notifications Center
*   **Source:** `.TODO/New_Design/Notifications/NotificationsModal.tsx`
*   **Target:** `lib/features/notifications/view/notifications_sheet.dart`
*   **Task:** Create a `GlassContainer` bottom sheet/overlay.
    *   Mock data `notifications` list.
    *   Group by "Today", "Yesterday".
    *   Distinct icons for Order, Payment, System.

### 3. Advanced Filters
*   **Source:** `.TODO/New_Design/Filters/FiltersModal.tsx`
*   **Target:** `lib/features/home/view/widgets/filters_sheet.dart`
*   **Task:** Create filter bottom sheet.
    *   Sort By chips.
    *   Budget Range slider (Flutter `RangeSlider`).
    *   Delivery Time chips.
    *   Seller Level checkboxes.
    *   "Apply Filters" button.

---

## 👤 Phase 5: Secondary Interactions

### 1. Public Profile
*   **Source:** `.TODO/New_Design/PublicProfile/PublicProfileModal.tsx`
*   **Target:** `lib/features/profile/view/public_profile_screen.dart`
*   **Task:** Display a user's profile to others.
    *   Header image gradient.
    *   Floating avatar.
    *   Stats row (Job Success, Total Jobs, Hourly).
    *   Portfolio grid.
    *   "Hire Now" / "Message" sticky bottom bar.



---

## ✨ Phase 6: Polish & Animations

*   **Transitions:** Ensure `Navigator` uses `FadeUpwardsPageTransitionsBuilder` or custom slide transitions to match the "modal" feel of the React app.
*   **Micro-interactions:**
    *   Add `Scale` transition on button press (reusable wrapper).
    *   Add `Hero` tags between `TaskCard` images and `TaskDetails` images.
*   **Scroll Physics:** Ensure `BouncingScrollPhysics` is used everywhere.

---

## 🔮 Last Phase: Backend Integration & Future Features

**Goal:** Connect the "Mock Data" UI to real Supabase logic.

### 1. Missing Backend Features
*   **Service Packages:**
    *   [ ] DB: Add `packages` JSONB to `tasks` table.
    *   [ ] Logic: Update `Task` model to parse packages.
*   **Chat Offers:**
    *   [ ] DB: Create `chat_offers` table.
    *   [ ] Logic: Update `ChatService` to handle offer messages types.
*   **Video Call:**
    *   [ ] Logic: Integrate Agora or WebRTC signaling.
*   **Notifications:**
    *   [ ] DB: Create `notifications` table with RLS.
    *   [ ] Logic: Real-time subscription.
*   **Advanced Filters:**
    *   [ ] DB: RPC function for complex filtering.
*   **Wallet:**
    *   [ ] DB: `wallets`, `transactions` tables.
    *   [ ] Logic: Stripe Connect integration.

### 2. Linking Mocks to Real Data
*   **Refactor:** Go through all files marked `// Mock Data` or `// TODO: Connect to Backend` and replace with Provider/ViewModel calls.
