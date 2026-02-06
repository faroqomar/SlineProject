# Admin Dashboard - Payments & Wallet Control

This module allows Admins to monitor the flow of money, debug gateway errors, and manually intervene in financial transactions.

## 1. Wallet Management (`/finance/wallets`)

**Purpose**: Monitor and correct user balances.

### 1.1 Features
- **View Balance**: See 'Available' vs 'Held' (Escrow) balance for any user.
- **Transaction History**: List of all `wallet_transactions` for a user.
- **Manual Adjustment (Danger Zone)**:
    - Ability to Credit/Debit a user manually (e.g., "Compassionate Refund", "Correction").
    - **Requirement**: Must require `Super Admin` role and a mandatory "Reason" field logged in Audit logs.

### 1.2 Database Reference
- **Table**: `wallet_transactions`
- **Enums**: `payment_status_enum` ('unpaid', 'held', 'released', 'refunded')

---

## 2. Payment Gateway Logs (`/finance/logs`)

**Purpose**: Debug failed payments from TBI or QiCard.

### 2.1 The Problem
When a user says "I paid but the app says pending", the Admin needs to check the **Raw Gateway Response**.

### 2.2 Proposed Schema (New Table)
We recommend creating a `payment_gateway_logs` table to store raw requests/responses.

```sql
create table payment_gateway_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id),
  gateway text not null, -- 'tbi' | 'qicard'
  endpoint text not null, -- '/payment/init' | '/payment/callback'
  request_payload jsonb,
  response_payload jsonb,
  status_code int,
  created_at timestamptz default now()
);
```

### 2.3 Dashboard UI
- **Filter**: By Gateway (TBI/Qi), Status (200/400/500), Date.
- **Detail View**: JSON Viewer for Request/Response to see exactly what the bank returned.

---

## 3. Escrow Controls

**Purpose**: Force-release or Refund money when the App logic gets stuck.

### 3.1 Actions
- **Force Release**: Move funds from `held` -> `released` for a specific Booking/Task.
- **Force Refund**: Move funds from `held` -> `refunded` (Back to Client).
- **Protocol**: These actions should only be available inside the **Dispute Resolution** module (`/disputes/[id]`), but listed here for architectural visibility.
