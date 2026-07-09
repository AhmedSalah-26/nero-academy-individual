-- ============================================================
-- Script: 038_instructor_full_access.sql
-- Description: Grants instructor role full access across all
--              relevant tables using the existing is_instructor()
--              helper function. Consolidates and replaces the
--              individual policies added in 035, 036, 037.
-- ============================================================

-- ============================================================
-- ENROLLMENTS — Full CRUD for instructor
-- ============================================================

DROP POLICY IF EXISTS "Instructors can select all enrollments" ON enrollments;
CREATE POLICY "Instructors can select all enrollments"
ON enrollments FOR SELECT TO authenticated
USING (public.is_instructor());

DROP POLICY IF EXISTS "Instructors can insert enrollments" ON enrollments;
CREATE POLICY "Instructors can insert enrollments"
ON enrollments FOR INSERT TO authenticated
WITH CHECK (public.is_instructor());

DROP POLICY IF EXISTS "Instructors can update enrollments" ON enrollments;
CREATE POLICY "Instructors can update enrollments"
ON enrollments FOR UPDATE TO authenticated
USING (public.is_instructor());

DROP POLICY IF EXISTS "Instructors can delete enrollments" ON enrollments;
CREATE POLICY "Instructors can delete enrollments"
ON enrollments FOR DELETE TO authenticated
USING (public.is_instructor());

-- ============================================================
-- LESSON_PROGRESS — Full CRUD for instructor
-- ============================================================

DROP POLICY IF EXISTS "Instructors can select lesson_progress" ON lesson_progress;
CREATE POLICY "Instructors can select lesson_progress"
ON lesson_progress FOR SELECT TO authenticated
USING (public.is_instructor());

DROP POLICY IF EXISTS "Instructors can insert lesson_progress" ON lesson_progress;
CREATE POLICY "Instructors can insert lesson_progress"
ON lesson_progress FOR INSERT TO authenticated
WITH CHECK (public.is_instructor());

DROP POLICY IF EXISTS "Instructors can update lesson_progress" ON lesson_progress;
CREATE POLICY "Instructors can update lesson_progress"
ON lesson_progress FOR UPDATE TO authenticated
USING (public.is_instructor());

DROP POLICY IF EXISTS "Instructors can delete lesson_progress" ON lesson_progress;
CREATE POLICY "Instructors can delete lesson_progress"
ON lesson_progress FOR DELETE TO authenticated
USING (public.is_instructor());

-- ============================================================
-- COURSE_REPORTS — Full access for instructor
-- ============================================================

DROP POLICY IF EXISTS "Instructors can select course reports" ON course_reports;
CREATE POLICY "Instructors can select course reports"
ON course_reports FOR SELECT TO authenticated
USING (public.is_instructor());

DROP POLICY IF EXISTS "Instructors can insert course reports" ON course_reports;
CREATE POLICY "Instructors can insert course reports"
ON course_reports FOR INSERT TO authenticated
WITH CHECK (public.is_instructor());

DROP POLICY IF EXISTS "Instructors can update course reports" ON course_reports;
CREATE POLICY "Instructors can update course reports"
ON course_reports FOR UPDATE TO authenticated
USING (public.is_instructor());

DROP POLICY IF EXISTS "Instructors can delete course reports" ON course_reports;
CREATE POLICY "Instructors can delete course reports"
ON course_reports FOR DELETE TO authenticated
USING (public.is_instructor());

-- Allow regular authenticated users to INSERT their own course reports
DROP POLICY IF EXISTS "Authenticated users can insert course reports" ON course_reports;
CREATE POLICY "Authenticated users can insert course reports"
ON course_reports FOR INSERT TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Allow users to view their own course reports
DROP POLICY IF EXISTS "Users can view their own course reports" ON course_reports;
CREATE POLICY "Users can view their own course reports"
ON course_reports FOR SELECT TO authenticated
USING (auth.uid() = user_id);

-- ============================================================
-- REVIEW_REPORTS — Full access for instructor
-- ============================================================

DROP POLICY IF EXISTS "Instructors can select review reports" ON review_reports;
CREATE POLICY "Instructors can select review reports"
ON review_reports FOR SELECT TO authenticated
USING (public.is_instructor());

DROP POLICY IF EXISTS "Instructors can insert review reports" ON review_reports;
CREATE POLICY "Instructors can insert review reports"
ON review_reports FOR INSERT TO authenticated
WITH CHECK (public.is_instructor());

DROP POLICY IF EXISTS "Instructors can update review reports" ON review_reports;
CREATE POLICY "Instructors can update review reports"
ON review_reports FOR UPDATE TO authenticated
USING (public.is_instructor());

DROP POLICY IF EXISTS "Instructors can delete review reports" ON review_reports;
CREATE POLICY "Instructors can delete review reports"
ON review_reports FOR DELETE TO authenticated
USING (public.is_instructor());

-- Allow regular authenticated users to INSERT their own review reports
DROP POLICY IF EXISTS "Authenticated users can insert review reports" ON review_reports;
CREATE POLICY "Authenticated users can insert review reports"
ON review_reports FOR INSERT TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Allow users to view their own review reports
DROP POLICY IF EXISTS "Users can view their own review reports" ON review_reports;
CREATE POLICY "Users can view their own review reports"
ON review_reports FOR SELECT TO authenticated
USING (auth.uid() = user_id);

-- ============================================================
-- COURSES — Update enrolled_count (for decrement RPC)
-- ============================================================

DROP POLICY IF EXISTS "Instructors can update courses" ON courses;
CREATE POLICY "Instructors can update courses"
ON courses FOR UPDATE TO authenticated
USING (public.is_instructor());


