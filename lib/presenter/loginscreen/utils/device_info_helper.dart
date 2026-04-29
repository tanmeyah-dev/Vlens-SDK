import 'dart:io';
import 'package:core/utils/cache/verification_cache.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';

class DeviceInfoHelper {
  static const double _defaultLatitude = 1.0;
  static const double _defaultLongitude = 1.0;
  static Map<String, double>? _memoryCachedLocation;
  static Future<Map<String, double>>? _ongoingLocationRequest;

  /// Get device IMEI (Android) or identifierForVendor (iOS)
  static Future<String> getDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        // For Android, we can use androidId or try to get IMEI
        // Note: Getting IMEI requires READ_PHONE_STATE permission and may not work on all devices
        // Using androidId as a fallback which is unique per device
        return androidInfo.id; // This is the Android ID
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown-device-id';
      }
      
      return 'unknown-device-id';
    } catch (e) {
      print('Error getting device ID: $e');
      return 'unknown-device-id';
    }
  }

  /// Get current geolocation
  static Future<Map<String, double>> getCurrentLocation() async {
    final cachedInMemory = _memoryCachedLocation;
    if (cachedInMemory != null) {
      return cachedInMemory;
    }

    _ongoingLocationRequest ??= _loadOrFetchAndCacheLocation();
    final location = await _ongoingLocationRequest!;
    _ongoingLocationRequest = null;
    return location;
  }

  static Future<Map<String, double>> _loadOrFetchAndCacheLocation() async {
    final persistentCached = await VerificationCache().getGeoLocation();
    if (persistentCached != null) {
      _memoryCachedLocation = persistentCached;
      return persistentCached;
    }

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return _cacheAndReturnDefaultLocation();
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          return _cacheAndReturnDefaultLocation();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        return _cacheAndReturnDefaultLocation();
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low, // Use low accuracy for faster response
        timeLimit: const Duration(seconds: 5), // Timeout after 5 seconds
      );

      final location = {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
      _memoryCachedLocation = location;
      await VerificationCache().setGeoLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      return location;
    } catch (e) {
      print('Error getting location: $e');
      return _cacheAndReturnDefaultLocation();
    }
  }

  static Future<Map<String, double>> _cacheAndReturnDefaultLocation() async {
    final fallback = {
      'latitude': _defaultLatitude,
      'longitude': _defaultLongitude,
    };
    _memoryCachedLocation = fallback;
    await VerificationCache().setGeoLocation(
      latitude: _defaultLatitude,
      longitude: _defaultLongitude,
    );
    return fallback;
  }
}
