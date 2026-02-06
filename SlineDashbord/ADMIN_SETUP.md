# Admin Dashboard Setup Guide

Use this guide when you are ready to create the new repository.

## 1. Initialize Project

Run this in your terminal (outside the `sline_app` folder):

```bash
# Create new Next.js app with Typescript, Tailwind, ESLint
npx create-next-app@latest sline_admin --typescript --tailwind --eslint

# ? Would you like to use src/ directory? -> No (or Yes, your preference, usually No for App Router simplicity)
# ? Would you like to use App Router? -> Yes
# ? Would you like to use Turbopack? -> No (optional, stable is safer)
# ? Would you like to customize the default import alias? -> Yes (@/*)
```

## 2. Install Dependencies

Enter the folder and install the core stack:

```bash
cd sline_admin

# 1. UI Components (Shadcn)
npx shadcn@latest init
# ? Style: New York
# ? Base Color: Slate
# ? CSS Variables: Yes

# Install Core Components immediately
npx shadcn@latest add button card table input form dialog dropdown-menu avatar badge toast sheet
# - button, card, input: Basics
# - table: For User/Task lists
# - dialog/sheet: For "View Details" modals
# - toast: For success/error messages
# - form: For proper validation wrapper

# 2. Supabase
npm install @supabase/supabase-js @supabase/ssr

# 3. Icons & Utilities
npm install lucide-react clsx tailwind-merge

# 4. State/Forms
npm install @tanstack/react-query react-hook-form zod @hookform/resolvers
```

## 3. Configure Environment

Create `.env.local`:

```bash
NEXT_PUBLIC_SUPABASE_URL=YOUR_SUPABASE_URL
NEXT_PUBLIC_SUPABASE_ANON_KEY=YOUR_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY=YOUR_SERVICE_ROLE_KEY
```

## 4. Scaffold the Project

1.  **Clean up**: Remove the default code in `app/page.tsx`.
2.  **Auth**: Create `app/auth/login/page.tsx`.
3.  **Layout**: Create `app/(dashboard)/layout.tsx` for your persistent sidebar.

## 5. Adding Components

When you need a button or card, don't build from scratch. Use Shadcn:

```bash
npx shadcn@latest add button card table input form dialog
```

---

**Next Step**: Refer to `ADMIN_ARCHITECTURE.md` to setup the file structure.
