import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Section header — either `headlineSm` or a small uppercase label, with an
/// optional trailing action ("See All" / "View All").
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final bool small;
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
    this.small = false,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              small ? title.toUpperCase() : title,
              style: small
                  ? AppText.labelSm.copyWith(
                      fontSize: 12,
                      color: AppColors.hint,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.72,
                    )
                  : AppText.headlineSm,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!,
                  style: AppText.labelLg.copyWith(color: AppColors.primaryNavy)),
            ),
        ],
      ),
    );
  }
}
