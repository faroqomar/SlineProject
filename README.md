# SLine — Freelance Marketplace Platform

<div align="center">

![Version](https://img.shields.io/badge/version-1.9-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.8.1+-02569B?logo=flutter)
![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-3ECF8E?logo=supabase)
![License](https://img.shields.io/badge/license-Private-red.svg)

**A modern, cross-platform freelance marketplace connecting clients with service providers**

[Features](#-features) • [Tech Stack](#-tech-stack) • [Getting Started](#-getting-started) • [Documentation](#-documentation) • [Architecture](#-architecture)

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

### 🏷️ Categories System
- Database-first category management
- Predefined categories (Design, Development, Marketing, etc.)
- Read-only for regular users

---

## 🛠️ Tech Stack

### Frontend
- **Flutter 3.8.1+** — Cross-platform UI framework (iOS, Android, Web, Desktop)
- **Dart 3.8.1+** — Programming language
- **Material Design 3** — Modern UI components
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
lib/
├── app/                          # Application-level configuration
│   └── main_navigation_screen.dart   # Bottom nav + routing
├── core/                         # Shared resources
│   ├── models/                   # Global models (user_profile)
│   ├── services/                 # Cross-cutting services
│   │   ├── supabase_config.dart  # Supabase initialization
│   │   └── logger_service.dart   # AppLogger (debug-only)
│   ├── widgets/                  # Shared UI components
│   │   ├── signed_avatar.dart    # Avatar with signed URLs
│   │   └── signed_image.dart     # Image with signed URLs
│   ├── theme/                    # App theming
│   └── utils/                    # Helper functions
├── features/                     # Feature modules (MVVM)
│   ├── auth/                     # Authentication
│   ├── home/                     # Home feed/dashboard
│   ├── tasks/                    # Task management
│   ├── chat/                     # Real-time messaging
│   ├── profile/                  # User profiles
│   ├── portfolio/                # Freelancer portfolio
│   ├── booking/                  # Booking & availability
│   ├── favorites/                # Saved freelancers
│   ├── saved/                    # Saved tasks
│   └── categories/               # Service categories
├── shared/                       # Shared constants
└── main.dart                     # App entry point
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
- IDE: VS Code or Android Studio with Flutter extension

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

# Build for production
flutter build apk                    # Android APK
flutter build ios                    # iOS (requires Xcode)
flutter build web                    # Web deployment

# Clean build artifacts
flutter clean && flutter pub get
```

---

## 📚 Documentation

### 📖 Essential Docs (Start Here)

| Document | Purpose | Audience |
|----------|---------|----------|
| **[CLAUDE.md](./CLAUDE.md)** | Complete development guide for AI assistants | Developers, Claude Code |
| **[AI_PROJECT_PROMPT.md](./AI_PROJECT_PROMPT.md)** | Comprehensive project context for AI (1200+ lines) | AI Assistants, New Developers |
| **[Sline_everything/DEVELOPER_GUIDE.md](./Sline_everything/DEVELOPER_GUIDE.md)** | System architecture & feature map | All Developers |

### 📋 Core Documentation

| Document | Description |
|----------|-------------|
| [STRUCTURE.md](./Sline_everything/STRUCTURE.md) | Project folder structure & conventions |
| [SUPABASE_SETUP.md](./Sline_everything/SUPABASE_SETUP.md) | Database schema, RLS policies, triggers (executable SQL) |
| [MVP_ROADMAP.md](./Sline_everything/MVP_ROADMAP.md) | Feature roadmap & completion status |
| [Sline_Log.md](./Sline_everything/Sline_Log.md) | Complete version history (200+ lines) |

### 🎓 Feature-Specific Guides

Located in `Sline_everything/DEVELOPER_GUIDE/`:
- Auth Feature.md
- Task Feature.md
- Chat Feature.md
- Booking Feature.md
- Profile Feature.md
- Portfolio Feature.md
- Favorites Feature.md
- Saved Feature.md
- Categories Feature.md
- Home Feature.md
- Core Module.md

### 📊 Analysis & Review (October 2024)

| Document | Purpose |
|----------|---------|
| [CODE_REVIEW.md](./Sline_everything/CODE_REVIEW.md) | Code quality assessment (7.5/10 → 9/10) |
| [ARCHITECTURE_ANALYSIS.md](./Sline_everything/ARCHITECTURE_ANALYSIS.md) | Scalability & performance analysis |
| [FEATURE_ENHANCEMENTS.md](./Sline_everything/FEATURE_ENHANCEMENTS.md) | 18 feature proposals with roadmap |
| [COMPREHENSIVE_ANALYSIS_SUMMARY.md](./Sline_everything/COMPREHENSIVE_ANALYSIS_SUMMARY.md) | Executive overview |

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
- Queries fail without valid session

**Private Storage**:
- All user uploads in private buckets
- Signed URLs (1-hour TTL, cached ~90min)
- Storage paths in database, NOT URLs
- RLS on storage objects

**Database Triggers**:
- Business rules enforced at database level
- Prevent offers on booking tasks
- Auto-assign task on offer acceptance
- Prevent overlapping availability slots
- Enforce DM requires favorite relationship
- Validate offer message payloads

---

## 🎯 Current Status

### Version 1.9 (November 2025)

**Completed Features** ✅:
- Auth & Profiles (with private avatar storage)
- Tasks (tender/booking, images, CRUD, search/filter)
- Real-time Chat (DM + task-linked, attachments, typed messages)
- Offers/Bids (unique pending per bidder, accept/reject)
- Booking System (availability slots, reservations, timezone-safe)
- Favorites & Saved Tasks (optimistic updates)
- Portfolio (CRUD, public gallery)
- Categories (DB-first, read-only)
- Infrastructure (AppLogger, signed images, error mapping)

**Code Quality**: 7.5/10 (targeting 9/10 after Sprint 1-2 fixes)

### Priority Roadmap

**Immediate (1-3 weeks) — Performance Sprint**:
- 🔴 **CRITICAL**: Fix N+1 query in TaskService (50x performance improvement)
- Add caching layer (in-memory + SQLite)
- Pull-to-refresh on all list screens
- Lifecycle-aware realtime subscriptions
- Shimmer skeleton loaders
- Enhanced empty states

**Short-term (1-3 months)**:
- Push notifications (FCM)
- User ratings & reviews
- Advanced task filters
- Role switching UI
- Theme system (Light/Dark mode)
- Localization (Arabic RTL + English LTR)
- Admin Dashboard (React/TypeScript)

**Medium-term (3-6 months)**:
- Payment integration & escrow
- Video/voice calls (Agora/Twilio)
- Location-based search
- Analytics dashboard
- Content moderation tools

**Long-term (6-12 months)**:
- AI-powered freelancer matching
- Subscription tiers
- Event sourcing for audit trails
- Microservices extraction
- Offline-first architecture

---

## 🧪 Testing

### Testing Strategy

**Unit Tests**:
- Repositories/Services (mock Supabase)
- ViewModels (state transitions)
- Utilities (formatting, pagination)

**Widget Tests**:
- Forms, validation, error display
- Image widgets, placeholders, fallbacks
- Lists (empty states, loading, pull-to-refresh)

**Integration Tests** (staging DB):
- Full user flows (auth → task → offer → chat → booking)
- RLS enforcement (negative tests)
- File storage lifecycle

**Non-Functional**:
- Performance (cold start, scrolling FPS)
- Battery (realtime subscriptions)
- Network (offline behavior, retries)

### Testing Checklist (Per Feature)
- [ ] Happy path works end-to-end
- [ ] RLS enforced (unauthorized access fails)
- [ ] Unique constraints handled gracefully
- [ ] Error states render correctly
- [ ] UI states (loading/error/empty) work
- [ ] Optimistic updates + rollback on failure
- [ ] Timestamps display in local timezone
- [ ] Pagination works without duplicates

---

## 📈 Key Performance Indicators

| Metric | Target | Priority |
|--------|--------|----------|
| DAU/MAU Ratio | >20% | HIGH |
| Task Completion Rate | >60% | HIGH |
| 30-Day User Retention | >40% | HIGH |
| Avg Session Length | >10 min | MEDIUM |
| Crash-Free Rate | >99% | CRITICAL |

**Post-Monetization KPIs**:
- GMV (Gross Merchandise Value)
- Take Rate (commission %)
- LTV/CAC Ratio (target >3:1)

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
- ✅ Error mapping (user-friendly messages)

**Architecture Rules**:
- ❌ NO Supabase calls in View layer
- ❌ NO business logic in View layer
- ❌ NO storing signed URLs in database
- ❌ NO skipping RLS considerations

### Adding a New Feature

1. **Database First**: Schema + RLS + indexes + triggers
2. **Create Feature Directory**: `lib/features/<feature>/`
3. **Models**: Immutable data classes with JSON serialization
4. **Services/Repos**: Supabase calls + error mapping
5. **ViewModels**: State management + business logic
6. **Views**: UI screens + widgets
7. **Wire Providers**: Add to `main.dart`
8. **Tests**: Unit + widget + integration
9. **Documentation**: Update `Sline_Log.md` + create feature guide

---

## 🛡️ Security & Privacy

- **RLS Enabled** on all tables (database-level security)
- **Private Storage** with short-lived signed URLs
- **Session Validation** on every query
- **Input Validation** client-side + database constraints
- **Error Masking** (no raw SQL errors exposed to users)
- **Audit Trails** via database triggers
- **Data Encryption** at rest (Supabase default) + in transit (TLS)

---

## 📞 Quick Reference

**Commands**:
```bash
flutter run                         # Run app
flutter analyze                     # Static analysis
flutter test                        # Run tests
AppLogger.d('message')              # Debug logging
AppLogger.i('message')              # Info logging
```

**Database**: Supabase Dashboard → Tables / SQL / Policies
**Storage**: Supabase Dashboard → Storage → Buckets
**Auth**: Supabase Dashboard → Authentication → Users

**Documentation Root**: `/Sline_everything/`
**Core Code**: `/lib/core/`
**Features**: `/lib/features/`

---

## 📄 License

Private - All Rights Reserved

---

## 📧 Contact & Support

For questions about architecture, features, or contributing:
- Review documentation in `Sline_everything/`
- Check `CLAUDE.md` for development patterns
- Read feature-specific guides in `DEVELOPER_GUIDE/`

---

<div align="center">

**Built with ❤️ using Flutter & Supabase**

[⬆ Back to Top](#sline--freelance-marketplace-platform)

</div>
