import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lms_platform/features/student/auth/domain/usecases/update_interests_usecase.dart';
import 'interests_state.dart';

class InterestsCubit extends Cubit<InterestsState> {
  final UpdateInterestsUseCase _updateInterestsUseCase;

  InterestsCubit({
    required UpdateInterestsUseCase updateInterestsUseCase,
  })  : _updateInterestsUseCase = updateInterestsUseCase,
        super(const InterestsState());

  /// Load available interests
  void loadInterests() {
    emit(state.copyWith(isLoading: true));

    // Static interests data - in production, fetch from API
    final categories = [
      const InterestCategory(
        id: 'development',
        nameAr: 'البرمجة والتطوير',
        nameEn: 'Development',
        interests: [
          Interest(id: 'python', nameAr: 'Python', nameEn: 'Python'),
          Interest(
              id: 'web_dev', nameAr: 'تطوير الويب', nameEn: 'Web Development'),
          Interest(id: 'ml', nameAr: 'تعلم الآلة', nameEn: 'Machine Learning'),
          Interest(id: 'react', nameAr: 'React', nameEn: 'React'),
          Interest(id: 'flutter', nameAr: 'Flutter', nameEn: 'Flutter'),
          Interest(id: 'swift', nameAr: 'SwiftUI', nameEn: 'SwiftUI'),
          Interest(id: 'nodejs', nameAr: 'Node.js', nameEn: 'Node.js'),
          Interest(id: 'java', nameAr: 'Java', nameEn: 'Java'),
        ],
      ),
      const InterestCategory(
        id: 'business',
        nameAr: 'الأعمال',
        nameEn: 'Business',
        interests: [
          Interest(id: 'finance', nameAr: 'المالية', nameEn: 'Finance'),
          Interest(id: 'leadership', nameAr: 'القيادة', nameEn: 'Leadership'),
          Interest(id: 'marketing', nameAr: 'التسويق', nameEn: 'Marketing'),
          Interest(id: 'startup', nameAr: 'ريادة الأعمال', nameEn: 'Startup'),
          Interest(id: 'management', nameAr: 'الإدارة', nameEn: 'Management'),
        ],
      ),
      const InterestCategory(
        id: 'design',
        nameAr: 'التصميم',
        nameEn: 'Design',
        interests: [
          Interest(id: 'ui_ux', nameAr: 'UI/UX', nameEn: 'UI/UX Design'),
          Interest(
              id: 'graphic',
              nameAr: 'التصميم الجرافيكي',
              nameEn: 'Graphic Design'),
          Interest(
              id: '3d',
              nameAr: 'النمذجة ثلاثية الأبعاد',
              nameEn: '3D Modeling'),
          Interest(
              id: 'illustration',
              nameAr: 'الرسم التوضيحي',
              nameEn: 'Illustration'),
          Interest(
              id: 'motion', nameAr: 'موشن جرافيك', nameEn: 'Motion Graphics'),
        ],
      ),
      const InterestCategory(
        id: 'personal',
        nameAr: 'التطوير الشخصي',
        nameEn: 'Personal Development',
        interests: [
          Interest(
              id: 'productivity', nameAr: 'الإنتاجية', nameEn: 'Productivity'),
          Interest(
              id: 'communication', nameAr: 'التواصل', nameEn: 'Communication'),
          Interest(id: 'languages', nameAr: 'اللغات', nameEn: 'Languages'),
          Interest(id: 'photography', nameAr: 'التصوير', nameEn: 'Photography'),
        ],
      ),
    ];

    emit(state.copyWith(
      categories: categories,
      isLoading: false,
    ));
  }

  /// Toggle interest selection
  void toggleInterest(String interestId) {
    final selected = Set<String>.from(state.selectedInterests);

    if (selected.contains(interestId)) {
      selected.remove(interestId);
    } else {
      selected.add(interestId);
    }

    emit(state.copyWith(selectedInterests: selected));
  }

  /// Update search query
  void updateSearch(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  /// Save selected interests
  Future<bool> saveInterests() async {
    if (!state.canContinue) return false;

    emit(state.copyWith(isSaving: true));

    final result = await _updateInterestsUseCase(
      state.selectedInterests.toList(),
    );

    return result.fold(
      (failure) {
        emit(state.copyWith(
          isSaving: false,
          errorMessage: failure.message,
        ));
        return false;
      },
      (_) {
        emit(state.copyWith(isSaving: false));
        return true;
      },
    );
  }

  /// Clear error
  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }
}
