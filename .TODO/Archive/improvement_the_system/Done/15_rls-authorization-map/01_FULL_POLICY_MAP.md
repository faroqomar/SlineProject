# 01_FULL_POLICY_MAP — Live `pg_policies` Evidence

> Extracted: 2026-03-06 from project `isddrknbjsgaantjojhm` (production)

## accounts

| Policy                    | Roles         | CMD    | qual                                            | with_check |
| ------------------------- | ------------- | ------ | ----------------------------------------------- | ---------- |
| `accounts_service_policy` | service_role  | ALL    | `true`                                          | `true`     |
| `accounts_select_policy`  | authenticated | SELECT | `(owner_id IS NULL) OR (owner_id = auth.uid())` | —          |
| `accounts_insert_policy`  | authenticated | INSERT | —                                               | `false`    |
| `accounts_update_policy`  | authenticated | UPDATE | `false`                                         | `false`    |
| `accounts_delete_policy`  | authenticated | DELETE | `false`                                         | —          |

✅ **Secure**: Authenticated users can read own + system accounts. All writes blocked.

---

## activity_log

| Policy                                   | Roles      | CMD    | qual                   | with_check |
| ---------------------------------------- | ---------- | ------ | ---------------------- | ---------- |
| `Users can view their own activity logs` | **public** | SELECT | `auth.uid() = user_id` | —          |

⚠️ **Role issue**: Uses `public` instead of `authenticated`.

---

## admin_approvals / admin_case_notes / admin_case_timeline / admin_pii_access_logs

| Policy               | Roles        | CMD | qual   | with_check |
| -------------------- | ------------ | --- | ------ | ---------- |
| `*_service_role_all` | service_role | ALL | `true` | `true`     |

✅ **Secure**: service_role only.

---

## admin_logs

| Policy                         | Roles      | CMD    | qual                                        | with_check |
| ------------------------------ | ---------- | ------ | ------------------------------------------- | ---------- |
| `Service Role can insert logs` | **public** | INSERT | —                                           | `true`     |
| `Admins can view all logs`     | **public** | SELECT | `EXISTS(admin_users WHERE id = auth.uid())` | —          |

🔴 **CRITICAL**: INSERT policy on `public` role with `with_check = true` — **any request** (even anon if granted) can insert log rows. Should be `service_role` only.

---

## admin_users

| Policy                          | Roles         | CMD    | qual              | with_check |
| ------------------------------- | ------------- | ------ | ----------------- | ---------- |
| `Users can view own admin data` | **public**    | SELECT | `auth.uid() = id` | —          |
| `admin_users_self_select`       | authenticated | SELECT | `id = auth.uid()` | —          |

⚠️ Duplicate policy (harmless but messy).

---

## audit_logs

| Policy                      | Roles         | CMD    | qual                                                          | with_check |
| --------------------------- | ------------- | ------ | ------------------------------------------------------------- | ---------- |
| `audit_logs_service_policy` | service_role  | ALL    | `true`                                                        | `true`     |
| `audit_logs_select_policy`  | authenticated | SELECT | `actor_user_id = auth.uid() OR EXISTS(journals→own accounts)` | —          |
| `audit_logs_insert_policy`  | authenticated | INSERT | —                                                             | `false`    |
| `audit_logs_update_policy`  | authenticated | UPDATE | `false`                                                       | `false`    |
| `audit_logs_delete_policy`  | authenticated | DELETE | `false`                                                       | —          |

✅ **Secure**: User can only see own audit trail.

---

## availability_slots

| Policy              | Roles         | CMD    | qual                       | with_check                 |
| ------------------- | ------------- | ------ | -------------------------- | -------------------------- |
| `slots_select_read` | authenticated | SELECT | `true`                     | —                          |
| `slots_write_owner` | authenticated | ALL    | `provider_id = auth.uid()` | `provider_id = auth.uid()` |

✅ **Secure**.

---

## bookings

