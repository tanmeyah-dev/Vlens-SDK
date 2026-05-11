import 'dart:convert';

import 'package:core/components/button/app_button.dart';
import 'package:core/components/textField/app_textfield.dart';
import 'package:core/utils/cache/verification_cache.dart';
import 'package:core/utils/network/http_headers_helper.dart';
import 'package:core/style/app_colors.dart';
import 'package:flutter/material.dart';

import '../model/request_fields_response.dart';
import '../../../utils/sdk_http_client.dart';
import '../../mobile_number/constants/api_urls.dart';
import 'summaryscreen.dart';

class UserInfoOneScene extends StatefulWidget {
  final Map<String, dynamic> eligibilityResponse;

  const UserInfoOneScene({
    super.key,
    required this.eligibilityResponse,
  });

  @override
  State<UserInfoOneScene> createState() => _UserInfoOneSceneState();
}

class _UserInfoOneSceneState extends State<UserInfoOneScene> {
  bool _isLoadingFields = true;
  bool _isSubmitting = false;
  String? _fieldsError;
  List<RequestFieldItem> _requestFields = [];
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, String?> _selectedValues = {};
  final Map<String, bool> _checkboxValues = {};
  final Map<String, DateTime?> _dateValues = {};
  final Map<String, Set<String>> _multiSelectValues = {};
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  static String _formatDateDdMmYyyy(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    return '$day-$month-$year';
  }

  static bool _parseBoolLoose(String? raw) {
    if (raw == null) return false;
    final s = raw.trim().toLowerCase();
    return s == 'true' ||
        s == '1' ||
        s == 'yes' ||
        s == 'y' ||
        s == 'نعم';
  }

