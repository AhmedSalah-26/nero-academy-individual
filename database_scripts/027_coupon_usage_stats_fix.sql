-- Keep instructor coupon statistics in sync with paid parent enrollments.

WITH ranked_usages AS (
  SELECT
    id,
    ROW_NUMBER() OVER (
      PARTITION BY coupon_id, enrollment_id
      ORDER BY used_at DESC, id DESC
    ) AS rn
  FROM coupon_usages
  WHERE enrollment_id IS NOT NULL
)
DELETE FROM coupon_usages cu
USING ranked_usages ranked
WHERE cu.id = ranked.id
  AND ranked.rn > 1;

CREATE UNIQUE INDEX IF NOT EXISTS idx_coupon_usages_coupon_enrollment
ON coupon_usages(coupon_id, enrollment_id)
WHERE enrollment_id IS NOT NULL;

DROP POLICY IF EXISTS "Instructors can view own coupon usages"
ON coupon_usages;
CREATE POLICY "Instructors can view own coupon usages"
ON coupon_usages
FOR SELECT
USING (
  user_id = auth.uid()
  OR EXISTS (
    SELECT 1
    FROM coupons c
    WHERE c.id = coupon_usages.coupon_id
      AND c.instructor_id = auth.uid()
  )
  OR is_admin()
);

CREATE OR REPLACE FUNCTION public.refresh_coupon_usage_count(
  p_coupon_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF p_coupon_id IS NULL THEN
    RETURN;
  END IF;

  UPDATE coupons
  SET usage_count = (
    SELECT COUNT(*)::INTEGER
    FROM coupon_usages
    WHERE coupon_id = p_coupon_id
  )
  WHERE id = p_coupon_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.sync_coupon_usage_from_parent_enrollment()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'UPDATE'
     AND OLD.coupon_id IS NOT NULL
     AND OLD.coupon_id IS DISTINCT FROM NEW.coupon_id THEN
    DELETE FROM coupon_usages
    WHERE coupon_id = OLD.coupon_id
      AND enrollment_id = NEW.id;

    PERFORM public.refresh_coupon_usage_count(OLD.coupon_id);
  END IF;

  IF NEW.coupon_id IS NOT NULL
     AND NEW.payment_status = 'paid' THEN
    INSERT INTO coupon_usages (
      coupon_id,
      user_id,
      enrollment_id,
      discount_amount,
      used_at
    )
    VALUES (
      NEW.coupon_id,
      NEW.user_id,
      NEW.id,
      GREATEST(COALESCE(NEW.coupon_discount, NEW.discount, 0), 0),
      COALESCE(NEW.paid_at, NOW())
    )
    ON CONFLICT (coupon_id, enrollment_id)
    WHERE enrollment_id IS NOT NULL
    DO UPDATE SET
      user_id = EXCLUDED.user_id,
      discount_amount = EXCLUDED.discount_amount,
      used_at = EXCLUDED.used_at;

    PERFORM public.refresh_coupon_usage_count(NEW.coupon_id);
  ELSE
    DELETE FROM coupon_usages
    WHERE enrollment_id = NEW.id;

    PERFORM public.refresh_coupon_usage_count(NEW.coupon_id);

    IF TG_OP = 'UPDATE' THEN
      PERFORM public.refresh_coupon_usage_count(OLD.coupon_id);
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_coupon_usage_from_parent_enrollment
ON parent_enrollments;
CREATE TRIGGER trg_sync_coupon_usage_from_parent_enrollment
AFTER INSERT OR UPDATE OF
  payment_status,
  coupon_id,
  coupon_discount,
  discount,
  user_id,
  paid_at
ON parent_enrollments
FOR EACH ROW
EXECUTE FUNCTION public.sync_coupon_usage_from_parent_enrollment();

-- Backfill paid orders that already used coupons but never created usage rows.
INSERT INTO coupon_usages (
  coupon_id,
  user_id,
  enrollment_id,
  discount_amount,
  used_at
)
SELECT
  pe.coupon_id,
  pe.user_id,
  pe.id,
  GREATEST(COALESCE(pe.coupon_discount, pe.discount, 0), 0),
  COALESCE(pe.paid_at, pe.updated_at, pe.created_at, NOW())
FROM parent_enrollments pe
WHERE pe.coupon_id IS NOT NULL
  AND pe.payment_status = 'paid'
ON CONFLICT (coupon_id, enrollment_id)
WHERE enrollment_id IS NOT NULL
DO UPDATE SET
  user_id = EXCLUDED.user_id,
  discount_amount = EXCLUDED.discount_amount,
  used_at = EXCLUDED.used_at;

-- Remove usage rows for orders that are still pending, cancelled, or no longer
-- attached to the same coupon.
DELETE FROM coupon_usages cu
USING parent_enrollments pe
WHERE cu.enrollment_id = pe.id
  AND (
    pe.coupon_id IS NULL
    OR pe.coupon_id <> cu.coupon_id
    OR pe.payment_status <> 'paid'
  );

-- Repair any stale counters from the usage table.
UPDATE coupons c
SET usage_count = COALESCE(usage_stats.usage_count, 0)
FROM (
  SELECT c_inner.id, COUNT(cu.id)::INTEGER AS usage_count
  FROM coupons c_inner
  LEFT JOIN coupon_usages cu ON cu.coupon_id = c_inner.id
  GROUP BY c_inner.id
) AS usage_stats
WHERE usage_stats.id = c.id;

GRANT EXECUTE ON FUNCTION public.refresh_coupon_usage_count(UUID)
TO authenticated;
