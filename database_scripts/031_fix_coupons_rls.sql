-- ====================================================================
-- 🔧 FIX: Row-Level Security (RLS) Policies for Coupons & Coupon Courses
-- ====================================================================
-- Run this SQL in your Supabase Dashboard -> SQL Editor to allow
-- instructors to successfully create, update, and manage their coupons.
-- ====================================================================

-- --------------------------------------------------------------------
-- 1. Policies for coupon_courses (Allows syncing courses to coupons)
-- --------------------------------------------------------------------
ALTER TABLE coupon_courses ENABLE ROW LEVEL SECURITY;

-- Allow select/read for all authenticated/anonymous users (e.g. cart/checkout verification)
DROP POLICY IF EXISTS "Anyone can view coupon courses" ON coupon_courses;
CREATE POLICY "Anyone can view coupon courses" ON coupon_courses FOR SELECT USING (true);

-- Allow instructors to manage (INSERT, UPDATE, DELETE) courses linked to their own coupons
DROP POLICY IF EXISTS "Instructors can manage coupon courses" ON coupon_courses;
CREATE POLICY "Instructors can manage coupon courses" ON coupon_courses FOR ALL 
  USING (
    EXISTS (
      SELECT 1 FROM coupons
      WHERE coupons.id = coupon_courses.coupon_id 
        AND coupons.instructor_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM coupons
      WHERE coupons.id = coupon_courses.coupon_id 
        AND coupons.instructor_id = auth.uid()
    )
  );

-- Allow admins full control
DROP POLICY IF EXISTS "Admins can manage coupon courses" ON coupon_courses;
CREATE POLICY "Admins can manage coupon courses" ON coupon_courses FOR ALL USING (is_admin());


-- --------------------------------------------------------------------
-- 2. Policies for coupons (Allows instructors to create/edit coupons)
-- --------------------------------------------------------------------
ALTER TABLE coupons ENABLE ROW LEVEL SECURITY;

-- Students / Cart system can view active coupons
DROP POLICY IF EXISTS "Anyone can view active coupons" ON coupons;
CREATE POLICY "Anyone can view active coupons" ON coupons FOR SELECT USING (is_active = true);

-- Instructors can view coupons they created
DROP POLICY IF EXISTS "Instructors can view own coupons" ON coupons;
CREATE POLICY "Instructors can view own coupons" ON coupons FOR SELECT 
  USING (instructor_id = auth.uid() OR is_admin());

-- Instructors can insert/create their own coupons
DROP POLICY IF EXISTS "Instructors can insert own coupons" ON coupons;
CREATE POLICY "Instructors can insert own coupons" ON coupons FOR INSERT 
  WITH CHECK (instructor_id = auth.uid() OR is_admin());

-- Instructors can update their own coupons
DROP POLICY IF EXISTS "Instructors can update own coupons" ON coupons;
CREATE POLICY "Instructors can update own coupons" ON coupons FOR UPDATE 
  USING (instructor_id = auth.uid() OR is_admin())
  WITH CHECK (instructor_id = auth.uid() OR is_admin());

-- Instructors can delete their own coupons
DROP POLICY IF EXISTS "Instructors can delete own coupons" ON coupons;
CREATE POLICY "Instructors can delete own coupons" ON coupons FOR DELETE 
  USING (instructor_id = auth.uid() OR is_admin());

-- Admins can manage all coupons
DROP POLICY IF EXISTS "Admins can manage all coupons" ON coupons;
CREATE POLICY "Admins can manage all coupons" ON coupons FOR ALL USING (is_admin());
