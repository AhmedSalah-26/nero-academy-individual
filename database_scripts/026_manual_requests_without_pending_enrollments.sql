-- Manual purchase requests must not create course enrollments until approved.
-- This migration stores requested courses separately, backfills old requests,
-- and removes unapproved manual rows from enrollments.

CREATE TABLE IF NOT EXISTS manual_purchase_request_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_enrollment_id UUID NOT NULL REFERENCES parent_enrollments(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  instructor_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  price DECIMAL(10,2) NOT NULL DEFAULT 0,
  original_price DECIMAL(10,2) DEFAULT 0,
  discount DECIMAL(10,2) DEFAULT 0,
  pricing_option JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(parent_enrollment_id, course_id)
);

CREATE INDEX IF NOT EXISTS idx_manual_purchase_items_parent
ON manual_purchase_request_items(parent_enrollment_id);

CREATE INDEX IF NOT EXISTS idx_manual_purchase_items_user_course
ON manual_purchase_request_items(user_id, course_id);

CREATE INDEX IF NOT EXISTS idx_manual_purchase_items_instructor
ON manual_purchase_request_items(instructor_id);

ALTER TABLE manual_purchase_request_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their manual request items"
ON manual_purchase_request_items;
CREATE POLICY "Users can view their manual request items"
ON manual_purchase_request_items
FOR SELECT
USING (user_id = auth.uid() OR is_admin());

DROP POLICY IF EXISTS "Users can create their manual request items"
ON manual_purchase_request_items;
CREATE POLICY "Users can create their manual request items"
ON manual_purchase_request_items
FOR INSERT
WITH CHECK (
  user_id = auth.uid()
  AND EXISTS (
    SELECT 1
    FROM parent_enrollments pe
    WHERE pe.id = parent_enrollment_id
      AND pe.user_id = auth.uid()
      AND pe.payment_method = 'manual'
      AND pe.payment_status = 'pending_manual_payment'
  )
);

DROP POLICY IF EXISTS "Admins can manage manual request items"
ON manual_purchase_request_items;
CREATE POLICY "Admins can manage manual request items"
ON manual_purchase_request_items
FOR ALL
USING (is_admin())
WITH CHECK (is_admin());

DROP POLICY IF EXISTS "Users can create their own pending enrollments"
ON enrollments;

DROP POLICY IF EXISTS "Users can create approved free enrollments"
ON enrollments;
CREATE POLICY "Users can create approved free enrollments"
ON enrollments
FOR INSERT
WITH CHECK (
  user_id = auth.uid()
  AND status = 'active'
  AND price = 0
  AND EXISTS (
    SELECT 1
    FROM parent_enrollments pe
    WHERE pe.id = parent_enrollment_id
      AND pe.user_id = auth.uid()
      AND pe.payment_method = 'free'
      AND pe.payment_status = 'paid'
      AND pe.total = 0
  )
  AND EXISTS (
    SELECT 1
    FROM courses c
    WHERE c.id = course_id
      AND (
        c.is_free = TRUE
        OR COALESCE(c.discount_price, c.price, 0) = 0
      )
  )
);

-- Backfill request items from the old design where pending requests were rows
-- in enrollments. This also keeps approved requests visible in the dashboard.
INSERT INTO manual_purchase_request_items (
  parent_enrollment_id,
  user_id,
  course_id,
  instructor_id,
  price,
  original_price,
  discount,
  pricing_option,
  created_at,
  updated_at
)
SELECT DISTINCT ON (e.parent_enrollment_id, e.course_id)
  e.parent_enrollment_id,
  e.user_id,
  e.course_id,
  e.instructor_id,
  e.price,
  e.price,
  COALESCE(e.discount, 0),
  e.pricing_option,
  COALESCE(e.created_at, NOW()),
  NOW()
FROM enrollments e
JOIN parent_enrollments pe ON pe.id = e.parent_enrollment_id
WHERE pe.payment_method = 'manual'
  AND pe.payment_status IN ('pending_manual_payment', 'paid', 'cancelled')
  AND e.parent_enrollment_id IS NOT NULL
ORDER BY e.parent_enrollment_id, e.course_id, e.created_at DESC
ON CONFLICT (parent_enrollment_id, course_id) DO UPDATE
SET
  user_id = EXCLUDED.user_id,
  instructor_id = EXCLUDED.instructor_id,
  price = EXCLUDED.price,
  original_price = EXCLUDED.original_price,
  discount = EXCLUDED.discount,
  pricing_option = EXCLUDED.pricing_option,
  updated_at = NOW();

-- Remove the accidental enrollments for requests that have not been approved.
DELETE FROM enrollments e
USING parent_enrollments pe
WHERE pe.id = e.parent_enrollment_id
  AND pe.payment_method = 'manual'
  AND pe.payment_status IN ('pending_manual_payment', 'cancelled');

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
  v_inserted_count INTEGER := 0;
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
    WHERE enrollments.status NOT IN ('active', 'completed');

    v_inserted_count := v_inserted_count + 1;
  END LOOP;

  IF v_inserted_count = 0 THEN
    RAISE EXCEPTION 'No enrollments were activated';
  END IF;

  RETURN TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION cancel_manual_purchase_request(
  p_parent_enrollment_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Only admins can cancel manual purchase requests';
  END IF;

  UPDATE parent_enrollments
  SET
    payment_status = 'cancelled',
    updated_at = NOW()
  WHERE id = p_parent_enrollment_id
    AND payment_status = 'pending_manual_payment';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pending manual purchase request was not found';
  END IF;

  DELETE FROM enrollments
  WHERE parent_enrollment_id = p_parent_enrollment_id;

  RETURN TRUE;
END;
$$;

GRANT SELECT, INSERT ON manual_purchase_request_items TO authenticated;
GRANT EXECUTE ON FUNCTION approve_manual_purchase_request(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION cancel_manual_purchase_request(UUID) TO authenticated;
