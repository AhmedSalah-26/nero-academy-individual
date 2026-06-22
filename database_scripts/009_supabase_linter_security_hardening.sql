-- 009_supabase_linter_security_hardening.sql
-- Run this script in Supabase SQL Editor after 006, 007, and 008.
-- Safe mode: addresses the main Supabase linter warnings that can be fixed
-- without breaking the current app RPC flows:
--   1. function_search_path_mutable
--   2. anon_security_definer_function_executable
--   3. public_bucket_allows_listing
--
-- Note:
-- SECURITY DEFINER functions that are intentionally called by signed-in users
-- will still be callable by authenticated after this script. Supabase may keep
-- warning about those until they are redesigned as SECURITY INVOKER functions
-- or moved out of the exposed public API schema. See 010 for strict lockdown.

BEGIN;

-- ============================================================
-- 1. Pin search_path for all public functions
-- ============================================================

DO $$
DECLARE
  v_function TEXT;
BEGIN
  FOR v_function IN
    SELECT FORMAT(
      '%I.%I(%s)',
      n.nspname,
      p.proname,
      pg_get_function_identity_arguments(p.oid)
    )
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.prokind = 'f'
  LOOP
    EXECUTE FORMAT(
      'ALTER FUNCTION %s SET search_path = public, pg_temp',
      v_function
    );
  END LOOP;
END;
$$;

-- ============================================================
-- 2. Revoke broad RPC execution, especially from anon
-- ============================================================

REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC;
REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM anon;
REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM authenticated;

-- Service role/admin operations should keep full function access.
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO service_role;

-- Re-grant only functions that are intentionally used by the app or RLS
-- policies for signed-in users. This keeps anon blocked while avoiding app
-- breakage for authenticated flows.
DO $$
DECLARE
  v_function TEXT;
  v_allowed_names TEXT[] := ARRAY[
    -- RLS/helper checks used by policies and screens
    'is_instructor',
    'is_admin',
    'is_enrolled',
    'can_manage_course',
    'current_profile_sensitive_state',
    'is_conversation_participant',

    -- Auth/profile helpers
    'add_phone_to_auth_user',
    'create_profile_for_phone_auth',

    -- Course details and learning
    'get_course_details',
    'get_recommended_courses',
    'update_lesson_progress',

    -- Enrollment/payment/coupon flows
    'create_enrollment',
    'confirm_enrollment_payment',
    'validate_coupon',

    -- Quiz flows
    'submit_quiz_attempt',
    'issue_certificate',

    -- Instructor dashboard and management
    'get_instructor_dashboard_stats',
    'get_instructor_revenue_chart',
    'get_instructor_enrollments_chart',
    'get_instructor_forum_courses',
    'process_refund',
    'increment_enrolled_count',
    'decrement_enrolled_count',
    'submit_withdraw_request',
    'toggle_section_published',
    'schedule_section_publish',
    'toggle_lesson_published',
    'schedule_lesson_publish',

    -- Course forum/chat flows
    'get_course_group_members',
    'update_course_group_title',
    'manage_course_group_member',
    'set_course_group_enabled',
    'get_user_conversations',
    'get_or_create_course_conversation',
    'get_or_create_single_conversation',

    -- Notifications
    'get_unread_notifications_count',
    'mark_all_notifications_read'
  ];
BEGIN
  FOR v_function IN
    SELECT FORMAT(
      '%I.%I(%s)',
      n.nspname,
      p.proname,
      pg_get_function_identity_arguments(p.oid)
    )
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.prokind = 'f'
      AND p.proname = ANY (v_allowed_names)
  LOOP
    EXECUTE FORMAT('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_function);
  END LOOP;
END;
$$;

-- Explicitly keep internal trigger/helper functions non-callable from clients.
-- Triggers can still execute trigger functions without client EXECUTE grants.
DO $$
DECLARE
  v_function TEXT;
  v_internal_names TEXT[] := ARRAY[
    'handle_new_user',
    'update_course_rating',
    'update_course_stats',
    'update_enrollment_progress',
    'update_instructor_stats',
    'update_qa_answer_upvotes_count',
    'trigger_update_course_stats_on_section',
    'trigger_update_course_stats_on_lesson',
    'trigger_update_course_stats_on_earning',
    'update_quiz_stats',
    'trigger_update_quiz_stats',
    'update_quiz_question_totals',
    'trigger_update_quiz_question_totals',
    'increment_quiz_questions',
    'decrement_quiz_questions'
  ];
BEGIN
  FOR v_function IN
    SELECT FORMAT(
      '%I.%I(%s)',
      n.nspname,
      p.proname,
      pg_get_function_identity_arguments(p.oid)
    )
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.prokind = 'f'
      AND p.proname = ANY (v_internal_names)
  LOOP
    EXECUTE FORMAT('REVOKE EXECUTE ON FUNCTION %s FROM PUBLIC', v_function);
    EXECUTE FORMAT('REVOKE EXECUTE ON FUNCTION %s FROM anon', v_function);
    EXECUTE FORMAT('REVOKE EXECUTE ON FUNCTION %s FROM authenticated', v_function);
  END LOOP;
END;
$$;

-- ============================================================
-- 3. Prevent listing public storage buckets
-- ============================================================

-- Public buckets can still serve files by public URL without a broad SELECT
-- policy on storage.objects. Dropping these policies prevents clients from
-- listing every object in the bucket through the Storage API.
DROP POLICY IF EXISTS "Public SELECT avatars" ON storage.objects;
DROP POLICY IF EXISTS "Public SELECT banners" ON storage.objects;
DROP POLICY IF EXISTS "Public SELECT categories" ON storage.objects;
DROP POLICY IF EXISTS "Public SELECT certificates" ON storage.objects;

COMMIT;
