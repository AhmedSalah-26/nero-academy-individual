import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:lms_platform/core/shared_widgets/dashboard/dashboard_widgets.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/admin_dashboard/data/models/admin_teacher_subscription_model.dart';
import 'package:lms_platform/features/admin_dashboard/presentation/cubit/admin_teacher_subscriptions_cubit.dart';

class AdminTeacherSubscriptionsContent extends StatefulWidget {
  const AdminTeacherSubscriptionsContent({super.key});

  @override
  State<AdminTeacherSubscriptionsContent> createState() =>
      _AdminTeacherSubscriptionsContentState();
}

class _AdminTeacherSubscriptionsContentState
    extends State<AdminTeacherSubscriptionsContent> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<AdminTeacherSubscriptionsCubit>().loadTeachers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 160) {
      context.read<AdminTeacherSubscriptionsCubit>().loadMoreTeachers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return BlocConsumer<AdminTeacherSubscriptionsCubit,
        AdminTeacherSubscriptionsState>(
      listener: (context, state) {
        if (state.actionStatus == AdminTeacherSubscriptionsStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isArabic
                  ? 'تم تحديث الاشتراك بنجاح'
                  : 'Subscription updated successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (state.actionStatus ==
            AdminTeacherSubscriptionsStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Something went wrong'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: DashboardSearchBar(
                hintText: 'Search teachers...',
                hintTextAr: 'ابحث عن مدرس...',
                onSearch: (query) {
                  context
                      .read<AdminTeacherSubscriptionsCubit>()
                      .loadTeachers(search: query.isEmpty ? null : query);
                },
              ),
            ),
            Expanded(
              child: state.isLoading && state.teachers.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 900;
                        if (!wide) {
                          return _MobileLayout(
                            state: state,
                            scrollController: _scrollController,
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 360,
                              child: _TeachersList(
                                state: state,
                                scrollController: _scrollController,
                              ),
                            ),
                            const VerticalDivider(width: 1),
                            Expanded(
                              child: _TeacherDetails(
                                teacher: state.selectedTeacher,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _MobileLayout extends StatelessWidget {
  final AdminTeacherSubscriptionsState state;
  final ScrollController scrollController;

  const _MobileLayout({
    required this.state,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        ...state.teachers.map(
          (teacher) => _TeacherTile(teacher: teacher, selected: false),
        ),
        if (state.selectedTeacher != null) ...[
          const SizedBox(height: 16),
          _TeacherDetails(teacher: state.selectedTeacher),
        ],
      ],
    );
  }
}

class _TeachersList extends StatelessWidget {
  final AdminTeacherSubscriptionsState state;
  final ScrollController scrollController;

  const _TeachersList({
    required this.state,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    if (state.teachers.isEmpty) {
      return Center(
        child: Text(isArabic ? 'لا يوجد مدرسين' : 'No teachers found'),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: state.teachers.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.teachers.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final teacher = state.teachers[index];
        return _TeacherTile(
          teacher: teacher,
          selected: state.selectedTeacherId == teacher.teacherId,
        );
      },
    );
  }
}

class _TeacherTile extends StatelessWidget {
  final AdminTeacherSubscriptionModel teacher;
  final bool selected;

  const _TeacherTile({
    required this.teacher,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final statusColor =
        teacher.hasActiveSubscription ? AppColors.success : AppColors.error;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        context
            .read<AdminTeacherSubscriptionsCubit>()
            .selectTeacher(teacher.teacherId);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.10)
              : (isDark ? AppColors.cardDark : AppColors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.16),
              child: Text(teacher.displayName.characters.first.toUpperCase()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teacher.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    teacher.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _StatusPill(
              label: teacher.hasActiveSubscription
                  ? (isArabic ? 'ساري' : 'Active')
                  : (isArabic ? 'غير ساري' : 'Inactive'),
              color: statusColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _TeacherDetails extends StatelessWidget {
  final AdminTeacherSubscriptionModel? teacher;

  const _TeacherDetails({required this.teacher});

  @override
  Widget build(BuildContext context) {
    final selectedTeacher = teacher;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    if (selectedTeacher == null) {
      return Center(
        child: Text(isArabic ? 'اختر مدرس لعرض اشتراكاته' : 'Select a teacher'),
      );
    }

    final current = selectedTeacher.currentSubscription;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedTeacher.displayName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(selectedTeacher.email),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showCreateDialog(context, selectedTeacher),
              icon: const Icon(Icons.add_rounded),
              label: Text(isArabic ? 'اشتراك جديد' : 'New subscription'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _CurrentSubscriptionCard(
          teacher: selectedTeacher,
          subscription: current,
        ),
        const SizedBox(height: 20),
        Text(
          isArabic ? 'سجل الاشتراكات' : 'Subscription history',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        if (selectedTeacher.subscriptions.isEmpty)
          Text(isArabic ? 'لا توجد اشتراكات بعد' : 'No subscriptions yet')
        else
          ...selectedTeacher.subscriptions.map(
            (subscription) => _SubscriptionHistoryItem(
              subscription: subscription,
            ),
          ),
      ],
    );
  }
}

class _CurrentSubscriptionCard extends StatelessWidget {
  final AdminTeacherSubscriptionModel teacher;
  final TeacherSubscriptionModel? subscription;

  const _CurrentSubscriptionCard({
    required this.teacher,
    required this.subscription,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final dateFormat = DateFormat('yyyy/MM/dd');
    final active = subscription != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: active
            ? AppColors.successLight
            : AppColors.warningLight.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active ? AppColors.success : AppColors.warning,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                active ? Icons.verified_rounded : Icons.lock_clock_rounded,
                color: active ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  active
                      ? (isArabic ? 'الاشتراك ساري' : 'Subscription active')
                      : (isArabic
                          ? 'لا يوجد اشتراك ساري'
                          : 'No active subscription'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.grey900,
                  ),
                ),
              ),
            ],
          ),
          if (subscription != null) ...[
            const SizedBox(height: 12),
            Text(
              '${isArabic ? 'الخطة' : 'Plan'}: ${subscription!.planName ?? '-'}',
              style: const TextStyle(color: AppColors.grey900),
            ),
            Text(
              '${isArabic ? 'ينتهي في' : 'Ends at'}: ${dateFormat.format(subscription!.endsAt)}',
              style: const TextStyle(color: AppColors.grey900),
            ),
            Text(
              '${isArabic ? 'الأيام المتبقية' : 'Remaining days'}: ${subscription!.remainingDays}',
              style: const TextStyle(color: AppColors.grey900),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showExtendDialog(context, subscription!),
                  icon: const Icon(Icons.more_time_rounded),
                  label: Text(isArabic ? 'تمديد' : 'Extend'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showCancelDialog(context, subscription!),
                  icon: const Icon(Icons.cancel_rounded),
                  label: Text(isArabic ? 'إلغاء' : 'Cancel'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SubscriptionHistoryItem extends StatelessWidget {
  final TeacherSubscriptionModel subscription;

  const _SubscriptionHistoryItem({required this.subscription});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final dateFormat = DateFormat('yyyy/MM/dd');
    final color = subscription.status == TeacherSubscriptionStatus.active
        ? AppColors.success
        : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subscription.planName ??
                      (isArabic ? 'اشتراك' : 'Subscription'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${dateFormat.format(subscription.startsAt)} - ${dateFormat.format(subscription.endsAt)}',
                ),
                if (subscription.notes?.isNotEmpty ?? false)
                  Text(
                    subscription.notes!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          _StatusPill(label: subscription.status.labelAr, color: color),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'extend') {
                _showExtendDialog(context, subscription);
              } else if (value == 'cancel') {
                _showCancelDialog(context, subscription);
              } else if (value == 'reactivate') {
                context
                    .read<AdminTeacherSubscriptionsCubit>()
                    .reactivateSubscription(subscription.id);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'extend',
                child: Text(isArabic ? 'تمديد' : 'Extend'),
              ),
              PopupMenuItem(
                value: 'cancel',
                child: Text(isArabic ? 'إلغاء' : 'Cancel'),
              ),
              PopupMenuItem(
                value: 'reactivate',
                child: Text(isArabic ? 'إعادة تفعيل' : 'Reactivate'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

Future<void> _showCreateDialog(
  BuildContext context,
  AdminTeacherSubscriptionModel teacher,
) async {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final formKey = GlobalKey<FormState>();
  final planController =
      TextEditingController(text: isArabic ? 'شهري' : 'Monthly');
  final daysController = TextEditingController(text: '30');
  final amountController = TextEditingController();
  final notesController = TextEditingController();

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(isArabic ? 'إضافة اشتراك جديد' : 'Add subscription'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: planController,
                  decoration: InputDecoration(
                    labelText: isArabic ? 'اسم الخطة' : 'Plan name',
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Required'
                      : null,
                ),
                TextFormField(
                  controller: daysController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isArabic ? 'عدد الأيام' : 'Days',
                  ),
                  validator: (value) {
                    final days = int.tryParse(value ?? '');
                    return days == null || days <= 0 ? 'Invalid days' : null;
                  },
                ),
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isArabic ? 'المبلغ اختياري' : 'Amount optional',
                  ),
                ),
                TextFormField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: isArabic ? 'ملاحظات' : 'Notes',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(isArabic ? 'إغلاق' : 'Close'),
          ),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final days = int.parse(daysController.text);
              context.read<AdminTeacherSubscriptionsCubit>().createSubscription(
                    TeacherSubscriptionUpsertDto(
                      teacherId: teacher.teacherId,
                      startsAt: DateTime.now(),
                      endsAt: DateTime.now().add(Duration(days: days)),
                      planName: planController.text.trim(),
                      amount: double.tryParse(amountController.text),
                      notes: notesController.text.trim().isEmpty
                          ? null
                          : notesController.text.trim(),
                    ),
                  );
              Navigator.pop(dialogContext);
            },
            child: Text(isArabic ? 'حفظ' : 'Save'),
          ),
        ],
      );
    },
  );
}

Future<void> _showExtendDialog(
  BuildContext context,
  TeacherSubscriptionModel subscription,
) async {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final daysController = TextEditingController(text: '30');
  final notesController = TextEditingController(text: subscription.notes);

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(isArabic ? 'تمديد الاشتراك' : 'Extend subscription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: daysController,
              keyboardType: TextInputType.number,
              decoration:
                  InputDecoration(labelText: isArabic ? 'عدد الأيام' : 'Days'),
            ),
            TextField(
              controller: notesController,
              decoration:
                  InputDecoration(labelText: isArabic ? 'ملاحظات' : 'Notes'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(isArabic ? 'إغلاق' : 'Close'),
          ),
          ElevatedButton(
            onPressed: () {
              final days = int.tryParse(daysController.text) ?? 0;
              if (days <= 0) return;
              context.read<AdminTeacherSubscriptionsCubit>().extendSubscription(
                    subscription: subscription,
                    days: days,
                    notes: notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
                  );
              Navigator.pop(dialogContext);
            },
            child: Text(isArabic ? 'تمديد' : 'Extend'),
          ),
        ],
      );
    },
  );
}

Future<void> _showCancelDialog(
  BuildContext context,
  TeacherSubscriptionModel subscription,
) async {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final notesController = TextEditingController(text: subscription.notes);

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(isArabic ? 'إلغاء الاشتراك' : 'Cancel subscription'),
        content: TextField(
          controller: notesController,
          decoration:
              InputDecoration(labelText: isArabic ? 'سبب الإلغاء' : 'Reason'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(isArabic ? 'إغلاق' : 'Close'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AdminTeacherSubscriptionsCubit>().cancelSubscription(
                    subscription.id,
                    notes: notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
                  );
              Navigator.pop(dialogContext);
            },
            child: Text(isArabic ? 'إلغاء الاشتراك' : 'Cancel subscription'),
          ),
        ],
      );
    },
  );
}
