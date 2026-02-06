# Admin Dashboard - System Configuration

**"The Cockpit Controls"**
These settings affect the active mobile application for ALL users instantly.

## 1. Feature Flags (Remote Config)

**Purpose**: Enable/Disable features without submitting a new App Store build.

### 1.1 Suggested Implementation
Create a `system_config` table in Supabase.

```sql
create table system_config (
  key text primary key, -- e.g., 'maintenance_mode', 'enable_payments'
  value jsonb not null, -- true/false or complex object
  description text,
  updated_at timestamptz default now()
);
```

### 1.2 Common Flags
| Key | Value | Description |
|---|---|---|
| `maintenance_mode` | `false` | If true, app shows "Under Maintenance" screen. |
| `min_app_version` | `"2.1.0"` | Force update for older apps. |
| `enable_signup` | `true` | Temporarily stop new users. |
| `payment_gateways` | `{"tbi": true, "qi": false}` | Toggle gateways on crash. |

## 2. Global Announcements

**Purpose**: Show a banner or modal to users (e.g., "Server restarting in 10 mins").

- **UI**: Simple form to set Title, Body, and Type (Info/Warning/Critical).
- **Backend**: Updates a row in `system_config` or inserts into `notifications` aimed at `all`.

## 3. Reference Data Management

**Purpose**: Edit Categories, Skills, or Tags without touching DB.

- **Categories**: Add new Job Categories, update Icons.
- **Tags**: Manage the list of selectable skills.
