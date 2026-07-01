import styles from './ShimmerEffect.module.css';

interface ShimmerEffectProps {
  width?: string | number;
  height?: string | number;
  borderRadius?: 'sm' | 'md' | 'lg' | 'xl' | 'full';
  className?: string;
}

export default function ShimmerEffect({
  width = '100%',
  height = '20px',
  borderRadius = 'md',
  className,
}: ShimmerEffectProps) {
  const style: React.CSSProperties = {
    width: typeof width === 'number' ? `${width}px` : width,
    height: typeof height === 'number' ? `${height}px` : height,
  };

  return (
    <div
      className={`${styles.shimmer} ${styles[borderRadius]} ${className || ''}`}
      style={style}
      aria-hidden="true"
    />
  );
}
