# 🆕 Phase Comparison Log: New Design vs. Flutter Implementation

**Date:** December 8, 2025
**Objective:** Page-by-page comparison of `.TODO/New_Design/` (React) vs. `lib/` (Flutter).
**Status:** New Phases Approaching.

---

## 1. 🏠 Home Page (`Home/HomeList.tsx` vs `HomeScreen.dart`)

### Design Analysis (React)
*   **Header:** "Good Morning" text, User Avatar (square rounded), Notification Bell (Glass).
*   **Search:** Glass input field with search icon + Filter button (Teal).
*   **Categories:** Horizontal scroll, Pill shape. Selected = Teal filled. Unselected = Glass.
*   **Task List (Key Element):**
    *   **Layout:** Card with a **Header Image/Color Block** (`h-32`) at the top.
    *   **Badges:**
        *   "HOT" (🔥): Floating Top-Left.
        *   Type (Tender/Booking): Floating Top-Right (Glass pill).
    *   **Content:** Title (`font-extrabold`), Description (line-clamp-2), Budget (Large Teal text) at the bottom.

### Flutter Implementation (`home_screen.dart` & `task_card.dart`)
*   **Header:** ✅ Implemented. Avatar is slightly different (Circle vs Rounded Square), but structure is correct.
*   **Search:** ✅ Implemented using `AppTextField` and GlassContainer for filter.
*   **Categories:** ✅ Implemented with `_buildCategoryChip`.
*   **Task List (Card):** ❌ **MISMATCH**.
    *   *Current Flutter:* Uses a Row-based layout. Avatar on left, text in middle. No top color/image block.
    *   *Missing:* The "Cover Image" style layout. The card needs to be redesigned to be a Column: [Image/Color Block] -> [Content Padding].
    *   *Missing:* "HOT" badge logic.

**Action Item:** Redesign `TaskCard` to match `HomeList.tsx`.

---

## 2. 📋 Tenders & Bookings (`Tenders/TenderList.tsx`, `Bookings/BookingList.tsx`)

### Design Analysis
*   **Tenders:** Filters `type === 'Tender'`. Uses the same Card style.
*   **Bookings:** Filters `type === 'Booking'`. Uses the same Card style but different badge colors.

### Flutter Implementation
*   **Screens:** ✅ `TendersScreen` and `BookingsDiscoveryScreen` exist and filter correctly.
*   **Cards:** ❌ Inherits the **mismatch** from the Home Page `TaskCard` issue.

**Action Item:** Fix `TaskCard` (it will propagate to these screens).

---

## 3. ➕ Create Task (`CreateTask/CreateTaskModal.tsx` vs `CreateTaskScreen.dart`)

### Design Analysis
*   **Wizard:** 3 Steps (Concept, Details, Logistics). Progress bar at top.
*   **Step 1:** Big Selection Cards (Tender vs Booking) + Category Grid.
*   **Step 2:** Text Inputs (Title, Desc, Tags).
*   **Step 3:**
    *   *Tender:* Budget + Deadline Chips.
    *   *Booking:* Package Tabs (Basic/Standard/Premium) + Inputs (Price, Days, Revisions).

### Flutter Implementation
*   **Structure:** ✅ 3-Step logic implemented.
*   **UI Components:**
    *   Selection Cards: ✅ `_buildTypeCard` matches.
    *   Inputs: ✅ `AppTextField` matches.
    *   Logistics: ✅ `_buildBookingLogistics` handles the package tabs logic.
*   **Data:** ✅ Persists `packages` map to the `Task` model.

**Status:** **High Parity**.

---

## 4. 💬 Chat (`Messages/ChatModal.tsx` vs `ChatScreen.dart`)

### Design Analysis
*   **Header:** Glass. Back button. User Name. "Offer" button (Pill shape).
*   **Messages:**
    *   Me: Teal bubble.
    *   Them: Glass bubble.
    *   **Custom Offer Bubble:** Distinct card-like bubble with "CUSTOM OFFER" header, Price, and Accept/Decline buttons.
*   **Input:** Glass bar at bottom. Attachment icon.

