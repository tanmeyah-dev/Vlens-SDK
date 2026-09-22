import 'package:tan_sdk/data/models/extracted_user_data.dart';

import '../model/lookups_response.dart';
import '../model/summary_answer_item.dart';
import '../model/user_info_model.dart';
import 'user_info_document_pdf_encoder.dart';
import 'user_info_field_helpers.dart';
import 'user_info_lookup_helpers.dart';

/// Builds `/mobile/customers/loans/one-click-apply` request body from form
/// answers, cached identity, and eligibility payload.
class OneClickApplyBuildResult {
  final Map<String, dynamic> body;

  const OneClickApplyBuildResult(this.body);
}

class OneClickApplyBuildException implements Exception {
  final String message;

  OneClickApplyBuildException(this.message);

  @override
  String toString() => message;
}

Future<OneClickApplyBuildResult> buildOneClickApplyBody({
  required UserInfoModel model,
  required List<SummaryAnswerItem> answers,
  String? cachedEmail,
  String? cachedPhone,
}) async {
  // Index by English-normalized keys and Arabic-normalized keys/labels so
  // fields like «قيمه التمويل» / «مده التمويل» resolve correctly.
  final byKey = <String, String>{};
  for (final a in answers) {
    final value = a.value.trim();
    if (value.isEmpty) continue;
    final englishKey = normalizeLookupKey(a.key);
    if (englishKey.isNotEmpty) byKey[englishKey] = value;
    final arabicKey = normalizeArabicLabel(a.key);
    if (arabicKey.isNotEmpty) byKey[arabicKey] = value;
    final arabicLabel = normalizeArabicLabel(a.label);
    if (arabicLabel.isNotEmpty) byKey[arabicLabel] = value;
  }

  String? answer(List<String> aliases) => _findByAliases(byKey, aliases);
  int? answerInt(List<String> aliases) => _asInt(answer(aliases));
  double? answerDouble(List<String> aliases) => _asDouble(answer(aliases));

  final extracted = model.cachedExtractedData;
  final front = extracted?.idFrontData;
  final back = extracted?.idBackData;
  final user = extracted?.user;

  final nationalId = _firstNonEmpty([
    answer(
        const ['nationalId', 'nationalID', 'idNumber', 'id_number', 'CIF_ID']),
    front?.idNumber,
    back?.idNumber,
    user?.idNumber,
  ]);
  if (nationalId == null) {
    throw OneClickApplyBuildException('الرقم القومي غير متوفر');
  }

  final arabicNames = _splitNameParts(
    first: front?.firstName,
    lastNames: front?.lastNames,
    full: _firstNonEmpty([front?.name, user?.fullName]),
  );
  final englishFull = _firstNonEmpty([
    answer(const ['fullNameEN', 'fullNameEn', 'nameEnglish', 'name_english']),
    front?.nameEnglish,
    [
      front?.firstNameEnglish,
      front?.lastNamesEnglish,
    ]
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .join(' '),
  ]);

  final birthdate = _formatApiDate(
        _firstNonEmpty([
          answer(const ['birthdate', 'dateOfBirth', 'dob', 'birthDate']),
          front?.dateOfBirth?.toIso8601String(),
        ]),
      ) ??
      '';

  final idIssueDate = _formatApiDate(
        _firstNonEmpty([
          answer(const ['idIssueDate', 'releaseDate', 'idReleaseDate']),
          back?.releaseDate?.toIso8601String(),
        ]),
      ) ??
      '';

  final idExpDate = _formatApiDate(
        _firstNonEmpty([
          answer(const ['idExpDate', 'idExpiry', 'idExpiryDate']),
          back?.idExpiry?.toIso8601String(),
        ]),
      ) ??
      '';

  final email = _firstNonEmpty([
        answer(const ['email', 'emailAddress', 'email_address']),
        user?.emailAddress,
        cachedEmail,
      ]) ??
      '';

  // Always use the phone cached at login for phoneNo1.
  // Do not read form "PHONE" / نوع الهاتف (lookup id like "2").
  final phoneNo1 = _firstNonEmpty([
        cachedPhone,
        user?.phoneNumber,
      ]) ??
      '';

  final phoneNo2 = null;

  final nickname = answer(const ['nickname', 'nickName', 'alias']) ?? '';

  final gender = _mapGender(
    raw: answer(const ['gender', 'CIF_GENDER', 'SEX']),
    fallbackLabel: _firstNonEmpty([
      front?.gender,
      back?.gender,
      back?.genderEnglish,
    ]),
    lookups: model.lookups,
  );

  final religion = answerInt(const ['religion', 'CIF_RELIGION']);
  final nationCode = answerInt(const [
        'nationCode',
        'CIF_NATION_CODE',
        'nationality',
        'nationalityCode',
      ]) ??
      1;
  final socialStatus = answerInt(const [
    'socialStatus',
    'CIF_SOCIAL_STATUS',
    'maritalStatus',
    'MARITAL_STATUS',
  ]);
  final noOfChildren = answerInt(const [
        'noOfChildren',
        'childrenCount',
        'numberOfChildren',
        'kidsCount',
      ]) ??
      0;
  final qualificationRaw = answer(const [
    'qualificationId',
    'CIF_QUALIFICATION_ID',
    'QUALIFICATION_ID',
    'QUALIFICATION',
    'EDUCATION',
    'المؤهل الدراسي',
    'اختر المؤهل الدراسي',
    'المؤهل',
  ]);
  final qualificationId = _asInt(qualificationRaw);
  final healthStatus = answerInt(const [
    'healthStatus',
    'CIF_HEALTH_STATUS',
    'HEALTH_STATUS',
  ]);
  // API expects jobCode; in this flow it comes from المؤهل الدراسي selection.
  final jobCode = _resolveJobCode(
    answer(const [
          'jobCode',
          'job',
          'jobId',
          'occupation',
          'CIF_JOB',
        ]) ??
        qualificationRaw,
    model.jobs,
  );

  final formStreet = _findFormAnswerByArabicLabel(answers, const [
    'الشارع',
    'شارع',
  ]);
  final formBuildingNo = _findFormAnswerByArabicLabel(
    answers,
    const [
      'رقم المبني',
      'رقم المبنى',
      'رقم البناء',
    ],
    englishAliases: const ['buildingNo', 'buildingNumber', 'building'],
  );
  final formFloorNo = _findFormAnswerByArabicLabel(
    answers,
    const [
      'رقم الدور',
      'رقم الطابق',
    ],
    englishAliases: const ['floorNo', 'floor', 'floorNumber'],
  );
  final formFlatNo = _findFormAnswerByArabicLabel(
    answers,
    const [
      'رقم الشقة',
      'رقم الشقه',
    ],
    englishAliases: const [
      'flatNo',
      'flatno',
      'apartment',
      'apartmentNo',
      'unitNo',
    ],
  );
  final idCardAddMark = _firstNonEmpty([
    front?.address,
    user?.address,
  ]);

  final address = _buildAddress(
    model: model,
    byKey: byKey,
    // address.street / buildingNo / floorNo / flatNo from form. addMark is
    // never sent on the customer address — only on addressInIdCard.
    streetFallback: formStreet,
    buildingNoFallback: formBuildingNo,
    floorNoFallback: formFloorNo,
    flatNoFallback: formFlatNo,
    includeAddMark: false,
    // state/city/village must come only from locations lookups cascade.
    locationCodesFromLookupsOnly: true,
  );
  final lookupLocationCodes = _lookupLocationCodesFromForm(model);
  address['stateCode'] = lookupLocationCodes.stateCode;
  address['cityCode'] = lookupLocationCodes.cityCode;
  address['villageCode'] = lookupLocationCodes.villageCode;
  if (formStreet != null && formStreet.isNotEmpty) {
    address['street'] = formStreet;
  }
  if (formBuildingNo != null && formBuildingNo.isNotEmpty) {
    address['buildingNo'] = formBuildingNo;
  }
  if (formFloorNo != null && formFloorNo.isNotEmpty) {
    address['floorNo'] = _asInt(formFloorNo) ?? formFloorNo;
  }
  if (formFlatNo != null && formFlatNo.isNotEmpty) {
    address['flatNo'] = _asInt(formFlatNo) ?? formFlatNo;
  }
  address.remove('addMark');

  final addressInIdCard = _buildAddress(
    model: model,
    byKey: byKey,
    keyPrefixAliases: const [
      'ADDRESSINIDCARD',
      'IDCARDADDRESS',
      'ADDRESSONID',
    ],
    streetFallback: formStreet,
    fallbackAddress: address,
    buildingNoFallback: formBuildingNo,
    floorNoFallback: formFloorNo,
    flatNoFallback: formFlatNo,
    addMarkFallback: idCardAddMark,
  );

  // Keep location codes identical on address and addressInIdCard.
  addressInIdCard['countryCode'] = address['countryCode'];
  addressInIdCard['stateCode'] = address['stateCode'];
  addressInIdCard['cityCode'] = address['cityCode'];
  addressInIdCard['villageCode'] = address['villageCode'];

  // Mirror the same form address details into addressInIdCard (including street).
  addressInIdCard['street'] = address['street'];
  addressInIdCard['buildingNo'] = address['buildingNo'];
  addressInIdCard['floorNo'] = address['floorNo'];
  addressInIdCard['flatNo'] = address['flatNo'];
  // addMark on the ID-card address is the OCR address from the ID data table.
  if (idCardAddMark != null && idCardAddMark.trim().isNotEmpty) {
    addressInIdCard['addMark'] = idCardAddMark.trim();
  } else {
    addressInIdCard.remove('addMark');
  }
  _normalizeAddressInIdCardDigits(addressInIdCard);

  final loanDetails = _buildLoanDetails(
    byKey: byKey,
    eligibilityResponse: model.eligibilityResponse,
  );

  final documents = await _buildDocuments(model);
  final customerDetails = <String, dynamic>{
    'info': {
      'stName': _nameAt(arabicNames, 0),
      'ndName': _nameAt(arabicNames, 1),
      'rdName': _nameAt(arabicNames, 2),
      'thName': _nameAt(arabicNames, 3),
      'rstName': _nameAt(arabicNames, 4),
      'fullNameEN': englishFull ?? '',
      'nickname': nickname,
      'birthdate': birthdate,
      'email': email,
      'phoneNo1': phoneNo1,
      'phoneNo2': phoneNo2,
      'idIssueDate': idIssueDate,
      'idExpDate': idExpDate,
    },
    'indv': {
      'religion': religion,
      'nationCode': nationCode,
      'gender': gender,
      'socialStatus': socialStatus,
      'noOfChildren': noOfChildren,
      'qualificationId': qualificationId,
      'healthStatus': healthStatus,
      'jobCode': jobCode,
    },
    'address': address,
    'addressInIdCard': addressInIdCard,
  };

  final body = <String, dynamic>{
    'nationalId': nationalId,
    'customerDetails': customerDetails,
    'loanDetails': loanDetails,
    'documents': documents,
  };

  print(
      '📎 one-click-apply documents: ${documents.map((d) => d['documentCode']).toList()}');

  return OneClickApplyBuildResult(body);
}

