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

- **Theme System**: `lib/core/theme/` (AppColors, AppTheme, AppDimens, AppTypography, AppDecorations) and staged design layers such as `lib/core/theme/designs/amber_dusk/amber_dusk_tokens.dart`
- **Services**: `lib/core/services/` (SupabaseConfig, AppLogger)
- **Runtime Guards**: `lib/core/services/account_guard_service.dart` (moderation + force logout checks)
- **Runtime Config**: `lib/core/services/system_config_service.dart`, `lib/core/providers/system_config_view_model.dart`
- **Widgets**: `lib/core/widgets/` (AppCardContainer, AppCard, AppStyledButton, SignedAvatar, AppButton, etc.; no glass/blur surfaces)
- **Utils**: `lib/core/utils/` (format_date.dart, format_price.dart, transitions)
- **Main App**: `lib/main.dart` (Provider setup, MaterialApp configuration)

## Agent System

### Agent Invocation Patterns

Agents are defined in `.cursor/Agents/` and can be invoked using triggers:

| Agent | File | Trigger Keywords | Use Case |
|-------|------|-----------------|----------|
| **@Architect** | `Agents/Architect.md` | "@Architect", "fix logic", "refactor" | Logic, MVVM compliance, refactoring |
| **@Pixel** | `Agents/Pixel.md` | "@Pixel", "design this", "make it pretty" | UI/UX, solid-surface themes, staged design tokens |
| **@Supabase_Ops** | `Agents/Supabase_Ops.md` | "@Supabase", "add table", "secure db" | Database, RLS, SQL, storage |
| **@Sentinel** | `Agents/Sentinel.md` | "@Sentinel", "check this", "run tests" | QA, security, documentation sync |
| **@DocsKeeper** | `Agents/DocsKeeper.md` | "@DocsKeeper", "document this", "update changelog" | Documentation updates |
| **@Planner** | `Agents/Planner.md` | "@Planner", "plan this feature" | Implementation planning |
| **@CodeGuard** | `Agents/CodeGuard.md` | "@CodeGuard", "review code", "performance check" | Code reviews, performance, security |
| **@Executor** | `Agents/Executor.md` | "@Executor", "execute plan", "start phase" | Execute plans from `.TODO/` |
| **@PlanCritic** | `Agents/PlanCritic.md` | "@PlanCritic" | Audit plans, risk prediction |
| **@Observability** | `Agents/Observability.md` | "@Observability", "logging", "metrics" | Logging, monitoring, telemetry |
| **@APIContract** | `Agents/APIContract.md` | "@APIContract", "define contract" | Contracts, DTOs, API shapes |
| **@DataMigration** | `Agents/DataMigration.md` | "@DataMigration", "migration", "backfill" | Schema migration, compatibility |
| **@ThreatModeler** | `Agents/ThreatModeler.md` | "@ThreatModeler", "threat model" | Security design, abuse cases |

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

**Configuration**: See `SharedStorageConfig` in `lib/core/config/storage_config.dart`:
- `avatarTtlSeconds` = 7200s, `taskImageTtlSeconds` = 7200s, `chatAttachmentTtlSeconds` = 3600s
- `cacheDuration` = 90min, `errorCacheDuration` = 30sec, `maxCacheSize` = 1000

**RLS v2**: `is_admin()`, `can_access_chat_attachment()`, `can_access_task_image()` helpers. Feature flag: `app_config.storage_rls_v2_enabled`.

## Database Tables Reference

| Table | Purpose | Key Fields |
|-------|---------|------------|
| `profiles` | User identity | `id`, `full_name`, `avatar_url`, `role` |
| `tasks` | Job posts | `id`, `user_id`, `title`, `status`, `task_type` |
| `task_requests` | Bids/offers | `id`, `task_id`, `bidder_id`, `price`, `days`, `status`, `payment_status`, `payment_deadline` |
| `system_config` | Runtime settings | `key`, `value` (JSON) |
| `conversations` | Chat threads | `id`, `user1_id`, `user2_id`, `task_id` |
| `messages` | Chat messages | `id`, `conversation_id`, `sender_id`, `content` |
| `bookings` | Reservations | `id`, `task_id`, `provider_id`, `client_id`, `slot_id` |
| `system_config` | Runtime flags | `maintenance_mode`, `disable_signups`, `min_app_version`, `app_banner` keys |
| `reports` | User safety reports | `reporter_user_id`, `entity_type`, `entity_id`, `status` |
| `disputes` | Booking/task disputes | `task_id`, `complainant_id`, `defendant_id`, `status` |
| `availability_slots` | Provider slots | `id`, `provider_id`, `starts_at`, `ends_at` |
| `favorites` | Saved freelancers | `id`, `client_id`, `freelancer_id` |
| `saved_tasks` | Bookmarked tasks | `id`, `user_id`, `task_id` |
| `portfolio_items` | Portfolio work | `id`, `owner_id`, `title`, `image_url` |

