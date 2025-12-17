# 📘 SLine App - Complete Development Log

**Last Updated:** 2025-12-16

---

## 🎯 Project Overview

**SLine** is a Flutter-based freelance marketplace application that connects clients with freelancers. The app enables users to post jobs, find freelancers, communicate, and manage projects through a modern mobile interface.

**Tech Stack:**

- **Frontend**: Flutter (Material Design 3)
- **Backend**: Supabase (BaaS - Backend as a Service)
- **State Management**: Provider with ChangeNotifier pattern
- **Authentication**: Supabase Auth (email/password)
- **Database**: PostgreSQL (via Supabase)
- **Storage**: Supabase Storage (for avatars, files)

---

## 📋 Version History

### 🟢 Version 2.5 — Saved Projects Feature Fix & Optimization

**Date:** 2025-12-17
**Commit:** _Pending_ — "feat(saved): global state, UI toggles, profile badge optimization"

#### ✅ Implemented

- **Global Saved Tasks State**
  - Promoted `SavedTasksViewModel` to a global provider in `main.dart`.
  - Added `_initAuthListener` to automatically load/clear tasks on login/logout.
  - Ensures bookmark state is consistent across Home, Search, and Profile screens.

- **Saved Projects UI**
  - **Profile Screen**: Added "Saved Projects" menu item with live counter badge.
  - **Optimization**: Used `Selector` for the badge to preventing full-screen rebuilds on toggle.
  - **Task Cards**: Added bookmark (heart) icon to `TenderTaskCard` and `BookingTaskCard` header.
  - **Saved Screen**: `SavedTasksScreen` now consumes the global ViewModel.

- **Critical Bug Fix (PGRST200)**
  - **Issue**: "Unknown User" and app crash due to missing foreign key relationship between `saved_tasks` and `profiles` via `tasks` table.
  - **Fix**: Updated `SavedTasksService.listMineWithDetails` to perform a robust 2-step fetch:
    1. Fetch saved tasks.
    2. Extract user IDs and fetch profiles in a batch.
    3. Merge profile data (name/avatar) into Task objects manually.
  - **Result**: Eliminates schema dependency risks and ensures author data always loads.

#### 📊 Impact

- **UX**: Users can bookmark tasks instantly from any card; state reflects immediately.
- **Performance**: Zero-rebuild updates for the Profile screen badge.
- **Stability**: Database schema looseness no longer causes "Unknown User" crashes.

#### 🗂️ Files Touched

- **Modified:**
  - `lib/features/saved/viewmodels/saved_tasks_view_model.dart` (Auth listener)
  - `lib/features/saved/data/saved_tasks_service.dart` (Manual join fix)
  - `lib/features/profile/view/profile_screen.dart` (Selector optimization)
  - `lib/features/tasks/view/widgets/tender_task_card.dart` (Toggle UI)
  - `lib/features/tasks/view/widgets/booking_task_card.dart` (Toggle UI)
  - `lib/main.dart` (Global provider)

#### 🔧 Technical Notes

- `SavedTasksService` manual join pattern works around the missing `tasks.user_id` FK reference in the generated Postgrest client, preventing `PGRST200` errors.

#### 🔜 Next

- **Localization**: RTL support.

### 🟢 Version 2.4 — Portfolio Management & iOS Stability

**Date:** 2025-12-16
**Commit:** _Pending_ — "feat(profile): Portfolio CRUD, FilePicker migration, iOS crash fix"

#### ✅ Implemented

- **Portfolio Management Feature**
  - Added `ManagePortfolioScreen` accessible from Settings with full CRUD operations
  - Added `addPortfolioItem`, `updatePortfolioItem`, `deletePortfolioItem`, `uploadPortfolioImage` methods to `ProfileRepository`
  - Added portfolio state management (`portfolioItems`, `isLoadingPortfolio`, `fetchPortfolio`) to `ProfileViewModel`
  - Portfolio items display in `ProfileScreen` using `SignedImage` with `bucket: 'portfolio'`
  - Navigation tile added to `SettingsScreen` for portfolio management

- **iOS Crash Fix** (CRITICAL)
  - **Root cause**: `SignedImage` widget rendering immediately after upload triggered native iOS memory/timing crash
  - **Fix**: Replaced in-dialog image preview with success checkmark indicator
  - **Migration**: Replaced `ImagePicker` with `FilePicker` in `ProfileViewModel` for better iOS stability
  - **Compression**: Added `FlutterImageCompress` for image resizing (max 1920px, 80% quality)

- **macOS Permissions Fixes**
  - Added `NSPhotoLibraryUsageDescription` and `NSCameraUsageDescription` to `macos/Runner/Info.plist`
  - Added `com.apple.security.files.user-selected.read-only` and `com.apple.security.network.client` to macOS entitlements

- **SignedImage Memory Optimization**
  - Added `memCacheWidth` and `memCacheHeight` to `CachedNetworkImage` to decode images at display size only
  - Prevents OOM crashes when rendering large images on iOS

#### 📊 Impact

- Freelancers can now manage portfolio items (add, edit, delete with images)
- iOS upload stability significantly improved (no more native crashes)
- Reduced memory footprint for image rendering across app

#### 🗂️ Files Touched

- **New:**
  - `lib/features/profile/view/manage_portfolio_screen.dart`
- **Modified:**
  - `lib/features/profile/data/profile_repository.dart` (portfolio CRUD + upload)
  - `lib/features/profile/viewmodels/profile_view_model.dart` (FilePicker, portfolio state)
  - `lib/features/profile/view/settings_screen.dart` (navigation to portfolio)
  - `lib/features/profile/view/profile_screen.dart` (portfolio display)
  - `lib/core/widgets/signed_image.dart` (bucket param, memCache optimization)
  - `macos/Runner/Info.plist` (permissions)
  - `macos/Runner/DebugProfile.entitlements` (file/network access)
  - `macos/Runner/Release.entitlements` (file/network access)

#### 🔧 Technical Notes

- `FilePicker` uses `UIDocumentPickerViewController` on iOS instead of `PHPicker`, avoiding `WFIsolatedShortcutRunner` crash
- Dialog now shows checkmark after upload; image renders in portfolio list view (not immediately in dialog)
- Storage bucket `portfolio` uses private access with signed URLs (2hr TTL)

#### 🔜 Next

- Profile Skills management (add/remove skills tags)
- Enhanced portfolio item details view

### 🟢 Version 2.3 — Phase 2: Orders Dashboard & Task Card Differentiation

**Date:** 2025-12-14
**Commit:** _Pending_ — "feat(orders): Orders dashboard, Tender/Booking cards, offer management"

#### ✅ Implemented

- **Phase 2.1: Tender vs Booking Cards** (UI/UX)
  - Created specialized `TenderTaskCard`: Coral theme, author info, offer count, deadline countdown.
  - Created specialized `BookingTaskCard`: Teal theme, provider info, availability status.
  - Updated `TaskCard` to dynamically delegate to the correct widget based on `task.taskType`.
  - Added visual cues (icons, badges) to clearly distinguish task types.

