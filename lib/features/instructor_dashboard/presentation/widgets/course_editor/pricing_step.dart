import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/models/course_commerce_models.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../cubit/course_editor_cubit.dart';

/// Pricing Step - Course price and discount
class PricingStep extends StatefulWidget {
  const PricingStep({super.key});

  @override
  State<PricingStep> createState() => _PricingStepState();
}

class _PricingStepState extends State<PricingStep> {

  String? _selectedBadge;
  bool _isBadgeEnabled = false;
  bool _isFlashSaleEnabled = false;
  DateTime? _flashSaleStartDate;
  DateTime? _flashSaleEndDate;
  final List<_PricingOptionControllers> _pricingOptionControllers = [];

  static const List<String> _badgeOptionsAr = [
    'عرض خاص',
    'الأكثر مبيعًا',
    'جديد',
    'الأعلى تقييمًا',
    'لفترة محدودة',
    'خصم اليوم',
  ];

  static const List<String> _badgeOptionsEn = [
    'Special Offer',
    'Best Seller',
    'New',
    'Top Rated',
    'Limited Time',
    'Today Deal',
  ];

  @override
  void initState() {
    super.initState();
    final state = context.read<CourseEditorCubit>().state;
    _selectedBadge = state.badge;
    _isBadgeEnabled = state.badge != null && state.badge!.isNotEmpty;
    _isFlashSaleEnabled = state.isFlashSale;
    _flashSaleStartDate = state.flashSaleStart;
    _flashSaleEndDate = state.flashSaleEnd;
    for (final option in state.pricingOptions) {
      _pricingOptionControllers.add(
        _PricingOptionControllers.fromOption(option),
      );
    }
  }

  @override
  void dispose() {
    for (final option in _pricingOptionControllers) {
      option.dispose();
    }
    super.dispose();
  }

  void _updateCubit() {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final badge = _isFlashSaleEnabled
        ? _flashSaleBadge(isArabic)
        : (_isBadgeEnabled ? _selectedBadge : null);
    final clearBadge = !_isFlashSaleEnabled && !_isBadgeEnabled;

    final flashSaleStart = _isFlashSaleEnabled ? _flashSaleStartDate : null;
    final flashSaleEnd = _isFlashSaleEnabled ? _flashSaleEndDate : null;
    final pricingOptions = _pricingOptionControllers
        .map((option) => option.toOption())
        .where((option) => option.isValid)
        .toList();

    // Price is now defined per subscription option — no global price/discount.
    context.read<CourseEditorCubit>().updatePricing(
          price: 0,
          clearDiscountPrice: true,
          badge: badge,
          clearBadge: clearBadge,
          isFlashSale: _isFlashSaleEnabled,
          flashSaleStart: flashSaleStart,
          clearFlashSaleStart: !_isFlashSaleEnabled,
          flashSaleEnd: flashSaleEnd,
          clearFlashSaleEnd: !_isFlashSaleEnabled,
          pricingOptions: pricingOptions,
        );
  }

