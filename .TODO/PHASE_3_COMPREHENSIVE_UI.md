# 🎨 Phase 3: Comprehensive UI Completion

**Status:** Completed
**Agent:** @SlinePlanner
**Source:** `.TODO/New_Design/`
**Target:** `lib/`

This phase focuses on implementing the remaining UI screens and modals to achieve 100% parity with the new design. We will replace placeholders and old screens with the new Glassmorphism implementations.

---

## 1. 🧩 Discovery Tabs (Tenders & Bookings)

The `MainNavigationScreen` currently has placeholders for these tabs.

- [x] **Implement Tenders Screen**
    - **Agent:** `@Pixel`
    - **Source:** `.TODO/New_Design/Tenders/TenderList.tsx`
    - **Task:** Create `lib/features/tasks/view/tenders_screen.dart`.
    - **Specs:** `CustomScrollView` with Header ("Tenders", "Open proposals..."). Use `TaskCard` with `isTender` filter.
    - **Integration:** Update `MainNavigationScreen` to use this widget.

- [x] **Implement Bookings Screen**
    - **Agent:** `@Pixel`
    - **Source:** `.TODO/New_Design/Bookings/BookingList.tsx`
    - **Task:** Create `lib/features/booking/view/bookings_discovery_screen.dart`.
    - **Specs:** `CustomScrollView` with Header ("Bookings", "Direct hire..."). Use `TaskCard` with `isBooking` filter.
    - **Integration:** Update `MainNavigationScreen` to use this widget.

---

## 2. ✨ Create Task Wizard

- [x] **Refactor Create Task Screen**
    - **Agent:** `@Pixel`
    - **Source:** `.TODO/New_Design/CreateTask/CreateTaskModal.tsx`
    - **Task:** Completely refactor `lib/features/tasks/view/create_task_screen.dart`.
    - **Specs:** Implement the 3-step wizard (Concept, Details, Logistics).
        - **Step 1:** Task Type selection (Cards) & Category Grid.
        - **Step 2:** Title, Description, Tags (AppTextFields).
        - **Step 3:** Budget/Deadline (Tender) OR Packages (Booking).
        - **Navigation:** "Next Step" buttons and progress bar.

---

## 3. 🔔 Modals & Overlays (Group 1)

- [x] **Notifications Center**
    - **Agent:** `@Pixel`
    - **Source:** `.TODO/New_Design/Notifications/NotificationsModal.tsx`
    - **Task:** Create `lib/features/notifications/view/notifications_modal.dart`.
    - **Specs:** `GlassContainer` bottom sheet. List notifications grouped by "Today", "Yesterday". Use mock data for now.
    - **Integration:** Wire to the Bell icon in `HomeScreen`.

- [x] **Advanced Filters**
    - **Agent:** `@Pixel`
    - **Source:** `.TODO/New_Design/Filters/FiltersModal.tsx`
    - **Task:** Create `lib/features/home/view/widgets/filters_modal.dart`.
    - **Specs:** Bottom sheet with Sort By chips, Budget Range slider, Delivery Time, Seller Level.
    - **Integration:** Wire to the Filter icon in `HomeScreen` and `MessagesScreen`.

---

## 4. 👤 Modals & Overlays (Group 2)

- [x] **Public Profile**
    - **Agent:** `@Pixel`
    - **Source:** `.TODO/New_Design/PublicProfile/PublicProfileModal.tsx`
    - **Task:** Create `lib/features/profile/view/public_profile_modal.dart`.
    - **Specs:** Full-screen modal with header image, floating avatar, stats row, portfolio grid, reviews list. Sticky bottom action bar ("Hire Now", "Message").
    - **Integration:** Wire to "View Profile" clicks in `TaskDetailsScreen`.

- [x] **Proposal Details**
    - **Agent:** `@Pixel`
    - **Source:** `.TODO/New_Design/ProposalDetails/ProposalDetailsModal.tsx`
    - **Task:** Create `lib/features/proposals/view/proposal_details_modal.dart`.
    - **Specs:** Detailed view of a proposal (Freelancer info, Bid amount, Cover letter, Attachments). "Accept/Decline" buttons.
    - **Integration:** Wire to proposal list items in `TaskDetailsScreen`.

- [x] **Video Call Mock**
    - **Agent:** `@Pixel`
    - **Source:** `.TODO/New_Design/Messages/VideoCallModal.tsx`
    - **Task:** Create `lib/features/chat/view/video_call_modal.dart`.
    - **Specs:** Full-screen mock call UI. Blurred background, pulsing avatar, call controls (Mute, End, Video).
    - **Integration:** Wire to Video icon in `ChatScreen` header.

---

## 5. ❤️ Polish & Legacy Updates

- [x] **Refactor Saved Tasks**
    - **Agent:** `@Pixel`
    - **Task:** Update `lib/features/saved/view/saved_tasks_screen.dart`.
    - **Specs:** Remove standard AppBar. Use `GlassContainer` header. Use `TaskCard` for items. Match the general app aesthetic.

- [x] **Refactor Proposal Submit Sheet**
    - **Agent:** `@Pixel`
    - **Source:** `.TODO/New_Design/ProposalDetails/ProposalSubmitModal.tsx`
    - **Task:** Update `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart`.
    - **Specs:** Match the visual style of the new design (GlassContainer, AppTextFields, File Upload placeholder).