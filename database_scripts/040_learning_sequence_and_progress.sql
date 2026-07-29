-- Keep enrollment progress accurate when curriculum lessons change, and
-- provide one server-side rule for sequential lesson access.

CREATE OR REPLACE FUNCTION public.recalculate_enrollment_progress(
  p_enrollment_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_course_id UUID;
  v_total_lessons INTEGER := 0;
  v_completed_lessons INTEGER := 0;
  v_progress NUMERIC(5, 2) := 0;
BEGIN
  SELECT course_id
  INTO v_course_id
  FROM public.enrollments
  WHERE id = p_enrollment_id;

  IF v_course_id IS NULL THEN
    RETURN;
  END IF;

  SELECT COUNT(*)
  INTO v_total_lessons
  FROM public.lessons l
  JOIN public.sections s ON s.id = l.section_id
  WHERE l.course_id = v_course_id
    AND s.is_published = TRUE
    AND l.is_published = TRUE
    AND l.is_mandatory = TRUE;

  SELECT COUNT(DISTINCT lp.lesson_id)
  INTO v_completed_lessons
  FROM public.lesson_progress lp
  JOIN public.lessons l ON l.id = lp.lesson_id
  JOIN public.sections s ON s.id = l.section_id
  WHERE lp.enrollment_id = p_enrollment_id
    AND lp.is_completed = TRUE
    AND l.course_id = v_course_id
    AND s.is_published = TRUE
    AND l.is_published = TRUE
    AND l.is_mandatory = TRUE;

  IF v_total_lessons > 0 THEN
    v_progress := LEAST(
      100,
      ROUND((v_completed_lessons::NUMERIC / v_total_lessons) * 100, 2)
    );
  END IF;

  UPDATE public.enrollments
  SET progress_percentage = v_progress,
      completed_lessons = v_completed_lessons,
      total_watch_time = (
        SELECT COALESCE(SUM(lp.watch_time), 0)
        FROM public.lesson_progress lp
        WHERE lp.enrollment_id = p_enrollment_id
      ),
      completed_at = CASE
        WHEN v_progress >= 100 THEN COALESCE(completed_at, NOW())
        ELSE NULL
      END,
      status = CASE
        WHEN v_progress >= 100 AND status IN ('active', 'completed')
          THEN 'completed'
        WHEN v_progress < 100 AND status = 'completed'
          THEN 'active'
        ELSE status
      END,
      updated_at = NOW()
  WHERE id = p_enrollment_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_enrollment_progress()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_enrollment_id UUID;
BEGIN
  v_enrollment_id := COALESCE(NEW.enrollment_id, OLD.enrollment_id);

  IF v_enrollment_id IS NULL THEN
    SELECT e.id
    INTO v_enrollment_id
    FROM public.enrollments e
    WHERE e.user_id = COALESCE(NEW.user_id, OLD.user_id)
      AND e.course_id = COALESCE(NEW.course_id, OLD.course_id)
    LIMIT 1;
  END IF;

  IF v_enrollment_id IS NOT NULL THEN
    PERFORM public.recalculate_enrollment_progress(v_enrollment_id);
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trigger_update_enrollment_progress
  ON public.lesson_progress;
CREATE TRIGGER trigger_update_enrollment_progress
AFTER INSERT OR UPDATE OR DELETE ON public.lesson_progress
FOR EACH ROW
EXECUTE FUNCTION public.update_enrollment_progress();

CREATE OR REPLACE FUNCTION public.recalculate_course_enrollments_progress()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_course_id UUID;
  v_enrollment RECORD;
BEGIN
  v_course_id := COALESCE(NEW.course_id, OLD.course_id);

  FOR v_enrollment IN
    SELECT id
    FROM public.enrollments
    WHERE course_id = v_course_id
      AND status IN ('active', 'completed')
  LOOP
    PERFORM public.recalculate_enrollment_progress(v_enrollment.id);
  END LOOP;

  -- A lesson can be moved between courses.
  IF TG_OP = 'UPDATE'
     AND OLD.course_id IS DISTINCT FROM NEW.course_id THEN
    FOR v_enrollment IN
      SELECT id
      FROM public.enrollments
      WHERE course_id = OLD.course_id
        AND status IN ('active', 'completed')
    LOOP
      PERFORM public.recalculate_enrollment_progress(v_enrollment.id);
    END LOOP;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trigger_recalculate_progress_on_lesson_change
  ON public.lessons;
CREATE TRIGGER trigger_recalculate_progress_on_lesson_change
AFTER INSERT OR DELETE OR UPDATE OF
  course_id, section_id, sort_order, is_published, is_mandatory
ON public.lessons
FOR EACH ROW
EXECUTE FUNCTION public.recalculate_course_enrollments_progress();

DROP TRIGGER IF EXISTS trigger_recalculate_progress_on_section_change
  ON public.sections;
CREATE TRIGGER trigger_recalculate_progress_on_section_change
AFTER INSERT OR DELETE OR UPDATE OF course_id, sort_order, is_published
ON public.sections
FOR EACH ROW
EXECUTE FUNCTION public.recalculate_course_enrollments_progress();

CREATE OR REPLACE FUNCTION public.can_access_lesson(
  p_lesson_id UUID,
  p_enrollment_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id UUID;
  v_course_id UUID;
  v_target_position BIGINT;
BEGIN
  SELECT e.user_id, e.course_id
  INTO v_user_id, v_course_id
  FROM public.enrollments e
  JOIN public.lessons l ON l.course_id = e.course_id
  WHERE e.id = p_enrollment_id
    AND l.id = p_lesson_id
    AND e.status IN ('active', 'completed');

  IF v_course_id IS NULL OR v_user_id IS DISTINCT FROM auth.uid() THEN
    RETURN FALSE;
  END IF;

  WITH ordered_lessons AS (
    SELECT
      l.id,
      l.is_mandatory,
      ROW_NUMBER() OVER (
        ORDER BY
          COALESCE(s.sort_order, 0),
          s.created_at,
          s.id,
          COALESCE(l.sort_order, 0),
          l.created_at,
          l.id
      ) AS position
    FROM public.sections s
    JOIN public.lessons l ON l.section_id = s.id
    WHERE s.course_id = v_course_id
      AND s.is_published = TRUE
      AND l.is_published = TRUE
  )
  SELECT position
  INTO v_target_position
  FROM ordered_lessons
  WHERE id = p_lesson_id;

  IF v_target_position IS NULL THEN
    RETURN FALSE;
  END IF;

  -- Every mandatory lesson before the target must be completed.
  IF EXISTS (
    WITH ordered_lessons AS (
      SELECT
        l.id,
        l.is_mandatory,
        ROW_NUMBER() OVER (
          ORDER BY
            COALESCE(s.sort_order, 0),
            s.created_at,
            s.id,
            COALESCE(l.sort_order, 0),
            l.created_at,
            l.id
        ) AS position
      FROM public.sections s
      JOIN public.lessons l ON l.section_id = s.id
      WHERE s.course_id = v_course_id
        AND s.is_published = TRUE
        AND l.is_published = TRUE
    )
    SELECT 1
    FROM ordered_lessons previous_lesson
    WHERE previous_lesson.position < v_target_position
      AND previous_lesson.is_mandatory = TRUE
      AND NOT EXISTS (
        SELECT 1
        FROM public.lesson_progress lp
        WHERE lp.enrollment_id = p_enrollment_id
          AND lp.lesson_id = previous_lesson.id
          AND lp.is_completed = TRUE
      )
  ) THEN
    RETURN FALSE;
  END IF;

  -- Every published quiz attached to an earlier mandatory lesson must have
  -- at least one submitted attempt. Passing is intentionally not required.
  IF EXISTS (
    WITH ordered_lessons AS (
      SELECT
        l.id,
        l.is_mandatory,
        ROW_NUMBER() OVER (
          ORDER BY
            COALESCE(s.sort_order, 0),
            s.created_at,
            s.id,
            COALESCE(l.sort_order, 0),
            l.created_at,
            l.id
        ) AS position
      FROM public.sections s
      JOIN public.lessons l ON l.section_id = s.id
      WHERE s.course_id = v_course_id
        AND s.is_published = TRUE
        AND l.is_published = TRUE
    )
    SELECT 1
    FROM ordered_lessons previous_lesson
    JOIN public.quizzes q ON q.lesson_id = previous_lesson.id
    WHERE previous_lesson.position < v_target_position
      AND previous_lesson.is_mandatory = TRUE
      AND q.is_published = TRUE
      AND NOT EXISTS (
        SELECT 1
        FROM public.quiz_attempts qa
        WHERE qa.enrollment_id = p_enrollment_id
          AND qa.quiz_id = q.id
          AND qa.completed_at IS NOT NULL
      )
  ) THEN
    RETURN FALSE;
  END IF;

  RETURN TRUE;
END;
$$;

GRANT EXECUTE ON FUNCTION public.can_access_lesson(UUID, UUID)
  TO authenticated;

CREATE OR REPLACE FUNCTION public.enforce_lesson_progress_sequence()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  -- Instructor/admin maintenance is handled by its own authorization rules.
  IF auth.uid() IS DISTINCT FROM NEW.user_id THEN
    RETURN NEW;
  END IF;

  IF NOT public.can_access_lesson(NEW.lesson_id, NEW.enrollment_id) THEN
    RAISE EXCEPTION 'Complete previous lessons and quizzes first';
  END IF;

  IF NEW.is_completed = TRUE AND EXISTS (
    SELECT 1
    FROM public.quizzes q
    WHERE q.lesson_id = NEW.lesson_id
      AND q.is_published = TRUE
      AND NOT EXISTS (
        SELECT 1
        FROM public.quiz_attempts qa
        WHERE qa.enrollment_id = NEW.enrollment_id
          AND qa.quiz_id = q.id
          AND qa.completed_at IS NOT NULL
      )
  ) THEN
    RAISE EXCEPTION 'Complete this lesson quizzes first';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_enforce_lesson_progress_sequence
  ON public.lesson_progress;
CREATE TRIGGER trigger_enforce_lesson_progress_sequence
BEFORE INSERT OR UPDATE OF lesson_id, enrollment_id, is_completed
ON public.lesson_progress
FOR EACH ROW
EXECUTE FUNCTION public.enforce_lesson_progress_sequence();

-- Enforce the same access rule when clients write lesson progress, so a
-- manually crafted RPC request cannot complete a locked lesson.
CREATE OR REPLACE FUNCTION public.update_lesson_progress(
  p_lesson_id UUID,
  p_watch_time INTEGER DEFAULT 0,
  p_last_position INTEGER DEFAULT 0,
  p_is_completed BOOLEAN DEFAULT FALSE
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_course_id UUID;
  v_enrollment_id UUID;
  v_progress_id UUID;
  v_result JSON;
BEGIN
  SELECT course_id
  INTO v_course_id
  FROM public.lessons
  WHERE id = p_lesson_id
    AND is_published = TRUE;

  SELECT id
  INTO v_enrollment_id
  FROM public.enrollments
  WHERE user_id = v_user_id
    AND course_id = v_course_id
    AND status IN ('active', 'completed');

  IF v_enrollment_id IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Not enrolled in this course'
    );
  END IF;

  IF NOT public.can_access_lesson(p_lesson_id, v_enrollment_id) THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Complete previous lessons and quizzes first'
    );
  END IF;

  IF p_is_completed AND EXISTS (
    SELECT 1
    FROM public.quizzes q
    WHERE q.lesson_id = p_lesson_id
      AND q.is_published = TRUE
      AND NOT EXISTS (
        SELECT 1
        FROM public.quiz_attempts qa
        WHERE qa.enrollment_id = v_enrollment_id
          AND qa.quiz_id = q.id
          AND qa.completed_at IS NOT NULL
      )
  ) THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Complete this lesson quizzes first'
    );
  END IF;

  INSERT INTO public.lesson_progress (
    user_id,
    lesson_id,
    course_id,
    enrollment_id,
    watch_time,
    last_position,
    is_completed,
    completed_at
  )
  VALUES (
    v_user_id,
    p_lesson_id,
    v_course_id,
    v_enrollment_id,
    GREATEST(p_watch_time, 0),
    GREATEST(p_last_position, 0),
    p_is_completed,
    CASE WHEN p_is_completed THEN NOW() ELSE NULL END
  )
  ON CONFLICT (user_id, lesson_id) DO UPDATE
  SET watch_time = GREATEST(
        public.lesson_progress.watch_time,
        EXCLUDED.watch_time
      ),
      last_position = EXCLUDED.last_position,
      is_completed = public.lesson_progress.is_completed
        OR EXCLUDED.is_completed,
      completed_at = COALESCE(
        public.lesson_progress.completed_at,
        EXCLUDED.completed_at
      ),
      last_watched_at = NOW(),
      updated_at = NOW()
  RETURNING id INTO v_progress_id;

  SELECT json_build_object(
    'success', true,
    'progress_id', v_progress_id,
    'course_progress', progress_percentage,
    'completed_lessons', completed_lessons
  )
  INTO v_result
  FROM public.enrollments
  WHERE id = v_enrollment_id;

  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.update_lesson_progress(
  UUID, INTEGER, INTEGER, BOOLEAN
) TO authenticated;

-- Fix existing stale values immediately when the migration is applied.
DO $$
DECLARE
  v_enrollment RECORD;
BEGIN
  FOR v_enrollment IN
    SELECT id
    FROM public.enrollments
    WHERE status IN ('active', 'completed')
  LOOP
    PERFORM public.recalculate_enrollment_progress(v_enrollment.id);
  END LOOP;
END;
$$;
