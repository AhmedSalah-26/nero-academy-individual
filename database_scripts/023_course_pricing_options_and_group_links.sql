-- Course pricing options and student group links
ALTER TABLE courses
  ADD COLUMN IF NOT EXISTS pricing_options JSONB NOT NULL DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS group_links JSONB NOT NULL DEFAULT '{}'::jsonb;

ALTER TABLE cart_items
  ADD COLUMN IF NOT EXISTS pricing_option JSONB;

ALTER TABLE enrollments
  ADD COLUMN IF NOT EXISTS pricing_option JSONB;

CREATE INDEX IF NOT EXISTS idx_courses_pricing_options_gin
  ON courses USING gin (pricing_options);
