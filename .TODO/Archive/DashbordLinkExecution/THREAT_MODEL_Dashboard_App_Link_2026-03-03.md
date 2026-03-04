# Threat Model - Dashboard App Link (2026-03-03)

## Scope
- Force logout and moderation guard paths.
- Report/dispute write paths.
- Public config read path.

## Abuse Cases

1. Session revocation bypass
- Threat: user keeps stale session after admin force logout.
- Mitigation: compare `force_logout_after` to session issue time on app start/resume.

2. Moderation bypass
- Threat: suspended/banned user still submits task/chat/wallet actions.
- Mitigation: centralized guard check before sensitive actions.

3. Report spam / forged ownership
- Threat: user floods reports or reports unrelated entities.
- Mitigation: RLS restrict insert to `reporter_user_id = auth.uid()`, optional server rate limit.

4. Unauthorized config read or write
- Threat: app clients read or mutate private config.
- Mitigation: read-only public subset path; no client write policies.

5. PII leakage via logs
- Threat: reasons and metadata include sensitive data in client logs.
- Mitigation: sanitize logs, no payload dumps for report/dispute reasons.

## Negative Test Checklist
- Suspended user cannot send chat message.
- Banned user cannot request withdrawal.
- Revoked session forced out on resume.
- Anonymous user cannot insert report/dispute.
- Authenticated non-admin cannot update `system_config`.
