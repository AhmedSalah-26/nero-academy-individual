import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/error_handler.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/network/network_info.dart';

/// Base Repository - Handles common repository logic
abstract class BaseRepository {
  final NetworkInfo networkInfo;

  BaseRepository(this.networkInfo);

  /// Execute a remote call with error handling
  ///
  /// Example usage:
  /// ```dart
  /// Future<Either<Failure, List<Course>>> getCourses() async {
  ///   return safeCall(() => remoteDataSource.getCourses());
  /// }
  /// ```
  Future<Either<Failure, T>> safeCall<T>(
    Future<T> Function() call, {
    bool checkConnection = true,
  }) async {
    // Check network connection
    if (checkConnection && !await networkInfo.isConnected) {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      final result = await call();
      return Right(result);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }

  /// Execute a remote call with cache fallback
  ///
  /// Example usage:
  /// ```dart
  /// Future<Either<Failure, List<Course>>> getCourses() async {
  ///   return safeCallWithCache(
  ///     remoteCall: () => remoteDataSource.getCourses(),
  ///     cacheCall: () => localDataSource.getCachedCourses(),
  ///     saveToCache: (courses) => localDataSource.cacheCourses(courses),
  ///   );
  /// }
  /// ```
  Future<Either<Failure, T>> safeCallWithCache<T>({
    required Future<T> Function() remoteCall,
    required Future<T> Function() cacheCall,
    Future<void> Function(T data)? saveToCache,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteCall();
        if (saveToCache != null) {
          await saveToCache(result);
        }
        return Right(result);
      } catch (e) {
        return Left(ErrorHandler.handle(e).failure);
      }
    } else {
      try {
        final cachedData = await cacheCall();
        return Right(cachedData);
      } catch (e) {
        return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
      }
    }
  }
}
