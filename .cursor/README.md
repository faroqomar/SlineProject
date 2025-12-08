# Cursor Configuration for SLine

This directory contains Cursor AI configuration files that help Cursor understand the SLine Flutter app architecture and conventions.

## How Cursor Uses These Files

### Automatic Rule Application

Cursor automatically applies rules based on:

1. **`.cursorrules`** (root directory) - Always active, fallback reference
2. **`.cursor/rules/*.mdc`** - Context-specific rules:
   - `project-rules.mdc` - Always active (`alwaysApply: true`)
   - `flutter-mvvm.mdc` - Applied to all `.dart` files
   - `supabase-database.mdc` - Applied to service/data files
   - `ui-theme.mdc` - Applied to view/widget files
   - `error-handling.mdc` - Applied to all Dart files
   - `code-quality.mdc` - Applied to all Dart files

### Agent System

Agents in `.cursor/Agents/` can be invoked using triggers:
- `@Architect` - Logic and architecture
- `@Pixel` - UI and design
- `@Supabase_Ops` - Database operations
- `@Sentinel` - QA and security
- `@SlineDocs` - Documentation
- `@SlinePlanner` - Planning

See `GEMINI.md` for complete agent definitions.

## Verification

To verify Cursor is using these rules:

1. **Ask Cursor**: "What are the project rules?" - It should reference these files
2. **Check Context**: Cursor should mention MVVM, AppColors, AppLogger automatically
3. **Test Agent**: Try "@Architect help me refactor this" - Should reference rules

## File Structure

```
.cursor/
├── rules/              # Rule files (.mdc)
│   ├── project-rules.mdc      # Always active
│   ├── flutter-mvvm.mdc       # Dart files
│   ├── supabase-database.mdc  # Service files
│   ├── ui-theme.mdc           # View files
│   ├── error-handling.mdc     # All Dart
│   └── code-quality.mdc       # All Dart
├── Agents/             # Agent definitions
│   ├── Architect.md
│   ├── Pixel.md
│   ├── Supabase_Ops.md
│   ├── Sentinel.md
│   ├── Sline_Docs.md
│   └── Sline_Planner.md
├── PROJECT_CONTEXT.md  # Quick reference
└── README.md          # This file
```

## Troubleshooting

If Cursor isn't referencing rules:

1. **Check `.cursorrules` exists** in root directory
2. **Verify rule files** have correct frontmatter (`alwaysApply: true` for project-rules)
3. **Restart Cursor** to reload rules
4. **Explicitly mention**: "Follow the rules in `.cursor/rules/`"

## Documentation References

All rules reference documentation in:
- `GEMINI.md` - Project overview
- `Sline_everything/` - Complete documentation
- `.cursor/PROJECT_CONTEXT.md` - Quick reference

