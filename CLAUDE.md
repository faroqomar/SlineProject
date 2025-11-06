# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**SLine** is a cross-platform freelance marketplace Flutter application connecting clients with service providers. It uses Supabase as the backend (auth, database, storage, realtime) and follows strict MVVM architecture with feature-based organization.

- **Framework**: Flutter 3.8.1+ (Dart SDK 3.8.1+)
- **Backend**: Supabase (PostgreSQL, Auth, Storage, Realtime)
- **State Management**: Provider with ChangeNotifier pattern
- **Platforms**: iOS, Android, Web, Linux, macOS, Windows
- **UI**: Material Design 3

## Essential Commands

### Development Workflow
```bash
# Install/update dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Run on specific platform
flutter run -d <device_id>              # List devices: flutter devices
flutter run -d chrome                    # Web
flutter run -d android                   # Android
flutter run -d ios                       # iOS simulator

# Code quality
flutter analyze                          # Static analysis
flutter format .                         # Format code

# Testing
flutter test                             # Run all tests
flutter test test/path/to/test.dart      # Run single test

# Build for production
flutter build apk                        # Android APK
flutter build ios                        # iOS (requires Xcode)
flutter build web                        # Web deployment
```

### Project-Specific Commands
```bash
# View available devices
flutter devices

# Clean build artifacts
flutter clean && flutter pub get

# Check Flutter/Dart versions
flutter --version

# Upgrade dependencies
flutter pub upgrade                      # Respect version constraints
flutter pub upgrade --major-versions     # Allow major version upgrades
```

## Architecture: MVVM Pattern (Feature-Based)

Every feature follows a strict MVVM structure under `lib/features/<feature>/`:

```
features/<feature>/
├── view/                    # UI Layer - Screens & Widgets
│   ├── <feature>_screen.dart
│   └── widgets/             # Feature-specific widgets
├── viewmodels/              # Business Logic - ChangeNotifier
│   └── <feature>_view_model.dart
├── models/                  # Data Models
│   └── <feature>_model.dart
├── data/                    # Repository Layer (optional)
│   └── <feature>_repository.dart
└── services/                # Backend Integration (optional)
    └── <feature>_service.dart
```

### Layer Responsibilities

**View** (`view/`):
- Stateless/Stateful widgets for UI rendering
- Local form state management only
- Uses `Consumer<ViewModel>` or `Provider.of<ViewModel>()` for state observation
- **NEVER** makes direct backend/Supabase calls
- Always check `mounted` after async operations in StatefulWidgets

**ViewModel** (`viewmodels/`):
- Extends `ChangeNotifier` for state management
- Manages UI state (loading, error, data)
- Orchestrates calls to repository/service layers
- Exposes methods for UI actions
- Calls `notifyListeners()` after state changes
- Business logic and validation

**Repository/Service** (`data/`, `services/`):
- Encapsulates Supabase queries and mutations
- Handles error mapping (RLS errors, unique constraints, etc.)
- Storage operations (upload, signed URL generation)
- Data transformation (JSON ↔ Model)
- **Always** query with valid session (`auth.uid()`)

**Model** (`models/`):
- Immutable data classes mirroring database schema
- JSON serialization (`fromJson`, `toJson`)
- UTC timestamps (convert to local in UI layer)

### Example Pattern
```dart
// Model
class Task {
  final String id;
  final String title;
  final DateTime createdAt;

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

// ViewModel with Lifecycle
class TaskViewModel extends ChangeNotifier {
  final TaskRepository _repository;
  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  TaskViewModel(this._repository);

  // DON'T load data in constructor (anti-pattern)
  // DO load data when screen mounts
  Future<void> init() async {
    await fetchTasks();
  }

  Future<void> fetchTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tasks = await _repository.getTasks();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    // Cancel any subscriptions here
    super.dispose();
  }
}

// View with mounted checks
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskViewModel>().init();
    });
  }

  Future<void> _submitTask() async {
    final result = await context.read<TaskViewModel>().createTask();
    if (!mounted) return;  // ALWAYS check after await
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Task created!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const CircularProgressIndicator();
        }
        if (viewModel.error != null) {
          return Text('Error: ${viewModel.error}');
        }
        return ListView(
          children: viewModel.tasks.map((task) => TaskCard(task)).toList(),
        );
      },
    );
  }
}
```

## Critical Files Reference

Know these files well:

