-- ============================================================
-- 🔧 015_allow_instructor_manage_categories.sql
-- Fix RLS on 'categories' table to allow instructors to INSERT,
-- UPDATE, and DELETE categories (not just admins).
--
-- Run in: Supabase Dashboard → SQL Editor → New Query
-- ============================================================

-- Drop the old admin-only policy
DROP POLICY IF EXISTS "Instructor can manage categories" ON public.categories;
DROP POLICY IF EXISTS "Admins can manage categories" ON public.categories;
DROP POLICY IF EXISTS "Admins can insert categories" ON public.categories;
DROP POLICY IF EXISTS "Admins can update categories" ON public.categories;
DROP POLICY IF EXISTS "Admins can delete categories" ON public.categories;

-- Allow SELECT: anyone can view active categories
DROP POLICY IF EXISTS "Anyone can view categories" ON public.categories;
CREATE POLICY "Anyone can view categories"
  ON public.categories FOR SELECT
  USING (is_active = true);

-- Allow admin: view ALL categories (including inactive)
DROP POLICY IF EXISTS "Admins can view all categories" ON public.categories;
CREATE POLICY "Admins can view all categories"
  ON public.categories FOR SELECT
  USING (is_admin());

-- Allow instructors AND admins to INSERT categories
DROP POLICY IF EXISTS "Instructor or admin can insert categories" ON public.categories;
CREATE POLICY "Instructor or admin can insert categories"
  ON public.categories FOR INSERT
  WITH CHECK (is_instructor() OR is_admin());

-- Allow instructors AND admins to UPDATE categories
DROP POLICY IF EXISTS "Instructor or admin can update categories" ON public.categories;
CREATE POLICY "Instructor or admin can update categories"
  ON public.categories FOR UPDATE
  USING (is_instructor() OR is_admin());

-- Allow instructors AND admins to DELETE categories
DROP POLICY IF EXISTS "Instructor or admin can delete categories" ON public.categories;
CREATE POLICY "Instructor or admin can delete categories"
  ON public.categories FOR DELETE
  USING (is_instructor() OR is_admin());

-- ── Verify ─────────────────────────────────────────────────
SELECT policyname, cmd, qual
FROM pg_policies
WHERE tablename = 'categories'
ORDER BY policyname;
