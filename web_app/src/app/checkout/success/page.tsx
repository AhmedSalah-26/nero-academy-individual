'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { CheckCircle, ArrowForward, ArrowBack, Sync, Error as ErrorIcon, WhatsApp, ContentCopy, Check } from '@mui/icons-material';
import { useApp } from '../../../context/AppContext';
import { supabase } from '../../../lib/supabaseClient';
import { AppButton } from '../../../components/ui';
import { usePageTransition } from '../../../lib/animations';
import styles from './page.module.css';

type VerificationState = 'verifying' | 'paid' | 'pending' | 'error';

export default function CheckoutSuccessPage() {
  const pageRef = usePageTransition();
  const { lang, t, refreshAuth } = useApp();
  const router = useRouter();
  const [state, setState] = useState<VerificationState>('verifying');
  const [errorMessage, setErrorMessage] = useState('');
  const [orderId, setOrderId] = useState('');
  const [instructorPhone, setInstructorPhone] = useState('');
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    let cancelled = false;
    const parentId = sessionStorage.getItem('pending_parent_enrollment_id');
    if (!parentId) { if (!cancelled) setState('error'); return; }

    async function verify() {
      try {
        const { data, error } = await supabase.from('parent_enrollments').select('payment_status, order_number, courses(instructor_id)').eq('id', parentId).single();
        if (error) throw error;
        if (data?.order_number) setOrderId(data.order_number);

        const instructorId = (data?.courses as { instructor_id: string }[] | undefined)?.[0]?.instructor_id;
        if (instructorId) {
          const { data: profData } = await supabase.from('profiles').select('phone').eq('id', instructorId).maybeSingle();
          if (profData?.phone) setInstructorPhone(profData.phone);
        }

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
        if (!cancelled) { setState('error'); setErrorMessage(err instanceof Error ? err.message : ''); }
      }
    }

    verify();
    const interval = window.setInterval(() => { if (state === 'pending' || state === 'verifying') verify(); }, 3000);
    return () => { cancelled = true; window.clearInterval(interval); };
  }, [refreshAuth, state]);

  const handleCopyOrderId = async () => {
    if (!orderId) return;
    try { await navigator.clipboard.writeText(orderId); setCopied(true); setTimeout(() => setCopied(false), 2000); } catch {}
  };

  const whatsappUrl = instructorPhone ? `https://wa.me/${instructorPhone.replace(/[^0-9+]/g, '')}` : 'https://wa.me/201012345678';

  const title = state === 'paid' ? t.paymentSuccess : state === 'pending' ? (lang === 'ar' ? 'في انتظار تأكيد الدفع...' : 'Waiting for payment confirmation...') : (lang === 'ar' ? 'تعذر التحقق من الدفع' : 'Could not verify payment');
  const message = state === 'paid' ? t.orderComplete : state === 'pending' ? (lang === 'ar' ? 'تم استلام طلبك، وسيتم تفعيل الكورس فور تأكيد الدفع.' : 'Your order was received. Courses will activate once payment is confirmed.') : (lang === 'ar' ? errorMessage || 'يرجى التواصل مع الدعم إذا استمرت المشكلة.' : errorMessage || 'Please contact support if the issue persists.');

  return (
    <div ref={pageRef} className={styles.successContainer}>
      <div className={styles.card}>
        {state === 'verifying' || state === 'pending' ? (
          <div className={styles.iconCircle}><Sync fontSize="large" className={styles.spin} /></div>
        ) : state === 'paid' ? (
          <div className={`${styles.iconCircle} ${styles.iconSuccess}`}><CheckCircle fontSize="large" /></div>
        ) : (
          <div className={`${styles.iconCircle} ${styles.iconError}`}><ErrorIcon fontSize="large" /></div>
        )}

        <h1 className={styles.title}>{title}</h1>
        <p className={styles.message}>{message}</p>

        {state === 'paid' && orderId && (
          <div className={styles.orderIdRow}>
            <span className={styles.orderIdLabel}>{lang === 'ar' ? 'رقم الطلب' : 'Order ID'}</span>
            <div className={styles.orderIdValue}>
              <span>{orderId}</span>
              <button onClick={handleCopyOrderId} className={styles.copyBtn} aria-label="Copy order ID">
                {copied ? <Check fontSize="small" /> : <ContentCopy fontSize="small" />}
              </button>
            </div>
          </div>
        )}

        {state === 'paid' && (
          <a href={whatsappUrl} target="_blank" rel="noopener noreferrer" className={styles.whatsappBtn}>
            <WhatsApp fontSize="small" />
            <span>{lang === 'ar' ? 'تواصل معنا عبر واتساب' : 'Contact us on WhatsApp'}</span>
          </a>
        )}

        <Link href="/my-learning" className={styles.dashboardBtn}>
          <span>{lang === 'ar' ? 'اذهب لصفحة تعليمي' : 'Go to My Learning'}</span>
          {lang === 'ar' ? <ArrowBack fontSize="small" /> : <ArrowForward fontSize="small" />}
        </Link>
      </div>
    </div>
  );
}
