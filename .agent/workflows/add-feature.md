---
description: Comprehensive workflow to add a new feature with strict MVVM, detailed planning, and multi-agent collaboration.
---

# Feature Implementation Workflow

This workflow ensures every feature is planned to perfection before a single line of code is written, then implemented using the specialized SLine Agent System.

**Prerequisites:**
- Read `GEMINI.md` to understand the Agent System.
- Read `Sline_everything/MVP_ROADMAP.md` to confirm feature scope.

---

## Phase 0: Strategic Planning (CRITICAL)

**Goal:** Create a perfect, step-by-step implementation plan.
**Agent:** `@SlinePlanner` (`.agent/workflows/slineplanner.md`)

1.  **Analyze Context**:
    -   Read `Sline_everything/SUPABASE_SETUP.md` (Database Truth).
    -   Read `Sline_everything/DEVELOPER_GUIDE.md` (Pattern Truth).
    -   Read `Sline_everything/STRUCTURE.md` (File Layout).
    -   Read `Sline_everything/MVP_ROADMAP.md` (Feature Status).

2.  **Draft Implementation Plan**:
    -   Create a new file: `.TODO/Future_Plans/[feature_name]_plan.md`.
    -   The plan **MUST** follow the structure in `@SlinePlanner`.
    -   **Include specific Agent assignments** for each step (e.g., "Step 1: Database - Assigned to @Supabase_Ops").

3.  **Verify Plan**:
    -   Does it handle RLS?
    -   Does it prevent N+1 queries?
    -   Does it use the Glassmorphism theme?
    -   Are all file paths absolute and correct?

---

## Phase 1: Database & Backend (if needed)

**Goal:** robust data foundation with RLS and Security.
**Agent:** `@Supabase_Ops` (`.agent/workflows/supabase.md`)
**Tools**: `@mcp:supabase-mcp-server`

1.  **Schema execution**: (if needed)
    -   Write SQL for tables, enums, and indexes.
    -   Apply RLS policies strictly (deny by default).
    -   Use `apply_migration` or `execute_sql` via Supabase MCP.
    -   **Verify**: Use `list_tables` and `execute_sql` to confirm creation.

2.  **Storage Buckets** (if needed):
    -   Create private buckets for user content.
    -   Set RLS for optional public access (e.g., portfolios).

3.  **Edge Functions** (if needed):
    -   Deploy using `deploy_edge_function`.

---

## Phase 2: Data Layer (Models & Services) (if needed)

**Goal:** Type-safe data access with no logic leaks.
**Agent:** `@Architect` (`.agent/workflows/architect.md`)
**Tools**: `@mcp:dart-mcp-server`

1.  **Models**:
    -   Create `lib/features/[feature]/models/[feature]_model.dart`.
    -   Ensure `immutable` classes.
    -   Implement `fromJson`/`toJson` with safe parsing.
    -   **Rule**: Use UTC for all `DateTime` fields.

2.  **Services**:
    -   Create `lib/features/[feature]/services/[feature]_service.dart`.
    -   Implement methods matching the plan.
    -   **Rule**: Use `.select('*, related!inner(*)')` for JOINs to prevent N+1 issues.
    -   **Rule**: Use `AppLogger` for all errors.

---

## Phase 3: Business Logic (MVVM)

**Goal:** Clean state management and UI separation.
**Agent:** `@Architect` (`.agent/workflows/architect.md`)

1.  **ViewModel**:
    -   Create `lib/features/[feature]/viewmodels/[feature]_view_model.dart`.
    -   Extend `ChangeNotifier`.
    -   Inject `Service` via constructor.
    -   Handle `isLoading`, `error`, and data states.
    -   **Rule**: Never expose mutable lists (use `UnmodifiableListView`).

2.  **Registration**:
    -   Register the strictly typed Provider in `lib/main.dart` or local scope.

---

## Phase 4: UI & UX Design (if needed)

**Goal:** "Wowed" user experience with specific SLine Aesthetics.
**Agent:** `@Pixel` (`.agent/workflows/pixel.md`)

1.  **Screens**:
    -   Create `lib/features/[feature]/view/[feature]_screen.dart`.
    -   Use `Consumer<ViewModel>` for reactive builds.
    -   **Design**: Implement "Liquid Glass" aesthetics using `GlassContainer`.
    -   **Colors**: strict usage of `AppColors` and `AppTheme` (No hardcoded hex).

2.  **Components**:
    -   Break down complex UIs into widgets in `view/widgets/`.
    -   Add micro-animations (hero, fade-ins, scale buttons).

---

## Phase 5: Verification & Documentation

**Goal:** Zero regressions and up-to-date truth.
**Agents:** `@Sentinel`, `@SlineDocs`
**Tools**: `@mcp:dart-mcp-server`

1.  **Testing**:
    -   Run `dart fix --apply`.
    -   Run `flutter analyze`.
    -   Manual verification of the flow.

2.  **Documentation Update**:
    -   Update `Sline_everything/SUPABASE_SETUP.md` with new schema.
    -   Update `Sline_everything/DEVELOPER_GUIDE.md` with new feature details.
    -   Mark feature as 'Completed' in `MVP_ROADMAP.md`.

---

## How to execute this workflow

1.  **Initialization**: "Compiling feature request..."
2.  **Planning**: Execute **Phase 0** to generate the plan file.
3.  **Approval**: Ask user to review `.TODO/Future_Plans/[feature]_plan.md`.
4.  **Execution**: Proceed sequentially through Phases 1-5, checking off items in the plan file.