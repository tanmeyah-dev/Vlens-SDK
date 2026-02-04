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
import '../../mobile_number/widgets/app_header.dart';
import '../bloc/username_security_code_bloc.dart';
import '../constants/security_code_constants.dart';
import '../event/username_security_code_event.dart';
import '../model/username_security_code_model.dart';
import '../state/username_security_code_state.dart';
import '../utils/arabic_only_formatter.dart';
import '../utils/username_validator.dart';
import '../widgets/pin_input_field.dart';
import '../widgets/security_code_guidelines.dart';

class UsernameSecurityCodeScene extends StatefulWidget {
  const UsernameSecurityCodeScene({super.key});

  @override
  State<UsernameSecurityCodeScene> createState() => _UsernameSecurityCodeSceneState();
}

class _UsernameSecurityCodeSceneState
    extends BaseState<UsernameSecurityCodeScene, UsernameSecurityCodeBloc, UsernameSecurityCodeModel> {
  late UsernameSecurityCodeModel _model;

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
                              usernameField(),
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
          "قم بإنشاء اسم مستخدم",
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

  Widget usernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          "اسم المستخدم",
          color: AppColors.secondary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        8.height,
        AppTextField(
          hintText: "اسم المستخدم",
          controller: _model.usernameController,
          keyboardType: TextInputType.text,
          inputFormatters: [
            ArabicOnlyFormatter(),
          ],
          onChanged: (_) {
            _checkAndEnableSaveButton();
          },
          validator: UsernameValidator.getValidationError,
        ),
      ],
    );
  }

  Widget createSecurityCodeField() {
    return PinInputField(
      label: "انشاء رمز الحماية",
      controller: _model.createSecurityCodeController,
      focusNode: _model.createSecurityCodeFocusNode,
      length: SecurityCodeConstants.pinLength,
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
      length: SecurityCodeConstants.pinLength,
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

  @override
  UsernameSecurityCodeBloc createBloc() {
    return UsernameSecurityCodeBloc(UsernameSecurityCodeModel());
  }

  @override
  void listenToState(BuildContext context, BaseStates state) {
    if (state is OnUsernameSecurityCodeSavedState) {
      // Navigate to login screen
      Navigator.of(context).pushNamed(RoutePath.loginScreen);
    }
  }

  void _checkAndEnableSaveButton() {
    emit(EnableSaveButtonEvent(_model.isFormValid()));
  }

  Future<void> validation() async {
    if (_model.formKey.currentState!.validate()) {
      if (!_model.isSecurityCodeValid()) {
        // Show error for invalid security code
        return;
      }
      if (!_model.doSecurityCodesMatch()) {
        // Show error for non-matching codes
        return;
      }
      emit(SaveUsernameSecurityCodeEvent(
        _model.usernameController.text,
        _model.createSecurityCodeController.text,
      ));
    }
  }
}
