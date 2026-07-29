-- ============================================================
-- 041_content_push_notification_webhook.sql
-- Queue OneSignal push delivery whenever a course or lesson is
-- published for the first time. Draft saves and later edits do not
-- send duplicate notifications.
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

CREATE OR REPLACE FUNCTION notify_content_push_on_publish()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
  v_supabase_url TEXT := current_setting('app.supabase_url', true);
  v_service_role_key TEXT := current_setting('app.service_role_key', true);
  v_old_record JSONB := NULL;
BEGIN
  IF NOT (
    (TG_OP = 'INSERT' AND NEW.is_published IS TRUE)
    OR
    (
      TG_OP = 'UPDATE'
      AND NEW.is_published IS TRUE
      AND OLD.is_published IS NOT TRUE
    )
  ) THEN
    RETURN NEW;
  END IF;

  -- Never make saving content fail when deployment settings are missing.
  IF NULLIF(v_supabase_url, '') IS NULL
     OR NULLIF(v_service_role_key, '') IS NULL THEN
    RAISE WARNING
      'Content push skipped: app.supabase_url or app.service_role_key is not configured';
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' THEN
    v_old_record := to_jsonb(OLD);
  END IF;

  PERFORM net.http_post(
    url := rtrim(v_supabase_url, '/') || '/functions/v1/notify-content-update',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_service_role_key
    ),
    body := jsonb_build_object(
      'type', TG_OP,
      'table', TG_TABLE_NAME,
      'schema', TG_TABLE_SCHEMA,
      'record', to_jsonb(NEW),
      'old_record', v_old_record
    ),
    timeout_milliseconds := 10000
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_course_push_on_publish ON courses;
CREATE TRIGGER trigger_course_push_on_publish
AFTER INSERT OR UPDATE OF is_published ON courses
FOR EACH ROW
EXECUTE FUNCTION notify_content_push_on_publish();

DROP TRIGGER IF EXISTS trigger_lesson_push_on_publish ON lessons;
CREATE TRIGGER trigger_lesson_push_on_publish
AFTER INSERT OR UPDATE OF is_published ON lessons
FOR EACH ROW
EXECUTE FUNCTION notify_content_push_on_publish();

REVOKE ALL ON FUNCTION notify_content_push_on_publish() FROM PUBLIC;

SELECT '041 - Content publish push webhook installed successfully' AS status;

-- Required once per hosted database:
-- ALTER DATABASE postgres
--   SET "app.supabase_url" = 'https://ubjhdafxmncfbaldfivd.supabase.co';
-- ALTER DATABASE postgres
--   SET "app.service_role_key" = '<SUPABASE_SERVICE_ROLE_KEY>';
-- SELECT pg_reload_conf();
