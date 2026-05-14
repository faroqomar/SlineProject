# SLine — Freelance Marketplace Platform

<div align="center">

![Version](https://img.shields.io/badge/docs-2.33.0-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.8.1+-02569B?logo=flutter)
![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-3ECF8E?logo=supabase)
![License](https://img.shields.io/badge/license-Private-red.svg)

**A modern, cross-platform freelance marketplace connecting clients with service providers**

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
- **Secure Wallet & Escrow** — Double-entry ledger system for safe fund handling
- **Future**: Premium placement, AI-powered matching

---

## Features

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

### 💳 Payment Ledger System (In Progress)

- Double-entry accounting system across `accounts`, `journal_entries`, and `ledger_lines`
- Escrow hold mechanism gating funds between booking and delivery
- Atomic RPC engine strictly enforcing zero negative balances, idempotency, and audit logging
- Stripe webhook integration for top-ups (deposits) and payouts (withdrawals)
- Immutable ledger architecture (append-only)

### 🎨 Theme System

- Three-layer design system: theme, layout, and components
- AppColors, AppTypography, AppMotion, AppDecorations, AppStates, AppTheme
- AppLayout and AppDimens for layout rhythm and fixed sizing
- Scoped Amber Dusk token layer under `lib/core/theme/designs/amber_dusk/`
- Material Design 3 remains the runtime foundation unless a plan explicitly changes it

---

## Tech Stack

### Frontend

- **Flutter 3.8.1+** — Cross-platform UI framework (iOS, Android, Web, Desktop)
- **Dart 3.8.1+** — Programming language
- **Material Design 3** — Runtime foundation with scoped Amber Dusk token adapters
- **Provider** — State management (ChangeNotifier pattern)

### Backend (Supabase BaaS)

- **PostgreSQL** — Relational database with strong data integrity
- **Supabase Auth** — Email/password authentication
- **Supabase Storage** — File storage with private buckets and signed URLs
- **Supabase Realtime** — WebSocket subscriptions for live updates
- **Row-Level Security (RLS)** — Database-level access control
- **Postgres RPC** — Atomic execution engine for strict transaction enforcement and idempotency

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
│   │   ├── theme/                # Three-layer theme and design tokens
│   │   │   ├── app_colors.dart
│   │   │   ├── app_typography.dart
│   │   │   ├── app_dimens.dart
│   │   │   ├── app_decorations.dart
│   │   │   ├── app_theme.dart
│   │   │   └── designs/              # Staged design systems, including Amber Dusk
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
├── .cursor/                      # Agent and rule configuration
│   ├── Agents/                   # Agent definitions
│   ├── rules/                    # Coding rules (.mdc files)
│   └── PROJECT_CONTEXT.md        # Quick reference
├── .TODO/                        # Active plans, QA checklists, and future work
├── Sline_everything/             # Project documentation and diagrams
├── AGENTS.md                     # Repository guidance for coding agents
└── docs/LOG/                     # Session and system-evolution logs
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

## Install And Run

### Prerequisites

- [Flutter SDK 3.8.1+](https://flutter.dev/docs/get-started/install)
- Dart SDK 3.8.1+ from the Flutter toolchain
- Xcode for iOS builds and simulators
- Android Studio or Android SDK tools for Android builds
- Supabase project access for backend-backed development
- VS Code, Cursor, or Android Studio with Flutter tooling

### 1. Clone And Install Dependencies

```bash
git clone <repository-url>
cd sline_app
flutter pub get
```

### 2. Configure Supabase

This checkout currently stores the Supabase URL and anon key in `lib/core/services/supabase_config.dart`. The anon key is public-client configuration; data access is protected by Row Level Security.

For a new Supabase project:

1. Create or select the Supabase project.
2. Apply the schema, policies, storage buckets, triggers, and RPCs from [Sline_everything/SUPABASE_SETUP.md](./Sline_everything/SUPABASE_SETUP.md).
3. Update `lib/core/services/supabase_config.dart` if you are pointing this app at a different project.
4. Review [Sline_everything/DOC_SOURCE_MAP.md](./Sline_everything/DOC_SOURCE_MAP.md) for the feature docs and diagrams relevant to your work.
5. For UI, navigation, redesign, modal, popup, tab, route, or reusable-widget work, also review [Sline_everything/UI_SURFACE_INVENTORY.md](./Sline_everything/UI_SURFACE_INVENTORY.md).

### 3. Generate Localizations

Run this after changing localization resources:

```bash
flutter gen-l10n
```

### 4. Run On A Device

```bash
flutter devices
flutter run -d <device_id>
```

Common targets:

```bash
flutter run -d chrome
flutter run -d ios
flutter run -d android
```

Enable Sentry only when you have a DSN:

```bash
flutter run --dart-define=SENTRY_DSN=<dsn> --dart-define=SENTRY_ENV=development
```

### 5. Validate Before Handoff

```bash
dart format .
flutter analyze --no-fatal-infos
flutter test
```

Run these when the change touches the relevant area:

```bash
flutter test test/rls/
flutter test integration_test/
flutter build apk --debug
flutter build ios --no-codesign
flutter build web
```

Clean rebuild:

```bash
flutter clean && flutter pub get
```

---

## AI Agents

SLine uses specialized AI agents in `.cursor/Agents/`. The core workflow is:

`@Planner` → `@PlanCritic` → `@Executor` → `@Orchestrator` → `@SystemEvolution` → `@DocsKeeper`

| Agent | Focus |
| --- | --- |
| `@Planner` | Detailed implementation plans grounded in docs, diagrams, UI inventory, code, and Supabase reality |
| `@PlanCritic` | Plan critique, gap finding, and execution-safety rewrites |
| `@Executor` | Plan execution, delegation, session logging, and verification gates |
| `@Orchestrator` | Full review pipeline and Master Report synthesis |
| `@DocsKeeper` | README, `Sline_everything/`, UI inventory, diagrams, source maps, and session docs sync |
| `@SystemEvolution` | Agent-system improvement reports and deduped durable rule merges |
| `@Architect` | MVVM, logic, contracts, and refactoring |
| `@Pixel` | UI, design-system usage, accessibility, visual QA, and polish |
| `@Supabase_Ops` | Database, RLS, RPC, triggers, storage, and Edge Functions |
| `@Sentinel` | QA, release gate, security validation, and docs freshness checks |
| `@CodeGuard` | Code quality, performance, dependency, and compatibility review |

### Cursor Configuration

```
.cursor/
├── Agents/                 # Agent definitions (.md files)
├── rules/                  # Coding rules (.mdc files)
│   ├── flutter-mvvm.mdc    # MVVM pattern rules
│   ├── supabase-database.mdc # Database rules
│   ├── ui-theme.mdc        # Theme system rules
│   ├── error-handling.mdc  # Error handling patterns
│   ├── code-quality.mdc    # Code quality standards
│   └── comment-guidelines.mdc # Comment coverage standard
└── PROJECT_CONTEXT.md      # Quick reference guide
```

---

## Documentation

### 📖 Essential Docs (Start Here)

| Document                                                                         | Purpose                                         |
| -------------------------------------------------------------------------------- | ----------------------------------------------- |
| **[AGENTS.md](./AGENTS.md)**                                                     | Repository instructions, architecture rules, and standard commands |
| **[Sline_everything/DEVELOPER_GUIDE.md](./Sline_everything/DEVELOPER_GUIDE.md)** | System architecture and feature map             |
| **[Sline_everything/DOC_SOURCE_MAP.md](./Sline_everything/DOC_SOURCE_MAP.md)**   | Feature-to-doc and feature-to-diagram routing   |
| **[Sline_everything/UI_SURFACE_INVENTORY.md](./Sline_everything/UI_SURFACE_INVENTORY.md)** | Complete screen, route, popup, sheet, tab, and shared-widget inventory |

### 📋 Core Documentation

| Document                                                  | Description                                              |
| --------------------------------------------------------- | -------------------------------------------------------- |
| [STRUCTURE.md](./Sline_everything/STRUCTURE.md)           | Project folder structure & conventions                   |
| [SUPABASE_SETUP.md](./Sline_everything/SUPABASE_SETUP.md) | Database schema, RLS policies, triggers (executable SQL) |
| [MVP_ROADMAP.md](./Sline_everything/MVP_ROADMAP.md)       | Feature roadmap & completion status                      |
| [Sline_Log.md](./Sline_everything/Sline_Log.md)           | Complete version history                                 |
| [CODE_REVIEW.md](./Sline_everything/CODE_REVIEW.md)       | Code quality patterns & best practices                   |
| [AppDigram/README.md](./Sline_everything/AppDigram/README.md) | Diagram index for feature planning and review         |

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

### Documentation Version 2.33.0 (2026-05-14)

**Latest Changes**:

- ✅ `Sline_everything/UI_SURFACE_INVENTORY.md` added as the source of truth for screens, routes, popups, sheets, tabs, navigation surfaces, reusable UI widgets, and full visual-file coverage
- ✅ Planner, PlanCritic, Executor, Pixel, Orchestrator, Sentinel, and DocsKeeper now require the UI inventory for UI work
- ✅ Scoped Amber Dusk treatment across auth gates, chat/notifications, tasks/work, booking/payment, and wallet surfaces
- ✅ Scoped Amber Dusk treatment across profile, public profile, portfolio, services, search, categories, favorites, saved tasks, notification modal/list, loading, status, and CTA helper surfaces
- ✅ Step 5 gap scan tightened profile/public-profile composition, portfolio proof tiles, notification contrast, and interaction semantics against Open Design evidence
- ✅ Step 6 Orchestrator review fixed confirmed HIGH/MED profile, notification, search, and dialog gaps and added the Phase 9-12 emulator checklist
- ✅ Notification realtime hardening for transient Supabase websocket closes
- ✅ Phase 9-12 phone-to-web handoff created for Mohammed with missing screenshot/runtime visual QA blockers called out
- ✅ Transactional QA recovery fixed sanitized booking payment return handling, IQD money display, signup/post refresh, Dashboard empty-state CTAs, Dashboard Inbox behavior, Messages search guidance, Wallet withdraw copy, and transactional Amber Dusk surfaces
- ✅ SystemEvolution 2026-05-14 merged runtime proof rules for focused/active form states, payment/booking lifecycle buckets, safe customer-facing payment result UI, and unexecuted gateway-branch reporting
- ✅ Agent workflow gates for README freshness, docs/diagram source maps, and code comment coverage
- ✅ `Sline_everything/DOC_SOURCE_MAP.md` and `Sline_everything/AppDigram/README.md` added for planning/review routing
- ✅ Root README refreshed for new-developer install and run flow

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
- Scoped Amber Dusk design-token adoption in completed phone surfaces
- Agent-assisted planning, execution, review, system evolution, and docs sync

### Priority Roadmap

**Immediate**:

- Complete Amber Dusk emulator visual parity for Phases 2-8, Phases 9-12, and Transactional QA Recovery using the active session logs, handoffs, `.TODO/EMULATOR_TEST_CHECKLIST_2026-05-13_OpenDesign_AmberDusk_Phases9_10_11_12_Step6.md`, and `.TODO/VisualQA_OpenDesign_AmberDusk_TransactionalQARecovery_iOSSimulator_2026-05-13/README.md` before claiming final visual parity
- Keep `README.md`, `Sline_everything/`, diagram index, and source map synchronized on every DocsKeeper pass
- Re-run the full QiCard processed-payment success branch so app success/recovery and Dashboard Bookings can be proven after gateway submission

**Short-term**:

- Expand localization coverage and RTL QA
- Continue push-notification runtime validation
- User ratings & reviews

**Medium-term**:

- Admin Dashboard
- AI-Driven Matching Engine

---

## 🤝 Contributing

### Development Standards

**Code Quality**:

- ✅ English only (code, comments, docs)
- ✅ No `print()` — use `AppLogger.d/i/w/e`
- ✅ Lint clean (`flutter analyze`)
- ✅ Formatted (`dart format .`)

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
8. **Documentation**: Update `README.md`, `Sline_everything/`, source map, diagrams, and session docs when relevant

---

## 📞 Quick Reference

**Commands**:

```bash
flutter run                         # Run app
flutter analyze --no-fatal-infos    # Static analysis
flutter test                        # Run tests
flutter pub outdated                # Check dependencies
```

**Key Files**:

- **Theme**: `lib/core/theme/`
- **Config**: `lib/core/services/supabase_config.dart`
- **Navigation**: `lib/app/main_navigation_screen.dart`
- **Agents**: `.cursor/Agents/`
- **Rules**: `.cursor/rules/`
- **Source Map**: `Sline_everything/DOC_SOURCE_MAP.md`
- **UI Inventory**: `Sline_everything/UI_SURFACE_INVENTORY.md`
- **Diagram Index**: `Sline_everything/AppDigram/README.md`

**Documentation Root**: `/Sline_everything/`

---

## 📄 License

Private - All Rights Reserved

---

<div align="center">

**Built with ❤️ using Flutter & Supabase**

</div>