**Reference**: See `Sline_everything/SUPABASE_SETUP.md` for complete schema.

## Task Request (Bid) Flow Overview (March 2026)

The Task Request (Bid) Flow manages the complete lifecycle of freelancer offers on tender-type tasks.

### Bid States

```
pending → accepted → payment_status:unpaid → payment_status:held (work begins)
    ↓         ↓
 rejected  withdrawn
```

### Two-Step Award Flow

1. **Award** (`accept_task_request`): Client selects offer, locks freelancer, sets 48h payment deadline
2. **Payment** (`pay_awarded_offer`): Client completes payment, funds held in escrow, work begins

### Key Files

| Layer | File | Purpose |
|-------|------|---------|
| Model | `lib/features/tasks/models/task_request_model.dart` | TaskRequest entity with OfferStatus/PaymentStatus |
| Service | `lib/features/tasks/services/task_requests_service.dart` | Supabase RPC calls, error mapping |
| ViewModel | `lib/features/tasks/viewmodels/task_requests_view_model.dart` | MVVM state holder, two-step award flow |
| Exceptions | `lib/features/tasks/exceptions/offer_exceptions.dart` | PriceMismatchException, OfferAlreadyAcceptedException |

### Security Features

- **Optimistic Concurrency**: Price validation prevents race conditions during award
- **Idempotency**: Double-clicking "Award" returns 'already_accepted' without duplicate actions
- **Auto-Expiry**: Cron job expires unpaid offers after 48-hour payment window
- **Rate Limiting**: 2-second debounce prevents bid spam

### RPC Functions

- `accept_task_request(task_id, request_id, expected_price_cents)` - Award offer
- `reject_task_request(task_id, request_id)` - Reject offer + create conversation
- `replace_task_request(task_id, freelancer_id, message, price, days)` - Update own offer
- `cleanup_expired_awards()` - Cron job for payment deadline enforcement

### Documentation

- API Contract: `.TODO/improvement_the_system/ImplementReady/04_task-request-bid-flow/API_CONTRACT.md`
- Threat Model: `.TODO/improvement_the_system/ImplementReady/04_task-request-bid-flow/THREAT_MODEL.md`
- Developer Guide: `Sline_everything/DEVELOPER_GUIDE.md#task-request-bid-flow`

---

## Dashboard Link Notes (March 2026)

- App enforces dashboard moderation and force-logout signals through startup/resume guard checks in `lib/main.dart`.
- Public config is consumed from Supabase via `get_public_system_config` and drives maintenance, min-version, signup block, and app banner.
- Safety surfaces are active from task/chat/public-profile/booking screens using `lib/features/safety/viewmodels/safety_view_model.dart`.

## Building and Running

### Prerequisites
- Flutter SDK 3.8.1+
- Dart SDK 3.8.1+
- Supabase account

### Setup
```bash
flutter pub get
# Configure Supabase (update lib/core/services/supabase_config.dart)
# Run SQL from Sline_everything/SUPABASE_SETUP.md
flutter run
flutter analyze
flutter format .
```

## Anti-Patterns to Avoid

1. ❌ Direct Supabase calls in UI widgets
2. ❌ Hardcoded colors (`Color(0xFF...)`)
3. ❌ N+1 queries (use JOINs instead)
4. ❌ `print()` statements (use `AppLogger`)
5. ❌ Offset pagination (use cursors)
6. ❌ Storing signed URLs in database (store paths)
7. ❌ Business logic in View layer
8. ❌ No error mapping (always map to user-friendly messages)

## Getting Help

1. Check `Sline_everything/DEVELOPER_GUIDE.md` for feature-specific docs
2. Check `Sline_everything/SUPABASE_SETUP.md` for database questions
3. Check `.cursor/rules/` for coding patterns
4. Invoke appropriate agent: `@Architect`, `@Pixel`, `@Supabase_Ops`, `@CodeGuard`, etc.
