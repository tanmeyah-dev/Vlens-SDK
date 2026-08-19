import 'dart:async';
import 'dart:convert';

import 'package:core/bases/base_state.dart';
import 'package:core/bases/states/base/base_state.dart';
import 'package:core/bases/states/base/render_data_state.dart';
import 'package:core/components/button/app_button.dart';
import 'package:core/components/image/app_image.dart';
import 'package:core/components/text/app_text.dart';
import 'package:core/components/textField/app_textfield.dart';
import 'package:core/extensions/widget_extension.dart';
import 'package:core/utils/ui.dart';
import 'package:core/style/app_colors.dart';
import 'package:core/utils/cache/verification_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tan_sdk/data/models/extracted_user_data.dart';
import 'package:tan_sdk/utils/extracted_data_log.dart';
import '../../home/scene/home_scene.dart';
import '../../id_data/scene/id_data_screen.dart';
import '../../id_data/utils/request_eligibility_helper.dart';
import '../model/login_response.dart';
import '../bloc/login_screen_bloc.dart';
import '../event/login_screen_event.dart';
import '../model/login_screen_model.dart';
import '../state/login_screen_state.dart';
import '../utils/phone_validator.dart';
import '../utils/verify_user_otp_dialog_helper.dart';
import '../utils/vlens_sdk_launcher.dart';
import '../../register_screen/widgets/pin_input_field.dart';
import '../model/login_screen_nav_args.dart';
import '../utils/request_documents_navigator.dart';

class LoginScreenScene extends StatefulWidget {
  final String? initialPhoneNumber;
  final String? vlenseStatus;

  const LoginScreenScene({
    super.key,
    this.initialPhoneNumber,
    this.vlenseStatus,
  });

  @override
  State<LoginScreenScene> createState() => _LoginScreenSceneState();
}

