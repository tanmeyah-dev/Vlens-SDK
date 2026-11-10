import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import 'session_expired_redirect.dart';

/// HTTP client for SDK API calls.
///
/// Debug builds may skip certificate validation for private and loopback
/// hosts. Release and profile builds always use the platform trust store.
class SdkHttpClient {
  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return _send('POST', url, headers: headers, body: body);
  }

  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
  }) {
    return _send('GET', url, headers: headers);
  }

  static Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return _send('PUT', url, headers: headers, body: body);
  }

  static Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
  }) {
    return _send('DELETE', url, headers: headers);
  }

  static Future<http.Response> _send(
    String method,
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    if (!kReleaseMode) {
      // Makes dart:io record the call for the DevTools Network tab.
      HttpClient.enableTimelineLogging = true;
      _logBlock('SDK HTTP request', method, url, headers, body);
    }

    final response = await _withOptionalInsecureTls(url, (client) {
      switch (method) {
        case 'GET':
          return client.get(url, headers: headers);
        case 'PUT':
          return client.put(url, headers: headers, body: body);
        case 'DELETE':
          return client.delete(url, headers: headers);
        default:
          return client.post(url, headers: headers, body: body);
      }
    });

    if (!kReleaseMode) {
      _logBlock(
        'SDK HTTP response ${response.statusCode}',
        method,
        url,
        response.headers,
        response.body,
      );
    }
    return response;
  }

  /// Prints in chunks so DevTools Logging keeps the full URL, body, and response.
  static void _logBlock(
    String title,
    String method,
    Uri url,
    Map<String, String>? headers,
    Object? body,
  ) {
    print('════════ $title ════════');
    print('$method $url');
    if (headers != null && headers.isNotEmpty) {
      print('Headers: $headers');
    }
    final text = body?.toString() ?? '';
    print('Body length: ${text.length}');
    const chunkSize = 800;
    for (var start = 0; start < text.length; start += chunkSize) {
      final end = start + chunkSize < text.length ? start + chunkSize : text.length;
      print(text.substring(start, end));
    }
    print('════════ end $title ════════');
  }

  static Future<http.Response> _withOptionalInsecureTls(
    Uri uri,
    Future<http.Response> Function(http.Client client) request,
  ) async {
    late final http.Response response;
    if (kReleaseMode || kProfileMode || !_shouldAllowInsecureTls(uri)) {
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
    return response;
  }

  static bool _isPrivateOrLocalDevHost(String host) {
    final h = host.toLowerCase();
    return h == 'localhost' ||
        h == '127.0.0.1' ||
        h.startsWith('192.168.') ||
        h.startsWith('10.') ||
        h.startsWith('172.') ||
        h.endsWith('.tanmeyah.lan');
  }

  /// Debug-only. Private and loopback hosts may present a certificate that
  /// is not in the device trust store.
  static bool _shouldAllowInsecureTls(Uri uri) {
    if (!kDebugMode) return false;
    if (uri.scheme != 'https') return false;
    if (!_isPrivateOrLocalDevHost(uri.host)) return false;
    return true;
  }
}
