# GEMINI.md — Project Brain & Active Context

# SLine Project Rules - Always Active

This file ensures Cursor always references the project rules and documentation.

## CRITICAL: Always Reference Documentation

When working on this project, ALWAYS reference these documentation files:

1. **`GEMINI.md`** - Project overview, agents, building instructions
2. **`Sline_everything/DEVELOPER_GUIDE.md`** - Complete feature documentation
3. **`Sline_everything/SUPABASE_SETUP.md`** - Database schema and RLS
4. **`Sline_everything/STRUCTURE.md`** - File organization
5. **`.cursor/PROJECT_CONTEXT.md`** - Quick reference guide
6. **`.cursor/rules/`** - All rule files for specific patterns

## Architecture Rules

- **MVVM Pattern**: View → ViewModel → Service → Supabase (NEVER direct Supabase in UI)
- **No Hardcoded Colors**: Use `AppColors` or `context.colorScheme`
- **No print()**: Use `AppLogger` from `lib/core/services/logger_service.dart`
- **No N+1 Queries**: Use JOINs, not loops with async calls
- **UTC Timestamps**: Store UTC, convert to local in UI
- **Cursor Pagination**: Use time-based cursors, NOT offsets

## Before Making Changes

1. Check `Sline_everything/SUPABASE_SETUP.md` for database schema
2. Check `Sline_everything/DEVELOPER_GUIDE.md` for feature patterns
3. Check `.cursor/rules/` for specific rules (flutter-mvvm.mdc, supabase-database.mdc, etc.)
4. Check `Sline_everything/CODE_REVIEW.md` for common mistakes to avoid

## Agent System

Use agents for specialized tasks:
- `@Architect` - Logic, MVVM, refactoring
- `@Pixel` - UI, themes, Glassmorphism
- `@Supabase_Ops` - Database, RLS, SQL
- `@Sentinel` - QA, security, testing
- `@SlineDocs` - Documentation updates
- `@SlinePlanner` - Implementation planning
- `@CodeGuard` - Code reviews, performance, security, dependency updates

See `GEMINI.md` and `.cursor/Agents/` for agent definitions.

## File Structure

- `lib/features/[feature]/view/` - UI (NO Supabase calls)
- `lib/features/[feature]/viewmodels/` - Business logic
- `lib/features/[feature]/services/` - Supabase API calls
- `lib/features/[feature]/models/` - Data models
- `lib/core/` - Shared resources (theme, services, widgets)

See `Sline_everything/STRUCTURE.md` for complete structure guide.

> [!IMPORTANT]
> This file is the **Single Source of Truth** for the SLine project (v2.1).
> All agents and developers must reference this file for architectural standards, active agents, and project status.

---

## 🤖 Active Agents (Invoke via @Name)
*The following agents are defined in the `.cursor/Agents/` directory. When invoked, I will adopt their persona.*

| Agent | Trigger | Focus |
|-------|---------|-------|
| **@Architect** | `@Architect`, "fix logic" | Technical Lead. Logic, MVVM compliance, Refactoring. |
| **@Pixel** | `@Pixel`, "design this" | UI/UX Artist. Glassmorphism, Animations, Themes. |
| **@Supabase_Ops** | `@Supabase`, "db schema" | Backend DBA. SQL, RLS, Storage, Edge Functions. |
| **@Sentinel** | `@Sentinel`, "run tests" | QA & Safety. Reviews, Documentation, Testing. |
| **@SlineDocs** | `@SlineDocs`, "update docs" | Docs Scribe. Maintains `Sline_everything/`. |
| **@SlinePlanner** | `@SlinePlanner`, "plan feature" | Strategic Planner. Implementation steps. |
| **@CodeGuard** | `@CodeGuard`, "review code" | Auditor. Performance, Security, Dependencies. |

---

## 🧠 Specialized Skills (in `.agent/skills/`)
*These reuseable skill modules can be invoked by agents or directly.*

