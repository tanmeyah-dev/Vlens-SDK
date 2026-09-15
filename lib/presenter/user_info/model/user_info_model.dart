import 'package:flutter/material.dart';
import 'package:tan_sdk/data/models/extracted_user_data.dart';

import 'lookups_response.dart';
import 'request_fields_response.dart';
import 'summary_answer_item.dart';
import '../utils/user_info_field_helpers.dart';
import '../utils/user_info_lookup_helpers.dart';

/// Mutable UI + loaded fields for the user-info (KYC) step.
class UserInfoModel {
  UserInfoModel({required this.eligibilityResponse});

  static const String leaseContractImageKey = 'leaseContract';
  static const String utilityReceiptImageKey = 'utilityReceipt';
  static const String otherDocumentImageKey = 'otherDocument';

  static const String leaseContractImageLabel = 'عقد الإيجار';
  static const String utilityReceiptImageLabel = 'إيصال مرافق';
  static const String otherDocumentImageLabel = 'اخرى (اختياري)';

  static const String utilityBillDocumentCode = 'UTILITY_BILL';
  static const String rentContractDocumentCode = 'RENT_CONTRACT';
  static const String otherDocumentCode = 'OTHER';

  static const List<MapEntry<String, String>> documentImageFields = [
    MapEntry(utilityReceiptImageKey, utilityReceiptImageLabel),
    MapEntry(leaseContractImageKey, leaseContractImageLabel),
    MapEntry(otherDocumentImageKey, otherDocumentImageLabel),
  ];

  static const Set<String> requiredDocumentImageKeys = {
    utilityReceiptImageKey,
    leaseContractImageKey,
  };

  /// one-click-apply `documents[].documentCode` for each local upload key.
  static const Map<String, String> documentApiCodes = {
    utilityReceiptImageKey: utilityBillDocumentCode,
    leaseContractImageKey: rentContractDocumentCode,
    otherDocumentImageKey: otherDocumentCode,
  };

  final Map<String, dynamic> eligibilityResponse;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool isLoadingFields = true;

  /// Set to true only after both request/fields and customers/lookups succeed.
  bool areFieldsReady = false;

  String? fieldsError;
  List<RequestFieldItem> requestFields = [];

  /// Standalone dropdowns built from `/mobile/customers/lookups`.
  List<RequestFieldItem> lookupFields = [];

  /// Lookups from `/mobile/customers/lookups`.
  Lookups? lookups;

  /// Jobs from `/mobile/customers/lookups` (`data.jobs`).
  List<JobItem> jobs = const [];

  /// Locations hierarchy from `/mobile/customers/lookups` (`data.locations`).
  List<LocationGovernorate> locations = const [];

  /// Cached VLens identity used to prefill matching fields.
  ExtractedUserData? cachedExtractedData;

  final Map<String, TextEditingController> textControllers = {};
  final Map<String, String?> selectedValues = {};
  final Map<String, bool> checkboxValues = {};
  final Map<String, DateTime?> dateValues = {};
  final Map<String, Set<String>> multiSelectValues = {};

  /// Local gallery image paths for document uploads (one image per key).
  final Map<String, String?> documentImagePaths = {
    leaseContractImageKey: null,
    utilityReceiptImageKey: null,
    otherDocumentImageKey: null,
  };

  /// Set after the user taps save; drives inline error display.
  bool showValidationErrors = false;

  /// Latest validation errors keyed by field key.
  Map<String, String> validationErrors = {};

  /// All visible form fields: request/fields + lookup dropdowns.
  List<RequestFieldItem> get allFormFields => [
        ...requestFields,
        ...lookupFields,
      ];

  void dispose() {
    for (final c in textControllers.values) {
      c.dispose();
    }
  }

  void _clearFieldControllers() {
    for (final c in textControllers.values) {
      c.dispose();
    }
    textControllers.clear();
    selectedValues.clear();
    checkboxValues.clear();
    dateValues.clear();
    multiSelectValues.clear();
  }

