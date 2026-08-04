import 'package:tan_sdk/data/models/extracted_user_data.dart';

import '../model/lookups_response.dart';
import '../model/request_fields_response.dart';

String normalizeLookupKey(String raw) {
  return raw.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
}

/// Arabic labels for standalone lookup dropdowns.
const Map<String, String> lookupDropdownLabelsAr = {
  'CIF_QUALIFICATION_ID': 'المؤهل',
  'CIF_RELIGION': 'الديانة',
  'CIF_LICENSE_TYPE': 'نوع الرخصة',
  'CIF_GENDER': 'النوع',
  'PHONE': 'نوع الهاتف',
  'CIF_SOCIAL_STATUS': 'الحالة الاجتماعية',
  'CIF_HEALTH_STATUS': 'الحالة الصحية',
  'RISK': 'درجة المخاطر',
  'CIF_NATION_CODE': 'الجنسية',
  'CIF_GRANTS': 'المنح',
};

/// Builds select fields from lookups so they always appear on user_info.
List<RequestFieldItem> buildLookupSelectFields(Lookups? lookups) {
  if (lookups == null) return const [];

  final entries = <MapEntry<String, List<LookupItem>>>[
    MapEntry('CIF_QUALIFICATION_ID', lookups.cifQualificationId),
    MapEntry('CIF_RELIGION', lookups.cifReligion),
    MapEntry('CIF_LICENSE_TYPE', lookups.cifLicenseType),
    MapEntry('CIF_GENDER', lookups.cifGender),
    MapEntry('PHONE', lookups.phone),
    MapEntry('CIF_SOCIAL_STATUS', lookups.cifSocialStatus),
    MapEntry('CIF_HEALTH_STATUS', lookups.cifHealthStatus),
    MapEntry('RISK', lookups.risk),
    MapEntry('CIF_NATION_CODE', lookups.cifNationCode),
    MapEntry('CIF_GRANTS', lookups.cifGrants),
  ];

  final fields = <RequestFieldItem>[];
  var order = 1000;
  for (final entry in entries) {
    if (entry.value.isEmpty) continue;
    final label = lookupDropdownLabelsAr[entry.key] ?? entry.key;
    fields.add(
      RequestFieldItem(
        order: order++,
        key: entry.key,
        displayText: label,
        type: 'select',
        visibleToUser: true,
        value: null,
        availableValues: entry.value.map((e) => e.name).toList(),
        availableValuesItems: const [],
        relatedQuestions: const [],
      ),
    );
  }
  return fields;
}

/// Resolves which lookup list belongs to a request-field key.
List<LookupItem> resolveLookupItemsForFieldKey(
  String fieldKey,
  Lookups? lookups,
) {
  if (lookups == null) return const [];
  final key = normalizeLookupKey(fieldKey);
  if (key.isEmpty) return const [];

  bool matches(List<String> aliases) => aliases.any(
        (alias) =>
            key == normalizeLookupKey(alias) ||
            key.contains(normalizeLookupKey(alias)),
      );

  if (matches(const [
    'CIF_QUALIFICATION_ID',
    'QUALIFICATION_ID',
    'QUALIFICATION',
    'EDUCATION',
  ])) {
    return lookups.cifQualificationId;
  }
  if (matches(const ['CIF_RELIGION', 'RELIGION'])) {
    return lookups.cifReligion;
  }
  if (matches(const ['CIF_LICENSE_TYPE', 'LICENSE_TYPE', 'LICENSE'])) {
    return lookups.cifLicenseType;
  }
  if (matches(const ['CIF_GENDER', 'GENDER', 'SEX'])) {
    return lookups.cifGender;
  }
  if (key == 'PHONE' ||
      key == 'PHONETYPE' ||
      key == 'PHONETYPEID' ||
      key == 'CIFPHONE' ||
      key == 'CIFPHONETYPE') {
    return lookups.phone;
  }
  if (matches(const [
    'CIF_SOCIAL_STATUS',
    'SOCIAL_STATUS',
    'MARITAL_STATUS',
    'MARITALSTATUS',
  ])) {
    return lookups.cifSocialStatus;
  }
  if (matches(const ['CIF_HEALTH_STATUS', 'HEALTH_STATUS', 'HEALTH'])) {
    return lookups.cifHealthStatus;
  }
  if (matches(const ['RISK'])) {
    return lookups.risk;
  }
  if (matches(const [
    'CIF_NATION_CODE',
    'NATION_CODE',
    'NATIONALITY',
    'NATIONALITY_CODE',
  ])) {
    return lookups.cifNationCode;
  }
  if (matches(const ['CIF_GRANTS', 'GRANTS'])) {
    return lookups.cifGrants;
  }
  return const [];
}

