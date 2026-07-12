-- 010_supabase_linter_strict_authenticated_rpc_lockdown.sql
-- Strict mode for clearing authenticated_security_definer_function_executable
-- warnings.
--
-- WARNING:
-- Do not run this on production until the listed RPC flows are replaced with
-- safer alternatives such as:
--   1. SECURITY INVOKER public functions backed by proper RLS policies.
--   2. SECURITY DEFINER functions moved to a non-exposed private schema and
--      called through carefully scoped wrappers.
--   3. Supabase Edge Functions using service-role secrets on the server side.
--
-- Running this script will remove direct authenticated EXECUTE access from the
-- SECURITY DEFINER functions still reported by the Supabase linter. That makes
-- the linter happy, but current app features that call these RPCs directly can
-- fail with permission errors until they are refactored.

BEGIN;

DO $$
DECLARE
  v_function TEXT;
  v_locked_names TEXT[] := ARRAY[
    -- RLS/helper checks. These should be moved to a private schema or converted
    -- to SECURITY INVOKER only after testing every policy that calls them.
    'can_manage_course',
    'current_profile_sensitive_state',
    'is_admin',
    'is_conversation_participant',
    'is_enrolled',
    'is_instructor',

    -- Enrollment/payment/coupon RPCs.
    'confirm_enrollment_payment',
    'create_enrollment',
    'validate_coupon',

    -- Course forum/chat RPCs.
    'get_course_group_members',
    'get_instructor_forum_courses',
    'get_or_create_course_conversation',
    'get_or_create_single_conversation',
    'get_user_conversations',
    'manage_course_group_member',
    'set_course_group_enabled',
    'update_course_group_title',

    -- Instructor dashboard/management RPCs.
    'get_instructor_dashboard_stats',
    'get_instructor_enrollments_chart',
    'get_instructor_revenue_chart',
    'process_refund',

    -- Learning/quiz RPCs.
    'issue_certificate',
    'submit_quiz_attempt',
    'update_lesson_progress'
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
      AND p.proname = ANY (v_locked_names)
  LOOP
    EXECUTE FORMAT('REVOKE EXECUTE ON FUNCTION %s FROM authenticated', v_function);
    EXECUTE FORMAT('REVOKE EXECUTE ON FUNCTION %s FROM anon', v_function);
    EXECUTE FORMAT('REVOKE EXECUTE ON FUNCTION %s FROM PUBLIC', v_function);
  END LOOP;
END;
$$;

COMMIT;
