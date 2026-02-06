---
description: Reviews Admin Dashboard code for Security, Architecture, and Standard violations
---

# Admin Code Reviewer

**Goal**: Verify that the code adheres to `admin-architecture.mdc`, `admin-security.mdc`, and `admin-standards.mdc`.

## Inspection Checklist

When running this skill on a file or PR, check for:

### 1. Security Violations (`admin-security.mdc`)
- [ ] **Prohibited Imports**: Is `createServiceRoleClient` imported in a file NOT marked `'use server'`?
- [ ] **Thrown Errors**: Does a Service `throw Error` instead of returning `{ success: false }`?
- [ ] **Missing Zod**: Does a Service Action accept arguments without `Schema.parse()`?
- [ ] **Missing RBAC**: Does the Service skip `verifyAdminRole()`?
- [ ] **Direct DB**: Does a Client Component (`'use client'`) try to import `supabase-js`?

### 2. Architecture Violations (`admin-architecture.mdc`)
- [ ] **Logic in View**: Does a `.view.tsx` file have `useEffect` or `fetch` calls?
- [ ] **DB in VM**: Does a `.vm.ts` file import `supabase`?
- [ ] **Naming**: do files match `use_*.vm.ts`, `*.service.ts`, `*.model.ts`?

### 3. Operational Standards (`admin-standards.mdc`)
- [ ] **Bulk Safety**: Does a loop over >10 items exist without a `limit` or `batch`?
- [ ] **Audit Missing**: Does a WRITE operation (insert/update/delete) happen without an accompanying `audit_logs.insert`?

## Remediation
If any violations are found:
1.  **Stop**: Do not approve the code.
2.  **Fix**: Rewrite the strict standard.
3.  **Explain**: Quote the specific `.mdc` rule violated.
