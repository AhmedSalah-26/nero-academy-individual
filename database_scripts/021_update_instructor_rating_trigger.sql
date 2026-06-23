-- ============================================================
-- 021_update_instructor_rating_trigger.sql
-- Automatically keeps instructor_profiles.average_rating and
-- total_reviews in sync whenever a course_review is inserted,
-- updated or deleted.
-- ============================================================

-- Helper function that recalculates the instructor rating from scratch
CREATE OR REPLACE FUNCTION update_instructor_average_rating(p_instructor_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_avg    NUMERIC(3,2);
  v_count  INT;
BEGIN
  SELECT
    ROUND(COALESCE(AVG(cr.rating), 0)::NUMERIC, 2),
    COUNT(cr.id)
  INTO v_avg, v_count
  FROM course_reviews cr
  JOIN courses c ON c.id = cr.course_id
  WHERE c.instructor_id = p_instructor_id;

  -- Upsert into instructor_profiles
  UPDATE instructor_profiles
  SET
    average_rating = v_avg,
    total_reviews  = v_count,
    updated_at     = NOW()
  WHERE instructor_id = p_instructor_id;

  -- If no row existed for this instructor, do nothing silently
  -- (the row should exist; if not, it will be fixed on next profile create)
END;
$$;

-- Trigger function called after INSERT / UPDATE / DELETE on course_reviews
CREATE OR REPLACE FUNCTION trg_sync_instructor_rating()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_instructor_id UUID;
BEGIN
  -- Determine the instructor_id from whichever row we have
  IF TG_OP = 'DELETE' THEN
    SELECT c.instructor_id INTO v_instructor_id
    FROM courses c WHERE c.id = OLD.course_id;
  ELSE
    SELECT c.instructor_id INTO v_instructor_id
    FROM courses c WHERE c.id = NEW.course_id;
  END IF;

  IF v_instructor_id IS NOT NULL THEN
    PERFORM update_instructor_average_rating(v_instructor_id);
  END IF;

  RETURN NULL; -- AFTER trigger; return value is ignored
END;
$$;

-- Drop old trigger if it exists, then create fresh
DROP TRIGGER IF EXISTS trg_course_review_rating_sync ON course_reviews;

CREATE TRIGGER trg_course_review_rating_sync
AFTER INSERT OR UPDATE OR DELETE ON course_reviews
FOR EACH ROW
EXECUTE FUNCTION trg_sync_instructor_rating();

-- ----------------------------------------------------------------
-- Back-fill: recalculate for all existing instructors right now
-- ----------------------------------------------------------------
DO $$
DECLARE
  rec RECORD;
BEGIN
  FOR rec IN
    SELECT DISTINCT c.instructor_id
    FROM courses c
    JOIN course_reviews cr ON cr.course_id = c.id
  LOOP
    PERFORM update_instructor_average_rating(rec.instructor_id);
  END LOOP;
END;
$$;
