-- Add availability windows for courses, sections, and lessons.
-- NULL means open-ended, preserving the current behavior.

ALTER TABLE courses
  ADD COLUMN IF NOT EXISTS available_from TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS available_until TIMESTAMPTZ;

ALTER TABLE sections
  ADD COLUMN IF NOT EXISTS available_from TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS available_until TIMESTAMPTZ;

ALTER TABLE lessons
  ADD COLUMN IF NOT EXISTS available_from TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS available_until TIMESTAMPTZ;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'courses_availability_window_check'
  ) THEN
    ALTER TABLE courses
      ADD CONSTRAINT courses_availability_window_check
      CHECK (available_until IS NULL OR available_from IS NULL OR available_until > available_from);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'sections_availability_window_check'
  ) THEN
    ALTER TABLE sections
      ADD CONSTRAINT sections_availability_window_check
      CHECK (available_until IS NULL OR available_from IS NULL OR available_until > available_from);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'lessons_availability_window_check'
  ) THEN
    ALTER TABLE lessons
      ADD CONSTRAINT lessons_availability_window_check
      CHECK (available_until IS NULL OR available_from IS NULL OR available_until > available_from);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_courses_availability
  ON courses(is_published, is_active, available_from, available_until);

CREATE INDEX IF NOT EXISTS idx_sections_availability
  ON sections(course_id, is_published, available_from, available_until);

CREATE INDEX IF NOT EXISTS idx_lessons_availability
  ON lessons(course_id, section_id, is_published, available_from, available_until);

CREATE OR REPLACE FUNCTION is_available_window(
  p_available_from TIMESTAMPTZ,
  p_available_until TIMESTAMPTZ
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
  SELECT (p_available_from IS NULL OR p_available_from <= NOW())
     AND (p_available_until IS NULL OR p_available_until > NOW());
$$;

CREATE OR REPLACE FUNCTION is_course_available(p_course_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM courses c
    WHERE c.id = p_course_id
      AND c.is_published = TRUE
      AND c.is_active = TRUE
      AND is_available_window(c.available_from, c.available_until)
  );
$$;

DROP POLICY IF EXISTS "Anyone can view published courses" ON courses;
CREATE POLICY "Anyone can view published courses" ON courses
FOR SELECT
USING (
  is_published = TRUE
  AND is_active = TRUE
  AND is_available_window(available_from, available_until)
);

DROP POLICY IF EXISTS "Anyone can view sections of published courses" ON sections;
DROP POLICY IF EXISTS "Anyone can view published sections" ON sections;
CREATE POLICY "Anyone can view sections of published courses" ON sections
FOR SELECT
USING (
  (
    is_published = TRUE
    AND is_available_window(available_from, available_until)
    AND is_course_available(course_id)
  )
  OR is_admin()
  OR EXISTS (
    SELECT 1
    FROM courses c
    WHERE c.id = sections.course_id
      AND c.instructor_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Anyone can view preview lessons" ON lessons;
CREATE POLICY "Anyone can view preview lessons" ON lessons
FOR SELECT
USING (
  is_preview = TRUE
  AND is_published = TRUE
  AND is_available_window(available_from, available_until)
  AND is_course_available(course_id)
);

DROP POLICY IF EXISTS "Enrolled students can view lessons" ON lessons;
CREATE POLICY "Enrolled students can view lessons" ON lessons
FOR SELECT
USING (
  is_published = TRUE
  AND is_available_window(available_from, available_until)
  AND is_course_available(course_id)
  AND is_enrolled(course_id)
);
