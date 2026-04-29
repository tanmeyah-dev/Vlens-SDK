import 'package:core/bases/base_state.dart';
import 'package:core/bases/states/base/base_state.dart';
import 'package:core/bases/states/base/render_data_state.dart';
import 'package:core/components/text/app_text.dart';
import 'package:core/style/app_colors.dart';
import 'package:flutter/material.dart';
import '../bloc/home_bloc.dart';
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
        appBar: AppBar(
          centerTitle: true,
          elevation: 0,
          backgroundColor: AppColors.white,
          title: const Text(
            'انواع ال',
            style: TextStyle(
              color: AppColors.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: SafeArea(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_model.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_model.errorMessage != null && _model.errorMessage!.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: AppText(
            _model.errorMessage!,
            color: AppColors.error,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_model.requestTypes.isEmpty) {
      return Center(
        child: AppText(
          'لا توجد بيانات',
          color: AppColors.secondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _model.requestTypes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _model.requestTypes[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                item.name ?? '-',
                color: AppColors.secondary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              const SizedBox(height: 6),
              AppText(
                item.typeName ?? '-',
                color: AppColors.gray,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ],
          ),
        );
      },
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
