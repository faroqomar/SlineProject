
# 📁 SLine App – Folder Structure Guide

This document explains the folder structure used in the SLine freelance marketplace app built with Flutter, Supabase, and FastAPI.

---

## 🔰 Top-Level Overview

```
lib/
├── app/
├── core/
├── features/
├── generated/
└── main.dart
```

---

## 📂 `lib/app/`

Contains global application configurations such as:

- `main_navigation_screen.dart`: Holds the `BottomNavigationBar` and all main screens.
- `app_theme.dart`: (Optional) Stores light/dark theme configs.

---

## 📂 `lib/core/`

Houses shared logic, services, and UI elements across the app.

- `models/`: Global data models (e.g., user model).
    - `services/`: Supabase service (including Realtime subscriptions for messages & conversations), image picker, **logger (AppLogger for debug-only logs)**, etc.
- `repositories/`: Abstract business logic layer over services.
- `widgets/`: Shared UI widgets like buttons, nav bars, etc.
- `providers/`: Global state (like navigation).
- `utils/`: Helper functions (e.g., date/price formatters).

---

## 📂 `lib/features/`

Each feature has its own isolated folder with this recommended structure:

```
features/
└── [feature_name]/
    ├── presentation/   # UI: screens & widgets
    ├── controllers/    # UI logic (ChangeNotifier or Riverpod)
    ├── services/       # Feature-specific backend logic
    └── models/         # Feature-specific data models
```

### Feature Examples:
- `auth/`: login/signup
- `home/`: service cards & feed
- `chat/`: real-time messaging with Supabase Realtime subscriptions
- `tasks/`: post and manage tasks
- `profile/`: view and edit user profile
- `booking/`: booking services

---

## 📂 `lib/generated/`

Contains generated localization files (`l10n.dart`) if using Flutter Intl for multi-language support.

---

## 🧠 Core Principles

- **Modular Design**: Each feature is self-contained and testable.
- **Separation of Concerns**: UI, logic, and services are separated.
- **Scalable**: Easy to add new features without breaking others.
- **Reusable**: Shared components and services live in `core/`.

---

## 📌 Example: Adding a New Feature

To add a `notifications` feature:

```
lib/features/notifications/
├── presentation/
├── controllers/
├── services/
└── models/
```

Then link it to the app via `main_navigation_screen.dart`.

---

This structure helps keep SLine maintainable, scalable, and easy to navigate for all contributors.

---

## 🔄 Recent Updates (2025-08-03)

- Integrated Supabase Realtime into the `chat` module for instant messaging updates.
- Updated `core/services/` with structured logging (AppLogger).
- Ensured cross-platform fixes for Chrome file uploads (`dart:io.File` vs `storage_client.File`).
- Improved UX: Added SnackBar confirmation after task publishing.
- **2025-08-22**: 
- Ownership enforcement in Offers: hide submit for owners; accept/reject visible only to task owner; RLS prevents owner self-bidding.
  - Added `TaskType` (tender/booking) to `TaskModel` and wired UI splits in `TaskDetailsScreen`.
  - Completed Offers flow (RequestsListScreen + SubmitRequestSheet) with provider-safe BottomSheet.
  - Guarded RequestsListScreen for non-tender tasks; booking placeholders connected for Sprint 2.
