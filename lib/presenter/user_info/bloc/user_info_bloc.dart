import 'dart:convert';

import 'package:core/bases/base_bloc.dart';
import 'package:core/bases/states/base/init_screen.dart';
import 'package:core/utils/cache/verification_cache.dart';
import 'package:core/utils/network/http_headers_helper.dart';
import 'package:flutter/foundation.dart';

import '../../../utils/sdk_http_client.dart';
import '../../id_data/utils/id_data_parser.dart';
import '../../validate_user/constants/api_urls.dart';
import '../event/user_info_event.dart';
import '../model/request_fields_response.dart';
import '../model/user_info_model.dart';
import '../state/user_info_state.dart';

class UserInfoBloc extends BaseBloc {
  UserInfoBloc(this._model)
      : super(initialState: InitScreen(_model)) {
    on<UserInfoLoadFieldsEvent>(_onLoadFields);
    on<UserInfoFormChangedEvent>(_onFormChanged);
    on<UserInfoSubmitEvent>(_onSubmit);
    Future<void>.microtask(() => add(UserInfoLoadFieldsEvent()));
  }

  final UserInfoModel _model;

  @override
  Future<void> close() {
    _model.dispose();
    return super.close();
  }

  void _onFormChanged(UserInfoFormChangedEvent event, emit) {
    emit(UpdateUserInfoUI(_model));
  }

  Future<void> _onSubmit(UserInfoSubmitEvent event, emit) async {
    emit(
      UserInfoNavigateToSummaryState(
        answeredFields: event.answers,
        userInfoModel: _model,
      ),
    );
  }

  Future<void> _onLoadFields(UserInfoLoadFieldsEvent event, emit) async {
    if (kDebugMode) {
      print('');
      print('═══════════════════════════════════════════════════════');
      print('📄 USER INFO SCREEN OPENED');
      print('═══════════════════════════════════════════════════════');
      print('Eligibility response: ${jsonEncode(_model.eligibilityResponse)}');
      print('═══════════════════════════════════════════════════════');
      print('');
    }

    final data = _model.eligibilityResponse['data'];
    final isEligible = data is Map<String, dynamic> && data['isEligible'] == true;

    if (!isEligible) {
      if (kDebugMode) {
        print('ℹ️ USER_INFO: isEligible=false, skipping request/fields call.');
      }
      _model.isLoadingFields = false;
      _model.areFieldsReady = false;
      _model.fieldsError = 'المستخدم غير مؤهل حالياً';
      emit(UpdateUserInfoUI(_model));
      return;
    }

    _model.isLoadingFields = true;
    _model.areFieldsReady = false;
    _model.fieldsError = null;
    emit(UpdateUserInfoUI(_model));

    final cache = VerificationCache();
    await _loadCachedExtractedData(cache);

    final requestTypeId = ApiUrls.kRequestTypeId;
    await cache.setRequestTypeId(requestTypeId);
    final accessToken = await cache.getAccessToken();
    final encryptedToken = await cache.getEncryptedAccessToken();
    final token = (accessToken != null && accessToken.trim().isNotEmpty)
        ? accessToken.trim()
        : (encryptedToken ?? '').trim();

    final headers = token.isNotEmpty
        ? HttpHeadersHelper.getHeadersWithAuth(token)
        : HttpHeadersHelper.getDefaultHeaders();
    final fieldsUrl = ApiUrls.getRequestFieldsUrl(requestTypeId: requestTypeId);

    if (kDebugMode) {
      print('');
      print('═══════════════════════════════════════════════════════');
      print('📤 USER_INFO API CALL');
      print('═══════════════════════════════════════════════════════');
      print('Fields URL: $fieldsUrl');
      print('requestTypeId (cached): $requestTypeId');
      print('Has Bearer Token: ${token.isNotEmpty}');
      print('Cached extracted data: ${_model.cachedExtractedData != null}');
      print('═══════════════════════════════════════════════════════');
      print('');
    }

    try {
      final fieldsResponse =
          await SdkHttpClient.get(Uri.parse(fieldsUrl), headers: headers);

      if (kDebugMode) {
        print('');
        print('═══════════════════════════════════════════════════════');
        print('📥 REQUEST FIELDS API RESPONSE (USER_INFO)');
        print('═══════════════════════════════════════════════════════');
        print('Status Code: ${fieldsResponse.statusCode}');
        print('Body: ${fieldsResponse.body}');
        print('═══════════════════════════════════════════════════════');
        print('');
      }

      if (fieldsResponse.statusCode != 200) {
        throw Exception('فشل تحميل الحقول (${fieldsResponse.statusCode})');
      }

      final decodedFields = jsonDecode(fieldsResponse.body);
      if (decodedFields is! Map<String, dynamic>) {
        throw Exception('استجابة غير صالحة من request/fields');
      }

      final parsed = RequestFieldsResponse.fromJson(decodedFields);
      final fields = parsed.data?.requestsFields
              .where((field) => field.visibleToUser)
              .toList() ??
          <RequestFieldItem>[];
      fields.sort((a, b) => a.order.compareTo(b.order));

      _model.populateFromRequestFields(fields);
      _model.isLoadingFields = false;
      _model.areFieldsReady = true;
      _model.fieldsError = null;

      if (kDebugMode) {
        final gender = _model.selectedValues['CIF_GENDER'];
        final religion = _model.selectedValues['CIF_RELIGION'];
        final social = _model.selectedValues['CIF_SOCIAL_STATUS'];
        print(
          '✅ USER_INFO: requestFields=${fields.length}',
        );
        print(
          '✅ USER_INFO defaults from national ID => '
          'GENDER=$gender, RELIGION=$religion, SOCIAL_STATUS=$social '
          '(cached=${_model.cachedExtractedData != null})',
        );
      }

      emit(UpdateUserInfoUI(_model));
    } catch (e) {
      if (kDebugMode) {
        print('❌ USER_INFO LOAD ERROR: $e');
      }
      _model.isLoadingFields = false;
      _model.areFieldsReady = false;
      _model.fieldsError = e.toString().replaceAll('Exception: ', '');
      emit(UpdateUserInfoUI(_model));
    }
  }

  Future<void> _loadCachedExtractedData(VerificationCache cache) async {
    if (_model.cachedExtractedData != null) {
      if (kDebugMode) {
        print(
          '📦 USER_INFO: using extracted data passed from IdDataScreen '
          '(marital=${_model.cachedExtractedData?.idBackData?.maritalStatus})',
        );
      }
      return;
    }

    try {
      final cached = await cache.getVlensExtractedData();
      _model.cachedExtractedData = parseExtractedUserData(cached);
      if (kDebugMode) {
        print(
          '📦 USER_INFO: loaded cached extracted data '
          '(${_model.cachedExtractedData != null})',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ USER_INFO: failed to load cached extracted data: $e');
      }
      _model.cachedExtractedData = null;
    }
  }

}