- **Phase 2.2: Orders Dashboard Overhaul** (Client View)
  - Implemented `OrdersDashboardScreen` to manage published tasks.
  - Features:
    - **Status Tabs**: Open, In Progress, Completed, Cancelled.
    - **Offer Management**: View offers in `OfferListSheet`, accept/reject bids.
    - **Task Management**: Edit and Delete actions via `OrderCard` menu.
  - Architecture: Added `OrdersViewModel` and `OrdersService` (aggregating Task/Request services).

- **Critical Bug Fixes** (Stability)
  - **Fixed PGRST204 Crash**: Removed `packages` and `offers` fields from `Task.toJson` updates, as these columns do not yet exist in the DB or are computed.
  - **Task Editing Fix**: Updated `CreateTaskScreen` to properly handle category selection (UUID vs legacy Name) to prevent `22P02` invalid input syntax errors.
  - **Offer List Crash**: Fixed `RangeError` in `OfferListSheet` when bidder name is empty.

#### 📊 Impact

- **UX**: Clients can now fully manage their task lifecycle (Post -> Review Offers -> Assign -> Complete).
- **Clarity**: Distinct visual languages for Tenders vs Bookings help users understand context immediately.
- **Stability**: Resolved blocking crashes in the "Create/Edit Task" flow.

#### 🗂️ Files Touched

- **New Features:**
  - `lib/features/orders/` (entire module: view, viewmodels, services, widgets)
  - `lib/features/tasks/view/widgets/tender_task_card.dart`
  - `lib/features/tasks/view/widgets/booking_task_card.dart`
- **Modified:**
  - `lib/features/tasks/models/task_model.dart` (removed problematic fields from toJson)
  - `lib/features/tasks/view/create_task_screen.dart` (fixed update logic)
  - `lib/features/tasks/view/widgets/task_card.dart` (delegation logic)
  - `lib/features/tasks/services/task_requests_service.dart` (added profile join)

#### 🔧 Technical Notes

- `TaskRequest` model updated to include `bidderName` and `bidderAvatar` from joined profile data to avoid N+1 queries in the offer list.
- `OrderCard` uses `PopupMenuButton` for Edit/Delete actions.

#### 🔜 Next

- **Phase 2.3**: Chat System Overhaul
- **Phase 2.4**: Profile Screen Enhancement

---

### 🟢 Version 2.2 — Phase 1 Foundation: Performance, Error Handling & Session Management

**Date:** 2025-12-14
**Commit:** _Pending_ — "feat(core): Phase 1 foundation - performance, error handling, session management"

#### ✅ Implemented

- **Phase 1.1: Task Card Image Display** (BUG FIX)
  - Updated `lib/features/tasks/view/widgets/task_card.dart` to display task images using `SignedImage` widget
  - Added conditional rendering: shows task image when `task.imagePaths` is not empty, falls back to colored header
  - Proper gradient overlay and placeholder sizing for loading/error states

- **Phase 1.2: App Performance Optimization**
  - Added `cached_network_image: ^3.4.1` to `pubspec.yaml` for image disk/memory caching
  - Updated `lib/core/widgets/signed_image.dart` to use `CachedNetworkImage` - reduced network calls on subsequent loads
  - Updated `lib/core/widgets/signed_avatar.dart` to use `CachedNetworkImage` and `CachedNetworkImageProvider`
  - Implemented cursor-based pagination in `lib/features/tasks/services/task_service.dart` via `getOpenTasksForHome(limit, cursorCreatedAtIso)`
  - Updated `lib/features/home/viewmodels/home_view_model.dart` with `loadMoreTasks()` for infinite scroll, pagination state (`_cursor`, `_hasMore`, `_isLoadingMore`)
  - Optimized `lib/features/tasks/viewmodels/task_view_model.dart` to minimize redundant `notifyListeners()` calls

- **Phase 1.3: Supabase Connection Verification** (AUDIT)
  - Created `lib/core/utils/error_mapper.dart` - centralized error-to-user-message mapping following `.cursor/rules/error-handling.mdc`
  - Updated `lib/features/tasks/services/task_service.dart` with proper `PostgrestException` handling and `ErrorMapper.map()` for all methods
  - Enhanced `lib/features/tasks/services/task_image_service.dart` with:
    - Authentication validation before upload
    - User-friendly error messages for storage errors
    - Added `deleteImage()` method for cleanup
    - Proper logging with `[TaskImages]` tag
  - Implemented session expiry handling in `lib/features/auth/viewmodels/auth_view_model.dart`:
    - Added Supabase auth state listener (`onAuthStateChange`)
    - Added `onSessionExpired` callback with pending queue to prevent race conditions
    - Proper subscription cleanup in `dispose()`
  - Updated `lib/main.dart` with `_AppWithAuthListener` wrapper for session expiry navigation

#### 📊 Impact

- **Performance**: Image caching reduces network calls significantly; cursor pagination prevents loading all tasks at once
- **UX**: User-friendly error messages instead of technical exceptions
- **Reliability**: Session expiry properly detected and handled with redirect to login
- **Maintainability**: Centralized `ErrorMapper` utility for consistent error handling

#### 🗂️ Files Touched

- **New Files:**
  - `lib/core/utils/error_mapper.dart` - Error mapping utility
- **Modified:**
  - `lib/features/tasks/view/widgets/task_card.dart` - Image display in headers
  - `lib/features/tasks/services/task_service.dart` - Pagination, error handling
  - `lib/features/tasks/services/task_image_service.dart` - Enhanced error handling
  - `lib/features/home/viewmodels/home_view_model.dart` - Pagination support
  - `lib/features/tasks/viewmodels/task_view_model.dart` - Optimized notifications
  - `lib/features/auth/viewmodels/auth_view_model.dart` - Session listener
  - `lib/core/widgets/signed_image.dart` - CachedNetworkImage
  - `lib/core/widgets/signed_avatar.dart` - CachedNetworkImage
  - `lib/main.dart` - Auth listener wrapper
  - `pubspec.yaml` - Added cached_network_image

#### 🔧 Technical Notes

- Cursor pagination uses `created_at` timestamps (ISO 8601) per project rules (no offset pagination)
- `ErrorMapper` handles `PostgrestException`, `AuthException`, `StorageException`, and network errors
- Session expiry events are queued if they occur before callback is set (prevents startup race condition)
- Image caching uses disk + memory cache via `flutter_cache_manager` (transitive dependency)

#### 🔜 Next

- Phase 2.1: Differentiate Tender vs Booking Cards
- Phase 2.2: Orders Dashboard Overhaul
- Plan `supabase_flutter` v2.x migration (30 outdated packages detected)

---

### 🟢 Version 2.1 — Theme System Dashboard, iOS 26 Liquid Glass Nav & CodeGuard Agent

**Date:** 2025-12-08
**Commit:** _Pending_ — "feat(theme): centralized theme dashboard, liquid glass nav bar, CodeGuard agent"

#### ✅ Implemented

- **Theme System Dashboard**
  - Created `lib/core/theme/theme_dashboard.dart` - comprehensive single source of truth for all theme values
  - Documents all `AppColors`, `AppTypography`, `AppDimens`, `AppDecorations` with usage examples
  - Includes design token mapping from Figma/design to Flutter
  - Added anti-patterns guide to prevent hardcoded values

