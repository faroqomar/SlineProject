---
description: Operational Standards for SLine Admin Dashboard
globs: ["sline_admin/**/*"]
alwaysApply: true
---

# Admin Operational Standards

## 0. Release Workflow (Branching)
- **Feature Branches**: All work happens on `feat/xyz` branches.
- **Merge Gate**: PRs are merged to `main` ONLY after:
    1.  `@QA` passes implementation tests.
    2.  `@SecGuard` approves the Audit/Security logic.
    3.  `@DocKeeper` confirms documentation is valid.

## 1. Naming Conventions (Strict)

| Type | Suffix | Example |
|---|---|---|
| Model | `.model.ts` | `features/users/models/user.model.ts` |
| Schema | `.schema.ts` | `features/users/models/user.schema.ts` |
| Service | `.service.ts` | `features/users/services/user.service.ts` |
| ViewModel | `.vm.ts` | `features/users/viewmodels/user_list.vm.ts` |
| View | `.view.tsx` | `features/users/view/user_list.view.tsx` |
| Hook | `.hook.ts` | `core/hooks/use-debounce.hook.ts` |

## 2. Response Standards (`ActionResult`)

All Services (and Server Code in general) must return a consistent shape.

```typescript
export type ActionResult<T = void> = 
  | { success: true; data: T; meta?: { requestId: string } }
  | { success: false; error: { code: string; message: string; details?: any } };
```

**Rule**: Server code **NEVER** throws raw errors. It catches exceptions and returns `success: false`.

## 3. Implementation Standards

### Input Validation (Zod)
- **Mandatory**: Every Service Action must start by parsing input with a strict Zod schema.
- **Rule**: No Database call is allowed until Zod validation passes.
- **Failure**: Return `{ success: false, error: { code: 'INVALID_INPUT', ... } }`.

### Bulk Operations Policy
- **Limits**: Hard cap on items per batch (e.g., max 200).
- **Progress**: Actions taking >2s must return a job ID or progress indicator logic.
- **Audit**: Log must contain count of affected ID range or array.

### Export Policy (CSV/PDF)
- **Server-Side Only**: Do not stream all JSON to client to convert to CSV.
- **Permissions**: Restricted to Super Admins or specific permission set.
- **Watermarking**: Critical exports should contain ID of the downloader in metadata/filename.

## 4. Testing Requirements
- **Service Tests**: Every Server Action must have a test case covering:
    1.  **Happy Path**: Success with valid data.
    2.  **Unauthorized**: Call without Admin role (Matches error code).
    3.  **Invalid Input**: Call with schema violation.

## 5. Rate Limiting
- **Brute Force**: Login/Verify endpoints must have strict rate limits.
- **Data Scraping**: List endpoints must limit paging speed/depth if abused.