  void setDocumentImage(String key, String path) {
    documentImagePaths[key] = path;
  }

  void clearDocumentImage(String key) {
    documentImagePaths[key] = null;
  }

  String? validateDocumentImage(String key) {
    if (!requiredDocumentImageKeys.contains(key)) return null;
    final path = documentImagePaths[key]?.trim() ?? '';
    if (path.isEmpty) return 'برجاء اختيار صورة';
    return null;
  }

  List<LookupItem> lookupItemsForField(RequestFieldItem field) {
    return resolveLookupItemsForFieldKey(field.key, lookups);
  }

  /// Select options: location cascade from lookups, else CIF_* lookups.
  List<LookupItem> selectOptionsForField(RequestFieldItem field) {
    final role = detectLocationFieldRole(field);
    if (role != null && locations.isNotEmpty) {
      return resolveLocationLookupItems(
        role: role,
        locations: locations,
        fields: allFormFields,
        selectedValues: selectedValues,
      );
    }
    return lookupItemsForField(field);
  }

  void onLocationSelectionChanged(RequestFieldItem field, String? value) {
    selectedValues[field.key] = value;
    final role = detectLocationFieldRole(field);
    if (role == null) return;
    clearDependentLocationSelections(
      changedRole: role,
      fields: allFormFields,
      selectedValues: selectedValues,
    );
  }

  void populateFromRequestFields(
    List<RequestFieldItem> fields, {
    List<RequestFieldItem>? lookupFieldsOverride,
  }) {
    _clearFieldControllers();
    requestFields = reorderStreetAndBuildingAfterDistrict(fields);
    lookupFields = lookupFieldsOverride ??
        buildLookupSelectFields(
          lookups,
          existingRequestFields: fields,
        );

    final prefill = buildPrefillMapFromExtractedData(cachedExtractedData);

    for (final field in allFormFields) {
      final t = field.type.toLowerCase();
      final cachedRaw = lookupPrefillValue(prefill, field.key);
      final lookupItems = lookupItemsForField(field);

      if (t == 'text' || t == 'number') {
        final initial = (field.value != null && field.value!.trim().isNotEmpty)
            ? field.value!
            : (cachedRaw ?? '');
        textControllers[field.key] = TextEditingController(text: initial);
      } else if (t == 'select' || t == 'radiogroup') {
        String? initial = field.value;
        final preferNationalId = shouldPrefillFromNationalId(field.key);
        final locationRole = detectLocationFieldRole(field);
        final usesLocations = locationRole != null && locations.isNotEmpty;

        // Location selects come from lookups hierarchy — do not keep FIELDS
        // availableValues / default names that are not location ids.
        if (usesLocations) {
          final optionItems = selectOptionsForField(field);
          if (initial != null && optionItems.isNotEmpty) {
            initial = findLookupItemByIdOrName(optionItems, initial)?.id;
          } else {
            initial = null;
          }
          selectedValues[field.key] = initial;
          continue;
        }

        // Gender / religion / social status: always prefer cached national ID.
        if (preferNationalId && cachedRaw != null) {
          if (lookupItems.isNotEmpty) {
            initial = matchLookupIdFromCachedLabel(lookupItems, cachedRaw) ??
                findLookupItemByIdOrName(lookupItems, cachedRaw)?.id;
          } else {
            initial = cachedRaw;
          }
        } else if ((initial == null || initial.trim().isEmpty) &&
            cachedRaw != null) {
          if (lookupItems.isNotEmpty) {
            initial = matchLookupIdFromCachedLabel(lookupItems, cachedRaw) ??
                findLookupItemByIdOrName(lookupItems, cachedRaw)?.id ??
                cachedRaw;
          } else {
            initial = cachedRaw;
          }
        } else if (initial != null && lookupItems.isNotEmpty) {
          initial =
              findLookupItemByIdOrName(lookupItems, initial)?.id ?? initial;
        }

        // Only keep a value that exists in the dropdown options.
        if (initial != null && lookupItems.isNotEmpty) {
          final ids = lookupItems.map((e) => e.id).toSet();
          if (!ids.contains(initial)) {
            initial = matchLookupIdFromCachedLabel(lookupItems, initial);
          }
        }

        // Nationality defaults to Egyptian and stays locked in the UI.
        if (isNationalityField(field) &&
            (initial == null || initial.trim().isEmpty)) {
          if (lookupItems.isNotEmpty) {
            initial = findEgyptianNationalityId(lookupItems);
          } else {
            final fromValues = field.availableValues.cast<String>().where((v) {
              final n = normalizeArabicLabel(v);
              return n.contains('مصر') ||
                  n.contains('egypt') ||
                  n == 'eg' ||
                  n == normalizeArabicLabel('مصري');
            });
            if (fromValues.isNotEmpty) {
              initial = fromValues.first;
            }
          }
        }

        selectedValues[field.key] = initial;
      } else if (t == 'checkbox') {
        checkboxValues[field.key] = parseBoolLoose(field.value);
      } else if (t == 'date') {
        dateValues[field.key] = parseDateLoose(field.value);
      } else if (t == 'multiselect') {
        initMultiSelectFromField(field, multiSelectValues);
      }
    }
  }

