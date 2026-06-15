import type { Metadata } from 'next';
import './globals.css';
import { AppProvider } from '../context/AppContext';
import { Header } from '../components/Header';

export const metadata: Metadata = {
  title: 'الأستاذ أحمد الشيخ | منصة الكيمياء للثانوية',
  description:
    'منصة تعليمية متكاملة لتقديم الكورسات التدريبية، الكويزات، المنتديات، والمتابعة الأبوية للطلاب.',
  keywords: ['تعليم', 'كورسات', 'دراسة', 'مدرسة', 'امتحانات', 'كيمياء', 'علوم'],
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ar" dir="rtl">
      <body>
        <div className="ambient-background" aria-hidden="true" />
        <AppProvider>
          <div
            style={{
              display: 'flex',
              flexDirection: 'column',
              minHeight: '100vh',
            }}
          >
            <Header />
            <main style={{ flex: 1 }}>{children}</main>
            <footer
              style={{
                textAlign: 'center',
                padding: '28px 20px 100px',
                borderTop: '1px solid var(--border)',
                color: 'var(--text-secondary)',
                fontSize: '0.72rem',
              }}
            >
              <p>
                &copy; {new Date().getFullYear()} منصة الأستاذ أحمد الشيخ. جميع الحقوق
                محفوظة.
              </p>
            </footer>
          </div>
        </AppProvider>
      </body>
    </html>
  );
}
