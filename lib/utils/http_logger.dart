import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// HTTP client wrapper that automatically logs all requests and responses.
class HttpLogger {
  static int _requestCounter = 0;

  /// Logs HTTP request details
  static void logRequest({
    required String method,
    required String url,
    Map<String, String>? headers,
    Object? body,
  }) {
    _requestCounter++;
    final timestamp = DateTime.now().toIso8601String();
    
    print('');
    print('═══════════════════════════════════════════════════════════════════');
    print('📤 HTTP REQUEST #$_requestCounter');
    print('═══════════════════════════════════════════════════════════════════');
    print('⏰ Timestamp: $timestamp');
    print('🔗 URL: $url');
    print('📝 Method: $method');
    
    if (headers != null && headers.isNotEmpty) {
      print('📋 Headers:');
      headers.forEach((key, value) {
        // Mask sensitive headers
        if (key.toLowerCase().contains('authorization') || 
            key.toLowerCase().contains('token') ||
            key.toLowerCase().contains('api-key')) {
          print('   $key: ${value.substring(0, value.length > 10 ? 10 : value.length)}***');
        } else {
          print('   $key: $value');
        }
      });
    }
    
    if (body != null) {
      print('📦 Body:');
      if (body is String) {
        try {
          // Try to format JSON
          final jsonBody = jsonDecode(body);
          print('   ${const JsonEncoder.withIndent('   ').convert(jsonBody)}');
        } catch (_) {
          print('   $body');
        }
      } else if (body is Map) {
        print('   ${const JsonEncoder.withIndent('   ').convert(body)}');
      } else {
        print('   $body');
      }
    }
    
    print('═══════════════════════════════════════════════════════════════════');
    print('');
    
    // Also log to debug console
    debugPrint('📤 HTTP REQUEST #$_requestCounter: $method $url');
  }

  /// Logs HTTP response details
  static void logResponse({
    required int requestNumber,
    required int statusCode,
    required Map<String, String> headers,
    required String body,
    String? url,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final isSuccess = statusCode >= 200 && statusCode < 300;
    
    print('');
    print('═══════════════════════════════════════════════════════════════════');
    print('📥 HTTP RESPONSE #$requestNumber ${isSuccess ? '✅' : '❌'}');
    print('═══════════════════════════════════════════════════════════════════');
    print('⏰ Timestamp: $timestamp');
    if (url != null) {
      print('🔗 URL: $url');
    }
    print('📊 Status Code: $statusCode ${_getStatusText(statusCode)}');
    
    if (headers.isNotEmpty) {
      print('📋 Headers:');
      headers.forEach((key, value) {
        print('   $key: $value');
      });
    }
    
    print('📦 Body:');
    try {
      // Try to format JSON
      final jsonBody = jsonDecode(body);
      print('   ${const JsonEncoder.withIndent('   ').convert(jsonBody)}');
    } catch (_) {
      // Not JSON, print as is
      final bodyPreview = body.length > 500 ? '${body.substring(0, 500)}...' : body;
      print('   $bodyPreview');
    }
    
    print('═══════════════════════════════════════════════════════════════════');
    print('');
    
    // Also log to debug console
    debugPrint('📥 HTTP RESPONSE #$requestNumber: $statusCode ${isSuccess ? '✅' : '❌'}');
  }

  /// Logs HTTP error
  static void logError({
    required int requestNumber,
    required dynamic error,
    String? url,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    
    print('');
    print('═══════════════════════════════════════════════════════════════════');
    print('❌❌❌ HTTP ERROR #$requestNumber ❌❌❌');
    print('═══════════════════════════════════════════════════════════════════');
    print('⏰ Timestamp: $timestamp');
    if (url != null) {
      print('🔗 URL: $url');
    }
    print('💥 Error: $error');
    print('═══════════════════════════════════════════════════════════════════');
    print('');
    
    // Also log to debug console
    debugPrint('❌ HTTP ERROR #$requestNumber: $error');
  }

  /// Performs a GET request with automatic logging
  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    final requestNumber = _requestCounter + 1;
    logRequest(
      method: 'GET',
      url: url.toString(),
      headers: headers,
    );

    try {
      final response = await http.get(url, headers: headers);
      logResponse(
        requestNumber: requestNumber,
        statusCode: response.statusCode,
        headers: response.headers,
        body: response.body,
        url: url.toString(),
      );
      return response;
    } catch (e) {
      logError(requestNumber: requestNumber, error: e, url: url.toString());
      rethrow;
    }
  }

  /// Performs a POST request with automatic logging
  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final requestNumber = _requestCounter + 1;
    logRequest(
      method: 'POST',
      url: url.toString(),
      headers: headers,
      body: body,
    );

    try {
      final response = await http.post(url, headers: headers, body: body);
      logResponse(
        requestNumber: requestNumber,
        statusCode: response.statusCode,
        headers: response.headers,
        body: response.body,
        url: url.toString(),
      );
      return response;
    } catch (e) {
      logError(requestNumber: requestNumber, error: e, url: url.toString());
      rethrow;
    }
  }

  /// Performs a PUT request with automatic logging
  static Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final requestNumber = _requestCounter + 1;
    logRequest(
      method: 'PUT',
      url: url.toString(),
      headers: headers,
      body: body,
    );

    try {
      final response = await http.put(url, headers: headers, body: body);
      logResponse(
        requestNumber: requestNumber,
        statusCode: response.statusCode,
        headers: response.headers,
        body: response.body,
        url: url.toString(),
      );
      return response;
    } catch (e) {
      logError(requestNumber: requestNumber, error: e, url: url.toString());
      rethrow;
    }
  }

  /// Performs a DELETE request with automatic logging
  static Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    final requestNumber = _requestCounter + 1;
    logRequest(
      method: 'DELETE',
      url: url.toString(),
      headers: headers,
    );

    try {
      final response = await http.delete(url, headers: headers);
      logResponse(
        requestNumber: requestNumber,
        statusCode: response.statusCode,
        headers: response.headers,
        body: response.body,
        url: url.toString(),
      );
      return response;
    } catch (e) {
      logError(requestNumber: requestNumber, error: e, url: url.toString());
      rethrow;
    }
  }

  /// Gets human-readable status text
  static String _getStatusText(int statusCode) {
    switch (statusCode) {
      case 200:
        return '(OK)';
      case 201:
        return '(Created)';
      case 204:
        return '(No Content)';
      case 400:
        return '(Bad Request)';
      case 401:
        return '(Unauthorized)';
      case 403:
        return '(Forbidden)';
      case 404:
        return '(Not Found)';
      case 500:
        return '(Internal Server Error)';
      case 502:
        return '(Bad Gateway)';
      case 503:
        return '(Service Unavailable)';
      default:
        return '';
    }
  }
}
