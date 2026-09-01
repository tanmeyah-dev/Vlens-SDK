import 'dart:convert';
import 'dart:io';
import 'package:core/bases/base_bloc.dart';
import 'package:core/bases/states/base/init_screen.dart';
import 'package:core/bases/states/general_state/general_render_state.dart';
import 'package:core/utils/network/http_headers_helper.dart';
import 'package:core/utils/cache/verification_cache.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../../../utils/api_exception_message.dart';
import '../../../utils/api_error_parser.dart';
import '../../../utils/sdk_http_client.dart';
import '../../validate_user/constants/api_urls.dart';
import '../constants/google_oauth_helper.dart';
import '../constants/google_oauth_config.dart';
import '../event/email_screen_event.dart';
import '../model/email_screen_model.dart';
import '../model/send_email_otp_response.dart';
import '../model/verify_oauth_token_response.dart';
import '../state/email_screen_state.dart';

class EmailScreenBloc extends BaseBloc {
  final EmailScreenModel _model;
  
  String get _apiUrlStepVerifyEmail => ApiUrls.getSendEmailOtpUrl();
  String get _apiUrlVerifyOAuthToken => ApiUrls.getVerifyOAuthTokenUrl();

  EmailScreenBloc(this._model)
      : super(initialState: InitScreen(_model)) {
    on<EnableSaveButtonEvent>(_onEnableSaveButtonEvent);
    on<SaveEmailEvent>(_onSaveEmailEvent);
    on<SignInWithGoogleEvent>(_onSignInWithGoogleEvent);
  }

  _onEnableSaveButtonEvent(EnableSaveButtonEvent event, emit) {
    _model.isSaveButtonDisabled = !event.isEnabled;
    emit(UpdateEmailScreenUI(_model));
  }

