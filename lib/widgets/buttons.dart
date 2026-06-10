import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class _BtnChild extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color fg;
  const _BtnChild({this.icon, required this.label, required this.fg});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 18, color: fg), const SizedBox(width: 8)],
        Flexible(
          child: Text(label,
              style: AppText.labelLg.copyWith(fontSize: 15, color: fg),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final bool disabled;
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.height = 52,
    this.disabled = false,
  });
  @override
  Widget build(BuildContext context) {
    final off = disabled || onPressed == null;
    return SizedBox(
      width: double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: off
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primaryNavy.withValues(alpha: 0.22),
                    offset: const Offset(0, 6),
                    blurRadius: 16,
                  ),
                ],
        ),
        child: FilledButton(
          onPressed: off ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryNavy,
            disabledBackgroundColor:
                AppColors.primaryNavy.withValues(alpha: 0.35),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.card)),
            elevation: 0,
          ),
          child: _BtnChild(icon: icon, label: label, fg: Colors.white),
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.height = 52,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.secondaryCyan,
          foregroundColor: AppColors.primaryNavy,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card)),
          elevation: 0,
        ),
        child: _BtnChild(icon: icon, label: label, fg: AppColors.primaryNavy),
      ),
    );
  }
}

class OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  const OutlineButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.height = 52,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryNavy,
          side: const BorderSide(color: AppColors.primaryNavy),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card)),
        ),
        child: _BtnChild(icon: icon, label: label, fg: AppColors.primaryNavy),
      ),
    );
  }
}
