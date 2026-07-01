'use client';

import React, { useState, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { Mail, Lock, MarkEmailUnread, ArrowForward } from '@mui/icons-material';
import { supabase } from '../../lib/supabaseClient';
import { useApp } from '../../context/AppContext';
import { Validators } from '../../lib/validators';
import { ToastUtils } from '../../lib/toast';
import AppBackButton from '../../components/ui/AppBackButton';
import styles from '../login/page.module.css';
import { usePageTransition } from '../../lib/animations';

export default function ForgotPasswordPage() {
  const pageRef = usePageTransition();
  const { lang, t } = useApp();
  const router = useRouter();

  const [email, setEmail] = useState('');
  const [otp, setOtp] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [phase, setPhase] = useState<1 | 2>(1);

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [resending, setResending] = useState(false);

  const clearError = (field: string) => {
    setErrors((prev) => {
      const next = { ...prev };
      delete next[field];
      return next;
    });
  };

  const validatePhase1 = useCallback((): boolean => {
    const newErrors: Record<string, string> = {};
    const emailErr = Validators.email(email, { lang });
    if (emailErr) newErrors.email = emailErr;
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  }, [email, lang]);

  const validatePhase2 = useCallback((): boolean => {
    const newErrors: Record<string, string> = {};
    if (!/^\d{6}$/.test(otp.trim())) {
      newErrors.otp = lang === 'ar' ? 'أدخل كود مكون من 6 أرقام' : 'Enter the 6-digit code';
    }
    const passErr = Validators.password(newPassword, { lang });
    if (passErr) newErrors.newPassword = passErr;
    const confirmErr = Validators.confirmPassword(newPassword, confirmPassword, { lang });
    if (confirmErr) newErrors.confirmPassword = confirmErr;
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  }, [otp, newPassword, confirmPassword, lang]);

  const handleSendCode = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validatePhase1()) return;

    setLoading(true);
    setError('');

    try {
      const { error: otpError } = await supabase.auth.signInWithOtp({
        email,
        options: { shouldCreateUser: false },
      });

      if (otpError) {
        setError(otpError.message);
      } else {
        setOtp('');
        setNewPassword('');
        setConfirmPassword('');
        setPhase(2);
        ToastUtils.showSuccess(
          lang === 'ar'
            ? 'تم إرسال كود التحقق لبريدك الإلكتروني'
            : 'Verification code sent to your email'
        );
      }
    } catch {
      setError(t.errorAuth);
    } finally {
      setLoading(false);
    }
  };

  const handleVerifyAndReset = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validatePhase2()) return;

    setLoading(true);
    setError('');

    try {
      const { data: verifyData, error: verifyError } = await supabase.auth.verifyOtp({
        email,
        token: otp,
        type: 'email',
      });

      if (verifyError) {
        setError(verifyError.message);
        return;
      }

      if (verifyData.user) {
        const { error: updateError } = await supabase.auth.updateUser({ password: newPassword });
        if (updateError) {
          setError(updateError.message);
          return;
        }

        await supabase.auth.signOut();

        ToastUtils.showSuccess(
          lang === 'ar'
            ? 'تم تغيير كلمة المرور بنجاح'
            : 'Password changed successfully'
        );
        router.push('/login');
      }
    } catch {
      setError(t.errorAuth);
    } finally {
      setLoading(false);
    }
  };

  const handleResend = async () => {
    setResending(true);
    try {
      const { error: resendError } = await supabase.auth.signInWithOtp({
        email,
        options: { shouldCreateUser: false },
      });
      if (resendError) {
        ToastUtils.showError(resendError.message);
      } else {
        ToastUtils.showSuccess(
          lang === 'ar' ? 'تم إعادة إرسال الكود' : 'Code resent'
        );
      }
    } catch {
      ToastUtils.showError(t.errorAuth);
    } finally {
      setResending(false);
    }
  };

  return (
    <div ref={pageRef} className={`${styles.authContainer} fade-in`}>
      <div className={`${styles.card} glass`}>
        <AppBackButton
          label={lang === 'ar' ? 'رجوع' : 'Back'}
          onClick={() => {
            if (phase === 2) {
              setPhase(1);
              setErrors({});
              setError('');
            } else {
              router.back();
            }
          }}
        />

        <div className={styles.resetIconCircle}>
          <MarkEmailUnread fontSize="large" />
        </div>

        <div className={styles.header}>
          <h1 className={`${styles.brandTitle} gradient-text`}>
            {lang === 'ar' ? 'استعادة كلمة المرور' : 'Reset Password'}
          </h1>
          <p className={styles.subtitle}>
            {phase === 1
              ? lang === 'ar'
                ? 'أدخل بريدك الإلكتروني وسنرسل لك كود التحقق.'
                : 'Enter your email and we will send you a verification code.'
              : lang === 'ar'
                ? 'أدخل الكود المرسل لبريدك وكلمة المرور الجديدة.'
                : 'Enter the code sent to your email and your new password.'}
          </p>
        </div>

        {error && <div className={styles.errorAlert}>{error}</div>}

        {phase === 1 ? (
          <form onSubmit={handleSendCode} className={styles.form} autoComplete="on">
            <div className={styles.inputGroup}>
              <label className={styles.label}>{t.email}</label>
              <div className={styles.inputWrapper}>
                <Mail fontSize="small" className={styles.inputIcon} />
                <input
                  type="email"
                  required
                  value={email}
                  onChange={(e) => { setEmail(e.target.value); clearError('email'); }}
                  placeholder="you@example.com"
                  autoComplete="email"
                  dir="ltr"
                  className={`${styles.input} ${errors.email ? styles.inputError : ''}`}
                />
              </div>
              {errors.email && <span className={styles.fieldError}>{errors.email}</span>}
            </div>

            <button type="submit" disabled={loading} className={`${styles.submitBtn} gradient-bg`}>
              {loading ? (
                <span className={styles.spinner}></span>
              ) : (
                <>
                  {t.sendResetCode}
                  <ArrowForward fontSize="small" />
                </>
              )}
            </button>
          </form>
        ) : (
          <form onSubmit={handleVerifyAndReset} className={styles.form} autoComplete="off">
            <input
              type="email"
              name="username"
              value={email}
              readOnly
              hidden
              autoComplete="username"
            />
            <div className={styles.inputGroup}>
              <label className={styles.label}>{t.enterOtp}</label>
              <input
                type="text"
                required
                name="reset_otp"
                value={otp}
                onChange={(e) => {
                  setOtp(e.target.value.replace(/\D/g, '').slice(0, 6));
                  clearError('otp');
                }}
                placeholder="123456"
                inputMode="numeric"
                pattern="[0-9]*"
                maxLength={6}
                autoComplete="one-time-code"
                dir="ltr"
                className={`${styles.input} ${styles.otpInput} ${errors.otp ? styles.inputError : ''}`}
              />
              {errors.otp && <span className={styles.fieldError}>{errors.otp}</span>}
            </div>

            <div className={styles.inputGroup}>
              <label className={styles.label}>
                {lang === 'ar' ? 'كلمة المرور الجديدة' : 'New Password'}
              </label>
              <div className={styles.inputWrapper}>
                <Lock fontSize="small" className={styles.inputIcon} />
                <input
                  type="password"
                  required
                  value={newPassword}
                  onChange={(e) => { setNewPassword(e.target.value); clearError('newPassword'); }}
                  placeholder="••••••••"
                  autoComplete="new-password"
                  className={`${styles.input} ${errors.newPassword ? styles.inputError : ''}`}
                />
              </div>
              {errors.newPassword && <span className={styles.fieldError}>{errors.newPassword}</span>}
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
                  value={confirmPassword}
                  onChange={(e) => { setConfirmPassword(e.target.value); clearError('confirmPassword'); }}
                  placeholder="••••••••"
                  autoComplete="new-password"
                  className={`${styles.input} ${errors.confirmPassword ? styles.inputError : ''}`}
                />
              </div>
              {errors.confirmPassword && (
                <span className={styles.fieldError}>{errors.confirmPassword}</span>
              )}
            </div>

            <button type="submit" disabled={loading} className={`${styles.submitBtn} gradient-bg`}>
              {loading ? (
                <span className={styles.spinner}></span>
              ) : (
                t.verifyAndReset
              )}
            </button>

            <button
              type="button"
              className={styles.resendBtn}
              onClick={handleResend}
              disabled={resending}
            >
              {resending ? <span className={styles.spinner} /> : t.resendCode}
            </button>
          </form>
        )}
      </div>
    </div>
  );
}
