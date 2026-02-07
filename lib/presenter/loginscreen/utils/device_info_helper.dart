import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';

class DeviceInfoHelper {
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
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return {'latitude': 1.0, 'longitude': 1.0};
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          return {'latitude': 1.0, 'longitude': 1.0};
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        return {'latitude': 1.0, 'longitude': 1.0};
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low, // Use low accuracy for faster response
        timeLimit: const Duration(seconds: 5), // Timeout after 5 seconds
      );

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    } catch (e) {
      print('Error getting location: $e');
      // Return default values if location cannot be obtained
      return {'latitude': 1.0, 'longitude': 1.0};
    }
  }
}
