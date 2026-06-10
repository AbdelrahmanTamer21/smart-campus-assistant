import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Filled input: #EEEEEE bg, 16-radius, leading icon, focus → 2px navy border,
/// inline #BA1A1A error text.
class AppTextField extends StatefulWidget {
  final IconData? icon;
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool obscure;
  final String? error;
  final Widget? trailing;
  final VoidCallback? onTrailingTap;
  final bool readOnly;
  final TextInputType? keyboardType;
  const AppTextField({
    super.key,
    this.icon,
    this.hint,
    this.controller,
    this.onChanged,
    this.obscure = false,
    this.error,
    this.trailing,
    this.onTrailingTap,
    this.readOnly = false,
    this.keyboardType,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final _focus = FocusNode();
  bool _f = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _f = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final err = widget.error != null;
    final borderColor = err
        ? AppColors.error
        : _f
            ? AppColors.primaryNavy
            : Colors.transparent;
    final iconColor = err
        ? AppColors.error
        : _f
            ? AppColors.primaryNavy
            : AppColors.hint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.fill,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Row(
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 20, color: iconColor),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: TextField(
                  focusNode: _focus,
                  controller: widget.controller,
                  onChanged: widget.onChanged,
                  obscureText: widget.obscure,
                  readOnly: widget.readOnly,
                  keyboardType: widget.keyboardType,
                  style: AppText.bodyLg,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: widget.hint,
                    hintStyle: AppText.bodyLg.copyWith(color: AppColors.hint),
                  ),
                ),
              ),
              if (widget.trailing != null)
                GestureDetector(
                    onTap: widget.onTrailingTap, child: widget.trailing!),
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
                  child: Text(widget.error!,
                      style: AppText.labelSm.copyWith(color: AppColors.error)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
