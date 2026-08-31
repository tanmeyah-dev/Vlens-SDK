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
import '../utils/vlens_data_api_helper.dart';

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
    _model.isLoadingVlensData = true;
    _model.errorMessage = null;
    emit(UpdateIdDataUI(_model));

    try {
      if (_model.loadFromApi) {
        // Verified login: GET /vlens-data?phoneNumber=... only (no POST).
        await _loadFromApi(emit);
      } else {
        // After VLens scan: POST extracted data and show it (no GET).
        await _submitFreshExtractedData(emit);
      }
    } finally {
      _model.isLoadingVlensData = false;
      emit(UpdateIdDataUI(_model));
    }

    await VerificationCache().setRequestTypeId(ApiUrls.kRequestTypeId);
  }

  /// Login (verified) path — GET only.
  Future<void> _loadFromApi(dynamic emit) async {
    try {
      final remote = await fetchVlensData();
      if (remote != null) {
        _model.effectiveExtractedData = remote;
        await _overwriteCachedExtractedData(remote);
        _model.errorMessage = null;
        emit(UpdateIdDataUI(_model));
        // ignore: avoid_print
        print('📦 IdDataBloc: loaded VLens data from API (login GET)');
      } else {
        _model.effectiveExtractedData = null;
        _model.errorMessage = 'لا توجد بيانات هوية متاحة';
        emit(UpdateIdDataUI(_model));
      }
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ IdDataBloc: failed to fetch VLens data from API: $e');
      _model.effectiveExtractedData = null;
      _model.errorMessage = e.toString().replaceAll('Exception: ', '');
      emit(UpdateIdDataUI(_model));
    }
  }

  /// VLens success path — POST extracted payload only (no GET).
  Future<void> _submitFreshExtractedData(dynamic emit) async {
    final fresh = _model.effectiveExtractedData ??
        parseExtractedUserData(_model.extractedData);
    if (fresh == null) {
      _model.errorMessage = 'لا توجد بيانات هوية لإرسالها';
      emit(UpdateIdDataUI(_model));
      return;
    }

    _model.effectiveExtractedData = fresh;
    await _overwriteCachedExtractedData(fresh);
    emit(UpdateIdDataUI(_model));

    try {
      await submitVlensData(fresh);
      // ignore: avoid_print
      print('✅ IdDataBloc: submitted VLens data to API (POST after scan)');
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ IdDataBloc: failed to submit VLens data: $e');
      _model.errorMessage = e.toString().replaceAll('Exception: ', '');
      emit(UpdateIdDataUI(_model));
    }
  }

  Future<void> _overwriteCachedExtractedData(dynamic data) async {
    try {
      final normalized = parseExtractedUserData(data)?.toJson() ??
          normalizeDynamicData(data);
      if (normalized == null) return;
      final cache = VerificationCache();
      await cache.setVlensExtractedData(normalized);
      await cache.setVlensTraceResponseBody(normalized);
      // ignore: avoid_print
      print('💾 IdDataBloc: overwritten VLens cache with latest scan');
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ IdDataBloc: failed to overwrite VLens cache: $e');
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
      // Always refresh cached identity so user_info can prefill from latest scan.
      final latest = _model.effectiveExtractedData ??
          parseExtractedUserData(_model.extractedData);
      if (latest != null) {
        await _overwriteCachedExtractedData(latest);
      }

      await VerificationCache().setRequestTypeId(ApiUrls.kRequestTypeId);

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
