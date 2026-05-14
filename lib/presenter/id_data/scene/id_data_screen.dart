import 'package:core/bases/base_state.dart';
import 'package:core/bases/states/base/base_state.dart';
import 'package:core/bases/states/base/render_data_state.dart';
import 'package:core/components/button/app_button.dart';
import 'package:core/components/image/app_image.dart';
import 'package:core/style/app_colors.dart';
import 'package:core/utils/ui.dart';
import 'package:flutter/material.dart';

import '../../user_info/scene/user_info_screen.dart';
import '../bloc/id_data_bloc.dart';
import '../event/id_data_event.dart';
import '../model/id_data_model.dart';
import '../state/id_data_state.dart';
import '../utils/id_data_display_rows.dart';

class IdDataScreen extends StatefulWidget {
  final dynamic extractedData;

  const IdDataScreen({
    super.key,
    required this.extractedData,
  });

  @override
  State<IdDataScreen> createState() => _IdDataScreenState();
}

class _IdDataScreenState extends BaseState<IdDataScreen, IdDataBloc, IdDataModel> {
  @override
  void listenToState(BuildContext context, BaseStates state) {
    if (state is IdDataNavigateToUserInfoState) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => UserInfoScreen(eligibilityResponse: state.eligibilityResponse),
        ),
      );
    }
  }

  @override
  Widget buildWidget(BuildContext context, RenderDataState<IdDataModel> state) {
    final model = state.data;
    final rows = buildIdDataDisplayRows(model.effectiveExtractedData);

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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'نتيجة التحقق',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'تم انشاء هاويتك الرقميه بنجاح و هذه هي البيانات الخاصه بك',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Table(
                        border: TableBorder.all(color: AppColors.border1),
                        columnWidths: const {
                          0: FlexColumnWidth(2),
                          1: FlexColumnWidth(3),
                        },
                        children: [
                          const TableRow(
                            decoration: BoxDecoration(color: AppColors.white),
                            children: [
                              Padding(
                                padding: EdgeInsets.all(10),
                                child: Text(
                                  'الحقل',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(10),
                                child: Text(
                                  'القيمة',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                          ...rows.map(
                            (entry) => TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Text(entry.key),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Text(entry.value),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (model.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      model.errorMessage!,
                      style: const TextStyle(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 12),
                  AppButton(
                    title: model.isCheckingEligibility
                        ? 'جاري التحقق...'
                        : 'اضغط هنا لاستكمال البيانات',
                    onPressed: model.isCheckingEligibility
                        ? null
                        : () => emit(IdDataContinueEvent()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  IdDataBloc createBloc() {
    return IdDataBloc(
      IdDataModel(extractedData: widget.extractedData),
    );
  }
}
