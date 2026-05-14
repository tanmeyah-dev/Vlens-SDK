import 'package:core/bases/base_state.dart';
import 'package:core/bases/states/base/base_state.dart';
import 'package:core/bases/states/base/render_data_state.dart';
import 'package:core/components/button/app_button.dart';
import 'package:core/components/text/app_text.dart';
import 'package:core/components/textField/app_textfield.dart';
import 'package:core/extensions/widget_extension.dart';
import 'package:core/utils/ui.dart';
import 'package:core/style/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../routes/route_path.dart';
import '../../validate_user/widgets/app_header.dart';
import '../bloc/register_screen_bloc.dart';
import 'package:core/utils/cache/verification_cache.dart';
import '../constants/security_code_constants.dart';
import '../event/register_screen_event.dart';
import '../model/register_screen_model.dart';
import '../state/register_screen_state.dart';
import '../utils/security_code_validator.dart';
import '../widgets/pin_input_field.dart';
import '../widgets/security_code_guidelines.dart';

class RegisterScreen extends StatefulWidget {
  final String? phoneNumberOtpRequestId;
  final String? transactionId;
  final String? mobileNumber;
  /// Email from email step (route argument); falls back to [VerificationCache].
  final String? verifiedEmail;

  const RegisterScreen({
    super.key,
    this.phoneNumberOtpRequestId,
    this.transactionId,
    this.mobileNumber,
    this.verifiedEmail,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState
    extends BaseState<RegisterScreen, RegisterScreenBloc, RegisterScreenModel> {
  late RegisterScreenModel _model;
  String? _cachedMobileNumber;
  String? _cachedEmail;
  String _fullEmailForRequest = '';
  bool _isCreateCodeVisible = false;
  bool _isConfirmCodeVisible = false;

  String _extractUsernamePrefix(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return '';
    final atIndex = raw.indexOf('@');
    if (atIndex <= 0) return raw;
    return raw.substring(0, atIndex).trim();
  }

  @override
  void initState() {
    super.initState();
    // Run after first frame so `buildWidget` has assigned `_model`.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCachedData());
  }

  Future<void> _loadCachedData() async {
    _cachedMobileNumber = await VerificationCache().getMobileNumber();
    _cachedEmail = await VerificationCache().getEmail();
    if (!mounted) return;
    final routeEmail = widget.verifiedEmail?.trim();
    final displayEmail = (routeEmail != null && routeEmail.isNotEmpty)
        ? routeEmail
        : (_cachedEmail ?? '');
    _fullEmailForRequest = displayEmail.trim();
    _model.usernameController.text = _extractUsernamePrefix(displayEmail);
    print('📥 Loaded from cache:');
    print('📥 mobileNumber: $_cachedMobileNumber');
    print('📥 email: $_cachedEmail');
    _checkAndEnableSaveButton();
  }

  @override
  Widget buildWidget(BuildContext context, RenderDataState<RegisterScreenModel> state) {
    _model = state.data;
    final routeEmail = widget.verifiedEmail?.trim();
    if (routeEmail != null && routeEmail.isNotEmpty) {
      _fullEmailForRequest = routeEmail;
      _model.usernameController.text = _extractUsernamePrefix(routeEmail);
    } else if (_fullEmailForRequest.isEmpty && (_cachedEmail?.trim().isNotEmpty == true)) {
      _fullEmailForRequest = _cachedEmail!.trim();
    }
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              header(),
              Expanded(
                child: Form(
                  key: _model.formKey,
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              40.height,
                              instructions(),
                              40.height,
                              userNameField(),
                              24.height,
                              createSecurityCodeField(),
                              24.height,
                              confirmSecurityCodeField(),
                              24.height,
                              securityCodeGuidelines(),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: saveButton(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget header() {
    return const AppHeader();
  }

  Widget instructions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppText(
          "إنشاء رمز الحماية",
          color: AppColors.primary,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ],
    );
  }

  Widget userNameField() {
    return AppTextField(
      labelText: "اسم المستخدم",
      hintText: "example@example.com",
      controller: _model.usernameController,
      keyboardType: TextInputType.emailAddress,
      enabled: true,
      readOnly: true,
      enableInteractiveSelection: false,
    );
  }

  Widget createSecurityCodeField() {
    return PinInputField(
      label: "انشاء رمز الحماية",
      controller: _model.createSecurityCodeController,
      focusNode: _model.createSecurityCodeFocusNode,
      obscureText: !_isCreateCodeVisible,
      endSuffix: Icon(
        _isCreateCodeVisible ? Icons.visibility_off : Icons.visibility,
        color: AppColors.gray,
      ),
      onSuffixTap: () {
        setState(() {
          _isCreateCodeVisible = !_isCreateCodeVisible;
        });
      },
      validator: (value) => SecurityCodeValidator.getValidationError(
        value ?? '',
        SecurityCodeConstants.pinLength,
      ),
      onChanged: () {
        setState(() {}); // Trigger rebuild to update guideline highlights
        _checkAndEnableSaveButton();
      },
      onCompleted: () {
        setState(() {}); // Trigger rebuild to update guideline highlights
        _checkAndEnableSaveButton();
      },
    );
  }

  Widget confirmSecurityCodeField() {
    return PinInputField(
      label: "تأكيد رمز الحماية",
      controller: _model.confirmSecurityCodeController,
      focusNode: _model.confirmSecurityCodeFocusNode,
      obscureText: !_isConfirmCodeVisible,
      endSuffix: Icon(
        _isConfirmCodeVisible ? Icons.visibility_off : Icons.visibility,
        color: AppColors.gray,
      ),
      onSuffixTap: () {
        setState(() {
          _isConfirmCodeVisible = !_isConfirmCodeVisible;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'تأكيد رمز الحماية مطلوب';
        }
        if (!SecurityCodeValidator.codesMatch(
          _model.createSecurityCodeController.text,
          value,
        )) {
          return 'رمز الحماية غير متطابق';
        }
        return null;
      },
      onChanged: () {
        setState(() {}); // Trigger rebuild to update guideline highlights
        _checkAndEnableSaveButton();
      },
      onCompleted: () {
        setState(() {}); // Trigger rebuild to update guideline highlights
        _checkAndEnableSaveButton();
      },
    );
  }

  Widget securityCodeGuidelines() {
    return SecurityCodeGuidelines(
      createCode: _model.createSecurityCodeController.text,
      confirmCode: _model.confirmSecurityCodeController.text,
      minLength: SecurityCodeConstants.pinLength,
    );
  }

  Widget saveButton() {
    return AppButton(
      title: "حفظ",
      textColor: _model.isSaveButtonDisabled ? AppColors.gray : AppColors.white,
      onPressed: _model.isSaveButtonDisabled ? null : () => validation(),
    );
  }

  RegisterScreenBloc createBloc() {
    return RegisterScreenBloc(RegisterScreenModel());
  }

  bool _isLoadingDialogShowing = false;
  bool _createUserLoadingActive = false;
  BuildContext? _loadingDialogContext;

  void _dismissCreateUserLoadingOverlay() {
    final dialogCtx = _loadingDialogContext;
    if (dialogCtx != null && dialogCtx.mounted) {
      Navigator.of(dialogCtx).pop();
    }
    _loadingDialogContext = null;
    _isLoadingDialogShowing = false;
  }

  @override
  void listenToState(BuildContext context, BaseStates state) {
    if (state is OnRegisterScreenLoadingState) {
      if (!_isLoadingDialogShowing) {
        _isLoadingDialogShowing = true;
        _createUserLoadingActive = true;
        print('⏳ Showing loading dialog...');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !context.mounted || !_createUserLoadingActive) {
            _isLoadingDialogShowing = false;
            return;
          }
          try {
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              barrierColor: Colors.black54,
              builder: (dialogContext) {
                _loadingDialogContext = dialogContext;
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
              _loadingDialogContext = null;
            });
            print('✅ Loading dialog shown successfully');
          } catch (e) {
            print('❌ Error showing loading dialog: $e');
            _isLoadingDialogShowing = false;
            _createUserLoadingActive = false;
          }
        });
      }
    } else if (state is OnRegisterScreenSavedState) {
      _createUserLoadingActive = false;
      _dismissCreateUserLoadingOverlay();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !context.mounted) return;
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return AlertDialog(
              content: const Text(
                'تهانينا لقد تم انشاء حساب',
                textAlign: TextAlign.center,
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    if (mounted && context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        RoutePath.loginScreen,
                        (route) => false,
                      );
                    }
                  },
                  child: const Text('حسناً'),
                ),
              ],
            );
          },
        );
      });
    } else if (state is OnRegisterScreenErrorState) {
      _createUserLoadingActive = false;
      _dismissCreateUserLoadingOverlay();
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _checkAndEnableSaveButton() {
    emit(EnableSaveButtonEvent(_model.isFormValid()));
  }

  Future<void> validation() async {
    if (_model.formKey.currentState!.validate()) {
      // Validate security code
      final code = _model.createSecurityCodeController.text;
      final validationError = SecurityCodeValidator.getValidationError(code, SecurityCodeConstants.pinLength);
      if (validationError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validationError),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
      
      if (!_model.doSecurityCodesMatch()) {
        // Show error for non-matching codes
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('رمز الحماية غير متطابق'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
      var mobileNumber = widget.mobileNumber ?? _cachedMobileNumber ?? '';
      if (mobileNumber.isEmpty) {
        mobileNumber = (await VerificationCache().getMobileNumber())?.trim() ?? '';
      }
      final email = _fullEmailForRequest.trim().isNotEmpty
          ? _fullEmailForRequest.trim()
          : (_cachedEmail ?? '').trim();

      print('📤 Using values for create-user API:');
      print('📤 email: $email');
      print('📤 mobileNumber: $mobileNumber');

      emit(RegisterScreenSaveEvent(
        email,
        _model.createSecurityCodeController.text,
        mobileNumber: mobileNumber,
      ));
    }
  }
}