| File | Purpose | When to Touch |
|------|---------|---------------|
| `lib/main.dart` | App entry, provider registration, routes | Adding new ViewModel or route |
| `lib/core/services/supabase_config.dart` | Supabase initialization | Never (unless credentials change) |
| `lib/core/services/logger_service.dart` | Centralized logging | Never (use AppLogger methods) |
| `lib/app/main_navigation_screen.dart` | Bottom nav + IndexedStack | Adding/removing main tabs |
| `lib/core/widgets/signed_avatar.dart` | Avatar rendering with signed URLs | When changing avatar logic |
| `lib/core/widgets/signed_image.dart` | Image rendering with signed URLs | When changing image display |
| `Sline_everything/SUPABASE_SETUP.md` | Database schema, RLS, triggers | Any DB change |

## Core Directory Structure

```
lib/
├── app/                              # Application-level configuration
│   └── main_navigation_screen.dart   # Bottom nav + routing
├── core/                             # Shared resources
│   ├── models/                       # Global models (user_profile)
│   ├── services/                     # Cross-cutting services
│   │   ├── supabase_config.dart      # Supabase initialization
│   │   └── logger_service.dart       # AppLogger (debug-only)
│   ├── providers/                    # App-wide state providers
│   ├── widgets/                      # Shared UI components
│   │   ├── signed_avatar.dart        # Avatar with signed URLs
│   │   └── signed_image.dart         # Image with signed URLs
│   ├── theme/                        # App theming
│   └── utils/                        # Helper functions
├── features/                         # Feature modules (MVVM)
│   ├── auth/                         # Authentication
│   ├── home/                         # Home feed/dashboard
│   ├── tasks/                        # Task management
│   ├── chat/                         # Real-time messaging
│   ├── profile/                      # User profiles
│   ├── portfolio/                    # Freelancer portfolio
│   ├── booking/                      # Booking & availability
│   ├── favorites/                    # Saved freelancers
│   ├── saved/                        # Saved tasks
│   └── categories/                   # Service categories
├── shared/                           # Shared constants
└── main.dart                         # App entry point
```

## Database Architecture (Supabase)

### Key Tables
- **profiles**: User identity (linked to `auth.users`)
- **tasks**: Job postings (tender/booking types)
- **task_requests**: Offers/bids on tender tasks
- **conversations**: Chat threads (1:1, optional task-linked)
- **messages**: Chat messages with attachments
- **availability_slots**: Provider availability
- **bookings**: Scheduled appointments
- **favorites**: Client's saved freelancers
- **categories**: Service categories (DB-first)
- **portfolio_items**: Freelancer work gallery

### Storage Buckets
- **avatars** (Private): Profile pictures - use signed URLs
- **task-images** (Private): Task attachments - use signed URLs
- **chat-attachments** (Private): Message files - use signed URLs
- **portfolio** (Public/Private): Portfolio images

### Row-Level Security (RLS)
- **ALL tables have RLS enabled** - queries fail without valid session
- Always query using authenticated session (`auth.uid()`)
- Session-based access control enforced at database level
- Private storage requires signed URLs (1-hour TTL by default)

### Common Error Patterns
- **42501** (RLS): Session expired or unauthorized → prompt re-authentication
- **23505** (Unique): Duplicate entry → show user-friendly message
- **23503** (FK): Related item doesn't exist → handle gracefully
- **AuthException**: Map to user-friendly auth errors

## Important Development Conventions

### Code Standards
1. **English only** for all code, comments, and documentation
2. **Never use `print()`** - use `AppLogger` from `lib/core/services/logger_service.dart`
   ```dart
   AppLogger.d('Debug message');          // Verbose logs (debug mode only)
   AppLogger.i('Info message');           // Standard logs
   AppLogger.w('Warning message');        // Warnings
   AppLogger.e('Error', error, stack);    // Errors with optional exception

   // Set log level in main.dart
   AppLogger.currentLevel = LogLevel.info;  // info = clean, debug = verbose
   ```
3. **Always check `mounted`** after async operations in StatefulWidgets
4. **Store paths, not URLs** - Store storage file paths in DB, generate signed URLs at render time
5. **UTC timestamps** - Store as UTC in DB, convert to local for display
6. **Time-based pagination** - Use ISO timestamp cursors, not offset-based pagination

### Supabase Integration
1. **Configuration**: `lib/core/services/supabase_config.dart` (initialized once at startup)
2. **Session management**: Always ensure valid session before queries
3. **Storage**: For private buckets, use `SignedAvatar` and `SignedImage` widgets from `lib/core/widgets/`
4. **Realtime**: WebSocket subscriptions for chat - see `lib/features/chat/`
5. **RPC**: Use Supabase RPC v1 for complex operations

