import 'dart:convert';

import 'package:core/components/button/app_button.dart';
import 'package:core/style/app_colors.dart';
import 'package:core/utils/cache/verification_cache.dart';
import 'package:core/utils/network/http_headers_helper.dart';
import 'package:flutter/material.dart';

import '../../../data/models/extracted_user_data.dart';
import '../../../utils/api_error_parser.dart';
import '../../../utils/sdk_http_client.dart';
import '../utils/device_info_helper.dart';
import 'request_submitted_scene.dart';
import '../../mobile_number/constants/api_urls.dart';
import '../../mobile_number/widgets/app_header.dart';

class SummaryAnswerItem {
  final String key;
  final String label;
  final String value;

  const SummaryAnswerItem({
    required this.key,
    required this.label,
    required this.value,
  });
}

class SummaryScreen extends StatefulWidget {
  final List<SummaryAnswerItem> answeredFields;

  const SummaryScreen({
    super.key,
    required this.answeredFields,
  });

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  static const Set<String> _hiddenRowKeys = {
    'isverificationprocesscompeleeted',
    'isverificationprocesscompleted',
    'isdigitalidentityverified',
    'deviceinfo',
    'user',
    'idfrontdata.gender',
    'idfrontdata.client_transaction_id',
    'idfrontdata.requesr_id',
    'idfrontdata.request_id',
    'idbackdata.client_transaction_id',
  };

  bool _isLoadingIdentityData = true;
  bool _isSubmitting = false;
  ExtractedUserData? _identityData;
  String _cardNumber = '';
  bool _isPermissionAccepted = false;

  @override
  void initState() {
    super.initState();
    _loadIdentityRows();
  }

  Future<void> _loadIdentityRows() async {
    final cached = await VerificationCache().getVlensExtractedData();
    final data = _toExtractedUserData(cached);
    final rows = _buildRowsFromExtractedData(data);
    final cardNumber = _resolveCardNumber(data, rows);
    if (!mounted) return;
    setState(() {
      _identityData = data;
      _cardNumber = cardNumber;
      _isLoadingIdentityData = false;
    });
  }

  String _resolveCardNumber(
    ExtractedUserData? data,
    List<MapEntry<String, String>> rows,
  ) {
    final fromModel = data?.idFrontData?.idNumber ??
        data?.user?.idNumber ??
        data?.idBackData?.idNumber;
    if (fromModel != null && fromModel.trim().isNotEmpty) {
      return fromModel.trim();
    }

    for (final row in rows) {
      final key = row.key.toLowerCase().replaceAll('_', '').replaceAll('.', '');
      if (key.contains('idnumber') && row.value.trim().isNotEmpty) {
        return row.value.trim();
      }
    }
    return '';
  }

  ExtractedUserData? _toExtractedUserData(dynamic value) {
    if (value == null) return null;
    if (value is ExtractedUserData) return value;
    if (value is Map<String, dynamic>) return ExtractedUserData.fromJson(value);
    if (value is Map) {
      return ExtractedUserData.fromJson(Map<String, dynamic>.from(value));
    }
    return null;
  }

  List<MapEntry<String, String>> _buildRowsFromExtractedData(ExtractedUserData? data) {
    final normalized = data?.toJson();
    final rows = <MapEntry<String, String>>[];
    _flattenToRows(normalized, rows);
    rows.removeWhere(
      (entry) => _hiddenRowKeys.contains(entry.key.trim().toLowerCase()),
    );
    if (rows.isEmpty) {
      return [const MapEntry('data', '')];
    }
    return rows;
  }

  void _flattenToRows(
    dynamic value,
    List<MapEntry<String, String>> rows, {
    String prefix = '',
  }) {
    if (value is Map) {
      value.forEach((key, nestedValue) {
        final nextPrefix = prefix.isEmpty ? '$key' : '$prefix.$key';
        _flattenToRows(nestedValue, rows, prefix: nextPrefix);
      });
      return;
    }

    if (value is List) {
      for (var i = 0; i < value.length; i++) {
        final nextPrefix = prefix.isEmpty ? '[$i]' : '$prefix[$i]';
        _flattenToRows(value[i], rows, prefix: nextPrefix);
      }
      return;
    }

    rows.add(MapEntry(prefix.isEmpty ? 'data' : prefix, '${value ?? ''}'));
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day-$month-$year';
  }

  String _getDisplayName() {
    final fullName = _identityData?.user?.fullName?.trim();
    if (fullName != null && fullName.isNotEmpty) return fullName;
    final idName = _identityData?.idFrontData?.name?.trim();
    if (idName != null && idName.isNotEmpty) return idName;
    return '';
  }

  List<MapEntry<String, String>> _buildPrimaryIdentityFields() {
    final data = _identityData;
    return [
      MapEntry('الاسم', data?.idFrontData?.name?.trim().isNotEmpty == true
          ? data!.idFrontData!.name!.trim()
          : data?.user?.fullName?.trim() ?? ''),
      MapEntry('العنوان', data?.idFrontData?.address?.trim().isNotEmpty == true
          ? data!.idFrontData!.address!.trim()
          : data?.user?.address?.trim() ?? ''),
      MapEntry('تاريخ الميلاد', _formatDate(data?.idFrontData?.dateOfBirth)),
      MapEntry('الحالة الاجتماعية', data?.idBackData?.maritalStatus?.trim() ?? ''),
      MapEntry(
        'النوع',
        data?.idFrontData?.gender?.trim().isNotEmpty == true
            ? data!.idFrontData!.gender!.trim()
            : data?.idBackData?.gender?.trim() ?? '',
      ),
    ];
  }

