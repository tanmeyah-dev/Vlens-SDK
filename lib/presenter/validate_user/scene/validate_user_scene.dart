import 'dart:async';

import 'package:core/bases/base_state.dart';
import 'package:core/bases/states/base/base_state.dart';
import 'package:core/bases/states/base/render_data_state.dart';
import 'package:core/components/button/app_button.dart';
import 'package:core/components/text/app_text.dart';
import 'package:core/extensions/widget_extension.dart';
import 'package:core/utils/ui.dart';
import 'package:core/style/app_colors.dart';
import 'package:flutter/material.dart';
import '../bloc/validate_user_bloc.dart';
import '../constants/validate_user_constants.dart';
import '../event/validate_user_event.dart';
import '../model/validate_user_model.dart';
import '../state/validate_user_state.dart';
import '../utils/verification_dialog_helper.dart';
import '../widgets/app_header.dart';
import '../widgets/validate_user_phone_field.dart';
import '../../../routes/route_path.dart';
import '../../../utils/sdk_navigator.dart';
import 'package:core/utils/cache/verification_cache.dart';

class ValidateUser extends StatefulWidget {
  /// Prefills the mobile field when opened from a host app after login.
  final String? initialPhoneNumber;

  const ValidateUser({super.key, this.initialPhoneNumber});

  @override
  State<ValidateUser> createState() => _ValidateUserState();
}

