# Skill Selection: 15_rls-authorization-map Audit

## Skills Selected

1.  **RLS & Privilege Boundaries**: The core subject is Supabase Row Level Security. I will analyze the live policies to ensure data isolation.
2.  **Threat Modeling (Security)**: I will adopt an adversarial mindset to find "over-privileged" roles (e.g., `public` having DELETE access) and potential bypasses.
3.  **Evidence-First Reading**: Every claim in the report will be matched to a `CREATE POLICY` statement or a database metadata query.
4.  **Invariants & Contracts**: I will extract the core authorization rules (e.g., "Profile ownership is immutable") that the RLS must enforce.
5.  **Diagram Crafting (Mermaid)**: I will create a high-fidelity authorization flow to replace the static table.
6.  **Observability (Logs/Alerts/Admin Trace)**: I will design logging strategies for RLS denials (`42501` errors) to ensure security events are visible.

## Rationale

This file is a "Matrix" but the current version is "Partial" and lacks the predicates (`qual`). The audit must fill these gaps and verify that the "zero-trust" architecture is actually implemented correctly.

## Skills Intentionally Not Used

- **DB-First Financial Modeling**: Though a ledger exists, the task is about _who_ can access it, not _how_ the balance is calculated.
- **State Machine & Lifecycle**: RLS is primarily about declarative access control at a point in time, not sequential state transitions.
