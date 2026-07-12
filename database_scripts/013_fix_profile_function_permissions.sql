-- ============================================================
-- 🔧 FIX ALL: Grant Execute on All Public Functions
-- Run this in: Supabase Dashboard → SQL Editor → New Query
-- ============================================================

-- ── Core Security Helpers ─────────────────────────────────
GRANT EXECUTE ON FUNCTION public.is_instructor() TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.is_enrolled(UUID) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.can_manage_course(UUID) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.current_profile_sensitive_state() TO authenticated, anon;

-- ── Enrollment RPCs ───────────────────────────────────────
GRANT EXECUTE ON FUNCTION public.create_enrollment(UUID, TEXT, UUID, VARCHAR, DECIMAL) TO authenticated;
GRANT EXECUTE ON FUNCTION public.confirm_enrollment_payment(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.process_refund(UUID, TEXT) TO authenticated;

-- ── Chat / Conversations ──────────────────────────────────
GRANT EXECUTE ON FUNCTION public.get_user_conversations(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_conversations(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_or_create_course_conversation(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_or_create_course_conversation(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_or_create_single_conversation(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_course_group_members(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_course_group_title(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.manage_course_group_member(UUID, UUID, TEXT, TEXT) TO authenticated;

-- ── Quiz Helpers ──────────────────────────────────────────
GRANT EXECUTE ON FUNCTION public.update_quiz_question_totals(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.increment_quiz_questions(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.decrement_quiz_questions(UUID, INTEGER) TO authenticated;

-- ── Verify all grants ─────────────────────────────────────
SELECT
  routine_name,
  grantee,
  privilege_type
FROM information_schema.routine_privileges
WHERE routine_schema = 'public'
  AND grantee IN ('authenticated', 'anon')
ORDER BY routine_name, grantee;