class _ValidateUserState
    extends BaseState<ValidateUser, ValidateUserBloc, ValidateUserModel> {
  late ValidateUserModel _mobileNumberModel;
  bool _didPrefillPhone = false;

  @override
  Widget buildWidget(
      BuildContext context, RenderDataState<ValidateUserModel> state) {
    _mobileNumberModel = state.data;
    _prefillPhoneNumberIfNeeded();

    // Calculate responsive padding based on screen width
    final horizontalPadding = screenWidth > 600
        ? screenWidth * 0.1 // 10% padding on tablets/desktop
        : 16.0; // Fixed 16px on mobile

    final verticalSpacing = screenHeight > 800
        ? 40 // More spacing on larger screens
        : (screenHeight * 0.05)
            .round(); // 5% of screen height on smaller screens

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        SdkNavigator.returnToHostApp(context);
      },
      child: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Center content on larger screens, full width on mobile
              final maxContentWidth = screenWidth > 600 ? 500.0 : screenWidth;

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: Column(
                    children: [
                      header(),
                      Expanded(
                        child: Form(
                          key: _mobileNumberModel.formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: horizontalPadding,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      verticalSpacing.height,
                                      instructions(),
                                      verticalSpacing.height,
                                      mobileNumberFields(),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(
                                  screenWidth > 600 ? 24 : 16,
                                ),
                                child: saveButton(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ),
    );
  }

  Widget header() {
    return AppHeader(
      showBackButton: true,
      onBackPressed: () => SdkNavigator.returnToHostApp(context),
    );
  }

  Widget instructions() {
    // Responsive font size based on screen width
    final fontSize = screenWidth > 600 ? 20.0 : 18.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppText(
          ValidateUserConstants.instructionsLine1,
          color: AppColors.primary,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          textAlign: TextAlign.center,
        ),
        4.height,
        AppText(
          ValidateUserConstants.instructionsLine2,
          color: AppColors.primary,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  bool get _isPhoneFromHostApp {
    final phone = widget.initialPhoneNumber?.trim();
    return phone != null && phone.isNotEmpty;
  }

  Widget mobileNumberFields() {
    return ValidateUserPhoneField(
      controller: _mobileNumberModel.mobileNumberController,
      readOnly: _isPhoneFromHostApp,
      onChanged: (value) {
        emit(EnableSaveButtonEvent(!_mobileNumberModel.isInputEmpty()));
      },
    );
  }

  Widget saveButton() {
    // Responsive button sizing
    final buttonHeight = screenWidth > 600 ? 72.0 : 64.0;
    final fontSize = screenWidth > 600 ? 18.0 : 16.0;

    // Only disable while a save request is in progress
    final isButtonDisabled = _mobileNumberModel.isLoading;

    return AppButton(
      title: ValidateUserConstants.saveButtonText,
      textColor: isButtonDisabled
          ? AppColors.gray
          : AppColors.white,
      height: buttonHeight,
      fontSize: fontSize,
      onPressed: isButtonDisabled ? null : () => validation(),
    );
  }

  ValidateUserBloc createBloc() {
    return ValidateUserBloc(ValidateUserModel());
  }

  void _prefillPhoneNumberIfNeeded() {
    if (_didPrefillPhone) return;
    _didPrefillPhone = true;

    final phone = widget.initialPhoneNumber?.trim();
    if (phone == null || phone.isEmpty) return;

    _mobileNumberModel.mobileNumberController.text = phone;
    _mobileNumberModel.isSaveButtonDisabled = false;
    unawaited(VerificationCache().setMobileNumber(phone));
  }

  bool _isLoadingDialogShowing = false;
  bool _isLoadingDialogMounted = false;

  @override
  void listenToState(BuildContext context, BaseStates state) {
    if (state is OnValidateUserLoadingState) {
      // Show loading dialog immediately
      if (!_isLoadingDialogShowing) {
        _isLoadingDialogShowing = true;
        print('⏳ Showing loading dialog...');
        // Use post frame callback to ensure context is ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && context.mounted && _isLoadingDialogShowing) {
            try {
              _isLoadingDialogMounted = true;
              showDialog(
                context: context,
                useRootNavigator: false,
                barrierDismissible: false,
                barrierColor: Colors.black54,
                builder: (dialogContext) => const Dialog(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ),
              ).then((_) {
                _isLoadingDialogMounted = false;
              });
              print('✅ Loading dialog shown successfully');
            } catch (e) {
              print('❌ Error showing loading dialog: $e');
              _isLoadingDialogShowing = false;
              _isLoadingDialogMounted = false;
            }
          } else {
            print('⚠️ Cannot show dialog - context not mounted');
            _isLoadingDialogShowing = false;
            _isLoadingDialogMounted = false;
          }
        });
      } else {
        print('⚠️ Loading dialog already showing');
      }
    } else if (state is OnPhoneNumberExistsState) {
      // Reset loading state
      emit(UpdateLoadingStateEvent(false));
      
      // Hide loading dialog if showing
      if (_isLoadingDialogShowing && _isLoadingDialogMounted) {
        _isLoadingDialogShowing = false;
        _isLoadingDialogMounted = false;
        Navigator.of(context, rootNavigator: false).pop(); // Close loading dialog
      }
      // Phone number exists - navigate to login screen
      print('📱 OnPhoneNumberExistsState received - Navigating to login screen');
      final mobileNumber = _mobileNumberModel.mobileNumberController.text.trim();
      Navigator.of(context).pushNamed(
        RoutePath.loginScreen,
        arguments: mobileNumber,
      );
    } else if (state is OnValidateUserSavedState) {
      // Reset loading state
      emit(UpdateLoadingStateEvent(false));
      
      // Hide loading dialog if showing
      if (_isLoadingDialogShowing && _isLoadingDialogMounted) {
        _isLoadingDialogShowing = false;
        _isLoadingDialogMounted = false;
        Navigator.of(context, rootNavigator: false).pop(); // Close loading dialog
      }
      // Always cache the typed mobile number so register/create-user can read it
      // even when the API omits OTP ids on some platforms.
      final mobileNumber = _mobileNumberModel.mobileNumberController.text.trim();
      if (mobileNumber.isNotEmpty) {
        unawaited(VerificationCache().setMobileNumber(mobileNumber));
        print('💾 Saved to cache - mobileNumber: $mobileNumber');
      }
      // Save phoneNumberOtpRequestId when present (required for StepCreate / OAuth).
      if (state.phoneNumberOtpRequestId != null &&
          state.phoneNumberOtpRequestId!.trim().isNotEmpty) {
        final otpId = state.phoneNumberOtpRequestId!.trim();
        final txId = (state.transactionId != null &&
                state.transactionId!.trim().isNotEmpty)
            ? state.transactionId!.trim()
            : otpId;
        unawaited(VerificationCache().setVerificationData(
          phoneNumberOtpRequestId: otpId,
          transactionId: txId,
          mobileNumber: mobileNumber,
        ));
        print('💾 Saved to cache - phoneNumberOtpRequestId: $otpId');
        print('💾 Saved to cache - transactionId: $txId');
      }
      // Show verification dialog on success (phoneNumberExists == false)
      print(
          '📱 OnValidateUserSavedState received - Showing verification dialog');
      showVerificationDialog(
        phoneNumberOtpRequestId: state.phoneNumberOtpRequestId,
        transactionId: state.transactionId,
      );
    } else if (state is OnValidateUserErrorState) {
      // Reset loading state
      emit(UpdateLoadingStateEvent(false));
      
      // Hide loading dialog if showing
      if (_isLoadingDialogShowing && _isLoadingDialogMounted) {
        _isLoadingDialogShowing = false;
        _isLoadingDialogMounted = false;
        Navigator.of(context, rootNavigator: false).pop(); // Close loading dialog
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

  bool _isValidationInProgress = false;

  Future<void> validation() async {
    // Prevent duplicate calls at scene level
    if (_isValidationInProgress || _mobileNumberModel.isLoading) {
      print('⚠️ Validation already in progress or loading, ignoring duplicate call');
      print('⚠️ _isValidationInProgress: $_isValidationInProgress');
      print('⚠️ _mobileNumberModel.isLoading: ${_mobileNumberModel.isLoading}');
      return;
    }

    // Set flag immediately
    _isValidationInProgress = true;

    print('');
    print('🔵🔵🔵 Validation called 🔵🔵🔵');
    if (_mobileNumberModel.formKey.currentState!.validate()) {
      print('✅ Form validation passed');

      // Hide keyboard
      hideKeyboard();

      // Get phone number
      final mobileNumber = _mobileNumberModel.mobileNumberController.text;

      print('📱 Phone Number: $mobileNumber');
      print('📤 Emitting ValidateUserSaveEvent...');
      print('');

      // Emit save event to BLoC (bloc will handle loading state and show dialog)
      // Double check flag before emitting
      if (!_isValidationInProgress) {
        print('⚠️⚠️⚠️ Validation lock was released before emitting! Not emitting event ⚠️⚠️⚠️');
        _isValidationInProgress = false; // Reset if somehow it got reset
        return;
      }
      
      print('📤 Emitting ValidateUserSaveEvent to bloc...');
      emit(ValidateUserSaveEvent(mobileNumber));
      print('✅ Event emitted to BLoC');
      print('🔒 Validation lock: $_isValidationInProgress');
      
      // Reset flag after a delay to allow bloc to process
      // Don't reset immediately to prevent rapid successive calls
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _isValidationInProgress = false;
          print('🔓 Validation lock released');
        }
      });
    } else {
      print('❌ Form validation failed');
      print('');
      _isValidationInProgress = false;
    }
  }

  void showVerificationDialog({
    String? phoneNumberOtpRequestId,
    String? transactionId,
  }) {
    // Get last 2 digits of phone number for masking
    final phoneNumber = _mobileNumberModel.mobileNumberController.text;
    final lastTwoDigits = phoneNumber.length >= 2
        ? phoneNumber.substring(phoneNumber.length - 2)
        : "90";

    VerificationDialogHelper.showVerificationDialog(
      context,
      lastTwoDigits,
      mobileNumber: phoneNumber,
      phoneNumberOtpRequestId: phoneNumberOtpRequestId,
      transactionId: transactionId,
    );
  }
}
