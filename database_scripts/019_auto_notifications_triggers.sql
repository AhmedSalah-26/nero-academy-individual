-- ============================================================
-- 019_auto_notifications_triggers.sql
-- Auto-notifications when a new course is published or new lesson added
-- ============================================================

-- ============================================================
-- 1. TRIGGER: Notify all students when a course is published
-- ============================================================

CREATE OR REPLACE FUNCTION notify_students_on_new_course()
RETURNS TRIGGER AS $$
DECLARE
  v_student RECORD;
  v_title_ar TEXT;
  v_title_en TEXT;
BEGIN
  -- Only fire when course transitions to published (is_published = true)
  IF (TG_OP = 'INSERT' AND NEW.is_published = TRUE)
  OR (TG_OP = 'UPDATE' AND NEW.is_published = TRUE AND (OLD.is_published = FALSE OR OLD.is_published IS NULL))
  THEN
    v_title_ar := COALESCE(NEW.title_ar, 'كورس جديد');
    v_title_en := COALESCE(NEW.title_en, v_title_ar);

    -- Insert a notification for every student in the platform
    FOR v_student IN
      SELECT id FROM profiles WHERE role = 'student' AND is_active = TRUE
    LOOP
      INSERT INTO notifications (
        user_id,
        title_ar,
        title_en,
        body_ar,
        body_en,
        type,
        data,
        is_read,
        created_at
      ) VALUES (
        v_student.id,
        'كورس جديد متاح! 🎉',
        'New Course Available! 🎉',
        'تم إضافة كورس جديد: ' || v_title_ar || ' — اشترك الآن!',
        'A new course is now available: ' || v_title_en || ' — Enroll now!',
        'course_update',
        jsonb_build_object('course_id', NEW.id, 'action', 'new_course'),
        FALSE,
        NOW()
      );
    END LOOP;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

DROP TRIGGER IF EXISTS trigger_notify_students_new_course ON courses;
CREATE TRIGGER trigger_notify_students_new_course
AFTER INSERT OR UPDATE OF is_published ON courses
FOR EACH ROW
EXECUTE FUNCTION notify_students_on_new_course();

-- ============================================================
-- 2. TRIGGER: Notify enrolled students when a new lesson is published
-- ============================================================

CREATE OR REPLACE FUNCTION notify_students_on_new_lesson()
RETURNS TRIGGER AS $$
DECLARE
  v_student RECORD;
  v_lesson_title_ar TEXT;
  v_lesson_title_en TEXT;
  v_course_title_ar TEXT;
  v_course_title_en TEXT;
BEGIN
  -- Only fire when lesson is published (newly inserted and published, or toggled to published)
  IF (TG_OP = 'INSERT' AND NEW.is_published = TRUE)
  OR (TG_OP = 'UPDATE' AND NEW.is_published = TRUE AND (OLD.is_published = FALSE OR OLD.is_published IS NULL))
  THEN
    v_lesson_title_ar := COALESCE(NEW.title_ar, 'درس جديد');
    v_lesson_title_en := COALESCE(NEW.title_en, v_lesson_title_ar);

    -- Get the course title
    SELECT title_ar, COALESCE(title_en, title_ar)
    INTO v_course_title_ar, v_course_title_en
    FROM courses WHERE id = NEW.course_id;

    -- Notify all students enrolled in this course (active enrollments only)
    FOR v_student IN
      SELECT DISTINCT e.user_id
      FROM enrollments e
      WHERE e.course_id = NEW.course_id
        AND e.status = 'active'
    LOOP
      INSERT INTO notifications (
        user_id,
        title_ar,
        title_en,
        body_ar,
        body_en,
        type,
        data,
        is_read,
        created_at
      ) VALUES (
        v_student.user_id,
        'درس جديد تم إضافته! 📚',
        'New Lesson Added! 📚',
        'تمت إضافة درس جديد: ' || v_lesson_title_ar || ' — في كورس: ' || COALESCE(v_course_title_ar, ''),
        'New lesson added: ' || v_lesson_title_en || ' — in course: ' || COALESCE(v_course_title_en, ''),
        'new_lesson',
        jsonb_build_object(
          'course_id', NEW.course_id,
          'lesson_id', NEW.id,
          'action', 'new_lesson'
        ),
        FALSE,
        NOW()
      );
    END LOOP;

    -- Also notify the instructor (so they know it was published successfully)
    INSERT INTO notifications (
      user_id,
      title_ar,
      title_en,
      body_ar,
      body_en,
      type,
      data,
      is_read,
      created_at
    )
    SELECT
      c.instructor_id,
      'تم نشر الدرس بنجاح ✅',
      'Lesson Published Successfully ✅',
      'تم نشر الدرس: ' || v_lesson_title_ar || ' في كورس: ' || COALESCE(v_course_title_ar, ''),
      'Lesson published: ' || v_lesson_title_en || ' in course: ' || COALESCE(v_course_title_en, ''),
      'new_lesson',
      jsonb_build_object(
        'course_id', NEW.course_id,
        'lesson_id', NEW.id,
        'action', 'lesson_published'
      ),
      FALSE,
      NOW()
    FROM courses c WHERE c.id = NEW.course_id;

  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

DROP TRIGGER IF EXISTS trigger_notify_students_new_lesson ON lessons;
CREATE TRIGGER trigger_notify_students_new_lesson
AFTER INSERT OR UPDATE OF is_published ON lessons
FOR EACH ROW
EXECUTE FUNCTION notify_students_on_new_lesson();

-- Grant access
GRANT EXECUTE ON FUNCTION notify_students_on_new_course() TO authenticated;
GRANT EXECUTE ON FUNCTION notify_students_on_new_lesson() TO authenticated;

SELECT '019 - Auto-notification triggers for courses and lessons created successfully!' AS status;
