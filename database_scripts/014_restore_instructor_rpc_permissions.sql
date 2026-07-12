-- ============================================================
-- 🔧 014_restore_instructor_rpc_permissions.sql
-- Restore EXECUTE grants on RPCs revoked by 010_supabase_linter_strict_authenticated_rpc_lockdown.sql
-- Uses exception handling so missing functions are skipped safely.
-- Run in: Supabase Dashboard → SQL Editor → New Query
-- ============================================================

DO $$
DECLARE
  v_sql TEXT;
  v_grants TEXT[] := ARRAY[
    -- Instructor Dashboard RPCs
    'GRANT EXECUTE ON FUNCTION public.get_instructor_dashboard_stats() TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.get_instructor_revenue_chart(TIMESTAMPTZ, TIMESTAMPTZ) TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.get_instructor_enrollments_chart(TIMESTAMPTZ, TIMESTAMPTZ) TO authenticated',

    -- Enrollment / Payment RPCs
    'GRANT EXECUTE ON FUNCTION public.create_enrollment(UUID, TEXT, UUID, VARCHAR, DECIMAL) TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.confirm_enrollment_payment(UUID, TEXT) TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.process_refund(UUID, TEXT) TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.validate_coupon(VARCHAR, UUID, DECIMAL, UUID[]) TO authenticated',

    -- Learning / Quiz RPCs
    'GRANT EXECUTE ON FUNCTION public.submit_quiz_attempt(UUID, JSONB, INT) TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.update_lesson_progress(UUID, INTEGER, INTEGER, BOOLEAN) TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.issue_certificate(UUID) TO authenticated',

    -- Security Helpers
    'GRANT EXECUTE ON FUNCTION public.is_instructor() TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.is_enrolled(UUID) TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.can_manage_course(UUID) TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.current_profile_sensitive_state() TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.is_conversation_participant(UUID, UUID) TO authenticated',

    -- Chat RPCs
    'GRANT EXECUTE ON FUNCTION public.get_user_conversations(UUID, TEXT) TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.get_or_create_course_conversation(UUID, UUID) TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.get_or_create_single_conversation(UUID, UUID) TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.get_course_group_members(UUID) TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.update_course_group_title(UUID, TEXT) TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.manage_course_group_member(UUID, UUID, TEXT, TEXT) TO authenticated',
    'GRANT EXECUTE ON FUNCTION public.get_instructor_forum_courses() TO authenticated'
  ];
BEGIN
  FOREACH v_sql IN ARRAY v_grants LOOP
    BEGIN
      EXECUTE v_sql;
      RAISE NOTICE 'OK: %', v_sql;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'SKIPPED (function not found): %', v_sql;
    END;
  END LOOP;
END;
$$;

-- ── Verify grants ──────────────────────────────────────────
SELECT
  routine_name,
  grantee,
  privilege_type
FROM information_schema.routine_privileges
WHERE routine_schema = 'public'
  AND grantee = 'authenticated'
ORDER BY routine_name;