  static DateTime? _parseDateLoose(String? raw) {
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

  void _initMultiSelectFromField(RequestFieldItem field) {
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
    _multiSelectValues[field.key] = chosen;
  }

  List<SummaryAnswerItem> _buildSummaryAnswers() {
    return _requestFields.map((field) {
      final type = field.type.toLowerCase();
      final title = field.displayText.trim().isNotEmpty ? field.displayText : field.key;
      String value = '';
      if (type == 'text') {
        value = _textControllers[field.key]?.text.trim() ?? '';
      } else if (type == 'select' || type == 'radiogroup') {
        value = (_selectedValues[field.key] ?? '').trim();
      } else if (type == 'checkbox') {
        value = (_checkboxValues[field.key] ?? false) ? 'نعم' : 'لا';
      } else if (type == 'date') {
        final d = _dateValues[field.key];
        if (d != null) {
          value = d.toUtc().toIso8601String();
          return SummaryAnswerItem(
            key: field.key,
            label: title,
            value: value,
            displayValue: _formatDateDdMmYyyy(d),
          );
        }
        value = '';
      } else if (type == 'multiselect') {
        final set = _multiSelectValues[field.key] ?? {};
        value = set.join(', ');
      }
      return SummaryAnswerItem(key: field.key, label: title, value: value);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    print('');
    print('═══════════════════════════════════════════════════════');
    print('📄 USERINFOONE SCREEN OPENED');
    print('═══════════════════════════════════════════════════════');
    print('Eligibility response: ${jsonEncode(widget.eligibilityResponse)}');
    print('═══════════════════════════════════════════════════════');
    print('');
    _callRequestFieldsIfEligible();
  }

  @override
  void dispose() {
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _callRequestFieldsIfEligible() async {
    final data = widget.eligibilityResponse['data'];
    final isEligible = data is Map<String, dynamic> && data['isEligible'] == true;

    if (!isEligible) {
      print('ℹ️ USERINFOONE: isEligible=false, skipping request/fields call.');
      if (!mounted) return;
      setState(() {
        _isLoadingFields = false;
        _fieldsError = 'المستخدم غير مؤهل حالياً';
      });
      return;
    }

    final cache = VerificationCache();
    final requestTypeId = await cache.getRequestTypeId();
    final accessToken = await cache.getAccessToken();
    final encryptedToken = await cache.getEncryptedAccessToken();
    final token = (accessToken != null && accessToken.trim().isNotEmpty)
        ? accessToken.trim()
        : (encryptedToken ?? '').trim();

    final headers = token.isNotEmpty
        ? HttpHeadersHelper.getHeadersWithAuth(token)
        : HttpHeadersHelper.getDefaultHeaders();
    final url = ApiUrls.getRequestFieldsUrl(requestTypeId: requestTypeId);

    print('');
    print('═══════════════════════════════════════════════════════');
    print('📤 REQUEST FIELDS API CALL (USERINFOONE)');
    print('═══════════════════════════════════════════════════════');
    print('URL: $url');
    print('Method: GET');
    print('requestTypeId (cached): $requestTypeId');
    print('Has Bearer Token: ${token.isNotEmpty}');
    print('Headers: $headers');
    print('═══════════════════════════════════════════════════════');
    print('');

    try {
      final response = await SdkHttpClient.get(
        Uri.parse(url),
        headers: headers,
      );

      print('');
      print('═══════════════════════════════════════════════════════');
      print('📥 REQUEST FIELDS API RESPONSE (USERINFOONE)');
      print('═══════════════════════════════════════════════════════');
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');
      print('═══════════════════════════════════════════════════════');
      print('');

      if (response.statusCode != 200) {
        throw Exception('فشل تحميل الحقول (${response.statusCode})');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('استجابة غير صالحة من request/fields');
      }

      final parsed = RequestFieldsResponse.fromJson(decoded);
      final fields = parsed.data?.requestsFields
              .where((field) => field.visibleToUser)
              .toList() ??
          <RequestFieldItem>[];
      fields.sort((a, b) => a.order.compareTo(b.order));

      for (final field in fields) {
        final t = field.type.toLowerCase();
        if (t == 'text') {
          _textControllers[field.key] =
              TextEditingController(text: field.value ?? '');
        } else if (t == 'select' || t == 'radiogroup') {
          _selectedValues[field.key] = field.value;
        } else if (t == 'checkbox') {
          _checkboxValues[field.key] = _parseBoolLoose(field.value);
        } else if (t == 'date') {
          _dateValues[field.key] = _parseDateLoose(field.value);
        } else if (t == 'multiselect') {
          _initMultiSelectFromField(field);
        }
      }

      if (!mounted) return;
      setState(() {
        _requestFields = fields;
        _isLoadingFields = false;
        _fieldsError = null;
      });
    } catch (e) {
      print('❌ REQUEST FIELDS API ERROR (USERINFOONE): $e');
      if (!mounted) return;
      setState(() {
        _isLoadingFields = false;
        _fieldsError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.primary,
          elevation: 0,
          title: const Text('اعرف عميلك',style: TextStyle(fontWeight: FontWeight.bold),),
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Container(
            color: AppColors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'برجاء الاجابة على الأسئلة التالية',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'بيانات العمل',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w400,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    const Divider(color: AppColors.border1, height: 28),
                    Expanded(
                      child: ListView(
                        children: [
                          if (_isLoadingFields)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (_fieldsError != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                _fieldsError!,
                                style: const TextStyle(color: AppColors.error),
                                textAlign: TextAlign.center,
                              ),
                            )
                          else ..._requestFields.map(_buildDynamicField),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      title: _isSubmitting ? 'جاري الحفظ...' : 'حفظ',
                      onPressed:
                          (_isLoadingFields || _isSubmitting) ? null : _onSavePressed,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicField(RequestFieldItem field) {
    final title = field.displayText.trim().isNotEmpty ? field.displayText : field.key;
    final type = field.type.toLowerCase();

    if (type == 'text') {
      final controller =
          _textControllers[field.key] ?? TextEditingController(text: field.value ?? '');
      _textControllers[field.key] = controller;
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: AppTextField(
          labelText: title,
          hintText: title,
          controller: controller,
          keyboardType: TextInputType.text,
          textAlign: TextAlign.right,
          validator: (value) {
            final text = (value ?? '').trim();
            if (text.isEmpty) return 'هذا الحقل مطلوب';
            if (text.length < 4) return 'الحد الأدنى 4 أحرف';
            return null;
          },
        ),
      );
    }

    if (type == 'radiogroup') {
      final values = field.availableValues;
      final current = _selectedValues[field.key];
      final selected = values.contains(current) ? current : null;

      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: FormField<String>(
          initialValue: selected,
          validator: (value) {
            if ((value ?? '').trim().isEmpty) {
              return 'برجاء الاختيار';
            }
            return null;
          },
          builder: (state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),
                RadioGroup<String>(
                  groupValue: state.value,
                  onChanged: (value) {
                    setState(() {
                      state.didChange(value);
                      _selectedValues[field.key] = value;
                    });
                  },
                  child: Column(
                    children: values
                        .map(
                          (option) => RadioListTile<String>(
                            contentPadding: EdgeInsets.zero,
                            title: Text(option, textAlign: TextAlign.right),
                            value: option,
                            selected: state.value == option,
                          ),
                        )
                        .toList(),
                  ),
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, right: 12),
                    child: Text(
                      state.errorText ?? '',
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );
    }

    if (type == 'checkbox') {
      final checked = _checkboxValues[field.key] ?? false;
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: checked,
          activeColor: AppColors.primary,
          title: Text(
            title,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: (value) {
            setState(() {
              _checkboxValues[field.key] = value ?? false;
            });
          },
        ),
      );
    }

    if (type == 'date') {
      final current = _dateValues[field.key];

      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: FormField<DateTime>(
          initialValue: current,
          validator: (value) => value == null ? 'برجاء اختيار التاريخ' : null,
          builder: (state) {
            final display = state.value != null
                ? _formatDateDdMmYyyy(state.value!)
                : null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: state.value ?? now,
                      firstDate: DateTime(1900),
                      lastDate: DateTime(now.year + 50, 12, 31),
                    );
                    if (picked != null) {
                      setState(() {
                        state.didChange(picked);
                        _dateValues[field.key] = picked;
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: InputDecorator(
                    isEmpty: display == null,
                    decoration: InputDecoration(
                      hintText: 'اختر $title',
                      hintStyle: const TextStyle(
                        color: AppColors.hintGray,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: AppColors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.border1, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.border1, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.primary, width: 1),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 15,
                      ),
                      suffixIcon:
                          const Icon(Icons.calendar_today, color: AppColors.secondary),
                    ),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        display ?? '',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, right: 12),
                    child: Text(
                      state.errorText ?? '',
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );
    }

    if (type == 'multiselect') {
      final options = field.availableValues;
      final selectedSet =
          Set<String>.from(_multiSelectValues[field.key] ?? {});

      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: FormField<Set<String>>(
          initialValue: selectedSet,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'اختر خياراً واحداً على الأقل';
            }
            return null;
          },
          builder: (state) {
            final active = Set<String>.from(state.value ?? {});

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: options.map((option) {
                    final isOn = active.contains(option);
                    return FilterChip(
                      label: Text(option),
                      selected: isOn,
                      onSelected: (on) {
                        setState(() {
                          final next = Set<String>.from(active);
                          if (on) {
                            next.add(option);
                          } else {
                            next.remove(option);
                          }
                          state.didChange(next);
                          _multiSelectValues[field.key] = next;
                        });
                      },
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      checkmarkColor: AppColors.primary,
                    );
                  }).toList(),
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 12),
                    child: Text(
                      state.errorText ?? '',
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );
    }

    if (type == 'select') {
      final values = field.availableValues;
      final current = _selectedValues[field.key];
      final selected = values.contains(current) ? current : null;

      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.secondary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: selected,
              decoration: InputDecoration(
                hintText: 'اختر $title',
                hintStyle: const TextStyle(
                  color: AppColors.hintGray,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border1, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border1, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              ),
              icon: const Icon(Icons.arrow_drop_down, color: AppColors.secondary),
              items: values
                  .map(
                    (value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, textAlign: TextAlign.right),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedValues[field.key] = value;
                });
              },
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'برجاء الاختيار';
                }
                return null;
              },
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _onSavePressed() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SummaryScreen(answeredFields: _buildSummaryAnswers()),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