### State Management

**Provider Registration** (main.dart):
All feature ViewModels are registered globally in `main.dart`:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ProfileViewModel()),
    ChangeNotifierProvider(create: (_) => NavigationProvider()),
    ChangeNotifierProvider(create: (_) => HomeViewModel()),
    ChangeNotifierProvider(create: (_) => TaskFilterViewModel()),
    ChangeNotifierProvider(create: (_) => TaskViewModel()),
    ChangeNotifierProvider(create: (_) => ChatViewModel()),
    ChangeNotifierProvider(create: (_) => BookingViewModel()),
  ],
  child: MaterialApp(...)
)
```

**When to add a new provider**:
- Creating a new feature with shared state across screens
- Need cross-widget state access without prop drilling
- Business logic that outlives a single widget's lifecycle

**DO NOT**:
- Create duplicate providers for the same ViewModel
- Use local `ChangeNotifierProvider` when global one exists

**Pattern Selection** — When to Use Each Provider Pattern:

**Consumer<T>** (Recommended):
```dart
Consumer<TaskViewModel>(
  builder: (context, viewModel, child) {
    return ListView(children: viewModel.tasks.map(...).toList());
  },
)
```
- Use when: You need to rebuild specific subtree on state change
- Benefit: Scoped rebuilds, better performance
- Best for: Lists, dynamic UI sections

**Provider.of<T>(context)** (Legacy pattern):
```dart
final viewModel = Provider.of<TaskViewModel>(context, listen: false);
```
- Use when: You need access in `initState()` or outside build method
- Use `listen: false` if you don't want rebuilds

**context.watch<T>()** (Modern alternative):
```dart
final viewModel = context.watch<TaskViewModel>();
```
- Use when: Simple value reading in build method
- More concise than Provider.of with listen: true

**Rule of Thumb**: Prefer `Consumer` for performance-critical lists. Use `context.watch` for simple cases.

**ViewModel Lifecycle**:
1. Feature ViewModels extend `ChangeNotifier`
2. Call `notifyListeners()` after every state change in ViewModel
3. Always cancel streams/subscriptions in `dispose()`

### Testing
- Unit tests for services and ViewModels
- Widget tests for UI interactions
- Integration tests against staging Supabase instance
- Follow patterns in `test/` directory

## Documentation Reference

The `Sline_everything/` directory contains comprehensive documentation:

- **DEVELOPER_GUIDE.md**: System map, architecture, data model, RLS policies, feature map, how to add new features
- **STRUCTURE.md**: Folder structure and conventions
- **SUPABASE_SETUP.md**: Database schema, RLS policies, triggers, storage setup
- **MVP_ROADMAP.md**: Development roadmap and feature status
- **Sline_Log.md**: Complete version history and changelog
- **DEVELOPER_GUIDE/**: Feature-specific deep dives (Auth, Tasks, Chat, Booking, Profile, etc.)

For detailed information on any feature, always refer to these documentation files first.

## Navigation Patterns

### Named Routes (defined in main.dart)
```dart
// Simple navigation
Navigator.pushNamed(context, '/tasks');

// With arguments
Navigator.pushNamed(
  context,
  '/availability',
  arguments: {
    'providerId': providerId,
    'taskId': taskId,
  },
);

// Reading arguments in target screen
final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
final taskId = args['taskId'] as String;
```

### Direct Navigation (for screens not in routes)
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => TaskDetailsScreen(taskId: id)),
);
```

### Bottom Navigation (main_navigation_screen.dart)
- Uses `IndexedStack` to preserve state across tabs
- `NavigationProvider` manages current tab index
- Tabs: Home, Chat, Tasks, Profile

## Adding a New Feature

1. **Database**: Add tables/columns in Supabase (follow `SUPABASE_SETUP.md`)
2. **Apply RLS**: Create appropriate RLS policies for the new tables
3. **Create feature directory**: `lib/features/<feature_name>/`
4. **Follow MVVM structure**: Create `view/`, `viewmodels/`, `models/`, `services/` subdirectories
5. **Model layer**: Create models with `fromJson`/`toJson`
6. **Service layer**: Encapsulate Supabase queries
7. **ViewModel layer**: Business logic with ChangeNotifier
8. **View layer**: UI screens and widgets
9. **Wire up providers**: Add to `MultiProvider` in `main.dart`
10. **Navigation**: Add routes in `main_navigation_screen.dart` if needed
11. **Document**: Update `Sline_Log.md` and add feature guide in `DEVELOPER_GUIDE/`

