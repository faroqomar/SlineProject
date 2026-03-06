# SLine Architecture Analysis & Optimization Guide

**Date**: October 31, 2024
**Version**: 1.9+
**Architecture Pattern**: MVVM with Provider

> Historical analysis note: this document captures architectural assessment snapshots over time. For the current live repository layout and active contracts, use `Sline_everything/STRUCTURE.md`, `Sline_everything/DEVELOPER_GUIDE.md`, and `Sline_everything/SUPABASE_SETUP.md`.

## Current Live Architecture Notes (2026-03-01)

- The bottom navigation still uses the legacy enum member `NavView.orders` in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/app_enums.dart`, but the live slot renders `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/dashboard/view/dashboard_screen.dart`.
- The standalone runtime under `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/` was removed; `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/README.md` is the only remaining file in that folder.
- The cleanup also removed the orphaned app-root `OrdersViewModel` provider from `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/main.dart`, which reduced stale state risk from an unreachable feature surface.
- Architectural rule reinforced by this change: when a navigation surface is consolidated, remove the orphaned provider/test/doc surface in the same patch instead of leaving a dead parallel feature tree.

---

## Table of Contents
1. [Current Architecture Overview](#current-architecture-overview)
2. [Architecture Decision Analysis](#architecture-decision-analysis)
3. [Scalability Assessment](#scalability-assessment)
4. [Performance Optimization Strategies](#performance-optimization-strategies)
5. [Security Architecture Review](#security-architecture-review)
6. [Future Architecture Recommendations](#future-architecture-recommendations)
7. [Migration Paths](#migration-paths)

---

## Current Architecture Overview

### High-Level System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter Application                     │
│                                                               │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐            │
│  │    View    │  │    View    │  │    View    │            │
│  │  (Widgets) │  │  (Widgets) │  │  (Widgets) │            │
│  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘            │
│        │                │                │                    │
│        ├────────────────┴────────────────┘                   │
│        │                                                      │
│  ┌─────▼──────────────────────────────────┐                 │
│  │         ViewModel (ChangeNotifier)      │                 │
│  │  - UI State Management                  │                 │
│  │  - Business Logic Orchestration         │                 │
│  │  - Error Mapping                        │                 │
│  └─────┬──────────────────────────────────┘                 │
│        │                                                      │
│  ┌─────▼──────────────────────────────────┐                 │
│  │         Repository (optional)           │                 │
│  │  - Data Access Abstraction              │                 │
│  │  - Caching Logic (future)               │                 │
│  └─────┬──────────────────────────────────┘                 │
│        │                                                      │
│  ┌─────▼──────────────────────────────────┐                 │
│  │              Service                    │                 │
│  │  - Supabase API Calls                   │                 │
│  │  - Business Logic                       │                 │
│  │  - Storage Operations                   │                 │
│  └─────┬──────────────────────────────────┘                 │
│        │                                                      │
└────────┼──────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│                    Supabase Backend                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │   Auth   │  │ Database │  │ Storage  │  │ Realtime │   │
│  │          │  │(Postgres)│  │ (S3-like)│  │(WebSock) │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
│                                                               │
│  - Row-Level Security (RLS)                                  │
│  - Database Triggers & Functions                             │
│  - Storage Policies                                          │
│  - Realtime Subscriptions                                    │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow Pattern

```
User Action → View → ViewModel → Repository → Service → Supabase
                ↓        ↓           ↓           ↓
            UI State  Loading    Optional    Error
            Update    State      Cache       Handling
```

---

## Architecture Decision Analysis

### Decision 1: MVVM Pattern
**Status**: ✅ Good Choice

**Pros**:
- Clear separation of concerns
- Testable business logic (ViewModels)
- UI independent of data layer
- Easy to reason about data flow

**Cons**:
- More boilerplate than simple setState
- Can be over-engineered for simple screens
- ViewModels can become "god objects"

**Assessment**: **Appropriate for this application's complexity**

**Improvements**:
- Consider splitting large ViewModels (e.g., TaskViewModel could be split into TaskListViewModel and TaskDetailsViewModel)
- Add clear naming conventions (e.g., `fetchTasks()` vs `loadTasks()`)

---

### Decision 2: Provider for State Management
**Status**: ✅ Good Choice (for now)

**Pros**:
- Native Flutter solution
- Simple to understand
- Good ecosystem support
- Sufficient for current complexity

**Cons**:
- No compile-time safety
- Manual `notifyListeners()` calls (error-prone)
- Difficult to debug state changes
- No built-in dev tools

**Assessment**: **Good for MVP, consider migration path**

**Future Consideration**:
```dart
// Current: Provider + ChangeNotifier
class TaskViewModel extends ChangeNotifier {
  List<Task> _tasks = [];

