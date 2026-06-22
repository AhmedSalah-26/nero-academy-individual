-- 017_fix_forum_function_permissions.sql
-- إعادة صلاحيات تنفيذ جميع الـ RPC functions التي تم إزالتها بواسطة سكريبت 010
-- يجب تشغيل هذا السكريبت بعد 010 دائماً

DO $$
DECLARE
  v_rec RECORD;
BEGIN
  FOR v_rec IN
    SELECT FORMAT('%I.%I(%s)', n.nspname, p.proname, pg_get_function_identity_arguments(p.oid)) AS fn_sig
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.prokind = 'f'
      AND p.proname = ANY(ARRAY[
        'can_manage_course','current_profile_sensitive_state','is_admin',
        'is_conversation_participant','is_enrolled','is_instructor',
        'confirm_enrollment_payment','create_enrollment','validate_coupon',
        'get_course_group_members','get_instructor_forum_courses',
        'get_or_create_course_conversation','get_or_create_single_conversation',
        'get_user_conversations','manage_course_group_member','set_course_group_enabled',
        'update_course_group_title','get_instructor_dashboard_stats',
        'get_instructor_enrollments_chart','get_instructor_revenue_chart',
        'process_refund','issue_certificate','submit_quiz_attempt','update_lesson_progress'
      ])
  LOOP
    EXECUTE FORMAT('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_rec.fn_sig);
  END LOOP;
END;
$$;