| Policy                        | Roles         | CMD    | qual                                   | with_check                                     |
| ----------------------------- | ------------- | ------ | -------------------------------------- | ---------------------------------------------- |
| `bookings_select_by_parties`  | authenticated | SELECT | `client_id = uid OR provider_id = uid` | —                                              |
| `bookings_select_parties`     | **public**    | SELECT | `uid = client_id OR uid = provider_id` | —                                              |
| `bookings_insert_by_client`   | authenticated | INSERT | —                                      | `client_id = uid AND NOT EXISTS(blocked slot)` |
| `bookings_insert_client`      | **public**    | INSERT | —                                      | `auth.uid() = client_id`                       |
| `bookings_update_by_provider` | authenticated | UPDATE | `provider_id = uid`                    | `provider_id = uid`                            |
| `bookings_cancel_by_client`   | authenticated | UPDATE | `client_id = uid`                      | `client_id = uid AND status = 'canceled'`      |
| `bookings_update_status_only` | **public**    | UPDATE | `uid = client_id OR uid = provider_id` | **NULL** ❌                                    |
| `bookings_deny_delete`        | **public**    | DELETE | `false`                                | —                                              |

🔴 **CRITICAL**: `bookings_update_status_only` on `public` role has **NULL with_check** — any authenticated-level user who is a party can set any column they want, not just status.
🔴 **RISK**: `bookings_insert_client` on `public` is redundant with the stricter `authenticated` policy but opens a weaker path.

---

## categories

| Policy                  | Roles         | CMD    | qual   | with_check |
| ----------------------- | ------------- | ------ | ------ | ---------- |
| `categories_select_all` | authenticated | SELECT | `true` | —          |

✅ **Secure**.

---

## change_requests

| Policy                        | Roles      | CMD    | qual                                                 | with_check                                            |
| ----------------------------- | ---------- | ------ | ---------------------------------------------------- | ----------------------------------------------------- |
| `change_requests_select`      | **public** | SELECT | `requester_id = uid OR is_work_log_participant(...)` | —                                                     |
| `change_requests_insert`      | **public** | INSERT | —                                                    | `requester_id = uid AND is_work_log_participant(...)` |
| `change_requests_soft_delete` | **public** | UPDATE | `requester_id = uid`                                 | **NULL** ⚠️                                           |

⚠️ All on `public`. Missing `with_check` on UPDATE.

---

## conversations

| Policy                                | Roles         | CMD    | qual                               | with_check                                        |
| ------------------------------------- | ------------- | ------ | ---------------------------------- | ------------------------------------------------- |
| `Allow users to read conversations`   | **public**    | SELECT | `uid = user1_id OR uid = user2_id` | —                                                 |
| `Users can view their conversations`  | **public**    | SELECT | `uid = user1_id OR uid = user2_id` | —                                                 |
| `conversations_select`                | authenticated | SELECT | same                               | —                                                 |
| `conversations_select_by_participant` | authenticated | SELECT | same                               | —                                                 |
| `conversations_select_participants`   | authenticated | SELECT | same                               | —                                                 |
| `Users can insert conversation...`    | **public**    | INSERT | —                                  | `uid = user1_id OR uid = user2_id`                |
| `conversations_insert`                | authenticated | INSERT | —                                  | `is_client(uid)... user1 OR user2... not null...` |
| `conversations_insert_client_only`    | authenticated | INSERT | —                                  | `initiated_by = uid... favorites/task check...`   |
| `conversations_update`                | authenticated | UPDATE | `user1 OR user2 = uid`             | `user1 OR user2 = uid`                            |

⚠️ **5 redundant SELECT policies**. The `public` INSERT policy is weaker than the `authenticated` ones.

---

## conversation_presence

✅ All `authenticated`. Well-scoped.

---

## direct_offers

