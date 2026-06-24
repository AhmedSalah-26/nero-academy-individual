// Supabase Edge Function: notify-admin-enrollment
// Triggered when a new parent_enrollments row is created.
// Sends the purchase request notification to the course instructor(s), not admins.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const ONESIGNAL_APP_ID = Deno.env.get('ONESIGNAL_APP_ID') ?? ''
const ONESIGNAL_REST_API_KEY = Deno.env.get('ONESIGNAL_REST_API_KEY') ?? ''
const wait = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms))

type EnrollmentItem = {
  course_id: string
  instructor_id?: string | null
  courses?:
    | {
        title_ar?: string | null
        title_en?: string | null
        instructor_id?: string | null
      }
    | Array<{
        title_ar?: string | null
        title_en?: string | null
        instructor_id?: string | null
      }>
    | null
}

serve(async (req) => {
  try {
    const payload = await req.json()
    const enrollment = payload.record

    if (!enrollment) {
      return new Response(JSON.stringify({ error: 'No record in payload' }), {
        status: 400,
      })
    }

    const userId = enrollment.user_id
    const totalAmount = enrollment.total ?? 0
    const paymentMethod = enrollment.payment_method ?? 'card'
    const enrollmentId = enrollment.id

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { autoRefreshToken: false, persistSession: false } },
    )

    const { data: profile } = await supabaseAdmin
      .from('profiles')
      .select('name, full_name')
      .eq('id', userId)
      .single()

    let enrollmentItems: EnrollmentItem[] = []
    let enrollmentItemsError: unknown = null

    for (let attempt = 0; attempt < 6; attempt++) {
      const { data, error } = await supabaseAdmin
        .from('enrollments')
        .select(
          `
          course_id,
          instructor_id,
          courses:course_id (
            title_ar,
            title_en,
            instructor_id
          )
        `,
        )
        .eq('parent_enrollment_id', enrollmentId)

      enrollmentItems = (data ?? []) as EnrollmentItem[]
      enrollmentItemsError = error

      if (enrollmentItemsError || enrollmentItems.length > 0) {
        break
      }

      await wait(500)
    }

    if (enrollmentItemsError) {
      throw enrollmentItemsError
    }

    const getCourse = (item: EnrollmentItem) =>
      Array.isArray(item.courses) ? item.courses[0] : item.courses

    const instructorIds = [
      ...new Set(
        (enrollmentItems ?? [])
          .map((item) => item.instructor_id ?? getCourse(item)?.instructor_id)
          .filter((id): id is string => typeof id === 'string' && id.length > 0),
      ),
    ]

    if (instructorIds.length === 0) {
      return new Response(
        JSON.stringify({ success: true, notified: 0, reason: 'No instructor found' }),
        { status: 200, headers: { 'Content-Type': 'application/json' } },
      )
    }

    const studentName = profile?.name ?? profile?.full_name ?? 'طالب جديد'
    const paymentMethodText =
      paymentMethod === 'wallet'
        ? 'محفظة إلكترونية'
        : paymentMethod === 'manual'
          ? 'دفع يدوي'
          : paymentMethod === 'free'
            ? 'مجاني'
            : 'بطاقة بنكية'

    const courseTitlesAr = (enrollmentItems ?? [])
      .map((item) => getCourse(item)?.title_ar)
      .filter(Boolean)
      .join('، ')
    const courseTitlesEn = (enrollmentItems ?? [])
      .map((item) => getCourse(item)?.title_en ?? getCourse(item)?.title_ar)
      .filter(Boolean)
      .join(', ')

    const notificationTitle = {
      ar: 'طلب شراء كورس جديد',
      en: 'New Course Purchase Request',
    }
    const notificationBody = {
      ar: `${studentName} طلب شراء ${courseTitlesAr || 'كورس'} بمبلغ ${totalAmount} ج.م عبر ${paymentMethodText}`,
      en: `${studentName} requested ${courseTitlesEn || 'a course'} for ${totalAmount} EGP via ${paymentMethod}`,
    }

    const { error: notificationInsertError } = await supabaseAdmin
      .from('notifications')
      .insert(
        instructorIds.map((instructorId) => ({
          user_id: instructorId,
          type: 'system',
          title_ar: notificationTitle.ar,
          title_en: notificationTitle.en,
          body_ar: notificationBody.ar,
          body_en: notificationBody.en,
          data: {
            type: 'new_enrollment',
            enrollment_id: enrollmentId,
            student_id: userId,
            course_ids: (enrollmentItems ?? []).map((item) => item.course_id),
            navigate_to: '/instructor/manual-purchase-requests',
          },
        })),
      )

    if (notificationInsertError) {
      throw notificationInsertError
    }

    let notified = 0
    if (ONESIGNAL_APP_ID && ONESIGNAL_REST_API_KEY) {
      const oneSignalResponse = await fetch(
        'https://onesignal.com/api/v1/notifications',
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            Authorization: `Basic ${ONESIGNAL_REST_API_KEY}`,
          },
          body: JSON.stringify({
            app_id: ONESIGNAL_APP_ID,
            include_external_user_ids: instructorIds,
            channel_for_external_user_ids: 'push',
            headings: notificationTitle,
            contents: notificationBody,
            data: {
              type: 'new_enrollment',
              enrollment_id: enrollmentId,
              student_id: userId,
              navigate_to: '/instructor/manual-purchase-requests',
            },
          }),
        },
      )

      const result = await oneSignalResponse.json()
      console.log('OneSignal response:', JSON.stringify(result))
      notified = result.recipients ?? 0
    }

    return new Response(
      JSON.stringify({
        success: true,
        notified,
        instructor_ids: instructorIds,
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } },
    )
  } catch (error) {
    console.error('Error in notify-admin-enrollment:', error)
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