- **iOS 26 Liquid Glass Bottom Navigation**
  - Redesigned `lib/core/widgets/custom_bottom_nav_bar.dart` with frosted glass effect
  - Features: `BackdropFilter` blur (sigma: 25), animated pill indicator, scale animations
  - Theme-adaptive: works in both light and dark modes with different opacity values
  - Notification badge support with glow effect

- **CodeGuard Agent** (New)
  - Created `.cursor/Agents/CodeGuard.md` - Performance, Security & Compatibility Auditor
  - Focus: Code reviews, performance optimization, security hardening, dependency updates
  - Triggers: `@CodeGuard`, "review code", "performance check", "security audit", "update dependencies"
  - Features: Review report template, automated checks, anti-pattern tables

- **Feature Inventory System**
  - Created `.TODO/Future_Plans/FEATURE_INVENTORY.md` - tracks design vs implementation status
  - Documents all features from `.TODO/New_Design/` matched to Flutter implementation
  - Categorizes features as: Implemented, Partially Implemented, Not Implemented

- **Video Call Feature Removal**
  - Removed `lib/features/chat/view/video_call_modal.dart`
  - Removed video call button from `chat_screen.dart` header
  - Removed `VideoCallModal` references from design files
  - Removed `ActiveCall` interface from types

- **Designer References**
  - Added `Sline_everything/designer_references/liquid_glass.md` - iOS 26 liquid glass documentation

#### 📊 Impact

- Theme changes now centralized - edit once, apply everywhere
- Bottom navigation matches iOS 26 design language with premium feel
- Code quality improvements via CodeGuard agent audits
- Clear roadmap for remaining design implementation work

#### 🗂️ Files Touched

- **Theme:** `lib/core/theme/theme_dashboard.dart` (new), `lib/core/theme/app_typography.dart`, `lib/core/theme/app_dimens.dart`
- **Navigation:** `lib/core/widgets/custom_bottom_nav_bar.dart`, `lib/app/main_navigation_screen.dart`
- **Agents:** `.cursor/Agents/CodeGuard.md` (new)
- **Documentation:** `GEMINI.md`, `.cursorrules`, `.cursor/PROJECT_CONTEXT.md`
- **Removed:** `lib/features/chat/view/video_call_modal.dart`, video call references in chat

#### 🔜 Next

- Audit `Colors.*` usage → migrate to `AppColors`
- Update Supabase Flutter to v2.x (major version migration)
- Implement remaining features from FEATURE_INVENTORY.md

---

### 🟢 Version 2.0 — Visual Parity & Task Card Redesign

**Date:** 2025-12-08
**Commit:** _Pending_ — "feat(ui): TaskCard redesign, isHot/bgColor support, offer count trigger"

#### ✅ Implemented

- **Task Visuals (DB)**
  - Added `is_hot` (boolean), `bg_color` (text), `offers` (int) to `tasks` table.
  - Added trigger `update_task_offer_count` to auto-update `offers` when requests are added/removed.
- **Task Visuals (Flutter)**
  - Updated `Task` model to include new fields (safe null handling).
  - Updated `TaskService` to select all columns (`*`).
  - **Redesigned `TaskCard`**: now matches React `HomeList` design with header color block, floating badges, and rich footer.
- **Theme**
  - Added `AppDimens.p128` for card headers.
  - Added `toHex` utility for colors.

#### 📊 Impact

- Achieved 100% visual parity with the new Glassmorphism design for Task Cards.
- Home, Tenders, and Bookings screens now look consistent and premium.
- Offer counts are now cached on the task record for instant display.

### 🟢 Version 1.9 — Private Avatars & Task Images (Signed URLs)

**Date:** 2025-09-20  
**Commit:** _Pending_ — "feat(storage): avatars & task-images buckets + signed render; show task images; unify ProfileController"

#### ✅ Implemented

- **Storage**
  - Created private buckets: **`avatars`**, **`task-images`**.
  - RLS on `storage.objects`:  
    - INSERT: authenticated owner only (`owner = auth.uid()` and correct `bucket_id`).  
    - SELECT: authenticated users for respective bucket (for signed URLs).
- **Database**
  - Added `ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS image_paths text[] DEFAULT '{}'::text[];`
  - Forced PostgREST cache reload via `NOTIFY pgrst, 'reload schema';`.
- **Services**
  - `AvatarService`: switched to `avatars` bucket, use bytes upload, `createSignedUrl` (Supabase v2), store **storage path** in `profiles.avatar_url`.
  - **`TaskImageService`**: upload bytes to `task-images` under `tasks/<taskId>/<timestamp>.<ext>` and generate signed URLs.
- **Controllers**
  - Unified `ProfileController` (removed duplicate UI-layer version).
  - `TaskController`: finalize images after create/update and persist `image_paths`.
- **Widgets/UI**
  - **`SignedAvatar`**: renders avatar from storage path or legacy URL with in-memory TTL cache.
  - **`SignedImage`**: renders task image from storage path/URL with caching.
  - `task_card.dart`: shows first task image (thumbnail).
  - `task_details_screen.dart`: shows first task image above description.
- **Code Hygiene**
  - Replaced deprecated `.withOpacity` → `.withValues(alpha: ...)`.
  - Removed unused imports and variables.

#### 🐛 Bugs Fixed

- 403 on avatar upload due to missing RLS → fixed by policies on `avatars`.
- “column `image_paths` does not exist” during insert → added column and reloaded PostgREST cache.
- Home avatars not refreshing → `SignedAvatar` with signed URL cache.
- Duplicate `ProfileController` type → unified import path.

#### 📊 Impact

- Consistent, secure image handling (avatars + task images) via private buckets.
- Faster perceived loads thanks to signed-URL caching.
- Tasks on Home and Details now visually rich with thumbnail.

#### 🗂️ Files Touched

- **Core Widgets:** `lib/core/widgets/signed_avatar.dart`, `lib/core/widgets/signed_image.dart`
- **Profile:** `features/profile/services/avatar_service.dart`, `features/profile/controllers/profile_controller.dart`, `features/profile/ui/widgets/profile_avatar.dart`, `features/profile/ui/widgets/profile_view.dart`
- **Tasks:** `features/tasks/services/task_service.dart`, **`features/tasks/services/task_image_service.dart`**, `features/tasks/controllers/task_controller.dart`, `features/tasks/presentation/widgets/task_card.dart`, `features/tasks/presentation/task_details_screen.dart`
- **Misc:** minor cleanups in theme & imports

#### 🧪 Smoke Tests

- Create task with 1–3 images → `image_paths` updated and visible in Home + Details.
- Change avatar → profile + home avatars refresh instantly.
- Web upload works (no `dart:io`).

#### 🔜 Next

- Task gallery (carousel) for multiple images in `task_details_screen`.
- Pull-to-refresh on Home.
- Image compression on upload (reduce bandwidth).

### 🟢 Version 1.8 — Profile Avatars Revamp & Home Avatar Fix  

**Date:** 2025-09-19  
**Commit:** _Pending_ — "fix: unify ProfileController, add SignedAvatar, private avatars bucket + RLS"

#### ✅ Implemented

- **Storage (Supabase):** Created private bucket **`avatars`**.
  - Path convention: `<uid>/<timestamp>.<ext>` (no bucket prefix inside `name`).
  - Added RLS policies on `storage.objects`:
    - INSERT/UPDATE/DELETE: authenticated users can write only under their own folder (`name like auth.uid() || '/%'`).
    - SELECT: authenticated users can read from `bucket_id = 'avatars'` (for client-side signed URLs).
