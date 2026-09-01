import 'package:core/bases/base_bloc.dart';
import 'package:core/bases/states/base/init_screen.dart';
import 'dart:io';
import 'package:core/utils/network/http_headers_helper.dart';
import 'package:http/http.dart' as http;
import '../../../utils/sdk_api_response.dart';
import '../../../utils/sdk_http_client.dart';
import '../event/home_event.dart';
import '../model/home_model.dart';
import '../model/request_types_response.dart';
import '../state/home_state.dart';
import '../../validate_user/constants/api_urls.dart';

class HomeBloc extends BaseBloc {
  final HomeModel _model;
  String get _apiUrlRequestTypes => ApiUrls.getRequestTypesUrl();

  HomeBloc(this._model)
      : super(initialState: InitHomeScreen(_model)) {
    on<UpdateHomeUIEvent>(_onUpdateHomeUIEvent);
    on<FetchRequestTypesEvent>(_onFetchRequestTypesEvent);
    add(FetchRequestTypesEvent());
  }

  _onUpdateHomeUIEvent(UpdateHomeUIEvent event, emit) {
    emit(InitHomeScreen(_model));
  }

  Future<void> _onFetchRequestTypesEvent(
      FetchRequestTypesEvent event, emit) async {
    _model.isLoading = true;
    _model.errorMessage = null;
    emit(InitHomeScreen(_model));

    try {
      final http.Response response = await SdkHttpClient.get(
        Uri.parse(_apiUrlRequestTypes),
        headers: HttpHeadersHelper.getDefaultHeaders(),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      final api = SdkApiResponse.from(response);
      final blockingError = api.blockingError(
        httpFallback: 'فشل في تحميل انواع الطلبات',
        businessFallback: 'فشل في تحميل انواع الطلبات',
      );
      if (blockingError != null) {
        _model.isLoading = false;
        _model.errorMessage = blockingError;
        emit(InitHomeScreen(_model));
        return;
      }

      if (response.body.isEmpty) {
        _model.isLoading = false;
        _model.errorMessage = 'استجابة فارغة من الخادم';
        emit(InitHomeScreen(_model));
        return;
      }

      final decoded = api.decoded;
      if (decoded == null) {
        _model.isLoading = false;
        _model.errorMessage = 'استجابة غير صالحة من الخادم';
        emit(InitHomeScreen(_model));
        return;
      }

      final parsed = RequestTypesResponse.fromJson(decoded);
      _model.requestTypes = parsed.data;
      _model.isLoading = false;
      _model.errorMessage = null;
      emit(InitHomeScreen(_model));
    } on SocketException {
      _model.isLoading = false;
      _model.errorMessage = 'لا يمكن الاتصال بالخادم';
      emit(InitHomeScreen(_model));
    } catch (_) {
      _model.isLoading = false;
      _model.errorMessage = 'حدث خطأ أثناء تحميل انواع الطلبات';
      emit(InitHomeScreen(_model));
    }
  }
}
