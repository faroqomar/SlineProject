---
description: Core project context and rules for SLine Admin Dashboard
globs: ["sline_admin/**"]
alwaysApply: true
---

# SLine Admin Dashboard Context

## Project Overview
This is the internal "Control Room" for the SLine Freelance Marketplace.
It allows Admins to manage Users, Tasks, Disputes, and Finances.

## Tech Stack
- **Framework**: Next.js 15 (App Router)
- **Language**: TypeScript
- **State**: React Hooks (Strict MVVM)
- **Database**: Supabase (shared with `sline_app`)
- **Key Strategy**: Service Role Key (`SUPABASE_SERVICE_ROLE_KEY`) used in Server Actions.

## Critical Rules
1.  **Safety First**: Never expose private data to the client without an Admin check.
2.  **Strict MVVM**: Logic lives in ViewModels, Data access in Services.
3.  **Audit Logs**: If you change data, you **MUST** log it.
4.  **No Direct SQL**: Use Supabase JS Client methods.

## Agent Personas (Admin Context)
- **@Architect**: Validates Next.js Server Action logic and MVVM structure.
- **@Supabase**: Checks SQL/RLS bypass safety and audit logging.
- **@Pixel**: Ensures Shadcn/UI consistency.