## Recent Major Changes

- **MVVM Restructure**: Complete re-architecture to strict MVVM pattern (Oct 2024)
- **Private Storage**: Migrated avatars and task-images to private buckets with signed URLs
- **Unified ProfileController**: Consolidated profile management
- **Documentation Refresh**: Added comprehensive guides for all core modules

## Troubleshooting

### Common Issues
1. **RLS errors (42501)**: Ensure user is authenticated and session is valid
2. **Storage 404**: Generate fresh signed URLs (they expire after 1 hour)
3. **Hot reload issues**: Try `flutter clean` and restart
4. **Build failures**: Run `flutter pub get` after pulling changes
5. **Platform-specific issues**: Check platform-specific folders (`ios/`, `android/`, etc.)

### Supabase Connection Issues
- Verify `supabase_config.dart` has correct URL and anon key
- Check network connectivity
- Ensure Supabase project is not paused (free tier auto-pauses after inactivity)

### Debugging Workflows

**State Issues**:
1. Check if ViewModel is registered in main.dart providers
2. Verify `notifyListeners()` is called after state changes
3. Use `Consumer` widget to ensure rebuilds happen
4. Check logs with `AppLogger.currentLevel = LogLevel.debug`

**RLS Permission Errors (42501)**:
1. Verify user is logged in: `Supabase.instance.client.auth.currentUser`
2. Check if session is expired
3. Review RLS policy for the table in Supabase Dashboard
4. Ensure query includes correct user_id filter

**Realtime Not Working**:
1. Verify `primaryKey` parameter is set correctly
2. Check RLS allows SELECT on table
3. Confirm subscription is not cancelled prematurely
4. Check Supabase Dashboard > Realtime for enabled tables

**Signed URL 404s**:
1. Signed URLs expire after 1 hour (default TTL)
2. Path might be stored incorrectly (should not include bucket name)
3. Check RLS allows SELECT on storage.objects for bucket
4. Regenerate URL: SignedAvatar/SignedImage handle this automatically

## Feature-Specific Patterns

### Auth Feature (`lib/features/auth/`)
- **Registration flow**: Sign up with Supabase Auth → create matching `profiles` row → navigate to main app
- **Session requirement**: Always verify `currentUser` exists before inserting into `profiles` (RLS will reject anonymous inserts)
- **Error mapping**: Map `Invalid login credentials` → "Email or password is incorrect"
- **Profile seeding**: Must happen immediately after successful signup while session is fresh

### Tasks Feature (`lib/features/tasks/`)
- **Task types**: `tender` (offers/bids) or `booking` (appointments)
- **Offers**: Only allowed on `tender` tasks (enforced by trigger `trg_task_requests_only_for_tender`)
- **Unique constraint**: One pending offer per (task, bidder) via partial unique index
- **Assignment**: Accepting an offer sets `tasks.assigned_freelancer_id` and updates status to `assigned` (automated by trigger)
- **Image storage**: Store paths in `image_paths` array, generate signed URLs for display

### Chat Feature (`lib/features/chat/`)
- **Conversation types**: Task-linked (job discussion) or DM (direct message to favorite)
- **DM requirement**: Client can only start DM with a freelancer in their `favorites` (enforced by trigger)
- **Task chat requirement**: Only task owner can initiate task-linked conversations
- **Message types**: `text`, `offer`, `offer_update`, `offer_accepted`, `offer_rejected`, `delivery_submitted`, etc.
- **Offer messages**: Must include `price` and `days` in `payload` jsonb field (validated by trigger)
- **Realtime**: Subscribe to `messages` and `conversations` streams for live updates
- **Attachments**: Private bucket with signed URLs; store path, generate URL on demand
- **Unique conversations**: One conversation per (user pair, task) via composite unique constraint

### Booking Feature (`lib/features/booking/`)
- **Timezone handling**: CRITICAL - Always convert local → UTC before insert, UTC → local for display
- **Slot constraints**: No overlapping open slots for same provider (enforced by trigger)
- **Active booking**: Max one active booking (pending/confirmed) per slot via partial unique index
- **Status transitions**: Guarded by `fn_booking_guard` trigger:
  - `pending` → `confirmed` (provider) or `canceled` (client/provider)
  - `confirmed` → `completed` (provider) or `canceled` (client/provider)
