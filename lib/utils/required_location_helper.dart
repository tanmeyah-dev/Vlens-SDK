import 'package:geolocator/geolocator.dart';

/// Why location could not be obtained for auth-sensitive flows.
enum LocationGateIssue {
  none,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unableToDetermine,
  positionError,
  unknown,
}

/// Result of resolving GPS coordinates with services + permissions enforced.
class RequiredLocationResult {
  final double? latitude;
  final double? longitude;
  final String errorMessage;
  final LocationGateIssue issue;

  const RequiredLocationResult._({
    this.latitude,
    this.longitude,
    required this.errorMessage,
    required this.issue,
  });

  factory RequiredLocationResult.success(double lat, double lng) {
    return RequiredLocationResult._(
      latitude: lat,
      longitude: lng,
      errorMessage: '',
      issue: LocationGateIssue.none,
    );
  }

  factory RequiredLocationResult.failure(
    LocationGateIssue issue,
    String errorMessage,
  ) {
    return RequiredLocationResult._(
      errorMessage: errorMessage,
      issue: issue,
    );
  }

  bool get hasCoordinates =>
      issue == LocationGateIssue.none &&
      latitude != null &&
      longitude != null &&
      _isPlausibleCoordinate(latitude!, longitude!);

  static bool isInvalidOrPlaceholder(double lat, double lng) {
    return !_isPlausibleCoordinate(lat, lng);
  }

  static bool _isPlausibleCoordinate(double lat, double lng) {
    if (lat.abs() > 90 || lng.abs() > 180) return false;
    // Legacy SDK fallback — not a real position.
    if ((lat - 1.0).abs() < 1e-9 && (lng - 1.0).abs() < 1e-9) return false;
    if (lat == 0 && lng == 0) return false;
    return true;
  }
}

/// Enforces system location (e.g. Android GPS) + runtime permission + a real fix.
class RequiredLocationHelper {
  RequiredLocationHelper._();

  /// Acquire latitude/longitude or a localized failure reason (Arabic).
  static Future<RequiredLocationResult> acquire() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return RequiredLocationResult.failure(
        LocationGateIssue.serviceDisabled,
        'خدمة الموقع غير مفعّلة. فعّل الموقع (GPS) من إعدادات الجهاز ثم أعد المحاولة.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return RequiredLocationResult.failure(
        LocationGateIssue.permissionDenied,
        'يلزم إذن الموقع لتسجيل الدخول أو إنشاء حساب. اضغط السماح عند الطلب.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      return RequiredLocationResult.failure(
        LocationGateIssue.permissionDeniedForever,
        'تم رفض إذن الموقع نهائياً. افتح إعدادات التطبيق وفعّل الموقع.',
      );
    }
    if (permission == LocationPermission.unableToDetermine) {
      return RequiredLocationResult.failure(
        LocationGateIssue.unableToDetermine,
        'تعذر تحديد حالة إذن الموقع. أعد تشغيل التطبيق وحاول مرة أخرى.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 20),
      );
      if (!RequiredLocationResult._isPlausibleCoordinate(
        position.latitude,
        position.longitude,
      )) {
        return RequiredLocationResult.failure(
          LocationGateIssue.positionError,
          'تم استلام إحداثيات غير صالحة. تأكد من تفعيل GPS وحاول مرة أخرى.',
        );
      }
      return RequiredLocationResult.success(
        position.latitude,
        position.longitude,
      );
    } catch (e, st) {
      // ignore: avoid_print
      print('RequiredLocationHelper.acquire error: $e\n$st');
      return RequiredLocationResult.failure(
        LocationGateIssue.positionError,
        'تعذر تحديد موقعك الحالي. تأكد من تفعيل GPS وأنك في مكان يمكن فيه استقبال الإشارة، ثم أعد المحاولة.',
      );
    }
  }
}
