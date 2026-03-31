# 03_ROLE_MIGRATION_PLAN — `public` → `authenticated`

## Principles

1. The `public` role in Supabase maps to the `anon` key and has **no valid session** guarantee.
2. Policies on `public` that check `auth.uid()` function correctly because `auth.uid()` returns NULL for anon, preventing matches. However, this is defense-in-depth, and using `authenticated` is the **explicit** contract.
3. Exception: `profiles` INSERT may need `public` for the initial signup flow where the session is created but the role hasn't transitioned yet. Verify with your auth flow.

## Policy-by-Policy Migration List

### Priority 1: CRITICAL (Security Risk)

| Table        | Policy                           | Current | Target           | Risk if unchanged                                                         |
| ------------ | -------------------------------- | ------- | ---------------- | ------------------------------------------------------------------------- |
| `messages`   | `Allow users to read messages`   | public  | **DROP**         | Allows reading ALL messages with just `auth.uid() IS NOT NULL`            |
| `messages`   | `Allow users to insert messages` | public  | **DROP**         | Allows inserting into ANY conversation with just `auth.uid() IS NOT NULL` |
| `admin_logs` | `Service Role can insert logs`   | public  | **service_role** | Any request can insert fake log entries                                   |

### Priority 2: HIGH (Role Hardening)

| Table           | Policy                                       | Current | Target                           | Notes                                                                |
| --------------- | -------------------------------------------- | ------- | -------------------------------- | -------------------------------------------------------------------- |
| `bookings`      | `bookings_insert_client`                     | public  | **DROP**                         | Redundant with `bookings_insert_by_client` (authenticated, stricter) |
| `bookings`      | `bookings_select_parties`                    | public  | **DROP**                         | Redundant with `bookings_select_by_parties` (authenticated)          |
| `bookings`      | `bookings_update_status_only`                | public  | authenticated + add `with_check` | Missing with_check is critical                                       |
| `tasks`         | `tasks_insert_owner`                         | public  | authenticated                    | Well-guarded but wrong role                                          |
| `tasks`         | `tasks_update_owner`                         | public  | **DROP**                         | Redundant with `tasks_update_involved` (authenticated, stricter)     |
| `task_requests` | `tr_insert`                                  | public  | authenticated                    | Well-guarded but wrong role                                          |
| `messages`      | `Users can insert their own messages`        | public  | **DROP**                         | Redundant with authenticated INSERT policies                         |
| `messages`      | `Users can view their messages`              | public  | **DROP**                         | Redundant with authenticated SELECT policies                         |
| `messages`      | `Users can view their conversation messages` | public  | **DROP**                         | Redundant                                                            |
| `messages`      | `Users can delete their own messages`        | public  | **DROP**                         | Redundant with `messages_delete`                                     |

### Priority 3: MEDIUM (Clean-up)

| Table                 | Policy                               | Current | Target          | Notes                                                            |
| --------------------- | ------------------------------------ | ------- | --------------- | ---------------------------------------------------------------- |
| `conversations`       | `Allow users to read conversations`  | public  | **DROP**        | Redundant with authenticated SELECT                              |
| `conversations`       | `Users can view their conversations` | public  | **DROP**        | Redundant                                                        |
| `conversations`       | `Users can insert conversation...`   | public  | **DROP**        | Redundant; weaker than authenticated policies                    |
| `notifications`       | `notifications_select_own`           | public  | authenticated   | Properly guarded but wrong role                                  |
| `notifications`       | `notifications_update_own`           | public  | authenticated   | Same                                                             |
| `services`            | All 5 policies                       | public  | authenticated   | Well-guarded but wrong role                                      |
| `activity_log`        | `Users can view...`                  | public  | authenticated   |                                                                  |
| `admin_users`         | `Users can view own admin data`      | public  | **DROP**        | Duplicate of `admin_users_self_select` (authenticated)           |
| `change_requests`     | All 3 policies                       | public  | authenticated   |                                                                  |
| `extension_requests`  | All 2 policies                       | public  | authenticated   |                                                                  |
| `work_contracts`      | `work_contracts_select`              | public  | authenticated   |                                                                  |
| `work_logs`           | All 4 policies                       | public  | authenticated   |                                                                  |
| `wallet_transactions` | `wallet_deny_mod`                    | public  | authenticated   |                                                                  |
| `wallet_transactions` | `wallet_select_own`                  | public  | authenticated   |                                                                  |
| `report_actions`      | `Service role full access...`        | public  | **DROP**        | Redundant with service_role policy                               |
| `reports`             | `Service role full access...`        | public  | **DROP**        | Redundant                                                        |
| `profiles`            | `Users can update...`                | public  | **DROP or fix** | Redundant with `profiles_update_self` but with NULL `with_check` |
| `profiles`            | `Users can delete...`                | public  | authenticated   |                                                                  |

### Keep on `public` (Justified)

| Table      | Policy                               | Justification                                                                                                          |
| ---------- | ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------- |
| `profiles` | `Users can insert their own profile` | Required for signup flow before auth session is fully established. `with_check = auth.uid() = id` is sufficient guard. |
| `bookings` | `bookings_deny_delete`               | `qual = false` — harmless deny-all.                                                                                    |

## Total Counts

- **DROP**: 17 redundant policies
- **Migrate** `public → authenticated`: ~15 policies
- **Migrate** `public → service_role`: 1 policy (`admin_logs` insert)
- **Keep** `public`: 2 policies (profiles insert, bookings deny_delete)
