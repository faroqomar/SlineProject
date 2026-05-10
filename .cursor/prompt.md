# SLine Implementation Prompt

When working on a new feature or change:

1. **Always use workflows** – Reference `.cursor/Agents/` for the right agent and follow the workflow (e.g. plan → execute → verify).

2. **In your plan, include which agents you will use** from `.cursor/Agents/`:
   - @Planner – produce a plan in `.TODO/PLAN_*.md`
   - @Architect – MVVM, services, viewmodels
   - @Pixel – UI, theme, glassmorphism
   - @Supabase_Ops – schema, RLS, SQL, storage
   - @Sentinel – QA, security, docs sync
   - @CodeGuard – review, performance, security
   - @Executor – run a plan phase-by-phase
   - @DocsKeeper – update `Sline_everything/` and changelog
   - @PlanCritic – audit and harden the plan
   - @Observability, @APIContract, @DataMigration, @ThreatModeler – when the plan requires them

3. **Always read the documentation** – Before implementing, read:
   - `Sline_everything/DEVELOPER_GUIDE.md`
   - `Sline_everything/SUPABASE_SETUP.md`
   - `Sline_everything/STRUCTURE.md`
   - `.cursor/PROJECT_CONTEXT.md`
   - `.cursor/rules/` (relevant rules for the change)

4. **Use Supabase MCP** when needed – If the task involves schema, RLS, or data shape validation, use the Supabase MCP server to confirm live schema and policies.
