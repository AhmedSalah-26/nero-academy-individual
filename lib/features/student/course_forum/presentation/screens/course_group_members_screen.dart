import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lms_platform/core/shared_widgets/loading_state.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/features/student/course_forum/data/models/course_forums_management_models.dart';

class CourseGroupMembersScreen extends StatefulWidget {
  final String courseId;
  final String courseTitleAr;
  final String courseTitleEn;

  const CourseGroupMembersScreen({
    super.key,
    required this.courseId,
    required this.courseTitleAr,
    required this.courseTitleEn,
  });

  @override
  State<CourseGroupMembersScreen> createState() =>
      _CourseGroupMembersScreenState();
}

class _CourseGroupMembersScreenState extends State<CourseGroupMembersScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _titleController = TextEditingController();
  bool _isLoading = true;
  bool _isSavingTitle = false;
  String? _error;
  List<ManagedMember> _members = const [];
  String? _groupTitle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadMembers();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final isArabic = Localizations.localeOf(context).languageCode == 'ar';
      final unknownName = isArabic ? 'غير معروف' : 'Unknown';
      final response = await _supabase.rpc('get_course_group_members',
          params: {'p_course_id': widget.courseId});

      final rows = response as List;
      final members = rows
          .map((row) => ManagedMember.fromJson(
                row as Map<String, dynamic>,
                unknownName: unknownName,
              ))
          .toList();

      String? groupTitle;
      if (rows.isNotEmpty) {
        groupTitle = (rows.first as Map<String, dynamic>)['conversation_title']
            as String?;
      }

      if (!mounted) return;
      setState(() {
        _members = members;
        _groupTitle = groupTitle;
        _titleController.text = groupTitle ?? '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateTitle() async {
    final value = _titleController.text.trim();
    if (value.isEmpty) return;

    setState(() => _isSavingTitle = true);
    try {
      await _supabase.rpc('update_course_group_title', params: {
        'p_course_id': widget.courseId,
        'p_title': value,
      });
      if (!mounted) return;
      setState(() => _groupTitle = value);
      final isArabic = Localizations.localeOf(context).languageCode == 'ar';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(isArabic ? 'تم تحديث اسم الجروب' : 'Group title updated'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingTitle = false);
      }
    }
  }

  Future<void> _applyAction(ManagedMember member, String action,
      {String? reason}) async {
    try {
      await _supabase.rpc('manage_course_group_member', params: {
        'p_course_id': widget.courseId,
        'p_target_user_id': member.userId,
        'p_action': action,
        'p_reason': reason,
      });
      if (!mounted) return;
      await _loadMembers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _onMemberMenuTap(ManagedMember member, String action) async {
    if (action == 'ban') {
      final reason = await _askBanReason();
      if (!mounted || reason == null) return;
      await _applyAction(member, 'ban', reason: reason);
      return;
    }

    await _applyAction(member, action);
  }

  Future<String?> _askBanReason() async {
    final controller = TextEditingController();
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title:
              Text(isArabic ? 'سبب البان (اختياري)' : 'Ban reason (optional)'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: isArabic ? 'اكتب السبب' : 'Write reason',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: Text(isArabic ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: Text(isArabic ? 'تأكيد' : 'Confirm'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final title = isArabic
        ? (widget.courseTitleAr.isNotEmpty
            ? widget.courseTitleAr
            : (widget.courseTitleEn.isNotEmpty
                ? widget.courseTitleEn
                : 'إدارة الجروب'))
        : (widget.courseTitleEn.isNotEmpty
            ? widget.courseTitleEn
            : (widget.courseTitleAr.isNotEmpty
                ? widget.courseTitleAr
                : 'Manage group'));

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(title),
      ),
      body: RefreshIndicator(
        onRefresh: _loadMembers,
        child: _buildBody(isDark, isArabic),
      ),
    );
  }

  Widget _buildBody(bool isDark, bool isArabic) {
    if (_isLoading) {
      return const AppLoadingState();
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 60),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton(
              onPressed: _loadMembers,
              child: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isArabic ? 'اسم الجروب' : 'Group name',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: _groupTitle ??
                            (isArabic ? 'ادخل اسم الجروب' : 'Enter group name'),
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSavingTitle ? null : _updateTitle,
                    child: _isSavingTitle
                        ? const SizedBox(
                            height: 14,
                            width: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isArabic ? 'حفظ' : 'Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isArabic ? 'الأعضاء' : 'Members',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (_members.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Text(isArabic ? 'لا يوجد أعضاء' : 'No members'),
          )
        else
          ..._members.map((member) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: member.userAvatar != null
                      ? NetworkImage(member.userAvatar!)
                      : null,
                  child: member.userAvatar == null
                      ? Text(member.userName.isEmpty
                          ? '?'
                          : member.userName[0].toUpperCase())
                      : null,
                ),
                title: Text(member.userName),
                subtitle: Text(member.subtitle(isArabic)),
                trailing: PopupMenuButton<String>(
                  icon: Icon(
                    member.role == 'admin'
                        ? Icons.manage_accounts_outlined
                        : Icons.more_vert,
                  ),
                  tooltip: member.role == 'admin'
                      ? (isArabic ? 'إعدادات الأدمن' : 'Admin settings')
                      : (isArabic ? 'إدارة العضو' : 'Manage member'),
                  onSelected: (value) => _onMemberMenuTap(member, value),
                  itemBuilder: (_) {
                    final items = <PopupMenuEntry<String>>[];
                    if (member.isBanned) {
                      items.add(
                        PopupMenuItem(
                          value: 'unban',
                          child: Text(isArabic ? 'فك البان' : 'Unban'),
                        ),
                      );
                      return items;
                    }

                    if (member.role != 'admin') {
                      items.add(
                        PopupMenuItem(
                          value: 'admin',
                          child: Text(isArabic ? 'ترقية لأدمن' : 'Make admin'),
                        ),
                      );
                    }
                    if (member.role == 'admin') {
                      items.add(
                        PopupMenuItem(
                          value: 'member',
                          child: Text(isArabic ? 'تحويل لعضو' : 'Make member'),
                        ),
                      );
                    }
                    items.add(
                      PopupMenuItem(
                        value: 'remove',
                        child: Text(
                          isArabic ? 'حذف من الجروب' : 'Remove from group',
                        ),
                      ),
                    );
                    items.add(
                      PopupMenuItem(
                        value: 'ban',
                        child: Text(
                          isArabic ? 'بان من الجروب' : 'Ban from group',
                        ),
                      ),
                    );
                    return items;
                  },
                ),
              ),
            );
          }),
      ],
    );
  }
}
