# 📝 Future Implementation Todo List

This file tracks features present in the **New Design** (`.TODO/New_Design_Code`) that are **not yet implemented** in the real backend/logic of `sline_app`.

**Current Strategy:** Implement the UI for these features using **Demo Data** so the app looks complete and testable.
**Future Strategy:** Connect these UI elements to real Supabase tables and backend logic.

---

## 1. 💰 Wallet & Payments
*   [ ] **Backend:** Create `wallets` and `transactions` tables in Supabase.
*   [ ] **Backend:** Implement Stripe/Payment Gateway integration.
*   [ ] **Logic:** Connect `WalletDashboard` to real data stream.
    *   *Current State:* UI uses `mockWalletData` from `MockData.ts`.

## 2. 📦 Service Packages (Fiverr-style)
*   [ ] **Database:** Update `tasks` table to support JSONB column for `packages` (Basic, Standard, Premium) OR create `task_packages` table.
*   [ ] **Logic:** Update `Task` model to parse package data.
*   [ ] **UI:** Wiring "Select Tier" logic in `TaskDetailsOverlay` to actual Booking creation.
    *   *Current State:* UI displays static packages.

## 3. 🤝 Custom Chat Offers
*   [ ] **Database:** Create `chat_offers` table or add `offer_details` JSONB to `messages` table.
*   [ ] **Logic:** Implement "Accept/Decline" logic which triggers an Order creation.
*   [ ] **UI:** Wire "Send Offer" button to backend function.
    *   *Current State:* "Send Offer" adds a local dummy message to the chat list.

## 4. 🔍 Advanced Filtering
*   [ ] **Backend:** Create complex query RPCs in Supabase to filter by `budget_range`, `delivery_time`, and `seller_level`.
*   [ ] **Logic:** Update `HomeViewModel` to accept a `FilterState` object.
    *   *Current State:* Filter UI exists but doesn't filter the actual list.

## 5. 🔔 Notification System
*   [ ] **Backend:** Create `notifications` table.
*   [ ] **Backend:** Set up Realtime listeners or Push Notifications (FCM).
*   [ ] **UI:** Connect `NotificationCenter` to the live stream.
    *   *Current State:* UI shows hardcoded "Today" and "Yesterday" notifications.

## 6. 📋 Orders Dashboard
*   [ ] **Backend:** Ensure `orders` table has statuses: `Active`, `Revision`, `Completed`, `Cancelled`.
*   [ ] **Logic:** Implement "Deliver Work" flow (file upload).
    *   *Current State:* Dashboard tabs switch lists, but actions like "Deliver" are cosmetic.
