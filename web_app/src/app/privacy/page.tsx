import Link from 'next/link';
import styles from '../settings/legal.module.css';

export default function PrivacyPage() {
  return <main className={styles.page}><Link href="/settings">العودة للإعدادات</Link><h1>سياسة الخصوصية</h1><p>نحمي بيانات حسابك ونستخدمها فقط لتقديم تجربة التعلم، متابعة تقدمك، وتنفيذ الخدمات التي تطلبها.</p><h2>البيانات التي نجمعها</h2><p>بيانات الحساب، الكورسات المسجلة، تقدم الدروس، وإعدادات الاستخدام.</p><h2>حماية البيانات</h2><p>لا نشارك بياناتك الشخصية مع أطراف خارجية إلا عند الحاجة لتقديم الخدمة أو الالتزام بالقانون.</p></main>;
}
