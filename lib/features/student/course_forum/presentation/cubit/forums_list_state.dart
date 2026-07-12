import 'package:lms_platform/features/student/course_forum/domain/entities/forum_entities.dart';

/// Forums List State
enum ForumsListStatus { initial, loading, success, error }

class InstructorForumCourse {
  final String id;
  final String titleAr;
  final String titleEn;
  final bool hasGroup;

  const InstructorForumCourse({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.hasGroup,
  });

  InstructorForumCourse copyWith({
    String? id,
    String? titleAr,
    String? titleEn,
    bool? hasGroup,
  }) {
    return InstructorForumCourse(
      id: id ?? this.id,
      titleAr: titleAr ?? this.titleAr,
      titleEn: titleEn ?? this.titleEn,
      hasGroup: hasGroup ?? this.hasGroup,
    );
  }
}

class ForumsListState {
  final ForumsListStatus status;
  final List<Conversation> conversations;
  final bool isInstructor;
  final List<InstructorForumCourse> instructorCourses;
  final String? togglingCourseId;
  final String errorMessage;
  final int currentPage;
  final bool hasMore;
  final String? searchQuery;
  final String? typeFilter; // null=all, 'single'=private, 'multi'=group

  const ForumsListState({
    this.status = ForumsListStatus.initial,
    this.conversations = const [],
    this.isInstructor = false,
    this.instructorCourses = const [],
    this.togglingCourseId,
    this.errorMessage = '',
    this.currentPage = 1,
    this.hasMore = true,
    this.searchQuery,
    this.typeFilter,
  });

  ForumsListState copyWith({
    ForumsListStatus? status,
    List<Conversation>? conversations,
    bool? isInstructor,
    List<InstructorForumCourse>? instructorCourses,
    String? togglingCourseId,
    bool clearTogglingCourseId = false,
    String? errorMessage,
    int? currentPage,
    bool? hasMore,
    String? searchQuery,
    String? typeFilter,
    bool clearTypeFilter = false,
  }) {
    return ForumsListState(
      status: status ?? this.status,
      conversations: conversations ?? this.conversations,
      isInstructor: isInstructor ?? this.isInstructor,
      instructorCourses: instructorCourses ?? this.instructorCourses,
      togglingCourseId: clearTogglingCourseId
          ? null
          : (togglingCourseId ?? this.togglingCourseId),
      errorMessage: errorMessage ?? this.errorMessage,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      searchQuery: searchQuery ?? this.searchQuery,
      typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
    );
  }
}
