import 'dart:convert';

class ApiErrorParser {
  static String extractMessage(
    String? rawBody, {
    String fallbackMessage = 'حدث خطأ غير متوقع',
  }) {
    if (rawBody == null || rawBody.trim().isEmpty) {
      return fallbackMessage;
    }

    try {
      final decoded = jsonDecode(rawBody);
      final message = _extractFromDynamic(decoded);
      if (message != null && message.trim().isNotEmpty) {
        return message.trim();
      }
    } catch (_) {
      // Ignore malformed JSON and return fallback.
    }

    return fallbackMessage;
  }

  static String? _extractFromDynamic(dynamic value) {
    if (value == null) return null;
    if (value is String && value.trim().isNotEmpty) return value.trim();

    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      final directKeys = <String>[
        'message',
        'Message',
        'error',
        'Error',
        'errorMessage',
        'ErrorMessage',
        'error_message',
        'title',
        'detail',
      ];

      for (final key in directKeys) {
        final extracted = _extractFromDynamic(map[key]);
        if (extracted != null && extracted.isNotEmpty) return extracted;
      }

      final dataExtracted = _extractFromDynamic(map['data']);
      if (dataExtracted != null && dataExtracted.isNotEmpty) return dataExtracted;

      final errorsExtracted = _extractFromDynamic(map['errors']);
      if (errorsExtracted != null && errorsExtracted.isNotEmpty) return errorsExtracted;

      for (final entry in map.values) {
        final extracted = _extractFromDynamic(entry);
        if (extracted != null && extracted.isNotEmpty) return extracted;
      }
    }

    if (value is List) {
      for (final item in value) {
        final extracted = _extractFromDynamic(item);
        if (extracted != null && extracted.isNotEmpty) return extracted;
      }
    }

    return null;
  }
}
