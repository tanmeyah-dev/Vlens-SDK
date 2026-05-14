import 'dart:convert';

import 'package:core/bases/base_bloc.dart';
import 'package:core/bases/states/base/init_screen.dart';
import 'package:core/utils/cache/verification_cache.dart';
import 'package:core/utils/network/http_headers_helper.dart';
import 'package:flutter/foundation.dart';

import '../../../utils/sdk_http_client.dart';
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

  void _onSubmit(UserInfoSubmitEvent event, emit) {
    emit(UserInfoNavigateToSummaryState(event.answers));
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
      _model.fieldsError = 'المستخدم غير مؤهل حالياً';
      emit(UpdateUserInfoUI(_model));
      return;
    }

    _model.isLoadingFields = true;
    _model.fieldsError = null;
    emit(UpdateUserInfoUI(_model));

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

    if (kDebugMode) {
      print('');
      print('═══════════════════════════════════════════════════════');
      print('📤 REQUEST FIELDS API CALL (USER_INFO)');
      print('═══════════════════════════════════════════════════════');
      print('URL: $url');
      print('Method: GET');
      print('requestTypeId (cached): $requestTypeId');
      print('Has Bearer Token: ${token.isNotEmpty}');
      print('Headers: $headers');
      print('═══════════════════════════════════════════════════════');
      print('');
    }

    try {
      final response = await SdkHttpClient.get(
        Uri.parse(url),
        headers: headers,
      );

      if (kDebugMode) {
        print('');
        print('═══════════════════════════════════════════════════════');
        print('📥 REQUEST FIELDS API RESPONSE (USER_INFO)');
        print('═══════════════════════════════════════════════════════');
        print('Status Code: ${response.statusCode}');
        print('Body: ${response.body}');
        print('═══════════════════════════════════════════════════════');
        print('');
      }

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

      _model.requestFields = fields;
      _model.populateFromRequestFields(fields);
      _model.isLoadingFields = false;
      _model.fieldsError = null;
      emit(UpdateUserInfoUI(_model));
    } catch (e) {
      if (kDebugMode) {
        print('❌ REQUEST FIELDS API ERROR (USER_INFO): $e');
      }
      _model.isLoadingFields = false;
      _model.fieldsError = e.toString().replaceAll('Exception: ', '');
      emit(UpdateUserInfoUI(_model));
    }
  }
}
