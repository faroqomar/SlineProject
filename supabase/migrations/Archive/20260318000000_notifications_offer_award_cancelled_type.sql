-- Allow notification type 'offer_award_cancelled' for cancel_awarded_offer RPC.
ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_type_check;
ALTER TABLE public.notifications ADD CONSTRAINT notifications_type_check
  CHECK (type = ANY (ARRAY[
    'offer', 'message', 'system', 'booking', 'task', 'payment', 'review',
    'offer_awarded', 'payment_required', 'work_active', 'award_expired',
    'offer_award_cancelled'
  ]::text[]));