const String _documentFileContentType = 'application/pdf';

String _documentFileName(String documentCode) {
  switch (documentCode) {
    case UserInfoModel.utilityBillDocumentCode:
      return 'utility_bill_2026.pdf';
    case UserInfoModel.rentContractDocumentCode:
      return 'rent_agreement.pdf';
    case UserInfoModel.otherDocumentCode:
      return 'other_document.pdf';
    default:
      return '$documentCode.pdf';
  }
}

Future<List<Map<String, String>>> _buildDocuments(UserInfoModel model) async {
  final documents = <Map<String, String>>[];

  for (final field in UserInfoModel.documentImageFields) {
    final path = model.documentImagePaths[field.key]?.trim() ?? '';
    final documentCode = UserInfoModel.documentApiCodes[field.key];
    if (documentCode == null || documentCode.isEmpty) continue;

    // Required docs must be present; optional "اخرى" is sent only when selected.
    if (path.isEmpty) {
      if (!UserInfoModel.requiredDocumentImageKeys.contains(field.key)) {
        continue;
      }
      throw OneClickApplyBuildException(
        'برجاء تحميل ${field.value}',
      );
    }

    try {
      final fileContent = await encodeLocalFileAsPdfBase64(path);
      if (!fileContent.startsWith('JVBERi0')) {
        throw const FormatException('PDF base64 must start with JVBERi0');
      }
      final fileName = _documentFileName(documentCode);
      documents.add({
        'documentCode': documentCode,
        'fileContent': fileContent,
        'fileName': fileName,
        'fileContentType': _documentFileContentType,
      });
      print(
        '📎 $documentCode → $fileName, $_documentFileContentType, '
        '${fileContent.length} chars, '
        'prefix=${fileContent.substring(0, 40)}',
      );
      if (fileContent.length > 1200000) {
        throw const FormatException(
          'PDF base64 is too large; re-pick a smaller photo.',
        );
      }
    } catch (e) {
      print('❌ Failed to encode ${field.key} ($documentCode): $e');
      throw OneClickApplyBuildException(
        'تعذر قراءة صورة ${field.value}',
      );
    }
  }

  final requiredCodes = UserInfoModel.requiredDocumentImageKeys
      .map((key) => UserInfoModel.documentApiCodes[key])
      .whereType<String>()
      .toSet();
  final sentCodes = documents.map((d) => d['documentCode']).toSet();
  if (!requiredCodes.every(sentCodes.contains)) {
    throw OneClickApplyBuildException(
      'برجاء تحميل كل المستندات المطلوبة',
    );
  }

  return documents;
}