LookupItem? findLookupItemByIdOrName(List<LookupItem> items, String? raw) {
  if (raw == null) return null;
  final needle = raw.trim();
  if (needle.isEmpty) return null;

  for (final item in items) {
    if (item.id == needle || item.name == needle) return item;
  }

  final normalizedNeedle = normalizeArabicLabel(needle);
  for (final item in items) {
    if (normalizeArabicLabel(item.id) == normalizedNeedle ||
        normalizeArabicLabel(item.name) == normalizedNeedle) {
      return item;
    }
  }
  return null;
}

String normalizeArabicLabel(String raw) {
  var value = raw.trim().toLowerCase();
  value = value.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
  value = value
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه')
      .replaceAll('ؤ', 'و')
      .replaceAll('ئ', 'ي')
      .replaceAll('ٱ', 'ا');
  value = value.replaceAll(RegExp(r'\s+'), ' ');
  return value;
}

bool _isGenderReligionOrSocialKey(String fieldKey) {
  final key = normalizeLookupKey(fieldKey);
  return key == 'CIFGENDER' ||
      key == 'GENDER' ||
      key == 'SEX' ||
      key == 'CIFRELIGION' ||
      key == 'RELIGION' ||
      key == 'CIFSOCIALSTATUS' ||
      key == 'SOCIALSTATUS' ||
      key == 'MARITALSTATUS';
}

/// Maps cached national-ID labels to lookup option ids for gender / religion /
/// social status (and falls back to generic matching for other lists).
String? matchLookupIdFromCachedLabel(List<LookupItem> items, String? label) {
  if (label == null || label.trim().isEmpty || items.isEmpty) return null;

  final direct = findLookupItemByIdOrName(items, label);
  if (direct != null) return direct.id;

  final normalized = normalizeArabicLabel(label);

  // Gender: national ID usually has Arabic/English words; lookups use M/F.
  const genderAliases = <String, List<String>>{
    'm': ['ذكر', 'male', 'm', 'رجل'],
    'f': ['انثى', 'انثي', 'اثنى', 'اثني', 'أنثى', 'female', 'f', 'امراه', 'امرأة'],
  };
  for (final item in items) {
    final idLower = item.id.toLowerCase();
    final aliasList = genderAliases[idLower];
    if (aliasList == null) continue;
    if (aliasList.any((a) => normalizeArabicLabel(a) == normalized)) {
      return item.id;
    }
  }

  // Religion aliases (Arabic ID + English).
  const religionAliases = <String, List<String>>{
    'مسلم': ['مسلم', 'مسلمه', 'muslim', 'islam', 'islamic'],
    'مسيحي': ['مسيحي', 'مسيحيه', 'christian', 'christianity'],
  };
  for (final item in items) {
    final nameKey = normalizeArabicLabel(item.name);
    final aliasList = religionAliases[nameKey] ?? religionAliases[item.name];
    if (aliasList != null &&
        aliasList.any((a) => normalizeArabicLabel(a) == normalized)) {
      return item.id;
    }
    // Also match when label contains the religion name.
    if (normalized == nameKey || normalized.contains(nameKey)) {
      return item.id;
    }
  }

  // Social / marital status: prefer exact normalized name, then known aliases,
  // then the shortest lookup name that starts with the ID label (so "متزوج"
  // selects "متزوج" not "متزوج و يعول").
  const socialAliases = <String, List<String>>{
    'اعزب': ['اعزب', 'أعزب', 'single', 'unmarried'],
    'متزوج': ['متزوج', 'married'],
    'مطلق': ['مطلق', 'divorced'],
    'مطلقه': ['مطلقه', 'مطلقة', 'divorced female'],
    'ارمل': ['ارمل', 'أرمل', 'widowed', 'widow', 'widower'],
    'ارمله': ['ارمله', 'أرملة'],
  };

  for (final item in items) {
    final nameKey = normalizeArabicLabel(item.name);
    for (final entry in socialAliases.entries) {
      if (nameKey != entry.key) continue;
      if (entry.value.any((a) => normalizeArabicLabel(a) == normalized)) {
        return item.id;
      }
    }
  }

  LookupItem? bestPrefix;
  for (final item in items) {
    final nameKey = normalizeArabicLabel(item.name);
    if (nameKey == normalized) return item.id;
    if (nameKey.startsWith(normalized) || normalized.startsWith(nameKey)) {
      if (bestPrefix == null ||
          normalizeArabicLabel(item.name).length <
              normalizeArabicLabel(bestPrefix.name).length) {
        bestPrefix = item;
      }
    }
  }
  if (bestPrefix != null) return bestPrefix.id;

  return null;
}