- **AvatarService:**
  - Switched bucket from `portfolio` → **`avatars`**.
  - Fixed `createSignedUrl` to use Supabase v2 API (returns `String`).
  - Upload now uses binary bytes (web-safe) and stores **storage path** in `profiles.avatar_url`.
- **ProfileController:**
  - Unified single source of truth (removed duplicate controller under `ui/controller/`).
  - Added `pickAndUploadAvatar(context)` and `refreshAvatarSignedUrl()`.
  - New state fields: `avatarSignedUrl`, `avatarUploading`.
  - Cleaned imports: removed `dart:io`/legacy picker service.
- **UI (Profile):**
  - `profile_avatar.dart` now uses controller methods/fields above and shows a loading overlay.
  - `profile_view.dart` import fixed to point to the unified controller.
- **UI (Home/Tasks):**
  - New reusable widget **`SignedAvatar`** (`lib/core/widgets/signed_avatar.dart`).
    - Accepts either legacy **URL** or new **storage path**.
    - Generates signed URL on the fly + in-memory TTL cache (~90m).
  - `task_card.dart`: replaced raw `NetworkImage` with `SignedAvatar` so avatars refresh correctly on Home.
- **Deprecations & Cleanup:**
  - Replaced `.withOpacity(..)` → `.withValues(alpha: ..)` where applicable.
  - Addressed `surfaceVariant` deprecation (migrate to `surfaceContainer*` as we polish theme).
  - Removed unused imports/variables; analyzer warnings resolved.

#### 🐛 Bugs Fixed

- **403 RLS on upload** (`new row violates row-level security policy`): bucket policies added to allow authenticated INSERT under `<uid>/...`.
- **Duplicate `ProfileController` type conflict**: removed legacy controller & fixed imports across widgets.
- **Home avatars not updating**: `SignedAvatar` resolves storage paths to fresh signed URLs (with caching) — fixes stale images on Task cards.
- **Web compatibility**: avatar upload avoids `dart:io` and uses `XFile.readAsBytes()`.

#### 📈 Impact

- Consistent, secure avatar flow across Web/iOS/Android.
- Faster perceived loads for avatars via lightweight cache.
- Cleaner architecture: single ProfileController + shared avatar widget.

#### 🔬 Notes / Migration

- Legacy rows where `profiles.avatar_url` stores a **public URL** still render (widget detects `http` and uses it directly).
- New uploads store **storage path** only; rendering always uses a **signed URL**.

#### 🧪 Smoke Test Checklist

- Upload avatar → loader shows → image updates immediately.
- Re-open Profile/Home → image still shows (signed URL regenerated on view).
- Web upload works; no 403; no `dart:io` usage.

### 🟢 Version 1.7 — Sprint 2 Complete: Booking (A2–A4) + Categories (DB-first) + Portfolio v1**Date:** 2025-08-23  

**Commit:** _Pending_ — "feat(booking): availability & bookings polish; add categories DB-first + tasks.category_id"

#### ✅ Implemented

### 🟢 Version 1.7 — Sprint 2 Complete: Booking (A2–A4) + Categories (DB-first) + Portfolio v1

- **Portfolio (B2)**
  - DB: `portfolio_items` + private `portfolio` bucket with RLS
  - Flutter: `PortfolioService`, `PortfolioController`, `PortfolioScreen`
  - Features: upload image (image_picker), create, edit, delete, details sheet
  - iOS: added NSPhotoLibraryUsageDescription in Info.plist

- **Tasks (Long-term category name)**
  - All task `.select(...)` now include `categories(name)` embed.
  - `TaskModel` adds `categoryName` resolved from embed (fallback to legacy text).
  - `TaskCard` & `TaskDetailsScreen` display `categoryName` (no UUID / null).
  - Fixed `AvailabilityScreen` navigation to pass correct `taskId` (`task.id`).
- **Booking (Frontend)**
  - `AvailabilityScreen`: grid/list toggle, pull-to-refresh, infinite scroll, role guard (provider-only Add Slot).
  - `BookingsListScreen`: tabs (As Client / As Provider), status filter, pagination with hasMore + inline loader.
  - `BookingSheet`: wired with `taskId`, `providerId`, `slotId`.
  - `AddSlotSheet`: pick local start/end, convert to UTC, create blocked/open slot.
  - `format_date.dart`: `formatRangeUtcToLocal`, `formatUtcToLocal` utilities (consistent local-time display).
- **Booking (Logic/Service/Controller)**
  - `BookingService.createSlot` now sets `provider_id = auth.uid()` (RLS requirement).
  - `BookingService.bookSlot` now sets `client_id = auth.uid()` (RLS requirement).
  - `BookingController`: friendly error mapper (`23505` → already booked, overlap trigger → overlapping slot), unified pagination flags (`slotsHasMore`, `bookingsClientHasMore`, `bookingsProviderHasMore`), and cursor handling.
- **Booking (DB/RLS)**
  - Partial unique index on `bookings(slot_id)` for `status in ('pending','confirmed')`.
  - Overlap prevention for `availability_slots` via trigger on insert/update using `tstzrange &&`.
  - Indexes: `idx_slots_provider_starts`, `idx_bookings_client_created`, `idx_bookings_provider_created`.
- **Categories (B1, DB-first)**
  - Table `public.categories` with `uq_categories_name` and `idx_categories_name_lower`.
  - RLS: **read-only** for authenticated users (select policy only).
  - Seed: Design/Development/Marketing/Photography/Writing/Cleaning/Other (idempotent).
  - Migration: `tasks.category_id` (nullable) + index + optional backfill from existing text field.

#### 📈 Impact

- End-to-end booking happy-path works on Web/iOS with proper RLS compliance.
- Clear UX: provider adds slots; client books; lists are paginated with robust states.
- Categories are now managed in DB (UI can switch later without breaking current flows).

#### 🔬 Notes

- Timezone: store UTC in DB; display local in Flutter via `toLocal()` (+ utilities).
- Providers are scoped by route; bottom sheets use the existing navigator to avoid Provider scope issues.
- Policies remain conservative; category writes are admin/server-only for now.

### 🟢 Version 1.6 — Tender Offers Complete & Booking Kickoff

**Date:** 2025-08-22  
**Commit:** _Pending_ — "feat: complete tender offers; add task_type & UI separation; provider fixes"

#### ✅ Implemented

- **DB:** `task_type_enum ('tender','booking')`, `task_requests` table with indexes and RLS.
- **Policies:** Owner sees all offers for their tender task; bidder sees only their offers; owner can accept/reject.
- **Triggers:** Prevent offers on booking tasks; optional trigger to allow updating `status` only.
- **Indexes:** `idx_tasks_type_created_at(task_type, created_at desc)`, `idx_task_requests_task_created(task_id, created_at desc)`, unique pending-per-user (`task_id,bidder_id` where `status='pending'`).
- **Flutter Model:** `TaskType` enum + `taskType` field; `isTender/isBooking` getters.
- **Services:** Explicit `select(..., task_type, ...)` in `task_service.dart`.
- **UI:**
  - `TaskDetailsScreen` shows **View Offers / Submit Offer** for tender; **Check Availability / Book Now** placeholders for booking.
  - `RequestsListScreen` **guarded** for non-tender with info message.
  - Submit-offer BottomSheet receives controller by parameter; `useRootNavigator: false`.