Map<String, dynamic> _buildLoanDetails({
  required Map<String, String> byKey,
  required Map<String, dynamic> eligibilityResponse,
}) {
  // نوع المنتج — always send static product type `1` for one-click-apply.
  const productId = 1;

  // قيمه التمويل → reqAmount
  final reqAmount = _asDouble(_findByAliases(byKey, const [
        'قيمه التمويل',
        'قيمة التمويل',
        'reqAmount',
        'requestAmount',
        'loanAmount',
        'amount',
        'requiredAmount',
      ])) ??
      _asDouble(_findInMap(eligibilityResponse, const [
        'قيمه التمويل',
        'قيمة التمويل',
        'reqAmount',
        'requestAmount',
        'loanAmount',
        'amount',
      ]));

  // مده التمويل → reqNoOfksts (عدد الأقساط)
  final reqNoOfksts = _asInt(_findByAliases(byKey, const [
        'مده التمويل',
        'مدة التمويل',
        'reqNoOfksts',
        'reqNoOfKsts',
        'numberOfInstallments',
        'installments',
        'tenure',
        'noOfInstallments',
      ])) ??
      _asInt(_findInMap(eligibilityResponse, const [
        'مده التمويل',
        'مدة التمويل',
        'reqNoOfksts',
        'reqNoOfKsts',
        'numberOfInstallments',
        'installments',
        'tenure',
      ]));

  if (reqAmount == null || reqNoOfksts == null) {
    final missing = <String>[
      if (reqAmount == null) 'قيمه التمويل',
      if (reqNoOfksts == null) 'مده التمويل',
    ].join(' و');
    throw OneClickApplyBuildException(
      'بيانات القرض غير مكتملة. برجاء إدخال $missing',
    );
  }

  return {
    'productId': productId,
    'reqAmount': reqAmount,
    'reqNoOfksts': reqNoOfksts,
  };
}

