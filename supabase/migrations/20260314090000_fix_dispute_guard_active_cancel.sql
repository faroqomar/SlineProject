-- Align dispute status trigger with canonical admin workflow:
-- open -> active
-- open|active -> canceled
-- active -> resolved

CREATE OR REPLACE FUNCTION public.fn_dispute_guard()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
BEGIN
  IF OLD.status IS NOT DISTINCT FROM NEW.status THEN
    RETURN NEW;
  END IF;

  IF OLD.status = 'open' AND NEW.status IN ('active', 'canceled') THEN
    RETURN NEW;
  END IF;

  IF OLD.status = 'active' AND NEW.status IN ('resolved', 'canceled') THEN
    RETURN NEW;
  END IF;

  RAISE EXCEPTION 'Invalid dispute status transition from % to %', OLD.status, NEW.status;
END;
$function$;
