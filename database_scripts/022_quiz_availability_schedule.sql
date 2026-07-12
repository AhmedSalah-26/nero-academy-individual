-- Add optional availability windows for quizzes.
-- Null values keep the current behavior: the quiz is available whenever published.

ALTER TABLE quizzes
  ADD COLUMN IF NOT EXISTS available_from TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS available_until TIMESTAMPTZ;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'quizzes_availability_window_check'
  ) THEN
    ALTER TABLE quizzes
      ADD CONSTRAINT quizzes_availability_window_check
      CHECK (
        available_until IS NULL
        OR available_from IS NULL
        OR available_until > available_from
      );
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_quizzes_availability
  ON quizzes(course_id, is_published, available_from, available_until);
