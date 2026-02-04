import 'package:core/extensions/widget_extension.dart';
import 'package:core/utils/ui.dart';
import 'package:core/style/app_colors.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';

class CountryCodeDisplay extends StatelessWidget {
  final CountryCode selectedCountryCode;

  const CountryCodeDisplay({
    super.key,
    required this.selectedCountryCode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.border1,
          width: 1,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                selectedCountryCode.flagUri ?? "",
                package: 'country_code_picker',
                width: 24,
                height: 24,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(width: 24, height: 24);
                },
              ),
              4.width,
              Text(
                selectedCountryCode.dialCode ?? "+20",
                style: TextStyle(
                  color: AppColors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
