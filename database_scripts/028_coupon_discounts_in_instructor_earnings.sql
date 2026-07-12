-- Instructor earnings must be calculated after per-course coupon discounts.

ALTER TABLE instructor_earnings
ADD COLUMN IF NOT EXISTS coupon_discount DECIMAL(10,2) NOT NULL DEFAULT 0;

CREATE OR REPLACE FUNCTION trigger_create_instructor_earning()
RETURNS TRIGGER AS $$
DECLARE
  v_instructor_id UUID;
  v_gross DECIMAL(10,2);
  v_coupon_discount DECIMAL(10,2);
  v_platform_fee DECIMAL(10,2);
  v_net DECIMAL(10,2);
  v_revenue_share DECIMAL(5,2) := 100.00;
BEGIN
  IF NEW.status NOT IN ('active', 'completed') THEN
    RETURN NEW;
  END IF;

  v_instructor_id := NEW.instructor_id;
  v_gross := GREATEST(COALESCE(NEW.price, 0), 0);
  v_coupon_discount := LEAST(
    GREATEST(COALESCE(NEW.discount, 0), 0),
    v_gross
  );

  IF v_instructor_id IS NULL THEN
    SELECT instructor_id INTO v_instructor_id
    FROM courses
    WHERE id = NEW.course_id;
  END IF;

  IF v_instructor_id IS NULL OR v_gross <= 0 THEN
    RETURN NEW;
  END IF;

  v_platform_fee := 0.00;
  v_net := GREATEST(v_gross - v_coupon_discount - v_platform_fee, 0);

  INSERT INTO instructor_earnings (
    instructor_id,
    enrollment_id,
    course_id,
    gross_amount,
    coupon_discount,
    platform_fee,
    net_amount,
    revenue_share,
    status,
    available_at,
    created_at
  )
  VALUES (
    v_instructor_id,
    NEW.id,
    NEW.course_id,
    v_gross,
    v_coupon_discount,
    v_platform_fee,
    v_net,
    v_revenue_share,
    'available',
    NOW(),
    NOW()
  )
  ON CONFLICT (enrollment_id)
  DO UPDATE SET
    instructor_id = EXCLUDED.instructor_id,
    course_id = EXCLUDED.course_id,
    gross_amount = EXCLUDED.gross_amount,
    coupon_discount = EXCLUDED.coupon_discount,
    platform_fee = EXCLUDED.platform_fee,
    net_amount = EXCLUDED.net_amount,
    revenue_share = EXCLUDED.revenue_share,
    status = CASE
      WHEN instructor_earnings.status = 'paid' THEN instructor_earnings.status
      ELSE EXCLUDED.status
    END,
    available_at = COALESCE(instructor_earnings.available_at, EXCLUDED.available_at);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

DROP TRIGGER IF EXISTS trigger_auto_instructor_earning ON enrollments;
CREATE TRIGGER trigger_auto_instructor_earning
AFTER INSERT OR UPDATE OF status, price, discount, instructor_id, course_id
ON enrollments
FOR EACH ROW
EXECUTE FUNCTION trigger_create_instructor_earning();

WITH ranked_earnings AS (
  SELECT
    id,
    ROW_NUMBER() OVER (
      PARTITION BY enrollment_id
      ORDER BY created_at DESC, id DESC
    ) AS rn
  FROM instructor_earnings
)
DELETE FROM instructor_earnings ie
USING ranked_earnings ranked
WHERE ie.id = ranked.id
  AND ranked.rn > 1;

CREATE UNIQUE INDEX IF NOT EXISTS idx_instructor_earnings_enrollment
ON instructor_earnings(enrollment_id);

-- Recalculate old earning rows from their enrollment row.
UPDATE instructor_earnings ie
SET
  gross_amount = GREATEST(COALESCE(e.price, 0), 0),
  coupon_discount = LEAST(
    GREATEST(COALESCE(e.discount, 0), 0),
    GREATEST(COALESCE(e.price, 0), 0)
  ),
  platform_fee = 0,
  net_amount = GREATEST(
    GREATEST(COALESCE(e.price, 0), 0)
    - LEAST(
        GREATEST(COALESCE(e.discount, 0), 0),
        GREATEST(COALESCE(e.price, 0), 0)
      ),
    0
  ),
  revenue_share = 100
FROM enrollments e
WHERE e.id = ie.enrollment_id
  AND e.status IN ('active', 'completed');

-- Create any missing earning rows for active paid enrollments.
INSERT INTO instructor_earnings (
  instructor_id,
  enrollment_id,
  course_id,
  gross_amount,
  coupon_discount,
  platform_fee,
  net_amount,
  revenue_share,
  status,
  available_at,
  created_at
)
SELECT
  COALESCE(e.instructor_id, c.instructor_id),
  e.id,
  e.course_id,
  GREATEST(COALESCE(e.price, 0), 0),
  LEAST(
    GREATEST(COALESCE(e.discount, 0), 0),
    GREATEST(COALESCE(e.price, 0), 0)
  ),
  0,
  GREATEST(
    GREATEST(COALESCE(e.price, 0), 0)
    - LEAST(
        GREATEST(COALESCE(e.discount, 0), 0),
        GREATEST(COALESCE(e.price, 0), 0)
      ),
    0
  ),
  100,
  'available',
  NOW(),
  COALESCE(e.enrolled_at, NOW())
FROM enrollments e
JOIN courses c ON c.id = e.course_id
WHERE e.status IN ('active', 'completed')
  AND GREATEST(COALESCE(e.price, 0), 0) > 0
  AND COALESCE(e.instructor_id, c.instructor_id) IS NOT NULL
ON CONFLICT (enrollment_id)
DO NOTHING;

