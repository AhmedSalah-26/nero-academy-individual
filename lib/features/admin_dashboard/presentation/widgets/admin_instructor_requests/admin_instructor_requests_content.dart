import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/services/app_logger.dart';
import '../../../../../core/shared_widgets/dashboard/dashboard_widgets.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/toast_utils.dart';
import '../../../../../core/utils/validators.dart';

// ─────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────

class _Request {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String accountType;
  final String status;
  final String? adminNotes;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewerName;

  const _Request({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.accountType,
    required this.status,
    required this.createdAt,
    this.adminNotes,
    this.reviewedAt,
    this.reviewerName,
  });

  factory _Request.fromJson(Map<String, dynamic> json) {
    final reviewerRaw = json['reviewer'];
    String? reviewerName;
    if (reviewerRaw is Map<String, dynamic>) {
      reviewerName = reviewerRaw['name']?.toString();
    }

    return _Request(
      id: json['id'] as String,
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? json['name'] as String
          : 'Unknown',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      accountType: 'instructor',
      status: json['status'] as String? ?? 'pending',
      adminNotes: json['admin_notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      reviewerName: reviewerName,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Main Widget
// ─────────────────────────────────────────────────────────────────

class AdminInstructorRequestsContent extends StatefulWidget {
  const AdminInstructorRequestsContent({super.key});

  @override
  State<AdminInstructorRequestsContent> createState() =>
      _AdminInstructorRequestsContentState();
}

class _AdminInstructorRequestsContentState
    extends State<AdminInstructorRequestsContent> {
  final _supabase = Supabase.instance.client;

  List<_Request> _requests = [];
  bool _isLoading = true;
  bool _isBusy = false;
  String _statusFilter = 'pending';
  String _searchQuery = '';

  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';

  // ── Lifecycle ──────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  // ── Data ───────────────────────────────────────────────────────

  Future<void> _loadRequests({bool showLoader = true}) async {
    if (showLoader) setState(() => _isLoading = true);

    try {
      var query = _supabase.from('instructor_applications').select('''
        id, name, email, phone, status, admin_notes,
        created_at, reviewed_at,
        reviewer:profiles!instructor_applications_reviewed_by_fkey(name)
      ''');

      if (_statusFilter != 'all') query = query.eq('status', _statusFilter);
      if (_searchQuery.isNotEmpty) {
        query = query.or(
            'name.ilike.%$_searchQuery%,email.ilike.%$_searchQuery%,phone.ilike.%$_searchQuery%');
      }

      final rows = await query.order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _requests = (rows as List)
            .map((r) => _Request.fromJson(r as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      AppLogger.e('[InstructorRequests] load error', e);
      ToastUtils.showError(_isArabic ? 'تعذر تحميل الطلبات' : 'Failed to load');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(
      String requestId, String status, String notes) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      await _supabase.from('instructor_applications').update({
        'status': status,
        'admin_notes': notes.isEmpty ? null : notes,
        'reviewed_by': _supabase.auth.currentUser?.id,
        'reviewed_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', requestId);

      ToastUtils.showSuccess(
          _isArabic ? 'تم تحديث حالة الطلب' : 'Status updated');
      await _loadRequests(showLoader: false);
    } catch (e) {
      ToastUtils.showError(_isArabic ? 'تعذر تحديث الطلب' : 'Update failed');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _createAccount({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);

    try {
      // Check duplicate
      final existing = await _supabase
          .from('profiles')
          .select('id')
          .eq('email', email)
          .limit(1);
      if ((existing as List).isNotEmpty) {
        ToastUtils.showError(_isArabic
            ? 'البريد الإلكتروني مستخدم بالفعل'
            : 'Email already exists');
        return;
      }

      // Sign up using the main client
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'role': role},
      );

      final userId = response.user?.id;
      if (userId == null) throw Exception('signUp returned no user');

      AppLogger.success('[AdminCreateAccount] Auth user created: $userId');

      // Wait briefly for the DB trigger to fire (creates profile row)
      await Future.delayed(const Duration(milliseconds: 500));

      // Ensure profile has correct name & role
      await _supabase.from('profiles').upsert({
        'id': userId,
        'email': email,
        'name': name,
        'role': role,
        'is_active': true,
      });

      // If instructor → ensure instructor_profiles row exists
      if (role == 'instructor') {
        final has = await _supabase
            .from('instructor_profiles')
            .select('id')
            .eq('instructor_id', userId)
            .maybeSingle();
        if (has == null) {
          await _supabase.from('instructor_profiles').insert({
            'instructor_id': userId,
            'display_name': name,
            'payout_method': 'wallet',
          });
        }
      }

      ToastUtils.showSuccess(
          _isArabic ? 'تم إنشاء الحساب بنجاح' : 'Account created successfully');

      // Sign out and go to login
      await _supabase.auth.signOut(scope: SignOutScope.local);
      if (mounted) {
        GoRouter.of(context).go('/splash');
      }
    } on AuthException catch (e) {
      AppLogger.e('[AdminCreateAccount] AuthException', e);
      ToastUtils.showError(_isArabic
          ? 'فشل إنشاء الحساب: ${e.message}'
          : 'Auth error: ${e.message}');
    } on PostgrestException catch (e) {
      AppLogger.e('[AdminCreateAccount] PostgrestException', e);
      ToastUtils.showError(_isArabic
          ? 'خطأ في قاعدة البيانات: ${e.message}'
          : 'DB error: ${e.message}');
    } catch (e) {
      AppLogger.e('[AdminCreateAccount] Error', e);
      ToastUtils.showError(
          _isArabic ? 'حدث خطأ غير متوقع' : 'Unexpected error');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  // ── Dialogs ────────────────────────────────────────────────────

  Future<void> _showCreateDialog() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _CreateAccountDialog(isArabic: _isArabic),
    );
    if (result == null) return;
    await _createAccount(
      name: result['name']!,
      email: result['email']!,
      password: result['password']!,
      role: result['role']!,
    );
  }

  Future<void> _showDecisionDialog(_Request request, String status) async {
    final confirmed = await showDialog<String>(
      context: context,
      builder: (_) => _DecisionDialog(
          request: request, status: status, isArabic: _isArabic),
    );
    if (confirmed == null) return;
    await _updateStatus(request.id, status, confirmed);
  }

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        Column(
          children: [
            _Header(
              isArabic: _isArabic,
              statusFilter: _statusFilter,
              isBusy: _isBusy,
              onRefresh: _loadRequests,
              onSearch: (q) {
                _searchQuery = q.trim();
                _loadRequests(showLoader: false);
              },
              onFilterChanged: (s) {
                setState(() => _statusFilter = s);
                _loadRequests(showLoader: false);
              },
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _loadRequests(showLoader: false),
                child: _requests.isEmpty ? _buildEmpty() : _buildList(),
              ),
            ),
          ],
        ),
        _Fab(isBusy: _isBusy, onTap: _showCreateDialog),
      ],
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: _requests.length,
      itemBuilder: (_, i) => _RequestCard(
        request: _requests[i],
        isArabic: _isArabic,
        isBusy: _isBusy,
        onApprove: () => _showDecisionDialog(_requests[i], 'approved'),
        onReject: () => _showDecisionDialog(_requests[i], 'rejected'),
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        SizedBox(
          height: 300,
          child: Center(
            child: Text(
              _isArabic ? 'لا توجد طلبات حالياً' : 'No requests found',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Header Widget
// ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final bool isArabic;
  final String statusFilter;
  final bool isBusy;
  final VoidCallback onRefresh;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onFilterChanged;

  const _Header({
    required this.isArabic,
    required this.statusFilter,
    required this.isBusy,
    required this.onRefresh,
    required this.onSearch,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isArabic ? 'طلبات المدرسين' : 'Instructor Requests',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: isBusy ? null : onRefresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DashboardSearchBar(
            hintText: 'Search by name, email, or phone...',
            hintTextAr: 'بحث بالاسم أو البريد أو الهاتف...',
            onSearch: onSearch,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['pending', 'approved', 'rejected', 'all']
                .map((s) => _FilterChip(
                      label: _statusLabel(s, isArabic),
                      selected: statusFilter == s,
                      onTap: () => onFilterChanged(s),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          _InfoBanner(isArabic: isArabic),
        ],
      ),
    );
  }

  static String _statusLabel(String s, bool isArabic) => switch (s) {
        'pending' => isArabic ? 'قيد المراجعة' : 'Pending',
        'approved' => isArabic ? 'مقبول' : 'Approved',
        'rejected' => isArabic ? 'مرفوض' : 'Rejected',
        _ => isArabic ? 'الكل' : 'All',
      };
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final bool isArabic;
  const _InfoBanner({required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Text(
        isArabic
            ? 'بعد قبول الطلب، يقوم الأدمن بإنشاء حساب المدرس مباشرةً عبر زر + بدون الحاجة إلى Supabase.'
            : 'Use the + button to create accounts directly without leaving this screen.',
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Request Card Widget
// ─────────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  final _Request request;
  final bool isArabic;
  final bool isBusy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _RequestCard({
    required this.request,
    required this.isArabic,
    required this.isBusy,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPending = request.status == 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? AppColors.cardDark : AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardHeader(request: request, isArabic: isArabic),
            const SizedBox(height: 10),
            _InfoRow(icon: Icons.mail_outline_rounded, text: request.email),
            if (request.phone.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              _InfoRow(icon: Icons.phone_outlined, text: request.phone),
            ],
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.badge_outlined,
              text:
                  '${isArabic ? 'نوع الحساب' : 'Type'}: ${_roleLabel(request.accountType)}',
            ),
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.schedule_rounded,
              text:
                  '${isArabic ? 'تاريخ الطلب' : 'Date'}: ${_fmt(request.createdAt)}',
            ),
            if (request.adminNotes?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              _NotesBox(notes: request.adminNotes!, isDark: isDark),
            ],
            if (isPending) ...[
              const SizedBox(height: 12),
              _ActionRow(
                isArabic: isArabic,
                isBusy: isBusy,
                onApprove: onApprove,
                onReject: onReject,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _roleLabel(String t) => switch (t) {
        'student' => 'Student',
        'admin' => 'Admin',
        'parent' => 'Parent',
        _ => 'Instructor',
      };

  static String _fmt(DateTime d) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${p(d.month)}-${p(d.day)} ${p(d.hour)}:${p(d.minute)}';
  }
}

class _CardHeader extends StatelessWidget {
  final _Request request;
  final bool isArabic;
  const _CardHeader({required this.request, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            request.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        _StatusBadge(status: request.status, isArabic: isArabic),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final bool isArabic;
  const _StatusBadge({required this.status, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'approved' => AppColors.success,
      'rejected' => AppColors.error,
      _ => AppColors.warning,
    };
    final label = switch (status) {
      'approved' => isArabic ? 'مقبول' : 'Approved',
      'rejected' => isArabic ? 'مرفوض' : 'Rejected',
      _ => isArabic ? 'قيد المراجعة' : 'Pending',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 13, color: Colors.grey))),
      ],
    );
  }
}

class _NotesBox extends StatelessWidget {
  final String notes;
  final bool isDark;
  const _NotesBox({required this.notes, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(notes, style: const TextStyle(fontSize: 13)),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final bool isArabic;
  final bool isBusy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ActionRow({
    required this.isArabic,
    required this.isBusy,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isBusy ? null : onReject,
            icon: const Icon(Icons.close_rounded),
            label: Text(isArabic ? 'رفض' : 'Reject'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isBusy ? null : onApprove,
            icon: const Icon(Icons.check_rounded),
            label: Text(isArabic ? 'قبول' : 'Approve'),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// FAB Widget
// ─────────────────────────────────────────────────────────────────

class _Fab extends StatelessWidget {
  final bool isBusy;
  final VoidCallback onTap;
  const _Fab({required this.isBusy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      end: 16,
      bottom: 16,
      child: FloatingActionButton(
        heroTag: 'admin_create_account_fab',
        onPressed: isBusy ? null : onTap,
        child: isBusy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_rounded),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Create Account Dialog
// ─────────────────────────────────────────────────────────────────

class _CreateAccountDialog extends StatefulWidget {
  final bool isArabic;
  const _CreateAccountDialog({required this.isArabic});

  @override
  State<_CreateAccountDialog> createState() => _CreateAccountDialogState();
}

class _CreateAccountDialogState extends State<_CreateAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  String _role = 'instructor';
  bool _showPass = false;
  bool _showConfirm = false;

  bool get _ar => widget.isArabic;

  static const _roles = ['instructor', 'student', 'admin'];
  static const _roleLabels = {
    'instructor': 'Instructor',
    'student': 'Student',
    'admin': 'Admin',
  };

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.pop(context, {
      'name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim().toLowerCase(),
      'password': _passCtrl.text,
      'role': _role,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
      title: Text(_ar ? 'إنشاء حساب جديد' : 'Create New Account'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Name
              TextFormField(
                controller: _nameCtrl,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: _ar ? 'الاسم' : 'Name',
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (v) => Validators.required(
                  v,
                  message: _ar ? 'الاسم مطلوب' : 'Name is required',
                ),
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: _ar ? 'البريد الإلكتروني' : 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                validator: (v) => Validators.email(
                  v,
                  emptyMessage:
                      _ar ? 'البريد الإلكتروني مطلوب' : 'Email is required',
                  invalidMessage:
                      _ar ? 'بريد إلكتروني غير صالح' : 'Invalid email',
                ),
              ),
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passCtrl,
                obscureText: !_showPass,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: _ar ? 'كلمة المرور' : 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_showPass
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () => setState(() => _showPass = !_showPass),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return _ar ? 'كلمة المرور مطلوبة' : 'Password is required';
                  }
                  if (v.length < 8) {
                    return _ar
                        ? 'كلمة المرور يجب أن تكون 8 أحرف على الأقل'
                        : 'Minimum 8 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirm Password
              TextFormField(
                controller: _confirmCtrl,
                obscureText: !_showConfirm,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: _ar ? 'تأكيد كلمة المرور' : 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_showConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () =>
                        setState(() => _showConfirm = !_showConfirm),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return _ar
                        ? 'تأكيد كلمة المرور مطلوب'
                        : 'Confirm password is required';
                  }
                  if (v != _passCtrl.text) {
                    return _ar
                        ? 'كلمات المرور غير متطابقة'
                        : 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Role Dropdown
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: InputDecoration(
                  labelText: _ar ? 'نوع الحساب' : 'Account Type',
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
                items: _roles
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(_roleLabels[r]!),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _role = v);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(_ar ? 'إلغاء' : 'Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(_ar ? 'إنشاء' : 'Create'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Decision Dialog (Approve / Reject)
// ─────────────────────────────────────────────────────────────────

class _DecisionDialog extends StatelessWidget {
  final _Request request;
  final String status;
  final bool isArabic;

  const _DecisionDialog({
    required this.request,
    required this.status,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final notesCtrl = TextEditingController();
    final isApprove = status == 'approved';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
      title: Text(
        isApprove
            ? (isArabic ? 'قبول الطلب' : 'Approve Request')
            : (isArabic ? 'رفض الطلب' : 'Reject Request'),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${request.name} — ${request.email}'),
          const SizedBox(height: 12),
          TextField(
            controller: notesCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: isArabic ? 'ملاحظات (اختياري)' : 'Notes (optional)',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(isArabic ? 'إلغاء' : 'Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, notesCtrl.text.trim()),
          child: Text(isApprove
              ? (isArabic ? 'تأكيد القبول' : 'Approve')
              : (isArabic ? 'تأكيد الرفض' : 'Reject')),
        ),
      ],
    );
  }
}
