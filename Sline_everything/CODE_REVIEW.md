# SLine Code Review & Improvement Report

**Date**: December 14, 2025 (Updated)
**Reviewed By**: CodeGuard + Architect + Sentinel Agents
**Previous Score**: 9/10
**Current Score**: 9.7/10

> Historical review note: this document records review findings and fixes from earlier passes. Treat references to removed files or older structure as historical context; the current live structure is documented in `Sline_everything/STRUCTURE.md` and `Sline_everything/DEVELOPER_GUIDE.md`.

## Current Guardrail Notes (2026-04-05)

### Widget Test Type A/B Classification (Phase F, 2026-04-05)

**Pattern**: Screens fall into two categories for widget testing:
- **Type A** — VM provided by Provider ancestor. Test mocks the VM directly via `ChangeNotifierProvider.value(value: mockVm)`.
- **Type B** — VM created internally in `build()` / `initState()`. Test mocks the services the VM consumes.

**Rule**: Before writing any widget test, classify the screen. Wrong classification causes either `ProviderNotFoundException` (Type A treated as B) or untestable constructor paths (Type B treated as A).

**Additional checks**:
- Verify the base class of every mock target: `ChangeNotifier` → `ChangeNotifierProvider.value`, plain class → `Provider<T>.value`.
- For Type B screens, trace every `context.read<T>()` / `context.watch<T>()` in the screen AND the VM it creates — all must have Provider ancestors in the test.

