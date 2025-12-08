# 🕵️ Comprehensive Design & Feature Comparison Report

**Date:** December 8, 2025
**Source:** `.TODO/New_Design/` (React/Tailwind)
**Target:** `lib/` (Flutter)
**Agent:** @SlinePlanner

This document provides a strict, element-by-element comparison between the reference design and the current Flutter implementation.

---

## 🚨 Critical Discrepancies (Immediate Action Required)

### 1. Task Card Visuals (`HomeList.tsx` vs `TaskCard.dart`)
*   **React Design:**
    *   **Layout:** Card has a **Header Image/Color Block** (`h-32`) at the top.
    *   **Badges:** "HOT" badge is a floating pill in the top-left of the header. Task Type (Tender/Booking) is a glass pill in the top-right.
    *   **Content:** Title and Description are below the header image.
    *   **Footer:** Budget is large and bold at the bottom.
*   **Flutter Implementation (`task_card.dart`):**
    *   **Layout:** Standard `Column` with padding. No top image/color block.
    *   **Badges:** Task Type is a small chip next to the user avatar in the content row. "HOT" badge is **missing**.
    *   **Content:** Standard text rows.
    *   **Status:** ❌ **Mismatch**. The Flutter card looks like a list tile, not a rich media card.

---

## 📖 Page-by-Page Analysis

### 1. 🏠 Home Screen
| Element | React Spec | Flutter Impl | Status | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **Header** | "Good Morning", Avatar, Bell. | `SliverToBoxAdapter` | ✅ | Matches. |
| **Search** | Glass input + Filter button. | `AppTextField` + Container | ✅ | Matches. |
| **Categories** | Horizontal chips. | `_buildCategoryChip` | ✅ | Matches. |
| **List** | Vertical list of Cards. | `SliverList` | ✅ | Layout matches, but **Card style** differs (see above). |

### 2. 📋 Tenders & Bookings Tabs
| Element | React Spec | Flutter Impl | Status | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **Header** | Title + Subtitle. | `SliverToBoxAdapter` | ✅ | Matches. |
| **Content** | Filtered list of Tasks. | Filtered `SliverList` | ✅ | Logic works. Visuals depend on `TaskCard` fix. |

### 3. ➕ Create Task Wizard
| Element | React Spec | Flutter Impl | Status | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **Steps** | 3 Steps (Concept, Details, Logistics). | `_currentStep` state | ✅ | Matches logic. |
| **Type Selection** | Large cards (Tender/Booking). | `_buildTypeCard` | ✅ | Matches visuals. |
| **Inputs** | Title, Desc, Budget. | `AppTextField` | ✅ | Matches styling. |
| **Packages** | Tabbed input for Booking. | `_buildBookingLogistics` | ✅ | Matches logic & UI. |

### 4. 💬 Chat Screen
| Element | React Spec | Flutter Impl | Status | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **Header** | User Name, Back, "Offer" Button. | `GlassContainer` header | ✅ | Matches. |
| **Bubbles** | "Me" (Teal), "Them" (Glass). | `MessageBubble` | ✅ | Matches styling. |
| **Custom Offer** | Special bubble with Price/Accept. | `_buildOfferBubble` | ✅ | **Visuals only.** Buttons do not trigger API actions. |
| **Input** | Glass bar with Attachment/Send. | `GlassContainer` footer | ✅ | Matches. |

### 5. 👤 Profile Screen
| Element | React Spec | Flutter Impl | Status | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **Avatar** | Large centered avatar + badges. | `SignedAvatar` | ✅ | Matches. |
| **Stats** | Projects/Rating/Earned grid. | `_buildStatItem` | ✅ | Visuals match. Data is hardcoded in View/VM. |
| **Menu** | List of glass tiles. | `_buildMenuItem` | ✅ | Matches. |
| **Dark Mode** | Toggle switch. | `ThemeModeProvider` | ✅ | Functional. |

### 6. 🌍 Public Profile
| Element | React Spec | Flutter Impl | Status | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **Header** | Gradient + Floating Avatar. | `PublicProfileHeader` | ✅ | Matches. |
| **Stats** | Job Success/Total/Hourly row. | `PublicProfileStats` | ✅ | Matches. |
| **Portfolio** | Grid of images. | `PublicProfilePortfolio` | ✅ | Matches. |
| **Reviews** | List of reviews. | `PublicProfileReviews` | ✅ | Matches. |
| **Data** | Real user data. | `FreelancerProfile.mock()` | ⚠️ | **Logic Gap:** Still using mock data service. |

### 7. 💰 Wallet & Orders
| Element | React Spec | Flutter Impl | Status | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **Wallet Card** | Glass credit card visual. | `WalletDashboardScreen` | ✅ | Visuals match perfectly. |
| **Transactions** | List of items. | Mock list | ⚠️ | **Logic Gap:** No backend connection. |
| **Orders Tabs** | Active/Rev/Comp/Cancel. | Tab Controller | ✅ | Matches. |
| **Order Card** | Status badge + Action button. | Mock card | ⚠️ | **Logic Gap:** No backend connection. |

---

## 🚀 Upcoming Phase: Phase 7 (Visual Polish & Logic Wiring)

Based on this comparison, the next phase must prioritize:

1.  **TaskCard Refactor:** Redesign `TaskCard` to match the React `HomeList` design (add the colored header block). This is critical for the "premium" feel.
2.  **Logic Wiring:**
    *   Connect **Public Profile** to real Supabase data.
    *   Connect **Wallet** to a real (or emulated) backend table.
    *   Connect **Orders** to a real backend table.
    *   Wire **Chat Offer** buttons (Accept/Decline) to actual logic.

This plan is detailed in `.TODO/PHASE_7_LOGIC_WIRING_PLAN.md` (created previously).