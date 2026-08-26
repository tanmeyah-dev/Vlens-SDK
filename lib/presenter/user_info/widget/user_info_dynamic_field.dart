import 'package:core/components/textField/app_textfield.dart';
import 'package:core/style/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../model/lookups_response.dart';
import '../model/request_fields_response.dart';
import '../model/user_info_model.dart';
import '../utils/user_info_field_helpers.dart';
import '../utils/user_info_lookup_helpers.dart';

/// Renders one dynamic request-field row (text, number, radio, checkbox, date, multiselect, select).
class UserInfoDynamicField extends StatelessWidget {
  const UserInfoDynamicField({
    super.key,
    required this.field,
    required this.model,
    required this.onFormChanged,
  });

  final RequestFieldItem field;
  final UserInfoModel model;
  final VoidCallback onFormChanged;

  void _dismissKeyboard(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final title =
        field.displayText.trim().isNotEmpty ? field.displayText : field.key;
    final type = field.type.toLowerCase();
    final isLockedFromId = isIdExtractedLockedField(field);
    final isOptional = isOptionalUserInfoField(field);

    if (type == 'text') {
      final isNumberOfChildren = field.key == 'numberOfChildren';
      final controller = model.textControllers[field.key] ??
          TextEditingController(text: field.value ?? '');
      model.textControllers[field.key] = controller;
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: AppTextField(
          labelText: title,
          hintText: title,
          controller: controller,
          keyboardType:
              isNumberOfChildren ? TextInputType.number : TextInputType.text,
          inputFormatters: isNumberOfChildren
              ? [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(1),
                ]
              : null,
          textAlign: TextAlign.right,
          onEditingComplete: () => _dismissKeyboard(context),
          onTapOutside: (_) => _dismissKeyboard(context),
          validator: (value) {
            final text = (value ?? '').trim();
            if (text.isEmpty) {
              return isOptional ? null : 'هذا الحقل مطلوب';
            }
            if (isNumberOfChildren) {
              if (text.length != 1) {
                return 'يجب إدخال رقم واحد فقط';
              }
              return null;
            }
            if (text.length < 4) return 'الحد الأدنى 4 أحرف';
            return null;
          },
        ),
      );
    }