- **RLS roles**: Provider creates/manages slots; Client books slots; Each sees only their bookings

### Profile Feature (`lib/features/profile/`)
- **Avatar storage**: Upload to private `avatars` bucket → store path in `profiles.avatar_url` → generate signed URLs for display
- **Role switching**: Changing `role` between `client`/`freelancer` affects Home/Tasks UX
- **Email updates**: Use `supabase.auth.updateUser()` for auth email, optionally sync to `profiles.email`
- **Session scope**: All profile updates require `auth.uid() = profiles.id` (RLS enforced)

### Favorites Feature (`lib/features/favorites/`)
- **Purpose**: Enables DM creation - clients can only start non-task chats with favorited freelancers
- **Unique constraint**: One favorite per (client, freelancer) pair
- **Privacy**: Each client sees only their own favorites (RLS enforced)
- **Integration**: Referenced by conversation creation trigger to gate DM access

### Portfolio Feature (`lib/features/portfolio/`)
- **Storage**: Currently uses public `portfolio` bucket with public URLs
- **Ownership**: Only owner can add/edit/delete items (RLS enforced)
- **Public visibility**: All users can view all portfolio items (SELECT policy allows all authenticated)
- **Image management**: Upload to storage → get public URL → store in `image_url` field

### Saved Feature (`lib/features/saved/`)
- **Privacy**: Users can only see/manage their own saved tasks
- **Unique constraint**: One save per (user, task) pair
- **Duplicate handling**: 23505 error on duplicate save → treat as success (already saved)
- **Optimistic UX**: Toggle icon immediately, sync in background

### Categories Feature (`lib/features/categories/`)
- **Read-only**: Regular users can only SELECT, admins manage via service role
- **Case-insensitive**: Unique constraint on `lower(name)` prevents duplicates
- **Caching**: Service maintains in-memory cache for performance
- **Search**: Client-side filtering when needed

### Home Feature (`lib/features/home/`)
- **Data source**: Aggregates open tasks from Tasks feature
- **Filter integration**: Uses `TaskFilterViewModel` for search and category filtering
- **Performance**: Batch-fetches with joins for author profiles and category names
- **Refresh**: Pull-to-refresh reloads tasks and syncs saved-state icons

## Database Guards and Triggers

### Business Logic Enforcement
1. **Offer guard** (`trg_task_requests_only_for_tender`): Rejects offers on booking-type tasks
2. **Offer payload validation**: Requires positive `price` and `days` in offer messages
3. **Booking status guard** (`fn_booking_guard`): Enforces valid status transitions with role checks
4. **Slot overlap prevention** (`trg_no_overlap_slots`): Prevents provider from creating overlapping open slots
5. **Conversation guard** (`trg_conversations_guard`): Enforces DM requires favorite; task chat requires task owner
6. **Auto-assignment** (`trg_messages_offer_accepted`): On `offer_accepted` message, updates task's `assigned_freelancer_id` and status

### Key Constraints
- **Unique conversations**: `(least(user1_id, user2_id), greatest(user1_id, user2_id), coalesce(task_id, NIL_UUID))`
- **Active booking per slot**: `UNIQUE INDEX ON bookings(slot_id) WHERE status IN ('pending', 'confirmed')`
- **Pending offer per bidder**: `UNIQUE INDEX ON task_requests(task_id, bidder_id) WHERE status = 'pending'`
- **Unique favorites**: `(client_id, freelancer_id)`
- **Case-insensitive category names**: `UNIQUE INDEX ON categories(LOWER(name))`

## RLS Policy Patterns

### Owner-Only Policies
```sql
-- Common pattern for user-owned resources
USING (auth.uid() = user_id)
CHECK (auth.uid() = user_id)
```
**Tables**: `profiles`, `tasks`, `availability_slots`, `portfolio_items`, `saved_tasks`, `favorites`

### Participant-Based Policies
```sql
-- Conversations & messages: only participants can access
USING (auth.uid() = user1_id OR auth.uid() = user2_id)
```
**Tables**: `conversations`, `messages`

### Role-Based Policies
```sql
-- Bookings: provider OR client can view
USING (auth.uid() = provider_id OR auth.uid() = client_id)

-- Task requests: task owner OR bidder can view
USING (
  task_id IN (SELECT id FROM tasks WHERE user_id = auth.uid())
  OR bidder_id = auth.uid()
)
```

