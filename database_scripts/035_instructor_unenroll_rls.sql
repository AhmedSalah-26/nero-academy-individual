-- ============================================================
-- Script: 035_instructor_unenroll_rls.sql
-- Description: Adds RLS policy allowing instructors to delete
--              enrollments and lesson_progress for their own courses.
--              Also creates decrement_enrolled_count function.
-- ============================================================

-- ---------------------------------------------------------------
-- 1. Allow instructors to DELETE enrollments for their own courses
-- ---------------------------------------------------------------
DROP POLICY IF EXISTS "Instructors can delete enrollments for their courses" ON enrollments;

CREATE POLICY "Instructors can delete enrollments for their courses"
ON enrollments
FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM courses
    WHERE courses.id = enrollments.course_id
      AND courses.instructor_id = auth.uid()
  )
);

-- ---------------------------------------------------------------
-- 2. Allow instructors to DELETE lesson_progress for their courses
-- ---------------------------------------------------------------
DROP POLICY IF EXISTS "Instructors can delete lesson_progress for their courses" ON lesson_progress;

CREATE POLICY "Instructors can delete lesson_progress for their courses"
ON lesson_progress
FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM courses
    WHERE courses.id = lesson_progress.course_id
      AND courses.instructor_id = auth.uid()
  )
);

-- ---------------------------------------------------------------
-- 3. Create decrement_enrolled_count function (if not exists)
-- ---------------------------------------------------------------
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
