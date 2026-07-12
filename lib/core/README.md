# Core Module - دليل الاستخدام

## Error Handling

### استخدام ErrorHandler في Repository

```dart
import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/core.dart';

class CourseRepositoryImpl extends BaseRepository implements CourseRepository {
  final CourseRemoteDataSource remoteDataSource;

  CourseRepositoryImpl(this.remoteDataSource, super.networkInfo);

  @override
  Future<Either<Failure, List<Course>>> getCourses() async {
    return safeCall(() => remoteDataSource.getCourses());
  }

  @override
  Future<Either<Failure, Course>> getCourseById(String id) async {
    return safeCall(() => remoteDataSource.getCourseById(id));
  }

  // مع Cache
  @override
  Future<Either<Failure, List<Course>>> getCoursesWithCache() async {
    return safeCallWithCache(
      remoteCall: () => remoteDataSource.getCourses(),
      cacheCall: () => localDataSource.getCachedCourses(),
      saveToCache: (courses) => localDataSource.cacheCourses(courses),
    );
  }
}
```

### استخدام ErrorHandler مباشرة

```dart
Future<Either<Failure, User>> login(String email, String password) async {
  try {
    final user = await authDataSource.login(email, password);
    return Right(user);
  } catch (e) {
    return Left(ErrorHandler.handle(e).failure);
  }
}
```

## Theme

### الألوان الأساسية

```dart
// Primary
AppColors.primary        // #6F7A3A - الذهبي الأساسي
AppColors.primaryLight   // #8C8B4A - الذهبي الهادئ
AppColors.primaryDark    // #4F5A28 - الذهبي الداكن

// Background
AppColors.backgroundLight  // #F7F6F8 - خلفية Light Mode
AppColors.backgroundDark   // #191022 - خلفية Dark Mode

// Status
AppColors.success  // أخضر
AppColors.error    // أحمر
AppColors.warning  // برتقالي
AppColors.info     // أزرق
```

### استخدام Spacing

```dart
// Padding
Padding(padding: AppSpacing.screenPadding, child: ...)
Padding(padding: AppSpacing.cardPadding, child: ...)

// Gaps
Column(children: [
  Text('Title'),
  AppSpacing.verticalGapMd,
  Text('Subtitle'),
])

// Border Radius
Container(
  decoration: BoxDecoration(
    borderRadius: AppRadius.borderRadiusMd,
  ),
)
```

## Translations

### استخدام الترجمة

```dart
import 'package:easy_localization/easy_localization.dart';

// في الـ Widget
Text('auth.login'.tr())
Text('errors.network'.tr())

// مع parameters
Text('course.students'.tr(args: ['100']))
```

## Toast Messages

```dart
// Success
ToastUtils.showSuccess('تم الحفظ بنجاح');

// Error
ToastUtils.showError('حدث خطأ');

// Warning
ToastUtils.showWarning('تحذير');

// Info
ToastUtils.showInfo('معلومة');

// Network Error
ToastUtils.showNetworkError();
```

## Validators

```dart
TextFormField(
  validator: (value) => Validators.email(value),
)

TextFormField(
  validator: (value) => Validators.password(value, minLength: 8),
)

TextFormField(
  validator: (value) => Validators.required(value, message: 'الاسم مطلوب'),
)
```

## Date & Number Utils

```dart
// Format price
NumberUtils.formatPrice(99.99)  // "99.99 ج.م"

// Format compact number
NumberUtils.formatCompact(1500)  // "1.5K"

// Relative time
AppDateUtils.getRelativeTime(date)  // "منذ 5 دقائق"

// Duration
AppDateUtils.formatDuration(90)  // "1س 30د"
```

