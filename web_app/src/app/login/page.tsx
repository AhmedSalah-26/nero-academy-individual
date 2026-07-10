'use client';

import React, { Suspense, useState, useCallback } from 'react';
import Link from 'next/link';
import { useRouter, useSearchParams } from 'next/navigation';
import { useApp } from '../../context/AppContext';
import { supabase } from '../../lib/supabaseClient';
import { Validators } from '../../lib/validators';
import { ToastUtils } from '../../lib/toast';
import {
  Mail,
  Lock,
  Person,
  Phone,
  Login as LoginIcon,
  MarkEmailUnread,
  ArrowBack,
  ArrowForward,
} from '@mui/icons-material';
import styles from './page.module.css';
import { usePageTransition } from '../../lib/animations';

function LoginContent() {
  const pageRef = usePageTransition();
  const { lang, t, refreshAuth, user } = useApp();
  const router = useRouter();
  const searchParams = useSearchParams();
  const redirectParam = searchParams.get('redirect');
  const safeRedirect =
    redirectParam && redirectParam.startsWith('/') && !redirectParam.startsWith('//')
      ? redirectParam
      : '/';

  const [activeTab, setActiveTab] = useState<'login' | 'register'>('login');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [stage, setStage] = useState(1);

  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState<{ text: string; isError: boolean } | null>(null);
  const [showVerification, setShowVerification] = useState(false);
  const [signedUpEmail, setSignedUpEmail] = useState('');
  const [resending, setResending] = useState(false);

  const [errors, setErrors] = useState<Record<string, string>>({});

  const clearError = (field: string) => {
    setErrors((prev) => {
      const next = { ...prev };
      delete next[field];
      return next;
    });
  };

  React.useEffect(() => {
    if (!user) return;

    let cancelled = false;
    async function finishAuthRedirect() {
      await refreshAuth();
      if (!cancelled) router.replace(safeRedirect);
    }

    void finishAuthRedirect();
    return () => {
      cancelled = true;
    };
  }, [router, safeRedirect, user?.id]);

  const handleSocialLogin = async (provider: 'google') => {
    setLoading(true);
    setMessage(null);
    try {
      const { error } = await supabase.auth.signInWithOAuth({
        provider,
        options: {
          redirectTo:
            typeof window !== 'undefined'
              ? `${window.location.origin}/login?redirect=${encodeURIComponent(safeRedirect)}`
              : undefined,
        },
      });
      if (error) throw error;
    } catch (err: unknown) {
      console.error(err);
      setMessage({ text: err instanceof Error ? err.message : t.errorAuth, isError: true });
      setLoading(false);
    }
  };

  const validateLoginStage = useCallback((): boolean => {
    const newErrors: Record<string, string> = {};
    const emailErr = Validators.email(email, { lang });
    if (emailErr) newErrors.email = emailErr;
    const passErr = Validators.password(password, { lang });
    if (passErr) newErrors.password = passErr;
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  }, [email, password, lang]);

  const validateRegStage = useCallback((): boolean => {
    const newErrors: Record<string, string> = {};
    if (stage === 1) {
      const nameErr = Validators.name(name, { lang });
      if (nameErr) newErrors.name = nameErr;
    } else if (stage === 2) {
      const emailErr = Validators.email(email, { lang });
      if (emailErr) newErrors.email = emailErr;
      const phoneErr = Validators.phone(phone, { lang });
      if (phoneErr) newErrors.phone = phoneErr;
    } else if (stage === 3) {
      const passErr = Validators.password(password, { lang });
      if (passErr) newErrors.password = passErr;
      const confirmErr = Validators.confirmPassword(password, confirmPassword, { lang });
      if (confirmErr) newErrors.confirmPassword = confirmErr;
    }
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  }, [stage, name, email, phone, password, confirmPassword, lang]);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validateLoginStage()) return;

    setLoading(true);
    setMessage(null);

    try {
      const { data, error } = await supabase.auth.signInWithPassword({ email, password });
      if (error) throw error;
      if (data.user) {
        await refreshAuth();
        router.replace(safeRedirect);
      }
    } catch (err: unknown) {
      console.error(err);
      setMessage({ text: err instanceof Error ? err.message : t.errorAuth, isError: true });
    } finally {
      setLoading(false);
    }
  };

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validateRegStage()) return;

    if (stage < 3) {
      setStage((s) => s + 1);
      return;
    }

    setLoading(true);
    setMessage(null);

    try {
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: {
            name,
            phone,
            role: 'student',
          },
        },
      });

      if (error) throw error;

      if (data.user && data.session === null) {
        setSignedUpEmail(email);
        setShowVerification(true);
      } else if (data.user) {
        await refreshAuth();
        router.push(safeRedirect === '/' ? '/interests' : safeRedirect);
      }
    } catch (err: unknown) {
      console.error(err);
      setMessage({ text: err instanceof Error ? err.message : t.errorAuth, isError: true });
    } finally {
      setLoading(false);
    }
  };

  const handleResend = async () => {
    setResending(true);
    try {
      const { error } = await supabase.auth.resend({ type: 'signup', email: signedUpEmail });
      if (error) {
        ToastUtils.showError(error.message);
      } else {
        ToastUtils.showSuccess(
          lang === 'ar'
            ? 'تم إعادة إرسال البريد الإلكتروني'
            : 'Verification email resent'
        );
      }
    } catch {
      ToastUtils.showError(t.errorAuth);
    } finally {
      setResending(false);
    }
  };

  const goBack = () => {
    if (stage > 1) {
      setStage((s) => s - 1);
      setErrors({});
    }
  };

  const ArrowIcon = lang === 'ar' ? ArrowBack : ArrowForward;

  if (showVerification) {
    return (
      <div className={`${styles.authContainer} fade-in`}>
        <div className={`${styles.card} glass`}>
          <div className={styles.verificationCard}>
            <div className={styles.verificationIcon}>
              <MarkEmailUnread fontSize="large" />
            </div>
            <h2 className={styles.verificationTitle}>{t.emailVerification}</h2>
            <p className={styles.verificationEmail}>{signedUpEmail}</p>
            <p className={styles.verificationText}>{t.verificationSent}</p>
            <div className={styles.verificationActions}>
              <Link href="/login">
                <button
                  type="button"
                  className={`${styles.submitBtn} gradient-bg`}
                  onClick={() => {
                    setShowVerification(false);
                    setActiveTab('login');
                    setStage(1);
                    setErrors({});
                    setMessage(null);
                  }}
                >
                  {t.doneGoToLogin}
                </button>
              </Link>
              <button
                type="button"
                className={styles.resendBtn}
                onClick={handleResend}
                disabled={resending}
              >
                {resending ? <span className={styles.spinner} /> : t.resendCode}
              </button>
            </div>
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
            {lang === 'ar' ? 'أحمد يحيى' : 'Ahmed Yahia'}
          </h1>
        </div>

        <div className={styles.tabBar}>
          <button
            type="button"
            className={`${styles.tab} ${activeTab === 'login' ? styles.tabActive : ''}`}
            onClick={() => {
              setActiveTab('login');
              setErrors({});
              setMessage(null);
            }}
          >
            {lang === 'ar' ? 'تسجيل الدخول' : 'Login'}
          </button>
          <button
            type="button"
            className={`${styles.tab} ${activeTab === 'register' ? styles.tabActive : ''}`}
            onClick={() => {
              setActiveTab('register');
              setStage(1);
              setErrors({});
              setMessage(null);
            }}
          >
            {lang === 'ar' ? 'إنشاء حساب' : 'Sign Up'}
          </button>
        </div>

        {message && (
          <div className={`${styles.alert} ${message.isError ? styles.errorAlert : styles.successAlert}`}>
            {message.text}
          </div>
        )}

        {activeTab === 'login' ? (
          <form onSubmit={handleLogin} className={styles.form}>
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

            <div className={styles.inputGroup}>
              <label className={styles.label}>{t.password}</label>
              <div className={styles.inputWrapper}>
                <Lock fontSize="small" className={styles.inputIcon} />
                <input
                  type="password"
                  required
                  value={password}
                  onChange={(e) => { setPassword(e.target.value); clearError('password'); }}
                  placeholder="••••••••"
                  autoComplete="current-password"
                  className={`${styles.input} ${errors.password ? styles.inputError : ''}`}
                />
              </div>
              {errors.password && <span className={styles.fieldError}>{errors.password}</span>}
            </div>

            <div className={styles.forgotRow}>
              <Link href="/forgot-password" className={styles.forgotLink}>
                {t.forgotPassword}
              </Link>
            </div>

            <button type="submit" disabled={loading} className={`${styles.submitBtn} gradient-bg`}>
              {loading ? (
                <span className={styles.spinner}></span>
              ) : (
                <>
                  <LoginIcon fontSize="small" />
                  <span>{t.login}</span>
                </>
              )}
            </button>
          </form>
        ) : (
          <form onSubmit={handleRegister} className={styles.form}>
            <div className={styles.stageDots}>
              {[1, 2, 3, 4].map((dot) => (
                <span
                  key={dot}
                  className={
                    dot === stage
                      ? styles.stageDotActive
                      : dot < stage
                        ? styles.stageDotCompleted
                        : styles.stageDot
                  }
                />
              ))}
            </div>

            {stage === 1 && (
              <div className={styles.inputGroup}>
                <label className={styles.label}>{t.name}</label>
                <div className={styles.inputWrapper}>
                  <Person fontSize="small" className={styles.inputIcon} />
                  <input
                    type="text"
                    required
                    value={name}
                    onChange={(e) => { setName(e.target.value); clearError('name'); }}
                    placeholder={lang === 'ar' ? 'أدخل اسمك الكامل' : 'Enter your full name'}
                    className={`${styles.input} ${errors.name ? styles.inputError : ''}`}
                  />
                </div>
                {errors.name && <span className={styles.fieldError}>{errors.name}</span>}
              </div>
            )}

            {stage === 2 && (
              <>
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

                <div className={styles.inputGroup}>
                  <label className={styles.label}>{t.phone}</label>
                  <div className={styles.countryCodeWrapper}>
                    <span className={styles.countryCode}>+20</span>
                    <div className={styles.inputWrapper}>
                      <Phone fontSize="small" className={styles.inputIcon} />
                      <input
                        type="tel"
                        required
                        value={phone}
                        onChange={(e) => { setPhone(e.target.value); clearError('phone'); }}
                        placeholder={lang === 'ar' ? '01xxxxxxxxx' : '01xxxxxxxxx'}
                        className={`${styles.input} ${styles.phoneInput} ${errors.phone ? styles.inputError : ''}`}
                      />
                    </div>
                  </div>
                  {errors.phone && <span className={styles.fieldError}>{errors.phone}</span>}
                </div>
              </>
            )}

            {stage === 3 && (
              <>
                <div className={styles.inputGroup}>
                  <label className={styles.label}>{t.password}</label>
                  <div className={styles.inputWrapper}>
                    <Lock fontSize="small" className={styles.inputIcon} />
                    <input
                      type="password"
                      required
                      value={password}
                      onChange={(e) => { setPassword(e.target.value); clearError('password'); }}
                      placeholder="••••••••"
                      autoComplete="new-password"
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
              </>
            )}

            {stage === 4 && (
              <button type="submit" disabled={loading} className={`${styles.submitBtn} gradient-bg`}>
                {loading ? (
                  <span className={styles.spinner}></span>
                ) : (
                  <>
                    <span>{t.createAccount}</span>
                    <ArrowIcon fontSize="small" />
                  </>
                )}
              </button>
            )}

            <div className={styles.stageNav}>
              {stage > 1 && (
                <button type="button" className={styles.stageBackBtn} onClick={goBack}>
                  {lang === 'ar' ? <ArrowForward fontSize="small" /> : <ArrowBack fontSize="small" />}
                  {t.backStep}
                </button>
              )}
              {stage < 3 && (
                <button type="submit" className={styles.stageNextBtn}>
                  {t.nextStep}
                  {lang === 'ar' ? <ArrowBack fontSize="small" /> : <ArrowForward fontSize="small" />}
                </button>
              )}
              {stage === 3 && (
                <button type="submit" className={styles.stageNextBtn} disabled={loading}>
                  {loading ? <span className={styles.spinner} /> : t.nextStep}
                </button>
              )}
            </div>
          </form>
        )}

        <div className={styles.divider}>{t.continueWith}</div>

        <div className={styles.socialButtons}>
          <button
            type="button"
            onClick={() => handleSocialLogin('google')}
            disabled={loading}
            className={styles.socialBtn}
            aria-label="Google"
          >
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M23.5 12.28c0-.86-.08-1.68-.22-2.48H12v4.7h6.45c-.28 1.48-1.11 2.74-2.37 3.58v2.98h3.84c2.25-2.07 3.54-5.12 3.54-8.78z" fill="#4285F4"/>
              <path d="M12 24c3.24 0 5.95-1.08 7.93-2.91l-3.84-2.98c-1.07.72-2.44 1.14-4.09 1.14-3.15 0-5.81-2.12-6.76-4.98H1.32v3.08C3.26 21.3 7.32 24 12 24z" fill="#34A853"/>
              <path d="M5.24 14.27c-.24-.72-.38-1.49-.38-2.27s.14-1.55.38-2.27V6.65H1.32C.48 8.24 0 10.06 0 12s.48 3.76 1.32 5.35l3.92-3.08z" fill="#FBBC05"/>
              <path d="M12 4.75c1.77 0 3.35.61 4.6 1.8l3.45-3.45C17.95 1.19 15.24 0 12 0 7.32 0 3.26 2.7 1.32 6.65l3.92 3.08c.95-2.86 3.61-4.98 6.76-4.98z" fill="#EA4335"/>
            </svg>
            Google
          </button>
        </div>
      </div>
    </div>
  );
}

export default function LoginPage() {
  return (
    <Suspense fallback={<div />}>
      <LoginContent />
    </Suspense>
  );
}
