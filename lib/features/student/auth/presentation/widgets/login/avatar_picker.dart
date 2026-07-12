import 'dart:typed_data';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

class AvatarPicker extends StatelessWidget {
  final Uint8List? imageBytes;
  final VoidCallback onTap;
  final bool isDark;

  const AvatarPicker({
    super.key,
    this.imageBytes,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? AppColors.grey800 : AppColors.grey100,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 3,
                  ),
                  image: imageBytes != null
                      ? DecorationImage(
                          image: MemoryImage(imageBytes!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: imageBytes == null
                    ? Icon(
                        Icons.person_rounded,
                        size: 50,
                        color: isDark ? AppColors.grey600 : AppColors.grey400,
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          imageBytes != null
              ? 'auth.change_avatar'.tr()
              : 'auth.avatar_hint'.tr(),
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.grey400 : AppColors.grey500,
          ),
        ),
      ],
    );
  }
}

/// Helper function to pick image
Future<Uint8List?> pickImage() async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 512,
    maxHeight: 512,
    imageQuality: 80,
  );
  if (picked != null) {
    return await picked.readAsBytes();
  }
  return null;
}
