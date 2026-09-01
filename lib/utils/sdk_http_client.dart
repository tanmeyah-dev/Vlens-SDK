import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import 'api_business_exception.dart';
import 'session_expired_redirect.dart';

/// HTTP client for SDK API calls.
///
/// HTTPS to private / loopback hosts can skip certificate validation
/// (self-signed dev servers) in all build modes.
///
/// For production or store builds, use a CA-trusted certificate on the server
/// instead of relying on insecure TLS.
class SdkHttpClient {
  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return _withOptionalInsecureTls(
      url,
      (client) => client.post(url, headers: headers, body: body),
    );
  }

  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    return _withOptionalInsecureTls(
      url,
      (client) => client.get(url, headers: headers),
    );
  }

  static Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return _withOptionalInsecureTls(
      url,
      (client) => client.put(url, headers: headers, body: body),
    );
  }

  static Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    return _withOptionalInsecureTls(
      url,
      (client) => client.delete(url, headers: headers),
    );
  }

  static Future<http.Response> _withOptionalInsecureTls(
    Uri uri,
    Future<http.Response> Function(http.Client client) request,
  ) async {
    late final http.Response response;
    if (!_shouldAllowInsecureTls(uri)) {
      final client = http.Client();
      try {
        response = await request(client);
      } finally {
        client.close();
      }
    } else {
      final ioHttpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => host == uri.host;
      final ioClient = IOClient(ioHttpClient);
      try {
        response = await request(ioClient);
      } finally {
        ioClient.close();
      }
    }

    SessionExpiredRedirect.handle(response, requestUri: uri);
    ApiBusinessResponse.ensureSuccess(response, requestUri: uri);
    return response;
  }

  static bool _isPrivateOrLocalDevHost(String host) {
    final h = host.toLowerCase();
    return h == 'localhost' ||
        h == '127.0.0.1' ||
        h.startsWith('192.168.') ||
        h.startsWith('10.') ||
        h.startsWith('172.');
  }

  /// Use [IOClient] with [badCertificateCallback] only for known private dev hosts.
  static bool _shouldAllowInsecureTls(Uri uri) {
    if (uri.scheme != 'https') return false;
    if (!_isPrivateOrLocalDevHost(uri.host)) return false;
    return true;
  }
}