**Evidence**: Phase F — `PaymentPendingStore` wrongly typed as `ChangeNotifier` (it's a plain class). Type B screens required service-level mocking, not VM mocking.

### Navigator Interception Pattern for Widget Tests (Phase F, 2026-04-05)

**Pattern**: When testing screens that launch a WebView or push a second route (e.g., payment checkout → webview), use a `NavigatorObserver` with a push counter to intercept the correct route.

**Rule**: The observer must skip the first `didPush` (which is the home/test route) and intercept subsequent pushes. Pop with the expected result (e.g., `PaymentReturnArgs(status: 'SUCCESS')`).

**Evidence**: Phase F — First attempt intercepted the wrong push (home route), destroying the screen before it rendered.

### Timer Management in Widget Tests (Phase F, 2026-04-05)

**Pattern**: When production code uses `Future.delayed` (e.g., auto-pop after 1200ms), tests must manage timing carefully.

**Rule**:
1. Assert BEFORE the timer fires (use short pumps: `for (var i = 0; i < N; i++) { await tester.pump(Duration(milliseconds: 50)); }`).
2. After assertions, drain the timer with `await tester.pumpAndSettle(Duration(seconds: 2))` to avoid `timersPending` failures.

**Evidence**: Phase F — `pumpAndSettle(Duration(seconds: 3))` pumped past the 1200ms auto-pop timer, removing the screen before assertions.

### Pluralization in UI Strings (Phase F, 2026-04-05)

**Rule**: UI strings displaying counts must handle singular vs plural correctly. Never hardcode the plural form.

```dart
// Correct
'$count ${count == 1 ? 'Revision' : 'Revisions'}'

// Wrong
'$count Revisions'  // shows "1 Revisions"
```

**Evidence**: Phase F — `task_details_screen.dart` showed "1 Revisions" for package revision count.

### T-Number Uniqueness in Test Files (Phase F, 2026-04-05)

**Rule**: Every `T###` test identifier must be unique across ALL test files. After writing tests, verify with:
```bash
grep -rn 'T[0-9]\{3\}' test/ | sed 's/:.*//' | sort | uniq -d
```
Any T-number appearing in more than one file is a collision that must be renumbered.

**Evidence**: Phase F — T160-T168 collision in `requests_list_screen_test.dart` and `work_item_details_screen_test.dart`.

### Agent System Evolution (Phase F, 2026-04-05)

**Process**: After multi-session work, run `@SystemEvolution` to scan all session logs, agent files, and core docs. It produces an evidence-based report identifying rule gaps, clarity gaps, propagation gaps, and coordination improvements. Apply recommendations to `.cursor/Agents/` files to prevent repeat failures.

**Evidence**: Phase F — First SystemEvolution report identified 13 priority actions across 7 agent files, all applied. Most common failure type: planning gaps (wrong assumptions about codebase reality).

### Raw String Interpolation Guard (Phase E, 2026-04-05)

**Pattern**: Never use raw string literals (`r'...'`) in `AppLogger` calls or any string containing `$variable` interpolation. Raw strings make `$` literal. Use normal single-quoted strings.

**Evidence**: Phase E BLOCKER — 14 `r'...$var...'` instances in `task_requests_award_delegate.dart` and `task_requests_view_model.dart` silently broke financial flow logging.

### Error Message Sanitization (Phase E, 2026-04-05)

**Rule**: NEVER pass `e.toString()`, `e.message`, or `error.toString()` to SnackBars, dialogs, or any user-visible UI. ALWAYS use `ErrorMapper.map(e)`. This applies in ViewModel catch blocks, View catch blocks, and Delegate catch blocks.

**Evidence**: Phase E — 6 raw exception leaks found across ViewModels and views.

### ViewState Mutation Preservation (Phase E, 2026-04-05)

**Pattern**: When using sealed `ViewState<T>`, action methods must NOT overwrite `ViewLoaded` → `ViewLoading`. Use `_actionInProgress` flag to preserve loaded data during mutations.

**Evidence**: Phase E — 8 action methods in WorkItemDetailsVM wiped loaded state.

### Web Payment URL Cleanup (Phase E, 2026-04-05)

**Rule**: Every code path processing web payment return URLs must call `clearPaymentReturnParamsFromUrl()` immediately after parsing. Both PaymentReturnScreen and DashboardScreen must clear.

**Evidence**: Phase E — Missing cleanup caused 20+ duplicate payment detection logs per session.

### Zone Initialization Order (Phase E, 2026-04-05)

**Rule**: `WidgetsFlutterBinding.ensureInitialized()` must be called BEFORE `runZonedGuarded()` (but inside Sentry's appRunner).

**Evidence**: Phase E — Zone mismatch error on every app startup.

### Lazy Supabase Client Resolution (Phase D, 2026-04-04)

**Pattern**: Adding a `SupabaseClient` DI parameter with `Supabase.instance.client` as eager default crashes tests where Supabase is not initialized (throws `AssertionError`, which is `Error` not `Exception`).

**Rule**: Always use a lazy getter:
```dart
final SupabaseClient? _injectedClient;
SupabaseClient get _client => _injectedClient ?? Supabase.instance.client;
```
Never `_client = client ?? Supabase.instance.client` in the initializer list.

**Evidence**: Same root cause across 3 sessions (Phase B, C, D). Systemic.

### Delegate Dispose Safety (Phase D, 2026-04-04)

**Pattern**: Delegates with async methods can complete after the parent VM disposes, calling `notifyListeners()` on a disposed `ChangeNotifier`.

**Rule**: Every delegate MUST receive `bool Function() isDisposed` from the parent VM. Every async method MUST check `if (_isDisposed()) return;` before calling `_onChanged()`. The parent passes `() => _isDisposed` as the callback.

### God-File Decomposition Checklist (Phase D, 2026-04-04)

When decomposing a file >800 lines:
1. Map every method to an extraction target (delegate class or extracted widget).
2. Identify methods that MUST stay (orchestration, lifecycle, caching coordination).
3. Set target: `current_lines - extractable_lines + 10% buffer`. Not arbitrary round numbers.
4. Preserve all public getters/methods with identical signatures (proxy to delegates).
5. Run tests after EACH delegate is created, not just at the end.
6. Add tests for each delegate independently.

### Defensive Collection Patterns (Phase D, 2026-04-04)

**Rule**: Delegate/ViewModel getters exposing internal lists MUST return `UnmodifiableListView`. Setters accepting external lists MUST store a defensive copy (`.toList()`).

```dart
List<BookingModel> get bookings => UnmodifiableListView(_bookings);
void setBookings(List<BookingModel> bookings) {
  _bookings = bookings.toList(); // defensive copy
}
```

---

## Guardrail Notes (2026-04-02)

### Constructor DI Testability (Phase C, 2026-04-02)

**Pattern**: ViewModels that create services internally from `SupabaseClient` are untestable — mock services cannot be injected.

**Rule**: All ViewModels MUST accept optional service parameters in their constructors with production defaults:
```dart
// Correct: services injectable, defaults to production
WalletViewModel({WalletRepository? repo, AccountGuardService? accountGuardService, SupabaseClient? client})

// Wrong: services created internally, no way to inject mocks
WalletViewModel({SupabaseClient? client})
```

**When refactoring**: Use initializer list with `final` fields and `??` defaults. Do NOT use `late` (non-final) — it removes compile-time immutability guarantees.

### Singleton Cleanup in Tests (Phase C, 2026-04-02)

**Pattern**: VMs that register with `RoleSwitchCoordinator()` (singleton) in constructors will pollute subsequent tests if not cleaned up.

**Rule**: Every test group for a VM that uses singletons MUST include:
```dart
tearDown(() {
  viewModel.dispose();
  RoleSwitchCoordinator().clearForTesting();
});
```

### Auto-Loading Constructor Mock Pre-Configuration (Phase C, 2026-04-02)

**Pattern**: VMs that call load/fetch/init methods in their constructor require ALL mock stubs to be configured BEFORE construction.

**Rule**: If a VM auto-loads in constructor (like DashboardVM), setUp must configure every repo/service stub before calling the constructor. Missing any stub = `MissingStubError`.

### Navigation Consolidation Must Remove Orphaned Runtime Surfaces

**Pattern**:
- A feature tab gets consolidated onto another live screen, but the old feature folder, provider, tests, and docs stay behind.

**Why it matters**:
- This creates false audit targets, stale providers, and duplicate mental models for the same user-facing surface.

**Required cleanup checklist**:
- Remove the old provider from `lib/main.dart` or the relevant local composition root.
- Delete dead runtime files instead of leaving them compiled-but-unreachable.
- Keep one explicit tombstone note if the old folder path must remain for transition clarity.
- Update `Sline_everything/DEVELOPER_GUIDE.md`, `Sline_everything/STRUCTURE.md`, `Sline_everything/MVP_ROADMAP.md`, and `Sline_everything/Sline_Log.md` in the same patch.
- Add or update a navigation/widget test so the surviving tab contract is asserted directly.

## Executive Summary

Following **Phase 1 Foundation** completion using CodeGuard, Architect, and Sentinel agents, the SLine Flutter application now includes **comprehensive error handling**, **image caching**, **cursor-based pagination**, and **session expiry management**. The app demonstrates **excellent architectural compliance**, **optimal performance patterns**, and **robust error handling**.

---

## ✅ PHASE 1 FIXES (December 2025)

### 1. Centralized Error Handling - NEW ✅

**Location**: `lib/core/utils/error_mapper.dart`
**Status**: **IMPLEMENTED**

Created centralized `ErrorMapper` utility following `.cursor/rules/error-handling.mdc`:

```dart
// Usage in services
try {
  await supabaseOperation();
} on PostgrestException catch (e, st) {
  AppLogger.e('Operation failed', tag: 'Service', error: e, stackTrace: st);
  throw Exception(ErrorMapper.map(e));  // User-friendly message
}
```

**Mapped Errors**:
| Exception Type | Code | User Message |
|----------------|------|--------------|
| PostgrestException | 42501 | "Session expired. Please log in again." |
| PostgrestException | 23505 | "This item already exists." |
| AuthException | invalid_credentials | "Email or password is incorrect." |
| StorageException | 413 | "File is too large. Please choose a smaller file." |

---

### 2. Image Caching - NEW ✅

**Location**: `lib/core/widgets/signed_image.dart`, `lib/core/widgets/signed_avatar.dart`
**Status**: **IMPLEMENTED**

Added `cached_network_image` package for disk/memory caching:

```dart
// Before - no caching
Image.network(url)

// After - cached
CachedNetworkImage(
  imageUrl: url,
  placeholder: (_, __) => LoadingWidget(),
  errorWidget: (_, __, ___) => PlaceholderWidget(),
)
```

**Impact**: Reduced network calls on subsequent loads, faster image display.

---

### 3. Cursor-Based Pagination - NEW ✅

**Location**: `lib/features/tasks/services/task_service.dart`, `lib/features/home/viewmodels/home_view_model.dart`
**Status**: **IMPLEMENTED**

Implemented per project rules (no offset pagination):

```dart
// Service
Future<List<Task>> getOpenTasksForHome({
  int limit = 20,
  String? cursorCreatedAtIso,
}) async {
  var query = _client.from('tasks').select(...).eq('status', 'open');
  if (cursorCreatedAtIso != null) {
    query = query.lt('created_at', cursorCreatedAtIso);
  }
  return query.order('created_at', ascending: false).limit(limit);
}

// ViewModel
Future<void> loadMoreTasks() async {
  if (_isLoadingMore || !_hasMore || _cursor == null) return;
  final tasks = await _taskService.getOpenTasksForHome(cursorCreatedAtIso: _cursor);
  _cursor = tasks.last.createdAt.toUtc().toIso8601String();
  _hasMore = tasks.length >= TaskService.defaultPageSize;
}
```

---

### 4. Session Expiry Handling - NEW ✅

**Location**: `lib/features/auth/viewmodels/` (then `auth_view_model.dart`; now split into `auth_session_view_model.dart` and `auth_form_view_model.dart`), `lib/main.dart`
**Status**: **IMPLEMENTED**

Added auth state listener with pending queue for race condition prevention:

```dart
// AuthViewModel
bool _pendingSessionExpired = false;
VoidCallback? _onSessionExpired;

set onSessionExpired(VoidCallback? callback) {
  _onSessionExpired = callback;
  // Process queued expiry from before callback was set
  if (_pendingSessionExpired && callback != null) {
    _pendingSessionExpired = false;
    callback();
  }
}

// Listener
_authSubscription = supabase.auth.onAuthStateChange.listen(
  (state) { /* handle state changes */ },
  onError: (error) {
    if (_onSessionExpired != null) {
      _onSessionExpired!();
    } else {
      _pendingSessionExpired = true;  // Queue for later
    }
  },
);
```

---

## ✅ COMPLETED FIXES (Previous Sessions)

### 1. N+1 Query Anti-Pattern - FIXED ✅

**Location**: `lib/features/tasks/services/task_service.dart`
**Status**: **RESOLVED**

**What was fixed**:

- Replaced 4 methods with N+1 queries with single JOIN queries
- Added `_selectWithProfile` constant for consistent query pattern
- Updated `Task.fromJson()` to parse nested profile data from JOINs

**Before** (51 queries for 50 tasks):

```dart
for (var i = 0; i < tasks.length; i++) {
  final user = await _client.from('profiles')...
}
```

**After** (1 query for any number of tasks):

```dart
static const String _selectWithProfile = '''
  ..., profiles!tasks_user_id_fkey(full_name, avatar_url)
''';
```

**Impact**: 10-50x performance improvement on task listings.

---

### 2. Auth Code Duplication - FIXED ✅

**Status**: **RESOLVED**

**What was fixed**:

- Deleted `lib/features/auth/services/auth_service.dart` (duplicate file)
- Updated `AuthViewModel` to use `AuthRepository` directly
- Refactored to return success/failure booleans instead of passing BuildContext

**Before**:

```dart
// Two identical files doing the same thing
class AuthService { ... }  // auth_service.dart
class AuthRepository { ... }  // auth_repository.dart - DUPLICATE!
```

**After**:

```dart
// Single source of truth
class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepo;
  Future<bool> login(...) async { ... }
}
```

---

### 3. BuildContext Anti-Pattern in AuthViewModel - FIXED ✅

**Status**: **RESOLVED**

**What was fixed**:

- Removed `State` and `BuildContext` parameters from ViewModel methods
- Methods now return `bool` for success/failure
- View handles navigation and SnackBars based on ViewModel state
- Added user-friendly error mapping with `_mapAuthError()`

**Before** (anti-pattern):

```dart
Future<void> login({required State state, ...}) async {
  Navigator.pushReplacement(state.context, ...);  // ❌ Context in ViewModel
}
```

**After** (proper MVVM):

```dart
Future<bool> login({required String email, ...}) async {
  // Returns true/false, UI handles navigation
}
```

---

### 4. Global Error Boundary - ADDED ✅

**Location**: `lib/main.dart`
**Status**: **RESOLVED**

**What was added**:

- `FlutterError.onError` for widget build errors
- `PlatformDispatcher.instance.onError` for native crashes
- `runZonedGuarded()` for uncaught async exceptions
- All errors logged via `AppLogger.e()` for future crash reporting integration

---

### 5. Direct Service Calls from UI - FIXED ✅

**Location**: `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart`
**Status**: **RESOLVED**

**What was fixed** (Favorites Fix 2026-03):

- RequestTile uses **only** `FavoritesViewModel` (from app-level provider); no direct `FavoritesService` call.
- `requests_list_screen.dart` passes `context.read<FavoritesViewModel>()` into RequestTile.
- Add-to-favorites uses typed `FavoritesMutationResult` for success/duplicate/error feedback.

---

### 6. Missing AuthViewModel Provider - FIXED ✅

**Location**: `lib/main.dart`
**Status**: **RESOLVED** (as of 2026-03-05; as of 2026-03-06 auth uses **AuthSessionViewModel** + **AuthFormViewModel** split—see DEVELOPER_GUIDE.md Auth Feature Reference)

**What was fixed**:

- Added auth ViewModel(s) to global `MultiProvider` (now `AuthSessionViewModel` and `AuthFormViewModel`)
- Added descriptive comments for all providers
- Profile screen uses global `AuthSessionViewModel` for logout

---

### 7. Inconsistent Logger Usage - FIXED ✅

**Locations**:

- `lib/features/favorites/viewmodels/favorites_view_model.dart`
- `lib/features/saved/viewmodels/saved_tasks_view_model.dart`

**Status**: **RESOLVED**

**What was fixed**:

- Replaced `Logger()` with `AppLogger`
- Removed unused `final _favVmLogger = Logger();` declarations

---

### 8. Duplicate SignedUrlCache Classes - FIXED ✅

**Status**: **RESOLVED**

**What was fixed**:

- Created shared `lib/core/utils/signed_url_cache.dart`
- Updated `SignedAvatar` and `SignedImage` to use shared cache
- Removed duplicate `_CacheEntry` classes

---

## 📊 CODE QUALITY METRICS

### Before vs After

| Metric                  | Before     | After    | Change   |
| ----------------------- | ---------- | -------- | -------- |
| Architecture Compliance | 8/10       | 9.5/10   | +1.5     |
| Performance             | 6/10       | 9/10     | +3       |
| Code Duplication        | 6/10       | 9/10     | +3       |
| Error Handling          | 7/10       | 9/10     | +2       |
| Testing Coverage        | 3/10       | 3/10     | -        |
| Documentation           | 9/10       | 9.5/10   | +0.5     |
| **Overall**             | **7.5/10** | **9/10** | **+1.5** |

---

## 📁 FILES MODIFIED

### Core

- `lib/main.dart` - Added error boundary, AuthSessionViewModel + AuthFormViewModel providers, comments
- `lib/core/services/supabase_config.dart` - Added security documentation
- `lib/core/services/logger_service.dart` - Enhanced documentation
- `lib/core/utils/signed_url_cache.dart` - NEW: Shared cache utility
- `lib/core/widgets/signed_avatar.dart` - Use shared cache
- `lib/core/widgets/signed_image.dart` - Use shared cache

### Auth Feature

- `lib/features/auth/services/auth_service.dart` - DELETED (duplicate)
- `lib/features/auth/viewmodels/` - Auth logic split into `auth_session_view_model.dart` and `auth_form_view_model.dart` (replacing former `auth_view_model.dart`)
- `lib/features/auth/view/login_screen.dart` - Updated for new ViewModel API
- `lib/features/auth/view/signup_screen.dart` - Updated for new ViewModel API

### Tasks Feature

- `lib/features/tasks/services/task_service.dart` - N+1 fix with JOINs
- `lib/features/tasks/models/task_model.dart` - Parse profile from JOINs
- `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart` - ViewModel support

### Other Features

- `lib/features/profile/view/profile_screen.dart` - Use global AuthSessionViewModel for logout
- `lib/features/favorites/viewmodels/favorites_view_model.dart` - Use AppLogger
- `lib/features/saved/viewmodels/saved_tasks_view_model.dart` - Use AppLogger
- `lib/features/home/viewmodels/home_view_model.dart` - Added documentation
- `lib/features/chat/viewmodels/chat_view_model.dart` - Added documentation
- `lib/features/booking/viewmodels/booking_view_model.dart` - Added documentation

---

## ✅ POSITIVE FINDINGS (Maintained)

These excellent practices remain in place:

1. **✅ Proper `mounted` Checks**: Consistently checking `mounted` after async operations
2. **✅ No Print Statements**: Team consistently uses `AppLogger` instead of `print()`
3. **✅ Proper Stream Disposal**: ChatViewModel correctly cancels subscriptions
4. **✅ Correct Use of `.single()` vs `.maybeSingle()`**: Proper NULL safety
5. **✅ Clean MVVM Separation**: Clear boundaries between View, ViewModel, Repository, Service
6. **✅ Proper Provider Usage**: Good use of Consumer, context.read, context.watch
7. **✅ UTC Timestamp Handling**: Proper conversion to local for display
8. **✅ Signed URL Pattern**: Correctly storing paths and generating signed URLs on demand
9. **✅ Cursor-Based Pagination**: BookingViewModel demonstrates best practice
10. **✅ Coordinator Pattern (NEW v2.18)**: `RoleSwitchCoordinator` enables cross-ViewModel teardown without violating MVVM boundaries

---

## 🎯 REMAINING WORK (Future Sprints)

### Medium Priority

- [ ] Create `CategoriesViewModel` for `create_task_screen.dart`
- [ ] Add loading state aggregation (global spinner)
- [ ] Write integration tests for critical paths
- [ ] Add performance monitoring (Firebase Performance)

### Low Priority

- [ ] Consider offline caching strategy (Hive/SQLite)
- [ ] Add analytics events for user behavior tracking
- [ ] Optimize image loading (caching, lazy loading)
- [ ] Add feature flags for A/B testing

---

## 🏆 KEY PATTERNS TO FOLLOW

Based on this review, here are the patterns all future code should follow:

### 1. Service Layer with JOINs

```dart
// Always use JOINs for related data - see TaskService._selectWithProfile
static const String _selectWithProfile = '''
  ..., profiles!fk_name(full_name, avatar_url)
''';
```

### 2. ViewModel with Bool Returns

```dart
// Don't pass BuildContext - return success/failure
Future<bool> doSomething() async {
  try {
    await _repo.operation();
    return true;
  } catch (e) {
    _error = _mapError(e);
    return false;
  }
}
```

### 3. Error Mapping

```dart
// Map technical errors to user-friendly messages
String _mapError(dynamic error) {
  if (error.toString().contains('23505')) return 'Already exists';
  if (error.toString().contains('rls')) return 'Not allowed';
  return 'Something went wrong';
}
```

### 4. Cursor Pagination

```dart
// Use ISO timestamps, not offsets - see BookingViewModel
String? cursor = data.last.createdAt.toIso8601String();
```

### 5. Shared Caching

```dart
// Use SignedUrlCache for all signed URLs
final cached = SignedUrlCache.get(path);
if (cached != null) return cached;
```

### 6. Returning Data from Bottom Sheets

Always prefer returning data via `Navigator.pop(result)` from a bottom sheet rather than navigating forwards directly from the sheet's context.

**WRONG**:

```dart
// ❌ Navigation from sheet context (prone to disposed state crash)
void _submit() {
  Navigator.pop(context);
  Navigator.push(context, (ctx) => NextScreen(...)); // Error: potential crash if context invalid
}
```

**CORRECT**:

```dart
// ✅ Return data, let parent handle navigation
void _submit() {
  Navigator.pop(context, ResultData(...));
}

// In parent screen
final result = await showModalBottomSheet<ResultData>(...);
if (result != null && mounted) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => NextScreen(data: result)));
}
```

### 7. Permission-Gated Review UI

Never show review badges, counters, pinned sections, or CTAs from a raw delivered-state flag alone.

**WRONG**:

```dart
if (item.needsReview) {
  showNeedsReviewBadge();
}
```

**CORRECT**:

```dart
if (item.actionableNeedsReview) {
  showNeedsReviewBadge();
} else if (item.awaitingCounterpartyReview) {
  showAwaitingCounterpartyReviewBadge();
}
```

Use this rule anywhere `vw_unified_work_items.needs_review` is consumed. The DB view tells you the item is delivered; the app must still decide whether the current user is the reviewing side.

### 8. Coordinator Pattern for Cross-ViewModel Communication (v2.18)

When a global app event (like role switching) needs to affect multiple ViewModels, use the **Coordinator Pattern** instead of direct ViewModel-to-ViewModel references.

**Problem**: ProfileViewModel cannot access DashboardViewModel/ChatViewModel directly (different Provider branches, MVVM violation).

**Solution**: Use a singleton coordinator that ViewModels register with:

```dart
// lib/core/mixins/role_switch_aware.dart
mixin RoleSwitchAware {
  Future<void> teardownForRoleSwitch();
}

// lib/core/services/role_switch_coordinator.dart
class RoleSwitchCoordinator {
  void register(RoleSwitchAware vm) { ... }
  void unregister(RoleSwitchAware vm) { ... }
  Future<void> teardownAll() async {
    // Call teardown on all registered ViewModels
  }
}

// In ViewModels
class ChatViewModel extends ChangeNotifier with RoleSwitchAware {
  ChatViewModel() {
    RoleSwitchCoordinator().register(this);
  }
  
  @override
  Future<void> teardownForRoleSwitch() async {
    // Clear caches, disconnect channels
  }
  
  @override
  void dispose() {
    RoleSwitchCoordinator().unregister(this);
    super.dispose();
  }
}
```

**Benefits**:
- Maintains MVVM boundaries (no direct ViewModel references)
- Enables cross-cutting concerns (teardown, reset, refresh)
- Testable (mock coordinator)
- Type-safe (mixin interface)

---

## 📅 NEXT REVIEW

Schedule the next comprehensive code review in **March 2025** to:

- Verify continued compliance with patterns
- Review any new features added
- Assess testing coverage improvements
- Identify new optimization opportunities

---

## ✅ CONCLUSION

The SLine codebase is now **production-ready** with:

- ✅ Optimal database query patterns (no N+1)
- ✅ Clean MVVM architecture throughout
- ✅ Global error handling
- ✅ No code duplication
- ✅ Consistent logging patterns
- ✅ Strategic documentation

**Score Improvement**: 7.5/10 → 9/10

The remaining 1 point gap is primarily testing coverage, which should be addressed in future sprints.