  Future<void> fetchTasks() async {
    _tasks = await _service.getTasks();
    notifyListeners(); // Easy to forget!
  }
}

// Future: Riverpod (compile-time safe, immutable)
@riverpod
class TaskNotifier extends _$TaskNotifier {
  @override
  FutureOr<List<Task>> build() async {
    return await ref.read(taskServiceProvider).getTasks();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() =>
      ref.read(taskServiceProvider).getTasks()
    );
  }
}
```

---

### Decision 3: Supabase as Backend
**Status**: ✅ Excellent Choice

**Pros**:
- Open source (no vendor lock-in)
- PostgreSQL (powerful relational DB)
- Built-in auth, storage, realtime
- Row-Level Security (RLS) at DB level
- Cost effective vs Firebase
- Self-hostable

**Cons**:
- Smaller ecosystem than Firebase
- Less mature mobile SDKs
- Free tier has limits (auto-pause)
- Learning curve for RLS

**Assessment**: **Perfect for this use case**

**RLS Advantages**:
```sql
-- Security at DATABASE level (can't bypass from client)
CREATE POLICY "Users can only see their own data"
ON profiles FOR SELECT
USING (auth.uid() = id);

-- vs Firebase (security in rules, easier to misconfigure)
{
  "rules": {
    "profiles": {
      "$uid": {
        ".read": "$uid === auth.uid"
      }
    }
  }
}
```

---

### Decision 4: Feature-Based Organization
**Status**: ✅ Excellent Choice

**Current Structure**:
```
lib/features/
├── auth/
├── tasks/
├── chat/
├── booking/
├── profile/
└── ...
```

**Pros**:
- Easy to find related code
- Clear feature boundaries
- Enables team parallelization
- Easy to delete features

**Cons**:
- Can lead to code duplication
- Shared widgets need careful placement

**Assessment**: **Ideal for multi-feature app**

**2026-03-01 Current Note**:
- Feature-based organization only stays healthy when decommissioned features are actually removed from runtime wiring. The retired `orders` module was a concrete example of a feature folder that had drifted out of navigation ownership while still keeping a provider and docs alive.

---

### Decision 5: Repository Pattern (Partial Implementation)
**Status**: ⚠️ Inconsistent

**Current State**:
- Some features have Repository layer (Auth, Tasks)
- Some features only have Service layer (Chat, Favorites)
- Auth has BOTH Service AND Repository (duplication!)

**Assessment**: **Needs standardization**

**Recommendation**:
```
Option 1 (Recommended): Keep Repository for all features
ViewModel → Repository → Service → Supabase
- Repository: Caching, error mapping, data aggregation
- Service: Direct Supabase calls only

Option 2 (Simpler): Remove Repository, use only Service
ViewModel → Service → Supabase
- Service: All business logic and Supabase calls

Option 3 (Current - NOT RECOMMENDED):
Mixed approach causes confusion
```

**Suggested Standard**:
```dart
// Service: Direct Supabase interaction
class TaskService {
  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchTasks() async {
    return await _client.from('tasks').select().order('created_at');
  }
}

// Repository: Business logic, caching, error mapping
class TaskRepository {
  final TaskService _service;
  final Cache? _cache;

  Future<List<Task>> getTasks({bool refresh = false}) async {
    if (!refresh && _cache != null) {
      final cached = _cache!.get<List<Task>>('tasks');
      if (cached != null) return cached;
    }

    try {
      final json = await _service.fetchTasks();
      final tasks = json.map((e) => Task.fromJson(e)).toList();
      _cache?.set('tasks', tasks, duration: Duration(minutes: 5));
      return tasks;
    } on PostgrestException catch (e) {
      throw _mapError(e);
    }
  }
}
```

---

### Decision 6: Coordinator Pattern for Cross-ViewModel Communication (v2.18)
**Status**: ✅ Excellent Choice

**Context**: Role switching requires cleaning up cached data across multiple ViewModels (Chat, Dashboard, Task, Home). Direct ViewModel-to-ViewModel references violate MVVM boundaries (ViewModels are independent units).

**Problem**: How to signal ViewModels to teardown when the active role changes?

**Solution**: Implement the **Coordinator Pattern** with a singleton coordinator and a mixin interface.

```dart
// Mixin interface for ViewModels that need teardown
mixin RoleSwitchAware {
  Future<void> teardownForRoleSwitch();
}

// Singleton coordinator that manages registrations
class RoleSwitchCoordinator {
  static final RoleSwitchCoordinator _instance = RoleSwitchCoordinator._internal();
  factory RoleSwitchCoordinator() => _instance;
  RoleSwitchCoordinator._internal();

  final List<RoleSwitchAware> _registered = [];

  void register(RoleSwitchAware vm) => _registered.add(vm);
  void unregister(RoleSwitchAware vm) => _registered.remove(vm);

  Future<void> teardownAll() async {
    final errors = <String>[];
    for (final vm in _registered) {
      try {
        await vm.teardownForRoleSwitch();
      } catch (e) {
        errors.add(e.toString());
      }
    }
    if (errors.isNotEmpty) throw RoleSwitchTeardownException(errors);
  }
}
```

**Usage in ViewModels**:
```dart
class ChatViewModel extends ChangeNotifier with RoleSwitchAware {
  ChatViewModel() {
    RoleSwitchCoordinator().register(this);
  }

  @override
  Future<void> teardownForRoleSwitch() async {
    // Cancel subscriptions
    await _client.removeAllChannels();
    // Clear cached data
    _conversations.clear();
    _messages.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    RoleSwitchCoordinator().unregister(this);
    super.dispose();
  }
}
```

**Pros**:
- ✅ Maintains MVVM boundaries (no direct ViewModel references)
- ✅ Type-safe (mixin interface contract)
- ✅ Testable (mock coordinator in tests)
- ✅ Extensible (can add other global events beyond role switching)
- ✅ Backward compatible (ViewModels opt-in via mixin)

**Cons**:
- ⚠️ Global state (singleton) — manageable, but requires testing discipline
- ⚠️ Registration cleanup critical (must call `unregister()` in `dispose()`)
- ⚠️ No compile-time safety for forgetting to call `teardownForRoleSwitch()`

**Assessment**: **Elegant solution to cross-cutting concern within MVVM**

**When to Use**:
- Cross-ViewModel events (e.g., logout, role switch, theme change)
- Global state teardown (clear all cached data)
- Synchronized refresh across multiple screens

**When NOT to Use**:
- Simple ViewModel-to-View data flow (use standard Provider/Consumer)
- Feature-specific coordination (keep within feature boundary)

**Related**: See `CODE_REVIEW.md` section 8 for implementation details.

---

## Scalability Assessment

### Current Load Capacity

**Estimated Limits (Before Optimization)**:
- Concurrent Users: ~1,000
- Database Queries/sec: ~50 (bottleneck: N+1 queries)
- Realtime Connections: ~500 (Supabase free tier limit)
- Storage: 1GB (Supabase free tier)

**After Optimization**:
- Concurrent Users: ~10,000
- Database Queries/sec: ~500+ (after fixing N+1)
- Realtime Connections: Limited by tier
- Storage: Unlimited (pay per GB)

### Bottlenecks Identified

#### 1. Database Query Inefficiency ⚠️
**Issue**: N+1 queries in TaskService
**Impact**: 10-50x performance degradation
**Fix**: JOIN queries or batch fetching
**Priority**: CRITICAL

#### 2. No Caching Strategy ⚠️
**Issue**: Every request hits Supabase
**Impact**: Slow loading, high costs
**Fix**: Implement Repository-level caching
**Priority**: HIGH

```dart
// Recommended caching strategy
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

  void invalidate(String key) => _cache.remove(key);
  void invalidateAll() => _cache.clear();
}
```

#### 3. No Pagination on Large Lists ⚠️
**Issue**: Fetching all tasks at once
**Impact**: Slow initial load, high memory
**Fix**: Implement cursor-based pagination

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

#### 4. Realtime Subscriptions Always Active ⚠️
**Issue**: Chat subscriptions active even when app backgrounded
**Impact**: Battery drain, unnecessary data transfer
**Fix**: Pause subscriptions when app paused

```dart
class ChatViewModel extends ChangeNotifier with WidgetsBindingObserver {
  StreamSubscription? _msgSub;
  bool _isPaused = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      pauseSubscriptions();
    } else if (state == AppLifecycleState.resumed) {
      resumeSubscriptions();
    }
  }

  void pauseSubscriptions() {
    _isPaused = true;
    _msgSub?.cancel();
  }

  void resumeSubscriptions() {
    _isPaused = false;
    _subscribeToMessages();
  }
}
```

#### 5. No Image Optimization ⚠️
**Issue**: Full-size images loaded for thumbnails
**Impact**: Slow loading, high data usage
**Fix**: Use Supabase image transformations

```dart
// Current
final url = supabase.storage.from('avatars').getPublicUrl(path);

