# Design Implementation Tracker

This document tracks the implementation of the new designs extracted from `.TODO/New_Design_Code`.

| Feature | Design Location | Status | Implementation Notes |
| :--- | :--- | :--- | :--- |
| **Auth** | `.TODO/New_Design_Code/Organized/Auth/AuthScreens.tsx` | Pending | Login and Signup screens with animations. |
| **Home** | `.TODO/New_Design_Code/Organized/Home/HomeView.tsx` | Pending | Main feed, search bar, categories, task cards. |
| **Tenders List** | `.TODO/New_Design_Code/Organized/Tenders/TenderListView.tsx` | Pending | Filtered list for Tender type tasks. |
| **Bookings List** | `.TODO/New_Design_Code/Organized/Bookings/BookingListView.tsx` | Pending | Filtered list for Booking type tasks. |
| **Messages List** | `.TODO/New_Design_Code/Organized/Messages/MessagesListView.tsx` | Pending | List of conversations. |
| **Chat Detail** | `.TODO/New_Design_Code/Organized/Messages/ChatOverlay.tsx` | Pending | Individual chat view, includes **Create Offer Modal**. |
| **Orders** | `.TODO/New_Design_Code/Organized/Orders/OrdersDashboard.tsx` | Pending | Orders dashboard with tabs (Active, Revision, etc.). |
| **Wallet** | `.TODO/New_Design_Code/Organized/Wallet/WalletDashboard.tsx` | Pending | Wallet view, balance card, transactions. |
| **Profile** | `.TODO/New_Design_Code/Organized/Profile/ProfileView.tsx` | Pending | User profile, stats, menu, dark mode toggle. |
| **Task Details** | `.TODO/New_Design_Code/Organized/TaskDetails/TaskDetailsOverlay.tsx` | Pending | Detailed view of a task, includes **Submit Proposal Modal**. |
| **Proposal Details** | `.TODO/New_Design_Code/Organized/ProposalDetails/ProposalDetailsOverlay.tsx` | Pending | Client view of a proposal. |
| **Public Profile** | `.TODO/New_Design_Code/Organized/PublicProfile/PublicProfileOverlay.tsx` | Pending | View of another user's profile. |
| **Create Task** | `.TODO/New_Design_Code/Organized/CreateTask/CreateTaskOverlay.tsx` | Pending | Multi-step wizard to create a new task (Tender/Booking). |
| **Notifications** | `.TODO/New_Design_Code/Organized/Notifications/NotificationCenter.tsx` | Pending | Notification center overlay. |
| **Filters** | `.TODO/New_Design_Code/Organized/Filters/AdvancedFilters.tsx` | Pending | Advanced search filters modal. |
| **Common** | `.TODO/New_Design_Code/Organized/Common/` | N/A | Shared `types.ts`, `Theme.ts`, `MockData.ts`. |

## Next Steps
1.  Review the `Common/types.ts` to ensure they match the Flutter models (or update Flutter models).
2.  Implement `Common/Theme.ts` logic in Flutter (using `ThemeData` and `ThemeExtension`).
3.  Implement each feature screen by screen, referring to the extracted `.tsx` files for layout and styling (Tailwind classes can be mapped to Flutter widgets/styles).
