import 'package:core/bases/base_state.dart';
import 'package:core/bases/states/base/base_state.dart';
import 'package:core/bases/states/base/render_data_state.dart';
import 'package:core/components/image/app_image.dart';
import 'package:core/components/text/app_text.dart';
import 'package:core/extensions/widget_extension.dart';
import 'package:core/utils/ui.dart';
import 'package:core/style/app_colors.dart';
import 'package:flutter/material.dart';
import '../bloc/home_bloc.dart';
import '../event/home_event.dart';
import '../model/home_model.dart';
import '../state/home_state.dart';

class HomeScene extends StatefulWidget {
  const HomeScene({super.key});

  @override
  State<HomeScene> createState() => _HomeSceneState();
}

class _HomeSceneState
    extends BaseState<HomeScene, HomeBloc, HomeModel> {
  late HomeModel _model;

  @override
  Widget buildWidget(
      BuildContext context, RenderDataState<HomeModel> state) {
    _model = state.data;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  const AppImage(
                    AppAssets.tanmeyah,
                    height: 120,
                    width: 120,
                  ),
                  40.height,
                  // Welcome message
                  AppText(
                    "مرحبا ريس شو الاخبار ماشي الحال كله تمام",
                    color: AppColors.secondary,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    textAlign: TextAlign.center,
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
  HomeBloc createBloc() {
    return HomeBloc(HomeModel());
  }

  @override
  void listenToState(BuildContext context, BaseStates state) {
    // Handle home screen states if needed
  }
}
