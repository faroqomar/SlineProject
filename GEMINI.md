# GEMINI.md

## 🤖 Active Agents (Invoke via @Name)
*The following agents are defined in the `Agents/` directory. When invoked, I will adopt their persona.*

*   **@Architect** (`Agents/Architect.md`): Technical Lead. Focus: Logic, MVVM, Refactoring, Database integrity.
    *   *Trigger:* "@Architect", "fix logic", "refactor".
*   **@Pixel** (`Agents/Pixel.md`): UI/UX Artist. Focus: Glassmorphism, Animations, Themes, Widgets.
    *   *Trigger:* "@Pixel", "design this", "make it pretty".
*   **@Supabase_Ops** (`Agents/Supabase_Ops.md`): Backend DBA. Focus: SQL, RLS, Edge Functions.
    *   *Trigger:* "@Supabase", "add table", "secure db".
*   **@Sentinel** (`Agents/Sentinel.md`): QA & Safety. Focus: Tests, Documentation, Analyzers.
    *   *Trigger:* "@Sentinel", "check this", "run tests".
*   **@SlineDocs** (`Agents/Sline_Docs.md`): Documentation Scribe. Focus: `Sline_everything` folder, Logs, Roadmap.
    *   *Trigger:* "@SlineDocs", "document this", "update changelog".
*   **@SlinePlanner** (`Agents/Sline_Planner.md`): Strategic Planner. Focus: Step-by-step implementation plans, Gap analysis.
    *   *Trigger:* "@SlinePlanner", "plan this feature", "how do I add...".

## Project Overview

This is a Flutter-based mobile application for a freelance marketplace called SLine. It connects clients with service providers, allowing them to post jobs, submit bids, and communicate in real-time. The backend is powered by Supabase, utilizing its database, authentication, and storage services. The app follows a strict MVVM (Model-View-ViewModel) architecture with a feature-based modular structure.

## Building and Running

### Prerequisites

*   Flutter SDK 3.8.1+
*   Dart SDK 3.8.1+
*   A Supabase account

### Installation and Setup

1.  **Clone the repository:**
    ```bash
    git clone <repository-url>
    cd sline_app
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Configure Supabase:**
    *   Create a new project on [supabase.com](https://supabase.com).
    *   Run the SQL schema from `Sline_everything/SUPABASE_SETUP.md`.
    *   Update `lib/core/services/supabase_config.dart` with your Supabase URL and anon key.

### Running the App

*   **To run the app on a connected device:**
    ```bash
    flutter run
    ```

*   **To list available devices:**
    ```bash
    flutter devices
    ```

*   **To run on a specific device:**
    ```bash
    flutter run -d <device_id>
    ```
    (e.g., `flutter run -d chrome`)

### Testing the App

*   **Run code analysis:**
    ```bash
    flutter analyze
    ```

*   **Run tests:**
    ```bash
    flutter test
    ```

## Development Conventions

*   **Architecture:** The project follows a strict Model-View-ViewModel (MVVM) pattern. The codebase is organized into feature-based modules.
*   **State Management:** `provider` is used for state management, following the `ChangeNotifier` pattern.
*   **Backend:** All backend services are provided by Supabase. Direct interaction with the Supabase client is encapsulated within the `repository/service` layer.
*   **Security:** Row-Level Security (RLS) is enabled on all database tables. File storage is kept in private buckets with access provided through signed URLs.
*   **Coding Style:**
    *   Code and comments are in English.
    *   `AppLogger` is used for logging instead of `print()`.
    *   Code should be lint-clean (`flutter analyze`) and formatted (`flutter format .`).
    *   Timestamps are stored in UTC and converted to local time in the UI.
    *   Pagination is implemented using cursors, not offsets.
    *   Error messages are mapped to be user-friendly.