  List<SummaryAnswerItem> buildSummaryAnswers() {
    final items = allFormFields
        .where((field) => !isHiddenUserInfoField(field))
        .map((field) {
      final type = field.type.toLowerCase();
      final title =
          field.displayText.trim().isNotEmpty ? field.displayText : field.key;
      String value = '';
      String? displayValue;

      if (type == 'text' || type == 'number') {
        value = textControllers[field.key]?.text.trim() ?? '';
      } else if (type == 'select' || type == 'radiogroup') {
        value = (selectedValues[field.key] ?? '').trim();
        final optionItems = selectOptionsForField(field);
        if (optionItems.isNotEmpty) {
          displayValue =
              findLookupItemByIdOrName(optionItems, value)?.name ?? value;
        }
      } else if (type == 'checkbox') {
        value = (checkboxValues[field.key] ?? false) ? 'نعم' : 'لا';
      } else if (type == 'date') {
        final d = dateValues[field.key];
        if (d != null) {
          value = d.toUtc().toIso8601String();
          return SummaryAnswerItem(
            key: field.key,
            label: title,
            value: value,
            displayValue: formatDateDdMmYyyy(d),
          );
        }
        value = '';
      } else if (type == 'multiselect') {
        final set = multiSelectValues[field.key] ?? {};
        value = set.join(', ');
      }
      return SummaryAnswerItem(
        key: field.key,
        label: title,
        value: value,
        displayValue: displayValue,
      );
    }).toList();

    for (final doc in documentImageFields) {
      final path = documentImagePaths[doc.key]?.trim() ?? '';
      if (path.isEmpty) continue;
      final fileName = path.split(RegExp(r'[/\\]')).last;
      items.add(
        SummaryAnswerItem(
          key: doc.key,
          label: doc.value,
          value: path,
          displayValue: fileName,
        ),
      );
    }

    return items;
  }

