'use client';

import { useEffect, useState, useMemo } from 'react';
import {
  CreditCard, CheckCircle, Schedule, Cancel, Replay,
  ExpandMore, Close, Receipt, CalendarToday,
} from '@mui/icons-material';
import { supabase } from '../../lib/supabaseClient';
import { useApp } from '../../context/AppContext';
import { AppBackButton, FilterChips, ShimmerEffect, EmptyState, PriceTag } from '../../components/ui';
import { usePageTransition } from '../../lib/animations';
import styles from './page.module.css';

interface Payment {
  id: string;
  total: number;
  subtotal: number;
  discount: number;
  payment_status: 'pending' | 'paid' | 'failed' | 'refunded' | 'cancelled';
  payment_method: string;
  paid_at?: string;
  created_at: string;
  order_number?: string;
  courses?: { title_ar: string; title_en?: string }[];
}

const statusConfig: Record<string, { icon: React.ElementType; ar: string; en: string; color: string }> = {
  paid: { icon: CheckCircle, ar: 'مدفوع', en: 'Paid', color: '#059669' },
  pending: { icon: Schedule, ar: 'معلق', en: 'Pending', color: '#D97706' },
  failed: { icon: Cancel, ar: 'فاشل', en: 'Failed', color: '#DC2626' },
  refunded: { icon: Replay, ar: 'مسترجع', en: 'Refunded', color: '#6B7280' },
  cancelled: { icon: Cancel, ar: 'ملغي', en: 'Cancelled', color: '#9CA3AF' },
};

type FilterTab = 'all' | 'paid' | 'pending' | 'refunded' | 'cancelled';

