// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lms_platform/core/services/user_role_service.dart';
import 'package:lms_platform/core/shared_widgets/glass_search_bar.dart';
import 'package:lms_platform/core/shared_widgets/responsive_dialog.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/utils/toast_utils.dart';
import 'package:lms_platform/features/student/auth/presentation/cubit/interests_cubit.dart';
import 'package:lms_platform/features/student/auth/presentation/cubit/interests_state.dart';

class InterestsSelectionScreen extends StatefulWidget {
  const InterestsSelectionScreen({super.key});

  @override
  State<InterestsSelectionScreen> createState() =>
      _InterestsSelectionScreenState();
}

class _InterestsSelectionScreenState extends State<InterestsSelectionScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<InterestsCubit>().loadInterests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: BlocListener<InterestsCubit, InterestsState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ToastUtils.showError(state.errorMessage!);
            context.read<InterestsCubit>().clearError();
          }
        },
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(isDark),
              Expanded(
                child: BlocBuilder<InterestsCubit, InterestsState>(
                  builder: (context, state) {
                    if (state.isLoading) {
                      return const Center(
                        child:
                            CircularProgressIndicator(color: AppColors.primary),
                      );
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 24),
                          _buildTitle(isDark),
                          const SizedBox(height: 24),
                          _buildSearchBar(isDark),
                          const SizedBox(height: 32),
                          ...state.filteredCategories.map((category) {
                            return _buildCategorySection(
                              category: category,
                              selectedInterests: state.selectedInterests,
                              isDark: isDark,
                            );
                          }),
                          const SizedBox(height: 16),
                          _buildSuggestion(isDark),
                          const SizedBox(height: 100),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomButton(isDark),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? AppColors.white : AppColors.textMainLight,
            ),
          ),
          // Progress Indicators
          Row(
            children: List.generate(4, (index) {
              final isActive = index <= 1;
              final isCurrent = index == 1;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isCurrent ? 32 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          TextButton(
            onPressed: () async {
              final role = await UserRoleService.getCurrentUserRole();
              if (!mounted) return;
              if (role == 'admin') {
                context.go('/admin');
              } else if (role == 'instructor') {
                context.go('/instructor');
              } else {
                context.go('/home');
              }
            },
            child: Text(
              'common.skip'.tr(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.grey400 : AppColors.grey500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(bool isDark) {
    return Column(
      children: [
        Text(
          'interests.title'.tr(),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.white : AppColors.textMainLight,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'interests.subtitle'.tr(),
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.grey400 : AppColors.grey500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSearchBar(bool _) {
    return GlassSearchBar(
      controller: _searchController,
      hintText: 'interests.search_placeholder'.tr(),
      onChanged: (query) {
        context.read<InterestsCubit>().updateSearch(query);
      },
      height: 52,
      borderRadius: 12,
    );
  }

  Widget _buildCategorySection({
    required dynamic category,
    required Set<String> selectedInterests,
    required bool isDark,
  }) {
    // Get localized name based on current locale
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final categoryName = isArabic ? category.nameAr : category.nameEn;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getCategoryIcon(category.id),
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                categoryName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.white : AppColors.textMainLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: category.interests.map<Widget>((interest) {
              final isSelected = selectedInterests.contains(interest.id);
              return _buildInterestChip(
                interest: interest,
                isSelected: isSelected,
                isDark: isDark,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestChip({
    required dynamic interest,
    required bool isSelected,
    required bool isDark,
  }) {
    // Get localized name based on current locale
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final interestName = isArabic ? interest.nameAr : interest.nameEn;

    return GestureDetector(
      onTap: () {
        context.read<InterestsCubit>().toggleInterest(interest.id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.cardDark : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.grey700 : const Color(0xFFE2E8F0)),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              interestName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.grey300 : AppColors.grey700),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.check_rounded,
                size: 16,
                color: Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestion(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Text(
            'interests.not_found'.tr(),
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.grey400 : AppColors.grey600,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _showSuggestTopicDialog(isDark),
            child: Text(
              'interests.suggest_topic'.tr(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(bool isDark) {
    return BlocBuilder<InterestsCubit, InterestsState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color:
                isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: state.canContinue && !state.isSaving
                    ? () async {
                        final success = await context
                            .read<InterestsCubit>()
                            .saveInterests();
                        if (success && mounted) {
                          // Navigate based on user role
                          final role =
                              await UserRoleService.getCurrentUserRole();
                          if (!mounted) return;
                          if (role == 'admin') {
                            context.go('/admin');
                          } else if (role == 'instructor') {
                            context.go('/instructor');
                          } else {
                            context.go('/home');
                          }
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: state.isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        '${'interests.continue_btn'.tr()} (${state.selectedCount} ${'interests.selected'.tr()})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSuggestTopicDialog(bool isDark) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => ResponsiveDialog(
        title: Text('interests.suggest_dialog_title'.tr()),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'interests.suggest_dialog_hint'.tr(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ToastUtils.showSuccess('interests.suggest_success'.tr());
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('common.submit'.tr()),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String categoryId) {
    switch (categoryId) {
      case 'programming':
        return Icons.code_rounded;
      case 'design':
        return Icons.palette_rounded;
      case 'business':
        return Icons.business_center_rounded;
      case 'marketing':
        return Icons.campaign_rounded;
      case 'photography':
        return Icons.camera_alt_rounded;
      case 'music':
        return Icons.music_note_rounded;
      case 'health':
        return Icons.favorite_rounded;
      case 'language':
        return Icons.translate_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}