// Optimized with transformations
final url = supabase.storage.from('avatars').getPublicUrl(
  path,
  transform: TransformOptions(
    width: 200,
    height: 200,
    resize: ResizeMode.cover,
  ),
);
```

---

## Performance Optimization Strategies

### 1. Query Optimization (CRITICAL)

**Current Performance**:
```dart
// ❌ 51 queries for 50 tasks
for (var task in tasks) {
  final profile = await getProfile(task.userId);
}
```

**Optimized**:
```dart
// ✅ 1 query for 50 tasks
final tasks = await supabase.from('tasks').select('''
  *,
  profiles!tasks_user_id_fkey(full_name, avatar_url)
''');
```

**Impact**: 10-50x faster, 50x fewer database connections

---

### 2. Implement Multi-Level Caching

```dart
class CacheStrategy {
  // Level 1: In-memory (instant)
  final MemoryCache _memory = MemoryCache();

  // Level 2: SQLite (fast)
  final LocalDatabase _db = LocalDatabase();

  // Level 3: Supabase (network)
  final SupabaseClient _supabase;

  Future<List<Task>> getTasks() async {
    // Try memory first
    var tasks = _memory.get<List<Task>>('tasks');
    if (tasks != null) return tasks;

    // Try local DB
    tasks = await _db.getTasks();
    if (tasks.isNotEmpty) {
      _memory.set('tasks', tasks);
      return tasks;
    }

    // Fetch from network
    tasks = await _fetchFromSupabase();
    await _db.saveTasks(tasks);
    _memory.set('tasks', tasks);
    return tasks;
  }
}
```

---

### 3. Optimize Realtime Subscriptions

**Current**: Global subscriptions always active
**Optimized**: Scoped subscriptions with lifecycle management

```dart
class ChatScreenState extends State<ChatScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {

