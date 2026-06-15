'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { Mail, ArrowLeft, ArrowRight, CheckCircle } from 'lucide-react';
import { supabase } from '../../lib/supabaseClient';
import { useApp } from '../../context/AppContext';
import styles from '../login/page.module.css';

export default function ForgotPasswordPage() {
  const { lang } = useApp();
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [sent, setSent] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    const { error: resetError } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/reset-password`,
    });

    if (resetError) {
      setError(resetError.message);
    } else {
      setSent(true);
    }

    setLoading(false);
  };

  return (
    <div className={`${styles.authContainer} fade-in`}>
      <div className={`${styles.card} glass`}>
        <div className={styles.header}>
          <h1 className={`${styles.title} gradient-text`}>
            {lang === 'ar' ? 'استعادة كلمة المرور' : 'Reset Password'}
          </h1>
          <p className={styles.subtitle}>
            {lang === 'ar'
              ? 'أدخل بريدك الإلكتروني وسنرسل لك رابطاً لإعادة التعيين.'
              : 'Enter your email and we will send you a reset link.'}
          </p>
        </div>

        {sent ? (
          <div className={styles.successAlert}>
            <CheckCircle size={24} />
            <span>
              {lang === 'ar'
                ? 'تم إرسال رابط إعادة التعيين. راجع بريدك الإلكتروني.'
                : 'Reset link sent. Please check your email.'}
            </span>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className={styles.form}>
            {error && <div className={styles.errorAlert}>{error}</div>}

            <div className={styles.inputGroup}>
              <label className={styles.label}>{lang === 'ar' ? 'البريد الإلكتروني' : 'Email'}</label>
              <div className={styles.inputWrapper}>
                <Mail size={18} className={styles.inputIcon} />
                <input
                  type="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="you@example.com"
                  className={styles.input}
                />
              </div>
            </div>

            <button type="submit" disabled={loading} className={`${styles.submitBtn} gradient-bg`}>
              {loading ? (
                <span className={styles.spinner}></span>
              ) : (
                <>
                  {lang === 'ar' ? 'إرسال الرابط' : 'Send Link'}
                  {lang === 'ar' ? <ArrowLeft size={18} /> : <ArrowRight size={18} />}
                </>
              )}
            </button>
          </form>
        )}

        <div className={styles.toggleState}>
          <Link href="/login" className={styles.toggleBtn}>
            {lang === 'ar' ? <ArrowRight size={16} /> : <ArrowLeft size={16} />}
            {lang === 'ar' ? 'العودة لتسجيل الدخول' : 'Back to login'}
          </Link>
        </div>
      </div>
    </div>
  );
}
