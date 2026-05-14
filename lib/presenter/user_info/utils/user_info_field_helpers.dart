import '../model/request_fields_response.dart';

String formatDateDdMmYyyy(DateTime d) {
  final day = d.day.toString().padLeft(2, '0');
  final month = d.month.toString().padLeft(2, '0');
  final year = d.year.toString();
  return '$day-$month-$year';
}

bool parseBoolLoose(String? raw) {
  if (raw == null) return false;
  final s = raw.trim().toLowerCase();
  return s == 'true' ||
      s == '1' ||
      s == 'yes' ||
      s == 'y' ||
      s == 'نعم';
}

DateTime? parseDateLoose(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final v = raw.trim();
  try {
    return DateTime.parse(v);
  } catch (_) {}
  final sep = RegExp(r'[-/.]');
  final parts = v.split(sep);
  if (parts.length == 3) {
    final a = int.tryParse(parts[0]);
    final b = int.tryParse(parts[1]);
    final c = int.tryParse(parts[2]);
    if (a != null && b != null && c != null) {
      if (a > 31) {
        return DateTime(a, b, c);
      }
      if (c > 31) {
        return DateTime(c, b, a);
      }
    }
  }
  return null;
}

void initMultiSelectFromField(
  RequestFieldItem field,
  Map<String, Set<String>> multiSelectValues,
) {
  final allowed = field.availableValues.toSet();
  final chosen = <String>{};
  final multi = field.multiValues;
  if (multi != null) {
    for (final item in multi) {
      if (allowed.contains(item)) chosen.add(item);
    }
  } else if (field.value != null && field.value!.trim().isNotEmpty) {
    for (final part in field.value!.split(',')) {
      final t = part.trim();
      if (allowed.contains(t)) chosen.add(t);
    }
  }
  multiSelectValues[field.key] = chosen;
}
