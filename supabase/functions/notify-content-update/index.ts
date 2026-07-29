import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const ONESIGNAL_APP_ID = Deno.env.get("ONESIGNAL_APP_ID") ?? "";
const ONESIGNAL_REST_API_KEY = Deno.env.get("ONESIGNAL_REST_API_KEY") ?? "";
const ONESIGNAL_API_URL = "https://api.onesignal.com/notifications";
const MAX_EXTERNAL_IDS_PER_REQUEST = 20_000;

const supabaseAdmin = createClient(
  Deno.env.get("SUPABASE_URL") ?? "",
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
  { auth: { autoRefreshToken: false, persistSession: false } },
);

type LocalizedText = { ar: string; en: string };
type DatabaseWebhookPayload = {
  type?: string;
  table?: string;
  record?: Record<string, unknown>;
  old_record?: Record<string, unknown> | null;
};

function wasJustPublished(payload: DatabaseWebhookPayload): boolean {
  const isPublished = payload.record?.is_published === true;
  if (!isPublished) return false;

  const eventType = payload.type?.toUpperCase();
  if (eventType === "INSERT") return true;
  if (eventType === "UPDATE") {
    return payload.old_record?.is_published !== true;
  }

  return false;
}

async function sendOneSignal(body: Record<string, unknown>) {
  if (!ONESIGNAL_APP_ID || !ONESIGNAL_REST_API_KEY) {
    throw new Error("ONESIGNAL_APP_ID or ONESIGNAL_REST_API_KEY is missing");
  }

  const response = await fetch(ONESIGNAL_API_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      Authorization: `Key ${ONESIGNAL_REST_API_KEY}`,
    },
    body: JSON.stringify({ app_id: ONESIGNAL_APP_ID, ...body }),
  });

  const responseText = await response.text();
  if (!response.ok) {
    throw new Error(
      `OneSignal request failed (${response.status}): ${responseText}`,
    );
  }

  console.log(`OneSignal accepted message: ${responseText}`);
}

async function sendPushToUsers(
  userIds: string[],
  headings: LocalizedText,
  contents: LocalizedText,
  data: Record<string, string>,
) {
  const uniqueUserIds = [...new Set(userIds.filter(Boolean))];

  for (
    let offset = 0;
    offset < uniqueUserIds.length;
    offset += MAX_EXTERNAL_IDS_PER_REQUEST
  ) {
    await sendOneSignal({
      include_aliases: {
        external_id: uniqueUserIds.slice(
          offset,
          offset + MAX_EXTERNAL_IDS_PER_REQUEST,
        ),
      },
      target_channel: "push",
      headings,
      contents,
      data,
    });
  }
}

async function sendPushByTag(
  tagKey: string,
  tagValue: string,
  headings: LocalizedText,
  contents: LocalizedText,
  data: Record<string, string>,
) {
  await sendOneSignal({
    filters: [{ field: "tag", key: tagKey, relation: "=", value: tagValue }],
    target_channel: "push",
    headings,
    contents,
    data,
  });
}

async function handleNewCourse(record: Record<string, unknown>) {
  const courseId = String(record.id);
  const titleAr = String(record.title_ar ?? "كورس جديد");
  const titleEn = String(record.title_en ?? titleAr);

  await sendPushByTag(
    "role",
    "student",
    { ar: "🎉 كورس جديد متاح الآن!", en: "🎉 New Course Available!" },
    {
      ar: `تم إضافة كورس جديد: ${titleAr} — اشترك الآن واستفد!`,
      en: `New course now available: ${titleEn} — Enroll now!`,
    },
    {
      type: "new_course",
      course_id: courseId,
      navigate_to: `/course/${courseId}`,
    },
  );

  console.log(`Sent new-course push for courseId=${courseId}`);
}

async function handleNewLesson(record: Record<string, unknown>) {
  const lessonId = String(record.id);
  const courseId = String(record.course_id);
  const lessonTitleAr = String(record.title_ar ?? "درس جديد");
  const lessonTitleEn = String(record.title_en ?? lessonTitleAr);

  const { data: course, error: courseError } = await supabaseAdmin
    .from("courses")
    .select("title_ar, title_en, instructor_id, is_published, is_active")
    .eq("id", courseId)
    .single();

  if (courseError) throw courseError;

  // A lesson inside a draft/inactive course is not visible to students yet.
  if (course?.is_published !== true || course?.is_active !== true) {
    console.log(
      `Skipped lesson push because courseId=${courseId} is not published and active`,
    );
    return;
  }

  const { data: enrollments, error: enrollmentsError } = await supabaseAdmin
    .from("enrollments")
    .select("user_id")
    .eq("course_id", courseId)
    .eq("status", "active");

  if (enrollmentsError) throw enrollmentsError;

  const courseTitleAr = String(course.title_ar ?? "");
  const courseTitleEn = String(course.title_en ?? courseTitleAr);
  const enrolledUserIds = (enrollments ?? []).map(
    (enrollment: { user_id: string }) => enrollment.user_id,
  );

  await sendPushToUsers(
    enrolledUserIds,
    { ar: "📚 درس جديد تمت إضافته!", en: "📚 New Lesson Added!" },
    {
      ar: `درس جديد: ${lessonTitleAr} — في كورس: ${courseTitleAr}`,
      en: `New lesson: ${lessonTitleEn} — in course: ${courseTitleEn}`,
    },
    {
      type: "new_lesson",
      course_id: courseId,
      lesson_id: lessonId,
      navigate_to: `/course/${courseId}`,
    },
  );

  console.log(
    `Sent new-lesson push for lessonId=${lessonId}, enrolled=${enrolledUserIds.length}`,
  );
}

serve(async (request) => {
  if (request.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  try {
    const payload = (await request.json()) as DatabaseWebhookPayload;

    if (!payload.record || !payload.table) {
      return new Response(
        JSON.stringify({ error: "Invalid database webhook payload" }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    if (!wasJustPublished(payload)) {
      return new Response(
        JSON.stringify({ success: true, skipped: "not_newly_published" }),
        {
          status: 200,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    if (payload.table === "courses") {
      await handleNewCourse(payload.record);
    } else if (payload.table === "lessons") {
      await handleNewLesson(payload.record);
    } else {
      return new Response(
        JSON.stringify({ error: `Unknown table: ${payload.table}` }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("notify-content-update failed:", error);
    return new Response(JSON.stringify({ error: (error as Error).message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