class _LoginScreenSceneState
    extends BaseState<LoginScreenScene, LoginScreenBloc, LoginScreenModel> {
  late LoginScreenModel _model;
  bool _listenersAdded = false;
  bool _isPhonePrefilledFromRoute = false;
  bool _isPasswordVisible = false;
  bool _isLoadingDialogShowing = false;
  bool _loginLoadingActive = false;
  bool _isOpeningVlens = false;
  BuildContext? _loginLoadingDialogContext;

  void _dismissLoginLoadingOverlay() {
    final dialogCtx = _loginLoadingDialogContext;
    if (dialogCtx != null && dialogCtx.mounted) {
      Navigator.of(dialogCtx).pop();
    }
    _loginLoadingDialogContext = null;
    _isLoadingDialogShowing = false;
  }

  @override
  void dispose() {
    if (_listenersAdded) {
      _model.mobileNumberController.removeListener(_updateButtonState);
      _model.passwordController.removeListener(_updateButtonState);
    }
    super.dispose();
  }

  @override
  Widget buildWidget(
      BuildContext context, RenderDataState<LoginScreenModel> state) {
    _model = state.data;
    _prefillPhoneNumberFromRoute(context);

    // Add listeners only once to prevent excessive state updates
    if (!_listenersAdded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_listenersAdded) {
          _model.mobileNumberController.addListener(_updateButtonState);
          _model.passwordController.addListener(_updateButtonState);
          _listenersAdded = true;
          // Initial button state check
          _updateButtonState();
        }
      });
    }
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Stack(
            children: [
              // Content
              Form(
                key: _model.formKey,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            160.height,
                            // Logo
                            _buildLogo(),
                            120.height,
                            // Title
                            _buildTitle(),
                            100.height,
                            // Mobile number field
                            _buildMobileNumberField(),
                            24.height,
                            // Password field (PIN)
                            _buildPasswordField(),
                          ],
                        ),
                      ),
                    ),
                    // Login button at bottom
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildLoginSection(),
                    ),
                  ],
                ),
              ),
              if (_isOpeningVlens)
                const Positioned.fill(
                  child: AbsorbPointer(
                    child: ColoredBox(
                      color: Color(0x66000000),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _prefillPhoneNumberFromRoute(BuildContext context) {
    if (_isPhonePrefilledFromRoute) {
      return;
    }

    String? phoneNumber = widget.initialPhoneNumber?.trim();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is LoginScreenNavArgs) {
      final fromArgs = args.phoneNumber?.trim();
      if (fromArgs != null && fromArgs.isNotEmpty) {
        phoneNumber = fromArgs;
      }
    } else if (args is String) {
      final fromArgs = args.trim();
      if (fromArgs.isNotEmpty) {
        phoneNumber = fromArgs;
      }
    }

    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      _model.mobileNumberController.text = phoneNumber;
    }

    _isPhonePrefilledFromRoute = true;
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: CustomPaint(
        painter: WavyBackgroundPainter(),
        child: Container(),
      ),
    );
  }

  Widget _buildSkipButton() {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () {
            // TODO: Handle skip action
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const HomeScene()));
          },
          child: AppText(
            "تخطي",
            color: AppColors.gray,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return const AppImage(
      AppAssets.tanmeyah,
      height: 80,
    );
  }

  Widget _buildTitle() {
    return AppText(
      "تسجيل الدخول",
      color: AppColors.secondary,
      fontSize: 24,
      fontWeight: FontWeight.w600,
    );
  }

  Widget _buildMobileNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          "رقم الموبايل",
          color: AppColors.secondary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        8.height,
        AppTextField(
          hintText: "01xxxxxxxxx",
          controller: _model.mobileNumberController,
          keyboardType: TextInputType.phone,
          maxLength: 11,
          textAlign: TextAlign.right,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: (_) {
            // Clear server-side error when user starts typing
            if (_model.phoneNumberError != null) {
              _model.phoneNumberError = null;
              emit(UpdateLoginScreenUIEvent(_model));
              // Re-validate to clear the error display
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _model.formKey.currentState?.validate();
              });
            }
            _updateButtonState();
          },
          validator: (value) {
            // Show server-side error if set (from login failure)
            if (_model.phoneNumberError != null) {
              return _model.phoneNumberError;
            }
            // Otherwise use client-side validation
            return PhoneValidator.validatePhone(context, value);
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return PinInputField(
      label: "كلمة المرور",
      controller: _model.passwordController,
      focusNode: _model.passwordFocusNode,
      obscureText: !_isPasswordVisible,
      startSuffix: Icon(
        _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
        color: AppColors.gray,
      ),
      onSuffixTap: () {
        setState(() {
          _isPasswordVisible = !_isPasswordVisible;
        });
      },
      keyboardType: TextInputType.visiblePassword,
      textAlign: TextAlign.right,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "كلمة المرور مطلوبة";
        }
        return null;
      },
      onChanged: _updateButtonState,
    );
  }

  void _updateButtonState() {
    if (mounted) {
      emit(EnableLoginButtonEvent(_model.areFieldsValid()));
    }
  }


  Widget _buildLoginSection() {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            title: "تسجيل الدخول",
            textColor:
                (_model.isLoginButtonDisabled || _model.awaitingOtpVerification)
                    ? AppColors.gray
                    : AppColors.white,
            onPressed: (_model.isLoginButtonDisabled ||
                    _model.awaitingOtpVerification)
                ? null
                : () => _validation(),
          ),
        ),
        if (_model.isBiometricAvailable) ...[
          8.width,
          _buildBiometricButton(),
        ],
      ],
    );
  }

  Widget _buildBiometricButton() {
    return GestureDetector(
      onTap: () {
        // TODO: Handle biometric login
      },
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppColors.primary,
        ),
        child: const Padding(
          padding: EdgeInsets.all(12.0),
          child: AppImage(
            AppAssets.fingerPrintWhite,
            height: 40,
            width: 40,
          ),
        ),
      ),
    );
  }

  Widget _buildCreateAccountLink() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppText(
            "ليس لديك حساب؟ ",
            color: AppColors.gray,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          GestureDetector(
            onTap: () {
              // TODO: Handle create account
            },
            child: AppText(
              "إنشاء حساب جديد",
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  LoginScreenBloc createBloc() {
    return LoginScreenBloc(LoginScreenModel());
  }

  @override
  void listenToState(BuildContext context, BaseStates state) {
    if (state is OnLoginLoadingState) {
      if (!_isLoadingDialogShowing) {
        _isLoadingDialogShowing = true;
        _loginLoadingActive = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !context.mounted || !_loginLoadingActive) {
            _isLoadingDialogShowing = false;
            return;
          }
          try {
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              barrierColor: Colors.black54,
              builder: (dialogContext) {
                _loginLoadingDialogContext = dialogContext;
                return const Dialog(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                );
              },
            ).whenComplete(() {
              _loginLoadingDialogContext = null;
            });
          } catch (e) {
            _isLoadingDialogShowing = false;
            _loginLoadingActive = false;
          }
        });
      }
    } else if (state is OnLoginSuccessState) {
      _loginLoadingActive = false;
      final loginResponseData = state.loginResponse.data;
      if (loginResponseData == null || !mounted || !context.mounted) {
        _dismissLoginLoadingOverlay();
        return;
      }

      final needsPhoneOtp =
          loginResponseData.isPhoneNumberConfirmationRequired == true &&
              loginResponseData.isPhoneNumberConfirmed != true;
      final hasUsableToken =
          (loginResponseData.accessToken?.trim().isNotEmpty == true) ||
              (loginResponseData.encryptedAccessToken?.trim().isNotEmpty ==
                  true);
      final openVlensDirectly = !needsPhoneOtp &&
          loginResponseData.isDigitalIdentityVerified != true;

      // Keep loading visible while switching into VLens to avoid a blank gap.
      if (!openVlensDirectly) {
        _dismissLoginLoadingOverlay();
      } else if (mounted) {
        setState(() => _isOpeningVlens = true);
      }

      // Run after this frame so the loading route is fully popped before VLens uses Navigator.
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || !context.mounted) return;

        if (needsPhoneOtp) {
          final phoneNumber = _model.mobileNumberController.text;
          final password = _model.passwordController.text;
          final otpReqId = loginResponseData.phoneNumberOtpRequestId;
          final txId = loginResponseData.transactionId;
          if (otpReqId != null &&
              otpReqId.isNotEmpty &&
              txId != null &&
              txId.isNotEmpty) {
            unawaited(VerificationCache().setVerificationData(
              phoneNumberOtpRequestId: otpReqId,
              transactionId: txId,
              mobileNumber: phoneNumber,
            ));
          }
          VerifyUserOTPDialogHelper.showVerifyUserOTPDialog(
            context,
            phoneNumber: phoneNumber,
            password: password,
            maskedPhoneNumber: loginResponseData.maskedPhoneNumber,
            phoneNumberOtpRequestId: otpReqId,
            transactionId: txId,
            vlenseStatus: widget.vlenseStatus,
          ).then((_) {
            if (!mounted) return;
            _model.awaitingOtpVerification = false;
            emit(UpdateLoginScreenUIEvent(_model));
          });
        } else {
          await VerificationCache().setLoginSession(
            accessToken: loginResponseData.accessToken,
            refreshToken: loginResponseData.refreshToken,
            encryptedAccessToken: loginResponseData.encryptedAccessToken,
            transactionId: loginResponseData.transactionId,
            userName: loginResponseData.userName,
            userFullName: loginResponseData.userFullName,
            nationalId: loginResponseData.nationalId,
          );
          final resolvedMobileNumber =
              (loginResponseData.userName ?? '').trim().isNotEmpty
                  ? loginResponseData.userName!.trim()
                  : _model.mobileNumberController.text.trim();
          unawaited(VerificationCache().setMobileNumber(resolvedMobileNumber));
          unawaited(_cacheLoginResponseData(loginResponseData));
          if (!hasUsableToken) {
            print(
                '⚠️ Login success without usable token, but OTP is not required by backend.');
          }

          if (!mounted || !context.mounted) return;

          if (RequestDocumentsNavigator.isStatus200(widget.vlenseStatus)) {
            _dismissLoginLoadingOverlay();
            if (mounted) setState(() => _isOpeningVlens = true);
            unawaited(_openRequestDocumentsAfterLogin(context));
            return;
          }

          if (loginResponseData.isDigitalIdentityVerified == true) {
            _dismissLoginLoadingOverlay();
            if (mounted) setState(() => _isOpeningVlens = true);
            unawaited(_openUserInfoForVerifiedIdentity(context));
            return;
          }

          _dismissLoginLoadingOverlay();
          _initializeVLensSDK(context, loginResponseData);
        }
      });
    } else if (state is OnLoginErrorState) {
      _loginLoadingActive = false;
      _dismissLoginLoadingOverlay();
      // Clear previous errors
      _model.phoneNumberError = null;
      _model.passwordError = null;
      // Set error message from API response
      _model.phoneNumberError = state.errorMessage;
      emit(UpdateLoginScreenUIEvent(_model));
      // Show snackbar with error message from API response
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.errorMessage),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      // Use a post-frame callback to ensure UI is updated before validation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_model.formKey.currentState != null && mounted) {
          _model.formKey.currentState!.validate();
        }
      });
    }
  }

  Future<void> _validation() async {
    if (_model.awaitingOtpVerification) {
      return;
    }

    // Clear previous server-side errors only (client-side validation errors will show automatically)
    _model.phoneNumberError = null;
    _model.passwordError = null;
    emit(UpdateLoginScreenUIEvent(_model));

    // Validate form - if validation fails, Flutter automatically shows errors on TextFormField
    // We need to wait for the UI to update before validating
    await Future.microtask(() {});

    final isValid = _model.formKey.currentState!.validate();

    if (!isValid) {
      // Validation failed - errors are automatically displayed by TextFormField
      // The form will show red borders and error messages below the fields
      return;
    }

    // Only proceed with login if form validation passes
    emit(LoginEvent(
      _model.mobileNumberController.text,
      _model.passwordController.text,
    ));
  }

  void _initializeVLensSDK(
      BuildContext context, LoginResponseData loginResponseData) {
    final launched = VlensSdkLauncher.launch(
      context: context,
      loginResponseData: loginResponseData,
      onSuccess: (data) {
        if (!mounted || !context.mounted) return;
        if (_isOpeningVlens) setState(() => _isOpeningVlens = false);
        final userData = ExtractedUserData.fromExtractedData(data);
        logExtractedDataAfterLogin(userData, context: 'after login');
        // Cache in background — navigate immediately.
        unawaited(_cacheVlensSuccessPayload(userData));
        Navigator.of(context, rootNavigator: true).pushReplacement(
          MaterialPageRoute(
            builder: (_) => IdDataScreen(extractedData: userData),
          ),
        );
      },
      onFailure: (errorCode, errorMsg) {
        if (_isOpeningVlens && mounted) {
          setState(() => _isOpeningVlens = false);
        }
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في التحقق: $errorMsg'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
    );

    if (!launched) {
      if (_isOpeningVlens && mounted) {
        setState(() => _isOpeningVlens = false);
      }
      final message = VlensSdkLauncher.missingMessage(loginResponseData);
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    // SDK route is pushed; drop our overlay on next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isOpeningVlens) {
        setState(() => _isOpeningVlens = false);
      }
    });
  }

  Future<void> _cacheVlensExtractedData(dynamic extractedData) async {
    try {
      final normalized = jsonDecode(jsonEncode(extractedData));
      await VerificationCache().setVlensExtractedData(normalized);
    } catch (_) {
      // Best effort cache only.
    }
  }

  Future<void> _cacheVlensSuccessPayload(dynamic extractedData) async {
    await _cacheVlensExtractedData(extractedData);
    try {
      final normalized = jsonDecode(jsonEncode(extractedData));
      await VerificationCache().setVlensTraceResponseBody(normalized);
    } catch (_) {
      print("eeeeeeeeee");
      // Best effort cache only.
    }
  }

  Future<void> _cacheLoginResponseData(dynamic loginResponseData) async {
    try {
      final normalized = jsonDecode(jsonEncode(loginResponseData));
      await VerificationCache().setLoginResponseData(normalized);
    } catch (e) {
      print('⚠️ Failed to cache login response data (login_screen): $e');
    }
  }

  Future<void> _openRequestDocumentsAfterLogin(BuildContext context) async {
    try {
      await RequestDocumentsNavigator.openAfterLogin(context);
    } finally {
      if (mounted && _isOpeningVlens) {
        setState(() => _isOpeningVlens = false);
      }
    }
  }

  Future<void> _openUserInfoForVerifiedIdentity(BuildContext context) async {
    final cachedData = await VerificationCache().getVlensExtractedData();
    if (cachedData != null) {
      logExtractedDataAfterLogin(
        cachedData,
        context: 'after login (cached VLENS)',
      );
    }
    if (!mounted || !context.mounted) return;
    try {
      await RequestEligibilityHelper.openUserInfoScreen(context);
    } catch (e) {
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted && _isOpeningVlens) {
        setState(() => _isOpeningVlens = false);
      }
    }
  }

}

