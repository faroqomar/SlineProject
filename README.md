# SLine — Freelance Marketplace Platform

<div align="center">

![Version](https://img.shields.io/badge/version-2.1-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.8.1+-02569B?logo=flutter)
![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-3ECF8E?logo=supabase)
![License](https://img.shields.io/badge/license-Private-red.svg)

**A modern, cross-platform freelance marketplace connecting clients with service providers**

[Features](#-features) • [Tech Stack](#-tech-stack) • [Getting Started](#-getting-started) • [Documentation](#-documentation) • [AI Agents](#-ai-agents)

</div>

---

## 🎯 Overview

**SLine** is a production-grade freelance marketplace mobile application built with Flutter and Supabase. It enables clients to post jobs, freelancers to showcase their work and submit bids, and both parties to communicate in real-time with enterprise-grade security.

### The Problem We Solve

- **Clients**: Need a fast, reliable way to find and hire freelancers, negotiate terms via chat, and book appointments
- **Freelancers**: Need a platform to showcase their portfolio, receive structured job offers, manage availability, and get hired
- **Platform**: Ensure trust, safety, and quality through moderation and transparent interactions

### Business Model

Two-sided marketplace with:
- **Tender-based tasks** — Clients receive bids from freelancers
- **Booking-based tasks** — Clients schedule appointments with freelancers
- **Real-time messaging** — In-app negotiation and project communication
- **Portfolio system** — Trust-building through work showcase
- **Future**: Escrow payments, premium placement, AI-powered matching

---

## ✨ Features

### 🔐 Authentication & Profiles
- Email/password authentication via Supabase Auth
- Role selection (Client or Freelancer)
- Profile management with avatar upload (private storage + signed URLs)
- Session management with automatic re-authentication

### 📋 Task Management
- Create tasks (tender with bidding OR booking with scheduling)
- Multiple image uploads (private storage with signed URLs)
- Search and filter by category/keywords
- Task details with creator info
- Edit/delete own tasks
- Task status tracking (open → assigned → completed → closed)

### 💼 Offers & Requests System
- Freelancers submit structured offers (price + timeline)
- Clients review and accept/reject offers
- One pending offer per bidder per task (enforced by database)
- Offer messages in chat with typed payload

### 💬 Real-time Messaging
- WhatsApp-style chat interface
- Conversations list with last message preview
- Task-linked conversations for job discussions
- Direct messages (requires favoriting)
- Image/file attachments (private storage + signed URLs)
- Real-time updates via WebSocket subscriptions
- Optimized realtime (upsert-in-place, no full refetch)

### 📅 Booking System
- Providers create availability slots (open/blocked)
- Clients book available slots
- Status management (pending → confirmed → completed/canceled)
- Timezone-safe (UTC storage, local display)
- Overlap prevention for provider slots
- Max one active booking per slot

### ⭐ Favorites & Saved Tasks
- Clients save freelancers to favorites
- Enables DM creation (business rule enforcement)
- Bookmark tasks for later
- Optimistic UI updates

### 🖼️ Portfolio System
- Freelancers upload work samples with images
- CRUD operations for portfolio items
- Public gallery (visible to all authenticated users)
- Project URL and description support

### 🎨 Theme System (v2.1)
- Centralized theme dashboard (`theme_dashboard.dart`)
- iOS 26-inspired liquid glass bottom navigation
- Material Design 3 with Glassmorphism effects
- AppColors, AppTypography, AppDimens, AppDecorations

---

## 🛠️ Tech Stack

### Frontend
- **Flutter 3.8.1+** — Cross-platform UI framework (iOS, Android, Web, Desktop)
- **Dart 3.8.1+** — Programming language
- **Material Design 3** — Modern UI components with Glassmorphism
- **Provider** — State management (ChangeNotifier pattern)

### Backend (Supabase BaaS)
- **PostgreSQL** — Relational database with strong data integrity
- **Supabase Auth** — Email/password authentication
- **Supabase Storage** — File storage with private buckets and signed URLs
- **Supabase Realtime** — WebSocket subscriptions for live updates
- **Row-Level Security (RLS)** — Database-level access control

### Architecture
- **Pattern**: Strict MVVM (Model-View-ViewModel)
- **Organization**: Feature-based modular structure
- **Security**: RLS on all tables, private storage by default
- **Data Flow**: View → ViewModel → Repository/Service → Supabase

---

## 📂 Project Structure

```
sline_app/
├── lib/                          # Flutter source code
│   ├── app/                      # Application-level configuration
│   │   └── main_navigation_screen.dart
│   ├── core/                     # Shared resources
│   │   ├── models/               # Global models
│   │   ├── services/             # Cross-cutting services
│   │   ├── widgets/              # Shared UI components
│   │   ├── theme/                # 🎨 Centralized theme system
│   │   │   ├── app_colors.dart
│   │   │   ├── app_typography.dart
│   │   │   ├── app_dimens.dart
│   │   │   ├── app_decorations.dart
│   │   │   ├── app_theme.dart
│   │   │   └── theme_dashboard.dart  # Single source of truth
│   │   ├── providers/            # Global state
│   │   └── utils/                # Helper functions
│   ├── features/                 # Feature modules (MVVM)
│   │   ├── auth/                 # Authentication
│   │   ├── home/                 # Home feed/dashboard
│   │   ├── tasks/                # Task management
│   │   ├── chat/                 # Real-time messaging
│   │   ├── profile/              # User profiles
│   │   ├── portfolio/            # Freelancer portfolio
│   │   ├── booking/              # Booking & availability
│   │   ├── wallet/               # Wallet & transactions
│   │   ├── orders/               # Order management
│   │   ├── notifications/        # Notifications
│   │   ├── favorites/            # Saved freelancers
│   │   ├── saved/                # Saved tasks
│   │   └── categories/           # Service categories
│   └── main.dart                 # App entry point
├── .cursor/                      # 🤖 Cursor AI configuration
│   ├── Agents/                   # AI agent definitions (7 agents)
│   ├── rules/                    # Coding rules (.mdc files)
│   └── PROJECT_CONTEXT.md        # Quick reference
├── .TODO/                        # Design & planning
│   ├── New_Design/               # React Native design references
│   └── Future_Plans/             # Feature inventory
├── Sline_everything/             # 📚 Project documentation
├── GEMINI.md                     # Project overview & agent triggers
└── .cursorrules                  # Always-active rules
```

### Feature Structure (MVVM)
Each feature follows strict MVVM:
```
features/<feature>/
├── view/                    # UI Layer - Screens & Widgets
├── viewmodels/              # Business Logic - ChangeNotifier
├── models/                  # Data Models
├── data/                    # Repository Layer
└── services/                # Backend Integration
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK 3.8.1+](https://flutter.dev/docs/get-started/install)
- [Dart SDK 3.8.1+](https://dart.dev/get-dart)
- Supabase account ([supabase.com](https://supabase.com))
- IDE: VS Code or Cursor with Flutter extension

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd sline_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Setup Supabase**
   - Create a new Supabase project
   - Run the SQL schema from `Sline_everything/SUPABASE_SETUP.md`
   - Copy your Supabase URL and anon key
   - Update `lib/core/services/supabase_config.dart` with your credentials

4. **Run the app**
   ```bash
   # List available devices
   flutter devices

   # Run on specific device
   flutter run -d chrome              # Web
   flutter run -d android             # Android
   flutter run -d ios                 # iOS simulator
   ```

### Development Commands

```bash
# Code analysis
flutter analyze

# Format code
flutter format .

# Run tests
flutter test

# Check outdated packages
flutter pub outdated

# Build for production
flutter build apk                    # Android APK
flutter build ios                    # iOS (requires Xcode)
flutter build web                    # Web deployment

# Clean build artifacts
flutter clean && flutter pub get
```

---

## 🤖 AI Agents

SLine uses specialized AI agents (in `.cursor/Agents/`) for different tasks:

| Agent | Trigger | Focus |
|-------|---------|-------|
| **@Architect** | `@Architect`, "fix logic", "refactor" | Logic, MVVM compliance, refactoring |
| **@Pixel** | `@Pixel`, "design this", "make it pretty" | UI/UX, Glassmorphism, themes |
| **@Supabase_Ops** | `@Supabase`, "add table", "secure db" | Database, RLS, SQL, storage |
| **@Sentinel** | `@Sentinel`, "check this", "run tests" | QA, security, testing |
| **@SlineDocs** | `@SlineDocs`, "document this" | Documentation updates |
| **@SlinePlanner** | `@SlinePlanner`, "plan this feature" | Implementation planning |
| **@CodeGuard** | `@CodeGuard`, "review code", "performance check" | Code reviews, performance, security, dependencies |

### Cursor Configuration

```
.cursor/
├── Agents/                 # Agent definitions (.md files)
├── rules/                  # Coding rules (.mdc files)
│   ├── flutter-mvvm.mdc    # MVVM pattern rules
│   ├── supabase-database.mdc # Database rules
│   ├── ui-theme.mdc        # Theme system rules
│   ├── error-handling.mdc  # Error handling patterns
│   └── code-quality.mdc    # Code quality standards
└── PROJECT_CONTEXT.md      # Quick reference guide
```

---

## 📚 Documentation

### 📖 Essential Docs (Start Here)

| Document | Purpose |
|----------|---------|
| **[GEMINI.md](./GEMINI.md)** | Project overview, agents, building instructions |
| **[Sline_everything/DEVELOPER_GUIDE.md](./Sline_everything/DEVELOPER_GUIDE.md)** | System architecture & feature map |
| **[.cursor/PROJECT_CONTEXT.md](./.cursor/PROJECT_CONTEXT.md)** | Quick reference for development |

### 📋 Core Documentation

| Document | Description |
|----------|-------------|
| [STRUCTURE.md](./Sline_everything/STRUCTURE.md) | Project folder structure & conventions |
| [SUPABASE_SETUP.md](./Sline_everything/SUPABASE_SETUP.md) | Database schema, RLS policies, triggers (executable SQL) |
| [MVP_ROADMAP.md](./Sline_everything/MVP_ROADMAP.md) | Feature roadmap & completion status |
| [Sline_Log.md](./Sline_everything/Sline_Log.md) | Complete version history |
| [CODE_REVIEW.md](./Sline_everything/CODE_REVIEW.md) | Code quality patterns & best practices |

### 🎓 Feature-Specific Guides

Located in `Sline_everything/DEVELOPER_GUIDE/`:
- Auth Feature.md
- Task Feature.md
- Chat Feature.md
- Booking Feature.md
- Profile Feature.md
- Portfolio Feature.md
- And more...

---

## 🏗️ Architecture

### MVVM Pattern (Strict Enforcement)

**View Layer** (`view/`):
- Pure UI rendering (StatelessWidget/StatefulWidget)
- Observes ViewModel via `Consumer<ViewModel>`
- Local form state only
- **NEVER makes direct Supabase calls**

**ViewModel Layer** (`viewmodels/`):
- Extends `ChangeNotifier`
- Manages UI state (loading, error, data)
- Orchestrates Repository/Service calls
- Business logic and validation
- Calls `notifyListeners()` after state changes

**Repository/Service Layer** (`data/`, `services/`):
- Encapsulates ALL Supabase queries
- Error mapping (RLS → user-friendly messages)
- Storage operations (upload, signed URLs)
- Never exposes raw database errors

**Model Layer** (`models/`):
- Immutable data classes
- JSON serialization (`fromJson`, `toJson`)
- UTC timestamps (converted to local in UI)

### Security Architecture

**Row-Level Security (RLS)**:
- ALL tables have RLS enabled
- Session-based access control (`auth.uid()`)
- Policies: owner-only, participant-based, role-based

**Private Storage**:
- All user uploads in private buckets
- Signed URLs (1-hour TTL, cached ~90min)
- Storage paths in database, NOT URLs

---

## 🎯 Current Status

### Version 2.1 (December 2025)

**Latest Changes**:
- ✅ Theme System Dashboard (centralized theme management)
- ✅ iOS 26 Liquid Glass Bottom Navigation
- ✅ CodeGuard Agent (code reviews, performance, security)
- ✅ Feature Inventory System
- ✅ Video Call Feature Removed (scope reduction)

**Completed Features**:
- Auth & Profiles (with private avatar storage)
- Tasks (tender/booking, images, CRUD, search/filter)
- Real-time Chat (DM + task-linked, attachments)
- Offers/Bids (unique pending per bidder)
- Booking System (availability slots, timezone-safe)
- Favorites & Saved Tasks
- Portfolio (CRUD, public gallery)
- Wallet & Orders Dashboard
- Notifications System
- Theme System (centralized)
- 7 AI Agents for development

### Priority Roadmap

**Immediate**:
- Audit `Colors.*` → `AppColors` migration
- Update Supabase Flutter to v2.x

**Short-term**:
- Localization (Arabic RTL + English LTR)
- Push notifications (FCM)
- User ratings & reviews

**Medium-term**:
- Payment integration & escrow
- Analytics dashboard
- Admin Dashboard

---

## 🤝 Contributing

### Development Standards

**Code Quality**:
- ✅ English only (code, comments, docs)
- ✅ No `print()` — use `AppLogger.d/i/w/e`
- ✅ Lint clean (`flutter analyze`)
- ✅ Formatted (`flutter format .`)

**Critical Patterns**:
- ✅ Check `mounted` after `await` in StatefulWidget
- ✅ Store paths, not URLs (for storage)
- ✅ UTC timestamps (store UTC, display local)
- ✅ Cursor pagination (not offset)
- ✅ Use `AppColors`, not hardcoded colors

**Architecture Rules**:
- ❌ NO Supabase calls in View layer
- ❌ NO business logic in View layer
- ❌ NO storing signed URLs in database
- ❌ NO hardcoded colors (`Color(0xFF...)`)

### Adding a New Feature

1. **Database First**: Schema + RLS + indexes + triggers
2. **Create Feature Directory**: `lib/features/<feature>/`
3. **Models**: Immutable data classes with JSON serialization
4. **Services/Repos**: Supabase calls + error mapping
5. **ViewModels**: State management + business logic
6. **Views**: UI screens + widgets
7. **Wire Providers**: Add to `main.dart`
8. **Documentation**: Update `Sline_Log.md` + create feature guide

---

## 📞 Quick Reference

**Commands**:
```bash
flutter run                         # Run app
flutter analyze                     # Static analysis
flutter test                        # Run tests
flutter pub outdated                # Check dependencies
AppLogger.d('message')              # Debug logging
AppLogger.i('message')              # Info logging
```

**Key Files**:
- **Theme**: `lib/core/theme/theme_dashboard.dart`
- **Config**: `lib/core/services/supabase_config.dart`
- **Navigation**: `lib/app/main_navigation_screen.dart`
- **Agents**: `.cursor/Agents/`
- **Rules**: `.cursor/rules/`

**Documentation Root**: `/Sline_everything/`

---

## 📄 License

Private - All Rights Reserved

---

<div align="center">

**Built with ❤️ using Flutter & Supabase**

[⬆ Back to Top](#sline--freelance-marketplace-platform)

</div>
