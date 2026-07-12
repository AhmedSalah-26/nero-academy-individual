import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lms_platform/core/base/base_state.dart';
import 'package:lms_platform/core/services/app_logger.dart';
import 'package:lms_platform/features/student/wishlist/domain/entities/wishlist_item_entity.dart';
import 'package:lms_platform/features/student/wishlist/domain/usecases/get_wishlist_usecase.dart';
import 'package:lms_platform/features/student/wishlist/domain/usecases/add_to_wishlist_usecase.dart';
import 'package:lms_platform/features/student/wishlist/domain/usecases/remove_from_wishlist_usecase.dart';
import 'package:lms_platform/features/student/wishlist/domain/usecases/toggle_wishlist_usecase.dart';
import 'package:lms_platform/features/student/wishlist/domain/repositories/wishlist_repository.dart';
import 'wishlist_state.dart';

/// Wishlist Cubit - Manages wishlist state
class WishlistCubit extends Cubit<WishlistState> {
  final GetWishlistUseCase getWishlistUseCase;
  final AddToWishlistUseCase addToWishlistUseCase;
  final RemoveFromWishlistUseCase removeFromWishlistUseCase;
  final ToggleWishlistUseCase toggleWishlistUseCase;
  final WishlistRepository wishlistRepository;

  WishlistCubit({
    required this.getWishlistUseCase,
    required this.addToWishlistUseCase,
    required this.removeFromWishlistUseCase,
    required this.toggleWishlistUseCase,
    required this.wishlistRepository,
  }) : super(const WishlistState());

  String? _currentUserId;

  /// Get current user ID
  String? get currentUserId => _currentUserId;

  /// Safe emit - only emit if not closed
  void _safeEmit(WishlistState newState) {
    if (!isClosed) {
      emit(newState);
    }
  }

  /// Set user ID without loading wishlist
  void setUserId(String userId) {
    AppLogger.i('❤️ [WishlistCubit] Setting userId: $userId');
    _currentUserId = userId;
  }

  /// Load wishlist
  Future<void> loadWishlist(String userId) async {
    AppLogger.i('❤️ [WishlistCubit] Loading wishlist for user: $userId');
    _currentUserId = userId;

    // Show loading state
    _safeEmit(state.copyWith(status: StateStatus.loading));

    final result = await getWishlistUseCase(GetWishlistParams(userId: userId));

    result.fold(
      (failure) {
        AppLogger.e(
            '[WishlistCubit] Failed to load wishlist: ${failure.message}');
        _safeEmit(state.copyWith(
          status: StateStatus.error,
          failure: failure,
        ));
      },
      (items) {
        AppLogger.success('[WishlistCubit] Wishlist loaded: ${items.length}');
        final courseIds = items.map((e) => e.courseId).toSet();
        _safeEmit(state.copyWith(
          status: StateStatus.success,
          items: items,
          wishlistCourseIds: courseIds,
        ));
      },
    );
  }

  /// Refresh wishlist
  Future<void> refreshWishlist() async {
    if (_currentUserId != null) {
      await loadWishlist(_currentUserId!);
    }
  }

  /// Set filter
  void setFilter(WishlistFilter filter) {
    _safeEmit(state.copyWith(filter: filter));
  }

