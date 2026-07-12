-- Keep quiz total_questions and total_points in sync with quiz_questions.
-- Also restores compatibility for older clients that call the legacy
-- increment/decrement RPC names after adding or deleting questions.

CREATE OR REPLACE FUNCTION public.update_quiz_question_totals(p_quiz_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.quizzes
  SET
    total_questions = (
      SELECT COUNT(*)::INT
      FROM public.quiz_questions
      WHERE quiz_id = p_quiz_id
    ),
    total_points = (
      SELECT COALESCE(SUM(points), 0)::INT
      FROM public.quiz_questions
      WHERE quiz_id = p_quiz_id
    ),
    updated_at = NOW()
  WHERE id = p_quiz_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.trigger_update_quiz_question_totals()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    PERFORM public.update_quiz_question_totals(OLD.quiz_id);
    RETURN OLD;
  END IF;

  PERFORM public.update_quiz_question_totals(NEW.quiz_id);

  IF TG_OP = 'UPDATE' AND OLD.quiz_id IS DISTINCT FROM NEW.quiz_id THEN
    PERFORM public.update_quiz_question_totals(OLD.quiz_id);
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS quiz_question_totals_trigger ON public.quiz_questions;

CREATE TRIGGER quiz_question_totals_trigger
AFTER INSERT OR UPDATE OR DELETE ON public.quiz_questions
FOR EACH ROW
EXECUTE FUNCTION public.trigger_update_quiz_question_totals();

CREATE OR REPLACE FUNCTION public.increment_quiz_questions(
  p_quiz_id UUID,
  p_points INTEGER DEFAULT 1
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public.update_quiz_question_totals(p_quiz_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.decrement_quiz_questions(
  p_quiz_id UUID,
  p_points INTEGER DEFAULT 1
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public.update_quiz_question_totals(p_quiz_id);
END;
$$;

DO $$
DECLARE
  quiz_record RECORD;
BEGIN
  FOR quiz_record IN SELECT id FROM public.quizzes LOOP
    PERFORM public.update_quiz_question_totals(quiz_record.id);
  END LOOP;
END;
$$;

GRANT EXECUTE ON FUNCTION public.update_quiz_question_totals(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.increment_quiz_questions(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.decrement_quiz_questions(UUID, INTEGER) TO authenticated;