export default function PaymentsPage() {
  const pageRef = usePageTransition();
  const { lang, user } = useApp();
  const [items, setItems] = useState<Payment[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<FilterTab>('all');
  const [detailPayment, setDetailPayment] = useState<Payment | null>(null);

  useEffect(() => {
    if (!user) return;
    supabase.from('parent_enrollments').select('id, total, subtotal, discount, payment_status, payment_method, paid_at, created_at, order_number')
      .eq('user_id', user.id).order('created_at', { ascending: false })
      .then(({ data, error }) => { if (!error) setItems((data || []) as Payment[]); setLoading(false); });
  }, [user]);

  const filtered = useMemo(() => {
    if (filter === 'all') return items;
    return items.filter((p) => p.payment_status === filter);
  }, [items, filter]);

  const filterTabs: { id: FilterTab; label: string }[] = [
    { id: 'all', label: lang === 'ar' ? `الكل (${items.length})` : `All (${items.length})` },
    { id: 'paid', label: lang === 'ar' ? `مدفوع (${items.filter((p) => p.payment_status === 'paid').length})` : `Paid (${items.filter((p) => p.payment_status === 'paid').length})` },
    { id: 'pending', label: lang === 'ar' ? `معلق (${items.filter((p) => p.payment_status === 'pending').length})` : `Pending (${items.filter((p) => p.payment_status === 'pending').length})` },
    { id: 'refunded', label: lang === 'ar' ? `مسترجع (${items.filter((p) => p.payment_status === 'refunded').length})` : `Refunded (${items.filter((p) => p.payment_status === 'refunded').length})` },
    { id: 'cancelled', label: lang === 'ar' ? `ملغي (${items.filter((p) => p.payment_status === 'cancelled').length})` : `Cancelled (${items.filter((p) => p.payment_status === 'cancelled').length})` },
  ];

  if (!user) return <main className={styles.page}><EmptyState type="generic" /></main>;

  return (
    <main ref={pageRef} className={styles.page}>
      <div className={styles.header}>
        <AppBackButton />
        <h1>{lang === 'ar' ? 'سجل المدفوعات' : 'Payment History'}</h1>
      </div>

      <div className={styles.filterRow}>
        <FilterChips
          items={filterTabs.map((t) => ({ id: t.id, label: t.label }))}
          selected={[filter]}
          onChange={(ids) => setFilter((ids[0] || 'all') as FilterTab)}
        />
      </div>

      {loading ? (
        <div className={styles.shimmerGrid}>{Array.from({ length: 4 }).map((_, i) => <ShimmerEffect key={i} height={80} />)}</div>
      ) : filtered.length === 0 ? (
        <EmptyState type="generic" title={lang === 'ar' ? 'لا توجد مدفوعات' : 'No payments found'} />
      ) : (
        <div className={styles.list}>
          {filtered.map((p) => {
            const cfg = statusConfig[p.payment_status] || statusConfig.pending;
            const Icon = cfg.icon;
            return (
              <article key={p.id} className={styles.card} onClick={() => setDetailPayment(p)}>
                <div className={styles.iconWrap} style={{ background: `${cfg.color}18`, color: cfg.color }}>
                  <Icon fontSize="small" />
                </div>
                <div className={styles.cardBody}>
                  <div className={styles.titleRow}>
                    <h3>{p.total.toFixed(2)} {lang === 'ar' ? 'ج.م' : 'EGP'}</h3>
                    <span className={styles.statusChip} style={{ background: `${cfg.color}18`, color: cfg.color }}>
                      {lang === 'ar' ? cfg.ar : cfg.en}
                    </span>
                  </div>
                  {p.order_number && <p className={styles.orderNumber}>#{p.order_number}</p>}
                  <div className={styles.meta}>
                    <CalendarToday fontSize="small" />
                    <span>{new Date(p.created_at).toLocaleDateString(lang === 'ar' ? 'ar-EG' : 'en-US')}</span>
                  </div>
                </div>
                <ExpandMore className={styles.expandIcon} />
              </article>
            );
          })}
        </div>
      )}

      {detailPayment && (
        <div className={styles.sheetOverlay} onClick={() => setDetailPayment(null)}>
          <div className={styles.sheet} onClick={(e) => e.stopPropagation()}>
            <div className={styles.sheetHeader}>
              <h2>{lang === 'ar' ? 'تفاصيل الدفعة' : 'Payment Details'}</h2>
              <button onClick={() => setDetailPayment(null)} className={styles.sheetClose}><Close fontSize="small" /></button>
            </div>
            <div className={styles.sheetBody}>
              {(() => {
                const p = detailPayment;
                const cfg = statusConfig[p.payment_status] || statusConfig.pending;
                return (
                  <>
                    <div className={styles.sheetRow}><span>{lang === 'ar' ? 'الحالة' : 'Status'}</span><span className={styles.statusChip} style={{ background: `${cfg.color}18`, color: cfg.color }}>{lang === 'ar' ? cfg.ar : cfg.en}</span></div>
                    <div className={styles.sheetRow}><span>{lang === 'ar' ? 'الإجمالي' : 'Total'}</span><strong>{p.total.toFixed(2)} {lang === 'ar' ? 'ج.م' : 'EGP'}</strong></div>
                    <div className={styles.sheetRow}><span>{lang === 'ar' ? 'المجموع الفرعي' : 'Subtotal'}</span><span>{p.subtotal.toFixed(2)} {lang === 'ar' ? 'ج.م' : 'EGP'}</span></div>
                    {p.discount > 0 && <div className={styles.sheetRow}><span>{lang === 'ar' ? 'الخصم' : 'Discount'}</span><span style={{ color: 'var(--success)' }}>-{p.discount.toFixed(2)} {lang === 'ar' ? 'ج.م' : 'EGP'}</span></div>}
                    <div className={styles.sheetRow}><span>{lang === 'ar' ? 'طريقة الدفع' : 'Payment Method'}</span><span>{p.payment_method}</span></div>
                    {p.order_number && <div className={styles.sheetRow}><span>{lang === 'ar' ? 'رقم الطلب' : 'Order No.'}</span><span>#{p.order_number}</span></div>}
                    <div className={styles.sheetRow}><span>{lang === 'ar' ? 'تاريخ الإنشاء' : 'Created'}</span><span>{new Date(p.created_at).toLocaleDateString(lang === 'ar' ? 'ar-EG' : 'en-US')}</span></div>
                    {p.paid_at && <div className={styles.sheetRow}><span>{lang === 'ar' ? 'تاريخ الدفع' : 'Paid at'}</span><span>{new Date(p.paid_at).toLocaleDateString(lang === 'ar' ? 'ar-EG' : 'en-US')}</span></div>}
                  </>
                );
              })()}
            </div>
          </div>
        </div>
      )}
    </main>
  );
}
