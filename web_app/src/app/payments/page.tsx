'use client';

import { useEffect, useState } from 'react';
import { CreditCard, CheckCircle, Clock, XCircle } from 'lucide-react';
import { supabase } from '../../lib/supabaseClient';
import { useApp } from '../../context/AppContext';
import { FeaturePageHero } from '../../components/FeaturePageHero';
import styles from '../student-features.module.css';

interface Payment {
  id: string;
  total: number;
  subtotal: number;
  discount: number;
  payment_status: 'pending' | 'paid' | 'failed' | 'refunded';
  payment_method: string;
  paid_at?: string;
  created_at: string;
}

const statusIcons: Record<string, React.ReactNode> = {
  paid: <CheckCircle size={18} />,
  pending: <Clock size={18} />,
  failed: <XCircle size={18} />,
  refunded: <XCircle size={18} />,
};

const statusLabels: Record<string, { ar: string; en: string }> = {
  paid: { ar: 'مدفوع', en: 'Paid' },
  pending: { ar: 'معلق', en: 'Pending' },
  failed: { ar: 'فاشل', en: 'Failed' },
  refunded: { ar: 'مسترجع', en: 'Refunded' },
};

export default function PaymentsPage() {
  const { lang, user } = useApp();
  const [items, setItems] = useState<Payment[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!user) return;

    supabase
      .from('parent_enrollments')
      .select('id, total, subtotal, discount, payment_status, payment_method, paid_at, created_at')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false })
      .then(({ data, error }) => {
        if (!error) setItems((data || []) as Payment[]);
        setLoading(false);
      });
  }, [user]);

  if (!user) {
    return (
      <main className={styles.page}>
        <div className={styles.empty}>
          {lang === 'ar' ? 'سجل الدخول لعرض سجل المدفوعات' : 'Sign in to view payment history'}
        </div>
      </main>
    );
  }

  return (
    <main className={styles.page}>
      <FeaturePageHero
        icon={CreditCard}
        eyebrow="BILLING"
        title={lang === 'ar' ? 'سجل المدفوعات' : 'Payment History'}
        subtitle={lang === 'ar' ? 'تفاصيل مشترياتك وحالات الدفع.' : 'Details of your purchases and payment status.'}
      />

      {loading ? (
        <div className={styles.empty}>{lang === 'ar' ? 'جاري التحميل...' : 'Loading...'}</div>
      ) : items.length === 0 ? (
        <div className={styles.empty}>
          <CreditCard size={38} />
          <strong>{lang === 'ar' ? 'لا توجد مدفوعات بعد' : 'No payments yet'}</strong>
        </div>
      ) : (
        <section className={styles.list}>
          {items.map((p) => {
            const status = p.payment_status || 'pending';
            const label = statusLabels[status] || { ar: status, en: status };

            return (
              <article key={p.id} className={styles.card}>
                <div className={styles.cardTop}>
                  <div className={styles.cardIcon}>{statusIcons[status]}</div>
                  <span className={`${styles.badge} ${styles[status]}`}>{lang === 'ar' ? label.ar : label.en}</span>
                </div>
                <h3>{p.total.toFixed(2)} {lang === 'ar' ? 'جنية' : 'EGP'}</h3>
                <p>
                  {lang === 'ar' ? 'طريقة الدفع:' : 'Payment method:'} {p.payment_method}
                </p>
                {p.discount > 0 && (
                  <p>
                    {lang === 'ar' ? 'الخصم:' : 'Discount:'} {p.discount.toFixed(2)}
                  </p>
                )}
                <div className={styles.meta}>
                  <span>{new Date(p.created_at).toLocaleDateString(lang === 'ar' ? 'ar-EG' : 'en-US')}</span>
                  {p.paid_at && <span>{new Date(p.paid_at).toLocaleDateString(lang === 'ar' ? 'ar-EG' : 'en-US')}</span>}
                </div>
              </article>
            );
          })}
        </section>
      )}
    </main>
  );
}
