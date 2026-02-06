# Admin Development Workflow

This document defines the **Strict 6-Stage Lifecycle** for every feature in the Admin Dashboard.

## The 6 Stages

### 1. Scaffold (`@AdminArchitect`)
*   **Goal**: Create the skeleton.
*   **Actions**:
    *   Create feature folder `features/[name]`.
    *   Create `model.ts` interfaces.
    *   Create empty `service.ts`, `vm.ts`, `view.tsx`.
    *   Update `routes` and `layout`.

### 2. Backend (`@SysOp`)
*   **Goal**: Secure data access.
*   **Actions**:
    *   Write **Zod Schemas** (`schema.ts`).
    *   Implement **Server Actions** (`service.ts`).
    *   Apply **RBAC** (`verifyAdminRole`).
    *   Apply **Audit Logging** inside atomic transactions.
    *   **NO UI** work here.

### 3. Frontend (`@UIExpert`)
*   **Goal**: Visuals and UX.
*   **Actions**:
    *   Implement **ViewModel** (`use_*.vm.ts`) to consume Service.
    *   Build **View** (`*.view.tsx`) using Shadcn.
    *   Add **Loading/Error/Empty** states.
    *   Add **Confirm Dialogs** with "Reason" input for destructive acts.

### 4. QA (`@QA_Tester`)
*   **Goal**: Break the feature.
*   **Actions**:
    *   **Smoke Test**: Does the happy path work?
    *   **Security Test**: Can a non-admin call the action? (Must fail).
    *   **Validation Test**: Does sending invalid data return a Zod error?
    *   **Regression**: Did we break anything else?

### 5. Security Gate (`@SecGuard`)
*   **Goal**: Blocking Review.
*   **Actions**:
    *   Review Code against `.mdc` rules.
    *   Verify **Definition of Done**:
        *   ✅ RBAC present?
        *   ✅ Zod used?
        *   ✅ Audit Log + Reason present?
        *   ✅ Pagination used?

### 6. Documentation (`@DocKeeper`)
*   **Goal**: Sync Reality.
*   **Actions**:
    *   Update `ADMIN_FEATURES.md`.
    *   Update `CHANGELOG.md`.
    *   Mark task as Done.

---

## Critical Rules Summary

| Rule | Owner | Enforcement |
|---|---|---|
| **No Throw** | Schema | Services must strictly return `ActionResult`, never throw. |
| **Zod First** | SysOp | First line of every Action must be `schema.parse()`. |
| **Reason Required** | All | UI must ask for it, Service must reject if missing. |
| **DB Ownership** | SysOp | Only SysOp touches Schema, RLS, Indexes, Migrations. |
