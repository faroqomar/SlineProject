---
description: Enforces Feature-First MVVM architecture in Next.js Admin Dashboard
globs: ["sline_admin/**/*.tsx", "sline_admin/**/*.ts"]
alwaysApply: true
---

# Admin Dashboard Architecture Rules (MVVM)

## Core Principle
This project interacts with the database via **Server Actions** acting as Services, and manages state via **Client ViewModels** (Custom Hooks).

### 1. Naming Conventions (Strict)

- **Models**: `features/*/models/*.model.ts`, `*.schema.ts`
- **Services**: `features/*/services/*.service.ts`
- **ViewModels**: `features/*/viewmodels/use_*.vm.ts` (e.g., `use_user_list.vm.ts`)
- **Views**: `features/*/view/*.view.tsx`

### 2. Service Layer Rules (`*.service.ts`)

- **MUST** start with `'use server'` at the top.
- **MUST** use `createServiceRoleClient()` for admin tasks.
- **MUST** return `Promise<ActionResult<T>>`.
- **NEVER** throw raw errors to the client. Always return `{ success: false, error: ... }`.
- **MUST** be the **ONLY** place that touches the database.

### 3. ViewModel Rules (`use_*.vm.ts`)

- **MUST** start with `'use client'`.
- **State Only**: Returns `{ state, isLoading, actions }`.
- **`useEffect` Restriction**: Allowed **ONLY** for initial data fetching (e.g., calling `load()`).
- **Service Boundary**: Calls Services as black boxes. Does not know about Supabase or DB queries.

### 4. View Rules (`*.view.tsx`)

- **Dumb Components**: Responsible for Layout and UI only.
- **NO useEffect**: Logic must live in the ViewModel.
- **Binding**: Takes data/actions purely from the ViewModel or Props.