  /// Validates one visible field; returns an Arabic error message or null.
  String? validateField(RequestFieldItem field) {
    if (isHiddenUserInfoField(field)) return null;

    final isOptional = isOptionalUserInfoField(field);
    final type = field.type.toLowerCase();

    if (type == 'text') {
      final text = textControllers[field.key]?.text.trim() ?? '';
      if (text.isEmpty) {
        return isOptional ? null : 'هذا الحقل مطلوب';
      }
      if (field.key == 'numberOfChildren') {
        if (text.length != 1) return 'يجب إدخال رقم واحد فقط';
      } else if (isBuildingNoField(field)) {
        if (!RegExp(r'^\d{1,4}$').hasMatch(text)) {
          return 'يجب إدخال 4 أرقام كحد أقصى';
        }
      } else if (text.length < 4) {
        return 'الحد الأدنى 4 أحرف';
      }
      return null;
    }

    if (type == 'number') {
      final text = textControllers[field.key]?.text.trim() ?? '';
      if (text.isEmpty) {
        return isOptional ? null : 'هذا الحقل مطلوب';
      }
      final normalized = text.replaceAll(',', '').replaceAll(' ', '');
      final amount = num.tryParse(normalized);
      if (normalized.isEmpty || amount == null) {
        return 'برجاء إدخال رقم صالح';
      }

      if (isBuildingNoField(field) && !RegExp(r'^\d{1,4}$').hasMatch(text)) {
        return 'يجب إدخال 4 أرقام كحد أقصى';
      }

      if (isMonthlyIncomeField(field) && amount > kMaxMonthlyIncome) {
        return 'الحد الاقصي للدخل الشهري يجب الا يزيد عن 83000';
      }

      if (isMonthlyExpenseField(field)) {
        final incomeError = _validateExpensesAgainstIncome(amount);
        if (incomeError != null) return incomeError;
      }

      return null;
    }

    if (type == 'radiogroup' || type == 'select') {
      final locationRole = detectLocationFieldRole(field);
      final usesLocations = locationRole != null && locations.isNotEmpty;
      final optionItems = usesLocations
          ? selectOptionsForField(field)
          : lookupItemsForField(field);

      if (usesLocations && optionItems.isEmpty) {
        if (locationRole == LocationFieldRole.city) {
          return 'برجاء اختيار المحافظة أولاً';
        }
        if (locationRole == LocationFieldRole.village) {
          return 'برجاء اختيار المدينة أولاً';
        }
      }

      final value = (selectedValues[field.key] ?? '').trim();
      if (value.isEmpty) {
        return isOptional ? null : 'برجاء الاختيار';
      }
      return null;
    }

    if (type == 'date') {
      if (dateValues[field.key] == null) {
        return isOptional ? null : 'برجاء اختيار التاريخ';
      }
      return null;
    }

    if (type == 'multiselect') {
      if ((multiSelectValues[field.key] ?? {}).isEmpty) {
        return isOptional ? null : 'اختر خياراً واحداً على الأقل';
      }
      return null;
    }

    if (type == 'checkbox') {
      if (!(checkboxValues[field.key] ?? false)) {
        return isOptional ? null : 'هذا الحقل مطلوب';
      }
      return null;
    }

    return null;
  }

  /// Validates every visible field on the form.
  Map<String, String> validateAllVisibleFields() {
    final errors = <String, String>{};
    for (final field in allFormFields) {
      if (isHiddenUserInfoField(field)) continue;
      final error = validateField(field);
      if (error != null) errors[field.key] = error;
    }
    for (final doc in documentImageFields) {
      final error = validateDocumentImage(doc.key);
      if (error != null) errors[doc.key] = error;
    }
    return errors;
  }

  /// Expenses must be strictly less than monthly income when income is set.
  String? _validateExpensesAgainstIncome(num expenseAmount) {
    RequestFieldItem? incomeField;
    for (final candidate in allFormFields) {
      if (isMonthlyIncomeField(candidate)) {
        incomeField = candidate;
        break;
      }
    }
    if (incomeField == null) return null;

    final incomeText = textControllers[incomeField.key]?.text.trim() ?? '';
    final incomeNormalized = incomeText.replaceAll(',', '').replaceAll(' ', '');
    final incomeAmount = num.tryParse(incomeNormalized);
    if (incomeAmount == null) return null;

    if (expenseAmount >= incomeAmount) {
      return 'يجب ان يكون  اجمالي المصروفات الشهريه اقل من اجمالي الدخل الشهري';
    }
    return null;
  }
}
