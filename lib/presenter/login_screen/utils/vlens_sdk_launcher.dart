import 'dart:async';

import 'package:core/utils/cache/verification_cache.dart';
import 'package:core/utils/ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vlens/vlens.dart';

import '../../../utils/vlens_debug_log.dart';
import '../model/login_response.dart';
import 'vlens_sdk_credentials.dart';

/// If VLens SDK never calls back, log after this duration (debug only).
const Duration _kVlensCallbackWatchdog = Duration(minutes: 5);

/// Fast path to open VLens: resolve credentials → init immediately → cache in background.
class VlensSdkLauncher {
  VlensSdkLauncher._();

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

  /// Returns `false` when credentials are missing (caller should show [missingMessage]).
  static bool launch({
    required BuildContext context,
    required LoginResponseData loginResponseData,
    required void Function(dynamic extractedData) onSuccess,
    required void Function(String errorCode, String errorMsg) onFailure,
    String? missingMessageOut,
    String source = 'unknown',
  }) {
    final credentials = VlensSdkCredentials.tryResolve(loginResponseData);
    if (credentials == null || !credentials.isReadyForVlensInit) {
      VlensDebugLog.sdkLaunchBlocked(
        source: source,
        reason: VlensSdkCredentials.missingFieldsMessage(loginResponseData),
      );
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

    VlensDebugLog.sdkLaunchStart(
      source: source,
      transactionId: credentials.transactionId,
      apiBaseUrl: credentials.apiBaseUrl,
      tenancyName: credentials.tenancyName,
    );

    var callbackReceived = false;
    Timer? watchdog;
    if (kDebugMode) {
      watchdog = Timer(_kVlensCallbackWatchdog, () {
        if (!callbackReceived) {
          VlensDebugLog.sdkNoCallback(
            source: source,
            elapsed: _kVlensCallbackWatchdog,
          );
        }
      });
    }

    void finishWatchdog() {
      callbackReceived = true;
      watchdog?.cancel();
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
      onSuccess: (data) {
        finishWatchdog();
        VlensDebugLog.sdkSuccess(source: source);
        // VLensManager calls config.onSuccess, then Navigator.pop() on its route.
        // Pushing a screen inside onSuccess gets undone by that pop — user stays on
        // VLens loading UI. Run app logic on the next frame after the pop.
        VlensDebugLog.sdkNavigationDeferred(source: source);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          VlensDebugLog.sdkRoutePopped(source: source);
          onSuccess(data);
        });
      },
      onFailure: (errorCode, errorMsg) {
        finishWatchdog();
        VlensDebugLog.sdkFailure(
          source: source,
          errorCode: errorCode,
          errorMsg: errorMsg,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onFailure(errorCode, errorMsg);
        });
      },
      getExtractedData: true,
      // Slightly snappier capture UX; SDK still retries.
      detectionRetryCounter: 3,
      enableSounds: false,
    );

    VlensDebugLog.sdkInitCalled();
    VLensManager().init(context, sdkConfig);
    return true;
  }

  static String missingMessage(LoginResponseData data) =>
      VlensSdkCredentials.missingFieldsMessage(data);
}
