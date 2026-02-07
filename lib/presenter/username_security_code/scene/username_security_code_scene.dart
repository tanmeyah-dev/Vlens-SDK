import 'package:core/bases/base_state.dart';
import 'package:core/bases/states/base/base_state.dart';
import 'package:core/bases/states/base/render_data_state.dart';
import 'package:core/components/button/app_button.dart';
import 'package:core/components/text/app_text.dart';
import 'package:core/extensions/widget_extension.dart';
import 'package:core/utils/ui.dart';
import 'package:core/style/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../routes/route_path.dart';
import '../../mobile_number/widgets/app_header.dart';
import '../../mobile_number/widgets/mobile_number_field.dart';
import '../bloc/username_security_code_bloc.dart';
import 'package:core/utils/cache/verification_cache.dart';
import '../constants/security_code_constants.dart';
import '../event/username_security_code_event.dart';
import '../model/username_security_code_model.dart';
import '../state/username_security_code_state.dart';
import '../utils/security_code_validator.dart';
import '../widgets/pin_input_field.dart';
import '../widgets/security_code_guidelines.dart';

class UsernameSecurityCodeScene extends StatefulWidget {
  final String? phoneNumberOtpRequestId;
  final String? transactionId;
  final String? mobileNumber;

  const UsernameSecurityCodeScene({
    super.key,
    this.phoneNumberOtpRequestId,
    this.transactionId,
    this.mobileNumber,
  });

  @override
  State<UsernameSecurityCodeScene> createState() => _UsernameSecurityCodeSceneState();
}

class _UsernameSecurityCodeSceneState
    extends BaseState<UsernameSecurityCodeScene, UsernameSecurityCodeBloc, UsernameSecurityCodeModel> {
  late UsernameSecurityCodeModel _model;
  String? _cachedPhoneNumberOtpRequestId;
  String? _cachedTransactionId;
  String? _cachedMobileNumber;

  @override
  void initState() {
    super.initState();
    _loadCachedData();
  }

  Future<void> _loadCachedData() async {
    _cachedPhoneNumberOtpRequestId = await VerificationCache().getPhoneNumberOtpRequestId();
    _cachedTransactionId = await VerificationCache().getTransactionId();
    _cachedMobileNumber = await VerificationCache().getMobileNumber();
    print('📥 Loaded from cache:');
    print('📥 phoneNumberOtpRequestId: $_cachedPhoneNumberOtpRequestId');
    print('📥 transactionId: $_cachedTransactionId');
    print('📥 mobileNumber: $_cachedMobileNumber');
  }

  @override
  Widget buildWidget(BuildContext context, RenderDataState<UsernameSecurityCodeModel> state) {
    _model = state.data;
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
                              mobileNumberFields(),
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
          "قم بادخال رقم الموبايل",
          color: AppColors.primary,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        4.height,
        AppText(
          "ورمز حماية",
          color: AppColors.primary,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ],
    );
  }

  Widget mobileNumberFields() {
    return MobileNumberField(
      controller: _model.usernameController,
      onChanged: (value) {
        _checkAndEnableSaveButton();
      },
    );
  }

  Widget createSecurityCodeField() {
    return PinInputField(
      label: "انشاء رمز الحماية",
      controller: _model.createSecurityCodeController,
      focusNode: _model.createSecurityCodeFocusNode,
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

  UsernameSecurityCodeBloc createBloc() {
    return UsernameSecurityCodeBloc(UsernameSecurityCodeModel());
  }

  bool _isLoadingDialogShowing = false;

  @override
  void listenToState(BuildContext context, BaseStates state) {
    if (state is OnUsernameSecurityCodeLoadingState) {
      // Show loading dialog immediately
      if (!_isLoadingDialogShowing) {
        _isLoadingDialogShowing = true;
        print('⏳ Showing loading dialog...');
        // Use post frame callback to ensure context is ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && context.mounted && _isLoadingDialogShowing) {
            try {
              showDialog(
                context: context,
                barrierDismissible: false,
                barrierColor: Colors.black54,
                builder: (dialogContext) => const Dialog(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
              print('✅ Loading dialog shown successfully');
            } catch (e) {
              print('❌ Error showing loading dialog: $e');
              _isLoadingDialogShowing = false;
            }
          } else {
            print('⚠️ Cannot show dialog - context not mounted');
            _isLoadingDialogShowing = false;
          }
        });
      } else {
        print('⚠️ Loading dialog already showing');
      }
    } else if (state is OnUsernameSecurityCodeSavedState) {
      // Hide loading dialog if showing
      if (_isLoadingDialogShowing) {
        _isLoadingDialogShowing = false;
        Navigator.of(context).pop(); // Close loading dialog
      }
      // Navigate to login screen
      Navigator.of(context).pushNamed(RoutePath.loginScreen);
    } else if (state is OnUsernameSecurityCodeErrorState) {
      // Hide loading dialog if showing
      if (_isLoadingDialogShowing) {
        _isLoadingDialogShowing = false;
        Navigator.of(context).pop(); // Close loading dialog
      }
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
      // Use cached values if widget values are not available
      final phoneNumberOtpRequestId = widget.phoneNumberOtpRequestId ?? 
          _cachedPhoneNumberOtpRequestId ?? '';
      final transactionId = widget.transactionId ?? 
          _cachedTransactionId ?? '';
      final mobileNumber = widget.mobileNumber ?? 
          _cachedMobileNumber ?? '';
      
      print('📤 Using values for create-user API:');
      print('📤 phoneNumberOtpRequestId: $phoneNumberOtpRequestId');
      print('📤 transactionId: $transactionId');
      print('📤 mobileNumber: $mobileNumber');
      
      emit(SaveUsernameSecurityCodeEvent(
        _model.usernameController.text,
        _model.createSecurityCodeController.text,
        phoneNumberOtpRequestId: phoneNumberOtpRequestId,
        transactionId: transactionId,
        mobileNumber: mobileNumber,
      ));
    }
  }
}
