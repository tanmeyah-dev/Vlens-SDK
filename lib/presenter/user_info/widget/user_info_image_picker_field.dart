import 'dart:io';

import 'package:core/style/app_colors.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../model/user_info_model.dart';

/// Single-image gallery picker used for KYC document uploads.
class UserInfoImagePickerField extends StatelessWidget {
  const UserInfoImagePickerField({
    super.key,
    required this.fieldKey,
    required this.title,
    required this.model,
    required this.onChanged,
  });

  final String fieldKey;
  final String title;
  final UserInfoModel model;
  final VoidCallback onChanged;

  Future<Permission> _galleryPermission() async {
    if (Platform.isIOS) return Permission.photos;

    if (Platform.isAndroid) {
      final sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
      // Android 13+ (API 33) uses READ_MEDIA_IMAGES via Permission.photos.
      if (sdkInt >= 33) return Permission.photos;
      return Permission.storage;
    }

    return Permission.photos;
  }

  Future<bool> _ensureGalleryPermission(BuildContext context) async {
    final permission = await _galleryPermission();
    var status = await permission.status;

    if (status.isGranted || status.isLimited) return true;

    if (status.isDenied) {
      status = await permission.request();
      if (status.isGranted || status.isLimited) return true;
    }

    if (!context.mounted) return false;

    final openSettings = status.isPermanentlyDenied || status.isRestricted;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          openSettings
              ? 'برجاء السماح بالوصول إلى معرض الصور من إعدادات التطبيق'
              : 'يجب السماح بالوصول إلى معرض الصور لاختيار الصورة',
        ),
        backgroundColor: AppColors.error,
        action: openSettings
            ? SnackBarAction(
                label: 'الإعدادات',
                textColor: Colors.white,
                onPressed: openAppSettings,
              )
            : null,
      ),
    );
    return false;
  }

  Future<void> _pickImage(BuildContext context) async {
    try {
      final allowed = await _ensureGalleryPermission(context);
      if (!allowed) return;

      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (file == null) return;
      model.setDocumentImage(fieldKey, file.path);
      onChanged();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر اختيار الصورة: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final path = model.documentImagePaths[fieldKey];
    final error = model.showValidationErrors
        ? model.validationErrors[fieldKey]
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.secondary,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _pickImage(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 120),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: error != null ? AppColors.error : AppColors.border1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: path == null || path.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            color: AppColors.secondary,
                            size: 32,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'اختر صورة من المعرض',
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Stack(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 160,
                          child: Image.file(
                            File(path),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: AppColors.secondary,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Material(
                            color: Colors.black54,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () {
                                model.clearDocumentImage(fieldKey);
                                onChanged();
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Material(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _pickImage(context),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                child: Text(
                                  'تغيير',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (error != null && error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 12),
              child: Text(
                error,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
