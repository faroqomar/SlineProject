# SLine Project Context

Quick reference guide for Cursor AI to understand the SLine Flutter app architecture, conventions, and workflows.

## Quick Links

### Documentation Files

- **`GEMINI.md`** - Project overview, agent definitions, building/running instructions, development conventions
- **`Sline_everything/DEVELOPER_GUIDE.md`** - Complete feature documentation with MVVM examples
- **`Sline_everything/SUPABASE_SETUP.md`** - Database schema, RLS policies, triggers, storage buckets
- **`Sline_everything/STRUCTURE.md`** - File organization and folder structure guide
- **`Sline_everything/ARCHITECTURE_ANALYSIS.md`** - Architecture decisions and patterns
- **`Sline_everything/CODE_REVIEW.md`** - Code quality patterns, N+1 query fixes, best practices
- **`Sline_everything/MVP_ROADMAP.md`** - Feature status and development roadmap
- **`Sline_everything/Sline_Log.md`** - Version history and changelog

### Core Code Locations

- **Theme System**: `lib/core/theme/` (AppColors, AppTheme, AppDimens, AppTypography, AppDecorations)
- **Services**: `lib/core/services/` (SupabaseConfig, AppLogger)
- **Widgets**: `lib/core/widgets/` (GlassContainer, SignedAvatar, AppButton, etc.)
- **Utils**: `lib/core/utils/` (format_date.dart, format_price.dart, transitions)
- **Main App**: `lib/main.dart` (Provider setup, MaterialApp configuration)

## Agent System

### Agent Invocation Patterns

Agents are defined in `.cursor/Agents/` and can be invoked using triggers:

| Agent | File | Trigger Keywords | Use Case |
|-------|------|-----------------|----------|
| **@Architect** | `Agents/Architect.md` | "@Architect", "fix logic", "refactor" | Logic, MVVM compliance, refactoring |
| **@Pixel** | `Agents/Pixel.md` | "@Pixel", "design this", "make it pretty" | UI/UX, Glassmorphism, themes |
| **@Supabase_Ops** | `Agents/Supabase_Ops.md` | "@Supabase", "add table", "secure db" | Database, RLS, SQL, storage |
| **@Sentinel** | `Agents/Sentinel.md` | "@Sentinel", "check this", "run tests" | QA, security, documentation sync |
| **@SlineDocs** | `Agents/Sline_Docs.md` | "@SlineDocs", "document this", "update changelog" | Documentation updates |
| **@SlinePlanner** | `Agents/Sline_Planner.md` | "@SlinePlanner", "plan this feature" | Implementation planning |

**Reference**: See `GEMINI.md` for complete agent definitions.

## Architecture Overview

### MVVM Pattern

```
View (UI) → ViewModel (Logic) → Service/Repository → Supabase
```

- **View**: `lib/features/*/view/` - UI widgets, NO direct Supabase calls
- **ViewModel**: `lib/features/*/viewmodels/` - Business logic, state management
- **Service**: `lib/features/*/services/` - Supabase API calls
- **Model**: `lib/features/*/models/` - Data structures

### State Management

- **Provider** + `ChangeNotifier` pattern
- ViewModels extend `ChangeNotifier`
- Use `Consumer<ViewModel>` or `context.watch<ViewModel>()` in UI

### Feature Structure

Each feature follows this structure:
```
features/[feature_name]/
├── view/          # UI screens/widgets
├── viewmodels/   # Business logic
├── services/     # Supabase calls
├── data/         # Repositories (optional)
└── models/       # Data models
```

## Common Workflows

### Adding a New Feature

1. **Database**: Add tables/RLS in `Sline_everything/SUPABASE_SETUP.md`
2. **Model**: Create model in `lib/features/[feature]/models/`
3. **Service**: Create service in `lib/features/[feature]/services/`
4. **ViewModel**: Create ViewModel in `lib/features/[feature]/viewmodels/`
5. **View**: Create UI in `lib/features/[feature]/view/`
6. **Provider**: Register in `lib/main.dart`
7. **Documentation**: Update `Sline_everything/DEVELOPER_GUIDE.md`

### Refactoring Checklist

1. Check `Sline_everything/CODE_REVIEW.md` for common issues
2. Run `flutter analyze` to check for lint errors
3. Ensure no N+1 queries (use JOINs)
4. Verify RLS policies still work
5. Update documentation if architecture changes

### Database Changes

1. Update `Sline_everything/SUPABASE_SETUP.md` with SQL
2. Add RLS policies for new tables
3. Create indexes for frequently queried fields
4. Add triggers/functions if needed
5. Test with actual user sessions

## Key Conventions

### Colors
- **NEVER** use hardcoded colors like `Color(0xFF146068)`
- **ALWAYS** use `AppColors.teal` or `context.colorScheme.primary`
- See `lib/core/theme/app_colors.dart` for available colors

