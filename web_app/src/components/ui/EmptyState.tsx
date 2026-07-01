'use client';

import {
  School,
  ShoppingCart,
  Favorite,
  Search,
  Notifications,
  WorkspacePremium,
  MenuBook,
  People,
  RateReview,
  QuestionAnswer,
  Category,
  Menu,
  StickyNote2,
  Bookmark,
  AttachFile,
  Campaign,
  Quiz,
  Forum,
} from '@mui/icons-material';
import AppButton from './AppButton';
import styles from './EmptyState.module.css';

type EmptyStateType =
  | 'courses'
  | 'cart'
  | 'wishlist'
  | 'search'
  | 'notifications'
  | 'certificates'
  | 'myLearning'
  | 'instructors'
  | 'reviews'
  | 'qa'
  | 'generic'
  | 'lessons'
  | 'notes'
  | 'bookmarks'
  | 'attachments'
  | 'announcements'
  | 'quizzes'
  | 'forum';

const iconMap: Record<EmptyStateType, React.ReactNode> = {
  courses: <School />,
  cart: <ShoppingCart />,
  wishlist: <Favorite />,
  search: <Search />,
  notifications: <Notifications />,
  certificates: <WorkspacePremium />,
  myLearning: <MenuBook />,
  instructors: <People />,
  reviews: <RateReview />,
  qa: <QuestionAnswer />,
  generic: <Category />,
  lessons: <Menu />,
  notes: <StickyNote2 />,
  bookmarks: <Bookmark />,
  attachments: <AttachFile />,
  announcements: <Campaign />,
  quizzes: <Quiz />,
  forum: <Forum />,
};

interface EmptyStateProps {
  type: EmptyStateType;
  title?: string;
  message?: string;
  actionLabel?: string;
  onAction?: () => void;
  compact?: boolean;
  className?: string;
}

export default function EmptyState({
  type,
  title,
  message,
  actionLabel,
  onAction,
  compact = false,
  className,
}: EmptyStateProps) {
  return (
    <div className={`${styles.container} ${compact ? styles.compact : ''} ${className || ''}`}>
      <div className={styles.iconWrapper}>{iconMap[type]}</div>
      {title && <h3 className={styles.title}>{title}</h3>}
      {message && <p className={styles.message}>{message}</p>}
      {actionLabel && onAction && (
        <div className={styles.action}>
          <AppButton variant="primary" size={compact ? 'small' : 'medium'} onClick={onAction}>
            {actionLabel}
          </AppButton>
        </div>
      )}
    </div>
  );
}
