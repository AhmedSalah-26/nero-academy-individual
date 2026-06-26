import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/models/course_commerce_models.dart';
import '../../../../core/services/app_logger.dart';
import '../models/cart_item_model.dart';
import '../models/cart_model.dart';
import '../models/coupon_model.dart';
import '../models/order_model.dart';
import '../models/payment_method_model.dart';
import '../../domain/entities/payment_method_entity.dart';

/// Cart Remote Data Source - API calls to Supabase
abstract class CartRemoteDataSource {
  Future<CartModel> getCart(String userId);
  Future<CartItemModel> addToCart(
    String userId,
    String courseId, {
    CoursePricingOption? pricingOption,
  });
  Future<void> removeFromCart(String userId, String cartItemId);
  Future<void> clearCart(String userId);
  Future<CouponModel> applyCoupon(String userId, String couponCode);
  Future<void> removeCoupon(String userId);
  Future<CouponModel> validateCoupon(String couponCode);
  Future<List<SavedPaymentMethodModel>> getSavedPaymentMethods(String userId);
  Future<OrderModel> checkout({
    required String userId,
    required PaymentMethodType paymentMethod,
    String? savedPaymentMethodId,
    Map<String, dynamic>? cardDetails,
    double couponDiscountTotal = 0,
  });
  Future<List<CartItemModel>> getRecommendedCourses(String userId, int limit);
  Future<int> getCartCount(String userId);
}

/// Cart Remote Data Source Implementation
class CartRemoteDataSourceImpl implements CartRemoteDataSource {
  final SupabaseClient supabase;

  CartRemoteDataSourceImpl({required this.supabase});