CREATE OR REPLACE FUNCTION update_course_stats(p_course_id UUID)
RETURNS VOID AS $$
DECLARE
    v_section_count INT;
    v_lesson_count INT;
    v_total_revenue DECIMAL(10,2);
BEGIN
    SELECT COUNT(*) INTO v_section_count
    FROM sections
    WHERE course_id = p_course_id;

    SELECT COUNT(*) INTO v_lesson_count
    FROM lessons
    WHERE course_id = p_course_id;

    SELECT COALESCE(SUM(net_amount), 0) INTO v_total_revenue
    FROM instructor_earnings
    WHERE course_id = p_course_id
      AND status IN ('available', 'paid', 'pending');

    UPDATE courses
    SET
      section_count = v_section_count,
      lesson_count = v_lesson_count,
      total_revenue = v_total_revenue
    WHERE id = p_course_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

CREATE OR REPLACE FUNCTION get_instructor_dashboard_stats()
RETURNS JSON AS $$
DECLARE
    v_instructor_id UUID := auth.uid();
    v_stats JSON;
    v_total_courses INT;
    v_published_courses INT;
    v_total_students INT;
    v_total_enrollments INT;
    v_monthly_enrollments INT;
    v_total_earnings NUMERIC;
    v_available_balance NUMERIC;
    v_pending_balance NUMERIC;
    v_average_rating NUMERIC;
    v_total_reviews INT;
    v_unanswered_questions INT;
BEGIN
    SELECT COUNT(*), COUNT(CASE WHEN is_published THEN 1 END)
    INTO v_total_courses, v_published_courses
    FROM courses
    WHERE instructor_id = v_instructor_id;

    SELECT
        COUNT(DISTINCT e.user_id),
        COUNT(*),
        COUNT(CASE WHEN e.enrolled_at >= DATE_TRUNC('month', NOW()) THEN 1 END)
    INTO v_total_students, v_total_enrollments, v_monthly_enrollments
    FROM enrollments e
    JOIN courses c ON c.id = e.course_id
    WHERE c.instructor_id = v_instructor_id
      AND e.status IN ('active', 'completed');

    SELECT
      COALESCE(SUM(net_amount), 0),
      COALESCE(SUM(CASE WHEN status IN ('available', 'paid') THEN net_amount ELSE 0 END), 0),
      COALESCE(SUM(CASE WHEN status = 'pending' THEN net_amount ELSE 0 END), 0)
    INTO v_total_earnings, v_available_balance, v_pending_balance
    FROM instructor_earnings
    WHERE instructor_id = v_instructor_id;

    SELECT COALESCE(AVG(cr.rating), 0), COUNT(*)
    INTO v_average_rating, v_total_reviews
    FROM course_reviews cr
    JOIN courses c ON c.id = cr.course_id
    WHERE c.instructor_id = v_instructor_id;

    SELECT COUNT(*)
    INTO v_unanswered_questions
    FROM qa_questions q
    JOIN courses c ON c.id = q.course_id
    WHERE c.instructor_id = v_instructor_id
      AND q.is_answered = false;

    v_stats := json_build_object(
        'total_courses', COALESCE(v_total_courses, 0),
        'published_courses', COALESCE(v_published_courses, 0),
        'total_students', COALESCE(v_total_students, 0),
        'total_enrollments', COALESCE(v_total_enrollments, 0),
        'monthly_enrollments', COALESCE(v_monthly_enrollments, 0),
        'total_earnings', COALESCE(v_total_earnings, 0),
        'available_balance', COALESCE(v_available_balance, 0),
        'pending_balance', COALESCE(v_pending_balance, 0),
        'average_rating', ROUND(COALESCE(v_average_rating, 0)::numeric, 1),
        'total_reviews', COALESCE(v_total_reviews, 0),
        'unanswered_questions', COALESCE(v_unanswered_questions, 0)
    );

    RETURN v_stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

CREATE OR REPLACE FUNCTION get_instructor_revenue_chart(
    p_start_date TIMESTAMPTZ DEFAULT NOW() - INTERVAL '30 days',
    p_end_date TIMESTAMPTZ DEFAULT NOW()
)
RETURNS TABLE (
    label TEXT,
    value DECIMAL(10,2)
) AS $$
DECLARE
    v_instructor_id UUID := auth.uid();
BEGIN
    RETURN QUERY
    SELECT
        TO_CHAR(DATE_TRUNC('day', dates.date), 'MM/DD') AS label,
        COALESCE(SUM(ie.net_amount), 0)::DECIMAL(10,2) AS value
    FROM generate_series(
        DATE_TRUNC('day', p_start_date),
        DATE_TRUNC('day', p_end_date),
        '1 day'::INTERVAL
    ) AS dates(date)
    LEFT JOIN instructor_earnings ie ON
        DATE_TRUNC('day', ie.created_at) = dates.date
        AND ie.instructor_id = v_instructor_id
        AND ie.status IN ('available', 'paid', 'pending')
    GROUP BY dates.date
    ORDER BY dates.date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

DO $$
DECLARE
    course_record RECORD;
BEGIN
    FOR course_record IN SELECT id FROM courses LOOP
        PERFORM update_course_stats(course_record.id);
    END LOOP;
END $$;

GRANT EXECUTE ON FUNCTION update_course_stats(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_instructor_dashboard_stats() TO authenticated;
GRANT EXECUTE ON FUNCTION get_instructor_revenue_chart(TIMESTAMPTZ, TIMESTAMPTZ)
TO authenticated;

REVOKE EXECUTE ON FUNCTION trigger_create_instructor_earning() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION trigger_create_instructor_earning() FROM authenticated;
REVOKE EXECUTE ON FUNCTION trigger_create_instructor_earning() FROM anon;
