import 'package:core/style/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'required_camera_helper.dart';

/// Presents camera permission UI when [RequiredCameraHelper.ensure] fails.
class CameraPermissionDialogHelper {
  CameraPermissionDialogHelper._();

  /// Requests permission; if still blocked, shows a dialog with retry / settings.
  /// Returns `true` when camera access is granted.
  static Future<bool> ensureWithUi(BuildContext context) async {
    var result = await RequiredCameraHelper.ensure();
    if (result.isGranted) return true;
    if (!context.mounted) return false;

    while (!result.isGranted) {
      if (!context.mounted) return false;

      final action = await showDialog<_CameraDialogAction>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          final openSettings =
              result.issue == CameraGateIssue.deniedForever ||
                  result.issue == CameraGateIssue.restricted;

          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text(
                'إذن الكاميرا مطلوب',
                textAlign: TextAlign.right,
              ),
              content: Text(
                result.errorMessage,
                textAlign: TextAlign.right,
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(_CameraDialogAction.cancel),
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                if (openSettings)
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext)
                        .pop(_CameraDialogAction.openSettings),
                    child: const Text(
                      'فتح الإعدادات',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  )
                else
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext)
                        .pop(_CameraDialogAction.retry),
                    child: const Text(
                      'إعادة المحاولة',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
              ],
            ),
          );
        },
      );

      if (action == null || action == _CameraDialogAction.cancel) {
        return false;
      }

      if (action == _CameraDialogAction.openSettings) {
        await openAppSettings();
        // User may grant in settings — re-check when they return.
        if (!context.mounted) return false;
        result = await RequiredCameraHelper.ensure();
        continue;
      }

      result = await RequiredCameraHelper.ensure();
    }

    return result.isGranted;
  }
}

enum _CameraDialogAction { retry, openSettings, cancel }