| Policy                 | Roles         | CMD    | qual                                     | with_check                                                 |
| ---------------------- | ------------- | ------ | ---------------------------------------- | ---------------------------------------------------------- |
| `direct_offers_select` | authenticated | SELECT | `client_id = uid OR freelancer_id = uid` | —                                                          |
| `direct_offers_insert` | authenticated | INSERT | —                                        | `freelancer_id = uid AND EXISTS(conversation participant)` |
| `direct_offers_update` | authenticated | UPDATE | `client_id = uid OR freelancer_id = uid` | same                                                       |
| `direct_offers_delete` | authenticated | DELETE | `false`                                  | —                                                          |

✅ **Secure**. Delete blocked.

---

## disputes

✅ All `authenticated`. `complainant_id = uid`.

---

## extension_requests

| Policy                      | Roles      | CMD    | qual                                            | with_check                                       |
| --------------------------- | ---------- | ------ | ----------------------------------------------- | ------------------------------------------------ |
| `extension_requests_select` | **public** | SELECT | `requester_id = uid OR is_work_log_participant` | —                                                |
| `extension_requests_insert` | **public** | INSERT | —                                               | `requester_id = uid AND is_work_log_participant` |

⚠️ On `public` but guarded by `auth.uid()`.

---

## favorites / saved_tasks

✅ All `authenticated`. Well-scoped to `uid`.

---

## journal_entries

| Policy                           | Roles         | CMD    | qual                                                   | with_check |
| -------------------------------- | ------------- | ------ | ------------------------------------------------------ | ---------- |
| `journal_entries_service_policy` | service_role  | ALL    | `true`                                                 | `true`     |
| `journal_entries_select_policy`  | authenticated | SELECT | `created_by = uid OR EXISTS(own account ledger lines)` | —          |
| `journal_entries_insert_policy`  | authenticated | INSERT | —                                                      | `false`    |
| `journal_entries_update_policy`  | authenticated | UPDATE | `false`                                                | `false`    |
| `journal_entries_delete_policy`  | authenticated | DELETE | `false`                                                | —          |

✅ **Secure**: Authenticated blocked from writes.

---

## ledger_lines

| Policy                        | Roles         | CMD    | qual                                                        | with_check |
| ----------------------------- | ------------- | ------ | ----------------------------------------------------------- | ---------- |
| `ledger_lines_service_policy` | service_role  | ALL    | `true`                                                      | `true`     |
| `ledger_lines_select_policy`  | authenticated | SELECT | `EXISTS(accounts WHERE owner_id = uid OR owner_id IS NULL)` | —          |
| `ledger_lines_insert_policy`  | authenticated | INSERT | —                                                           | `false`    |
| `ledger_lines_update_policy`  | authenticated | UPDATE | `false`                                                     | `false`    |
| `ledger_lines_delete_policy`  | authenticated | DELETE | `false`                                                     | —          |

✅ **Secure**: Financial data locked to service_role writes.

---

## messages

| Policy                                       | Roles         | CMD    | qual                                     | with_check                                                    |
| -------------------------------------------- | ------------- | ------ | ---------------------------------------- | ------------------------------------------------------------- |
| `Allow users to read messages`               | **public**    | SELECT | `auth.uid() IS NOT NULL`                 | —                                                             |
| `Users can view their conversation messages` | **public**    | SELECT | `EXISTS(conversation participant check)` | —                                                             |
| `Users can view their messages`              | **public**    | SELECT | `uid = sender_id OR uid = receiver_id`   | —                                                             |
| `messages_select`                            | authenticated | SELECT | `is_conversation_participant(...)`       | —                                                             |
| `messages_select_by_participant`             | authenticated | SELECT | `EXISTS(conversations...)`               | —                                                             |
| `messages_select_participants`               | authenticated | SELECT | `EXISTS(conversations...)`               | —                                                             |
| `Allow users to insert messages`             | **public**    | INSERT | —                                        | `auth.uid() IS NOT NULL`                                      |
| `Users can insert their own messages`        | **public**    | INSERT | —                                        | `uid = sender_id`                                             |
| `messages_insert`                            | authenticated | INSERT | —                                        | `is_conversation_participant AND sender_id = uid`             |
| `messages_insert_by_sender`                  | authenticated | INSERT | —                                        | `sender_id = uid AND EXISTS(convo participant)`               |
| `messages_insert_participants_only`          | authenticated | INSERT | —                                        | `sender_id = uid AND convo participant AND offer-type checks` |
| `messages_update`                            | authenticated | UPDATE | `sender_id = uid`                        | `sender_id = uid`                                             |
| `messages_update_by_receiver`                | authenticated | UPDATE | `receiver_id = uid`                      | `receiver_id = uid`                                           |
| `Users can delete their own messages`        | **public**    | DELETE | `uid = sender_id`                        | —                                                             |
| `messages_delete`                            | authenticated | DELETE | `sender_id = uid`                        | —                                                             |

