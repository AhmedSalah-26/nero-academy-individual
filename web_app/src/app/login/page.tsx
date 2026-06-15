'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useApp } from '../../context/AppContext';
import { supabase } from '../../lib/supabaseClient';
import { Mail, Lock, User, Phone, LogIn, UserPlus } from 'lucide-react';
import styles from './page.module.css';

export default function LoginPage() {
  const { lang, t, refreshAuth, user } = useApp();
  const router = useRouter();
  
  const [isSignUp, setIsSignUp] = useState(false);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');
  const [role, setRole] = useState<'student' | 'instructor'>('student');
  
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState<{ text: string; isError: boolean } | null>(null);

  React.useEffect(() => {
    if (user) router.replace('/');
  }, [router, user]);

  const handleSocialLogin = async (provider: 'google' | 'apple' | 'facebook') => {
    setLoading(true);
    setMessage(null);
    try {
      const { error } = await supabase.auth.signInWithOAuth({
        provider,
        options: {
          redirectTo: typeof window !== 'undefined' ? window.location.origin : undefined,
        },
      });
      if (error) throw error;
    } catch (err: unknown) {
      console.error(err);
      setMessage({ text: err instanceof Error ? err.message : t.errorAuth, isError: true });
      setLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setMessage(null);

    try {
      if (isSignUp) {
        // Sign Up Flow
        const { data, error } = await supabase.auth.signUp({
          email,
          password,
          options: {
            data: {
              name,
              phone,
              role,
            },
          },
        });

        if (error) throw error;

        if (data.user) {
          void refreshAuth();
          router.push('/interests');
        }
      } else {
        // Sign In Flow
        const { data, error } = await supabase.auth.signInWithPassword({
          email,
          password,
        });

        if (error) throw error;

        if (data.user) {
          router.replace('/');
          void refreshAuth();
        }
      }
    } catch (err: unknown) {
      console.error(err);
      setMessage({ text: err instanceof Error ? err.message : t.errorAuth, isError: true });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className={`${styles.authContainer} fade-in`}>
      <div className={`${styles.card} glass`}>
        <div className={styles.header}>
          <h1 className={`${styles.title} gradient-text`}>
            {isSignUp ? t.signup : t.login}
          </h1>
          <p className={styles.subtitle}>
            {isSignUp ? t.dontHaveAccount : t.alreadyHaveAccount}
          </p>
        </div>

        {message && (
          <div className={`${styles.alert} ${message.isError ? styles.errorAlert : styles.successAlert}`}>
            {message.text}
          </div>
        )}

        <form onSubmit={handleSubmit} className={styles.form}>
          {isSignUp && (
            <>
              <div className={styles.inputGroup}>
                <label className={styles.label}>{t.name}</label>
                <div className={styles.inputWrapper}>
                  <User size={18} className={styles.inputIcon} />
                  <input
                    type="text"
                    required
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    placeholder={lang === 'ar' ? 'أدخل اسمك الكامل' : 'Enter your full name'}
                    className={styles.input}
                  />
                </div>
              </div>

              <div className={styles.inputGroup}>
                <label className={styles.label}>{t.phone}</label>
                <div className={styles.inputWrapper}>
                  <Phone size={18} className={styles.inputIcon} />
                  <input
                    type="tel"
                    required
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    placeholder={lang === 'ar' ? 'أدخل رقم الهاتف' : 'Enter phone number'}
                    className={styles.input}
                  />
                </div>
              </div>

              <div className={styles.inputGroup}>
                <label className={styles.label}>
                  {lang === 'ar' ? 'نوع الحساب' : 'Account Type'}
                </label>
                <div className={styles.roleSelection}>
                  <button
                    type="button"
                    onClick={() => setRole('student')}
                    className={`${styles.roleBtn} ${role === 'student' ? styles.roleBtnActive : ''}`}
                  >
                    {t.studentRole}
                  </button>
                  <button
                    type="button"
                    onClick={() => setRole('instructor')}
                    className={`${styles.roleBtn} ${role === 'instructor' ? styles.roleBtnActive : ''}`}
                  >
                    {t.instructorRole}
                  </button>
                </div>
              </div>
            </>
          )}

          <div className={styles.inputGroup}>
            <label className={styles.label}>{t.email}</label>
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

          <div className={styles.inputGroup}>
            <label className={styles.label}>{t.password}</label>
            <div className={styles.inputWrapper}>
              <Lock size={18} className={styles.inputIcon} />
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className={styles.input}
              />
            </div>
          </div>

          {!isSignUp && (
            <div className={styles.forgotRow}>
              <Link href="/forgot-password" className={styles.forgotLink}>
                {lang === 'ar' ? 'نسيت كلمة المرور؟' : 'Forgot password?'}
              </Link>
            </div>
          )}

          <button type="submit" disabled={loading} className={`${styles.submitBtn} gradient-bg`}>
            {loading ? (
              <span className={styles.spinner}></span>
            ) : isSignUp ? (
              <>
                <UserPlus size={18} />
                <span>{t.signup}</span>
              </>
            ) : (
              <>
                <LogIn size={18} />
                <span>{t.login}</span>
              </>
            )}
          </button>
        </form>

        <div className={styles.toggleState}>
          <button
            type="button"
            onClick={() => setIsSignUp(!isSignUp)}
            className={styles.toggleBtn}
          >
            {isSignUp ? t.alreadyHaveAccount : t.dontHaveAccount}
          </button>
        </div>

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
          <button
            type="button"
            onClick={() => handleSocialLogin('apple')}
            disabled={loading}
            className={styles.socialBtn}
            aria-label="Apple"
          >
            <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
              <path d="M17.05 20.28c-.98.95-2.05.88-3.08.4-1.09-.5-2.09-.48-3.24 0-1.44.62-2.21.44-3.06-.4C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.06 1.87-2.54 6.98.22 8.13-.57 1.5-1.31 2.99-2.27 4.08zm-5.85-15.1c.07-2.04 1.76-3.79 3.74-3.94.29 2.32-1.91 4.96-3.74 3.94z"/>
            </svg>
            Apple
          </button>
          <button
            type="button"
            onClick={() => handleSocialLogin('facebook')}
            disabled={loading}
            className={styles.socialBtn}
            aria-label="Facebook"
          >
            <svg width="18" height="18" viewBox="0 0 24 24" fill="#1877F2" xmlns="http://www.w3.org/2000/svg">
              <path d="M24 12.07C24 5.41 18.63 0 12 0S0 5.41 0 12.07C0 18.1 4.39 23.1 10.12 24v-8.44H7.08v-3.49h3.04V9.41c0-3.02 1.79-4.7 4.53-4.7 1.31 0 2.68.24 2.68.24v2.97h-1.51c-1.49 0-1.95.93-1.95 1.89v2.26h3.33l-.53 3.49h-2.8V24C19.61 23.1 24 18.1 24 12.07z"/>
            </svg>
            Facebook
          </button>
        </div>
      </div>
    </div>
  );
}