Map<String, dynamic> _buildAddress({
  required UserInfoModel model,
  required Map<String, String> byKey,
  List<String> keyPrefixAliases = const [],
  String? streetFallback,
  Map<String, dynamic>? fallbackAddress,
  String? buildingNoFallback,
  String? floorNoFallback,
  String? flatNoFallback,
  String? addMarkFallback,
  bool locationCodesFromLookupsOnly = false,
  bool includeAddMark = true,
}) {
  String? scoped(List<String> aliases) {
    if (keyPrefixAliases.isNotEmpty) {
      for (final prefix in keyPrefixAliases) {
        final p = normalizeLookupKey(prefix);
        for (final alias in aliases) {
          final hit = _findByAliases(byKey, ['${p}_$alias', '$p$alias']);
          if (hit != null) return hit;
        }
      }
    }
    return _findByAliases(byKey, aliases);
  }

  final lookupCodes = _lookupLocationCodesFromForm(model);
  int? stateCode = lookupCodes.stateCode;
  int? cityCode = lookupCodes.cityCode;
  int? villageCode = lookupCodes.villageCode;

  if (!locationCodesFromLookupsOnly) {
    stateCode ??= _asInt(scoped(const [
      'stateCode',
      'governorate',
      'governate',
      'CIF_GOVERNORATE',
    ]));
    cityCode ??= _asInt(scoped(const ['cityCode', 'city', 'CIF_CITY']));
    villageCode ??= _asInt(scoped(const [
      'villageCode',
      'village',
      'district',
      'CIF_VILLAGE',
      'CIF_DISTRICT',
    ]));
  }

  final street = _firstNonEmpty([
        scoped(const ['street', 'propertyAddress']),
        streetFallback,
      ]) ??
      '';
  final buildingNo = _firstNonEmpty([
        // Prefer extracted ID building number when provided.
        buildingNoFallback,
        scoped(const [
          'buildingNo',
          'buildingNumber',
          'building',
        ]),
      ]) ??
      '';
  final floorNo = _asInt(_firstNonEmpty([
    floorNoFallback,
    scoped(const ['floorNo', 'floor', 'floorNumber']),
  ]));
  final flatno = _asInt(_firstNonEmpty([
    flatNoFallback,
    scoped(const [
      'flatno',
      'flatNo',
      'apartment',
      'apartmentNo',
      'unitNo',
    ]),
  ]));
  final addMark = _firstNonEmpty([
        addMarkFallback,
        scoped(const [
          'addMark',
          'addressMark',
          'landmark',
          'nearBy',
        ]),
      ]) ??
      '';
  final countryCode = _asInt(scoped(const ['countryCode', 'country'])) ?? 1;

  final built = <String, dynamic>{
    'countryCode': countryCode,
    'stateCode': stateCode,
    'cityCode': cityCode,
    'villageCode': villageCode,
    'street': street,
    'buildingNo': buildingNo,
    'floorNo': floorNo,
    'flatNo': flatno,
  };
  // addMark is optional — omit when empty or when this is the customer address.
  if (includeAddMark && addMark.trim().isNotEmpty) {
    built['addMark'] = addMark.trim();
  }

  final hasAny = stateCode != null ||
      cityCode != null ||
      villageCode != null ||
      street.isNotEmpty ||
      buildingNo.isNotEmpty ||
      floorNo != null ||
      flatno != null ||
      (includeAddMark && addMark.isNotEmpty);

  if (!hasAny && fallbackAddress != null) {
    final copied = Map<String, dynamic>.from(fallbackAddress);
    // Keep ID-card fields even when copying the customer address shell.
    if (buildingNoFallback != null && buildingNoFallback.trim().isNotEmpty) {
      copied['buildingNo'] = buildingNoFallback.trim();
    }
    if (floorNoFallback != null && floorNoFallback.trim().isNotEmpty) {
      copied['floorNo'] = _asInt(floorNoFallback) ?? floorNoFallback.trim();
    }
    if (flatNoFallback != null && flatNoFallback.trim().isNotEmpty) {
      copied['flatNo'] = _asInt(flatNoFallback) ?? flatNoFallback.trim();
    }
    if (includeAddMark &&
        addMarkFallback != null &&
        addMarkFallback.trim().isNotEmpty) {
      copied['addMark'] = addMarkFallback.trim();
    } else {
      copied.remove('addMark');
    }
    return copied;
  }
  return built;
}

