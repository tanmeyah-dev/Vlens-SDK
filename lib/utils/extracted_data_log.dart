import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:tan_sdk/data/models/extracted_user_data.dart';

/// Debug-only: logs normalized VLens identity payload after login / verification success.
void logExtractedDataAfterLogin(dynamic extractedData, {String context = ''}) {
  if (!kDebugMode) return;
  final tag = context.isEmpty ? 'VLENS extractedData' : 'VLENS extractedData ($context)';
  try {
    final dynamic serializable = extractedData is ExtractedUserData
        ? extractedData.toJson()
        : jsonDecode(jsonEncode(extractedData));
    final pretty = const JsonEncoder.withIndent('  ').convert(serializable);
    debugPrint('[$tag]\n$pretty');
  } catch (e) {
    debugPrint('[$tag] JSON encode failed ($e): $extractedData');
  }
}
