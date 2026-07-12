import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Course Selection Dialog - Used for selecting courses in coupon editor
class CourseSelectionDialog extends StatefulWidget {
  final bool isArabic;
  final Set<String> initialSelectedIds;

  const CourseSelectionDialog({
    super.key,
    required this.isArabic,
    required this.initialSelectedIds,
  });

  @override
  State<CourseSelectionDialog> createState() => _CourseSelectionDialogState();

  /// Shows the dialog and returns selected course IDs and data
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required bool isArabic,
    required Set<String> initialSelectedIds,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => CourseSelectionDialog(
        isArabic: isArabic,
        initialSelectedIds: initialSelectedIds,
      ),
    );
  }
}

class _CourseSelectionDialogState extends State<CourseSelectionDialog> {
  late Set<String> _selectedIds;
  List<Map<String, dynamic>> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.initialSelectedIds);
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await supabase
          .from('courses')
          .select('id, title_ar, title_en, thumbnail_url, is_published')
          .eq('instructor_id', userId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _courses = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading courses: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(isDark),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _courses.isEmpty
                      ? _buildEmptyState()
                      : _buildCourseList(isDark),
            ),
            _buildFooter(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.school, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.isArabic ? 'اختر الكورسات' : 'Select Courses',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            widget.isArabic ? 'لا توجد كورسات' : 'No courses found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _courses.length,
      itemBuilder: (context, index) {
        final course = _courses[index];
        final courseId = course['id'] as String;
        final isSelected = _selectedIds.contains(courseId);
        final titleAr = course['title_ar'] as String? ?? '';
        final titleEn = course['title_en'] as String?;
        final title = widget.isArabic ? titleAr : (titleEn ?? titleAr);

        return CheckboxListTile(
          value: isSelected,
          onChanged: (value) {
            setState(() {
              if (value == true) {
                _selectedIds.add(courseId);
              } else {
                _selectedIds.remove(courseId);
              }
            });
          },
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          secondary: _buildCourseThumbnail(course),
        );
      },
    );
  }

  Widget _buildCourseThumbnail(Map<String, dynamic> course) {
    if (course['thumbnail_url'] != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          course['thumbnail_url'],
          width: 60,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 60,
            height: 40,
            color: Colors.grey[300],
            child: const Icon(Icons.school, size: 20),
          ),
        ),
      );
    }
    return Container(
      width: 60,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.school,
        color: AppColors.primary,
        size: 20,
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.grey50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Text(
            widget.isArabic
                ? '${_selectedIds.length} محدد'
                : '${_selectedIds.length} selected',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.isArabic ? 'إلغاء' : 'Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _selectedIds.isNotEmpty ? _onConfirm : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(widget.isArabic ? 'تأكيد' : 'Confirm'),
          ),
        ],
      ),
    );
  }

  void _onConfirm() {
    final selectedCoursesData = <String, Map<String, dynamic>>{};
    for (final id in _selectedIds) {
      final course = _courses.firstWhere(
        (c) => c['id'] == id,
        orElse: () => {},
      );
      if (course.isNotEmpty) {
        selectedCoursesData[id] = course;
      }
    }
    Navigator.pop(context, {
      'ids': _selectedIds,
      'courses': selectedCoursesData,
    });
  }
}
