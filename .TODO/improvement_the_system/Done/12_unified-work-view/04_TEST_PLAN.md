# Test Plan: 12_unified-work-view

## 1. Automated SQL Verification (PostgreSQL)

### 1.1) Column Consistency Test

**Goal**: Ensure all UNION ALL branches return identical column types and counts.
**Steps**:

1. Run `\d vw_unified_work_items` to verify the schema.
2. Check that `price` is always `numeric`.
3. Check that `client_id` and `freelancer_id` are never null where expected.

### 1.2) RLS Verification (The "Adversary" Test)

**Goal**: Ensure User A cannot see User B's unified work items.
**Steps**:

1. `SET ROLE anon;`
2. `SET auth.uid = 'user-a-uuid';`
3. `SELECT * FROM vw_unified_work_items;` (Should only see items where client_id or freelancer_id matches).
4. `SET auth.uid = 'user-b-uuid';`
5. `SELECT * FROM vw_unified_work_items;` (Should only see User B's items).

### 1.3) Data Aggregation Coverage

**Goal**: Verify all 4 item types appear in the view.
**Steps**:

1. Insert a mock `task` (in_progress).
2. Insert a mock `booking` (active).
3. Insert a mock `task_request` (accepted/unpaid) + `task` (assigned).
4. Insert a mock `direct_offer` (active).
5. Query `vw_unified_work_items` and verify all 4 rows appear with correct `source_type`.

---

## 2. Integration Testing (Dart/Flutter)

### 2.1) Service Layer Load

**Goal**: Verify `WorkManagementService.listUnifiedWorkItems` maps correctly.
**Command**: `flutter test test/features/work/services/work_management_service_test.dart`
_(Note: If test doesn't exist, create one that mocks the Supabase response for the new view schema)._

### 2.2) Status Mapping Edge Cases

**Goal**: Verify `disputed` status override.
**Steps**:

1. Create a task in the DB.
2. Create a dispute for that task.
3. Call `getUnifiedWorkItem` in Flutter and assert `unified_status == UnifiedWorkStatus.disputed`.

---

## 3. Manual UI Verification

### 3.1) The "One Feed" Test

**Steps**:

1. Log in as a Freelancer.
2. Have a client book a session (Booking).
3. Have a client accept a bid (Task).
4. Go to the "My Work" dashboard.
5. **Success Criteria**: Both items appear in the same list with consistent styling.

### 3.2) Role Switch Consistency

**Steps**:

1. Switch to Client role.
2. Verify the same items appear but from the "Client" perspective (e.g., seeing the freelancer's name).