  @override
  bool get wantKeepAlive => false; // Don't keep off-screen chats alive

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscribe();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _unsubscribe();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _unsubscribe();
    } else if (state == AppLifecycleState.resumed) {
      _subscribe();
    }
  }
}
```

---

### 4. Lazy Loading & Pagination

```dart
class TaskListView extends StatefulWidget {
  @override
  State<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<TaskViewModel>().loadTasks();
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (currentScroll >= maxScroll * 0.9) {
      // Load more when user reaches 90% of list
      context.read<TaskViewModel>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: context.watch<TaskViewModel>().tasks.length + 1,
      itemBuilder: (context, index) {
        final vm = context.watch<TaskViewModel>();

        if (index == vm.tasks.length) {
          return vm.isLoadingMore
              ? Center(child: CircularProgressIndicator())
              : SizedBox();
        }

        return TaskCard(task: vm.tasks[index]);
      },
    );
  }
}
```

---

### 5. Image Loading Optimization

```dart
class OptimizedImage extends StatelessWidget {
  final String path;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: _getOptimizedUrl(path, width, height),
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          width: width,
          height: height,
          color: Colors.white,
        ),
      ),
      errorWidget: (context, url, error) => Icon(Icons.error),
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
    );
  }

  String _getOptimizedUrl(String path, double? w, double? h) {
    return supabase.storage.from('images').getPublicUrl(
      path,
      transform: TransformOptions(
        width: w?.toInt() ?? 800,
        height: h?.toInt(),
        resize: ResizeMode.cover,
        quality: 80,
      ),
    );
  }
}
```

---

## Security Architecture Review

### Current Security Posture: ✅ STRONG

#### 1. Row-Level Security (RLS) ✅
**Status**: Properly implemented

```sql
-- Example: Users can only see their own profiles
CREATE POLICY "profile_select_own" ON profiles
FOR SELECT USING (auth.uid() = id);

