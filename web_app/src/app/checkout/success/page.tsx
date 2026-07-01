'use client';

import React, { useEffect, useState, Suspense } from 'react';
import Link from 'next/link';
import { useRouter, useSearchParams } from 'next/navigation';
import { CheckCircle, Sync, Error as ErrorIcon, WhatsApp, ContentCopy, Check, ArrowForward, ArrowBack, AssignmentTurnedInRounded } from '@mui/icons-material';
import { useApp } from '../../../context/AppContext';
import { supabase } from '../../../lib/supabaseClient';
import { usePageTransition } from '../../../lib/animations';
import styles from './page.module.css';

type VerificationState = 'verifying' | 'paid' | 'pending' | 'error';

function normalizePhone(phone: string | null | undefined): string | null {
  if (!phone) return null;
  const digits = phone.replace(/[^0-9]/g, '');
  if (!digits) return null;
  if (digits.startsWith('00') && digits.length > 2) return digits.slice(2);
  return digits;
}

async function loadInstructorPhone(parentId: string): Promise<string | null> {
  try {
    const { data: requestItems } = await supabase
      .from('manual_purchase_request_items')
      .select('instructor_id, course_id')
      .eq('parent_enrollment_id', parentId)
      .limit(1);

    let first = requestItems?.[0];

    if (!first) {
      const { data: enrollments } = await supabase
        .from('enrollments')
        .select('instructor_id, course_id')
        .eq('parent_enrollment_id', parentId)
        .limit(1);

      first = enrollments?.[0];
    }

    if (first?.instructor_id) {
      const { data: prof } = await supabase
        .from('profiles')
        .select('phone')
        .eq('id', first.instructor_id)
        .maybeSingle();
      const normalized = normalizePhone(prof?.phone);
      if (normalized) return normalized;
    }

    if (first?.course_id) {
      const { data: course } = await supabase
        .from('courses')
        .select('instructor_id')
        .eq('id', first.course_id)
        .maybeSingle();
      if (course?.instructor_id) {
        const { data: prof } = await supabase
          .from('profiles')
          .select('phone')
          .eq('id', course.instructor_id)
          .maybeSingle();
        const normalized = normalizePhone(prof?.phone);
        if (normalized) return normalized;
      }
    }

    const { data: fallback } = await supabase
      .from('profiles')
      .select('phone')
      .in('role', ['admin', 'instructor'])
      .not('phone', 'is', null)
      .limit(1)
      .maybeSingle();

    return normalizePhone(fallback?.phone);
  } catch {
    return null;
  }
}

