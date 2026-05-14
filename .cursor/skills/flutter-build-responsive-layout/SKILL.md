---
name: flutter-build-responsive-layout
description: Use `LayoutBuilder`, `MediaQuery`, or `Expanded/Flexible` to create a layout that adapts to different screen sizes. Use when you need the UI to look good on both mobile and tablet/desktop form factors.
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Tue, 21 Apr 2026 20:17:40 GMT
---
# Implementing Adaptive Layouts
## SLine Project Overrides

These upstream Flutter/Dart instructions are adapted for SLine. Apply these rules before the generic workflow:

- Preserve SLine's strict MVVM boundary: Views render state and call ViewModels; ViewModels call services/repositories; services own Supabase, storage, realtime, and payment access.
- Do not put Supabase, RPC, storage, business rules, or navigation side effects directly in `lib/features/*/view/` widgets. If a View needs data the ViewModel does not expose, document the gap or extend the ViewModel/service layer.
- Prefer existing project patterns over new dependencies: Provider state management, manual `fromJson`/`toJson`/`copyWith`, `ViewState<T>` for new complex VMs, `AppLogger`, `AppFailure`, `ErrorMapper`, `AppMotion`, `AppColors`, `AppTypography`, `AppDimens`, `AppLayout`, and shared widgets under `lib/core/widgets/`.
- Do not introduce `build_runner`, `freezed`, generated mocks, `go_router`, `http`, or new architecture packages unless the user explicitly asks and the repo evidence supports it.
- Before implementation, search related feature files with `rg`, then keep changes scoped to the target feature or shared layer. Preserve unrelated user changes in the dirty worktree.
- After meaningful code changes, run `dart format` on touched Dart files, `flutter analyze --no-fatal-infos`, and focused `flutter test` targets. Run the full suite when shared behavior or cross-feature contracts changed.

### SLine Layout Notes

Use SLine design tokens for spacing, typography, motion, and dimensions. Components should not hardcode colors, font sizes, durations, padding, avatar sizes, card heights, or shadows. Keep phone-first behavior compatible with the existing five-tab shell and hidden detail routes.

