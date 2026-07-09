-- ============================================================
-- Script: 036_review_reports_rls.sql
-- Description: Adds missing RLS policies for the review_reports table.
--              Allows authenticated users to insert reports and read
--              their own reports.
-- ============================================================

-- ---------------------------------------------------------------
-- 1. Allow authenticated users to INSERT into review_reports
-- ---------------------------------------------------------------
DROP POLICY IF EXISTS "Authenticated users can insert review reports" ON review_reports;

CREATE POLICY "Authenticated users can insert review reports"
ON review_reports
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = user_id
);

-- ---------------------------------------------------------------
-- 2. Allow users to SELECT their own review reports
-- ---------------------------------------------------------------
DROP POLICY IF EXISTS "Users can view their own review reports" ON review_reports;

CREATE POLICY "Users can view their own review reports"
ON review_reports
FOR SELECT
TO authenticated
USING (
  auth.uid() = user_id
);

-- ---------------------------------------------------------------
-- 3. Allow admins/instructors to view all reports (optional)
-- ---------------------------------------------------------------
DROP POLICY IF EXISTS "Instructors can view review reports for their courses" ON review_reports;

CREATE POLICY "Instructors can view review reports for their courses"
ON review_reports
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM course_reviews cr
    JOIN courses c ON c.id = cr.course_id
    WHERE cr.id = review_reports.review_id
      AND c.instructor_id = auth.uid()
  )
);