function CheckoutSuccessContent() {
  const pageRef = usePageTransition();
  const { lang, t, refreshAuth } = useApp();
  const router = useRouter();
  const searchParams = useSearchParams();
  const [state, setState] = useState<VerificationState>('verifying');
  const [errorMessage, setErrorMessage] = useState('');
  const [orderId, setOrderId] = useState('');
  const [shortOrderId, setShortOrderId] = useState('');
  const [instructorPhone, setInstructorPhone] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);
  const [loadingPhone, setLoadingPhone] = useState(true);

  useEffect(() => {
    let cancelled = false;
    const parentId = sessionStorage.getItem('pending_parent_enrollment_id') || searchParams.get('id');
    if (!parentId) {
      if (!cancelled) setState('error');
      return;
    }

    setShortOrderId(parentId.length <= 8 ? parentId.toUpperCase() : parentId.substring(0, 8).toUpperCase());

    async function verify() {
      try {
        const { data, error } = await supabase
          .from('parent_enrollments')
          .select('id, payment_status, payment_method')
          .eq('id', parentId)
          .single();

        if (error) throw error;

        if (data?.id) setOrderId(data.id);

        const status = data?.payment_status;
        if (status === 'paid') {
          sessionStorage.removeItem('pending_parent_enrollment_id');
          sessionStorage.removeItem('checkout_totals');
          sessionStorage.removeItem('applied_coupon');
          await refreshAuth();
          if (!cancelled) setState('paid');
        } else if (status === 'pending' || status === 'pending_manual_payment') {
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

    async function loadPhone() {
      setLoadingPhone(true);
      const phone = await loadInstructorPhone(parentId!);
      if (!cancelled) {
        setInstructorPhone(phone);
        setLoadingPhone(false);
      }
    }

    verify();
    loadPhone();

    const interval = window.setInterval(() => {
      if (state === 'pending' || state === 'verifying') verify();
    }, 3000);

    return () => {
      cancelled = true;
      window.clearInterval(interval);
    };
  }, [refreshAuth, state, searchParams]);

  const handleCopy = async (value: string) => {
    try {
      await navigator.clipboard.writeText(value);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {}
  };

  const handleWhatsApp = () => {
    if (!instructorPhone) return;
    const text = encodeURIComponent(t.whatsappMessage.replace('{orderId}', orderId || shortOrderId));
    const url = `https://wa.me/${instructorPhone}?text=${text}`;
    window.open(url, '_blank', 'noopener,noreferrer');
  };

  const isPaid = state === 'paid';
  const isPending = state === 'pending';
  const isError = state === 'error';

  return (
    <div ref={pageRef} className={styles.successContainer}>
      <div className={styles.card}>
        {state === 'verifying' ? (
          <div className={styles.iconCircle}>
            <Sync fontSize="large" className={styles.spin} />
          </div>
        ) : isPaid ? (
          <div className={`${styles.iconCircle} ${styles.iconSuccess}`}>
            <CheckCircle fontSize="large" />
          </div>
        ) : isPending ? (
          <div className={`${styles.iconCircle} ${styles.iconPending}`}>
            <AssignmentTurnedInRounded fontSize="large" />
          </div>
        ) : (
          <div className={`${styles.iconCircle} ${styles.iconError}`}>
            <ErrorIcon fontSize="large" />
          </div>
        )}

        <h1 className={styles.title}>
          {isPaid ? t.paymentSuccess : isPending ? t.requestSubmitted : isError ? (lang === 'ar' ? 'تعذر التحقق' : 'Could not verify') : ''}
        </h1>

        <p className={styles.message}>
          {isPaid
            ? t.orderComplete
            : isPending
            ? t.manualRequestSubtitle
            : isError
            ? errorMessage || (lang === 'ar' ? 'يرجى التواصل مع الدعم.' : 'Please contact support.')
            : ''}
        </p>

        {(isPaid || isPending || isError) && (
          <div className={styles.infoList}>
            <div className={styles.infoTile}>
              <div className={styles.infoTileIcon}>
                <AssignmentTurnedInRounded fontSize="small" />
              </div>
              <div className={styles.infoTileContent}>
                <span className={styles.infoTileLabel}>{t.operationId}</span>
                <span className={styles.infoTileValue}>{shortOrderId}</span>
              </div>
              <button className={styles.copyBtn} onClick={() => handleCopy(orderId || shortOrderId)} aria-label="Copy">
                {copied ? <Check fontSize="small" /> : <ContentCopy fontSize="small" />}
              </button>
            </div>

            {(isPending || isError) && (
              <div className={styles.infoTile}>
                <div className={styles.infoTileIcon}>
                  <WhatsApp fontSize="small" />
                </div>
                <div className={styles.infoTileContent}>
                  <span className={styles.infoTileLabel}>{t.instructorWhatsapp}</span>
                  <span className={styles.infoTileValue}>
                    {loadingPhone
                      ? (lang === 'ar' ? 'جاري التحميل...' : 'Loading...')
                      : instructorPhone
                      ? `+${instructorPhone}`
                      : t.noPhoneAvailable}
                  </span>
                </div>
                {instructorPhone && (
                  <button className={styles.copyBtn} onClick={() => handleCopy(`+${instructorPhone}`)} aria-label="Copy phone">
                    {copied ? <Check fontSize="small" /> : <ContentCopy fontSize="small" />}
                  </button>
                )}
              </div>
            )}
          </div>
        )}

        {(isPending || isError) && (
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

        <div className={styles.actions}>
          <Link href="/orders-status" className={`${styles.dashboardBtn} gradient-bg`}>
            <span>{t.viewOrders}</span>
            {lang === 'ar' ? <ArrowBack fontSize="small" /> : <ArrowForward fontSize="small" />}
          </Link>

          <Link href="/" className={styles.textBtn}>
            {t.backToHome}
          </Link>
        </div>
      </div>
    </div>
  );
}

export default function CheckoutSuccessPage() {
  return (
    <Suspense fallback={<div />}>
      <CheckoutSuccessContent />
    </Suspense>
  );
}
