'use client';

import { useApp } from '../../context/AppContext';
import { SectionHeader } from './SectionHeader';
import { VerticalCourseCard, type CourseData } from './VerticalCourseCard';
import { HorizontalCourseCard } from './HorizontalCourseCard';
import styles from './CourseSection.module.css';

interface CourseSectionProps {
  title: string;
  courses: CourseData[];
  locale: string;
  isVertical?: boolean;
  onSeeAll?: string;
  onWishlistToggle: (courseId: string) => void;
}

export function CourseSection({
  title, courses, locale, isVertical, onSeeAll, onWishlistToggle,
}: CourseSectionProps) {
  const { wishlist } = useApp();

  if (courses.length === 0) return null;

  return (
    <div className={styles.section}>
      <SectionHeader title={title} seeAllHref={onSeeAll} />
      {isVertical ? (
        <div className={styles.verticalList}>
          {courses.slice(0, 5).map((course) => (
            <HorizontalCourseCard
              key={course.id}
              course={course}
              isWishlisted={wishlist.includes(course.id)}
              onWishlistToggle={() => onWishlistToggle(course.id)}
            />
          ))}
        </div>
      ) : (
        <div className={styles.horizontalScroll}>
          {courses.map((course) => (
            <VerticalCourseCard
              key={course.id}
              course={course}
              isWishlisted={wishlist.includes(course.id)}
              onWishlistToggle={() => onWishlistToggle(course.id)}
            />
          ))}
        </div>
      )}
    </div>
  );
}
