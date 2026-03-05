# Observability: Proposals 2026-03-04

**Purpose**: Privacy-safe proposal telemetry for rollout and debugging.

## Events (AppLogger; no PII)

| Event | Where | Payload (sanitized) |
|-------|--------|---------------------|
| Proposal submit attempt | TaskRequestsService / ProposalRepository | taskId (no user id) |
| Proposal submit success | TaskRequestsService / ProposalRepository | requestId |
| Proposal submit failure (role) | TaskRequestsService | tag only |
| Proposal replace | ProposalRepository | taskId |
| Proposal reject | ProposalRepository | requestId |
| Award start / success / failure | ProposalAwardRepository / TaskService | requestId |
| Finalize (pay) start / success / failure | ProposalAwardRepository / TenderPaymentCoordinator | requestId |
| Payment resume opened | Launcher (Inbox/Work/Next Actions) | source (e.g. inbox_tab) |
| Cancel awarded | ProposalAwardRepository | requestId |
| Auth rejection | RPC returns error; log in repository | tag only |

## Where emitted

- Repositories: ProposalRepository, ProposalAwardRepository, TaskRequestsService, TaskService.
- ViewModels: TaskRequestsViewModel, TenderPaymentViewModel (and proposals ViewModels when wired).
- No raw payment payloads, no profile fields, no cross-user data in logs.

## Verification

- @ThreatModeler: confirm no PII/oversharing (no emails, UUIDs of other users, amounts in logs if sensitive).
- Rollout: use events to detect finalize failure spikes and auth rejection spikes.
