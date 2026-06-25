-- ============================================================
-- 024_fix_enrollment_webhook_null_url.sql
-- Fix: null value in column "url" of relation "http_request_queue"
--      violates not-null constraint
--
-- Root cause: notify_admin_on_new_enrollment() reads app.supabase_url
-- and app.service_role_key from PostgreSQL settings. If these settings
-- are not configured, v_supabase_url is NULL, making v_function_url
-- NULL — which causes pg_net to throw a NOT NULL constraint violation
-- on http_request_queue.url.
--
-- Fix: Guard the HTTP call so it is skipped when the URL or key is
-- missing. The enrollment row is still created successfully; the
-- admin notification just won't fire until the settings are added.
-- ============================================================

CREATE OR REPLACE FUNCTION notify_admin_on_new_enrollment()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_supabase_url     TEXT := current_setting('app.supabase_url', true);
  v_service_role_key TEXT := current_setting('app.service_role_key', true);
  v_function_url     TEXT;
BEGIN
  -- ✅ Guard: skip HTTP call if the required settings are not configured.
  --    This prevents a NOT NULL violation on http_request_queue.url.
  IF v_supabase_url IS NULL OR v_supabase_url = ''
  OR v_service_role_key IS NULL OR v_service_role_key = ''
  THEN
    RETURN NEW;
  END IF;

  -- Build the Edge Function URL
  v_function_url := v_supabase_url || '/functions/v1/notify-admin-enrollment';

  -- Send HTTP request to the Edge Function via pg_net
  PERFORM net.http_post(
    url     := v_function_url,
    headers := jsonb_build_object(
      'Content-Type',  'application/json',
      'Authorization', 'Bearer ' || v_service_role_key
    ),
    body := jsonb_build_object(
      'type',   'INSERT',
      'table',  'parent_enrollments',
      'record', row_to_json(NEW)
    )
  );

  RETURN NEW;
END;
$$;

-- Re-create the trigger (no change needed here, just kept for reference)
DROP TRIGGER IF EXISTS trigger_notify_admin_on_enrollment ON parent_enrollments;
CREATE TRIGGER trigger_notify_admin_on_enrollment
  AFTER INSERT ON parent_enrollments
  FOR EACH ROW
  EXECUTE FUNCTION notify_admin_on_new_enrollment();

SELECT '024 - Fixed enrollment webhook null-URL guard applied successfully!' AS status;

-- ============================================================
-- OPTIONAL: To fully enable admin push notifications, run the
-- following in Supabase Dashboard > SQL Editor:
--
--   ALTER DATABASE postgres
--     SET "app.supabase_url" = 'https://<YOUR_PROJECT_REF>.supabase.co';
--
--   ALTER DATABASE postgres
--     SET "app.service_role_key" = '<YOUR_SERVICE_ROLE_KEY>';
--
-- Then reload the configuration:
--   SELECT pg_reload_conf();
-- ============================================================
