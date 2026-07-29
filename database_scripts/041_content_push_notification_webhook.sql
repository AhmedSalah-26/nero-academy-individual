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
  v_function_url CONSTANT TEXT :=
    'https://ubjhdafxmncfbaldfivd.supabase.co/functions/v1/notify-content-update';
  v_webhook_key TEXT;
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

  -- The public project API key is stored encrypted in Supabase Vault instead
  -- of relying on custom PostgreSQL settings, which hosted projects may block.
  SELECT decrypted_secret
  INTO v_webhook_key
  FROM vault.decrypted_secrets
  WHERE name = 'content_push_webhook_key'
  ORDER BY created_at DESC
  LIMIT 1;

  -- Never make saving content fail when deployment configuration is missing.
  IF NULLIF(v_webhook_key, '') IS NULL THEN
    RAISE WARNING
      'Content push skipped: Vault secret content_push_webhook_key is not configured';
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' THEN
    v_old_record := to_jsonb(OLD);
  END IF;

  PERFORM net.http_post(
    url := v_function_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_webhook_key,
      'apikey', v_webhook_key
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

-- Required once per hosted database (use the project's public anon key):
-- SELECT vault.create_secret(
--   '<SUPABASE_ANON_KEY>',
--   'content_push_webhook_key',
--   'Authenticates the content publish database webhook'
-- );
