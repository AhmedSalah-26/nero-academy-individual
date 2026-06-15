'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useApp } from '../../../context/AppContext';
import { supabase } from '../../../lib/supabaseClient';
import { CheckCircle, ArrowRight, ArrowLeft, Loader2, AlertCircle } from 'lucide-react';
import styles from './page.module.css';

type VerificationState = 'verifying' | 'paid' | 'pending' | 'error';

export default function CheckoutSuccessPage() {
  const { lang, t, refreshAuth } = useApp();
  const router = useRouter();
  const [state, setState] = useState<VerificationState>('verifying');
  const [errorMessage, setErrorMessage] = useState('');

  useEffect(() => {
    let cancelled = false;

    async function verify() {
      const parentId = sessionStorage.getItem('pending_parent_enrollment_id');

      if (!parentId) {
        if (!cancelled) setState('error');
        return;
      }

      try {
        const { data, error } = await supabase
          .from('parent_enrollments')
          .select('payment_status')
          .eq('id', parentId)
          .single();

        if (error) throw error;

        if (data?.payment_status === 'paid') {
          sessionStorage.removeItem('pending_parent_enrollment_id');
          sessionStorage.removeItem('checkout_totals');
          sessionStorage.removeItem('applied_coupon');
          await refreshAuth();
          if (!cancelled) setState('paid');
        } else if (data?.payment_status === 'pending') {
          if (!cancelled) setState('pending');
        } else {
          if (!cancelled) setState('error');
        }
      } catch (err: unknown) {
        if (!cancelled) {
          setState('error');
          setErrorMessage(err instanceof Error ? err.message : '');
        }
      }
    }

    verify();

    const interval = window.setInterval(() => {
      if (state === 'pending' || state === 'verifying') {
        verify();
      }
    }, 3000);

    return () => {
      cancelled = true;
      window.clearInterval(interval);
    };
  }, [refreshAuth, state]);

  const title =
    state === 'paid'
      ? t.paymentSuccess
      : state === 'pending'
      ? lang === 'ar'
        ? 'في انتظار تأكيد الدفع...'
        : 'Waiting for payment confirmation...'
      : lang === 'ar'
      ? 'تعذر التحقق من الدفع'
      : 'Could not verify payment';

  const message =
    state === 'paid'
      ? t.orderComplete
      : state === 'pending'
      ? lang === 'ar'
        ? 'تم استلام طلبك، وسيتم تفعيل الكورس فور تأكيد الدفع.'
        : 'Your order was received. Courses will activate once payment is confirmed.'
      : lang === 'ar'
      ? errorMessage || 'يرجى التواصل مع الدعم إذا استمرت المشكلة.'
      : errorMessage || 'Please contact support if the issue persists.';

  return (
    <div className={`${styles.successContainer} fade-in`}>
      <div className={`${styles.card} glass`}>
        {state === 'verifying' || state === 'pending' ? (
          <Loader2 size={64} className={`${styles.successIcon} ${styles.spin}`} />
        ) : state === 'paid' ? (
          <CheckCircle size={72} className={styles.successIcon} />
        ) : (
          <AlertCircle size={72} className={styles.errorIcon} />
        )}

        <h1 className={`${styles.title} ${state === 'error' ? styles.errorText : 'gradient-text'}`}>
          {title}
        </h1>
        <p className={styles.message}>{message}</p>

        {state === 'paid' && (
          <Link href="/my-learning" className={`${styles.dashboardBtn} gradient-bg`}>
            <span>{lang === 'ar' ? 'اذهب لصفحة مقرراتي' : 'Go to My Learning'}</span>
            {lang === 'ar' ? <ArrowLeft size={16} /> : <ArrowRight size={16} />}
          </Link>
        )}

        {state === 'error' && (
          <button
            type="button"
            onClick={() => router.push('/my-learning')}
            className={`${styles.dashboardBtn} gradient-bg`}
          >
            <span>{lang === 'ar' ? 'صفحة تعليمي' : 'My Learning'}</span>
            {lang === 'ar' ? <ArrowLeft size={16} /> : <ArrowRight size={16} />}
          </button>
        )}
      </div>
    </div>
  );
}
