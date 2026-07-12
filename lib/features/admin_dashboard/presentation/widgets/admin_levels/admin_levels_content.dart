import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/shared_widgets/loading_skeleton.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/routing/app_router.dart';
import '../../cubit/admin_levels_cubit.dart';
import 'level_list_item.dart';

/// Admin Levels Content
class AdminLevelsContent extends StatefulWidget {
  const AdminLevelsContent({super.key});

  @override
  State<AdminLevelsContent> createState() => _AdminLevelsContentState();
}

class _AdminLevelsContentState extends State<AdminLevelsContent> {
  @override
  void initState() {
    super.initState();
    context.read<AdminLevelsCubit>().loadLevels(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<AdminLevelsCubit, AdminLevelsState>(
      builder: (context, state) {
        return Stack(
          children: [
            Column(
              children: [
                _buildHeader(context, state, isArabic, isDark),
                Expanded(child: _buildLevelsList(context, state, isArabic)),
              ],
            ),
            Positioned(
              bottom: 16,
              right: isArabic ? null : 16,
              left: isArabic ? 16 : null,
              child: FloatingActionButton(
                onPressed: () => _showLevelDialog(context, isArabic),
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AdminLevelsState state,
    bool isArabic,
    bool isDark,
  ) {
    final statusOptions = [
      {'value': 'active', 'label': 'Active', 'labelAr': 'نشط'},
      {'value': 'inactive', 'label': 'Inactive', 'labelAr': 'غير نشط'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: DropdownButton<int>(
            value: state.isActiveFilter == false ? 1 : 0,
            underline: const SizedBox(),
            items: statusOptions.asMap().entries.map((entry) {
              return DropdownMenuItem<int>(
                value: entry.key,
                child: Text(
                  isArabic
                      ? entry.value['labelAr'] as String
                      : entry.value['label'] as String,
                ),
              );
            }).toList(),
            onChanged: (index) {
              if (index != null) {
                context
                    .read<AdminLevelsCubit>()
                    .changeActiveFilter(index == 0 ? true : false);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLevelsList(
    BuildContext context,
    AdminLevelsState state,
    bool isArabic,
  ) {
    if (state.isLoading) {
      return _buildLoadingSkeleton();
    }

    final levels = state.isActiveFilter == false
        ? state.inactiveLevels
        : state.activeLevels;

    if (levels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.layers_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              isArabic ? 'لا توجد مستويات' : 'No levels found',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<AdminLevelsCubit>().loadLevels(
            isActive: state.isActiveFilter,
            refresh: true,
          ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: levels.length,
        itemBuilder: (context, index) {
          final level = levels[index];
          return LevelListItem(
            level: level,
            onEdit: () => _showLevelDialog(context, isArabic, level),
            onToggleStatus: () =>
                context.read<AdminLevelsCubit>().toggleLevelStatus(level.id),
          );
        },
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 8,
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
              LoadingSkeleton(width: 48, height: 48),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoadingSkeleton(height: 16, width: 150),
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

  void _showLevelDialog(BuildContext context, bool isArabic, [dynamic level]) {
    final cubit = context.read<AdminLevelsCubit>();
    AppRouter.goToLevelEditor(
      context,
      level: level,
      onSave: (dto) {
        if (level != null) {
          cubit.updateLevel(level.id, dto);
        } else {
          cubit.createLevel(dto);
        }
      },
    );
  }
}
