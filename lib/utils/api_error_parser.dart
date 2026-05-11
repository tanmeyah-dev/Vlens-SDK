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

  /// ASP.NET / ProblemDetails style: `{ "title": "...", "errors": { "Key": ["msg"] } }`.
  /// Prefer concrete field messages over generic [title].
  static String? _flattenErrorsMap(dynamic errors) {
    if (errors is! Map) return null;
    final parts = <String>[];
    for (final entry in Map<String, dynamic>.from(errors).entries) {
      final key = entry.key;
      final v = entry.value;
      final keyParts = <String>[];
      if (v is List) {
        for (final item in v) {
          final s = item?.toString().trim();
          if (s != null && s.isNotEmpty) keyParts.add(s);
        }
      } else {
        final s = v?.toString().trim();
        if (s != null && s.isNotEmpty) keyParts.add(s);
      }
      if (keyParts.isEmpty) {
        keyParts.add(_friendlyValidationFieldName(key));
      }
      parts.addAll(keyParts);
    }
    if (parts.isEmpty) return null;
    return parts.join('\n');
  }

  static String _friendlyValidationFieldName(String key) {
    switch (key) {
      case 'MinimumRequiredSignatories':
        return 'لم يُستوفَ العدد الأدنى من الموقّعين المطلوبين لهذا الطلب. '
            'يجب إضافة عدد كافٍ من الموقّعين وفق إعدادات نوع الطلب.';
      default:
        return key;
    }
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
      ];

      for (final key in directKeys) {
        final extracted = _extractFromDynamic(map[key]);
        if (extracted != null && extracted.isNotEmpty) return extracted;
      }

      for (final errorsKey in ['errors', 'Errors']) {
        final flattened = _flattenErrorsMap(map[errorsKey]);
        if (flattened != null && flattened.isNotEmpty) return flattened;
      }

      for (final key in ['title', 'detail', 'Title', 'Detail']) {
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