-- Example: Only task owner or bidder can see requests
CREATE POLICY "requests_select_participant" ON task_requests
FOR SELECT USING (
  task_id IN (SELECT id FROM tasks WHERE user_id = auth.uid())
  OR bidder_id = auth.uid()
);
```

**Assessment**: ✅ Excellent - Security enforced at DB level

---

#### 2. Private Storage with Signed URLs ✅
**Status**: Correctly implemented

```dart
// ✅ Correct: Store path, generate signed URL
await supabase.from('profiles').update({
  'avatar_url': 'avatars/user-id/avatar.jpg'
});

final signedUrl = await supabase.storage
    .from('avatars')
    .createSignedUrl(path, 3600); // 1 hour expiry
```

**Assessment**: ✅ Good - Prevents unauthorized access

---

#### 3. Input Validation ⚠️
**Status**: Needs improvement

**Current**: Basic validation in UI
**Recommendation**: Add server-side validation

```sql
-- Add database constraints
ALTER TABLE tasks ADD CONSTRAINT budget_positive
  CHECK (budget > 0);

ALTER TABLE task_requests ADD CONSTRAINT price_positive
  CHECK (price > 0 AND days > 0);

-- Add trigger for business logic
CREATE OR REPLACE FUNCTION validate_task_request()
RETURNS TRIGGER AS $$
BEGIN
  IF (SELECT task_type FROM tasks WHERE id = NEW.task_id) = 'booking' THEN
    RAISE EXCEPTION 'Cannot submit request on booking tasks';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

---

#### 4. Secrets Management ⚠️
**Status**: Needs improvement

**Current**: Hardcoded in `supabase_config.dart`

```dart
// ❌ NOT RECOMMENDED
const kSupabaseUrl = 'https://xxx.supabase.co';
const kSupabaseAnonKey = 'eyJhbGciOiJIUzI1...';
```

**Recommendation**: Use environment variables

```dart
// ✅ RECOMMENDED
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load();
  final url = dotenv.env['SUPABASE_URL']!;
  final key = dotenv.env['SUPABASE_ANON_KEY']!;
  await SupabaseConfig.init(url: url, anonKey: key);
}

// .env (gitignored)
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGci...
```

---

#### 5. Rate Limiting ⚠️
**Status**: Not implemented

**Recommendation**: Add Supabase edge functions with rate limiting

```typescript
// supabase/functions/create-task/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "@supabase/supabase-js";

const RATE_LIMIT = 10; // 10 tasks per hour

serve(async (req) => {
  const userId = req.headers.get("x-user-id");

  // Check rate limit
  const recentTasks = await supabase
    .from("tasks")
    .select("id")
    .eq("user_id", userId)
    .gte("created_at", new Date(Date.now() - 3600000).toISOString());

  if (recentTasks.length >= RATE_LIMIT) {
    return new Response("Rate limit exceeded", { status: 429 });
  }

  // Process task creation...
});
```

---

## Future Architecture Recommendations

### 1. Migrate to Riverpod (6-12 months)

**Benefits**:
- Compile-time safety
- Better DevTools
- Immutable state
- Easier testing

**Migration Path**:
```dart
// Phase 1: Add Riverpod alongside Provider
dependencies:
  provider: ^6.0.5
  flutter_riverpod: ^2.4.0

// Phase 2: Migrate one feature at a time
// Start with new features using Riverpod

// Phase 3: Gradually migrate existing features

// Phase 4: Remove Provider completely
```

---

### 2. Add Offline-First Architecture (12 months)

**Recommended**: Hive + Drift (SQLite)

```dart
// Local storage for offline
class OfflineTaskRepository {
  final Box<Task> _taskBox = Hive.box('tasks');
  final TaskService _service;

  Future<List<Task>> getTasks() async {
    try {
      // Try network first
      final tasks = await _service.getTasks();
      await _syncToLocal(tasks);
      return tasks;
    } catch (e) {
      // Fallback to local
      return _taskBox.values.toList();
    }
  }
}
```

---

### 3. Implement Event Sourcing for Critical Flows

**Use Case**: Task status changes, booking lifecycle

```dart
// Event store
class TaskEvent {
  final String taskId;
  final String eventType; // 'created', 'assigned', 'completed'
  final Map<String, dynamic> data;
  final DateTime timestamp;
}

// Audit trail + ability to replay events
class TaskEventStore {
  Future<void> recordEvent(TaskEvent event) async {
    await supabase.from('task_events').insert(event.toJson());
  }

  Future<List<TaskEvent>> getHistory(String taskId) async {
    return await supabase
        .from('task_events')
        .select()
        .eq('task_id', taskId)
        .order('timestamp');
  }
}
```

---

