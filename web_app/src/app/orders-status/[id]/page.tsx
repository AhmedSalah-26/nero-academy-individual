'use client';

import React, { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import Link from 'next/link';
import {
  CheckCircle, Schedule, Cancel, Replay, WhatsApp,
  ContentCopy, Check, ArrowForward, ArrowBack,
  ConfirmationNumber, CalendarToday, Info, PlayCircleOutlined,
} from '@mui/icons-material';
import { supabase } from '../../../lib/supabaseClient';
import { useApp } from '../../../context/AppContext';
import { AppBackButton, LoadingState, EmptyState } from '../../../components/ui';
import { usePageTransition } from '../../../lib/animations';
import styles from './page.module.css';

interface OrderCourse {
  title_ar: string;
  title_en?: string;
  price: number;
}

interface OrderEnrollment {
  id: string;
  course_id: string;
  instructor_id?: string;
  price: number;
  status: string;
  courses?: OrderCourse | null;
}

interface OrderDetail {
  id: string;
  order_number?: string;
  total: number;
  subtotal: number;
  discount: number;
  coupon_discount?: number;
  coupon_code?: string;
  payment_status: 'pending' | 'paid' | 'failed' | 'refunded' | 'cancelled' | 'pending_manual_payment';
  payment_method: string;
  paid_at?: string;
  created_at: string;
  enrollments?: OrderEnrollment[];
}

function normalizePhone(phone: string | null | undefined): string | null {
  if (!phone) return null;
  const digits = phone.replace(/[^0-9]/g, '');
  if (!digits) return null;
  if (digits.startsWith('00') && digits.length > 2) return digits.slice(2);
  return digits;
}

const statusConfig: Record<string, { icon: React.ElementType; ar: string; en: string; color: string }> = {
  paid: { icon: CheckCircle, ar: 'مدفوع', en: 'Paid', color: '#059669' },
  pending: { icon: Schedule, ar: 'معلق', en: 'Pending', color: '#D97706' },
  pending_manual_payment: { icon: Schedule, ar: 'قيد المراجعة', en: 'Under Review', color: '#D97706' },
  failed: { icon: Cancel, ar: 'فاشل', en: 'Failed', color: '#DC2626' },
  refunded: { icon: Replay, ar: 'مسترجع', en: 'Refunded', color: '#6B7280' },
  cancelled: { icon: Cancel, ar: 'ملغي', en: 'Cancelled', color: '#9CA3AF' },
};

export default function OrderDetailsPage() {
  const pageRef = usePageTransition();
  const { lang, t, user, loading: authLoading } = useApp();
  const router = useRouter();
  const params = useParams();
  const orderId = params?.id as string;

  const [order, setOrder] = useState<OrderDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [instructorPhone, setInstructorPhone] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    if (authLoading) return;
    if (!user) {
      router.push('/login?redirect=/orders-status');
      return;
    }
    const userId = user.id;
    if (!orderId) {
      setLoading(false);
      return;
    }

    let cancelled = false;

    async function fetchOrder() {
      try {
        const { data, error: fetchError } = await supabase
          .from('parent_enrollments')
          .select(`
            id, total, subtotal, discount, coupon_discount, coupon_code,
            payment_status, payment_method, paid_at, created_at,
            enrollments ( id, course_id, instructor_id, price, status, courses ( title_ar, title_en ) )
          `)
          .eq('id', orderId)
          .eq('user_id', userId)
          .single();

        if (fetchError || !data) throw fetchError || new Error('Order not found');

        const parsed = data as unknown as OrderDetail;
        if (!cancelled) setOrder(parsed);

        const firstInstructorId = parsed.enrollments?.[0]?.instructor_id;
        const firstCourseId = parsed.enrollments?.[0]?.course_id;

        let phone: string | null = null;
        if (firstInstructorId) {
          const { data: prof } = await supabase
            .from('profiles')
            .select('phone')
            .eq('id', firstInstructorId)
            .maybeSingle();
          phone = normalizePhone(prof?.phone);
        }
        if (!phone && firstCourseId) {
          const { data: course } = await supabase
            .from('courses')
            .select('instructor_id')
            .eq('id', firstCourseId)
            .maybeSingle();
          if (course?.instructor_id) {
            const { data: prof } = await supabase
              .from('profiles')
              .select('phone')
              .eq('id', course.instructor_id)
              .maybeSingle();
            phone = normalizePhone(prof?.phone);
          }
        }
        if (!phone) {
          const { data: fallback } = await supabase
            .from('profiles')
            .select('phone')
            .in('role', ['admin', 'instructor'])
            .not('phone', 'is', null)
            .limit(1)
            .maybeSingle();
          phone = normalizePhone(fallback?.phone);
        }
        if (!cancelled) setInstructorPhone(phone);
      } catch (err: unknown) {
        if (!cancelled) setError(err instanceof Error ? err.message : 'Unknown error');
      } finally {
        if (!cancelled) setLoading(false);
      }
    }

    fetchOrder();
    return () => { cancelled = true; };
  }, [authLoading, orderId, router, user]);

  const handleCopy = async (value: string) => {
    try {
      await navigator.clipboard.writeText(value);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {}
  };

  const handleWhatsApp = () => {
    if (!instructorPhone || !order) return;
    const shortId = order.order_number || (order.id.length <= 8 ? order.id.toUpperCase() : order.id.substring(0, 8).toUpperCase());
    const text = encodeURIComponent(t.whatsappMessage.replace('{orderId}', shortId));
    window.open(`https://wa.me/${instructorPhone}?text=${text}`, '_blank', 'noopener,noreferrer');
  };

  if (authLoading || loading) {
    return (
      <main className={styles.page}>
        <LoadingState />
      </main>
    );
  }

  if (error || !order) {
    return (
      <main className={styles.page}>
        <div className={styles.header}>
          <AppBackButton />
          <h1>{t.orderDetails}</h1>
        </div>
        <EmptyState
          type="generic"
          title={lang === 'ar' ? 'تعذر تحميل التفاصيل' : 'Could not load details'}
          message={error || undefined}
        />
      </main>
    );
  }

  const cfg = statusConfig[order.payment_status] || statusConfig.pending;
  const StatusIcon = cfg.icon;
  const courses = order.enrollments || [];
  const shortOrderId = order.order_number || (order.id.length <= 8 ? order.id.toUpperCase() : order.id.substring(0, 8).toUpperCase());
  const isPending = order.payment_status === 'pending' || order.payment_status === 'pending_manual_payment';

  return (
    <main ref={pageRef} className={styles.page}>
      <div className={styles.header}>
        <AppBackButton />
        <h1>{t.orderDetails}</h1>
      </div>

      <div className={styles.card}>
        <div className={styles.statusRow}>
          <span className={styles.statusChip} style={{ background: `${cfg.color}18`, color: cfg.color }}>
            <StatusIcon fontSize="small" />
            {lang === 'ar' ? cfg.ar : cfg.en}
          </span>
        </div>

        <div className={styles.infoList}>
          <div className={styles.infoTile}>
            <ConfirmationNumber fontSize="small" />
            <div>
              <span>{t.orderId}</span>
              <strong>{shortOrderId}</strong>
            </div>
            <button className={styles.copyBtn} onClick={() => handleCopy(order.order_number || order.id)} aria-label="Copy">
              {copied ? <Check fontSize="small" /> : <ContentCopy fontSize="small" />}
            </button>
          </div>

          <div className={styles.infoTile}>
            <CalendarToday fontSize="small" />
            <div>
              <span>{lang === 'ar' ? 'التاريخ' : 'Date'}</span>
              <strong>{new Date(order.created_at).toLocaleDateString(lang === 'ar' ? 'ar-EG' : 'en-US')}</strong>
            </div>
          </div>

          <div className={styles.infoTile}>
            <Info fontSize="small" />
            <div>
              <span>{t.paymentMethod}</span>
              <strong>{order.payment_method}</strong>
            </div>
          </div>

          {isPending && (
            <div className={styles.infoTile}>
              <WhatsApp fontSize="small" />
              <div>
                <span>{t.instructorWhatsapp}</span>
                <strong>{instructorPhone ? `+${instructorPhone}` : t.noPhoneAvailable}</strong>
              </div>
            </div>
          )}
        </div>

        <h2 className={styles.sectionTitle}>{t.coursesList}</h2>
        <div className={styles.coursesList}>
          {courses.map((enr) => {
            const courseTitle = lang === 'ar'
              ? enr.courses?.title_ar
              : (enr.courses?.title_en || enr.courses?.title_ar);
            return (
              <div key={enr.id} className={styles.courseRow}>
                <PlayCircleOutlined fontSize="small" />
                <span>{courseTitle}</span>
                <strong>{enr.price.toFixed(2)} {lang === 'ar' ? 'ج.م' : 'EGP'}</strong>
              </div>
            );
          })}
        </div>

        <div className={styles.priceBreakdown}>
          <div className={styles.priceRow}>
            <span>{lang === 'ar' ? 'المجموع الفرعي' : 'Subtotal'}</span>
            <span>{order.subtotal.toFixed(2)} {lang === 'ar' ? 'ج.م' : 'EGP'}</span>
          </div>
          {order.discount > 0 && (
            <div className={styles.priceRow}>
              <span>{lang === 'ar' ? 'الخصم' : 'Discount'}</span>
              <span style={{ color: 'var(--success)' }}>-{order.discount.toFixed(2)} {lang === 'ar' ? 'ج.م' : 'EGP'}</span>
            </div>
          )}
          {(order.coupon_discount || 0) > 0 && (
            <div className={styles.priceRow}>
              <span>{lang === 'ar' ? 'كوبون' : 'Coupon'} {order.coupon_code ? `(${order.coupon_code})` : ''}</span>
              <span style={{ color: 'var(--success)' }}>-{order.coupon_discount!.toFixed(2)} {lang === 'ar' ? 'ج.م' : 'EGP'}</span>
            </div>
          )}
          <div className={`${styles.priceRow} ${styles.totalRow}`}>
            <span>{t.total}</span>
            <strong>{order.total.toFixed(2)} {lang === 'ar' ? 'ج.م' : 'EGP'}</strong>
          </div>
        </div>

        {isPending && (
          <button
            onClick={handleWhatsApp}
            disabled={!instructorPhone}
            className={styles.whatsappBtn}
            type="button"
          >
            <WhatsApp fontSize="small" />
            <span>{t.contactWhatsapp}</span>
          </button>
        )}

        <Link href="/orders-status" className={`${styles.backBtn} gradient-bg`}>
          {lang === 'ar' ? <ArrowBack fontSize="small" /> : <ArrowForward fontSize="small" />}
          <span>{t.viewOrders}</span>
        </Link>
      </div>
    </main>
  );
}
