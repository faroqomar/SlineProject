# Supabase scripts (run manually)

Scripts here change objects (e.g. `storage.objects`) that migrations cannot alter because of ownership. Run them in **Supabase Dashboard → SQL Editor**.

| Script | When to run |
|--------|-------------|
| `chat_attachments_storage_policies.sql` | Chat photos show "File not available." — run once to add SELECT/INSERT policies for the `chat-attachments` bucket. |
