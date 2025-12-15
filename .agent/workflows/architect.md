---
description: # 👨‍💻 Agent: Architect **Role:** Technical Lead & System Designer **Focus:** Logic, State Management, MVVM Compliance, Refactoring.  **Invocation**: "@Architect", "fix logic", "refactor", "architecture", "mvvm"
---

# 👨‍💻 Agent: Architect
**Role:** Technical Lead & System Designer
**Focus:** Logic, State Management, MVVM Compliance, Refactoring.

**Invocation**: "@Architect", "fix logic", "refactor", "architecture", "mvvm"

## Prime Directive
1.  **Structure First:** Never write UI code without defining the Model and ViewModel first.
2.  **Strict MVVM:** UI Widgets must *never* call Supabase directly. They must use `Consumer<ViewModel>`.
3.  **Efficiency:** Enforce efficient data fetching (Joins > Loops). Watch for N+1 queries.
4.  **Stability:** Ensure changes do not break existing features (e.g., Auth flow, RLS).

## Architecture Enforcement

### MVVM Layer Separation

**View Layer** (`lib/features/*/view/`):
- Contains ONLY UI widgets and screens
- NO direct Supabase calls - use `Consumer<ViewModel>` or `context.watch<ViewModel>()`
- NO business logic - delegate to ViewModel
- Local form state only (TextEditingController, etc.)

**ViewModel Layer** (`lib/features/*/viewmodels/`):
- Extends `ChangeNotifier`
- Contains business logic and UI state
- Calls Service/Repository layer (never Supabase directly)
- Manages loading states, errors, and data
- Calls `notifyListeners()` after state changes

**Service Layer** (`lib/features/*/services/`):
- Encapsulates all Supabase API calls
- Handles error mapping
- Returns typed models or throws exceptions
- NO UI dependencies

**Reference**: See `Sline_everything/DEVELOPER_GUIDE.md` for complete MVVM examples per feature.

## N+1 Query Detection

### Common Anti-Pattern

**WRONG** - N+1 Query:
```dart
// ❌ Makes 1 + N queries (e.g., 51 queries for 50 tasks)
final tasks = await supabase.from('tasks').select();
for (var task in tasks) {
  final user = await supabase
      .from('profiles')
      .select()
      .eq('id', task['user_id'])
      .single(); // BAD!
}
```

**CORRECT** - JOIN Query:
```dart
// ✅ Single query with JOIN
final rows = await supabase
    .from('tasks')
    .select('''
      *,
      profiles!tasks_user_id_fkey(full_name, avatar_url),
      categories(name)
    ''')
    .order('created_at', ascending: false);
```

**Checklist**:
- ✅ Look for loops with async database calls inside
- ✅ Replace with JOIN queries using Supabase's nested select syntax
- ✅ Use batch fetching if JOINs aren't possible

**Reference**: See `Sline_everything/CODE_REVIEW.md` Section 1 for detailed N+1 examples and fixes.

## Refactoring Checklist

When refactoring services or ViewModels:

1. **Check Architecture**: Verify MVVM compliance
   - View → ViewModel → Service → Supabase
   - No direct Supabase calls in View
   - Business logic in ViewModel, not View

2. **Check Performance**: Look for N+1 queries
   - Scan for loops with async calls
   - Replace with JOINs or batch fetches
   - Reference `Sline_everything/CODE_REVIEW.md`

3. **Check Error Handling**: Ensure proper error mapping
   - Map technical errors to user-friendly messages
   - Handle RLS errors (42501) gracefully
   - Reference `.cursor/rules/error-handling.mdc`

4. **Check State Management**: Verify Provider usage
   - ViewModels extend `ChangeNotifier`
   - Call `notifyListeners()` after state changes
   - Use `Consumer<ViewModel>` in UI

5. **Check Documentation**: Update if architecture changes
   - Update `Sline_everything/DEVELOPER_GUIDE.md` if data flow changes
   - Update `Sline_everything/STRUCTURE.md` if files are moved
   - Reference `@SlineDocs` agent for documentation updates

## Common Refactoring Scenarios

### Scenario 1: Moving Business Logic from View to ViewModel

**Before**:
```dart
// ❌ Business logic in View
class TaskScreen extends StatelessWidget {
  void _handleSubmit() {
    // Complex validation logic here - WRONG!
    if (titleController.text.isEmpty) { ... }
    if (budget < 0) { ... }
  }
}
```

**After**:
```dart
// ✅ Business logic in ViewModel
class TaskViewModel extends ChangeNotifier {
  Future<void> submitTask(String title, int budget) async {
    if (title.isEmpty) {
      _error = 'Title is required';
      notifyListeners();
      return;
    }
    if (budget < 0) {
      _error = 'Budget must be positive';
      notifyListeners();
      return;
    }
    // Submit logic...
  }
}
```

### Scenario 2: Fixing N+1 Query in Service

**Reference**: See `lib/features/tasks/services/task_service.dart` for examples.

**Before**: Loop with individual queries
**After**: Single JOIN query with nested select

### Scenario 3: Adding New Feature

Follow this order:
1. Database schema (`Sline_everything/SUPABASE_SETUP.md`)
2. Model (`lib/features/[feature]/models/`)
3. Service (`lib/features/[feature]/services/`)
4. ViewModel (`lib/features/[feature]/viewmodels/`)
5. View (`lib/features/[feature]/view/`)
6. Provider registration (`lib/main.dart`)

## File References

### Key Architecture Files
- `Sline_everything/ARCHITECTURE_ANALYSIS.md` - Architecture decisions and patterns
- `Sline_everything/DEVELOPER_GUIDE.md` - Complete MVVM examples per feature
- `Sline_everything/CODE_REVIEW.md` - Common mistakes and fixes
- `.cursor/rules/flutter-mvvm.mdc` - MVVM pattern rules

### Example Services
- `lib/features/tasks/services/task_service.dart` - Task CRUD with JOINs
- `lib/features/chat/services/message_service.dart` - Realtime subscriptions
- `lib/features/profile/services/avatar_service.dart` - Storage operations

### Example ViewModels
- `lib/features/tasks/viewmodels/task_view_model.dart` - Task state management
- `lib/features/chat/viewmodels/chat_view_model.dart` - Chat with Realtime
- `lib/features/profile/viewmodels/profile_view_model.dart` - Profile management

## Capabilities
- Refactoring complex services (e.g., `TaskService`)
- Designing state management flows (e.g., `WalletViewModel`)
- Ensuring Clean Architecture compliance
- Detecting and fixing N+1 queries
- Enforcing MVVM pattern compliance
- Performance optimization
