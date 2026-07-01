'use client';

import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Lock, CheckCircle, ErrorOutlined } from '@mui/icons-material';
import { supabase } from '../../lib/supabaseClient';
import { useApp } from '../../context/AppContext';
import { Validators } from '../../lib/validators';
import { ToastUtils } from '../../lib/toast';
import styles from '../login/page.module.css';
import { usePageTransition } from '../../lib/animations';

export default function ResetPasswordPage() {
  const pageRef = usePageTransition();
  const { lang, t } = useApp();
  const router = useRouter();
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [loading, setLoading] = useState(false);
  const [done, setDone] = useState(false);
  const [error, setError] = useState('');
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [urlError, setUrlError] = useState('');

  useEffect(() => {
    if (typeof window === 'undefined') return;
    const hash = window.location.hash.substring(1);
    const params = new URLSearchParams(hash);
    const errorCode = params.get('error');
    const errorDesc = params.get('error_description');
    if (errorCode) {
      setUrlError(
        errorDesc || errorCode || (lang === 'ar' ? 'رابط غير صالح' : 'Invalid link')
      );
    }

    supabase.auth.onAuthStateChange((event) => {
      if (event === 'PASSWORD_RECOVERY') {
        // ready to update password
      }
    });
  }, [lang]);

  const clearError = (field: string) => {
    setErrors((prev) => {
      const next = { ...prev };
      delete next[field];
      return next;
    });
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    const newErrors: Record<string, string> = {};
    const passErr = Validators.password(password, { lang });
    if (passErr) newErrors.password = passErr;
    const confirmErr = Validators.confirmPassword(password, confirm, { lang });
    if (confirmErr) newErrors.confirm = confirmErr;
    setErrors(newErrors);
    if (Object.keys(newErrors).length > 0) return;

    setLoading(true);
    setError('');

    try {
      const { error: updateError } = await supabase.auth.updateUser({ password });
      if (updateError) {
        setError(updateError.message);
      } else {
        setDone(true);
        ToastUtils.showSuccess(
          lang === 'ar'
            ? 'تم تحديث كلمة المرور بنجاح'
            : 'Password updated successfully'
        );
        setTimeout(() => router.push('/login'), 2000);
      }
    } catch {
      setError(t.errorAuth);
    } finally {
      setLoading(false);
    }
  };

  if (urlError) {
    return (
      <div className={`${styles.authContainer} fade-in`}>
        <div className={`${styles.card} glass`}>
          <div style={{ textAlign: 'center', padding: '32px' }}>
            <div className={styles.resetIconCircle}>
              <ErrorOutlined fontSize="large" />
            </div>
            <h2 style={{ fontSize: '1.2rem', fontWeight: 700, marginBottom: 8, color: 'var(--error)' }}>
              {lang === 'ar' ? 'خطأ في الرابط' : 'Link Error'}
            </h2>
            <p style={{ fontSize: '0.9rem', color: 'var(--text-muted)', marginBottom: 24 }}>
              {urlError}
            </p>
            <button
              type="button"
              className={`${styles.submitBtn} gradient-bg`}
              onClick={() => router.push('/forgot-password')}
            >
              {lang === 'ar' ? 'طلب رابط جديد' : 'Request new link'}
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div ref={pageRef} className={`${styles.authContainer} fade-in`}>
      <div className={`${styles.card} glass`}>
        <div className={styles.header}>
          <h1 className={`${styles.brandTitle} gradient-text`}>
            {lang === 'ar' ? 'كلمة مرور جديدة' : 'New Password'}
          </h1>
        </div>

        {done ? (
          <div className={styles.successAlert}>
            <CheckCircle fontSize="medium" />
            <span>
              {lang === 'ar'
                ? 'تم تحديث كلمة المرور. جاري التوجيه...'
                : 'Password updated. Redirecting...'}
            </span>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className={styles.form}>
            {error && <div className={styles.errorAlert}>{error}</div>}

            <div className={styles.inputGroup}>
              <label className={styles.label}>
                {lang === 'ar' ? 'كلمة المرور الجديدة' : 'New Password'}
              </label>
              <div className={styles.inputWrapper}>
                <Lock fontSize="small" className={styles.inputIcon} />
                <input
                  type="password"
                  required
                  value={password}
                  onChange={(e) => { setPassword(e.target.value); clearError('password'); }}
                  className={`${styles.input} ${errors.password ? styles.inputError : ''}`}
                />
              </div>
              {errors.password && <span className={styles.fieldError}>{errors.password}</span>}
            </div>

            <div className={styles.inputGroup}>
              <label className={styles.label}>
                {lang === 'ar' ? 'تأكيد كلمة المرور' : 'Confirm Password'}
              </label>
              <div className={styles.inputWrapper}>
                <Lock fontSize="small" className={styles.inputIcon} />
                <input
                  type="password"
                  required
                  value={confirm}
                  onChange={(e) => { setConfirm(e.target.value); clearError('confirm'); }}
                  className={`${styles.input} ${errors.confirm ? styles.inputError : ''}`}
                />
              </div>
              {errors.confirm && <span className={styles.fieldError}>{errors.confirm}</span>}
            </div>

            <button type="submit" disabled={loading} className={`${styles.submitBtn} gradient-bg`}>
              {loading ? (
                <span className={styles.spinner}></span>
              ) : (
                lang === 'ar' ? 'تحديث كلمة المرور' : 'Update Password'
              )}
            </button>
          </form>
        )}
      </div>
    </div>
  );
}
