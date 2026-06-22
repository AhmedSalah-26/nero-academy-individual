// Supabase Edge Function: notify-admin-enrollment
// يتم استدعاؤها تلقائياً عند إضافة صف جديد في جدول parent_enrollments
// عبر Supabase Database Webhook

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const ONESIGNAL_APP_ID = Deno.env.get('ONESIGNAL_APP_ID') ?? ''
const ONESIGNAL_REST_API_KEY = Deno.env.get('ONESIGNAL_REST_API_KEY') ?? ''

serve(async (req) => {
  try {
    const payload = await req.json()

    // بيانات الطلب الجديد من Supabase Webhook
    const enrollment = payload.record
    if (!enrollment) {
      return new Response(JSON.stringify({ error: 'No record in payload' }), { status: 400 })
    }

    const userId = enrollment.user_id
    const totalAmount = enrollment.total ?? 0
    const paymentMethod = enrollment.payment_method ?? 'card'
    const enrollmentId = enrollment.id

    // استخدم Supabase Admin client لجلب اسم الطالب
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { autoRefreshToken: false, persistSession: false } }
    )

    // جلب بيانات الطالب
    const { data: profile } = await supabaseAdmin
      .from('profiles')
      .select('name, full_name')
      .eq('id', userId)
      .single()

    const studentName = profile?.name ?? profile?.full_name ?? 'طالب جديد'

    // تحديد طريقة الدفع للعرض
    const paymentMethodText =
      paymentMethod === 'wallet'
        ? 'محفظة إلكترونية'
        : paymentMethod === 'manual'
        ? 'دفع يدوي'
        : 'بطاقة بنكية'

    // محتوى الإشعار بالعربي والإنجليزي
    const notificationTitle = {
      ar: '💰 طلب شراء كورس جديد',
      en: '💰 New Course Purchase Request',
    }
    const notificationBody = {
      ar: `${studentName} طلب شراء كورس بمبلغ ${totalAmount} ج.م عبر ${paymentMethodText}`,
      en: `${studentName} requested to purchase a course for ${totalAmount} EGP via ${paymentMethodText}`,
    }

    // إرسال الإشعار عبر OneSignal API
    // استهداف المستخدمين بـ tag: role = admin
    const oneSignalResponse = await fetch('https://onesignal.com/api/v1/notifications', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        Authorization: `Basic ${ONESIGNAL_REST_API_KEY}`,
      },
      body: JSON.stringify({
        app_id: ONESIGNAL_APP_ID,
        // استهداف المستخدمين الذين لديهم تاغ role = admin
        filters: [{ field: 'tag', key: 'role', relation: '=', value: 'admin' }],
        headings: notificationTitle,
        contents: notificationBody,
        // بيانات إضافية تُرسل مع الإشعار لفتح الصفحة الصحيحة
        data: {
          type: 'new_enrollment',
          enrollment_id: enrollmentId,
          student_id: userId,
          navigate_to: '/admin/enrollments',
        },
      }),
    })

    const result = await oneSignalResponse.json()
    console.log('OneSignal response:', JSON.stringify(result))

    return new Response(
      JSON.stringify({ success: true, notified: result.recipients ?? 0 }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error in notify-admin-enrollment:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
