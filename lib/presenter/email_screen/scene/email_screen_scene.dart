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
import 'package:core/utils/cache/verification_cache.dart';
import '../bloc/email_screen_bloc.dart';
import '../event/email_screen_event.dart';
import '../model/email_screen_model.dart';
import '../state/email_screen_state.dart';
import '../utils/email_verification_dialog_helper.dart';

class EmailScreenScene extends StatefulWidget {
  const EmailScreenScene({super.key});

  @override
  State<EmailScreenScene> createState() => _EmailScreenSceneState();
}

class _EmailScreenSceneState
    extends BaseState<EmailScreenScene, EmailScreenBloc, EmailScreenModel> {
  late EmailScreenModel _model;
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
    print('📥 Loaded from cache in EmailScreenScene:');
    print('📥 phoneNumberOtpRequestId: $_cachedPhoneNumberOtpRequestId');
    print('📥 transactionId: $_cachedTransactionId');
    print('📥 mobileNumber: $_cachedMobileNumber');
  }

  @override
  Widget buildWidget(BuildContext context, RenderDataState<EmailScreenModel> state) {
    _model = state.data;
    
    // Calculate responsive padding based on screen width
    final horizontalPadding = screenWidth > 600
        ? screenWidth * 0.1 // 10% padding on tablets/desktop
        : 16.0; // Fixed 16px on mobile

    final verticalSpacing = screenHeight > 800
        ? 40 // More spacing on larger screens
        : (screenHeight * 0.05)
            .round(); // 5% of screen height on smaller screens

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
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                              verticalSpacing.height,
                              instructions(),
                              verticalSpacing.height,
                              emailField(),
                              verticalSpacing.height,
                              orDivider(),
                              16.height,
                              googleSignInButton(),
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
          "قم بادخال",
          color: AppColors.primary,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        4.height,
        AppText(
          "الإيميل الخاص بك",
          color: AppColors.primary,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ],
    );
  }

  Widget emailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          "الإيميل",
          color: AppColors.secondary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        8.height,
        AppTextField(
          hintText: "example@example.com",
          controller: _model.emailController,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) {
            _checkAndEnableSaveButton();
          },
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'البريد الإلكتروني مطلوب';
            }
            final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
            if (!emailRegex.hasMatch(value.trim())) {
              return 'البريد الإلكتروني غير صحيح';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget orDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: AppText(
            'أو',
            color: AppColors.secondary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border1)),
      ],
    );
  }

  Widget googleSignInButton() {
    final disabled = _model.isLoading || _model.isGoogleLoading;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled
            ? null
            : () {
                hideKeyboard();
                emit(SignInWithGoogleEvent());
              },
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          height: 64,
          decoration: BoxDecoration(
            color: disabled ? const Color(0xffE9EAEE) : AppColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFDADCE0)),
                ),
                child: const Text(
                  'G',
                  style: TextStyle(
                    color: Color(0xFF4285F4),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'المتابعة باستخدام Google',
                style: TextStyle(
                  color: disabled ? AppColors.gray : AppColors.secondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget saveButton() {
    // Disable button if loading or if input is invalid
    final isButtonDisabled = _model.isSaveButtonDisabled || _model.isLoading;

    return AppButton(
      title: "حفظ",
      textColor: isButtonDisabled
          ? AppColors.gray
          : AppColors.white,
      onPressed: isButtonDisabled ? null : () => validation(),
    );
  }

  EmailScreenBloc createBloc() {
    return EmailScreenBloc(EmailScreenModel());
  }

  bool _isLoadingDialogShowing = false;
  bool _isLoadingDialogMounted = false;

  @override
  void listenToState(BuildContext context, BaseStates state) {
    if (state is OnEmailLoadingState) {
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
              _isLoadingDialogMounted = true;
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
    } else if (state is OnEmailVerificationRequiredState) {
      // Hide loading dialog if showing
      if (_isLoadingDialogShowing && _isLoadingDialogMounted) {
        _isLoadingDialogShowing = false;
        _isLoadingDialogMounted = false;
        Navigator.of(context, rootNavigator: false).pop(); // Close loading dialog
      }
      // Show email verification dialog
      print('📧 Showing email verification dialog');
      EmailVerificationDialogHelper.showEmailVerificationDialog(
        context,
        state.email,
        emailOtpRequestId: state.emailOtpRequestId,
        transactionId: state.transactionId,
      );
    } else if (state is OnEmailConfirmedState) {
      // Hide loading dialog if showing
      if (_isLoadingDialogShowing && _isLoadingDialogMounted) {
        _isLoadingDialogShowing = false;
        _isLoadingDialogMounted = false;
        Navigator.of(context, rootNavigator: false).pop(); // Close loading dialog
      }
      final email = (state.email?.trim().isNotEmpty == true)
          ? state.email!.trim()
          : _model.emailController.text.trim();
      print('📧 Email confirmed - navigating to username security screen');
      Navigator.of(context).pushNamed(
        RoutePath.registerScreen,
        arguments: email,
      );
    } else if (state is OnEmailErrorState) {
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
    } else if (state is OnEmailLoadingDismissedState) {
      // Cancel/interrupt can arrive before the post-frame showDialog runs.
      if (_isLoadingDialogShowing && _isLoadingDialogMounted) {
        Navigator.of(context, rootNavigator: false).pop();
      }
      _isLoadingDialogShowing = false;
      _isLoadingDialogMounted = false;
    }
  }

  void _checkAndEnableSaveButton() {
    final email = _model.emailController.text.trim();
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    final isValid = email.isNotEmpty && emailRegex.hasMatch(email);
    print('🔍 Email validation check: email="$email", isValid=$isValid');
    emit(EnableSaveButtonEvent(isValid));
  }

  bool _isValidationInProgress = false;

  Future<void> validation() async {
    // Prevent duplicate calls at scene level
    if (_isValidationInProgress || _model.isLoading) {
      print('⚠️ Validation already in progress or loading, ignoring duplicate call');
      print('⚠️ _isValidationInProgress: $_isValidationInProgress');
      print('⚠️ _model.isLoading: ${_model.isLoading}');
      return;
    }

    // Set flag immediately
    _isValidationInProgress = true;

    print('');
    print('🔵🔵🔵 Email Validation called 🔵🔵🔵');
    if (_model.formKey.currentState!.validate()) {
      print('✅ Form validation passed');
      
      // Disable button immediately to prevent double-tap
      _model.isSaveButtonDisabled = true;
      emit(EnableSaveButtonEvent(false));
      
      // Hide keyboard
      hideKeyboard();

      // Get email
      final email = _model.emailController.text.trim();

      print('📧 Email: $email');
      print('📤 Emitting SaveEmailEvent...');
      print('');

      // Emit save event to BLoC (bloc will handle loading state and show dialog)
      // Double check flag before emitting
      if (!_isValidationInProgress) {
        print('⚠️⚠️⚠️ Validation lock was released before emitting! Not emitting event ⚠️⚠️⚠️');
        _isValidationInProgress = false; // Reset if somehow it got reset
        return;
      }
      
      print('📤 Emitting SaveEmailEvent to bloc...');
      emit(SaveEmailEvent(email));
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
}
