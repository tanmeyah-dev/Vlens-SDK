import 'dart:convert';

import 'package:core/components/button/app_button.dart';
import 'package:core/style/app_colors.dart';
import 'package:core/utils/cache/verification_cache.dart';
import 'package:core/utils/network/http_headers_helper.dart';
import 'package:flutter/material.dart';

import '../../../utils/sdk_http_client.dart';
import '../../mobile_number/constants/api_urls.dart';
import 'userinfoone_scene.dart';

class DigitalIdentitySuccessScene extends StatefulWidget {
  final dynamic extractedData;

  const DigitalIdentitySuccessScene({
    super.key,
    required this.extractedData,
  });

  @override
  State<DigitalIdentitySuccessScene> createState() =>
      _DigitalIdentitySuccessSceneState();
}

class _DigitalIdentitySuccessSceneState extends State<DigitalIdentitySuccessScene> {
  bool _isLoadingTypes = true;
  bool _isCheckingEligibility = false;
  String? _errorMessage;
  dynamic _effectiveExtractedData;

  @override
  void initState() {
    super.initState();
    _effectiveExtractedData = widget.extractedData;
    print('');
    print('═══════════════════════════════════════════════════════');
    print('📄 DIGITAL IDENTITY SUCCESS SCREEN OPENED');
    print('═══════════════════════════════════════════════════════');
    print('extractedData : ${widget.extractedData}');
    print('═══════════════════════════════════════════════════════');
    print('');
    _ensureCachedExtractedData();
    _loadCachedVlensTraceResponseBody();
    _logCurrentAndCachedVlensData();
    _fetchAndCacheRequestTypeId();
  }

  Future<void> _ensureCachedExtractedData() async {
    final cached = await VerificationCache().getVlensExtractedData();
    if (cached != null) return;

    try {
      final normalized = _normalizeData(widget.extractedData);
      await VerificationCache().setVlensExtractedData(normalized);
      print('💾 Cached extractedData from success screen fallback.');
    } catch (e) {
      print('⚠️ Failed to cache extractedData from success screen: $e');
    }
  }

  Future<void> _logCurrentAndCachedVlensData() async {
    dynamic normalizedCurrent;
    try {
      normalizedCurrent = _deepSerializable(widget.extractedData);
    } catch (_) {
      normalizedCurrent = '${widget.extractedData}';
    }

    final cachedData = await VerificationCache().getVlensExtractedData();
    final cachedTraceBody = await VerificationCache().getVlensTraceResponseBody();
    final currentPretty = _prettyJsonOrText(normalizedCurrent);
    final cachedPretty = _prettyJsonOrText(cachedData);
    final cachedTracePretty = _prettyJsonOrText(cachedTraceBody);
    print('');
    print('═══════════════════════════════════════════════════════');
    print('🧾 VLENS DATA COMPARISON (CURRENT VS CACHED)');
    print('═══════════════════════════════════════════════════════');
    print('Current extractedData: $currentPretty');
    print('Cached extractedData: $cachedPretty');
    print('Cached VLENS_TRACE response body: $cachedTracePretty');
    print('═══════════════════════════════════════════════════════');
    print('');
  }

  dynamic _deepSerializable(dynamic value) {
    if (value == null ||
        value is String ||
        value is num ||
        value is bool) {
      return value;
    }

    if (value is List) {
      return value.map(_deepSerializable).toList();
    }

    if (value is Map) {
      return value.map(
        (key, nested) => MapEntry('$key', _deepSerializable(nested)),
      );
    }

    try {
      final dynamic asJson = (value as dynamic).toJson();
      return _deepSerializable(asJson);
    } catch (_) {
      return '$value';
    }
  }

  String _prettyJsonOrText(dynamic value) {
    try {
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      return '$value';
    }
  }

  Future<void> _loadCachedVlensTraceResponseBody() async {
    final cachedTraceBody = await VerificationCache().getVlensTraceResponseBody();
    if (cachedTraceBody == null) return;
    print('📦 Loaded cached VLENS_TRACE response body in success screen.');
    if (_effectiveExtractedData == null && mounted) {
      setState(() {
        _effectiveExtractedData = cachedTraceBody;
      });
    }
  }

