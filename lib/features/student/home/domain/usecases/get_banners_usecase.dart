import 'package:dartz/dartz.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/core/usecase/usecase.dart';
import 'package:lms_platform/features/student/home/domain/entities/banner_entity.dart';
import 'package:lms_platform/features/student/home/domain/repositories/home_repository.dart';

/// Get Banners UseCase
class GetBannersUseCase implements UseCase<List<BannerEntity>> {
  final HomeRepository repository;

  GetBannersUseCase(this.repository);

  @override
  Future<Either<Failure, List<BannerEntity>>> call() {
    return repository.getBanners();
  }
}
