-- ============================================================
-- Script: 037_course_reports_rls.sql
-- Description: Adds missing RLS policies for the course_reports table.
--              Allows authenticated users to insert and read their reports.
-- ============================================================

-- ---------------------------------------------------------------
-- 1. Allow authenticated users to INSERT into course_reports
-- ---------------------------------------------------------------
DROP POLICY IF EXISTS "Authenticated users can insert course reports" ON course_reports;

CREATE POLICY "Authenticated users can insert course reports"
ON course_reports
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = user_id
);

-- ---------------------------------------------------------------
-- 2. Allow users to SELECT their own course reports
-- ---------------------------------------------------------------
DROP POLICY IF EXISTS "Users can view their own course reports" ON course_reports;

CREATE POLICY "Users can view their own course reports"
ON course_reports
FOR SELECT
TO authenticated
USING (
  auth.uid() = user_id
);

-- ---------------------------------------------------------------
-- 3. Allow instructors to view reports on their own courses
-- ---------------------------------------------------------------
DROP POLICY IF EXISTS "Instructors can view reports on their courses" ON course_reports;

CREATE POLICY "Instructors can view reports on their courses"
ON course_reports
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM courses
    WHERE courses.id = course_reports.course_id
      AND courses.instructor_id = auth.uid()
  )
);