### Public Read Policies
```sql
-- Categories and portfolio: authenticated users can read
USING (true)  -- for SELECT only
```

## Realtime Subscriptions

### Chat Feature
```dart
// Subscribe to new messages in a conversation
final messagesStream = supabase
    .from('messages')
    .stream(primaryKey: ['id'])
    .eq('conversation_id', conversationId)
    .order('created_at');

// Subscribe to conversation list updates
final conversationsStream = supabase
    .from('conversations')
    .stream(primaryKey: ['id'])
    .order('created_at', ascending: false);
```

**Important**:
- Realtime subscriptions respect RLS policies
- Use `primaryKey` parameter for proper stream updates
- Clean up subscriptions in `dispose()` to prevent memory leaks
- Handle stream errors gracefully with error builders

## Comprehensive Error Handling

### PostgreSQL Error Codes
| Code | Meaning | User-Friendly Message | Action |
|------|---------|----------------------|---------|
| `42501` | RLS permission denied | "Session expired. Please sign in again." | Re-authenticate |
| `23505` | Unique violation | "This item already exists." / "Already saved." | Treat as success or show conflict |
| `23503` | Foreign key violation | "Related item does not exist." | Validate references before insert |
| `22P02` | Invalid UUID syntax | "Invalid identifier provided." | Validate UUIDs client-side |
| `PGRST116` | Multiple rows returned | "Data integrity issue detected." | Use `.single()` or `.maybeSingle()` |

### Auth Error Handling
```dart
try {
  await supabase.auth.signInWithPassword(email: email, password: password);
} on AuthException catch (e) {
  if (e.message.contains('Invalid login credentials')) {
    throw const FormatException('Email or password is incorrect.');
  }
  if (e.message.contains('Email not confirmed')) {
    throw const FormatException('Please verify your email first.');
  }
  rethrow;
}
```

### Storage Error Handling
```dart
try {
  final path = await uploadAvatar(bytes);
  final signedUrl = await storage.createSignedUrl(path, 3600);
} on StorageException catch (e) {
  if (e.statusCode == '404') {
    throw const FormatException('File not found.');
  }
  throw const FormatException('Upload failed. Please try again.');
}
```

## Testing Checklists

### Per-Feature Testing
Each feature should verify:
1. **Happy path**: Primary user flow works end-to-end
2. **RLS enforcement**: Non-owners/participants cannot access restricted data
3. **Unique constraints**: Duplicate prevention works with friendly errors
4. **Error states**: Network failures, invalid input handled gracefully
5. **UI state**: Loading/error/empty states render correctly
6. **Optimistic updates**: UI updates immediately, syncs in background
7. **Timestamps**: All dates display in local timezone
8. **Pagination**: Load more works without duplicates

### Auth Testing
- Signup → profile created → navigation to main app
- Duplicate signup → friendly error
- Login failure → buttons re-enable, error shown
- Logout → session cleared, return to login

### Chat Testing
- Create DM → requires favorite
- Send text/image → appears in both participants' views
- Realtime → messages appear without refresh
- Offer message → requires price/days in payload

### Booking Testing
- Create slot → no overlap with existing
- Book slot → max one active booking
- Status transitions → only valid moves allowed
- Timezone display → always shows local time

### Tasks Testing
- Create tender → offer flow enabled
- Create booking → offer flow disabled
- Submit offer → unique pending per bidder
- Accept offer → task assigned automatically

## Utility Functions

### Date/Time Formatting
```dart
// Located in lib/core/utils/format_date.dart
String formatUtcToLocal(DateTime utc) {
  final local = utc.toLocal();
  return DateFormat('MMM d, y - h:mm a').format(local);
}
```

### Price Formatting
```dart
// Located in lib/core/utils/format_price.dart
String formatPrice(int cents) {
  return '\$${(cents / 100).toStringAsFixed(2)}';
}
```

### Signed URLs
```dart
// For private storage buckets (avatars, task-images, chat-attachments)
final signedUrl = await supabase.storage
    .from('avatars')
    .createSignedUrl(path, 3600); // 1 hour TTL

// Use SignedAvatar or SignedImage widgets from lib/core/widgets/
SignedAvatar(
  path: user.avatarUrl,
  radius: 40,
  placeholder: Icon(Icons.person),
)
```

## Key Dependencies