  _onSignInWithGoogleEvent(SignInWithGoogleEvent event, emit) async {
    if (_model.isLoading || _model.isGoogleLoading) return;

    _model.isGoogleLoading = true;
    _model.isLoading = true;
    emit(UpdateEmailScreenUI(_model));
    emit(OnEmailLoadingState());

    try {
      final idToken = await GoogleOAuthHelper.getIdToken();
      GoogleOAuthHelper.logIdTokenClaims(idToken);

      final requestBody = jsonEncode({
        'provider': 'Google',
        'IdToken': idToken,
      });

      print('');
      print('═══════════════════════════════════════════════════════');
      print('📤 VERIFY OAUTH TOKEN API REQUEST');
      print('═══════════════════════════════════════════════════════');
      print('URL: $_apiUrlVerifyOAuthToken');
      print('Method: POST');
      print('Body: {"provider":"Google","IdToken":"<redacted>"}');
      print('═══════════════════════════════════════════════════════');
      print('');

      final response = await SdkHttpClient.post(
        Uri.parse(_apiUrlVerifyOAuthToken),
        headers: HttpHeadersHelper.getDefaultHeaders(),
        body: requestBody,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - Server may not be running or not accessible');
        },
      );

      print('');
      print('═══════════════════════════════════════════════════════');
      print('📥 VERIFY OAUTH TOKEN API RESPONSE');
      print('═══════════════════════════════════════════════════════');
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');
      print('═══════════════════════════════════════════════════════');
      print('');

      if (response.statusCode != 200) {
        String errorMessage = 'فشل التحقق من حساب Google';
        final apiErrorMessage = ApiErrorParser.extractMessage(
          response.body,
          fallbackMessage: errorMessage,
        );
        if (apiErrorMessage.trim().isNotEmpty) {
          errorMessage = apiErrorMessage;
        }
        _model.isLoading = false;
        _model.isGoogleLoading = false;
        emit(UpdateEmailScreenUI(_model));
        emit(OnEmailErrorState(errorMessage));
        return;
      }

      if (response.body.isEmpty) {
        _model.isLoading = false;
        _model.isGoogleLoading = false;
        emit(UpdateEmailScreenUI(_model));
        emit(OnEmailErrorState('استجابة فارغة من الخادم'));
        return;
      }

      final decoded = jsonDecode(response.body);
      final parsed = VerifyOAuthTokenResponse.fromJson(
        decoded is Map<String, dynamic> ? decoded : <String, dynamic>{},
      );
      final apiErrorMessage = ApiErrorParser.extractMessage(
        response.body,
        fallbackMessage: 'فشل التحقق من حساب Google',
      );

      final oauthId = parsed.data?.oAuthTokenVerificationRequestId?.trim();
      final email = parsed.data?.email?.trim();
      final verified = parsed.data?.isVerified == true;

      if (!parsed.success || parsed.errorCode != null) {
        _model.isLoading = false;
        _model.isGoogleLoading = false;
        emit(UpdateEmailScreenUI(_model));
        emit(OnEmailErrorState(
          parsed.message?.trim().isNotEmpty == true
              ? parsed.message!.trim()
              : apiErrorMessage,
        ));
        return;
      }

      if (!verified || oauthId == null || oauthId.isEmpty) {
        _model.isLoading = false;
        _model.isGoogleLoading = false;
        emit(UpdateEmailScreenUI(_model));
        emit(OnEmailErrorState(
          parsed.message?.trim().isNotEmpty == true
              ? parsed.message!.trim()
              : (parsed.data?.validationResult ?? apiErrorMessage),
        ));
        return;
      }

      final resolvedEmail = (email != null && email.isNotEmpty) ? email : '';
      if (resolvedEmail.isNotEmpty) {
        _model.emailController.text = resolvedEmail;
      }

      await VerificationCache().setOAuthVerificationData(
        oAuthTokenVerificationRequestId: oauthId,
        email: resolvedEmail,
      );

      print('💾 Saved OAuth verification data:');
      print('💾 oAuthTokenVerificationRequestId: $oauthId');
      print('💾 email: $resolvedEmail');

      _model.isLoading = false;
      _model.isGoogleLoading = false;
      emit(UpdateEmailScreenUI(_model));
      emit(OnEmailConfirmedState(
        email: resolvedEmail,
        oauthTokenVerificationRequestId: oauthId,
      ));
    } on GoogleSignInException catch (e) {
      print('❌ GoogleSignInException: ${e.code.name} ${e.description}');
      _model.isLoading = false;
      _model.isGoogleLoading = false;
      emit(UpdateEmailScreenUI(_model));

      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        // User dismissed the Google sheet — dismiss loader, no error snackbar.
        emit(OnEmailLoadingDismissedState());
        return;
      }
      emit(OnEmailErrorState(_googleSignInUserMessage(e)));
    } catch (e) {
      print('❌ Google OAuth error: $e');
      _model.isLoading = false;
      _model.isGoogleLoading = false;
      emit(UpdateEmailScreenUI(_model));

      final msg = e.toString();
      if (_looksLikeMissingIosUrlScheme(msg)) {
        emit(OnEmailErrorState(_missingIosUrlSchemeMessage()));
      } else if (msg.contains('IdToken')) {
        emit(OnEmailErrorState(
          'تعذر الحصول على رمز Google. تأكد من إعداد Web Client ID.',
        ));
      } else if (msg.contains('SocketException') ||
          msg.contains('connection refused') ||
          msg.contains('Failed host lookup')) {
        emit(OnEmailErrorState(
          'لا يمكن الاتصال بالخادم.\n\nيرجى التحقق من الاتصال والمحاولة مرة أخرى',
        ));
      } else {
        emit(OnEmailErrorState(
          'حدث خطأ أثناء تسجيل الدخول بحساب Google',
        ));
      }
    }
  }

  /// Maps Google Sign-In failures to actionable Arabic messages.
  /// Release builds often fail with ApiException 10 (DEVELOPER_ERROR) when the
  /// release / Play App Signing SHA-1 is missing from the Android OAuth client.
  String _googleSignInUserMessage(GoogleSignInException e) {
    final raw = '${e.description ?? ''} ${e.code.name}'.toLowerCase();
    if (_looksLikeMissingIosUrlScheme(raw)) {
      return _missingIosUrlSchemeMessage();
    }

    final looksLikeDeveloperError = raw.contains('10:') ||
        raw.contains('api_exception: 10') ||
        raw.contains('developer_error') ||
        raw.contains('developer error') ||
        raw.contains('12500') ||
        e.code == GoogleSignInExceptionCode.clientConfigurationError ||
        e.code == GoogleSignInExceptionCode.providerConfigurationError;

    if (looksLikeDeveloperError) {
      return 'فشل Google Sign-In في نسخة الـ release.\n'
          'أضف SHA-1 لمفتاح التوقيع (release / Play App Signing) '
          'إلى عميل Android في Google Cloud Console ثم انتظر بضع دقائق.';
    }

    if (e.description?.trim().isNotEmpty == true) {
      return e.description!.trim();
    }
    return 'فشل تسجيل الدخول بحساب Google';
  }

  bool _looksLikeMissingIosUrlScheme(String raw) {
    final lower = raw.toLowerCase();
    return lower.contains('url schemes') ||
        lower.contains('url scheme') ||
        lower.contains('nsinvalidargumentexception') ||
        lower.contains(GoogleOAuthConfig.iosReversedClientId.toLowerCase());
  }

  String _missingIosUrlSchemeMessage() {
    return 'إعداد Google Sign-In على iOS غير مكتمل.\n'
        'أضف CFBundleURLTypes في ios/Runner/Info.plist:\n'
        '${GoogleOAuthConfig.iosReversedClientId}';
  }

  _onSaveEmailEvent(SaveEmailEvent event, emit) async {
    _model.isLoading = true;
    emit(UpdateEmailScreenUI(_model));
    emit(OnEmailLoadingState()); // Emit loading state to show dialog
    
    try {
      // Prepare request body
      final requestBody = jsonEncode({
        'email': event.email,
      });

      print('');
      print('═══════════════════════════════════════════════════════');
      print('📤 STEP VERIFY EMAIL API REQUEST');
      print('═══════════════════════════════════════════════════════');
      print('URL: $_apiUrlStepVerifyEmail');
      print('Method: POST');
      print('Headers: ${HttpHeadersHelper.getDefaultHeaders()}');
      print('Body: $requestBody');
      print('Email: ${event.email}');
      print('═══════════════════════════════════════════════════════');
      print('');


      // Make API call with better error handling
      http.Response response;
      try {
        response = await SdkHttpClient.post(
          Uri.parse(_apiUrlStepVerifyEmail),
          headers: HttpHeadersHelper.getDefaultHeaders(),
          body: requestBody,
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Request timeout - Server may not be running or not accessible');
          },
        );
      } on SocketException catch (e) {
        // Connection error
        print('');
        print('═══════════════════════════════════════════════════════');
        print('❌ CONNECTION ERROR - SocketException');
        print('═══════════════════════════════════════════════════════');
        print('Error: ${e.message}');
        print('Address: ${e.address}');
        print('Port: ${e.port}');
        print('URL Attempted: $_apiUrlStepVerifyEmail');
        print('═══════════════════════════════════════════════════════');
        print('');
        rethrow;
      } catch (e) {
        print('❌ Connection error: $e');
        print('❌ URL attempted: $_apiUrlStepVerifyEmail');
        rethrow;
      }

      print('');
      print('═══════════════════════════════════════════════════════');
      print('📥 STEP VERIFY EMAIL API RESPONSE');
      print('═══════════════════════════════════════════════════════');
      print('Status Code: ${response.statusCode}');
      print('Headers: ${response.headers}');
      print('Body: ${response.body}');
      print('═══════════════════════════════════════════════════════');
      print('');


      if (response.statusCode == 200) {
        // Success - parse response and show verification dialog
        print('✅ StepVerifyEmail API successful');
        
        try {
          // Parse response
          if (response.body.isEmpty) {
            print('⚠️ Response body is empty');
            _model.isLoading = false;
            emit(UpdateEmailScreenUI(_model));
            emit(OnEmailErrorState('استجابة فارغة من الخادم'));
            return;
          }
          
          final responseBody = jsonDecode(response.body);
          print('✅ JSON decoded successfully');
          print('📋 Response body: $responseBody');
          
          final sendEmailOtpResponse = SendEmailOtpResponse.fromJson(
            responseBody is Map<String, dynamic> 
                ? responseBody 
                : <String, dynamic>{},
          );
          
          print('✅ SendEmailOtpResponse model created successfully');
          
          print('');
          print('═══════════════════════════════════════════════════════');
          print('📊 SEND EMAIL OTP RESPONSE MODEL');
          print('═══════════════════════════════════════════════════════');
          print('Code: ${sendEmailOtpResponse.code ?? "N/A"}');
          print('Message: ${sendEmailOtpResponse.message ?? "N/A"}');
          print('Success: ${sendEmailOtpResponse.success}');
          print('emailConfirmed: ${sendEmailOtpResponse.data?.emailConfirmed}');
          print('EmailOtpRequestId: ${sendEmailOtpResponse.data?.emailOtpRequestId ?? "N/A"}');
          print('TransactionId: ${sendEmailOtpResponse.data?.transactionId ?? "N/A"}');
          print('═══════════════════════════════════════════════════════');
          print('');
          
          if (!sendEmailOtpResponse.success) {
            _model.isLoading = false;
            emit(UpdateEmailScreenUI(_model));
            emit(OnEmailErrorState(
                sendEmailOtpResponse.message ?? 'فشل في التحقق من الإيميل'));
            return;
          }

          // Always persist trimmed email for username / create-user screens.
          // Email OTP flow must send oauthTokenVerificationRequestId as null.
          final trimmedEmail = event.email.trim();
          await VerificationCache().setEmail(trimmedEmail);
          await VerificationCache().clearOAuthTokenVerificationRequestId();

          final isEmailConfirmed =
              sendEmailOtpResponse.data?.emailConfirmed ?? false;
          final emailOtpRequestId = sendEmailOtpResponse.data?.emailOtpRequestId;
          final transactionId = sendEmailOtpResponse.data?.transactionId;

          // Save IDs when present (some API versions may omit them).
          if (emailOtpRequestId != null &&
              emailOtpRequestId.isNotEmpty &&
              transactionId != null &&
              transactionId.isNotEmpty) {
            await VerificationCache().setEmailVerificationData(
              emailOtpRequestId: emailOtpRequestId,
              transactionId: transactionId,
              email: trimmedEmail,
            );
            
            print('💾 Saved email verification data to cache:');
            print('💾 emailOtpRequestId: $emailOtpRequestId');
            print('💾 transactionId: $transactionId');
            print('💾 email: $trimmedEmail');
          } else {
            print('ℹ️ send-otp response did not include emailOtpRequestId/transactionId');
          }
            
          // Emit state based on confirmation status.
          _model.isLoading = false;
          emit(UpdateEmailScreenUI(_model));

          if (isEmailConfirmed) {
            print('✅ Email already confirmed - navigating to username security screen');
            emit(OnEmailConfirmedState(
              email: trimmedEmail,
              oauthTokenVerificationRequestId: null,
            ));
          } else {
            print('✅ Email not confirmed - showing verification dialog');
            emit(OnEmailVerificationRequiredState(
              email: trimmedEmail,
              emailOtpRequestId: emailOtpRequestId,
              transactionId: transactionId,
            ));
          }
        } catch (e, stackTrace) {
          print('');
          print('═══════════════════════════════════════════════════════');
          print('❌ ERROR PARSING STEP VERIFY EMAIL RESPONSE');
          print('═══════════════════════════════════════════════════════');
          print('Error: $e');
          print('Error Type: ${e.runtimeType}');
          print('Stack Trace: $stackTrace');
          print('Response Body: ${response.body}');
          print('═══════════════════════════════════════════════════════');
          print('');
          
          
          _model.isLoading = false;
          emit(UpdateEmailScreenUI(_model));
          emit(OnEmailErrorState('فشل في معالجة الاستجابة من الخادم'));
        }
      } else {
        // Error response
        String errorMessage = 'فشل في التحقق من الإيميل';
        final apiErrorMessage = ApiErrorParser.extractMessage(
          response.body,
          fallbackMessage: errorMessage,
        );
        if (response.statusCode == 417 && apiErrorMessage.trim().isNotEmpty) {
          errorMessage = apiErrorMessage;
        }
        
        try {
          if (response.body.isNotEmpty) {
            final errorBody = jsonDecode(response.body);
            errorMessage = errorBody['message'] ?? 
                          errorBody['error'] ?? 
                          errorBody['errorMessage'] ??
                          errorBody['error_message'] ??
                          errorBody['data']?['message'] ??
                          errorBody['data']?['error'] ??
                          'فشل في التحقق من الإيميل';
            if (response.statusCode == 417 && apiErrorMessage.trim().isNotEmpty) {
              errorMessage = apiErrorMessage;
            }
          }
        } catch (e) {
          print('⚠️ Error parsing error response: $e');
          if (response.statusCode == 417 && apiErrorMessage.trim().isNotEmpty) {
            errorMessage = apiErrorMessage;
          }
        }

        print('❌ StepVerifyEmail API failed with status code: ${response.statusCode}');
        print('❌ Error message: $errorMessage');
        
        _model.isLoading = false;
        emit(UpdateEmailScreenUI(_model));
        emit(OnEmailErrorState(errorMessage));
      }
    } catch (e) {
      final userFriendlyMessage = apiExceptionMessage(
        e,
        fallback: 'حدث خطأ أثناء التحقق من الإيميل. يرجى المحاولة مرة أخرى',
      );

      print('❌ Error verifying email: $e');
      print('❌ User-friendly message: $userFriendlyMessage');
      _model.isLoading = false;
      emit(UpdateEmailScreenUI(_model));
      emit(OnEmailErrorState(userFriendlyMessage));
    }
  }

}