/// Whether this field should default from cached national-ID values.
bool shouldPrefillFromNationalId(String fieldKey) =>
    _isGenderReligionOrSocialKey(fieldKey);

/// Prefill map from cached VLens identity → request field keys.
Map<String, String> buildPrefillMapFromExtractedData(ExtractedUserData? data) {
  if (data == null) return const {};

  final front = data.idFrontData;
  final back = data.idBackData;
  final user = data.user;

  final gender =
      _firstNonEmpty([front?.gender, back?.gender, back?.genderEnglish]);
  final religion = _firstNonEmpty([back?.religion, back?.religionEnglish]);
  final marital =
      _firstNonEmpty([back?.maritalStatus, back?.maritalStatusEnglish]);
  final name = _firstNonEmpty([front?.name, user?.fullName]);
  final address = _firstNonEmpty([front?.address, user?.address]);
  final idNumber =
      _firstNonEmpty([front?.idNumber, back?.idNumber, user?.idNumber]);
  final phone = _firstNonEmpty([user?.phoneNumber]);
  final email = _firstNonEmpty([user?.emailAddress]);
  final job = _firstNonEmpty([back?.job, back?.jobTitle]);

  final map = <String, String>{};
  void putAll(List<String> keys, String? value) {
    if (value == null || value.isEmpty) return;
    for (final key in keys) {
      map[normalizeLookupKey(key)] = value;
    }
  }

  putAll(const ['name', 'fullName', 'customerName', 'full_name'], name);
  putAll(const ['address', 'customerAddress'], address);
  putAll(const ['idNumber', 'nationalId', 'nationalID', 'id_number'], idNumber);
  putAll(const ['phoneNumber', 'mobile', 'mobileNumber'], phone);
  putAll(const ['email', 'emailAddress', 'email_address'], email);
  putAll(const ['job', 'jobTitle', 'occupation'], job);
  putAll(const ['gender', 'CIF_GENDER', 'GENDER', 'SEX'], gender);
  putAll(const ['religion', 'CIF_RELIGION', 'RELIGION'], religion);
  putAll(const [
    'maritalStatus',
    'socialStatus',
    'CIF_SOCIAL_STATUS',
    'SOCIAL_STATUS',
    'marital_status',
  ], marital);

  return map;
}

String? lookupPrefillValue(Map<String, String> prefill, String fieldKey) {
  return prefill[normalizeLookupKey(fieldKey)];
}

String? _firstNonEmpty(List<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
  }
  return null;
}