- `supabase_flutter: ^1.10.5` - Supabase client
- `provider: ^6.0.5` - State management
- `image_picker: ^1.0.7` - Image selection
- `file_picker: ^8.0.3` - File selection
- `flutter_image_compress: ^2.3.0` - Image compression
- `logger: ^2.0.2` - Logging
- `sign_in_with_apple: ^5.0.0` - Apple authentication
- `mime: ^1.0.6` - MIME type detection

## Critical Performance Issues & Fixes

### N+1 Query Anti-Pattern (CRITICAL - Fix Immediately)
**Location**: `lib/features/tasks/services/task_service.dart`
**Impact**: 10-50x performance degradation

**Problem**:
```dart
// ❌ CURRENT: 51 queries for 50 tasks
for (var task in tasks) {
  final profile = await getProfile(task.userId);
}
```

**Solution**:
```dart
// ✅ FIXED: 1 query with JOIN
Future<List<Task>> getTasks() async {
  final response = await _client
      .from('tasks')
      .select('''
        *,
        profiles!tasks_user_id_fkey(full_name, avatar_url),
        categories(name)
      ''')
      .order('created_at', ascending: false);

  return (response as List).map((json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return Task.fromJson({
      ...json,
      if (profile != null) ...{
        'user_name': profile['full_name'],
        'user_avatar': profile['avatar_url'],
      },
    });
  }).toList();
}
```

**Affected Methods** (all need fixing):
- `getTasks()`
- `getTasksByUser(String userId)`
- `getTasksByStatus(TaskStatus status)`
- `getOpenTasksForHome()`

### Code Duplication (HIGH Priority)
**Issue**: Complete duplication between `auth_service.dart` and `auth_repository.dart`
**Action**: Delete `auth_service.dart` entirely, use only `AuthRepository`

### Architecture Violations
**DO NOT**:
- ❌ Call services directly from UI widgets - always go through ViewModels
- ❌ Create repository instances directly in UI - inject via Provider
- ❌ Create duplicate ViewModel providers - reuse global instances from main.dart

## Performance Optimization Strategies

### 1. Implement Caching
```dart
class CacheManager {
  final Map<String, (dynamic, DateTime)> _cache = {};

  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (DateTime.now().isAfter(entry.$2)) {
      _cache.remove(key);
      return null;
    }
    return entry.$1 as T;
  }

  void set<T>(String key, T value, {Duration duration = const Duration(minutes: 5)}) {
    _cache[key] = (value, DateTime.now().add(duration));
  }
}
```

### 2. Pagination for Large Lists
```dart
class TaskRepository {
  String? _lastCursor;

  Future<List<Task>> getTasks({bool loadMore = false}) async {
    final query = _client.from('tasks').select().order('created_at', ascending: false);

    if (loadMore && _lastCursor != null) {
      query.lt('created_at', _lastCursor);
    }

    query.limit(20);

    final results = await query;
    if (results.isNotEmpty) {
      _lastCursor = results.last['created_at'];
    }

    return results.map((e) => Task.fromJson(e)).toList();
  }
}
```

### 3. Lifecycle-Aware Realtime Subscriptions
```dart
class ChatViewModel extends ChangeNotifier with WidgetsBindingObserver {
  StreamSubscription? _msgSub;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _msgSub?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      _subscribeToMessages();
    }
  }
}
```

### 4. Image Optimization with Transformations
```dart
// Use Supabase image transformations for thumbnails
final url = supabase.storage.from('avatars').getPublicUrl(
  path,
  transform: TransformOptions(
    width: 200,
    height: 200,
    resize: ResizeMode.cover,
  ),
);
```

## Scalability Metrics

### Current Capacity (Before Optimization)
- Concurrent Users: ~1,000
- Database Queries/sec: ~50 (bottleneck: N+1 queries)
- Realtime Connections: ~500 (Supabase free tier limit)

### After Optimization
- Concurrent Users: ~10,000
- Database Queries/sec: ~500+
- Realtime Connections: Limited by tier

### Key Bottlenecks
1. **N+1 queries** in TaskService (CRITICAL)
2. **No caching** - every request hits Supabase
3. **No pagination** on some list screens
4. **Always-active subscriptions** - drain battery when backgrounded
5. **No image optimization** - full-size images for thumbnails

## Common Pitfalls to Avoid

