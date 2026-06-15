'use client';

import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Lock, CheckCircle } from 'lucide-react';
import { supabase } from '../../lib/supabaseClient';
import { useApp } from '../../context/AppContext';
import styles from '../login/page.module.css';

export default function ResetPasswordPage() {
  const { lang } = useApp();
  const router = useRouter();
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [loading, setLoading] = useState(false);
  const [done, setDone] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    // Supabase sends the session in the hash fragment; parse it automatically
    supabase.auth.onAuthStateChange((event) => {
      if (event === 'PASSWORD_RECOVERY') {
        // ready to update password
      }
    });
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (password !== confirm) {
      setError(lang === 'ar' ? 'كلمتا المرور غير متطابقتين' : 'Passwords do not match');
      return;
    }

    setLoading(true);
    setError('');

    const { error: updateError } = await supabase.auth.updateUser({ password });

    if (updateError) {
      setError(updateError.message);
    } else {
      setDone(true);
      setTimeout(() => router.push('/login'), 2000);
    }

    setLoading(false);
  };

  return (
    <div className={`${styles.authContainer} fade-in`}>
      <div className={`${styles.card} glass`}>
        <div className={styles.header}>
          <h1 className={`${styles.title} gradient-text`}>
            {lang === 'ar' ? 'كلمة مرور جديدة' : 'New Password'}
          </h1>
        </div>

        {done ? (
          <div className={styles.successAlert}>
            <CheckCircle size={24} />
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
              <label className={styles.label}>{lang === 'ar' ? 'كلمة المرور الجديدة' : 'New Password'}</label>
              <div className={styles.inputWrapper}>
                <Lock size={18} className={styles.inputIcon} />
                <input
                  type="password"
                  required
                  minLength={6}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className={styles.input}
                />
              </div>
            </div>

            <div className={styles.inputGroup}>
              <label className={styles.label}>{lang === 'ar' ? 'تأكيد كلمة المرور' : 'Confirm Password'}</label>
              <div className={styles.inputWrapper}>
                <Lock size={18} className={styles.inputIcon} />
                <input
                  type="password"
                  required
                  minLength={6}
                  value={confirm}
                  onChange={(e) => setConfirm(e.target.value)}
                  className={styles.input}
                />
              </div>
            </div>

            <button type="submit" disabled={loading} className={`${styles.submitBtn} gradient-bg`}>
              {loading ? <span className={styles.spinner}></span> : (lang === 'ar' ? 'تحديث كلمة المرور' : 'Update Password')}
            </button>
          </form>
        )}
      </div>
    </div>
  );
}