| Skill | Folder | Purpose |
|-------|--------|---------|
| **Architecture Enforcer** | `architecture_guard` | Prevents UI direct-DB calls & MVVM drift. |
| **Feature Scaffolder** | `feature_scaffolder` | Generates strict MVVM boilerplate (Model, VM, Service, View). |
| **Supabase Ops** | `supabase_migration` | Generates SQL, RLS Policies, Indexes & Migration Logs. |
| **CRUD Builder** | `crud_generator` | Builds List, Detail, and Form screens wired to VM. |
| **Bug Triage** | `bug_fixer` | Systematic workflow: Reproduce → Isolate → Fix → Verify. |
| **Code Reviewer** | `code_reviewer` | Anti-pattern hunter (Logic leaks, Performance, Naming). |
| **Commit Helper** | `commit_helper` | Standardizes commit messages & update changelogs. |
| **Docs Sync** | `docs_sync` | Keeps `DEVELOPER_GUIDE.md` and `STRUCTURE.md` up to date. |
| **Asset Manager** | `asset_manager` | Type-safe asset management to replace raw strings. |

---

## 🎯 Project Overview (Version 2.1)

**SLine** is a production-grade freelance marketplace mobile application built with **Flutter** and **Supabase**.
It employs a strict **MVVM** architecture and feature-based modularity.

### Core Features (v2.1)
- **Theme System**: Centralized `theme_dashboard.dart` with iOS 26-inspired Liquid Glass navigation.
- **Authentication**: Supabase Auth with Role selection (Client/Freelancer).
- **Tasks**: Tender & Booking systems with private image storage.
- **Messaging**: Real-time chat with attachments (Private Buckets + Signed URLs).
- **Portfolio**: Public gallery for freelancers.
- **Security**: 100% RLS on all tables. Private storage buckets.

---

## 🛠️ Architecture & Standards

### 1. MVVM Pattern (Strict)
- **View (`view/`)**: Pure UI. `Consumer<ViewModel>`. **NO Supabase calls.**
- **ViewModel (`viewmodels/`)**: `ChangeNotifier`. Business logic. Holds state.
- **Repository (`data/` & `services/`)**: DIRECT Supabase calls. Error handling.

### 2. Database & Security
- **RLS**: Enabled on ALL tables. Policies based on `auth.uid()`.
- **Storage**: files in `private` buckets. Access via Signed URLs only.
- **Timestamps**: Stored in UTC, displayed in Local time.

### 3. Coding Style
- **No `print()`**: Use `AppLogger` (d/i/w/e).
- **Colors**: Use `AppColors.*` from `lib/core/theme/`. No hardcoded hex.
- **Formatting**: `flutter format .` and `flutter analyze` are mandatory.

---

## 📂 Project Structure

```text
sline_app/
├── lib/
│   ├── core/theme/           # 🎨 Centralized Theme (AppColors, ThemeDashboard)
│   ├── features/             # 📦 Feature features (auth, tasks, chat, etc.)
│   │   └── <feature>/        # MVVM: view/, viewmodels/, data/, models/
│   └── main.dart             # App Entry
├── .cursor/                  # 🤖 AI Configuration
│   ├── Agents/               # Agent Personas
│   └── rules/                # .mdc Rule files
├── Sline_everything/         # 📚 Documentation Archive
│   ├── MVP_ROADMAP.md        # Feature Status
│   └── SUPABASE_SETUP.md     # SQL Schema
└── GEMINI.md                 # 👈 YOU ARE HERE
```

---

## 🚀 Quick Reference

### Developer Commands
```bash
flutter run                 # Run App
flutter analyze             # Check Lints
flutter test                # Run Unit Tests
flutter format .            # Format Code
```

### Critical Files
- **Theme Truth**: [`lib/core/theme/theme_dashboard.dart`](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/theme/theme_dashboard.dart)
- **Supabase Config**: [`lib/core/services/supabase_config.dart`](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/services/supabase_config.dart)
- **Navigation**: [`lib/app/main_navigation_screen.dart`](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/app/main_navigation_screen.dart)
- **Commenting**: [`agent/rules/comment_guidelines.md`](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/.agent/rules/comment_guidelines.md)

---

## 📊 Roadmap Status (Dec 2025)
- [x] **Project Init & Auth**
- [x] **Tasks Module** (CRUD, Search, Images)
- [x] **Chat System** (Realtime, Attachments, Optimization)
- [x] **Theme Dashboard** (v2.1)
- [ ] **Localization** (Arabic RTL)
- [ ] **Push Notifications**