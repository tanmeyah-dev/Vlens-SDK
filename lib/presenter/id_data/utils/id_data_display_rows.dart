import 'package:tan_sdk/data/models/extracted_user_data.dart';

String _formatDate(DateTime? date) {
  if (date == null) return '';
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  return '$day-$month-$year';
}

String? _nonEmpty(String? v) {
  final t = v?.trim();
  if (t == null || t.isEmpty) return null;
  return t;
}

void _addRow(List<MapEntry<String, String>> rows, String labelAr, String? value) {
  final v = _nonEmpty(value);
  if (v == null) return;
  rows.add(MapEntry(labelAr, v));
}

void _addDateRow(List<MapEntry<String, String>> rows, String labelAr, DateTime? d) {
  if (d == null) return;
  rows.add(MapEntry(labelAr, _formatDate(d)));
}

/// User-facing rows: Arabic labels only (same mapping as legacy digital identity screen).
List<MapEntry<String, String>> buildIdDataDisplayRows(ExtractedUserData? data) {
  final rows = <MapEntry<String, String>>[];
  if (data == null) {
    return [const MapEntry('لا توجد بيانات', '')];
  }

  final u = data.user;
  final f = data.idFrontData;
  final b = data.idBackData;

  final combinedUserName = [
    u?.name,
    u?.surname,
  ].whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty).join(' ');
  final name = _nonEmpty(f?.name) ??
      _nonEmpty(u?.fullName) ??
      _nonEmpty(combinedUserName.isEmpty ? null : combinedUserName);
  _addRow(rows, 'الاسم', name);

  final idNumber = _nonEmpty(f?.idNumber) ?? _nonEmpty(b?.idNumber) ?? _nonEmpty(u?.idNumber);
  _addRow(rows, 'رقم الهوية', idNumber);

  _addDateRow(rows, 'تاريخ الميلاد', f?.dateOfBirth);

  final gender = _nonEmpty(f?.gender) ?? _nonEmpty(b?.gender);
  _addRow(rows, 'النوع', gender);

  final address = _nonEmpty(f?.address) ?? _nonEmpty(u?.address);
  _addRow(rows, 'العنوان', address);

  _addRow(rows, 'المحافظة', f?.govern);
  _addRow(rows, 'المدينة', f?.city);
  _addRow(rows, 'المنطقة', f?.district);

  _addRow(rows, 'الحالة الاجتماعية', b?.maritalStatus);
  _addRow(rows, 'المهنة', b?.job);
  _addRow(rows, 'المسمى الوظيفي', b?.jobTitle);
  _addRow(rows, 'الدين', b?.religion);
  _addRow(rows, 'اسم الزوج', b?.husbandName);

  _addDateRow(rows, 'تاريخ الإصدار', b?.releaseDate);
  _addDateRow(rows, 'تاريخ انتهاء الهوية', b?.idExpiry);

  _addRow(rows, 'رقم الهاتف', u?.phoneNumber);
  _addRow(rows, 'البريد الإلكتروني', u?.emailAddress);
  _addRow(rows, 'اسم المستخدم', u?.userName);

  if (rows.isEmpty) {
    return [const MapEntry('لا توجد بيانات', '')];
  }
  return rows;
}
