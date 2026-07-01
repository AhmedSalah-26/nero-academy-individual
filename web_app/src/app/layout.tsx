import type { Metadata } from 'next';
import './globals.css';
import { AppProvider } from '../context/AppContext';
import { Header } from '../components/Header';
import DynamicOfflineIndicator from '../components/DynamicOfflineIndicator';

export const metadata: Metadata = {
  title: 'شهاب Tech | منصة التعليم',
  description:
    'منصة تعليمية متكاملة لتقديم الكورسات التدريبية، الكويزات، المنتديات، والمتابعة الأبوية للطلاب.',
  keywords: ['تعليم', 'كورسات', 'دراسة', 'مدرسة', 'امتحانات', 'تعلم', 'شهاب'],
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ar" dir="rtl" data-scroll-behavior="smooth">
      <body>
        <AppProvider>
          <div
            style={{
              display: 'flex',
              flexDirection: 'column',
              minHeight: '100vh',
            }}
          >
            <Header />
            <DynamicOfflineIndicator />
            <main style={{ flex: 1 }}>{children}</main>
            <footer
              style={{
                textAlign: 'center',
                padding: '28px 20px',
                borderTop: '1px solid var(--border)',
                color: 'var(--text-secondary)',
                fontSize: '0.72rem',
              }}
            >
              <p>
                &copy; {new Date().getFullYear()} شهاب Tech. جميع الحقوق محفوظة.
              </p>
            </footer>
          </div>
        </AppProvider>
      </body>
    </html>
  );
}