/// state/city/village codes from form location cascade (lookups) only.
({int? stateCode, int? cityCode, int? villageCode})
    _lookupLocationCodesFromForm(UserInfoModel model) {
  int? stateCode;
  int? cityCode;
  int? villageCode;

  String? selectedFor(LocationFieldRole role) {
    final field = findLocationFieldByRole(model.allFormFields, role);
    if (field == null) return null;
    return model.selectedValues[field.key]?.trim();
  }

  final stateRaw = selectedFor(LocationFieldRole.governorate);
  final cityRaw = selectedFor(LocationFieldRole.city);
  final villageRaw = selectedFor(LocationFieldRole.village);

  // Prefer validating against backend locations hierarchy when available.
  if (model.locations.isNotEmpty) {
    final gov = findGovernorateById(model.locations, stateRaw);
    if (gov != null) {
      stateCode = gov.id;
      final city = findCityById(gov, cityRaw);
      if (city != null) {
        cityCode = city.id;
        final village = findVillageById(city, villageRaw);
        if (village != null) {
          villageCode = village.id;
        }
      }
    }
    return (stateCode: stateCode, cityCode: cityCode, villageCode: villageCode);
  }

  // Fallback: use selected lookup ids as-is when locations list is empty.
  stateCode = _asInt(stateRaw);
  cityCode = _asInt(cityRaw);
  villageCode = _asInt(villageRaw);
  return (stateCode: stateCode, cityCode: cityCode, villageCode: villageCode);
}

