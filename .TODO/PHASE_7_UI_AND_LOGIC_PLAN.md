# 📅 Phase 7: Visual Completion & Logic Roadmap

**Status:** Planning
**Agent:** @SlinePlanner
**Date:** December 8, 2025
**Objective:** 
1.  **Immediate UI:** Fix the critical visual discrepancy in `TaskCard` to achieve 100% design parity.
2.  **Future Logic:** Map out the backend and logic implementation for the newly added "Glassmorphism" screens (Wallet, Orders, Public Profile).

---

## 🎨 Part 1: Immediate UI Actions (The "Rich Card" Upgrade)

The current `TaskCard` looks like a simple list item. The new design requires a rich, Instagram-style card. This must be fixed first as it impacts the **Home**, **Tenders**, and **Bookings** screens.

### 🛠️ Task 1: Redesign `TaskCard`
*   **Source:** `.TODO/New_Design/Home/HomeList.tsx`
*   **Target:** `lib/features/tasks/view/widgets/task_card.dart`
*   **Implementation Steps:**
    1.  **Structure:** Change root from `Row` to `Column` inside the `GlassContainer`.
    2.  **Header Image/Block:**
        *   Add a top container (Height ~140px).
        *   Background: `task.bgColor` (or a generated pastel color based on Category).
        *   Overlay: `LinearGradient` (transparent to black/dark teal) for text legibility if text is on top, or just aesthetic.
    3.  **Floating Badges (Stack):**
        *   **Top Left:** "HOT" Badge (Red/Gold glass pill). *Logic: Random for now or based on `offers > 10`.*
        *   **Top Right:** Task Type Badge (Tender/Booking) - moved from list item to floating pill.
    4.  **Content Body:**
        *   **Title:** `AppTypography.h6`, max 2 lines.
        *   **Description:** `AppTypography.bodySmall`, max 2 lines, ellipsis.
        *   **Footer:**
            *   **Left:** Time Left / Offer Count.
            *   **Right:** Budget (Large, Teal, FontWeight.w900).

---

## 🔮 Part 2: Future Logic Implementation Plan (The "Todo List")

The following features have complete UIs (implemented in Phase 3-6) but rely on Mock Data or lack database connections.

### 1. 💰 Wallet & Payments System
*   **Context:** `lib/features/wallet/` currently displays hardcoded data.
*   **Todo:**
    *   [ ] **Database (@Supabase_Ops):** Create `wallets` table (`user_id`, `balance`, `currency`) and `transactions` table (`wallet_id`, `amount`, `type`, `status`, `reference_id`).
    *   [ ] **Backend (@Supabase_Ops):** Set up Stripe Connect or similar via Edge Functions for real processing.
    *   [ ] **Repository (@Architect):** Create `WalletRepository` to fetch balance and transaction history.
    *   [ ] **State (@Architect):** Create `WalletViewModel` to replace the mock data in `WalletDashboardScreen`.

### 2. 📦 Orders Dashboard Workflow
*   **Context:** `lib/features/orders/` shows tabs but cards are static.
*   **Todo:**
    *   [ ] **Database (@Supabase_Ops):** Ensure `orders` table exists and has `status` enum (`active`, `revision`, `completed`, `cancelled`).
    *   [ ] **Repository (@Architect):** Update `OrderRepository` to fetch orders grouped by status.
    *   [ ] **Logic (@Architect):** Implement state transitions (e.g., `markDelivered`, `requestRevision`) in `OrderViewModel`.
    *   [ ] **Wiring (@Pixel):** Connect "Deliver Work" button in `OrdersDashboardScreen` to the file upload logic.

### 3. 🤝 Chat Offers Logic
*   **Context:** The "Create Offer" modal sends a JSON text message, but "Accept/Decline" buttons do nothing.
*   **Todo:**
    *   [ ] **Database (@Supabase_Ops):** Create `chat_offers` table or standardized JSONB structure within `messages`.
    *   [ ] **Logic (@Architect):** Implement `OfferService`.
        *   `sendOffer()`: Creates DB record + Message.
        *   `acceptOffer()`: Updates offer status -> Creates Order -> Updates Message UI.
    *   [ ] **UI Wiring (@Pixel):** Update `ChatScreen` bubble buttons to call `vm.acceptOffer(offerId)`.

### 4. 🌍 Real Public Profile Data
*   **Context:** `PublicProfileScreen` uses `FreelancerProfile.mock()`.
*   **Todo:**
    *   [ ] **Database (@Supabase_Ops):** Add `bio`, `hourly_rate`, `job_success`, `total_jobs` columns to `profiles` table.
    *   [ ] **Database (@Supabase_Ops):** Create `user_portfolio` and `user_reviews` tables.
    *   [ ] **Repository (@Architect):** Update `ProfileRepository` to fetch full public profile aggregation.
    *   [ ] **Wiring (@Pixel):** Update `PublicProfileViewModel` to fetch real data by `userId`.

### 5. 🧩 Advanced Filters
*   **Context:** Filter UI is connected to VM, but backend RPC might need tuning for range queries.
*   **Todo:**
    *   [ ] **Database (@Supabase_Ops):** Create/Update RPC `search_tasks_advanced` to handle `min_budget`, `max_budget`, `delivery_time` efficiently.

---

## 🚀 Execution Sequence

1.  **Run Phase 7.1:** Implement the **TaskCard Redesign** immediately to finalize the "Look & Feel".
2.  **Pause:** Await user prioritization for the Logic modules (Wallet vs Orders vs Chat).
