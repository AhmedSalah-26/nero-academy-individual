-- ============================================================
-- 060: Fix Missing Tables & Columns
-- Run this in Supabase SQL Editor AFTER 040_nasaq_app_schema.sql
-- ============================================================

BEGIN;

-- ────────────────────────────────────────────────────────────
-- 1. user_settings  (used by SettingsRemoteDataSource)
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.user_settings (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id              UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  language_code        TEXT NOT NULL DEFAULT 'ar',
  is_dark_mode         BOOLEAN NOT NULL DEFAULT FALSE,
  notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  video_autoplay       BOOLEAN NOT NULL DEFAULT TRUE,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id)
);

ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage own settings" ON public.user_settings;
CREATE POLICY "Users can manage own settings"
  ON public.user_settings FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ────────────────────────────────────────────────────────────
-- 2. popular_searches  (used by CourseSearchRemoteDataSource)
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.popular_searches (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  query        TEXT NOT NULL UNIQUE,
  search_count INTEGER NOT NULL DEFAULT 1,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.popular_searches ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view popular searches" ON public.popular_searches;
CREATE POLICY "Anyone can view popular searches"
  ON public.popular_searches FOR SELECT USING (TRUE);

DROP POLICY IF EXISTS "Authenticated can insert searches" ON public.popular_searches;
CREATE POLICY "Authenticated can insert searches"
  ON public.popular_searches FOR INSERT
  TO authenticated WITH CHECK (TRUE);

DROP POLICY IF EXISTS "Authenticated can update searches" ON public.popular_searches;
CREATE POLICY "Authenticated can update searches"
  ON public.popular_searches FOR UPDATE
  TO authenticated USING (TRUE);

-- ────────────────────────────────────────────────────────────
-- 3. direct_message_reactions  (used by DirectChatCubit)
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.direct_message_reactions (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID NOT NULL REFERENCES public.direct_messages(id) ON DELETE CASCADE,
  user_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  reaction   TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(message_id, user_id, reaction)
);

CREATE INDEX IF NOT EXISTS idx_dm_reactions_message
  ON public.direct_message_reactions(message_id);

ALTER TABLE public.direct_message_reactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Participants can manage dm reactions" ON public.direct_message_reactions;
CREATE POLICY "Participants can manage dm reactions"
  ON public.direct_message_reactions FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ────────────────────────────────────────────────────────────
-- 4. withdraw_requests  (used by InstructorEarningsDataSource)
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.withdraw_requests (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  amount          DECIMAL(10,2) NOT NULL CHECK (amount > 0),
  status          TEXT NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending','approved','rejected','paid')),
  method          TEXT NOT NULL DEFAULT 'bank_transfer',
  account_details JSONB DEFAULT '{}',
  requested_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  approved_at     TIMESTAMPTZ,
  paid_at         TIMESTAMPTZ,
  admin_id        UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_withdraw_requests_user
  ON public.withdraw_requests(user_id, requested_at DESC);

ALTER TABLE public.withdraw_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Instructors can manage own withdrawals" ON public.withdraw_requests;
CREATE POLICY "Instructors can manage own withdrawals"
  ON public.withdraw_requests FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ────────────────────────────────────────────────────────────
-- 5. Missing columns in existing tables
-- ────────────────────────────────────────────────────────────

-- profiles.parent_phone  (used in SettingsRemoteDataSource profileColumns)
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS parent_phone TEXT;

-- teachers.website_url  (used in getUserProfile instructor fields)
ALTER TABLE public.teachers
  ADD COLUMN IF NOT EXISTS website_url TEXT;

-- teachers.cover_image_url  (used in getUserProfile instructor fields)
ALTER TABLE public.teachers
  ADD COLUMN IF NOT EXISTS cover_image_url TEXT;

-- ────────────────────────────────────────────────────────────
-- 6. announcements RLS - ensure instructor can manage own
-- ────────────────────────────────────────────────────────────
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Instructor manages own announcements" ON public.announcements;
CREATE POLICY "Instructor manages own announcements"
  ON public.announcements FOR ALL
  USING (instructor_id = auth.uid())
  WITH CHECK (instructor_id = auth.uid());

DROP POLICY IF EXISTS "Enrolled students can view announcements" ON public.announcements;
CREATE POLICY "Enrolled students can view announcements"
  ON public.announcements FOR SELECT
  USING (
    is_published = TRUE
    AND EXISTS (
      SELECT 1 FROM public.enrollments e
      WHERE e.course_id = announcements.course_id
        AND e.user_id = auth.uid()
        AND e.status IN ('active', 'completed')
    )
  );

COMMIT;
