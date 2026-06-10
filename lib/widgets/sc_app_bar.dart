import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// App bar: leading avatar/back + small uppercase title + optional larger
/// subtitle + trailing. Matches the prototype's `AppBar`.
class SCAppBar extends StatelessWidget {
  final Widget? leading;
  final VoidCallback? onBack;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final bool dark;
  const SCAppBar({
    super.key,
    this.leading,
    this.onBack,
    this.title,
    this.subtitle,
    this.trailing,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.headerTop,
        AppSpacing.screen,
        AppSpacing.headerBottom,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (onBack != null)
            _CircleBtn(
              icon: Icons.chevron_left,
              onTap: onBack!,
              bg: dark ? Colors.white.withValues(alpha: 0.12) : AppColors.fill,
              fg: fg,
            )
          else if (leading != null)
            leading!,
          if (onBack != null || leading != null) const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: AppSpacing.headerContentHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(title!.toUpperCase(),
                        style: AppText.labelLg.copyWith(
                          fontSize: 13,
                          color: dark ? Colors.white70 : AppColors.hint,
                          letterSpacing: 1.04,
                        )),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: AppText.headlineSm.copyWith(fontSize: 17, color: fg),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color bg;
  final Color fg;
  const _CircleBtn({required this.icon, required this.onTap, required this.bg, required this.fg});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, size: 22, color: fg),
      ),
    );
  }
}

/// White circular icon button with l1 shadow (bell, refresh, etc.).
class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color bg;
  final Color iconColor;
  final bool dot;
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.bg = AppColors.card,
    this.iconColor = AppColors.primaryNavy,
    this.dot = false,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              boxShadow: AppShadow.l1,
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          if (dot)
            Positioned(
              top: 11,
              right: 12,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.card, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
