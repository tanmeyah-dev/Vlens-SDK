import 'package:core/bases/base_state.dart';
import 'package:core/bases/states/base/base_state.dart';
import 'package:core/bases/states/base/render_data_state.dart';
import 'package:core/components/button/app_button.dart';
import 'package:core/components/image/app_image.dart';
import 'package:core/style/app_colors.dart';
import 'package:core/utils/ui.dart';
import 'package:flutter/material.dart';

import '../../login_screen/scene/summaryscreen.dart';
import '../bloc/user_info_bloc.dart';
import '../event/user_info_event.dart';
import '../model/user_info_model.dart';
import '../state/user_info_state.dart';
import '../widget/user_info_dynamic_field.dart';

class UserInfoScreen extends StatefulWidget {
  final Map<String, dynamic> eligibilityResponse;

  const UserInfoScreen({
    super.key,
    required this.eligibilityResponse,
  });

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends BaseState<UserInfoScreen, UserInfoBloc, UserInfoModel> {
  bool _isSubmitting = false;

  @override
  void listenToState(BuildContext context, BaseStates state) {
    if (state is UserInfoNavigateToSummaryState) {
      Navigator.of(context)
          .push<void>(
        MaterialPageRoute<void>(
          builder: (_) => SummaryScreen(answeredFields: state.answeredFields),
        ),
      )
          .whenComplete(() {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      });
    }
  }

  @override
  Widget buildWidget(BuildContext context, RenderDataState<UserInfoModel> state) {
    final model = state.data;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.primary,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const AppImage(
            AppAssets.tanmeyah,
            height: 44,
          ),
        ),
        body: ColoredBox(
          color: AppColors.white,
          child: SafeArea(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.translucent,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: model.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'اعرف عميلك',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'برجاء الاجابة على الأسئلة التالية',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'بيانات العمل',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w400,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                      const Divider(color: AppColors.border1, height: 28),
                      Expanded(
                        child: ListView(
                          children: [
                            if (model.isLoadingFields)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(child: CircularProgressIndicator()),
                              )
                            else if (model.fieldsError != null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  model.fieldsError!,
                                  style:
                                      const TextStyle(color: AppColors.error),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            else ...[
                              ...model.requestFields.map(
                                (f) => UserInfoDynamicField(
                                  field: f,
                                  model: model,
                                  onFormChanged: () =>
                                      emit(UserInfoFormChangedEvent()),
                                ),
                              ),
                              if (model.lookupFields.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                const Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    'بيانات إضافية',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.black,
                                    ),
                                  ),
                                ),
                                const Divider(
                                  color: AppColors.border1,
                                  height: 24,
                                ),
                                ...model.lookupFields.map(
                                  (f) => UserInfoDynamicField(
                                    field: f,
                                    model: model,
                                    onFormChanged: () =>
                                        emit(UserInfoFormChangedEvent()),
                                  ),
                                ),
                              ],
                            ],                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        title: _isSubmitting ? 'جاري الحفظ...' : 'حفظ',
                        onPressed: (model.isLoadingFields || _isSubmitting)
                            ? null
                            : () => _onSavePressed(model),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onSavePressed(UserInfoModel model) async {
    final isValid = model.formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() => _isSubmitting = true);

    try {
      emit(UserInfoSubmitEvent(model.buildSummaryAnswers()));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() => _isSubmitting = false);
    }
  }

  @override
  UserInfoBloc createBloc() {
    return UserInfoBloc(UserInfoModel(eligibilityResponse: widget.eligibilityResponse));
  }
}