  Widget _buildIdentityFieldRow(MapEntry<String, String> row) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            row.key,
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              row.value,
              style: const TextStyle(
                color: AppColors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerFieldRow(MapEntry<String, String> row) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            row.key,
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              row.value,
              style: const TextStyle(
                color: AppColors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightedPrimaryRow() {
    final valueText = _cardNumber;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFA7A9AC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'رقم البطاقة',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 44 / 2, // keep visual scale close to design
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.left,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              valueText,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 40 / 2, // keep visual scale close to design
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSendPressed() async {
    if (_isSubmitting) return;

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

      final userDeviceUtcTime = DateTime.now().toUtc().toIso8601String();

      final requestFieldsValues = <String, dynamic>{};
      for (final item in widget.answeredFields) {
        requestFieldsValues[item.key] = item.value.trim();
      }

      final body = {
        'requestTypeId': requestTypeId,
        'geoLocation': await DeviceInfoHelper.getCurrentLocation(),
        'userDeviceUtcTime': userDeviceUtcTime,
        'requestFieldsValues': requestFieldsValues,
      };

      final createUrl = ApiUrls.getRequestCreateUrl();
      print('');
      print('═══════════════════════════════════════════════════════');
      print('📤 REQUEST CREATE API CALL (SUMMARY)');
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
      print('📥 REQUEST CREATE API RESPONSE (SUMMARY)');
      print('═══════════════════════════════════════════════════════');
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');
      print('═══════════════════════════════════════════════════════');
      print('');

      if (!mounted) return;
      if (response.statusCode == 200) {
        final decodedCreateResponse = _tryDecodeMap(response.body);
        final isCreateSuccess = _isCreateRequestSuccess(decodedCreateResponse);
        if (!isCreateSuccess) {
          final createErrorMessage = ApiErrorParser.extractMessage(
            response.body,
            fallbackMessage: 'فشل إنشاء الطلب',
          );
          throw Exception(createErrorMessage);
        }

        final createdRequestId = _extractCreatedRequestId(decodedCreateResponse);
        if (createdRequestId == null) {
          throw Exception('رقم الطلب الناتج من إنشاء الطلب غير متوفر');
        }

        setState(() {
          _isSubmitting = false;
        });
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RequestSubmittedScene(requestId: createdRequestId),
          ),
        );
      } else {
        final errorMessage = response.statusCode == 417
            ? ApiErrorParser.extractMessage(
                response.body,
                fallbackMessage: 'تم إرسال الطلب (${response.statusCode})',
              )
            : 'تم إرسال الطلب (${response.statusCode})';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (!mounted) return;
      if (_isSubmitting) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Map<String, dynamic>? _tryDecodeMap(String rawBody) {
    if (rawBody.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(rawBody);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // Ignore malformed JSON and fallback with null map.
    }
    return null;
  }

  bool _isCreateRequestSuccess(Map<String, dynamic>? responseBody) {
    if (responseBody == null) return false;
    final rootSuccess = responseBody['success'];
    if (rootSuccess is bool) return rootSuccess;

    final data = responseBody['data'];
    if (data is Map) {
      final dataSuccess = data['success'];
      if (dataSuccess is bool) return dataSuccess;
    }
    return false;
  }

  dynamic _extractCreatedRequestId(Map<String, dynamic>? responseBody) {
    if (responseBody == null) return null;
    if (responseBody['id'] != null) return responseBody['id'];

    final data = responseBody['data'];
    if (data is Map) {
      final dataMap = Map<String, dynamic>.from(data);
      if (dataMap['id'] != null) return dataMap['id'];
      if (dataMap['requestId'] != null) return dataMap['requestId'];
    }
    return null;
  }

  Widget _buildConsentText() {
    final name = _getDisplayName();
    return RichText(
      textAlign: TextAlign.start,
      text: TextSpan(
        style: const TextStyle(
          color: Color(0xFF0A84D0),
          fontSize: 20,
          fontWeight: FontWeight.w500,
          height: 1.35,
        ),
        children: [
          const TextSpan(text: 'نعم أقر أنا '),
          TextSpan(
            text: name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const TextSpan(text: '\n'),
          const TextSpan(
            text: 'بأن هذه البيانات صحيحة وأي خطأ\nبها يعرضني للمساءلة القانونية',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final answersRows = widget.answeredFields
        .map((item) => MapEntry(item.label, item.value))
        .toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: Stack(
          children: [
            SafeArea(
              child: Container(
                color: AppColors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const AppHeader(),
                        const SizedBox(height: 8),
                        const Text(
                          'برجاء مراجعة هذه البيانات و التأكد من صحتها',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        if (_isLoadingIdentityData)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else
                          _buildHighlightedPrimaryRow(),
                        const Divider(color: AppColors.border1, height: 22),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: _isLoadingIdentityData
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(20),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : Column(
                                  children: _buildPrimaryIdentityFields()
                                      .map(_buildIdentityFieldRow)
                                      .toList(),
                                ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: answersRows.map(_buildAnswerFieldRow).toList(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isPermissionAccepted = !_isPermissionAccepted;
                            });
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                _isPermissionAccepted
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: _isPermissionAccepted
                                    ? AppColors.primary
                                    : AppColors.secondary,
                                size: 32,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: _buildConsentText(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        AppButton(
                          title: _isSubmitting ? 'جاري الإرسال...' : 'ارسال',
                          onPressed: (_isPermissionAccepted && !_isSubmitting)
                              ? _onSendPressed
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_isSubmitting)
              Positioned.fill(
                child: AbsorbPointer(
                  child: Container(
                    color: Colors.black26,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
