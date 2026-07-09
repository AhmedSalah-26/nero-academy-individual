-- ============================================================
-- Function: decrement_enrolled_count
-- Description: Decrements the enrolled_count on the courses table
--              when a student is unenrolled. Uses GREATEST(0, ...)
--              to prevent the count from going below zero.
-- Usage (Flutter): _client.rpc('decrement_enrolled_count', params: {'p_course_id': courseId})
-- ============================================================

CREATE OR REPLACE FUNCTION public.decrement_enrolled_count(p_course_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE courses
  SET enrolled_count = GREATEST(0, enrolled_count - 1)
  WHERE id = p_course_id;
END;
$$;
