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

  final Map<String, dynamic> eligibilityResponse;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool isLoadingFields = true;
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
    requestFields = fields;
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
        final usesLocations =
            locationRole != null && locations.isNotEmpty;

        // Location selects come from lookups hierarchy — do not keep FIELDS
        // availableValues / default names that are not location ids.
        if (usesLocations) {
          final optionItems = selectOptionsForField(field);
          if (initial != null && optionItems.isNotEmpty) {
            initial =
                findLookupItemByIdOrName(optionItems, initial)?.id;
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
    return allFormFields.map((field) {
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
  }
}
