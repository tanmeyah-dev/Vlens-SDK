import 'package:flutter/material.dart';

import 'request_fields_response.dart';
import 'summary_answer_item.dart';
import '../utils/user_info_field_helpers.dart';

/// Mutable UI + loaded fields for the user-info (KYC) step.
class UserInfoModel {
  UserInfoModel({required this.eligibilityResponse});

  final Map<String, dynamic> eligibilityResponse;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool isLoadingFields = true;
  String? fieldsError;
  List<RequestFieldItem> requestFields = [];

  final Map<String, TextEditingController> textControllers = {};
  final Map<String, String?> selectedValues = {};
  final Map<String, bool> checkboxValues = {};
  final Map<String, DateTime?> dateValues = {};
  final Map<String, Set<String>> multiSelectValues = {};

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

  void populateFromRequestFields(List<RequestFieldItem> fields) {
    _clearFieldControllers();
    for (final field in fields) {
      final t = field.type.toLowerCase();
      if (t == 'text' || t == 'number') {
        textControllers[field.key] =
            TextEditingController(text: field.value ?? '');
      } else if (t == 'select' || t == 'radiogroup') {
        selectedValues[field.key] = field.value;
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
    return requestFields.map((field) {
      final type = field.type.toLowerCase();
      final title =
          field.displayText.trim().isNotEmpty ? field.displayText : field.key;
      String value = '';
      if (type == 'text' || type == 'number') {
        value = textControllers[field.key]?.text.trim() ?? '';
      } else if (type == 'select' || type == 'radiogroup') {
        value = (selectedValues[field.key] ?? '').trim();
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
      return SummaryAnswerItem(key: field.key, label: title, value: value);
    }).toList();
  }
}
