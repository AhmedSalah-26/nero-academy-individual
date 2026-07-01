-- Fix checkout totals for courses whose public price is stored in pricing_options.
-- Apply this in Supabase SQL editor after 001_individual_lms_schema.sql.

CREATE OR REPLACE FUNCTION public.course_effective_price(
  p_price NUMERIC,
  p_discount_price NUMERIC,
  p_is_free BOOLEAN,
  p_pricing_options JSONB,
  p_is_flash_sale BOOLEAN DEFAULT FALSE,
  p_flash_sale_price NUMERIC DEFAULT NULL,
  p_flash_sale_end TIMESTAMPTZ DEFAULT NULL
)
RETURNS NUMERIC
LANGUAGE sql
STABLE
AS $$
  WITH base AS (
    SELECT COALESCE(
      NULLIF(p_price, 0),
      (
        SELECT MIN(NULLIF((opt->>'price')::NUMERIC, 0))
        FROM jsonb_array_elements(COALESCE(p_pricing_options, '[]'::jsonb)) opt
      ),
      0
    ) AS base_price
  )
  SELECT CASE
    WHEN COALESCE(p_is_free, FALSE) THEN 0
    WHEN COALESCE(p_is_flash_sale, FALSE)
      AND (p_flash_sale_end IS NULL OR p_flash_sale_end > NOW())
      AND COALESCE(p_flash_sale_price, 0) > 0
      AND p_flash_sale_price < base.base_price
      THEN p_flash_sale_price
    WHEN COALESCE(p_discount_price, 0) > 0
      AND p_discount_price < base.base_price
      THEN p_discount_price
    ELSE base.base_price
  END
  FROM base;
$$;

CREATE OR REPLACE FUNCTION public.create_enrollment(
  p_user_id UUID,
  p_payment_method TEXT DEFAULT 'card',
  p_coupon_id UUID DEFAULT NULL,
  p_coupon_code VARCHAR DEFAULT NULL,
  p_coupon_discount DECIMAL DEFAULT 0
)
RETURNS UUID AS $$
DECLARE
  v_parent_enrollment_id UUID;
  v_enrollment_id UUID;
  v_course RECORD;
  v_total_subtotal DECIMAL := 0;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM cart_items WHERE user_id = p_user_id) THEN
    RAISE EXCEPTION 'Cart is empty';
  END IF;

  SELECT COALESCE(SUM(public.course_effective_price(
    c.price,
    c.discount_price,
    c.is_free,
    c.pricing_options,
    c.is_flash_sale,
    c.flash_sale_price,
    c.flash_sale_end
  )), 0)
  INTO v_total_subtotal
  FROM cart_items ci
  JOIN courses c ON c.id = ci.course_id
  WHERE ci.user_id = p_user_id;

  INSERT INTO parent_enrollments (
    user_id, total, subtotal, discount,
    coupon_id, coupon_code, coupon_discount,
    payment_method, payment_status
  )
  VALUES (
    p_user_id,
    GREATEST(v_total_subtotal - COALESCE(p_coupon_discount, 0), 0),
    v_total_subtotal,
    COALESCE(p_coupon_discount, 0),
    p_coupon_id, p_coupon_code, COALESCE(p_coupon_discount, 0),
    p_payment_method,
    CASE WHEN GREATEST(v_total_subtotal - COALESCE(p_coupon_discount, 0), 0) = 0 THEN 'paid' ELSE 'pending' END
  )
  RETURNING id INTO v_parent_enrollment_id;

  FOR v_course IN
    SELECT
      c.id AS course_id,
      c.instructor_id,
      public.course_effective_price(
        c.price,
        c.discount_price,
        c.is_free,
        c.pricing_options,
        c.is_flash_sale,
        c.flash_sale_price,
        c.flash_sale_end
      ) AS final_price
    FROM cart_items ci
    JOIN courses c ON c.id = ci.course_id
    WHERE ci.user_id = p_user_id
  LOOP
    INSERT INTO enrollments (
      user_id, course_id, instructor_id, parent_enrollment_id,
      price, status, enrolled_at
    )
    VALUES (
      p_user_id, v_course.course_id, v_course.instructor_id, v_parent_enrollment_id,
      v_course.final_price,
      CASE WHEN v_course.final_price = 0 OR GREATEST(v_total_subtotal - COALESCE(p_coupon_discount, 0), 0) = 0 THEN 'active' ELSE 'pending' END,
      NOW()
    )
    ON CONFLICT (user_id, course_id) DO UPDATE SET
      parent_enrollment_id = EXCLUDED.parent_enrollment_id,
      price = EXCLUDED.price,
      status = EXCLUDED.status,
      updated_at = NOW()
    RETURNING id INTO v_enrollment_id;
  END LOOP;

  IF p_coupon_id IS NOT NULL THEN
    INSERT INTO coupon_usages (coupon_id, user_id, enrollment_id, discount_amount)
    VALUES (p_coupon_id, p_user_id, v_parent_enrollment_id, COALESCE(p_coupon_discount, 0));

    UPDATE coupons SET usage_count = usage_count + 1 WHERE id = p_coupon_id;
  END IF;

  DELETE FROM cart_items WHERE user_id = p_user_id;

  RETURN v_parent_enrollment_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.course_effective_price(NUMERIC, NUMERIC, BOOLEAN, JSONB, BOOLEAN, NUMERIC, TIMESTAMPTZ) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_enrollment(UUID, TEXT, UUID, VARCHAR, DECIMAL) TO authenticated;
