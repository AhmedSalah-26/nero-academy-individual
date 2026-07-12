import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/shared_widgets/user_avatar.dart';
import '../../data/models/admin_user_model.dart';
import '../widgets/admin_users/user_details_sections.dart';

/// User Details Screen - Full screen version
class UserDetailsScreen extends StatefulWidget {
  final AdminUserModel user;
  final Function(AdminUserModel) onUpdate;
  final VoidCallback? onBan;
  final VoidCallback? onUnban;

  const UserDetailsScreen({
    super.key,
    required this.user,
    required this.onUpdate,
    this.onBan,
    this.onUnban,
  });

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _headlineArController;
  late TextEditingController _headlineEnController;
  late TextEditingController _bioArController;
  late TextEditingController _bioEnController;
  late String _selectedRole;
  late bool _isActive;
  late bool _isVerifiedInstructor;
  late List<String> _interests;
  late List<String> _expertise;
  bool _isEditing = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _nameController = TextEditingController(text: widget.user.name ?? '');
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _headlineArController =
        TextEditingController(text: widget.user.headlineAr ?? '');
    _headlineEnController =
        TextEditingController(text: widget.user.headlineEn ?? '');
    _bioArController = TextEditingController(text: widget.user.bioAr ?? '');
    _bioEnController = TextEditingController(text: widget.user.bioEn ?? '');
    _selectedRole = widget.user.role;
    _isActive = widget.user.isActive;
    _isVerifiedInstructor = widget.user.isVerifiedInstructor;
    _interests = List.from(widget.user.interests);
    _expertise = List.from(widget.user.expertise);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _headlineArController.dispose();
    _headlineEnController.dispose();
    _bioArController.dispose();
    _bioEnController.dispose();
    super.dispose();
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final dateFormat = DateFormat('yyyy/MM/dd - HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'تفاصيل المستخدم' : 'User Details'),
        actions: [
          if (!_isEditing)
            TextButton.icon(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(isArabic ? 'تعديل' : 'Edit'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserHeader(isDark, isArabic),
            const SizedBox(height: 24),
            _buildBasicInfo(isDark, isArabic, dateFormat),
            const SizedBox(height: 24),
            if (_selectedRole == 'instructor')
              buildInstructorInfo(
                isDark: isDark,
                isArabic: isArabic,
                isEditing: _isEditing,
                headlineArController: _headlineArController,
                headlineEnController: _headlineEnController,
                bioArController: _bioArController,
                bioEnController: _bioEnController,
                expertise: _expertise,
                isVerifiedInstructor: _isVerifiedInstructor,
                user: widget.user,
                markChanged: _markChanged,
                onVerifiedChanged: (value) {
                  setState(() => _isVerifiedInstructor = value);
                  _markChanged();
                },
                onExpertiseAdd: (value) {
                  setState(() => _expertise.add(value));
                  _markChanged();
                },
                onExpertiseRemove: (index) {
                  setState(() => _expertise.removeAt(index));
                  _markChanged();
                },
              ),
            if (_selectedRole == 'student')
              buildStudentInfo(
                isDark: isDark,
                isArabic: isArabic,
                isEditing: _isEditing,
                interests: _interests,
                onAdd: (value) {
                  setState(() => _interests.add(value));
                  _markChanged();
                },
                onRemove: (index) {
                  setState(() => _interests.removeAt(index));
                  _markChanged();
                },
              ),
            const SizedBox(height: 24),
            buildStatusSection(
              isDark: isDark,
              isArabic: isArabic,
              isEditing: _isEditing,
              isActive: _isActive,
              user: widget.user,
              onActiveChanged: (value) {
                setState(() => _isActive = value);
                _markChanged();
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(isDark, isArabic),
    );
  }

  Widget _buildUserHeader(bool isDark, bool isArabic) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            UserAvatar(
              imageUrl: widget.user.avatarUrl,
              name: widget.user.displayName,
              size: AvatarSize.xl,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user.displayName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildRoleBadge(isDark, isArabic),
                      const SizedBox(width: 8),
                      if (widget.user.isBanned) _buildBannedBadge(isArabic),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.email_outlined,
                          size: 16,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.user.email,
                          style: TextStyle(
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 16),
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: widget.user.email));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text(isArabic ? 'تم النسخ' : 'Copied')),
                          );
                        },
                        tooltip: isArabic ? 'نسخ' : 'Copy',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(bool isDark, bool isArabic) {
    final roleLabels = {
      'student': isArabic ? 'طالب' : 'Student',
      'instructor': isArabic ? 'مدرس' : 'Instructor',
      'admin': isArabic ? 'مسؤول' : 'Admin',
    };
    final roleColors = {
      'student': AppColors.info,
      'instructor': AppColors.primary,
      'admin': AppColors.warning,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: roleColors[widget.user.role]!.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        roleLabels[widget.user.role] ?? widget.user.role,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: roleColors[widget.user.role],
        ),
      ),
    );
  }

  Widget _buildBannedBadge(bool isArabic) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isArabic ? 'محظور' : 'Banned',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.error,
        ),
      ),
    );
  }

  Widget _buildBasicInfo(bool isDark, bool isArabic, DateFormat dateFormat) {
    return buildSection(
      title: isArabic ? 'المعلومات الأساسية' : 'Basic Information',
      isDark: isDark,
      children: [
        buildField(
          label: isArabic ? 'الاسم' : 'Name',
          controller: _nameController,
          isDark: isDark,
          enabled: _isEditing,
          onChanged: (_) => _markChanged(),
        ),
        const SizedBox(height: 12),
        buildField(
          label: isArabic ? 'رقم الهاتف' : 'Phone',
          controller: _phoneController,
          isDark: isDark,
          enabled: _isEditing,
          onChanged: (_) => _markChanged(),
        ),
        const SizedBox(height: 12),
        if (_isEditing)
          DropdownButtonFormField<String>(
            initialValue: _selectedRole,
            decoration: InputDecoration(
              labelText: isArabic ? 'الدور' : 'Role',
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(
                  value: 'student', child: Text(isArabic ? 'طالب' : 'Student')),
              DropdownMenuItem(
                  value: 'instructor',
                  child: Text(isArabic ? 'مدرس' : 'Instructor')),
              DropdownMenuItem(
                  value: 'admin', child: Text(isArabic ? 'مسؤول' : 'Admin')),
            ],
            onChanged: (value) {
              setState(() => _selectedRole = value!);
              _markChanged();
            },
          )
        else
          buildInfoRow(
            label: isArabic ? 'الدور' : 'Role',
            value: _selectedRole == 'student'
                ? (isArabic ? 'طالب' : 'Student')
                : _selectedRole == 'instructor'
                    ? (isArabic ? 'مدرس' : 'Instructor')
                    : (isArabic ? 'مسؤول' : 'Admin'),
            isDark: isDark,
          ),
        const SizedBox(height: 12),
        buildInfoRow(
          label: isArabic ? 'تاريخ التسجيل' : 'Registered',
          value: dateFormat.format(widget.user.createdAt),
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        buildInfoRow(
          label: isArabic ? 'آخر تحديث' : 'Last Updated',
          value: dateFormat.format(widget.user.updatedAt),
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        buildInfoRow(
          label: 'ID',
          value: widget.user.id,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildBottomBar(bool isDark, bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (widget.user.isBanned)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    widget.onUnban?.call();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.lock_open_rounded),
                  label: Text(isArabic ? 'إلغاء الحظر' : 'Unban'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              )
            else
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    widget.onBan?.call();
                  },
                  icon: const Icon(Icons.block_rounded, color: AppColors.error),
                  label: Text(
                    isArabic ? 'حظر' : 'Ban',
                    style: const TextStyle(color: AppColors.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            if (_isEditing) ...[
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _hasChanges = false;
                      _initControllers();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(isArabic ? 'إلغاء' : 'Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _hasChanges ? _saveChanges : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(isArabic ? 'حفظ' : 'Save'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _saveChanges() {
    final updatedUser = widget.user.copyWith(
      name: _nameController.text.isEmpty ? null : _nameController.text,
      phone: _phoneController.text.isEmpty ? null : _phoneController.text,
      role: _selectedRole,
      headlineAr: _headlineArController.text.isEmpty
          ? null
          : _headlineArController.text,
      headlineEn: _headlineEnController.text.isEmpty
          ? null
          : _headlineEnController.text,
      bioAr: _bioArController.text.isEmpty ? null : _bioArController.text,
      bioEn: _bioEnController.text.isEmpty ? null : _bioEnController.text,
      expertise: _expertise,
      interests: _interests,
      isActive: _isActive,
      isVerifiedInstructor: _isVerifiedInstructor,
    );

    widget.onUpdate(updatedUser);
    setState(() {
      _isEditing = false;
      _hasChanges = false;
    });
  }
}
