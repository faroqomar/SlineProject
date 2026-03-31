# Chat Creation Matrix - Threat Model

**Document ID**: PLAN_ChatCreationMatrix_ThreatModel  
**Version**: 1.0  
**Date**: 2026-03-06  
**Owner**: @ThreatModeler  
**Reviewers**: @Sentinel, @CodeGuard, @Architect  

---

## 1. Scope

This threat model covers the Chat Creation Matrix feature, focusing on:
- Direct message (DM) creation between clients and freelancers
- Task-linked conversation creation
- Role-based access controls (client vs freelancer)
- Favorites-based access controls
- Rate limiting
- Race condition handling

**Out of Scope**:
- Message content security (encryption)
- File attachment security
- Real-time message delivery security
- Authentication (handled by Supabase Auth)

---

## 2. Asset Inventory

| Asset | Type | Value | Owner |
|-------|------|-------|-------|
| `conversations` table | Data | High - User privacy | System |
| `messages` table | Data | High - User privacy | System |
| `favorites` table | Data | Medium - Social graph | System |
| DM creation capability | Function | High - Business logic | Product |
| User role (client/freelancer) | Identity | High - Access control | User |

---

## 3. Threat Actors

| Actor | Motivation | Capability | Risk Level |
|-------|-----------|------------|------------|
| **Spam Freelancer** | Mass DM clients for pitching | Can create accounts, automate API calls | High |
| **Curious Client** | DM freelancers not in favorites | Can use app normally, may try API manipulation | Medium |
| **Malicious User** | Bypass controls, spy on others | Technical knowledge, may try SQL injection | Medium |
| **Compromised Account** | Abuse trusted identity | Has valid credentials, normal user capabilities | High |
| **Disgruntled User** | Harassment via mass conversations | Can create multiple accounts | Medium |

---

## 4. Threat Scenarios

### T1: Freelancer DM Bypass (Critical)

**Threat**: Freelancer initiates direct DM with client without being prompted.

**Current State (Before Fix)**:
- App layer prevents this (UI only shows "Message" for clients)
- No database-level enforcement
- Direct API calls could bypass UI restriction

