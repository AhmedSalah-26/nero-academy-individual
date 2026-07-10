import { supabase } from './supabaseClient';

export type ReportTargetType = 'course' | 'review';

export type ReportReason =
  | 'inappropriate'
  | 'spam'
  | 'misleading'
  | 'copyright'
  | 'harassment'
  | 'other';

export interface ReportReasonOption {
  value: ReportReason;
  labelAr: string;
  labelEn: string;
}

export const reportReasons: ReportReasonOption[] = [
  { value: 'inappropriate', labelAr: 'محتوى غير لائق', labelEn: 'Inappropriate content' },
  { value: 'spam', labelAr: 'محتوى مزعج / سبام', labelEn: 'Spam' },
  { value: 'misleading', labelAr: 'معلومات مضللة', labelEn: 'Misleading information' },
  { value: 'copyright', labelAr: 'انتهاك حقوق الملكية', labelEn: 'Copyright violation' },
  { value: 'harassment', labelAr: 'تحرش أو إساءة', labelEn: 'Harassment' },
  { value: 'other', labelAr: 'أخرى', labelEn: 'Other' },
];

export async function hasPendingReport(
  targetType: ReportTargetType,
  targetId: string,
  userId: string
) {
  const table = targetType === 'course' ? 'course_reports' : 'review_reports';
  const targetColumn = targetType === 'course' ? 'course_id' : 'review_id';

  const { data, error } = await supabase
    .from(table)
    .select('id')
    .eq(targetColumn, targetId)
    .eq('user_id', userId)
    .eq('status', 'pending')
    .limit(1);

  if (error) {
    throw error;
  }

  return (data || []).length > 0;
}

export async function submitCourseReport({
  courseId,
  userId,
  reason,
  description,
}: {
  courseId: string;
  userId: string;
  reason: ReportReason;
  description?: string;
}) {
  const { error } = await supabase.from('course_reports').insert({
    course_id: courseId,
    user_id: userId,
    reason,
    description: description || null,
    status: 'pending',
  });

  if (error) {
    throw error;
  }
}

export async function submitReviewReport({
  reviewId,
  userId,
  reason,
  description,
  reviewerId,
  reviewComment,
  reviewRating,
}: {
  reviewId: string;
  userId: string;
  reason: ReportReason;
  description?: string;
  reviewerId?: string | null;
  reviewComment?: string | null;
  reviewRating?: number | null;
}) {
  const { error } = await supabase.from('review_reports').insert({
    review_id: reviewId,
    user_id: userId,
    reason,
    description: description || null,
    cached_reviewer_id: reviewerId || null,
    cached_review_comment: reviewComment || null,
    cached_review_rating: reviewRating ?? null,
    status: 'pending',
  });

  if (error) {
    throw error;
  }
}
