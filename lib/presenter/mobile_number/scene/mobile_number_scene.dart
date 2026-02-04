import 'package:core/bases/base_state.dart';
import 'package:core/bases/states/base/base_state.dart';
import 'package:core/bases/states/base/render_data_state.dart';
import 'package:core/components/button/app_button.dart';
import 'package:core/components/text/app_text.dart';
import 'package:core/extensions/widget_extension.dart';
import 'package:core/utils/ui.dart';
import 'package:core/style/app_colors.dart';
import 'package:flutter/material.dart';
import '../bloc/mobile_number_bloc.dart';
import '../constants/mobile_number_constants.dart';
import '../event/mobile_number_event.dart';
import '../model/mobile_number_model.dart';
import '../state/mobile_number_state.dart';
import '../utils/verification_dialog_helper.dart';
import '../widgets/app_header.dart';
import '../widgets/mobile_number_field.dart';

class MobileNumberScene extends StatefulWidget {
  const MobileNumberScene({super.key});

  @override
  State<MobileNumberScene> createState() => _MobileNumberSceneState();
}

class _MobileNumberSceneState
    extends BaseState<MobileNumberScene, MobileNumberBloc, MobileNumberModel> {
  late MobileNumberModel _mobileNumberModel;

  @override
  Widget buildWidget(
      BuildContext context, RenderDataState<MobileNumberModel> state) {
    _mobileNumberModel = state.data;
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
                  key: _mobileNumberModel.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
          MobileNumberConstants.instructionsLine1,
          color: AppColors.primary,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        4.height,
        AppText(
          MobileNumberConstants.instructionsLine2,
          color: AppColors.primary,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ],
    );
  }

  Widget mobileNumberFields() {
    return MobileNumberField(
      controller: _mobileNumberModel.mobileNumberController,
      selectedCountryCode: _mobileNumberModel.selectedCountryCode,
      onChanged: (value) {
        emit(EnableSaveButtonEvent(!_mobileNumberModel.isInputEmpty()));
      },
    );
  }

  Widget saveButton() {
    return AppButton(
      title: MobileNumberConstants.saveButtonText,
      textColor: _mobileNumberModel.isSaveButtonDisabled
          ? AppColors.gray
          : AppColors.white,
      onPressed:
          _mobileNumberModel.isSaveButtonDisabled ? null : () => validation(),
    );
  }

  @override
  MobileNumberBloc createBloc() {
    return MobileNumberBloc(MobileNumberModel());
  }

  @override
  void listenToState(BuildContext context, BaseStates state) {
    if (state is OnMobileNumberSavedState) {
      // TODO: Handle success - navigate back or show success message
      Navigator.of(context).pop();
    }
  }

  Future<void> validation() async {
    if (_mobileNumberModel.formKey.currentState!.validate()) {
      showVerificationDialog();
    }
  }

  void showVerificationDialog() {
    // Get last 2 digits of phone number for masking
    final phoneNumber = _mobileNumberModel.mobileNumberController.text;
    final lastTwoDigits = phoneNumber.length >= 2
        ? phoneNumber.substring(phoneNumber.length - 2)
        : "90";

    VerificationDialogHelper.showVerificationDialog(context, lastTwoDigits);
  }
}
