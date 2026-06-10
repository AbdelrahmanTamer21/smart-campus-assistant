import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

enum ChipVariant { confirmed, cancelled, roomchanged, open, urgent, featured, soon, pending }

class _ChipStyle {
  final Color bg;
  final Color fg;
  final String label;
  const _ChipStyle(this.bg, this.fg, this.label);
}

const _styles = {
  ChipVariant.confirmed: _ChipStyle(AppColors.successContainer, AppColors.onSuccess, 'Confirmed'),
  ChipVariant.cancelled: _ChipStyle(AppColors.errorContainer, AppColors.onErrorContainer, 'Cancelled'),
  ChipVariant.roomchanged: _ChipStyle(AppColors.roomChangedBg, AppColors.roomChangedFg, 'Room Changed'),
  ChipVariant.open: _ChipStyle(AppColors.secondaryCyan, AppColors.primaryNavy, 'OPEN NOW'),
  ChipVariant.urgent: _ChipStyle(AppColors.errorContainer, AppColors.onErrorContainer, 'Urgent'),
  ChipVariant.featured: _ChipStyle(AppColors.primaryNavy, Colors.white, 'Featured'),
  ChipVariant.soon: _ChipStyle(AppColors.secondaryCyan, AppColors.primaryNavy, 'Class Starting Soon'),
  ChipVariant.pending: _ChipStyle(AppColors.roomChangedBg, AppColors.roomChangedFg, 'Pending sync'),
};

class StatusChip extends StatelessWidget {
  final ChipVariant variant;
  final String? label;
  final IconData? icon;
  const StatusChip({super.key, required this.variant, this.label, this.icon});
  @override
  Widget build(BuildContext context) {
    final s = _styles[variant]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(AppRadius.tag),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: s.fg), const SizedBox(width: 5)],
          Text(label ?? s.label,
              style: AppText.labelSm.copyWith(
                color: s.fg,
                fontWeight: FontWeight.w600,
                letterSpacing: variant == ChipVariant.open || variant == ChipVariant.soon ? 0.4 : 0,
              )),
        ],
      ),
    );
  }
}

/// Simple pill tag with custom colors.
class Tag extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  const Tag({super.key, required this.text, this.bg = AppColors.fill, this.fg = AppColors.textMuted});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.tag)),
      child: Text(text,
          style: AppText.labelSm.copyWith(color: fg, fontWeight: FontWeight.w600)),
    );
  }
}

/// Horizontal filter chips with one active (navy fill).
class FilterChipBar extends StatelessWidget {
  final List<String> items;
  final int active;
  final ValueChanged<int> onChanged;
  final EdgeInsets padding;
  const FilterChipBar({
    super.key,
    required this.items,
    required this.active,
    required this.onChanged,
    this.padding = EdgeInsets.zero,
  });
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++)
            Padding(
              padding: EdgeInsets.only(right: i == items.length - 1 ? 0 : 8),
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: i == active ? AppColors.primaryNavy : AppColors.fill,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(items[i],
                      style: AppText.labelLg.copyWith(
                        fontSize: 13,
                        color: i == active ? Colors.white : AppColors.textMuted,
                      )),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
