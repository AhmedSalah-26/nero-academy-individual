-- ============================================================
-- 039_get_course_details_rpc.sql
-- Creates get_course_details() RPC used by both web & Flutter
-- to fetch full curriculum metadata bypassing RLS.
-- Non-enrolled users see locked lessons, enrolled users see all.
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_course_details(
  p_course_id UUID,
  p_locale    TEXT DEFAULT 'ar'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'sections', COALESCE(
      (
        SELECT jsonb_agg(
          jsonb_build_object(
            'id',         s.id,
            'title',      CASE
                            WHEN p_locale = 'en'
                              AND s.title_en IS NOT NULL
                              AND s.title_en <> ''
                            THEN s.title_en
                            ELSE s.title_ar
                          END,
            'sort_order', s.sort_order,
            'lessons',    COALESCE(
              (
                SELECT jsonb_agg(
                  jsonb_build_object(
                    'id',              l.id,
                    'title',           CASE
                                         WHEN p_locale = 'en'
                                           AND l.title_en IS NOT NULL
                                           AND l.title_en <> ''
                                         THEN l.title_en
                                         ELSE l.title_ar
                                       END,
                    'type',            l.type,
                    'duration',        l.video_duration,
                    'is_preview',      l.is_preview,
                    'available_from',  l.available_from,
                    'available_until', l.available_until
                  )
                  ORDER BY l.sort_order ASC
                )
                FROM lessons l
                WHERE l.section_id = s.id
              ),
              '[]'::jsonb
            )
          )
          ORDER BY s.sort_order ASC
        )
        FROM sections s
        WHERE s.course_id   = p_course_id
          AND s.is_published = TRUE
      ),
      '[]'::jsonb
    )
  ) INTO v_result;

  RETURN v_result;
END;
$$;

-- Grant execute to both anon (guest) and authenticated users
GRANT EXECUTE ON FUNCTION public.get_course_details(UUID, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.get_course_details(UUID, TEXT) TO authenticated;