  Future<void> _fetchAndCacheRequestTypeId() async {
    setState(() {
      _isLoadingTypes = true;
      _errorMessage = null;
    });

    try {
      final token = await _resolveToken();
      final headers = token != null && token.isNotEmpty
          ? HttpHeadersHelper.getHeadersWithAuth(token)
          : HttpHeadersHelper.getDefaultHeaders();
      final requestTypesUrl = ApiUrls.getRequestTypesUrl();
      print('');
      print('═══════════════════════════════════════════════════════');
      print('📤 REQUEST TYPES API CALL');
      print('═══════════════════════════════════════════════════════');
      print('URL: $requestTypesUrl');
      print('Method: GET');
      print('Has Bearer Token: ${token != null && token.isNotEmpty}');
      print('Headers: $headers');
      print('═══════════════════════════════════════════════════════');
      print('');
      final response = await SdkHttpClient.get(
        Uri.parse(requestTypesUrl),
        headers: headers,
      );
      print('');
      print('═══════════════════════════════════════════════════════');
      print('📥 REQUEST TYPES API RESPONSE');
      print('═══════════════════════════════════════════════════════');
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');
      print('═══════════════════════════════════════════════════════');
      print('');

      if (response.statusCode != 200) {
        throw Exception('فشل تحميل أنواع الطلبات (${response.statusCode})');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('استجابة غير صالحة من الخادم');
      }

      final data = decoded['data'];
      if (data is! List || data.isEmpty) {
        throw Exception('لا توجد أنواع طلبات متاحة');
      }

      final first = data.first;
      if (first is! Map<String, dynamic> || first['id'] == null) {
        throw Exception('تعذر قراءة نوع الطلب');
      }

      final rawId = first['id'];
      final requestTypeId = rawId is int ? rawId : int.tryParse('$rawId');
      if (requestTypeId == null) {
        throw Exception('معرف نوع الطلب غير صالح');
      }

      await VerificationCache().setRequestTypeId(requestTypeId);
      print('💾 Cached requestTypeId: $requestTypeId');
      if (!mounted) return;
      setState(() {
        _isLoadingTypes = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingTypes = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<String?> _resolveToken() async {
    final cache = VerificationCache();
    final access = await cache.getAccessToken();
    if (access != null && access.trim().isNotEmpty) {
      return access.trim();
    }
    final encrypted = await cache.getEncryptedAccessToken();
    if (encrypted != null && encrypted.trim().isNotEmpty) {
      return encrypted.trim();
    }
    return null;
  }

  List<MapEntry<String, String>> _buildRowsFromExtractedData(dynamic data) {
    final normalized = _normalizeData(data);
    final rows = <MapEntry<String, String>>[];
    _flattenToRows(normalized, rows);
    if (rows.isEmpty) {
      return [const MapEntry('data', '')];
    }
    return rows;
  }

  dynamic _normalizeData(dynamic value) {
    if (value == null) return null;
    if (value is Map || value is List || value is String || value is num || value is bool) {
      return value;
    }

    // Try to use object.toJson() via jsonEncode/jsonDecode for SDK models.
    try {
      final encoded = jsonEncode(value);
      return jsonDecode(encoded);
    } catch (_) {
      return '$value';
    }
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

  Future<void> _onContinuePressed() async {
    setState(() {
      _isCheckingEligibility = true;
      _errorMessage = null;
    });

    try {
      final token = await _resolveToken();
      final headers = token != null && token.isNotEmpty
          ? HttpHeadersHelper.getHeadersWithAuth(token)
          : HttpHeadersHelper.getDefaultHeaders();
      final eligibilityUrl = ApiUrls.getRequestEligibilityUrl();
      print('');
      print('═══════════════════════════════════════════════════════');
      print('📤 REQUEST ELIGIBILITY API CALL');
      print('═══════════════════════════════════════════════════════');
      print('URL: $eligibilityUrl');
      print('Method: GET');
      print('Has Bearer Token: ${token != null && token.isNotEmpty}');
      print('Headers: $headers');
      print('═══════════════════════════════════════════════════════');
      print('');
      final response = await SdkHttpClient.get(
        Uri.parse(eligibilityUrl),
        headers: headers,
      );
      print('');
      print('═══════════════════════════════════════════════════════');
      print('📥 REQUEST ELIGIBILITY API RESPONSE');
      print('═══════════════════════════════════════════════════════');
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');
      print('═══════════════════════════════════════════════════════');
      print('');

      if (response.statusCode != 200) {
        throw Exception('فشل التحقق من الأهلية (${response.statusCode})');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('استجابة الأهلية غير صالحة');
      }

      final data = decoded['data'];
      final isEligible = data is Map<String, dynamic> && data['isEligible'] == true;
      print('✅ Eligibility result: isEligible=$isEligible');
      if (!mounted) return;
      if (isEligible) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => UserInfoOneScene(eligibilityResponse: decoded),
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'عذراً، المستخدم غير مؤهل حالياً';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingEligibility = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _buildRowsFromExtractedData(_effectiveExtractedData);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.primary,
          elevation: 0,
          title: const Text('نتيجة التحقق'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'تم انشاء هاويتك الرقميه بنجاح و هذه هي البيانات الخاصه بك',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Table(
                      border: TableBorder.all(color: AppColors.border1),
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(3),
                      },
                      children: [
                        const TableRow(
                          decoration: BoxDecoration(color: Color(0xFFF2F6F8)),
                          children: [
                            Padding(
                              padding: EdgeInsets.all(10),
                              child: Text(
                                'الحقل',
                                style: TextStyle(fontWeight: FontWeight.w700),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(10),
                              child: Text(
                                'القيمة',
                                style: TextStyle(fontWeight: FontWeight.w700),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        ...rows.map(
                          (entry) => TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Text(entry.key),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Text(entry.value),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isLoadingTypes) ...[
                  const SizedBox(height: 8),
                  const Center(child: CircularProgressIndicator()),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 12),
                AppButton(
                  title: _isCheckingEligibility
                      ? 'جاري التحقق...'
                      : 'اضغط هنا لاستكمال البيانات',
                  onPressed: (_isLoadingTypes || _isCheckingEligibility)
                      ? null
                      : _onContinuePressed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
