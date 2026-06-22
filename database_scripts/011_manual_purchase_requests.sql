-- Manual purchase request workflow
-- Run this after the previous schema migrations.

ALTER TABLE parent_enrollments
DROP CONSTRAINT IF EXISTS parent_enrollments_payment_status_check;

ALTER TABLE parent_enrollments
ADD CONSTRAINT parent_enrollments_payment_status_check
CHECK (
  payment_status IN (
    'pending',
    'pending_manual_payment',
    'paid',
    'failed',
    'cancelled',
    'refunded'
  )
);

CREATE INDEX IF NOT EXISTS idx_parent_enrollments_manual_pending
ON parent_enrollments(payment_status, created_at DESC)
WHERE payment_status = 'pending_manual_payment';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'parent_enrollments'
      AND policyname = 'Users can create their own parent enrollments'
  ) THEN
    CREATE POLICY "Users can create their own parent enrollments"
    ON parent_enrollments
    FOR INSERT
    WITH CHECK (user_id = auth.uid());
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'enrollments'
      AND policyname = 'Users can create their own pending enrollments'
  ) THEN
    CREATE POLICY "Users can create their own pending enrollments"
    ON enrollments
    FOR INSERT
    WITH CHECK (user_id = auth.uid());
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'parent_enrollments'
      AND policyname = 'Admins can update parent enrollments'
  ) THEN
    CREATE POLICY "Admins can update parent enrollments"
    ON parent_enrollments
    FOR UPDATE
    USING (is_admin())
    WITH CHECK (is_admin());
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'enrollments'
      AND policyname = 'Admins can update enrollments'
  ) THEN
    CREATE POLICY "Admins can update enrollments"
    ON enrollments
    FOR UPDATE
    USING (is_admin())
    WITH CHECK (is_admin());
  END IF;
END $$;

CREATE OR REPLACE FUNCTION approve_manual_purchase_request(
  p_parent_enrollment_id UUID,
  p_access_days INTEGER
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Only admins can approve manual purchase requests';
  END IF;

  IF p_access_days NOT IN (30, 60, 90) THEN
    RAISE EXCEPTION 'Access days must be 30, 60, or 90';
  END IF;

  UPDATE parent_enrollments
  SET
    payment_status = 'paid',
    payment_method = 'manual',
    paid_at = NOW(),
    updated_at = NOW()
  WHERE id = p_parent_enrollment_id
    AND payment_status = 'pending_manual_payment';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pending manual purchase request was not found';
  END IF;

  UPDATE enrollments
  SET
    status = 'active',
    access_expires_at = NOW() + make_interval(days => p_access_days),
    enrolled_at = COALESCE(enrolled_at, NOW()),
    updated_at = NOW()
  WHERE parent_enrollment_id = p_parent_enrollment_id;

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

  UPDATE enrollments
  SET
    status = 'refunded',
    updated_at = NOW()
  WHERE parent_enrollment_id = p_parent_enrollment_id;

  RETURN TRUE;
END;
$$;

GRANT EXECUTE ON FUNCTION approve_manual_purchase_request(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION cancel_manual_purchase_request(UUID) TO authenticated;