/// Converts Arabic-Indic (٠-٩) and Extended Arabic-Indic (۰-۹) digits to 0-9.
String _toWesternDigits(String raw) {
  return raw
      .replaceAllMapped(
        RegExp(r'[٠-٩]'),
        (m) => '${m.group(0)!.codeUnitAt(0) - 0x0660}',
      )
      .replaceAllMapped(
        RegExp(r'[۰-۹]'),
        (m) => '${m.group(0)!.codeUnitAt(0) - 0x06F0}',
      );
}

/// Converts Arabic digits to Western in all [addressInIdCard] string fields.
void _normalizeAddressInIdCardDigits(Map<String, dynamic> addressInIdCard) {
  for (final key in addressInIdCard.keys.toList()) {
    final value = addressInIdCard[key];
    if (value is String && value.trim().isNotEmpty) {
      addressInIdCard[key] = _toWesternDigits(value.trim());
    }
  }
}

/// Finds a non-empty answer whose key/label matches any Arabic needle.
String? _findFormAnswerByArabicLabel(
  List<SummaryAnswerItem> answers,
  List<String> arabicLabels, {
  List<List<String>> extraContainsAll = const [],
  List<String> englishAliases = const [],
}) {
  final needles = arabicLabels.map(normalizeArabicLabel).toList();
  for (final a in answers) {
    final value = a.value.trim();
    if (value.isEmpty) continue;
    final haystack = normalizeArabicLabel('${a.key} ${a.label}');
    if (needles.any((n) => n.isNotEmpty && haystack.contains(n))) {
      return value;
    }
    for (final group in extraContainsAll) {
      if (group.every((p) => haystack.contains(normalizeArabicLabel(p)))) {
        return value;
      }
    }
    for (final en in englishAliases) {
      if (haystack.contains(en.toLowerCase())) return value;
    }
  }
  return null;
}

int? _resolveJobCode(String? raw, List<JobItem> jobs) {
  if (raw == null || raw.trim().isEmpty) return null;
  final direct = _asInt(raw);
  if (direct != null) return direct;
  final needle = normalizeArabicLabel(raw);
  for (final job in jobs) {
    if (job.codeId == raw.trim()) return _asInt(job.codeId);
    if (normalizeArabicLabel(job.nameAr) == needle) return _asInt(job.codeId);
    final en = job.nameEn;
    if (en != null && normalizeArabicLabel(en) == needle) {
      return _asInt(job.codeId);
    }
  }
  return null;
}

