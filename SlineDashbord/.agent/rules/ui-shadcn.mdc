---
description: UI Standardization rules using Shadcn/UI and Tailwind
globs: ["sline_admin/**/*.tsx"]
alwaysApply: true
---

# UI & Theme Rules (Shadcn)

## 1. Component Usage
- **ALWAYS** use `components/ui/*` (Shadcn) for primitives.
- **DO NOT** use raw HTML (`<button>`) when a component exists (`<Button>`).

```tsx
// ✅ CORRECT
import { Button } from '@/components/ui/button';
<Button variant="default">Click me</Button>
```

## 2. Data Tables & Lists
- **Mandatory Pagination**: Never fetch `select('*')` without `range()` or `limit()`.
- **Server-Side Pagination**: ViewModels should request `page` and `pageSize`.
- **Shadcn DataTable**: Use the standard `data-table` component with columns definition.

## 3. High-Risk UI Patterns
- **Destructive Buttons**: Must be `variant="destructive"`.
- **Confirmation Modals**: Any action that writes to DB (Delete, Ban, Edit) requires a `<Dialog>` or `<AlertDialog>` with:
    - Title: "Are you sure?"
    - Description: "This action cannot be undone."
    - **Input: "Reason" (Mandatory)**: UI must capture a text reason for the Audit Log.
    - Buttons: Cancel (Ghost), Confirm (Destructive).

## 4. Forms
- **MUST** use `react-hook-form` + `zod` resolver.
- **MUST** use `<Form>` wrapper from Shadcn.
- **Validation**: Define Zod schema in `models/*.schema.ts`.
