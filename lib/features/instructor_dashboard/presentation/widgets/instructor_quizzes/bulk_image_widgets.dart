import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// نوع ترقيم الإجابات
enum AnswerLabelType { numeric, alphabetEn, alphabetAr }

/// نموذج سؤال مؤقت
class ImageQuestionModel {
  final XFile? imageFile;
  int? correctAnswerIndex;
  ImageQuestionModel({this.imageFile});
}

/// Setup Section Widget
class BulkImageSetupSection extends StatelessWidget {
  final AnswerLabelType labelType;
  final int optionsCount;
  final bool isPickingImages;
  final bool isArabic;
  final bool isDark;
  final ValueChanged<AnswerLabelType> onLabelTypeChanged;
  final ValueChanged<int> onOptionsCountChanged;
  final VoidCallback onPickImages;

  const BulkImageSetupSection({
    super.key,
    required this.labelType,
    required this.optionsCount,
    required this.isPickingImages,
    required this.isArabic,
    required this.isDark,
    required this.onLabelTypeChanged,
    required this.onOptionsCountChanged,
    required this.onPickImages,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.photo_library,
                  size: 48, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 24),
          _buildLabelTypeCard(),
          const SizedBox(height: 16),
          _buildOptionsCountCard(),
          const SizedBox(height: 24),
          _buildPickerArea(),
        ],
      ),
    );
  }

  Widget _buildLabelTypeCard() {
    return _SetupCard(
      icon: Icons.abc,
      iconColor: AppColors.info,
      title: isArabic ? 'نوع ترقيم الإجابات' : 'Answer Label Type',
      isDark: isDark,
      child: Row(
        children: [
          _LabelChip(
              '1, 2, 3, 4',
              Icons.format_list_numbered,
              labelType == AnswerLabelType.numeric,
              isDark,
              () => onLabelTypeChanged(AnswerLabelType.numeric)),
          const SizedBox(width: 10),
          _LabelChip(
              'a, b, c, d',
              Icons.abc,
              labelType == AnswerLabelType.alphabetEn,
              isDark,
              () => onLabelTypeChanged(AnswerLabelType.alphabetEn)),
          const SizedBox(width: 10),
          _LabelChip(
              'أ، ب، ج، د',
              Icons.text_fields,
              labelType == AnswerLabelType.alphabetAr,
              isDark,
              () => onLabelTypeChanged(AnswerLabelType.alphabetAr)),
        ],
      ),
    );
  }

  Widget _buildOptionsCountCard() {
    return _SetupCard(
      icon: Icons.format_list_bulleted,
      iconColor: AppColors.warning,
      title: isArabic ? 'عدد الخيارات' : 'Options Count',
      isDark: isDark,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: List.generate(5, (i) {
          final count = i + 2;
          return _CountButton(count, optionsCount == count, isDark,
              () => onOptionsCountChanged(count));
        }),
      ),
    );
  }

  Widget _buildPickerArea() {
    return InkWell(
      onTap: isPickingImages ? null : onPickImages,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.cardDark
              : AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3), width: 2),
        ),
        child: Center(
          child: isPickingImages
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_photo_alternate_outlined,
                          size: 40, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isArabic
                          ? 'اضغط لاختيار صور الأسئلة'
                          : 'Tap to select question images',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isArabic
                          ? 'يمكنك اختيار عدة صور دفعة واحدة'
                          : 'You can select multiple images at once',
                      style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final bool isDark;
  final Widget child;

  const _SetupCard(
      {required this.icon,
      required this.iconColor,
      required this.title,
      required this.isDark,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight)),
          ]),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _LabelChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _LabelChip(
      this.label, this.icon, this.isSelected, this.isDark, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.15)
                : (isDark ? AppColors.surfaceDark : AppColors.grey50),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
                width: isSelected ? 2 : 1),
          ),
          child: Column(children: [
            Icon(icon,
                color: isSelected ? AppColors.primary : Colors.grey, size: 24),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.primary : null),
                textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}

class _CountButton extends StatelessWidget {
  final int count;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _CountButton(this.count, this.isSelected, this.isDark, this.onTap);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.surfaceDark : AppColors.grey100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
              width: isSelected ? 2 : 1),
        ),
        child: Center(
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (isSelected)
              const Icon(Icons.check, size: 16, color: Colors.white),
            if (isSelected) const SizedBox(width: 4),
            Text('$count',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.primary)),
          ]),
        ),
      ),
    );
  }
}