lib/
├── app/                     # Main App Configs: navigation, themes, and entry points
│   ├── main_navigation_screen.dart  # Holds bottom nav and routes to feature screens
│   └── app_theme.dart               # Custom light/dark themes (if needed)
│
├── core/                    # Shared, reusable resources across features
│   ├── models/              # Global data models used across the app
│   │   └── user_model.dart
│   ├── services/            # Generic services (e.g., logger, supabase, image picker)
│   │   └── supabase_service.dart
│   ├── repositories/        # Abstract layer over services (fetchUser, getTasks)
│   │   └── user_repository.dart
│   ├── widgets/             # Shared custom widgets (e.g., buttons, cards)
│   │   └── custom_bottom_nav_bar.dart
│   ├── providers/           # App-wide logic state (e.g., navigation state)
│   │   └── navigation_provider.dart
│   └── utils/               # Helper functions (validators, date formatting, etc.)
│       └── format_price.dart
│
├── features/                # Each app feature in its own isolated folder
│   ├── auth/                # Signup, login, onboarding
│   │   ├── presentation/    # UI widgets/screens
│   │   │   └── login_screen.dart
│   │   ├── controllers/     # UI logic (ChangeNotifier)
│   │   │   └── auth_controller.dart
│   │   └── services/        # Specific service calls (Supabase Auth etc.)
│   │       └── auth_service.dart
│
│   ├── home/                # Homepage (freelancer/client feed)
│   │   ├── presentation/
│   │   │   └── home_screen.dart
│   │   ├── controllers/
│   │   │   └── home_controller.dart
│   │   └── widgets/         # Card for task offer, ratings, etc.
│   │       └── service_card.dart
│
│   ├── chat/                # Real-time messaging module
│   │   ├── presentation/
│   │   │   └── chat_screen.dart
│   │   ├── controllers/
│   │   │   └── chat_controller.dart
│   │   └── models/
│   │       └── chat_message_model.dart
│
│   ├── tasks/               # Posting and bidding on tasks
│   │   ├── presentation/
│   │   │   ├── tasks_screen.dart
│   │   │   └── create_task_screen.dart
│   │   ├── controllers/
│   │   │   └── task_controller.dart
│   │   ├── models/
│   │   │   └── task_model.dart
│   │   └── services/
│   │       └── task_service.dart
│
│   ├── profile/             # Profile view/edit, role switch
│   │   ├── presentation/
│   │   │   └── profile_screen.dart
│   │   ├── controllers/
│   │   │   └── profile_controller.dart
│   │   └── widgets/
│   │       └── profile_avatar_widget.dart
│
│   └── booking/             # Booking/reservation module
│       ├── presentation/
│       │   └── booking_screen.dart
│       ├── controllers/
│       │   └── booking_controller.dart
│       └── models/
│           └── booking_model.dart
│
├── generated/               # (auto) localization files, if using Flutter intl
│   └── l10n.dart
│
└── main.dart                # Entry point of the app → calls MainNavigationScreen

    ├── presentation/
    │   ├── profile_screen.dart
    │   └── portfolio/
    │       ├── portfolio_screen.dart
    │       ├── widgets/
    │       │   ├── portfolio_grid.dart
    │       │   ├── add_portfolio_sheet.dart
    │       │   └── portfolio_details_sheet.dart
    ├── controllers/
    │   ├── profile_controller.dart
    │   └── portfolio_controller.dart
    ├── services/
    │   └── portfolio_service.dart
    └── models/
        └── portfolio_item.dart

# 📁 SLine App – Folder Structure Guide (Updated)

**Last updated:** 2025-08-17

This document explains the folder structure used in the SLine freelance marketplace app built with Flutter, Supabase, and FastAPI.

---

## 🔰 Top-Level Overview

```
lib/
├── app/
├── core/
├── features/
├── generated/
└── main.dart
```

---

## 📂 `lib/app/`
- `main_navigation_screen.dart`: BottomNavigationBar + main screens.
- `app_theme.dart`: (Optional) Light/Dark themes.

---

## 📂 `lib/core/`
Shared logic, services, and UI.

- `models/`: Global data models.
- `services/`: Supabase service, **logger (AppLogger)**, etc.
- `repositories/`: Business logic over services.
- `widgets/`: Shared UI components.
- `providers/`: App-wide state.
- `utils/`: Helpers (date/price formatters, validators).

---

## 📂 `lib/features/`
Each feature is isolated:

```
features/
└── chat/
    ├── presentation/
    │   └── chat_screen.dart           # UI (now supports images/files)
    ├── controllers/
    │   └── chat_controller.dart       # Realtime subscriptions
    ├── services/
    │   ├── message_service.dart       # send/get/subscribe + createOrGetConversation
    │   └── attachment_service.dart    # upload + signed URLs (chat-attachments bucket)
    └── models/
        ├── conversation_model.dart
        └── message_model.dart         # includes attachment fields
```

Other features follow the same pattern (`auth/`, `tasks/`, `profile/`, ...).

---

## 🧠 Core Principles
- Modular design
- Separation of concerns
- Scalable & testable
- Reusable shared components

---

## 🔄 Recent Updates
- **2025-08-17**: Chat attachments added (Storage bucket, RLS, model/service/UI updates). 
- **2025-08-03**: Realtime messaging enabled and stabilized.
# 📁 SLine App – Folder Structure Guide (Up-to-date)

**Last Updated:** 2025-08-17

This guide explains the feature-first structure used in SLine (Flutter + Supabase).

---

## Top-Level
```
lib/
├── app/
├── core/
├── features/
├── generated/
└── main.dart
```

