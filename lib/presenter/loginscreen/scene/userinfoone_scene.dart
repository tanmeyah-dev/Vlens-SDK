import 'dart:convert';

import 'package:core/components/button/app_button.dart';
import 'package:core/components/textField/app_textfield.dart';
import 'package:core/utils/cache/verification_cache.dart';
import 'package:core/utils/network/http_headers_helper.dart';
import 'package:core/style/app_colors.dart';
import 'package:flutter/material.dart';

import '../model/request_fields_response.dart';
import '../utils/device_info_helper.dart';
import '../../../utils/sdk_http_client.dart';
import '../../mobile_number/constants/api_urls.dart';

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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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
        if (field.type.toLowerCase() == 'text') {
          _textControllers[field.key] =
              TextEditingController(text: field.value ?? '');
        } else if (field.type.toLowerCase() == 'select') {
          _selectedValues[field.key] = field.value;
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
        body: Padding(
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
      final cache = VerificationCache();
      final requestTypeId = await cache.getRequestTypeId();
      if (requestTypeId == null) {
        throw Exception('معرف نوع الطلب غير متوفر');
      }

      final accessToken = await cache.getAccessToken();
      final encryptedToken = await cache.getEncryptedAccessToken();
      final token = (accessToken != null && accessToken.trim().isNotEmpty)
          ? accessToken.trim()
          : (encryptedToken ?? '').trim();
      final headers = token.isNotEmpty
          ? HttpHeadersHelper.getHeadersWithAuth(token)
          : HttpHeadersHelper.getDefaultHeaders();

      final location = await DeviceInfoHelper.getCurrentLocation();
      final latitude = (location['latitude'] as num?)?.toDouble() ?? 0.0;
      final longitude = (location['longitude'] as num?)?.toDouble() ?? 0.0;
      final userDeviceUtcTime = DateTime.now().toUtc().toIso8601String();

      final requestFieldsValues = <String, dynamic>{};
      for (final field in _requestFields) {
        final type = field.type.toLowerCase();
        if (type == 'text') {
          final value = _textControllers[field.key]?.text.trim() ?? '';
          requestFieldsValues[field.key] = value;
        } else if (type == 'select') {
          final value = (_selectedValues[field.key] ?? '').trim();
          requestFieldsValues[field.key] = value;
        }
      }

      final body = {
        'requestTypeId': requestTypeId,
        'geoLocation': {
          'latitude': latitude,
          'longitude': longitude,
        },
        'userDeviceUtcTime': userDeviceUtcTime,
        'requestFieldsValues': requestFieldsValues,
      };

      final createUrl = ApiUrls.getRequestCreateUrl();
      print('');
      print('═══════════════════════════════════════════════════════');
      print('📤 REQUEST CREATE API CALL (USERINFOONE)');
      print('═══════════════════════════════════════════════════════');
      print('URL: $createUrl');
      print('Method: POST');
      print('Headers: $headers');
      print('Body: ${jsonEncode(body)}');
      print('═══════════════════════════════════════════════════════');
      print('');

      final response = await SdkHttpClient.post(
        Uri.parse(createUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      print('');
      print('═══════════════════════════════════════════════════════');
      print('📥 REQUEST CREATE API RESPONSE (USERINFOONE)');
      print('═══════════════════════════════════════════════════════');
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');
      print('═══════════════════════════════════════════════════════');
      print('');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.statusCode == 200
                ? 'تم حفظ البيانات بنجاح'
                : 'تم إرسال الطلب (${response.statusCode})',
          ),
          backgroundColor:
              response.statusCode == 200 ? AppColors.primary : AppColors.error,
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