## Contents
- [Space Measurement Guidelines](#space-measurement-guidelines)
- [Widget Sizing and Constraints](#widget-sizing-and-constraints)
- [Device and Orientation Behaviors](#device-and-orientation-behaviors)
- [Workflow: Constructing an Adaptive Layout](#workflow-constructing-an-adaptive-layout)
- [Workflow: Optimizing for Large Screens](#workflow-optimizing-for-large-screens)
- [Examples](#examples)

## Space Measurement Guidelines
Determine the available space accurately to ensure layouts adapt to the app window, not just the physical device.

*   **Use `MediaQuery.sizeOf(context)`** to get the size of the entire app window.
*   **Use `LayoutBuilder`** to make layout decisions based on the parent widget's allocated space. Evaluate `constraints.maxWidth` to determine the appropriate widget tree to return.
*   **Do not use `MediaQuery.orientationOf` or `OrientationBuilder`** near the top of the widget tree to switch layouts. Device orientation does not accurately reflect the available app window space.
*   **Do not check for hardware types** (e.g., "phone" vs. "tablet"). Flutter apps run in resizable windows, multi-window modes, and picture-in-picture. Base all layout decisions strictly on available window space.

## Widget Sizing and Constraints
Understand and apply Flutter's core layout rule: **Constraints go down. Sizes go up. Parent sets position.**

*   **Distribute Space:** Use `Expanded` and `Flexible` within `Row`, `Column`, or `Flex` widgets.
    *   Use `Expanded` to force a child to fill all remaining available space (equivalent to `Flexible` with `fit: FlexFit.tight` and a `flex` factor of 1.0).
    *   Use `Flexible` to allow a child to size itself up to a specific limit while still expanding/contracting. Use the `flex` factor to define the ratio of space consumption among siblings.
*   **Constrain Width:** Prevent widgets from consuming all horizontal space on large screens. Wrap widgets like `GridView` or `ListView` in a `ConstrainedBox` or `Container` and define a `maxWidth` in the `BoxConstraints`.
*   **Lazy Rendering:** Always use `ListView.builder` or `GridView.builder` when rendering lists with an unknown or large number of items.

## Device and Orientation Behaviors
Ensure the app behaves correctly across all device form factors and input methods.

*   **Do not lock screen orientation.** Locking orientation causes severe layout issues on foldable devices, often resulting in letterboxing (the app centered with black borders). Android large format tiers require both portrait and landscape support.
*   **Fallback for Locked Orientation:** If business requirements strictly mandate a locked orientation, use the `Display API` to retrieve physical screen dimensions instead of `MediaQuery`. `MediaQuery` fails to receive the larger window size in compatibility modes.
*   **Support Multiple Inputs:** Implement support for basic mice, trackpads, and keyboard shortcuts. Ensure touch targets are appropriately sized and keyboard navigation is accessible.

## Workflow: Constructing an Adaptive Layout

Follow this workflow to implement a layout that adapts to the available `BoxConstraints`.

**Task Progress:**
- [ ] Identify the target widget that requires adaptive behavior.
- [ ] Wrap the widget tree in a `LayoutBuilder`.
- [ ] Extract the `constraints.maxWidth` from the builder callback.
- [ ] Define an adaptive breakpoint (e.g., `largeScreenMinWidth = 600`).
- [ ] **If `maxWidth > largeScreenMinWidth`:** Return a large-screen layout (e.g., a `Row` placing a navigation sidebar and content area side-by-side).
- [ ] **If `maxWidth <= largeScreenMinWidth`:** Return a small-screen layout (e.g., a `Column` or standard navigation-style approach).
- [ ] Run validator -> resize the application window -> review layout transitions -> fix overflow errors.

## Workflow: Optimizing for Large Screens

Follow this workflow to prevent UI elements from stretching unnaturally on large displays.

**Task Progress:**
- [ ] Identify full-width components (e.g., `ListView`, text blocks, forms).
- [ ] **If optimizing a list:** Convert `ListView.builder` to `GridView.builder` using `SliverGridDelegateWithMaxCrossAxisExtent` to automatically adjust column counts based on window size.
- [ ] **If optimizing a form or text block:** Wrap the component in a `ConstrainedBox`.
- [ ] Apply `BoxConstraints(maxWidth: [optimal_width])` to the `ConstrainedBox`.
- [ ] Wrap the `ConstrainedBox` in a `Center` widget to keep the constrained content centered on large screens.
- [ ] Run validator -> test on desktop/tablet target -> review horizontal stretching -> adjust `maxWidth` or grid extents.

## Examples

### Adaptive Layout using LayoutBuilder
Demonstrates switching between a mobile and desktop layout based on available width.

```dart
import 'package:flutter/material.dart';

const double largeScreenMinWidth = 600.0;

class AdaptiveLayout extends StatelessWidget {
  const AdaptiveLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > largeScreenMinWidth) {
          return _buildLargeScreenLayout();
        } else {
          return _buildSmallScreenLayout();
        }
      },
    );
  }

  Widget _buildLargeScreenLayout() {
    return Row(
      children: [
        const SizedBox(width: 250, child: Placeholder(color: Colors.blue)),
        const VerticalDivider(width: 1),
        Expanded(child: const Placeholder(color: Colors.green)),
      ],
    );
  }

  Widget _buildSmallScreenLayout() {
    return const Placeholder(color: Colors.green);
  }
}
```

### Constraining Width on Large Screens
Demonstrates preventing a widget from consuming all horizontal space.

```dart
import 'package:flutter/material.dart';

class ConstrainedContent extends StatelessWidget {
  const ConstrainedContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 800.0, // Maximum width for readability
          ),
          child: ListView.builder(
            itemCount: 50,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text('Item $index'),
              );
            },
          ),
        ),
      ),
    );
  }
}
```
