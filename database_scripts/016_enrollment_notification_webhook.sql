-- 016_enrollment_notification_webhook.sql
-- يقوم بإنشاء Webhook تلقائي يُطلق عند إضافة صف جديد في parent_enrollments
-- يستدعي Edge Function تُرسل إشعار Push للأدمن عبر OneSignal

-- ======================================================
-- الطريقة 1: استخدام pg_net لإرسال HTTP Request مباشرة
-- (يجب تفعيل امتداد pg_net في Supabase Dashboard)
-- ======================================================

-- تفعيل امتداد pg_net (افعل هذا من Supabase Dashboard > Database > Extensions)
-- CREATE EXTENSION IF NOT EXISTS pg_net;

-- إنشاء Function تُرسل الإشعار عبر HTTP Request
CREATE OR REPLACE FUNCTION notify_admin_on_new_enrollment()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_supabase_url TEXT := current_setting('app.supabase_url', true);
  v_service_role_key TEXT := current_setting('app.service_role_key', true);
  v_function_url TEXT;
BEGIN
  -- URL الـ Edge Function الخاصة بنا
  v_function_url := v_supabase_url || '/functions/v1/notify-admin-enrollment';

  -- إرسال HTTP Request للـ Edge Function
  PERFORM net.http_post(
    url := v_function_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_service_role_key
    ),
    body := jsonb_build_object(
      'type', 'INSERT',
      'table', 'parent_enrollments',
      'record', row_to_json(NEW)
    )
  );

  RETURN NEW;
END;
$$;

-- إنشاء Trigger يُطلق الـ Function عند إضافة طلب شراء جديد
DROP TRIGGER IF EXISTS trigger_notify_admin_on_enrollment ON parent_enrollments;
CREATE TRIGGER trigger_notify_admin_on_enrollment
  AFTER INSERT ON parent_enrollments
  FOR EACH ROW
  EXECUTE FUNCTION notify_admin_on_new_enrollment();

-- ======================================================
-- الطريقة 2: إنشاء Database Webhook يدوياً من Supabase Dashboard
-- ======================================================
-- اذهب إلى: Database > Webhooks > Create a new hook
-- Name: notify_admin_on_enrollment
-- Table: parent_enrollments
-- Events: INSERT
-- Type: HTTP Request (POST)
-- URL: https://<YOUR_PROJECT_REF>.supabase.co/functions/v1/notify-admin-enrollment
-- HTTP Headers:
--   Authorization: Bearer <YOUR_SERVICE_ROLE_KEY>
--   Content-Type: application/json