// Custom painter for wavy background
class WavyBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFE5CC) // Light orange
      ..style = PaintingStyle.fill;

    // First wavy line (top left to center right)
    final path1 = Path();
    path1.moveTo(0, size.height * 0.1);
    path1.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.15,
      size.width * 0.6,
      size.height * 0.2,
    );
    path1.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.25,
      size.width,
      size.height * 0.3,
    );
    path1.lineTo(size.width, 0);
    path1.lineTo(0, 0);
    path1.close();

    // Second wavy shape (right side, larger)
    final path2 = Path();
    path2.moveTo(size.width * 0.5, size.height * 0.4);
    path2.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.5,
      size.width,
      size.height * 0.6,
    );
    path2.lineTo(size.width, size.height);
    path2.lineTo(size.width * 0.5, size.height);
    path2.close();

    // Third wavy line (bottom)
    final path3 = Path();
    path3.moveTo(0, size.height * 0.8);
    path3.quadraticBezierTo(
      size.width * 0.2,
      size.height * 0.75,
      size.width * 0.5,
      size.height * 0.8,
    );
    path3.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.85,
      size.width,
      size.height * 0.9,
    );
    path3.lineTo(size.width, size.height);
    path3.lineTo(0, size.height);
    path3.close();

    // Draw with different colors
    paint.color = const Color(0xFFFFE5CC); // Light orange
    canvas.drawPath(path1, paint);

    paint.color = const Color(0xFFFFE5E5); // Light pink
    canvas.drawPath(path2, paint);

    paint.color = const Color(0xFFFFE5CC); // Light orange
    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
