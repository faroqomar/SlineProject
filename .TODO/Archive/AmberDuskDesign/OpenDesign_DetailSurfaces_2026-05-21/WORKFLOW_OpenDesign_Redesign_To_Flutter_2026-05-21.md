# Workflow: Open Design Redesign To Flutter Implementation

This workflow defines how Codex should handle a user-provided screenshot or
design-code file, send the design request through Open Design, wait for the
redesigned result, and implement the finished design in the target SLine
Flutter screen.

## Purpose

Use this workflow when the user provides:

- A screenshot of an existing SLine screen.
- A screenshot of an external design direction.
- A design-code file, HTML/JSX/CSS artifact, or Open Design project/file.
- A prompt asking to redesign, improve, polish, normalize, or adapt a target
  SLine screen.

The expected output is not just advice. Codex should drive the design loop,
pull the final Open Design artifact, implement it in the target Flutter view,
and verify the result.

## Non-Negotiable Boundaries

- Keep implementation in Flutter view/shared-widget/theme-token layers unless
  the user explicitly approves ViewModel, service, repository, Supabase, or
  schema work.
- Never call Supabase directly from a view.
- Use `AppColors`, `AppTypography`, `AppDimens`, `AppLayout`,
  `AppDecorations`, and `AppMotion`; do not introduce raw colors, raw font
  sizes, raw spacing, raw durations, or hardcoded shadows in feature views.
- Treat Open Design output as design reference, not runtime proof. Final
  visual completion still requires Flutter runtime screenshots or a clear
  manual visual evidence note.
- If Open Design uses unsupported patterns such as blur-backed glass,
  unlicensed fonts, or inaccessible contrast, adapt them to the approved SLine
  token system and record the decision.
- If the target data is not exposed by the ViewModel, document the missing
  contract. Do not add direct data fetches to the view.

## Intake Contract

Before editing code, record these facts in the work notes or run artifact:

- User prompt: the exact redesign/improvement request.
- Target screen: route, widget, feature folder, and current Flutter file path.
- Input source: screenshot path, attached image, design-code file, or Open
  Design project/file.
- Target device context: phone/web, width/height if known, theme mode, and
  relevant state such as loading, empty, error, authenticated, or unauthenticated.
- Acceptance target: pixel-close redesign, style improvement, density fix,
  component extraction, or token normalization.

If any item is unclear, infer it from the repo and screenshot first. Ask the
user only when the target screen or design intent cannot be safely inferred.

## Discovery Pass

1. Inspect git status and avoid overwriting unrelated dirty files.
2. Search for the target screen, widget class, route, and shared components
   with `rg`.
3. List all candidate Flutter files before editing.
4. Identify the owning layer:
   - Feature view file for screen-specific layout.
   - `lib/core/widgets/` for shared UI primitives.
   - `lib/core/theme/` or `lib/core/theme/designs/amber_dusk/` for token-level
     changes.
5. Identify focused tests that should be run after the implementation.

## Open Design Connection Strategy

Use the strongest available path in this order:

1. Open Design MCP active context:
   - Use `get_active_context` when the user says the design is already open.
   - Use `get_project`, `list_files`, `search_files`, and preferably
     `get_artifact` to pull the completed design bundle.
2. Open Design MCP explicit project:
   - Use a project UUID or name substring when the user provides one.
   - Prefer `get_artifact(include: "auto")` over many separate file reads.
3. Open Design app through Computer Use:
   - Use this when MCP can read projects but cannot directly create, prompt, or
     upload the screenshot.
   - Drive the local app UI: open the project, attach or reference the
     screenshot/design-code input, paste the user prompt, start the redesign,
     and wait until the app reports completion.
4. User-assisted fallback:
   - If neither MCP nor app automation can submit the prompt, ask the user to
     run the prompt in Open Design and leave the finished design open. Then pull
     it with MCP active context.

Record which route was used and the Open Design project/file names or IDs.

## Prompt Sent To Open Design

Use the user's wording, but add implementation constraints so the output can be
translated safely into SLine:

```text
Redesign or improve the provided screen for the SLine Flutter app.

User request:
<paste exact user prompt>

Target screen:
<route/widget/file/state>

Constraints:
- Preserve the screen's actual product function and information hierarchy.
- Use SLine's existing token system and Flutter component boundaries.
- Avoid unsupported glass/blur/backdrop effects unless explicitly requested.
- Keep text legible at phone sizes and avoid overlap.
- Provide a concrete layout with colors, typography, spacing, states, and
  component structure that can be implemented in Flutter.
```

If the request is a strict match to a screenshot, ask Open Design for a
pixel-close treatment. If it is an improvement request, ask for a revised
composition plus the reasons for the changes.

## Waiting And Polling

After submitting the Open Design prompt:

1. Wait for the app to finish rather than switching immediately to code.
2. Poll with `list_files(since: <timestamp>)` or `get_active_context` when MCP
   is available.
3. Re-run `get_artifact` after completion and save the high-signal output in
   notes:
   - Entry file.
   - Referenced CSS/JSX/design-token files.
   - Screenshot/export paths if available.
   - Any generated design-system or skill notes.
4. If completion is ambiguous, inspect the app UI with Computer Use or ask the
   user to confirm the design is finished.

## Translation To Flutter

Use the completed Open Design artifact as a reference and adapt it to the
current SLine architecture:

1. Map design sections to existing Flutter widgets and shared components.
2. Reuse existing ViewModel state and models.
3. Prefer small view-layer edits over new abstractions.
4. Extract a shared widget only when multiple existing surfaces need the same
   component.
5. Convert raw design values to SLine tokens:
   - Colors to `AppColors` or `context.colorScheme`.
   - Type to `AppTypography`.
   - Spacing/radii/sizes to `AppDimens` or `AppLayout`.
   - Shadows to `AppDecorations.elevation`.
   - Motion to `AppMotion`.
6. Preserve accessibility, text scaling, empty/loading/error states, and
   localization constraints.

## Implementation Gate

Before applying edits, state the exact files that will be changed. Then:

1. Edit only the identified files.
2. Keep comments useful and focused on why non-obvious layout/token decisions
   were made.
3. Do not modify business logic unless a documented data contract gap makes it
   unavoidable and the user approves it.
4. Do not touch unrelated dirty files.

## Verification Gate

Run verification proportional to the touched surface:

- `dart format <changed dart files>`
- Focused widget/unit tests for the touched screen or shared widget.
- `flutter analyze --no-fatal-infos`
- `git diff --check`
- Runtime screenshot/manual visual QA when a visual parity claim is made.

For visual work, final notes must distinguish:

- Open Design reference proof.
- Flutter implementation proof.
- Runtime screenshot/manual QA proof.
- Remaining states that still need screenshots or exact Open Design evidence.

## Run Artifact Template

For substantial redesign work, create a run folder:

```text
.TODO/OpenDesign_Redesign_Run_<screen>_<yyyy-mm-dd>/
  00_INPUT.md
  01_DISCOVERY.md
  02_OPEN_DESIGN_OUTPUT.md
  03_IMPLEMENTATION_NOTES.md
  04_VERIFICATION.md
  screenshots/
```

Small one-screen fixes may use a concise note in the final response instead,
but the same gates still apply.

## Completion Response

The final response should include:

- What Open Design input/output was used.
- Which Flutter files changed.
- What verification passed.
- Any visual QA or missing-state caveat.
- Any user action needed only if a real blocker remains.
