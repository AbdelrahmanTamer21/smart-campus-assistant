import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_card.dart';
import 'primitives.dart';

/// Card-styled list row: leading icon + title + meta + trailing/chevron.
class ListRow extends StatelessWidget {
  final IconData? icon;
  final Color? iconTint;
  final Widget? leading;
  final String title;
  final String? meta;
  final Widget? trailing;
  final Color? accent;
  final VoidCallback? onTap;
  final bool chevron;
  const ListRow({
    super.key,
    this.icon,
    this.iconTint,
    this.leading,
    required this.title,
    this.meta,
    this.trailing,
    this.accent,
    this.onTap,
    this.chevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        accent: accent,
        onTap: onTap,
        pad: 14,
        child: Row(
          children: [
            if (leading != null)
              leading!
            else if (icon != null)
              IconCircle(
                icon: icon!,
                tint: iconTint ?? AppColors.fill,
                color: AppColors.primaryNavy,
                size: 42,
                iconSize: 20,
              ),
            if (leading != null || icon != null) const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppText.labelLg.copyWith(fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (meta != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(meta!,
                          style: AppText.bodyMd.copyWith(color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                ],
              ),
            ),
            ?trailing,
            if (trailing == null && chevron)
              const Icon(Icons.chevron_right, size: 22, color: AppColors.border),
          ],
        ),
      ),
    );
  }
}
