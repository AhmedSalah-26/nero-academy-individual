import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lms_platform/core/routing/app_router.dart';
import 'package:lms_platform/core/shared_widgets/loading_skeleton.dart';
import 'package:lms_platform/core/shared_widgets/responsive_dialog.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/instructor_dashboard/data/models/banner_model.dart';
import 'package:lms_platform/features/instructor_dashboard/domain/repositories/instructor_repository.dart';
import 'package:lms_platform/features/instructor_dashboard/presentation/cubit/instructor_banners_cubit.dart';
import 'banner_list_item.dart';

/// Instructor Banners Content
class InstructorBannersContent extends StatefulWidget {
  const InstructorBannersContent({super.key});

  @override
  State<InstructorBannersContent> createState() =>
      _InstructorBannersContentState();
}

class _InstructorBannersContentState extends State<InstructorBannersContent> {
  @override
  void initState() {
    super.initState();
    context.read<InstructorBannersCubit>().loadBanners();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return BlocConsumer<InstructorBannersCubit, InstructorBannersState>(
      listener: (context, state) {
        if (state.status == InstructorBannersStatus.error &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
            ),
          );
          context.read<InstructorBannersCubit>().clearError();
        }
      },
      builder: (context, state) {
        return Column(
          children: [
            _buildHeader(context, state, isArabic),
            Expanded(child: _buildBannersList(context, state, isArabic)),
          ],
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    InstructorBannersState state,
    bool isArabic,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Map isActiveFilter (bool?) to drop-down status values
    final currentFilter = state.isActiveFilter == null
        ? 'all'
        : (state.isActiveFilter! ? 'active' : 'inactive');

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: DropdownButton<String>(
              value: currentFilter,
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down_rounded),
              borderRadius: BorderRadius.circular(8),
              items: [
                DropdownMenuItem(
                  value: 'all',
                  child: Row(
                    children: [
                      const Icon(Icons.list_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(isArabic ? 'الكل' : 'All'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'active',
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(isArabic ? 'نشط' : 'Active'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'inactive',
                  child: Row(
                    children: [
                      const Icon(Icons.pause_circle_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(isArabic ? 'غير نشط' : 'Inactive'),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  bool? isActive;
                  if (value == 'active') isActive = true;
                  if (value == 'inactive') isActive = false;
                  context.read<InstructorBannersCubit>().loadBanners(
                        isActive: isActive,
                        refresh: true,
                      );
                }
              },
            ),
          ),
          const Spacer(),
          _buildAddButton(context, isArabic),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, bool isArabic) {
    return ElevatedButton.icon(
      onPressed: () => _showBannerEditor(context, null),
      icon: const Icon(Icons.add_rounded, size: 20),
      label: Text(isArabic ? 'إضافة بانر' : 'Add Banner'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildBannersList(
    BuildContext context,
    InstructorBannersState state,
    bool isArabic,
  ) {
    if (state.status == InstructorBannersStatus.loading &&
        state.banners.isEmpty) {
      return _buildLoadingSkeleton();
    }

    if (state.banners.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              isArabic ? 'لا يوجد بانرات' : 'No banners found',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showBannerEditor(context, null),
              icon: const Icon(Icons.add_rounded),
              label: Text(isArabic ? 'إضافة بانر جديد' : 'Add New Banner'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<InstructorBannersCubit>().loadBanners(
            isActive: state.isActiveFilter,
            refresh: true,
          ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.banners.length,
        itemBuilder: (context, index) {
          final banner = state.banners[index];
          return BannerListItem(
            key: ValueKey(banner.id),
            banner: banner,
            index: index,
            totalCount: state.banners.length,
            onEdit: () => _showBannerEditor(context, banner),
            onToggleStatus: () => context
                .read<InstructorBannersCubit>()
                .toggleBannerStatus(banner),
            onDelete: () => _confirmDelete(context, banner, isArabic),
          );
        },
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.cardDark
                : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.borderDark
                  : AppColors.borderLight,
            ),
          ),
          child: const Row(
            children: [
              LoadingSkeleton(width: 120, height: 68),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoadingSkeleton(height: 18, width: 150),
                    SizedBox(height: 8),
                    LoadingSkeleton(height: 14, width: 200),
                    SizedBox(height: 8),
                    LoadingSkeleton(height: 14, width: 100),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBannerEditor(BuildContext context, BannerModel? banner) {
    AppRouter.goToBannerEditor(
      context,
      banner: banner,
      onSave: (dto) async {
        bool success;
        if (banner == null) {
          success =
              await context.read<InstructorBannersCubit>().createBanner(dto);
        } else {
          success = await context.read<InstructorBannersCubit>().updateBanner(
                banner.id,
                BannerUpdateDto(
                  titleAr: dto.titleAr,
                  titleEn: dto.titleEn,
                  subtitleAr: dto.subtitleAr,
                  subtitleEn: dto.subtitleEn,
                  imageUrl: dto.imageUrl,
                  linkType: dto.linkType,
                  linkValue: dto.linkValue,
                  sortOrder: dto.sortOrder,
                  startDate: dto.startDate,
                  endDate: dto.endDate,
                ),
              );
        }
        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                Localizations.localeOf(context).languageCode == 'ar'
                    ? (banner == null
                        ? 'تم إنشاء البانر بنجاح'
                        : 'تم تحديث البانر بنجاح')
                    : (banner == null
                        ? 'Banner created successfully'
                        : 'Banner updated successfully'),
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
    );
  }

  void _confirmDelete(BuildContext context, BannerModel banner, bool isArabic) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (dialogContext) => ResponsiveAlertDialog(
        title: isArabic ? 'حذف البانر' : 'Delete Banner',
        content: isArabic
            ? 'هل أنت متأكد من حذف البانر "${banner.titleAr}"؟'
            : 'Are you sure you want to delete banner "${banner.titleEn ?? banner.titleAr}"?',
        confirmText: isArabic ? 'حذف' : 'Delete',
        cancelText: isArabic ? 'إلغاء' : 'Cancel',
        isDestructive: true,
        onConfirm: () async {
          Navigator.pop(dialogContext);
          final success = await context
              .read<InstructorBannersCubit>()
              .deleteBanner(banner.id);
          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isArabic
                      ? 'تم حذف البانر بنجاح'
                      : 'Banner deleted successfully',
                ),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
      ),
    );
  }
}