  String _flashSaleBadge(bool isArabic) {
    return isArabic ? 'فلاش سيل' : 'Flash Sale';
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<CourseEditorCubit, CourseEditorState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isArabic ? 'تعديل التسعير' : 'Course Pricing',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isArabic
                    ? 'كل اشتراك له سعره الخاص — يُعرض أول اشتراك في صفحة الكورس'
                    : 'Each subscription has its own price — the first is shown on the course page',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
              const SizedBox(height: 32),
              Material(
                  color: isDark ? AppColors.cardDark : AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPricingOptionsSection(isArabic, isDark, state),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Divider(),
                        ),

                        // Promotions Section Header
                        Row(
                          children: [
                            const Icon(Icons.local_offer_outlined,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              isArabic
                                  ? 'العروض والشارات'
                                  : 'Promotions & Badges',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            isArabic
                                ? 'تفعيل الشارة الترويجية'
                                : 'Enable Promotional Badge',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.textMainDark
                                  : AppColors.textMainLight,
                            ),
                          ),
                          subtitle: Text(
                            isArabic
                                ? 'مثل: فلاش سيل، عرض خاص'
                                : 'e.g., Flash Sale, Best Seller',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight,
                            ),
                          ),
                          value: _isBadgeEnabled,
                          activeThumbColor: AppColors.primary,
                          onChanged: (value) {
                            setState(() {
                              _isBadgeEnabled = value;
                              if (!value) {
                                _selectedBadge = null;
                              } else {
                                final options = isArabic
                                    ? _badgeOptionsAr
                                    : _badgeOptionsEn;
                                _selectedBadge ??= options.first;
                              }
                            });
                            _updateCubit();
                          },
                        ),
                        if (_isBadgeEnabled) ...[
                          const SizedBox(height: 16),
                          _buildBadgeDropdown(
                            isDark: isDark,
                            isArabic: isArabic,
                          ),
                        ],

                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),

                        // Flash Sale Section Header
                        Row(
                          children: [
                            const Icon(Icons.flash_on,
                                color: Colors.orange, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              isArabic ? 'عرض الفلاش' : 'Flash Sale',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            isArabic ? 'تفعيل عرض الفلاش' : 'Enable Flash Sale',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.textMainDark
                                  : AppColors.textMainLight,
                            ),
                          ),
                          subtitle: Text(
                            isArabic
                                ? 'خصم لفترة محدودة مع عداد تنازلي'
                                : 'Limited time discount with countdown',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight,
                            ),
                          ),
                          value: _isFlashSaleEnabled,
                          activeThumbColor: Colors.orange,
                          onChanged: (value) {
                            setState(() {
                              _isFlashSaleEnabled = value;
                              if (value) {
                                _isBadgeEnabled = true;
                                _selectedBadge = _flashSaleBadge(isArabic);
                              }
                            });
                            _updateCubit();
                          },
                        ),

                        if (_isFlashSaleEnabled) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Colors.orange,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                     isArabic
                                         ? 'بعد انتهاء وقت الفلاش، يعود سعر الاشتراك العادي تلقائيًا.'
                                         : 'After the flash sale ends, the regular subscription price is restored automatically.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors.textMainDark
                                          : AppColors.textMainLight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildDatePicker(
                                context: context,
                                label:
                                    isArabic ? 'تاريخ البداية' : 'Start Date',
                                selectedDate: _flashSaleStartDate,
                                onTap: () => _selectDate(true),
                                isDark: isDark,
                              ),
                              const SizedBox(width: 16),
                              _buildDatePicker(
                                context: context,
                                label: isArabic ? 'تاريخ النهاية' : 'End Date',
                                selectedDate: _flashSaleEndDate,
                                onTap: () => _selectDate(false),
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 24),
                        _buildPricePreview(state, isArabic, isDark),
                      ],
                    ),
                  )),
              const SizedBox(height: 24),
              _buildPricingTips(isArabic, isDark),
              const SizedBox(height: 32),
              if (!state.isEditing)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () =>
                          context.read<CourseEditorCubit>().setStep(1),
                      icon: Icon(
                          isArabic ? Icons.arrow_forward : Icons.arrow_back),
                      label: Text(isArabic ? 'السابق' : 'Previous'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _updateCubit();
                        context.read<CourseEditorCubit>().setStep(3);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(isArabic ? 'التالي' : 'Next'),
                          const SizedBox(width: 8),
                          Icon(isArabic
                              ? Icons.arrow_back
                              : Icons.arrow_forward),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildBadgeDropdown({
    required bool isDark,
    required bool isArabic,
  }) {
    final options = isArabic ? _badgeOptionsAr : _badgeOptionsEn;
    final currentValue = options.contains(_selectedBadge)
        ? _selectedBadge
        : (options.isNotEmpty ? options.first : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? 'الشارة' : 'Badge',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: currentValue,
          items: options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedBadge = value;
            });
            _updateCubit();
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? AppColors.surfaceDark : AppColors.grey50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPricingOptionsSection(
    bool isArabic,
    bool isDark,
    CourseEditorState state,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.grey50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isArabic ? 'اختيارات الاشتراك' : 'Subscription Options',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _pricingOptionControllers.add(
                      _PricingOptionControllers(
                        label: TextEditingController(),
                        price: TextEditingController(),
                        discountPrice: TextEditingController(),
                        durationDays: TextEditingController(),
                      ),
                    );
                  });
                  _updateCubit();
                },
                icon: const Icon(Icons.add, size: 18),
                label: Text(isArabic ? 'إضافة' : 'Add'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isArabic
                ? 'أضف اختيارات الاشتراك وحدد سعر كل واحد. سيُعرض أول اشتراك في صفحة الكورس.'
                : 'Add subscription options with individual prices. The first one is shown on the course page.',
            style: TextStyle(
              fontSize: 12,
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
          const SizedBox(height: 16),
          if (_pricingOptionControllers.isEmpty)
            Text(
              isArabic
                  ? 'لا توجد اختيارات مضافة.'
                  : 'No subscription options added.',
              style: TextStyle(
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            )
          else
            ..._pricingOptionControllers.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  bottom:
                      index == _pricingOptionControllers.length - 1 ? 0 : 12,
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: isArabic
                            ? AlignmentDirectional.centerStart
                            : AlignmentDirectional.centerEnd,
                        child: IconButton(
                          tooltip: isArabic ? 'حذف' : 'Remove',
                          onPressed: () {
                            setState(() {
                              final removed =
                                  _pricingOptionControllers.removeAt(index);
                              removed.dispose();
                            });
                            _updateCubit();
                          },
                          icon: const Icon(Icons.delete_outline),
                          color: AppColors.error,
                        ),
                      ),
                      _buildCompactTextField(
                        controller: option.label,
                        label: isArabic ? 'الاختيار' : 'Option',
                        hint: isArabic ? '30 يوم' : '30 days',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildCompactTextField(
                        controller: option.price,
                        label: isArabic ? 'السعر' : 'Price',
                        hint: '0',
                        isDark: isDark,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        suffixText: state.currency,
                      ),
                      const SizedBox(height: 12),
                      _buildCompactTextField(
                        controller: option.discountPrice,
                        label: isArabic ? 'سعر الخصم (اختياري)' : 'Discount Price (Optional)',
                        hint: '0',
                        isDark: isDark,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        suffixText: state.currency,
                      ),
                      const SizedBox(height: 12),
                      _buildCompactTextField(
                        controller: option.durationDays,
                        label: isArabic ? 'أيام' : 'Days',
                        hint: '30',
                        isDark: isDark,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? suffixText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: (_) => _updateCubit(),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffixText,
        filled: true,
        fillColor: isDark ? AppColors.cardDark : AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
    );
  }

  Widget _buildPricePreview(
      CourseEditorState state, bool isArabic, bool isDark) {
    // Show first valid pricing option price in preview
    final validOptions = _pricingOptionControllers
        .map((c) => c.toOption())
        .where((o) => o.isValid)
        .toList();
    final firstOption = validOptions.isNotEmpty ? validOptions.first : null;
    final firstOptionPrice = firstOption?.price;
    final firstOptionDiscountPrice = firstOption?.discountPrice;
    final firstOptionLabel = firstOption?.label;

    final hasDiscount = firstOptionDiscountPrice != null &&
        firstOptionPrice != null &&
        firstOptionDiscountPrice < firstOptionPrice;
    final discountPercentage = hasDiscount
        ? ((firstOptionPrice - firstOptionDiscountPrice) /
                firstOptionPrice *
                100)
            .round()
        : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.grey50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(
            Icons.preview_outlined,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
          Text(
            isArabic ? 'معاينة السعر:' : 'Price Preview:',
            style: TextStyle(
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
          if (firstOptionPrice != null && firstOptionPrice > 0) ...[
            if (firstOptionLabel != null && firstOptionLabel.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  firstOptionLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            if (hasDiscount) ...[
              Text(
                '${firstOptionPrice.toStringAsFixed(0)} ${state.currency}',
                style: TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
              Text(
                '${firstOptionDiscountPrice.toStringAsFixed(0)} ${state.currency}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '-$discountPercentage%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ),
            ] else
              Text(
                '${firstOptionPrice.toStringAsFixed(0)} ${state.currency}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
            if (validOptions.length > 1)
              Text(
                isArabic
                    ? '+ ${validOptions.length - 1} اشتراكات أخرى'
                    : '+ ${validOptions.length - 1} more option(s)',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
          ] else
            Text(
              isArabic
                  ? 'أضف اشتراكات لتحديد السعر'
                  : 'Add subscription options to set pricing',
              style: TextStyle(
                fontSize: 14,
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPricingTips(bool isArabic, bool isDark) {
    final tips = isArabic
        ? [
            'كل اشتراك له سعره الخاص — مثلاً: 30 يوم بـ100 جنيه، 60 يوم بـ180 جنيه',
            'يُعرض الاشتراك الأول في صفحة الكورس — رتبهم بالأرخص أولاً',
            'يمكنك تغيير الاشتراكات في أي وقت',
          ]
        : [
            'Each subscription has its own price — e.g., 30 days for 100 EGP',
            'The first subscription is shown on the course page — put the cheapest first',
            'You can update subscription options at any time',
          ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: AppColors.info),
              const SizedBox(width: 8),
              Text(
                isArabic ? 'نصائح التسعير' : 'Pricing Tips',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: AppColors.info)),
                    Expanded(
                      child: Text(
                        tip,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Future<void> _selectDate(bool isStart) async {
    final now = DateTime.now();
    final initialDate = isStart
        ? (_flashSaleStartDate ?? now)
        : (_flashSaleEndDate ??
            (_flashSaleStartDate ?? now).add(const Duration(days: 1)));

    final firstDate = isStart ? now : (_flashSaleStartDate ?? now);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Theme.of(context).cardColor,
              onSurface: Theme.of(context).textTheme.bodyMedium!.color!,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      if (!mounted) return;
      final activeContext = context;

      // Select Time
      final timeOfDay = TimeOfDay.fromDateTime(
          isStart ? (_flashSaleStartDate ?? now) : (_flashSaleEndDate ?? now));

      // ignore: use_build_context_synchronously
      final pickedTime = await showTimePicker(
        // ignore: use_build_context_synchronously
        context: activeContext,
        initialTime: timeOfDay,
        builder: (context, child) {
          return Theme(
            data: Theme.of(activeContext).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                surface: Theme.of(activeContext).cardColor,
                onSurface: Theme.of(activeContext).textTheme.bodyMedium!.color!,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        final fullDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        ).toUtc();

        setState(() {
          if (isStart) {
            _flashSaleStartDate = fullDateTime;
            // Validate End Date
            if (_flashSaleEndDate != null &&
                _flashSaleEndDate!.isBefore(_flashSaleStartDate!)) {
              _flashSaleEndDate = null;
            }
          } else {
            _flashSaleEndDate = fullDateTime;
          }
        });
        _updateCubit();
      }
    }
  }

  Widget _buildDatePicker({
    required BuildContext context,
    required String label,
    required DateTime? selectedDate,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final formattedDate = selectedDate == null
        ? ''
        : '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')} ${selectedDate.hour.toString().padLeft(2, '0')}:${selectedDate.minute.toString().padLeft(2, '0')}';

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.grey50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      formattedDate.isNotEmpty
                          ? formattedDate
                          : (Localizations.localeOf(context).languageCode ==
                                  'ar'
                              ? 'اختر التاريخ'
                              : 'Select Date'),
                      style: TextStyle(
                        color: formattedDate.isNotEmpty
                            ? (isDark
                                ? AppColors.textMainDark
                                : AppColors.textMainLight)
                            : (isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingOptionControllers {
  final TextEditingController label;
  final TextEditingController price;
  final TextEditingController discountPrice;
  final TextEditingController durationDays;

  _PricingOptionControllers({
    required this.label,
    required this.price,
    required this.discountPrice,
    required this.durationDays,
  });

  factory _PricingOptionControllers.fromOption(CoursePricingOption option) {
    return _PricingOptionControllers(
      label: TextEditingController(text: option.label),
      price: TextEditingController(text: option.price.toStringAsFixed(0)),
      discountPrice: TextEditingController(
        text: option.discountPrice?.toStringAsFixed(0) ?? '',
      ),
      durationDays: TextEditingController(
        text: option.durationDays?.toString() ?? '',
      ),
    );
  }

  CoursePricingOption toOption() {
    return CoursePricingOption(
      label: label.text.trim(),
      price: double.tryParse(price.text.trim()) ?? 0,
      discountPrice: double.tryParse(discountPrice.text.trim()),
      durationDays: int.tryParse(durationDays.text.trim()),
    );
  }

  void dispose() {
    label.dispose();
    price.dispose();
    discountPrice.dispose();
    durationDays.dispose();
  }
}
