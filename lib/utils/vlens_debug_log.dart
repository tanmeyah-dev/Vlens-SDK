import 'package:flutter/foundation.dart';

/// Debug-only console logs to trace VLens SDK + `/vlens-data` API flow.
///
/// Filter console with `VLENS` to see the full timeline:
/// SDK launch → SDK success/failure → API wait → API response.
class VlensDebugLog {
  VlensDebugLog._();

  static void _print(String tag, String message) {
    if (!kDebugMode) return;
    final ts = DateTime.now().toIso8601String();
    debugPrint('[$ts] [VLENS/$tag] $message');
  }

  static void _banner(String title) {
    if (!kDebugMode) return;
    debugPrint('');
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint(title);
    debugPrint('═══════════════════════════════════════════════════════');
  }

  // ── SDK ──────────────────────────────────────────────────────────────────

  static void sdkLaunchStart({
    required String source,
    required String transactionId,
    required String apiBaseUrl,
    required String tenancyName,
  }) {
    _banner('🚀 VLENS SDK LAUNCH START ($source)');
    _print('SDK', 'transactionId=$transactionId');
    _print('SDK', 'apiBaseUrl=$apiBaseUrl');
    _print('SDK', 'tenancyName=$tenancyName');
    _print('SDK', 'Waiting for VLens SDK onSuccess / onFailure callback...');
  }

  static void sdkLaunchBlocked({required String source, required String reason}) {
    _banner('⛔ VLENS SDK LAUNCH BLOCKED ($source)');
    _print('SDK', reason);
  }

  static void sdkInitCalled() {
    _print('SDK', 'VLensManager.init() called — SDK UI should open now');
  }

  static void sdkSuccess({required String source}) {
    _banner('✅ VLENS SDK SUCCESS ($source)');
    _print('SDK', 'onSuccess fired — extracted data received from VLens');
  }

  static void sdkNavigationDeferred({required String source}) {
    _print(
      'SDK',
      'Deferring app navigation until VLens route pops '
      '(VLensManager calls onSuccess before Navigator.pop)',
    );
  }

  static void sdkRoutePopped({required String source}) {
    _print('SDK', 'VLens FlowController route should be closed now');
  }

  static void sdkFailure({
    required String source,
    required String errorCode,
    required String errorMsg,
  }) {
    _banner('❌ VLENS SDK FAILURE ($source)');
    _print('SDK', 'errorCode=$errorCode');
    _print('SDK', 'errorMsg=$errorMsg');
  }

  /// Fires when neither onSuccess nor onFailure was called within [timeout].
  static void sdkNoCallback({
    required String source,
    required Duration elapsed,
  }) {
    _banner('⏱️ VLENS SDK NO RESPONSE ($source)');
    _print(
      'SDK',
      'No callback after ${elapsed.inSeconds}s — issue is likely inside VLens SDK '
      '(network, camera, or SDK internal). Check VLens side.',
    );
  }

  // ── API (/vlens-data) ────────────────────────────────────────────────────

  static void apiRequestStart({
    required String operation,
    required String method,
    required String url,
    String? phoneNumber,
  }) {
    _banner('📤 VLENS API REQUEST START ($operation)');
    _print('API', '$method $url');
    if (phoneNumber != null) _print('API', 'phoneNumber=$phoneNumber');
    _print('API', 'Waiting for HTTP response...');
  }

  static void apiRequestSuccess({
    required String operation,
    required int statusCode,
    required Duration elapsed,
    String? bodyPreview,
  }) {
    _banner('📥 VLENS API RESPONSE OK ($operation)');
    _print('API', 'statusCode=$statusCode');
    _print('API', 'elapsed=${elapsed.inMilliseconds}ms');
    if (bodyPreview != null) {
      _print('API', 'body=${_truncate(bodyPreview)}');
    }
  }

  static void apiRequestFailed({
    required String operation,
    required Duration elapsed,
    required String reason,
    int? statusCode,
    String? bodyPreview,
  }) {
    _banner('❌ VLENS API RESPONSE FAILED ($operation)');
    _print('API', 'elapsed=${elapsed.inMilliseconds}ms');
    if (statusCode != null) _print('API', 'statusCode=$statusCode');
    _print('API', 'reason=$reason');
    if (bodyPreview != null) {
      _print('API', 'body=${_truncate(bodyPreview)}');
    }
  }

  static void apiRequestError({
    required String operation,
    required Duration elapsed,
    required Object error,
  }) {
    _banner('💥 VLENS API NETWORK ERROR ($operation)');
    _print('API', 'elapsed=${elapsed.inMilliseconds}ms');
    _print('API', 'error=$error');
    _print('API', 'Issue is likely on our side (network/timeout/server unreachable).');
  }

  // ── IdDataBloc ───────────────────────────────────────────────────────────

  static void blocInitializeStart({required bool loadFromApi}) {
    _banner(loadFromApi ? '🔄 ID DATA: GET path (login)' : '🔄 ID DATA: POST path (after scan)');
    _print('BLOC', 'isLoadingVlensData=true — UI shows spinner');
  }

  static void blocInitializeEnd({
    required bool loadFromApi,
    required String outcome,
    Duration? elapsed,
  }) {
    _banner('🏁 ID DATA INITIALIZE DONE');
    _print('BLOC', 'path=${loadFromApi ? "GET" : "POST"}');
    _print('BLOC', 'outcome=$outcome');
    if (elapsed != null) {
      _print('BLOC', 'elapsed=${elapsed.inMilliseconds}ms');
    }
    _print('BLOC', 'isLoadingVlensData=false — spinner should hide');
  }

  static String _truncate(String value, {int max = 800}) {
    if (value.length <= max) return value;
    return '${value.substring(0, max)}… (${value.length} chars total)';
  }
}