  @override
  Future<CartModel> getCart(String userId) async {
    try {
      // Fetch active/completed enrollments to filter them out of the cart
      final enrolledResponse = await supabase
          .from('enrollments')
          .select('course_id')
          .eq('user_id', userId)
          .inFilter('status', ['active', 'completed']);

      final enrolledIds = (enrolledResponse as List)
          .map((e) => e['course_id'] as String)
          .toSet();

      // Remove cart items for already-enrolled courses to prevent duplicate key issues
      if (enrolledIds.isNotEmpty) {
        await supabase
            .from('cart_items')
            .delete()
            .eq('user_id', userId)
            .inFilter('course_id', enrolledIds.toList());
      }

      final response = await supabase.from('cart_items').select('''
            *,
            courses (
              id, title_ar, title_en, thumbnail_url, price, discount_price,
              is_flash_sale, flash_sale_start, flash_sale_end,
              currency, is_free, rating, rating_count,
              profiles:instructor_id (name, avatar_url)
            )
          ''').eq('user_id', userId).order('created_at', ascending: false);

      final items = (response as List)
          .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return CartModel.fromItems(userId: userId, items: items, coupon: null);
    } on PostgrestException catch (e) {
      throw ServerException(e.message, code: e.code);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<CartItemModel> addToCart(
    String userId,
    String courseId, {
    CoursePricingOption? pricingOption,
  }) async {
    try {
      // Check if user is already enrolled in this course
      final enrollment = await supabase
          .from('enrollments')
          .select('id, status')
          .eq('user_id', userId)
          .eq('course_id', courseId)
          .maybeSingle();

      if (enrollment != null) {
        final status = enrollment['status'] as String?;
        if (status == 'active' || status == 'completed') {
          throw const ValidationException('cart.already_enrolled');
        } else if (status == 'pending') {
          throw const ValidationException('cart.pending_enrollment');
        }
      }

      final course = await supabase
          .from('courses')
          .select(
              'price, discount_price, is_free, is_flash_sale, flash_sale_start, flash_sale_end, pricing_options')
          .eq('id', courseId)
          .single();

      AppLogger.d('🛒 [AddToCart] Course data: $course');

      final isFree = course['is_free'] == true;
      final discountPrice = course['discount_price'];
      final price = course['price'];
      final isFlashSale = course['is_flash_sale'] == true;
      final flashSaleStart = _parseDateTime(course['flash_sale_start']);
      final flashSaleEnd = _parseDateTime(course['flash_sale_end']);
      final now = DateTime.now();
      final isFlashSaleActive = isFlashSale &&
          (flashSaleStart == null || !now.isBefore(flashSaleStart)) &&
          (flashSaleEnd == null || !now.isAfter(flashSaleEnd));

      AppLogger.d(
          '🛒 [AddToCart] is_free: $isFree, discount_price: $discountPrice, price: $price');

      double priceAtAdd = 0.0;
      if (!isFree) {
        final selectedOption = _resolveSelectedPricingOption(
          pricingOption,
          course['pricing_options'],
        );
        if (selectedOption != null) {
          priceAtAdd = selectedOption.price;
        } else if (discountPrice != null &&
            (!isFlashSale || isFlashSaleActive)) {
          priceAtAdd = double.tryParse(discountPrice.toString()) ?? 0.0;
        } else if (price != null) {
          priceAtAdd = double.tryParse(price.toString()) ?? 0.0;
        }
        // Round to whole number
        priceAtAdd = priceAtAdd.round().toDouble();
      }

      AppLogger.d('🛒 [AddToCart] Final priceAtAdd: $priceAtAdd');

      final response = await supabase.from('cart_items').insert({
        'user_id': userId,
        'course_id': courseId,
        'price_at_add': priceAtAdd,
        if (pricingOption != null) 'pricing_option': pricingOption.toJson(),
      }).select('''
            *,
            courses (
              id, title_ar, title_en, thumbnail_url, price, discount_price,
              is_flash_sale, flash_sale_start, flash_sale_end,
              currency, is_free, rating, rating_count,
              profiles:instructor_id (name, avatar_url)
            )
          ''').single();

      return CartItemModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const ValidationException('Course already in cart');
      }
      throw ServerException(e.message, code: e.code);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> removeFromCart(String userId, String cartItemId) async {
    try {
      await supabase
          .from('cart_items')
          .delete()
          .eq('id', cartItemId)
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw ServerException(e.message, code: e.code);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> clearCart(String userId) async {
    try {
      await supabase.from('cart_items').delete().eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw ServerException(e.message, code: e.code);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<CouponModel> validateCoupon(String couponCode) async {
    try {
      final response = await supabase
          .from('coupons')
          .select()
          .eq('code', couponCode.toUpperCase())
          .eq('is_active', true)
          .single();

      final coupon = CouponModel.fromJson(response);
      if (!coupon.isValid) {
        throw const ValidationException('Coupon is expired or invalid');
      }
      return coupon;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw const NotFoundException('Coupon not found');
      }
      throw ServerException(e.message, code: e.code);
    } catch (e) {
      if (e is ValidationException || e is NotFoundException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<CouponModel> applyCoupon(String userId, String couponCode) async {
    // Coupon validation only - no storage (table doesn't exist)
    return await validateCoupon(couponCode);
  }

  @override
  Future<void> removeCoupon(String userId) async {
    // No-op - coupon storage table doesn't exist yet
  }

  @override
  Future<List<SavedPaymentMethodModel>> getSavedPaymentMethods(
      String userId) async {
    // Payment methods table doesn't exist yet - return empty list
    return [];
  }

  @override
  Future<OrderModel> checkout({
    required String userId,
    required PaymentMethodType paymentMethod,
    String? savedPaymentMethodId,
    Map<String, dynamic>? cardDetails,
    double couponDiscountTotal = 0,
  }) async {
    try {
      AppLogger.i('🛒 [Checkout] Starting checkout for user: $userId');

      // Get cart items
      final cartItems = await supabase
          .from('cart_items')
          .select('course_id, price_at_add, pricing_option')
          .eq('user_id', userId);

      if ((cartItems as List).isEmpty) {
        throw const ServerException('Cart is empty');
      }

      AppLogger.i('🛒 [Checkout] Found ${cartItems.length} items in cart');

      // Pre-flight check: filter out any courses already enrolled (active/completed)
      // to prevent unique constraint violation on enrollments table
      final enrolledCheck = await supabase
          .from('enrollments')
          .select('course_id')
          .eq('user_id', userId)
          .inFilter('status', ['active', 'completed']);

      final alreadyEnrolledIds =
          (enrolledCheck as List).map((e) => e['course_id'] as String).toSet();

      final filteredCartItems = (cartItems as List)
          .where((item) => !alreadyEnrolledIds.contains(item['course_id']))
          .toList();

      if (filteredCartItems.isEmpty) {
        throw const ValidationException(
            'All courses in your cart are already enrolled.');
      }

      // If some items were filtered, clean them from cart silently
      if (filteredCartItems.length < cartItems.length) {
        final toRemove = (cartItems as List)
            .where((item) => alreadyEnrolledIds.contains(item['course_id']))
            .map((item) => item['course_id'] as String)
            .toList();
        await supabase
            .from('cart_items')
            .delete()
            .eq('user_id', userId)
            .inFilter('course_id', toRemove);
        AppLogger.w(
            '🛒 [Checkout] Removed ${toRemove.length} already-enrolled course(s) from cart');
      }

      // ✅ CHECK: منع إرسال طلب جديد لو في طلب pending على نفس الكورسات
      final cartCourseIds =
          filteredCartItems.map((item) => item['course_id'] as String).toList();

      final pendingEnrollments = await supabase
          .from('enrollments')
          .select('course_id')
          .eq('user_id', userId)
          .eq('status', 'pending')
          .inFilter('course_id', cartCourseIds);

      if ((pendingEnrollments as List).isNotEmpty) {
        final pendingCourseIds =
            pendingEnrollments.map((e) => e['course_id'] as String).toList();
        AppLogger.w(
            '🛒 [Checkout] User already has pending orders for: $pendingCourseIds');
        throw const ValidationException(
            'You already have a pending purchase request for one or more of these courses. '
            'Please wait for admin review before submitting again.');
      }

      // Calculate total using current effective prices (considering flash sales)
      double total = 0;
      final List<Map<String, dynamic>> processedItems = [];

      for (final item in filteredCartItems) {
        final courseId = item['course_id'] as String;
        final priceAtAdd = (item['price_at_add'] as num?)?.toDouble() ?? 0;

        // Re-fetch current course price data including flash sale info
        final courseData = await supabase
            .from('courses')
            .select(
                'instructor_id, price, discount_price, is_free, is_flash_sale, flash_sale_start, flash_sale_end, pricing_options')
            .eq('id', courseId)
            .single();

        final instructorId = courseData['instructor_id'] as String?;
        final isFree = courseData['is_free'] == true;
        final price = (courseData['price'] as num?)?.toDouble() ?? 0;
        final discountPrice =
            (courseData['discount_price'] as num?)?.toDouble();
        final isFlashSale = courseData['is_flash_sale'] == true;
        final flashSaleStart = _parseDateTime(courseData['flash_sale_start']);
        final flashSaleEnd = _parseDateTime(courseData['flash_sale_end']);
        final now = DateTime.now();
        final isFlashSaleActive = isFlashSale &&
            (flashSaleStart == null || !now.isBefore(flashSaleStart)) &&
            (flashSaleEnd == null || !now.isAfter(flashSaleEnd));

        final requestedOption = item['pricing_option'] is Map<String, dynamic>
            ? CoursePricingOption.fromJson(
                item['pricing_option'] as Map<String, dynamic>,
              )
            : null;
        final selectedOption = _resolveSelectedPricingOption(
          requestedOption,
          courseData['pricing_options'],
        );

        // Calculate current effective price
        double currentEffectivePrice = 0.0;
        if (!isFree) {
          if (selectedOption != null) {
            currentEffectivePrice = selectedOption.price;
          } else if (discountPrice != null &&
              (!isFlashSale || isFlashSaleActive)) {
            currentEffectivePrice = discountPrice;
          } else {
            currentEffectivePrice = price;
          }
        }

        // Use the lower of price_at_add and current effective price (best deal for user)
        final effectivePrice = isFree
            ? 0.0
            : (currentEffectivePrice < priceAtAdd
                ? currentEffectivePrice
                : priceAtAdd);

        // Round to whole number
        final roundedPrice = effectivePrice.round().toDouble();

        AppLogger.i('🛒 [Checkout] Course $courseId: priceAtAdd=$priceAtAdd, '
            'currentEffective=$currentEffectivePrice, '
            'flashSaleActive=$isFlashSaleActive, '
            'finalPrice=$roundedPrice');

        total += roundedPrice;
        processedItems.add({
          'courseId': courseId,
          'effectivePrice': roundedPrice,
          'originalPrice': price, // Always pass the original course price
          'instructorId': instructorId,
          'pricingOption': item['pricing_option'],
        });
      }

      final finalTotal =
          (total - couponDiscountTotal).clamp(0, double.infinity);
      final isFreeOrder = finalTotal == 0;

      AppLogger.i(
          '🛒 [Checkout] Total amount: $total, couponDiscount: $couponDiscountTotal, finalTotal: $finalTotal');

      // Create parent enrollment first
      final parentEnrollmentResponse = await supabase
          .from('parent_enrollments')
          .insert({
            'user_id': userId,
            'total': finalTotal,
            'subtotal': total,
            'discount': couponDiscountTotal,
            'coupon_discount': couponDiscountTotal,
            'payment_method': isFreeOrder ? 'free' : 'manual',
            'payment_status': isFreeOrder ? 'paid' : 'pending_manual_payment',
            'paid_at': isFreeOrder ? DateTime.now().toIso8601String() : null,
          })
          .select('id')
          .single();

      final parentEnrollmentId = parentEnrollmentResponse['id'] as String;
      AppLogger.i(
          '🛒 [Checkout] Parent enrollment created: $parentEnrollmentId');

      // Distribute coupon discount proportionally across paid items
      for (final item in processedItems) {
        final effectivePrice = item['effectivePrice'] as double;
        if (effectivePrice > 0 && total > 0 && couponDiscountTotal > 0) {
          // Proportional distribution: item's share = (itemPrice / total) * totalCouponDiscount
          final itemCouponDiscount =
              (effectivePrice / total * couponDiscountTotal).round().toDouble();
          item['couponDiscount'] = itemCouponDiscount;
        } else {
          item['couponDiscount'] = 0.0;
        }
      }

      // Create enrollments for each course
      for (final processed in processedItems) {
        final courseId = processed['courseId'] as String;
        final priceAtAdd = processed['effectivePrice'] as double;
        final originalPrice = processed['originalPrice'] as double;
        final instructorId = processed['instructorId'] as String?;
        final pricingOption = processed['pricingOption'];
        final itemCouponDiscount = processed['couponDiscount'] as double;

        AppLogger.i(
            '🛒 [Checkout] Processing course: $courseId, price: $priceAtAdd, originalPrice: $originalPrice, couponDiscount: $itemCouponDiscount');

        final existing = await supabase
            .from('enrollments')
            .select('id, status')
            .eq('user_id', userId)
            .eq('course_id', courseId)
            .maybeSingle();

        if (existing == null) {
          AppLogger.i('🛒 [Checkout] Creating new enrollment...');

          // Create enrollment with pending status if payment required
          final enrollmentResponse = await supabase
              .from('enrollments')
              .insert({
                'user_id': userId,
                'course_id': courseId,
                'instructor_id': instructorId,
                'parent_enrollment_id': parentEnrollmentId,
                'status': isFreeOrder ? 'active' : 'pending',
                'progress_percentage': 0,
                'completed_lessons': 0,
                'price': priceAtAdd,
                'pricing_option': pricingOption,
                'discount': itemCouponDiscount,
                'total_watch_time': 0,
                'enrolled_at': DateTime.now().toIso8601String(),
              })
              .select('id')
              .single();

          final enrollmentId = enrollmentResponse['id'] as String;
          AppLogger.i(
              '🛒 [Checkout] Enrollment created with ID: $enrollmentId');

          // Create instructor earning record (if paid course and has instructor)
          if (priceAtAdd > 0 && instructorId != null) {
            AppLogger.i('🛒 [Checkout] Creating instructor earning record...');

            try {
              // Fetch instructor's revenue_share from instructor_profiles
              double revenueShare = 70.0; // default
              final instructorProfile = await supabase
                  .from('instructor_profiles')
                  .select('revenue_share')
                  .eq('instructor_id', instructorId)
                  .maybeSingle();

              if (instructorProfile != null &&
                  instructorProfile['revenue_share'] != null) {
                revenueShare =
                    (instructorProfile['revenue_share'] as num).toDouble();
              }

              AppLogger.i(
                  '🛒 [Checkout] Instructor revenue_share: $revenueShare%');

              // Calculate earnings based on EFFECTIVE price (after course discount)
              final instructorShare =
                  (priceAtAdd * (revenueShare / 100)).round().toDouble();
              final platformFee = priceAtAdd - instructorShare;

              // Net instructor earning = instructorShare - itemCouponDiscount
              final netInstructorEarning =
                  (instructorShare - itemCouponDiscount)
                      .clamp(0, double.infinity)
                      .toDouble();

              AppLogger.i(
                  '🛒 [Checkout] Earnings: effective=$priceAtAdd, original=$originalPrice, '
                  'share=$instructorShare, fee=$platformFee, couponDiscount=$itemCouponDiscount, '
                  'netEarning=$netInstructorEarning');

              // Note: earnings_transactions will be created automatically by trigger
              // when enrollment status changes to 'active'

              AppLogger.success(
                  '🛒 [Checkout] Instructor earning will be created by trigger! '
                  'Effective=$priceAtAdd, Original=$originalPrice, Share=$instructorShare, '
                  'Fee=$platformFee, CouponDiscount=$itemCouponDiscount, Net=$netInstructorEarning');
            } catch (earningError) {
              AppLogger.e(
                  '🛒 [Checkout] Failed to create instructor earning: $earningError');
              // Don't throw - enrollment was successful, just log the error
            }
          } else {
            AppLogger.w(
                '🛒 [Checkout] Skipping earnings: effectivePrice=$priceAtAdd, instructorId=$instructorId');
          }
        } else {
          final existingStatus = existing['status'] as String?;
          if (existingStatus == 'pending') {
            AppLogger.i(
                '🛒 [Checkout] Updating existing pending enrollment...');
            await supabase.from('enrollments').update({
              'parent_enrollment_id': parentEnrollmentId,
              'status': isFreeOrder ? 'active' : 'pending',
              'price': priceAtAdd,
              'pricing_option': pricingOption,
              'discount': itemCouponDiscount,
              'enrolled_at': DateTime.now().toIso8601String(),
            }).eq('id', existing['id']);
          } else {
            AppLogger.w(
                '🛒 [Checkout] User already enrolled in course $courseId (status: $existingStatus)');
          }
        }
      }

      await supabase.from('cart_items').delete().eq('user_id', userId);
      AppLogger.i('🛒 [Checkout] Cart cleared after order request');

      AppLogger.success('🛒 [Checkout] Checkout completed successfully!');

      return OrderModel.fromJson({
        'id': parentEnrollmentId,
        'user_id': userId,
        'total_amount': finalTotal,
        'currency': 'EGP',
        'status': isFreeOrder ? 'completed' : 'pending',
        'payment_method': isFreeOrder ? 'free' : 'manual',
        'created_at': DateTime.now().toIso8601String(),
      });
    } on PostgrestException catch (e) {
      AppLogger.e(
          '🛒 [Checkout] PostgrestException: ${e.message}, code: ${e.code}');
      throw ServerException(e.message, code: e.code);
    } catch (e) {
      AppLogger.e('🛒 [Checkout] Error: $e');
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<CartItemModel>> getRecommendedCourses(
      String userId, int limit) async {
    try {
      final response = await supabase
          .from('courses')
          .select('''
            id, title_ar, title_en, thumbnail_url, price, discount_price,
            is_flash_sale, flash_sale_start, flash_sale_end,
            currency, is_free, rating, rating_count,
            profiles:instructor_id (name, avatar_url)
          ''')
          .eq('is_published', true)
          .order('enrolled_count', ascending: false)
          .limit(limit);

      return (response as List).map((e) {
        final map = Map<String, dynamic>.from(e as Map<String, dynamic>);
        map['course_id'] = map['id'];
        map['created_at'] = DateTime.now().toIso8601String();
        return CartItemModel.fromJson(map);
      }).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message, code: e.code);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<int> getCartCount(String userId) async {
    try {
      final response =
          await supabase.from('cart_items').select('id').eq('user_id', userId);
      return (response as List).length;
    } on PostgrestException catch (e) {
      throw ServerException(e.message, code: e.code);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  CoursePricingOption? _resolveSelectedPricingOption(
    CoursePricingOption? requested,
    dynamic rawOptions,
  ) {
    if (requested == null) return null;

    final options = parseCoursePricingOptions(rawOptions);
    for (final option in options) {
      final sameLabel = option.label.trim() == requested.label.trim();
      final sameDays = option.durationDays == requested.durationDays;
      final samePrice = option.price.round() == requested.price.round();
      if (sameLabel && sameDays && samePrice) {
        return option;
      }
    }

    throw const ValidationException('Invalid pricing option');
  }
}
