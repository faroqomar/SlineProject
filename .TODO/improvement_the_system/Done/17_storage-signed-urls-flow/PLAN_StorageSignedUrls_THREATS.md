# Storage Signed URLs - Threat Model

**Date**: 2026-03-06  
**Author**: @ThreatModeler  
**Scope**: Storage RLS policies for avatars, chat-attachments, task-images

---

## 1. Threat Actors

| Actor | Motivation | Capability |
|-------|------------|------------|
| Authenticated User (Non-Participant) | Curiosity, data theft, stalking | Valid JWT, can call Supabase API |
| Anonymous Attacker | Data harvesting, reconnaissance | No credentials, limited to public endpoints |
| Privileged Insider (Compromised Admin) | Data exfiltration, surveillance | Admin JWT, bypasses participant checks |
| External Attacker | Session hijacking, URL interception | Network access, potential MITM |

---

## 2. Attack Scenarios

### T1: Path Guessing Attack (HIGH RISK)

**Scenario**: Authenticated user guesses path of private chat attachment

**Current State (BEFORE fixes)**:
- Bucket-level policy: `bucket_id = 'chat-attachments'`
- Any authenticated user can call `createSignedUrl` on any path
- Path pattern: `convos/<uuid>/<filename>`
- Conversation IDs are UUIDs (hard to guess but could be leaked/shared)

**Attack Steps**:
1. Attacker obtains conversation ID via screenshot, shared link, or social engineering
2. Attacker constructs path: `convos/<leaked_id>/attachment.jpg`
3. Attacker calls `createSignedUrl('chat-attachments', path, 3600)`
4. **VULNERABILITY**: Policy allows access (only checks bucket_id)
5. Attacker receives signed URL and views private attachment

**Mitigation (AFTER fixes)**:
- Object-level policy calls `can_access_chat_attachment(path, auth.uid())`
- Function parses path, extracts conversation_id, verifies participation
- Non-participants receive 403 Forbidden

**Test Case**: T51 (other client cannot access chat attachment)

---

### T2: Task Image Enumeration (MEDIUM RISK)

**Scenario**: Authenticated user enumerates all task images by iterating user IDs

**Current State (BEFORE fixes)**:
- Bucket-level policy: `bucket_id = 'task-images'`
- Path pattern: `<user_id>/<timestamp>.jpg`
- User IDs are UUIDs (hard to enumerate)

**Attack Steps**:
1. Attacker discovers one user's ID via profile or task listing
2. Attacker guesses other user IDs (UUIDs are hard, but not impossible with enough resources)
3. Attacker constructs paths: `<guessed_id>/*.jpg`
4. Attacker calls storage API to test access
5. **VULNERABILITY**: Policy allows access (only checks bucket_id)
6. Attacker downloads images belonging to other users

**Mitigation (AFTER fixes)**:
- Object-level policy calls `can_access_task_image(path, auth.uid())`
- Function checks `split_part(name, '/', 1) = auth.uid()`
- Non-owners receive 403 Forbidden

**Test Case**: T52b (non-owner cannot access task image)

---

### T3: Admin Bypass Abuse (MEDIUM RISK)

**Scenario**: Compromised admin account used to access all private data

**Risk**: Admin bypass is INTENTIONAL for dispute resolution, but creates concentration of risk

**Controls**:
1. Admin accounts use MFA (to be enforced)
2. Admin access logged to `admin_logs` table
3. Admin access only via `is_admin()` helper
4. Admin JWT claims verified

**Residual Risk**: If admin account compromised, attacker can access all storage

**Mitigation**:
- Audit logging for all admin storage access
- Regular audit of admin_logs
- Principle of least privilege (only designated support staff get admin)

**Test Case**: T53 (admin can access all private storage)

---

### T4: Signed URL Interception (LOW RISK)

**Scenario**: Signed URL leaked via clipboard, proxy logs, or network sniffing

**Attack Steps**:
1. User copies signed URL from browser dev tools
2. User pastes URL in public chat or insecure location
3. Attacker captures URL from logs or network
4. URL is valid for TTL duration (3600s for chat, 7200s for avatars)
5. Attacker accesses private image until URL expires

**Mitigation**:
- Short TTLs minimize exposure window
- HTTPS prevents network sniffing (required)
- URL contains token but not session credentials
- Cache in Flutter doesn't persist URLs outside app session

**Acceptance**: This is an accepted risk given HTTPS requirement and short TTLs

---

### T5: Cache Stampede / DoS (MEDIUM RISK)

**Scenario**: User scrolling through chat triggers excessive signed URL requests

**Current State (BEFORE fixes)**:
- `AttachmentMessageTile` calls `createSignedUrl` in `initState`
- No caching in tile
- 20 images = 20 API calls on every scroll
- Could lead to rate limiting or poor UX

**Mitigation (AFTER fixes)**:
- `SignedUrlCache` stores URLs for 90 minutes
- Same image on scroll = cache hit = 0 API calls
- Error caching prevents retry storms
- Bounded cache size (1000 items) prevents memory issues

**Test Case**: T54-T57 (cache behavior tests)

---

### T6: Policy Syntax Error (HIGH RISK)

**Scenario**: Migration creates malformed RLS policy that accidentally blocks legitimate users

**Risk**: All participants lose access to their own data

**Prevention**:
1. Atomic migration with transaction rollback
2. Feature flag for gradual rollout
3. Test harness validates allow/deny cases before production
4. Rollback playbook with <5min execution time

**Test Cases**: T50-T53 validate both allow and deny paths

---

## 3. Negative Test Requirements

| Test ID | Scenario | Expected Result | Owner |
|---------|----------|-----------------|-------|
| T51 | Non-participant accesses chat attachment | 403 Forbidden | @Sentinel |
| T52b | Non-owner accesses task image | 403 Forbidden | @Sentinel |
| T51b | Anonymous accesses chat attachment | 403/JWT error | @Sentinel |
| T56 | Anonymous accesses task images | 403/JWT error | @Sentinel |
| T57 | Anonymous accesses avatars | 403/JWT error | @Sentinel |

---

## 4. Security Invariants

| Invariant | How Enforced | How Verified |
|-----------|--------------|--------------|
| DB stores paths only | Code review | Grep for signed_url in schema |
| RLS prevents cross-user access | Policy + helpers | T51, T52b tests |
| Admin access logged | `admin_logs` table triggers | Query admin_logs after admin test |
| Signed URLs expire | TTL in createSignedUrl | Wait test + expiry check |
| Cache bounded | `_maxCacheSize = 1000` | Unit test for eviction |

---

## 5. Residual Risks (After Mitigation)

| Risk | Level | Notes |
|------|-------|-------|
| Compromised admin account | Medium | Mitigated by MFA, audit logs, least privilege |
| Signed URL leak via user action | Low | Accepted - short TTL, HTTPS |
| Feature flag bypass | Low | Fallback to broad policies if flag fails |
| Path structure change | Low | Monitored via migration reviews |

---

**Document Version**: 1.0  
**Next Step**: Create API contracts
