-- ============================================================
-- 020_earnings_trigger.sql
-- Auto-insert into instructor_earnings on every active enrollment
-- ============================================================

-- Function: Called after each row inserted/updated in enrollments
CREATE OR REPLACE FUNCTION trigger_create_instructor_earning()
RETURNS TRIGGER AS $$
DECLARE
  v_instructor_id UUID;
  v_price         DECIMAL(10,2);
  v_gross         DECIMAL(10,2);
  v_platform_fee  DECIMAL(10,2);
  v_net           DECIMAL(10,2);
  v_revenue_share DECIMAL(5,2) := 100.00; -- 100% to instructor (no platform fee)
BEGIN
  -- Only create earning on active enrollment with a price > 0
  IF NEW.status <> 'active' THEN
    RETURN NEW;
  END IF;

  -- Get instructor_id and price from enrollment
  v_instructor_id := NEW.instructor_id;
  v_price         := COALESCE(NEW.price, 0);

  -- If instructor_id not set on enrollment row, get it from courses table
  IF v_instructor_id IS NULL THEN
    SELECT instructor_id INTO v_instructor_id
    FROM courses WHERE id = NEW.course_id;
  END IF;

  IF v_instructor_id IS NULL THEN
    RETURN NEW; -- no instructor found, skip
  END IF;

  -- Skip if price is 0 (free course)
  IF v_price <= 0 THEN
    RETURN NEW;
  END IF;

  v_gross        := v_price;
  v_platform_fee := 0.00;                  -- adjust if platform takes a cut
  v_net          := v_gross - v_platform_fee;

  -- Avoid duplicates: only insert if no earning row exists for this enrollment
  IF NOT EXISTS (
    SELECT 1 FROM instructor_earnings WHERE enrollment_id = NEW.id
  ) THEN
    INSERT INTO instructor_earnings (
      instructor_id,
      enrollment_id,
      course_id,
      gross_amount,
      platform_fee,
      net_amount,
      revenue_share,
      status,
      available_at,
      created_at
    ) VALUES (
      v_instructor_id,
      NEW.id,
      NEW.course_id,
      v_gross,
      v_platform_fee,
      v_net,
      v_revenue_share,
      'available',
      NOW(),
      NOW()
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- Drop and recreate trigger
DROP TRIGGER IF EXISTS trigger_auto_instructor_earning ON enrollments;

CREATE TRIGGER trigger_auto_instructor_earning
AFTER INSERT OR UPDATE OF status ON enrollments
FOR EACH ROW
EXECUTE FUNCTION trigger_create_instructor_earning();

-- Make sure trigger function can't be called by clients directly
REVOKE EXECUTE ON FUNCTION trigger_create_instructor_earning() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION trigger_create_instructor_earning() FROM authenticated;
REVOKE EXECUTE ON FUNCTION trigger_create_instructor_earning() FROM anon;

SELECT '020 - Instructor earnings trigger created successfully!' AS status;
