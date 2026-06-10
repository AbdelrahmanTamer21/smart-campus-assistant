import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Styled dropdown matching [AppTextField] — use for constrained catalog fields.
class AppDropdownField<T> extends StatelessWidget {
  final IconData? icon;
  final String? hint;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;
  final String? error;

  const AppDropdownField({
    super.key,
    this.icon,
    this.hint,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final err = error != null;
    final borderColor = err ? AppColors.error : Colors.transparent;
    final iconColor = err ? AppColors.error : AppColors.hint;
    final safeValue = items.contains(value) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.fill,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: iconColor),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<T>(
                    isExpanded: true,
                    value: safeValue,
                    hint: Text(
                      hint ?? 'Select',
                      style: AppText.bodyLg.copyWith(color: AppColors.hint),
                    ),
                    icon: const Icon(Icons.expand_more, color: AppColors.primaryNavy),
                    style: AppText.bodyLg.copyWith(color: AppColors.textPrimary),
                    dropdownColor: AppColors.card,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    items: [
                      for (final item in items)
                        DropdownMenuItem(
                          value: item,
                          child: Text(
                            itemLabel(item),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: onChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (err)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 13, color: AppColors.error),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(error!,
                      style: AppText.labelSm.copyWith(color: AppColors.error)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