🔴 **CRITICAL**: `Allow users to insert messages` on `public` with `with_check = auth.uid() IS NOT NULL` — **any authenticated user can insert a message into ANY conversation** regardless of participation. This **bypasses** the conversation-participant constraint.

🔴 **CRITICAL**: `Allow users to read messages` on `public` with `qual = auth.uid() IS NOT NULL` — **any authenticated user can read ALL messages in the system**.

---

## notifications

| Policy                     | Roles      | CMD    | qual            | with_check      |
| -------------------------- | ---------- | ------ | --------------- | --------------- |
| `notifications_select_own` | **public** | SELECT | `user_id = uid` | —               |
| `notifications_update_own` | **public** | UPDATE | `user_id = uid` | `user_id = uid` |

⚠️ On `public` but properly scoped to `auth.uid()`.

---

## portfolio_items

✅ All `authenticated`. Well-scoped.

---

## profiles

| Policy                                 | Roles         | CMD    | qual                                  | with_check  |
| -------------------------------------- | ------------- | ------ | ------------------------------------- | ----------- |
| `profiles_select_self`                 | authenticated | SELECT | `id = uid`                            | —           |
| `profiles_select_conversation_partner` | authenticated | SELECT | `EXISTS(conversations where partner)` | —           |
| `Users can insert their own profile`   | **public**    | INSERT | —                                     | `uid = id`  |
| `Users can update their own profile`   | **public**    | UPDATE | `uid = id`                            | **NULL** ⚠️ |
| `profiles_update_self`                 | authenticated | UPDATE | `id = uid`                            | `id = uid`  |
| `Users can delete their own profile`   | **public**    | DELETE | `uid = id`                            | —           |

⚠️ `public` INSERT is needed for signup flow (profile created before session is fully `authenticated`). But `public` UPDATE with NULL `with_check` is a risk — could theoretically allow updating other users' fields if `qual` is bypassed.

---

## report_actions / reports

| Policy                                    | Roles         | CMD    | qual                           | with_check               |
| ----------------------------------------- | ------------- | ------ | ------------------------------ | ------------------------ |
| `Service role full access report_actions` | **public**    | ALL    | `auth.role() = 'service_role'` | **NULL**                 |
| `report_actions_service_role_all`         | service_role  | ALL    | `true`                         | `true`                   |
| `Service role full access reports`        | **public**    | ALL    | `auth.role() = 'service_role'` | **NULL**                 |
| `reports_service_role_all`                | service_role  | ALL    | `true`                         | `true`                   |
| `reports_insert_own`                      | authenticated | INSERT | —                              | `reporter_user_id = uid` |
| `reports_select_own`                      | authenticated | SELECT | `reporter_user_id = uid`       | —                        |

⚠️ `public`-role ALL with `qual = auth.role() = 'service_role'`: functionally correct but anti-pattern. The `service_role` policy already covers this.

---

## services

