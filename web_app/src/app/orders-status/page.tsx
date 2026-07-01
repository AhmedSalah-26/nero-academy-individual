'use client';

import { useEffect, useState, useMemo } from 'react';
import { useRouter } from 'next/navigation';
import {
  CheckCircle, Schedule, Cancel, Replay,
  ExpandMore, CalendarToday, Close, PlayCircleOutlined,
  ConfirmationNumber, ContentCopy, Check
} from '@mui/icons-material';
import { supabase } from '../../lib/supabaseClient';
import { useApp } from '../../context/AppContext';
import { AppBackButton, FilterChips, ShimmerEffect, EmptyState, ResponsiveDialog } from '../../components/ui';
import { usePageTransition } from '../../lib/animations';
import styles from './page.module.css';

interface PaymentCourse {
  id: string;
  title: string;
  price: number;
  thumbnailUrl?: string;
}

interface Payment {
  id: string;
  total: number;
  subtotal: number;
  discount: number;
  coupon_code?: string;
  coupon_discount?: number;
  payment_status: 'pending' | 'paid' | 'failed' | 'refunded' | 'cancelled' | 'pending_manual_payment';
  payment_method: string;
  paid_at?: string;
  created_at: string;
  order_number?: string;
  transaction_id?: string;
  courses: PaymentCourse[];
}

const statusConfig: Record<string, { icon: React.ElementType; ar: string; en: string; color: string }> = {
  paid: { icon: CheckCircle, ar: 'مدفوع', en: 'Paid', color: '#059669' },
  pending: { icon: Schedule, ar: 'معلق', en: 'Pending', color: '#D97706' },
  pending_manual_payment: { icon: Schedule, ar: 'قيد المراجعة', en: 'Under Review', color: '#D97706' },
  failed: { icon: Cancel, ar: 'فاشل', en: 'Failed', color: '#DC2626' },
  refunded: { icon: Replay, ar: 'مسترجع', en: 'Refunded', color: '#6B7280' },
  cancelled: { icon: Cancel, ar: 'ملغي', en: 'Cancelled', color: '#9CA3AF' },
};

const methodConfig: Record<string, { ar: string; en: string }> = {
  card: { ar: 'بطاقة ائتمان', en: 'Credit Card' },
  wallet: { ar: 'محفظة إلكترونية', en: 'Mobile Wallet' },
  manual: { ar: 'دفع يدوي', en: 'Manual Payment' },
  free: { ar: 'مجاني', en: 'Free' },
  cash: { ar: 'نقدي', en: 'Cash' },
};

type FilterTab = 'all' | 'paid' | 'pending' | 'refunded' | 'cancelled';

