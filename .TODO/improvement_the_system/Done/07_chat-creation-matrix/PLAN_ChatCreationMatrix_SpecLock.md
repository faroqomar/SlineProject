# Chat Creation Matrix - Spec Lock Document

**Document ID**: PLAN_ChatCreationMatrix_SpecLock  
**Version**: 1.0 (Locked)  
**Date**: 2026-03-06  
**Status**: 🔒 LOCKED - No changes without formal review  
**Owner**: @Sentinel (QA Lead)  
**Approved By**: @Architect, @Supabase_Ops, @DataMigration  

---

## 1. Purpose

This document locks the technical specifications for the Chat Creation Matrix implementation. Once locked, changes require:
1. Formal review with all stakeholders
2. Impact assessment on downstream phases
3. Updated test cases
4. Re-approval from @Sentinel

---

## 2. Decisions Locked

### D1: Rate Limit Scope ✅ DECIDED

**Decision**: Option A - Per-user only (simpler, trusts auth)

**Rationale**:
- IP-based rate limiting adds complexity (edge function requirement)
- Current threat model doesn't indicate coordinated account-switching attacks
- Can be added later if telemetry shows abuse
- 20/hour per user is generous for legitimate use

**Implementation**:
```sql
-- Rate limit check in guard trigger
IF NOT check_conversation_rate_limit(NEW.initiated_by) THEN
    RAISE EXCEPTION 'Rate limit exceeded: maximum 20 conversations per hour';
END IF;
```

**No-Go**: IP-based rate limiting is OUT OF SCOPE for this phase.

---

### D2: Existing DM Conversation Handling ✅ DECIDED

**Decision**: Option A - Grandfather all existing conversations

**Rationale**:
- Guard trigger only runs on INSERT operations
- Existing conversations remain valid regardless of new rules
- No retroactive enforcement
- Clean separation: old behavior vs new behavior
- Avoids breaking active conversations
- Simplifies migration (no data changes)

**Implementation**:
- No migration of existing `conversations` rows
- Document grandfathering in release notes
- New rules apply only to new conversations created after deployment

**Acceptance Criteria**:
- Existing conversations remain accessible
- Users can continue messaging in existing conversations
- No admin action required for existing data

---

### D3: Error Message Localization ✅ DECIDED

**Decision**: Option A - Human-readable SQL errors, Flutter maps via ErrorMapper

**Rationale**:
- Faster implementation (no error code system to build)
- SQL exceptions are already human-readable
- ErrorMapper provides clean abstraction for Flutter layer
- Can migrate to error codes later if needed
- Consistent with existing error handling patterns

**Implementation**:

SQL Guard (raises human-readable messages):
```sql
RAISE EXCEPTION 'Freelancers cannot start direct conversations';
RAISE EXCEPTION 'You can only message freelancers in your favorites list';
RAISE EXCEPTION 'Rate limit exceeded: maximum 20 conversations per hour';
RAISE EXCEPTION 'Target user not found';
```

Flutter ErrorMapper:
```dart
// lib/core/utils/error_mapper.dart additions
static String _mapChatCreationError(String rawError) {
  if (rawError.contains('Freelancers cannot start')) {
    return AppStrings.freelancerCannotStartDm;
  }
  if (rawError.contains('favorites list')) {
    return AppStrings.notInFavorites;
  }
  if (rawError.contains('Rate limit exceeded')) {
    return AppStrings.rateLimitExceeded;
  }
  if (rawError.contains('Target user not found')) {
    return AppStrings.userNotFound;
  }
  return AppStrings.genericError;
}
```

**No-Go**: Structured error codes are OUT OF SCOPE for this phase.

---

## 3. Acceptance Criteria (Locked)

### Correctness
- [ ] All 6 conversation entry points work:
  1. Client favorites freelancer → starts DM
  2. Freelancer bid → task-linked conversation
  3. Client accepts bid → task-linked conversation
  4. Client rejects bid → conversation created (reject flow)
  5. Reply in existing conversation
  6. Deep link to conversation
- [ ] `start_direct_conversation_v1` RPC is idempotent: 10 calls → 1 row
- [ ] Guard trigger blocks all invalid attempts with clear error messages

### Security
- [ ] Freelancers cannot initiate DMs (negative test passes)
- [ ] Clients cannot DM non-favorites (negative test passes)
- [ ] Rate limit enforced at 20/hour (21st blocked)
- [ ] No RLS bypass found in audit

### UX Stability
- [ ] Race condition handled gracefully (no crashes, no duplicates)
- [ ] Error messages are user-friendly and actionable
- [ ] Existing conversations remain accessible

### Performance
- [ ] RPC response time < 500ms for DM creation
- [ ] Guard trigger overhead < 50ms per insert
- [ ] Rate limit check uses indexed query

### Migration Safety
- [ ] Zero downtime deployment
- [ ] Backward compatibility maintained (feature flag)
- [ ] Rollback plan tested

---

## 4. Non-Goals (Locked)

The following are EXPLICITLY OUT OF SCOPE:

| Feature | Why Excluded | Future Consideration |
|---------|--------------|---------------------|
| IP-based rate limiting | Complexity; no current threat | Add via edge function if needed |
| Structured error codes | Over-engineering for current needs | Migrate if localization needs grow |
| Retroactive enforcement on existing conversations | Risk of breaking active chats | N/A - grandfathering is permanent |
| Admin dashboard for violations | No violations expected | Build if data validation finds issues |
| Group chat support | Completely different feature | Separate epic |
| Message encryption | Out of scope for this security layer | Separate security review |

---

## 5. Change Control Process

### If a change is needed after lock:

1. **Proposer** documents:
   - What needs to change
   - Why it needs to change
   - Impact on phases 1-5
   - Updated test cases needed

2. **Review Meeting** with:
   - @Sentinel (QA Lead)
   - @Architect (Technical Lead)
   - @Supabase_Ops (DBA)
   - Phase owner affected by change

3. **Decision**:
   - Approved: Update plan, version bump, re-test affected phases
   - Rejected: Document reason, maintain current spec

4. **Version Control**:
   - Locked version: 1.0
   - Changes bump minor version: 1.1, 1.2, etc.
   - Major changes bump major version: 2.0 (requires full re-review)

---

## 6. Signatures

By approving this spec lock, stakeholders confirm:
- Technical approach is sound
- Implementation can proceed
- Acceptance criteria are achievable
- Risks are understood and accepted

| Role | Name | Signature | Date |
|------|------|-----------|------|
| QA Lead | @Sentinel | [APPROVED] | 2026-03-06 |
| Technical Lead | @Architect | [APPROVED] | 2026-03-06 |
| DBA | @Supabase_Ops | [APPROVED] | 2026-03-06 |
| Data Migration | @DataMigration | [APPROVED] | 2026-03-06 |

---

## 7. References

- Original Plan: `.TODO/implement_the_system/ImplementReady/07_chat-creation-matrix/`
- PlanCritic Review: `.cursor/plans/chat_creation_matrix_-_plancritic_hardened_b3c6248c.plan.md`
- Test Fixtures: `.TODO/PLAN_ChatCreationMatrix_TestFixtures.md`
- Data Validation: `.TODO/PLAN_ChatCreationMatrix_DataValidation.md`

---

**Status**: 🔒 LOCKED - Implementation may proceed  
**Next Action**: Begin Phase 0.4 (Threat Model)