### Logging
- **NEVER** use `print()` or `debugPrint()`
- **ALWAYS** use `AppLogger.i()`, `AppLogger.d()`, `AppLogger.e()`
- Import from `lib/core/services/logger_service.dart`

### Timestamps
- **ALWAYS** store in UTC
- **ALWAYS** convert to local in UI using `formatUtcToLocal()`
- See `lib/core/utils/format_date.dart`

### Pagination
- **NEVER** use offset pagination
- **ALWAYS** use cursor-based pagination with timestamps
- Example: `.lt('created_at', cursorIso)`

### Error Handling
- **ALWAYS** map technical errors to user-friendly messages
- Common codes: 42501 (RLS), 23505 (unique), 23503 (FK)
- See `.cursor/rules/error-handling.mdc` for mapping table

## Storage Buckets

| Bucket | Visibility | Purpose | Pattern |
|--------|-----------|---------|---------|
| `avatars` | Private | Profile pictures | Store path, generate signed URL |
| `task-images` | Private | Task images | Store path, generate signed URL |
| `chat-attachments` | Private | Message files | Store path, generate signed URL |
| `portfolio` | Public/Private | Portfolio work | Store path or public URL |

**CRITICAL**: Store paths in DB, NOT signed URLs. Generate signed URLs at render time.

## Database Tables Reference

| Table | Purpose | Key Fields |
|-------|---------|------------|
| `profiles` | User identity | `id`, `full_name`, `avatar_url`, `role` |
| `tasks` | Job posts | `id`, `user_id`, `title`, `status`, `task_type` |
| `task_requests` | Bids/offers | `id`, `task_id`, `bidder_id`, `price`, `days` |
| `conversations` | Chat threads | `id`, `user1_id`, `user2_id`, `task_id` |
| `messages` | Chat messages | `id`, `conversation_id`, `sender_id`, `content` |
| `bookings` | Reservations | `id`, `task_id`, `provider_id`, `client_id`, `slot_id` |
| `availability_slots` | Provider slots | `id`, `provider_id`, `starts_at`, `ends_at` |
| `favorites` | Saved freelancers | `id`, `client_id`, `freelancer_id` |
| `saved_tasks` | Bookmarked tasks | `id`, `user_id`, `task_id` |
| `portfolio_items` | Portfolio work | `id`, `owner_id`, `title`, `image_url` |

**Reference**: See `Sline_everything/SUPABASE_SETUP.md` for complete schema.

## Building and Running

### Prerequisites
- Flutter SDK 3.8.1+
- Dart SDK 3.8.1+
- Supabase account

### Setup
```bash
# Install dependencies
flutter pub get

# Configure Supabase (update lib/core/services/supabase_config.dart)
# Run SQL from Sline_everything/SUPABASE_SETUP.md

# Run app
flutter run

# Run on specific device
flutter run -d <device_id>

# Code analysis
flutter analyze

# Format code
flutter format .
```

**Reference**: See `GEMINI.md` for complete instructions.

## Anti-Patterns to Avoid

1. ❌ Direct Supabase calls in UI widgets
2. ❌ Hardcoded colors (`Color(0xFF...)`)
3. ❌ N+1 queries (use JOINs instead)
4. ❌ `print()` statements (use `AppLogger`)
5. ❌ Offset pagination (use cursors)
6. ❌ Storing signed URLs in database (store paths)
7. ❌ Business logic in View layer
8. ❌ No error mapping (always map to user-friendly messages)

## File Location Guide

### Where to Find Things

- **Theme**: `lib/core/theme/`
- **Services**: `lib/core/services/` (global), `lib/features/*/services/` (feature-specific)
- **ViewModels**: `lib/features/*/viewmodels/`
- **Models**: `lib/features/*/models/`
- **Views**: `lib/features/*/view/`
- **Widgets**: `lib/core/widgets/` (shared), `lib/features/*/view/widgets/` (feature-specific)
- **Utils**: `lib/core/utils/`
- **Providers**: `lib/core/providers/`
- **Routes**: Defined in `lib/main.dart` and `lib/app/main_navigation_screen.dart`

## Version History

See `Sline_everything/Sline_Log.md` for complete version history and changelog.

Current version: **2.0** (as of 2025-12-08)
- Task visuals (is_hot, bg_color, offers)
- TaskCard redesign with Glassmorphism
- Theme system improvements

## Getting Help

1. Check `Sline_everything/DEVELOPER_GUIDE.md` for feature-specific docs
2. Check `Sline_everything/SUPABASE_SETUP.md` for database questions
3. Check `.cursor/rules/` for coding patterns
4. Invoke appropriate agent: `@Architect`, `@Pixel`, `@Supabase_Ops`, etc.