### Flutter Implementation
*   **Header:** ✅ Glass header implemented. "Offer" button exists.
*   **Messages:** ✅ `MessageBubble` implements the color logic.
*   **Offer Bubble:** ✅ `_buildOfferBubble` implements the specific layout (Price, Title, Buttons).
    *   *Note:* The buttons "Accept/Decline" are currently UI placeholders (no backend logic).
*   **Input:** ✅ Glass input bar implemented.

**Status:** **High Parity** (Visuals). Logic pending for Offer actions.

---

## 5. 👤 Profile (`Profile/ProfileView.tsx` vs `ProfileScreen.dart`)

### Design Analysis
*   **Card:** Glass card containing Avatar (with badges "Top Rated"), Name, Title, and Stats Grid (Projects/Rating/Earned).
*   **Menu:** Vertical list of Glass tiles (Icon + Title + Arrow).
*   **Dark Mode:** Toggle switch row.

### Flutter Implementation
*   **Card:** ✅ Implemented. `_buildStatItem` matches the stats grid.
*   **Menu:** ✅ `_buildMenuItem` matches.
*   **Dark Mode:** ✅ Implemented and functional.

**Status:** **High Parity**. Stats data is currently hardcoded/mocked in the View/VM.

---

## 6. 🌍 Public Profile (`PublicProfile/PublicProfileModal.tsx` vs `PublicProfileScreen.dart`)

### Design Analysis
*   **Header:** Gradient background (`h-120`). Floating Avatar overlaps header. Back button in glass circle.
*   **Content:**
    *   Stats Row (Job Success/Total/Hourly) with dividers.
    *   Skills (Wrap chips).
    *   Portfolio (Grid).
    *   Reviews (List).
*   **Bottom Bar:** Sticky Glass bar with "Message" (Ghost) and "Hire Now" (Teal) buttons.

### Flutter Implementation
*   **Header:** ✅ `PublicProfileHeader` implements the gradient and overlapping avatar.
*   **Stats:** ✅ `PublicProfileStats` matches the design.
*   **Portfolio/Reviews:** ✅ Widgets created and mimic the layout.
*   **Bottom Bar:** ✅ Implemented using `GlassContainer`.

**Status:** **High Parity**. Data source is currently a Mock object (`FreelancerProfile.mock()`).

---

## 7. 💰 Wallet (`Wallet/WalletScreen.tsx` vs `WalletDashboardScreen.dart`)

### Design Analysis
*   **Credit Card:** Teal gradient, noise texture, specific layout for Balance/Escrow/Card Number.
*   **Actions:** Withdraw (Yellow), Top Up (Glass).
*   **Transactions:** List of glass tiles with icons (Arrow Up/Down).

### Flutter Implementation
*   **Credit Card:** ✅ Matches visual style (gradients, shadows). Noise texture might be missing/simplified.
*   **Actions:** ✅ Buttons match.
*   **Transactions:** ✅ List items match `New_Design`.

**Status:** **High Parity**. 100% Mock data.

---

## 8. 📦 Orders (`Orders/OrdersScreen.tsx` vs `OrdersDashboardScreen.dart`)

### Design Analysis
*   **Tabs:** Segmented control (Active/Revision/Completed).
*   **Order Card:** Glass card. Header (Client avatar + Name + Status Badge). Metrics row (Time Left / Budget). Footer (Action Buttons).

### Flutter Implementation
*   **Tabs:** ✅ Implemented.
*   **Card:** ✅ `_buildOrderCard` implements the specific layout including the metrics row and footer actions.

**Status:** **High Parity**. 100% Mock data.

---

# 🚨 Summary of Missing Items (New Phases)

The comparison reveals that **Visual Parity is very high**, with one major exception:

1.  **TaskCard Redesign (Critical):** The `TaskCard` in Flutter is outdated compared to the React `HomeList` design. It lacks the cover image/color block and floating badges. This affects the core look of Home, Tenders, and Bookings.

**Next Steps (Logic & Wiring):**
While the UI is there, the data driving it is often mocked.
*   **Wallet:** Need Backend Tables (`wallets`, `transactions`) + Repository.
*   **Orders:** Need Backend Table (`orders`) + Repository.
*   **Offers:** Wire "Accept/Decline" in Chat to actual DB actions.
*   **Public Profile:** Fetch real data from `profiles` table instead of mock.

This concludes the Phase Comparison.
