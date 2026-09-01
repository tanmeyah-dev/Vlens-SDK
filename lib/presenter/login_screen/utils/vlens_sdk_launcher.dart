import 'dart:async';

import 'package:core/utils/cache/verification_cache.dart';
import 'package:core/utils/ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vlens/vlens.dart';

import '../../../utils/camera_permission_dialog_helper.dart';
import '../../../utils/required_camera_helper.dart';
import '../model/login_response.dart';
import 'vlens_sdk_credentials.dart';

/// Fast path to open VLens: camera permission → credentials → init → cache in background.
class VlensSdkLauncher {
  VlensSdkLauncher._();

  static const String cameraPermissionDeniedMessage =
      'يلزم إذن الكاميرا للتحقق من الهوية. اضغط السماح عند الطلب.';

  static final ColorsConfig _colors = ColorsConfig(
    light: ColorConfig(
      accent: '#4E5A78',
      primary: '#397374',
      secondary: '#FF4081',
      background: '#FEFEFE',
      dark: '#000000',
      light: '#FFFFFF',
    ),
    dark: ColorConfig(
      accent: '#FFC107',
      primary: '#2196F3',
      secondary: '#FF4081',
      background: '#000000',
      dark: '#FFFFFF',
      light: '#000000',
    ),
  );

  /// Returns `false` when camera permission or credentials are missing.
  static Future<bool> launch({
    required BuildContext context,
    required LoginResponseData loginResponseData,
    required void Function(dynamic extractedData) onSuccess,
    required void Function(String errorCode, String errorMsg) onFailure,
    String? missingMessageOut,
    void Function(CameraGateIssue issue)? onCameraPermissionDenied,
  }) async {
    final granted = await CameraPermissionDialogHelper.ensureWithUi(context);
    if (!granted) {
      onCameraPermissionDenied?.call(CameraGateIssue.denied);
      return false;
    }

    final credentials = VlensSdkCredentials.tryResolve(loginResponseData);
    if (credentials == null || !credentials.isReadyForVlensInit) {
      return false;
    }

    // Persist session in background — do not block SDK open.
    unawaited(
      VerificationCache().setLoginSession(
        accessToken: credentials.accessToken,
        refreshToken: credentials.refreshToken,
        encryptedAccessToken: loginResponseData.encryptedAccessToken,
        transactionId: credentials.transactionId,
        userName: loginResponseData.userName,
        userFullName: loginResponseData.userFullName,
        nationalId: loginResponseData.nationalId,
      ),
    );

    if (kDebugMode) {
      print('🚀 VLens init tx=${credentials.transactionId}');
    }

    final sdkConfig = SdkConfig(
      transactionId: credentials.transactionId,
      isLivenessOnly: false,
      isNationalIdOnly: false,
      logoPath: AppAssets.tanmeyah,
      env: EnvironmentConfig(
        apiBaseUrl: credentials.apiBaseUrl,
        accessToken: credentials.accessToken,
        refreshToken: credentials.refreshToken,
        apiKey: credentials.apiKey,
        tenancyName: credentials.tenancyName,
      ),
      defaultLocale: 'ar',
      colors: _colors,
      errorMessages: [
        ApiError(
          errorCode: 101,
          errorMessageEn: 'Network error',
          errorMessageAr: 'خطأ في الشبكة',
        ),
      ],
      onSuccess: onSuccess,
      onFailure: onFailure,
      getExtractedData: true,
      // Slightly snappier capture UX; SDK still retries.
      detectionRetryCounter: 3,
      enableSounds: false,
    );

    if (!context.mounted) {
      return false;
    }

    VLensManager().init(context, sdkConfig);
    return true;
  }

  static String missingMessage(LoginResponseData data) =>
      VlensSdkCredentials.missingFieldsMessage(data);
}
