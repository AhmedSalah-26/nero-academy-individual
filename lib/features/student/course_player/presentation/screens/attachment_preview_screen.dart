import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lms_platform/core/theme/app_colors.dart';
import 'package:lms_platform/core/shared_widgets/back_button.dart';
import 'package:lms_platform/core/shared_widgets/error_state.dart';

// Conditional imports
import 'attachment_preview_mobile.dart'
    if (dart.library.html) 'attachment_preview_web.dart' as platform;

/// Attachment Preview Screen - Downloads and opens files
class AttachmentPreviewScreen extends StatefulWidget {
  final String url;
  final String title;

  const AttachmentPreviewScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<AttachmentPreviewScreen> createState() =>
      _AttachmentPreviewScreenState();
}

class _AttachmentPreviewScreenState extends State<AttachmentPreviewScreen> {
  bool _isDownloading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _downloadAndOpenFile();
  }

  Future<void> _downloadAndOpenFile() async {
    try {
      setState(() {
        _isDownloading = true;
        _errorMessage = null;
      });

      if (kIsWeb) {
        // For web, just open the URL in a new tab
        final uri = Uri.parse(widget.url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          setState(() {
            _isDownloading = false;
          });
        } else {
          setState(() {
            _isDownloading = false;
            _errorMessage = 'لا يمكن فتح الرابط';
          });
        }
      } else {
        // For mobile, download and open
        await platform.downloadAndOpenFile(
          url: widget.url,
          fileName: widget.title,
          onSuccess: () {
            if (mounted) {
              setState(() {
                _isDownloading = false;
              });
            }
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                _isDownloading = false;
                _errorMessage = error;
              });
            }
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _errorMessage = 'فشل في تحميل الملف: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        leading: const AppBackButton(),
        title: Text(
          widget.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.white : AppColors.textMainLight,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        surfaceTintColor: Colors.transparent,
      ),
      body: Center(
        child: _isDownloading
            ? _buildDownloadingState(isDark)
            : _errorMessage != null
                ? _buildErrorState()
                : _buildSuccessState(isDark),
      ),
    );
  }

  Widget _buildDownloadingState(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'جاري تحميل الملف...',
          style: TextStyle(
            fontSize: 16,
            color: isDark ? AppColors.grey300 : AppColors.textMutedLight,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return ErrorState(
      type: ErrorType.generic,
      display: ErrorStateDisplay.section,
      message: _errorMessage!,
      onRetry: _downloadAndOpenFile,
    );
  }

  Widget _buildSuccessState(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: 64,
          color: AppColors.success,
        ),
        const SizedBox(height: 16),
        Text(
          kIsWeb ? 'تم فتح الملف في نافذة جديدة' : 'تم تحميل الملف بنجاح',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.white : AppColors.textMainLight,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
          label: const Text('رجوع'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
