import type { Metadata } from 'next';
import './globals.css';
import { AppProvider } from '../context/AppContext';
import { Header } from '../components/Header';
import { BottomNavbar } from '../components/BottomNavbar';
import DynamicOfflineIndicator from '../components/DynamicOfflineIndicator';

export const metadata: Metadata = {
  title: 'أحمد يحيى | LAB COAT في الكيمياء',
  description:
    'منصة تعليمية متخصصة في شرح الكيمياء، التدريب، المراجعات، والكويزات مع مستر أحمد يحيى.',
  keywords: ['كيمياء', 'أحمد يحيى', 'LAB COAT', 'كورسات', 'امتحانات', 'مراجعات', 'تعلم'],
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
            <BottomNavbar />
            <footer
              style={{
                textAlign: 'center',
                padding: '28px 20px 92px',
                borderTop: '1px solid var(--border)',
                color: 'var(--text-secondary)',
                fontSize: '0.72rem',
              }}
            >
              <p style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px', flexWrap: 'wrap', margin: 0 }}>
                <span>&copy; {new Date().getFullYear()} أحمد يحيى - LAB COAT. جميع الحقوق محفوظة.</span>
                <span>•</span>
                <a
                  href="https://AhmedSalah-26.github.io/shehabtech-privacy/"
                  target="_blank"
                  rel="noopener noreferrer"
                  style={{ color: 'var(--primary)', textDecoration: 'none', fontWeight: 'bold' }}
                >
                  سياسة الخصوصية / Privacy Policy
                </a>
              </p>
            </footer>
          </div>
        </AppProvider>
      </body>
    </html>
  );
}
