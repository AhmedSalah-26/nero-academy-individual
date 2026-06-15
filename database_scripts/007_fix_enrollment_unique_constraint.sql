-- 007_fix_enrollment_unique_constraint.sql
-- Run this script in your Supabase SQL Editor to update the create_enrollment function.
-- This prevents "duplicate key value violates unique constraint" crashes.

CREATE OR REPLACE FUNCTION public.create_enrollment(
  p_user_id UUID,
  p_payment_method TEXT DEFAULT 'card',
  p_coupon_id UUID DEFAULT NULL,
  p_coupon_code VARCHAR DEFAULT NULL,
  p_coupon_discount DECIMAL DEFAULT 0
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_parent_enrollment_id UUID;
  v_enrollment_id UUID;
  v_course RECORD;
  v_coupon RECORD;
  v_total_subtotal DECIMAL := 0;
  v_coupon_discount DECIMAL := 0;
  v_user_usage_count INTEGER := 0;
BEGIN
  SELECT NULL::UUID AS id, NULL::VARCHAR AS code INTO v_coupon;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_user_id IS DISTINCT FROM v_user_id THEN
    RAISE EXCEPTION 'Cannot create enrollment for another user';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.cart_items WHERE user_id = v_user_id) THEN
    RAISE EXCEPTION 'Cart is empty';
  END IF;

  -- 1. Check if the user is already active or completed in any of the courses in their cart
  FOR v_course IN
    SELECT
      c.id AS course_id,
      c.title_ar,
      c.title_en
    FROM public.cart_items ci
    JOIN public.courses c ON c.id = ci.course_id
    WHERE ci.user_id = v_user_id
  LOOP
    IF EXISTS (
      SELECT 1 FROM public.enrollments
      WHERE user_id = v_user_id
        AND course_id = v_course.course_id
        AND status IN ('active', 'completed')
    ) THEN
      RAISE EXCEPTION 'You are already enrolled in course: %', COALESCE(v_course.title_ar, v_course.title_en);
    END IF;
  END LOOP;

  -- 2. Calculate subtotal
  SELECT COALESCE(SUM(
    CASE
      WHEN c.is_flash_sale AND c.flash_sale_end > NOW() THEN COALESCE(c.flash_sale_price, c.discount_price, c.price)
      ELSE COALESCE(c.discount_price, c.price)
    END
  ), 0)
  INTO v_total_subtotal
  FROM public.cart_items ci
  JOIN public.courses c ON c.id = ci.course_id
  WHERE ci.user_id = v_user_id;

  -- 3. Apply Coupon if applicable
  IF p_coupon_id IS NOT NULL OR p_coupon_code IS NOT NULL THEN
    SELECT *
    INTO v_coupon
    FROM public.coupons
    WHERE (id = p_coupon_id OR code = UPPER(p_coupon_code))
      AND is_active = TRUE
      AND is_suspended = FALSE
      AND start_date <= NOW()
      AND (end_date IS NULL OR end_date >= NOW())
      AND (usage_limit IS NULL OR usage_count < usage_limit)
      AND min_order_amount <= v_total_subtotal
    LIMIT 1;

    IF v_coupon.id IS NULL THEN
      RAISE EXCEPTION 'Invalid coupon';
    END IF;

    SELECT COUNT(*)
    INTO v_user_usage_count
    FROM public.coupon_usages
    WHERE coupon_id = v_coupon.id
      AND user_id = v_user_id;

    IF v_user_usage_count >= v_coupon.usage_limit_per_user THEN
      RAISE EXCEPTION 'Coupon usage limit exceeded';
    END IF;

    IF v_coupon.discount_type = 'percentage' THEN
      v_coupon_discount := v_total_subtotal * (v_coupon.discount_value / 100);
      IF v_coupon.max_discount_amount IS NOT NULL THEN
        v_coupon_discount := LEAST(v_coupon_discount, v_coupon.max_discount_amount);
      END IF;
    ELSE
      v_coupon_discount := LEAST(v_coupon.discount_value, v_total_subtotal);
    END IF;
  END IF;

  -- 4. Create parent enrollment
  INSERT INTO public.parent_enrollments (
    user_id, total, subtotal, discount,
    coupon_id, coupon_code, coupon_discount,
    payment_method, payment_status
  )
  VALUES (
    v_user_id,
    GREATEST(v_total_subtotal - v_coupon_discount, 0),
    v_total_subtotal,
    v_coupon_discount,
    v_coupon.id,
    v_coupon.code,
    v_coupon_discount,
    p_payment_method,
    CASE WHEN GREATEST(v_total_subtotal - v_coupon_discount, 0) = 0 THEN 'paid' ELSE 'pending' END
  )
  RETURNING id INTO v_parent_enrollment_id;

  -- 5. Insert or update course enrollments (Handling unique constraint conflict)
  FOR v_course IN
    SELECT
      c.id AS course_id,
      c.instructor_id,
      CASE
        WHEN c.is_flash_sale AND c.flash_sale_end > NOW() THEN COALESCE(c.flash_sale_price, c.discount_price, c.price)
        ELSE COALESCE(c.discount_price, c.price)
      END AS final_price
    FROM public.cart_items ci
    JOIN public.courses c ON c.id = ci.course_id
    WHERE ci.user_id = v_user_id
  LOOP
    INSERT INTO public.enrollments (
      user_id, course_id, instructor_id, parent_enrollment_id,
      price, discount, status, enrolled_at
    )
    VALUES (
      v_user_id,
      v_course.course_id,
      v_course.instructor_id,
      v_parent_enrollment_id,
      v_course.final_price,
      CASE
        WHEN v_total_subtotal > 0 THEN ROUND(v_coupon_discount * (v_course.final_price / v_total_subtotal), 2)
        ELSE 0
      END,
      CASE WHEN GREATEST(v_total_subtotal - v_coupon_discount, 0) = 0 THEN 'active' ELSE 'pending' END,
      NOW()
    )
    ON CONFLICT (user_id, course_id)
    DO UPDATE SET
      instructor_id = EXCLUDED.instructor_id,
      parent_enrollment_id = EXCLUDED.parent_enrollment_id,
      price = EXCLUDED.price,
      discount = EXCLUDED.discount,
      status = EXCLUDED.status,
      enrolled_at = EXCLUDED.enrolled_at,
      updated_at = NOW()
    RETURNING id INTO v_enrollment_id;
  END LOOP;

  -- 6. Record coupon usage if coupon was applied
  IF v_coupon.id IS NOT NULL THEN
    INSERT INTO public.coupon_usages (coupon_id, user_id, enrollment_id, discount_amount)
    VALUES (v_coupon.id, v_user_id, v_parent_enrollment_id, v_coupon_discount);

    UPDATE public.coupons
    SET usage_count = usage_count + 1
    WHERE id = v_coupon.id;
  END IF;

  -- 7. Clear cart items
  DELETE FROM public.cart_items WHERE user_id = v_user_id;

  RETURN v_parent_enrollment_id;
END;
$$;
