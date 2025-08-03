
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
- `services/`: Supabase service, image picker, **logger (AppLogger for debug-only logs)**, etc.
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
- `chat/`: real-time messaging
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