1. ❌ **N+1 Queries** - Always use JOINs or batch fetching
2. ❌ **Code Duplication** - Don't duplicate logic between layers
3. ❌ **UI Calling Services** - Always route through ViewModels
4. ❌ **Storing Signed URLs** - Store paths, generate URLs on demand
5. ❌ **Forgetting UTC Conversion** - Always convert UTC to local for display
6. ❌ **Missing `mounted` Checks** - Always check after async operations in StatefulWidgets
7. ❌ **Forgot to Dispose Streams** - Always cancel subscriptions in dispose()
8. ❌ **Using `print()`** - Always use AppLogger instead

## Code Quality Metrics

### Current State
| Metric | Score | Target |
|--------|-------|--------|
| Architecture Compliance | 8/10 | 9.5/10 |
| Performance | 6/10 | 9/10 |
| Code Duplication | 6/10 | 9/10 |
| Error Handling | 7/10 | 8.5/10 |
| Testing Coverage | 3/10 | 7/10 |
| Documentation | 9/10 | 9/10 |
| **Overall** | **7.5/10** | **9/10** |

## Priority Roadmap

### Sprint 1 (Week 1) - CRITICAL FIXES
- [ ] Fix N+1 query in TaskService (4 methods) - 2-3 hours
- [ ] Remove AuthService/AuthRepository duplication - 1-2 hours
- [ ] Add global error boundary - 30 minutes

**Expected Impact**: 10-50x performance improvement

### Sprint 2 (Week 2) - HIGH PRIORITY
- [ ] Fix direct service calls in task_card.dart - 30 minutes
- [ ] Remove duplicate AuthViewModel provider - 15 minutes
- [ ] Standardize to AppLogger everywhere - 1 hour
- [ ] Create CategoriesViewModel - 1-2 hours

### Quick Wins (Weeks 3-4)
- [ ] Pull-to-refresh everywhere - 1 day
- [ ] Enhanced empty states - 2 days
- [ ] Shimmer skeleton loaders - 2 days
- [ ] Optimistic UI updates - 1 day per feature

### Short-Term Features (1-3 months)
- [ ] Push notifications - 1-2 weeks
- [ ] User ratings & reviews - 1 week
- [ ] Advanced task filters - 1 week
- [ ] Search history - 2 days
- [ ] In-app media viewer - 2 days

### Strategic Features (3-6 months)
- [ ] Payment integration (Stripe) - 3-4 weeks
- [ ] Video calls (Agora/Twilio) - 2-3 weeks
- [ ] Location-based search - 1 week
- [ ] Analytics dashboard - 1-2 weeks

## Future Architecture Recommendations

### 1. State Management Migration (6-12 months)
Consider migrating from Provider to Riverpod for:
- Compile-time safety
- Better DevTools
- Immutable state
- Easier testing

### 2. Offline-First Architecture (3-6 months)
Implement multi-level caching:
- Level 1: In-memory (instant)
- Level 2: SQLite/Hive (fast)
- Level 3: Supabase (network)

### 3. Event Sourcing for Critical Flows
For task status changes, booking lifecycle:
- Audit trail
- Ability to replay events
- Better debugging

### 4. Analytics & Monitoring
Add Firebase Analytics, Crashlytics, and Performance monitoring for:
- User behavior tracking
- Crash reporting
- Performance metrics
- A/B testing capabilities

## Security Best Practices

### Already Implemented ✅
- Row-Level Security (RLS) at database level
- Private storage with signed URLs
- Proper session-based access control
- Secure password handling via Supabase Auth

### Needs Improvement ⚠️
1. **Secrets Management**: Move from hardcoded values to environment variables
2. **Input Validation**: Add server-side validation (database constraints)
3. **Rate Limiting**: Implement via Supabase Edge Functions
4. **Error Messages**: Don't expose internal errors to users

## Testing Strategy

### Unit Tests
- Services and repositories (data layer)
- ViewModels (business logic)
- Utility functions

### Widget Tests
- UI interactions
- ViewModel integration with widgets
- Form validation

### Integration Tests
- Complete user flows (signup → login → create task)
- Against staging Supabase instance
- Cross-feature interactions

## Monitoring & Analytics

### Key Metrics to Track
**Development**:
- Code coverage (target: >70%)
- Build time (optimize if >5 minutes)
- App size (target: <50MB)
- Crash-free rate (target: >99%)

**Product**:
- DAU/MAU ratio (target: >20%)
- Task completion rate (target: >60%)
- User retention (30-day, target: >40%)
- Average session length (target: >10 minutes)

**Business** (Post-Payment Integration):
- GMV (Gross Merchandise Value)
- Take rate (commission %)
- LTV (Lifetime Value per user)
- CAC (Customer Acquisition Cost)