- **Bugfix:** Resolved `ProviderNotFoundException` when opening submit-offer sheet.

#### 📈 Impact

- Clear separation between bidding (tender) and scheduling (booking).
- Robust UX with no cross-route provider issues.
- Ready foundation for Sprint 2 (Booking: availability + reservations).

#### 🔜 Next (Sprint 2)

- Add `availability_slots` + `bookings` tables + RLS.
- Implement `AvailabilityScreen` + `BookingSheet`.
- Realtime updates for bookings; prevent double-booking with trigger.

### 🔰 Version 0.1 - Initial State (Baseline)

**Date**: Before 2025-07-25
**Status**: Basic Flutter project with minimal functionality

#### What Existed

- ✅ Basic Flutter project structure
- ✅ Supabase integration setup
- ✅ Basic authentication system (email/password)
- ✅ Simple profile management
- ✅ Database tables: `users`, `roles`, `user_roles`
- ✅ Row-level security (RLS) policies
- ✅ Basic UI with login/signup screens

#### Project Structure (v0.1)

```
lib/
├── core/
│   ├── models/
│   ├── repositories/
│   └── services/
├── features/
│   ├── auth/
│   │   ├── controller/
│   │   ├── data/
│   │   ├── model/
│   │   └── ui/
│   ├── profile/
│   │   └── ui/
│   ├── home/
│   ├── booking/
│   ├── chat/
│   └── tasks/
└── main.dart
```

#### Key Features (v0.1)

- Basic authentication flow
- User profile editing
- Avatar upload functionality
- Role switching (client/freelancer)
- Simple navigation between screens

#### Issues in v0.1

- ❌ Inconsistent folder structure
- ❌ Mixed naming conventions
- ❌ No proper navigation system
- ❌ Incomplete feature implementation
- ❌ No standardized architecture

---

### 🚀 Version 1.1 - Major Architecture Restructuring

**Date**: 2025-07-25
**Status**: Complete project restructuring and navigation implementation
**Commit**: `97f9704` - "feat: Complete project restructuring to align with STRUCTURE.md"

#### 🏗️ Major Changes

##### 1. Complete Architecture Restructuring

- **Reorganized entire project** to follow STRUCTURE.md standards
- **Implemented modular feature-based architecture** with proper separation of concerns
- **All features now follow** `presentation/`, `controllers/`, `services/`, `models/` pattern
- **Standardized naming conventions** across the entire project

##### 2. Bottom Navigation System Implementation

- **Added complete 4-tab navigation system**: Home, Chat, Tasks, Profile
- **Implemented MainNavigationScreen** with IndexedStack for state preservation
- **Created CustomBottomNavBar component** with NavigationProvider for state management
- **Material Design 3 consistent theming** throughout the app

##### 3. Core Infrastructure Enhancements

- **Added `core/utils/`** with PriceFormatter and DateFormatter utilities
- **Created `core/providers/navigation_provider.dart`** for app-wide navigation state
- **Enhanced `core/widgets/`** with reusable CustomBottomNavBar component
- **Proper Provider setup** with dependency injection in main.dart

##### 4. Feature-by-Feature Restructuring

###### Auth Feature Restructuring

- **Before**: `controller/`, `data/`, `model/`, `ui/`
- **After**: `presentation/`, `controllers/`, `services/`
- **Changes**:
  - Moved AuthController to use ChangeNotifier pattern
  - Created AuthService for Supabase integration
  - Updated LoginScreen with proper Provider integration
  - Fixed navigation to use MainNavigationScreen

###### Home Feature Enhancement

- **Added**: `controllers/`, `widgets/`
- **Changes**:
  - Created HomeController for managing featured tasks
  - Added ServiceCard widget for displaying task listings
  - Enhanced HomeScreen with pull-to-refresh and loading states
  - Integrated with TaskModel for data structure
  - Added mock data for featured tasks display

###### Chat Feature Implementation

- **Added**: `controllers/`, `models/`
- **Changes**:
  - Created ChatController with message management
  - Added ChatMessage model with JSON serialization
  - Prepared structure for real-time messaging implementation
  - Ready for Supabase Realtime integration

###### Tasks Feature Implementation

- **Added**: `controllers/`, `models/`, `services/`
- **Changes**:
  - Implemented TaskController with CRUD operations
  - Created Task model with TaskStatus enum
  - Added TaskService for Supabase integration
  - Prepared for job posting and browsing functionality
  - Mock data implementation for testing

###### Profile Feature Restructuring

- **Before**: Mixed structure with old ProfileView
- **After**: `controllers/`, `widgets/`
- **Changes**:
  - Restructured to use ProfileController with ChangeNotifier
  - Created ProfileAvatarWidget for image upload functionality
  - Enhanced ProfileScreen with complete form validation
  - Fixed ProviderNotFoundException by updating import structure
  - Added logout functionality in app bar

##### 5. Provider Integration & Bug Fixes

- **Updated main.dart** with all controllers (Auth, Home, Chat, Tasks, Profile, Navigation)
- **Proper MultiProvider setup** for dependency injection
- **Fixed all import paths** to use new structure
- **Resolved ProviderNotFoundException** by updating ProfileScreen
- **Added proper initialization** for all controllers

##### 6. Documentation & Reference

- **Added comprehensive STRUCTURE.md** guide
- **Created Windserf_Refrence.md** with complete project analysis
- **Updated README_SLINE_OVERVIEW.md** placeholder
- **Documented all architectural decisions** and patterns

#### 📁 New Project Structure (v1.0)

```
lib/
├── app/                     # Main App Configs
│   └── main_navigation_screen.dart
├── core/                    # Shared Resources
│   ├── models/              # Global data models
│   ├── providers/           # App-wide state
│   │   └── navigation_provider.dart
│   ├── repositories/        # Data access layer
│   ├── services/            # Core services
│   │   └── supabase_config.dart
│   ├── utils/               # Helper functions
│   │   └── format_price.dart
│   └── widgets/             # Shared UI components
│       └── custom_bottom_nav_bar.dart
├── features/                # Feature-based organization
│   ├── auth/
│   │   ├── controllers/
│   │   │   └── auth_controller.dart
│   │   ├── presentation/
│   │   │   └── login_screen.dart
│   │   └── services/
│   │       └── auth_service.dart
│   ├── chat/
│   │   ├── controllers/
│   │   │   └── chat_controller.dart
│   │   ├── models/
│   │   │   └── chat_message_model.dart
│   │   └── presentation/
│   │       └── chat_screen.dart
│   ├── home/
│   │   ├── controllers/
│   │   │   └── home_controller.dart
│   │   ├── presentation/
│   │   │   └── home_screen.dart
│   │   └── widgets/
│   │       └── service_card.dart
│   ├── profile/
│   │   ├── controllers/
│   │   │   └── profile_controller.dart
│   │   ├── presentation/
│   │   │   └── profile_screen.dart
│   │   └── widgets/
│   │       └── profile_avatar_widget.dart
│   └── tasks/
│       ├── controllers/
│       │   └── task_controller.dart
│       ├── models/
│       │   └── task_model.dart
│       ├── presentation/
│       │   └── tasks_screen.dart
│       └── services/
│           └── task_service.dart
└── main.dart
```

