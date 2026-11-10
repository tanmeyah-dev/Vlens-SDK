import 'dart:io';

import 'package:core/components/image/app_image.dart';
import 'package:core/style/app_colors.dart';
import 'package:core/utils/ui.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../model/user_info_model.dart';
import '../utils/user_info_image_preview_helper.dart';

/// Single-image gallery picker used for KYC document uploads.
///
/// **iOS:** Uses `requestFullMetadata: true` so `image_picker` triggers the
/// system Photos permission alert (Full Access / Limited / Don't Allow).
/// After returning from Settings, uses `requestFullMetadata: false` (PHPicker)
/// to avoid the known crash when Full Access was just granted.
///
/// **Android:** Android 13+ opens the system photo picker, which needs no
/// gallery permission. Android 12 and below requests storage permission.
class UserInfoImagePickerField extends StatefulWidget {
  const UserInfoImagePickerField({
    super.key,
    required this.fieldKey,
    required this.title,
    required this.model,
    required this.onChanged,
    this.readOnly = false,
  });

  final String fieldKey;
  final String title;
  final UserInfoModel model;
  final VoidCallback onChanged;

  /// When true, shows the selected file with the same card as the form,
  /// without pick or delete actions.
  final bool readOnly;

  @override
  State<UserInfoImagePickerField> createState() =>
      _UserInfoImagePickerFieldState();
}

