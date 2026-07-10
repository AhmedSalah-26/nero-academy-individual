'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { Star, Send, Person, Flag } from '@mui/icons-material';
import { supabase } from '../lib/supabaseClient';
import { useApp } from '../context/AppContext';
import styles from './ReviewsSection.module.css';

interface Review {
  id: string;
  user_id: string;
  rating: number;
  review: string;
  created_at: string;
  profiles?: { name?: string; avatar_url?: string };
}

interface ReviewsSectionProps {
  courseId: string;
  isEnrolled: boolean;
}

export function ReviewsSection({ courseId, isEnrolled }: ReviewsSectionProps) {
  const { lang, user } = useApp();
  const [reviews, setReviews] = useState<Review[]>([]);
  const [averageRating, setAverageRating] = useState(0);
  const [loading, setLoading] = useState(true);
  const [rating, setRating] = useState(0);
  const [reviewText, setReviewText] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [message, setMessage] = useState('');

  useEffect(() => {
    async function loadReviews() {
      const { data, error } = await supabase
        .from('course_reviews')
        .select('id, user_id, rating, review, created_at, profiles(name, avatar_url)')
        .eq('course_id', courseId)
        .eq('is_visible', true)
        .order('created_at', { ascending: false });

      if (!error && data) {
        const mapped = data as unknown as Review[];
        setReviews(mapped);
        const avg =
          mapped.length > 0
            ? mapped.reduce((sum, r) => sum + r.rating, 0) / mapped.length
            : 0;
        setAverageRating(Number(avg.toFixed(1)));
      }
      setLoading(false);
    }

    loadReviews();
  }, [courseId]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user || rating === 0) return;

    setSubmitting(true);
    setMessage('');

    try {
      const { error } = await supabase.from('course_reviews').upsert(
        {
          course_id: courseId,
          user_id: user.id,
          rating,
          review: reviewText.trim(),
          is_visible: true,
          updated_at: new Date().toISOString(),
        },
        { onConflict: 'course_id,user_id' }
      );

      if (error) throw error;

      setMessage(lang === 'ar' ? 'تم إرسال التقييم بنجاح' : 'Review submitted successfully');
      setReviewText('');
      setRating(0);

      // Reload reviews
      const { data } = await supabase
        .from('course_reviews')
        .select('id, user_id, rating, review, created_at, profiles(name, avatar_url)')
        .eq('course_id', courseId)
        .eq('is_visible', true)
        .order('created_at', { ascending: false });

      if (data) {
        const mapped = data as unknown as Review[];
        setReviews(mapped);
        const avg = mapped.reduce((sum, r) => sum + r.rating, 0) / mapped.length;
        setAverageRating(Number(avg.toFixed(1)));
      }
    } catch (err: unknown) {
      const text = err instanceof Error ? err.message : lang === 'ar' ? 'حدث خطأ' : 'An error occurred';
      setMessage(text);
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) {
    return <div className={styles.loading}>{lang === 'ar' ? 'جاري التحميل...' : 'Loading...'}</div>;
  }

  return (
    <div className={styles.reviewsSection}>
      <div className={styles.header}>
        <h2 className={styles.title}>
          {lang === 'ar' ? 'تقييمات الطلاب' : 'Student Reviews'}
        </h2>
        {reviews.length > 0 && (
          <div className={styles.average}>
            <Star fontSize="small" fill="currentColor" />
            <strong>{averageRating}</strong>
            <span>({reviews.length})</span>
          </div>
        )}
      </div>

      {isEnrolled && (
        <form onSubmit={handleSubmit} className={`${styles.form} glass`}>
          <h3>{lang === 'ar' ? 'أضف تقييمك' : 'Write a review'}</h3>
          <div className={styles.starsInput}>
            {[1, 2, 3, 4, 5].map((star) => (
              <button
                key={star}
                type="button"
                onClick={() => setRating(star)}
                className={styles.starBtn}
                aria-label={`${star} stars`}
              >
                <Star
                  fontSize="large"
                  fill={star <= rating ? 'currentColor' : 'none'}
                  className={star <= rating ? styles.filledStar : styles.emptyStar}
                />
              </button>
            ))}
          </div>
          <textarea
            value={reviewText}
            onChange={(e) => setReviewText(e.target.value)}
            placeholder={lang === 'ar' ? 'اكتب رأيك في الكورس...' : 'Share your experience with this course...'}
            className={styles.textarea}
            rows={4}
          />
          {message && <div className={styles.message}>{message}</div>}
          <button
            type="submit"
            disabled={rating === 0 || submitting}
            className={`${styles.submitBtn} gradient-bg`}
          >
            <Send fontSize="small" />
            {lang === 'ar' ? 'إرسال التقييم' : 'Submit Review'}
          </button>
        </form>
      )}

      <div className={styles.list}>
        {reviews.length === 0 ? (
          <div className={styles.empty}>
            {lang === 'ar' ? 'لا توجد تقييمات بعد' : 'No reviews yet'}
          </div>
        ) : (
          reviews.map((review) => (
            <article key={review.id} className={`${styles.reviewCard} glass`}>
              <div className={styles.reviewHeader}>
                <div className={styles.author}>
                  {review.profiles?.avatar_url ? (
                    <img src={review.profiles.avatar_url} alt="" className={styles.avatar} />
                  ) : (
                    <div className={styles.avatarPlaceholder}>
                      <Person fontSize="small" />
                    </div>
                  )}
                  <span>{review.profiles?.name || (lang === 'ar' ? 'طالب' : 'Student')}</span>
                </div>
                <div className={styles.rating}>
                  {Array.from({ length: 5 }).map((_, i) => (
                    <Star
                      key={i}
                      fontSize="small"
                      fill={i < review.rating ? 'currentColor' : 'none'}
                      className={i < review.rating ? styles.filledStar : styles.emptyStar}
                    />
                  ))}
                </div>
              </div>
              <p className={styles.reviewText}>{review.review}</p>
              <span className={styles.date}>
                {new Date(review.created_at).toLocaleDateString(lang === 'ar' ? 'ar-EG' : 'en-US')}
              </span>
              {user?.id !== review.user_id && (
                <Link
                  href={`/report?target=review&id=${review.id}&returnTo=${encodeURIComponent(`/courses/${courseId}`)}`}
                  className={styles.reportLink}
                >
                  <Flag fontSize="small" />
                  <span>{lang === 'ar' ? 'إبلاغ' : 'Report'}</span>
                </Link>
              )}
            </article>
          ))
        )}
      </div>
    </div>
  );
}