#### ✅ Key Features Implemented (v1.0)

##### Navigation System

- **4-tab bottom navigation**: Home, Chat, Tasks, Profile
- **IndexedStack implementation** for state preservation
- **NavigationProvider** for reactive state management
- **Consistent Material Design 3** theming

##### Home Screen

- **Featured tasks display** with ServiceCard widgets
- **Pull-to-refresh functionality**
- **Loading states and empty state handling**
- **Mock data integration** for testing

##### Profile Management

- **Complete profile editing form** with validation
- **Avatar upload functionality** with image picker
- **Role switching capabilities**
- **Logout functionality**
- **Real-time data sync** with Supabase

##### Authentication System

- **Email/password authentication**
- **User session management**
- **Proper error handling** and user feedback
- **Navigation integration** with main app flow

##### Data Models & Services

- **Task model** with status management
- **ChatMessage model** for messaging
- **Service layer** for Supabase integration
- **Utility functions** for formatting

#### 🔧 Technical Improvements (v1.0)

##### Architecture

- **Modular design**: Each feature is self-contained and testable
- **Separation of concerns**: UI, logic, and services properly separated
- **Scalable structure**: Easy to add new features without breaking others
- **Reusable components**: Shared components and services in core/

##### State Management

- **Provider pattern**: Consistent ChangeNotifier usage
- **Proper dependency injection**: All controllers registered in main.dart
- **Reactive UI updates**: Consumer widgets for state changes
- **No global state pollution**: Each feature manages its own state

##### Code Quality

- **English comments**: All code documented in English
- **Consistent naming**: Following Dart conventions
- **Proper error handling**: Try-catch blocks with user feedback
- **Form validation**: Complete input validation throughout

#### 🎯 Current Capabilities (v1.0)

##### What Users Can Do

1. **Authentication**: Register, login, logout
2. **Navigation**: Seamlessly switch between 4 main sections
3. **Profile Management**: Edit profile, upload avatar, change role
4. **Home Dashboard**: View featured tasks, refresh content
5. **Basic UI**: Consistent Material Design interface

##### What's Ready for Development

1. **Chat System**: Controller and model structure ready for real-time messaging
2. **Task Management**: Complete CRUD operations structure ready
3. **Booking System**: Placeholder structure ready for implementation
4. **Enhanced Features**: All foundations laid for advanced functionality

#### 🐛 Issues Fixed (v1.0)

- ✅ **ProviderNotFoundException**: Fixed by updating ProfileScreen structure
- ✅ **Inconsistent folder structure**: Standardized to STRUCTURE.md
- ✅ **Mixed naming conventions**: Unified to Dart standards
- ✅ **Navigation issues**: Implemented proper bottom navigation
- ✅ **Import path problems**: Updated all imports to new structure
- ✅ **State management issues**: Proper Provider integration

#### 📊 Development Statistics (v1.0)

- **Files Changed**: 24 files
- **Lines Added**: 2,065 lines
- **Lines Removed**: 4 lines
- **New Features Created**: 5 major features
- **Controllers Implemented**: 6 controllers
- **Models Created**: 2 data models
- **Services Added**: 2 service classes
- **Widgets Created**: 3 custom widgets

---

## 🔮 Future Development Roadmap

### 📋 Next Priority Features

- [Update] B1 (Categories DB) is provisioned in DB; upcoming step is to switch Task form dropdown to use CategoriesService.

#### Version 1.1 - Task Management System

- **Task Posting**: Complete UI for clients to post jobs
- **Task Browsing**: Freelancer interface for browsing available tasks
- **Task Details**: Detailed view with bidding functionality
- **Task Status Management**: Progress tracking and updates
- **Search & Filters**: Advanced task search capabilities

#### Version 1.2 - Real-time Chat System

- **Supabase Realtime Integration**: Live messaging functionality
- **Chat Threads**: Conversation management between users
- **Message History**: Persistent chat storage and retrieval
- **Push Notifications**: Real-time message notifications
- **File Sharing**: Document and image sharing in chats

#### Version 1.3 - Booking & Payment System

- **Project Booking**: Formal project agreement system
- **Milestone Management**: Project phase tracking
- **Payment Integration**: Stripe or similar payment processor
- **Invoice Generation**: Automated billing system
- **Dispute Resolution**: Conflict management tools

#### Version 1.4 - Enhanced User Experience

- **Reviews & Ratings**: User feedback system
- **User Profiles**: Enhanced freelancer/client profiles
- **Portfolio Management**: Showcase work and skills
- **Advanced Search**: AI-powered matching system
- **Analytics Dashboard**: Performance metrics for users

### 🔧 Technical Debt & Improvements

- **Legacy Folder Cleanup**: Remove any remaining old structure files
- **Performance Optimization**: Image compression, lazy loading
- **Offline Support**: Local caching for core features
- **Testing Implementation**: Unit tests, widget tests, integration tests
- **CI/CD Pipeline**: Automated testing and deployment

---

## 📚 Development Guidelines

### 🎯 Architecture Principles

1. **Follow STRUCTURE.md**: Maintain consistent folder structure
2. **Separation of Concerns**: Keep UI, logic, and data layers separate
3. **Provider Pattern**: Use ChangeNotifier for state management
4. **English Documentation**: All code and comments in English
5. **Modular Design**: Each feature should be self-contained

### 🔄 Development Workflow

1. **Feature Planning**: Define requirements and structure
2. **Model Creation**: Design data models first
3. **Service Implementation**: Create service layer for data operations
4. **Controller Development**: Implement business logic
5. **UI Implementation**: Build presentation layer
6. **Testing**: Ensure functionality works correctly
7. **Documentation**: Update logs and documentation
8. **Git Commit**: Detailed commit messages

### 📝 Commit Message Format

```
feat/fix/docs: Brief description

🎯 What was implemented:
- Feature 1
- Feature 2

🔧 Technical changes:
- Change 1
- Change 2

📊 Impact:
- Impact description
```

---

## 🎯 Key Learnings & Decisions

### ✅ What Worked Well

1. **Modular Architecture**: Easy to navigate and maintain
2. **Provider Pattern**: Consistent state management across features
3. **STRUCTURE.md Guide**: Clear development standards
4. **Feature-based Organization**: Logical code separation
5. **Comprehensive Documentation**: Easy to understand and continue

### 🔄 What Could Be Improved

1. **Testing Coverage**: Need comprehensive test suite
2. **Performance Monitoring**: Add performance tracking
3. **Error Handling**: More robust error management
4. **User Feedback**: Better loading states and error messages
5. **Code Reviews**: Implement peer review process

### 📋 Important Notes for Future Development

1. **Always follow STRUCTURE.md** when adding new features
2. **Update this log** with every significant change
3. **Maintain Provider pattern** for state management
4. **Keep documentation updated** with architectural changes
5. **Test thoroughly** before committing major changes

---

_This log should be updated with every major version release and significant feature implementation._

---

### 📦 Version 1.3 - My Tasks & Task Editing

