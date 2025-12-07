# 🛠️ SLine Development Workflow & Protocols

**Version**: 1.0
**Objective**: Standardized, error-free execution of features, designs, and refactors using the SLine Agent System.

---

## 🚦 1. The "Start Here" Checklist
**Before writing a single line of code**, identify the type of task and follow the protocol.

### 🆕 Type A: New Feature (e.g., "Add Wallet System")
1.  **Invoke @SlinePlanner**: Ask for a "Gap Analysis" and "Implementation Plan".
    *   *Prompt:* "@SlinePlanner Plan the Wallet feature. Check `SUPABASE_SETUP.md` for existing tables."
2.  **Invoke @Supabase_Ops**: Apply database changes first.
    *   *Prompt:* "@Supabase_Ops Create the SQL migration for the Wallet tables based on the plan."
3.  **Invoke @Architect**: Define the Core Layer (Model/Service/ViewModel).
    *   *Prompt:* "@Architect Scaffold the Wallet MVVM structure in `lib/features/wallet/`."
4.  **Invoke @Pixel**: Build the UI.
    *   *Prompt:* "@Pixel Create the `WalletScreen` using `GlassContainer` and the new theme."
5.  **Invoke @Sentinel**: Verify and Document.
    *   *Prompt:* "@Sentinel Audit the new feature for RLS security and update `Sline_Log.md`."

### 🎨 Type B: New Design / UI Overhaul
1.  **Invoke @Pixel**: Analyze the design source (e.g., React/Tailwind).
    *   *Prompt:* "@Pixel Map the colors and spacing from `.TODO/New_Design_Code` to `lib/core/theme/`."
2.  **Invoke @Pixel**: Implement "Dumb" Widgets first.
    *   *Prompt:* "@Pixel Create the `GlassCard` widget in `lib/core/widgets/`."
3.  **Invoke @Architect**: Connect Logic.
    *   *Prompt:* "@Architect Bind `HomeViewModel` to the new `HomeView`."

### 🐛 Type C: Bug Fix / Refactor
1.  **Invoke @Sentinel**: Reproduce the issue (Mental or Test).
    *   *Prompt:* "@Sentinel Analyze `task_service.dart` for N+1 query issues."
2.  **Invoke @Architect**: Apply the fix.
    *   *Prompt:* "@Architect Refactor `getTasks` to use a JOIN query."
3.  **Invoke @SlineDocs**: Update documentation.
    *   *Prompt:* "@SlineDocs Log this fix in `Sline_Log.md`."

---

## 🤖 Agent Roster & Responsibilities

| Agent | Handle | Trigger When... | Output |
| :--- | :--- | :--- | :--- |
| **Planner** | `@SlinePlanner` | You have a vague idea or complex request. | Step-by-step `.md` Plan. |
| **Architect** | `@Architect` | You need Logic, State, Models, or Services. | Dart code (MVVM). |
| **Pixel** | `@Pixel` | You need Screens, Widgets, Animations, or Themes. | Flutter UI code. |
| **Database** | `@Supabase_Ops` | You need Tables, RLS, SQL, or Triggers. | SQL scripts. |
| **QA/Docs** | `@Sentinel` | You need Tests, Security Checks, or Final Review. | Analysis or Test code. |
| **Scribe** | `@SlineDocs` | You finished a task. | Updates to `Sline_everything/`. |

---

## 📜 Critical Rules (The "Constitution")

1.  **Database First**: Never write Flutter code for data that doesn't exist in Supabase yet.
2.  **Theme Compliance**: UI must use `AppTheme.of(context)`, never hardcoded colors.
3.  **MVVM Strictness**: UI Widgets (`View`) never talk to `Services` directly. They talk to `ViewModels`.
4.  **Doc Sync**: If you change the code, you **MUST** update `Sline_everything/`.
5.  **English Only**: All code, comments, and commits must be in English.

---

## 🚀 Execution Example: "Add Dark Mode"

1.  **User:** "I want to add Dark Mode."
2.  **@Pixel:** "I will update `app_theme.dart` to include a `darkTheme` definition mapping our teal/gold colors to dark variants." (Writes code)
3.  **@Architect:** "I will update `ProfileViewModel` to toggle `ThemeMode` and persist it in `SharedPreferences`." (Writes code)
4.  **@SlineDocs:** "Updating `DEVELOPER_GUIDE.md` to mention Theme support." (Writes docs)
5.  **Done.**
