import 'dart:convert';

import 'package:tan_sdk/data/models/extracted_user_data.dart';

ExtractedUserData? parseExtractedUserData(dynamic value) {
  if (value == null) return null;
  if (value is ExtractedUserData) return value;
  if (value is Map<String, dynamic>) {
    return ExtractedUserData.fromJson(value);
  }
  if (value is Map) {
    return ExtractedUserData.fromJson(
      Map<String, dynamic>.from(value),
    );
  }

  try {
    final encoded = jsonEncode(value);
    final decoded = jsonDecode(encoded);
    if (decoded is Map<String, dynamic>) {
      return ExtractedUserData.fromJson(decoded);
    }
    if (decoded is Map) {
      return ExtractedUserData.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    }
  } catch (_) {
    // Best effort parser only.
  }
  return null;
}

dynamic normalizeDynamicData(dynamic value) {
  if (value == null) return null;
  if (value is Map || value is List || value is String || value is num || value is bool) {
    return value;
  }

  try {
    final encoded = jsonEncode(value);
    return jsonDecode(encoded);
  } catch (_) {
    return '$value';
  }
}