export default function OrdersStatusPage() {
  const pageRef = usePageTransition();
  const { lang, user, loading: authLoading } = useApp();
  const router = useRouter();
  const [items, setItems] = useState<Payment[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<FilterTab>('all');
  const [detailPayment, setDetailPayment] = useState<Payment | null>(null);
  const [copiedId, setCopiedId] = useState<string | null>(null);

  useEffect(() => {
    if (authLoading) return;
    if (!user) {
      router.push('/login?redirect=/orders-status');
      return;
    }

    supabase.from('parent_enrollments')
      .select(`
        id, total, subtotal, discount, coupon_discount, coupon_code,
        payment_status, payment_method, paid_at, created_at, payment_transaction_id,
        enrollments (
          course_id,
          courses (
            id,
            title_ar,
            title_en,
            thumbnail_url,
            price
          )
        ),
        manual_purchase_request_items (
          course_id,
          price,
          courses (
            id,
            title_ar,
            title_en,
            thumbnail_url,
            price
          )
        )
      `)
      .eq('user_id', user.id)
      .order('created_at', { ascending: false })
      .then(({ data, error }) => {
        if (!error && data) {
          const parsedPayments = (data || []).map((item: any) => {
            const courseById: Record<string, PaymentCourse> = {};

            const addCourseFrom = (row: any, preferRowPrice = false) => {
              if (!row || !row.courses) return;
              const course = row.courses;
              const courseId = course.id || row.course_id;
              if (!courseId) return;

              const rowPrice = row.price;
              const coursePrice = course.price ?? 0;

              courseById[courseId] = {
                id: courseId,
                title: lang === 'ar' ? (course.title_ar || course.title_en || '') : (course.title_en || course.title_ar || ''),
                price: preferRowPrice ? (rowPrice ?? coursePrice) : coursePrice,
                thumbnailUrl: course.thumbnail_url,
              };
            };

            if (Array.isArray(item.enrollments)) {
              item.enrollments.forEach((e: any) => addCourseFrom(e));
            }
            if (Array.isArray(item.manual_purchase_request_items)) {
              item.manual_purchase_request_items.forEach((m: any) => addCourseFrom(m, true));
            }

            return {
              ...item,
              transaction_id: item.payment_transaction_id,
              courses: Object.values(courseById),
            } as Payment;
          });

          setItems(parsedPayments);
        }
        setLoading(false);
      });
  }, [authLoading, router, user, lang]);

  const filtered = useMemo(() => {
    if (filter === 'all') return items;
    if (filter === 'pending') {
      return items.filter((p) => p.payment_status === 'pending' || p.payment_status === 'pending_manual_payment');
    }
    return items.filter((p) => p.payment_status === filter);
  }, [items, filter]);

  const filterTabs: { id: FilterTab; label: string }[] = [
    { id: 'all', label: lang === 'ar' ? `الكل (${items.length})` : `All (${items.length})` },
    { id: 'paid', label: lang === 'ar' ? `مدفوع (${items.filter((p) => p.payment_status === 'paid').length})` : `Paid (${items.filter((p) => p.payment_status === 'paid').length})` },
    { id: 'pending', label: lang === 'ar' ? `معلق (${items.filter((p) => p.payment_status === 'pending' || p.payment_status === 'pending_manual_payment').length})` : `Pending (${items.filter((p) => p.payment_status === 'pending' || p.payment_status === 'pending_manual_payment').length})` },
    { id: 'refunded', label: lang === 'ar' ? `مسترجع (${items.filter((p) => p.payment_status === 'refunded').length})` : `Refunded (${items.filter((p) => p.payment_status === 'refunded').length})` },
    { id: 'cancelled', label: lang === 'ar' ? `ملغي (${items.filter((p) => p.payment_status === 'cancelled' || p.payment_status === 'failed').length})` : `Cancelled (${items.filter((p) => p.payment_status === 'cancelled' || p.payment_status === 'failed').length})` },
  ];

  const handleCopy = async (e: React.MouseEvent, value: string, id: string) => {
    e.stopPropagation();
    try {
      await navigator.clipboard.writeText(value);
      setCopiedId(id);
      setTimeout(() => setCopiedId(null), 2000);
    } catch {}
  };

  const getShortOrderId = (p: Payment) => {
    const rawId = p.order_number || p.id;
    return rawId.length <= 8 ? rawId.toUpperCase() : rawId.substring(0, 8).toUpperCase();
  };

  const getPaymentMethodLabel = (method: string) => {
    const cfg = methodConfig[method];
    return cfg ? (lang === 'ar' ? cfg.ar : cfg.en) : method;
  };

  if (authLoading || (!user && loading)) {
    return (
      <main className={styles.page}>
        <div className={styles.hero}>
          <div className={styles.heroText}>
            <h1>{lang === 'ar' ? 'حالة الطلبات' : 'Orders Status'}</h1>
          </div>
          <div className={styles.heroIcon}>📦</div>
        </div>
        <div className={styles.shimmerGrid}>{Array.from({ length: 4 }).map((_, i) => <ShimmerEffect key={i} height={120} />)}</div>
      </main>
    );
  }

  if (!user) return <main className={styles.page}><EmptyState type="generic" /></main>;

  return (
    <main ref={pageRef} className={styles.page}>
      {/* Hero */}
      <div className={styles.hero}>
        <div className={styles.heroText}>
          <h1>{lang === 'ar' ? 'حالة الطلبات' : 'Orders Status'}</h1>
          <p>{lang === 'ar' ? 'تتبع جميع طلباتك وحالة الدفع في مكان واحد' : 'Track all your orders and payment status in one place'}</p>
        </div>
        <div className={styles.heroIcon}>📦</div>
      </div>

      {/* Toolbar */}
      <div className={styles.toolbar}>
        <div className={styles.filterRow}>
          <FilterChips
            items={filterTabs.map((t) => ({ id: t.id, label: t.label }))}
            selected={[filter]}
            onChange={(ids) => setFilter((ids[0] || 'all') as FilterTab)}
          />
        </div>
        <span className={styles.resultsCount}>
          <strong>{filtered.length}</strong> {lang === 'ar' ? 'طلب' : 'orders'}
        </span>
      </div>

      {loading ? (
        <div className={styles.shimmerGrid}>{Array.from({ length: 4 }).map((_, i) => <ShimmerEffect key={i} height={120} />)}</div>
      ) : filtered.length === 0 ? (
        <EmptyState type="generic" title={lang === 'ar' ? 'لا توجد طلبات' : 'No orders found'} />
      ) : (
        <div className={styles.list}>
          {filtered.map((p) => {
            const cfg = statusConfig[p.payment_status] || statusConfig.pending;
            const Icon = cfg.icon;
            const shortId = getShortOrderId(p);
            return (
              <article key={p.id} className={styles.card} onClick={() => setDetailPayment(p)}>
                <div className={styles.cardHeader}>
                  <span className={styles.statusChip} style={{ background: `${cfg.color}18`, color: cfg.color }}>
                    <Icon fontSize="small" style={{ fontSize: 14 }} />
                    {lang === 'ar' ? cfg.ar : cfg.en}
                  </span>
                  <span className={styles.dateText}>
                    {new Date(p.created_at).toLocaleDateString(lang === 'ar' ? 'ar-EG' : 'en-US', { day: 'numeric', month: 'short', year: 'numeric' })}
                  </span>
                </div>

                <div className={styles.orderNumberRow}>
                  <ConfirmationNumber className={styles.orderNumberIcon} />
                  <span className={styles.orderNumberLabel}>{lang === 'ar' ? 'رقم الطلب' : 'Order number'}</span>
                  <span className={styles.orderNumberValue}>{shortId}</span>
                  <button className={styles.copyBtn} onClick={(e) => handleCopy(e, p.order_number || p.id, p.id)}>
                    {copiedId === p.id ? <Check fontSize="small" style={{ color: 'var(--success)' }} /> : <ContentCopy fontSize="small" />}
                  </button>
                </div>

                {p.courses.length > 0 && (
                  <div className={styles.coursesSection}>
                    {p.courses.map((c) => (
                      <div key={c.id} className={styles.courseItem}>
                        <PlayCircleOutlined className={styles.courseIcon} />
                        <span className={styles.courseTitle}>{c.title}</span>
                      </div>
                    ))}
                  </div>
                )}

                <div className={styles.cardFooter}>
                  <span className={styles.paymentMethod}>
                    {getPaymentMethodLabel(p.payment_method)}
                  </span>
                  <strong className={styles.totalAmount}>
                    {p.total.toFixed(2)} {lang === 'ar' ? 'ج.م' : 'EGP'}
                  </strong>
                </div>

                {p.transaction_id && (
                  <div className={styles.transactionId}>
                    {lang === 'ar' ? 'رقم المعاملة' : 'Transaction ID'}: {p.transaction_id}
                  </div>
                )}
              </article>
            );
          })}
        </div>
      )}

      {detailPayment && (
        <ResponsiveDialog
          open={!!detailPayment}
          onClose={() => setDetailPayment(null)}
          title={lang === 'ar' ? 'تفاصيل الطلب' : 'Order Details'}
          maxWidth="sm"
        >
          <div className={styles.sheetBody}>
            {(() => {
              const p = detailPayment;
              const cfg = statusConfig[p.payment_status] || statusConfig.pending;
              const StatusIcon = cfg.icon;
              const shortId = getShortOrderId(p);
              return (
                <>
                  <div className={styles.sheetDetailRow}>
                    <span className={styles.detailLabel}>{lang === 'ar' ? 'الحالة' : 'Status'}</span>
                    <span className={styles.statusChip} style={{ background: `${cfg.color}18`, color: cfg.color }}>
                      <StatusIcon fontSize="small" style={{ fontSize: 14 }} />
                      {lang === 'ar' ? cfg.ar : cfg.en}
                    </span>
                  </div>

                  <div className={styles.sheetDetailRow}>
                    <span className={styles.detailLabel}>{lang === 'ar' ? 'رقم الطلب' : 'Order Number'}</span>
                    <div className={styles.detailValueWithCopy}>
                      <span className={styles.detailValue}>{shortId}</span>
                      <button className={styles.copyBtn} onClick={(e) => handleCopy(e, p.order_number || p.id, `detail-${p.id}`)}>
                        {copiedId === `detail-${p.id}` ? <Check fontSize="small" style={{ color: 'var(--success)' }} /> : <ContentCopy fontSize="small" />}
                      </button>
                    </div>
                  </div>

                  <div className={styles.sheetDetailRow}>
                    <span className={styles.detailLabel}>{lang === 'ar' ? 'التاريخ' : 'Date'}</span>
                    <span className={styles.detailValue}>
                      {new Date(p.created_at).toLocaleDateString(lang === 'ar' ? 'ar-EG' : 'en-US', { day: 'numeric', month: 'long', year: 'numeric', hour: '2-digit', minute: '2-digit' })}
                    </span>
                  </div>

                  <div className={styles.sheetDetailRow}>
                    <span className={styles.detailLabel}>{lang === 'ar' ? 'طريقة الدفع' : 'Payment Method'}</span>
                    <span className={styles.detailValue}>{getPaymentMethodLabel(p.payment_method)}</span>
                  </div>

                  {p.transaction_id && (
                    <div className={styles.sheetDetailRow}>
                      <span className={styles.detailLabel}>{lang === 'ar' ? 'رقم المعاملة' : 'Transaction ID'}</span>
                      <span className={styles.detailValue}>{p.transaction_id}</span>
                    </div>
                  )}

                  {p.paid_at && (
                    <div className={styles.sheetDetailRow}>
                      <span className={styles.detailLabel}>{lang === 'ar' ? 'تاريخ الدفع' : 'Paid At'}</span>
                      <span className={styles.detailValue}>
                        {new Date(p.paid_at).toLocaleDateString(lang === 'ar' ? 'ar-EG' : 'en-US', { day: 'numeric', month: 'long', year: 'numeric', hour: '2-digit', minute: '2-digit' })}
                      </span>
                    </div>
                  )}

                  {p.courses.length > 0 && (
                    <div className={styles.sheetCoursesSection}>
                      <h3>{lang === 'ar' ? 'الكورسات' : 'Courses'}</h3>
                      <div className={styles.sheetCoursesList}>
                        {p.courses.map((c) => (
                          <div key={c.id} className={styles.sheetCourseRow}>
                            <div className={styles.sheetCourseLeft}>
                              <PlayCircleOutlined className={styles.courseIcon} />
                              <span className={styles.sheetCourseTitle}>{c.title}</span>
                            </div>
                            <span className={styles.sheetCoursePrice}>
                              {c.price > 0 ? `${c.price.toFixed(2)} ${lang === 'ar' ? 'ج.م' : 'EGP'}` : (lang === 'ar' ? 'مجاني' : 'Free')}
                            </span>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  <div className={styles.sheetPricingSection}>
                    <h3>{lang === 'ar' ? 'تفاصيل السعر' : 'Price Breakdown'}</h3>
                    <div className={styles.priceRow}>
                      <span>{lang === 'ar' ? 'المجموع الفرعي' : 'Subtotal'}</span>
                      <span>{p.subtotal.toFixed(2)} {lang === 'ar' ? 'ج.م' : 'EGP'}</span>
                    </div>

                    {p.discount > 0 && (
                      <div className={styles.priceRow}>
                        <span>{lang === 'ar' ? 'الخصم' : 'Discount'}</span>
                        <span className={styles.discountValue}>-{p.discount.toFixed(2)} {lang === 'ar' ? 'ج.م' : 'EGP'}</span>
                      </div>
                    )}

                    {p.coupon_discount && p.coupon_discount > 0 && (
                      <div className={styles.priceRow}>
                        <span>
                          {lang === 'ar' ? 'كوبون الخصم' : 'Coupon Discount'}
                          {p.coupon_code ? ` (${p.coupon_code})` : ''}
                        </span>
                        <span className={styles.discountValue}>-{p.coupon_discount.toFixed(2)} {lang === 'ar' ? 'ج.م' : 'EGP'}</span>
                      </div>
                    )}

                    <div className={`${styles.priceRow} ${styles.sheetTotalRow}`}>
                      <span>{lang === 'ar' ? 'الإجمالي' : 'Total'}</span>
                      <strong>{p.total.toFixed(2)} {lang === 'ar' ? 'ج.م' : 'EGP'}</strong>
                    </div>
                  </div>
                </>
              );
            })()}
          </div>
        </ResponsiveDialog>
      )}
    </main>
  );
}
