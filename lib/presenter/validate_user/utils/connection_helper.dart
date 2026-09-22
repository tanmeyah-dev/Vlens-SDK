import 'dart:io';
import '../constants/api_urls.dart';

/// Helper class to diagnose and fix connection issues
class ConnectionHelper {
  /// Get troubleshooting instructions based on the current configuration
  static String getTroubleshootingInstructions() {
    final baseUrl = ApiUrls.getLocalBaseUrl();
    final isEmulator = !ApiUrls.usePhysicalDeviceIp;
    
    String instructions = '';
    
    if (isEmulator) {
      instructions = '''
للأندرويد المحاكي:
• تأكد أن الخادم يعمل على localhost:8055 على جهازك
• جرب في Terminal: curl -k $baseUrl/vlens/api/v1/digital/identity/verify/phone
• إذا كان الخادم يستخدم HTTP وليس HTTPS، قم بتغيير ApiUrls.useHttps = false
• تأكد أن الخادم يعمل قبل تشغيل التطبيق
''';
    } else {
      instructions = '''
للجهاز الفعلي:
• تأكد أن الخادم يعمل على 192.168.54.117:8055
• تأكد أن جهازك على نفس شبكة Wi-Fi
• جرب في Terminal: curl -k $baseUrl/vlens/api/v1/digital/identity/verify/phone
• تأكد أن الجدار الناري يسمح بالاتصال على المنفذ 8055
''';
    }
    
    return instructions;
  }
  
  /// Test if server is reachable (basic check)
  static Future<bool> testConnection() async {
    try {
      final url = ApiUrls.getVerifyPhoneUrl();
      final uri = Uri.parse(url);
      
      // Try to connect to the server
      final socket = await Socket.connect(
        uri.host,
        uri.port,
        timeout: const Duration(seconds: 5),
      );
      await socket.close();
      return true;
    } catch (e) {
      print('❌ Connection test failed: $e');
      return false;
    }
  }
  
  /// Get the expected server URL for manual testing
  static String getExpectedServerUrl() {
    if (ApiUrls.usePhysicalDeviceIp) {
      return '192.168.54.117:8055';
    } else {
      return 'localhost:8055';
    }
  }
}
