'use client';

import { Suspense, useEffect, useMemo, useState } from 'react';
import Link from 'next/link';
import { useRouter, useSearchParams } from 'next/navigation';
import {
  ArrowForward,
  Block,
  CheckCircle,
  Copyright,
  ErrorOutlined,
  Flag,
  InfoOutlined,
  MarkEmailUnread,
  MoreHoriz,
  ReportGmailerrorred,
  Star,
} from '@mui/icons-material';
import AppBackButton from '../../components/ui/AppBackButton';
import AppButton from '../../components/ui/AppButton';
import { useApp } from '../../context/AppContext';
import { supabase } from '../../lib/supabaseClient';
import {
  hasPendingReport,
  reportReasons,
  submitCourseReport,
  submitReviewReport,
  type ReportReason,
  type ReportTargetType,
} from '../../lib/reports';
import styles from './page.module.css';

interface CourseSummary {
  id: string;
  title_ar: string;
  title_en: string;
  thumbnail_url?: string | null;
}

interface ReviewSummary {
  id: string;
  course_id: string;
  user_id: string;
  rating: number;
  review: string | null;
  profiles?: { name?: string | null; avatar_url?: string | null } | null;
  courses?: { title_ar?: string | null; title_en?: string | null } | null;
}

type TargetSummary =
  | { type: 'course'; course: CourseSummary }
  | { type: 'review'; review: ReviewSummary };

const reasonIcons: Record<ReportReason, React.ReactNode> = {
  inappropriate: <Block fontSize="small" />,
  spam: <MarkEmailUnread fontSize="small" />,
  misleading: <InfoOutlined fontSize="small" />,
  copyright: <Copyright fontSize="small" />,
  harassment: <ReportGmailerrorred fontSize="small" />,
  other: <MoreHoriz fontSize="small" />,
};

function normalizeTarget(value: string | null): ReportTargetType | null {
  return value === 'course' || value === 'review' ? value : null;
}

function ReportPageContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { lang, user, loading } = useApp();
  const isArabic = lang === 'ar';

  const targetType = normalizeTarget(searchParams.get('target'));
  const targetId = searchParams.get('id') || '';
  const returnTo = searchParams.get('returnTo') || '/';
  const hasInvalidParams = !targetType || !targetId;

  const [target, setTarget] = useState<TargetSummary | null>(null);
  const [selectedReason, setSelectedReason] = useState<ReportReason | null>(null);
  const [description, setDescription] = useState('');
  const [hasPending, setHasPending] = useState(false);
  const [isLoadingTarget, setIsLoadingTarget] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isSubmitted, setIsSubmitted] = useState(false);
  const [error, setError] = useState('');

  const pageTitle = useMemo(() => {
    if (targetType === 'course') {
      return isArabic ? 'الإبلاغ عن الكورس' : 'Report Course';
    }
    return isArabic ? 'الإبلاغ عن التعليق' : 'Report Review';
  }, [isArabic, targetType]);

  useEffect(() => {
    if (loading) return;
    if (!user) return;
    if (hasInvalidParams) return;

    let cancelled = false;

    async function loadTarget() {
      setIsLoadingTarget(true);
      setError('');

      try {
        const pending = await hasPendingReport(targetType!, targetId, user!.id);
        if (!cancelled) {
          setHasPending(pending);
        }

        if (targetType === 'course') {
          const { data, error: courseError } = await supabase
            .from('courses')
            .select('id, title_ar, title_en, thumbnail_url')
            .eq('id', targetId)
            .maybeSingle();

          if (courseError) throw courseError;
          if (!data) throw new Error('Course not found');

          if (!cancelled) {
            setTarget({ type: 'course', course: data as CourseSummary });
          }
        } else {
          const { data, error: reviewError } = await supabase
            .from('course_reviews')
            .select('id, course_id, user_id, rating, review, profiles(name, avatar_url), courses(title_ar, title_en)')
            .eq('id', targetId)
            .maybeSingle();

          if (reviewError) throw reviewError;
          if (!data) throw new Error('Review not found');

          if (!cancelled) {
            setTarget({ type: 'review', review: data as unknown as ReviewSummary });
          }
        }
      } catch (err) {
        const fallback = isArabic
          ? 'تعذر تحميل بيانات البلاغ'
          : 'Could not load report details';
        if (!cancelled) {
          setError(err instanceof Error ? err.message : fallback);
        }
      } finally {
        if (!cancelled) {
          setIsLoadingTarget(false);
        }
      }
    }

    void loadTarget();

    return () => {
      cancelled = true;
    };
  }, [hasInvalidParams, isArabic, loading, targetId, targetType, user]);

  const handleSubmit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();

    if (!user || !targetType || !targetId || !selectedReason || hasPending || isSubmitting) {
      return;
    }

    setIsSubmitting(true);
    setError('');

    try {
      if (targetType === 'course') {
        await submitCourseReport({
          courseId: targetId,
          userId: user.id,
          reason: selectedReason,
          description: description.trim(),
        });
      } else if (target?.type === 'review') {
        await submitReviewReport({
          reviewId: targetId,
          userId: user.id,
          reason: selectedReason,
          description: description.trim(),
          reviewerId: target.review.user_id,
          reviewComment: target.review.review,
          reviewRating: target.review.rating,
        });
      }

      setIsSubmitted(true);
      setHasPending(true);
    } catch (err) {
      const message = err instanceof Error ? err.message : '';
      setError(
        message ||
          (isArabic ? 'حدث خطأ أثناء إرسال البلاغ' : 'Failed to submit report')
      );
    } finally {
      setIsSubmitting(false);
    }
  };

  if (!loading && !user) {
    return null;
  }

  const targetName =
    target?.type === 'course'
      ? isArabic
        ? target.course.title_ar
        : target.course.title_en || target.course.title_ar
      : target?.type === 'review'
      ? target.review.courses
        ? isArabic
          ? target.review.courses.title_ar || target.review.courses.title_en
          : target.review.courses.title_en || target.review.courses.title_ar
        : ''
      : '';

  return (
    <main className={styles.page}>
      <AppBackButton label={isArabic ? 'رجوع' : 'Back'} />

      <section className={`${styles.panel} glass`}>
        <div className={styles.hero}>
          <span className={styles.heroIcon}>
            <Flag fontSize="small" />
          </span>
          <div>
            <p className={styles.eyebrow}>
              {isArabic ? 'مركز البلاغات' : 'Reports Center'}
            </p>
            <h1>{pageTitle}</h1>
            <p>
              {isArabic
                ? 'اختر سبب البلاغ وأضف تفاصيل تساعدنا على مراجعته بسرعة.'
                : 'Choose a reason and add details so we can review it quickly.'}
            </p>
          </div>
        </div>

        {isLoadingTarget ? (
          <div className={styles.stateCard}>
            {isArabic ? 'جاري تحميل بيانات البلاغ...' : 'Loading report details...'}
          </div>
        ) : hasInvalidParams ? (
          <div className={`${styles.stateCard} ${styles.errorState}`}>
            <ErrorOutlined fontSize="small" />
            <span>{isArabic ? 'بيانات البلاغ غير صحيحة' : 'Invalid report data'}</span>
          </div>
        ) : error && !target ? (
          <div className={`${styles.stateCard} ${styles.errorState}`}>
            <ErrorOutlined fontSize="small" />
            <span>{error}</span>
          </div>
        ) : isSubmitted || hasPending ? (
          <div className={`${styles.stateCard} ${styles.successState}`}>
            <CheckCircle fontSize="large" />
            <h2>{isArabic ? 'لديك بلاغ معلق' : 'Pending Report'}</h2>
            <p>
              {isArabic
                ? 'تم استلام البلاغ وهو قيد المراجعة. سنرد عليك في أقرب وقت.'
                : 'Your report has been received and is under review.'}
            </p>
            <Link href={returnTo} className={styles.returnLink}>
              {isArabic ? 'العودة للمحتوى' : 'Return to content'}
              <ArrowForward fontSize="small" />
            </Link>
          </div>
        ) : (
          <form className={styles.form} onSubmit={handleSubmit}>
            <div className={styles.targetCard}>
              {target?.type === 'course' && target.course.thumbnail_url ? (
                <img src={target.course.thumbnail_url} alt="" />
              ) : (
                <span className={styles.targetIcon}>
                  {target?.type === 'review' ? <Star fontSize="small" /> : <Flag fontSize="small" />}
                </span>
              )}
              <div>
                <span>{targetType === 'course' ? pageTitle : targetName}</span>
                <strong>
                  {target?.type === 'review'
                    ? target.review.review || (isArabic ? 'تعليق بدون نص' : 'Review without text')
                    : targetName}
                </strong>
              </div>
            </div>

            <div className={styles.fieldGroup}>
              <label>{isArabic ? 'سبب البلاغ' : 'Reason for report'}</label>
              <div className={styles.reasonGrid}>
                {reportReasons.map((reason) => {
                  const active = selectedReason === reason.value;
                  return (
                    <button
                      key={reason.value}
                      type="button"
                      className={`${styles.reasonTile} ${active ? styles.reasonActive : ''}`}
                      onClick={() => setSelectedReason(reason.value)}
                    >
                      <span>{reasonIcons[reason.value]}</span>
                      <strong>{isArabic ? reason.labelAr : reason.labelEn}</strong>
                    </button>
                  );
                })}
              </div>
            </div>

            <div className={styles.fieldGroup}>
              <label htmlFor="report-description">
                {isArabic ? 'تفاصيل إضافية' : 'Additional details'}
              </label>
              <textarea
                id="report-description"
                value={description}
                onChange={(event) => setDescription(event.target.value)}
                placeholder={
                  isArabic
                    ? 'اكتب أي تفاصيل تساعد في فهم المشكلة...'
                    : 'Add any details that help us understand the issue...'
                }
                maxLength={700}
                rows={5}
              />
              <small>{description.length}/700</small>
            </div>

            {error && (
              <div className={`${styles.inlineMessage} ${styles.errorState}`}>
                <ErrorOutlined fontSize="small" />
                <span>{error}</span>
              </div>
            )}

            <div className={styles.actions}>
              <AppButton
                type="submit"
                loading={isSubmitting}
                disabled={!selectedReason || isSubmitting}
                startIcon={<Flag fontSize="small" />}
              >
                {isArabic ? 'إرسال البلاغ' : 'Submit Report'}
              </AppButton>
              <AppButton type="button" variant="secondary" onClick={() => router.push(returnTo)}>
                {isArabic ? 'إلغاء' : 'Cancel'}
              </AppButton>
            </div>
          </form>
        )}
      </section>
    </main>
  );
}

export default function ReportPage() {
  return (
    <Suspense fallback={<main className={styles.page} />}>
      <ReportPageContent />
    </Suspense>
  );
}
