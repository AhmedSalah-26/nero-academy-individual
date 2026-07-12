-- ============================================================
-- 029_fix_group_chat_unauthorized_participants.sql
-- 
-- Problem: Students who have NOT enrolled (or have pending enrollments)
-- appear in course group conversations because:
--   1. They were added manually
--   2. Old versions of get_user_conversations auto-joined without
--      proper status filtering
--
-- Fix:
--   1. Remove any 'member' participants from group conversations
--      who are NOT actively enrolled (active/completed) in the course.
--   2. Update get_user_conversations to ONLY auto-join users who
--      have ACTIVE or COMPLETED enrollments.
-- ============================================================

-- Step 1: Clean up unauthorized participants
-- Remove members from group chats if they are not actively enrolled
DELETE FROM public.conversation_participants cp
USING public.conversations c
WHERE cp.conversation_id = c.id
  AND c.type = 'multi'
  AND c.course_id IS NOT NULL
  AND cp.role = 'member'
  AND NOT EXISTS (
    SELECT 1
    FROM public.enrollments e
    WHERE e.course_id = c.course_id
      AND e.user_id = cp.user_id
      AND e.status IN ('active', 'completed')
  )
  -- Don't remove the instructor/admin
  AND NOT EXISTS (
    SELECT 1 FROM public.courses cr
    WHERE cr.id = c.course_id
      AND cr.instructor_id = cp.user_id
  );

-- Step 2: Replace get_user_conversations with a version that
-- auto-joins ONLY on active/completed enrollments
DROP FUNCTION IF EXISTS public.get_user_conversations(UUID, TEXT);

CREATE OR REPLACE FUNCTION public.get_user_conversations(
    p_user_id UUID,
    p_type TEXT DEFAULT NULL
)
RETURNS TABLE (
    conversation_id UUID,
    conversation_type VARCHAR(10),
    conversation_title TEXT,
    course_id UUID,
    created_at TIMESTAMPTZ,
    last_message_id UUID,
    last_message_text TEXT,
    last_message_user_id UUID,
    last_message_user_name TEXT,
    last_message_created_at TIMESTAMPTZ,
    participants_count BIGINT,
    other_user_name TEXT,
    other_user_avatar TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_caller UUID := auth.uid();
    v_is_admin BOOLEAN := FALSE;
BEGIN
    IF v_caller IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM public.profiles p
        WHERE p.id = v_caller AND p.role = 'admin'
    ) INTO v_is_admin;

    IF v_caller <> p_user_id AND NOT v_is_admin THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    -- Auto-join ONLY for users with ACTIVE or COMPLETED enrollments
    -- (NOT pending, NOT pending_manual_payment)
    INSERT INTO public.conversation_participants (conversation_id, user_id, role)
    SELECT
        c.id,
        p_user_id,
        CASE
            WHEN cr.instructor_id = p_user_id THEN 'admin'
            ELSE 'member'
        END
    FROM public.conversations c
    JOIN public.courses cr ON cr.id = c.course_id
    WHERE c.type = 'multi'
      AND (
          cr.instructor_id = p_user_id
          OR EXISTS (
              SELECT 1
              FROM public.enrollments e
              WHERE e.course_id = c.course_id
                AND e.user_id = p_user_id
                AND e.status IN ('active', 'completed')  -- ✅ Only active/completed
          )
      )
    ON CONFLICT ON CONSTRAINT conversation_participants_conversation_id_user_id_key DO UPDATE
    SET role = CASE
        WHEN EXCLUDED.role = 'admin' THEN 'admin'
        ELSE conversation_participants.role
    END;

    -- Also remove user from any group chats they are no longer entitled to
    DELETE FROM public.conversation_participants cp2
    USING public.conversations c2
    WHERE cp2.conversation_id = c2.id
      AND c2.type = 'multi'
      AND c2.course_id IS NOT NULL
      AND cp2.user_id = p_user_id
      AND cp2.role = 'member'
      AND NOT EXISTS (
          SELECT 1 FROM public.enrollments e2
          WHERE e2.course_id = c2.course_id
            AND e2.user_id = p_user_id
            AND e2.status IN ('active', 'completed')
      )
      AND NOT EXISTS (
          SELECT 1 FROM public.courses cr2
          WHERE cr2.id = c2.course_id
            AND cr2.instructor_id = p_user_id
      );

    RETURN QUERY
    SELECT
        c.id AS conversation_id,
        c.type AS conversation_type,
        c.title AS conversation_title,
        c.course_id,
        c.created_at,
        lm.id AS last_message_id,
        lm.message_text AS last_message_text,
        lm.user_id AS last_message_user_id,
        p_sender.name AS last_message_user_name,
        lm.created_at AS last_message_created_at,
        (SELECT COUNT(*) FROM public.conversation_participants cp2 WHERE cp2.conversation_id = c.id) AS participants_count,
        CASE WHEN c.type = 'single' THEN (
            SELECT p_other.name FROM public.conversation_participants cp_other
            JOIN public.profiles p_other ON p_other.id = cp_other.user_id
            WHERE cp_other.conversation_id = c.id AND cp_other.user_id <> p_user_id
            LIMIT 1
        ) ELSE NULL END AS other_user_name,
        CASE WHEN c.type = 'single' THEN (
            SELECT p_other.avatar_url FROM public.conversation_participants cp_other
            JOIN public.profiles p_other ON p_other.id = cp_other.user_id
            WHERE cp_other.conversation_id = c.id AND cp_other.user_id <> p_user_id
            LIMIT 1
        ) ELSE NULL END AS other_user_avatar
    FROM public.conversations c
    JOIN public.conversation_participants cp ON cp.conversation_id = c.id AND cp.user_id = p_user_id
    LEFT JOIN LATERAL (
        SELECT m.id, m.message_text, m.user_id, m.created_at
        FROM public.messages m
        WHERE m.conversation_id = c.id AND m.is_deleted = FALSE
        ORDER BY m.created_at DESC
        LIMIT 1
    ) lm ON TRUE
    LEFT JOIN public.profiles p_sender ON p_sender.id = lm.user_id
    WHERE (p_type IS NULL OR c.type = p_type)
    ORDER BY COALESCE(lm.created_at, c.created_at) DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_user_conversations(UUID, TEXT) TO authenticated;

SELECT '029 - Fixed unauthorized group chat participants. Active-enrollment-only auto-join applied.' AS status;