---

## `lib/app/`
- `main_navigation_screen.dart` — Bottom nav + routing via `IndexedStack`
- `app_theme.dart` — (optional) M3 light/dark themes

## `lib/core/`
Shared logic and cross-cutting utilities:
- `services/` — `supabase_config.dart`, **`logger_service.dart` (AppLogger)**, pickers
- `models/` — app-wide models (e.g., user)
- `repositories/` — indirection over services
- `providers/` — global state (e.g., navigation)
- `widgets/` — shared UI pieces (bottom bar, etc.)
- `utils/` — helpers (date/price formatters)

## `lib/features/`
Each feature is isolated with `presentation/`, `controllers/`, `services/`, `models/`.

### Chat Feature
```
features/chat/
├── presentation/
│   ├── chat_screen.dart              # Thread UI (images/files supported)
│   └── messages_screen.dart          # Conversations list
├── controllers/
│   └── chat_controller.dart          # Realtime (upsert-in-place)
├── services/
│   ├── message_service.dart          # send/get/subscribe + createOrGetConversation
│   └── attachment_service.dart       # upload bytes + signed URLs (private bucket)
├── models/
│   ├── conversation_model.dart
│   └── message_model.dart            # includes attachment fields
└── attachments/
    ├── services/
    │   └── upload_service.dart       # thin wrapper around AttachmentService
    ├── widgets/
    │   └── attachment_message_tile.dart
    ├── models/                       # (optional, payload types)
    └── utils/                        # (optional, MIME helpers)
```

### Other Features
- `auth/`, `tasks/`, `profile/`, `booking/` — same pattern

---

## Principles
- **Feature isolation:** attachments live under `chat/attachments/`
- **Realtime:** avoid full-list refetch; **upsert** new events locally
- **Queries:** apply `.or()` / `.in_()` **before** `.order()` / `.limit()`
- **Docs & comments:** English only
- **Logging:** use `AppLogger` for debug, avoid `print`

## 📚 lib File Index (auto-generated: 2025-09-02)

## 🔄 Recent Updates (2025-09-20)

- **Avatars (private):** إنشاء سلة `avatars` + سياسات RLS (INSERT/SELECT لمالك الملف)، توحيد `ProfileController`، إضافة ويدجت **SignedAvatar** (يصنع signed URL + كاش داخلي). صور البروفايل تتحدث فورًا في Home/Tasks/Profile.
- **Task Images (private):** إنشاء سلة `task-images` + RLS، إضافة **TaskImageService** (رفع بايتات + signed URL)، وإضافة عمود **`tasks.image_paths text[]`** (idempotent) وربطه بالواجهة.
- **UI:**
  - `task_card.dart`: عرض أول صورة للمهمة عبر **SignedImage**.
  - `task_details_screen.dart`: عرض أول صورة فوق الوصف عبر **SignedImage**.
- **تنظيف كود:** استبدال `.withOpacity` بـ `.withValues(alpha: ...)`، إزالة imports غير مستخدمة، وحل تضارب تعريف `ProfileController`.

- `widgets/`: Shared UI widgets like buttons, nav bars, etc.
  - `signed_avatar.dart` — resolves avatar storage path → short-lived signed URL with caching.
  - `signed_image.dart` — resolves task image storage path/URL → short-lived signed URL with caching.

task_image_service.dart (upload to task-images + createSignedUrl)

Sorted ascending. Keep this section in sync when files change.

