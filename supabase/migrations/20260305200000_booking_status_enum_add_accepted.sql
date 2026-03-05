-- Allow booking_status_enum to accept value 'accepted' for backward compatibility.
-- Some payment/recovery paths (e.g. older edge or RPC) may write 'accepted'; semantically
-- it means paid_request_pending (payment secured, awaiting provider accept). App maps both to paidRequestPending.
-- New code should use paid_request_pending only.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum
    WHERE enumtypid = 'public.booking_status_enum'::regtype
      AND enumlabel = 'accepted'
  ) THEN
    ALTER TYPE public.booking_status_enum ADD VALUE 'accepted';
  END IF;
END
$$;
