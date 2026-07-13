// Supabase Edge Function: notify-content-update
// Triggered by Supabase Database Webhook when:
//   - A new course is published (courses table, INSERT or UPDATE on is_published = true)
//   - A new lesson is published (lessons table, INSERT or UPDATE on is_published = true)
// Uses OneSignal to send push notifications

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const ONESIGNAL_APP_ID = Deno.env.get('ONESIGNAL_APP_ID') ?? ''
const ONESIGNAL_REST_API_KEY = Deno.env.get('ONESIGNAL_REST_API_KEY') ?? ''

const supabaseAdmin = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
  { auth: { autoRefreshToken: false, persistSession: false } }
)

// ─── Send OneSignal push to specific external_user_ids ───────────────────────
async function sendPushToUsers(
  userIds: string[],
  headings: { ar: string; en: string },
  contents: { ar: string; en: string },
  data: Record<string, string>
) {
  if (!ONESIGNAL_APP_ID || !ONESIGNAL_REST_API_KEY) {
    console.warn('OneSignal credentials missing, skipping push.')
    return
  }
  if (userIds.length === 0) return

  const body: Record<string, unknown> = {
    app_id: ONESIGNAL_APP_ID,
    include_aliases: { external_id: userIds },
    target_channel: 'push',
    headings,
    contents,
    data,
  }

  const response = await fetch('https://onesignal.com/api/v1/notifications', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      Authorization: `Basic ${ONESIGNAL_REST_API_KEY}`,
    },
    body: JSON.stringify(body),
  })

  const result = await response.json()
  console.log('OneSignal push result:', JSON.stringify(result))
}

// ─── Send OneSignal push via segment/tag (e.g. role = student) ───────────────
async function sendPushByTag(
  tagKey: string,
  tagValue: string,
  headings: { ar: string; en: string },
  contents: { ar: string; en: string },
  data: Record<string, string>
) {
  if (!ONESIGNAL_APP_ID || !ONESIGNAL_REST_API_KEY) {
    console.warn('OneSignal credentials missing, skipping push.')
    return
  }

  const body = {
    app_id: ONESIGNAL_APP_ID,
    filters: [{ field: 'tag', key: tagKey, relation: '=', value: tagValue }],
    headings,
    contents,
    data,
  }

  const response = await fetch('https://onesignal.com/api/v1/notifications', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      Authorization: `Basic ${ONESIGNAL_REST_API_KEY}`,
    },
    body: JSON.stringify(body),
  })

  const result = await response.json()
  console.log('OneSignal segment push result:', JSON.stringify(result))
}

// ─── Handle new course published ─────────────────────────────────────────────
async function handleNewCourse(record: Record<string, unknown>) {
  const courseId = record.id as string
  const titleAr = (record.title_ar as string) ?? 'كورس جديد'
  const titleEn = (record.title_en as string) ?? titleAr
  const isPublished = record.is_published as boolean

  if (!isPublished) return

  const headings = {
    ar: '🎉 كورس جديد متاح الآن!',
    en: '🎉 New Course Available!',
  }
  const contents = {
    ar: `تم إضافة كورس جديد: ${titleAr} — اشترك الآن واستفد!`,
    en: `New course now available: ${titleEn} — Enroll now!`,
  }
  const data = {
    type: 'new_course',
    course_id: courseId,
    navigate_to: `/course/${courseId}`,
  }

  // Push to all students via tag
  await sendPushByTag('role', 'student', headings, contents, data)
  console.log(`✅ Pushed new-course notification for courseId=${courseId}`)
}

// ─── Handle new lesson published ─────────────────────────────────────────────
async function handleNewLesson(record: Record<string, unknown>) {
  const lessonId = record.id as string
  const courseId = record.course_id as string
  const lessonTitleAr = (record.title_ar as string) ?? 'درس جديد'
  const lessonTitleEn = (record.title_en as string) ?? lessonTitleAr
  const isPublished = record.is_published as boolean

  if (!isPublished) return

  // Get course title
  const { data: course } = await supabaseAdmin
    .from('courses')
    .select('title_ar, title_en, teacher_id')
    .eq('id', courseId)
    .single()

  const courseTitleAr = course?.title_ar ?? ''
  const courseTitleEn = course?.title_en ?? courseTitleAr
  const teacherId = course?.teacher_id as string | undefined

  // Get all active enrolled students for this course
  const { data: enrollments } = await supabaseAdmin
    .from('enrollments')
    .select('user_id')
    .eq('course_id', courseId)
    .eq('status', 'active')

  const enrolledUserIds = (enrollments ?? []).map((e: { user_id: string }) => e.user_id)

  const headings = {
    ar: '📚 درس جديد تم إضافته!',
    en: '📚 New Lesson Added!',
  }
  const contentsStudents = {
    ar: `درس جديد: ${lessonTitleAr} — في كورس: ${courseTitleAr}`,
    en: `New lesson: ${lessonTitleEn} — in course: ${courseTitleEn}`,
  }
  const data = {
    type: 'new_lesson',
    course_id: courseId,
    lesson_id: lessonId,
    navigate_to: `/course/${courseId}`,
  }

  // Push to enrolled students
  if (enrolledUserIds.length > 0) {
    await sendPushToUsers(enrolledUserIds, headings, contentsStudents, data)
  }

  // Push confirmation to instructor
  if (teacherId) {
    const instructorHeadings = {
      ar: '✅ تم نشر الدرس بنجاح',
      en: '✅ Lesson Published Successfully',
    }
    const instructorContents = {
      ar: `تم نشر: ${lessonTitleAr} في كورس: ${courseTitleAr}`,
      en: `Published: ${lessonTitleEn} in course: ${courseTitleEn}`,
    }
    await sendPushToUsers(
      [teacherId],
      instructorHeadings,
      instructorContents,
      { ...data, type: 'lesson_published' }
    )
  }

  console.log(`✅ Pushed new-lesson notification for lessonId=${lessonId}, enrolled=${enrolledUserIds.length}`)
}

// ─── Main handler ─────────────────────────────────────────────────────────────
serve(async (req) => {
  try {
    const payload = await req.json()
    const record = payload.record as Record<string, unknown>
    const table = payload.table as string // 'courses' or 'lessons'
    const eventType = payload.type as string // INSERT or UPDATE

    if (!record) {
      return new Response(JSON.stringify({ error: 'No record in payload' }), { status: 400 })
    }

    console.log(`📨 notify-content-update triggered: table=${table}, event=${eventType}`)

    if (table === 'courses') {
      await handleNewCourse(record)
    } else if (table === 'lessons') {
      await handleNewLesson(record)
    } else {
      return new Response(JSON.stringify({ error: `Unknown table: ${table}` }), { status: 400 })
    }

    return new Response(
      JSON.stringify({ success: true }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error in notify-content-update:', error)
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
