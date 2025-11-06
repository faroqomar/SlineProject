# Repository Guidelines

## Project Layout & Key Files
SLine is a feature-first Flutter marketplace. Core bootstrap, theming, and shared widgets live in `lib/core/`, navigation shells in `lib/app/`, and every feature follows `lib/features/<feature>/{view,viewmodels,models,data,services}` with matching tests under `test/`. `lib/main.dart` registers providers (auth, chat, tasks, booking) and selects `MainNavigationScreen` or `LoginScreen` based on Supabase auth. `lib/core/services/supabase_config.dart` bootstraps the client—swap in environment keys before distributing builds. Reuse `SignedAvatar`/`SignedImage` for private-bucket media, route changes through `lib/app/main_navigation_screen.dart`, and keep the deep dives in `Sline_everything/DEVELOPER_GUIDE/` synced with code and schema updates.

## Tooling & Commands
```bash
flutter pub get                    # sync dependencies
flutter run -d <device_id>         # launch (list via flutter devices)
flutter analyze                    # honor flutter_lints analysis_options
flutter format .                   # enforce 2-space style
flutter test                       # run unit + widget suites
flutter build apk|ios|web          # produce release builds
```
Web deploys from `build/web`; Netlify rewrites all routes to `index.html`.

## Coding Standards & Patterns
- Use English identifiers, 2-space indentation, `snake_case.dart` files, `UpperCamelCase` types, and `lowerCamelCase` members.
- Views never touch Supabase; delegate to ChangeNotifier viewmodels/repositories, guard post-await UI code with `if (!mounted) return;`, and surface user-friendly errors.
- Replace `print` with `AppLogger` (logs respect `LogLevel` and only emit in debug). Persist storage paths, not signed URLs, and convert UTC timestamps in the view layer.
- Use feature helpers (e.g. `TaskImageService` caps five images) and keep business logic out of widgets. Bottom navigation uses `IndexedStack` + `NavigationProvider` with `CustomBottomNavBar`.

## Supabase & Security
- All tables enforce RLS—always operate under an authenticated session.
- Apply schema or policy changes via `Sline_everything/SUPABASE_SETUP.md`; note migrations in PRs and update feature docs.
- Respect server-side triggers guarding booking flows, offer validation, favorites-before-DM, and slot overlap prevention; mirror intent with client validation.
- Private buckets (`avatars`, `task-images`, `chat-attachments`) require short-lived signed URLs; portfolios remain public unless policies change.

## Testing & QA
- Unit-test repositories/services (mock Supabase) and ChangeNotifier state transitions; widget-test forms, realtime lists, and navigation.
- Run integration smoke tests whenever RLS, storage, or triggers shift. Name files `*_test.dart`, mirror production layout, and keep `flutter test` and `flutter analyze` green.

## Commits & PRs
- Use action-driven prefixes (`feat:`, `fix:`, `chore:`, `docs:`) such as `feat: tighten booking slot validation`.
- PRs should summarize the problem/solution, Supabase migrations, and doc updates.
- Paste recent `flutter test` / `flutter analyze` output, link roadmap issues, keep scope narrow, and sync relevant guides in `Sline_everything/`.
