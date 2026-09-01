import 'package:permission_handler/permission_handler.dart';

/// Why camera access could not be granted before opening VLens.
enum CameraGateIssue {
  none,
  denied,
  deniedForever,
  restricted,
  unknown,
}

/// Result of resolving camera runtime permission.
class RequiredCameraResult {
  final String errorMessage;
  final CameraGateIssue issue;

  const RequiredCameraResult._({
    required this.errorMessage,
    required this.issue,
  });

  factory RequiredCameraResult.granted() {
    return const RequiredCameraResult._(
      errorMessage: '',
      issue: CameraGateIssue.none,
    );
  }

  factory RequiredCameraResult.failure(
    CameraGateIssue issue,
    String errorMessage,
  ) {
    return RequiredCameraResult._(
      errorMessage: errorMessage,
      issue: issue,
    );
  }

  bool get isGranted => issue == CameraGateIssue.none;
}

/// Requests camera permission before VLens biometric capture.
class RequiredCameraHelper {
  RequiredCameraHelper._();

  /// Ensures camera permission is granted or returns a localized failure (Arabic).
  static Future<RequiredCameraResult> ensure() async {
    var status = await Permission.camera.status;

    if (status.isGranted || status.isLimited) {
      return RequiredCameraResult.granted();
    }

    if (status.isRestricted) {
      return RequiredCameraResult.failure(
        CameraGateIssue.restricted,
        'الكاميرا غير متاحة على هذا الجهاز بسبب قيود النظام.',
      );
    }

    // Always attempt the system prompt when not granted yet — even if the plugin
    // reports permanentlyDenied before the first ask (misconfigured host app).
    status = await Permission.camera.request();

    if (status.isGranted || status.isLimited) {
      return RequiredCameraResult.granted();
    }

    if (status.isPermanentlyDenied) {
      return RequiredCameraResult.failure(
        CameraGateIssue.deniedForever,
        'تم رفض إذن الكاميرا. افتح إعدادات التطبيق وفعّل الكاميرا ثم أعد المحاولة.',
      );
    }

    if (status.isDenied) {
      return RequiredCameraResult.failure(
        CameraGateIssue.denied,
        'يلزم إذن الكاميرا للتحقق من الهوية. اضغط السماح عند الطلب.',
      );
    }

    return RequiredCameraResult.failure(
      CameraGateIssue.unknown,
      'تعذر الوصول إلى الكاميرا. تأكد من إعدادات التطبيق (إذن الكاميرا) ثم أعد المحاولة.',
    );
  }
}