| Policy                                | Roles      | CMD    | qual                  | with_check            |
| ------------------------------------- | ---------- | ------ | --------------------- | --------------------- |
| `Public can view active services`     | **public** | SELECT | `status = 'active'`   | —                     |
| `Freelancers can view own services`   | **public** | SELECT | `uid = freelancer_id` | —                     |
| `Freelancers can insert own services` | **public** | INSERT | —                     | `uid = freelancer_id` |
| `Freelancers can update own services` | **public** | UPDATE | `uid = freelancer_id` | **NULL** ⚠️           |
| `Freelancers can delete own services` | **public** | DELETE | `uid = freelancer_id` | —                     |

⚠️ All on `public`. Missing `with_check` on UPDATE.

---

## support_tickets / ticket_messages

✅ All `authenticated`. Admin-check via `EXISTS(admin_users)`.

---

## system_config

✅ All `authenticated` with admin check. Duplicate policies but harmless.

---

## task_requests

| Policy               | Roles         | CMD    | qual                                        | with_check                                      |
| -------------------- | ------------- | ------ | ------------------------------------------- | ----------------------------------------------- |
| `tr_select`          | authenticated | SELECT | `freelancer_id = uid OR EXISTS(task owner)` | —                                               |
| `tr_insert`          | **public**    | INSERT | —                                           | `freelancer_id = uid AND task open AND not own` |
| `tr_update`          | authenticated | UPDATE | `freelancer_id = uid AND pending`           | same                                            |
| `tr_update_by_owner` | authenticated | UPDATE | `EXISTS(task owner)`                        | `EXISTS(task owner)`                            |
| `tr_delete`          | authenticated | DELETE | `freelancer_id = uid AND pending`           | —                                               |

⚠️ INSERT on `public` but well-guarded by business logic in `with_check`.

---

## tasks

| Policy                                        | Roles         | CMD    | qual                                      | with_check       |
| --------------------------------------------- | ------------- | ------ | ----------------------------------------- | ---------------- |
| `tasks_select_authenticated_open_or_involved` | authenticated | SELECT | `open OR owner OR freelancer OR assigned` | —                |
| `tasks_insert_owner`                          | **public**    | INSERT | —                                         | `owner_id = uid` |
| `tasks_update_owner`                          | **public**    | UPDATE | `owner_id = uid`                          | **NULL** ⚠️      |
| `tasks_update_involved`                       | authenticated | UPDATE | `owner OR freelancer OR assigned = uid`   | same             |
| `tasks_delete_owner`                          | authenticated | DELETE | `owner_id = uid`                          | —                |

⚠️ `tasks_update_owner` on `public` with NULL `with_check`.

---

## wallet_transactions

| Policy              | Roles      | CMD    | qual            | with_check |
| ------------------- | ---------- | ------ | --------------- | ---------- |
| `wallet_deny_mod`   | **public** | ALL    | `false`         | —          |
| `wallet_select_own` | **public** | SELECT | `uid = user_id` | —          |

✅ Frozen table. Reads only.

---

## work_contracts

| Policy                  | Roles      | CMD    | qual                           | with_check |
| ----------------------- | ---------- | ------ | ------------------------------ | ---------- |
| `work_contracts_select` | **public** | SELECT | `is_work_log_participant(...)` | —          |

⚠️ On `public` but properly guarded.

---

## work_logs

| Policy                  | Roles      | CMD    | qual                                                    | with_check                                         |
| ----------------------- | ---------- | ------ | ------------------------------------------------------- | -------------------------------------------------- |
| `work_logs_select`      | **public** | SELECT | `(private AND author) OR (not private AND participant)` | —                                                  |
| `work_logs_insert`      | **public** | INSERT | —                                                       | `uid = author_id AND is_work_log_participant(...)` |
| `work_logs_deny_update` | **public** | UPDATE | `false`                                                 | —                                                  |
| `work_logs_deny_delete` | **public** | DELETE | `false`                                                 | —                                                  |

✅ Immutable. Well-guarded.

---

## withdrawal_requests

✅ All `authenticated` + service_role. Well-scoped.
