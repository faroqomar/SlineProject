# SLine Agents (Cursor)

All agents and workflows live under **`.cursor/`**. Always prefer these over `.agent/` when invoking or following workflows.

## Quick Reference

| Invoke | File | Use for |
|--------|------|--------|
| `@Architect` | [Agents/Architect.md](Agents/Architect.md) | Logic, MVVM, refactoring |
| `@UIDesigner` | [Agents/UIDesigner.md](Agents/UIDesigner.md) | UI, theme, interaction, motion |
| `@BackendOps` | [Agents/BackendOps.md](Agents/BackendOps.md) | Schema, RLS, SQL, RPC, storage |
| `@QA` | [Agents/QA.md](Agents/QA.md) | QA, security, release gate |
| `@DocsKeeper` | [Agents/DocsKeeper.md](Agents/DocsKeeper.md) | Docs, changelog, Sline_everything sync |
| `@Planner` | [Agents/Planner.md](Agents/Planner.md) | Implementation plans |
| `@CodeReviewer` | [Agents/CodeReviewer.md](Agents/CodeReviewer.md) | Code review, performance, security |
| `@Executor` | [Agents/Executor.md](Agents/Executor.md) | Execute plans from `.TODO/` |
| `@PlanCritic` | [Agents/PlanCritic.md](Agents/PlanCritic.md) | Audit and harden plans |
| `@Observability` | [Agents/Observability.md](Agents/Observability.md) | Logging, metrics, telemetry |
| `@APIContract` | [Agents/APIContract.md](Agents/APIContract.md) | Contracts, DTOs, API shapes |
| `@DataMigration` | [Agents/DataMigration.md](Agents/DataMigration.md) | Schema migration, compatibility |
| `@SecurityAuditor` | [Agents/SecurityAuditor.md](Agents/SecurityAuditor.md) | Security design, abuse cases |
| `@TemplateOwner` | [Agents/TemplateOwner.md](Agents/TemplateOwner.md) | Task templates and reusable blueprint ownership |
| `@Orchestrator` | [Agents/Orchestrator.md](Agents/Orchestrator.md) | Multi-agent review pipeline |
| `@SystemEvolution` | [Agents/SystemEvolution.md](Agents/SystemEvolution.md) | Session-log analysis and agent-system improvement |

## Rules And Context

- **Rules**: `.cursor/rules/*.mdc` — project and file-specific rules (MVVM, code quality, error handling, theme, Supabase, etc.).
- **Context**: [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md) — architecture, conventions, doc links.
- **Prompt**: [prompt.md](prompt.md) — how to use workflows and agents for new features.
- **Session Logs**: `docs/LOG/SESSION_<PLAN_NAME>_<YYYY-MM-DD>.md` — append-only execution history for every plan.
- **Feature Diagrams**: `docs/diagrams/<FeatureName>.md` — Mermaid diagrams plus explanations for schema, order flow, and backend process flow.

## Skills (Project-Local)

Skills live under `.cursor/skills/` and reference `.cursor/rules/` and `.cursor/Agents/`.

- `architecture-guard` — MVVM boundaries
- `asset-manager` — assets and pubspec
- `bug-fixer` — triage and fix workflow
- `code-reviewer` — structured code review
- `commit-helper` — conventional commits
- `crud-generator` — list/detail/form screens
- `docs-sync` — keep docs aligned with code
- `evidence-first-reading` — prove code claims with file, symbol, and snippet
- `feature-scaffolder` — new feature layout
- `frontend-design` — design context, anti-patterns, context gathering
- UI execution skills: `adapt`, `animate`, `arrange`, `audit`, `bolder`, `clarify`, `colorize`, `critique`, `delight`, `distill`, `extract`, `harden`, `normalize`, `onboard`, `optimize`, `overdrive`, `polish`, `quieter`, `teach-impeccable`, `typeset`
- `supabase-migration` — migrations, RLS, rollout safety

When working on SLine, always reference `@.cursor` first.

## Planning And Execution Standards

- Plans must be written in painstaking detail.
- Plans must prefer more phases, more sub-phases, and smaller atomic steps.
- Every phase, sub-phase, and step must name its owning agent.
- Meaningful UI steps must include skill tags from `.cursor/skills/`.
- Meaningful Supabase schema, RLS, RPC, storage, or migration steps must include `Skill: supabase-migration`.
- Every executed plan must have an append-only session log under `docs/LOG/`.
- Every schema, order flow, or backend process feature must produce or update a per-feature diagram under `docs/diagrams/`.
