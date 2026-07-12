
BEGIN;

-- Make trigger functions SECURITY DEFINER so they can execute internal helper functions
-- without exposing the helper functions directly to clients via RPC.

ALTER FUNCTION trigger_update_course_stats_on_section() SECURITY DEFINER SET search_path = public, pg_temp;
ALTER FUNCTION trigger_update_course_stats_on_lesson() SECURITY DEFINER SET search_path = public, pg_temp;
ALTER FUNCTION trigger_update_course_stats_on_earning() SECURITY DEFINER SET search_path = public, pg_temp;

-- Quiz stats triggers
ALTER FUNCTION trigger_update_quiz_stats() SECURITY DEFINER SET search_path = public, pg_temp;
ALTER FUNCTION trigger_update_quiz_question_totals() SECURITY DEFINER SET search_path = public, pg_temp;

-- Other stat/helper triggers
ALTER FUNCTION handle_new_user() SECURITY DEFINER SET search_path = public, pg_temp;
ALTER FUNCTION update_course_rating() SECURITY DEFINER SET search_path = public, pg_temp;
ALTER FUNCTION update_enrollment_progress() SECURITY DEFINER SET search_path = public, pg_temp;
ALTER FUNCTION update_instructor_stats() SECURITY DEFINER SET search_path = public, pg_temp;
ALTER FUNCTION update_qa_answer_upvotes_count() SECURITY DEFINER SET search_path = public, pg_temp;

COMMIT;