**Date**: 2025-08-02  
**Status**: Completed My Tasks feature with edit/delete support  
**Commit**: _Pending_ - "feat: Add My Tasks tab with edit and delete functionality"

#### 🆕 Implemented Features

##### 1. My Tasks Section

- Added "My Tasks" tab inside Profile screen
- Displays list of tasks created by the logged-in user
- Auto-loads tasks when the Profile screen is opened

##### 2. Edit/Delete Task

- Edit: Reuses CreateTaskScreen in edit mode with prefilled data
- Delete: Removes selected task with confirmation and state refresh
- TaskService updated with `updateTask` method
- ProfileController extended with `fetchMyTasks`, `deleteMyTask`, `updateMyTask`

#### 📊 Impact

- Users can now manage their posted tasks from Profile
- Improves user experience by allowing direct editing and deletion of tasks
- Prepares the groundwork for request and messaging features

---

### 📦 Version 1.2 - Task Creation Feature

**Date**: 2025-07-26  
**Status**: Task creation fully implemented with Supabase integration  
**Commit**: _Pending_ - "feat: Implement task creation with full UI and Supabase integration"

#### 🆕 Implemented Features

##### 1. Create Task Flow

- Added full-screen `CreateTaskScreen` under `features/tasks/presentation/`
- Integrated form fields: title, description, budget, skills, and category
- Connected to `TaskController` for business logic
- Used `TaskModel` to structure task data
- Implemented validation and submission feedback

##### 2. Supabase Integration

- Task is created via `TaskService.createTask()` method
- Task is saved to Supabase with correct userId and category field
- Implemented error handling and loading state

##### 3. Category Field Support

- TaskModel updated to include `category` field
- Supabase `tasks` table now includes a `category` column (type: text)
- UI dropdown for category selection integrated in create task screen
- Home screen updated to show category inside task cards

##### 4. UI/UX Enhancements

- Applied proper theming and spacing for Material 3
- Included success SnackBar after task is posted
- Disabled button when loading to prevent multiple submissions

##### 5. Publisher Info Display

- TaskCard now displays publisher full_name and avatar_url
- Implemented Supabase relationship (tasks → users) for fetching user info
- Added SnackBar confirmation after successful task posting to replace black screen issue
- Ensured BottomNavigationBar persists after publishing task

#### 📊 Impact

- Users (clients) can now post tasks into the marketplace
- Category is now a required field, shown in both posting and display
- Feature unlocks the next step: browsing tasks for freelancers

#### 📌 Next Steps After v1.2

- Implement task browsing screen for freelancers
- Display task details screen on tap
- Enable filtering by category and skill

# --- v0.7 Logger Integration & Messaging Fix ---

### 📦 Version 0.7 - Logger Integration & Messaging Fix

**Date**: 2025-08-03  
**Status**: Completed logger integration and messaging display fixes  
**Commit**: _Pending_ - "feat: Integrate AppLogger and enhance messaging UI"

#### 🆕 Implemented Features

##### 1. Centralized Logger Integration

- Added `core/services/logger_service.dart` with `AppLogger` using PrettyPrinter
- Replaced all `debugPrint` calls with `AppLogger` (d/i/w/e)
- Ensured logs only display in debug mode using `kDebugMode`

##### 2. Messaging System Enhancements

- Extended `Conversation` model with `lastMessage` and `lastMessageTime`
- Updated `message_service.dart` to fetch `last_message` safely (handles Map/List/null)
- Updated `messages_screen.dart` UI to WhatsApp-style preview:
  - Avatar + name of other user
  - Last message content
  - Timestamp of last message
- Fixed conversation fetching to prevent type cast errors
- Verified Supabase queries handle relationships with `profiles` table

##### 3. Supabase Adjustments

- Confirmed `conversations` table foreign keys:
  - `user1_id → auth.users.id`
  - `user2_id → auth.users.id`
  - `task_id → tasks.id`
- Adjusted Supabase query joins for `profiles` to fetch user names
- Added safe handling for `messages` relation returning arrays

##### 4. Task Publishing Confirmation

- Replaced black screen issue after posting task with success SnackBar
- Ensured BottomNavigationBar persists after publishing

#### 📊 Impact

- Debug console now shows structured, meaningful logs only in debug mode
- Messaging tab reliably displays all conversations with last message + time
- Groundwork laid for Supabase Realtime integration for live chat
- Users receive clear feedback when posting tasks, eliminating confusion from previous black screen issue

# --- v0.8 Supabase Realtime Messaging ---

### 📦 Version 0.8 - Supabase Realtime Messaging

**Date**: 2025-08-03  
**Status**: Enabled Supabase Realtime for conversations and messages  
**Commit**: _Pending_ - "feat: Enable Supabase Realtime for conversations and messages"

#### 🆕 Implemented Features

##### 1. Supabase Realtime Integration

- Enabled realtime on `messages` and `conversations` tables
- Subscribed to conversation and message changes using `supabase.channel`
- UI now auto-updates when new messages are sent/received between users

##### 2. Security Policies

- Added row-level security policies to restrict access:
  - Conversations visible only to participants
  - Messages visible only to sender and participants of a conversation
- Insert policies restricted to authenticated users

##### 3. UI Enhancements

- Conversations list updates in real-time when a new message is added
- Last message preview updates instantly without refresh
- Fixed null/empty lastMessage cases to prevent crashes

##### 4. Debug Logging

- Extended AppLogger to show realtime subscription events
- Clear logs for join, insert, update, and delete events

#### 📊 Impact

- True real-time messaging between accounts without manual refresh
- Improved user experience with instant updates in the Chat tab
- Secure policies ensure no unauthorized data access

# --- v0.9 Realtime Messaging Fix & Cleanup ---

### 📦 Version 0.9 - Realtime Messaging Fix & Cleanup

**Date**: 2025-08-05  
**Status**: Fixed realtime sync issues and cleaned message flow  
**Commit**: _Pending_ - "fix: Enhance realtime chat sync & clean message handling"

#### 🆕 Implemented Features

##### 1. Realtime Messaging Fixes

- Fixed issue where new messages did not appear instantly on the receiver’s side
- Added `listenToMessagesRealtime()` in `message_service.dart` and integrated it in `chat_controller.dart`
- Verified Supabase channel subscription for reliable event listening

##### 2. Code Cleanup & Refactor

- Removed unused and duplicate code from:
  - `messages_screen.dart`
  - `chat_controller.dart`
  - `message_service.dart`
- Cleaned up redundant imports

##### 3. Bug Fixes

- Resolved ambiguous import for `Conversation` by using alias imports
- Replaced deprecated `inFilter()` with `.in_()` for Supabase queries
- Fixed type cast issue in message fetching methods by adding explicit casting

##### 4. Logging & Documentation

- Enhanced AppLogger output for realtime events:
  - ✅ Conversations fetched
  - ✅ Conversations updated
  - 📩 New message received and messages refreshed
- Added detailed English documentation/comments in:
  - `chat_controller.dart`
  - `message_service.dart`
  - `messages_screen.dart`

#### 📊 Impact

- Users now see new messages instantly without refreshing
- Reduced risk of runtime errors due to cleaner code
- Improved maintainability with consistent documentation
- Debug console provides clear feedback for realtime chat operations

