# 04_TEST_PLAN

## 1. RLS Contract Verification (SQL)

### T1: Verify No Exposed `public` INSERT/UPDATE

**Objective**: Ensure `public` (anon) role cannot modify data.
**Command**:

```sql
SELECT tablename, policyname, cmd, roles
FROM pg_policies
WHERE roles && '{public}'::name[] AND cmd IN ('INSERT', 'UPDATE', 'DELETE');
```

**Expected**: Returns 0 rows (except for legacy/explicitly allowed cases like `profiles` insert during signup).

### T2: Verify `SECURITY INVOKER` on All Views

**Objective**: Ensure views do not bypass RLS.
**Command**:

```sql
SELECT viewname, definition
FROM pg_views
WHERE schemaname = 'public' AND definition ILIKE '%SECURITY DEFINER%';
```

**Expected**: Returns 0 rows.

### T3: Ownership Matrix Test

**Objective**: Verify that `uid` check exists for all owner-scoped policies.
**Command**:

```sql
SELECT tablename, policyname, qual
FROM pg_policies
WHERE policyname ILIKE '%self%' OR policyname ILIKE '%owner%';
```

**Validation**: Check that `qual` contains `auth.uid() = ...`.

## 2. Integration Tests (Flutter/Supabase)

### T4: Cross-User Record Leakage

- **Scenario**: User A attempts to `SELECT` User B's private notification.
- **Verification**: `await supabase.from('notifications').select().eq('user_id', userBId)` should return an empty list or error.

### T5: Favorite-DM Guard

- **Scenario**: Client A tries to message Freelancer B without B being in A's favorites.
- **Verification**: `INSERT INTO conversations` should fail with a trigger exception `P0001`.

### T6: Ledger Write Blocking

- **Scenario**: Authenticated user attempts to modify `ledger_lines`.
- **Verification**: `UPDATE ledger_lines` should fail with `42501`.
