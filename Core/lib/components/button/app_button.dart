import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:core/components/image/app_image.dart';
import 'package:core/keys/constants.dart';
import '../../style/app_gradient.dart';
import '../../style/app_colors.dart';
import '../../style/app_fonts.dart';
import '../../style/app_dimens.dart';
import '../../utils/ui.dart';

class AppButton extends Container {
  AppButton({
    super.key,
    String title = "",
    Color? backgroundColor = AppColors.primary,
    Color textColor = AppColors.white,
    double fontSize = AppFonts.heading5,
    FontWeight fontWeight = FontWeight.w500,
    double radius = AppDimens.small,
    double minWidth = double.infinity,
    double height = 64,
    VoidCallback? onPressed,
    String? icon,
    IconData? fontAwesomeIcon,
    double iconSize = 20,
    Color borderColor = AppColors.hide,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.center,
    bool horizontalGradient = true,
    bool gradient = false,
    bool shadow = false,
  }) : super(
          decoration: BoxDecoration(
            gradient: gradient
                ? AppGradient(isHorizontal: horizontalGradient).primary
                : null,
            border: Border.all(
              color: borderColor,
              style: BorderStyle.solid,
              width: AppDimens.border,
            ),
            borderRadius: BorderRadius.all(Radius.circular(radius)),
            boxShadow: shadow
                ? [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.10),
                      blurRadius: 1,
                      spreadRadius: 1,
                      offset: const Offset(0, 1),
                    )
                  ]
                : [],
          ),
          child: MaterialButton(
            minWidth: minWidth,
            height: height,
            disabledColor: const Color(0xffE9EAEE),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
            elevation: 0,
            color: gradient ? null : backgroundColor,
            padding: EdgeInsets.zero,
            textColor: textColor,
            onPressed: onPressed,
            child: text(
              icon,
              fontAwesomeIcon,
              title,
              fontSize,
              fontWeight,
              iconSize,
              mainAxisAlignment,
              key,
            ),
          ),
        );

  static Widget text(
    String? icon,
    IconData? fontAwesomeIcon,
    String title,
    double fontSize,
    FontWeight fontWeight,
    double iconSize,
    MainAxisAlignment mainAxisAlignment,
    Key? key,
  ) {
    if (icon == null && fontAwesomeIcon == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 4.5),
        child: Text(
          title,
          key: key,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            fontFamily: 'Roboto',
          ),
        ),
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null)
            AppImage(
              icon,
              width: iconSize,
              height: iconSize,
            ),
          if (fontAwesomeIcon != null)
            FaIcon(fontAwesomeIcon, size: iconSize),
          icon != null || fontAwesomeIcon != null
              ? const SizedBox(width: 8)
              : const SizedBox(width: 0),
          Container(
            margin: const EdgeInsets.only(bottom: 5),
            child: Text(
              title,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: fontWeight,
              ),
            ),
          )
        ],
      );
    }
  }
}
