import 'package:equatable/equatable.dart';
import 'package:lms_platform/core/base/base_state.dart';
import 'package:lms_platform/core/errors/failures.dart';
import 'package:lms_platform/features/student/wishlist/domain/entities/wishlist_item_entity.dart';

/// Wishlist Filter Type
enum WishlistFilter {
  all,
  priceDrops,
  enrolled,
}

/// Wishlist State
class WishlistState extends Equatable {
  final StateStatus status;
  final List<WishlistItemEntity> items;
  final WishlistFilter filter;
  final Failure? failure;
  final bool isRemovingItem;
  final String? removingItemId;
  final bool isTogglingItem;
  final String? togglingCourseId;
  final Set<String> wishlistCourseIds;

  const WishlistState({
    this.status = StateStatus.initial,
    this.items = const [],
    this.filter = WishlistFilter.all,
    this.failure,
    this.isRemovingItem = false,
    this.removingItemId,
    this.isTogglingItem = false,
    this.togglingCourseId,
    this.wishlistCourseIds = const {},
  });

  bool get isLoading => status == StateStatus.loading;
  bool get isSuccess => status == StateStatus.success;
  bool get isError => status == StateStatus.error;
  String? get errorMessage => failure?.message;

  bool get isEmpty => filteredItems.isEmpty;
  int get itemsCount => items.length;

  /// Get filtered items based on current filter
  List<WishlistItemEntity> get filteredItems {
    switch (filter) {
      case WishlistFilter.all:
        return items;
      case WishlistFilter.priceDrops:
        return items.where((item) => item.hasPriceDrop).toList();
      case WishlistFilter.enrolled:
        return items.where((item) => item.isEnrolled).toList();
    }
  }

  /// Calculate total value of wishlist
  double get totalValue {
    return items.fold(0, (sum, item) => sum + item.currentPrice);
  }

  /// Calculate total savings
  double get totalSavings {
    return items.fold(0, (sum, item) {
      if (item.discountPrice != null && item.price > item.discountPrice!) {
        return sum + (item.price - item.discountPrice!);
      }
      return sum;
    });
  }

  /// Check if course is in wishlist
  bool isInWishlist(String courseId) => wishlistCourseIds.contains(courseId);

  WishlistState copyWith({
    StateStatus? status,
    List<WishlistItemEntity>? items,
    WishlistFilter? filter,
    Failure? failure,
    bool? isRemovingItem,
    String? removingItemId,
    bool? isTogglingItem,
    String? togglingCourseId,
    Set<String>? wishlistCourseIds,
    bool clearFailure = false,
  }) {
    return WishlistState(
      status: status ?? this.status,
      items: items ?? this.items,
      filter: filter ?? this.filter,
      failure: clearFailure ? null : (failure ?? this.failure),
      isRemovingItem: isRemovingItem ?? this.isRemovingItem,
      removingItemId: removingItemId,
      isTogglingItem: isTogglingItem ?? this.isTogglingItem,
      togglingCourseId: togglingCourseId,
      wishlistCourseIds: wishlistCourseIds ?? this.wishlistCourseIds,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        filter,
        failure,
        isRemovingItem,
        removingItemId,
        isTogglingItem,
        togglingCourseId,
        wishlistCourseIds.toList()
          ..sort(), // Convert to sorted list for proper comparison
      ];
}
