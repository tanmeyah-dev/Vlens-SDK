import 'package:core/style/app_colors.dart';
import 'package:core/utils/cache/verification_cache.dart';
import 'package:core/utils/network/http_headers_helper.dart';
import 'package:flutter/material.dart';

import '../../../utils/api_exception_message.dart';
import '../model/request_current_response.dart';
import '../scene/request_documents_scene.dart';
import 'request_current_fetcher.dart';

/// Opens [RequestDocumentsScene] after a successful login when the host
/// app entered the SDK with `vlenseStatus == 200`.
class RequestDocumentsNavigator {
  static bool isStatus200(String? status) =>
      status?.toString().trim() == '200';

  static Future<Map<String, String>> _resolveHeaders() async {
    final cache = VerificationCache();
    final accessToken = await cache.getAccessToken();
    final encryptedToken = await cache.getEncryptedAccessToken();
    final token = (accessToken != null && accessToken.trim().isNotEmpty)
        ? accessToken.trim()
        : (encryptedToken ?? '').trim();
    return token.isNotEmpty
        ? HttpHeadersHelper.getHeadersWithAuth(token)
        : HttpHeadersHelper.getDefaultHeaders();
  }

  static Future<void> openAfterLogin(BuildContext context) async {
    return openDocumentsScene(context, logLabel: 'VLENSE_STATUS_200');
  }

  /// Fetches the current request documents and opens [RequestDocumentsScene].
  static Future<void> openDocumentsScene(
    BuildContext context, {
    String logLabel = 'REQUEST_DOCUMENTS',
  }) async {
    if (!context.mounted) return;
    // Avoid !_debugLocked when called right after dismissing another dialog.
    await WidgetsBinding.instance.endOfFrame;
    if (!context.mounted) return;

    var dialogShown = false;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
    dialogShown = true;

    try {
      final headers = await _resolveHeaders();
      final currentResponse = await RequestCurrentFetcher.fetch(
        headers,
        logLabel: logLabel,
      );

      if (!context.mounted) return;
      if (dialogShown) {
        Navigator.of(context).pop();
        dialogShown = false;
      }
      await WidgetsBinding.instance.endOfFrame;
      if (!context.mounted) return;

      final documents =
          currentResponse.data?.documents ?? <RequestCurrentDocument>[];
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => RequestDocumentsScene(
            requestId: currentResponse.data?.id,
            documents: documents,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      if (dialogShown) {
        await WidgetsBinding.instance.endOfFrame;
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(apiExceptionMessage(e)),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}
