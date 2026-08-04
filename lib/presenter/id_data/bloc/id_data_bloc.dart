import 'dart:async';
import 'dart:convert';

import 'package:core/bases/base_bloc.dart';
import 'package:core/bases/states/base/init_screen.dart';
import 'package:core/utils/cache/verification_cache.dart';
import 'package:core/utils/network/http_headers_helper.dart';

import '../../../utils/sdk_http_client.dart';
import '../../validate_user/constants/api_urls.dart';
import '../event/id_data_event.dart';
import '../model/id_data_model.dart';
import '../state/id_data_state.dart';
import '../utils/id_data_parser.dart';

class IdDataBloc extends BaseBloc {
  IdDataBloc(this._model)
      : super(initialState: InitScreen(_model)) {
    on<IdDataInitializeEvent>(_onInitialize);
    on<IdDataContinueEvent>(_onContinue);
    Future<void>.microtask(() => add(IdDataInitializeEvent()));
  }

  final IdDataModel _model;

  Future<void> _onInitialize(
    IdDataInitializeEvent event,
    emit,
  ) async {
    emit(UpdateIdDataUI(_model));

    await Future.wait<void>([
      _ensureCachedExtractedData(),
      _loadCachedVlensTraceResponseBody(emit),
    ]);
    unawaited(_fetchAndCacheRequestTypeId(emit));
  }

  Future<void> _ensureCachedExtractedData() async {
    try {
      final normalized =
          (_model.effectiveExtractedData ??
                  parseExtractedUserData(_model.extractedData))
              ?.toJson() ??
          normalizeDynamicData(_model.extractedData);
      if (normalized == null) return;
      await VerificationCache().setVlensExtractedData(normalized);
    } catch (_) {}
  }

  Future<void> _loadCachedVlensTraceResponseBody(dynamic emit) async {
    final cachedTraceBody = await VerificationCache().getVlensTraceResponseBody();
    if (cachedTraceBody == null) return;
    final parsed = parseExtractedUserData(cachedTraceBody);
    if (_model.effectiveExtractedData == null) {
      _model.effectiveExtractedData = parsed;
      emit(UpdateIdDataUI(_model));
    }
  }

  Future<void> _fetchAndCacheRequestTypeId(dynamic emit) async {
    if (await VerificationCache().getRequestTypeId() != null) {
      return;
    }

    try {
      final token = await _resolveToken();
      final headers = token != null && token.isNotEmpty
          ? HttpHeadersHelper.getHeadersWithAuth(token)
          : HttpHeadersHelper.getDefaultHeaders();
      final requestTypesUrl = ApiUrls.getRequestTypesUrl();
      final response = await SdkHttpClient.get(
        Uri.parse(requestTypesUrl),
        headers: headers,
      );

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
      _model.errorMessage = null;
      emit(UpdateIdDataUI(_model));
    } catch (e) {
      _model.errorMessage = e.toString().replaceAll('Exception: ', '');
      emit(UpdateIdDataUI(_model));
    }
  }

  Future<void> _onContinue(
    IdDataContinueEvent event,
    emit,
  ) async {
    _model.isCheckingEligibility = true;
    _model.errorMessage = null;
    emit(UpdateIdDataUI(_model));

    try {
      // Always refresh cached identity so user_info can prefill from it.
      await _ensureCachedExtractedData();

      if (await VerificationCache().getRequestTypeId() == null) {
        await _fetchAndCacheRequestTypeId(emit);
      }
      if (await VerificationCache().getRequestTypeId() == null) {
        _model.errorMessage ??= 'تعذر تحميل أنواع الطلبات';
        return;
      }

      final token = await _resolveToken();
      final headers = token != null && token.isNotEmpty
          ? HttpHeadersHelper.getHeadersWithAuth(token)
          : HttpHeadersHelper.getDefaultHeaders();
      final eligibilityUrl = ApiUrls.getRequestEligibilityUrl();
      final response = await SdkHttpClient.get(
        Uri.parse(eligibilityUrl),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('فشل التحقق من الأهلية (${response.statusCode})');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('استجابة الأهلية غير صالحة');
      }

      final data = decoded['data'];
      final isEligible = data is Map<String, dynamic> && data['isEligible'] == true;
      if (isEligible) {
        emit(IdDataNavigateToUserInfoState(decoded));
      } else {
        _model.errorMessage = 'عذراً، المستخدم غير مؤهل حالياً';
      }
    } catch (e) {
      _model.errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _model.isCheckingEligibility = false;
      emit(UpdateIdDataUI(_model));
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
}
