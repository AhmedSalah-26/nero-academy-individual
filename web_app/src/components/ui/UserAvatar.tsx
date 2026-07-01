import Verified from '@mui/icons-material/Verified';
import styles from './UserAvatar.module.css';

interface UserAvatarProps {
  src?: string;
  alt?: string;
  size?: 'xs' | 'sm' | 'md' | 'lg' | 'xl';
  initials?: string;
  verified?: boolean;
  borderColor?: string;
  className?: string;
}

export default function UserAvatar({
  src,
  alt = '',
  size = 'md',
  initials,
  verified = false,
  borderColor,
  className,
}: UserAvatarProps) {
  const style = borderColor ? { borderColor } : undefined;

  const getInitials = (name?: string) => {
    if (!name) return '?';
    const parts = name.trim().split(/\s+/);
    if (parts.length === 1) return parts[0][0];
    return parts[0][0] + parts[parts.length - 1][0];
  };

  return (
    <div
      className={`${styles.avatar} ${styles[size]} ${className || ''}`}
      style={style}
      role="img"
      aria-label={alt}
    >
      {src ? (
        <img className={styles.image} src={src} alt={alt} />
      ) : (
        <span className={styles.initials}>{initials || getInitials(alt)}</span>
      )}
      {verified && (
        <span className={styles.verifiedBadge}>
          <Verified sx={{ fontSize: 'inherit' }} />
        </span>
      )}
    </div>
  );
}