**Attack Path**:
1. Freelancer authenticates with valid credentials
2. Freelancer crafts API request to `conversations` table
3. Freelancer sets `initiated_by` to their own user ID
4. Freelancer sets `task_id = null` (direct DM)
5. Row inserted successfully (if RLS doesn't block)

**Mitigation (Implemented)**:
```sql
-- Guard trigger enforces role check
IF NEW.task_id IS NULL THEN
    IF NOT is_client(NEW.initiated_by) THEN
        RAISE EXCEPTION 'Freelancers cannot start direct conversations';
    END IF;
END IF;
```

**Verification Test**:
```dart
test('freelancer creating DM fails', () async {
  final freelancerUser = createMockFreelancerUser();
  // Attempt to create DM as freelancer
  expect(() => service.createDM(freelancerUser, targetId),
    throwsA(contains('Freelancers cannot start')));
});
```

**Residual Risk**: None (fully mitigated at DB level)

---

### T2: Favorites Bypass (Critical)

**Threat**: Client initiates DM with freelancer not in their favorites list.

**Current State (Before Fix)**:
- App layer checks favorites before showing "Message" button
- No database-level enforcement
- Direct API calls could create conversation with any freelancer

**Attack Path**:
1. Client knows freelancer's UUID (from public profiles)
2. Client crafts API request with freelancer's ID
3. Client is not in favorites table for that freelancer
4. Row inserted successfully (if RLS doesn't block)

**Mitigation (Implemented)**:
```sql
-- Guard trigger enforces favorites check
IF NOT EXISTS (
    SELECT 1 FROM favorites
    WHERE client_id = NEW.initiated_by
    AND freelancer_id = target_user_id
) THEN
    RAISE EXCEPTION 'You can only message freelancers in your favorites list';
END IF;
```

**Verification Test**:
```dart
test('create DM to non-favorite fails', () async {
  // Freelancer B is NOT in client's favorites
  expect(() => service.createDM(clientUser, freelancerBId),
    throwsA(contains('favorites list')));
});
```

**Residual Risk**: None (fully mitigated at DB level)

---

### T3: Spam Attack via Mass Conversation Creation (High)

**Threat**: Malicious client creates many conversations rapidly to spam freelancers.

**Attack Path**:
1. Client favorites 1000 freelancers (automated or manual)
2. Client scripts API calls to create conversations with all 1000
3. Each freelancer receives notification/appears in conversation list
4. Platform becomes spam vector

**Mitigation (Implemented)**:
```sql
-- Rate limiting: 20 conversations per hour
IF NOT check_conversation_rate_limit(NEW.initiated_by) THEN
    RAISE EXCEPTION 'Rate limit exceeded: maximum 20 conversations per hour';
END IF;
```

**Additional Mitigations**:
- Favorites list itself has no rate limit (by design)
- But conversation creation is rate-limited
- admin_logs tracks all conversation creation for audit

**Verification Test**:
```dart
test('rate limit blocks after 20 attempts', () async {
  // Create 20 conversations successfully
  for (int i = 0; i < 20; i++) {
    await service.createDM(clientUser, differentFreelancerIds[i]);
  }
  // 21st attempt should fail
  expect(() => service.createDM(clientUser, anotherFreelancerId),
    throwsA(contains('Rate limit exceeded')));
});
```

**Residual Risk**: Low
- 20/hour is generous for legitimate use
- Can tune threshold based on telemetry
- Emergency override available via app_config

---

### T4: Identity Spoofing (Critical)

**Threat**: User creates conversation impersonating another user.

**Attack Path**:
1. User A knows User B's UUID
2. User A crafts INSERT with `initiated_by = User B's UUID`
3. Database accepts if RLS doesn't properly validate
4. Conversation appears as if User B initiated it

**Mitigation (Already Existing + Enhanced)**:
```sql
-- Guard trigger enforces identity integrity
IF NEW.initiated_by IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'initiated_by must equal current user';
END IF;
```

**Verification Test**:
```dart
test('identity spoofing blocked', () async {
  // Attempt to set initiated_by to different user
  final spoofedData = {'initiated_by': 'different-user-id'};
  expect(() => service.rawInsert(spoofedData),
    throwsA(contains('initiated_by must equal')));
});
```

**Residual Risk**: None (enforced by existing guard, remains unchanged)

---

### T5: Task Context Spoofing (Medium)

**Threat**: User attaches arbitrary `task_id` to conversation to gain access.

**Attack Path**:
1. User knows task ID for a task they're not involved in
2. User creates conversation with that task_id
3. User gains visibility into task context/messages

**Mitigation (Implemented)**:
```sql
-- Guard trigger verifies task participation
IF NEW.task_id IS NOT NULL THEN
    IF NOT EXISTS (
        SELECT 1 FROM task_requests
        WHERE task_id = NEW.task_id
        AND (freelancer_id = NEW.initiated_by OR bidder_id = NEW.initiated_by)
        AND status IN ('pending', 'accepted')
    ) AND v_task_owner_id IS DISTINCT FROM NEW.initiated_by THEN
        RAISE EXCEPTION 'You must have an active bid on this task to start a conversation';
    END IF;
END IF;
```

**Residual Risk**: Low
- Must have active bid on task
- Task owner can always create (via reject flow)

---

### T6: Race Condition Duplicate Conversations (Medium)

**Threat**: Rapid double-click creates duplicate conversations.

**Attack Path**:
1. User clicks "Message" button rapidly twice
2. Both requests check for existing conversation simultaneously
3. Both find no existing conversation
4. Both insert new rows
5. Duplicate conversations created

**Mitigation (Implemented)**:
```sql
-- Unique constraint prevents duplicates
UNIQUE (LEAST(user1_id, user2_id), GREATEST(user1_id, user2_id), COALESCE(task_id, NIL_UUID))

-- Atomic RPC with ON CONFLICT
INSERT INTO conversations (...)
VALUES (...)
ON CONFLICT (...) DO UPDATE SET updated_at = NOW()
RETURNING *;
```

**Verification Test**:
```dart
test('idempotent: 50 concurrent calls return same conversation', () async {
  final futures = List.generate(50, (_) => service.createDM(clientUser, freelancerId));
  final results = await Future.wait(futures);
  // All results should have same conversation ID
  final uniqueIds = results.map((r) => r.id).toSet();
  expect(uniqueIds.length, equals(1));
});
```

**Residual Risk**: None (handled by atomic RPC + unique constraint)

---

### T7: Rate Limit Bypass (Low)

**Threat**: User switches accounts to bypass per-user rate limit.

**Attack Path**:
1. User creates multiple accounts
2. Each account creates 20 conversations
3. Effectively unlimited conversations across accounts

**Mitigation**:
- No IP-based rate limiting (explicitly out of scope per D1)
- Relies on account creation friction (email verification)
- admin_logs tracks all conversation creation for pattern detection
- Can add IP-based limiting later if telemetry shows abuse

**Residual Risk**: Medium
- Currently accepted risk per D1 decision
- Can add edge function for IP-based limiting if needed

---

### T8: Error Message Information Leakage (Low)

**Threat**: Error messages reveal sensitive information (user IDs, internal structure).

**Attack Path**:
1. User triggers various error conditions
2. Error messages reveal internal details
3. Attacker uses information for further attacks

**Mitigation (Implemented)**:
```sql
-- Generic error messages (no user IDs)
RAISE EXCEPTION 'Target user not found';  -- NOT: 'User 123-456 not found'
RAISE EXCEPTION 'Freelancers cannot start direct conversations';  -- No details

-- Detailed logging to admin_logs (server-side only)
INSERT INTO admin_logs (action, details) 
VALUES ('conversation_creation_failed', jsonb_build_object('error', '...'));
```

**Verification**:
- Review all RAISE EXCEPTION statements
- Ensure no `%` formatting with user IDs
- ErrorMapper in Flutter provides user-friendly abstractions

**Residual Risk**: None (with proper review in Phase 1.5)

---

## 5. Risk Summary Matrix

| Threat | Severity | Likelihood | Risk Score | Status |
|--------|----------|------------|------------|--------|
| T1: Freelancer DM Bypass | Critical | Medium | **High** | ✅ Mitigated |
| T2: Favorites Bypass | Critical | Medium | **High** | ✅ Mitigated |
| T3: Spam Attack | High | Medium | **High** | ✅ Mitigated |
| T4: Identity Spoofing | Critical | Low | **Medium** | ✅ Mitigated |
| T5: Task Context Spoofing | Medium | Low | **Low** | ✅ Mitigated |
| T6: Race Condition | Medium | High | **Medium** | ✅ Mitigated |
| T7: Rate Limit Bypass | Medium | Medium | **Medium** | ⚠️ Accepted |
| T8: Error Info Leakage | Low | Low | **Low** | ✅ Mitigated |

**Risk Score Formula**: Severity × Likelihood
- Critical × Any = High Risk
- High × High = High Risk
- All others = Medium/Low Risk

---

## 6. Security Test Plan

### Negative Test Cases (Must Fail)

| Test | Expected Result | Priority |
|------|-----------------|----------|
| Freelancer calls `start_direct_conversation_v1` | Error: "Freelancers cannot start direct conversations" | P0 |
| Client calls with non-favorite freelancer ID | Error: "You can only message freelancers in your favorites list" | P0 |
| 21st conversation in 1 hour | Error: "Rate limit exceeded" | P0 |
| Spoof `initiated_by` in raw INSERT | Error: "initiated_by must equal current user" | P0 |
| Create task conversation for task user didn't bid on | Error: "You must have an active bid on this task" | P1 |
| Double-tap "Message" button | Single conversation created (idempotent) | P1 |

### Positive Test Cases (Must Succeed)

| Test | Expected Result | Priority |
|------|-----------------|----------|
| Client favorites freelancer → starts DM | Conversation created | P0 |
| Freelancer bids → task conversation created | Conversation created | P0 |
| Client rejects bid → conversation created | Conversation created (GUC exception) | P0 |
| Existing conversation → return same | Same conversation returned | P0 |

---

## 7. Compliance & Audit

### Audit Trail

All conversation creation attempts logged to `admin_logs`:

```sql
INSERT INTO admin_logs (
    user_id, action, entity_type, entity_id, details
) VALUES (
    v_caller,
    'conversation_created',
    'conversations',
    v_conversation.id,
    jsonb_build_object(
        'type', 'direct_dm',
        'target_id', v_target,
        'is_new', (v_conversation.created_at = v_conversation.updated_at)
    )
);
```

**Log Retention**: Per existing admin_logs policy
**PII Handling**: Target ID logged for audit; no other PII

---

## 8. Incident Response

### If T3 (Spam) Detected

1. **Immediate**: Disable feature flag `enable_direct_conversation_rpc`
2. **Short-term**: Reduce rate limit to 5/hour via app_config
3. **Medium-term**: Review admin_logs for pattern, identify accounts
4. **Long-term**: Consider IP-based limiting if needed

### If T1/T2 Bypass Discovered

1. **Immediate**: Disable feature flag
2. **Investigation**: Review admin_logs for unauthorized conversations
3. **Cleanup**: Archive violating conversations (don't delete - preserve evidence)
4. **Fix**: Emergency SQL patch to guard trigger

---

## 9. Sign-Off

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Threat Modeler | @ThreatModeler | [APPROVED] | 2026-03-06 |
| Security Review | @CodeGuard | [APPROVED] | 2026-03-06 |
| QA Lead | @Sentinel | [APPROVED] | 2026-03-06 |

---

**Next Step**: Create API Contract (Phase 0.5)
