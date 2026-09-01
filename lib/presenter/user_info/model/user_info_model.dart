import 'package:flutter/material.dart';
import 'package:tan_sdk/data/models/extracted_user_data.dart';

import 'lookups_response.dart';
import 'request_fields_response.dart';
import 'summary_answer_item.dart';
import '../utils/user_info_field_helpers.dart';
import '../utils/user_info_lookup_helpers.dart';

/// Mutable UI + loaded fields for the user-info (KYC) step.
class UserInfoModel {
  UserInfoModel({
    required this.eligibilityResponse,
    ExtractedUserData? extractedData,
  }) : cachedExtractedData = extractedData;

  final Map<String, dynamic> eligibilityResponse;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool isLoadingFields = true;

  /// Set to true after request/fields load succeeds.
  bool areFieldsReady = false;

  String? fieldsError;
  List<RequestFieldItem> requestFields = [];

  /// Extra lookup-driven dropdowns (unused when lookups API is not called).
  List<RequestFieldItem> lookupFields = [];

  /// Optional lookup lists (populated only when a lookups source is wired).
  Lookups? lookups;

  /// Optional jobs list for one-click apply job code resolution.
  List<JobItem> jobs = const [];

  /// Optional location hierarchy for governorate/city/village cascades.
  List<LocationGovernorate> locations = const [];

  /// Cached VLens identity used to prefill matching fields.
  /// Set from [IdDataScreen] after `/vlens-data` or from local cache.
  ExtractedUserData? cachedExtractedData;

  final Map<String, TextEditingController> textControllers = {};
  final Map<String, String?> selectedValues = {};
  final Map<String, bool> checkboxValues = {};
  final Map<String, DateTime?> dateValues = {};
  final Map<String, Set<String>> multiSelectValues = {};

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

  List<LookupItem> lookupItemsForField(RequestFieldItem field) {
    return resolveLookupItemsForFieldKey(field.key, lookups);
  }

  /// Dropdown options: lookups when present, else request/fields choices.
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
    final fromLookups = lookupItemsForField(field);
    if (fromLookups.isNotEmpty) return fromLookups;
    return selectOptionsFromRequestField(field);
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
      final cachedRaw = lookupPrefillValueForField(
        prefill,
        field,
        extractedData: cachedExtractedData,
      );
      final optionItems = selectOptionsForField(field);

      if (t == 'text' || t == 'number') {
        final initial = (field.value != null && field.value!.trim().isNotEmpty)
            ? field.value!
            : (cachedRaw ?? '');
        textControllers[field.key] = TextEditingController(text: initial);
      } else if (t == 'select' || t == 'radiogroup') {
        final preferNationalId = shouldPrefillFromNationalId(field.key);
        final locationRole = detectLocationFieldRole(field);
        final usesLocations =
            locationRole != null && locations.isNotEmpty;

        // Location selects come from lookups hierarchy — do not keep FIELDS
        // availableValues / default names that are not location ids.
        if (usesLocations) {
          String? initial = field.value;
          if (initial != null && optionItems.isNotEmpty) {
            initial =
                findLookupItemByIdOrName(optionItems, initial)?.id;
          } else {
            initial = null;
          }
          selectedValues[field.key] = initial;
          continue;
        }

        var initial = resolveSelectInitialValue(
          field: field,
          optionItems: optionItems,
          fieldValue: field.value,
          cachedRaw: cachedRaw,
          preferNationalId: preferNationalId,
        );

        // Nationality defaults to Egyptian and stays locked in the UI.
        if (isNationalityField(field) &&
            (initial == null || initial.trim().isEmpty)) {
          if (optionItems.isNotEmpty) {
            initial = findEgyptianNationalityId(optionItems);
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

    applyMaritalStatusFromIdData(
      extractedData: cachedExtractedData,
      fields: allFormFields,
      selectedValues: selectedValues,
      optionsFor: selectOptionsForField,
    );
  }

  List<SummaryAnswerItem> buildSummaryAnswers() {
    final items = allFormFields.map((field) {
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

    return items;
  }
}
