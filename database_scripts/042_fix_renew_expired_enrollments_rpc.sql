-- Fix renewal approvals for enrollments whose status is still active/completed
-- but access_expires_at has already passed.
CREATE OR REPLACE FUNCTION approve_manual_purchase_request(
  p_parent_enrollment_id UUID,
  p_access_days INTEGER
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_order parent_enrollments%ROWTYPE;
  v_item RECORD;
  v_activated_count INTEGER := 0;
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Only admins can approve manual purchase requests';
  END IF;

  IF p_access_days NOT IN (30, 60, 90) THEN
    RAISE EXCEPTION 'Access days must be 30, 60, or 90';
  END IF;

  SELECT *
  INTO v_order
  FROM parent_enrollments
  WHERE id = p_parent_enrollment_id
    AND payment_status = 'pending_manual_payment'
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pending manual purchase request was not found';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM manual_purchase_request_items
    WHERE parent_enrollment_id = p_parent_enrollment_id
  ) THEN
    RAISE EXCEPTION 'Manual purchase request has no courses';
  END IF;

  UPDATE parent_enrollments
  SET
    payment_status = 'paid',
    payment_method = 'manual',
    paid_at = NOW(),
    updated_at = NOW()
  WHERE id = p_parent_enrollment_id;

  FOR v_item IN
    SELECT *
    FROM manual_purchase_request_items
    WHERE parent_enrollment_id = p_parent_enrollment_id
  LOOP
    INSERT INTO enrollments (
      user_id,
      course_id,
      instructor_id,
      parent_enrollment_id,
      price,
      pricing_option,
      discount,
      status,
      progress_percentage,
      completed_lessons,
      total_watch_time,
      access_expires_at,
      enrolled_at,
      updated_at
    )
    VALUES (
      v_item.user_id,
      v_item.course_id,
      v_item.instructor_id,
      p_parent_enrollment_id,
      v_item.price,
      v_item.pricing_option,
      COALESCE(v_item.discount, 0),
      'active',
      0,
      0,
      0,
      NOW() + make_interval(days => p_access_days),
      NOW(),
      NOW()
    )
    ON CONFLICT (user_id, course_id)
    DO UPDATE SET
      instructor_id = EXCLUDED.instructor_id,
      parent_enrollment_id = EXCLUDED.parent_enrollment_id,
      price = EXCLUDED.price,
      pricing_option = EXCLUDED.pricing_option,
      discount = EXCLUDED.discount,
      status = 'active',
      access_expires_at = EXCLUDED.access_expires_at,
      enrolled_at = NOW(),
      updated_at = NOW()
    WHERE enrollments.status IN ('pending', 'expired', 'refunded')
      OR enrollments.access_expires_at <= NOW();

    IF FOUND THEN
      v_activated_count := v_activated_count + 1;
    END IF;
  END LOOP;

  IF v_activated_count = 0 THEN
    RAISE EXCEPTION 'No enrollments were activated';
  END IF;

  RETURN TRUE;
END;
$$;

GRANT EXECUTE ON FUNCTION approve_manual_purchase_request(UUID, INTEGER) TO authenticated;
