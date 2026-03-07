# Risk Register: 16_escrow-invariants-idempotency.md

## J1) Risks in Current System (Unpatched)

| Risk ID | Risk Description              | Severity  | Likelihood | Impact                       | Evidence                                                                                   |
| :------ | :---------------------------- | :-------- | :--------- | :--------------------------- | :----------------------------------------------------------------------------------------- |
| **R1**  | **Double Release of Escrow**  | 🔴 High   | 🟠 Medium  | Financial loss, broken trust | `extensions.digest` uses `now()` in `rpc_approve_delivery`                                 |
| **R2**  | **Race Condition on Release** | 🟡 Medium | 🟡 Low     | Inconsistent ledger balances | Missing `FOR UPDATE` lock on entity row before ledger call                                 |
| **R3**  | **Orphaned Ledger Entries**   | 🟡 Medium | 🟡 Low     | Audit trail mismatch         | Entity status update happens _after_ ledger insert without explicit transaction-fail check |

## J2) Risks Introduced by Improvements

| Risk ID | Risk Description               | Severity  | Likelihood | Mitigation                                                                                                    |
| :------ | :----------------------------- | :-------- | :--------- | :------------------------------------------------------------------------------------------------------------ |
| **M1**  | **Migration Downtime**         | 🟢 Low    | 🟢 Low     | Use `CREATE OR REPLACE FUNCTION` for atomic updates                                                           |
| **M2**  | **Client Compatibility**       | 🟡 Medium | 🟠 Medium  | If switching to Client-Side keys, old app versions must be forced to update or logic must fallback gracefully |
| **M3**  | **Key Collision (Stable Key)** | 🟢 Low    | 🟢 Low     | Using `source_status` in key ensures that if status is unchanged, key is the same, which is exactly the goal  |

---

## Skills applied:

- Threat Modeling (Security)
- Production Migration Planning
- Evidence-First Reading
