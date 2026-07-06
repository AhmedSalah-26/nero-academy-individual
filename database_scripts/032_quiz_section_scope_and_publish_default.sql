-- Add section-level quiz support and make new quizzes unpublished by default.

ALTER TABLE quizzes
  ADD COLUMN IF NOT EXISTS section_id UUID REFERENCES sections(id) ON DELETE CASCADE;

ALTER TABLE quizzes
  ALTER COLUMN is_published SET DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS idx_quizzes_section ON quizzes(section_id);

COMMENT ON COLUMN quizzes.section_id IS
  'Optional: if set and lesson_id is null, the quiz belongs to an entire course section.';