    if (type == 'number') {
      final controller = model.textControllers[field.key] ??
          TextEditingController(text: field.value ?? '');
      model.textControllers[field.key] = controller;
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: AppTextField(
          labelText: title,
          hintText: title,
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          textAlign: TextAlign.right,
          onEditingComplete: () => _dismissKeyboard(context),
          onTapOutside: (_) => _dismissKeyboard(context),
          validator: (value) {
            final text = (value ?? '').trim();
            if (text.isEmpty) {
              return isOptional ? null : 'هذا الحقل مطلوب';
            }
            final normalized = text.replaceAll(',', '').replaceAll(' ', '');
            if (normalized.isEmpty || num.tryParse(normalized) == null) {
              return 'برجاء إدخال رقم صالح';
            }
            return null;
          },
        ),
      );
    }

    if (type == 'radiogroup') {
      final lookupItems = model.lookupItemsForField(field);
      final useLookups = lookupItems.isNotEmpty;
      final values = useLookups
          ? lookupItems.map((e) => e.id).toList()
          : field.availableValues;
      final labelsByValue = useLookups
          ? {for (final item in lookupItems) item.id: item.name}
          : {for (final v in values) v: v};
      final current = model.selectedValues[field.key];
      final selected = values.contains(current) ? current : null;

      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: FormField<String>(
          key: ValueKey<String>(
              'rg_${field.key}_${model.selectedValues[field.key] ?? ''}'),
          initialValue: selected,
          validator: (value) {
            if ((value ?? '').trim().isEmpty) {
              return 'برجاء الاختيار';
            }
            return null;
          },
          builder: (formState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),
                RadioGroup<String>(
                  groupValue: formState.value,
                  onChanged: isLockedFromId
                      ? (_) {}
                      : (value) {
                          _dismissKeyboard(context);
                          formState.didChange(value);
                          model.selectedValues[field.key] = value;
                          onFormChanged();
                        },
                  child: Column(
                    children: values
                        .map(
                          (option) => RadioListTile<String>(
                            contentPadding: EdgeInsets.zero,
                            enabled: !isLockedFromId,
                            title: Text(
                              labelsByValue[option] ?? option,
                              textAlign: TextAlign.right,
                            ),
                            value: option,
                            selected: formState.value == option,
                          ),
                        )
                        .toList(),
                  ),
                ),
                if (formState.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, right: 12),
                    child: Text(
                      formState.errorText ?? '',
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );
    }

    if (type == 'checkbox') {
      final checked = model.checkboxValues[field.key] ?? false;
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: checked,
          activeColor: AppColors.primary,
          title: Text(
            title,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: (value) {
            _dismissKeyboard(context);
            model.checkboxValues[field.key] = value ?? false;
            onFormChanged();
          },
        ),
      );
    }

    if (type == 'date') {
      final current = model.dateValues[field.key];

      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: FormField<DateTime>(
          key: ValueKey<String>(
              'dt_${field.key}_${model.dateValues[field.key]?.millisecondsSinceEpoch ?? 0}'),
          initialValue: current,
          validator: (value) => value == null ? 'برجاء اختيار التاريخ' : null,
          builder: (formState) {
            final display = formState.value != null
                ? formatDateDdMmYyyy(formState.value!)
                : null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    _dismissKeyboard(context);
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: formState.value ?? now,
                      firstDate: DateTime(1900),
                      lastDate: DateTime(now.year + 50, 12, 31),
                    );
                    if (picked != null) {
                      formState.didChange(picked);
                      model.dateValues[field.key] = picked;
                      onFormChanged();
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: InputDecorator(
                    isEmpty: display == null,
                    decoration: InputDecoration(
                      hintText: 'اختر $title',
                      hintStyle: const TextStyle(
                        color: AppColors.hintGray,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: AppColors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.border1, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.border1, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.primary, width: 1),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 15,
                      ),
                      suffixIcon: const Icon(Icons.calendar_today,
                          color: AppColors.secondary),
                    ),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        display ?? '',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                if (formState.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, right: 12),
                    child: Text(
                      formState.errorText ?? '',
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );
    }

    if (type == 'multiselect') {
      final options = field.availableValues;
      final selectedSet =
          Set<String>.from(model.multiSelectValues[field.key] ?? {});

      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: FormField<Set<String>>(
          key: ValueKey<String>(
              'ms_${field.key}_${(model.multiSelectValues[field.key] ?? {}).join('|')}'),
          initialValue: selectedSet,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'اختر خياراً واحداً على الأقل';
            }
            return null;
          },
          builder: (formState) {
            final active = Set<String>.from(formState.value ?? {});

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: options.map((option) {
                    final isOn = active.contains(option);
                    return FilterChip(
                      label: Text(option),
                      selected: isOn,
                      onSelected: (on) {
                        _dismissKeyboard(context);
                        final next = Set<String>.from(active);
                        if (on) {
                          next.add(option);
                        } else {
                          next.remove(option);
                        }
                        formState.didChange(next);
                        model.multiSelectValues[field.key] = next;
                        onFormChanged();
                      },
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      checkmarkColor: AppColors.primary,
                    );
                  }).toList(),
                ),
                if (formState.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 12),
                    child: Text(
                      formState.errorText ?? '',
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );
    }

    if (type == 'select') {
      final locationRole = detectLocationFieldRole(field);
      final usesLocations =
          locationRole != null && model.locations.isNotEmpty;
      final lookupItems = usesLocations
          ? model.selectOptionsForField(field)
          : model.lookupItemsForField(field);
      final useLookups = lookupItems.isNotEmpty || usesLocations;
      final optionItems = useLookups
          ? lookupItems
          : field.availableValues
              .map((value) => LookupItem(id: value, name: value))
              .toList();
      final current = model.selectedValues[field.key]?.trim();
      // Match by id or display name so short labels like "لا" stay selected.
      LookupItem? selectedItem;
      if (current != null && current.isNotEmpty) {
        for (final item in optionItems) {
          if (item.id.trim() == current || item.name.trim() == current) {
            selectedItem = item;
            break;
          }
        }
      }
      final selected = selectedItem?.id;

      final govField = findLocationFieldByRole(
        model.allFormFields,
        LocationFieldRole.governorate,
      );
      final cityField = findLocationFieldByRole(
        model.allFormFields,
        LocationFieldRole.city,
      );
      final parentCascadeKey = usesLocations
          ? '${model.selectedValues[govField?.key] ?? ''}_'
              '${model.selectedValues[cityField?.key] ?? ''}'
          : '';

      final hintText = () {
        if (usesLocations && optionItems.isEmpty) {
          if (locationRole == LocationFieldRole.city) {
            return 'اختر المحافظة أولاً';
          }
          if (locationRole == LocationFieldRole.village) {
            return 'اختر المدينة أولاً';
          }
        }
        return 'اختر $title';
      }();

      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.secondary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: ValueKey<String>(
                'dd_${field.key}_${parentCascadeKey}_${selected ?? ''}',
              ),
              initialValue: selected,
              isExpanded: true,
              decoration: InputDecoration(
                hintText: selected == null ? hintText : null,
                hintStyle: const TextStyle(
                  color: AppColors.hintGray,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: isLockedFromId
                    ? const Color(0xFFF3F3F3)
                    : AppColors.white,
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
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border1, width: 1),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              icon: Icon(
                Icons.arrow_drop_down,
                color: isLockedFromId
                    ? AppColors.hintGray
                    : AppColors.secondary,
              ),
              onTap: isLockedFromId ? null : () => _dismissKeyboard(context),
              selectedItemBuilder: (context) => optionItems
                  .map(
                    (item) => Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        item.name,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          color: AppColors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              items: optionItems
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item.id,
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          item.name,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (isLockedFromId || optionItems.isEmpty)
                  ? null
                  : (value) {
                      if (usesLocations) {
                        model.onLocationSelectionChanged(field, value);
                      } else {
                        model.selectedValues[field.key] = value;
                      }
                      onFormChanged();
                    },
              validator: (value) {
                if (usesLocations && optionItems.isEmpty) {
                  if (locationRole == LocationFieldRole.city) {
                    return 'برجاء اختيار المحافظة أولاً';
                  }
                  if (locationRole == LocationFieldRole.village) {
                    return 'برجاء اختيار المدينة أولاً';
                  }
                }
                if ((value ?? '').trim().isEmpty) {
                  return isOptional ? null : 'برجاء الاختيار';
                }
                return null;
              },
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
