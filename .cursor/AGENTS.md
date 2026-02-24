# SLine Agents (Cursor)

All agents and workflows live under **`.cursor/`**. Always prefer these over `.agent/` when invoking or following workflows.

## Quick reference

| Invoke | File | Use for |
|--------|------|--------|
| @Architect | [Agents/Architect.md](Agents/Architect.md) | Logic, MVVM, refactoring |
| @Pixel | [Agents/Pixel.md](Agents/Pixel.md) | UI, theme, glassmorphism |
| @Supabase_Ops | [Agents/Supabase_Ops.md](Agents/Supabase_Ops.md) | Schema, RLS, SQL, storage |
| @Sentinel | [Agents/Sentinel.md](Agents/Sentinel.md) | QA, security, release gate |
| @SlineDocs | [Agents/Sline_Docs.md](Agents/Sline_Docs.md) | Docs, changelog, Sline_everything |
| @SlinePlanner | [Agents/Sline_Planner.md](Agents/Sline_Planner.md) | Implementation plans |
| @CodeGuard | [Agents/CodeGuard.md](Agents/CodeGuard.md) | Code review, performance, security |
| @Executor | [Agents/Executor.md](Agents/Executor.md) | Execute plans from .TODO/ |
| @PlanCritic | [Agents/Plan_Critic.md](Agents/Plan_Critic.md) | Audit and harden plans |
| @Observability | [Agents/Observability.md](Agents/Observability.md) | Logging, metrics, telemetry |
| @APIContract | [Agents/APIContract.md](Agents/APIContract.md) | Contracts, DTOs, API shapes |
| @DataMigration | [Agents/DataMigration.md](Agents/DataMigration.md) | Schema migration, compatibility |
| @ThreatModeler | [Agents/ThreatModeler.md](Agents/ThreatModeler.md) | Security design, abuse cases |

## Rules and context

- **Rules**: `.cursor/rules/*.mdc` — project and file-specific rules (MVVM, code quality, error handling, theme, Supabase, etc.).
- **Context**: [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md) — architecture, conventions, doc links.
- **Prompt**: [prompt.md](prompt.md) — how to use workflows and agents for new features.

## Skills (project-local)

Skills live under `.cursor/skills/` and reference `.cursor/rules/` and `.cursor/Agents/`:

- `architecture-guard` — MVVM boundaries
- `asset-manager` — assets and pubspec
- `code-reviewer` — structured code review
- `crud-generator` — List/Detail/Form screens
- `docs-sync` — keep docs aligned with code
- `feature-scaffolder` — new feature layout
- `bug-fixer` — triage and fix workflow
- `commit-helper` — conventional commits
- `supabase-migration` — migrations and RLS

When working on SLine, **always reference @.cursor** (rules, agents, PROJECT_CONTEXT, prompt).