# 📘 SLine App - Complete Development Log

**Last Updated:** 2025-08-17

---

## 🎯 Project Overview

Flutter + Supabase freelance marketplace with real-time chat, tasks, and profiles.

---

## 📋 Version History

### 🟢 Version 1.4 — Chat Attachments & Storage

**Date:** 2025-08-17  
**Commit:** _Pending_ — "feat: chat attachments with Supabase Storage (private)"

#### ✅ Implemented

- Message model extended with: `receiver_id`, `attachment_url`, `attachment_type`, `attachment_name`, `attachment_size`.
- Private bucket `chat-attachments` created; upload via `AttachmentService`.
- Storage RLS policies for INSERT/SELECT using `policyname` (fixed `polname` error) and `schemaname='storage'`.
- `MessageService` updated:
  - `createOrGetConversation` with order-insensitive pair filter.
  - `sendMessage` accepts text and/or attachment.
  - `getMessages` returns attachment fields.
  - Realtime ordered by `created_at`.
- `ChatScreen` UI:
  - Image/File pickers (`image_picker`, `file_picker`).
  - Image thumbnails via signed URL; file chip with name.
- DB index on `(conversation_id, created_at)` for messages.

#### 🧪 Verification

- Upload image/file → appears instantly on both sides (realtime).
- Storage objects visible in `chat-attachments` under `conversationId/…`.
- Signed URL works for authenticated users (policy SELECT present).
- `flutter analyze` clean except minor `.withOpacity` notice (optional: use `.withValues(alpha: 0.85)`).

#### 🛠 SQL Snapshot

```sql
ALTER TABLE public.messages
  ADD COLUMN IF NOT EXISTS receiver_id uuid REFERENCES public.profiles(id),
  ADD COLUMN IF NOT EXISTS attachment_url text,
  ADD COLUMN IF NOT EXISTS attachment_type text,
  ADD COLUMN IF NOT EXISTS attachment_name text,
  ADD COLUMN IF NOT EXISTS attachment_size integer;

CREATE INDEX IF NOT EXISTS idx_messages_convo_created
  ON public.messages (conversation_id, created_at);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'chat_attach_insert_auth'
      AND schemaname = 'storage'
      AND tablename  = 'objects'
  ) THEN
    CREATE POLICY "chat_attach_insert_auth"
    ON storage.objects
    FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'chat-attachments' AND owner = auth.uid());
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'chat_attach_select_auth'
      AND schemaname = 'storage'
      AND tablename  = 'objects'
  ) THEN
    CREATE POLICY "chat_attach_select_auth"
    ON storage.objects
    FOR SELECT
    TO authenticated
    USING (bucket_id = 'chat-attachments');
  END IF;
END$$;
```

---

### 📦 Version 1.3 — My Tasks & Task Editing

**Date:** 2025-08-02  
**Status:** Completed  
**Commit:** _Pending_ — "feat: Add My Tasks tab with edit and delete functionality"

(unchanged content retained)

---

### 📦 Version 1.2 — Task Creation Feature

**Date:** 2025-07-26  
**Status:** Completed

(unchanged content retained)

---

### 🧱 v0.9 / v0.8 / v0.7 — Realtime & Logger groundwork

(unchanged content retained; see previous notes)

# 📘 SLine App - Complete Development Log (Consolidated)

**Last Updated:** 2025-08-17

---

## 🎯 Overview

Flutter + Supabase freelance marketplace with real-time chat, tasks, and profiles.

---

## 📋 Version History (highlights)

### 🟢 Version 1.5 — Realtime Optimizations & Attachments Isolation

**Date:** 2025-08-17  
**Commit:** _Pending_ — "fix: realtime upsert, chats render images instantly; tighten queries"

#### ✅ Implemented

- **Realtime (messages):** in-place **upsert** on events (insert/replace + sort by `created_at`).
- **Immediate image rendering:** append server-returned message directly after send.
- **Query stability:** chain `.or()` / `.in_()` **before** `.order()` / `.limit()`.
- **Conversations last_message:** `order(created_at desc)` + `limit 1` on embedded `messages`.
- **Null-safety in ChatScreen:** guard `user?.id` when computing `isMine`.
- **Attachments isolation:** `features/chat/attachments/` (services + widgets).

#### 📦 Impact

- Lower network usage and smoother UI in long threads.
- No temporary `[photo]` text bubbles — images show immediately.
- Fewer edge-case crashes (null auth, heavy relations).

#### 🔧 Files (high level)

- `chat_controller.dart`: send flow + realtime listener upsert
- `message_service.dart`: query order/limit + filter order
- `chat/presentation/`: `ChatScreen`, `AttachmentMessageTile`
- `attachments/services/`: `upload_service.dart` wrapper → `AttachmentService`

---

### 🟢 Version 1.4 — Chat Attachments & Storage

**Date:** 2025-08-17  
**Commit:** _Pending_ — "feat: chat attachments with Supabase Storage (private)"

#### ✅ Implemented

- Message model extended: `receiver_id`, `attachment_url`, `attachment_type`, `attachment_name`, `attachment_size`.
- Storage bucket `chat-attachments` (private) with INSERT/SELECT policies.
- `AttachmentService` (upload + signed URL), UI image/file bubbles.
- DB index `(conversation_id, created_at)` for messages.

#### 🧪 SQL Snapshot

(see `SUPABASE_SETUP.md`).

---

### 📦 Version 1.3 — My Tasks & Task Editing (2025-08-02)

- "My Tasks" in Profile with edit/delete.

### 📦 Version 1.2 — Task Creation (2025-07-26)

- CreateTaskScreen + TaskService integration.

### 🔧 v0.9 / v0.8 / v0.7 — Realtime & Logger groundwork

- Realtime enabled for conversations/messages, AppLogger integrated.

---

## 🧭 Notes

- Docs consolidated: **STRUCTURE.md**, **SUPABASE_SETUP.md**, **MVP_ROADMAP.md**.
- Keep comments and docs in **English**; product UI bilingual later.

> ملاحظة: إذا عندك لقسم قديم باسم “6.2 حارس إنشاء المحادثات (Client-only)”، استبدله بالكامل بالنص الجديد أعلاه.

---

# 2) Sline_Log.md

## أضِف مدخلة نسخة جديدة تحت “Version History”

ابحث عن عنوان `## 📋 Version History` وألصق المقطع التالي **مباشرة بعده**:
🟢 Version 1.8 — Chat guard flip (owner blocked) + RPC v1 + UI guard

Date: 2025-09-14
Commit: Pending — “fix(chat): block owner from starting task chat; add RPC v1; client guard”

✅ Implemented
 • DB Trigger: Replaced trg_conversations_before_insert_guard logic → owner cannot start task-linked chats; non-owner must chat with task owner; normalized (user1_id,user2_id) order.
 • RPC: Added start_task_conversation_v1(p_task_id uuid) returning conversations row; grants to authenticated.
 • Flutter: message_service.createOrGetConversation() now calls start_task_conversation_v1(...).select().single(); task_card.dart shows a friendly SnackBar if owner taps Chat.

📈 Impact
 • Prevents server-side error surfaces to owners; clean UX for non-owners.
 • Eliminates duplicate conversations for the same (task + pair).
