'use client';

import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import { supabase } from '../../lib/supabaseClient';
import { Mail as MailIcon, Person, TrendingUp } from '@mui/icons-material';
import { usePageTransition } from '../../lib/animations';
import styles from './page.module.css';

interface StudentProfile {
  id: string;
  name: string;
  email: string;
}

interface StudentEnrollment {
  id: string;
  progress_percentage: number;
  completed_lessons: number;
  last_accessed_at: string;
  courses: {
    title_ar: string;
    title_en: string;
    total_lessons: number;
  };
}

export default function ParentPortalPage() {
  const pageRef = usePageTransition();
  const { lang, t } = useApp();

  const [studentEmail, setStudentEmail] = useState('');
  const [student, setStudent] = useState<StudentProfile | null>(null);
  const [enrollments, setEnrollments] = useState<StudentEnrollment[]>([]);
  const [searched, setSearched] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSearch = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!studentEmail) return;

    setLoading(true);
    setError(null);
    setStudent(null);
    setEnrollments([]);
    setSearched(true);

    try {
      // 1. Find the student by email in the profiles table
      const { data: profileData, error: profileError } = await supabase
        .from('profiles')
        .select('id, name, email, role')
        .eq('email', studentEmail.trim().toLowerCase())
        .single();

      if (profileError || !profileData) {
        setError(t.noStudentFound);
        setLoading(false);
        return;
      }

      // Check role - only student progress monitoring is allowed
      if (profileData.role !== 'student') {
        setError(t.noStudentFound);
        setLoading(false);
        return;
      }

      setStudent(profileData as StudentProfile);

      // 2. Fetch the student's active course enrollments and progress
      const { data: enrollData, error: enrollError } = await supabase
        .from('enrollments')
        .select(`
          id,
          progress_percentage,
          completed_lessons,
          last_accessed_at,
          courses (
            title_ar,
            title_en,
            total_lessons
          )
        `)
        .eq('user_id', profileData.id)
        .in('status', ['active', 'completed']);

      if (enrollData && !enrollError) {
        setEnrollments(enrollData as unknown as StudentEnrollment[]);
      }
    } catch (err) {
      console.error('Error looking up student:', err);
      setError(t.noStudentFound);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div ref={pageRef} className="container fade-in">
      <div className={styles.header}>
        <h1 className={styles.pageTitle}>{t.parentPortalTitle}</h1>
        <p className={styles.subtitle}>{t.parentDescription}</p>
      </div>

      {/* Lookup Form */}
      <div className={`${styles.searchCard} glass`}>
        <form onSubmit={handleSearch} className={styles.searchForm}>
          <div className={styles.inputWrapper}>
            <MailIcon fontSize="small" className={styles.mailIcon} />
            <input
              type="email"
              required
              placeholder={t.studentEmail}
              value={studentEmail}
              onChange={(e) => setStudentEmail(e.target.value)}
              className={styles.input}
            />
          </div>
          <button type="submit" disabled={loading} className={`${styles.searchBtn} gradient-bg`}>
            {loading ? <span className={styles.spinner}></span> : <span>{t.search}</span>}
          </button>
        </form>
      </div>

      {/* Results Viewport */}
      {searched && !loading && (
        <div className={styles.resultsSection}>
          {error ? (
            <div className={`${styles.errorAlert} glass`}>
              <span>{error}</span>
            </div>
          ) : (
            student && (
              <div className={`${styles.reportCard} glass`}>
                <div className={styles.studentInfo}>
                  <div className={styles.avatarPlaceholder}>
                    <Person fontSize="large" />
                  </div>
                  <div>
                    <h2 className={styles.studentName}>{student.name}</h2>
                    <span className={styles.studentEmailText}>{student.email}</span>
                  </div>
                </div>

                <h3 className={styles.reportTitle}>{t.studentProgressReport}</h3>

                {enrollments.length === 0 ? (
                  <p className={styles.noEnrollments}>
                    {lang === 'ar' 
                      ? 'هذا الطالب غير مسجل في أي كورس حالياً.' 
                      : 'This student is not enrolled in any courses.'}
                  </p>
                ) : (
                  <div className={styles.progressList}>
                    {enrollments.map((enroll) => (
                      <div key={enroll.id} className={styles.progressItem}>
                        <div className={styles.progressDetails}>
                          <h4 className={styles.courseTitle}>
                            {lang === 'ar' ? enroll.courses.title_ar : enroll.courses.title_en}
                          </h4>
                          <span className={styles.statsLabel}>
                            {enroll.completed_lessons} / {enroll.courses.total_lessons || 0} {t.lessonsCount}
                          </span>
                        </div>

                        {/* Progress bar layout */}
                        <div className={styles.barContainer}>
                          <div className={styles.progressBarBg}>
                            <div 
                              className={styles.progressBarFill} 
                              style={{ width: `${enroll.progress_percentage}%` }}
                            ></div>
                          </div>
                          <span className={styles.percentageText}>
                            {Math.round(enroll.progress_percentage)}%
                          </span>
                        </div>

                        <div className={styles.footerRow}>
                          <TrendingUp fontSize="small" className={styles.footerIcon} />
                          <span>
                            {t.lastAccessed}: {enroll.last_accessed_at ? new Date(enroll.last_accessed_at).toLocaleDateString() : 'N/A'}
                          </span>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            )
          )}
        </div>
      )}
    </div>
  );
}
