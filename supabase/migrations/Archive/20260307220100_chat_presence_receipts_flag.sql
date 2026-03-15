-- Feature flag for presence and receipt UI (typing indicator, delivered/read ticks).
-- When 'false': no presence upsert, no receipt ticks (single tick only).
INSERT INTO public.app_config (key, value, description)
VALUES (
  'chat_presence_receipts_enabled',
  'true',
  'Enable typing indicator and delivered/read receipt ticks in chat. Set to false to disable.'
)
ON CONFLICT (key) DO NOTHING;
