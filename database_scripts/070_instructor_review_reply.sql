-- ============================================================
-- 070: Instructor review reply support
-- Adds instructor_reply/replied_at columns to course_reviews and
-- grants instructors (is_admin()) UPDATE access so they can reply
-- to reviews on their own courses.
-- Run AFTER 000_nasaq_full_database.sql.
-- ============================================================

BEGIN;

-- 1. Add reply columns to course_reviews
ALTER TABLE public.course_reviews
  ADD COLUMN IF NOT EXISTS instructor_reply TEXT,
  ADD COLUMN IF NOT EXISTS replied_at TIMESTAMPTZ;

-- 2. Replace the review management policy so instructors can update
--    reviews for their own courses (to post a reply).
--    The student's own-row access (user_id = auth.uid()) is preserved.
DROP POLICY IF EXISTS "Enrolled users can manage reviews" ON public.course_reviews;

CREATE POLICY "Enrolled users can manage reviews"
  ON public.course_reviews FOR ALL
  TO authenticated
  USING (
    user_id = auth.uid()
    OR public.is_admin()
    OR EXISTS (
      SELECT 1
      FROM public.courses c
      WHERE c.id = course_reviews.course_id
        AND c.instructor_id = auth.uid()
    )
  )
  WITH CHECK (
    user_id = auth.uid()
    OR public.is_admin()
    OR EXISTS (
      SELECT 1
      FROM public.courses c
      WHERE c.id = course_reviews.course_id
        AND c.instructor_id = auth.uid()
    )
  );

COMMIT;
