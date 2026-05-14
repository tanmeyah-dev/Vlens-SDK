import 'package:core/components/button/app_button.dart';
import 'package:core/components/image/app_image.dart';
import 'package:core/style/app_colors.dart';
import 'package:core/utils/ui.dart';
import 'package:core/utils/cache/verification_cache.dart';
import 'package:core/utils/network/http_headers_helper.dart';
import 'package:flutter/material.dart';

import '../model/request_current_response.dart';
import '../utils/request_current_fetcher.dart';
import 'request_documents_scene.dart';
import 'request_submitted_scene.dart';

/// Shown after successful [request/create]; calls [request/current] only after user taps continue.
class WaitingApprovalScreen extends StatefulWidget {
  final dynamic requestId;

  const WaitingApprovalScreen({
    super.key,
    required this.requestId,
  });

  @override
  State<WaitingApprovalScreen> createState() => _WaitingApprovalScreenState();
}

class _WaitingApprovalScreenState extends State<WaitingApprovalScreen> {
  bool _isLoading = false;

  Future<Map<String, String>> _resolveHeaders() async {
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

  Future<void> _onContinuePressed() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final headers = await _resolveHeaders();
      final currentResponse =
          await RequestCurrentFetcher.fetch(headers, logLabel: 'WAITING_APPROVAL');

      final currentRequestId = currentResponse.data?.id ?? widget.requestId;
      final documents =
          currentResponse.data?.documents ?? <RequestCurrentDocument>[];

      if (!mounted) return;

      if (documents.isNotEmpty) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => RequestDocumentsScene(
              requestId: currentRequestId,
              documents: documents,
            ),
          ),
        );
      } else {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => RequestSubmittedScene(requestId: currentRequestId),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.primary,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const AppImage(
            AppAssets.tanmeyah,
            height: 44,
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
            child: AppButton(
              title: _isLoading ? 'جاري التحميل...' : 'استكمال البيانات',
              onPressed: _isLoading ? null : _onContinuePressed,
            ),
          ),
        ),
        body: ColoredBox(
          color: AppColors.white,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Expanded(
                    child: Center(
                      child: Text(
                        'تم إنشاء طلبك بنجاح',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        height: 28,
                        width: 28,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
