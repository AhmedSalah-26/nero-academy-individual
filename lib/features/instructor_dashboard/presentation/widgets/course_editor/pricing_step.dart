import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../cubit/course_editor_cubit.dart';

/// Pricing Step - Course price and discount
class PricingStep extends StatefulWidget {
  const PricingStep({super.key});

  @override
  State<PricingStep> createState() => _PricingStepState();
}

class _PricingStepState extends State<PricingStep> {
  late TextEditingController _priceController;
  late TextEditingController _discountPriceController;
  String? _selectedBadge;
  bool _isBadgeEnabled = false;
  bool _isFlashSaleEnabled = false;
  DateTime? _flashSaleStartDate;
  DateTime? _flashSaleEndDate;

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
    _priceController = TextEditingController(
        text: state.price > 0 ? state.price.toString() : '');
    _discountPriceController = TextEditingController(
      text: state.discountPrice?.toString() ?? '',
    );
    _selectedBadge = state.badge;
    _isBadgeEnabled = state.badge != null && state.badge!.isNotEmpty;
    _isFlashSaleEnabled = state.isFlashSale;
    _flashSaleStartDate = state.flashSaleStart;
    _flashSaleEndDate = state.flashSaleEnd;
  }

  @override
  void dispose() {
    _priceController.dispose();
    _discountPriceController.dispose();
    super.dispose();
  }

  void _updateCubit() {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final price = double.tryParse(_priceController.text) ?? 0;
    final parsedDiscountPrice = _discountPriceController.text.isEmpty
        ? null
        : double.tryParse(_discountPriceController.text);

    final hasValidDiscount = parsedDiscountPrice != null &&
        parsedDiscountPrice > 0 &&
        parsedDiscountPrice < price;

    final discountPrice = hasValidDiscount ? parsedDiscountPrice : null;
    final clearDiscountPrice = _discountPriceController.text.trim().isEmpty;

    final badge = _isFlashSaleEnabled
        ? _flashSaleBadge(isArabic)
        : (_isBadgeEnabled ? _selectedBadge : null);
    final clearBadge = !_isFlashSaleEnabled && !_isBadgeEnabled;

    final flashSaleStart = _isFlashSaleEnabled ? _flashSaleStartDate : null;
    final flashSaleEnd = _isFlashSaleEnabled ? _flashSaleEndDate : null;

    context.read<CourseEditorCubit>().updatePricing(
          price: price,
          discountPrice: discountPrice,
          clearDiscountPrice: clearDiscountPrice,
          badge: badge,
          clearBadge: clearBadge,
          isFlashSale: _isFlashSaleEnabled,
          flashSaleStart: flashSaleStart,
          clearFlashSaleStart: !_isFlashSaleEnabled,
          flashSaleEnd: flashSaleEnd,
          clearFlashSaleEnd: !_isFlashSaleEnabled,
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
                isArabic ? 'تسعير الكورس' : 'Course Pricing',
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
                    ? 'حدد سعر الكورس والخصم إن وجد'
                    : 'Set your course price and discount if applicable',
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
                    // Price Section Header
                    Row(
                      children: [
                        const Icon(Icons.payments_outlined,
                            color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isArabic ? 'إعدادات السعر' : 'Price Settings',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildPriceField(
                      controller: _priceController,
                      label: isArabic ? 'السعر الأصلي' : 'Original Price',
                      hint: '0',
                      isDark: isDark,
                      currency: state.currency,
                    ),
                    const SizedBox(height: 16),
                    _buildPriceField(
                      controller: _discountPriceController,
                      label: isArabic
                          ? 'سعر الخصم (اختياري)'
                          : 'Discount Price (Optional)',
                      hint: isArabic ? 'اختياري' : 'Optional',
                      isDark: isDark,
                      currency: state.currency,
                    ),

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
                          isArabic ? 'العروض والشارات' : 'Promotions & Badges',
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
                            final options =
                                isArabic ? _badgeOptionsAr : _badgeOptionsEn;
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
                                    ? 'سعر الفلاش سيل = سعر الخصم. بعد نهاية الوقت يعود السعر الأصلي تلقائيًا.'
                                    : 'Flash sale uses Discount Price. After end time, original price is restored automatically.',
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
                            label: isArabic ? 'تاريخ البداية' : 'Start Date',
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

  Widget _buildPriceField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    required String currency,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => _updateCubit(),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(Icons.monetization_on_outlined,
                size: 20,
                color: isDark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight),
            suffixText: currency,
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

  Widget _buildPricePreview(
      CourseEditorState state, bool isArabic, bool isDark) {
    final hasDiscount =
        state.discountPrice != null && state.discountPrice! < state.price;
    final discountPercentage = hasDiscount
        ? ((state.price - state.discountPrice!) / state.price * 100).round()
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
          if (hasDiscount) ...[
            Text(
              '${state.price.toStringAsFixed(0)} ${state.currency}',
              style: TextStyle(
                decoration: TextDecoration.lineThrough,
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
            Text(
              '${state.discountPrice!.toStringAsFixed(0)} ${state.currency}',
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
              state.price > 0
                  ? '${state.price.toStringAsFixed(0)} ${state.currency}'
                  : (isArabic ? 'مجاني' : 'Free'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPricingTips(bool isArabic, bool isDark) {
    final tips = isArabic
        ? [
            'حدد سعراً تنافسياً بناءً على محتوى الكورس',
            'استخدم الخصومات لجذب المزيد من الطلاب',
            'يمكنك تغيير السعر في أي وقت',
          ]
        : [
            'Set a competitive price based on your course content',
            'Use discounts to attract more students',
            'You can change the price at any time',
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
