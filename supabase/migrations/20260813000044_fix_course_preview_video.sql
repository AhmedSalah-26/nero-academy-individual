-- Repair the preview for "Programming Basics".
-- The previous preview lesson was unpublished and had no video URL.
DO $$
DECLARE
  v_course_id UUID := 'fb29c60d-0897-44c8-8114-6e615848268d';
  v_lesson_id UUID := 'b1c2fffa-bd27-476d-abea-443663134b80';
  v_preview_url TEXT := 'https://youtu.be/lkG1YYEsM0o';
BEGIN
  UPDATE public.lessons
  SET is_preview = TRUE,
      video_provider = 'youtube'
  WHERE id = v_lesson_id
    AND course_id = v_course_id
    AND is_published = TRUE
    AND video_url = v_preview_url;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Expected published preview lesson was not found';
  END IF;

  UPDATE public.courses
  SET preview_video_url = v_preview_url,
      updated_at = NOW()
  WHERE id = v_course_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Expected course was not found';
  END IF;
END;
$$;