class _UserInfoImagePickerFieldState extends State<UserInfoImagePickerField>
    with WidgetsBindingObserver {
  static final ImagePicker _picker = ImagePicker();

  bool _picking = false;

  /// After Settings → Full Access, avoid PhotoKit full-metadata path.
  bool _useSafePickerAfterSettings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Kept for resume timing after Settings; flag is consumed in _pickImage.
  }

  Future<bool> _ensureAndroidGalleryPermission() async {
    if (!Platform.isAndroid) return true;

    final sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
    // READ_MEDIA_IMAGES is not in the app manifest. The system photo picker
    // selects one image without that permission.
    if (sdkInt >= 33) return true;

    final permission = Permission.storage;

    try {
      var status = await permission.status;
      if (status.isGranted || status.isLimited) return true;

      status = await permission.request();
      if (!mounted) return false;
      if (status.isGranted || status.isLimited) return true;

      _showError(
        status.isPermanentlyDenied || status.isRestricted
            ? 'برجاء السماح بالوصول إلى معرض الصور من إعدادات التطبيق'
            : 'يجب السماح بالوصول إلى معرض الصور لاختيار الصورة',
        offerSettings: status.isPermanentlyDenied || status.isRestricted,
      );
      return false;
    } catch (_) {
      return true;
    }
  }

  void _showError(String message, {bool offerSettings = false}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        action: offerSettings
            ? SnackBarAction(
                label: 'الإعدادات',
                textColor: Colors.white,
                onPressed: () {
                  _useSafePickerAfterSettings = true;
                  openAppSettings();
                },
              )
            : null,
      ),
    );
  }

  Future<void> _pickImage() async {
    if (widget.readOnly || _picking) return;
    _picking = true;
    try {
      if (Platform.isAndroid) {
        final allowed = await _ensureAndroidGalleryPermission();
        if (!allowed || !mounted) return;
      }

      // iOS: true → Apple shows Photos permission alert via PhotoKit.
      // After Settings grant, false → PHPicker only (avoids crash).
      final requestFullMetadata =
          Platform.isIOS && !_useSafePickerAfterSettings;

      if (_useSafePickerAfterSettings) {
        await Future<void>.delayed(const Duration(milliseconds: 350));
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return;
        _useSafePickerAfterSettings = false;
      }

      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 85,
        requestFullMetadata: requestFullMetadata,
      );
      if (!mounted || file == null) return;

      if (!_isAllowedPhoto(file)) {
        _showError('يجب اختيار صورة بصيغة JPEG او PNG فقط');
        return;
      }

      widget.model.setDocumentImage(widget.fieldKey, file.path);
      widget.onChanged();
    } on PlatformException catch (e) {
      if (!mounted) return;
      final code = e.code.toLowerCase();
      final message = (e.message ?? '').toLowerCase();
      final permissionRelated = code.contains('photo') ||
          code.contains('permission') ||
          message.contains('photo') ||
          message.contains('permission') ||
          message.contains('access') ||
          message.contains('denied');
      if (permissionRelated) {
        _showError(
          'برجاء السماح بالوصول إلى معرض الصور من إعدادات التطبيق',
          offerSettings: true,
        );
      } else {
        _showError('تعذر اختيار الصورة: ${e.message ?? e.code}');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('تعذر اختيار الصورة: $e');
    } finally {
      _picking = false;
    }
  }

  bool _isAllowedPhoto(XFile file) {
    final mime = (file.mimeType ?? '').toLowerCase();
    final name = file.name.toLowerCase();
    final path = file.path.toLowerCase();
    bool hasExt(String ext) => name.endsWith(ext) || path.endsWith(ext);

    if (mime.contains('pdf') || hasExt('.pdf')) return false;
    if (mime.startsWith('image/')) return true;
    if (hasExt('.jpg') ||
        hasExt('.jpeg') ||
        hasExt('.png') ||
        hasExt('.heic') ||
        hasExt('.heif') ||
        hasExt('.webp')) {
      return true;
    }
    // ImagePicker.pickImage already returns a photo when type metadata is missing.
    return mime.isEmpty;
  }

  void _removeFile() {
    if (widget.readOnly) return;
    widget.model.clearDocumentImage(widget.fieldKey);
    widget.onChanged();
  }

  void _previewImage(String path) {
    if (!mounted) return;
    showUserInfoImagePreview(
      context,
      imagePath: path,
      title: widget.title,
    );
  }

  String _fileDisplayName(String path) {
    final fileName = path.split(RegExp(r'[/\\]')).last;
    final dot = fileName.lastIndexOf('.');
    if (dot <= 0) return fileName;
    return fileName.substring(0, dot);
  }

  String get _emptyPrompt {
    if (widget.fieldKey == UserInfoModel.utilityReceiptImageKey) {
      return ' قم بتحميل ايصال مرافق (كهرباء، مياه، او غاز)';
    }
    if (widget.fieldKey == UserInfoModel.leaseContractImageKey) {
      return ' قم بتحميل عقد ايجار';
    }
    if (widget.fieldKey == UserInfoModel.otherDocumentImageKey) {
      return 'يمكنك تحميل ملف اخر (اختياري)';
    }
    return ' قم بتحميل ${widget.title}';
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.model.documentImagePaths[widget.fieldKey];
    final error = widget.model.showValidationErrors
        ? widget.model.validationErrors[widget.fieldKey]
        : null;
    final isEmpty = path == null || path.isEmpty;
    final thumbnailSize = widget.readOnly ? 72.0 : 48.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 10),
          if (isEmpty)
            InkWell(
              onTap: widget.readOnly ? null : _pickImage,
              borderRadius: BorderRadius.circular(14),
              child: CustomPaint(
                painter: _DashedRRectPainter(
                  color:
                      error != null ? AppColors.error : const Color(0xFFD0D5DD),
                  radius: 14,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 28,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Iconsax.document_upload,
                        color: AppColors.navy,
                        size: 32,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _emptyPrompt,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'يجب أن يكون الملف المرفق بصيغة JPEG او PNG.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.hintGray,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.only(bottom: 2),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.navy,
                              width: 1,
                            ),
                          ),
                        ),
                        child: const Text(
                          'تحميل',
                          style: TextStyle(
                            color: AppColors.navy,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(14),
                border:
                    error != null ? Border.all(color: AppColors.error) : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _previewImage(path!),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(path!),
                                  width: thumbnailSize,
                                  height: thumbnailSize,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const AppImage(
                                    AppAssets.pdf,
                                    width: 32,
                                    height: 32,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      _fileDisplayName(path),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        color: AppColors.black,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (widget.readOnly) ...[
                                      const SizedBox(height: 4),
                                      const Text(
                                        'اضغط لمعاينة الصورة',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          color: AppColors.hintGray,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.visibility_outlined,
                                color: AppColors.navy,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!widget.readOnly) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: _removeFile,
                      tooltip: 'حذف',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      icon: const AppImage(
                        AppAssets.delete,
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ],
                ],
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

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({
    required this.color,
    required this.radius,
    this.strokeWidth = 1.2,
    this.dashWidth = 6,
    this.dashGap = 4,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashWidth;
  final double dashGap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final inset = strokeWidth / 2;
    final rrect = RRect.fromLTRBR(
      inset,
      inset,
      size.width - inset,
      size.height - inset,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    canvas.drawPath(_dashPath(path), paint);
  }

  Path _dashPath(Path source) {
    final dashed = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      while (distance < metric.length) {
        final length = draw ? dashWidth : dashGap;
        final next = (distance + length).clamp(0, metric.length).toDouble();
        if (draw) {
          dashed.addPath(metric.extractPath(distance, next), Offset.zero);
        }
        distance = next;
        draw = !draw;
      }
    }
    return dashed;
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
