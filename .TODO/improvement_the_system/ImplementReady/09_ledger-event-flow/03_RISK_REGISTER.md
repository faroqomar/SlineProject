# Risk Register: Ledger Event Flow

## 1. Current System Risks (Pre-Improvement)

| Risk ID  | Risk Description                                                                                                       | Severity | Likelihood | Impact                                      | Evidence                                                 |
| -------- | ---------------------------------------------------------------------------------------------------------------------- | -------- | ---------- | ------------------------------------------- | -------------------------------------------------------- |
| R-LED-01 | **Ledger/Status Mismatch**: A booking is marked `completed` but the `release_with_fee` event fails or is never called. | High     | Medium     | Financial leakage (unpaid providers).       | `SUPABASE_SETUP.md:L1847` (Manual trigger in RPC logic). |
| R-LED-02 | **Idempotency Collision**: Weak idempotency key leads to a legit transaction being rejected as a replay.               | Medium   | Low        | User frustration / Support tickets.         | `LedgerService.dart:L13-19` (Deterministic UUIDv5).      |
| R-LED-03 | **Precision Loss**: Rounding errors during fee calculation cause the journal to be unbalanced.                         | High     | Low        | System halt (Unbalanced Journal Exception). | `SUPABASE_SETUP.md:L151` (Internal balancing check).     |

## 2. Risk Mitigation & Improvements

| Risk ID  | Improvement / Mitigation                                                                                              | Residual Risk                      |
| -------- | --------------------------------------------------------------------------------------------------------------------- | ---------------------------------- |
| R-LED-01 | Wrap entity status update AND ledger call in a single atomic DB function.                                             | Low (System-wide DB failure only). |
| R-LED-02 | Incorporate `now()` or a sequence count in the idempotency digest if same-second events are needed.                   | Near Zero.                         |
| R-LED-04 | **Migration Risk**: Moving historical data to the new ledger structure might introduce errors in historical balances. | High                               |
| R-LED-05 | **Complexity Risk**: Double-entry is harder to debug for non-financial developers.                                    | Medium                             |

---

## 3. Production Readiness Severity

**Current Score: 7/10**

- _Reasoning_: The ledger engine `process_payment_event_ledger` is robust and handles the core invariants well, but the orchestration from the Flutter side (two-phase commit for withdrawals) and the lack of comprehensive lifecycle visibility in the documentation are risks for scaling.
