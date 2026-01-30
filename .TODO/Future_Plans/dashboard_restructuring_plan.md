# Dashboard Restructuring Implementation Plan (Phase 3)

## Overview
This plan addresses **Phase 3: Dashboard Restructuring** of the SLine Improvement Plan. The goal is to clean up the navigation, consolidate the "Manage" tab into "Bookings", and enhance the Freelancer Dashboard with pending requests and active bookings.

## Prerequisites
- Working `BookingService` and `TaskService` (Phase 1 completed).
- Existing `DashboardScreen` and `MainNavigationScreen`.

## Phase 0: Strategic Planning (CRITICAL)

**Goal:** Create a perfect, step-by-step implementation plan.
**Agent:** `@SlinePlanner`

- [x] Analyze Context (Completed)
- [x] Draft Implementation Plan (This document)
- [ ] Verify Plan with User

---

## Phase 1: Backend Services

**Goal:** Provide data for the new dashboard sections.
**Agent:** `@Architect`
**Tools:** `@mcp:dart-mcp-server`

1.  **`BookingService` Update**:
    -   File: `lib/features/booking/services/booking_service.dart`
    -   Action: Add `Future<List<BookingModel>> getPendingRequests({int limit})`.
    -   Logic: Fetch bookings with status `paid_request_pending` where current user is provider.
    -   Use `AppLogger` for errors.

2.  **`TaskService` Update**:
    -   File: `lib/features/tasks/services/task_service.dart`
    -   Action: Add `Future<List<TaskRequest>> getPendingPaymentTenders({int limit})`.
    -   Logic: Fetch tasks where `status = 'open'` and `current_user` is freelancer (bidder) and offer is accepted but payment pending? 
    -   *Correction*: The requirement is `TaskService.getPendingPaymentTenders()`. This likely refers to specific tender-related pending items.
    -   *Decision*: Implement `getPendingPaymentTenders` to fetch offers that are in a state requiring action.

---

## Phase 2: UI Structure Refactoring

**Goal:** Clean navigation and improved Freelancer experinece.
**Agent:** `@Pixel`

1.  **Main Navigation**:
    -   File: `lib/app/main_navigation_screen.dart`
    -   Action: Remove "Manage" Tab. Consolidate index.
    -   Update `screens` list.

2.  **Dashboard Screen**:
    -   File: `lib/features/dashboard/view/dashboard_screen.dart`
    -   Action: Update `TabBar` to remove "Manage".
    -   Update `TabBarView`.
    -   Tabs: Overview, Bookings, Work, Inbox.

3.  **Freelancer Work Screen (Refactor)**:
    -   File: `lib/features/dashboard/view/tabs/active_work_tab.dart` (Rename to `WorkTab`)
    -   Action: Implement `DefaultTabController` inside this tab.
    -   Sub-tabs:
        1.  **Active**: Show Active Bookings + Active Orders.
        2.  **Completed**: Show Completed history.
        3.  **Cancelled**: Show Cancelled history.

4.  **Overview Screen**:
    -   File: `lib/features/dashboard/view/tabs/overview_tab.dart`
    -   Action: Add Toggle for "Recent Activity".
    -   Sections: "Pending Requests" (Horizontal Scroll), "Active Bookings" (Vertical List).

5.  **Notifications**:
    -   File: `lib/features/notifications/view/widgets/notification_badge_button.dart`
    -   Action: Ensure Red/Gray badge logic based on `is_read`.
    -   File: `lib/features/notifications/view/notifications_modal.dart`
    -   Action: Add "Mark all as read" button/logic.

---

## Phase 3: Verification & Documentation

**Goal:** Zero regressions and up-to-date truth.
**Agents:** `@Sentinel`, `@SlineDocs`

1.  **Testing**:
    -   Run `flutter analyze`.
    -   Manual verification of the flow.

2.  **Documentation Update**:
    -   Update `MVP_ROADMAP.md` (Mark Phase 3 complete).

---

## Verification Plan

### Automated Tests
- Run `flutter analyze` to ensure no broken imports from removing "Manage" tab.

### Manual Verification
1.  **Navigation**:
    -   Open App -> Check Bottom Bar.
    -   Check Dashboard Tabs: Overview, Bookings, Work, Inbox. No "Manage".
2.  **Freelancer Dashboard**:
    -   Login as Freelancer.
    -   Check "Overview" tab.
    -   Verify "Pending Requests" section shows `paid_request_pending` bookings.
    -   Verify "Active Bookings" section shows `active` bookings.
3.  **Work Tab**:
    -   Tap "Work" tab.
    -   Verify Sub-tabs: Active, Completed, Cancelled.
    -   Check content in each.
4.  **Notifications**:
    -   Trigger a notification.
    -   Check Badge turns Red.
    -   Open Notifications Modal -> Mark Read -> Badge turns Gray/Gone.