  /// Toggle wishlist for a course (add/remove) with optimistic update
  Future<bool?> toggleWishlist(String courseId) async {
    AppLogger.i('❤️ [WishlistCubit] Toggling wishlist for course: $courseId');

    if (_currentUserId == null) {
      AppLogger.e('[WishlistCubit] Cannot toggle: userId is null!');
      return null;
    }

    // Optimistic update - update UI immediately
    final wasInWishlist = state.wishlistCourseIds.contains(courseId);
    final Set<String> optimisticIds = {...state.wishlistCourseIds};

    if (wasInWishlist) {
      optimisticIds.remove(courseId);
    } else {
      optimisticIds.add(courseId);
    }

    AppLogger.i(
        '[WishlistCubit] Optimistic update: wasIn=$wasInWishlist, newIds=${optimisticIds.length}');

    _safeEmit(state.copyWith(
      wishlistCourseIds: optimisticIds,
      isTogglingItem: true,
      togglingCourseId: courseId,
    ));

    final result = await toggleWishlistUseCase(
      ToggleWishlistParams(userId: _currentUserId!, courseId: courseId),
    );

    return result.fold(
      (failure) {
        AppLogger.e('[WishlistCubit] Failed to toggle: ${failure.message}');
        // Revert optimistic update on failure
        final Set<String> revertedIds = {...state.wishlistCourseIds};
        if (wasInWishlist) {
          revertedIds.add(courseId);
        } else {
          revertedIds.remove(courseId);
        }
        _safeEmit(state.copyWith(
          wishlistCourseIds: revertedIds,
          isTogglingItem: false,
          togglingCourseId: null,
        ));
        return null;
      },
      (isAdded) {
        AppLogger.success(
            '[WishlistCubit] Toggle success: ${isAdded ? "added" : "removed"}');

        // Update items list if removed
        final List<WishlistItemEntity> updatedItems = [...state.items];
        if (!isAdded) {
          updatedItems.removeWhere((item) => item.courseId == courseId);
        }

        _safeEmit(state.copyWith(
          items: updatedItems,
          isTogglingItem: false,
          togglingCourseId: null,
        ));

        return isAdded;
      },
    );
  }

  /// Remove item from wishlist by item ID
  Future<void> removeFromWishlist(String wishlistItemId) async {
    if (_currentUserId == null) return;
    if (state.items.isEmpty) return;

    AppLogger.i('❤️ [WishlistCubit] Removing item: $wishlistItemId');

    // Find the item first
    final itemToRemove =
        state.items.where((item) => item.id == wishlistItemId).firstOrNull;
    if (itemToRemove == null) {
      AppLogger.w('[WishlistCubit] Item not found: $wishlistItemId');
      return;
    }

    _safeEmit(
        state.copyWith(isRemovingItem: true, removingItemId: wishlistItemId));

    final result = await removeFromWishlistUseCase(
      RemoveFromWishlistParams(
        userId: _currentUserId!,
        wishlistItemId: wishlistItemId,
      ),
    );

    result.fold(
      (failure) {
        AppLogger.e('[WishlistCubit] Failed to remove: ${failure.message}');
        _safeEmit(state.copyWith(isRemovingItem: false, removingItemId: null));
      },
      (_) {
        AppLogger.success('[WishlistCubit] Item removed');

        final updatedItems =
            state.items.where((item) => item.id != wishlistItemId).toList();
        final Set<String> updatedIds = {...state.wishlistCourseIds};
        updatedIds.remove(itemToRemove.courseId);

        _safeEmit(state.copyWith(
          items: updatedItems,
          wishlistCourseIds: updatedIds,
          isRemovingItem: false,
          removingItemId: null,
        ));
      },
    );
  }

  /// Check if course is in wishlist
  bool isInWishlist(String courseId) {
    return state.wishlistCourseIds.contains(courseId);
  }

  /// Clear wishlist
  Future<void> clearWishlist() async {
    if (_currentUserId == null) return;

    AppLogger.i('❤️ [WishlistCubit] Clearing wishlist');
    // Don't show loading state when clearing - just clear items directly

    final result = await wishlistRepository.clearWishlist(_currentUserId!);

    result.fold(
      (failure) {
        AppLogger.e('[WishlistCubit] Failed to clear: ${failure.message}');
        _safeEmit(state.copyWith(
          status: StateStatus.error,
          failure: failure,
        ));
      },
      (_) {
        AppLogger.success('[WishlistCubit] Wishlist cleared');
        _safeEmit(state.copyWith(
          status: StateStatus.success,
          items: const [],
          wishlistCourseIds: const {},
        ));
      },
    );
  }
}