String? _mapGender({
  required String? raw,
  required String? fallbackLabel,
  required Lookups? lookups,
}) {
  String? fromLabel(String? value) {
    if (value == null) return null;
    final t = value.trim();
    if (t.isEmpty) return null;
    final upper = t.toUpperCase();
    if (upper == 'M' ||
        upper == 'MALE' ||
        t == 'ذكر' ||
        t.contains('ذكر') ||
        upper.contains('MALE')) {
      return 'M';
    }
    if (upper == 'F' ||
        upper == 'FEMALE' ||
        t == 'أنثى' ||
        t == 'انثى' ||
        t.contains('أنث') ||
        t.contains('انث') ||
        upper.contains('FEMALE')) {
      return 'F';
    }
    return null;
  }

  final direct = fromLabel(raw) ?? fromLabel(fallbackLabel);
  if (direct != null) return direct;

  if (raw != null && lookups != null) {
    final item = findLookupItemByIdOrName(lookups.cifGender, raw);
    final mapped = fromLabel(item?.name);
    if (mapped != null) return mapped;
  }

  return raw?.trim().isNotEmpty == true ? raw!.trim() : null;
}

List<String> _splitNameParts({
  String? first,
  String? lastNames,
  String? full,
}) {
  final firstTrim = first?.trim();
  if (firstTrim != null && firstTrim.isNotEmpty) {
    final rest = (lastNames ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    return [firstTrim, ...rest];
  }
  return (full ?? '')
      .trim()
      .split(RegExp(r'\s+'))
      .where((e) => e.isNotEmpty)
      .toList();
}

String _nameAt(List<String> parts, int index) =>
    index < parts.length ? parts[index] : '';

String? _formatApiDate(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final parsed = parseDateLoose(raw);
  if (parsed == null) {
    // Already human-formatted? normalize separators to `/`.
    final cleaned = raw.trim().replaceAll('-', '/').replaceAll('.', '/');
    return cleaned;
  }
  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  final year = parsed.year.toString();
  return '$day/$month/$year';
}

String? _findByAliases(Map<String, String> byKey, List<String> aliases) {
  for (final alias in aliases) {
    for (final normalizedAlias in _normalizedAliasCandidates(alias)) {
      final exact = byKey[normalizedAlias];
      if (exact != null && exact.trim().isNotEmpty) return exact.trim();

      for (final entry in byKey.entries) {
        final key = entry.key;
        if (key == normalizedAlias) return entry.value;
        if (normalizedAlias.length >= 4 && key.contains(normalizedAlias)) {
          return entry.value;
        }
        if (key.length >= 4 && normalizedAlias.contains(key)) {
          return entry.value;
        }
      }
    }
  }
  return null;
}

String? _findInMap(dynamic node, List<String> aliases) {
  if (node == null) return null;
  if (node is Map) {
    final map = Map<String, dynamic>.from(node);
    for (final entry in map.entries) {
      final keyCandidates = _normalizedAliasCandidates(entry.key.toString());
      for (final alias in aliases) {
        final aliasCandidates = _normalizedAliasCandidates(alias);
        final matched = keyCandidates.any(
          (key) => aliasCandidates.any(
            (a) =>
                key == a ||
                (a.length >= 4 && key.contains(a)) ||
                (key.length >= 4 && a.contains(key)),
          ),
        );
        if (!matched) continue;
        final v = entry.value;
        if (v == null) continue;
        final s = v.toString().trim();
        if (s.isNotEmpty) return s;
      }
    }
    for (final value in map.values) {
      final nested = _findInMap(value, aliases);
      if (nested != null) return nested;
    }
  } else if (node is List) {
    for (final item in node) {
      final nested = _findInMap(item, aliases);
      if (nested != null) return nested;
    }
  }
  return null;
}

/// English lookup keys (A–Z/0–9) plus Arabic-normalized labels.
List<String> _normalizedAliasCandidates(String raw) {
  final out = <String>[];
  final english = normalizeLookupKey(raw);
  if (english.isNotEmpty) out.add(english);
  final arabic = normalizeArabicLabel(raw);
  if (arabic.isNotEmpty) out.add(arabic);
  return out;
}

int? _asInt(String? raw) {
  if (raw == null) return null;
  final t = _toWesternDigits(raw.trim());
  if (t.isEmpty) return null;
  return int.tryParse(t) ?? double.tryParse(t)?.round();
}

double? _asDouble(String? raw) {
  if (raw == null) return null;
  final t = raw.trim().replaceAll(',', '');
  if (t.isEmpty) return null;
  return double.tryParse(t);
}

String? _firstNonEmpty(List<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
  }
  return null;
}
