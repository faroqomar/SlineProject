# Model Consolidation Plan: TaskRequest vs ProposalModel

## Executive Summary

This plan outlines the consolidation of two overlapping domain models representing the same database entity (`task_requests` table) into a single canonical model (`TaskRequest`).

**Status:** Phase 0.3 - Deprecation & Alignment  
**Target Completion:** 2 sprints (Sprint N+1: Deprecation, Sprint N+2: Migration & Removal)

---

## Field Comparison Matrix

| Field | TaskRequest | ProposalModel | Notes |
|-------|-------------|---------------|-------|
| `id` | ✅ String | ✅ String | Primary key |
| `taskId` | ✅ String | ✅ String | FK to tasks table |
| `bidderId` | ✅ String | ✅ String | Maps to `freelancer_id` (canonical) / `bidder_id` (legacy) |
| `price` | ✅ int | ✅ int | Stored as BIGINT in DB |
| `days` | ✅ int | ✅ int | Duration estimate |
| `note` | ✅ String? | ✅ String? | Optional message from bidder |
| `status` | ✅ OfferStatus | ✅ OfferStatus | pending/accepted/rejected/unknown |
| `paymentStatus` | ✅ PaymentStatus | ✅ PaymentStatus | unpaid/paid/pending |
| `createdAt` | ✅ DateTime | ✅ DateTime | UTC timestamp |
| `bidderName` | ✅ String? | ✅ String? | Joined from profiles.full_name |
| `bidderAvatar` | ✅ String? | ✅ String? | Joined from profiles.avatar_url |
| `taskTitle` | ✅ String? | ✅ String? | Joined from tasks.title |
| `paymentDeadline` | ⚠️ **MISSING** | ✅ DateTime? | **Gap identified** - used for tender expiration |

### Summary
- **Total fields in TaskRequest:** 12
- **Total fields in ProposalModel:** 13
- **Missing in TaskRequest:** 1 field (`paymentDeadline`)

---

## Identified Gap: paymentDeadline

**Field:** `paymentDeadline` (DateTime?)  
**Purpose:** Tracks the deadline for payment on accepted offers in tender-based tasks.  
**Database Column:** `task_requests.payment_deadline`  
**Usage Location:** `lib/features/proposals/data/proposal_repository.dart:122-124`

**Impact:**
- TaskRequest currently cannot represent the full state of a task request with payment deadline
- Converting ProposalModel → TaskRequest loses payment deadline information
- Prevents complete migration from ProposalModel to TaskRequest

---

## Consolidation Approach

### Sprint N+1: Deprecation & Alignment (Current Sprint)

**Goals:**
1. Mark `ProposalModel` as deprecated with clear migration path
2. Add `paymentDeadline` field to `TaskRequest` to achieve feature parity
3. Update `TaskRequest.fromProposal()` factory to include payment deadline
4. Ensure all ProposalRepository methods can return TaskRequest instead

**Files to Modify:**
| File | Change |
|------|--------|
| `lib/features/proposals/models/proposal_model.dart` | Add `@Deprecated` annotation |
| `lib/features/tasks/models/task_request_model.dart` | Add `paymentDeadline` field, update factory methods |

**Backward Compatibility:**
- ProposalModel remains functional during deprecation period
- Existing code using ProposalModel continues to work with warnings
- No breaking changes to API or database schema

### Sprint N+2: Migration & Removal

**Goals:**
1. Migrate all ProposalModel consumers to TaskRequest
2. Update ProposalRepository to return TaskRequest
3. Remove ProposalModel class entirely
4. Update imports and type references throughout codebase

**Migration Checklist:**
- [ ] Search for all `ProposalModel` imports
- [ ] Replace `List<ProposalModel>` with `List<TaskRequest>` in repositories
- [ ] Update ViewModels that use ProposalModel
- [ ] Update UI widgets consuming ProposalModel
- [ ] Remove `fromProposal` factory once ProposalModel is gone

---

## Migration Timeline

```
Week 1-2 (Sprint N+1): Deprecation Phase
├─ Add @Deprecated to ProposalModel
├─ Add paymentDeadline to TaskRequest
├─ Update fromProposal factory
├─ Announce deprecation to team
└─ Create migration tickets for Sprint N+2

Week 3-4 (Sprint N+2): Migration Phase
├─ Migrate ProposalRepository methods
├─ Migrate ViewModels
├─ Migrate UI widgets
├─ Run full regression test suite
└─ Delete ProposalModel file
```

---

## Deprecation Message

```dart
@Deprecated(
  'Use TaskRequest instead. '
  'ProposalModel is being consolidated into TaskRequest for a unified domain model. '
  'Migration: Replace ProposalModel with TaskRequest in your code. '
  'See MODEL_CONSOLIDATION_PLAN.md for details. '
  'Scheduled removal: Sprint N+2 (2 weeks from now).',
)
```

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Breaking existing features during migration | Low | High | Gradual deprecation period, maintain backward compatibility |
| Missed ProposalModel usages | Medium | Medium | Global search for imports, code review checklist |
| State management issues | Low | High | Comprehensive testing of TaskRequest in ViewModels |
| Database schema mismatch | Low | High | Both models read from same table, no schema changes needed |

---

## Verification Steps

1. **After Sprint N+1:**
   - [ ] `flutter analyze` passes with no errors
   - [ ] ProposalModel shows deprecation warnings where used
   - [ ] TaskRequest includes `paymentDeadline` field
   - [ ] `fromProposal` factory preserves all fields including deadline

2. **After Sprint N+2:**
   - [ ] No remaining ProposalModel references in codebase
   - [ ] All proposal-related features work with TaskRequest
   - [ ] Unit tests pass for TaskRequest (including deadline logic)
   - [ ] Integration tests pass for tender/award flow

---

## Related Documentation

- `lib/features/tasks/models/task_request_model.dart` - Target canonical model
- `lib/features/proposals/models/proposal_model.dart` - Source deprecated model
- `lib/features/proposals/data/proposal_repository.dart` - Primary ProposalModel consumer
- `Sline_everything/DEVELOPER_GUIDE.md` - Architecture patterns

---

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-03-06 | Consolidate to TaskRequest | TaskRequest has richer parsing, copyWith, equality, and is used in more features |
| 2026-03-06 | Add paymentDeadline to TaskRequest | Required for feature parity; field exists in DB and is used by tender system |
| 2026-03-06 | 2-sprint deprecation timeline | Allows gradual migration without disrupting active development |

---

*Generated: 2026-03-06*  
*Author: Executor Agent - Phase 0.3*  
*Reviewers: CodeGuard, Architect*