### 4. Microservices for Heavy Operations

**Candidates**:
- Image processing (resize, compress, format conversion)
- Video transcoding (if adding video)
- PDF generation (invoices, contracts)
- Email notifications

```
Flutter App → Supabase Edge Functions → External Services
                                     ↓
                              [Image Processing Worker]
                              [Email Service]
                              [Payment Gateway]
```

---

### 5. Add Analytics & Monitoring

```dart
class AnalyticsService {
  void trackEvent(String name, {Map<String, dynamic>? properties}) {
    // Firebase Analytics
    FirebaseAnalytics.instance.logEvent(
      name: name,
      parameters: properties,
    );

    // Mixpanel / Amplitude
    Mixpanel.track(name, properties: properties);
  }

  void trackPerformance(String operation, Duration duration) {
    FirebasePerformance.instance.newTrace(operation)
      ..start()
      ..setMetric('duration_ms', duration.inMilliseconds)
      ..stop();
  }
}

// Usage
await AnalyticsService().trackEvent('task_created', properties: {
  'task_type': 'tender',
  'budget': 500,
  'category': 'design',
});
```

---

## Migration Paths

### Path 1: Provider → Riverpod (Recommended Timeline: 6-12 months)

**Phase 1 (Month 1-2)**: Setup & New Features
- Add `flutter_riverpod` dependency
- Create Riverpod providers for new features only
- Team training on Riverpod

**Phase 2 (Month 3-6)**: Migrate Read-Only Features
- Start with simple features (Categories, Portfolio)
- Migrate ViewModels to StateNotifier/AsyncNotifier
- Test thoroughly

**Phase 3 (Month 7-10)**: Migrate Complex Features
- Migrate Auth, Tasks, Chat
- Update all widget trees to use ConsumerWidget
- Remove Provider dependencies

**Phase 4 (Month 11-12)**: Cleanup & Optimization
- Remove all Provider code
- Optimize with Riverpod features (autodispose, family, etc.)
- Final testing & performance tuning

---

### Path 2: Add Offline Support (Recommended Timeline: 3-6 months)

**Phase 1 (Month 1)**: Local Storage Setup
```dart
dependencies:
  hive: ^2.2.3
  hive_flutter: ^1.1.0

// Initialize
await Hive.initFlutter();
Hive.registerAdapter(TaskAdapter());
await Hive.openBox<Task>('tasks');
```

**Phase 2 (Month 2-3)**: Repository Pattern with Offline
```dart
class TaskRepository {
  final TaskService _remoteService;
  final Box<Task> _localBox;

  Future<List<Task>> getTasks({bool forceRefresh = false}) async {
    if (!forceRefresh && !await _hasNetwork()) {
      return _localBox.values.toList();
    }

    try {
      final tasks = await _remoteService.getTasks();
      await _syncToLocal(tasks);
      return tasks;
    } catch (e) {
      if (_localBox.isNotEmpty) {
        return _localBox.values.toList();
      }
      rethrow;
    }
  }
}
```

**Phase 3 (Month 4-5)**: Sync Strategy
- Implement queue for pending operations
- Handle conflicts (last-write-wins or manual resolution)
- Add background sync

**Phase 4 (Month 6)**: Polish & Testing
- Handle edge cases
- Add UI indicators for offline mode
- Thorough testing on various network conditions

---

### Path 3: Modularization (Future: 12+ months)

**Goal**: Split app into independent packages

```
sline_app/
├── packages/
│   ├── core/
│   │   ├── lib/
│   │   │   ├── services/
│   │   │   ├── models/
│   │   │   └── utils/
│   │   └── pubspec.yaml
│   ├── features_auth/
│   ├── features_tasks/
│   ├── features_chat/
│   └── features_booking/
├── apps/
│   ├── mobile/
│   └── web/
└── pubspec.yaml
```

**Benefits**:
- Clear boundaries
- Independent versioning
- Easier testing
- Code reuse across apps

---

## Conclusion

The SLine architecture is **fundamentally sound** with proper separation of concerns and good practices. The immediate priorities are:

1. **Fix N+1 queries** (Critical, 1 week)
2. **Standardize Repository pattern** (High, 1 week)
3. **Implement caching** (High, 2 weeks)
4. **Add offline support** (Medium, 3-6 months)
5. **Migrate to Riverpod** (Low, 6-12 months)

With these improvements, SLine will be ready to scale to **10,000+ concurrent users** with excellent performance and maintainability.
