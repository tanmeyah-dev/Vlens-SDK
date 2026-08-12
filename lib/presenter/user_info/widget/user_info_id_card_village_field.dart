import 'package:core/style/app_colors.dart';
import 'package:flutter/material.dart';

import '../model/user_info_model.dart';
import '../utils/user_info_lookup_helpers.dart';

/// Dropdown: villages under the city extracted from the national ID.
class UserInfoIdCardVillageField extends StatelessWidget {
  const UserInfoIdCardVillageField({
    super.key,
    required this.model,
    required this.onFormChanged,
  });

  final UserInfoModel model;
  final VoidCallback onFormChanged;

  @override
  Widget build(BuildContext context) {
    final idCardCity = model.idCardCityFromExtract;
    final optionItems = model.idCardVillageOptions;
    final values = optionItems.map((e) => e.id).toList();
    final current = model.selectedValues[idCardVillageFieldKey];
    final selected = values.contains(current) ? current : null;

    final hintText = () {
      if (idCardCity == null) {
        return 'تعذر تحديد المدينة من بيانات البطاقة';
      }
      if (optionItems.isEmpty) {
        return 'لا توجد مناطق متاحة لهذه المدينة';
      }
      return idCardVillageFieldLabel;
    }();

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            idCardVillageFieldLabel,
            style: const TextStyle(
              color: AppColors.secondary,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey<String>(
              'dd_${idCardVillageFieldKey}_${idCardCity?.id ?? 'none'}_${selected ?? ''}',
            ),
            initialValue: selected,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                color: AppColors.hintGray,
                fontSize: 14,
              ),
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border1, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border1, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary, width: 1),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            ),
            icon: const Icon(Icons.arrow_drop_down, color: AppColors.secondary),
            items: optionItems
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item.id,
                    child: Text(item.name, textAlign: TextAlign.right),
                  ),
                )
                .toList(),
            onChanged: optionItems.isEmpty
                ? null
                : (value) {
                    model.selectedValues[idCardVillageFieldKey] = value;
                    onFormChanged();
                  },
            validator: (value) {
              if (optionItems.isEmpty) return null;
              if ((value ?? '').trim().isEmpty) {
                return 'برجاء اختيار المنطقة التابعة للبطاقة';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
