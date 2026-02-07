/// Helper class for managing HTTP headers
class HttpHeadersHelper {
  /// API Key for all requests
  static const String apiKey = 'j1m9DwIywPS1dPCkFUT2hM2IRr10921gq5PBzQID6xI';

  /// Get default headers for API requests
  static Map<String, String> getDefaultHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Accept-Language': 'ar', // Arabic as default language
      'ApiKey': apiKey,
    };
  }

  /// Get headers with authorization token
  static Map<String, String> getHeadersWithAuth(String token) {
    final headers = getDefaultHeaders();
    headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  /// Get headers with custom content type
  static Map<String, String> getHeadersWithContentType(String contentType) {
    final headers = getDefaultHeaders();
    headers['Content-Type'] = contentType;
    return headers;
  }
}