```text
lib/app/main_navigation_screen.dart
lib/core/models/user_profile.dart
lib/core/providers/navigation_provider.dart
lib/core/services/logger_service.dart
lib/core/services/supabase_config.dart
lib/core/theme/app_colors.dart
lib/core/utils/format_date.dart
lib/core/utils/format_price.dart
lib/core/widgets/custom_bottom_nav_bar.dart
lib/features/.DS_Store
lib/features/auth/controller/auth_controller.dart
lib/features/auth/controllers/auth_controller.dart
lib/features/auth/data/auth_repository.dart
lib/features/auth/model/user_credentials.dart
lib/features/auth/presentation/login_screen.dart
lib/features/auth/services/auth_service.dart
lib/features/auth/ui/login_screen.dart
lib/features/auth/ui/signup_screen.dart
lib/features/booking/controllers/booking_controller.dart
lib/features/booking/models/booking_model.dart
lib/features/booking/models/slot_model.dart
lib/features/booking/presentation/add_slot_sheet.dart
lib/features/booking/presentation/availability_screen.dart
lib/features/booking/presentation/booking_sheet.dart
lib/features/booking/presentation/bookings_list_screen.dart
lib/features/booking/services/booking_service.dart
lib/features/categories/models/category_model.dart
lib/features/categories/services/categories_service.dart
lib/features/chat/attachments/errors/attachment_exceptions.dart
lib/features/chat/attachments/models/attachment_payload.dart
lib/features/chat/attachments/services/compress_service.dart
lib/features/chat/attachments/services/pick_image_service.dart
lib/features/chat/attachments/services/send_attachment_usecase.dart
lib/features/chat/attachments/services/upload_service.dart
lib/features/chat/attachments/utils/mime_utils.dart
lib/features/chat/attachments/widgets/attachment_message_tile.dart
lib/features/chat/controllers/chat_controller.dart
lib/features/chat/models/conversation_model.dart
lib/features/chat/models/message_model.dart
lib/features/chat/presentation/chat_screen.dart
lib/features/chat/presentation/messages_screen.dart
lib/features/chat/presentation/widgets/message_bubble.dart
lib/features/chat/services/attachment_service.dart
lib/features/chat/services/message_service.dart
lib/features/favorites/controller/favorites_controller.dart
lib/features/favorites/data/favorites_service.dart
lib/features/favorites/models/favorite_model.dart
lib/features/favorites/presentation/screens/favorites_screen.dart
lib/features/favorites/presentation/widgets/favorite_card.dart
lib/features/favorites/routes/favorites_routes.dart
lib/features/home/controllers/home_controller.dart
lib/features/home/presentation/home_screen.dart
lib/features/home/widgets/service_card.dart
lib/features/profile/controllers/portfolio_controller.dart
lib/features/profile/controllers/profile_controller.dart
lib/features/profile/models/portfolio_item.dart
lib/features/profile/presentation/portfolio/ sheets/ add_portfolio_sheet.dart
lib/features/profile/presentation/portfolio/ sheets/edit_portfolio_sheet.dart
lib/features/profile/presentation/portfolio/ sheets/portfolio_details_sheet.dart
lib/features/profile/presentation/portfolio/portfolio_screen.dart
lib/features/profile/presentation/portfolio/widgets/image_placeholder.dart
lib/features/profile/presentation/portfolio/widgets/portfolio_tile.dart
lib/features/profile/presentation/profile_screen.dart
lib/features/profile/services/portfolio_service.dart
lib/features/profile/ui/controller/profile_controller.dart
lib/features/profile/ui/widgets/profile_avatar.dart
lib/features/profile/ui/widgets/profile_form.dart
lib/features/profile/ui/widgets/profile_language_toggle.dart
lib/features/profile/ui/widgets/profile_logout_button.dart
lib/features/profile/ui/widgets/profile_name_field.dart
lib/features/profile/ui/widgets/profile_password_reset.dart
lib/features/profile/ui/widgets/profile_role_toggle.dart
lib/features/profile/ui/widgets/profile_view.dart
lib/features/profile/widgets/profile_avatar_widget.dart
lib/features/saved/controller/saved_tasks_controller.dart
lib/features/saved/data/saved_tasks_service.dart
lib/features/saved/models/saved_task_model.dart
lib/features/saved/presentation/screens/saved_tasks_screen.dart
lib/features/saved/presentation/screens/widgets/saved_task_tile.dart
lib/features/saved/routes/saved_routes.dart
lib/features/tasks/controllers/task_controller.dart
lib/features/tasks/controllers/task_filter_controller.dart
lib/features/tasks/controllers/task_requests_controller.dart
lib/features/tasks/models/task_model.dart
lib/features/tasks/models/task_request_model.dart
lib/features/tasks/presentation/create_task_screen.dart
lib/features/tasks/presentation/requests/requests_list_screen.dart
lib/features/tasks/presentation/requests/submit_request_sheet.dart
lib/features/tasks/presentation/requests/widgets/request_tile.dart
lib/features/tasks/presentation/task_details_screen.dart
lib/features/tasks/presentation/widgets/task_card.dart
lib/features/tasks/services/task_requests_service.dart
lib/features/tasks/services/task_service.dart
lib/main.dart
lib/shared/constants/categories.dart
lib/features/profile/services/avatar_service.dart
lib/core/widgets/signed_avatar.dart
lib/core/widgets/signed_image.dart