import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/student/cart/domain/entities/coupon_entity.dart';

/// Coupon Section - Professional Design
class CouponSection extends StatefulWidget {
  final CouponEntity? appliedCoupon;
  final bool isLoading;
  final String? error;
  final Function(String) onApply;
  final VoidCallback onRemove;

  const CouponSection({
    super.key,
    this.appliedCoupon,
    this.isLoading = false,
    this.error,
    required this.onApply,
    required this.onRemove,
  });

  @override
  State<CouponSection> createState() => _CouponSectionState();
}

class _CouponSectionState extends State<CouponSection> {
  final _controller = TextEditingController();
  bool _isExpanded = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // If coupon is applied, show applied state
    if (widget.appliedCoupon != null) {
      return _buildAppliedCoupon(isDark);
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.grey200,
        ),
      ),
      child: Column(
        children: [
          // Header - Tap to expand
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_offer_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'cart.enter_coupon'.tr(),
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: isDark ? AppColors.grey400 : AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Expandable input
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildInputSection(isDark),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Input field
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.grey100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.grey300,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !widget.isLoading,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'COUPON2024',
                      hintStyle: TextStyle(
                        color: isDark ? AppColors.grey500 : AppColors.grey400,
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight,
                    ),
                  ),
                ),
                // Apply button
                Container(
                  margin: const EdgeInsets.all(4),
                  child: ElevatedButton(
                    onPressed: widget.isLoading
                        ? null
                        : () {
                            if (_controller.text.trim().isNotEmpty) {
                              widget.onApply(_controller.text.trim());
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 0,
                    ),
                    child: widget.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'cart.apply'.tr(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          // Error message
          if (widget.error != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 14,
                  color: AppColors.error,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.error!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppliedCoupon(bool isDark) {
    final coupon = widget.appliedCoupon!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              coupon.code,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
                letterSpacing: 1,
              ),
            ),
          ),
          // Remove button
          GestureDetector(
            onTap: widget.onRemove,
            child: const Icon(
              Icons.close_rounded,
              color: AppColors.error,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}
